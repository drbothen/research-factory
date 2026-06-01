# STATE — research-factory engine (self-dogfooded build state)

**The one file to read to resume.** Authoritative, versioned, in-repo. Pairs with `BUILD-PLAN.md`
(the design) and `git log` (the artifacts). My machine-local memory is only a pointer to this.

Last updated: 2026-05-31.

## Current phase

**v0.9 COMPLETE.** Next: **v1.0** — portfolio (L6) + a real 2nd market via /init-market + engine marketplace
publish + `bump-engine` cross-instance version propagation.

Also notable: **PR #1 was human-merged** — federal-dod-buyer night-shift work is now `status/active` on the
instance `main` (the autonomy-3 human-merge step, closing the full v0.8 loop end to end), and the night-shift
state-manager recorded its run in the instance `.factory/STATE.md` track build log.

### What's left to v1.0 (recommended order)

1. **`build-track` iteration cap** — the load-bearing fix (see Open items). Do FIRST; de-risks unattended scale.
2. **Cold-start prerequisites:** ship `templates/corpus/` (generic L2/L3/summary/L4 doc templates — a cold 2nd market has nothing to copy) + engine `LICENSE` + engine `CLAUDE.md` (+ `docs/FACTORY.md`) — needed before publish.
3. **2nd market cold via `/init-market`** — the real proof of "config + seed, not code". Acceptance: 2nd market → Beta from a cold seed.
4. **L6 portfolio** — `research-portfolio` repo + `portfolio-synth.lobster` (the 7th workflow). Acceptance: an L6 cross-market brief, human-approved.
5. **Engine release** — marketplace publish + `bump-engine` cross-instance version-propagation Action. Acceptance: a version bump propagates to instances via PR.
(Optional/stretch: 5 deferred state hooks · `github-ops` + orchestrator sequence playbooks · WASM `factory-dispatcher` · autonomy 3.5.)

### In-flight at last context clear (2026-05-31)

- **Validation run** of the `factory-artifacts` state-push: `nightly-research` run `26732442937` on `international-cohort` (instance) was `in_progress`. CHECK IT FIRST on resume: `gh run view 26732442937 --repo 1898andCo/ot-ics-research`. Verifying: (a) `claude/international-cohort*` branch + PR opened, (b) `.factory/STATE.md` pushed to `factory-artifacts` (compare HEAD vs `937a1f6` — the pre-run SHA), (c) STATE.md history preserved not clobbered (the state-manager writes a fresh STATE.md in CI since `.factory` is gitignored on `main` — if it clobbers the track log, the run will show it; fix = fetch `factory-artifacts` STATE at build start).

## Roadmap status (BUILD-PLAN §15)

| Phase | Status | Acceptance evidence |
|---|---|---|
| P0 — prerequisites | ✅ done | 3 vendor keys validated in hello-world Action; secrets hygiene |
| v0.1 — engine skeleton + OT instance | ✅ done | require-citation hook proven headless; build-track → adversary PASS on one track; config loader |
| v0.5 — L1→L5 pipeline | ✅ done | L3→L4 synth → adversary PASS; L5 judgment through human gate (REVISE×3→PASS); 34 bats green |
| v0.8 — Actions autonomy + /init-market | ✅ done | live night-shift run → **PR #1** (real fixes, autonomy 3); Codex+Gemini review green; /init-market throwaway scaffold |
| v0.9 — PM pipeline | ✅ done | OT operationalization-gap finding → concept + 7-section PRD + 7-field stories; Dev-Readiness Check ran (2 CLEAR, 5 flagged as labeled Assumptions/Open-Questions, no invention) → `1898andCo/ot-ics-research/pm/operationalization-gap/` |
| v1.0 — portfolio (L6) + 2nd market + marketplace publish | ⬜ | 2nd market to Beta from cold seed; L6 brief; engine version-bump propagation |

## Repos

| Repo | Role | Visibility |
|---|---|---|
| `drbothen/research-factory` | the engine (this repo) | **public** (so instances clone the marketplace) |
| `drbothen/research-factory-template` | thin instance starter (`gh repo create --template`) | private |
| `1898andCo/ot-ics-research` | instance #1 — OT/ICS, the **canonical** OT corpus | private |

## Deployment fixes baked into the Action templates (so the next market just works)

The v0.8 live shakedown surfaced these; all corrected in `templates/github-action-templates/`:
1. Org must **enable GitHub Actions** for the instance repo (org-admin).
2. Builder workflows need `permissions: id-token: write` (claude-code-action OIDC).
3. The **Claude GitHub App** must be installed on the org (it has `workflows:write`). Do NOT override
   auth with `github_token` — GITHUB_TOKEN can't push `.github/workflows/` changes, and PRs it opens
   don't trigger `on-pr-review`. Use the App token (omit `github_token`).
4. `plugin_marketplaces` needs the full `https://github.com/<org>/<repo>.git` URL (`.git` suffix).
5. claude-code-action only **pushes a branch**; it never opens a PR — open it explicitly.
6. Its `branch_name` output is **empty when Claude pushes via Bash** — detect the `claude/*` branch instead.
7. Engine repo must be **public** for the marketplace clone (scrub any secrets from history first — we used filter-repo).
8. Codex review of a bot PR needs `allow-bots: true` + `allow-bot-users: "claude[bot]"`.
9. Gemini needs env `GEMINI_CLI_TRUST_WORKSPACE=true` (headless trust).
10. Gemini `gemini_model` must be UNSET or a **valid** generateContent model (`gemini-3-pro` is NOT valid).

Audit: every builder run uploads the `claude-execution-log` artifact (`execution_file`). `show_full_output`
stays OFF (it echoes tool results incl. secrets into the log).

## Deferred components (built lean vs BUILD-PLAN §7–§12; see §15.1 for the full delta)

- **Hooks 4/9** (have: require-citation, layer-discipline, protect-secrets, forbidden-phrase). Deferred (state-dependent, in `docs/HOOKS.md`): source-faithfulness-guard, anchor-not-strip-guard, convergence-tracker, protect-canonical, factory-branch-guard.
- **Agents 11/12** — missing `github-ops`; no `orchestrator/*-sequence` playbooks.
- **Workflows 6/7** — missing `portfolio-synth` (v1.0/L6).
- **Templates** — no `templates/corpus/` generic doc templates for new markets.
- **Docs/dirs** — missing `docs/FACTORY.md`, `CONVERGENCE.md`; unused `data/`, `checklists/`; no engine `LICENSE` / `CLAUDE.md`.
- **State model** — ✅ `.factory/` now on the orphan `factory-artifacts` branch worktree (§11), gitignored on `main`. Deferred: INDEX sharding, size-cap hook.

## Open items (not blockers)

- **build-track iteration cap (v0.9 refinement):** the adversary loop has no cap → runs away (50+ min, no
  convergence) on a heavily-flawed draft, so it never commits. Add a max-N-passes cap → commit-what-it-has +
  open a PR flagged "did not fully converge, M MUST-FIX remain."
- **on-pr-review comment posting unverified:** reviewers run green but post 0 comments — likely because
  build-track already converged the PR to 0 MUST-FIX; verify by running on-pr-review against a deliberately-
  flawed PR.

## Decisions log

- 2026-05-31: `1898andCo/ot-ics-research` is the **canonical** OT corpus (cutover; old ai-knowledge-base →
  ot-security-research mirror chain is legacy).
- 2026-05-31: engine repo made **public**; secret fragment scrubbed from history before publishing.
- 2026-05-31: **researcher prefers MCP search** (Perplexity/Tavily), built-in WebSearch/WebFetch fallback.
- 2026-05-31: **never cancel an in-flight paid run without asking** (operator rule).

## How to resume (cold session, zero prior context)

**This file lives on the orphan `factory-artifacts` branch — it is NOT on `main`.** A fresh `main` clone won't
see it. Get it with: `git fetch origin factory-artifacts && git worktree add .factory factory-artifacts`
(or read once: `git show origin/factory-artifacts:STATE.md`). The engine README + BUILD-PLAN §18 on `main` point here.

1. **Repos** (clone all three): `drbothen/research-factory` (engine, public), `drbothen/research-factory-template` (private), `1898andCo/ot-ics-research` (instance, private). Local clones on this machine: `~/Dev/research-factory`, `~/Dev/ot-ics-research`. `gh` is authed as **drbothen** (admin on 1898andCo).
2. **Read:** this file (full), then `BUILD-PLAN.md` §1 (constitution), §15+§15.1 (roadmap + status/delta), §18 (bootstrap). `CHANGELOG.md` for per-phase deltas.
3. **Verify the live proof:** `gh pr view 1 --repo 1898andCo/ot-ics-research` (merged night-shift PR); `git log --oneline` in each repo.
4. **First action on resume:** check the in-flight run above (`26732442937`). Then pick up at **What's left to v1.0** — start with the `build-track` iteration cap.
5. Secrets are set on the instance (ANTHROPIC/OPENAI/GEMINI/PERPLEXITY/TAVILY) + engine; never re-commit them.
