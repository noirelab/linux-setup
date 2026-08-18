# SECURITY_AUDIT

## Escopo

- Repositório:
- Branch/commit:
- Data:
- Modo: audit | fix | verify | report
- Ambientes avaliados: local | preview | staging | produção
- Componentes: frontend | backend | Supabase Auth | Data API | Storage | Realtime | Edge Functions | WAF
- Limitações de acesso:

## Resumo executivo

Descreva em linguagem direta:

- risco geral observado, sem declarar segurança absoluta
- principais superfícies de ataque
- P0/P1 confirmados
- mudanças implementadas
- ações externas ainda necessárias

## Contagem

| Severidade | Confirmados | Corrigidos | Pendentes | Aceitos |
|---|---:|---:|---:|---:|
| P0 | 0 | 0 | 0 | 0 |
| P1 | 0 | 0 | 0 | 0 |
| P2 | 0 | 0 | 0 | 0 |
| P3 | 0 | 0 | 0 | 0 |

## Achados

### [P0/P1/P2/P3] Título

- **ID:**
- **Status:** confirmado | corrigido | parcialmente corrigido | pendente | aceito
- **Confiança:** alta | média | baixa
- **Local:** `arquivo:linha` ou query
- **Evidência:** sem expor segredo, token ou PII
- **Impacto:** cenário defensivo e recursos afetados
- **Correção mínima:**
- **Correção ideal:**
- **Mudanças realizadas:**
- **Teste de segurança:**
- **Teste de regressão:**
- **Ação externa:** Dashboard/provedor/rotação/deploy
- **Rollback:**

## Controles avaliados

### Segredos e chaves

- [ ] publishable/anon corretamente tratados como públicos
- [ ] nenhum secret/service_role no cliente
- [ ] módulos administrativos server-only
- [ ] histórico e artifacts revisados
- [ ] rotação/revogação confirmada quando necessária

### Banco e RLS

- [ ] RLS nas relações expostas
- [ ] grants mínimos
- [ ] isolamento entre usuários
- [ ] isolamento entre tenants
- [ ] USING/WITH CHECK coerentes
- [ ] SECURITY DEFINER/search_path revisados
- [ ] Security Advisor/db lint revisados

### Auth e MFA

- [ ] auth maduro; sem senha caseira
- [ ] MFA obrigatório para privilegiados
- [ ] AAL2 reenforçado no backend
- [ ] AAL2 reenforçado em RLS sensível
- [ ] recuperação e remoção de fator seguras
- [ ] redirects, PKCE e sessão revisados
- [ ] mudança de email/senha exige reautenticação conforme risco

### Anti-abuso

- [ ] limites nativos do Supabase Auth revisados
- [ ] rate limiting em endpoints próprios
- [ ] limite por IP + identidade + usuário/tenant quando adequado
- [ ] CAPTCHA validado server-side
- [ ] 429/Retry-After/backoff
- [ ] sem hard lockout vulnerável a DoS

### APIs e Edge Functions

- [ ] autenticação
- [ ] autorização por recurso/tenant
- [ ] validação de schema
- [ ] CORS explícito
- [ ] CSRF quando aplicável
- [ ] payload/upload limits
- [ ] idempotência
- [ ] erros e logs seguros

### Storage

- [ ] buckets públicos justificados
- [ ] políticas por bucket/owner/tenant
- [ ] listagem restrita
- [ ] MIME/tamanho/quota
- [ ] URLs assinadas para privado

### WAF e headers

- [ ] rotas realmente cobertas pelo WAF identificadas
- [ ] managed/custom rules com rollout seguro
- [ ] rate limiting no edge
- [ ] CSP/HSTS/nosniff/referrer/permissions/frame-ancestors
- [ ] admin/previews protegidos

### Observabilidade

- [ ] Auth audit logs
- [ ] alertas 401/403/429 e auth abuse
- [ ] ações administrativas auditadas
- [ ] logs sem segredo/token/PII completa
- [ ] backup/PITR/restauração conforme risco

## Alterações no repositório

Liste arquivos e migrations alterados, com motivo.

## Verificação executada

| Verificação | Ambiente | Resultado | Evidência |
|---|---|---|---|
| Scanner estático | local | | |
| Lint/typecheck | local | | |
| Testes unitários | local | | |
| Testes RLS A/B | local/staging | | |
| MFA aal1/aal2 | local/staging | | |
| CAPTCHA inválido/replay | local/staging | | |
| Rate limit controlado | local/staging | | |
| db lint | local | | |

## Ações externas pendentes

Copie itens de `SECURITY_DASHBOARD_ACTIONS.md` e atribua responsável/data.

## Riscos residuais

Declare limites concretos. Exemplos:

- configuração do Dashboard não foi acessada
- rotação ainda não confirmada
- WAF cobre app.example.com, mas não chamadas diretas a project-ref.supabase.co
- testes foram locais, não em staging
- fluxo legado ainda depende de migration futura

## Conclusão

Informe controles confirmados, controles pendentes e próxima revisão. Não use “100% seguro”.
