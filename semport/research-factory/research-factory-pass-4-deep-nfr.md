# Pass 4 (NFR) — Deepening Round 1 — research-factory engine

> Inputs read: `research-factory-pass-4-nfr-catalog.md` (broad), `research-factory-pass-6-synthesis.md` (backlog P4-1/2/3, G-2, R-6).
> Source re-read this round: `templates/factory.config.template.yaml` (budget+convergence+merge block), `bin/factory-config.sh` (validator body :70-110), `bin/lobster-parse`, all 4 hooks, all 5 Action templates, `tests/*.bats` (35 @tests), `.github/workflows/ci.yml:44-56`, `docs/AUTONOMY.md` (full).
> **Mandate: audit broad doc vs the 5 Known Hallucination Classes; re-derive every numeric; retract failures as CONV-ABS-N.**

---

## 0. Hallucination audit of the Pass-4 broad doc (5 classes)

Every numeric / structural claim in the broad doc was re-checked against source this round. Result: **no retractions (CONV-ABS-N: none).** The broad doc holds up. Detail:

| Class | Claim audited | Source re-check | Verdict |
|---|---|---|---|
| **C1 fabricated entity/file** | "5 Action templates" (NFR-002/022/027) | `find templates/github-action-templates -name '*.yml' \| wc -l` → **5** (ingest, nightly-research, on-pr-review, portfolio-rollup, weekly-maintenance). | OK — exactly 5. (The broad doc's checkpoint and `.gitkeep`-free count is correct; Pass-6/G-4 once wrote "6 Action templates" — **that** is the loose number, not Pass-4.) |
| **C2 invented numeric** | `timeout: 5` ×4 (NFR-026); `novelty_threshold 0.15` / `clean_passes_required 3` / `max_passes 6` (NFR-012/013); `per_run_cap 25` / tiers `100/250/400/500` (NFR-029); `retention-days 30` (NFR-022); action timeouts `120/90/60/30/20/10` (NFR-027); `REQUIRE_CITATION_MIN_LINES 3` (NFR-014) | `hooks.json:7-10` → four `"timeout": 5` ✓. `config.template :converge block` → `0.15 / 3 / 6` ✓. `budget` block → `per_run_cap: 25`, `warn:100 alert:250 pause:400 hard_stop:500` ✓. Action `timeout-minutes`: ingest **60**, nightly **120**, on-pr-review **30**+**20**, portfolio-rollup **120**, weekly-maintenance **90**, engine ci.yml **10** ✓. | OK — every number matches byte-for-byte. |
| **C3 misattributed enforcement** | NFR-029 graded **ASPIRATIONAL / no enforcer located** | `.sh` + `lobster-parse` + 5 `.yml` scanned: **0 enforcement references** (see §1). | OK — and this round *strengthens* the grade (validator gap, §1). |
| **C4 invented file path / line** | NFR-013 capped-exit PR title `[DID NOT CONVERGE: M MUST-FIX]` at "nightly-research.yml:72-86" | Title literal lives at `nightly-research.yml:83`; `Do NOT merge` at `:85`; fallback body at `:156`. Range is right. | OK. |
| **C5 hallucinated relationship** | "first-deny-wins chain `protect-secrets → require-citation → layer-discipline → forbidden-phrase`" (NFR-011) | `hooks.json:7-10` order matches exactly. | OK. |

**Audit conclusion:** the Pass-4 broad doc is clean against all five classes. No CONV-ABS retractions. Findings below are *additive* (newly-discovered gaps), not corrections.

---

## 1. P4-1 (HIGH) — Budget-enforcer verdict: DEFINITIVE

**Question (carryover):** `budget.thresholds` / `per_run_cap` / `on_critical_path_downgrade` are config-only. Is it (a) intended human discipline, (b) deferred to GitHub-billing integration, or (c) a true missing mechanism?

**Method.** Scanned every executable + declarative file for `budget|per_run_cap|hard_stop|spend|cumulative|cost`:

- **Executable code** (`bin/lobster-parse`, `bin/factory-config.sh`, all 4 `hooks/*.sh`): **0 references.** No code reads a spend ledger, totals vendor cost, or compares against a tier.
- **All 5 Action templates** (`*.yml`): **0 references** to `budget|spend|per_run_cap|hard_stop|cost`. No CI step measures or caps spend; no `claude-code-action` `--max-cost`-style flag is set.
- **The only two non-config "hits" are non-enforcement:**
  - `workflows/portfolio-synth.lobster:19` — `"…blows the token budget). Index/summary level only."` This is an **LLM-context token budget** comment (why the rollup pulls L4/L5 only), **not** spend governance. Unrelated.
  - `skills/init-market/SKILL.md:54` — a **doc pointer** ("Config schema + autonomy/budget: `…/docs/AUTONOMY.md`"). A reference, not an enforcer.
- **`AUTONOMY.md` (read full):** §Budget describes tiers `warn→alert→pause→hard_stop`, `per_run_cap`, and `on_critical_path_downgrade: pause` purely as **policy prose**. The framing — "Frame cost as per verified finding… If budget would force a model downgrade on the critical path, **pause**" — is written as **operator/LLM-reasoning guidance**, with **no mechanism named** that measures spend or trips a tier. It explicitly says "the engine reads them, contains no hardcoded policy" — but *reads* is the strongest verb; nothing *acts*.

**NEW this round (sharpens the verdict beyond Pass-2/3/4/6):** `factory-config.sh validate` (body `:78-103`) checks **only** `.market`, `.slug`, `.seed.scope_doc`, `.seed.source_inventory`, non-empty `.vectors` / `.tracks`, and id/name presence on entries. It does **not** read or validate the `budget`, `review.convergence`, `autonomy_level`, or `merge` blocks **at all**. Consequence:
- The budget config is not merely **unenforced at runtime** — it is **un-schema-validated at config time**. A market could ship `hard_stop: 50` *below* `pause: 400`, or omit the entire `budget` block, or set `per_run_cap: "banana"`, and `factory-config.sh validate` → **PASS** (and CI's template-config check at `ci.yml:52-53` would pass too).
- This removes the last plausible "(b) deferred-to-integration with a validated schema seam" reading: there is **not even a schema seam**.

**VERDICT — definitively (c): a true missing mechanism, with no validation seam.**
Budget governance is **declared in config + prose, validated nowhere, enforced nowhere.** It is the engine's single declared-but-unbuilt feature (matching the Pass-6 §5 recommendation). It is *not* (a) framed as human-discipline (AUTONOMY.md never says "the morning human checks spend" — unlike merges, which it explicitly hands to the human); it is *not* (b) deferred to a billing integration (no seam, no validated schema, no TODO/`# deferred` marker found). The `on_critical_path_downgrade: pause` knob in particular has **no consumer** — nothing detects a "forced downgrade" event to pause on.

**Re-grade recommendation for NFR-029:** keep ASPIRATIONAL but append the *validation gap* — currently the catalog says "no enforcer located"; it should also say "and no schema validation: malformed/missing budget blocks pass `factory-config.sh validate`." This also resolves Pass-6 **R-6** (Pass-1 §5's "At hard_stop, refuse new agent dispatch" is the optimistic reading; the correct grade is unenforced **and** unvalidated).

---

## 2. P4-2 (MED) — Test-gap NFR observations (confirmed by suite scan)

Re-derived the bats inventory: `config.bats 7`, `hooks-v05.bats 11`, `hooks.bats 9`, `lobster.bats 8` = **35 @tests** (matches Pass-3/6). Scanned all four for `timeout|converge|novelty|max_passes|budget|did not`:
- `config.bats 0`, `hooks-v05.bats 0`, `lobster.bats 0`.
- `hooks.bats 1` — **ruled a false positive**: the match is the word "converge" inside a **test fixture corpus body** (`hooks.bats:60`, an L4 synthesis fixture: "Three tracks converge on the operationalization gap…"), not a convergence-math assertion.

**Confirmed zero-coverage NFRs (test-gap observations):**

| NFR | Behavior with no test | Evidence |
|---|---|---|
| **NFR-026** | The `timeout 5` per-hook bound is asserted from `hooks.json` only; **no test** measures hook wall-clock or asserts the runner kills a >5s hook. | 0 bats hits for `timeout`; hooks tested for *verdict*, never *latency*. |
| **NFR-012** | The convergence math `novelty = new/(new+dup) < 0.15` × `3` clean passes is **orchestrator-prose only**; no test simulates a multi-pass loop and asserts the stop condition. | 0 bats hits for `novelty`/`converge` (real); BC-068 MEDIUM. |
| **NFR-013** | The **capped-exit PR-title path** `[DID NOT CONVERGE: M MUST-FIX]` (`nightly-research.yml:83`) is template prose; **no test** drives `LOOP_CAPPED=true` and asserts the flagged title / `surface-to-human` vs `commit-flagged` dispatch. | 0 bats hits for `max_passes`/`did not`; the title literal is never referenced by any test. |
| **NFR-011 (fail-closed)** | The `jq`-missing fail-closed exit is asserted from `command -v jq` guards; **no test stubs a missing `jq`** to prove the closed-fail. | 0 bats hits; consistent with Pass-3 gap #3. |

**Observation (not a recommendation to build):** the entire **Performance + convergence-honesty NFR band is config-/prose-declared, never test-pinned.** This is the inverse of the security/correctness band (NFR-001/014/015 — 23 of 35 tests). The single highest-value missing test (cross-confirms Pass-3 P3-1) is a **capped-exit simulation** asserting both the PR-title flag and that it is **never** presented as PASS.

---

## 3. P4-3 (MED) — Template-lint recommendation (the CI gap is real)

Verified the depth of CI's Action-template validation. `.github/workflows/ci.yml:47-53`:
```
for f in …/github-action-templates/*.yml; do
  echo "yaml-check $f"; yq -e '.' "$f" > /dev/null
done
bash …/factory-config.sh validate …/factory.config.template.yaml
```
**The Action-template "validation" is `yq -e '.'` — a pure YAML-parseability check.** It asserts the file is well-formed YAML and nothing about its **NFR posture**. Nothing in CI (or anywhere) asserts, per-template:

| NFR | Per-template posture that could silently drift | Currently checked? |
|---|---|---|
| **NFR-007** | `show_full_output` **absent** (OFF) in every builder job (a copy that adds `show_full_output: true` leaks tool results incl. secrets into the public run log). | **No** — only YAML-parse. |
| **NFR-008** | No literal `$VAR` in a reviewer MCP **env block** (the documented "v1 failure": a literal overrides the real inherited key). | **No.** |
| **NFR-010** | Reviewer Perplexity-MCP fence ("ONLY to check… never author") present in the prompt. | **No.** |
| **NFR-022** | `upload-artifact@v4` step present **and** `retention-days: 30` **and** `if: always()` on every model job. | **No** — a drifted copy dropping the upload or retention would parse fine. |
| **NFR-003** | `id-token: write` present on builders / **absent** on `on-pr-review`; reviewer `contents: read`. | **No.** |

**Recommendation (mirrors `ci.yml`'s existing `hooks.json` shape-assertion idiom):** add a CI **template-lint** step — a small `yq`-driven assertion harness over `github-action-templates/*.yml` that fails the build if any builder job lacks the `show_full_output`-OFF posture / artifact upload / `retention-days: 30`, any reviewer job carries `id-token` or a literal `$VAR` env, or any model job is missing `if: always()` on its upload. This is the **structural fix for the NFR-007/008/010/022 "per-template, not centrally enforced" gap** (Pass-4 broad gaps #4/#5) and is consistent with the codebase's "convention = enforced invariant" posture (Pass-5). It is *additive engine code* (a CI step), not market-specific logic, so it respects P10.

**Bonus extension (from §1):** the same lint seam is the natural home for a **config-schema check of the budget/convergence/merge blocks** — the validator gap found in §1. `factory-config.sh validate` should additionally assert `budget.thresholds` are monotonic (`warn ≤ alert ≤ pause ≤ hard_stop`), `per_run_cap > 0`, and `max_passes ≥ clean_passes_required` (the config comment *states* this invariant but nothing checks it).

---

## Delta Summary
- **New items added:** 3 substantive.
  1. **Budget verdict sharpened to "(c) missing mechanism + no validation seam"** (P4-1): newly found that `factory-config.sh validate` ignores the entire `budget`/`convergence`/`autonomy`/`merge` block — malformed/absent budget config PASSes. Beyond Pass-2/3/4/6, which only said "no runtime enforcer." [Security/Cost · NFR-029 · Maintainability]
  2. **Config-invariant `max_passes ≥ clean_passes_required` is stated-in-comment but un-asserted** (P4-3 bonus): the validator never checks it; nor budget-tier monotonicity. [Maintainability · NFR-013/037]
  3. **CI Action-template validation is `yq -e` parse-only** (P4-3): empirically confirmed it asserts zero NFR posture — substantiates the template-lint recommendation as a real, not theoretical, gap. [Maintainability · NFR-007/008/010/022/003]
- **Existing items refined:** NFR-029 (add validation-gap clause); R-6 resolved (Pass-1 §5 over-stated; correct grade = unenforced **and** unvalidated); P4-2 test-gaps confirmed with the one bats false-positive ruled out.
- **Hallucination audit:** 5 classes checked, **0 retractions (no CONV-ABS-N)** — every Pass-4 numeric re-derived byte-for-byte.

## Novelty Assessment
Novelty: **SUBSTANTIVE**
The validator-gap finding (§1) materially changes how the system would be spec'd: budget governance is not just "unenforced at runtime" (the prior model) but "unvalidated at config time" — there is **no schema seam**, which removes the "deferred-to-integration" reading entirely and converts a soft "missing enforcer" note into a hard "config promises a behavior that is neither built nor guarded" requirement. The CI-validation-is-parse-only confirmation (§3) turns a speculative "a drifted copy could regress" gap into a verified one and gives the template-lint recommendation a concrete CI insertion point + scope. Removing this round's findings would change the spec: a downstream PRD would otherwise assume the config schema constrains the budget block (it does not) and would under-scope the template-lint. That clears the SUBSTANTIVE bar (3 items).

## Remaining gaps
- Whether `claude-code-action` exposes any vendor-side per-run cost cap (a `--max-cost`-style input) that an instance *could* wire is **external to this tree** — unresolvable here; flag for the Action-vendor-docs owner (overlaps Pass-1 G-4 / P1-4).
- The `on_critical_path_downgrade: pause` knob has **no detectable consumer** even in prose — it presumes a "forced downgrade" event the engine never emits; whether that event is intended to come from the orchestrator's reasoning is undeterminable without the orchestrator runtime (Pass-3 P3-1 territory).
- Cross-vendor cumulative spend would require reading three providers' billing APIs; no such integration or seam exists — confirms (c), but the *intended* data source is unspecified.

## Convergence Declaration
Another round needed — NO. **Pass 4 has one more substantive round's worth of value already delivered here; the remaining gaps are all external-to-tree (vendor-action cost flags, orchestrator runtime) and cannot be resolved by reading this repo.** This round is SUBSTANTIVE; a round 2 against the same source would yield only nitpicks (the enforcer-absence is now exhaustively proven). Recommend Pass-4 round 2 be declared NITPICK unless new source (orchestrator runtime / vendor-action docs) is mounted.

## State Checkpoint
```yaml
pass: 4
round: 1
status: complete
timestamp: 2026-06-01T00:00:00Z
novelty: SUBSTANTIVE
budget_verdict: "(c) missing mechanism + no schema-validation seam — definitive"
hallucination_retractions: 0
substantive_items: 3
carryover_resolved: [P4-1, P4-2, P4-3, R-6]
```
