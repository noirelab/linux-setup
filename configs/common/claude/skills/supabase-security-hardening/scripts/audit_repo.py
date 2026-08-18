#!/usr/bin/env python3
"""Defensive static scanner for Supabase-oriented web repositories.

This scanner is intentionally conservative. It reports heuristics that must be
confirmed by a human/agent in code context. It never prints secret values.
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import re
import subprocess
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable, Sequence

IGNORE_DIRS = {
    ".git",
    ".hg",
    ".svn",
    "node_modules",
    ".next",
    ".nuxt",
    "dist",
    "build",
    "coverage",
    ".turbo",
    ".vercel",
    ".netlify",
    "vendor",
    ".venv",
    "venv",
    "__pycache__",
    "target",
}

TEXT_EXTENSIONS = {
    ".js", ".jsx", ".ts", ".tsx", ".mjs", ".cjs",
    ".py", ".go", ".rs", ".java", ".kt", ".rb", ".php",
    ".sql", ".md", ".txt", ".json", ".jsonc", ".yaml", ".yml",
    ".toml", ".ini", ".conf", ".env", ".sh", ".bash", ".zsh",
    ".html", ".htm", ".css", ".scss", ".vue", ".svelte",
}

MAX_FILE_BYTES = 2_000_000
SELF_SKILL_DIR = Path(__file__).resolve().parents[1]

SEVERITY_ORDER = {"P0": 0, "P1": 1, "P2": 2, "P3": 3, "INFO": 4}


@dataclass(frozen=True)
class Finding:
    severity: str
    rule_id: str
    title: str
    path: str
    line: int
    detail: str
    recommendation: str
    confidence: str = "medium"


@dataclass
class Coverage:
    supabase_detected: bool = False
    auth_detected: bool = False
    mfa_detected: bool = False
    captcha_detected: bool = False
    rate_limit_detected: bool = False
    rls_detected: bool = False
    waf_detected: bool = False
    security_headers_detected: bool = False
    edge_functions_detected: bool = False
    storage_detected: bool = False


JWT_RE = re.compile(r"\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b")
SECRET_KEY_RE = re.compile(r"\bsb_secret_[A-Za-z0-9_-]{8,}\b")
DB_URL_RE = re.compile(r"\bpostgres(?:ql)?://[^\s'\"`]+", re.IGNORECASE)
PUBLIC_SECRET_NAME_RE = re.compile(
    r"\b(?:VITE|NEXT_PUBLIC|REACT_APP|PUBLIC|NUXT_PUBLIC)_[A-Z0-9_]*"
    r"(?:SERVICE_ROLE|SECRET|PRIVATE_KEY|DATABASE_URL|JWT_SECRET|ADMIN_KEY)[A-Z0-9_]*\b"
)
SERVICE_ROLE_NAME_RE = re.compile(r"\b(?:SUPABASE_)?SERVICE_ROLE(?:_KEY)?\b", re.IGNORECASE)
ADMIN_API_RE = re.compile(r"\bauth\.admin\b")
CREATE_CLIENT_RE = re.compile(r"\bcreateClient\s*\(")
CUSTOM_PASSWORD_RE = re.compile(
    r"\b(?:bcrypt|argon2|scrypt|pbkdf2)\.(?:hash|verify|compare)|"
    r"\bpassword_hash\s*\(|\bPasswordHasher\b",
    re.IGNORECASE,
)
EVAL_RE = re.compile(r"\b(?:eval\s*\(|new\s+Function\s*\()")
CORS_WILDCARD_RE = re.compile(r"access-control-allow-origin\s*['\"\]:=, ]+\*", re.IGNORECASE)
RLS_TRUE_RE = re.compile(r"\b(?:using|with\s+check)\s*\(\s*true\s*\)", re.IGNORECASE)
GRANT_ALL_RE = re.compile(r"\bgrant\s+all(?:\s+privileges)?\b.*\bto\s+(?:anon|authenticated|public)\b", re.IGNORECASE)
SECURITY_DEFINER_RE = re.compile(r"\bsecurity\s+definer\b", re.IGNORECASE)
CREATE_PUBLIC_TABLE_RE = re.compile(
    r"\bcreate\s+table\s+(?:if\s+not\s+exists\s+)?(?:public\.)?([a-zA-Z_][a-zA-Z0-9_]*)",
    re.IGNORECASE,
)
ENABLE_RLS_RE_TEMPLATE = r"\balter\s+table\s+(?:only\s+)?(?:public\.)?{table}\s+enable\s+row\s+level\s+security\b"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Static defensive audit for Supabase repositories")
    parser.add_argument("--root", default=".", help="Repository root")
    parser.add_argument("--format", choices=("markdown", "json"), default="markdown")
    parser.add_argument("--output", help="Optional output file")
    return parser.parse_args()


def is_probably_text(path: Path) -> bool:
    name = path.name.lower()
    if name.startswith(".env"):
        return True
    if name in {"dockerfile", "makefile", "procfile", ".gitignore", ".npmrc"}:
        return True
    return path.suffix.lower() in TEXT_EXTENSIONS


def iter_files(root: Path) -> Iterable[Path]:
    root_resolved = root.resolve()
    try:
        self_inside_root = SELF_SKILL_DIR.is_relative_to(root_resolved)
    except AttributeError:  # Python 3.8 compatibility
        try:
            SELF_SKILL_DIR.relative_to(root_resolved)
            self_inside_root = True
        except ValueError:
            self_inside_root = False

    for current, dirs, files in os.walk(root):
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS]
        base = Path(current)
        for filename in files:
            path = base / filename
            if self_inside_root:
                try:
                    if path.resolve().is_relative_to(SELF_SKILL_DIR):
                        continue
                except AttributeError:
                    try:
                        path.resolve().relative_to(SELF_SKILL_DIR)
                        continue
                    except ValueError:
                        pass
            try:
                if path.is_symlink() or not path.is_file():
                    continue
                if path.stat().st_size > MAX_FILE_BYTES:
                    continue
            except OSError:
                continue
            if is_probably_text(path):
                yield path


def read_text(path: Path) -> str | None:
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None


def relative(path: Path, root: Path) -> str:
    try:
        return path.resolve().relative_to(root.resolve()).as_posix()
    except ValueError:
        return path.as_posix()


def is_frontend_context(rel_path: str, text: str) -> bool:
    lower_path = f"/{rel_path.lower()}"
    head = text[:500].lower()
    server_markers = (
        "/api/", "/server/", "/backend/", "/supabase/functions/", "/functions/",
        "/actions/", ".server.", "/route.ts", "/route.js", "/middleware.",
    )
    if any(marker in lower_path for marker in server_markers):
        return False
    if "use server" in head or "server-only" in head:
        return False
    if "use client" in head:
        return True

    definite_frontend_markers = (
        "/components/", "/pages/", "/client/", "/frontend/", ".client.",
    )
    if any(marker in lower_path for marker in definite_frontend_markers):
        return True

    suffix = path_suffix(rel_path)
    if suffix in {".jsx", ".tsx", ".vue", ".svelte", ".html"}:
        return True
    if any(signal in text for signal in ("import.meta.env", "window.", "document.", "localStorage")):
        return True
    return False


def path_suffix(path: str) -> str:
    return Path(path).suffix.lower()


def line_number(text: str, index: int) -> int:
    return text.count("\n", 0, index) + 1


def decode_jwt_role(token: str) -> str | None:
    try:
        payload = token.split(".", 2)[1]
        payload += "=" * (-len(payload) % 4)
        data = json.loads(base64.urlsafe_b64decode(payload.encode("ascii")))
        role = data.get("role")
        return role if isinstance(role, str) else None
    except Exception:
        return None


def git_tracked_files(root: Path) -> set[str]:
    try:
        result = subprocess.run(
            ["git", "-C", str(root), "ls-files", "-z"],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            timeout=10,
        )
        return {item.decode("utf-8", errors="replace") for item in result.stdout.split(b"\0") if item}
    except (OSError, subprocess.SubprocessError):
        return set()


def add_matches(
    findings: list[Finding],
    regex: re.Pattern[str],
    text: str,
    rel: str,
    severity: str,
    rule_id: str,
    title: str,
    detail: str,
    recommendation: str,
    confidence: str = "high",
) -> None:
    for match in regex.finditer(text):
        findings.append(Finding(
            severity=severity,
            rule_id=rule_id,
            title=title,
            path=rel,
            line=line_number(text, match.start()),
            detail=detail,
            recommendation=recommendation,
            confidence=confidence,
        ))


def scan(root: Path) -> tuple[list[Finding], Coverage, list[str]]:
    findings: list[Finding] = []
    coverage = Coverage()
    notes: list[str] = []
    tracked = git_tracked_files(root)
    all_sql: list[tuple[str, str]] = []
    all_text_lower_parts: list[str] = []

    for path in iter_files(root):
        text = read_text(path)
        if text is None:
            continue
        rel = relative(path, root)
        lower = text.lower()
        all_text_lower_parts.append(lower[:200_000])

        if "supabase" in lower:
            coverage.supabase_detected = True
        if any(term in lower for term in ("signinv", "signin", "signup", "sign_up", "resetpassword", "auth.getuser", "supabase.auth")):
            coverage.auth_detected = True
        if any(term in lower for term in ("getauthenticatorassurancelevel", "auth.mfa", "aal2", "totp")):
            coverage.mfa_detected = True
        if any(term in lower for term in ("turnstile", "hcaptcha", "captchatoken", "captcha_token")):
            coverage.captcha_detected = True
        if any(term in lower for term in ("ratelimit", "rate_limit", "rate-limit", "too many requests", "retry-after", "upstash/ratelimit")):
            coverage.rate_limit_detected = True
        if "row level security" in lower or "create policy" in lower:
            coverage.rls_detected = True
        if any(term in lower for term in ("cloudflare", "waf", "managed challenge")):
            coverage.waf_detected = True
        if any(term in lower for term in ("content-security-policy", "x-content-type-options", "permissions-policy", "strict-transport-security")):
            coverage.security_headers_detected = True
        if "supabase/functions" in rel.lower() or "edge function" in lower:
            coverage.edge_functions_detected = True
        if any(term in lower for term in ("storage.objects", ".storage.", "storage.from(")):
            coverage.storage_detected = True

        # Actual secret material. Values are never included in output.
        add_matches(
            findings, SECRET_KEY_RE, text, rel, "P0", "SECRET-SUPABASE-SB-SECRET",
            "Chave Supabase secreta encontrada no repositório",
            "Um valor com formato sb_secret_* aparece neste arquivo.",
            "Remova do código, rotacione/revogue no Supabase, mova para secret store server-side e audite o histórico Git.",
        )

        for match in JWT_RE.finditer(text):
            role = decode_jwt_role(match.group(0))
            if role == "service_role":
                findings.append(Finding(
                    severity="P0",
                    rule_id="SECRET-SUPABASE-SERVICE-JWT",
                    title="JWT service_role encontrado no repositório",
                    path=rel,
                    line=line_number(text, match.start()),
                    detail="O token decodifica para role=service_role; o valor foi omitido.",
                    recommendation="Rotacione o segredo/chave afetado, remova do repositório e mantenha uso apenas em runtime confiável.",
                    confidence="high",
                ))

        for match in DB_URL_RE.finditer(text):
            value = match.group(0)
            if "${" not in value and "<" not in value and "example" not in value.lower():
                findings.append(Finding(
                    severity="P0",
                    rule_id="SECRET-DATABASE-URL",
                    title="Connection string Postgres possivelmente hardcoded",
                    path=rel,
                    line=line_number(text, match.start()),
                    detail="Uma URL postgres foi encontrada; o valor foi omitido.",
                    recommendation="Confirme se é real. Se for, rotacione a senha, remova do código/histórico e use secret store server-side.",
                    confidence="medium",
                ))

        add_matches(
            findings, PUBLIC_SECRET_NAME_RE, text, rel, "P0", "SECRET-PUBLIC-ENV",
            "Variável sensível marcada para exposição pública",
            "O nome usa prefixo público de bundler/framework e indica segredo privilegiado.",
            "Remova o prefixo público, mova a operação para servidor/Edge Function e rotacione a credencial se já foi publicada.",
        )

        frontend = is_frontend_context(rel, text)
        if frontend and SERVICE_ROLE_NAME_RE.search(text):
            match = SERVICE_ROLE_NAME_RE.search(text)
            assert match is not None
            findings.append(Finding(
                severity="P0",
                rule_id="SECRET-SERVICE-ROLE-FRONTEND",
                title="Referência a service_role em contexto de frontend",
                path=rel,
                line=line_number(text, match.start()),
                detail="O arquivo parece ser entregue ao cliente e referencia uma credencial administrativa.",
                recommendation="Mova a operação privilegiada para backend server-only e use JWT do usuário + RLS para operações comuns.",
                confidence="high",
            ))

        if frontend and ADMIN_API_RE.search(text):
            match = ADMIN_API_RE.search(text)
            assert match is not None
            findings.append(Finding(
                severity="P0",
                rule_id="AUTH-ADMIN-API-FRONTEND",
                title="Supabase auth.admin usado em contexto de frontend",
                path=rel,
                line=line_number(text, match.start()),
                detail="APIs administrativas não devem ser chamadas por código distribuído ao navegador.",
                recommendation="Crie endpoint server-side autenticado, autorizado, rate-limited e auditado; não exponha chave administrativa.",
                confidence="high",
            ))

        if CUSTOM_PASSWORD_RE.search(text):
            match = CUSTOM_PASSWORD_RE.search(text)
            assert match is not None
            findings.append(Finding(
                severity="P1",
                rule_id="AUTH-CUSTOM-PASSWORD",
                title="Possível autenticação caseira baseada em senha",
                path=rel,
                line=line_number(text, match.start()),
                detail="Foi detectado hashing/verificação de senha na aplicação. Isso pode ser legítimo, mas exige revisão especializada.",
                recommendation="Prefira Supabase Auth/provedor maduro. Se for legado, revise hashing, reset, enumeração, sessão, MFA e plano de migração.",
                confidence="low",
            ))

        add_matches(
            findings, EVAL_RE, text, rel, "P1", "CODE-DYNAMIC-EVAL",
            "Execução dinâmica de código detectada",
            "eval/new Function aumenta risco de injeção e dificulta CSP.",
            "Remova a execução dinâmica ou limite estritamente a entradas confiáveis com justificativa e testes.",
            confidence="medium",
        )

        if CORS_WILDCARD_RE.search(text) and any(term in lower for term in ("authorization", "cookie", "supabase", "jwt")):
            match = CORS_WILDCARD_RE.search(text)
            assert match is not None
            findings.append(Finding(
                severity="P1",
                rule_id="API-CORS-WILDCARD",
                title="CORS wildcard em endpoint com indícios de autenticação",
                path=rel,
                line=line_number(text, match.start()),
                detail="Origin '*' aparece em código que também lida com autenticação/sessão.",
                recommendation="Use allowlist explícita por ambiente e trate preflight/métodos/headers de forma restrita.",
                confidence="medium",
            ))

        if path.suffix.lower() == ".sql":
            all_sql.append((rel, text))
            add_matches(
                findings, RLS_TRUE_RE, text, rel, "P1", "RLS-UNIVERSAL-TRUE",
                "Política RLS aparentemente universal",
                "USING(true) ou WITH CHECK(true) pode tornar a operação pública para o papel da política.",
                "Confirme o recurso. Restrinja por papel, owner, tenant e operação; teste acesso cruzado.",
                confidence="high",
            )
            add_matches(
                findings, GRANT_ALL_RE, text, rel, "P1", "GRANT-ALL-DATA-API",
                "GRANT ALL para papel exposto",
                "Privilégios amplos para anon/authenticated/public aumentam a superfície do Data API.",
                "Revogue e conceda somente operações necessárias, mantendo RLS como segunda camada.",
                confidence="high",
            )
            for match in SECURITY_DEFINER_RE.finditer(text):
                window_start = max(0, match.start() - 2000)
                window_end = min(len(text), match.end() + 2000)
                window = text[window_start:window_end].lower()
                if "set search_path" not in window:
                    findings.append(Finding(
                        severity="P1",
                        rule_id="FUNCTION-DEFINER-SEARCH-PATH",
                        title="SECURITY DEFINER sem search_path explícito próximo",
                        path=rel,
                        line=line_number(text, match.start()),
                        detail="A função privilegiada pode depender de search_path mutável. Confirme a definição completa.",
                        recommendation="Fixe search_path mínimo, qualifique objetos, revise owner e revogue EXECUTE de papéis desnecessários.",
                        confidence="medium",
                    ))

        # Tracked env files are a repo hygiene risk even when current values are placeholders.
        if rel in tracked and (Path(rel).name == ".env" or Path(rel).name.startswith(".env.")):
            if not Path(rel).name.endswith((".example", ".sample", ".template")):
                findings.append(Finding(
                    severity="P1",
                    rule_id="GIT-TRACKED-ENV",
                    title="Arquivo de ambiente rastreado pelo Git",
                    path=rel,
                    line=1,
                    detail="Arquivo .env real aparece em git ls-files.",
                    recommendation="Remova do índice, mantenha apenas template sem valores, rotacione segredos reais e revise o histórico.",
                    confidence="high",
                ))

    # Cross-file SQL analysis for CREATE TABLE without an observed ENABLE RLS.
    combined_sql = "\n".join(text for _, text in all_sql)
    for rel, text in all_sql:
        for match in CREATE_PUBLIC_TABLE_RE.finditer(text):
            table = match.group(1)
            enable_re = re.compile(ENABLE_RLS_RE_TEMPLATE.format(table=re.escape(table)), re.IGNORECASE)
            if not enable_re.search(combined_sql):
                findings.append(Finding(
                    severity="P1",
                    rule_id="RLS-CREATED-TABLE-NO-ENABLE",
                    title="Tabela criada sem ENABLE ROW LEVEL SECURITY observado",
                    path=rel,
                    line=line_number(text, match.start()),
                    detail=f"A migration cria public.{table}, mas o scanner não encontrou ENABLE RLS para essa tabela.",
                    recommendation="Confirme se a tabela é exposta. Habilite RLS e crie políticas/grants mínimos em migration versionada.",
                    confidence="medium",
                ))

    corpus = "\n".join(all_text_lower_parts)
    if coverage.auth_detected and not coverage.mfa_detected:
        notes.append("Auth foi detectado, mas não há evidência estática de MFA/AAL2. Verifique especialmente admin e ações sensíveis.")
    if coverage.auth_detected and not coverage.captcha_detected:
        notes.append("Auth foi detectado, mas não há evidência estática de CAPTCHA/Turnstile/hCaptcha.")
    if coverage.auth_detected and not coverage.rate_limit_detected:
        notes.append("Auth foi detectado, mas não há evidência estática de rate limiting da aplicação. Confirme também os limites nativos no Dashboard.")
    if coverage.supabase_detected and not coverage.rls_detected:
        notes.append("Supabase foi detectado, mas migrations/políticas RLS não foram encontradas no repositório.")
    if coverage.storage_detected and "storage.objects" not in corpus:
        notes.append("Supabase Storage foi detectado, mas não há evidência estática de políticas para storage.objects no repositório.")
    if not coverage.security_headers_detected:
        notes.append("Não foi encontrada configuração explícita dos principais security headers; confirme no framework/CDN.")
    if coverage.waf_detected:
        notes.append("WAF/Cloudflare foi citado. Confirme quais hostnames e rotas realmente passam por ele; chamadas diretas ao Supabase podem não passar.")

    # De-duplicate exact findings.
    unique: dict[tuple[str, str, int, str], Finding] = {}
    for finding in findings:
        key = (finding.rule_id, finding.path, finding.line, finding.title)
        unique[key] = finding
    ordered = sorted(
        unique.values(),
        key=lambda f: (SEVERITY_ORDER.get(f.severity, 99), f.path, f.line, f.rule_id),
    )
    return ordered, coverage, notes


def render_markdown(root: Path, findings: Sequence[Finding], coverage: Coverage, notes: Sequence[str]) -> str:
    counts = {severity: sum(1 for f in findings if f.severity == severity) for severity in SEVERITY_ORDER}
    lines = [
        "# Auditoria estática Supabase",
        "",
        f"Raiz analisada: `{root}`",
        "",
        "## Resumo",
        "",
        f"- P0: {counts['P0']}",
        f"- P1: {counts['P1']}",
        f"- P2: {counts['P2']}",
        f"- P3: {counts['P3']}",
        f"- Informativos: {counts['INFO']}",
        "",
        "## Cobertura detectada",
        "",
    ]
    for key, value in asdict(coverage).items():
        lines.append(f"- {key}: {'sim' if value else 'não detectado'}")

    lines.extend(["", "## Achados", ""])
    if not findings:
        lines.append("Nenhum achado determinístico foi encontrado pelo scanner. Isso não comprova segurança; execute a revisão manual e dinâmica autorizada.")
    else:
        for index, finding in enumerate(findings, start=1):
            lines.extend([
                f"### {index}. [{finding.severity}] {finding.title}",
                "",
                f"- Regra: `{finding.rule_id}`",
                f"- Local: `{finding.path}:{finding.line}`",
                f"- Confiança: {finding.confidence}",
                f"- Evidência: {finding.detail}",
                f"- Correção: {finding.recommendation}",
                "",
            ])

    lines.extend(["## Lacunas para revisão manual", ""])
    if notes:
        lines.extend(f"- {note}" for note in notes)
    else:
        lines.append("- Nenhuma lacuna adicional inferida pelo scanner.")

    lines.extend([
        "",
        "## Limites",
        "",
        "Este scanner usa heurísticas e não acessa o Dashboard Supabase, tráfego real, WAF, secret stores ou banco remoto. Confirme os achados e execute testes locais/staging antes de qualquer mudança em produção.",
        "",
    ])
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    root = Path(args.root).expanduser().resolve()
    if not root.exists() or not root.is_dir():
        print(f"Erro: raiz inválida: {root}", file=sys.stderr)
        return 2

    findings, coverage, notes = scan(root)
    if args.format == "json":
        output = json.dumps({
            "root": str(root),
            "findings": [asdict(f) for f in findings],
            "coverage": asdict(coverage),
            "manual_review_notes": list(notes),
        }, ensure_ascii=False, indent=2)
    else:
        output = render_markdown(root, findings, coverage, notes)

    if args.output:
        out_path = Path(args.output).expanduser()
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(output + "\n", encoding="utf-8")
    else:
        print(output)

    return 1 if any(f.severity in {"P0", "P1"} for f in findings) else 0


if __name__ == "__main__":
    raise SystemExit(main())
