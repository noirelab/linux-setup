--!nonstrict
-- Bar widget: current Claude Code weekly (7-day) usage, shown next to the
-- 5-hour session widget so both are visible at once.

local function isLeap(y)
  return (y % 4 == 0 and y % 100 ~= 0) or (y % 400 == 0)
end

local DAYS_IN_MONTH = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

local function isoUtcToEpoch(iso)
  if not iso then
    return nil
  end
  local y, mo, d, h, mi, s = iso:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
  if not y then
    return nil
  end
  y, mo, d, h, mi, s = tonumber(y), tonumber(mo), tonumber(d), tonumber(h), tonumber(mi), tonumber(s)

  local days = 0
  if y >= 1970 then
    for yy = 1970, y - 1 do
      days += isLeap(yy) and 366 or 365
    end
  else
    for yy = y, 1969 do
      days -= isLeap(yy) and 366 or 365
    end
  end
  for m = 1, mo - 1 do
    days += DAYS_IN_MONTH[m]
    if m == 2 and isLeap(y) then
      days += 1
    end
  end
  days += d - 1

  return days * 86400 + h * 3600 + mi * 60 + s
end

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

local function render()
  local u = noctalia.state.get("usage")
  local showLabel = noctalia.getConfig("show_label")
  local warnPercent = tonumber(noctalia.getConfig("warn_percent")) or 90

  barWidget.setGlyph("calendar-week")

  if not u or (not u.sevenDayPercent and u.error) then
    barWidget.setText("--")
    barWidget.setColor("secondary")
    barWidget.setGlyphColor("secondary")
    barWidget.setTooltip(`Claude · semana (7d): {(u and u.error) or "carregando..."}`)
    return
  end

  local pct = u.sevenDayPercent
  local pctText = pct and `{math.floor(pct + 0.5)}%` or "--"

  if showLabel then
    barWidget.setText(`7d {pctText}`)
  else
    barWidget.setText(pctText)
  end

  local isWarn = pct and pct >= warnPercent
  barWidget.setColor(isWarn and "error" or "secondary")
  barWidget.setGlyphColor(isWarn and "error" or "secondary")

  local resetEpoch = isoUtcToEpoch(u.sevenDayResetsAt)
  local tooltip = `Uso semanal (7d): {pctText} — reseta em {formatRemaining(resetEpoch)}`
  if u.rateLimited then
    tooltip = tooltip .. ` · {u.error}`
  end
  barWidget.setTooltip(tooltip)
end

noctalia.state.watch("usage", render)

function update()
  noctalia.setUpdateInterval(15000)
  render()
end

function onClick()
  local u = noctalia.state.get("usage")
  if u and u.error then
    noctalia.notifyError("Claude Usage", u.error)
  else
    render()
  end
end
