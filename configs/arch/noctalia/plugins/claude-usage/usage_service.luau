--!nonstrict
-- Headless service: polls the same endpoint the `claude` CLI uses for
-- `/status` (GET /api/oauth/usage) using the OAuth access token Claude Code
-- keeps refreshed on disk, and publishes the 5-hour session and 7-day
-- (weekly) utilization to shared state for the bar widgets to render.
--
-- 429 handling: the usage endpoint shares the rate limit with the Claude
-- Code CLI itself, so bursts of 429s are expected while Claude Code is
-- active. On a 429 the service keeps the last known-good numbers, doubles a
-- backoff interval (60s -> 120s -> ... capped at 15min), and retries. Any
-- success resets the backoff and the normal polling cadence.

local STATE_KEY = "usage"
local BACKOFF_START_SEC = 60
local BACKOFF_MAX_SEC = 900

local backoffSec = 0

local function basePollSeconds()
  local seconds = tonumber(noctalia.getConfig("poll_seconds")) or 90
  if seconds < 20 then
    seconds = 20
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

local function readToken()
  local path = noctalia.getConfig("credentials_path")
  if not path or path == "" then
    path = "~/.claude/.credentials.json"
  end

  local contents, readErr = noctalia.readFile(path)
  if not contents then
    return nil, readErr or ("could not read " .. path)
  end

  local data, decodeErr = noctalia.json.decode(contents)
  if not data then
    return nil, decodeErr or "invalid credentials JSON"
  end

  local oauth = data.claudeAiOauth
  if not oauth or not oauth.accessToken then
    return nil, "no accessToken in credentials file"
  end

  return oauth.accessToken
end

-- Transient failures (network, rate limit) keep the last known-good numbers
-- so the widgets keep showing percentages instead of blinking to "--".
local function setTransientError(msg)
  local current = noctalia.state.get(STATE_KEY) or {}
  noctalia.state.set(STATE_KEY, {
    error = msg,
    rateLimited = true,
    updatedAtSec = os.time(),
    fiveHourPercent = current.fiveHourPercent,
    fiveHourResetsAt = current.fiveHourResetsAt,
    sevenDayPercent = current.sevenDayPercent,
    sevenDayResetsAt = current.sevenDayResetsAt,
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
  local token, tokenErr = readToken()
  if not token then
    setPermanentError(tokenErr)
    return
  end

  noctalia.http({
    url = "https://api.anthropic.com/api/oauth/usage",
    method = "GET",
    headers = {
      "Authorization: Bearer " .. token,
      "anthropic-beta: oauth-2025-04-20",
      "Content-Type: application/json",
    },
  }, function(res)
    if not res.ok then
      setTransientError("erro de rede")
      return
    end

    if res.status == 401 then
      setPermanentError("sessão expirada — abra o Claude Code para renovar")
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

    local fiveHour = body.five_hour
    local sevenDay = body.seven_day

    backoffSec = 0
    noctalia.state.set(STATE_KEY, {
      error = nil,
      rateLimited = false,
      fiveHourPercent = fiveHour and fiveHour.utilization or nil,
      fiveHourResetsAt = fiveHour and fiveHour.resets_at or nil,
      sevenDayPercent = sevenDay and sevenDay.utilization or nil,
      sevenDayResetsAt = sevenDay and sevenDay.resets_at or nil,
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
