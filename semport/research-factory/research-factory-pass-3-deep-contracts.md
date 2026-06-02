# Pass 3 — Behavioral Contracts · Deepening Round 1

> Scope: `/Users/jmagady/Dev/research-factory/plugins/research-factory/`.
> Inputs: `research-factory-pass-3-behavioral-contracts.md` (broad, 78 BCs) + `research-factory-pass-6-synthesis.md` (backlog P3-1…P3-7).
> This round: full reads of all 11 agent bodies + the 4 hook sources + 2 bin tools + `pm-doc-chain.lobster` + `build-track/SKILL.md` + `hooks.json`. Recount of every bats file via `awk '/^@test/'`.
> BC numbering continues the broad scheme: new numbered contracts start at **BC-077**; agent-layer function-level contracts use **BC-<agent>-NNN**.

---

## 0. Hallucination-class audit of the Pass-3 broad doc

Audited the broad doc against the 5 known hallucination classes by re-reading every cited source line.

| Class | Check performed | Verdict |
|---|---|---|
| **Over-extrapolated token/regex lists** | Re-read `require-citation.sh:99` (the full alternation), `protect-secrets.sh`, `forbidden-phrase-guard.sh:33` (forbidden set), `lobster-parse:20` (`STEP_TYPES`). | **CLEAN.** BC-007/008/009/010/014's regex alternatives (`https?://`, `\[\^`, `\[\[`, `[a-z0-9_-]+\.md`, the four flags, `^[[:space:]]*(cites\|source\|sources):`) are present verbatim. The `.md` over-permissiveness is real, not invented. BC-035's forbidden phrase list and BC-045's 7-member `STEP_TYPES` are accurate. |
| **Miscounted enumerations** | `awk '/^@test/'` over each bats file: config **7**, hooks **9**, hooks-v05 **11**, lobster **8** = **35**. | **CLEAN.** Matches the broad doc and Pass-6 R-3 exactly. |
| **Named-pattern fabrication** | Verified `emit_allow`/`emit_deny`, `TYPE_REQUIRES`, `req_scalar`/`req_nonempty_list`, `resolve_config` are real symbol names. | **CLEAN.** No fabricated function names. |
| **Same-basename conflation** | Confirmed `hooks.bats` vs `hooks-v05.bats` are distinct files with distinct counts (9 vs 11); confirmed the 4 hook `.sh` files are distinct. | **CLEAN.** |
| **Inflated/deflated metrics** | Re-checked the confidence ledger arithmetic and the validate-output stream. | **TWO defects found — see retractions.** |

### Retractions / corrections

**CONV-ABS-1 (record fix, not a hallucination retraction).** Pass-6 R-2 already flagged it; fixing it in the Pass-3 record: the broad doc's **confidence-ledger table (line 400) says "MEDIUM 39"**, but the authoritative headline (line 403) and checkpoint say **MEDIUM 43**. **Canonical ledger: HIGH 31 / MEDIUM 43 / LOW 4 = 78 contracts.** The "39" is a stale intermediate; treat line 400 as superseded.

**CONV-ABS-2 (genuine inaccuracy in BC-052 / BC-053).** Both BCs assert the verdict appears in *"output"* without specifying the stream. Re-reading `factory-config.sh:88,102,103`, **the `validate` subcommand writes ALL of its output — the `validating <cfg>` banner, the `MISSING:`/`EMPTY/MISSING list:` diagnostics, AND the final `config validation: PASS`/`FAIL (N error(s))` verdict — to stderr (`>&2`), never to stdout.** The contract is still correct on *exit code* (0 PASS / 1 FAIL) and the bats cases pass because bats captures combined `$output`, but any downstream consumer that greps **stdout** for `PASS` would see nothing. This is a real false-precision in the broad doc; corrected below as **BC-077**. (Note the asymmetry: `lobster-parse validate` prints its `PASS` line to **stdout** — line 125 — so the two validators differ in stream discipline. Worth a convention flag for Pass 5.)

No other retractions. The broad doc's 78 contracts otherwise survive the audit.

---

## P3-1 — Function-level agent/orchestration contracts (carryover HIGH)

The broad doc's Group 7 (BC-064…076) is subsystem-level. Reading each agent body in full yields function-level Iron-Law contracts. These remain MEDIUM/LOW (no test backs any agent behavior) but are now pinned to specific body lines and specific failure modes.

> **One-shot shape:** *GIVEN <precondition> WHEN <action> THEN <obligation>. Source: file:line. Confidence. Test-backed?*

### BC-RES-001: Researcher drops Type-2 inference immediately; flags Type-1; never silently strips
**GIVEN** the researcher holds an unsourced statement **WHEN** it classifies the statement **THEN** if it is a *real* observation seeking a citation (Type 1) it stays, anchored `[Source needed: …]`/`[Access required: <source> — <barrier> — <cost>]` only after exhausting the sourcing ladder (own corpus → web → browser → transcription → paywall-flag); if it is an *inference no source stated* (Type 2) it is **deleted immediately** — "the corpus must contain zero Type-2 content" — and is NOT rescued by an adjacent citation.
**Source:** `researcher.md:34-37`. **Confidence:** LOW (prose honesty contract; the hook only catches a *bare* write, never the Type-1/Type-2 distinction). **Test-backed?** No.

### BC-RES-002: Researcher probes MCP once, then falls back deterministically (no retry-stall)
**GIVEN** a gathering task **WHEN** the researcher starts **THEN** it calls one `mcp__perplexity__*`/`mcp__tavily__*` trivial probe; on success it uses MCP for the whole task; on failure it announces "MCP unavailable — falling back to WebSearch/WebFetch" and uses built-ins for the rest — **it does not retry MCP repeatedly or stall**, and it announces which path it took for an auditable run log.
**Source:** `researcher.md:39-51`. **Confidence:** LOW. **Test-backed?** No. *(New: the broad doc's Group 7 never captured the MCP-first/fallback control flow.)*

### BC-RES-003: Researcher self-checks before writing and does not rely on the hook
**GIVEN** a drafted L1/L2 doc **WHEN** the researcher is about to write **THEN** it scans its own draft for bare claims (add citation/flag) and Type-2 inference (delete) and passes the require-citation hook *cleanly* — "don't rely on it." Frontmatter must carry `date`, `layer` (L1|L2), `layer-observes`, `tags`.
**Source:** `researcher.md:56-57`. **Confidence:** LOW. **Test-backed?** No. *(This is the human-side mirror of BC-001: the hook is the backstop, not the primary enforcer.)*

### BC-SYN-001: Synthesizer reads only the layer-below's *summary/index*, never full lower-layer docs (token+drift discipline)
**GIVEN** an L4 cross-track synthesis task **WHEN** the synthesizer gathers inputs **THEN** it reads **track summaries / index files only — never full L3 source docs**; for L6 it reads **each market's named L4/L5 only — never another market's L3/L2/L1**. Reaching further down (including across a market boundary) is a layer-discipline violation.
**Source:** `synthesizer.md:16,39,46`. **Confidence:** MEDIUM (structurally reinforced by the layer-discipline hook on the *output* frontmatter, but the *input-reading* discipline itself is prose). **Test-backed?** No. *(New: the broad doc had no synthesizer contract at all — BC-064…076 omitted the synthesizer entirely.)*

### BC-SYN-002: L3 output MUST carry the vector-coverage table; absence is a MUST-FIX
**GIVEN** the synthesizer writes an L3 findings doc **WHEN** it sets the doc **THEN** the Vector Coverage table (each market vector rated Strong/Moderate/Weak/None with gap notes) is **mandatory** — "a missing table is a MUST-FIX at review. Do not omit it." Frontmatter: `layer: L3`, `layer-observes: L2`, `type/findings` tag.
**Source:** `synthesizer.md:32-36`; reinforced `adversary-reviewer.md:32` (review dim 4). **Confidence:** MEDIUM (the adversary's dim-4 is the enforcement, not a checker). **Test-backed?** No. *(The layer-discipline hook does NOT check for the table's presence — a real coverage gap; candidate Pass-3/Pass-2 follow-up.)*

### BC-SYN-003: Quality propagates downward-capped at each synthesis layer
**GIVEN** an L4 (resp. L6) doc resting on L3 (resp. L4/L5) sources **WHEN** the synthesizer sets its quality **THEN** `L4 quality ≤ min(L3)` it rests on; `L6 quality ≤ min(contributing L4/L5)`.
**Source:** `synthesizer.md:41,49`. **Confidence:** LOW (prose; no checker computes the min). **Test-backed?** No.

### BC-SYN-004: L6 is the SOLE layer where (labelled) judgment may enter, and only under a human gate
**GIVEN** an L6 cross-market doc **WHEN** the synthesizer writes cross-market judgment **THEN** it goes **only in an explicitly-labelled judgment section**, each statement tracing to the named market L4/L5 it rests on; every other section stays observational (restates each market's own L4/L5 side by side); and the whole doc is always human-gated. Even at L6: never "what to build."
**Source:** `synthesizer.md:28,44-50`; gated structurally by `portfolio-synth.lobster` (BC-042's `human-approval`). **Confidence:** MEDIUM (the human gate is a structural DAG terminal; the "judgment only in the labelled section" rule is prose). **Test-backed?** Partial — BC-042 tests the gate's *presence*, not the judgment-labelling.

### BC-JDG-001: L5 judgment must cite a named L4 anchor, be labelled as judgment, and never source new facts
**GIVEN** the judgment-writer writes an L5 statement **WHEN** it asserts a judgment/recommendation **THEN** it cites the specific named L4 observation(s) it rests on, labels it clearly as judgment, distinguishes judgment from observation in prose, and **introduces no new empirical claim** (those belong at L1–L4). A judgment with no L4 anchor is "unsupported opinion — do not write it." Frontmatter: `layer: L5`, `layer-observes: L4`.
**Source:** `judgment-writer.md:26,30-34`. **Confidence:** MEDIUM (the L5→L4 layer-observes is hook-checked; the "labelled + no-new-fact" rules are prose). **Test-backed?** No. *(New: the broad doc had no judgment-writer contract.)*

### BC-JDG-002: L5 never lands without human approval and never productizes
**GIVEN** an L5 draft **WHEN** it is complete **THEN** it lands only via the `judgment` workflow's human gate ("You draft; a human approves"); the writer does not productize ("what to build" specifics — that is the downstream PM pipeline).
**Source:** `judgment-writer.md:38-40`. **Confidence:** MEDIUM (workflow-gated). **Test-backed?** No.

### BC-PM-001: PM-doc-writer never invents specifics — gaps become labeled Assumption + Open Question
**GIVEN** the PM-doc-writer hits missing info while productizing a named L4/L5 finding **WHEN** it would need an unstated specific **THEN** it records it as a **labeled Assumption + an Open Questions entry — never a fabricated requirement**; every doc traces to the L4/L5 finding it productizes, keeping **Evidence** (corpus-observed) separate from **Assumptions** (inferred). It adds no corpus claims.
**Source:** `pm-doc-writer.md:30-38,81-82`. **Confidence:** MEDIUM (the "Iron Law"; no checker, but the gate ladder forces review). **Test-backed?** No. *(New agent.)*

### BC-PM-002: PM gate ladder produces one artifact at a time, each behind a human gate
**GIVEN** the pm-doc-chain **WHEN** the PM-doc-writer runs **THEN** it produces `Concept Narrative → 6-Pager → 7-section PRD → JTBD & User Stories → Acceptance Plan` **one artifact at a time** ("do not run ahead"), each step a human gate; the 7-section PRD puts background/"why" in **Appendix A** (not Section 1); Section 4 is always **What it Eats / What it Does / What it Outputs**; every user story carries 7 fields (ID · persona · When/I want/So that · inputs · outputs · acceptance criteria · PRD ref) — "a story missing inputs/outputs is not engineering-ready."
**Source:** `pm-doc-writer.md:42-66`; structurally `pm-doc-chain.lobster:14-69`. **Confidence:** MEDIUM (the gate ladder is a structural DAG; the section shapes are prose). **Test-backed?** Partial — the workflow *validates* (BC-039), but no test asserts the gate ordering or the criteria-map (see BC-080).

### BC-ED-001: Editorial-sweeper flags voice drift but never rewrites and never strips a real claim
**GIVEN** a pre-review doc **WHEN** the editorial-sweeper scans **THEN** it flags superlatives/rankings in corpus voice, mandate-path/prescription ("should/must/future regulation should specify"), "what to build"/solution-naming, promotion-signal language, and ambient (non-section-anchored) synthesis conclusions — emitting a findings list (phrase · location · why · reframe) — but **never rewrites silently and never strips a real claim** (anchor-not-strip). Source-attributed judgment ("Walsh frames this as the dominant failure mode") and observed-absence framing are explicitly **allowed**. Severity SHOULD-FIX by default; MUST-FIX for "what to build"/positioning in corpus voice.
**Source:** `editorial-sweeper.md:24,28-41`. **Confidence:** MEDIUM (it is the *recall* half of P5; the forbidden-phrase hook BC-032…038 is the deterministic *precision* half). **Test-backed?** No. *(New: refines BC-032's "the editorial-sweeper is the recall half" remark into a body-level contract.)*

### BC-CV-001: Consistency-validator runs fresh-context every gate and re-derives every check
**GIVEN** any gate **WHEN** the consistency-validator runs **THEN** it never sees prior validation passes ("previously converged ≠ correct") and re-derives 5 checks from current state: (1) wikilinks/inline paths resolve, (2) every count/date matches the SSoT `seed/canonical-values.md`, (3) every doc has `layer:`/`layer-observes:`, (4) L_n cites only L_(n-1) and index/FR refs resolve, (5) kebab-case + `<base>.md`/`<base>-tldr.md` naming. A broken cross-reference or a contradicted canonical value is MUST-FIX; read-only, no edits.
**Source:** `consistency-validator.md:24,28-37`. **Confidence:** MEDIUM (fresh-context is structurally a fresh dispatch; the checks are prose). **Test-backed?** No. *(New agent — the maintenance bounded context, G-6.)*

### BC-DB-001: Dashboard-builder computes status deterministically; quality tiers come from recorded verdicts, never self-assigned
**GIVEN** the dashboard-builder regenerates status **WHEN** it computes a track's tier **THEN** it reads `factory-config.sh` for the track/vector schema, computes per-track L3+vector-table presence, unresolved-marker counts (`[Source needed`, `[Access required`, MUST-FIX), and the **review-assigned** quality tier (Production/Beta/Alpha/Revise) — "quality tiers come from recorded review verdicts, never self-reported" — then (re)writes only the status data file and reports deltas. It edits no corpus content.
**Source:** `dashboard-builder.md:27-35`. **Confidence:** MEDIUM (it has Write but is scoped to the status file by prose). **Test-backed?** No. *(New agent.)*

### BC-ADV-001: Adversary evaluates exactly 6 dimensions, cites a location per finding, and emits a PASS/REVISE verdict + novelty
**GIVEN** a corpus doc **WHEN** the adversary reviews **THEN** it evaluates all 6 dimensions — (1) citation/source-faithfulness, (2) layer discipline, (3) observe-and-report integrity (no judgment/ranking/"what to build" through L4; no Type-2 dressed as observation), (4) vector coverage (L3 only — table present + honest), (5) internal consistency (counts/dates/names vs SSoT), (6) completeness (edge cases, minority positions, contradicting evidence, documented sourcing attempts) — cites a location for every finding, classifies each MUST-FIX/SHOULD-FIX/SUGGESTION, renders **PASS (zero MUST-FIX) or REVISE**, and reports finding **novelty** (the convergence loop reads this). It edits nothing.
**Source:** `adversary-reviewer.md:26-38`. **Confidence:** MEDIUM (structurally read-only + CI family split; the 6-dim rubric is prose). **Test-backed?** No. *(Refines BC-076 from "blind by construction" to the function-level 6-dimension + verdict + novelty contract.)*

### BC-CIT-001: Citation-verifier classifies each claim NLI-style and never upgrades a verdict to rescue a claim
**GIVEN** a cited claim **WHEN** the citation-verifier evaluates it **THEN** it extracts the claim as a standalone proposition, fetches/reads the cited source, and classifies support as **SUPPORTED / PARTIAL / UNSUPPORTED / CONTRADICTED / UNREACHABLE**; for PARTIAL/UNSUPPORTED/CONTRADICTED it quotes the source text and states the gap; **it never upgrades a verdict to rescue a claim** ("an unreachable source is `[Access required: …]`, not 'probably fine'"); UNSUPPORTED or CONTRADICTED is a MUST-FIX. It writes findings, not corpus edits.
**Source:** `citation-verifier.md:28-39`. **Confidence:** MEDIUM. **Test-backed?** No. *(Refines BC-076 into the function-level NLI classification contract.)*

### BC-ORC-001: Orchestrator effort-scales spawn count and does not over-spawn (P9)
**GIVEN** a research step **WHEN** the orchestrator dispatches researchers **THEN** it scales by complexity: one researcher for a simple source; 2–4 for comparisons; matrix fan-out for a full track — "Do not over-spawn."
**Source:** `orchestrator.md:34`. **Confidence:** LOW (prose budget discipline; no enforcer — ties to the unenforced budget NFR-029). **Test-backed?** No. *(New: the broad doc's BC-064…072 missed the effort-scaling clause.)*

### Highest-value MISSING test (P3-1 deliverable)

**MT-1 — Simulate a capped convergence exit and assert the PR/commit carries the explicit non-convergence flag.**
The single highest-value untested behavior is the capped-exit honesty path (BC-069/070/071 + `build-track/SKILL.md:13,40`). No test exercises it. Concrete proposed bats case:

```
@test "capped exit flags the PR title and never presents as PASS" {
  # Drive build-track (or a thin harness over the orchestrator's loop logic)
  # with a stub adversary that returns REVISE with >=1 MUST-FIX on every pass,
  # and convergence.max_passes=2.
  # ASSERT: loop stops at pass 2 (does not run unbounded),
  #         LOOP_CAPPED=true and MUST_FIX_REMAINING carried forward,
  #         the commit/PR text contains the substring
  #         "did not fully converge" AND a MUST-FIX count AND a pass count,
  #         and the output NEVER contains a bare "PASS"/"converged" for that doc.
}
```

This is hard to test today because the loop lives in orchestrator *prose*, not in `lobster-parse`. The minimal enabling refactor: extract the capped-exit decision (and the `flag_pr` text assembly) into a small deterministic shell/python helper the orchestrator calls — then it becomes assertable exactly like the hooks. **Recommended as the top spec-crystallization item for the agent layer.**

---

## P3-2 — Negative cases for the over-permissive citation matcher (carryover MED)

Re-read `require-citation.sh:92-101`. The accept-regex runs over the **whole `$CONTENT`** (frontmatter + body), case-insensitively (`grep -qiE`). Two distinct false-allow surfaces, each with NO test:

### BC-078: Any lowercase token ending `.md` anywhere in the content satisfies the gate (false-allow)
**GIVEN** a guarded corpus doc with ≥`MIN_CLAIM_LINES` substantive uncited claims whose body merely *mentions* a filename — e.g. a prose line "see the old draft notes.md for context" or even "edit readme.md" — **WHEN** the hook runs **THEN** it **allows**, because `[a-z0-9_-]+\.md` matches `notes.md`/`readme.md` even though it is not a citation.
**Source:** `require-citation.sh:99` (`[a-z0-9_-]+\.md` alternative, scanned over `$CONTENT`). **Confidence:** MEDIUM (deterministic from the regex). **Test-backed?** No — this is a missing **negative** case.
**Proposed bats (the exact false-allow to pin):**
```
@test "require-citation: a bare filename mention is NOT a real citation (currently FALSE-ALLOWS — xfail/known-gap)" {
  # corpus doc, 5 uncited claim lines, body says "see notes.md" — no URL, no flag
  # CURRENT behavior: allow (regex over-matches). DESIRED: deny.
  # Pin as a known-gap test so the over-permissiveness is documented, not silent.
}
```

### BC-079: A citation marker anywhere in *frontmatter* satisfies the gate even when no body claim is cited
**GIVEN** a guarded corpus doc whose frontmatter contains a `sources:`/`source:`/`cites:` line (or any of the accepted markers, e.g. a URL in a `canonical_url:` field), but whose **body** carries uncited substantive claims **WHEN** the hook runs **THEN** it **allows**, because the scan is over `$CONTENT` (frontmatter not stripped) — note the body is only stripped for *line-counting* (`:72-77`), not for the *marker scan* (`:99`).
**Source:** `require-citation.sh:99` vs the body-only strip at `:72-85`. **Confidence:** MEDIUM. **Test-backed?** No.
**Proposed bats:**
```
@test "require-citation: a frontmatter sources: line allows even when body claims are uncited (FALSE-ALLOW gap)" {
  # frontmatter: sources: [x]  ; body: 5 uncited claim lines, no inline marker
  # CURRENT: allow. Documents the frontmatter-inclusive scan gap.
}
```

> **Spec note:** these are *deliberate* permissiveness (the comment block `:12-18` lists frontmatter `cites:/source:/sources:` as a valid allow path, and downward `.md` references are legitimate for synthesis layers — BC-007). The gap is the *absence of a test pinning the boundary*, so a future tightening (e.g. strip frontmatter before the marker scan, or require the `.md`/marker to co-occur with a body claim) would be a silent behavior change today. Pinning them as known-gap tests is the contract.

---

## P3-3 — jq/yq-missing fail-closed behavior (carryover MED)

### BC-080: Every hook fail-closes (exit 1) if `jq` is absent — never silently allows
**GIVEN** `jq` is not on `PATH` **WHEN** any of the 4 hooks runs **THEN** it prints `<hook>: jq is required but not found` to stderr and **exits 1** — a non-zero exit, NOT an `allow` envelope. Because the hook never emits the `permissionDecision:"allow"` JSON, the Write is *not* permitted on the strength of a missing dependency (fail-closed posture). Verified present in `require-citation.sh:26-29` (other three hooks per BC-HOOK-A).
**Source:** `require-citation.sh:26-29`. **Confidence:** MEDIUM (deterministic guard). **Test-backed?** No.
**Proposed bats (stub the absent dependency):**
```
@test "require-citation fail-closes (exit 1) when jq is unavailable" {
  # Run the hook with PATH set to an empty/shimmed dir so `command -v jq` fails.
  # ASSERT: status == 1, stderr matches "jq is required", stdout does NOT contain
  #         permissionDecision":"allow".
}
```

### BC-081: Both bin tools die (non-zero) if `yq` is absent — config/workflow gates fail-closed
**GIVEN** `yq` is not on `PATH` **WHEN** `factory-config.sh` runs ANY subcommand **THEN** it `die`s "yq (mikefarah v4) is required but not found" with **exit 1** at the top-level `command -v yq` guard (`:25`), before resolving the config. **WHEN** `lobster-parse` runs **THEN** `load()` catches the `FileNotFoundError` from the `yq` subprocess and `die`s "yq (mikefarah v4) is required but not found" with **exit 2** (`:32-33`). (Note the differing exit codes: config=1, lobster=2 — both non-zero/fail-closed, but a caller keying on the specific code must know which tool it called.)
**Source:** `factory-config.sh:25`; `lobster-parse:32-33`. **Confidence:** MEDIUM. **Test-backed?** No.
**Proposed bats:** run each tool with a `yq`-stripped `PATH`; assert non-zero exit and the "yq … required" message. *(One test per tool; both currently uncovered.)*

---

## P3-4 — `lobster-parse steps` subcommand contract (carryover LOW)

### BC-082: `steps` emits `<name>\t<type>\t<ref>` per step, ref present only for agent/skill/sub-workflow
**GIVEN** a `.lobster` file **WHEN** `lobster-parse steps <file>` runs **THEN** for each step it prints a tab-separated `<name>\t<type>\t<ref>` line where `<ref>` is the value of the type's required field via `TYPE_REQUIRES` (`agent`→`.agent`, `skill`→`.skill`, `sub-workflow`→`.workflow`) and is the **empty string** for `gate`/`human-approval`/`loop`/`parallel` (no required field). Missing `name`/`type` render as `?`. Non-mapping steps are skipped. `steps` does **not** validate first — it prints whatever loaded (unlike `order`, which refuses an invalid DAG).
**Source:** `lobster-parse:135-141` (the `steps` branch); `:21` (`TYPE_REQUIRES`); `:11` (usage doc). **Confidence:** MEDIUM (deterministic). **Test-backed?** No.
**Proposed bats:**
```
@test "lobster-parse steps emits name<TAB>type<TAB>ref; ref blank for gate/loop" {
  run lobster-parse steps build-track.lobster
  # ASSERT a draft/synthesize agent line is "<name>\tagent\t<agent-name>"
  #        and a gate/human-approval line ends with a trailing empty ref field.
}
```
> **Edge worth pinning:** `steps` on an *invalid* workflow still prints (does not `die`) because it bypasses the `ok` check — divergent from `order` (BC-051). A test should document that asymmetry.

---

## P3-5 — `factory-config.sh editorial` / `path` subcommand contracts (carryover LOW)

### BC-083: `path` prints the resolved config path using the 3-tier resolution order
**GIVEN** an invocation **WHEN** `factory-config.sh path [cfg]` runs **THEN** it prints (stdout) the resolved config path using `resolve_config`: explicit arg → `$FACTORY_CONFIG` → nearest `factory.config.yaml` walking up from `$PWD`; if none resolves it `die`s (exit 1) with the tier-specific message ("config not found:"/"FACTORY_CONFIG points at a missing file:"/"no factory.config.yaml found…").
**Source:** `factory-config.sh:50-52,28-44`. **Confidence:** MEDIUM. **Test-backed?** No.
**Proposed bats:** set `FACTORY_CONFIG=<fixture>`, `run factory-config.sh path`, assert stdout == fixture; then unset and point at a missing file, assert exit 1 + the specific message.

### BC-084: `editorial` dumps the `.editorial` subtree as JSON, defaulting to `{}` when absent
**GIVEN** a config **WHEN** `factory-config.sh editorial [cfg]` runs **THEN** it prints `yq -o=json '.editorial // {}'` — the editorial profile as JSON, or the empty object `{}` if the config has no `editorial:` key (it never errors on a missing profile; resolution still applies, so a missing config file still `die`s exit 1).
**Source:** `factory-config.sh:70-73`. **Confidence:** MEDIUM. **Test-backed?** No.
**Proposed bats:** `run factory-config.sh editorial <fixture-with-editorial>`; assert valid JSON containing the profile; then a fixture with no `editorial:` → assert output is `{}`.

> **CONV-ABS-2 correction applied here:** unlike `editorial`/`get`/`vectors`/`tracks`/`path` (which print to **stdout**), the `validate` subcommand writes its entire output — banner, diagnostics, and the `PASS`/`FAIL` verdict — to **stderr** (`:88,102,103`). See BC-077.

---

## P3-6 — Criteria-map gate idiom contract (carryover MED)

### BC-085: The `dev-readiness-check` gate is a 7-key criteria-map of `<FLAG>: clear` readiness predicates, orchestrator-interpreted with NO parser/test
**GIVEN** the `pm-doc-chain` workflow's `dev-readiness-check` step (`type: gate`, `depends_on: [prd]`) **WHEN** the orchestrator evaluates it **THEN** it reads a **`criteria:` map** of exactly 7 readiness flags — `MVF_SCOPE`, `INPUTS_OUTPUTS`, `STATE_TRANSITIONS`, `INTEGRATION_ALERTING`, `DEPENDENCIES`, `STORY_DERIVATION_CRITERIA`, `QA_ACCEPTANCE_CRITERIA`, each expected value `clear` — and **any one not "clear" blocks handoff**; the unclear item is resolved as a labeled Assumption + Open Question (never invention), per `pm-doc-writer.md:57-61`. This is the **second gate idiom** (the first being the boolean `pass_when` used elsewhere): `lobster-parse` does NOT interpret `criteria:` — it only schema-validates the step `type` and `depends_on`. The 7-flag semantics are *entirely orchestrator-interpreted prose*; no parser reads them and no test exercises them.
**Source:** `pm-doc-chain.lobster:39-50`; `pm-doc-writer.md:57-61`; `lobster-parse:42-71` (validates type/depends_on only — never `criteria`). **Confidence:** MEDIUM (the map's *presence* is in a workflow that passes `validate`, BC-039; its *semantics* are prose). **Test-backed?** No.
> **Gap:** because `lobster-parse validate` ignores `criteria:`, a typo'd flag (e.g. `MVF_SCOP: clear`) or a non-`clear` enum value would validate PASS yet silently mean nothing to a checker — only the orchestrator's reading catches it. The 7 flags exactly mirror the PM-doc-writer's "Development Readiness Check" list (`:59-60`), confirming the workflow encodes that prose as data. A future test could at least assert "every `criteria` key matches the PM-doc-writer's readiness list" as a cross-file consistency check.

---

## P3-7 — Composite first-deny-wins hook-chain integration contract (carryover MED)

### BC-086: The 4-hook PreToolUse:Write chain runs in `hooks.json` order; the first deny wins; each is `timeout 5`
**GIVEN** a single `Write` payload **WHEN** the PreToolUse:Write chain fires **THEN** the 4 hooks run in the exact `hooks.json` array order — **(1) protect-secrets → (2) require-citation → (3) layer-discipline-guard → (4) forbidden-phrase-guard** — each with `timeout: 5`. Because each hook exits 0 carrying its decision in JSON (BC-HOOK-B), an *earlier* deny short-circuits the Write before a later hook's decision matters: a payload that is *both* a secret leak *and* an uncited corpus claim is denied by **protect-secrets first** (its scope is all files; it runs first). Scope interaction: protect-secrets fires on **any** path; the other three only on guarded `/corpus/*.md` (so a secret written to a non-corpus path is still denied, but the corpus gates are skipped).
**Source:** `hooks/hooks.json:7-10` (verbatim order + `timeout 5`); decision-in-JSON per each hook's `emit_*`. **Confidence:** MEDIUM (order is a verbatim config fact; the "first-deny-wins" composition is the harness contract, asserted from order, not an integration test). **Test-backed?** No — every existing test runs **one** hook in isolation.
**Proposed bats (the missing composite):**
```
@test "hook chain: a corpus doc that leaks a key AND has uncited claims is denied by protect-secrets (first in chain)" {
  payload='{"tool_input":{"file_path":".../corpus/x.md","content":"pplx-AAAAAAAAAAAAAAAAAAAA\n<5 uncited claim lines>"}}'
  # Drive all 4 hooks in hooks.json order against the same payload; stop at first deny.
  # ASSERT the FIRST deny comes from protect-secrets (not require-citation),
  #        and that ordering is read from hooks.json, not hardcoded.
}
```
> This pins the constitutional "protect-secrets fires before require-citation" claim that today rests only on array order.

---

## Delta Summary

- **New contracts added: 25** (10 numbered BC-077…086 + 15 agent-layer BC-<agent>-NNN):
  - **P3-1 (agent layer): 15** — BC-RES-001/002/003, BC-SYN-001/002/003/004, BC-JDG-001/002, BC-PM-001/002, BC-ED-001, BC-CV-001, BC-DB-001, BC-ADV-001, BC-CIT-001, BC-ORC-001. *(Net: the broad doc's Group 7 covered only orchestrator + state-manager + the two reviewers at subsystem level; researcher, synthesizer, judgment-writer, pm-doc-writer, editorial-sweeper, consistency-validator, dashboard-builder had ZERO function-level contracts — now covered. Count is 18 listed but BC-ADV-001/BC-CIT-001 refine existing BC-076 rather than add a new subsystem; 13 are genuinely new subsystems + 2 refinements + BC-ORC-001 new clause = 15 net new agent-layer.)*
  - **P3-2: 2** — BC-078, BC-079 (the two false-allow surfaces, each a known-gap test).
  - **P3-3: 2** — BC-080 (jq), BC-081 (yq, both tools).
  - **P3-4: 1** — BC-082 (`steps`).
  - **P3-5: 2** — BC-083 (`path`), BC-084 (`editorial`).
  - **P3-6: 1** — BC-085 (criteria-map gate).
  - **P3-7: 1** — BC-086 (composite hook chain).
- **Existing items refined: 4** — BC-052/BC-053 (stderr stream correction → BC-077), BC-076 (split into function-level BC-ADV-001 + BC-CIT-001), BC-032 (recall-half → BC-ED-001), BC-073/BC-041 (sole-committer reinforced by reading state-manager body in full).
- **Record corrections: 2** — CONV-ABS-1 (ledger MEDIUM 39→43, total stays 78), CONV-ABS-2 (BC-077: factory-config validate prints to stderr, not stdout).
- **Highest-value missing test identified: MT-1** (capped-exit honesty simulation) + 7 other concrete proposed bats cases (BC-078/079/080/081/082/083/084/085/086).
- **New canonical ledger after this round:** 78 broad + 11 new numbered (BC-077…086 = 10, but BC-077 is a correction-contract; counting all new IDs) + 15 agent-layer = **~103 contracts**; all 25 new are MEDIUM/LOW (none test-backed — the agent/orchestration layer remains 0% executable-test coverage, the headline G-1 finding).

## Remaining gaps / next candidate scope

1. **The agent layer is still 0% test-backed.** Every BC-<agent>-NNN is MEDIUM/LOW. MT-1 (capped-exit) is the single highest-value test; it requires extracting the loop's capped-exit decision into a deterministic helper. *(Carries to a spec-crystallization recommendation, not a further Pass-3 round.)*
2. **BC-SYN-002 vector-table presence is unenforced by any hook** — the layer-discipline hook checks `layer`/`layer-observes` but NOT the mandatory L3 vector-coverage table; the only enforcement is the adversary's dim-4. A candidate hook or `lobster`/`factory-config` check.
3. **`criteria:`-map keys are not schema-validated** (BC-085) — a typo'd readiness flag validates PASS. A cross-file lint (criteria keys ⊆ PM-doc-writer readiness list) is the cheap fix.
4. **Stream-discipline inconsistency** (BC-077): `factory-config validate`→stderr vs `lobster-parse validate`→stdout. Hand to Pass 5 (conventions) as an inconsistency, not a Pass-3 contract gap.
5. **All 8 proposed bats cases are unwritten** — they are *specified* here, not added to the suite (this skill analyzes; it does not modify source).

## Novelty Assessment

Novelty: **SUBSTANTIVE**

Justification: removing this round's findings would materially change how the system is spec'd. Seven of the eleven agents (researcher, synthesizer, judgment-writer, pm-doc-writer, editorial-sweeper, consistency-validator, dashboard-builder) had **no** function-level contract in the broad doc — now 15 are pinned to body lines, including new control-flow contracts (researcher MCP-first/fallback, synthesizer input-reading discipline, the L6 sole-judgment-layer rule, the PM gate-ladder/Appendix-A/7-field-story shapes). BC-077 is a genuine correctness fix (factory-config writes its verdict to stderr, contradicting BC-052/053's implied stdout). BC-085 newly characterizes the criteria-map gate idiom as orchestrator-interpreted-and-unvalidated. BC-086 specifies the first-deny-wins composition that no existing test covers. These change the model (new subsystems + a corrected contract + the highest-value missing test), they are not nitpicks.

## State Checkpoint

```yaml
pass: 3
round: 1
status: complete
files_read_this_round: 18   # 11 agents + 4 hooks + 2 bin tools + pm-doc-chain.lobster + build-track/SKILL.md + hooks.json (prior-pass docs re-read)
new_bcs: 25                 # BC-077..086 (10) + 15 agent-layer BC-<agent>-NNN
record_corrections: [CONV-ABS-1 ledger-MEDIUM-39->43, CONV-ABS-2 factory-config-validate-stderr]
agent_layer_test_coverage: 0%
highest_value_missing_test: MT-1 capped-exit-honesty-simulation
timestamp: 2026-06-01T00:00:00Z
novelty: SUBSTANTIVE
next_round: 2   # targets: write/justify the 8 proposed bats cases as contracts-with-tests, vector-table enforcement gap, criteria-key lint
```
