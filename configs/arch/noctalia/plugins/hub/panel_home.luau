--!nonstrict
-- Hub: Central de Controle do Nava OS, no lugar do menu nativo do Noctalia.
-- Inicio em tiles; tocar num tile abre o detalhe (Audio, Rede, Bluetooth, Notificacoes, Midia, Energia).
-- Estetica: vidro sobre azul-marinho, um acento so (azul-gelo), rosa e verde apenas para estado.
-- Leituras sem `noctalia msg` (derruba o shell de dentro de plugins); `msg` so em acoes de clique.

local HISTORY = 48
-- Altura comum dos dois cards de baixo do Inicio, para as bases alinharem
local BOTTOM_H = 132
local PROFILES = { "performance", "balanced", "power-saver" }
local PROFILE_LABEL = { ["performance"] = "Desempenho", ["balanced"] = "Equilibrado", ["power-saver"] = "Economia" }

local ACCENT = "#9fb6f0"
local ON_ACCENT = "#0b0d16"
local ROSE = "#f29bb0"
local SAGE = "#b5d3a8"

-- Camadas de vidro: base, elevado e a borda de luz
local TILE = "#ffffff10"
local TILE_RAISED = "#ffffff1c"
local EDGE = "#ffffff24"
local TRACK = "#ffffff14"

local VIEWS = { "home", "audio", "network", "bluetooth", "notifications", "media", "power", "calendar" }

local DAYS = { "Domingo", "Segunda-feira", "Terça-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira", "Sábado" }
local MONTHS = {
  "janeiro", "fevereiro", "março", "abril", "maio", "junho",
  "julho", "agosto", "setembro", "outubro", "novembro", "dezembro",
}

local view = "home"
local isOpen = false
local ticks = 0
local holdUntil = 0
local cpuHistory = {}
local render

local s = {
  -- inicio
  wifi = false, ssid = "", bluetooth = false, dnd = false, caffeine = false, nightlight = false,
  -- volume e brilho ficam nil ate a primeira leitura, para nao piscar 0% ao abrir
  profile = "balanced", volume = nil, muted = false, brightness = nil,
  time = "--:--", date = "", uptime = "", host = "", user = "", fullname = "",
  -- audio
  out = { name = "", volume = 0, muted = false }, inp = { name = "", volume = 0, muted = false }, apps = {},
  -- rede
  netCurrent = nil, networks = {}, netMsg = "", ip = "",
  -- bluetooth
  btDevices = {},
  -- notificacoes
  notifs = {}, notifTab = "all",
  -- midia
  media = nil, artPath = nil, artUrl = "",
  -- energia
  batteryPct = nil, batteryStatus = "",
}

local function sh(cmd, cb)
  noctalia.runAsync(cmd, function(r)
    if not cb then return end
    local ok, err = pcall(cb, r.stdout or "", r.exitCode)
    if not ok then noctalia.notifyError("Hub", tostring(err)) end
  end)
end

local function trim(text)
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function clamp01(v) return math.clamp(v or 0, 0, 1) end

local function pctNumber(volumeTable)
  if type(volumeTable) ~= "table" then return 0 end
  for _, ch in pairs(volumeTable) do
    local p = type(ch) == "table" and ch.value_percent
    if p then return tonumber(p:match("(%d+)")) or 0 end
  end
  return 0
end

-- ---------- Leituras ----------

local refreshMedia
local refreshCalendar

local function refreshHome()
  sh("nmcli radio wifi", function(out) s.wifi = trim(out) == "enabled" end)
  sh("LC_ALL=C nmcli -t -f active,ssid dev wifi list --rescan no", function(out) s.ssid = out:match("yes:([^\n]*)") or "" end)
  sh("bluetoothctl show", function(out) s.bluetooth = out:find("Powered: yes", 1, true) ~= nil end)
  sh("powerprofilesctl get", function(out)
    local v = trim(out)
    if v ~= "" then s.profile = v end
  end)
  sh("wpctl get-volume @DEFAULT_AUDIO_SINK@", function(out)
    local v = tonumber(out:match("Volume:%s*([%d%.]+)"))
    if v then s.volume = math.floor(v * 100 + 0.5) end
    s.muted = out:find("MUTED", 1, true) ~= nil
  end)
  -- Formato: dispositivo,classe,atual,NN%,max
  sh("brightnessctl -m", function(out)
    local p = tonumber(out:match("^[^,]*,[^,]*,[^,]*,(%d+)%%"))
    if p then s.brightness = p end
  end)
  refreshMedia()
end

local function refreshClock()
  local t = os.date("*t")
  s.time = string.format("%02d:%02d", t.hour, t.min)
  s.date = string.format("%s, %d de %s", DAYS[t.wday], t.day, MONTHS[t.month])
  local raw = noctalia.readFile("/proc/uptime")
  local secs = raw and tonumber(raw:match("^(%d+)"))
  if secs then
    local h, m = math.floor(secs / 3600), math.floor((secs % 3600) / 60)
    s.uptime = h > 0 and `{h}h {m}min` or `{m}min`
  end
end

local function refreshAudio()
  local script = "pactl get-default-sink; pactl get-default-source; echo '###'; pactl -f json list sinks; echo '###'; "
    .. "pactl -f json list sources; echo '###'; pactl -f json list sink-inputs"
  sh(script, function(out)
    local head, sinks, sources, inputs = out:match("^(.-)###\n(.-)###\n(.-)###\n(.*)$")
    if not head then return end
    local defSink, defSource = head:match("^([^\n]*)\n([^\n]*)")
    local function pick(json, default)
      local list = noctalia.json.decode(json)
      if type(list) ~= "table" then return nil end
      for _, d in ipairs(list) do
        if d.name == default then return d end
      end
      return list[1]
    end
    local sk = pick(sinks, defSink)
    if sk then s.out = { name = sk.description or sk.name or "", volume = pctNumber(sk.volume), muted = sk.mute == true } end
    local sc = pick(sources, defSource)
    if sc then s.inp = { name = sc.description or sc.name or "", volume = pctNumber(sc.volume), muted = sc.mute == true } end
    local list = noctalia.json.decode(inputs)
    local apps = {}
    if type(list) == "table" then
      for _, a in ipairs(list) do
        local props = a.properties or {}
        table.insert(apps, {
          index = a.index,
          name = props["application.name"] or props["media.name"] or "App",
          volume = pctNumber(a.volume),
          muted = a.mute == true,
        })
      end
    end
    s.apps = apps
  end)
end

local function splitEscaped(line)
  line = line:gsub("\\:", "\1")
  local out = {}
  for field in (line .. ":"):gmatch("([^:]*):") do
    table.insert(out, (field:gsub("\1", ":")))
  end
  return out
end

local function refreshNetwork()
  sh("nmcli radio wifi", function(out) s.wifi = trim(out) == "enabled" end)
  sh("LC_ALL=C nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY,FREQ dev wifi list; echo '###'; "
    .. "ip -4 -o addr show scope global | awk '{print $4}' | head -1 | cut -d/ -f1", function(out)
    local list, ip = out:match("^(.-)###\n(.*)$")
    if not list then return end
    s.ip = trim(ip):match("^(%S+)") or ""
    local best, current = {}, nil
    for line in list:gmatch("[^\n]+") do
      local f = splitEscaped(line)
      local ssid = f[2]
      if ssid and ssid ~= "" then
        local entry = { ssid = ssid, signal = tonumber(f[3]) or 0, secure = (f[4] or "") ~= "" and f[4] ~= "--", freq = f[5] or "", active = f[1] == "*" }
        if entry.active then current = entry end
        local prev = best[ssid]
        if not prev or entry.active or (not prev.active and entry.signal > prev.signal) then best[ssid] = entry end
      end
    end
    local arr = {}
    for _, e in pairs(best) do table.insert(arr, e) end
    table.sort(arr, function(a, b)
      if a.active ~= b.active then return a.active end
      return a.signal > b.signal
    end)
    s.networks, s.netCurrent = arr, current
  end)
end

local function refreshBluetooth()
  local script = "bluetoothctl show | grep -q 'Powered: yes' && echo POWER=1 || echo POWER=0; "
    .. "bluetoothctl devices Paired | while read -r _ mac name; do "
    .. "c=$(bluetoothctl info \"$mac\" | grep -c 'Connected: yes'); echo \"DEV|$mac|$c|$name\"; done"
  sh(script, function(out)
    s.bluetooth = out:find("POWER=1", 1, true) ~= nil
    local devices = {}
    for mac, c, name in out:gmatch("DEV|([^|]+)|(%d)|([^\n]*)") do
      table.insert(devices, { mac = mac, connected = c == "1", name = name })
    end
    s.btDevices = devices
  end)
end

local function refreshNotifications()
  local dir = noctalia.getenv("HOME") or ""
  local raw = noctalia.readFile(dir .. "/.local/state/noctalia/notification_history.json")
  local data = raw and noctalia.json.decode(raw)
  local list = {}
  if type(data) == "table" and type(data.entries) == "table" then
    for i = #data.entries, 1, -1 do
      local n = data.entries[i].notification
      if type(n) == "table" and n.summary then
        table.insert(list, { app = n.app_name or "", summary = n.summary or "", body = n.body or "", at = (n.received_wall_ms or 0) / 1000 })
      end
      if #list >= 60 then break end
    end
  end
  s.notifs = list
end

local refreshMediaOf

local function playerLabel(name)
  local base = name:match("^([^.]+)") or name
  return base:sub(1, 1):upper() .. base:sub(2)
end

refreshMedia = function()
  noctalia.runAsync({ "playerctl", "-a", "metadata", "--format", "{{playerInstance}}|{{xesam:url}}" }, function(lr)
    local list = {}
    for line in (lr.stdout or ""):gmatch("[^\n]+") do
      local name, url = line:match("^(.-)|(.*)$")
      -- WhatsApp Web registra como player e atrapalha: fica fora da lista
      if name and not url:find("web.whatsapp.com", 1, true) then list[#list + 1] = name end
    end
    s.players = list
    local found = false
    for _, n in ipairs(list) do if n == s.player then found = true end end
    if not found then s.player = list[1] end
    if not s.player then
      s.media = nil
      return
    end
    refreshMediaOf(s.player)
  end)
end

refreshMediaOf = function(player)
  -- Separador \31 (unit separator): "|" aparece em titulos e deslocava os campos
  local fmt = "{{status}}\31{{title}}\31{{artist}}\31{{album}}\31{{mpris:artUrl}}\31{{position}}\31{{mpris:length}}"
  noctalia.runAsync({ "playerctl", "-p", player, "metadata", "--format", fmt }, function(r)
    if r.exitCode ~= 0 then
      s.media = nil
      return
    end
    local status, title, artist, album, art, pos, len = trim(r.stdout or ""):match("^(.-)\31(.-)\31(.-)\31(.-)\31(.-)\31(.-)\31(.*)$")
    if not status then
      s.media = nil
      return
    end
    s.media = {
      status = status, title = title, artist = artist, album = album,
      position = (tonumber(pos) or 0) / 1000000, length = (tonumber(len) or 0) / 1000000,
    }
    if art == "" then
      s.artUrl, s.artPath = "", nil
    elseif art ~= s.artUrl then
      s.artUrl, s.artPath = art, nil
      local dir = noctalia.pluginDataDir()
      if art:sub(1, 8) == "file:///" then
        s.artPath = art:sub(8):gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
      -- A URL vem de qualquer player MPRIS: so http(s), sem redirect para outro protocolo
      elseif dir and art:match("^https?://") then
        noctalia.mkdirAll(dir)
        local hash = 0
        for i = 1, #art do hash = (hash * 31 + art:byte(i)) % 1000000007 end
        local path = `{dir}/art_{hash}.jpg`
        noctalia.runAsync({ "curl", "-sL", "--proto", "=http,https", "--proto-redir", "=http,https",
          "--max-time", "8", "--max-filesize", "5000000", "-o", path, "--", art }, function(res)
          -- Se a faixa mudou durante o download, esta capa ja nao vale
          if res.exitCode == 0 and s.artUrl == art then s.artPath = path end
        end)
      end
    end
  end)
end

local function refreshPower()
  local cap = noctalia.readFile("/sys/class/power_supply/BAT1/capacity")
  local st = noctalia.readFile("/sys/class/power_supply/BAT1/status")
  s.batteryPct = cap and tonumber(trim(cap)) or nil
  s.batteryStatus = st and trim(st) or ""
  sh("powerprofilesctl get", function(out)
    local v = trim(out)
    if v ~= "" then s.profile = v end
  end)
end

local function refreshView()
  if view == "home" then refreshHome(); refreshClock()
  elseif view == "audio" then refreshAudio()
  elseif view == "network" then refreshNetwork()
  elseif view == "bluetooth" then refreshBluetooth()
  elseif view == "notifications" then refreshNotifications()
  elseif view == "media" then refreshMedia()
  elseif view == "power" then refreshPower()
  elseif view == "calendar" then refreshCalendar() end
end

local REFRESH_EVERY = { home = 2, audio = 2, network = 6, bluetooth = 5, notifications = 5, media = 1, power = 5, calendar = 60 }

-- Uma amostra por tick (nao por render, que tambem roda em cliques).
-- Historico vazio comeca como linha reta no valor atual, em vez de grafico vazio
local function sampleCpu()
  local stats = noctalia.systemStats() or {}
  local v = clamp01((stats.cpu and stats.cpu.usagePercent or 0) / 100)
  if #cpuHistory == 0 then
    for _ = 1, HISTORY - 1 do table.insert(cpuHistory, v) end
  end
  table.insert(cpuHistory, v)
  while #cpuHistory > HISTORY do table.remove(cpuHistory, 1) end
end

-- ---------- Componentes ----------

local function surface(make, props, children)
  props.fill = props.fill or TILE
  props.border = props.border or EDGE
  props.borderWidth = props.borderWidth or 1
  props.radius = props.radius or 20
  return make(props, children)
end

local function muted(text, size)
  return ui.label({ text = text, fontSize = size or 11, color = "on_surface_variant", maxLines = 1 })
end

local function heading(text)
  return ui.label({ text = text, fontSize = 13, fontWeight = "bold", maxLines = 1, flexGrow = 1 })
end

-- Circulo de icone: acento quando ligado, vidro quando desligado
local function orb(glyph, on, handler, size)
  size = size or 34
  return ui.row({
    width = size, height = size, radius = size / 2, align = "center", justify = "center",
    fill = on and ACCENT or TILE_RAISED, onClick = handler,
  }, {
    ui.glyph({ name = glyph, size = math.floor(size * 0.47), color = on and ON_ACCENT or "on_surface" }),
  })
end

-- Tile da Central: o circulo liga e desliga, o texto abre o detalhe
local function tile(glyph, name, detail, on, onToggle, target)
  return surface(ui.row, { align = "center", gap = 10, padding = 10, flexGrow = 1, radius = 18 }, {
    orb(glyph, on, onToggle),
    ui.row({ flexGrow = 1, align = "center", onClick = function() setView(target) end }, {
      ui.column({ gap = 1, flexGrow = 1 }, {
        ui.label({ text = name, fontSize = 13, fontWeight = "bold", maxLines = 1 }),
        muted(detail),
      }),
      ui.glyph({ name = "chevron-right", size = 14, color = "on_surface_variant" }),
    }),
  })
end

local function header(text, right)
  return ui.row({ align = "center", gap = 6 }, {
    ui.button({ glyph = "chevron-left", variant = "ghost", tooltip = "Voltar", onClick = function() setView("home") end }),
    ui.label({ text = text, fontSize = 20, fontWeight = "bold", flexGrow = 1 }),
    right or ui.spacer({ width = 0 }),
  })
end

local function section(text, child)
  return ui.column({ gap = 6 }, { ui.row({ paddingH = 4 }, { muted(text, 12) }), child })
end

-- Lista agrupada no estilo iOS: um vidro so, linhas separadas por fio
local function group(rows)
  local children = {}
  for i, r in ipairs(rows) do
    if i > 1 then children[#children + 1] = ui.separator({ thickness = 1, color = "#ffffff14", spacing = 0 }) end
    children[#children + 1] = r
  end
  return surface(ui.column, { gap = 0, paddingH = 12, paddingV = 2, radius = 18 }, children)
end

local function listRow(glyph, text, sub, active, right, handler)
  return ui.row({ align = "center", gap = 10, paddingV = 9, onClick = handler }, {
    ui.glyph({ name = glyph, size = 16, color = active and ACCENT or "on_surface_variant" }),
    ui.column({ gap = 1, flexGrow = 1 }, {
      ui.label({ text = text, fontSize = 13, fontWeight = active and "bold" or "medium", maxLines = 1, color = active and ACCENT or "on_surface" }),
      sub and muted(sub) or ui.spacer({ height = 0 }),
    }),
    right or ui.spacer({ width = 0 }),
  })
end

local function segmented(options, current, onPick)
  local segs = {}
  for _, o in ipairs(options) do
    local on = o[1] == current
    segs[#segs + 1] = ui.row({
      flexGrow = 1, align = "center", justify = "center", paddingV = 7, radius = 11,
      fill = on and ACCENT or "#00000000", onClick = function() onPick(o[1]) end,
    }, {
      ui.label({ text = o[2], fontSize = 12, fontWeight = on and "bold" or "medium", color = on and ON_ACCENT or "on_surface" }),
    })
  end
  return surface(ui.row, { gap = 2, padding = 3, radius = 14 }, segs)
end

local function empty(text)
  return surface(ui.row, { align = "center", justify = "center", padding = 24, radius = 18 }, { muted(text, 12) })
end

-- O scroll ocupa o que sobra do painel (altura fixa nao e respeitada e vaza pela borda).
-- A chave muda com o conteudo (`sig`) para o scroll ser recriado e remedido
local function listBox(items, sig)
  return ui.scroll({ gap = 10, flexGrow = 1, key = `{view}-{sig or #items}` }, items)
end

local function sliderRow(glyph, value, isMuted, onValue, onMute)
  return ui.row({ align = "center", gap = 8 }, {
    ui.button({ glyph = isMuted and (glyph .. "-off") or glyph, variant = "ghost", onClick = onMute }),
    ui.slider({
      min = 0, max = 100, step = 1, value = value, flexGrow = 1,
      onChange = function(v)
        holdUntil = os.clock() + 1.2
        onValue(math.floor(v + 0.5))
      end,
    }),
    ui.label({ text = `{value}%`, fontSize = 12, fontWeight = "bold", width = 34, textAlign = "right" }),
  })
end

local function setVolume(v)
  s.volume = v
  noctalia.runAsync(`wpctl set-volume @DEFAULT_AUDIO_SINK@ {v}%`)
end

local function setBrightness(v)
  s.brightness = math.max(v, 1)
  noctalia.runAsync({ "brightnessctl", "-q", "set", `{s.brightness}%` })
end

local function togglePlay()
  local m = s.media
  if not m or not s.player then return end
  m.status = m.status == "Playing" and "Paused" or "Playing"
  noctalia.runAsync({ "playerctl", "-p", s.player, "play-pause" })
  render()
end

local function artwork(size, radius)
  if s.artPath then return ui.image({ path = s.artPath, width = size, height = size, radius = radius, fit = "cover" }) end
  return ui.row({ width = size, height = size, radius = radius, fill = TILE_RAISED, align = "center", justify = "center" }, {
    ui.glyph({ name = "music", size = math.floor(size * 0.4), color = "on_surface_variant" }),
  })
end

local function transport(size)
  local playing = s.media and s.media.status == "Playing"
  return ui.row({ gap = 4, align = "center", justify = "center" }, {
    ui.button({ glyph = "player-skip-back", variant = "ghost", controlSize = size, onClick = function() noctalia.runAsync({ "playerctl", "-p", s.player, "previous" }) end }),
    ui.button({ glyph = playing and "player-pause" or "player-play", variant = "primary", controlSize = size, onClick = togglePlay }),
    ui.button({ glyph = "player-skip-forward", variant = "ghost", controlSize = size, onClick = function() noctalia.runAsync({ "playerctl", "-p", s.player, "next" }) end }),
  })
end

-- ---------- Inicio ----------

local function mediaTile()
  local open = function() setView("media") end
  local m = s.media
  if not m then
    return surface(ui.row, { width = 230, align = "center", gap = 10, padding = 12, radius = 18, onClick = open }, {
      orb("music", false, open),
      ui.column({ gap = 1, flexGrow = 1 }, {
        ui.label({ text = "Nada tocando", fontSize = 13, fontWeight = "bold" }),
        muted("Abrir mídia"),
      }),
    })
  end
  return surface(ui.column, { width = 230, gap = 8, padding = 12, radius = 18 }, {
    ui.row({ gap = 10, align = "center", onClick = open }, {
      artwork(52, 12),
      ui.column({ gap = 1, flexGrow = 1 }, {
        ui.label({ text = m.title, fontSize = 13, fontWeight = "bold", maxLines = 1 }),
        muted(m.artist ~= "" and m.artist or playerLabel(s.player or "")),
      }),
    }),
    transport("sm"),
  })
end

local function mini(label, value, fraction)
  return ui.column({ gap = 4, flexGrow = 1 }, {
    ui.row({ align = "center", gap = 4 }, {
      ui.label({ text = label, fontSize = 11, color = "on_surface_variant", flexGrow = 1 }),
      ui.label({ text = value, fontSize = 11, fontWeight = "bold" }),
    }),
    ui.progress({ progress = clamp01(fraction), fill = fraction > 0.85 and ROSE or ACCENT, track = TRACK, radius = 2, height = 4 }),
  })
end

local function homeView()
  local stats = noctalia.systemStats() or {}
  local usage = stats.cpu and stats.cpu.usagePercent or 0
  local cpu, ram, gpu = stats.cpu or {}, stats.ram or {}, stats.gpu or {}
  local vramFraction = gpu.vramTotalBytes and gpu.vramTotalBytes > 0 and (gpu.vramUsedBytes or 0) / gpu.vramTotalBytes or 0
  local function gib(b) return b and string.format("%.1f", b / 1073741824) or "--" end
  local function deg(v) return v and string.format("%.0f°", v) or "--" end
  local name = s.fullname ~= "" and (s.fullname:match("^(%S+)") or s.fullname) or s.user

  local sliders = {}
  if s.volume then sliders[#sliders + 1] = sliderRow("volume", s.volume, s.muted, setVolume, "onMute") end
  if s.brightness then sliders[#sliders + 1] = sliderRow("sun", s.brightness, false, setBrightness, nil) end

  return ui.column({ gap = 12 }, {
    ui.row({ align = "center", gap = 14 }, {
      ui.label({ text = s.time, fontSize = 34, fontWeight = "bold" }),
      ui.column({ gap = 1, flexGrow = 1 }, {
        ui.label({ text = s.date, fontSize = 13, fontWeight = "medium", maxLines = 1 }),
        muted(`{name}  ·  {s.host}  ·  ligado há {s.uptime}`),
      }),
      ui.row({ gap = 6, align = "center" }, {
        orb("coffee", s.caffeine, "onCaffeine", 30),
        orb("moon", s.nightlight, "onNight", 30),
        orb("calendar", false, function() setView("calendar") end, 30),
        orb("bell", false, function() setView("notifications") end, 30),
        orb("power", false, function() setView("power") end, 30),
        orb("settings", false, "onSettings", 30),
      }),
    }),
    ui.row({ gap = 10, align = "start" }, {
      ui.column({ gap = 10, flexGrow = 1 }, {
        ui.row({ gap = 10 }, {
          tile("wifi", "Wi-Fi", s.wifi and (s.ssid ~= "" and s.ssid or "Ligado") or "Desligado", s.wifi, "onWifi", "network"),
          tile("bluetooth", "Bluetooth", s.bluetooth and "Ligado" or "Desligado", s.bluetooth, "onBluetooth", "bluetooth"),
        }),
        ui.row({ gap = 10 }, {
          tile("bell-off", "Silêncio", s.dnd and "Ativado" or "Desativado", s.dnd, "onDnd", "notifications"),
          tile("gauge", "Energia", PROFILE_LABEL[s.profile] or s.profile, s.profile == "performance", "onProfile", "power"),
        }),
      }),
      mediaTile(),
    }),
    ui.row({ gap = 10, align = "start" }, {
      surface(ui.column, { gap = 8, padding = 12, flexGrow = 1, height = BOTTOM_H, radius = 18 }, {
        ui.row({ align = "center" }, {
          heading("Sistema"),
          muted(string.format("CPU %.0f%%  ·  %s", usage, deg(cpu.tempC))),
        }),
        ui.graph({ values = cpuHistory, color = ACCENT, fillOpacity = 0.18, lineWidth = 2, height = 48 }),
        ui.row({ gap = 12 }, {
          mini("RAM", `{gib(ram.usedMb and ram.usedMb * 1048576)} GiB`, (ram.usagePercent or 0) / 100),
          mini("GPU", gpu.usagePercent and string.format("%.0f%%", gpu.usagePercent) or "--", (gpu.usagePercent or 0) / 100),
          mini("VRAM", `{gib(gpu.vramUsedBytes)} GiB`, vramFraction),
        }),
      }),
      surface(ui.column, { width = 230, height = BOTTOM_H, gap = 6, padding = 10, justify = "center", radius = 18 }, {
        ui.row({ align = "center", paddingH = 4 }, {
          heading("Som e tela"),
          ui.button({ glyph = "chevron-right", variant = "ghost", controlSize = "sm", tooltip = "Áudio", onClick = function() setView("audio") end }),
        }),
        table.unpack(sliders),
      }),
    }),
  })
end

-- ---------- Detalhes ----------

local function audioView()
  local items = {
    section("Saída", surface(ui.column, { gap = 4, padding = 10, radius = 18 }, {
      ui.row({ paddingH = 4 }, { ui.label({ text = s.out.name ~= "" and s.out.name or "Sem dispositivo", fontSize = 13, fontWeight = "bold", maxLines = 1 }) }),
      sliderRow("volume", s.out.volume, s.out.muted, function(v)
        s.out.volume = v
        noctalia.runAsync(`wpctl set-volume @DEFAULT_AUDIO_SINK@ {v}%`)
      end, function()
        s.out.muted = not s.out.muted
        noctalia.runAsync("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
      end),
    })),
    section("Entrada", surface(ui.column, { gap = 4, padding = 10, radius = 18 }, {
      ui.row({ paddingH = 4 }, { ui.label({ text = s.inp.name ~= "" and s.inp.name or "Sem dispositivo", fontSize = 13, fontWeight = "bold", maxLines = 1 }) }),
      sliderRow("microphone", s.inp.volume, s.inp.muted, function(v)
        s.inp.volume = v
        noctalia.runAsync(`wpctl set-volume @DEFAULT_AUDIO_SOURCE@ {v}%`)
      end, function()
        s.inp.muted = not s.inp.muted
        noctalia.runAsync("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")
      end),
    })),
  }
  local appRows = {}
  for _, app in ipairs(s.apps) do
    table.insert(appRows, ui.row({ align = "center", gap = 10, paddingV = 6 }, {
      ui.label({ text = app.name, fontSize = 12, fontWeight = "medium", maxLines = 1, width = 110 }),
      ui.slider({
        min = 0, max = 100, step = 1, value = app.volume, flexGrow = 1,
        onChange = function(v)
          holdUntil = os.clock() + 1.2
          app.volume = math.floor(v + 0.5)
          noctalia.runAsync({ "pactl", "set-sink-input-volume", tostring(app.index), `{app.volume}%` })
        end,
      }),
      ui.label({ text = `{app.volume}%`, fontSize = 12, fontWeight = "bold", width = 34, textAlign = "right" }),
    }))
  end
  table.insert(items, section("Apps", #appRows > 0 and group(appRows) or empty("Nenhum app tocando agora")))
  return ui.column({ gap = 10, flexGrow = 1 }, { header("Áudio"), listBox(items, #s.apps) })
end

local function networkView()
  local cur = s.netCurrent
  local items = {}
  if cur then
    table.insert(items, surface(ui.row, { align = "center", gap = 12, padding = 12, radius = 18, fill = ACCENT .. "1f", border = ACCENT .. "55" }, {
      orb("wifi", true, nil, 38),
      ui.column({ gap = 2, flexGrow = 1 }, {
        ui.label({ text = cur.ssid, fontSize = 14, fontWeight = "bold", maxLines = 1 }),
        muted(`{s.ip}  ·  sinal {cur.signal}%  ·  {cur.freq}`),
      }),
      ui.button({ text = "Desconectar", variant = "ghost", controlSize = "sm", onClick = "onNetDisconnect" }),
    }))
  end
  if s.netMsg ~= "" then table.insert(items, ui.label({ text = s.netMsg, fontSize = 11, color = ROSE })) end
  local rows = {}
  for _, n in ipairs(s.networks) do
    if not n.active then
      rows[#rows + 1] = listRow("wifi", n.ssid, nil, false, ui.row({ gap = 8, align = "center" }, {
        n.secure and ui.glyph({ name = "lock", size = 13, color = "on_surface_variant" }) or ui.spacer({ width = 0 }),
        muted(`{n.signal}%`),
      }), function()
        s.netMsg = `Conectando a {n.ssid}…`
        noctalia.runAsync({ "nmcli", "dev", "wifi", "connect", n.ssid }, function(r)
          s.netMsg = r.exitCode == 0 and "" or (n.secure and "Rede nova com senha: conecte pelas configurações." or "Falha ao conectar.")
          refreshNetwork()
        end)
      end)
    end
  end
  table.insert(items, section("Outras redes", #rows > 0 and group(rows) or empty(s.wifi and "Procurando redes…" or "Wi-Fi desligado")))
  local sig = `{#s.networks}-{cur and cur.ssid or ""}-{s.netMsg}-{s.wifi}`
  return ui.column({ gap = 10, flexGrow = 1 }, { header("Wi-Fi", ui.toggle({ checked = s.wifi, onChange = "onWifiToggle" })), listBox(items, sig) })
end

local function bluetoothView()
  local rows = {}
  for _, d in ipairs(s.btDevices) do
    rows[#rows + 1] = listRow("bluetooth", d.name, d.connected and "Conectado" or "Pareado", d.connected, ui.row({ gap = 2, align = "center" }, {
      ui.button({
        text = d.connected and "Desconectar" or "Conectar", variant = "ghost", controlSize = "sm",
        onClick = function()
          noctalia.runAsync({ "bluetoothctl", d.connected and "disconnect" or "connect", d.mac }, function() refreshBluetooth() end)
        end,
      }),
      ui.button({ glyph = "trash", variant = "ghost", controlSize = "sm", tooltip = "Esquecer", onClick = function()
        noctalia.runAsync({ "bluetoothctl", "remove", d.mac }, function() refreshBluetooth() end)
      end }),
    }))
  end
  local body = section("Meus dispositivos", #rows > 0 and group(rows) or empty("Nenhum dispositivo pareado"))
  return ui.column({ gap = 10, flexGrow = 1 }, { header("Bluetooth", ui.toggle({ checked = s.bluetooth, onChange = "onBtToggle" })), listBox({ body }, #s.btDevices) })
end

local function ago(at)
  local diff = os.time() - at
  if diff < 60 then return "agora" end
  if diff < 3600 then return `há {math.floor(diff / 60)} min` end
  if diff < 86400 then return `há {math.floor(diff / 3600)} h` end
  return `há {math.floor(diff / 86400)} d`
end

local function notificationsView()
  local now = os.date("*t")
  local midnight = os.time({ year = now.year, month = now.month, day = now.day, hour = 0, min = 0, sec = 0 })
  local function inTab(at)
    if s.notifTab == "today" then return at >= midnight end
    if s.notifTab == "yesterday" then return at < midnight and at >= midnight - 86400 end
    if s.notifTab == "older" then return at < midnight - 86400 end
    return true
  end
  local items = {}
  for _, n in ipairs(s.notifs) do
    if inTab(n.at) then
      table.insert(items, surface(ui.column, { gap = 2, padding = 12, radius = 16 }, {
        ui.row({ align = "center" }, {
          ui.label({ text = n.app, fontSize = 11, color = "on_surface_variant", maxLines = 1, flexGrow = 1 }),
          muted(ago(n.at), 10),
        }),
        ui.label({ text = n.summary, fontSize = 13, fontWeight = "bold", maxLines = 1 }),
        n.body ~= "" and ui.label({ text = n.body, fontSize = 12, color = "on_surface_variant", maxLines = 2 }) or ui.spacer({ height = 0 }),
      }))
    end
  end
  if #items == 0 then items = { empty("Sem notificações") } end
  local right = ui.row({ gap = 6, align = "center" }, {
    orb("bell-off", s.dnd, "onDnd", 30),
    orb("trash", false, "onClearNotifs", 30),
  })
  local tabs = { { "all", "Todas" }, { "today", "Hoje" }, { "yesterday", "Ontem" }, { "older", "Antigas" } }
  return ui.column({ gap = 10, flexGrow = 1 }, {
    header("Notificações", right),
    segmented(tabs, s.notifTab, function(id) s.notifTab = id; render() end),
    listBox(items, `{s.notifTab}-{#items}`),
  })
end

local function playerChips()
  local row = {}
  for _, n in ipairs(s.players or {}) do
    local on = n == s.player
    row[#row + 1] = ui.row({
      paddingH = 12, paddingV = 6, radius = 13, fill = on and ACCENT or TILE_RAISED,
      onClick = function()
        s.player = n
        s.media = nil
        s.artUrl = nil
        s.artPath = nil
        refreshMediaOf(n)
      end,
    }, { ui.label({ text = playerLabel(n), fontSize = 12, fontWeight = on and "bold" or "medium", color = on and ON_ACCENT or "on_surface" }) })
  end
  return ui.row({ gap = 6 }, row)
end

local function mediaView()
  local m = s.media
  if not m then
    return ui.column({ gap = 10 }, { header("Mídia"), playerChips(), empty("Nada tocando agora") })
  end
  local function fmt(sec) return string.format("%d:%02d", math.floor(sec / 60), math.floor(sec % 60)) end
  return ui.column({ gap = 10 }, {
    header("Mídia"),
    playerChips(),
    surface(ui.row, { gap = 18, align = "center", padding = 16, radius = 24 }, {
      artwork(170, 18),
      ui.column({ gap = 6, flexGrow = 1 }, {
        ui.label({ text = m.title, fontSize = 18, fontWeight = "bold", maxLines = 2 }),
        ui.label({ text = m.artist, fontSize = 13, color = "on_surface_variant", maxLines = 1 }),
        muted(m.album),
        ui.spacer({ height = 6 }),
        ui.progress({ progress = m.length > 0 and clamp01(m.position / m.length) or 0, fill = ACCENT, track = TRACK, radius = 3, height = 5 }),
        ui.row({ align = "center" }, {
          ui.label({ text = fmt(m.position), fontSize = 10, color = "on_surface_variant", flexGrow = 1 }),
          muted(fmt(m.length), 10),
        }),
        transport(nil),
      }),
    }),
  })
end

local function powerView()
  local pct = s.batteryPct
  local low = pct and pct <= 20
  local statusText = (s.batteryStatus == "Charging" and "Carregando") or (s.batteryStatus == "Full" and "Carga completa")
    or (s.batteryStatus == "Discharging" and "Na bateria") or s.batteryStatus
  local sessionActions = {
    { "lock", "Bloquear", "lock" },
    { "logout", "Sair", "logout" },
    { "lock_and_suspend", "Suspender", "moon" },
    { "reboot", "Reiniciar", "refresh" },
    { "shutdown", "Desligar", "power" },
  }
  local sessionRow = {}
  for _, a in ipairs(sessionActions) do
    sessionRow[#sessionRow + 1] = ui.column({ gap = 6, align = "center", flexGrow = 1 }, {
      orb(a[3], false, function()
        panel.close()
        noctalia.runAsync("noctalia msg session " .. a[1])
      end, 46),
      muted(a[2]),
    })
  end
  local profiles = {}
  for _, p in ipairs(PROFILES) do profiles[#profiles + 1] = { p, PROFILE_LABEL[p] } end
  return ui.column({ gap = 12 }, {
    header("Energia"),
    surface(ui.row, { align = "center", gap = 14, padding = 14, radius = 18 }, {
      ui.label({ text = pct and `{pct}%` or "--", fontSize = 30, fontWeight = "bold", color = low and ROSE or "on_surface" }),
      ui.column({ gap = 6, flexGrow = 1 }, {
        ui.label({ text = statusText ~= "" and statusText or "Bateria", fontSize = 13, fontWeight = "medium" }),
        ui.progress({ progress = (pct or 0) / 100, fill = low and ROSE or (s.batteryStatus == "Charging" and SAGE or ACCENT), track = TRACK, radius = 3, height = 6 }),
      }),
    }),
    section("Modo de energia", segmented(profiles, s.profile, function(p)
      s.profile = p
      noctalia.runAsync("powerprofilesctl set " .. p)
      render()
    end)),
    section("Sessão", ui.row({ gap = 6, paddingV = 4 }, sessionRow)),
  })
end

local WEEKDAYS = { "D", "S", "T", "Q", "Q", "S", "S" }
-- Largura fixa por dia: com flexGrow as colunas variam com o texto e a grade entorta
local CELL = 40
local GCAL = (noctalia.getenv("HOME") or "") .. "/.config/noctalia/plugins/hub/gcal.py"

local function daysIn(year, month)
  if month == 2 then return (year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)) and 29 or 28 end
  return ({ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 })[month]
end

-- Eventos do Google Calendar via gcal.py (endereco iCal secreto em ~/.config/noctalia/gcal.urls)
refreshCalendar = function()
  local y, m = s.calYear, s.calMonth
  sh(`test -f "$HOME/.config/noctalia/gcal.urls" || \{ echo NOURLS; exit 0; }; python3 "{GCAL}" {y} {m} 2>/dev/null`, function(out, code)
    if y ~= s.calYear or m ~= s.calMonth then return end
    if out:find("NOURLS", 1, true) then
      s.calEvents, s.calStatus = {}, "Google Calendar não conectado"
      return
    end
    if code ~= 0 then
      s.calStatus = "Erro ao ler a agenda"
      return
    end
    local byDay = {}
    for line in out:gmatch("[^\n]+") do
      local e = noctalia.json.decode(line)
      if type(e) == "table" and e.date then
        local d = tonumber(e.date:sub(9, 10))
        byDay[d] = byDay[d] or {}
        table.insert(byDay[d], e)
      end
    end
    s.calEvents, s.calStatus = byDay, ""
  end)
end

local function shiftMonth(delta)
  local m = s.calMonth + delta
  s.calYear += math.floor((m - 1) / 12)
  s.calMonth = (m - 1) % 12 + 1
  s.calSel, s.calEvents = 1, {}
  refreshCalendar()
  render()
end

local function calendarView()
  local now = os.date("*t")
  local y, m = s.calYear, s.calMonth
  local first = os.date("*t", os.time({ year = y, month = m, day = 1, hour = 12 })).wday
  local total = daysIn(y, m)
  local events = s.calEvents or {}

  local function cell(d)
    local today = d and y == now.year and m == now.month and d == now.day
    local selected = d and d == s.calSel
    local wday = d and (first + d - 2) % 7 + 1
    local color = today and ON_ACCENT or ((wday == 1 or wday == 7) and "on_surface_variant" or "on_surface")
    return ui.column({ width = CELL, height = 34, align = "center", gap = 1, onClick = d and function() s.calSel = d; render() end or nil }, {
      ui.row({
        width = 28, height = 28, radius = 14, align = "center", justify = "center",
        fill = today and ACCENT or (selected and TILE_RAISED or "#00000000"),
      }, {
        ui.label({ text = d and tostring(d) or "", fontSize = 12, fontWeight = (today or selected) and "bold" or "medium", color = color }),
      }),
      ui.row({ width = 4, height = 4, radius = 2, fill = d and events[d] and ACCENT or "#00000000" }, {}),
    })
  end

  local head = {}
  for _, w in ipairs(WEEKDAYS) do head[#head + 1] = ui.row({ width = CELL, justify = "center" }, { muted(w, 11) }) end
  local weeks = { ui.row({ gap = 2 }, head) }
  local d = 2 - first
  while d <= total do
    local row = {}
    for _ = 1, 7 do
      row[#row + 1] = cell(d >= 1 and d <= total and d or nil)
      d += 1
    end
    weeks[#weeks + 1] = ui.row({ gap = 2 }, row)
  end

  local sel = s.calSel
  local selWday = (first + sel - 2) % 7 + 1
  local dayTitle = (y == now.year and m == now.month and sel == now.day) and "Hoje" or `{DAYS[selWday]}, {sel}`
  local rows = {}
  for _, e in ipairs(events[sel] or {}) do
    rows[#rows + 1] = listRow("calendar-event", e.title, e.time ~= "" and e.time or "Dia inteiro", false)
  end
  local agenda = #rows > 0 and group(rows) or empty(s.calStatus ~= "" and s.calStatus or "Nada marcado")

  local month = MONTHS[m]:sub(1, 1):upper() .. MONTHS[m]:sub(2)
  local right = ui.row({ gap = 2, align = "center" }, {
    (y ~= now.year or m ~= now.month) and ui.button({ text = "Hoje", variant = "ghost", controlSize = "sm", onClick = function()
      s.calYear, s.calMonth = now.year, now.month
      shiftMonth(0)
      s.calSel = now.day
      render()
    end }) or ui.spacer({ width = 0 }),
    ui.button({ glyph = "chevron-up", variant = "ghost", controlSize = "sm", tooltip = "Mês anterior", onClick = function() shiftMonth(-1) end }),
    ui.button({ glyph = "chevron-down", variant = "ghost", controlSize = "sm", tooltip = "Próximo mês", onClick = function() shiftMonth(1) end }),
  })
  return ui.column({ gap = 10, flexGrow = 1 }, {
    header(`{month} de {y}`, right),
    ui.row({ gap = 12, align = "start", flexGrow = 1 }, {
      -- A chave muda com o mes: 5 ou 6 semanas, sem reaproveitar linhas da grade anterior
      surface(ui.column, { gap = 2, padding = 10, radius = 18, key = `cal-{y}-{m}` }, weeks),
      ui.column({ gap = 6, flexGrow = 1 }, {
        ui.row({ paddingH = 4 }, { heading(dayTitle) }),
        listBox({ agenda }, `{y}-{m}-{sel}-{#rows}-{s.calStatus}`),
      }),
    }),
  })
end

local BUILDERS = {
  home = homeView, audio = audioView, network = networkView, bluetooth = bluetoothView,
  notifications = notificationsView, media = mediaView, power = powerView, calendar = calendarView,
}

-- A chave por tela recria a arvore na troca; sem ela o Noctalia reaproveita nos da tela
-- anterior e herda fill, borda e altura que a tela nova nao define (molduras fantasmas, conteudo vazando)
render = function()
  panel.render(ui.column({ padding = 16, flexGrow = 1, key = view }, { (BUILDERS[view] or homeView)() }))
end

function setView(id)
  if id == "calendar" then
    local t = os.date("*t")
    s.calYear, s.calMonth, s.calSel = t.year, t.month, t.day
  end
  view = id
  ticks = 0
  refreshView()
  render()
end

-- ---------- Acoes ----------

function onWifi()
  s.wifi = not s.wifi
  noctalia.runAsync("nmcli radio wifi " .. (s.wifi and "on" or "off"))
  render()
end

function onWifiToggle(value)
  s.wifi = value == true or value == "true"
  noctalia.runAsync("nmcli radio wifi " .. (s.wifi and "on" or "off"))
end

function onNetDisconnect()
  noctalia.runAsync("nmcli dev disconnect $(nmcli -t -f DEVICE,TYPE dev | awk -F: '$2==\"wifi\"{print $1; exit}')", function() refreshNetwork() end)
end

function onBluetooth()
  s.bluetooth = not s.bluetooth
  noctalia.runAsync("bluetoothctl power " .. (s.bluetooth and "on" or "off"))
  render()
end

function onBtToggle(value)
  s.bluetooth = value == true or value == "true"
  noctalia.runAsync("bluetoothctl power " .. (s.bluetooth and "on" or "off"))
end

-- O estado real nao pode ser lido daqui (msg em leitura derruba o shell), entao o clique
-- manda o estado explicito em vez de toggle: sistema e tela convergem no primeiro clique
function onDnd()
  s.dnd = not s.dnd
  noctalia.runAsync({ "noctalia", "msg", "notification-dnd-set", s.dnd and "on" or "off" })
  render()
end

function onCaffeine()
  s.caffeine = not s.caffeine
  noctalia.runAsync({ "noctalia", "msg", s.caffeine and "caffeine-enable" or "caffeine-disable" })
  render()
end

function onNight()
  s.nightlight = not s.nightlight
  noctalia.runAsync({ "noctalia", "msg", s.nightlight and "nightlight-enable" or "nightlight-disable" })
  render()
end

function onClearNotifs()
  s.notifs = {}
  noctalia.runAsync("noctalia msg notification-clear-history")
  render()
end

function onProfile()
  local nextProfile = PROFILES[1]
  for i, name in ipairs(PROFILES) do
    if name == s.profile then nextProfile = PROFILES[i % #PROFILES + 1] end
  end
  s.profile = nextProfile
  noctalia.runAsync("powerprofilesctl set " .. nextProfile)
  render()
end

function onMute()
  s.muted = not s.muted
  noctalia.runAsync("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
  render()
end

function onSettings()
  panel.close()
  noctalia.openSettings()
end

function onOpen(context)
  isOpen = true
  ticks = 0
  holdUntil = 0
  view = "home"
  for _, id in ipairs(VIEWS) do
    if id == context then view = context end
  end
  local today = os.date("*t")
  s.calYear, s.calMonth, s.calSel = today.year, today.month, today.day
  s.user = noctalia.getenv("USER") or ""
  local host = noctalia.readFile("/etc/hostname")
  s.host = host and trim(host) or ""
  if s.fullname == "" then
    sh("getent passwd \"$USER\" | cut -d: -f5 | cut -d, -f1", function(out) s.fullname = trim(out) end)
  end
  panel.setWantsSecondTicks(true)
  cpuHistory = {}
  sampleCpu()
  refreshView()
  render()
end

function onClose() isOpen = false end

function update()
  if not isOpen then return end
  ticks += 1
  sampleCpu()
  if os.clock() < holdUntil then return end
  if ticks % (REFRESH_EVERY[view] or 5) == 0 then refreshView() end
  render()
end

local _onOpen = onOpen
function onOpen(...)
  local ok, err = pcall(_onOpen, ...)
  if not ok then noctalia.notifyError("Hub", tostring(err)) end
end

local _update = update
function update(...)
  local ok, err = pcall(_update, ...)
  if not ok then noctalia.notifyError("Hub update", tostring(err)) end
end
