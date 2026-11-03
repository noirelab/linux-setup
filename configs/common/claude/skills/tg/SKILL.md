---
name: tg
description: Fala com o usuário pelo Telegram (bot próprio dele). Use quando ele pedir para mandar uma mensagem ou arquivo no Telegram, para avisar no Telegram quando uma tarefa terminar, ou quando disser que vai sair e quer continuar a conversa pelo celular.
argument-hint: "[sair [sonnet|haiku|opus] [resumo] | avisa | status | <mensagem ou arquivo>]"
---

# /tg: Telegram

Scripts desta skill (sempre chame pelo caminho completo):
- `${CLAUDE_SKILL_DIR}/send.sh [-m "texto"] [arquivo ...]`: manda texto e/ou arquivos para a conta pareada. `--status` mostra bot, pareamento e sessão.
- `${CLAUDE_SKILL_DIR}/handoff.sh [--model M] [--summary arquivo] <session-id> <pasta>`: leva esta conversa para uma sessão em background (tmux `claude-tg`) ligada ao Telegram. Mantém o modo de permissão desta sessão.

Pedido do usuário: $ARGUMENTS

## Escolha o modo pelo pedido

**1. Sair / vou sair / continuar no celular**
Monte a chamada a partir do pedido:
- Modelo citado (`sonnet`, `haiku`, `opus`) → `--model <nome>`. Sem modelo, não passe a flag (fica o padrão da conta).
- `resumo` (ou "leve", "sem histórico") → escreva em `/tmp/tg-resumo-${CLAUDE_SESSION_ID}.md` um resumo de até 40 linhas com: objetivo, o que já foi feito, arquivos e caminhos envolvidos, decisões tomadas e próximos passos. Passe `--summary <esse arquivo>`. Sem `resumo`, a conversa inteira é copiada.

Rode `${CLAUDE_SKILL_DIR}/handoff.sh [flags] "${CLAUDE_SESSION_ID}" "$(pwd)"`.
- `OK`: diga ao usuário, em 2 linhas, que a conversa continua no Telegram, que ele pode fechar este terminal e que, ao voltar, `tmux attach -t claude-tg` abre a sessão com tudo o que foi falado pelo Telegram. Depois disso, não faça mais trabalho nesta sessão: a cópia no Telegram é quem continua.
- `JA_EXISTE`: pergunte se pode encerrar a sessão antiga (`tmux kill-session -t claude-tg`; ela pode ser retomada depois com `claude --resume`). Só encerre com um sim.
- Falta de pareamento: explique que ele precisa mandar uma mensagem ao bot, receber o código e rodar `tmux attach -t claude-tg` e depois `/telegram:access pair <código>` e `/telegram:access policy allowlist`.

**2. Avisa quando terminar**
Continue (ou faça) a tarefa em andamento normalmente. Ao terminar, e também se travar num erro ou precisar de uma decisão dele, mande pelo `send.sh` um resumo curto em texto simples: o que foi feito, o resultado e o que falta. Anexe os arquivos que a tarefa produziu e que ele vai querer ver.

**3. Status** (sem argumentos ou "status"): rode `send.sh --status` e repasse o resultado.

**4. Qualquer outra coisa:** mande agora o que foi pedido. Texto vai com `-m`. Arquivos vão como argumentos, com caminho absoluto. Se ele falou do arquivo de forma vaga ("manda o relatório"), ache o arquivo antes de mandar e, na dúvida entre vários, pergunte.

## Regras
- Nunca leia, mostre ou copie `~/.claude/channels/telegram/.env` nem o token. Os scripts cuidam disso.
- Se `send.sh` falhar, mostre a mensagem de erro dele ao usuário, sem inventar que foi enviado.
- Dentro da sessão do canal (quando as mensagens chegam como `<channel source="telegram">`), responda pela ferramenta `reply` do plugin; o `send.sh` serve para as demais sessões.
- Se o token precisar ser trocado: o usuário cria `/tmp/telegram-token.txt` com `nano` e roda `${CLAUDE_SKILL_DIR}/set-token.sh`. Nunca peça o token no chat.
