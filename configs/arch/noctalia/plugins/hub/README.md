# Balerion OS

Painel de controle próprio da barra do Noctalia. Substitui o menu nativo.
O id técnico continua `noirelab/hub`: mudar quebraria as referências no `config.toml`.

## Vocabulário

Use estes nomes ao pedir mudanças.

| Nome | O que é | Onde mora |
|------|---------|-----------|
| Barra | A faixa no topo dos dois monitores | `~/.config/noctalia/config.toml`, `[bar.default]` |
| Relógio do Balerion | Hora e data no centro da barra; clique abre o Balerion OS | `widget_clock.luau` |
| Cápsula de status | Volume, bateria e bandeja | `config.toml`, capsule_group `status` |
| Cápsula de uso | Uso do Claude (5h / semana) | plugin `claude-usage`, capsule_group `time` |
| Widget de música | Capa + música na barra (nativo, `media`) | `config.toml`, `[widget.media]` |
| Balerion OS | O painel flutuante que abre do relógio | `panel_home.luau` |

## Telas do Balerion OS

Cada tela é uma função `<nome>View()` em `panel_home.luau`.

| Tela | id | Abre por |
|------|----|----------|
| Início (tiles, performance, mídia) | `home` | clique no relógio |
| Áudio | `audio` | clique no volume |
| Rede | `network` | tile Wi-Fi |
| Bluetooth | `bluetooth` | tile Bluetooth |
| Notificações | `notifications` | botão de sino ou tile Silêncio no Início |
| Mídia | `media` | clique no widget de música |
| Energia | `power` | clique na bateria |
| Calendário | `calendar` | botão de calendário no Início |

Abrir uma tela direto: `noctalia msg panel-toggle noirelab/hub:home <id>`.

## Monitores

- HDMI-A-1: principal, horizontal (1920 px). Barra completa.
- DP-1: vertical (1080 px). Sem o widget de música (`[bar.default.monitor."DP-1"]`).
