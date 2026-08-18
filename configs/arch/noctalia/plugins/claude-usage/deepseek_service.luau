--!nonstrict
-- Headless service: polls the DeepSeek balance endpoint
-- (GET https://api.deepseek.com/user/balance) and publishes the account
-- balance to shared state for the bar widgets to render.
--
-- API key resolution order: the deepseek_api_key plugin setting, then the
-- DEEPSEEK_API_KEY environment variable, then a JSON file (default
-- ~/.local/share/opencode/auth.json, where opencode keeps its provider
-- keys) read as { deepseek = { key = "..." } }.
--
-- 429 handling mirrors the Claude usage service: keep last known-good
-- values, back off exponentially (60s -> ... capped at 15min), retry.

local STATE_KEY = "deepseek"
local BACKOFF_START_SEC = 60
local BACKOFF_MAX_SEC = 900

local backoffSec = 0

local function basePollSeconds()
  local seconds = tonumber(noctalia.getConfig("deepseek_poll_seconds")) or 300
  if seconds < 60 then
    seconds = 60
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

local function readApiKey()
  local configured = noctalia.getConfig("deepseek_api_key")
  if configured and configured ~= "" then
    return configured
  end

  local fromEnv = noctalia.getenv("DEEPSEEK_API_KEY")
  if fromEnv and fromEnv ~= "" then
    return fromEnv
  end

  local path = noctalia.getConfig("deepseek_key_path")
  if not path or path == "" then
    path = "~/.local/share/opencode/auth.json"
  end

  local contents, readErr = noctalia.readFile(path)
  if not contents then
    return nil, readErr or ("could not read " .. path)
  end

  local data, decodeErr = noctalia.json.decode(contents)
  if not data then
    return nil, decodeErr or "invalid auth JSON"
  end

  local key = data.deepseek and data.deepseek.key
  if not key or key == "" then
    return nil, "no deepseek.key in " .. path
  end

  return key
end

local function setTransientError(msg)
  local current = noctalia.state.get(STATE_KEY) or {}
  noctalia.state.set(STATE_KEY, {
    error = msg,
    rateLimited = true,
    updatedAtSec = os.time(),
    currency = current.currency,
    totalBalance = current.totalBalance,
    grantedBalance = current.grantedBalance,
    isAvailable = current.isAvailable,
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
  local key, keyErr = readApiKey()
  if not key then
    setPermanentError(keyErr)
    return
  end

  noctalia.http({
    url = "https://api.deepseek.com/user/balance",
    method = "GET",
    headers = { "Authorization: Bearer " .. key },
  }, function(res)
    if not res.ok then
      setTransientError("erro de rede")
      return
    end

    if res.status == 401 then
      setPermanentError("chave DeepSeek inválida — verifique deepseek_api_key")
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

    local info = body.balance_infos and body.balance_infos[1]
    backoffSec = 0
    noctalia.state.set(STATE_KEY, {
      error = nil,
      rateLimited = false,
      isAvailable = body.is_available,
      currency = info and info.currency or nil,
      totalBalance = info and tonumber(info.total_balance) or nil,
      grantedBalance = info and tonumber(info.granted_balance) or nil,
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
