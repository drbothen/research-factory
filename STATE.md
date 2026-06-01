# STATE — research-factory engine (self-dogfooded build state)

**The one file to read to resume.** Authoritative, versioned, in-repo. Pairs with `BUILD-PLAN.md`
(the design) and `git log` (the artifacts). My machine-local memory is only a pointer to this.

Last updated: 2026-06-01.

## ▶ RESUME NEXT SESSION — start item 4: the L6 portfolio

**v1.0 items #1–#3 are DONE** (cap, state-restore, cold-start prereqs, review-spec, working cross-family
review, 2nd market proven cold). The public engine + template were org-scrubbed and made public; both
market corpora stay private. **Pick up at v1.0 item #4 — the L6 cross-market portfolio.** There are now
**two real markets** to synthesize across — `<your-org>/ot-ics-research` (OT/ICS) and
`<your-org>/medical-device-security-research` (healthcare) — sharing vendors (Claroty/Armis/Forescout) and
governance (CISA), so the L6 synthesis has genuine content.

**Concrete first steps for item 4** (design: BUILD-PLAN §3 L6, §6 repos, §9 `portfolio-synth.lobster` line 321,
§12 `portfolio-rollup.yml` line 389; acceptance = one L6 cross-market brief, human-approved):
1. **Build `portfolio-synth.lobster`** — the missing 7th workflow (engine `plugins/research-factory/workflows/`).
   Shape: pull each registered instance's L4/L5 outputs → synthesizer (L6, cites named L4/L5 of each market) →
   adversary review (capped) → **human-approval** → cross-market brief. L6 is cross-market *judgment* — always
   human-gated. Validate with `lobster-parse validate`.
2. **L6 doc template** — add `templates/corpus/L6-portfolio-synthesis.md` (observes L4/L5 across markets; cites
   named market L4/L5; carries a market×vector roll-up). Mirror the L4 template's shape.
3. **Create `<your-org>/research-portfolio`** (PRIVATE) from the template, with a manifest registering the two
   instances. Install a `portfolio-rollup.yml` Action (`cron: 0 9 * * 1`) that runs `portfolio-synth` across
   registered instances → L6 brief → human-gated PR. (`init-market` step 7 already says "register in portfolio".)
4. **Run it** to produce the first L6 brief (OT × medical-device) → human-approved. That's the item-4 acceptance.
   Then item #5 (engine marketplace publish + `bump-engine` propagation) closes v1.0.

Everything below is the durable detail. **Read this file top-to-bottom on a cold resume.**

## Current phase

**v1.0 IN PROGRESS.** Done: item 1 (cap, engine PR #1) + state-restore (PR #2) + item 2 (cold-start, PR #3)
+ review-spec (PR #4) + cross-family-review-actually-reviews (PR #5). **Item 3 — 2nd market — PROVEN:**
`<your-org>/medical-device-security-research` created cold; `regulatory-governance` driven to **adversary
PASS** from the cold seed (the "config + seed, not code" thesis, with ZERO engine code); state-restore
proven live; cross-family review (Codex+Gemini) validated catching planted errors. Remaining for full Beta:
build the other 5 tracks (mechanical, autonomy 3). Remaining v1.0: **item 4 L6 portfolio · item 5 release**.

> **Template repo was refreshed first** (`drbothen/research-factory-template`): its 4 workflows had drifted
> behind the engine (missing v0.8 hardening + the v1.0 cap/state-restore fixes); also added `.github/mcp.json`
> + `.factory/` gitignore. Manual stand-in for the not-yet-built `bump-engine` propagation (item #5).

> Note: "engine PR #1/#2" = PRs on `drbothen/research-factory` (the engine). Distinct from instance
> `<your-org>/ot-ics-research` PRs (its PR #1 federal-dod-buyer, PR #2 international-cohort).

Also notable: **PR #1 was human-merged** — federal-dod-buyer night-shift work is now `status/active` on the
instance `main` (the autonomy-3 human-merge step, closing the full v0.8 loop end to end), and the night-shift
state-manager recorded its run in the instance `.factory/STATE.md` track build log.

### What's left to v1.0 (recommended order)

1. ✅ **`build-track` iteration cap** — DONE (engine PR #1, merged `bee28fa`). `convergence.max_passes: 6`
   threaded through the 4 loop lobsters + orchestrator + build-track SKILL + nightly/ingest Actions. On cap →
   commit-what-it-has + PR flagged "did not fully converge, M MUST-FIX remain." Cap value validated as sane:
   the international-cohort run converged at **pass 5** (< 6), so 6 would not have false-triggered (but it's snug).
2. ✅ **Cold-start prerequisites** — DONE (engine PR #3, merged `caf4cea`). Shipped: MIT `LICENSE`; root
   `CLAUDE.md` (engine constitution + layout + build/test); `docs/FACTORY.md` (operator orientation);
   `templates/corpus/` (L2-baseline +tldr, L3-findings +tldr with the mandatory vector-coverage table,
   track-summary, L4-cross-track-synthesis, README) — wired into the build-track + init-market skills.
3. ✅ **2nd market cold via `/init-market`** — DONE (acceptance met). `medical-device-security` created cold
   from the refreshed template; `regulatory-governance` → adversary PASS from the cold seed (zero engine code);
   state-restore proven live; cross-family review validated. Also surfaced + fixed two cold-start gaps the OT
   instance had masked: the generic `docs/review-spec.md` (PR #4) and the non-functioning cross-family review
   (PR #5). Full Beta = build the remaining 5 tracks (mechanical).
4. **L6 portfolio** — `research-portfolio` repo + `portfolio-synth.lobster` (the 7th workflow). Acceptance: an L6 cross-market brief, human-approved. **← NEXT** (OT + medical-device are now two real markets to synthesize across).
5. **Engine release** — marketplace publish + `bump-engine` cross-instance version-propagation Action. Acceptance: a version bump propagates to instances via PR.
(Optional/stretch: 5 deferred state hooks · `github-ops` + orchestrator sequence playbooks · WASM `factory-dispatcher` · autonomy 3.5.)

### State-model validation RESULT (2026-06-01) — run `26732442937` on `international-cohort`

The in-flight validation run completed **success** (51m34s; converged at adversary pass 5, not a runaway).
- **(a) ✅** `claude/international-cohort-beta-advance` branch + **PR #2** opened on the instance.
- **(b) ❌→FIXED** Persist step logged `no .factory state written this run`; `factory-artifacts` HEAD never
  moved off pre-run `937a1f6`. **Root cause:** the night-shift loop persisted `.factory/` at the END but never
  RESTORED it at the START — the instance checkout begins empty (`.factory` gitignored on `main`), so the
  state-manager had no STATE.md to append to → wrote nothing → persist pushed nothing. **Fixed in engine PR #2
  (merged `fbf2ffc`):** added a "Restore pipeline state from factory-artifacts" step after checkout (mirror of
  persist), and clarified the state-manager's CI role (agent WRITES the workspace `.factory/STATE.md`; the
  workflow owns the branch round-trip). **Not yet re-validated by a live run** — next night-shift run should
  show a `### international-cohort — …` entry appended to the instance Track build log + HEAD advancing.
- **(c) ✅ (trivially)** instance Track build log un-clobbered — but only because (b) wrote nothing.

## Roadmap status (BUILD-PLAN §15)

| Phase | Status | Acceptance evidence |
|---|---|---|
| P0 — prerequisites | ✅ done | 3 vendor keys validated in hello-world Action; secrets hygiene |
| v0.1 — engine skeleton + OT instance | ✅ done | require-citation hook proven headless; build-track → adversary PASS on one track; config loader |
| v0.5 — L1→L5 pipeline | ✅ done | L3→L4 synth → adversary PASS; L5 judgment through human gate (REVISE×3→PASS); 34 bats green |
| v0.8 — Actions autonomy + /init-market | ✅ done | live night-shift run → **PR #1** (real fixes, autonomy 3); Codex+Gemini review green; /init-market throwaway scaffold |
| v0.9 — PM pipeline | ✅ done | OT operationalization-gap finding → concept + 7-section PRD + 7-field stories; Dev-Readiness Check ran (2 CLEAR, 5 flagged as labeled Assumptions/Open-Questions, no invention) → `<your-org>/ot-ics-research/pm/operationalization-gap/` |
| v1.0 — portfolio (L6) + 2nd market + marketplace publish | ⬜ | 2nd market to Beta from cold seed; L6 brief; engine version-bump propagation |

## Repos

| Repo | Role | Visibility |
|---|---|---|
| `drbothen/research-factory` | the engine (this repo) | **public** (so instances clone the marketplace) |
| `drbothen/research-factory-template` | thin instance starter (`gh repo create --template`) | **public** (org refs scrubbed + history collapsed first) |
| `<your-org>/ot-ics-research` | instance #1 — OT/ICS, the **canonical** OT corpus | private |

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
- **Templates** — ✅ `templates/corpus/` shipped (engine PR #3): L2-baseline+tldr, L3-findings+tldr, track-summary, L4-cross-track-synthesis, README.
- **Docs/dirs** — ✅ `docs/FACTORY.md` + engine `LICENSE` (MIT) + root `CLAUDE.md` shipped (engine PR #3). Still missing: `CONVERGENCE.md`; unused `data/`, `checklists/`.
- **State model** — ✅ `.factory/` now on the orphan `factory-artifacts` branch worktree (§11), gitignored on `main`. Deferred: INDEX sharding, size-cap hook.

## Open items (not blockers)

- ✅ **build-track iteration cap** — DONE (engine PR #1, `bee28fa`). See v1.0 list item 1.
- ✅ **state-restore PROVEN live:** the first cold build on `medical-device-security` (regulatory-governance)
  advanced `factory-artifacts` with a `### regulatory-governance — 2026-06-01` track-build-log entry. The
  PR #2 (`fbf2ffc`) restore-at-start works end to end on a fresh instance.
- ✅ **on-pr-review now actually reviews + comments** — engine PR #5. Was a no-op (Codex never got the diff;
  no comment-posting). Now diff-scoped, posts findings as PR comments, scoped Perplexity MCP, audit artifacts.
  Validated on a planted-error PR (both reviewers caught a false "HIPAA final" claim + an unsourced Type-2
  claim; Gemini's Perplexity found the real figure). Resolves the old "0 comments" item.
- **ingest.yml + weekly-maintenance.yml have NO state round-trip:** unlike nightly-research they have neither a
  restore nor a persist step, so they never record `.factory/` state at all. Give them the same symmetric
  restore+persist pair (follow-up to PR #2).
- **cap value (6) is snug:** international-cohort converged at pass 5. A genuinely harder track needing 6–7 real
  revise passes would get prematurely flagged "did not converge." Revisit `max_passes` if false-flags appear;
  it's a per-market `factory.config` knob, so an instance can raise it.
- **Codex reviewer's Perplexity MCP falls back to WebSearch:** Gemini's Perplexity MCP works (verified
  citations live); Codex logs "MCP available but called via WebSearch/WebFetch fallback" — the inline
  `codex-args` `mcp_servers` env propagation isn't landing the key. Codex still reviews well via fallback;
  refine the Codex MCP env wiring as a follow-up (low priority — review works).
- **state-manager CI commit mechanism:** the regulatory-governance state push carried the agent's commit
  voice, so the agent may self-push `factory-artifacts` in CI despite the division-of-labor note (the
  workflow's persist step should own it). Net result correct; confirm one canonical path.
- **`pull_request` runs use the PR-HEAD-branch workflow** (not main) — so workflow fixes reach a market's
  reviews on the NEXT build-track PR (branched from updated main), not retroactively on in-flight PRs. Keep
  this in mind when shipping `on-pr-review`/Action changes.
- ✅ **engine `factory-artifacts` history PURGED:** rewrote the branch with `git filter-repo --path specs/
  --invert-paths` and force-pushed (`a521fb1…8cd2848`). Fresh-clone verified: `STATE.md` is the only path in
  all 9 commits; no seed/research blobs recoverable. (GitHub may keep unreachable old commits by exact SHA
  until server-side GC — not reachable via any ref/clone/browse; fine for non-secret content.) Residual:
  STATE.md still narrates market-#2 detail (regulatory triad, incidents) in prose — public-fact; redact
  further only if full market-neutrality is wanted.
- **company-specific forbidden phrases moved out of the engine hook (P10):** `forbidden-phrase-guard.sh` now
  carries only generic positioning patterns; market-specific company names belong in each instance's
  `editorial.forbidden_phrases_extra`. Add them to the OT + medical-device instance configs to restore that catch.

## Decisions log

- 2026-05-31: `<your-org>/ot-ics-research` is the **canonical** OT corpus (cutover; old ai-knowledge-base →
  ot-security-research mirror chain is legacy).
- 2026-05-31: engine repo made **public**; secret fragment scrubbed from history before publishing.
- 2026-05-31: **researcher prefers MCP search** (Perplexity/Tavily), built-in WebSearch/WebFetch fallback.
- 2026-05-31: **never cancel an in-flight paid run without asking** (operator rule).
- 2026-06-01: **`max_passes` cap = 6** (default) on the adversary loop — the canonical home is
  `factory.config` `convergence.max_passes`; lobsters mirror the default. Autonomous loops commit-flagged on
  cap; human-gated loops surface-to-human.
- 2026-06-01: **the workflow (not the state-manager agent) owns the `factory-artifacts` round-trip in CI** —
  restore-at-start + persist-at-end are deterministic bash steps; the agent only writes the workspace
  `.factory/STATE.md`. Avoids double-push and fragile haiku git surgery.
- 2026-06-01: **also commit the cap fix to the engine on a feature branch → PR → squash-merge** (operator chose
  push-and-merge over hold-local); CI `test` gate must be green before merge.
- 2026-06-01: **engine LICENSE = MIT** (operator choice — maximal adoption for a public marketplace others clone).
- 2026-06-01: **market #2 = Healthcare & Medical-Device Security** (`<your-org>/medical-device-security-research`) —
  closest cyber-physical sibling to OT; chosen for L6 portfolio value + distinct FDA/HDO/HTM vectors. Seed from a
  Perplexity Sonar Deep Research landscape (47 sources).
- 2026-06-01: **reviewers get scoped Perplexity MCP** (operator request) — verification-only (review-spec-fenced);
  Gemini fetches/checks the cited source (P3). **No model is a black box** (operator rule): every model uploads its
  full output as an artifact (Claude builder, Codex, Gemini).
- 2026-06-01: **the workflow owns the factory-artifacts round-trip in CI**, and `pull_request` runs use the
  PR-head-branch workflow — Action/review changes land on the NEXT build-track PR, not retroactively.

## How to resume (cold session, zero prior context)

**This file lives on the orphan `factory-artifacts` branch — it is NOT on `main`.** A fresh `main` clone won't
see it. Get it with: `git fetch origin factory-artifacts && git worktree add .factory factory-artifacts`
(or read once: `git show origin/factory-artifacts:STATE.md`). The engine README + BUILD-PLAN §18 on `main` point here.

1. **Repos** (clone all three): `drbothen/research-factory` (engine, public), `drbothen/research-factory-template` (private), `<your-org>/ot-ics-research` (instance, private). Local clones on this machine: `~/Dev/research-factory`, `~/Dev/ot-ics-research`. `gh` is authed as **drbothen** (admin on <your-org>).
2. **Read:** this file (full), then `BUILD-PLAN.md` §1 (constitution), §15+§15.1 (roadmap + status/delta), §18 (bootstrap). `CHANGELOG.md` for per-phase deltas.
3. **Verify the live proof:** `gh pr view 1 --repo <your-org>/ot-ics-research` (merged night-shift PR); `git log --oneline` in each repo.
4. **First action on resume:** check the in-flight run above (`26732442937`). Then pick up at **What's left to v1.0** — start with the `build-track` iteration cap.
5. Secrets are set on the instance (ANTHROPIC/OPENAI/GEMINI/PERPLEXITY/TAVILY) + engine; never re-commit them.
