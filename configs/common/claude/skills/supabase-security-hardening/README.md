# Supabase Security Hardening — Claude Code Skill

Skill manual para auditar, corrigir e verificar aplicações Supabase sem confundir chaves públicas com segredos e sem aplicar mudanças destrutivas em produção.

## Instalação pessoal

Copie a pasta inteira para:

```bash
~/.claude/skills/supabase-security-hardening/
```

Exemplo:

```bash
mkdir -p ~/.claude/skills
cp -R supabase-security-hardening ~/.claude/skills/
```

## Instalação por projeto

```bash
mkdir -p .claude/skills
cp -R supabase-security-hardening .claude/skills/
```

## Uso

```text
/supabase-security-hardening audit
/supabase-security-hardening audit auth,rls,secrets
/supabase-security-hardening fix
/supabase-security-hardening verify
/supabase-security-hardening report
```

A skill é manual (`disable-model-invocation: true`) porque o modo `fix` pode criar migrations e alterar autenticação/autorização. Ela começa sempre por auditoria somente leitura e não deve tocar produção sem autorização explícita.

## Conteúdo

- `SKILL.md`: fluxo principal
- `scripts/audit_repo.py`: scanner estático defensivo
- `sql/supabase_security_audit.sql`: queries somente leitura
- `references/hardening-playbook.md`: playbook detalhado
- `templates/security-report.md`: relatório
- `templates/dashboard-actions.md`: ações externas
- `tests/test_audit_repo.py`: testes do scanner

## Limites

A skill não substitui pentest profissional, revisão humana, acesso ao Dashboard, monitoramento real ou testes autorizados em staging. O scanner usa heurísticas e pode gerar falsos positivos/negativos.

## Testes

```bash
python3 -m unittest discover -s tests -v
```
