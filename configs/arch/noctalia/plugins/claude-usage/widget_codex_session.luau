--!nonstrict
-- Bar widget: current Codex primary rate-limit window (5-hour session),
-- matching what Codex's /status shows as the 5h limit.

local function formatRemaining(epochSeconds)
  if not epochSeconds then
    return "?"
  end
  local diff = epochSeconds - os.time()
  if diff <= 0 then
    return "agora"
  end
  local days = math.floor(diff / 86400)
  local hours = math.floor((diff % 86400) / 3600)
  local mins = math.floor((diff % 3600) / 60)
  if days > 0 then
    return `{days}d {hours}h`
  elseif hours > 0 then
    return `{hours}h {mins}min`
  else
    return `{mins}min`
  end
end

local function creditSuffix(c)
  if not c.unlimited and not c.creditBalance then
    return ""
  end
  if c.unlimited then
    return " · créditos ilimitados"
  end
  return ` · créditos {c.creditBalance}`
end

local function render()
  local u = noctalia.state.get("codex")
  local showLabel = noctalia.getConfig("show_label")
  local warnPercent = tonumber(noctalia.getConfig("warn_percent")) or 90

  barWidget.setGlyph("brand-openai")

  if not u or (not u.primaryPercent and u.error) then
    barWidget.setText("--")
    barWidget.setColor("secondary")
    barWidget.setGlyphColor("secondary")
    barWidget.setTooltip(`Codex · sessão (5h): {(u and u.error) or "carregando..."}`)
    return
  end

  local pct = u.primaryPercent
  local pctText = pct and `{math.floor(pct + 0.5)}%` or "--"

  if showLabel then
    barWidget.setText(`5h {pctText}`)
  else
    barWidget.setText(pctText)
  end

  local isWarn = pct and pct >= warnPercent
  barWidget.setColor(isWarn and "error" or "secondary")
  barWidget.setGlyphColor(isWarn and "error" or "secondary")

  local tooltip = `Codex · sessão (5h): {pctText} — reseta em {formatRemaining(u.primaryResetsAt)}`
  if u.planType then
    tooltip = tooltip .. ` · plano {u.planType}`
  end
  tooltip = tooltip .. creditSuffix(u)
  if u.rateLimited then
    tooltip = tooltip .. ` · {u.error}`
  end
  barWidget.setTooltip(tooltip)
end

noctalia.state.watch("codex", render)

function update()
  noctalia.setUpdateInterval(15000)
  render()
end

function onClick()
  local u = noctalia.state.get("codex")
  if u and u.error then
    noctalia.notifyError("Codex Usage", u.error)
  else
    render()
  end
end
