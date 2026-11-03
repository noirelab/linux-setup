#!/usr/bin/env bash
# Leva a conversa atual para uma sessão em background (tmux claude-tg) ligada ao Telegram.
# Uso: handoff.sh [--model sonnet|haiku|opus] [--summary arquivo] <session-id> <pasta>
#   sem --summary: copia (fork) a conversa inteira
#   com --summary: abre uma sessão nova só com o resumo (contexto menor, menos tokens)
set -euo pipefail
model=() summary=""
while [ $# -gt 0 ]; do
  case $1 in
    --model) model=(--model "${2:?--model precisa de valor}"); shift 2 ;;
    --summary) summary=${2:?--summary precisa de arquivo}; shift 2 ;;
    *) break ;;
  esac
done
sid=${1:?session id}; dir=${2:?pasta}
s=claude-tg
here=$(dirname "$(readlink -f "$0")")
pidf="$HOME/.claude/channels/telegram/bot.pid"

if tmux has-session -t "$s" 2>/dev/null; then
  echo "JA_EXISTE: já tem uma sessão do Telegram rodando (tmux attach -t $s)."; exit 2
fi
[ -z "$summary" ] || [ -s "$summary" ] || { echo "FALHOU: resumo $summary vazio ou inexistente."; exit 1; }

# Repassa a conta atual. Na conta principal a variável tem que ficar vazia
# (e o servidor tmux pode ter herdado a da outra conta, por isso o -u).
if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then acct=(env CLAUDE_CONFIG_DIR="$CLAUDE_CONFIG_DIR"); else acct=(env -u CLAUDE_CONFIG_DIR); fi

# Mantém o modo de permissão da sessão de origem (cc e cc2 rodam sem prompts).
perm=()
p=$PPID
for _ in 1 2 3 4 5 6 7 8; do
  args=$(ps -o args= -p "$p" 2>/dev/null) || break
  case $args in
    *--dangerously-skip-permissions*) perm=(--dangerously-skip-permissions); break ;;
    *"--permission-mode bypassPermissions"*) perm=(--permission-mode bypassPermissions); break ;;
  esac
  p=$(ps -o ppid= -p "$p" | tr -d ' ')
  [ "${p:-0}" -gt 1 ] || break
done

if [ -n "$summary" ]; then
  conv=("Você está continuando uma conversa pelo Telegram. Resumo do que foi feito até agora:

$(cat "$summary")

Não responda esta mensagem no Telegram. Espere a próxima mensagem do usuário.")
else
  conv=(--resume "$sid" --fork-session)
fi

old_pid=$(cat "$pidf" 2>/dev/null || true)  # um bot.pid antigo não conta como "subiu"
# O plugin fica desligado nas sessões normais; liga só nesta.
tmux new-session -d -s "$s" -c "$dir" \
  "${acct[@]}" claude "${perm[@]}" "${model[@]}" -n telegram \
    --channels plugin:telegram@claude-plugins-official \
    --settings '{"enabledPlugins":{"telegram@claude-plugins-official":true}}' \
    "${conv[@]}"

# A sessão de origem já roda nesta pasta, então o "confiar nesta pasta?" já foi
# respondido por você; a cópia responde "sim" uma única vez. Se perguntar de novo, para.
answered=0
for _ in $(seq 1 30); do
  tmux has-session -t "$s" 2>/dev/null || { echo "FALHOU: a sessão fechou logo ao abrir."; exit 1; }
  if tmux capture-pane -p -t "$s" | grep -q "trust this folder"; then
    if [ $answered = 1 ]; then
      echo "CONFIAR: o Claude pediu para confiar em $dir. Rode tmux attach -t $s, escolha 'Yes, I trust this folder' e saia com Ctrl+b d."
      exit 3
    fi
    tmux send-keys -t "$s" Down Enter; answered=1; sleep 2; continue
  fi
  cur=$(cat "$pidf" 2>/dev/null || true)
  [ -n "$cur" ] && [ "$cur" != "$old_pid" ] && break
  sleep 1
done

pid=$(cat "$pidf" 2>/dev/null || true)
if [ -n "$pid" ] && ps -p "$pid" -o args= 2>/dev/null | grep -q server.ts; then
  ctx="conversa inteira"; [ -z "$summary" ] || ctx="só o resumo"
  echo "OK: sessão claude-tg rodando em $dir (${model[1]:-modelo padrão}, $ctx${perm:+, sem prompts de permissão}), bot ativo."
else
  echo "AVISO: sessão aberta, mas o bot ainda não subiu (confira com tmux attach -t $s)."
fi
"$here/send.sh" -m "📱 Conversa transferida para cá (pasta: $dir). Pode falar." 2>&1 || true
