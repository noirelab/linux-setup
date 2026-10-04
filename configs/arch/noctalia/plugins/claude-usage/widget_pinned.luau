--!nonstrict
-- One bar item for the provider selected in the picker panel.

local PIN_KEY = "pinned_provider"

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
  local warn = tonumber(noctalia.getConfig("warn_percent")) or 90

  local function percent(value)
    return value and (`{math.floor(value + 0.5)}%`) or "--"
  end

  barWidget.setGlyph(claude and "sparkles" or "brand-openai")
  barWidget.setText(`{claude and "Claude" or "Codex"} 5h {percent(session)} · 7d {percent(week)}`)
  local color = ((session and session >= warn) or (week and week >= warn)) and "error" or "secondary"
  barWidget.setColor(color)
  barWidget.setGlyphColor(color)
  local tooltip = `{claude and "Claude" or "Codex"} · sessão {percent(session)} · semana {percent(week)} · clique para fixar outro`
  if usage.error then
    tooltip = tooltip .. ` · {usage.error}`
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
