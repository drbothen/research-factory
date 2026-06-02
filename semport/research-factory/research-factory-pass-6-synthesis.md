# Pass 6: Synthesis & Validation — research-factory engine

> Scope of record: `/Users/jmagady/Dev/research-factory/plugins/research-factory/` (the plugin = the engine).
> This pass is the **final broad-sweep deliverable** of Phase A. It reads all of Pass 0–5 (`-pass-0-inventory` … `-pass-5-conventions`) and reconciles them against source where they disagree.
> It does **not** re-derive findings from scratch — it ties them together, resolves cross-pass conflicts, grades confidence, and produces the **prioritized deepening backlog** that drives Phase B (convergence deepening, starting Passes 2 & 3).
> Source re-checks performed this pass (to resolve conflicts): agent file count (`find … | wc -l` → 11), workflow count (→ 7), bats `@test` count per file (`awk` → 7+11+9+8 = 35), and a budget-enforcer scan of all `.sh`/`lobster-parse` (→ no enforcer found, confirming the gap).

---

## 1. Unified system understanding (the one-picture narrative)

**What the engine is.** The research-factory engine is a **domain-agnostic, declarative research-corpus production pipeline** shipped as a Claude Code plugin (`plugin.json` v0.9.0, MIT). It has *almost no runtime application code*: across 64 files / ~3,631 LOC, the only general-purpose code is `bin/lobster-parse` (147 LOC Python — a DAG validator/orderer) and `bin/factory-config.sh` (109 LOC Bash — a config validator). The "program" is a **contract distributed across four declarative substrates** (Pass 0 §What-this-is, Pass 1 §What-the-architecture-is):

1. **Markdown-as-agent** prompt files (11 subagents) — the behavioral spec;
2. **`.lobster` YAML DAGs** (7 workflows) — pipeline-as-data;
3. **Bash PreToolUse:Write hooks** (4 gates) — the deterministic fail-closed enforcement;
4. **`factory.config.yaml`** (26-key knob surface) — the per-market policy layer.

**How it works (inventory → architecture → domain → contracts → NFR → conventions, as one chain):**

- **Inventory (Pass 0)** establishes the substrate map and the load-bearing fact that *behavior is data, not code* — which is why every later pass measures "enforcement mode" rather than "call graph."
- **Architecture (Pass 1)** decomposes the engine into **7 one-directional layers** (A registration → B entry → C orchestration → D workflow-DAGs → E agents → F cross-cutting gates → G templates) running on **2 execution surfaces**: (a) a local Claude plugin (single model family, hooks active, P6 *simulated*) and (b) GitHub Actions (the **cross-family wall realized structurally** — Claude builds, Codex adversary-reviews, Gemini citation-verifies). The heart is the **convergence state machine**: a `loop` step re-dispatches a *fresh, blind* reviewer until novelty < 0.15 for 3 clean passes, hard-capped at 6 passes, with two honest capped-exit dispatches (`commit-flagged` / `surface-to-human`).
- **Domain (Pass 2)** shows the *content* the machine produces: a **layered observation stack L1→L6** where each `L_n` cites only `L_(n-1)`, every Claim is **cite-or-flag-or-drop** (Type-1 flagged, Type-2 dropped), and the corpus stays **opinion-free through L4** (judgment only at L5, cross-market judgment only at L6). 16 entities, 19 value objects/enums, 12 business rules, 4 state machines. The **P10 invariant** ("a market = config + seed, never code") is *verified*: all 26 config keys map cleanly to a parameterized behavior; nothing market-specific is hardcoded.
- **Contracts (Pass 3)** pins the *mechanically enforced* surface from the **35 bats `@test`s**: 78 behavioral contracts (76 numbered + 2 cross-cutting), of which 31 are HIGH (test-backed: the 4 hooks, lobster-parse, factory-config), and the entire agent/orchestration behavioral layer (Group 7, BC-064…076) is MEDIUM/LOW because it is enforced by *structure + prose*, never by a checker.
- **NFR (Pass 4)** reframes the same surface as 37 non-functional requirements across 6 categories, classified MECHANICAL (11) / STRUCTURAL (16) / ASPIRATIONAL (10). The reliability/correctness band is densest and best-enforced; the single biggest *unenforced* NFR is **budget governance (NFR-029)**.
- **Conventions (Pass 5)** shows the engine is *unusually internally consistent* because **nearly every convention is also an enforced invariant** (a hook, a validator, a DAG-terminal, or a CI step backs it): 45 conventions, 11 design patterns, 6 grounded anti-patterns. The two genuine soft spots are *coverage* (agent behavior + two declarative idioms untested) and *prose-only enforcement* of the honesty contracts.

**The single thread that unifies all six passes:** the engine **enforces structurally, executes by reasoning.** Determinism (hooks fail-closed, lobster-parse refuses bad DAGs, info-asymmetry via `context.exclude` + read-only tool grants + CI family split, sole-committer as DAG-terminal) guards the boundaries; an LLM orchestrator interprets the runtime semantics (convergence math, gate predicates, capped-exit honesty) that no checker validates. Every confidence grade and every gap in this analysis falls out of *which side of that line* a behavior sits on.

---

## 2. Cross-pass inconsistency reconciliation

Each row is a contradiction *between passes* (or a number worth pinning), resolved against source.

| # | Apparent conflict | Resolution (source-checked) | Status |
|---|---|---|---|
| **R-1** | **Agent count: "11 agents" (Pass 0/1/5) vs "10 workers" (Pass 1 §1 layer E, Pass 1 Mermaid)** | Both correct, different denominators. `find agents -name '*.md' \| wc -l` → **11 files = 11 agents**, one of which is the `orchestrator`. Pass 1 says "11, minus orchestrator = **10 worker agents**." Not a conflict — terminology. **Canonical: 11 agents total (1 orchestrator + 10 workers).** | RESOLVED |
| **R-2** | **BC totals: Pass 3 ledger table lists "MEDIUM 39" but the headline says "MEDIUM 43"** | The ledger *table* row (line 400) under-counts; the headline (line 403) and checkpoint (`confidence: {HIGH: 31, MEDIUM: 43, LOW: 4}`) are authoritative: **31 + 43 + 4 = 78** matches the stated total (76 numbered + 2 cross-cutting). The "39" is a stale intermediate. **Canonical: HIGH 31 / MEDIUM 43 / LOW 4 = 78 contracts.** | RESOLVED (Pass-3 internal typo flagged for deepening) |
| **R-3** | **`@test` count: Pass 3 says "35 tests (config 7, hooks 9, hooks-v05 11, lobster 8)"; Pass 5 repeats it** | Re-derived this pass via `awk '/^@test/'`: config **7**, hooks-v05 **11**, hooks **9**, lobster **8** → **35**. **Confirmed exactly.** | RESOLVED |
| **R-4** | **Workflow count: "7 workflows" everywhere, but Pass 0 once called portfolio-synth "the 7th workflow" implying earlier docs had 6** | `find workflows -name '*.lobster' \| wc -l` → **7**. The "7th workflow" phrasing is historical (portfolio-synth was the newest addition, repo v1.0 item #4); the current tree has 7. **Canonical: 7.** | RESOLVED |
| **R-5** | **Step types: Pass 0 says "4 step types (agent/loop/gate/human-approval)"; Pass 1 says "7 step types"** | `lobster-parse` `STEP_TYPES` defines **7** (`agent skill gate human-approval loop parallel sub-workflow`); the **shipped 7 workflows use 5** of them (`agent skill gate human-approval loop`); `parallel`/`sub-workflow` are defined-but-unused. Pass 0's "4" was the pre-deepening undercount (missed `skill`). **Canonical: 7 defined, 5 used.** Pass 1 is correct; Pass 0 is superseded. | RESOLVED |
| **R-6** | **Budget enforcement: Pass 1 §5 describes it as a working cross-cutting concern ("At hard_stop, refuse new agent dispatch"); Pass 2/3/4 flag it as unenforced** | Source scan this pass: **no `.sh` or `lobster-parse` references `hard_stop`/`per_run_cap`/cumulative spend.** The thresholds exist only in `factory.config.template.yaml` as declarative policy and in `AUTONOMY.md` prose. Pass 1 §5 described the *intended* behavior as if realized; Pass 2/3/4 correctly downgraded it to **declared-but-unenforced (NFR-029, ASPIRATIONAL)**. **Canonical: budget governance has NO located enforcer** — Pass 1's framing is the optimistic reading; the later passes are correct. | RESOLVED (Pass 1 §5 budget row should be re-graded ASPIRATIONAL in deepening) |
| **R-7** | **Entity/engine-layer naming collision: "layers" means two different things** | Deliberate and consistently disambiguated: **engine layers A–G** (code structure, Pass 1) vs **corpus content layers L1–L6** (domain, Pass 2). Every pass that touches both flags the distinction (Pass 1 §1, Pass 2 §0). **Not a conflict — a documented homonym.** | RESOLVED (no action) |
| **R-8** | **Model-family wall (P6): "realized in agent frontmatter" (implied by Pass 0 model table) vs "realized at CI" (Pass 1/2/4)** | Agent frontmatter assigns *tiers within one family* (opus/sonnet/haiku) — this does **not** create cross-family diversity. The **cross-family** wall (Claude vs Codex vs Gemini) is realized **only at the GitHub-Action layer** (`on-pr-review.yml`). Locally, P6 is *simulated* (same family plays both roles — acknowledged fallback). **Canonical: tiers in frontmatter; families at CI.** Pass 1/2/4 correct; Pass 0's model table is necessary-but-not-sufficient. | RESOLVED |
| **R-9** | **LOC total: Pass 0 "~3,631" — any drift across passes?** | All later passes cite "~3,631 LOC / 64 files" verbatim from Pass 0; none re-derived. Treated as the single source of truth (Pass 0 re-derived it via `find … -exec wc -l`). No conflict; **one un-re-verified number** (low risk). | RESOLVED (carry-forward, not re-checked this pass) |

**Unresolved conflicts:** none. All nine reconcile against source. Two carry a *deepening action* (R-2: fix the Pass-3 ledger typo; R-6: re-grade the Pass-1 §5 budget row).

---

## 3. Confidence assessment

| Area | Confidence | Basis |
|---|---|---|
| **Inventory (Pass 0)** | **HIGH** | All counts re-derived via `find … wc`; re-confirmed this pass (agents 11, workflows 7, tests 35). One number (3,631 LOC) carried forward un-rechecked → still HIGH. |
| **Architecture (Pass 1)** | **HIGH** | 19 source files read directly (orchestrator, lobster-parse, 7 workflows, 4 hooks, 3 Action templates, 2 skills, config). The 2-surface split and convergence SM are multiply-confirmed. *Caveat:* the §5 budget-governance row is over-stated (R-6). |
| **Domain model (Pass 2)** | **HIGH** for the layer spine, entity catalog, value objects, and the 26-key config enumeration (all explicit in templates + LAYER-MODEL + agents). **MEDIUM** for: PM-consumes-finding edge, phase-transition triggers, STATE.md field schema (modeled from prose; live file external to tree). |
| **Behavioral contracts (Pass 3)** | **HIGH** *only* for the 31 test-backed BCs (the 4 hooks + 2 bin tools, exercised by 35 `@test`s). **MEDIUM** for the 43 logic-derived (regex/control-flow, no test). **LOW** for the 4 prose-only honesty contracts. The entire **agent/orchestration behavioral layer is NOT test-backed.** |
| **NFR (Pass 4)** | **HIGH** for the MECHANICAL band (11 NFRs: hooks, lobster-parse, config, CI, GitHub platform). **MEDIUM/LOW** for the 10 ASPIRATIONAL NFRs. The **budget NFR-029 is the lowest-confidence claim that it is "enforced" — confirmed unenforced this pass.** |
| **Conventions (Pass 5)** | **HIGH** — 45 conventions grounded in directly-read source (all 11 agent frontmatters, `forbidden-phrase-guard.sh` verbatim skeleton, lobster idioms, git log). **MEDIUM** only where conformance was *inferred* across unread files (the other 3 hooks' byte-level skeleton, the 6 Action templates' naming). |

**Highest-confidence claims (multiply-confirmed + test-backed):** the fail-closed Write gate chain (4 hooks, BC-001…038, 23 of 35 tests); the lobster-parse DAG validator (BC-039…051); the config validator (BC-052…060); the sole-committer-as-DAG-terminal (BC-041 asserted by `lobster.bats:42`); the P10 config-completeness verdict.

**Lowest-confidence claims (prose-only / single-source / inferred):** budget enforcement (NFR-029, no enforcer); the convergence math (NFR-012/BC-068 — no test simulates a capped exit); the capped-exit no-fake-PASS honesty (BC-071); the no-REVISE-commit precondition (BC-074); the STATE.md live field schema; the market-phase transition triggers.

---

## 4. Gap report (the Phase-B driver)

### 4a. Orphaned / under-documented subsystems (treated shallowly by the broad sweep)

| Gap | What's thin | Where it should deepen | Severity |
|---|---|---|---|
| **G-1 · Agent/convergence behavioral layer has NO executable test** | The entire orchestration + agent surface (convergence math, info-asymmetry, sole-committer precondition, capped-exit honesty) is enforced by structure + prose only. 0 of 35 tests touch it. All of Pass-3 Group 7 (BC-064…076) is MEDIUM/LOW. | **Pass 3 deepening** — read each agent body in full (not just frontmatter); enumerate function-level Iron-Law contracts; identify the *single highest-value missing test* (simulate a capped exit, assert the `[DID NOT CONVERGE: M MUST-FIX]` PR title). | **HIGH** |
| **G-2 · Budget governance NFR has no enforcer** | `budget.thresholds`/`per_run_cap`/`on_critical_path_downgrade` are config-only. Confirmed this pass: no `.sh`/`lobster-parse` reads them; no Action step measures spend. Pass 1 §5 over-described it as working (R-6). | **Pass 4 deepening** (primary) — determine if it is (a) intended human discipline, (b) deferred to GitHub-billing integration, or (c) a true missing mechanism. **Pass 1 deepening** — re-grade the §5 row ASPIRATIONAL. | **HIGH** |
| **G-3 · STATE.md field schema is modeled from prose only** | The resume aggregate (phase / step / decisions / branches / drift / track-build-log) is described in `state-manager.md`; the *live* file is on the orphan `factory-artifacts` branch, external to the tree. | **Pass 2 deepening** — read `git show origin/factory-artifacts:STATE.md` to confirm the actual aggregate shape vs the prose model. | **MEDIUM** |
| **G-4 · GitHub-Action runtime behavior read at the YAML level only** | The 6 Action templates were read for security/reliability NFRs, but the *runtime semantics* (token exchange inside `claude-code-action`, the fallback-PR detection logic, the Codex/Gemini prompt assembly) are opaque to this tree (vendor actions). `ingest.yml`, `weekly-maintenance.yml` read less deeply than nightly/on-pr-review. | **Pass 1 deepening** + **Pass 4 deepening** — trace the fallback-PR and restore/persist step logic line-by-line; confirm OIDC scope downstream use is genuinely external. | **MEDIUM** |
| **G-5 · Templates not yet read in depth** | Pass 2 read L3/L4/L6/PRD; **L2-baseline, L2-tldr, L3-tldr, track-summary, concept-narrative, six-pager, user-stories, acceptance-plan, `review-spec.md` (119 LOC), `instance-docs/`** were not read in full. Possible undiscovered value objects (e.g. track-summary's L4-consumption field set). | **Pass 2 deepening** (value objects) + **Pass 5 deepening** (convention conformance across the 6 `.yml` + remaining corpus/pm templates). | **MEDIUM** |
| **G-6 · Maintenance / "Corpus Health" bounded context under-modeled** | `consistency-validator` + `dashboard-builder` + `maintenance.lobster` touch drift-detection and single-source-of-truth validation — a candidate small bounded context Pass 2 named but did not deeply model. The 3 "mechanical sweep" agent bodies were not read in full. | **Pass 2 deepening** (bounded context) + **Pass 5 deepening** (confirm CV-014/015 body convention holds for these 3 agents). | **MEDIUM** |
| **G-7 · `editorial-sweeper`/`consistency-validator`/`dashboard-builder` bodies read at frontmatter level only** | Section-presence scanned, not read in full (Pass 5 gap #5). Their precision/recall division-of-labor and exact responsibilities are inferred. | **Pass 5 deepening** (+ feeds Pass 3 if any testable contract surfaces). | **LOW-MEDIUM** |

### 4b. Entity detail needing function-level depth (→ Pass 2 deepening)

1. **`STATE` aggregate** — confirm the live field schema from `factory-artifacts` (G-3). The single highest-value Pass-2 deepening read.
2. **`TrackSummary`** — the "L4-consumption surface" field set is named but not enumerated; read `templates/corpus/track-summary.md` and `L3-findings-tldr.md`.
3. **`VectorCoverageTable`** — confirm the exact roll-up fields (Evidence basis / Structural note) and the L4 market-picture + L6 market×vector matrix shapes against the unread tldr/track-summary templates.
4. **`PMDocLadder` sub-entities** — `ConceptNarrative`, `SixPager`, `AcceptancePlan` were not read in full (only PRD + user-stories field sets are pinned); confirm no additional value objects.
5. **`Market` phase-transition triggers** — the operations that graduate observe-and-report → judgment → productization are inferred from init-market "prove one track first"; pin the transition contract (also a Pass-3 BC candidate).
6. **"Corpus Health" bounded context** — model the drift-item / single-source-of-truth entities the maintenance workflow operates on (G-6).

### 4c. Subsystem-level BCs needing function-level depth (→ Pass 3 deepening)

1. **The entire agent/orchestration layer (BC-064…076)** — convert subsystem-level MEDIUM/LOW prose contracts into function-level contracts per agent body (G-1). Highest priority.
2. **Convergence-loop math** — no test exercises novelty = new/(new+dup) < 0.15 × 3-clean-passes, nor the cap-at-6 behavior. Propose the capped-exit simulation test (asserts PR-title flag).
3. **Hook over-permissiveness (BC-014, AP-2)** — the `[a-z0-9_-]+\.md` matcher and whole-content (frontmatter-inclusive) citation scan are untested false-allow paths; specify the negative bats cases.
4. **Fail-closed dependency paths (BC-HOOK-A, BC-063)** — `jq`-missing / `yq`-missing exits are asserted from `command -v` guards only; no test stubs a missing dependency.
5. **`lobster-parse steps` subcommand + `factory-config editorial`/`path` subcommands** — logic-only, untested (`name\ttype\tref` output, JSON dump, resolution print).
6. **Criteria-map gate idiom (pm-doc-chain `dev-readiness-check`)** — the `MVF_SCOPE: clear` … readiness-flag gate is orchestrator-interpreted with no parser or test coverage; only the boolean `pass_when` path is test-reachable.
7. **Chain-ordering / first-deny-wins** (BC-HOOK-B) — asserted from `hooks.json` order, not an integration test running all 4 hooks against one payload.
8. **Budget-threshold enforcement** — confirm (with Pass 4) whether *any* enforcer exists; if not, BC-029-style "no contract" is the finding.

### 4d. Consolidated deepening backlog (merged "remaining gaps" from Passes 0–5, prioritized, labeled by owning pass)

> Convergence order per protocol: **Passes 2 & 3 first** (highest value), then 0/1/4/5. Items below are de-duplicated across the six passes' gap lists. **Count: 24 items** — Pass 0: 2 · Pass 1: 4 · Pass 2: 6 · Pass 3: 7 · Pass 4: 3 · Pass 5: 2.

**→ Pass 2 (Domain) deepening — 6 items** *(run first)*
- P2-1 *(HIGH)* STATE.md live field schema from `factory-artifacts` (G-3 / Pass-2 gap #3).
- P2-2 *(MED)* TrackSummary + VectorCoverageTable roll-up field sets from unread tldr/track-summary templates (Pass-2 gap #2/#5).
- P2-3 *(MED)* Remaining PM-ladder sub-entities (concept/six-pager/acceptance) — confirm no new value objects (Pass-2 gap #5).
- P2-4 *(MED)* Market phase-transition triggers (Pass-2 gap #6).
- P2-5 *(MED)* "Corpus Health" bounded context (consistency/dashboard/maintenance) (Pass-2 gap #7 / G-6).
- P2-6 *(LOW)* Remaining `templates/corpus/*` + `templates/pm/*` full read for any missed value object (Pass-2 gap #5 / G-5).

**→ Pass 3 (Contracts) deepening — 7 items** *(run first)*
- P3-1 *(HIGH)* Function-level contracts for the agent/orchestration layer; identify the single highest-value missing test (capped-exit simulation) (G-1 / Pass-3 gap #1).
- P3-2 *(MED)* Negative bats cases for the over-permissive `.md`/frontmatter citation matchers (AP-2 / Pass-3 gap #2).
- P3-3 *(MED)* `jq`/`yq`-missing fail-closed test (Pass-3 gap #3).
- P3-4 *(LOW)* `lobster-parse steps` contract + test (Pass-3 gap #4).
- P3-5 *(LOW)* `factory-config editorial`/`path` subcommand contracts (Pass-3 gap #5).
- P3-6 *(MED)* Criteria-map gate idiom contract (pm-doc-chain) (Pass-3 gap #6 / AP-3).
- P3-7 *(MED)* Composite first-deny-wins hook-chain integration contract (Pass-3 gap #8).

**→ Pass 0 (Inventory) deepening — 2 items**
- P0-1 *(LOW)* Re-verify the carried-forward 3,631 LOC / 64-file totals; fix the Pass-3 ledger MEDIUM-count typo (R-2) and the Pass-0 "4 step types" undercount (R-5) in the record.
- P0-2 *(LOW)* Read the 4 still-unread Action templates / 4 unread corpus-pm templates / `rules/research-protocol.md` end-to-end for inventory completeness (Pass-0 gap, Pass-1 gap #8).

**→ Pass 1 (Architecture) deepening — 4 items**
- P1-1 *(HIGH)* Re-grade the §5 budget-governance row from "working concern" to ASPIRATIONAL/unenforced (R-6 / G-2).
- P1-2 *(MED)* Trace the GitHub-Action fallback-PR + restore/persist runtime logic line-by-line (G-4).
- P1-3 *(MED)* Document the `parallel`/`sub-workflow` defined-but-unused step types (would the orchestrator fan out / recurse?) (R-5).
- P1-4 *(LOW)* Confirm OIDC token-exchange is genuinely external to the tree (Pass-4 gap #7, arch-owned).

**→ Pass 4 (NFR) deepening — 3 items**
- P4-1 *(HIGH)* Resolve the budget-enforcer question definitively: human-discipline vs deferred vs missing (G-2 / Pass-4 gap #1).
- P4-2 *(MED)* Note the absence of tests for `timeout 5` hook bound, convergence math, and the capped-exit PR-title path (Pass-4 gap #2/#3).
- P4-3 *(MED)* Recommend a template-lint for the per-template log-leak / retention / `$VAR`-override postures (NFR-007/008/010/022, Pass-4 gap #4/#5).

**→ Pass 5 (Conventions) deepening — 2 items**
- P5-1 *(MED)* Confirm naming/frontmatter/tag conventions across the 6 `.yml` Action templates + remaining corpus/pm templates; byte-level hook-skeleton conformance of the other 3 hooks (Pass-5 gap #1/#5/#6).
- P5-2 *(LOW)* Quantify commit-convention drift over full history; confirm `color` field is cosmetic (no tooling reads it) (Pass-5 gap #3/#4 / AP-4).

---

## 5. Recommendations for spec crystallization (downstream skills)

1. **Treat the deterministic surface and the reasoned surface as two different spec tiers.** The hooks + validators + config (HIGH, 31 test-backed BCs / 11 MECHANICAL NFRs) crystallize directly into hard requirements. The agent/orchestration layer (MEDIUM/LOW) crystallizes into *behavioral intents enforced structurally* — spec them as invariants with their structural backstop named (tool-grant absence, `context.exclude`, DAG-terminal, CI family split), not as testable assertions.
2. **Flag budget governance as the one declared-but-unbuilt feature.** Any PRD that consumes this analysis must decide whether to *build* the enforcer (G-2). It is the only place where config promises a behavior the engine does not deliver.
3. **The P10 invariant is the load-bearing architectural spec.** "A market = config + seed, never code" is verified (all 26 keys map to behavior); make it the top-line constraint any change is tested against — additive `*_extra`/`*_default` keys, never new engine branches.
4. **Preserve the honesty contracts explicitly** (capped-exit never fakes PASS; sole-committer refuses on REVISE; anchor-not-strip). They are LOW-confidence (prose-only) yet constitutionally central — they need *named* spec status precisely because no checker protects them.

---

## State Checkpoint

```yaml
pass: 6
status: complete
phase: A-broad-sweep-COMPLETE
passes_synthesized: [0,1,2,3,4,5]
source_rechecks_this_pass: [agent_count=11, workflow_count=7, bats_tests=35, budget_enforcer=none-found]
inconsistencies_found: 9
inconsistencies_unresolved: 0
inconsistencies_with_deepening_action: 2   # R-2 ledger typo, R-6 budget re-grade
gap_subsystems: 7        # G-1..G-7
deepening_backlog_items: 24
deepening_backlog_by_pass: {pass0: 2, pass1: 4, pass2: 6, pass3: 7, pass4: 3, pass5: 2}
highest_priority_deepening: [P3-1 agent-layer-contracts, P2-1 STATE-schema, G-2/P4-1 budget-enforcer]
timestamp: 2026-06-01T00:00:00Z
next_phase: B-convergence-deepening
next_passes: [2, 3]   # run first per convergence order
```

## Resume checkpoint

**Phase A (broad sweep, Passes 0–6) is COMPLETE.** All six pass files are on disk; all cross-pass inconsistencies reconcile against source (0 unresolved). The consolidated deepening backlog has **24 items** (Pass 0: 2 · Pass 1: 4 · Pass 2: 6 · Pass 3: 7 · Pass 4: 3 · Pass 5: 2).

**Phase B (convergence deepening) begins next, starting with Passes 2 and 3** (highest value, per the convergence order). The three highest-priority targets across the whole backlog are: **P3-1** (function-level contracts for the untested agent/orchestration layer — the single biggest blind spot), **P2-1** (STATE.md live field schema from the `factory-artifacts` branch), and **G-2/P4-1** (resolve the budget-governance enforcer question — the one declared-but-unbuilt behavior). Each Phase-B round must end with a Delta Summary + binary Novelty Assessment (SUBSTANTIVE/NITPICK) per the convergence protocol.
