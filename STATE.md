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

## How to resume

1. Read this file + `BUILD-PLAN.md` §15 (roadmap) and §1 (constitution).
2. `git log --oneline` here for the artifact trail; `gh pr view 1 --repo 1898andCo/ot-ics-research` for the live proof.
3. Pick up at the **Current phase** above. For v0.9, see BUILD-PLAN §4 (PM pipeline) + §9 (`pm-doc-chain.lobster`).
