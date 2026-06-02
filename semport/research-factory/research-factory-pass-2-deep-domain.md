# Pass 2: Domain Model — DEEP (round 1) — research-factory engine

> Convergence deepening of Pass 2. Carryover targets P2-1…P2-6 (verbatim from the Pass-6 backlog).
> Reads this round (in full): `agents/state-manager.md`, the live hand-rolled STATE example
> (`.factory/cycles/v1.0-brownfield-migration/legacy-research-factory-state.md`), `templates/corpus/`
> {track-summary, L3-findings, L3-findings-tldr, L2-baseline, L2-baseline-tldr, L4-cross-track-synthesis,
> L6-portfolio-synthesis, README}, `templates/pm/` {concept-narrative, six-pager, acceptance-plan},
> `skills/{init-market,build-track}/SKILL.md`, `agents/{consistency-validator,dashboard-builder,editorial-sweeper}.md`,
> `workflows/maintenance.lobster`.
> Only **deltas / new depth** vs the broad Pass-2 doc are recorded. Confidence tags as in the broad pass.

---

## 0. Hallucination audit of the Pass-2 broad doc (5 known classes)

Re-derived every count and re-checked the named structures against source this round.

| Broad-doc claim | Re-check | Verdict |
|---|---|---|
| "PMDocLadder = 5 ordered templates (concept/six-pager/prd/stories/acceptance)" | `ls templates/pm/` → exactly `acceptance-plan.md, concept-narrative.md, prd.md, six-pager.md, user-stories.md` = **5 files**. | ✅ accurate |
| "8 corpus templates / L1–L6 family" | `ls templates/corpus/` → 8 files (L2-baseline ±tldr, L3-findings ±tldr, track-summary, L4-cross-track-synthesis, L6-portfolio-synthesis, README). **No L1 template ships** — L1 is "raw sourcing," scaffolded by the researcher, not a corpus skeleton. The broad-doc `L1RawSourcing` entity is real (LAYER-MODEL row) but has **no template file** (README §"per-track document set" lists 5 track docs + L4 + L6, none L1). | ✅ accurate; **clarified**: L1 has no skeleton template |
| "TrackSummary = (L3-level, L4-consumption surface)" frontmatter `layer: L3` | track-summary.md frontmatter is `layer: L3 / layer-observes: L2` **plus** `track:`, `tier:`, `release:` — three fields the broad doc never listed (see P2-2 below). | ⚠️ **incomplete** — refined, not retracted |
| "VectorCoverageTable rolls up to a market-level picture at L4 and a market×vector matrix at L6" | L4 template §"Market-Level Vector Picture" is explicitly **Optional** (`<!-- Optional: roll up… -->`); L6 §"Market × Vector Roll-Up" is **not** marked optional. Broad doc implied both mandatory. | ⚠️ **over-stated** — corrected in P2-2 |
| "Phase enum {observe-and-report \| judgment \| productization}; transition triggers inferred" | Confirmed: no operation graduates a Market automatically. The only documented trigger is init-market step 8 (human, manual). See P2-4. | ✅ accurate (the inference was correctly hedged) |
| STATE entity "Key properties: phase, step, decisions log, active branches, drift items, ## Track build log" | The **prose model** (state-manager.md) names exactly these. The **concrete example** carries a far larger field set (≈10 named sections). Broad doc modeled the prose, not the artifact. See P2-1. | ⚠️ **materially incomplete** — the largest delta this round |

No finding required full retraction (no `CONV-ABS-N`). Two were over-stated/incomplete and are corrected below. **Net: the broad doc's entity *names* survive; its *field sets* for STATE, TrackSummary, and the L4/L6 roll-ups were under-specified.**

---

## P2-1 (HIGH) — STATE aggregate: prose-model vs concrete-artifact reconciliation

This is the round's headline delta. The broad doc modeled STATE from `state-manager.md` prose. Reading
the **actual hand-rolled artifact** shows the engine's STATE is a *much* richer, semi-structured prose
document than the 6-field prose model implied — and reveals a model/artifact gap worth recording.

### Authoritative prose model (`state-manager.md:32`)
STATE.md is "the single zero-context-resume file: **current phase, current step, decisions log, active
branches, drift items**," size-capped with history extracted to cycle files, plus a `## Track build log`
(one entry per burst). That is the **contract** — six conceptual fields. (`state-manager.md:32,38-44`.)

### Concrete artifact field set (the legacy hand-rolled example)
The real `STATE.md` is **free-form Markdown prose, not YAML/structured frontmatter** — a critical modeling
fact the broad doc missed (it implied a structured aggregate). Its actual recurring sections:

| STATE section (concrete) | Maps to prose field? | What it holds | Conf |
|---|---|---|---|
| `## ▶ RESUME NEXT SESSION` (a "what to do next" block, ⏵-flagged, top of file) | **NOT in prose model** | the single most-load-bearing block: next action + current blocker + decision options | HIGH |
| `## Current phase` | ≈ "current phase/step" but free prose, version-tagged (`v1.0 IN PROGRESS`), not the config `phase` enum | narrative build-phase, not the {observe/judgment/productization} enum | HIGH |
| `### What's left to v1.0` (ordered checklist with ✅/⛔/⬜) | ≈ "current step" | the work-item ledger with status glyphs | HIGH |
| `## Roadmap status` (table: Phase · Status · Acceptance evidence) | **NOT in prose model** | per-milestone acceptance-evidence ledger | HIGH |
| `## Repos` (table: Repo · Role · Visibility) | **NOT in prose model** | the repo topology (engine/template/instances/portfolio) | HIGH |
| `## Deployment fixes baked into the Action templates` (numbered) | **NOT in prose model** | accumulated ops gotchas | HIGH |
| `## Deferred components` | **NOT in prose model** | built-lean delta vs BUILD-PLAN (hooks 4/9, agents 11/12, etc.) | HIGH |
| `## Open items (not blockers)` | ≈ "drift items" (loosely) | tracked-but-non-blocking issues, ✅-resolvable in place | HIGH |
| `## Decisions log` (dated bullets) | ✅ "decisions log" | append-only dated decisions | HIGH |
| `## How to resume` (numbered cold-start) | **NOT in prose model** | the bootstrap procedure | HIGH |
| `## Track build log` (per-burst `### <track> — <date>` entries) | ✅ "## Track build log" | one entry per production burst | HIGH (named in both) |

**Reconciliation finding (new, MEDIUM):** the prose contract names **6** fields; the concrete artifact has
**~11** recurring sections, **7 of which the prose model does not enumerate** (RESUME block, Roadmap-status
table, Repos table, Deployment-fixes, Deferred-components, How-to-resume, and the version-narrative form of
"phase"). This is the **engine's own dogfooded STATE**, written by a human operator — so it is *richer than
the contract the haiku state-manager is told to maintain*. The state-manager's machine-maintained STATE
(per the CI division-of-labor) would plausibly carry only the contract fields + the Track-build-log it
appends; the operator-authored sections are human-curated. **Modeling consequence:** STATE is best modeled
as **two overlapping schemas** — (a) the *agent-maintained core* (phase, step, decisions log, branches,
drift, Track build log — the 6-field contract) and (b) the *operator-curated superset* (the resume block,
roadmap/repos/deployment ledgers) that lives in the same file but is hand-authored. The broad doc's STATE
entity is correct for (a) and silent on (b).

**New STATE-adjacent entities/value objects:**
- **`WorkItemStatus` (value object, enum-ish):** `✅ done` · `⛔ BLOCKED` · `⬜ not-started` · `🔄/in-progress`
  glyphs used throughout the RESUME + What's-left ledgers. (Concrete artifact, throughout.) **HIGH.**
- **`Decision` (value object):** a dated, append-only `YYYY-MM-DD: <decision text>` entry; never rewritten.
  The broad doc named "decisions log" as a field but not the entry shape. **HIGH** (`Decisions log` section).
- **`TrackBuildLogEntry` (value object):** `### <track-slug> — <date>` + run id + convergence-pass-count +
  outcome (the international-cohort entry records "converged at adversary pass 5"). The broad doc named the
  log; this pins the **entry carries the convergence-pass-count and run id** — directly linking STATE to the
  convergence state machine. **HIGH** (concrete artifact §State-model-validation-RESULT, Track build log).
- **`RepoRole` (value object, enum):** engine (public) · template (public) · instance (private) ·
  portfolio (private) — the repo-topology vocabulary. **MEDIUM** (concrete `## Repos`; matches Pass-1 surfaces).
- **Cycle-file extraction (relationship):** when STATE grows, history is **extracted to `cycle` files**
  (`.factory/cycles/<cycle>/…`) — the legacy STATE itself lives under `cycles/v1.0-brownfield-migration/`.
  STATE 1──N CycleFile (archived history). The broad doc mentioned size-cap; this names the archive target.
  **HIGH** (`state-manager.md:32` + the artifact's own path).

---

## P2-2 (MED) — TrackSummary + VectorCoverageTable roll-up field sets (exact)

### TrackSummary — full field set (refines the broad doc)
Frontmatter (new — broad doc omitted all three): **`track: <slug>`, `tier: <Alpha|Beta|Production>`,
`release: <vX.Y>`** in addition to `date/layer:L3/layer-observes:L2/tags`. Body sections (exact, in order):
1. **`## Findings`** — a **complete numbered index** (`F1, F2…Fn`), each: `finding statement + evidence
   anchor + (→ Finding n)` back-reference to the full L3 doc. Contract: "**COMPLETE structured index of
   every L3 finding** — not a highlight reel. If a finding exists in the findings doc, it appears here."
   → **new value object `FindingIndexEntry`** = {id `Fn`, statement, evidence-anchor, L3-finding-ref}. **HIGH.**
2. **`## Vector Coverage`** — a *3-column* reduction (`Vector · Coverage · Notes`) — **fewer columns** than
   the full L3 table's 4 (drops the separate `Evidence basis`, folds it into `Notes`). **HIGH.**
3. **`## Structural Gaps`** — "named, observable gaps… **feed work-item generation** and L4 synthesis."
   → recurring sub-entity (see below). **HIGH.**
4. **`## Bottom Line`** — "2–4 sentences **an L4 synthesizer can lift directly**." The literal L4-consumption
   payload. **HIGH.**
5. **`## Related`** — points at the L3 findings + L2 baseline.
The track-summary header comment also names an **authoritative external spec**: `_meta/track-summary-spec.md`
**in the instance** (not in the engine) — a per-instance format doc the engine template defers to. **MEDIUM**
(referenced, not shippable in the generic engine — consistent with P10).

### VectorCoverageTable — three distinct shapes (new precision)
The "one table" is actually **three layer-specific shapes**, not one rolled-up form:

| Where | Columns | Mandatory? | Conf |
|---|---|---|---|
| **L3 findings** (the canonical) | `Vector · Coverage · Evidence basis · Structural note` (4) | **MANDATORY** (missing = MUST-FIX; unexplained None/Weak = SHOULD-FIX) | HIGH |
| **L3 findings TL;DR** | `Vector · Coverage · Note` (3) | mandatory ("table is mandatory at L3", carried into the tldr) | HIGH |
| **track-summary** | `Vector · Coverage · Notes` (3) | present (part of the complete index) | HIGH |
| **L4 "Market-Level Vector Picture"** | `Vector · Market-level coverage · Contributing tracks` (3) | **OPTIONAL** (`<!-- Optional -->`) — aggregates per-track tables, adds a **`Contributing tracks`** column | HIGH |
| **L6 "Market × Vector Roll-Up"** | `Vector · <market-a> · <market-b> · Cross-market note` (market-columns) | present (not marked optional) | HIGH |

**Corrections to the broad doc:** (a) the L4 market picture is **optional**, not mandatory; (b) the L4 form
introduces a new column `Contributing tracks`; (c) the L6 matrix's columns are **per-market**, the vector
rows are the **union** of markets' schemas, and **cells can be `n/a`** for a vector a market doesn't carry
(market-a-only / market-b-only rows). These `n/a` cells are a real value-object state the broad doc didn't
capture. **HIGH.**

### New recurring sub-entity: `StructuralGap`
Appears as a named section in **L2-baseline ("Gaps Worth Naming"), L3 (implicit in findings),
track-summary ("Structural Gaps"), L4 ("Structural Gaps — market-level"), and L6 ("Structural Gaps —
portfolio-level")** — i.e. a **single domain concept that propagates up every layer**, each level widening
its scope (track gap → market gap → portfolio gap = "negative space between markets"). The track-summary
notes structural gaps "**feed work-item generation**" — linking StructuralGap to the (un-modeled) work-item
pipeline. **New value object, propagates the full L2→L6 spine.** **HIGH** (5 templates name it).

### L2-baseline field set (new — broad doc never read it)
The L2 baseline is the **richest single template** (13 named sections): What-This-Document-Is ·
What-"\<Track\>"-Means · Why-Structurally-Distinct · Current-Methods · (optional comparison table) ·
Drivers-Making-This-Acute-Now · Where-Approaches-Stop-Short · Gaps-Worth-Naming · Reframings-Worth-Surfacing
· What-"Good"-Would-Look-Like (**bounded as observed desired-state, not corpus recommendation**) ·
Open-Questions · Related · Companion-document. The **"What 'Good' Would Look Like"** section is a notable
domain construct: it lets observed/stated desired-states into an observe-only layer **only when framed as
what the sources say**, not as the corpus's view — the exact seam the editorial-sweeper polices (P2-5).
**HIGH.**

---

## P2-3 (MED) — Remaining PM-ladder sub-entities (concept / six-pager / acceptance)

Read all three in full. **No new top-level entity** beyond the 5-doc ladder, but **new value objects** and a
confirmed cross-ladder invariant:

- **Traceability ID scheme (value object family, now fully enumerated):** `INIT-<id>` (concept/six-pager
  header) → `PRD-<id>` → `US-<n>` (user stories) → `TC-<n>` / `EC-<n>` (acceptance test/edge cases). The
  broad doc listed "INIT · PRD · JTBD · US · AC" from pm-doc-writer; the templates **refine AC into `TC`
  (test case) + `EC` (edge case)** and add the explicit `Traces to PRD-<id> / US-<n>` linkage. **HIGH.**
- **`Evidence / Assumptions / Open-Questions` triad (value object):** appears verbatim in **every** ladder
  doc (concept, six-pager) as a named, **separated** block — the structural realization of the
  "never-invent-specifics → labeled Assumption + Open Question" rule. Confirms it is a *required document
  section*, not just a behavioral norm. **HIGH.**
- **AcceptancePlan sub-entities (new):** `TestCase` {TC-id, story-ref, scenario, steps, expected, pass/fail}
  · `EdgeCase` {EC-id, scenario, expected} · `OperationalValidation` (ties to PRD §7 metrics) ·
  `Threat/AbuseCase` (conditional: "platform/security work") · `DefinitionOfDone` (checkbox list: all MVF
  stories' AC pass · operational validation met · open questions resolved-or-deferred-with-owner). The
  **`DefinitionOfDone`** is a genuine new value object — the ladder's terminal gate, mirroring the corpus's
  adversary-PASS gate. **HIGH.**
- **Six-pager `Non-Goals` (value object):** explicit "scope fences" section — the PM-side analogue of the
  corpus's "what this track does NOT cover" boundary. **MEDIUM.**
- **Confirmed:** **MVF vs Future** separation recurs in concept ("MVF intent vs longer-term"), six-pager
  ("Phasing Sketch (MVF → Future)"), and (per broad doc) the PRD — so MVF/Future is a **ladder-wide value
  object**, not a PRD-only one as the broad doc framed it. **HIGH.**

---

## P2-4 (MED) — Market phase-transition triggers (pinned)

The broad doc's state-machine C marked these MEDIUM/inferred. Now **pinned from source**:

- **There is NO automated phase-graduation operation.** No agent, workflow, hook, or skill transitions a
  Market's `phase` from `observe-and-report` → `judgment` → `productization`. The `phase` value is a **plain
  config field** in `factory.config.yaml` that a **human edits**. (Confirmed: init-market interviews for
  `phase` as a seed input; no later operation rewrites it.) **HIGH (negative finding).**
- **The single documented graduation gate is init-market step 8 + its Red Flag:** *"Prove one track by hand
  before enabling autonomy: run `build-track` on a single track to an **adversary PASS** … Only then turn
  the cron schedules on. Start at `autonomy_level: 3`."* The Red-Flag row makes it a hard rule: *"I'll turn
  the cron schedules on now." → "No… Prove one track by hand before enabling autonomy."* So the **real
  transition gated by an operation** is *manual-proof → autonomy-enablement*, NOT the phase enum. **HIGH.**
- **Modeling consequence:** the broad doc conflated two orthogonal progressions. They are distinct:
  1. **`phase`** (observe/judgment/productization) — a human-set *capability flag* (which contexts the
     market has turned on); no transition operation.
  2. **`autonomy_level`** (3 → 3.5 → 4) — gated by the **prove-one-track-to-adversary-PASS-by-hand** step;
     this is the only operation-backed graduation in the engine.
  The `judgment`/`productization` phases are further fenced by `merge.always_human` (l5/l6/pm are *always*
  human-gated regardless of phase) — so "graduating to judgment" enables L5 *work* but never auto-merges it.
  **HIGH.** This corrects state-machine C: relabel it **two independent progressions**, only one of which
  (autonomy) has a transition trigger.

---

## P2-5 (MED) — "Corpus Health" bounded context (modeled)

The maintenance triad is a genuine small bounded context, distinct from Corpus Production. Read all three
agent bodies + `maintenance.lobster`.

### Context shape
`maintenance.lobster` (weekly cron) runs **consistency-validator ∥ editorial-sweeper** (both `depends_on:
[]` = parallel, fresh context) → **dashboard-builder** (`depends_on` both) → **state-manager** (opens a PR;
**human merges at autonomy 3, never auto**). So Corpus Health is a **read-mostly audit context** whose only
write is the dashboard data file + a PR. **HIGH.**

### Entities / value objects (new)
- **`DriftItem` (the context's core entity):** a detected cross-document inconsistency. The
  consistency-validator produces **5 typed drift checks**: (1) **broken reference** (dangling `[[wikilink]]`
  / file path), (2) **canonical-value drift** (a count/date not matching `seed/canonical-values.md`), (3)
  **missing/inconsistent layer-tag**, (4) **traceability break** (L_n citing other than L_(n-1); dangling
  FR/ID ref), (5) **naming violation** (kebab-case, `<base>.md`/`<base>-tldr.md`). Each DriftItem carries
  **{location, corrected-target/value, severity ∈ MUST-FIX/SHOULD-FIX/SUGGESTION}**. A broken cross-ref or
  contradicted canonical value is **MUST-FIX**. **HIGH** (`consistency-validator.md:27-37`).
- **`SingleSourceOfTruth` (value object, now grounded):** `seed/canonical-values.md` is the **named
  authoritative file** every count/date must match; "never re-derive a canonical value." The broad doc had
  the rule (B-rule 11); this pins the **artifact** (`seed/canonical-values.md`) the validator checks against.
  **HIGH.**
- **`EditorialDriftFinding` (value object):** the editorial-sweeper's output — a flagged phrase + location +
  why-it-drifts + reframe-suggestion. **6 drift categories:** superlatives/rankings · mandate-path/
  prescription · "what to build"/solution-naming · promotion-signal language · ambient-synthesis
  conclusions (a Bottom-Line not anchored to its section) · (and the *allowed* set: source-attributed
  judgment, observed-absence framing). Severity **SHOULD-FIX by default; MUST-FIX for "what to build" /
  positioning in corpus voice.** This is the **recall** side of the P5 observe-only invariant the hook
  (bright-lines) can't catch. **HIGH** (`editorial-sweeper.md:26-41`).
- **`DashboardStatus` (value object) + `dashboard data file` (entity):** dashboard-builder computes, per
  track, **{L3-findings-present, vector-coverage-table-present, unresolved-marker-count (`[Source needed`,
  `[Access required`, MUST-FIX), quality-tier}** and writes a **status/dashboard data file**, reporting
  **tier/marker deltas since last build**. Critically: **quality tiers are READ from recorded adversary
  verdicts, never self-assigned** ("I compute status; I do not assign it by opinion"). So the Quality-tier
  value object (broad doc §2a.4) is *produced* by the adversary and *reported* by the dashboard — two
  agents, one value object, never self-reported. **HIGH** (`dashboard-builder.md:26-35`).

### Bounded-context relationships (new)
- Corpus Health **observes** the Corpus Production output (read-only) and **emits** DriftItems +
  EditorialDriftFindings into the same MUST-FIX/SHOULD-FIX/SUGGESTION severity vocabulary the adversary uses
  — so its findings feed the **same review-loop disposition** as adversary findings. **MEDIUM.**
- **`Unresolved marker` (value object):** the dashboard counts `[Source needed`, `[Access required`, and
  MUST-FIX as the three marker types — re-using the broad doc's Unsourced-flag value object as a *countable
  health metric*. **HIGH.**
- StructuralGap (P2-2) → "feed work-item generation"; DriftItem → MUST-FIX into the loop. Both confirm an
  un-modeled **WorkItem** concept (the corpus surfaces gaps that become work). The engine has **no WorkItem
  entity/template** — it is referenced ("feed work-item generation") but not realized. **MEDIUM (gap).**

---

## P2-6 (LOW) — Remaining value objects swept

- **Frontmatter `window` / `release` (value object):** L4 and L6 carry `window: <synthesis-window-or-release>`;
  track-summary carries `release: <vX.Y>`; the portfolio manifest keys on `window`. The **synthesis window**
  is a real domain value object (the time/release slice a cross-track or cross-market synthesis covers) the
  broad doc only mentioned in passing. L6 also carries `markets: [<slug>, …]` frontmatter (the rollup's
  market set). **HIGH.**
- **`tier` frontmatter on track-summary** = the Quality-tier value object surfaced in *document frontmatter*
  (Alpha/Beta/Production), not just in review records. **HIGH.**
- **README "per-track document set = five documents" + "one L4 per release window" + "L6 is the lone
  cross-market doc, lives in the portfolio repo":** confirms cardinality the broad doc asserted — Track 1──5
  docs (L2±tldr, L3±tldr, summary), Market 1──N L4 (one per window), Portfolio 1──N L6. **HIGH.**
- **Instance filename convention (value object):** README pins the exact instance filenames each template
  produces (`<market>-<track-slug>.md`, `…-tldr.md`, `…-findings.md`, `…-findings-tldr.md`, `…-summary.md`,
  `<market>-synthesis-<window>.md`, `portfolio-<window>.md`). A naming value object the consistency-validator
  checks. **HIGH.**

---

## Delta Summary

- **New items added by P2 target:**
  - P2-1 (STATE): 1 reconciliation finding (6-field contract vs ~11-section artifact; STATE is **prose, not
    structured**) + 5 new value objects/relationships (WorkItemStatus, Decision-entry, TrackBuildLogEntry
    carrying convergence-pass-count, RepoRole, Cycle-file extraction).
  - P2-2 (rollups): 3 new (FindingIndexEntry, StructuralGap as L2→L6-propagating value object, L2-baseline
    13-section field set) + 2 corrections (L4 market picture is **optional** + adds `Contributing tracks`;
    L6 matrix is per-market union with `n/a` cells) + TrackSummary frontmatter `track/tier/release`.
  - P2-3 (PM): 4 new value objects (refined AC→TC/EC ID scheme, Evidence/Assumptions/Open-Q triad as
    required section, AcceptancePlan TestCase/EdgeCase/DefinitionOfDone family, Six-pager Non-Goals) + MVF/
    Future re-scoped ladder-wide.
  - P2-4 (phase): 1 structural correction (phase enum has **no transition operation**; the only
    operation-gated graduation is autonomy via "prove-one-track-to-adversary-PASS").
  - P2-5 (Corpus Health): 1 bounded context modeled + 5 entities/value objects (DriftItem w/ 5 typed checks,
    SingleSourceOfTruth=`seed/canonical-values.md`, EditorialDriftFinding w/ 6 categories, DashboardStatus +
    dashboard data file, Unresolved-marker metric) + the un-modeled WorkItem gap.
  - P2-6: 4 (synthesis-window value object, tier-in-frontmatter, document-set cardinality, instance filename
    convention).
- **Existing items refined:** STATE entity, TrackSummary, VectorCoverageTable, Quality-tier, market-phase
  state machine (C), PMDocLadder traceability IDs.
- **Hallucination retractions:** 0 full (no `CONV-ABS-N`); 2 over-stated claims corrected (L4 rollup
  optionality; STATE field completeness).
- **Remaining gaps:** WorkItem pipeline (referenced, never modeled); the per-instance `_meta/
  track-summary-spec.md` authoritative format (external to engine); `seed/canonical-values.md` schema (named,
  not templated in the engine).

## Novelty Assessment

Novelty: **SUBSTANTIVE**

Removing this round's findings *would* change how I'd spec the system: (1) STATE would be modeled as a
6-field structured aggregate when it is actually a ~11-section **prose** document with a model/artifact gap
between the agent-maintained core and the operator-curated superset — a spec built on the broad model would
under-specify the resume contract and mis-type STATE as structured; (2) the phase-transition correction is
load-bearing — the broad doc's state-machine C implied an operation graduates `phase`, but the only
operation-gated progression is `autonomy_level`, and `phase` is a human-set flag with no trigger (a spec
would otherwise invent a non-existent graduation operation); (3) "Corpus Health" goes from a named-but-empty
bounded context to a modeled one with 5 entities and the typed DriftItem check set; (4) StructuralGap is a
newly-identified value object that propagates the entire L2→L6 spine and feeds an un-modeled WorkItem
concept. These are model-changing, not refinements.

## Remaining gaps / next candidate scope (verbatim-ready for round 2)

1. **WorkItem pipeline (MED).** Both StructuralGap ("feed work-item generation") and DriftItem (MUST-FIX into
   the loop) reference a work-item concept the engine never models with an entity or template. Trace whether
   work-items are (a) an instance-side `_meta/` artifact, (b) GitHub Issues, or (c) unrealized — read any
   `new-track`/work-item scaffolder referenced by skills, and grep the Action templates for issue creation.
2. **STATE machine-maintained schema vs operator superset (MED).** Confirm by reading a *CI-written* STATE
   (an instance `.factory/STATE.md` track-build-log entry produced by the haiku state-manager) whether the
   agent emits only the 6-field core + Track-build-log, validating the two-schema model from P2-1.
3. **`seed/canonical-values.md` + `seed/scope.md` + `seed/sources.md` schemas (LOW).** The SingleSourceOfTruth
   artifact and the seed triad are named/required but their internal structure was not read this round
   (no engine template ships for them — confirm they are pure instance artifacts, consistent with P10).
4. **`_meta/track-summary-spec.md` (LOW).** track-summary.md defers to an instance-side authoritative format
   doc; confirm it is genuinely external to the engine (P10) and not a missed engine template.
5. **PRD §"Core Functionality = What it Eats / Does / Outputs" as a value object (LOW).** The broad doc named
   it; a round could confirm whether the Eats/Does/Outputs triad recurs as a reusable structure across the
   ladder or is PRD-only.

## State Checkpoint
```yaml
pass: 2
round: 1
status: complete
files_read_this_round: 18
timestamp: 2026-06-01T00:00:00Z
novelty: SUBSTANTIVE
next_round_candidates: [WorkItem-pipeline, CI-written-STATE-schema, seed-triad-schema, track-summary-spec, prd-core-functionality-vo]
```
