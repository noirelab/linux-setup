--!nonstrict
-- Bar widget: current DeepSeek account balance, formatted with the
-- account's currency symbol, switching to the warning color when the
-- balance drops at or below the low_balance threshold.

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
  local showLabel = noctalia.getConfig("show_label")
  local lowBalance = tonumber(noctalia.getConfig("low_balance")) or 0.5

  barWidget.setGlyph("coins")

  if not b or (not b.totalBalance and b.error) then
    barWidget.setText("--")
    barWidget.setColor("secondary")
    barWidget.setGlyphColor("secondary")
    barWidget.setTooltip(`DeepSeek: {(b and b.error) or "carregando..."}`)
    return
  end

  local amount = formatMoney(b.totalBalance, b.currency)
  if showLabel then
    barWidget.setText("DS " .. amount)
  else
    barWidget.setText(amount)
  end

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
