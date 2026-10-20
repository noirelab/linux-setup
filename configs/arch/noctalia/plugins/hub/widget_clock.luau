--!nonstrict
-- Data e hora no centro da barra, em portugues, sem fundo. O clique abre o painel.

local DAYS = { "Domingo", "Segunda-feira", "Terça-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira", "Sábado" }
local MONTHS = {
  "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
  "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro",
}

-- Largura das duas caixas laterais. Iguais, para a hora ficar sempre no centro do widget
-- (e portanto no centro da tela), independente do tamanho do texto da data.
local SIDE = 230

local function render()
  local t = os.date("*t")
  barWidget.render(ui.row({ align = "center", gap = 10 }, {
    ui.spacer({ width = SIDE }),
    ui.label({ text = string.format("%02d:%02d", t.hour, t.min), fontSize = 14, fontWeight = "bold", color = "on_surface" }),
    ui.row({ width = SIDE, align = "center", justify = "start" }, {
      ui.label({
        text = string.format("%s, %d de %s", DAYS[t.wday], t.day, MONTHS[t.month]),
        fontSize = 13,
        maxLines = 1,
        color = "on_surface_variant",
      }),
    }),
  }))
end

function update()
  noctalia.setUpdateInterval(15000)
  render()
end

function onClick()
  noctalia.togglePanel("noirelab/hub:home")
end

function onRightClick()
  noctalia.togglePanel("noirelab/hub:home")
end
