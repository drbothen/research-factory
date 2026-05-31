# research-factory

Generic, dynamic **research factory** engine — an autonomous, GitHub-Actions-backed pipeline that
grows a rigorously-sourced, auditable research corpus from a *seed* and graduates it into
product-management deliverables. Domain-agnostic: a new market is a new **config + seed**, not new code.

See [`BUILD-PLAN.md`](./BUILD-PLAN.md) for the full design (self-contained; read top to bottom).

## Status

Pre-build (v0). Currently at **P0 — Prerequisites** (BUILD-PLAN §15):

- [x] Verify no secrets committed in any repo; `.gitignore` `.mcp.json` everywhere
- [ ] Provision 3 vendor credentials as GitHub Secrets — `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GEMINI_API_KEY`
- [ ] Validate all 3 keys via the hello-world Action (`.github/workflows/hello-world-secrets.yml`)

## Cross-family model routing (verified 2026-05-31)

| Role | Action | Model |
|---|---|---|
| builder | `anthropics/claude-code-action@v1` | `claude-opus-4-8` · `claude-sonnet-4-6` · `claude-haiku-4-5-20251001` |
| adversary reviewer | `openai/codex-action@v1` | `gpt-5.5` (default) · `gpt-5.4` · `gpt-5.3-codex` |
| citation verifier | `google-github-actions/run-gemini-cli@v0` | `gemini-3-pro` |

Engine lives under `drbothen`; research instances under `1898andCo`.
