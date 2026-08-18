# SECURITY_DASHBOARD_ACTIONS

Use este documento para ações que não podem ser concluídas apenas pelo repositório. Nunca cole valores de segredo aqui.

## Supabase — API Keys

- [ ] Migrar para `sb_publishable_*` e `sb_secret_*` quando aplicável.
- [ ] Confirmar que chaves legadas desnecessárias foram desabilitadas.
- [ ] Rotacionar/revogar secret/service_role exposto.
- [ ] Registrar responsável, data e confirmação de revogação.

## Supabase — Auth

- [ ] Habilitar/configurar CAPTCHA (Turnstile ou hCaptcha).
- [ ] Revisar rate limits por endpoint.
- [ ] Configurar custom SMTP de produção.
- [ ] Confirmar email verification.
- [ ] Confirmar double confirm para mudança de email quando exigido.
- [ ] Configurar política de senha e leaked password protection quando disponível.
- [ ] Revisar Site URL e Redirect URLs; remover wildcards excessivos.
- [ ] Revisar session timebox, inactivity timeout e single-session.
- [ ] Habilitar security notification emails relevantes.
- [ ] Revisar Auth audit logs.

## Supabase — Database

- [ ] Executar/revisar Security Advisor.
- [ ] Confirmar RLS em todas as relações expostas.
- [ ] Revisar schemas expostos no Data API.
- [ ] Desabilitar Data API se não usado.
- [ ] Revisar SSL enforcement e network restrictions.
- [ ] Configurar backup/PITR conforme RPO/RTO.

## Supabase — Storage

- [ ] Revisar buckets públicos.
- [ ] Revisar políticas de `storage.objects`.
- [ ] Confirmar limites de tamanho e MIME.

## Cloudflare/WAF

- [ ] Confirmar DNS proxied nos hostnames desejados.
- [ ] Habilitar managed rules adequadas.
- [ ] Criar custom rules em log/challenge antes de block.
- [ ] Criar rate limiting para login, signup, reset, forms e APIs próprias.
- [ ] Configurar Turnstile com hostnames corretos.
- [ ] Usar widgets/chaves separados por ambiente.
- [ ] Confirmar server-side Siteverify.
- [ ] Revisar analytics e falsos positivos.
- [ ] Proteger admin/previews com Access quando aplicável.

## Deploy/CI

- [ ] Secret stores atualizados em todos os ambientes.
- [ ] Artifacts/builds antigos invalidados após exposição.
- [ ] Source maps e logs revisados.
- [ ] Secret scanning habilitado no repositório/CI.
- [ ] Testes de RLS e security gates no CI.

## Registro

| Ação | Ambiente | Responsável | Prazo | Status | Evidência sem segredo |
|---|---|---|---|---|---|
| | | | | | |
