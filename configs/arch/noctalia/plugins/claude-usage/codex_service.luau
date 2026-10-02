--!nonstrict
-- Headless service: polls the Codex usage endpoint
-- (GET https://chatgpt.com/backend-api/codex/usage) with the ChatGPT OAuth
-- token the Codex CLI keeps in auth.json, and publishes the primary (5h)
-- and secondary (weekly) rate-limit windows plus credit info to shared
-- state for the bar widgets to render.
--
-- The endpoint sits behind Cloudflare and rejects requests that do not look
-- like the CLI, so requests carry the same originator/version headers Codex
-- sends. 429 handling mirrors the Claude usage service: keep last known-good
-- values, back off exponentially (60s -> ... capped at 15min), retry.

local STATE_KEY = "codex"
local BACKOFF_START_SEC = 60
local BACKOFF_MAX_SEC = 900
local CODEX_VERSION = "0.160.0"

local backoffSec = 0

local function basePollSeconds()
  local seconds = tonumber(noctalia.getConfig("codex_poll_seconds")) or 90
  if seconds < 30 then
    seconds = 30
  end
  return seconds
end

local function schedule()
  if backoffSec > 0 then
    noctalia.setUpdateInterval(backoffSec * 1000)
  else
    noctalia.setUpdateInterval(basePollSeconds() * 1000)
  end
end

local function readAuth()
  local path = noctalia.getConfig("codex_auth_path")
  if not path or path == "" then
    path = "~/.codex/auth.json"
  end

  local contents, readErr = noctalia.readFile(path)
  if not contents then
    return nil, nil, readErr or ("could not read " .. path)
  end

  local data, decodeErr = noctalia.json.decode(contents)
  if not data then
    return nil, nil, decodeErr or "invalid auth JSON"
  end

  local tokens = data.tokens
  if not tokens or not tokens.access_token or tokens.access_token == "" then
    return nil, nil, "sem token ChatGPT — faça login no Codex"
  end

  return tokens.access_token, tokens.account_id
end

-- Transient failures (network, rate limit) keep the last known-good numbers
-- so the widgets keep showing percentages instead of blinking to "--".
local function setTransientError(msg)
  local current = noctalia.state.get(STATE_KEY) or {}
  noctalia.state.set(STATE_KEY, {
    error = msg,
    rateLimited = true,
    updatedAtSec = os.time(),
    primaryPercent = current.primaryPercent,
    primaryResetsAt = current.primaryResetsAt,
    secondaryPercent = current.secondaryPercent,
    secondaryResetsAt = current.secondaryResetsAt,
    planType = current.planType,
    hasCredits = current.hasCredits,
    unlimited = current.unlimited,
    creditBalance = current.creditBalance,
  })
end

local function setPermanentError(msg)
  backoffSec = 0
  noctalia.state.set(STATE_KEY, { error = msg, updatedAtSec = os.time() })
  schedule()
end

local function handle429()
  if backoffSec == 0 then
    backoffSec = BACKOFF_START_SEC
  else
    backoffSec = math.min(backoffSec * 2, BACKOFF_MAX_SEC)
  end
  setTransientError(`HTTP 429 — limite de taxa, nova tentativa em {backoffSec}s`)
  schedule()
end

local function poll()
  local token, accountId, authErr = readAuth()
  if not token then
    setPermanentError(authErr)
    return
  end

  local headers = {
    "Authorization: Bearer " .. token,
    "originator: codex_cli_rs",
    "version: " .. CODEX_VERSION,
    "User-Agent: codex_cli_rs/" .. CODEX_VERSION .. " (Linux x86_64)",
    "Accept: application/json",
  }
  if accountId and accountId ~= "" then
    table.insert(headers, "ChatGPT-Account-Id: " .. accountId)
  end

  noctalia.http({
    url = "https://chatgpt.com/backend-api/codex/usage",
    method = "GET",
    headers = headers,
  }, function(res)
    if not res.ok then
      setTransientError("erro de rede")
      return
    end

    if res.status == 401 then
      setPermanentError("sessão expirada — abra o Codex para renovar")
      return
    end

    if res.status == 429 then
      handle429()
      return
    end

    if res.status ~= 200 then
      setPermanentError(`HTTP {res.status}`)
      return
    end

    local body, decodeErr = noctalia.json.decode(res.body)
    if not body then
      setTransientError(decodeErr or "resposta inválida")
      return
    end

    local rateLimit = body.rate_limit
    local primary = rateLimit and rateLimit.primary_window
    local secondary = rateLimit and rateLimit.secondary_window
    local credits = body.credits

    backoffSec = 0
    noctalia.state.set(STATE_KEY, {
      error = nil,
      rateLimited = false,
      primaryPercent = primary and primary.used_percent or nil,
      primaryResetsAt = primary and primary.reset_at or nil,
      secondaryPercent = secondary and secondary.used_percent or nil,
      secondaryResetsAt = secondary and secondary.reset_at or nil,
      planType = body.plan_type,
      hasCredits = credits and credits.has_credits or nil,
      unlimited = credits and credits.unlimited or nil,
      creditBalance = credits and credits.balance or nil,
      updatedAtSec = os.time(),
    })
    schedule()
  end)
end

function update()
  schedule()
  poll()
end

function onConfigChanged()
  backoffSec = 0
  schedule()
  poll()
end
