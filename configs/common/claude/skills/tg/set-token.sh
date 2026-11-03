#!/usr/bin/env bash
# Grava o token do bot do Telegram para o plugin do Claude Code sem que ele
# passe pela tela, pelo histórico do shell ou pela lista de processos.
# Uso: nano /tmp/telegram-token.txt  (cole o token)  &&  ~/.claude/skills/tg/set-token.sh
set -euo pipefail
src=${1:-/tmp/telegram-token.txt}
dir=${TELEGRAM_STATE_DIR:-$HOME/.claude/channels/telegram}  # compartilhado pelas duas contas

[ -r "$src" ] || { echo "Arquivo $src não existe. Crie com: nano $src"; exit 1; }
token=$(tr -d '[:space:]' <"$src")
[[ $token =~ ^[0-9]+:[A-Za-z0-9_-]{30,}$ ]] || { echo "Formato inválido (esperado 123456789:AAH...). Nada foi gravado."; exit 1; }

# printf é builtin: o token vai para o curl via stdin, nunca em argv
resp=$(printf 'url = "https://api.telegram.org/bot%s/getMe"\n' "$token" | curl -sS --max-time 15 -K -) || { echo "Falha de rede ao validar o token."; exit 1; }
if [ "$(jq -r '.ok' <<<"$resp")" != true ]; then
  echo "Telegram recusou o token: $(jq -r '.description // "erro desconhecido"' <<<"$resp"). Nada foi gravado."
  exit 1
fi

umask 077
mkdir -p "$dir"
printf 'TELEGRAM_BOT_TOKEN=%s\n' "$token" >"$dir/.env.tmp"
mv "$dir/.env.tmp" "$dir/.env"
chmod 600 "$dir/.env"
rm -f "$src"
echo "Token válido para @$(jq -r '.result.username' <<<"$resp"), gravado em $dir/.env (modo 600). $src foi apagado."
