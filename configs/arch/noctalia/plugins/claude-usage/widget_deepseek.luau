--!nonstrict
-- Bar widget: current DeepSeek account balance, formatted with the
-- account's currency symbol, switching to the warning color when the
-- balance drops at or below the low_balance threshold. Identified by the
-- DeepSeek whale instead of a "DS" text prefix.

local WHALE_FILE = "deepseek-whale.svg"

-- The whale follows the theme's "secondary" role so it matches the text
-- next to it. barWidget images cannot take a palette role, so resolve the
-- hex from the active palette and bake it into a copy of the bundled SVG.
local FALLBACK_SECONDARY = { dark = "#8ea49e", light = "#6f8795" }

local function pluginFile(name)
  local dir = noctalia.pluginDir()
  return dir and (dir .. "/" .. name) or nil
end

local function stateHome()
  local custom = noctalia.getenv("NOCTALIA_STATE_HOME")
  if custom and custom ~= "" then
    return custom
  end
  local home = noctalia.getenv("HOME")
  if not home or home == "" then
    return nil
  end
  return home .. "/.local/state/noctalia"
end

local function paletteSecondary(dark)
  local modeKey = dark and "dark" or "light"
  if noctalia.getSetting then
    local source = noctalia.getSetting("theme.source")
    if source == "community" then
      local name = noctalia.getSetting("theme.community_palette")
      local dir = stateHome()
      if name and name ~= "" and dir then
        local encoded = (name:gsub(" ", "%%20"))
        local contents = noctalia.readFile(dir .. "/community-palettes/" .. encoded .. ".json")
        if contents then
          local data = noctalia.json.decode(contents)
          local color = data and data[modeKey] and data[modeKey].mSecondary
          if color then
            return color
          end
        end
      end
    end
  end
  return FALLBACK_SECONDARY[modeKey]
end

local iconColor
local iconPath
local function whaleIconPath()
  local dark = true
  if noctalia.isDarkMode then
    dark = noctalia.isDarkMode() == true
  end
  local color = paletteSecondary(dark)
  if iconPath and iconColor == color then
    return iconPath
  end

  local template = pluginFile(WHALE_FILE)
  local svg = template and noctalia.readFile(template)
  local dataDir = noctalia.pluginDataDir()
  if not svg or not dataDir then
    return nil
  end

  noctalia.mkdirAll(dataDir)
  svg = svg:gsub("currentColor", color, 1)
  local outPath = dataDir .. "/deepseek-whale-" .. color:gsub("#", "") .. ".svg"
  local ok = noctalia.writeFile(outPath, svg)
  if not ok then
    return nil
  end

  iconColor = color
  iconPath = outPath
  return outPath
end

local CURRENCY_SYMBOLS = {
  USD = "$",
  CNY = "¥",
  EUR = "€",
  GBP = "£",
  JPY = "¥",
}

local function formatMoney(value, currency)
  if not value then
    return "?"
  end
  local text = string.format("%.2f", value)
  if text:find("%.") then
    text = text:gsub("%.?0+$", "")
  end
  local symbol = CURRENCY_SYMBOLS[currency] or (currency and (currency .. " ") or "")
  return symbol .. text
end

local function render()
  local b = noctalia.state.get("deepseek")
  local lowBalance = tonumber(noctalia.getConfig("low_balance")) or 0.5

  local path = whaleIconPath()
  if path and noctalia.fileExists(path) then
    barWidget.setImage(path, true, 16, 16)
  else
    barWidget.setGlyph("fish")
  end

  if not b or (not b.totalBalance and b.error) then
    barWidget.setText("--")
    barWidget.setColor("secondary")
    barWidget.setGlyphColor("secondary")
    barWidget.setTooltip(`DeepSeek: {(b and b.error) or "carregando..."}`)
    return
  end

  local amount = formatMoney(b.totalBalance, b.currency)
  barWidget.setText(amount)

  local isLow = b.isAvailable == false
    or (b.totalBalance ~= nil and b.totalBalance < lowBalance)
  barWidget.setColor(isLow and "error" or "secondary")
  barWidget.setGlyphColor(isLow and "error" or "secondary")

  local tooltip = `DeepSeek · saldo: {amount}`
  if b.grantedBalance then
    tooltip = tooltip .. ` (crédito {formatMoney(b.grantedBalance, b.currency)})`
  end
  if b.isAvailable == false then
    tooltip = tooltip .. " — sem créditos disponíveis"
  end
  if b.rateLimited then
    tooltip = tooltip .. ` · {b.error}`
  end
  barWidget.setTooltip(tooltip)
end

noctalia.state.watch("deepseek", render)

function update()
  noctalia.setUpdateInterval(15000)
  render()
end

function onClick()
  local b = noctalia.state.get("deepseek")
  if b and b.error then
    noctalia.notifyError("DeepSeek Balance", b.error)
  else
    render()
  end
end
