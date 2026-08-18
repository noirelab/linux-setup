# Health Check

Runs the full audit of a knowledge base: contradictions, provenance, structure, staleness,
coverage, and unincorporated outputs. Report-only by default; nothing meaningful is ever
changed without explicit approval.

## When to use

- `sko health-check` (also `--since-last` for a delta report).
- Reviewing `system/health-checks/YYYY-MM-DD-health-check.md`.
- Applying only the safe actions from a report (`--apply-safe <report-id>`).

## Audit checklist

1. Contradictions between wiki pages (numbers, dates, definitions, terminology).
2. Inconsistent numbers/dates/definitions.
3. Broken links; 4. missing backlinks; 5. orphaned pages; 6. missing source provenance;
   7. unsupported claims; 8. unprocessed raw sources; 9. sources only partially represented;
   10. duplicate/overlapping articles; 11. stale articles; 12. time-sensitive claims;
   13. topic coverage gaps; 14. unanswered open questions; 15. useful unlinked connections;
   16. potential new pages; 17. valuable outputs not incorporated; 18. writing-style issues;
   19. invalid frontmatter; 20. missing/outdated index entries.

## Rules

- Default is report-only (`behavior.health_check_mode`).
- Never automatically resolve meaningful factual contradictions — record them, propose
  investigation, wait for human decision.
- Safe-to-automate changes are limited to: regenerating the index, updating backlinks/
  related-page sections, rebuilding the search cache.
- Save reports under `system/health-checks/YYYY-MM-DD-health-check.md` with the standard
  section layout.
- Score: start at 100, subtract for findings (critical 15, warning 5, info 1, suggestion 0.5).
