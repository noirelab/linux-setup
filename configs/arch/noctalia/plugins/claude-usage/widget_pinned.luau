--!nonstrict
-- One bar item for the provider selected in the picker panel.

local PIN_KEY = "pinned_provider"

local DAYS_IN_MONTH = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31 }

local function isLeap(year)
  return year % 4 == 0 and year % 100 ~= 0 or year % 400 == 0
end

local function resetRemaining(value)
  local epoch = type(value) == "number" and value or nil
  if type(value) == "string" then
    local year, month, day, hour, minute, second = value:match("^(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)")
    if year then
      year, month, day = tonumber(year), tonumber(month), tonumber(day)
      hour, minute, second = tonumber(hour), tonumber(minute), tonumber(second)
      if month >= 1 and month <= 12 and day >= 1 and day <= 31 and hour <= 23 and minute <= 59 and second <= 60 then
        local days = 0
        if year >= 1970 then
          for y = 1970, year - 1 do days += isLeap(y) and 366 or 365 end
        else
          for y = year, 1969 do days -= isLeap(y) and 366 or 365 end
        end
        for m = 1, month - 1 do
          days += DAYS_IN_MONTH[m]
          if m == 2 and isLeap(year) then days += 1 end
        end
        days += day - 1
        local sign, offsetHour, offsetMinute = value:match("([+-])(%d%d):(%d%d)$")
        local offset = sign and (tonumber(offsetHour) * 60 + tonumber(offsetMinute)) * 60 or 0
        if sign == "-" then offset = -offset end
        epoch = days * 86400 + hour * 3600 + minute * 60 + second - offset
      end
    end
  end
  if not epoch then return "--" end
  local diff = epoch - os.time()
  if diff <= 0 then return "agora" end
  local days = math.floor(diff / 86400)
  local hours = math.floor((diff % 86400) / 3600)
  local minutes = math.floor((diff % 3600) / 60)
  if days > 0 then return `{days}d {hours}h` end
  if hours > 0 then return `{hours}h {minutes}min` end
  return `{math.max(1, minutes)}min`
end

local function savedProvider()
  local dir = noctalia.pluginDataDir()
  local raw = dir and noctalia.readFile(dir .. "/pinned-provider.json")
  local data = raw and noctalia.json.decode(raw)
  if data and (data.provider == "claude" or data.provider == "codex") then
    return data.provider
  end
  return "claude"
end

local function render()
  local provider = noctalia.state.get(PIN_KEY) or savedProvider()
  local claude = provider == "claude"
  local usage = noctalia.state.get(claude and "usage" or "codex") or {}
  local session = claude and usage.fiveHourPercent or usage.primaryPercent
  local week = claude and usage.sevenDayPercent or usage.secondaryPercent
  local sessionReset = claude and usage.fiveHourResetsAt or usage.primaryResetsAt
  local weekReset = claude and usage.sevenDayResetsAt or usage.secondaryResetsAt
  local warn = tonumber(noctalia.getConfig("warn_percent")) or 90

  local function percent(value)
    return value and (`{math.floor(value + 0.5)}%`) or "--"
  end

  local pluginDir = noctalia.pluginDir()
  if claude and pluginDir then
    barWidget.setImage(pluginDir .. "/claude-logo.svg", false, 17, 17)
  else
    barWidget.setGlyph(claude and "sparkles" or "brand-openai")
  end
  -- The bar may squeeze this capsule beside other widgets. The logo names
  -- the provider; the two numbers are session/week usage in that order.
  barWidget.setText(`{percent(session)} | {percent(week)}`)
  local color = ((session and session >= warn) or (week and week >= warn)) and "error" or "secondary"
  barWidget.setColor(color)
  barWidget.setGlyphColor(color)
  local tooltip = `{claude and "Claude" or "Codex"}\n5h {percent(session)} · reseta em {resetRemaining(sessionReset)}\n7d {percent(week)} · reseta em {resetRemaining(weekReset)}`
  if usage.error then
    tooltip = tooltip .. `\n{usage.error}`
  end
  barWidget.setTooltip(tooltip)
end

noctalia.state.watch(PIN_KEY, render)
noctalia.state.watch("usage", render)
noctalia.state.watch("codex", render)

function update()
  noctalia.setUpdateInterval(15000)
  if not noctalia.state.get(PIN_KEY) then
    noctalia.state.set(PIN_KEY, savedProvider())
  end
  render()
end

function onClick()
  noctalia.togglePanel("noirelab/claude-usage:picker")
end
