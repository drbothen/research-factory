# research-factory

Generic, dynamic **research factory** engine — an autonomous, GitHub-Actions-backed pipeline that
grows a rigorously-sourced, auditable research corpus from a *seed* and graduates it into
product-management deliverables. Domain-agnostic: a new market is a new **config + seed**, not new code.

See [`BUILD-PLAN.md`](./BUILD-PLAN.md) for the full design (self-contained; read top to bottom).

## Status

- [x] **P0** — secrets hygiene; 3 vendor keys provisioned + validated (hello-world Action green)
- [x] **v0.1** — plugin skeleton; require-citation hook (proven headless); config loader; OT instance #1 (`1898andCo/ot-ics-research`) migrated + build-track loop validated (adversary PASS)
- [x] **v0.5** — `.lobster` workflow engine (`bin/lobster-parse`) + 5 workflows; 6 more agents (orchestrator, synthesizer, judgment-writer, consistency-validator, editorial-sweeper, dashboard-builder); 4 fail-closed hooks (see `plugins/research-factory/docs/HOOKS.md`); `release.yml`
- [ ] **v0.8** — GitHub Actions autonomy + `/init-market` + `research-factory-template`
- [ ] **v0.9** — PM pipeline · **v1.0** — portfolio (L6) + 2nd market + marketplace publish

Test suite: 32 bats cases (config, hooks, lobster). CI validates manifests + all `.lobster` workflows + runs the suite.

## Cross-family model routing (verified 2026-05-31)

| Role | Action | Model |
|---|---|---|
| builder | `anthropics/claude-code-action@v1` | `claude-opus-4-8` · `claude-sonnet-4-6` · `claude-haiku-4-5-20251001` |
| adversary reviewer | `openai/codex-action@v1` | `gpt-5.5` (default) · `gpt-5.4` · `gpt-5.3-codex` |
| citation verifier | `google-github-actions/run-gemini-cli@v0` | `gemini-3-pro` |

Engine lives under `drbothen`; research instances under `1898andCo`.
