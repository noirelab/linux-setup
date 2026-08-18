---
name: supabase-security-hardening
description: Audita, corrige e verifica a segurança de aplicações web que usam Supabase. Use manualmente para encontrar vazamento de segredos, falhas de RLS/autorização, autenticação fraca, ausência de MFA, rate limiting, CAPTCHA, validação, proteção de APIs, Storage e configurações de produção.
argument-hint: "[audit|fix|verify|report] [escopo opcional]"
arguments:
  - mode
  - scope
disable-model-invocation: true
---

# Supabase Security Hardening

Execute uma revisão defensiva do repositório autorizado atual. Não teste, enumere nem ataque sistemas de terceiros. Não faça exploração destrutiva, exfiltração, persistência, negação de serviço ou testes de carga em produção.

## Entrada

- Modo: `$mode`
- Escopo: `$scope`
- Se o modo estiver vazio, use `audit`.
- Se o escopo estiver vazio, audite o repositório inteiro.

Modos:

- `audit`: somente leitura; produz achados priorizados e plano de correção.
- `fix`: audita e implementa correções seguras no código e em migrations locais.
- `verify`: verifica correções já aplicadas com testes locais ou staging autorizado.
- `report`: gera ou atualiza `SECURITY_AUDIT.md` sem alterar a aplicação.

## Regras inegociáveis

1. Comece em modo somente leitura. Não altere arquivos antes de entender stack, superfícies de ataque e arquitetura de autenticação/autorização.
2. Nunca execute migrations, rotação de chaves, alteração de Auth, WAF, DNS ou deploy em produção sem autorização explícita do usuário.
3. Nunca imprima, copie para o relatório ou envie ao chat valores completos de segredos, tokens, cookies, JWTs, URLs de banco ou dados pessoais. Mostre apenas nome, arquivo e linha; masque valores.
4. Não trate a chave Supabase `publishable` ou a chave legada `anon` como segredo. Elas podem existir no cliente. O controle real deve ser RLS + grants mínimos. Trate `sb_secret_*`, `service_role`, JWT secret, database URL e credenciais de terceiros como segredos críticos.
5. Não prometa que WAF protege chamadas diretas para `*.supabase.co`. WAF no domínio da aplicação só cobre o tráfego que passa por ele. Proteja o Data API com RLS, grants, pre-request checks e, quando necessário, mova operações sensíveis para backend/Edge Function atrás de controles próprios.
6. Não confie apenas em checagens de rota ou papel no frontend. Toda autorização deve ser reenforçada no backend e/ou no banco.
7. Não use `user_metadata` editável pelo usuário para autorização. Use `app_metadata`, claims controladas pelo servidor ou tabelas de associação protegidas por RLS.
8. Não crie autenticação caseira com senha armazenada pela aplicação. Prefira Supabase Auth ou provedor maduro já adotado no projeto.
9. Corrija por migrations versionadas. Não edite apenas o banco remoto pelo Dashboard.
10. Preserve compatibilidade. Para mudanças potencialmente bloqueantes, crie rollout em etapas, feature flag, migration reversível e plano de recuperação.

## Fluxo obrigatório

### 1. Descobrir a arquitetura

Leia, quando existirem:

- `package.json`, lockfiles, `README*`, `CLAUDE.md`
- `.env.example`, arquivos de configuração e ignore files
- clientes Supabase, middleware, API routes, server actions e Edge Functions
- `supabase/config.toml`, `supabase/migrations/**`, `supabase/functions/**`, testes
- configurações de Vercel, Netlify, Cloudflare, Docker, CI/CD
- páginas de login, signup, recuperação, troca de email, admin e formulários públicos

Identifique:

- framework e runtime
- onde Auth, Data API, Storage, Realtime e Edge Functions são usados
- quais operações passam direto do navegador ao Supabase
- quais operações usam backend próprio
- tipos de usuário, tenants, papéis e recursos sensíveis
- ambientes local, preview, staging e produção

### 2. Executar auditoria estática inicial

Execute o scanner incluído:

```bash
python3 "${CLAUDE_SKILL_DIR}/scripts/audit_repo.py" \
  --root "${CLAUDE_PROJECT_DIR}" \
  --format markdown
```

Use o resultado como ponto de partida, não como prova final. Confirme cada achado no contexto do código.

Também use buscas focadas, sem revelar valores:

```bash
rg -n --hidden --glob '!node_modules/**' --glob '!.git/**' \
  'service_role|sb_secret_|SUPABASE_SECRET|DATABASE_URL|JWT_SECRET|PRIVATE_KEY|SECRET_KEY' .

rg -n --hidden --glob 'supabase/migrations/**' \
  'row level security|create policy|security definer|grant all|using\s*\(\s*true\s*\)|with check\s*\(\s*true\s*\)' .
```

Se `rg` não existir, use `grep -RIn` com exclusões equivalentes.

### 3. Auditar por domínio

Use [references/hardening-playbook.md](references/hardening-playbook.md) como checklist detalhado.

#### A. Segredos e chaves

Verifique:

- `service_role`, `sb_secret_*`, JWT signing secret, DB URLs e credenciais de terceiros em código cliente, bundles, logs, fixtures, screenshots, commits e CI
- variáveis sensíveis com prefixos públicos como `VITE_`, `NEXT_PUBLIC_`, `PUBLIC_`, `REACT_APP_` ou `NUXT_PUBLIC_`
- clientes administrativos importáveis pelo frontend
- `auth.admin` ou operações privilegiadas em módulos cliente
- `.env` commitado, `.env.example` com valores reais, source maps e logs contendo segredos

Classificação:

- `sb_publishable_*`/`anon`: informativo; valide RLS e grants, não marque como vazamento por si só.
- `sb_secret_*`/`service_role`: crítico se acessível fora de runtime confiável.
- segredo confirmado em Git: P0; recomendar rotação imediata no provedor, atualização dos secret stores, revogação do antigo, auditoria de uso e limpeza de histórico quando apropriado.

A skill pode preparar mudanças de código e checklist de rotação, mas nunca deve inventar novas chaves nem declarar rotação concluída sem confirmação externa.

#### B. Banco, Data API, RLS e grants

Para cada tabela, view, função e sequência exposta:

- RLS habilitado quando aplicável
- políticas específicas por operação e papel
- `USING` e `WITH CHECK` coerentes
- isolamento por `user_id`, `organization_id` ou tenant verificado
- grants mínimos para `anon` e `authenticated`
- ausência de `GRANT ALL` desnecessário
- funções `SECURITY DEFINER` com owner, grants e `search_path` seguros
- views com comportamento de segurança explícito
- nenhuma autorização baseada em campo controlável pelo cliente
- objetos internos fora de schemas expostos

Trate como P0/P1:

- tabela sensível exposta sem RLS
- política que permite leitura/escrita transversal entre usuários ou tenants
- função privilegiada executável por `anon`/`authenticated` sem necessidade
- `service_role` usado para atender requisições comuns do usuário

Se existir ambiente Supabase local, rode consultas somente leitura de [sql/supabase_security_audit.sql](sql/supabase_security_audit.sql). Para projeto linked/remoto, peça autorização antes.

Use também, quando disponível:

```bash
supabase db lint --local --level warning
```

Não use `--linked` sem autorização explícita.

#### C. MFA/2FA e sessão

Implemente MFA de forma completa, não cosmética:

- obrigatório para administradores, equipe, suporte e qualquer papel privilegiado
- obrigatório para operações sensíveis, mesmo que o restante da conta use MFA opcional
- obrigatório para todos os usuários quando o sistema processa alto risco, dados muito sensíveis ou o usuário solicitar explicitamente
- fluxo de enrollment, challenge, verify, recuperação e remoção de fator
- verificação de `aal2` no backend e em RLS para recursos sensíveis
- redirecionamento seguro para conclusão do MFA quando a sessão está em `aal1`
- notificação e trilha de auditoria para inclusão/remoção de fator

Nunca considere a proteção concluída apenas porque a interface pede código TOTP. Confirme que uma chamada direta à API com sessão `aal1` é negada.

#### D. Auth pronto e fluxos de identidade

Prefira Supabase Auth já integrado ao banco. Verifique:

- confirmação de email quando apropriada
- PKCE nos fluxos server-side/SSR quando suportado
- redirects allowlisted e sem wildcard excessivo em produção
- respostas genéricas para reduzir enumeração de conta
- reautenticação para mudança de email, senha, MFA, dados críticos e ações destrutivas
- confirmação dupla de mudança de email em sistemas sensíveis
- política de senha forte e proteção contra senhas vazadas quando o plano permitir
- sessão com timebox/inatividade/single-session conforme risco
- logout e revogação de sessão funcionando
- `getUser()`/verificação server-side adequada; não confiar apenas em estado do cliente

Ao encontrar auth caseiro, não faça migração destrutiva automática. Produza plano em fases, compatibilidade de usuários, reset seguro e rollback.

#### E. Normalização e verificação de email

Aplique uma política única em signup, login, recuperação, linking e troca de email:

- `trim` de espaços externos
- normalização Unicode definida e testada
- domínio em lowercase e convertido para formato canônico/IDN seguro quando necessário
- preservar o valor original para exibição, quando útil
- não remover pontos nem aliases `+` de Gmail por padrão
- não inventar regex rígida; use biblioteca madura e verificação de propriedade
- comparar de forma consistente em todos os fluxos
- impedir diferenças entre frontend, backend e banco que criem contas duplicadas ou confusão de identidade
- mascarar email em logs e nunca registrar tokens/links completos

Se a arquitetura decide lowercasing do local-part, documente a decisão e teste colisões antes de migrar dados existentes.

#### F. Rate limiting e anti-automação

Aplique defesa em profundidade a:

- login, signup, OTP, resend, reset de senha, magic link e MFA verify
- criação de conta anônima
- formulários públicos e upload
- endpoints de busca, exportação, geração de conteúdo, webhooks e ações caras
- mutações de dados e ações administrativas

Combine chaves de limite conforme o caso:

- IP confiável do proxy
- usuário autenticado
- tenant/organização
- identificador normalizado e hasheado, nunca email puro no log
- rota e tipo de ação

Use limite progressivo, `429`, `Retry-After`, backoff e desafio adicional. Evite lockout rígido que permita DoS contra uma conta. Não confie em `X-Forwarded-For` vindo diretamente da internet; aceite-o somente de proxies conhecidos.

Primeiro aproveite os rate limits nativos do Supabase Auth. Para endpoints próprios, use mecanismo centralizado e atômico. Cloudflare WAF/rate limiting pode proteger o domínio da aplicação, mas não substitui limites no backend nem RLS no Supabase.

Não aplique números arbitrários como verdade universal. Registre uma baseline inicial, justifique os thresholds e permita ajuste por ambiente.

#### G. CAPTCHA/Turnstile

Para Supabase Auth, habilite hCaptcha ou Cloudflare Turnstile nos fluxos suportados. Para formulários e endpoints próprios:

- renderize sitekey pública no cliente
- envie o token ao backend
- valide server-side usando o secret privado
- rejeite token ausente, inválido, expirado, duplicado ou de hostname/action inesperado
- use chaves separadas por ambiente
- nunca considere apenas o widget do frontend como proteção
- combine com rate limiting; CAPTCHA sozinho não resolve abuso

#### H. Edge Functions, APIs e validação

Em cada endpoint:

- método HTTP allowlisted
- autenticação declarada e JWT validado no servidor
- autorização por recurso/tenant
- schema validation de body, params e query
- limite de tamanho de payload e upload
- CORS com origins explícitas em produção
- CSRF quando autenticação depende de cookies
- rate limiting e idempotência em ações críticas
- timeouts, retries limitados e tratamento de erro sem stack trace
- segredo apenas em runtime server-side
- queries parametrizadas; nada de SQL concatenado
- SSR cria cliente por request e não compartilha sessão entre usuários

#### I. Storage

Verifique:

- buckets públicos somente quando conteúdo é realmente público
- políticas em `storage.objects` por bucket, owner, tenant e operação
- upload com limites de MIME, extensão, tamanho e quantidade
- nomes de arquivo gerados pelo servidor quando necessário
- URLs assinadas com expiração curta para arquivos privados
- service key jamais no cliente
- prevenção de listagem e acesso transversal
- processamento seguro de arquivos e isolamento de conteúdo ativo

#### J. WAF, headers e superfície de rede

Recomende/implemente conforme o deploy:

- Cloudflare WAF managed rules e custom rules com rollout em log/challenge antes de block
- rate limiting no edge para rotas públicas críticas
- Turnstile para formulários e autenticação
- HTTPS, HSTS após confirmar cobertura total, CSP ajustada, `frame-ancestors`, `nosniff`, Referrer-Policy e Permissions-Policy
- proteção de previews/admin com Access, autenticação ou restrição de rede
- SSL enforcement e network restrictions no banco quando disponíveis e compatíveis
- Data API desabilitado se o projeto não o utiliza

Documente claramente quais endpoints passam pelo WAF e quais continuam acessíveis diretamente no Supabase.

#### K. Logging, monitoramento e resposta

Verifique:

- Auth audit logs e Security Advisor revisados
- alertas para falhas repetidas, picos de signup/reset, 401/403/429 e ações administrativas
- logs estruturados sem senha, token, cookie, segredo ou PII completa
- correlação por request ID
- retenção e acesso mínimos
- procedimento de incidente e rotação
- backup/PITR e teste de restauração conforme criticidade

### 4. Priorizar achados

Use:

- **P0 Crítico**: exposição ativa de segredo privilegiado, bypass de autorização, acesso cruzado a dados, RCE/SQLi, tabela sensível pública, admin sem proteção real.
- **P1 Alto**: RLS incompleto, MFA ausente em admin, endpoints de auth/recuperação abusáveis, Storage privado exposto, função privilegiada ampla.
- **P2 Médio**: headers, sessão excessiva, logging sensível parcial, CAPTCHA/rate limit ausente em fluxo de menor risco.
- **P3 Baixo**: hardening adicional, documentação, observabilidade e melhorias de defesa em profundidade.

Cada achado deve conter:

1. evidência com arquivo/linha ou query
2. cenário de impacto defensivo, sem instruções de exploração contra terceiros
3. severidade e confiança
4. correção mínima e correção ideal
5. arquivos/migrations afetados
6. teste de regressão e teste de segurança
7. ação externa necessária no Dashboard/provedor

### 5. Implementar no modo `fix`

Antes de editar, apresente o plano resumido. Depois:

- corrija primeiro P0/P1 confirmados
- gere migrations idempotentes/revisáveis
- preserve uma via de acesso administrativo segura
- adicione testes negativos: usuário A não acessa B, `anon` não escreve, `aal1` não executa ação sensível, token CAPTCHA inválido falha, rate limit retorna 429
- adicione `.env.example` apenas com nomes/placeholders
- atualize documentação de deploy e Dashboard
- não faça rotação real nem deploy sem autorização

Para mudanças que dependem do Dashboard, crie `SECURITY_DASHBOARD_ACTIONS.md` usando [templates/dashboard-actions.md](templates/dashboard-actions.md).

### 6. Verificar

No modo `verify` ou após `fix`:

- execute lint, typecheck, testes unitários e integração
- suba Supabase local quando o projeto suportar
- aplique migrations em ambiente descartável
- execute testes com `anon`, usuário A, usuário B, admin `aal1` e admin `aal2`
- valide que operações permitidas continuam funcionando
- valide que erros não vazam detalhes
- rode `supabase db lint --local`
- execute o scanner novamente e compare o delta

Nunca execute carga agressiva. Teste rate limits com poucos requests controlados em local/staging.

### 7. Entrega

Use [templates/security-report.md](templates/security-report.md) para produzir a resposta e, quando solicitado, `SECURITY_AUDIT.md`.

Separe explicitamente:

- corrigido no repositório
- verificado localmente
- pendente de configuração externa
- pendente de rotação/revogação
- risco aceito pelo usuário
- não verificável com o acesso atual

Não diga “site seguro” ou “100% protegido”. Diga quais controles foram avaliados, implementados e testados, e quais limites permanecem.

## Recursos adicionais

- Checklist detalhado: [references/hardening-playbook.md](references/hardening-playbook.md)
- Consultas SQL somente leitura: [sql/supabase_security_audit.sql](sql/supabase_security_audit.sql)
- Scanner estático: [scripts/audit_repo.py](scripts/audit_repo.py)
- Modelo de relatório: [templates/security-report.md](templates/security-report.md)
- Ações externas: [templates/dashboard-actions.md](templates/dashboard-actions.md)
