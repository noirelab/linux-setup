--!nonstrict
-- Choose which provider's session and weekly usage stays in the bar.

local PIN_KEY = "pinned_provider"
local render

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
  local function pct(value)
    return value and (`{math.floor(value + 0.5)}%`) or "--"
  end
  return `5h {pct(session)}  ·  7d {pct(week)}`
end

local function choice(key, title, glyph)
  local active = provider() == key
  return ui.row({ align = "center", gap = 10 }, {
    ui.glyph({ name = glyph, size = 22, color = active and "primary" or "secondary" }),
    ui.column({ flexGrow = 1, gap = 2 }, {
      ui.label({ text = title, fontWeight = "bold", color = "on_surface" }),
      ui.label({ text = summary(key), fontSize = 12, color = "on_surface_variant" }),
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
  noctalia.state.set(PIN_KEY, provider())
  render()
end
