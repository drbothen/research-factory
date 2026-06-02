# Pass 4: NFR Catalog — research-factory engine

> Scope of record: `/Users/jmagady/Dev/research-factory/plugins/research-factory/` (the plugin = the engine), plus the engine's own `.github/workflows/ci.yml`, `BUILD-PLAN.md`, and `docs/AUTONOMY.md`.
> Builds on Pass 0 (inventory, 64 files), Pass 1 (7 engine layers, 2 execution surfaces, convergence SM), Pass 2 (domain model, 26 config keys), Pass 3 (78 behavioral contracts).
> **Every NFR below is grounded in source read this pass** (4 hooks, hooks.json, 5 Action templates, mcp.json, config template, AUTONOMY.md, FACTORY-SOUL.md, ci.yml, researcher.md) or in a prior-pass citation re-confirmed against source. No fabrication.

## What an "NFR" is in this codebase

This engine has almost no runtime application code (Pass 0/1). Its non-functional requirements are therefore encoded in **four substrates**, not in service config or middleware:

1. **Bash PreToolUse hooks** — the only place an NFR is mechanically enforced *inside* the engine (fail-closed, deterministic, <100ms, `timeout 5`).
2. **GitHub Action templates** — where security (OIDC/App-token/secrets-from-Secrets), reliability (state round-trip, fallback PR), observability (artifact upload), and performance (job timeouts, model tier) NFRs are realized at the CI layer.
3. **`factory.config.yaml`** — the *declarative* NFR knob surface (convergence numbers, autonomy level, budget tiers, model tiers). These are **policy values the engine reads**; enforcement lives elsewhere (orchestrator reasoning, Action, or — for budget — **not yet located**, see Gaps).
4. **Agent/skill Iron Laws + constitution (FACTORY-SOUL P1–P10)** — prose-level NFRs the LLM is told to honor, structurally reinforced by tool-grant absence and `context.exclude`, but not checked by code.

**Enforcement legend used throughout:**
- **MECHANICAL** — a hook denies, a CLI flag constrains, a parser refuses, CI fails the build. Deterministic; no LLM in the loop.
- **STRUCTURAL** — enforced by the *shape* of the system (tool-grant absence, different CLI family, DAG terminal, `context.exclude`, permissions block) rather than a checker. Cannot be narrated around, but no explicit assertion fires.
- **ASPIRATIONAL** — prose Iron Law / constitution principle; real intent, enforced by LLM reasoning only.

One-shot example of the NFR entry shape used below:

> ### NFR-000: <one-line requirement>
> **Category:** <Security|Reliability|Observability|Performance/Cost|Scalability|Maintainability>.
> **Requirement:** <what must hold>.
> **Encoded in:** `<file>:<lines>` — `<the concrete value/flag/pattern>`.
> **Enforcement:** MECHANICAL | STRUCTURAL | ASPIRATIONAL — <why>.
> **Cross-ref:** <prior-pass BC / entity / arch finding>.

---

# A. SECURITY

### NFR-001: No credential is ever written into any repo file
**Category:** Security (secrets hygiene).
**Requirement:** A `Write` whose content contains a secret-shaped token is denied — on **every** file, not corpus-scoped. Credentials live only in GitHub Secrets / OIDC, never in-repo.
**Encoded in:** `hooks/protect-secrets.sh:21` — `PATTERNS='(sk-[A-Za-z0-9]{20,})|(pplx-[A-Za-z0-9]{20,})|(tvly-(prod|dev)?-?[A-Za-z0-9]{16,})|(gh[pousr]_[A-Za-z0-9]{30,})|(AKIA[0-9A-Z]{16})|(-----BEGIN [A-Z ]*PRIVATE KEY-----)|(xox[baprs]-[A-Za-z0-9-]{10,})'`; deny at `:23-24`. Wired first in the chain (`hooks.json:7`, `timeout 5`).
**Enforcement:** MECHANICAL — first PreToolUse:Write hook; high-precision case-sensitive match (Pass 3 BC-031); fires before any other gate (Pass 3 BC-HOOK-B).
**Cross-ref:** Pass 3 BC-025…031; Pass 1 §5 "Secrets hygiene".

### NFR-002: Keys are injected from GitHub Secrets via env, never hardcoded; MCP config interpolates `${VAR}`
**Category:** Security (secrets provenance).
**Requirement:** All provider keys reach the runtime only through `${{ secrets.* }}` env blocks; the MCP server config references env vars by name, never a literal value.
**Encoded in:** `templates/github-action-templates/mcp.json:3` (`"//keys": "Keys are expanded from job env (GitHub Secrets) — NEVER hardcode them here."`), `:9` (`"PERPLEXITY_API_KEY": "${PERPLEXITY_API_KEY}"`), `:13` (`tavilyApiKey=${TAVILY_API_KEY}`); `nightly-research.yml:52-55`, `ingest.yml:27-30`, `on-pr-review.yml:56-58,103-105`.
**Enforcement:** STRUCTURAL (template convention) + MECHANICAL backstop (NFR-001 would deny a literal key). The instance copies these templates; the engine never embeds a key.
**Cross-ref:** Pass 2 §2a.4 budget.vendors "each key is a separate GitHub Secret".

### NFR-003: OIDC `id-token: write` is granted only where `claude-code-action` requires it
**Category:** Security (least-privilege CI permissions).
**Requirement:** The OIDC id-token permission is present exactly in the Claude-builder workflows that need it, scoped per-workflow.
**Encoded in:** `nightly-research.yml:17-20` (`contents: write` · `pull-requests: write` · `id-token: write  # required by claude-code-action (OIDC)`), identically `portfolio-rollup.yml:21-24`, `ingest.yml:12-15`, `weekly-maintenance.yml:12-15`. **`on-pr-review.yml:24-26` deliberately omits `id-token` and downgrades to `contents: read`** (reviewers never write).
**Enforcement:** STRUCTURAL — GitHub Actions `permissions:` block is enforced by the platform; the review job is read-only by permission, not just by prompt.
**Cross-ref:** Pass 1 §4 surface (b).

### NFR-004: The cross-family review job runs read-only and never writes the corpus
**Category:** Security (privilege separation of the adversary).
**Requirement:** The adversary/citation reviewers cannot mutate the repo: read-only sandbox + read-only token + read-only safety strategy.
**Encoded in:** `on-pr-review.yml:24` (`contents: read`), `:60` (`sandbox: read-only`), `:61` (`safety-strategy: read-only`); Gemini job has only `pull-requests: write` for posting comments. Reinforced by agent tool grants (`adversary-reviewer`/`citation-verifier` are `[Read, Grep, Glob]`, no Write — Pass 3 BC-076).
**Enforcement:** STRUCTURAL/MECHANICAL — sandbox + permission block + tool-grant absence are three independent walls.
**Cross-ref:** Pass 3 BC-076; Pass 1 §4 P6 wall.

### NFR-005: The Claude **App token** (not `GITHUB_TOKEN`) authors builder pushes/PRs
**Category:** Security + Reliability (token capability scoping).
**Requirement:** Builder workflows deliberately do **not** override `github_token`, so the Claude GitHub App token is used — it has `workflows:write` (can push branches whose range touches `.github/workflows/`) and, by being a non-`GITHUB_TOKEN` author, **triggers `on-pr-review`** when the PR opens.
**Encoded in:** `nightly-research.yml:56-59` (the "NO github_token override" comment block), `portfolio-rollup.yml:92-93`. Restore/persist/fallback steps still use `GITHUB_TOKEN` for plain git ops (`:36`, `:114`, `:137`).
**Enforcement:** STRUCTURAL — the *absence* of an override selects the App token; the workflow-trigger semantics are a GitHub platform behavior (a `GITHUB_TOKEN`-authored PR cannot trigger another workflow).
**Cross-ref:** Pass 1 §4 "Two CI subtleties".

### NFR-006: Bot-authored PRs are explicitly allow-listed past the reviewer's bot guard
**Category:** Security (intentional, narrowly-scoped bot trust).
**Requirement:** The Codex reviewer must process a PR authored by `claude[bot]`; bot trust is opt-in and named, not blanket.
**Encoded in:** `on-pr-review.yml:62-63` — `allow-bots: true` + `allow-bot-users: "claude[bot]"` (scoped to exactly the builder bot, with the inline rationale "PR is authored by claude[bot]; allow our bot past the guard").
**Enforcement:** STRUCTURAL (Action input). Scoped to a single named bot user.
**Cross-ref:** Pass 1 §4.

### NFR-007: `show_full_output` is OFF to avoid echoing secrets/tool-results into the run log
**Category:** Security (log-leak prevention).
**Requirement:** The Claude action must not stream full tool output to the public run log, where a returned secret could be exposed; the safe capture is the uploaded artifact instead.
**Encoded in:** `nightly-research.yml:87-88` — `# show_full_output left OFF — it can echo tool results (incl. secrets) into the run log. # The full conversation is captured the safe way: the claude-execution-log artifact below.`
**Enforcement:** STRUCTURAL — realized by the *absence* of the `show_full_output` input (default off) plus the artifact path (NFR-016). The engine is public, so the run log is world-readable.
**Cross-ref:** NFR-016; CLAUDE.md "Keep the engine public-clean".

### NFR-008: Reviewer MCP env must not override the inherited real key with a literal
**Category:** Security/Reliability (key-integrity in the reviewer sandbox).
**Requirement:** The Gemini/Codex MCP server inherits `PERPLEXITY_API_KEY` from job env; a literal `$VAR` must **not** be placed in the settings env block (it would override the real inherited key with an unexpanded string — the documented "v1 failure").
**Encoded in:** `on-pr-review.yml:103,107-108` (`# do NOT put a literal "$VAR" in the env block here, that overrides the real key`), `:15-16` comment in header.
**Enforcement:** ASPIRATIONAL (operator convention captured in a comment; not asserted by a test).
**Cross-ref:** Pass 1 §5.

### NFR-009: The engine repo stays "public-clean" — no market-specific or secret content
**Category:** Security (supply-chain / public-surface hygiene).
**Requirement:** The published plugin must contain zero secrets and zero market-specific data; keys live in GitHub Secrets/OIDC; `.mcp.json`/`.env` are gitignored at the instance.
**Encoded in:** `CLAUDE.md` Conventions ("never commit secrets (keys live in GitHub Secrets/OIDC)"; "Keep the engine public-clean"); enforced for content by NFR-001 (protect-secrets on every file) and the P10 generic-engine rule (NFR-024).
**Enforcement:** STRUCTURAL (process) + MECHANICAL backstop (protect-secrets). The repo is public by design (`nightly-research.yml:60` "engine repo is public").
**Cross-ref:** NFR-001, NFR-024.

### NFR-010: Reviewer search MCP is fenced to verification-only (no corpus authoring)
**Category:** Security (capability confinement of a powerful tool).
**Requirement:** The reviewers get Perplexity search to *check* source-faithfulness but are fenced from authoring or suggesting new corpus content.
**Encoded in:** `on-pr-review.yml:13-14` (header), `:121-129` (Gemini prompt: "Use the Perplexity MCP tools ONLY to check whether a cited source supports a claim — never to author or suggest new corpus content").
**Enforcement:** ASPIRATIONAL (prompt fence) reinforced by STRUCTURAL read-only sandbox (NFR-004 means even if it tried, it cannot write).
**Cross-ref:** NFR-004.

---

# B. RELIABILITY / CORRECTNESS

### NFR-011: Every corpus Write passes a fail-closed gate chain
**Category:** Reliability (correctness gate).
**Requirement:** Four PreToolUse:Write hooks run in order on every Write; a violation denies the write regardless of which agent attempted it; a hook that cannot run (missing `jq`) exits non-zero (fails closed, not open).
**Encoded in:** `hooks/hooks.json:3-12` — matcher `Write`, four hooks ordered `protect-secrets → require-citation → layer-discipline-guard → forbidden-phrase-guard`, each `"timeout": 5`. Fail-closed-on-missing-`jq`: `protect-secrets.sh:10`, `require-citation.sh:26-29`, etc.
**Enforcement:** MECHANICAL.
**Cross-ref:** Pass 3 BC-HOOK-A/B; Pass 1 §5 "Fail-closed Write gate chain".

### NFR-012: Quantitative convergence — loop until novelty decays, not until "looks done"
**Category:** Reliability (review-quality oracle).
**Requirement:** The adversary loop continues until finding-novelty stays below `novelty_threshold` for `clean_passes_required` consecutive passes; each pass re-dispatches a **fresh** reviewer blind to prior passes (novelty = new/(new+dup)).
**Encoded in:** `factory.config.template.yaml:38-40` — `novelty_threshold: 0.15`, `clean_passes_required: 3`; same block in every review-bearing `.lobster` (Pass 1 §3.2). Interpreted by `orchestrator.md:32`; restated in `build-track/SKILL.md:37`.
**Enforcement:** ASPIRATIONAL/STRUCTURAL — the *numbers* are config; the loop math is orchestrator-interpreted (Pass 3 BC-068, MEDIUM — no executable test of the convergence math). Freshness is structurally backed by `context.exclude: [prior-review-passes]`.
**Cross-ref:** Pass 2 rule #7; Pass 3 BC-068; Pass 1 §3.2.

### NFR-013: `max_passes` is a hard runaway cap — a stuck draft stops, commits flagged, never silently no-ops
**Category:** Reliability (anti-runaway) + Cost.
**Requirement:** The loop is hard-capped at `max_passes` (default 6, must be ≥ `clean_passes_required`). On cap it stops, sets `LOOP_CAPPED=true`, carries `MUST_FIX_REMAINING`, and the result is flagged "did not fully converge" — it is **never** presented as a PASS and **never** a silent no-op.
**Encoded in:** `factory.config.template.yaml:41-47` (the cap + the rationale: "an unattended night-shift run never burns the whole job timeout and commits nothing"); `nightly-research.yml:72-86` (capped-exit PR title `[DID NOT CONVERGE: M MUST-FIX]`), `ingest.yml:44-46`, `portfolio-rollup.yml:107-119`. Two `on_cap` dispatches: `commit-flagged` (build-track/ingest) vs `surface-to-human` (judgment/cross-track/portfolio) — Pass 1 §3.3.
**Enforcement:** ASPIRATIONAL (the cap honesty / "still loop to the cap" is prose, Pass 3 BC-071 LOW) but the **cap value itself is consumed by the Action prompt** and the flagged-PR title path is template-encoded.
**Cross-ref:** Pass 2 event `ConvergenceCapped`; Pass 3 BC-069…071; Pass 1 §3.3.

### NFR-014: Cite-or-flag-or-drop with zero Type-2 — claims are sourced, flagged, or removed
**Category:** Reliability (corpus integrity, the core quality NFR).
**Requirement:** Every corpus claim carries a citation OR an explicit unsourced flag; AI-invented (Type-2) content is dropped immediately (zero tolerance); real-but-unsourced (Type-1) is flagged, never deleted (anchor-not-strip).
**Encoded in:** `require-citation.sh:92-103` (deny a substantive corpus doc with neither marker nor flag); `researcher.md:29,34-37`; `FACTORY-SOUL.md:9-10,19-23`. Enforced *three ways*: researcher self-check, the hook, the citation-verifier (Pass 2 rule #1).
**Enforcement:** MECHANICAL (the hook, Pass 3 BC-001…014) + ASPIRATIONAL (Type-2 drop is agent-side, no hook detects an invention).
**Cross-ref:** Pass 2 rule #1/#3, claim-disposition SM; Pass 3 BC-001…014.

### NFR-015: Layer discipline — an `L_n` doc may cite only `L_(n-1)`
**Category:** Reliability (structural correctness of the observation stack).
**Requirement:** A layer-tagged corpus doc whose `layer-observes` is not the immediately-lower layer (or `external` for L1) is denied.
**Encoded in:** `hooks/layer-discipline-guard.sh:44-58`; vector-coverage table mandatory at L3 (`LAYER-MODEL.md:35`).
**Enforcement:** MECHANICAL (Pass 3 BC-015…024).
**Cross-ref:** Pass 2 rule #4/#6 (downward-capped quality L4 ≤ min(L3) ≤ min(L2)).

### NFR-016: Sole-committer, one burst → one atomic commit, committer runs last
**Category:** Reliability (commit-race avoidance, audit integrity).
**Requirement:** Only the state-manager commits, as the DAG-terminal step; one production burst yields exactly one atomic commit (corpus + STATE together); the orchestrator holds no Write tool; the committer refuses to commit without recorded review verdicts / on a REVISE.
**Encoded in:** `state-manager.md:17,25-27,31`; structurally the `commit` step is the topo-terminal (Pass 3 BC-041, asserted by `tests/lobster.bats:42`); `orchestrator.md` tool grant excludes Write (Pass 3 BC-064).
**Enforcement:** STRUCTURAL (DAG terminal + tool-grant absence) + ASPIRATIONAL (no-REVISE-commit precondition is prose, Pass 3 BC-074 LOW).
**Cross-ref:** Pass 2 rule #9; Pass 3 BC-073…075.

### NFR-017: CI state round-trip — restore-before / persist-after, runs even on failure
**Category:** Reliability (state durability across stateless runners).
**Requirement:** Pipeline state (`.factory/`) is restored from the orphan `factory-artifacts` branch **before** the builder runs and persisted back **after** — the persist step runs `if: always()` so a failed run still saves partial state; the state-manager only *writes* the workspace file in CI (the Action owns the branch round-trip; double-handling is forbidden).
**Encoded in:** `nightly-research.yml:34-45` (restore), `:111-129` (persist, `if: always()` at `:112`), mirrored in `portfolio-rollup.yml:36-47,132-150`; the "without it the persist step finds an empty `.factory/` and pushes nothing (the loop is a no-op)" rationale at `:30-32`. State-manager CI/local split: `state-manager.md:34-45` (Pass 3 BC-075).
**Enforcement:** STRUCTURAL (Action step ordering + `if: always()` guard).
**Cross-ref:** Pass 2 `STATE` entity; Pass 3 BC-075; Pass 1 §4 state round-trip.

### NFR-018: Fallback PR opener guarantees a PR exists even when Claude's own `gh pr create` didn't fire
**Category:** Reliability (no-silent-loss of a completed run).
**Requirement:** A safety-net step detects the branch Claude pushed (because `claude-code-action`'s `branch_name` output is empty for Bash pushes) and opens a PR if none exists, staying neutral on convergence (it cannot read the loop outcome).
**Encoded in:** `nightly-research.yml:131-157`, `portfolio-rollup.yml:152-172`. Neutral-title `[check convergence]` / `[check convergence]` body referencing the conversation-log artifact.
**Enforcement:** STRUCTURAL (Action step, `if: always()`).
**Cross-ref:** Pass 1 §4 "fallback PR opener".

### NFR-019: `concurrency` cancels superseded PR-review runs
**Category:** Reliability/Cost (no duplicate review work on rapid pushes).
**Requirement:** A new push to a PR cancels the in-flight review for that PR.
**Encoded in:** `on-pr-review.yml:28-31` — `concurrency: { group: pr-review-${{ github.event.pull_request.number }}, cancel-in-progress: true }`.
**Enforcement:** MECHANICAL (GitHub platform).
**Cross-ref:** —

### NFR-020: Diff-scoping discipline — reviewers review only the files the PR changed
**Category:** Reliability (review actually reviews the change; avoids whole-checkout no-op).
**Requirement:** Each reviewer is given the exact changed-file list (`gh pr diff --name-only`) and reviews only those — "otherwise the reviewer has the whole checkout but no scope and no-ops."
**Encoded in:** `on-pr-review.yml:6-8` (header), `:39-51` (Codex prompt assembly), `:91-97,121-123` (Gemini changed-files compute + prompt).
**Enforcement:** STRUCTURAL (the prompt is constructed from the diff) — a structural fix for a known failure mode.
**Cross-ref:** Pass 1 §4 "Diff-scoping discipline".

### NFR-021: Builder never auto-merges — research advances behind a human merge gate
**Category:** Reliability (irreversible-action gate) — see also NFR-031.
**Requirement:** All builder Actions open a PR and explicitly `Do NOT merge` at autonomy 3; the morning human disposes.
**Encoded in:** `nightly-research.yml:85` (`Do NOT merge`), `ingest.yml:46`, `weekly-maintenance.yml:37`, `portfolio-rollup.yml:120`; `docs/AUTONOMY.md:20-22`.
**Enforcement:** ASPIRATIONAL (prompt) + STRUCTURAL (the Action has no merge step; `claude-code-action` returns a branch+PR by default).
**Cross-ref:** NFR-031.

---

# C. OBSERVABILITY / AUDITABILITY

### NFR-022: No model is a black box — every model run uploads its full output as an artifact
**Category:** Observability (full-trace auditability).
**Requirement:** Every CLI/model run uploads its complete conversation/output as a retained artifact, in addition to any PR comment — parity across builder and both reviewers.
**Encoded in:** `nightly-research.yml:90-98` (`claude-execution-log-${{ github.run_id }}`, `retention-days: 30`, `if: always()`), `ingest.yml:49-56`, `weekly-maintenance.yml:39-47`, `portfolio-rollup.yml:122-129`; reviewer side `on-pr-review.yml:68-75` (`codex-review-log`, `retention-days: 30`) and `:104` (`upload_artifacts: true` for Gemini). Header rule `on-pr-review.yml:10-11` "NO BLACK BOXES (operator rule)".
**Enforcement:** STRUCTURAL/MECHANICAL — `upload-artifact@v4` steps guarded `if: always()`.
**Cross-ref:** NFR-007 (the artifact is the *safe* capture vs. the run log).

### NFR-023: Findings are posted as PR comments (human-visible review record)
**Category:** Observability (in-context audit trail on the artifact under review).
**Requirement:** Both reviewers post their findings back as a PR comment, not just an artifact.
**Encoded in:** `on-pr-review.yml:76-83` (Codex `gh pr comment`), `:130-138` (Gemini `gh pr comment`), each `if: always()` and no-op-safe (`[ -s codex-review.md ]` / `[ -n "$SUMMARY" ]`).
**Enforcement:** MECHANICAL (Action step).
**Cross-ref:** NFR-022.

### NFR-024: The commit trail is the audit log; STATE.md is the resumable source of truth
**Category:** Observability (durable provenance + zero-context resume).
**Requirement:** One atomic commit per burst makes the git log the artifact trail; `.factory/STATE.md` is the single zero-context-resume file (phase, decisions, branches, drift, track build log), living on the orphan `factory-artifacts` branch.
**Encoded in:** `FACTORY-SOUL.md:14` (P8 "External filesystem is memory; state survives sessions"); `state-manager.md:31-47`; `nightly-research.yml:99-107` / `ingest.yml:57-65` run-summaries write `session_id` + the artifact name to `$GITHUB_STEP_SUMMARY` (resume with `--resume <session_id>`). CLAUDE.md "`git log` is the artifact trail".
**Enforcement:** STRUCTURAL (commit model + branch model) + ASPIRATIONAL (STATE.md content discipline is state-manager prose).
**Cross-ref:** Pass 2 `STATE` entity; NFR-016, NFR-017.

### NFR-025: Researcher announces which search path it took, for an auditable run log
**Category:** Observability (tool-path transparency).
**Requirement:** The researcher probes MCP once, announces MCP-vs-fallback, and records source/author/venue/date/URL per source — so the run log shows how each claim was gathered.
**Encoded in:** `researcher.md:45-51` ("Announce which path you took so the run log is auditable"), `:55` (record source metadata).
**Enforcement:** ASPIRATIONAL (agent prose).
**Cross-ref:** Pass 2 op `draft-L1/L2`.

---

# D. PERFORMANCE / COST

### NFR-026: Hooks are bounded — `timeout 5` per hook, deterministic, <100ms target
**Category:** Performance (gate latency bound).
**Requirement:** Each PreToolUse:Write hook must complete within 5s; the hooks are designed deterministic and sub-100ms (no LLM, pure Bash+`jq`/`grep`).
**Encoded in:** `hooks.json:7-10` (`"timeout": 5` ×4); `protect-secrets.sh:5-6` header "Deterministic, <100ms"; `require-citation.sh`/others likewise pure-Bash.
**Enforcement:** MECHANICAL (timeout enforced by the hook runner) + STRUCTURAL (no network/LLM in a hook).
**Cross-ref:** Pass 1 §5 ("runs <100ms").

### NFR-027: Each Action is a bounded unit with a job timeout well under the 6h hosted cap
**Category:** Performance/Cost (runaway-runner guard).
**Requirement:** Every scheduled Action carries a `timeout-minutes` sized to "one track / one synthesis," never "the whole corpus"; the 6h hosted-runner cap is the binding execution limit.
**Encoded in:** `nightly-research.yml:25` (`timeout-minutes: 120` "bounded — one track/work-item, not the whole corpus (§12.2)"), `portfolio-rollup.yml:29` (120), `weekly-maintenance.yml:20` (90), `ingest.yml:20` (60), `on-pr-review.yml:35` (adversary 30) / `:87` (citation-verify 20), engine `ci.yml:12` (10). `docs/AUTONOMY.md:34-35` "the 6-hour hosted-runner cap is the binding execution limit … never 'do the whole corpus'."
**Enforcement:** MECHANICAL (GitHub `timeout-minutes`) + ASPIRATIONAL (the "bounded unit" sizing is a design rule).
**Cross-ref:** NFR-013 (max_passes is the in-loop counterpart to the job timeout).

### NFR-028: Model-tier assignment is the primary cost lever (opus/sonnet/haiku by role)
**Category:** Cost (spend-vs-capability allocation).
**Requirement:** Each agent/Action is assigned the cheapest adequate tier: opus for adversarial/judgment-bearing roles, sonnet for the builder, haiku for mechanical sweeps; the config exposes builder/reviewer tiers per market.
**Encoded in:** Agent frontmatter `model:` (Pass 0/1: opus = adversary-reviewer/citation-verifier/judgment-writer/pm-doc-writer; sonnet = orchestrator/researcher/synthesizer; haiku = state-manager/editorial-sweeper/consistency-validator/dashboard-builder). Action model flags: `nightly-research.yml:68` / `ingest.yml:36` / `portfolio-rollup.yml:99` `--model claude-sonnet-4-6`; `weekly-maintenance.yml:32` `--model claude-haiku-4-5-20251001` (cheapest tier for hygiene); reviewer `on-pr-review.yml:59` `model: gpt-5.5`. Config knobs `review.builder_model_tier`/`reviewer_model_tier` (`factory.config.template.yaml:36-37`).
**Enforcement:** STRUCTURAL (the tier is wired into each agent/Action) — a deliberate cost allocation.
**Cross-ref:** Pass 2 §2a.4 "Model-family tier".

### NFR-029: Cross-vendor budget governance — per-run cap + escalating cumulative tiers
**Category:** Cost (spend bound).
**Requirement:** Spend is bounded per-run and cumulatively across three vendors via escalating tiers (warn → alert → pause → hard_stop); a budget-forced model downgrade on the critical path **pauses** rather than continuing underpowered. Cost is framed *per verified finding*, not a spend floor.
**Encoded in:** `factory.config.template.yaml:64-74` — `per_run_cap: 25`, `thresholds: {warn:100, alert:250, pause:400, hard_stop:500}`, `vendors: [anthropic, openai, google]`, `on_critical_path_downgrade: pause`; `docs/AUTONOMY.md:24-32`.
**Enforcement:** **ASPIRATIONAL / DECLARATIVE — no enforcer located.** The thresholds are config the engine "reads," but no hook, CLI, Action step, or test was found that *measures* cumulative spend and acts on a tier. **This is a real gap** (see Gaps; consistent with Pass 2 gap #4 and Pass 3 gap #7).
**Cross-ref:** Pass 2 event `BudgetThresholdCrossed` (MEDIUM, "enforcement agent not located"); Pass 3 gap #7.

### NFR-030: Effort-scaled researcher fan-out — scale legs to task size, document what was dropped
**Category:** Cost (anti-over-spawning) + Completeness.
**Requirement:** The researcher scales effort to the task (one source = light pass; comparison = a few legs; full track = matrix fan-out) and documents any failed sourcing attempt (P9 "scale effort; document what you dropped").
**Encoded in:** `researcher.md:58` ("Effort-scale (P9). One source = a light pass; a comparison = a few legs; a full track = matrix fan-out. Document any sourcing attempt that failed"); `FACTORY-SOUL.md:15` (P9).
**Enforcement:** ASPIRATIONAL (agent prose).
**Cross-ref:** Pass 2 op `draft-L1/L2`; FACTORY-SOUL P9.

---

# E. SCALABILITY / EXTENSIBILITY

### NFR-031: Human gates on every irreversible/judgment action, at every autonomy level
**Category:** Reliability/Governance (positioned here as the autonomy scaling axis).
**Requirement:** L5 judgment, L6 portfolio, PM productization, and publish/external delivery are `always_human` regardless of autonomy level; the autonomy ladder (3 → 3.5 → 4) only ever raises *research-layer* merge autonomy.
**Encoded in:** `factory.config.template.yaml:48-62` (`autonomy_level: 3`; `merge.auto_merge_when` consulted only at ≥3.5; `merge.always_human: [l5_judgment, l6_portfolio, pm_productization, publish_or_external_delivery]`); `docs/AUTONOMY.md:6-22`; `human-approval` workflow steps in judgment/portfolio/pm-doc-chain (Pass 1 §3.1).
**Enforcement:** STRUCTURAL (workflow `human-approval` terminal + Action never-merge) + ASPIRATIONAL (self-approval prohibition is prose, Pass 3 BC-072).
**Cross-ref:** Pass 2 rule #10; Pass 3 BC-072; `docs/AUTONOMY.md`.

### NFR-032: Generic engine, per-market config (P10) — the scaling axis is config+seed, never code
**Category:** Scalability/Extensibility (the defining architectural NFR).
**Requirement:** A new market is a new `factory.config.yaml` + `seed/` and nothing else; the engine carries zero market-specific logic; if a behavior can't be expressed in config+seed, **stop and surface the gap**.
**Encoded in:** `FACTORY-SOUL.md:16` (P10); `factory.config.template.yaml` (the 26-key knob surface, Pass 2 §2a.6); `forbidden-phrase-guard.sh:30-32` (generic patterns only; market names go in `editorial.forbidden_phrases_extra`, Pass 3 BC-036); `init-market/SKILL.md` Iron Law.
**Enforcement:** STRUCTURAL (config-driven behavior; Pass 2 verified all variability is config-expressible) + ASPIRATIONAL (the "surface the gap" rule is prose). CI proves the template config validates (NFR-035).
**Cross-ref:** Pass 2 rule #12 + §2a.6 "P10 verdict"; Pass 3 BC-036.

### NFR-033: Multi-market portfolio rollup scales by appending a manifest entry
**Category:** Scalability (cross-market aggregation without code).
**Requirement:** L6 portfolio synthesis pulls each registered instance's **named L4/L5 only** (never L3/L2/L1) per `portfolio/manifest.yaml`; adding a market to the portfolio = appending an `instances[]` entry; the rollup never reaches below the cross-market layer boundary.
**Encoded in:** `portfolio-rollup.yml:49-82` (manifest-driven, glob-scoped, blobless shallow clone, `find -path "./$pat"`); `portfolio/manifest.yaml` schema (Pass 2 entity); `init-market/SKILL.md:45-49` (step 7 appends the entry).
**Enforcement:** STRUCTURAL (manifest-driven loop; the glob restriction is the layer-discipline boundary at the file-copy level).
**Cross-ref:** Pass 2 `Portfolio`/`PortfolioManifest`; Pass 1 §4.

### NFR-034: Marketplace publish + bump-engine propagation — instances enable, never fork
**Category:** Extensibility (single-source engine distribution).
**Requirement:** The engine ships once as a Claude Code plugin published to a marketplace; instances *enable* it (`plugin_marketplaces` + `plugins:`), so an engine bump propagates without per-instance code changes.
**Encoded in:** `nightly-research.yml:61-64` / `ingest.yml:31-34` / `weekly-maintenance.yml:28-31` / `portfolio-rollup.yml:94-97` (`plugin_marketplaces: https://github.com/drbothen/research-factory.git` + `plugins: research-factory@research-factory`); `.claude-plugin/plugin.json` (the published manifest); `ci.yml:25-31` validates the marketplace + plugin manifests.
**Enforcement:** STRUCTURAL (plugin distribution model).
**Cross-ref:** Pass 0/1 registration layer.

---

# F. MAINTAINABILITY

### NFR-035: CI validates every manifest, lobster, Action template, and the template config, and runs the bats suite
**Category:** Maintainability (keep-the-suite-green guard against engine rot).
**Requirement:** Every push/PR validates: plugin/marketplace/hooks JSON manifests; the hooks.json wrapped-shape invariant; every `.lobster`; every Action template YAML; the template config (must validate — protects against template rot, Pass 3 BC-059); and the full bats suite — within a 10-minute job.
**Encoded in:** `.github/workflows/ci.yml:25-56` (`Validate plugin JSON manifests`, `Assert hooks.json uses the wrapped … shape`, `Validate all .lobster workflows` via `lobster-parse validate`, `Validate Action templates + template config parse`, `Run plugin test suite`); `timeout-minutes: 10` at `:12`. Suite: `tests/run-all.sh` over 4 bats files / 35 `@tests` (Pass 3).
**Enforcement:** MECHANICAL (CI is the merge gate, per CLAUDE.md "let CI's `test` gate pass, then squash-merge").
**Cross-ref:** Pass 3 component index (all 35 tests); CLAUDE.md Build/test/validate.

### NFR-036: The DSL validator refuses malformed/cyclic workflows before any dispatch
**Category:** Maintainability/Reliability (well-formedness guarantee for the pipeline-as-data).
**Requirement:** `lobster-parse validate` rejects unknown step types, missing required fields, unknown `depends_on` targets, dependency cycles, empty/nameless workflows, and duplicate names; `order` refuses an invalid workflow — so the orchestrator only ever dispatches a well-formed, acyclic DAG.
**Encoded in:** `bin/lobster-parse` (schema + Kahn cycle detection + topo order); exercised by `tests/lobster.bats` (8 tests, Pass 3 BC-039…051).
**Enforcement:** MECHANICAL (parser + tests + the orchestrator's validate-then-order precondition, Pass 3 BC-065).
**Cross-ref:** Pass 1 §3; Pass 3 BC-039…051,065.

### NFR-037: Config-of-record is itself validated, and the shipped template must pass validation
**Category:** Maintainability (config correctness + template non-rot).
**Requirement:** `factory-config.sh validate` enforces required fields (market/slug/seed/non-empty vectors+tracks with id+name / slug+name); the shipped `factory.config.template.yaml` must itself validate (a regression guard).
**Encoded in:** `bin/factory-config.sh:78-103`; `tests/config.bats` (7 tests, Pass 3 BC-052…060); `ci.yml:52-53` validates the template config.
**Enforcement:** MECHANICAL.
**Cross-ref:** Pass 3 BC-052…060; Pass 2 §2a.6.

---

## Enforcement summary (count by mode)

| Enforcement mode | NFRs | Note |
|---|---:|---|
| **MECHANICAL** (hook/CLI/CI/platform) | NFR-001, 004(partial), 011, 014(hook part), 015, 019, 023, 026, 035, 036, 037 | The deterministic spine: 4 hooks, lobster-parse, factory-config, CI, GitHub `concurrency`/`timeout-minutes`/`permissions`. |
| **STRUCTURAL** (shape: tool-grant/family/DAG/permissions/template) | NFR-002, 003, 004, 005, 006, 007, 009, 016, 017, 018, 020, 028, 031, 032, 033, 034 | Enforced by the system's shape; cannot be narrated around, but no explicit assertion fires. |
| **ASPIRATIONAL** (prose Iron Law / constitution / comment) | NFR-008, 010, 012(math), 013(honesty), 021, 024(content), 025, 029, 030 | Real intent, LLM-reasoning-enforced; the highest-risk band for drift. |

**Headline:** 37 NFRs across 6 categories. The engine's reliability/correctness NFRs are the densest (11) and the best-enforced (hooks + lobster-parse + CI are all MECHANICAL). The single most important **unenforced** NFR is **budget governance (NFR-029)** — declared in config, with no located enforcer.

## Configuration values that encode NFR decisions (consolidated)

| Knob | Value (default) | NFR encoded | Source |
|---|---|---|---|
| Hook chain timeout | `timeout: 5` (×4) | NFR-026 gate-latency bound | `hooks.json:7-10` |
| `novelty_threshold` | `0.15` | NFR-012 convergence oracle | config `:39` |
| `clean_passes_required` | `3` | NFR-012 | config `:40` |
| `max_passes` | `6` (≥ clean_passes) | NFR-013 runaway cap | config `:41` |
| `autonomy_level` | `3` (start) / 3.5 / 4 | NFR-031 autonomy ladder | config `:48` |
| `merge.always_human` | l5/l6/pm/publish | NFR-031 irreversible gate | config `:58-62` |
| `budget.per_run_cap` | `25` usd | NFR-029 spend bound | config `:67` |
| `budget.thresholds` | warn100/alert250/pause400/hard_stop500 | NFR-029 (unenforced) | config `:68-72` |
| `on_critical_path_downgrade` | `pause` | NFR-029 pause-not-underpower | config `:74` |
| builder/reviewer model tier | sonnet / different-family | NFR-028 cost lever, NFR-004 P6 wall | config `:36-37` |
| Action `timeout-minutes` | 120/90/60/30/20/10 | NFR-027 bounded unit | all Action templates |
| Action model flag | sonnet (build) / haiku (maint) / gpt-5.5 (review) | NFR-028 | nightly/maint/on-pr-review |
| Artifact `retention-days` | `30` | NFR-022 audit retention | all Action templates |
| `permissions.id-token` | `write` (builders) / absent (review) | NFR-003 least-privilege | Action templates |
| `sandbox` / `safety-strategy` | `read-only` (reviewer) | NFR-004 | `on-pr-review.yml:60-61` |
| `concurrency.cancel-in-progress` | `true` | NFR-019 | `on-pr-review.yml:31` |
| `REQUIRE_CITATION_MIN_LINES` | `3` (env-overridable) | NFR-014 stub threshold | `require-citation.sh:24` |

---

## Resume checkpoint

```yaml
pass: 4
status: complete
files_read_this_pass: 13   # 3 prior pass outputs + protect-secrets.sh + hooks.json + 5 Action templates (nightly, on-pr-review, portfolio-rollup, ingest, weekly-maintenance) + mcp.json + config template + AUTONOMY.md + FACTORY-SOUL.md + ci.yml + researcher.md
nfrs_catalogued: 37
categories: {security: 10, reliability: 11, observability: 4, performance_cost: 5, scalability_extensibility: 4, maintainability: 3}
enforcement: {mechanical: 11, structural: 16, aspirational: 10}   # NFRs may span modes; counted by primary
unenforced_nfr_flagged: NFR-029 budget-governance (no enforcer located — confirms pass-2 gap-4 / pass-3 gap-7)
key_config_values: {novelty_threshold: 0.15, clean_passes_required: 3, max_passes: 6, autonomy_level: 3, per_run_cap: 25, budget_tiers: [100,250,400,500], hook_timeout: 5, action_timeouts: [120,90,60,30,20,10], artifact_retention_days: 30}
timestamp: 2026-06-01T00:00:00Z
next_pass: 5
next_pass_name: Convention & Pattern Catalog
```

## Remaining gaps / next candidate scope (for Pass 5 + Pass-4 deepening)

1. **Budget enforcement is unimplemented (NFR-029, the biggest finding).** `budget.thresholds` / `per_run_cap` / `on_critical_path_downgrade` are declarative config with **no located enforcer** — no hook reads a cumulative-spend ledger, no Action step measures spend, no orchestrator rule was found that pauses on a tier. Pass-4 deepening should confirm whether this is (a) intended-as-human-discipline, (b) deferred to a future GitHub-billing integration, or (c) a genuine missing mechanism. Cross-confirms Pass-2 gap #4 / Pass-3 gap #7.
2. **The convergence math (NFR-012) has no executable test.** The novelty = new/(new+dup) < 0.15 × 3-clean-passes contract and the capped-exit flag text (NFR-013) are orchestrator/skill prose with no bats/integration test (Pass-3 gap #1). An NFR-completeness round would note the absence of a test that simulates a capped exit and asserts the `[DID NOT CONVERGE: M MUST-FIX]` PR-title path.
3. **No test exercises the `timeout 5` hook bound or the fail-closed `jq`-missing path** (NFR-026, NFR-011) — asserted from `hooks.json` + `command -v jq` guards only (Pass-3 gap #3). Performance/reliability NFRs are config-declared, not test-pinned.
4. **Reviewer-key-integrity (NFR-008) and verification-only-fence (NFR-010) are comment-only.** No test/lint asserts that a literal `$VAR` is absent from the Gemini settings env block, nor that the reviewer cannot author corpus content (the read-only sandbox is the real backstop). Candidate for a YAML-lint rule.
5. **Artifact retention / log-leak posture (NFR-007, NFR-022) is per-template, not centrally enforced.** `retention-days: 30` and the OFF `show_full_output` posture are repeated in each template; a drifted copy in a future Action could regress silently. A template-lint (mirroring `ci.yml`'s hooks.json shape assertion) would close this.
6. **Autonomy-level transition triggers (NFR-031) are prose.** The ladder 3 → 3.5 → 4 "earned per-layer after the gates prove themselves" (`AUTONOMY.md:8`) has no encoded promotion mechanism; it is a human decision. Pass 5 (conventions) may catalog this as the autonomy-promotion pattern.
7. **OIDC scope is granted but its downstream use is opaque to this tree.** `id-token: write` is "required by claude-code-action (OIDC)" — the actual token exchange happens inside the vendor action, outside this repo. NFR-003 is verified at the permissions-block level only.
```