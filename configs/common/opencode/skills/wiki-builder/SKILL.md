# Wiki Builder

Builds and maintains the structured wiki: index first, then one page per meaningful topic,
with links, citations, and explicit separation between sourced facts and synthesis.

## When to use

- `sko wiki build` (full or `--changed` incremental) / `sko wiki update`.
- Creating or reorganizing wiki pages.
- Validating wiki structure (`sko wiki validate`, `sko links repair`).

## Build order

1. Read the knowledge base `CLAUDE.md` and `config.yaml` (focus, language, writing style).
2. Read the ingestion registry; process only new or changed sources unless a full build is
   requested.
3. Create/update `wiki/index.md` first — it is the entry point and must list every page.
4. Identify main concepts, entities, frameworks, claims, processes, and questions.
5. One Markdown page per meaningful topic.
6. Link related pages with standard Markdown links (`[Title](./page-id.md)`).
7. Maintain backlinks/related-pages sections.
8. Cite `src_...` ids for important claims; mark synthesis explicitly.
9. Record contradictions — never resolve them silently.
10. Preserve manually written pages (`generated: false`).
11. Save major restructures as proposals in `system/proposed-changes/` for approval.
12. Update the changelog.

## Page quality bar

- No tiny pages with little informational value — merge overlapping topics.
- No near-duplicate pages.
- Unsupported claims are omitted or explicitly labeled as unsourced.
- Every page has: Summary, Core ideas, Evidence and sources, Contradictions (if any),
  Practical implications, Open questions, Related pages, Source references.

## Rules

- Never fabricate quotes, citations, or evidence.
- The index must link every active page; every important claim traces to a source id.
- Never touch `raw/`; never edit `system/normalized/`.
