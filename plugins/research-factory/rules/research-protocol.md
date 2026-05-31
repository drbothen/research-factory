# research-protocol — conventions every agent follows

Vendor-neutral (plain markdown) so Claude, Codex, and Gemini all read the same source of truth.

## Naming & paths

- Lowercase kebab-case. `<base>.md` for a full doc; `<base>-tldr.md` for its TLDR (≤3 pages — the one place length is a hard constraint).
- Instance corpus lives under `corpus/<track-slug>/`. Templates under `corpus/templates/` or the engine's `templates/`. Per-instance state under `.factory/`.
- One metric → one authoritative file (Single-Source-of-Truth). Everything else cites it; nothing re-derives a canonical value.

## Citations

- Every claim carries a citation (source URL / footnote) **or** an explicit flag.
- Flag forms: `[Source needed: <what was searched, why unfound>]` (Type-1, unsourced) and `[Access required: <source> — <barrier> — <est. cost>]` (paywalled — never "dropped").
- A synthesis conclusion drawn from research in the same doc is **section-anchored**: "The pass documented in the section above found…", not an ambient "No X exists."

## Sourcing escalation (exhaust before any drop)

1. Own corpus (cross-cite existing evidence) → 2. Web fetch/search → 3. Browser automation (SPAs/paywall previews) → 4. Audio/video transcription → 5. Paywall — flag `[Access required]`, don't drop → 6. Social/restricted platforms (credential-assisted) → 7. Document the attempt (what was searched, what was found, why unsourceable). A documented failed attempt is corpus data.

## Review & commit

- Builder ≠ reviewer. The adversary and citation-verifier never share a model family with the builder and are never skipped.
- The reviewer is information-asymmetric: no prior passes, no drafter reasoning, no summaries.
- The **state-manager is the sole committer** and runs last in every burst — one burst, one atomic commit.
- Quality tiers are assigned by review, never self-reported: Production (0 markers + L3 + adversary PASS) · Beta · Alpha (SHOULD-FIX remain) · Revise (MUST-FIX remain).

## Secrets

Credentials live in GitHub Secrets / OIDC only. Never commit `.mcp.json`, `.env`, or any key — they are gitignored. The state-manager refuses to commit a secret.
