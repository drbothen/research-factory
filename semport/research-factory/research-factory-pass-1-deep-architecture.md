# Pass 1 Deepening — Round 1: Architecture — research-factory engine

> Scope of record: `/Users/jmagady/Dev/research-factory/plugins/research-factory/`.
> Inputs: `research-factory-pass-1-architecture.md` (broad) + `research-factory-pass-6-synthesis.md` (backlog P1-1…P1-4, R-6, G-2/G-4).
> This round (a) audits the broad Pass-1 doc against the 5 Known Hallucination Classes with shell re-derivation, then (b) deepens the four carryover targets line-by-line against source. Every claim below was read this round from: orchestrator.md, lobster-parse (full), all 5 Action `.yml` + mcp.json, AUTONOMY.md, config template, lobster.bats.

---

## Hallucination audit (5 classes) — re-derived counts

| Class | Check | Result |
|---|---|---|
| **1. Phantom module/file** | re-list every component dir | clean — all named files exist |
| **2. Count inflation** | `find … \| wc -l`: agents=**11**, workflows=**7**, hooks.sh=**4**, commands=**3**, skills=**2**, Action `.yml`=**5** | **ONE FAILURE → `CONV-ABS-1`** (see below). All others confirmed exactly. |
| **3. Invented capability** | does any source implement budget enforcement / parallel / sub-workflow runtime? | **NO** — three over-claims (P1-1, P1-3) → retracted/re-graded below |
| **4. Misattributed mechanism** | is the cross-family wall in frontmatter or CI? budget in an agent or config-only? | CI (correct in broad doc); budget config-only (broad §5 over-stated) |
| **5. Fabricated relationship/edge** | "orchestrator would fan-out/recurse" on parallel/sub-workflow | **unsupported inference** — no source wires it (P1-3) |

### CONV-ABS-1 (retraction) — "6 GitHub Action templates" is wrong; there are **5**

The broad doc states **"Six Action templates"** (§4 surface-b), **"the 6 GitHub Action templates"** (§1 layer G), and **"6 GitHub Action templates"** in the Mermaid + checkpoint. Shell:
`find templates/github-action-templates -name '*.yml' \| wc -l` → **5**.
The five are `nightly-research.yml`, `on-pr-review.yml`, `ingest.yml`, `weekly-maintenance.yml`, `portfolio-rollup.yml`. The 6th file in that directory is **`mcp.json`** — an MCP server config copied to `.github/mcp.json`, **not a GitHub Action**. The likely source of the "6" is that `on-pr-review.yml` carries **two jobs** (`adversary-review` Codex + `citation-verify` Gemini) — but that is 5 files / 6 jobs, not 6 Action templates. **Canonical: 5 Action `.yml` templates (6 jobs total), + 1 `mcp.json` config.** Retract every "6 Action templates" instance in the broad doc.

---

## P1-1 (HIGH) — Re-grade §5 budget-governance row to ASPIRATIONAL/unenforced — CONFIRMED & SHARPENED

Exhaustive scan this round (case-insensitive `hard_stop|per_run_cap|budget|spend|cumulative|on_critical_path` over every `.sh`, `lobster-parse`, all 5 Action `.yml`, all 11 agent bodies):

- **hooks/*.sh** → 0 matches. **bin/lobster-parse** → 0. **bin/factory-config.sh** → 0. **All 5 Action templates** → 0. **All 11 agent bodies (incl. orchestrator)** → 0.
- The thresholds exist in exactly **two places, both declarative/prose**: `templates/factory.config.template.yaml` lines 64–74 (`per_run_cap: 25`, `thresholds: {warn:100, alert:250, pause:400, hard_stop:500}`, `on_critical_path_downgrade: pause`) and `docs/AUTONOMY.md` §Budget (lines 24–35, operator-discipline prose; explicitly frames cost "per verified finding," cites the 6-hour hosted-runner cap as the *real* binding limit).

**Sharper than R-6 stated.** R-6/G-2 framed budget as "config-only, no enforcer." This round confirms it is weaker still: **the orchestrator — the only component that could refuse a dispatch — never mentions budget at all.** `orchestrator.md` step 6 is "Effort-scale (P9): one researcher for a simple source… do not over-spawn" — a *fan-out heuristic*, NOT a spend gate; it reads no `budget` key, tracks no cumulative cost, and has no `hard_stop` branch. The broad doc's §5 failure-mode cell ("At hard_stop, refuse new agent dispatch; a forced model downgrade pauses…") is **verbatim-lifted from the config-file comment**, presented as realized behavior. The only operative budget-like limit in the whole system is the GitHub `timeout-minutes` per job (120/60/90/30/120) — a wall-clock bound, not a spend bound.

**Re-grade (replaces broad §5 row 8):**

| Concern | Mechanism | Where realized | Enforcement grade |
|---|---|---|---|
| **Budget governance** | `budget{per_run_cap, thresholds{warn/alert/pause/hard_stop}, on_critical_path_downgrade}` declared in config; operator-discipline narrative in AUTONOMY.md; "per verified finding" framing. | `factory.config.template.yaml:64-74` + `docs/AUTONOMY.md:24-35` **only**. No agent, hook, validator, or Action step reads any budget key. | **ASPIRATIONAL / UNENFORCED.** The sole proxy limit is per-job `timeout-minutes` (wall-clock, not spend). Aligns with NFR-029 / G-2 / Pass-3 BC "no contract." |

---

## P1-2 (MED) — GitHub-Action runtime traced line-by-line — DEEPENED (broad §4 was Claude/portfolio-only)

The broad doc's CI sequence diagram covered nightly + portfolio-rollup as "mirror steps." Reading **all five** line-by-line reveals the templates are **NOT uniform** — there are three distinct template shapes, and the broad doc generalized the heaviest one to all.

### Template-shape taxonomy (new)

| Template | Restore `.factory` | Persist `.factory` | Fallback-PR opener | MCP search keys | Model | timeout |
|---|---|---|---|---|---|---|
| **nightly-research.yml** | ✅ (steps 34–45) | ✅ `always()` (111–129) | ✅ (134–157) | perplexity+tavily | sonnet-4-6 | 120m |
| **portfolio-rollup.yml** | ✅ (36–47) | ✅ `always()` (132–150) | ✅ (154–172) | perplexity+tavily | sonnet-4-6 | 120m |
| **ingest.yml** | ❌ **none** | ❌ **none** | ❌ **none** | perplexity+tavily | sonnet-4-6 | 60m |
| **weekly-maintenance.yml** | ❌ **none** | ❌ **none** | ❌ **none** | ❌ **none** (no `--mcp-config`) | **haiku-4-5** | 90m |
| **on-pr-review.yml** | n/a (read-only reviewers) | n/a | n/a (comments, not PRs) | perplexity (reviewers) | Codex gpt-5.5 / Gemini | 30m/20m |

**New finding F1 — only the two state-bearing builders carry the round-trip + fallback.** The broad doc implied the restore/persist/fallback triad is the general night-shift pattern. In fact **ingest.yml and weekly-maintenance.yml have neither the factory-artifacts round-trip nor a fallback-PR opener.** They rely 100% on Claude's own in-prompt `gh pr create`. Consequence: an ingest/maintenance run that commits a branch but fails to open a PR leaves an **orphan `claude/*` branch with no PR** — no safety net catches it (unlike nightly/portfolio, where the `git ls-remote … claude/* | tail -1` fallback step opens one). Also: ingest/maintenance write **no `.factory/STATE.md` persistence** — any state the state-manager writes in those jobs is discarded at job end (the workspace `.factory/` is never pushed to the orphan branch). This is an architectural asymmetry the broad doc missed entirely.

**New finding F2 — the `branch_name` output is documented inconsistently across templates.** nightly-research.yml (lines 105, 131–133) correctly states `claude-code-action`'s `branch_name` output is **empty when Claude pushes via Bash** (the reason the fallback opener `git ls-remote`-detects the branch). But ingest.yml:63 and weekly-maintenance.yml:54 print `branch_name` in the run summary with the comment "← empty = no commit" — which is **false given F1's mechanism**: branch_name is empty whenever Claude pushes via Bash, *whether or not* it committed. In ingest/maintenance, where Claude is told to `gh pr create` via Bash, `branch_name` will be empty even on a successful commit, so the summary's "empty = no commit" gloss is misleading. (Not a runtime bug — a summary-line annotation defect — but it pins how the fallback-detection idiom works.)

### Fallback-PR detection mechanism (P1-2 core, exact)

`nightly-research.yml:138-157` / `portfolio-rollup.yml:158-172`, `always()`:
1. `BR=$(git ls-remote --heads origin "refs/heads/claude/${TRACK}*" | sed 's|.*refs/heads/||' | sort | tail -1)` — list remote `claude/<track>*` heads, take the lexically-last (`sort | tail -1`) as the branch this run pushed. (nightly filters by `${TRACK}`; portfolio hardcodes `claude/portfolio-rollup*`.)
2. `[ -z "$BR" ]` → no branch → Claude made no committable change (or push failed) → `exit 0` (neutral no-op, the loop must be allowed to make zero changes per the prompt's "If you make NO changes … open no PR/branch").
3. `gh pr list --head "$BR" … -q '.[0].number'` non-empty → Claude already opened its own (better-titled) PR via the App token → `exit 0`.
4. else → open a **neutral fallback PR** (`--title "… [check convergence]"`). The comment (150–153) is explicit: this step **cannot read the loop outcome**, so it must NOT assert "adversary PASS" — convergence (PASS vs capped) lives only in the `claude-execution-log` artifact.

Why the branch detection is needed at all: `branch_name` output is empty for Bash pushes (F2), so the workflow can't get the branch from the action's outputs — it must rediscover it from the remote.

### App-token vs GITHUB_TOKEN (verified, sharpens broad §4 subtlety 1)

`nightly-research.yml:56-59` / `portfolio-rollup.yml:92-93`: **no `github_token:` override** is passed to `claude-code-action`, so it uses the **Claude GitHub App token**. Two stated reasons, both load-bearing: (a) the App token has `workflows:write`, so a push whose range touches `.github/workflows/**` succeeds (GITHUB_TOKEN cannot — "the blocked-push root cause"); (b) a PR opened by the App token **triggers `on-pr-review`**, whereas a `GITHUB_TOKEN`-authored PR would not trigger another workflow (GitHub's recursion guard). This is the structural linchpin that makes the cross-family review *fire automatically* — the broad doc noted it but did not connect it to the on-pr-review trigger dependency.

### restore-at-start / persist-at-end (exact, nightly 34–45 / 111–129; portfolio 36–47 / 132–150)

- **Restore** (before builder): `git fetch origin factory-artifacts || true`; if `refs/remotes/origin/factory-artifacts` exists → `mkdir -p .factory && git archive origin/factory-artifacts | tar -x -C .factory`; else echo "first run." Uses **GITHUB_TOKEN** (read of own-repo branch is fine). Rationale (comment 29–33): without restore, the persist step finds an empty `.factory/` and pushes nothing → the night-shift loop silently no-ops against an empty build log.
- **Persist** (`always()`, even on failure): guard `[ -d .factory ] && [ -n "$(ls -A .factory)" ]` else exit 0; `git worktree add` of `origin/factory-artifacts` (or `--orphan -b factory-artifacts` first run) into a tempdir; `cp -R .factory/. "$wt"/`; commit as `claude[bot]`; `git push origin HEAD:factory-artifacts || echo "no state change"`. **The Action — not the state-manager — owns the branch round-trip** (matches CLAUDE.md §11: "in CI the workflow owns the branch round-trip … the state-manager only *writes* the workspace `.factory/STATE.md`"). Verified: no agent body fetches/commits/pushes `factory-artifacts` in CI.

### on-pr-review.yml runtime (the cross-family gate, two jobs)

- **Job 1 `adversary-review`** (Codex, gpt-5.5, `sandbox: read-only` + `safety-strategy: read-only`): step `prep` assembles `review-prompt.md` = `cat docs/review-spec.md` + the diff scope (`gh pr diff … --name-only`). `allow-bots: true` + `allow-bot-users: "claude[bot]"` lets the Codex action past its bot-author guard (the PR is authored by `claude[bot]`). Codex MCP config inlined via `codex-args --config mcp_servers={…npx @perplexity-ai/mcp-server…}` for VERIFICATION-ONLY source checks. Output → `codex-review.md` → artifact + PR comment.
- **Job 2 `citation-verify`** (Gemini, `run-gemini-cli@v0`): independent checkout, own `gh pr diff --name-only`, NLI-style verdicts (SUPPORTED/PARTIAL/UNSUPPORTED/CONTRADICTED/UNREACHABLE), UNSUPPORTED/CONTRADICTED = MUST-FIX. MCP key passed via **job `env` inheritance** with an explicit warning (107–108, 16) **not** to set a literal `$VAR` in the `settings` env block (would override the real inherited key with the unexpanded string — "the v1 failure").
- `concurrency: pr-review-${{ pr.number }}` + `cancel-in-progress` so a re-push supersedes an in-flight review. `permissions: contents:read, pull-requests:write` — reviewers cannot write the corpus (structural read-only on top of the agent-level read-only). Confirms broad §4's "review is a gate, not a merge" at the permission level.

---

## P1-3 (MED) — `parallel` / `sub-workflow` are validate-only stubs with ZERO runtime spec — DEEPENED (retract broad inference)

Exhaustive scan (`parallel|sub-workflow|sub_workflow` over all `.md`, `.lobster`, `lobster-parse`, `.bats`):

- **Only two hits, both inside lobster-parse:** line 20 `STEP_TYPES = {… "parallel", "sub-workflow"}` and line 21 `TYPE_REQUIRES = {… "sub-workflow": "workflow"}`.
- **Zero hits** in: any of the 7 workflows, any of the 11 agent bodies (**including orchestrator.md** — its "How you run a workflow" enumerates only `agent`/`skill`/`loop`/`gate`/`human-approval`, steps 1–7), any doc (FACTORY/AUTONOMY/LAYER-MODEL/HOOKS/FACTORY-SOUL), any test, any template.

**Retract broad §3.1 inference.** The broad doc's table says `parallel` → "(not used … orchestrator *would* fan out)" and `sub-workflow` → "(not used … *would* recurse into another DAG)." **Neither claim is grounded** — nothing in the tree wires either behavior; the orchestrator has no fan-out-per-step or recurse-into-DAG instruction. These are inferences presented in a column otherwise filled with source facts. Re-grade as **defined-but-unspecified**.

**Sharper structural finding (F3): the lobster data model cannot express what these step types imply.** Reading `validate()`/`order()`/`steps` (lobster-parse 42–144): a step is a **flat mapping** keyed by `name`/`type`/`depends_on`/`agent|skill|workflow`. There is **no nested-children / sub-steps field** in the schema, and **`load()` is never called recursively** on a `workflow:` reference. Therefore:
- **`parallel`** is **semantically redundant**: parallelism is *already* expressed by the flat DAG (independent steps share a topo level), and the orchestrator *already* runs those together ("Independent steps may run together," orchestrator step 2). A dedicated `parallel` step type would need a children list the schema doesn't have. It adds nothing the existing model lacks.
- **`sub-workflow`** is a **dangling reference**: `TYPE_REQUIRES` only checks the `workflow:` field is a non-empty *string* (line 69–71). lobster-parse never opens, validates, or topo-merges the referenced workflow — there is no DAG-of-DAGs expansion anywhere. A `sub-workflow` step would validate, emit in topo order as a single opaque node, and then have **no interpreter** (the orchestrator wouldn't know to recurse).

`tests/lobster.bats` (8 `@test`s) confirms: it tests "rejects an invalid step type" (the allowlist negatively), but **no test positively validates a `parallel` or `sub-workflow` step** — so even the validator's handling of them is unexercised. **Canonical: 7 types defined, 5 used + implemented, 2 (`parallel`, `sub-workflow`) are forward-declared allowlist entries with no schema support, no interpreter, and no test.** They are best read as *reserved keywords* for a future DAG model, not latent capabilities.

---

## P1-4 (LOW) — OIDC token-exchange is genuinely external to the tree — CONFIRMED

Scan (`id-token|oidc|token-exchange|sts\.|getidtoken`): the **only** OIDC *runtime* surface in the tree is the `permissions: id-token: write` grant in **4 of the 5** Action templates (nightly-research:20, ingest:15, portfolio-rollup:24, weekly-maintenance:15), each annotated "required by claude-code-action (OIDC)". **The token exchange itself runs inside `anthropics/claude-code-action@v1`** (a vendor action — external to this tree; nothing here calls an STS endpoint, mints, or reads an ID token). All other `OIDC` references are about secret *hygiene*, not token exchange: `protect-secrets.sh:3,24`, `state-manager.md:52`, `research-protocol.md:45`, `init-market/SKILL.md:28` — all say "credentials live in GitHub Secrets/OIDC only, never in-repo." **Confirmed external; broad §4 stands.**

**Minor F4 (LOW):** `on-pr-review.yml` does **not** grant `id-token: write` (it uses `openai/codex-action` + `run-gemini-cli`, keyed by plain API-key secrets, not OIDC). And `weekly-maintenance.yml` grants `id-token: write` but its `claude-code-action` invocation is the lightest (haiku, no `--mcp-config`) — the grant is present because claude-code-action's Anthropic-API auth path can use OIDC regardless of MCP usage. So the OIDC grant tracks "which action is `claude-code-action`," not "which job needs search MCP."

---

## Delta Summary
- **Retractions:** 1 count error → **CONV-ABS-1** ("6 Action templates" → **5** `.yml` + 1 `mcp.json`); 2 inference retractions → broad §3.1 `parallel`/`sub-workflow` "would fan-out/recurse" (P1-3).
- **Re-grades:** 1 → §5 budget row to **ASPIRATIONAL/UNENFORCED**, sharper than R-6 (orchestrator never reads budget at all; only `timeout-minutes` is a real limit) (P1-1).
- **New findings:** F1 (ingest/maintenance lack restore+persist+fallback — state-bearing triad is builder-only; orphan-branch risk + discarded STATE) · F2 (`branch_name`-empty annotation inconsistent across templates) · F3 (lobster schema is flat; `parallel` redundant, `sub-workflow` dangling — neither has interpreter or schema support) · F4 (OIDC grant tracks the action, not the job's needs).
- **Existing items refined:** App-token→on-pr-review trigger dependency made explicit; fallback-PR `git ls-remote … | tail -1` detection traced exactly; restore/persist GITHUB_TOKEN-vs-App-token split confirmed; cross-family `permissions: contents:read` read-only-at-CI confirmed.
- **Items confirmed unchanged:** agents=11, workflows=7, hooks=4, commands=3, skills=2; OIDC external (P1-4); 2-surface split; convergence SM.

## Remaining gaps
- The *vendor* internals of `claude-code-action@v1` / `codex-action@v1` / `run-gemini-cli@v0` (token exchange, prompt assembly, branch-push mechanics) remain opaque by definition (external; not deepenable from this tree) — close as "external boundary, not a gap."
- Whether ingest/maintenance's missing factory-artifacts round-trip (F1) is intentional (those workflows are stateless-by-design: ingest appends one source, maintenance edits in place) or an omission is a **design-intent question** for spec crystallization, not resolvable from source alone. Flag to Pass-6/Pass-8 synthesis.
- `parallel`/`sub-workflow` future-DAG intent (F3) is undocumented even in BUILD-PLAN within this tree; if BUILD-PLAN (repo root, outside the plugin scope-of-record) specs them, that's a Pass-0/8 cross-check, not a Pass-1 gap.

## Novelty Assessment
Novelty: **SUBSTANTIVE**
Removing this round would leave the model wrong in ways that change the spec: it would keep a **non-existent 6th Action template** (CONV-ABS-1), keep budget governance mis-graded as a *working* cross-cutting concern with an orchestrator-level enforcer it does not have (P1-1 — a HIGH-priority correction that changes whether a downstream PRD must *build* the enforcer), keep an unsupported claim that the orchestrator fans-out/recurses on `parallel`/`sub-workflow` when the schema cannot even express them (P1-3/F3), and — most consequentially — keep the false belief that all four Claude builders share the factory-artifacts round-trip + fallback-PR safety net when **two of them (ingest, maintenance) have neither** (F1), which materially changes the deployment-topology and reliability model.

## Convergence Declaration
Another round needed? **No for the four carryover targets** — P1-1…P1-4 are now resolved to source with retractions/re-grades recorded. But this round surfaced **new SUBSTANTIVE architecture deltas** (CONV-ABS-1, F1, F3) not in the broad doc, so Pass 1 has **not** converged. A round-2 should: (a) re-read `mcp.json`/`factory-config.sh` for any further config-surface the broad doc generalized, (b) confirm whether ingest/maintenance statelessness (F1) is by-design via BUILD-PLAN, (c) verify the `commands/*` thin-router claim and `skills/init-market` Action-install logic against source (init-market installs the 5 `.yml` + mcp.json — touched but not deeply traced this round).

## State Checkpoint
```yaml
pass: 1
round: 1
status: complete
targets_resolved: [P1-1, P1-2, P1-3, P1-4]
retractions: [CONV-ABS-1]   # "6 Action templates" -> 5 .yml + 1 mcp.json
regrades: [budget-governance -> ASPIRATIONAL/UNENFORCED]
inference_retractions: [parallel/sub-workflow "orchestrator would fan-out/recurse"]
new_findings: [F1 ingest+maintenance lack restore/persist/fallback, F2 branch_name annotation drift, F3 flat-schema parallel-redundant+subworkflow-dangling, F4 oidc-grant-tracks-action]
files_read_this_round: [orchestrator.md, bin/lobster-parse(full), nightly-research.yml, on-pr-review.yml, ingest.yml, weekly-maintenance.yml, portfolio-rollup.yml, mcp.json, docs/AUTONOMY.md, factory.config.template.yaml(budget), tests/lobster.bats]
timestamp: 2026-06-01T00:00:00Z
novelty: SUBSTANTIVE
```
