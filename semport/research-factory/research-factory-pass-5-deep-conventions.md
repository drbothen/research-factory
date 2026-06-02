# Pass 5 Deepening (Round 1): Conventions — research-factory engine

> Deepens the broad Pass-5 catalog (CV-001…045) against Pass-6 carryover targets **P5-1** and **P5-2**.
> Method this round: read all 4 hooks side-by-side (byte-level), all 5 Action `.yml` templates' `name:` fields, all 6 corpus templates' frontmatter, all 5 pm templates' frontmatter, and re-derived commit-convention drift over the **full 55-commit history (all branches)** + a `color`-reader scan across every non-`.md` file. No fabrication — every claim below was read or re-derived this round.

---

## Audit against the 5 Known Hallucination Classes (broad Pass-5 doc)

Re-derived counts/claims that the broad pass asserted but had only *inferred* (its own gaps #1/#5/#6 flagged these as unverified). Results:

| # | Class | Broad-pass claim | Verified value | Verdict |
|---|---|---|---|---|
| H1 | **Phantom count** | CV-012: "`github-action-templates/` (**6** `*.yml` + `mcp.json`)" | `ls` → **5** `.yml` (`ingest`, `nightly-research`, `on-pr-review`, `portfolio-rollup`, `weekly-maintenance`) + `mcp.json` | **CONV-ABS-1** — the "6" is wrong; there are 5. The Pass-6 backlog inherited the error ("the 6 `.yml` Action templates" appears verbatim in P5-1). |
| H2 | **Over-claimed uniformity** | CV-026: "**every** hook follows **one** skeleton … **all 4 hooks share this skeleton**"; CV-027/028 "4/4 … identical" | 3 hooks byte-identical; `require-citation.sh` **diverges** (see below) | **CONV-ABS-2** — partially retracted: skeleton is *structurally* uniform but **not byte-uniform**; "byte-for-byte" (broad gap #6's own test) FAILS for 1 of 4. |
| H3 | **Schema over-specification** | CV-004: "every corpus LayerDocument carries **exactly these four** frontmatter fields"; "tag-namespace **triple** `topic/ type/ status/`" | L4/L6/track-summary carry **extra** fields (`window`, `markets`, `track`, `tier`, `release`); tags include a **4th** namespace `scope/`; L4/L6 **drop** `topic/<track-slug>` | **CONV-ABS-3** — "exactly four" and "triple" retracted; corrected below. |
| H4 | **Unverified inference** | CV-013/AP-4: "`color` is purely cosmetic … none found this pass" | `color`-reader scan over all `.sh`/`.json`/`.lobster`/`lobster-parse` → **0 hits** | **CONFIRMED** (not a hallucination) — AP-4 now has positive evidence, upgraded HIGH. |
| H5 | **Stale carry-forward** | CV-037: "CONSISTENT recently / MOSTLY across full history" (un-quantified) | Full 55-commit re-derivation below | **CONFIRMED + quantified** (was directionally right, now measured). |

Net: **3 retractions (CONV-ABS-1/2/3)**, 2 confirmations. None of the 45 CVs is wholesale invented; the failures are an over-count, an over-claim of byte-uniformity, and an over-tight schema. The broad pass *flagged* H2/H3 as inferred (its gaps #1/#5/#6) and graded them MEDIUM in Pass-6 §3 — so these are honest-inference corrections, not fabrications.

---

## Target P5-1 — naming / frontmatter / hook-skeleton conformance

### F1 — CONV-ABS-1: there are 5 Action `.yml` templates, not 6 (naming CONSISTENT)
All five carry a kebab-case top-level GitHub-Actions `name:` matching the file stem (`ingest.yml`→`name: ingest`, `nightly-research`, `on-pr-review`, `portfolio-rollup`, `weekly-maintenance`) — so **CV-001 (kebab) and CV-002 (name===stem) extend cleanly to the Action layer**. The count is the only error: CV-012's "6 `*.yml`" and the Pass-6 P5-1 wording "the 6 `.yml` Action templates" are both off-by-one. `mcp.json` is the 6th file but is JSON config, not a workflow. **Correction: 5 `.yml` + `mcp.json`.**

### F2 — CONV-ABS-3: corpus frontmatter is a *base-4 + optional-extras* schema, not "exactly four"
Read all 6 corpus templates. The base set `date, layer, layer-observes, tags` holds in 6/6, BUT:
- **L4-cross-track-synthesis** adds `window:`; **its tags drop `topic/<track-slug>`** (cross-track docs have no single track) → `tags: [topic/<market-slug>, type/synthesis, status/draft]`.
- **L6-portfolio-synthesis** adds `window:` AND `markets: [...]`; **its tags use a different namespace** `scope/portfolio` (not `topic/`) and add `markets` as a structured list.
- **track-summary** adds `track:`, `tier:`, `release:` (three extra fields).
- So the tag-namespace is **four** members (`topic/`, `type/`, `status/`, `scope/`), not the "triple" CV-004 claimed, and `topic/<track-slug>` is present only on per-track docs (L2/L3), absent on cross-track/portfolio docs (L4/L6).

**Corrected CV-004:** *every corpus LayerDocument carries the base set `date, layer, layer-observes, tags`; aggregation docs (L4/L6/track-summary) additionally carry scope fields (`window`, `markets`, `track`, `tier`, `release`); the `tags` array draws from `topic/ type/ status/ scope/` and omits `topic/<track-slug>` on non-per-track docs.* Consistency: **CONSISTENT** as a base+extension schema (the extras are principled by document scope), **INCONSISTENT** only against the broad pass's over-tight "exactly four / triple" statement.

### F3 — NEW CV-046: the PM ladder uses a *blockquote-metadata* convention, NOT layer frontmatter
Read all 5 pm templates (`prd`, `concept-narrative`, `six-pager`, `user-stories`, `acceptance-plan`). **None carries any YAML frontmatter.** Instead each opens with `# <DocType> — <title>` then a `>` blockquote carrying inline traceability (`PRD-<id> · parent INIT-<id> · traces to <L4/L5 finding>`; `INIT-<id>`; `Traces to PRD-<id> / US-<n>`). This is a **distinct, deliberate second template family**: corpus docs are machine-gated (frontmatter parsed by the layer-discipline hook) and so carry YAML; PM docs are human-handoff artifacts outside the corpus hook scope (`/corpus/` filter, CV-028) and so carry prose-blockquote metadata instead. The PM traceability prefixes (CV-005: `INIT·PRD·JTBD·US·AC`) live in this blockquote, not in frontmatter — explaining CV-005's "enforcement is prose-level" (Pass-3 found no test): there is no frontmatter for a hook to parse. **CV-004 should be scoped to "corpus LayerDocuments only"; PM docs are governed by new CV-046.**

### F4 — NEW CV-047: `*-tldr.md` is a *co-layer* view, observing the same lower layer as its full sibling
`L2-baseline-tldr` → `layer-observes: L1` (same as `L2-baseline`); `L3-findings-tldr` → `layer-observes: L2` (same as `L3-findings`). A TL;DR is **not** an L(n+1) doc observing the full L_n doc — it is a co-layer summary at the same layer, observing the same lower layer. This refines CV-003/CV-004: the layer-discipline invariant (L_n observes L(n-1)) treats a tldr as identical-layer to its sibling, so the hook passes both. A reasonable reader (and an LLM translator) might wrongly model the tldr as observing its full sibling; it does not.

### F5 — CONV-ABS-2: hook skeleton is structurally uniform but NOT byte-uniform (require-citation diverges)
Side-by-side read of all 4 hooks. `protect-secrets`, `layer-discipline-guard`, `forbidden-phrase-guard` are **byte-identical** in their skeleton: single-line `emit_allow()`/`emit_deny()` helpers with `jq -nc --arg r "$1"`, and a one-line dep-guard `command -v jq &>/dev/null || { echo "<name>.sh: jq required" >&2; exit 1; }`. `require-citation.sh` **diverges on three axes** (it is the oldest/largest hook, 103 LOC vs 26–59):
1. **Multi-line emit helpers** with `local reason="$1"` and `--arg reason "$reason"` (the other three use inline `--arg r "$1"`).
2. **Multi-line dep-guard** `if ! command -v jq &>/dev/null; then echo "…jq is required but not found" >&2; exit 1; fi` (vs the one-line `|| {…}` form).
3. **Multi-line scope-ladder** (broken across `case` blocks with a separate `BASENAME=$(basename …)` var) vs the others' compact single-line `case` statements.

The **JSON envelope emitted is identical** (allow/deny decision bytes match), so behavior is uniform — but the broad pass's own deepening test (gap #6: "confirm the skeleton is byte-for-byte uniform … identical `emit_allow`/`emit_deny` helpers") **FAILS for require-citation**. Corrected CV-026/027/028: *the skeleton is **semantically/structurally** uniform across 4/4 hooks; **byte-uniform** across 3/4, with `require-citation.sh` carrying a stylistic (pre-standardization) variant of the same contract.* This is a refactor opportunity, not a bug — and a real convention-drift datum the broad pass's "all 4 identical" obscured.

### F6 — stream/exit convention IS uniform across all 4 hooks (carryover sub-question, CONFIRMED)
The Pass-6 P5-1 sub-question asked whether require-citation's stream/exit convention matches the others (given the Pass-3 finding that `factory-config` writes to stderr while `lobster-parse` writes to stdout). Verified: **all 4 hooks** send the jq-missing diagnostic to **stderr** with **`exit 1`** (self-failure), and the allow/deny JSON decision to **stdout** with **`exit 0`**. So the hook chain is internally consistent on streams (unlike the bin/ tools' split). The `factory-config`-vs-`lobster-parse` stderr/stdout divergence (Pass-3) is a **bin/-layer** inconsistency that does **not** propagate to the hook layer. New sub-finding: the engine has **two stream conventions by layer** — hooks uniformly (stdout=decision, stderr=self-error); bin/ tools split (`factory-config`→stderr diagnostics, `lobster-parse`→stdout). Worth flagging for a translator: don't assume one global stream convention.

---

## Target P5-2 — commit-convention drift + `color` cosmetics

### F7 — CONV: commit-convention drift quantified over full 55-commit history
Re-derived `git log --all --format='%s'` (55 commits, all branches incl. `factory-artifacts`). Tally of the leading token:

| Prefix class | Count | Conventional-commits? |
|---|---|---|
| `feat` / `fix` / `chore` / `docs` / `ci` / `revert` (standard types) | ~30 | YES |
| `state` / `state(…)` / `chore(state)` | 13 | **NO** — `state` is not a CC type (a project-invented type for `.factory/STATE.md` bursts) |
| `vX.Y:` (`v0.1`, `v0.5`, `v0.8`, `v0.9`) | 7 | **NO** — version-milestone prefix, not a type |
| `factory(phase-0)` / `factory-artifacts:` | 3 | **NO** — project-invented |
| bare `actions:` / `P0:` | 2 | **NO** |

**~25 of 55 (~45%) deviate from strict conventional-commits.** But the deviation is **front-loaded in time**: the `vX.Y:` milestone prefixes and the no-type `factory-artifacts:`/`P0:` subjects are all **early plumbing/milestone commits** (pre-v1.0). The `state:` family (13) is the one **persistent** non-CC convention — it is the engine's **deliberate** marker for state-manager `.factory/STATE.md` commits (the sole-committer's burst commits, CV-039), and it survives to recent history. So CV-037's "MOSTLY across full history / CONSISTENT recently" is **confirmed and quantified**: recent *feature* commits are clean CC (`feat(scope): … (#PR)`), but the `state:` lane is a standing parallel convention, not drift. **No `commitlint`/CI subject-linting exists** (confirmed: no commitlint config, CI validates manifests/lobster/templates/config but not commit subjects) — so the convention is honor-system, which is why the two lanes (`feat/fix` vs `state`) coexist uncorrected.

**Refinement to CV-037:** the engine actually runs **two commit conventions in parallel** — (a) conventional-commits `type(scope): summary (#PR)` for human/feature PRs, and (b) a `state:`/`state(§N):` lane for the sole-committer's `.factory/STATE.md` bursts. This is principled (different committer, different artifact, different branch `factory-artifacts`), not sloppiness — but CV-037 modeled only lane (a).

### F8 — CONFIRMED CV/AP-4: `color` is purely cosmetic — zero readers engine-wide
Scanned every `.sh`, `.json`, `.lobster`, and `lobster-parse` for any reference to the agent-frontmatter `color` field → **0 hits**. No hook, no validator, no workflow, no `hooks.json`, no `plugin.json` reads it. AP-4 is now positively confirmed (was "none found this pass" → now "exhaustively none"): `color` is a Claude-Code-display affordance only; `name` is the sole dispatch key (CV-002). Upgrade AP-4 evidence from inference to **HIGH-confidence verified**.

---

## Delta Summary
- **New conventions added: 2** — CV-046 (PM-ladder blockquote-metadata, distinct from corpus frontmatter), CV-047 (tldr is a co-layer view).
- **Retractions (CONV-ABS): 3** — CONV-ABS-1 (Action `.yml` count 6→5), CONV-ABS-2 (hook skeleton byte-uniform 4/4 → 3/4; require-citation diverges), CONV-ABS-3 (corpus frontmatter "exactly four / triple" → base-4 + scope-extras + 4-member tag namespace).
- **Existing conventions refined: 4** — CV-004 (scoped to corpus + extras), CV-026/027/028 (structural-not-byte uniformity), CV-037 (two-lane commit convention, quantified ~45% non-CC), CV-005 (PM prefixes live in blockquote, hence untestable).
- **Confirmations: 2** — AP-4 `color` zero-readers (HIGH); hook stream convention uniform (stderr/exit1 self-error, stdout/exit0 decision) + new "two stream conventions by layer" datum.
- **Carryover targets closed:** P5-1 (Action naming ✓ via F1; corpus/pm frontmatter ✓ via F2/F3; byte-level hook conformance ✓ via F5; require-citation stream convention ✓ via F6) and P5-2 (commit drift ✓ via F7; `color` cosmetic ✓ via F8) — **both fully resolved.**

## Remaining gaps
- None convention-blocking. Minor: `instance-docs/review-spec.md` (119 LOC) and `templates/portfolio/manifest.yaml` frontmatter conformance not separately audited this round (low value — neither is corpus- or PM-family; review-spec is a Codex prompt, manifest is YAML config). `ingest.yml`/`weekly-maintenance.yml` *runtime* semantics are a Pass-1/Pass-4 concern (G-4), not a convention concern.

## Novelty Assessment
Novelty: SUBSTANTIVE

Removing this round's findings WOULD change how the system is spec'd: a downstream skill modeling "the corpus frontmatter schema" would over-tighten it to 4 fields (CONV-ABS-3) and miss the L4/L6/track-summary scope-fields and the `scope/` tag namespace; it would mis-model the PM ladder as carrying layer frontmatter (CV-046) when it carries none; it would assume all 4 hooks are byte-identical (CONV-ABS-2) when require-citation is a divergent variant; and it would mis-state the commit convention as single-lane (F7) when a parallel `state:` lane is structural. Three of these are corrections to over-claims in the broad doc (retractions), and two are genuinely new conventions (CV-046/047) — well above the 3-substantive-item bar.

## State Checkpoint
pass: 5
round: 1
status: complete
timestamp: 2026-06-01T00:00:00Z
novelty: SUBSTANTIVE
