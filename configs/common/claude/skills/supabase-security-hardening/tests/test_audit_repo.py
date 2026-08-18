from __future__ import annotations

import importlib.util
import tempfile
import unittest
import sys
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "audit_repo.py"
spec = importlib.util.spec_from_file_location("audit_repo", SCRIPT)
assert spec and spec.loader
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)


class AuditRepoTests(unittest.TestCase):
    def scan_files(self, files: dict[str, str]):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for name, content in files.items():
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(content, encoding="utf-8")
            findings, coverage, notes = module.scan(root)
            return findings, coverage, notes

    def test_publishable_and_anon_are_not_reported_as_secrets(self):
        findings, _, _ = self.scan_files({
            "src/client.ts": "const a='sb_publishable_example_123456789'; const b=process.env.VITE_SUPABASE_ANON_KEY;"
        })
        self.assertFalse(any(f.severity == "P0" for f in findings))

    def test_sb_secret_is_critical(self):
        findings, _, _ = self.scan_files({
            "src/components/client.tsx": "'use client'; const key='sb_secret_FAKE_TEST_VALUE_123456789';"
        })
        self.assertTrue(any(f.rule_id == "SECRET-SUPABASE-SB-SECRET" for f in findings))

    def test_service_role_in_client_is_critical(self):
        findings, _, _ = self.scan_files({
            "src/components/client.tsx": "'use client'; const key=process.env.SUPABASE_SERVICE_ROLE_KEY;"
        })
        self.assertTrue(any(f.rule_id == "SECRET-SERVICE-ROLE-FRONTEND" for f in findings))

    def test_service_role_name_in_server_route_is_not_frontend_finding(self):
        findings, _, _ = self.scan_files({
            "src/app/api/admin/route.ts": "import 'server-only'; const key=process.env.SUPABASE_SERVICE_ROLE_KEY;"
        })
        self.assertFalse(any(f.rule_id == "SECRET-SERVICE-ROLE-FRONTEND" for f in findings))

    def test_open_rls_and_missing_enable_are_reported(self):
        findings, _, _ = self.scan_files({
            "supabase/migrations/001.sql": (
                "create table public.orders(id uuid);\n"
                "create policy open on public.orders for all to authenticated using (true) with check (true);\n"
            )
        })
        rules = {f.rule_id for f in findings}
        self.assertIn("RLS-CREATED-TABLE-NO-ENABLE", rules)
        self.assertIn("RLS-UNIVERSAL-TRUE", rules)

    def test_enable_rls_suppresses_missing_enable_finding(self):
        findings, _, _ = self.scan_files({
            "supabase/migrations/001.sql": (
                "create table public.orders(id uuid);\n"
                "alter table public.orders enable row level security;\n"
            )
        })
        self.assertFalse(any(f.rule_id == "RLS-CREATED-TABLE-NO-ENABLE" for f in findings))


if __name__ == "__main__":
    unittest.main()
