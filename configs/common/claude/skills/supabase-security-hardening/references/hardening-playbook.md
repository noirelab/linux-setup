# Playbook de hardening para Supabase

Use este arquivo como referência detalhada durante a auditoria. Confirme a versão atual das bibliotecas e dos serviços antes de implementar APIs específicas.

## 1. Modelo de responsabilidade

Supabase fornece primitives seguras, mas a aplicação continua responsável por:

- políticas de autorização e isolamento de tenant
- grants de banco
- segredo em runtime confiável
- validação de entrada
- limites de abuso
- configuração de Auth, Storage, redirects e SMTP
- segurança do frontend, backend, deploy e DNS
- monitoramento e resposta a incidentes

A presença do SDK Supabase ou de uma tela de login não comprova autorização correta.

## 2. Chaves: o que pode e o que não pode aparecer no frontend

### Permitido no cliente

- `sb_publishable_*`
- chave legada `anon`
- URL pública do projeto Supabase
- Turnstile/hCaptcha sitekey

Esses valores identificam o projeto/cliente, mas não devem conceder acesso indevido. O acesso é limitado por grants, RLS e JWT do usuário.

### Proibido no cliente

- `sb_secret_*`
- chave legada `service_role`
- JWT signing secret
- connection strings Postgres
- SMTP password
- Turnstile/hCaptcha secret
- Stripe secret, webhook secret
- OpenAI/Anthropic API keys
- Resend/SendGrid/SES secrets
- credenciais de S3 ou qualquer admin token

### Rotação após exposição

1. Pare a publicação do artefato vulnerável quando necessário.
2. Gere uma nova credencial no provedor.
3. Atualize secret stores de local, CI, preview, staging e produção.
4. Faça deploy sem registrar o valor.
5. Revogue/desabilite a credencial antiga.
6. Audite logs e uso durante a janela de exposição.
7. Limpe histórico Git quando isso reduzir exposição futura, sem confundir limpeza com revogação.
8. Invalide caches, artifacts e source maps que contenham o segredo.
9. Documente data, escopo, responsável e evidência de conclusão.

Migrar de chaves legadas para `publishable`/`secret` facilita separação e rotação. Não assuma que criar chaves novas revoga as legadas.

## 3. Padrão de cliente Supabase

### Cliente browser

- apenas publishable/anon
- sessão do usuário
- nenhuma API administrativa
- operações autorizadas por RLS

### Cliente server-side comum

- prefira propagar JWT do usuário para preservar RLS
- crie cliente por request em SSR
- não compartilhe sessão entre requisições
- valide o usuário no servidor

### Cliente administrativo

- segredo apenas no servidor
- módulo marcado server-only quando o framework suportar
- não exportado por barrel compartilhado com frontend
- uso mínimo, com autorização própria e audit log
- não usar para “resolver” erro de RLS

## 4. RLS e isolamento de dados

### Regras gerais

- habilite RLS em toda relação exposta que contenha dados não públicos
- crie políticas separadas e legíveis por operação
- use `TO authenticated` ou papel específico
- use `USING` para linhas existentes e `WITH CHECK` para novas versões da linha
- indexe colunas usadas por políticas, como `user_id` e `organization_id`
- use `select auth.uid()`/`select auth.jwt()` quando apropriado para melhor plano
- teste com usuários distintos e tenants distintos

### Política típica por proprietário

```sql
alter table public.documents enable row level security;

create policy "users read own documents"
on public.documents
for select
to authenticated
using ((select auth.uid()) = owner_id);

create policy "users create own documents"
on public.documents
for insert
to authenticated
with check ((select auth.uid()) = owner_id);

create policy "users update own documents"
on public.documents
for update
to authenticated
using ((select auth.uid()) = owner_id)
with check ((select auth.uid()) = owner_id);
```

Não copie esse padrão sem confirmar o modelo real. Em SaaS multi-tenant, verifique associação ativa à organização em tabela protegida.

### MFA em RLS

Para tabela cuja utilização sempre exige MFA:

```sql
create policy "require aal2"
on public.sensitive_records
as restrictive
for all
to authenticated
using ((select auth.jwt()->>'aal') = 'aal2')
with check ((select auth.jwt()->>'aal') = 'aal2');
```

Use política restritiva para que outra política permissiva não contorne a exigência. Teste `aal1` e `aal2`.

### Papéis e claims

- não use `raw_user_meta_data`/`user_metadata` para autorização
- prefira `raw_app_meta_data`/`app_metadata` controlado pelo servidor ou tabela de membership
- não aceite `role`, `is_admin`, `organization_id` ou `owner_id` enviados pelo cliente sem recalcular/verificar
- mudanças de papel exigem operação administrativa protegida e auditada

### Funções e RPC

- revogue `EXECUTE` de `public`, `anon` e `authenticated` quando não necessário
- qualifique schemas
- em `SECURITY DEFINER`, fixe `search_path` seguro e mínimo
- valide o chamador e o recurso dentro da função
- evite SQL dinâmico; quando necessário, use quoting e allowlists
- mantenha helpers de RLS em schema não exposto quando possível

Exemplo de declaração mais segura:

```sql
create or replace function private.example()
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  -- lógica autorizada
end;
$$;

revoke all on function private.example() from public, anon, authenticated;
```

A lista exata do `search_path` depende das dependências da função.

### Views

- verifique se a view executa como invoker ou creator na versão atual do Postgres
- não exponha colunas sensíveis por view aparentemente “segura”
- grants na view não substituem a análise das tabelas/funções subjacentes

## 5. Grants e schemas

- use schema dedicado para superfície de API quando isso simplificar auditoria
- mantenha tabelas internas em schema não exposto
- revogue default privileges amplos em projetos antigos quando compatível
- conceda somente operações necessárias
- RLS e grants são camadas diferentes; use ambas
- desabilite Data API se nenhuma biblioteca REST/GraphQL/SDK cliente depender dela

Antes de revogar defaults, faça inventário e teste completo; mudanças podem quebrar APIs existentes.

## 6. MFA obrigatório

### Escopo recomendado

- sempre: owner, admin, suporte, operador e contas de equipe
- sempre: mudança de email, senha, fator MFA, papel, dados bancários, exportação, exclusão e ações destrutivas
- todos os usuários: aplicações financeiras, saúde, dados altamente sensíveis ou exigência contratual

### Implementação completa

1. Login inicial gera sessão `aal1`.
2. Consulte AAL atual/próximo e fatores disponíveis.
3. Sem fator: direcione para enrollment TOTP.
4. Com fator: challenge e verify.
5. Atualize sessão e confirme `aal2`.
6. Backend verifica claim antes de operação.
7. RLS restritiva reforça `aal2` no dado sensível.
8. Mudança/remoção de fator exige reautenticação e gera notificação.
9. Defina recuperação segura para perda do dispositivo.

Não use SMS como única escolha para administradores quando TOTP ou fator resistente a phishing estiver disponível no provedor adotado.

## 7. Email como identidade

### Canonicalização

- remova espaços externos
- normalize Unicode de forma consistente
- normalize domínio para lowercase
- converta domínio internacionalizado de modo consistente para comparação
- preserve original para exibição/comunicação
- não aplique regras específicas de Gmail a domínios que você não controla
- documente tratamento do local-part

### Fluxos

A mesma função/política deve ser usada em:

- signup
- login
- password reset
- magic link/OTP
- account linking
- mudança de email
- convites
- busca administrativa

### Mudança de email

- trate como mudança de identidade
- exija sessão recente/MFA para conta privilegiada
- notifique endereço antigo
- confirme endereço novo
- considere dupla confirmação
- invalide ou revise sessões conforme risco

### Anti-enumeração

- mensagens equivalentes para conta existente/inexistente
- tempos semelhantes quando viável
- limite por IP e hash do identificador
- não exponha resultado em logs ou analytics

## 8. Senhas, OTP e sessão

- use Supabase Auth/provedor maduro
- configure mínimo de senha coerente com risco
- habilite proteção contra senha vazada quando disponível
- não imponha regras que incentivem padrões previsíveis sem necessidade
- limite envio e verificação de OTP
- não registre OTP, reset token, magic link ou URL completa
- configure custom SMTP em produção
- revise timebox, inactivity timeout e single-session para perfis privilegiados
- exija reautenticação para ação sensível
- use PKCE em fluxos server-side compatíveis
- restrinja redirects; evite wildcard amplo em produção

## 9. Rate limiting

### Camadas

1. limites nativos do Supabase Auth
2. rate limit no backend/Edge Function
3. limite no WAF/edge para tráfego que passa pelo domínio
4. quota por usuário/tenant para consumo de recursos
5. RLS/grants para autorização; rate limit nunca substitui autorização

### Chaves compostas

- rota + IP
- rota + user id
- rota + tenant
- rota + hash do email/telefone normalizado
- ação cara + recurso

### Comportamento

- algoritmo atômico centralizado
- resposta `429`
- `Retry-After`
- backoff progressivo
- challenge após sinais de abuso
- métricas por rota e decisão
- allowlist somente para integrações controladas
- limites distintos por ambiente

### Baseline inicial sugerida

Use somente como ponto de partida e ajuste com métricas:

- contato público: 5 submissões/10 min/IP
- signup: 3/30 min/IP, CAPTCHA
- reset: 3/hora/identificador e 10/hora/IP
- login: challenge progressivo após falhas; limite por IP + identificador
- OTP/MFA verify: poucas tentativas em janela curta e cooldown de resend
- exportações e IA: quota por usuário/tenant, além de limite por minuto

Não use bloqueio rígido longo por conta como única defesa, pois permite que terceiros causem negação de serviço.

## 10. CAPTCHA e Turnstile

### Supabase Auth

Habilite proteção nativa nos fluxos suportados e envie `captchaToken` nas chamadas do SDK conforme documentação da versão usada.

### Endpoint próprio

Fluxo obrigatório:

1. widget produz token
2. cliente envia token junto à requisição
3. backend chama Siteverify com secret privado
4. backend valida `success`, hostname/action quando usados e códigos de erro
5. backend processa a ação apenas após validação

Tokens Turnstile são de curta duração e uso único; implemente refresh e erros recuperáveis. Use chaves de teste oficiais em E2E, nunca em produção.

## 11. Edge Functions e APIs

Checklist por endpoint:

- autenticação necessária?
- método permitido?
- origin permitido?
- schema validado?
- tamanho máximo?
- usuário tem acesso ao recurso?
- tenant coincide?
- `aal2` exigido?
- rate limit aplicado?
- idempotency key necessária?
- segredo está server-side?
- timeout e retry são limitados?
- resposta mascara detalhes internos?
- log omite PII/segredo?

Para webhooks:

- valide assinatura no corpo bruto
- use timestamp/nonce quando o provedor suporta
- rejeite replay
- idempotência por event id
- não confie apenas em IP

## 12. Storage

- bucket público significa leitura pública; use apenas para assets realmente públicos
- bucket privado + URL assinada para conteúdo do usuário
- políticas por `bucket_id`, path, owner e tenant
- restrinja listagem
- valide MIME real, tamanho e extensão
- evite servir HTML/SVG ativo em domínio principal quando não confiável
- faça scanning/quarentena quando o risco justificar
- remova metadados sensíveis de imagens quando necessário
- imponha quota por usuário/tenant

## 13. WAF e Cloudflare

### O que o WAF cobre

Somente requests que chegam a um hostname/zone protegido e passam pela Cloudflare. Chamadas do browser diretamente para `project-ref.supabase.co` não passam automaticamente pelo WAF do domínio da aplicação.

### Estratégia

- managed rules em modo compatível
- custom rules para admin, previews, países/ASN quando justificável
- rate limiting em login/form/API própria
- Managed Challenge antes de bloqueio definitivo quando há risco de falso positivo
- Turnstile para forms/auth
- Cloudflare Access para backoffice/previews quando aplicável
- logs e revisão de falsos positivos

Não use WAF para encobrir RLS quebrado.

## 14. Security headers

Revise no framework/deploy:

- `Content-Security-Policy`
- `Strict-Transport-Security` após HTTPS total
- `X-Content-Type-Options: nosniff`
- `Referrer-Policy`
- `Permissions-Policy`
- `frame-ancestors` na CSP
- cookies `Secure`, `HttpOnly`, `SameSite` quando aplicável

Construa CSP a partir dos recursos realmente usados. Turnstile exige allowlist específica para seus scripts/frames.

## 15. Observabilidade

Alertas mínimos:

- crescimento abrupto de 401/403/429
- falhas de login/reset/MFA por usuário e IP
- criação incomum de contas
- mudanças de papel/MFA/email
- uso de endpoint administrativo
- picos de egress/download/exportação
- erros de RLS e tentativas de acesso cruzado
- uso anormal de APIs pagas

Nunca logue:

- senha
- access/refresh token
- cookie de sessão
- service key
- authorization header
- OTP/reset token
- URL completa de magic link
- corpo completo com PII sem necessidade

## 16. CI/CD

- secret scanning no pre-commit e CI
- dependency audit com triagem real
- lint/typecheck/test
- Supabase local em CI quando viável
- migrations aplicadas em banco descartável
- testes de RLS com múltiplos usuários
- `supabase db lint`
- build client inspecionado para segredo privilegiado
- deploy bloqueado por P0/P1 confirmado
- previews isolados de produção

## 17. Testes de segurança mínimos

### RLS

- anon sem acesso indevido
- usuário A acessa próprio recurso
- usuário A não acessa recurso de B
- tenant A não acessa tenant B
- update não permite trocar owner/tenant
- delete respeita papel

### MFA

- admin `aal1` recebe negação/redirecionamento
- admin `aal2` funciona
- chamada direta ao endpoint com `aal1` falha
- RLS bloqueia operação sensível com `aal1`

### CAPTCHA/rate limit

- token ausente falha
- token inválido falha
- token reutilizado falha
- limite controlado retorna 429
- request legítimo após janela volta a funcionar

### Segredos

- bundle final não contém segredo privilegiado
- logs não mostram token
- módulos admin não são importados pelo cliente

## 18. Fontes oficiais

Anthropic Claude Code Skills:
- https://code.claude.com/docs/en/skills

Supabase:
- https://supabase.com/docs/guides/getting-started/api-keys
- https://supabase.com/docs/guides/api/securing-your-api
- https://supabase.com/docs/guides/database/postgres/row-level-security
- https://supabase.com/docs/guides/database/database-advisors
- https://supabase.com/docs/guides/auth/auth-mfa
- https://supabase.com/docs/guides/auth/auth-captcha
- https://supabase.com/docs/guides/auth/rate-limits
- https://supabase.com/docs/guides/auth/password-security
- https://supabase.com/docs/guides/auth/sessions
- https://supabase.com/docs/guides/auth/redirect-urls
- https://supabase.com/docs/guides/storage/security/access-control
- https://supabase.com/docs/guides/deployment/going-into-prod
- https://supabase.com/docs/reference/cli/overview

Cloudflare:
- https://developers.cloudflare.com/turnstile/get-started/server-side-validation/
- https://developers.cloudflare.com/waf/rate-limiting-rules/
- https://developers.cloudflare.com/waf/custom-rules/

OWASP:
- https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- https://cheatsheetseries.owasp.org/cheatsheets/Multifactor_Authentication_Cheat_Sheet.html
- https://cheatsheetseries.owasp.org/cheatsheets/Credential_Stuffing_Prevention_Cheat_Sheet.html
- https://cheatsheetseries.owasp.org/cheatsheets/Email_Validation_and_Verification_Cheat_Sheet.html
- https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html
- https://cheatsheetseries.owasp.org/cheatsheets/Forgot_Password_Cheat_Sheet.html
