#!/usr/bin/env bash
# Manda texto e/ou arquivos para a conta pareada no bot do Telegram.
# Uso: send.sh [-m "texto"] [arquivo ...]    |    send.sh --status
# Só usa os endpoints de envio, então não briga com o polling da sessão do canal.
set -euo pipefail
state=${TELEGRAM_STATE_DIR:-$HOME/.claude/channels/telegram}
die() { echo "tg: $*" >&2; exit 1; }

[ -r "$state/.env" ] || die "sem token em $state/.env (rode set-token.sh)"
TOKEN=$(sed -n 's/^TELEGRAM_BOT_TOKEN=//p' "$state/.env")
[ -n "$TOKEN" ] || die "TELEGRAM_BOT_TOKEN vazio em $state/.env"
chat=$(jq -r '.allowFrom[0] // empty' "$state/access.json" 2>/dev/null || true)

# O token vai para o curl pelo stdin (printf é builtin), nunca em argv.
api() {
  local method=$1; shift
  printf 'url = "https://api.telegram.org/bot%s/%s"\n' "$TOKEN" "$method" |
    curl -sS --max-time 300 -K - "$@"
}
check() { [ "$(jq -r .ok <<<"$1")" = true ] || die "Telegram recusou: $(jq -r '.description // .' <<<"$1")"; }

if [ "${1:-}" = --status ]; then
  r=$(api getMe); check "$r"
  echo "bot: @$(jq -r .result.username <<<"$r")"
  echo "pareado: ${chat:-não (falta parear)}"
  echo "política: $(jq -r '.dmPolicy // "pairing"' "$state/access.json" 2>/dev/null || echo pairing)"
  tmux has-session -t claude-tg 2>/dev/null && echo "sessão do Telegram: rodando (tmux attach -t claude-tg)" || echo "sessão do Telegram: parada"
  exit 0
fi

[ -n "$chat" ] || die "nenhuma conta pareada ainda: abra a sessão do canal e rode /telegram:access pair <código>"

msg=""
if [ "${1:-}" = -m ]; then msg=${2:-}; shift 2 || die "-m precisa de texto"; fi
[ -n "$msg" ] || [ $# -gt 0 ] || die "nada para enviar"

if [ -n "$msg" ]; then
  if [ ${#msg} -le 4000 ]; then
    check "$(api sendMessage --form-string "chat_id=$chat" --form-string "text=$msg")"
  else  # acima do limite do Telegram: vai como arquivo
    tmp=$(mktemp --suffix=.txt); printf '%s\n' "$msg" >"$tmp"
    check "$(api sendDocument --form-string "chat_id=$chat" -F "document=@$tmp;filename=mensagem.txt")"
    rm -f "$tmp"
  fi
fi

for f in "$@"; do
  [ -f "$f" ] || die "arquivo não existe: $f"
  [ "$(stat -c %s "$f")" -le 52428800 ] || die "maior que 50MB (limite do Telegram): $f"
  case "${f,,}" in
    *.jpg|*.jpeg|*.png|*.webp) field=photo; method=sendPhoto ;;
    *) field=document; method=sendDocument ;;
  esac
  check "$(api "$method" --form-string "chat_id=$chat" -F "$field=@\"$f\"")"
done
echo "tg: enviado"
