--!nonstrict
-- Choose which provider's session and weekly usage stays in the bar.

local PIN_KEY = "pinned_provider"
local render
local lastMinute
local panelOpen = false
local clockIconColor
local clockIconFile

local function clockIconPath()
  local color = (noctalia.getColor and noctalia.getColor("on_surface_variant")) or "#9298a0"
  if clockIconColor == color and clockIconFile then return clockIconFile end
  local pluginDir = noctalia.pluginDir()
  local dataDir = noctalia.pluginDataDir()
  local svg = pluginDir and noctalia.readFile(pluginDir .. "/clock-lucide.svg")
  if not svg or not dataDir then return nil end
  noctalia.mkdirAll(dataDir)
  local path = dataDir .. "/clock-lucide-" .. color:gsub("#", "") .. ".svg"
  local ok = noctalia.writeFile(path, svg:gsub("currentColor", color, 1))
  if not ok then return nil end
  clockIconColor = color
  clockIconFile = path
  return path
end

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

local function provider()
  local current = noctalia.state.get(PIN_KEY)
  if current == "claude" or current == "codex" then
    return current
  end
  local dir = noctalia.pluginDataDir()
  local raw = dir and noctalia.readFile(dir .. "/pinned-provider.json")
  local data = raw and noctalia.json.decode(raw)
  return data and data.provider == "codex" and "codex" or "claude"
end

local function summary(key)
  local data = noctalia.state.get(key == "claude" and "usage" or "codex") or {}
  local session = key == "claude" and data.fiveHourPercent or data.primaryPercent
  local week = key == "claude" and data.sevenDayPercent or data.secondaryPercent
  local sessionReset = key == "claude" and data.fiveHourResetsAt or data.primaryResetsAt
  local weekReset = key == "claude" and data.sevenDayResetsAt or data.secondaryResetsAt
  local function pct(value)
    return value and (`{math.floor(value + 0.5)}%`) or "--"
  end
  return `5h {pct(session)}  ·  7d {pct(week)}`, `5h {resetRemaining(sessionReset)}  ·  7d {resetRemaining(weekReset)}`
end

local function choice(key, title, glyph)
  local active = provider() == key
  local usageText, resetText = summary(key)
  local clockPath = clockIconPath()
  local pluginDir = noctalia.pluginDir()
  local claudeIcon = key == "claude" and pluginDir and (pluginDir .. "/claude-logo.svg") or nil
  return ui.row({ align = "center", gap = 10 }, {
    claudeIcon and ui.image({ path = claudeIcon, width = 22, height = 22, fit = "contain" })
      or ui.glyph({ name = glyph, size = 22, color = active and "primary" or "secondary" }),
    ui.column({ flexGrow = 1, gap = 2 }, {
      ui.label({ text = title, fontWeight = "bold", color = "on_surface" }),
      ui.label({ text = usageText, fontSize = 12, color = "on_surface_variant" }),
      ui.row({ align = "center", gap = 4 }, {
        clockPath and ui.image({ path = clockPath, width = 13, height = 13, fit = "contain" })
          or ui.glyph({ name = "clock", size = 13, color = "on_surface_variant" }),
        ui.label({ text = resetText, fontSize = 11, color = "on_surface_variant" }),
      }),
    }),
    ui.button({
      text = active and "Fixado" or "Fixar",
      variant = active and "primary" or "ghost",
      onClick = function()
        onPin(key)
      end,
    }),
  })
end

noctalia.state.watch("usage", function() if panelOpen then render() end end)
noctalia.state.watch("codex", function() if panelOpen then render() end end)

render = function()
  panel.render(ui.column({ gap = 14, align = "stretch" }, {
    ui.row({ align = "center", gap = 8 }, {
      ui.label({ text = "Fixar na barra", fontSize = 16, fontWeight = "bold", flexGrow = 1 }),
      ui.button({ glyph = "close", variant = "ghost", onClick = "onClosePanel" }),
    }),
    choice("claude", "Claude", "sparkles"),
    choice("codex", "Codex", "brand-openai"),
    ui.label({ text = "DeepSeek desativado por enquanto", fontSize = 11, color = "outline" }),
  }))
end

function onPin(key)
  if key ~= "claude" and key ~= "codex" then
    return
  end
  local dir = noctalia.pluginDataDir()
  if not dir then
    noctalia.notifyError("Usage", "Não foi possível abrir os dados do plugin")
    return
  end
  noctalia.mkdirAll(dir)
  local ok, err = noctalia.writeFile(dir .. "/pinned-provider.json", noctalia.json.encode({ provider = key }))
  if not ok then
    noctalia.notifyError("Usage", err or "Não foi possível salvar a escolha")
    return
  end
  noctalia.state.set(PIN_KEY, key)
  render()
end

function onClosePanel()
  panel.close()
end

function onOpen()
  panelOpen = true
  noctalia.state.set(PIN_KEY, provider())
  lastMinute = math.floor(os.time() / 60)
  panel.setWantsSecondTicks(true)
  render()
end

function onClose()
  panelOpen = false
end

function update()
  if not panelOpen then return end
  local minute = math.floor(os.time() / 60)
  if minute ~= lastMinute then
    lastMinute = minute
    render()
  end
end
