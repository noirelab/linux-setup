--!nonstrict
-- Bar widget: sticky-note icon that toggles the notes panel.

function update()
  noctalia.setUpdateInterval(60000)
  barWidget.setGlyph("notes")
  barWidget.setTooltip(noctalia.tr("widget.tooltip"))
end

function onClick()
  noctalia.togglePanel("noirelab/notepad:panel")
end
