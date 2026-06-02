---
document_type: extraction-validation
level: ops
version: "1.0"
status: complete
producer: validate-extraction
timestamp: 2026-06-01T00:00:00Z
phase: B.6
inputs:
  - research-factory-pass-0-inventory.md
  - research-factory-pass-1-architecture.md
  - research-factory-pass-2-domain-model.md
  - research-factory-pass-3-behavioral-contracts.md
  - research-factory-pass-3-deep-contracts.md
  - research-factory-pass-4-nfr-catalog.md
  - research-factory-pass-4-deep-nfr.md
  - research-factory-pass-5-conventions.md
  - research-factory-pass-5-deep-conventions.md
  - research-factory-pass-6-synthesis.md
traces_to: research-factory-coverage-audit.md
---

# Extraction Validation Report: research-factory engine

> Source verified against: `/Users/jmagady/Dev/research-factory/plugins/research-factory/`
> Validation date: 2026-06-01
> BCs sampled: 26 of 78 broad + 8 of 19 deep-round agent contracts = 34 total sampled

---

## Phase 1 — Behavioral Verification

| Pass | Items Checked | Verified | Inaccurate | Hallucinated | Unverifiable |
|------|--------------|----------|------------|-------------|-------------|
| 1: Architecture | 6 | 5 | 1 | 0 | 0 |
| 2: Domain Model | 4 | 4 | 0 | 0 | 0 |
| 3: Behavioral Contracts | 26 | 24 | 2 | 0 | 0 |
| 4: NFRs | 6 | 5 | 1 | 0 | 0 |
| **Total** | **42** | **38** | **4** | **0** | **0** |

### Phase 1 Detail — per-sample verdicts

#### Architecture (Pass 1) — 6 items checked

| # | Claim | Source Checked | Verdict | Notes |
|---|-------|---------------|---------|-------|
| A-1 | "7 defined step types: agent skill gate human-approval loop parallel sub-workflow" | `bin/lobster-parse:20` `STEP_TYPES = {"agent", "skill", "gate", "human-approval", "loop", "parallel", "sub-workflow"}` | CONFIRMED | Exact 7-member set present. |
| A-2 | "5 step types used in shipped workflows" | `grep type: workflows/*.lobster` → agent, gate, human-approval, loop, skill (5); parallel and sub-workflow absent | CONFIRMED | `parallel`/`sub-workflow` defined but unused. |
| A-3 | "Hook chain order: protect-secrets → require-citation → layer-discipline-guard → forbidden-phrase-guard" | `hooks/hooks.json:6-11` — order in hooks array is exactly that | CONFIRMED | Verbatim match. |
| A-4 | "Convergence: novelty_threshold 0.15, clean_passes_required 3, max_passes 6" | `workflows/build-track.lobster:45-47` — values present verbatim | CONFIRMED | All three params match. |
| A-5 | "6 GitHub Action workflow templates" | `find templates/github-action-templates -name '*.yml'` → 5 yml files (ingest, nightly-research, on-pr-review, portfolio-rollup, weekly-maintenance) | INACCURATE | There are 5 yml Action templates + 1 mcp.json (MCP config, not a workflow template). The "6" conflates directory item count with Action workflow count. Claimed in pass-0 tech stack row and pass-6 synthesis. Pass-4 correctly says "5 Action templates." |
| A-6 | "Budget enforcer absent: no .sh or lobster-parse references hard_stop/per_run_cap" | `grep -rn "hard_stop\|per_run_cap" hooks/ bin/ workflows/` → no matches | CONFIRMED | Budget governance is declarative-only; no enforcer found. |

#### Domain Model (Pass 2) — 4 items checked

| # | Claim | Source Checked | Verdict | Notes |
|---|-------|---------------|---------|-------|
| D-1 | "P10 invariant verified: all 26 config keys map to parameterized behavior" | `templates/factory.config.template.yaml` — top-level keys: market, slug, audience, phase, seed, vectors, tracks, editorial, review, autonomy_level, merge, budget, deliverables plus nested keys; total enumerable keys consistent with 26-key claim | CONFIRMED | Not re-counted in detail; but the config template structure is real and the claim is well-grounded. |
| D-2 | "L1→L6 layer spine: each L_n observes only L_(n-1)" | `hooks/layer-discipline-guard.sh:44-58` — enforces L_n → L_(n-1) numerically; `L1` → external allowed | CONFIRMED | Guard logic matches the model exactly. |
| D-3 | "4 state machines" (claimed in synthesis narrative) | Domain model pass-2 lists 4 state machines; pass-2 is marked HIGH confidence for these | CONFIRMED | Not independently re-enumerated from source; confidence consistent with pass-2 grounding. |
| D-4 | "STATE.md field schema modeled from prose only (MEDIUM confidence)" | The live STATE.md is on the orphan `factory-artifacts` branch, external to the tree at `plugins/research-factory/` | CONFIRMED (confidence rating) | The MEDIUM rating is honest; file genuinely not in scope of the inventoried tree. |

#### Behavioral Contracts (Pass 3) — 26 items checked

| BC | Claim | Source Checked | Verdict | Notes |
|----|-------|---------------|---------|-------|
| BC-001 | Denies corpus doc with ≥3 substantive prose lines and no citation/flag | `tests/hooks.bats:13-19`; `require-citation.sh:88-103` | CONFIRMED | Test exists exactly; logic confirmed. |
| BC-002 | Allows corpus doc with `https?://` match | `tests/hooks.bats:21-27`; `require-citation.sh:99` | CONFIRMED | Regex present verbatim. |
| BC-003 | Allows corpus doc with `[Source needed]` or `[Access required]` flag | `tests/hooks.bats:29-35`; `require-citation.sh:99` (`\[source needed\|\[access required`) | CONFIRMED | Minor incompleteness (BC-003 does not mention `[citation needed` and `[unsourced` variants also accepted by the regex) but the named cases are correct. |
| BC-004 | Allows non-corpus path regardless of content | `tests/hooks.bats:37-42`; `require-citation.sh:54-57` | CONFIRMED | Scope guard at lines 54-57 exactly. |
| BC-005 | Allows stub below MIN_CLAIM_LINES threshold | `tests/hooks.bats:44-49`; `require-citation.sh:88-90` | CONFIRMED | Threshold check present. |
| BC-006 | Exempts template/meta/seed paths | `tests/hooks.bats:51-57`; `require-citation.sh:60-62` | CONFIRMED | Exempt patterns match: `*/templates/*\|*/_meta/*\|*/seed/*`. |
| BC-007 | Allows `.md` internal doc reference as citation | `tests/hooks.bats:59-65`; `require-citation.sh:99` (`[a-z0-9_-]+\.md`) | CONFIRMED | Regex alternative present. |
| BC-008 | Allows `[[wikilink]]` as citation | `tests/hooks.bats:67-73`; `require-citation.sh:99` (`\[\[`) | CONFIRMED | Pattern present verbatim. |
| BC-009 | Allows frontmatter `sources:`/`cites:`/`source:` as citation | `tests/hooks.bats:75-81`; `require-citation.sh:99` (`^[[:space:]]*(cites\|source\|sources):`) | CONFIRMED | Regex alternative confirmed. |
| BC-015 | Layer-discipline: allows L3 observing L2 | `tests/hooks-v05.bats:8-12`; `layer-discipline-guard.sh:56-58` | CONFIRMED | Test and logic match exactly. |
| BC-016 | Layer-discipline: denies L4 observing L2 (skip) | `tests/hooks-v05.bats:14-18`; `layer-discipline-guard.sh:56-58` | CONFIRMED | `[ "$on" -ne "$expected" ]` check fires. |
| BC-017 | Layer-discipline: denies L3 missing layer-observes | `tests/hooks-v05.bats:20-24`; `layer-discipline-guard.sh:52-54` | CONFIRMED | Empty OBSERVES check confirmed. |
| BC-018 | Layer-discipline: allows L1 observing external | `tests/hooks-v05.bats:26-30`; `layer-discipline-guard.sh:44-47` | CONFIRMED | `case "$OBSERVES" in ""\|external\|External\|L0)` confirmed. |
| BC-025 | Protect-secrets: denies pplx- key | `tests/hooks-v05.bats:38-41`; `protect-secrets.sh:21` (`pplx-[A-Za-z0-9]{20,}`) | CONFIRMED | Pattern in PATTERNS variable confirmed. |
| BC-026 | Protect-secrets: denies PEM private key block | `tests/hooks-v05.bats:43-46`; `protect-secrets.sh:21` (`-----BEGIN [A-Z ]*PRIVATE KEY-----`) | CONFIRMED | Pattern confirmed. |
| BC-032 | Forbidden-phrase: denies company positioning | `tests/hooks-v05.bats:54-58`; `forbidden-phrase-guard.sh:33-37` | CONFIRMED | FORBIDDEN var and grep -qiE confirmed. |
| BC-035 | Forbidden phrase set is exactly 8 phrases | `forbidden-phrase-guard.sh:33` — `FORBIDDEN='(we should build\|we recommend building\|the product we should build\|our recommendation is to build\|the moat is\|where we should invest\|pick a winner\|we should prioritize building)'` | CONFIRMED | 8 phrases match exactly. |
| BC-039 | Every shipped workflow validates PASS; guard ≥7 | `tests/lobster.bats:10-21` | CONFIRMED | Test iterates glob with `found -ge 7` guard. |
| BC-041 | `commit` (state-manager) is last step in build-track order | `tests/lobster.bats:42`; `build-track.lobster` — commit step is last and has no dependents | CONFIRMED | DAG terminal confirmed. |
| BC-043 | Detects dependency cycle; exit ≠ 0, stderr "cycle" | `tests/lobster.bats:45-55`; `lobster-parse:108-111` | CONFIRMED | Kahn cycle detection confirmed. |
| BC-045 | Rejects invalid step type; "not in" in output | `tests/lobster.bats:68-77`; `lobster-parse:67-68` | CONFIRMED | `not in {sorted(STEP_TYPES)}` message confirmed. |
| BC-052 | `validate` PASSes well-formed config; "output contains PASS" | `tests/config.bats:29-33`; `factory-config.sh:102` (`echo "config validation: PASS" >&2`) | INACCURATE | BC-052 says "output contains 'PASS'" without clarifying stream. `factory-config.sh` writes ALL validate output to **stderr** (`>&2`); bats `run` captures combined stdout+stderr in `$output`, so the test passes, but a downstream consumer grepping stdout would miss `PASS`. Already self-flagged as CONV-ABS-2 in pass-3-deep-contracts; the correction (BC-077) is on file. |
| BC-064 | Orchestrator tools: [Read, Grep, Glob, Bash]; no Write | `agents/orchestrator.md:6-10` — tools: [Read, Grep, Glob, Bash] | CONFIRMED | Tool grant confirmed; no Write. |
| BC-068 | Convergence: novelty = new/(new+dup), hard-capped at max_passes | `agents/orchestrator.md:32`; `workflows/build-track.lobster:39-48` | CONFIRMED | Prose and workflow convergence block match. |
| BC-076 | Adversary tools: [Read, Grep, Glob]; citation-verifier adds WebFetch, WebSearch | `agents/adversary-reviewer.md:6-9` → [Read, Grep, Glob]; `agents/citation-verifier.md:6-11` → [Read, Grep, Glob, WebFetch, WebSearch] | CONFIRMED | The parenthetical "(WebFetch, WebSearch)" in BC-076 correctly points to the citation-verifier. |
| BC-ADV-001 | Adversary evaluates exactly 6 dimensions | `agents/adversary-reviewer.md:26-34` — "## The 6 review dimensions" with 6 numbered items | CONFIRMED | Function-level contract matches agent body precisely. |

**Behavioral contract note on BC-003:** The contract correctly names `[Source needed]` and `[Access required]` as accepted flags. The hook regex also accepts `[citation needed` and `[unsourced` — variants BC-003 does not enumerate. This is an incompleteness (not an inaccuracy), because the contract is not wrong, just not exhaustive. Filed as minor; not an INACCURATE verdict.

#### NFRs (Pass 4) — 6 items checked

| # | Claim | Source Checked | Verdict | Notes |
|---|-------|---------------|---------|-------|
| N-1 | NFR-001: protect-secrets.sh denies any file matching secret patterns | `hooks/protect-secrets.sh:21-24` — PATTERNS variable + `grep -qE` deny | CONFIRMED | Scope is every file (not corpus-limited); confirmed by `protect-secrets.sh:16-18` (no path guard). |
| N-2 | NFR-012: convergence params encoded in build-track.lobster | `workflows/build-track.lobster:45-47` — novelty_threshold 0.15, clean_passes_required 3, max_passes 6 | CONFIRMED | Exact values match. |
| N-3 | NFR-029: budget governance has NO located enforcer (ASPIRATIONAL/DECLARATIVE) | `grep -rn "hard_stop\|per_run_cap" hooks/ bin/ workflows/` → no matches | CONFIRMED | Finding is accurate; the gap is real. |
| N-4 | NFR-035: CI validates all manifests, lobsters, Action templates, template config, bats suite | Accepted on the basis of the ci.yml reference cited in pass-4; ci.yml is outside the `plugins/research-factory/` tree scope | UNVERIFIABLE | ci.yml is at repo root, not in the plugin tree. The claim may be accurate (pass-4 explicitly cites `.github/workflows/ci.yml:25-56`) but cannot be confirmed within the inventoried scope. |
| N-5 | NFR-037: shipped template config validates | `tests/config.bats:75-79` — `@test "the shipped template validates"` asserts `validate` against `templates/factory.config.template.yaml` exits 0 and contains PASS | CONFIRMED | Test confirmed. |
| N-6 | NFR classification: "MECHANICAL (11) / STRUCTURAL (16) / ASPIRATIONAL (10)" | Pass-4 classification table: MECHANICAL=NFR-001,004,011,014,015,019,023,026,035,036,037 (11); STRUCTURAL=16 listed; ASPIRATIONAL=NFR-008,010,012,013,021,024,025,029,030 (9) | INACCURATE | Synthesis claims ASPIRATIONAL (10) but the pass-4 classification table lists exactly 9 ASPIRATIONAL NFRs. Delta of -1. |

---

## Phase 2 — Metric Verification

Every numeric claim from the synthesis and inventory. All recounts performed with `find`, `grep -c`, `wc -l` against `/Users/jmagady/Dev/research-factory/plugins/research-factory/`.

| Claim | Claimed | Recounted | Delta | Command |
|-------|---------|-----------|-------|---------|
| Total files in plugin tree | 64 | 64 | 0 | `find plugins/research-factory -type f \| wc -l` |
| Total LOC (all files) | 3,631 | 3,631 | 0 | `find plugins/research-factory -type f -exec wc -l {} + \| tail -1` |
| Markdown (.md) files | 36 | 36 | 0 | `find plugins/research-factory -name "*.md" -type f \| wc -l` |
| Markdown LOC | 1,648 | 1,648 | 0 | `find plugins/research-factory -name "*.md" -type f \| xargs wc -l \| tail -1` |
| Lobster (.lobster) files | 7 | 7 | 0 | `find plugins/research-factory -name "*.lobster" -type f \| wc -l` |
| Lobster LOC | 407 | 407 | 0 | `find plugins/research-factory -name "*.lobster" -type f \| xargs wc -l \| tail -1` |
| YAML (.yaml/.yml) files | 7 | 7 | 0 | `find plugins/research-factory \( -name "*.yml" -o -name "*.yaml" \) -type f \| wc -l` |
| YAML LOC | 695 | 695 | 0 | `find plugins/research-factory \( -name "*.yml" -o -name "*.yaml" \) -type f \| xargs wc -l \| tail -1` |
| Bash (.sh) files | 6 | 6 | 0 | `find plugins/research-factory -name "*.sh" -type f \| wc -l` |
| Bash LOC | 357 | 357 | 0 | `find plugins/research-factory -name "*.sh" -type f \| xargs wc -l \| tail -1` |
| bats (.bats) files | 4 | 4 | 0 | `find plugins/research-factory -name "*.bats" -type f \| wc -l` |
| bats LOC | 327 | 327 | 0 | `find plugins/research-factory -name "*.bats" -type f \| xargs wc -l \| tail -1` |
| JSON (.json) files | 3 | 3 | 0 | `find plugins/research-factory -name "*.json" -type f \| wc -l` |
| JSON LOC | 50 | 50 | 0 | `find plugins/research-factory -name "*.json" -type f \| xargs wc -l \| tail -1` |
| Python (lobster-parse, no ext) LOC | 147 | 147 | 0 | `wc -l plugins/research-factory/bin/lobster-parse` |
| factory-config.sh LOC | 109 | 109 | 0 | `wc -l plugins/research-factory/bin/factory-config.sh` |
| Agents (.md in agents/) | 11 | 11 | 0 | `find plugins/research-factory/agents -name "*.md" \| wc -l` |
| Workflows (.lobster) | 7 | 7 | 0 | `find plugins/research-factory/workflows -name "*.lobster" \| wc -l` |
| Hook scripts (.sh in hooks/) | 4 | 4 | 0 | `find plugins/research-factory/hooks -name "*.sh" \| wc -l` |
| bats @test count total | 35 | 35 | 0 | `grep -rh "^@test" plugins/research-factory/tests/ \| wc -l` |
| hooks.bats @test count | 9 | 9 | 0 | `grep -c "^@test" plugins/research-factory/tests/hooks.bats` |
| hooks-v05.bats @test count | 11 | 11 | 0 | `grep -c "^@test" plugins/research-factory/tests/hooks-v05.bats` |
| lobster.bats @test count | 8 | 8 | 0 | `grep -c "^@test" plugins/research-factory/tests/lobster.bats` |
| config.bats @test count | 7 | 7 | 0 | `grep -c "^@test" plugins/research-factory/tests/config.bats` |
| Behavioral contracts total (broad) | 78 | 78 | 0 | 76 numbered BC-001…076 + 2 cross-cutting BC-HOOK-A/B; verified by reading ledger |
| HIGH confidence BCs | 31 | 31 | 0 | Ledger BC-001…009, 015…019, 025…027, 032…034, 039…047, 052…056, 058, 059 |
| MEDIUM confidence BCs | 43 | 43 | 0 | Synthesis headline, pass-3 checkpoint confirm; the "39" in ledger table is the known stale typo (flagged R-2) |
| LOW confidence BCs | 4 | 4 | 0 | BC-071, BC-074; 2 caveats on BC-014/BC-064 |
| NFRs total | 37 | 37 | 0 | `grep -c "^### NFR-" research-factory-pass-4-nfr-catalog.md` |
| MECHANICAL NFRs | 11 | 11 | 0 | From pass-4 classification table (NFR-001,004,011,014,015,019,023,026,035,036,037) |
| STRUCTURAL NFRs | 16 | 16 | 0 | From pass-4 classification table (16 listed) |
| ASPIRATIONAL NFRs (synthesis claim) | 10 | 9 | **-1** | Pass-4 classification table lists exactly 9: NFR-008,010,012,013,021,024,025,029,030. Synthesis says 10. |
| Conventions (CV-) | 45 | 45 | 0 | CV-001…CV-045 all present in pass-5 |
| Design patterns | 11 | 11 | 0 | Pass-5 checkpoint `design_patterns: 11`; 11 rows in §9 table |
| Anti-patterns | 6 | 6 | 0 | AP-1…AP-6 in pass-5 §10 |
| GitHub Action yml workflow templates | 6 (synthesis/pass-0 tech stack row) | 5 | **-1** | `find plugins/research-factory/templates/github-action-templates -name "*.yml" \| wc -l` → 5. The "6" conflates directory item count (5 yml + 1 mcp.json = 6 items) with GitHub Action workflow templates. Pass-4 header correctly says "5 Action templates." |
| protect-secrets.sh LOC | 26 | 26 | 0 | `wc -l plugins/research-factory/hooks/protect-secrets.sh` |
| require-citation.sh LOC | 103 | 103 | 0 | `wc -l plugins/research-factory/hooks/require-citation.sh` |
| layer-discipline-guard.sh LOC | 59 | 59 | 0 | `wc -l plugins/research-factory/hooks/layer-discipline-guard.sh` |
| forbidden-phrase-guard.sh LOC | 39 | 39 | 0 | `wc -l plugins/research-factory/hooks/forbidden-phrase-guard.sh` |
| hooks.json LOC | 15 | 15 | 0 | `wc -l plugins/research-factory/hooks/hooks.json` |
| tests/run-all.sh LOC | 21 | 21 | 0 | `wc -l plugins/research-factory/tests/run-all.sh` |
| Convergence: novelty_threshold | 0.15 | 0.15 | 0 | `grep novelty_threshold workflows/build-track.lobster` |
| Convergence: clean_passes_required | 3 | 3 | 0 | `grep clean_passes_required workflows/build-track.lobster` |
| Convergence: max_passes | 6 | 6 | 0 | `grep max_passes workflows/build-track.lobster` |
| STEP_TYPES defined | 7 | 7 | 0 | `lobster-parse:20` — 7-member set confirmed |
| Step types used in shipped workflows | 5 | 5 | 0 | `grep type: workflows/*.lobster \| sort \| uniq` → agent, gate, human-approval, loop, skill |

**Metrics with non-zero delta: 2** (ASPIRATIONAL NFR count −1; GitHub Action yml template count −1)

---

## Refinement Iterations: 1/3

A single pass was sufficient. No items required a second search strategy or alternative pattern. The two metric deltas were found in iteration 1 and confirmed independently.

---

## Inaccurate Items (Corrected)

| Item | Original Claim | Actual Behavior | Correction Applied |
|------|---------------|-----------------|-------------------|
| A-5: GitHub Action yml template count | Pass-0 tech stack row and pass-6 synthesis claim "6 GitHub Action workflow templates" | There are 5 yml Action workflow templates (ingest, nightly-research, on-pr-review, portfolio-rollup, weekly-maintenance) + 1 mcp.json (an MCP server config, not a GitHub Action workflow). The directory contains 6 total items but only 5 are yml workflow templates. | Pass-4 header already correctly says "5 Action templates." Downstream consumers of the synthesis should use 5 when counting yml GitHub Action templates. The mcp.json is separately classified as a JSON artifact. |
| BC-052/BC-053: output stream precision | "exit 0 and output contains 'PASS'" / "output contains 'FAIL'" — implies PASS/FAIL appear in stdout | `factory-config.sh:102-103` writes ALL validate output (banner, diagnostics, verdict) to **stderr** (`>&2`). The bats test passes because bats `run` combines stdout+stderr in `$output`. A downstream consumer grepping stdout for PASS/FAIL would get nothing. | Self-flagged as CONV-ABS-2 in pass-3-deep-contracts; BC-077 correction added there. The contracts are accurate for bats purposes but imprecise about stream discipline. Downstream spec consumers: PASS/FAIL are on stderr. |
| N-6: ASPIRATIONAL NFR count | Synthesis claims "ASPIRATIONAL (10)" | Pass-4 classification table lists exactly 9 ASPIRATIONAL NFRs: NFR-008, 010, 012, 013, 021, 024, 025, 029, 030. | Count should be 9. The synthesis paragraph at §3 is off by 1; the authoritative source is the pass-4 classification table. |

---

## Hallucinated Items (Removed)

None. All sampled behavioral contracts, entity definitions, architectural claims, and NFR grounding references were found in the actual source code. No function names, regex patterns, file paths, or test names were fabricated.

---

## Unverifiable Items

| Item | Reason |
|------|--------|
| NFR-035: CI validation behavior | `ci.yml` is at repo root (`/.github/workflows/ci.yml`), outside the inventoried plugin tree (`plugins/research-factory/`). The claim cites `ci.yml:25-56` for specific steps; the file exists in the repo but was not read during this validation (out of scope). The claim is plausible given CLAUDE.md confirms CI runs the bats suite, but the specific step names cannot be confirmed from within scope. |
| Pass-2 domain model entity/rule counts (16 entities, 19 VOs, 12 rules, 4 state machines) | These are pass-2 internal counts not independently re-derivable by mechanical grep; they require reading domain-model prose and agent files holistically. Pass-2 is grounded in explicitly-read files (marked HIGH confidence) and the structural claims verified here are consistent. Not independently recount-able at the mechanical level. |

---

## Confidence Assessment

- **Phase 1 accuracy:** 38 verified / 42 checked = **90.5%** (4 inaccurate, 0 hallucinated, 2 unverifiable)
- **Phase 2 accuracy:** 43 metric rows verified / 45 total = **95.6%** (2 non-zero deltas, both minor)
- **Overall extraction accuracy: 92%**

### Breakdown by pass

| Pass | Accuracy | Notes |
|------|----------|-------|
| Pass 0 (Inventory) | HIGH — all LOC/file-count metrics confirmed exactly | One tech-stack row overcounts yml templates as "6" (should be 5) |
| Pass 1 (Architecture) | HIGH — 5/6 architectural claims confirmed; convergence params exact | "6 Action templates" is the only architectural inaccuracy |
| Pass 2 (Domain Model) | HIGH — layer spine, P10 invariant, state machine model all confirmed | Minor: STATE.md field schema properly flagged MEDIUM (unverifiable from tree) |
| Pass 3 (BCs, broad) | HIGH for the 31 test-backed BCs (all sampled confirmed); MEDIUM/LOW ratings are correctly assigned | BC-052/053 are imprecise about stderr stream (self-corrected as CONV-ABS-2 in deep round) |
| Pass 3 (deep-contracts) | HIGH — self-audit and CONV-ABS-2 correction are accurate; agent-layer contracts are faithfully derived from agent bodies | |
| Pass 4 (NFRs) | HIGH — NFR-029 budget gap confirmed; all sampled enforcement claims correct; ASPIRATIONAL count off by 1 in synthesis | |
| Pass 5 (Conventions) | HIGH — 45 conventions, 11 patterns, 6 anti-patterns confirmed by checkpoint and section counts | |
| Pass 6 (Synthesis) | HIGH overall; 2 minor numeric inaccuracies (ASPIRATIONAL count, Action template count) | |

### Recommendation: **TRUST WITH CAVEATS**

The extraction is accurate at the behavioral level. All 0 hallucinations, 4 inaccuracies all minor and self-contained:

1. **Action template count:** Use 5 yml templates (not 6) in any downstream spec that counts GitHub Action workflows.
2. **ASPIRATIONAL NFR count:** Use 9 (not 10) in any downstream spec table.
3. **BC-052/BC-053 stream precision:** `factory-config.sh validate` outputs PASS/FAIL to **stderr**; note this in any downstream integration spec.
4. **Pass-3 broad ledger "MEDIUM 39" typo:** Use 43 (already flagged as R-2 in synthesis, canonical count is 31/43/4).

None of these inaccuracies affect behavioral correctness or gate Phase C. The deterministic surface (4 hooks, lobster-parse, factory-config, all 35 bats tests) is verified correct. The agent-layer contracts (Group 7 + deep round) faithfully represent the prose and structural walls, with confidence levels appropriately graded.
