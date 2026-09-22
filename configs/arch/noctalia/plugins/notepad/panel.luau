--!nonstrict
-- Sticky notes panel styled with the shell palette. List view shows
-- compact note cards (click to open); the editor is a full-surface
-- multiline input with idle autosave (flush after a short pause in
-- typing, on navigation, and on panel close). Notes persist to
-- pluginDataDir()/notes.json.

local ACCENTS = { "primary", "secondary", "tertiary", "error" }
local AUTOSAVE_IDLE_TICKS = 2 -- 1s panel ticks with no edits before a flush
local MAX_PREVIEW_LINES = 4

local VIMIUM_BODY = table.concat({
  "f → mostra letras em tudo que dá pra clicar",
  "F → igual ao f, mas abre o link em nova aba",
  "j → desce a página",
  "k → sobe a página",
  "d → desce meia tela",
  "u → sobe meia tela",
  "gg → vai pro topo",
  "G → vai pro fim",
  "/ → pesquisa texto na página",
  "n → próximo resultado da pesquisa",
  "N → resultado anterior",
  "r → recarrega a página",
  "H → voltar",
  "L → avançar",
  "x → fecha a aba atual",
  "X → reabre a última aba fechada",
  "t → nova aba",
  "J → aba da esquerda",
  "K → aba da direita",
  "? → abre a lista completa de atalhos",
}, "\n")

local dataPath
local notes = {}      -- array of { id, title, body, color }
local nextId = 1

local view = "list"   -- "list" | "editor"
local current = nil   -- id da nota aberta no editor
local buffer = ""     -- corpo (input uncontrolled)
local titleBuffer = "" -- título (input uncontrolled)
local dirty = false
local idleTicks = 0
local pendingDelete = false
local render

local function tr(key, subst)
  return noctalia.tr(key, subst)
end

local function save()
  local ok, err = noctalia.writeFile(dataPath, noctalia.json.encode(notes))
  if not ok then
    noctalia.notifyError(tr("app.name"), err or "failed to save")
  end
end

local function seed()
  notes = {}
  if noctalia.getConfig("seed_vimium") ~= false then
    notes[1] = { id = 1, title = "Vimium", body = VIMIUM_BODY, color = 1 }
    nextId = 2
    save()
  end
end

local function load()
  local dir = noctalia.pluginDataDir()
  if dir == nil then
    noctalia.notifyError(tr("app.name"), tr("panel.err_data_dir"))
    return
  end
  dataPath = dir .. "/notes.json"
  local raw = noctalia.readFile(dataPath)
  if raw then
    local decoded = noctalia.json.decode(raw)
    if type(decoded) == "table" and #decoded > 0 then
      notes = {}
      for _, n in ipairs(decoded) do
        if type(n) == "table" and type(n.id) == "number" then
          table.insert(notes, {
            id = n.id,
            title = type(n.title) == "string" and n.title or "",
            body = type(n.body) == "string" and n.body or "",
            color = type(n.color) == "number" and math.clamp(n.color, 1, #ACCENTS) or 1,
          })
          if n.id >= nextId then
            nextId = n.id + 1
          end
        end
      end
      return
    end
  end
  seed()
end

local function findNote(id)
  for _, n in ipairs(notes) do
    if n.id == id then
      return n
    end
  end
end

local function flush()
  if not dirty or current == nil then
    return
  end
  local note = findNote(current)
  if note ~= nil then
    note.title = titleBuffer
    note.body = buffer
  end
  save()
  dirty = false
end

local function openNote(id)
  flush()
  local note = findNote(id)
  if not note then
    return
  end
  current = id
  titleBuffer = note.title
  buffer = note.body
  view = "editor"
  dirty = false
  idleTicks = 0
  pendingDelete = false
  render()
end

local function backToList()
  flush()
  view = "list"
  current = nil
  buffer = ""
  titleBuffer = ""
  dirty = false
  pendingDelete = false
  render()
end

local function editorStatusLine()
  local words = select(2, buffer:gsub("%S+", ""))
  local chars = utf8.len(buffer) or #buffer
  local status = dirty and tr("panel.editing") or tr("panel.saved")
  return status .. "  ·  " .. tr("panel.counts", { words = words, chars = chars })
end

local function editorHeader()
  local note = findNote(current)
  if not note then
    return ui.row({})
  end
  local trailing
  if pendingDelete then
    trailing = {
      ui.label({ text = tr("panel.confirm_delete"), color = "error" }),
      ui.button({ glyph = "check", variant = "primary", onClick = "onConfirmDelete" }),
      ui.button({ glyph = "close", variant = "ghost", onClick = function()
        pendingDelete = false
        render()
      end }),
    }
  else
    trailing = {
      ui.button({ glyph = "palette", variant = "ghost", tooltip = tr("panel.color"), onClick = "onCycleColor" }),
      ui.button({ glyph = "trash", variant = "ghost", tooltip = tr("panel.delete"), onClick = function()
        pendingDelete = true
        render()
      end }),
    }
  end
  local children = {
    ui.button({ glyph = "arrow-left", variant = "ghost", tooltip = tr("panel.back"), onClick = "onBack" }),
    ui.input({
      key = "edit-title-" .. note.id,
      value = titleBuffer,
      placeholder = tr("panel.untitled"),
      flexGrow = 1,
      onChange = "onTitleEdited",
    }),
  }
  for _, node in ipairs(trailing) do
    table.insert(children, node)
  end
  return ui.row({ gap = 6, align = "center" }, children)
end

local function editorView()
  return ui.column({ flexGrow = 1, gap = 8, align = "stretch" }, {
    editorHeader(),
    ui.input({
      key = "editor-" .. current,
      value = buffer,
      multiline = true,
      focus = true,
      flexGrow = 1,
      placeholder = tr("panel.body_placeholder"),
      onChange = "onEdited",
      onSubmit = "onFlushNow",
    }),
    ui.label({ text = editorStatusLine(), fontSize = 11, color = "on_surface_variant" }),
  })
end

local function listCard(note)
  local accent = ACCENTS[note.color] or ACCENTS[1]
  local title = note.title ~= "" and note.title or tr("panel.untitled")
  local rows = {}
  local count = 0
  for line in string.gmatch(note.body, "[^\n]+") do
    count += 1
    if count > MAX_PREVIEW_LINES then
      table.insert(rows, ui.label({ text = "…", fontSize = 13, color = "outline" }))
      break
    end
    table.insert(rows, ui.label({ text = line, fontSize = 13, color = "on_surface_variant", maxLines = 1 }))
  end
  if count == 0 then
    table.insert(rows, ui.label({ text = tr("panel.empty_body"), fontSize = 13, color = "outline" }))
  end
  return ui.column({
    key = "card-" .. note.id,
    fill = "surface_variant/0.5",
    radius = 12,
    border = "outline/0.15",
    borderWidth = 1,
    padding = 12,
    gap = 8,
    onClick = function()
      openNote(note.id)
    end,
  }, {
    ui.row({ gap = 8, align = "center" }, {
      ui.box({ width = 10, height = 10, radius = 5, fill = accent, opacity = 0.9 }),
      ui.label({ text = title, fontSize = 13, fontWeight = "bold", color = "on_surface", flexGrow = 1, maxLines = 1 }),
    }),
    ui.separator({ thickness = 1, color = "outline/0.25", spacing = 0 }),
    ui.column({ gap = 3 }, rows),
  })
end

local function listView()
  local cards = {}
  for _, note in ipairs(notes) do
    table.insert(cards, listCard(note))
  end
  if #cards == 0 then
    table.insert(cards, ui.column({ align = "center", gap = 8, paddingV = 32 }, {
      ui.glyph({ name = "notes", size = 36, color = "outline" }),
      ui.label({ text = tr("panel.empty"), color = "outline", fontSize = 13 }),
    }))
  end
  return ui.scroll({ flexGrow = 1, gap = 8 }, cards)
end

render = function()
  local isEditor = view == "editor" and current ~= nil
  local header = {
    ui.label({ text = tr("panel.title"), fontSize = 16, fontWeight = "bold", color = "on_surface", flexGrow = 1 }),
  }
  if not isEditor then
    table.insert(header, ui.button({ key = "header-new", glyph = "plus", variant = "primary", tooltip = tr("panel.new"), onClick = "onNewNote" }))
    table.insert(header, ui.button({ key = "header-close", glyph = "close", variant = "ghost", tooltip = tr("panel.close"), onClick = "onClosePanel" }))
  end
  panel.render(ui.column({ flexGrow = 1, gap = 12, align = "stretch" }, {
    ui.row({ align = "center", gap = 8 }, header),
    isEditor and editorView() or listView(),
  }))
end

function onNewNote()
  flush()
  local id = nextId
  nextId += 1
  table.insert(notes, { id = id, title = "", body = "", color = ((id - 1) % #ACCENTS) + 1 })
  save()
  openNote(id)
end

function onTitleEdited(value)
  titleBuffer = value
  dirty = true
  idleTicks = 0
  render()
end

function onEdited(value)
  buffer = value
  dirty = true
  idleTicks = 0
  render()
end

function onFlushNow(value)
  buffer = value
  dirty = true
  flush()
  render()
end

function onBack()
  backToList()
end

function onClosePanel()
  panel.close()
end

function onConfirmDelete()
  if current ~= nil then
    for i, n in ipairs(notes) do
      if n.id == current then
        table.remove(notes, i)
        break
      end
    end
    save()
  end
  current = nil
  buffer = ""
  titleBuffer = ""
  dirty = false
  view = "list"
  pendingDelete = false
  render()
end

function onCycleColor()
  local note = findNote(current)
  if note ~= nil then
    note.color = (note.color % #ACCENTS) + 1
    save()
    render()
  end
end

function onOpen()
  load()
  view = "list"
  current = nil
  buffer = ""
  titleBuffer = ""
  dirty = false
  pendingDelete = false
  panel.setWantsSecondTicks(true)
  render()
end

function onClose()
  flush()
end

function update()
  if dirty then
    idleTicks += 1
    if idleTicks >= AUTOSAVE_IDLE_TICKS then
      flush()
      render()
    end
  end
end
