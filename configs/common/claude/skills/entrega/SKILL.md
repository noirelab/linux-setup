---
name: entrega
description: Fecha uma task com três entregas: a mensagem do PR (com tabela de arquivos criados, alterados e removidos), um PDF curto para leigos (fluxogramas, gráficos, sem jargão) e um PPTX de slides simples para apresentar ao grupo. Use antes de dizer que uma task terminou, ou quando o usuário pedir "entrega", "fecha a task", "mensagem do PR", "PDF da task", "slides da task" ou "preparar apresentação".
---

# Entrega da task

Rode depois das skills de revisão do PR (`verification-loop`, `simplify`, `code-review`, `security-review`), para que tudo descreva o código final.

## 0. Decidir o tamanho

Leia o diff completo (`git diff <base>...HEAD`, mais `git status` para arquivos não commitados) e o histórico da conversa. Base = branch de destino do PR (normalmente `develop` ou `main`).

- **Diff trivial** (typo, bump de versão, valor de config, só formatação): faça só a mensagem do PR e diga que pulou PDF e PPTX.
- **Qualquer outra coisa:** as três entregas.

Saída em `~/Downloads/<slug-da-task>/`: `PR.md`, `<slug>.pdf`, `<slug>.pptx` e `figs/`. Não coloque no repositório; pergunte ao usuário se quer versionar.

## 1. Mensagem do PR (`PR.md`)

```markdown
## Resumo
<2 a 4 frases: problema, o que foi feito, efeito.>

## Arquivos

| Arquivo | Situação | O que mudou |
|---|---|---|
| `src/x.py` | criado | ... |
| `src/y.py` | alterado | ... |
| `old/z.py` | removido | ... |

## Como testar
<comandos e resultado esperado>

## Pontos de atenção
<decisões em aberto, limitações, o que fica para outra task. Omita se não houver.>
```

- A coluna Situação vem de `git diff --name-status` (A = criado, M = alterado, D = removido, R = renomeado), nunca da memória.
- Uma linha por arquivo. Testes entram na tabela.
- Sem atribuição de IA (regra do CLAUDE.md global).

## 2. PDF para leigos

Estrutura:

1. **O problema**: o que estava errado ou faltando, em linguagem do dia a dia.
2. **O que foi feito**: uma frase em negrito com o resultado.
3. **Como funciona**: um fluxograma e uma analogia ("funciona como um professor corrigindo uma prova").
4. **Resultados**: gráficos com números reais da task (testes, medições, antes e depois). Cada gráfico tem legenda e um "o que o gráfico mostra" em tópicos.
5. **O que muda na prática**: para quem usa o sistema.
6. **Decisões em aberto**: numeradas, com a recomendação.
7. **Perguntas e respostas**: 8 a 15 perguntas que alguém de fora faria ("o que é X?", "isso já funciona?", "por que não Y?").

Regras de escrita:
- Escreva para quem não é da área. Todo termo técnico é explicado na primeira vez em que aparece, ou trocado por palavra comum.
- Sem código no texto. Print de terminal só quando ele for a prova (testes passando), e com uma frase explicando o que é.
- Frases curtas. Sem travessão, sem emoji.
- Nenhum dado real de cliente (nome, CNPJ, valor). Use exemplos inventados e diga que são inventados.
- Só números que você mediu ou leu nesta task. Não invente métrica.

Figuras:
- Fluxogramas, trechos de terminal: `uv run --with pygments python3 ~/.claude/skills/entrega/scripts/figs.py spec.json` (formato do spec no docstring do script; `kind: flow` aceita colunas com várias caixas e cores `blue|green|orange|purple|gray|red`).
- Gráficos: matplotlib via `uv run --with matplotlib`, PNG em 2x, verde para bom, laranja para atenção, rótulo do valor em cima de cada barra. Escala comprimida só com aviso na legenda.

Geração: escreva `<slug>.md` com as imagens em `figs/` e converta com a skill `make-pdf`. Depois renderize as páginas em PNG (`pdftoppm -r 60`) e olhe todas: figura cortada, página quase vazia ou tabela quebrada é defeito.

## 3. PPTX para o grupo

Use a skill `anthropic-skills:pptx` (PptxGenJS). Público: o grupo, nem todos da área.

- 5 a 8 slides: capa; o problema; o que foi feito (fluxograma); resultados (1 gráfico por slide, com uma frase dizendo a conclusão); o que muda na prática; decisões para discutir.
- Reaproveite as figuras do PDF.
- No máximo 4 tópicos por slide, cada um com até 12 palavras. O detalhe fica no PDF, não no slide.
- Sem código, sem tabela de números. Um número só entra se for o resultado principal ("0 alarmes falsos"), grande e com uma frase do que significa.
- Rodapé com projeto e task, número do slide.
- Renderize os slides em imagem e olhe todos antes de entregar: texto estourando a caixa é defeito.

## 4. Fechar

Responda com o caminho dos três arquivos, o resumo do PR e qualquer coisa que ficou de fora (por exemplo, "sem gráfico de desempenho: não houve medição nesta task").
