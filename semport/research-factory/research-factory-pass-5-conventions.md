# Pass 5: Convention & Pattern Catalog — research-factory engine

> Scope of record: `/Users/jmagady/Dev/research-factory/plugins/research-factory/` (the plugin = the engine) + repo-root `CLAUDE.md` (the engine's own conventions doc).
> Builds on Pass 0 (inventory, 64 files / ~3,631 LOC), Pass 1 (7 engine layers, 2 execution surfaces), Pass 2 (domain model), Pass 3 (78 behavioral contracts).
> Every convention below is grounded in source read this pass (all 11 agent frontmatters, `build-track.lobster`, `pm-doc-chain.lobster`, `forbidden-phrase-guard.sh`, `hooks.json`, `run-all.sh`, `hooks-v05.bats`, 3 command files, 2 SKILL frontmatters, `L3-findings.md` template, `lobster-parse` STEP_TYPES, `state-manager.md`, `adversary-reviewer.md`, `git log -25`). No fabrication.
>
> **Consistency scale used throughout:** **CONSISTENT** = applied everywhere the pattern is applicable, no exceptions found · **MOSTLY** = applied with a small number of deliberate, explainable exceptions · **INCONSISTENT** = partially adopted / divergent / aspirational.

---

## What "convention" means in this codebase

This engine has almost no runtime code (Pass 1): the "program" is a contract distributed across declarative substrates. So its conventions are not API-style coding conventions — they are **structural conventions of a declarative system**: directory-as-registry layout, Markdown-as-agent frontmatter schemas, the `.lobster` DSL idioms, fail-closed Bash-hook shape, bats test shape, and the state/commit discipline encoded in `CLAUDE.md`. The conventions ARE the architecture's enforcement surface — they are how "config + seed, never code" (P10) and the constitution (P1–P10) are kept honest. The single most important meta-convention: **a convention here is usually also an invariant** (e.g. "one agent per file" is also "the registry is the directory").

One-shot example of the catalog-entry shape used below:

> ### CV-000: <convention name>
> **Rule:** <the convention stated as a rule>.
> **Example:** `<file>:<lines or construct>`.
> **Consistency:** CONSISTENT | MOSTLY | INCONSISTENT — <evidence / exceptions>.

---

## 1. Naming conventions

### CV-001: kebab-case for all files, slugs, agent/workflow/skill/command names
**Rule:** every file, directory, market `slug`, track `slug`, agent `name`, workflow `name`, and skill `name` is kebab-case. This is stated as a project rule in `CLAUDE.md` ("Files & slugs: kebab-case") and held everywhere.
**Example:** agents `adversary-reviewer.md`, `citation-verifier.md`, `pm-doc-writer.md`; workflows `cross-track-synth.lobster`, `portfolio-synth.lobster`; skills `build-track`, `init-market`; the `slug` config key drives `corpus/<track-slug>/`, branch names `claude/<track>-*`, and `instance-outputs/<slug>/` (Pass 2 §2a.6).
**Consistency:** CONSISTENT — all 11 agent filenames, all 7 `.lobster` filenames, both skill dir names, all 3 command filenames, all 5 doc filenames (`FACTORY.md` etc. use SCREAMING for top-level docs but multi-word ones are kebab: `LAYER-MODEL.md`, `FACTORY-SOUL.md`). No camelCase or snake_case file/slug found anywhere in the plugin.

### CV-002: agent `name` field === filename stem
**Rule:** each agent's frontmatter `name:` exactly matches its filename without `.md`, and the workflow `agent:` reference uses that same string. This is what makes the directory a registry — the name is the dispatch key.
**Example:** `agents/state-manager.md` → `name: state-manager` → referenced as `agent: state-manager` in `build-track.lobster:66`. Verified across all 11 agents (frontmatter `name` matches stem in every case).
**Consistency:** CONSISTENT — 11/11 agents. Same holds for skills: `skills/build-track/SKILL.md` → `name: build-track`.

### CV-003: layer-tag vocabulary — `Ln` (capital L + digit)
**Rule:** corpus layers are written `L1`…`L6` (capital L, no space, single digit) in frontmatter, prose, hook regex, and templates. The `layer-observes` value is the immediately-lower `L(n-1)` token, or `external`/`L0`/empty for L1.
**Example:** `templates/corpus/L3-findings.md:3-4` (`layer: L3` / `layer-observes: L2`); the layer-discipline guard parses exactly this (`layer-discipline-guard.sh`, Pass 3 BC-015…024); LAYER-MODEL.md uses `L1`…`L6` throughout.
**Consistency:** CONSISTENT — uniform across templates, hooks, agents, docs. L6's `layer-observes` is the one documented multi-value form (`L4/L5 (across markets)`, Pass 2).

### CV-004: layer frontmatter field set — `date`, `layer`, `layer-observes`, `tags`
**Rule:** every corpus LayerDocument carries exactly these four frontmatter fields, with `tags` an array of `topic/<slug>`, `type/<kind>`, `status/<state>` namespaced tags.
**Example:** `templates/corpus/L3-findings.md:1-6` — `tags: [topic/<market-slug>, topic/<track-slug>, type/findings, status/draft]`.
**Consistency:** CONSISTENT across the corpus templates read (L3 verified directly; L2/L4/L6 confirmed via Pass 2's template survey). The `topic/ type/ status/` tag-namespace triple is a stable sub-convention.

### CV-005: BC / traceability ID prefixes
**Rule:** identifiers in the PM ladder use fixed uppercase prefixes for traceability: `INIT · PRD · JTBD · US · AC` (Pass 2 §2a). Behavioral-contract IDs in the *analysis* layer use `BC-NNN` (a Pass-3 convention, not engine source). The lobster gate criteria-map uses SCREAMING_SNAKE flag names.
**Example:** PM IDs from `pm-doc-writer.md` (Pass 2); gate flags `MVF_SCOPE`, `INPUTS_OUTPUTS`, `STATE_TRANSITIONS` at `pm-doc-chain.lobster:43-49`; loop output vars `ADVERSARY_VERDICT`, `MUST_FIX_REMAINING`, `LOOP_CAPPED` at `build-track.lobster:60`.
**Consistency:** MOSTLY — SCREAMING_SNAKE is consistent for gate/loop runtime variables; the PM traceability prefixes are a documented convention in `pm-doc-writer.md` but their enforcement is prose-level (Pass 3 found no test).

---

## 2. Module organization

### CV-006: directory-as-registry plugin layout
**Rule:** the plugin is organized by *kind* into fixed top-level directories — `agents/ workflows/ skills/ commands/ hooks/ bin/ rules/ templates/ docs/ tests/` plus `.claude-plugin/`. `plugin.json` declares only metadata; **everything is discovered by directory convention** (Pass 1 layer A). The only explicit wiring file is `hooks/hooks.json`.
**Example:** `.claude-plugin/plugin.json` (19 LOC, metadata only); discovery confirmed in Pass 0/1.
**Consistency:** CONSISTENT — no agent/skill/command is registered anywhere but by living in its directory. This is the load-bearing organizational invariant.

### CV-007: one-agent-per-file
**Rule:** each subagent is exactly one `.md` file in `agents/`; no file defines two agents, no agent spans two files.
**Example:** 11 files → 11 agents (Pass 0). Verified frontmatter `name` is unique per file.
**Consistency:** CONSISTENT — 11/11.

### CV-008: one-workflow-per-`.lobster`
**Rule:** each pipeline is exactly one `.lobster` file in `workflows/`; the file's top-level `name:` is the workflow id.
**Example:** 7 files → 7 workflows (`build-track`, `ingest-source`, `cross-track-synth`, `judgment`, `portfolio-synth`, `pm-doc-chain`, `maintenance`).
**Consistency:** CONSISTENT — 7/7.

### CV-009: skill = a `SKILL.md` inside an eponymous folder
**Rule:** a user-invocable skill is a directory `skills/<name>/` containing `SKILL.md`, whose frontmatter `name:` matches the folder.
**Example:** `skills/build-track/SKILL.md` (`name: build-track`), `skills/init-market/SKILL.md` (`name: init-market`).
**Consistency:** CONSISTENT — 2/2.

### CV-010: command = a thin router `.md` deferring to a same-named skill/workflow
**Rule:** a command file in `commands/` is 8–9 LOC: frontmatter (`description`, `argument-hint`) + one line invoking the same-named skill (or, for `pm-doc-chain`, the orchestrator + workflow). It holds no behavior.
**Example:** `commands/build-track.md:6` — "Use the `research-factory build-track` skill via the Skill tool." `Arguments: $ARGUMENTS`.
**Consistency:** CONSISTENT — all 3 commands follow the router shape; `argument-hint` present on all 3.

### CV-011: bin = the only general-purpose code, isolated
**Rule:** all general-purpose code (the Python DAG validator, the Bash config validator) lives in `bin/`; the rest of the engine is declarative. `lobster-parse` has no extension and is executable; `factory-config.sh` carries `.sh`.
**Example:** `bin/lobster-parse` (147 LOC Python), `bin/factory-config.sh` (109 LOC Bash).
**Consistency:** CONSISTENT — no general-purpose code leaks into `agents/`, `workflows/`, or `templates/`.

### CV-012: templates mirror their target tree
**Rule:** `templates/` is partitioned by destination — `corpus/` (L2–L6 + track-summary skeletons), `pm/` (the 5 ladder docs), `github-action-templates/` (6 `.yml` + `mcp.json`), `portfolio/` (`manifest.yaml`), `instance-docs/` (`review-spec.md`). Each is copied into an instance, never executed in the engine (Pass 1 layer G).
**Example:** `templates/corpus/L3-findings.md` mirrors a real `corpus/<track>/...-findings.md`.
**Consistency:** CONSISTENT — the partition is clean; hooks exempt `*/templates/*` so placeholder claims in skeletons aren't blocked (Pass 3 BC-006).

---

## 3. Markdown-as-agent pattern

### CV-013: agent frontmatter schema — `name`, `description`, `model`, `color`, `tools`
**Rule:** every agent declares the same five frontmatter fields in (essentially) this order: `name` (kebab id), `description` (a "Use for…" usage hint, often naming the info-asymmetry posture), `model` (`opus`/`sonnet`/`haiku`), `color` (a display color), `tools` (a YAML list — the per-agent capability grant).
**Example (verified across all 11):**
| agent | model | color | (Write?) |
|---|---|---|---|
| orchestrator | sonnet | purple | no Write |
| researcher | sonnet | blue | Write |
| synthesizer | sonnet | blue | Write |
| editorial-sweeper | haiku | yellow | — |
| citation-verifier | opus | green | read-only |
| adversary-reviewer | opus | red | read-only |
| judgment-writer | opus | orange | Write |
| consistency-validator | haiku | cyan | — |
| dashboard-builder | haiku | green | — |
| pm-doc-writer | opus | magenta | Write |
| state-manager | haiku | yellow | Write/Edit/Bash |
**Consistency:** CONSISTENT — 11/11 carry `name/model/color/tools`; all 11 carry `description`. Model assignment is a *deliberate* convention (opus = adversarial/judgment-bearing; sonnet = draft/coordinate; haiku = mechanical/sweep), not incidental — Pass 1 §model-assignment. `color` is purely cosmetic but uniformly present (note: blue and green each reused twice — colors are not unique keys, `name` is).

### CV-014: prose-as-prompt body structure
**Rule:** an agent body is a prompt written as second-person prose ("You are the…"), structured with a small set of conventional `##` sections: a role sentence, **"## Announce at Start"** (a verbatim self-identification line), then role-specific sections (Iron Law / Information Asymmetry / Responsibilities / Boundaries / dimensions).
**Example:** `state-manager.md` — role line, "## Announce at Start" (verbatim quote), "## Iron Law", "## Responsibilities", "## Boundaries". `adversary-reviewer.md` — role line, "## Announce at Start", "## Information Asymmetry", "## The 6 review dimensions", "## Severity & output".
**Consistency:** CONSISTENT for "Announce at Start" (**11/11 agents** carry it, verified). The verbatim-quote self-identification ("say verbatim: > I am the …") is a strong cross-agent convention.

### CV-015: the "Iron Law" / asymmetry-section convention
**Rule:** agents that own a constitutional invariant state it in a bold **"## Iron Law"** section; the two pure reviewers instead use **"## Information Asymmetry (structural, not optional)"** (because their invariant *is* blindness, not a positive law).
**Example:** "## Iron Law" present in 9/11 agents (`editorial-sweeper`, `judgment-writer`, `orchestrator`, `pm-doc-writer`, `researcher`, `state-manager`, `synthesizer`, + skills `build-track`/`init-market`). The 2 without it — `adversary-reviewer`, `citation-verifier` — use "Information Asymmetry" instead (verified via section scan). `dashboard-builder` and `consistency-validator` likewise lean on Announce + Boundaries rather than a named Iron Law.
**Consistency:** MOSTLY — the *naming* varies by role (Iron Law vs Information Asymmetry vs Boundaries), but the *pattern* (a bold bright-line section stating the agent's non-negotiable) is near-universal. The variance is principled, not sloppy.

### CV-016: skill body = Iron Law + Announce + red-flag table
**Rule:** a SKILL.md mirrors the agent body convention — `name`/`description`/`argument-hint` frontmatter, an "## Iron Law" stating the sanctioned-exit honesty contract, an "## Announce at Start" verbatim line, and (for build-track) a red-flag table.
**Example:** `skills/build-track/SKILL.md:11-19` — "## Iron Law" (the capped-exit honesty contract) then "## Announce at Start".
**Consistency:** CONSISTENT — both skills carry frontmatter `name`/`description`/`argument-hint`; both carry the Iron Law + Announce shape.

---

## 4. Pipeline-as-data pattern (the `.lobster` DSL idioms)

### CV-017: workflow header — `name` / `description` (folded) / `trigger` / `steps`
**Rule:** every `.lobster` opens with `name:`, a folded-scalar `description: >`, a `trigger:` note, then a `steps:` list. The DSL is YAML-shaped (`yq -o=json` parses it).
**Example:** `build-track.lobster:1-8`; `pm-doc-chain.lobster:1-8`.
**Consistency:** CONSISTENT — 7/7 (validator requires top-level `name` + non-empty `steps`, Pass 3 BC-047/048).

### CV-018: step shape — `name` / `type` / (`agent`|`skill`|`workflow`) / `depends_on` / `timeout` / `on_failure`
**Rule:** each step is a mapping with `name` (unique), `type` (one of the 7 `STEP_TYPES`: `agent skill gate human-approval loop parallel sub-workflow`), the type's required ref field (`agent:` for agent, `skill:` for skill, `workflow:` for sub-workflow), `depends_on: [<names>]` (DAG wiring), optional `timeout:` (seconds), optional `on_failure:` (e.g. `abort`).
**Example:** `lobster-parse:20-21` defines `STEP_TYPES` and `TYPE_REQUIRES`; `build-track.lobster:9-14` (`draft` step: agent/researcher, `depends_on: []`, `timeout: 1800`, `on_failure: abort`).
**Consistency:** CONSISTENT — validator-enforced for the three ref fields (Pass 3 BC-045/046); `timeout`/`on_failure` are optional and used where it matters (e.g. `draft` aborts on failure).

### CV-019: `depends_on` is the sole wiring; order is derived, never written
**Rule:** execution order is never authored — it is *derived* by `lobster-parse order` (Kahn topo sort, ties broken by sorted name). Authors only declare `depends_on`. A dependency must precede its dependent; `commit` is always the DAG terminal.
**Example:** `build-track.lobster` chain `draft→synthesize→editorial-sweep→citation-verify→adversary-review→gate-pass→commit` via `depends_on` only; Pass 3 BC-040/041 assert `draft` before `synthesize` and `commit` last.
**Consistency:** CONSISTENT — 7/7; every workflow's `commit` step `depends_on` the prior gate/approval and emits last.

### CV-020: `convergence{}` block idiom — identical params, differing `on_cap`
**Rule:** a `loop` step carries a `convergence:` block with the canonical triple `novelty_threshold: 0.15`, `clean_passes_required: 3`, `max_passes: 6` (hard cap) plus an `on_cap:` dispatch (`commit-flagged` or `surface-to-human`). The params are identical across all five review-bearing workflows; only `on_cap` differs by workflow class.
**Example:** `build-track.lobster:44-48` (`on_cap: commit-flagged`); judgment/cross-track/portfolio use `surface-to-human` (Pass 1 §3.3).
**Consistency:** CONSISTENT — the param triple is copy-identical across all loops (and mirrors `factory.config` `review.convergence`); the differentiator is exactly one field (`on_cap`), chosen by whether the workflow is already human-gated.

### CV-021: `context.exclude` info-asymmetry-wall idiom
**Rule:** a review step declares `context: { exclude: [...] }` listing the context the reviewer must NOT see — drawn from the fixed vocabulary `prior-review-passes`, `drafter-reasoning`, `orchestrator-summary`. An inline comment states the asymmetry intent.
**Example:** `build-track.lobster:34-35` (citation-verify excludes `[drafter-reasoning, orchestrator-summary]` — "sees claim+source only") and `:49-50` (adversary-review excludes all three).
**Consistency:** CONSISTENT — the exclude vocabulary is uniform; citation-verify excludes the 2-tuple, adversary the 3-tuple (it must additionally not see prior passes). Structurally reinforced by read-only tool grants (CV-013).

### CV-022: capped-exit idiom — `on_cap` + `on_capped_exit.flag_pr` paired with a `LOOP_CAPPED` gate disjunct
**Rule:** the capped-exit honesty contract is expressed in two coupled places: the loop's `on_cap:` value, and the gate's `on_capped_exit: { flag_pr: "<message>" }` plus a `pass_when` disjunct `or LOOP_CAPPED == true`. The `flag_pr` message uses `{VAR}` interpolation of loop outputs.
**Example:** `build-track.lobster:60-62` — `pass_when: "(ADVERSARY_VERDICT == PASS and MUST_FIX_REMAINING == 0) or LOOP_CAPPED == true"` + `flag_pr: "did not fully converge — {MUST_FIX_REMAINING} MUST-FIX remain after {max_passes} passes"`.
**Consistency:** CONSISTENT for the commit-flagged class (build-track, ingest-source); the surface-to-human class carries the unconverged status into the `human-approval` prompt instead (Pass 1 §3.3). Both honor "never present a capped draft as PASS" (Pass 3 BC-071).

### CV-023: two gate idioms — boolean `pass_when` vs. criteria-map of `clear` flags
**Rule:** a `gate` step's `criteria:` is one of two shapes: (a) a single `pass_when:` boolean expression over loop outputs, or (b) a map of named readiness flags each required to be `clear`. Both are *orchestrator-interpreted* (the parser never looks inside `criteria`).
**Example:** boolean — `build-track.lobster:59-60` (`pass_when`). Criteria-map — `pm-doc-chain.lobster:42-49` (`MVF_SCOPE: clear`, `INPUTS_OUTPUTS: clear`, … `QA_ACCEPTANCE_CRITERIA: clear`; "any one unclear blocks handoff → resolve as labeled Assumption + Open Question, not invention").
**Consistency:** MOSTLY — both idioms are valid and used; this is a *deliberate* two-form pattern, not an inconsistency, but it does mean gate semantics aren't uniform across workflows (the build-track gate and the pm-doc-chain gate read very differently). Pass 3 gap #6 notes the criteria-map path has no test coverage.

### CV-024: `human-approval` step idiom — `prompt:` + `required: true`
**Rule:** a human gate is `type: human-approval` with a `prompt:` string (the question put to the human) and, where non-skippable, `required: true`. It carries no `agent:`/`skill:` (no ref-field required). Placed before any L5/L6/PM/publish terminal.
**Example:** `pm-doc-chain.lobster:65-69` — final `human-approval` with `required: true` and a productization-gate prompt; `:9-12` intake gate.
**Consistency:** CONSISTENT — human-approval steps appear in judgment/cross-track/portfolio/pm-doc-chain, always with a `prompt`; `required: true` on the non-skippable ones (Pass 1 §3.1).

### CV-025: inline `#` comments carry the runtime semantics the parser ignores
**Rule:** because `lobster-parse` validates only structure (not convergence math / gate predicates / asymmetry intent), each behavioral nuance is re-stated as an inline `#` comment on the step — the comment is the human-readable spec the orchestrator follows.
**Example:** `build-track.lobster:42-43` (loop semantics), `:55-58` (capped-exit gate behavior), `:69` ("sole committer, runs last"); `pm-doc-chain.lobster:37,50,57` (PRD shape, gate resolution, story fields).
**Consistency:** CONSISTENT — every non-obvious step in the read workflows carries an explanatory comment. This is the thin-validator/thick-interpreter split made legible (Pass 1 §3).

---

## 5. Error handling / gate pattern (fail-closed PreToolUse hooks)

### CV-026: hook skeleton — shebang + header + `set -euo pipefail` + `jq` guard + `emit_allow`/`emit_deny` + stdin read
**Rule:** every hook follows one skeleton: `#!/usr/bin/env bash`; a multi-line `#` header explaining scope and the precision/recall division of labor; `set -euo pipefail`; a `command -v jq … || { echo …; exit 1; }` dependency guard; `INPUT=$(cat)`; two helper functions `emit_allow()` / `emit_deny()` that print the PreToolUse JSON envelope and `exit 0`; then extract `tool_input.file_path` / `tool_input.content` via `jq -r`.
**Example:** `forbidden-phrase-guard.sh:1-23` shows the entire skeleton verbatim.
**Consistency:** CONSISTENT — all 4 hooks share this skeleton (Pass 3 BC-HOOK-A/B confirm `jq`-guard + JSON-envelope-on-stdin across all four).

### CV-027: decision-in-JSON, exit-0-even-on-deny convention
**Rule:** allow/deny is carried in the JSON envelope's `permissionDecision`, NOT the exit code. Both `emit_allow` and `emit_deny` `exit 0`. A non-zero exit is reserved for the hook *itself* failing (missing `jq` → `exit 1`) — which is itself the fail-closed posture.
**Example:** `forbidden-phrase-guard.sh:19-20` (`emit_allow`/`emit_deny` both `exit 0`); `:16` (`jq` missing → `exit 1`). Pass 3 BC-HOOK-A/B.
**Consistency:** CONSISTENT — 4/4 hooks; the deny envelope adds `permissionDecisionReason`, the allow envelope does not.

### CV-028: scope-guard ladder — corpus-only + exempt-path + basename-exempt + empty-content short-circuit
**Rule:** the corpus-scoped hooks (require-citation, layer-discipline, forbidden-phrase) run a fixed early-exit ladder before any real check: (1) `case "$FILE_PATH" in *"/corpus/"*.md) : ;; *) emit_allow` (scope to corpus claim docs); (2) exempt `*/templates/*|*/_meta/*|*/seed/*`; (3) basename-exempt `README.md|STATE.md|MEMORY.md|*-index.md|index.md`; (4) `[ -z "$CONTENT" ] && emit_allow`. `protect-secrets` deliberately omits the corpus scope (it guards *all* files).
**Example:** `forbidden-phrase-guard.sh:25-28`; Pass 3 BC-004/006/011/012/037.
**Consistency:** CONSISTENT for the 3 corpus hooks (identical ladder); `protect-secrets` is the one deliberate exception (broader scope, no corpus filter) — explained in its header.

### CV-029: deny-reason message convention — name the violation, quote the hit, prescribe the fix, append the path
**Rule:** a deny reason is a single sentence that (a) names the violated principle, (b) quotes the exact matched text via `grep -ioE … | head -1`, (c) prescribes the remediation (reframe / move to L5 / flag), and (d) ends with `($FILE_PATH)`.
**Example:** `forbidden-phrase-guard.sh:36-37` — "Observe-and-report violation: corpus doc contains company-positioning … (\"$hit\"). … Reframe as a sourced observation, or move judgment to L5 … ($FILE_PATH)".
**Consistency:** CONSISTENT — the four hooks' deny messages all follow the name/quote/prescribe/path shape (Pass 3 BC-001/032/038; secrets/layer deny messages likewise self-explain).

### CV-030: precision-hook / recall-agent division-of-labor convention
**Rule:** every deterministic hook is deliberately *narrow* (high precision); the *nuanced* version of the same concern is an LLM agent's job, and the hook header says so explicitly. Generic patterns live in the hook; market-specific names defer to `editorial.forbidden_phrases_extra` (P10).
**Example:** `forbidden-phrase-guard.sh:8-12` ("deliberately NARROW … the nuanced sweep … is the editorial-sweeper AGENT's job") and `:30-32` (defers company names to instance config).
**Consistency:** CONSISTENT — the hook/agent pairing (forbidden-phrase↔editorial-sweeper; require-citation↔citation-verifier) is a stated convention in the headers, matching Pass 1 §5's precision/recall framing.

### CV-031: hook wiring order convention — secrets first, integrity last
**Rule:** the 4 hooks are wired in `hooks.json` in a fixed first-deny-wins order: `protect-secrets → require-citation → layer-discipline-guard → forbidden-phrase-guard`, each `timeout: 5`, referenced via `${CLAUDE_PLUGIN_ROOT}/hooks/<name>.sh`.
**Example:** `hooks.json:7-10`.
**Consistency:** CONSISTENT — the order (broadest/most-severe secrets gate first) is deliberate; `timeout: 5` uniform across all 4.

---

## 6. Test patterns (bats)

### CV-032: one bats suite per testable component
**Rule:** tests are partitioned by component into `tests/*.bats`: `config.bats` (factory-config.sh), `hooks.bats` (require-citation), `hooks-v05.bats` (the three v0.5 hooks: layer/secrets/forbidden-phrase), `lobster.bats` (lobster-parse). A `run-all.sh` runner discovers `*.bats`.
**Example:** Pass 3 covered all 4 suites = 35 `@tests` (config 7, hooks 9, hooks-v05 11, lobster 8).
**Consistency:** CONSISTENT — the partition maps cleanly to the 4 hooks + 2 bin tools (only the deterministic, mechanically-enforced surface is tested; agents are intentionally untested — Pass 3 Group 7 is all MEDIUM/LOW).

### CV-033: bats payload-helper convention
**Rule:** each hook suite defines a `payload()` helper that builds the tool-call JSON via `jq -nc --arg`, then drives the hook with `run bash "$HDIR/<hook>.sh" <<< "$(payload <path> <content>)"` and asserts `[ "$status" -eq 0 ]` plus `[[ "$output" == *'"allow"'* ]]` / `*'"deny"'*`.
**Example:** `hooks-v05.bats:5` (`payload()` helper), `:8-12` (allow case), `:14-18` (deny case).
**Consistency:** CONSISTENT — the `payload()` + `run` + status-0 + allow/deny-substring assertion shape is uniform across the hook suites. Test names are descriptive sentences ("layer-discipline: allows L3 observing L2", "… DENIES L4 that declares it observes L2 (skipping L3)") — SCREAMING the deny cases is a readable sub-convention.

### CV-034: runner preflight convention — assert deps before running
**Rule:** `run-all.sh` is `set -euo pipefail`, resolves its own dir via `BASH_SOURCE`, then asserts each external dependency (`bats`, `jq`, `yq` mikefarah v4) is present with an actionable install message before invoking `bats "$DIR"/*.bats`.
**Example:** `run-all.sh:7-18` (three `command -v` preflight guards), `:21` (glob-run).
**Consistency:** CONSISTENT — mirrors the hook `jq`-guard convention (CV-026): fail loudly on a missing tool rather than silently mis-test.

### CV-035: "keep the suite green / add a case when you change behavior" rule
**Rule:** `CLAUDE.md` states the standing rule: "Keep the suite green; add cases when you change behavior." CI (`ci.yml`) validates plugin manifests, every `.lobster`, Action templates, the template config, and runs the suite. The template config is itself a test fixture (Pass 3 BC-059: the shipped template must `validate` PASS — guards template rot).
**Example:** `CLAUDE.md` Build/test section; `tests/config.bats:75-79` (template-validates test).
**Consistency:** MOSTLY — the rule is documented and CI-enforced for the deterministic surface; but Pass 3 identified real coverage gaps (no agent-behavior tests, `lobster-parse steps`/`factory-config editorial` untested, no `jq`-missing fail-closed test, criteria-map gate untested). The *rule* is consistent; *coverage* of new declarative behaviors lags.

---

## 7. State / commit conventions

### CV-036: branch-off-main → PR → CI `test` gate → squash-merge
**Rule:** `CLAUDE.md` mandates: never commit to `main` directly; branch off `main`, open a PR, let CI's `test` gate pass, then squash-merge. Irreversible/outward actions (publish, external delivery, merging a paid-bot PR) are human-gated.
**Example:** `git log` shows every commit is a squash-merge with a `(#N)` PR number (`9ced663 … (#7)`, `31a377c … (#6)`, etc.) — 7 PRs, all squash-merged.
**Consistency:** CONSISTENT — the visible history is uniformly squash-merged PR commits; no direct-to-main feature commits in the recent window (early `factory-artifacts` plumbing commits predate the rule's full adoption).

### CV-037: conventional-commit subject style — `type(scope): summary (vX #N) (#PR)`
**Rule:** commit subjects follow a conventional-commits shape: `feat|fix|chore|docs(<scope>): <lowercase summary>`, often with a roadmap tag `(v1.0 #N)` and the squash PR number `(#PR)`. Scopes name the touched surface (`portfolio`, `on-pr-review`, `cold-start`, `build-track`, `nightly`, `actions`).
**Example:** `feat(portfolio): L6 cross-market synthesis — the 7th workflow (v1.0 #4) (#7)`; `fix(on-pr-review): the cross-family review now actually reviews the diff + comments (#5)`; `chore: scrub company/org references from the public engine (#6)`.
**Consistency:** CONSISTENT — `git log -25` shows `feat`/`fix`/`chore`/`docs`/`state`/`actions`/`v0.9`/`revert` prefixes; the `type(scope):` form dominates. Minor variance in older commits (`state(§11):`, `v0.9:`) shows the convention tightened over time → MOSTLY across the *full* history but CONSISTENT recently.

### CV-038: never commit `.factory/` on `main`; state lives on the orphan `factory-artifacts` branch
**Rule:** `.factory/` (pipeline state, incl. `STATE.md`) is gitignored on `main` and lives ONLY on the orphan `factory-artifacts` branch, mounted as a worktree. In CI the *workflow* owns the branch round-trip (restore-at-start + persist-at-end); the state-manager only *writes* the workspace `.factory/STATE.md`.
**Example:** `CLAUDE.md` "State model (§11)"; `state-manager.md:34-45` (the local-commits-branch vs CI-only-writes split); `git log` plumbing commits `5111bbf`/`e223f82`/`011e994` establishing the orphan branch. (This Pass-5 file is itself being written under `.factory/semport/` — the analysis workspace — consistent with the gitignore rule.)
**Consistency:** CONSISTENT — the state-branch model is documented in three places (`CLAUDE.md`, `state-manager.md`, `BUILD-PLAN.md` §11) and enforced by gitignore + the Action templates' restore/persist steps (Pass 1 §CI round-trip).

### CV-039: sole-committer / one-burst-one-atomic-commit (P8)
**Rule:** the state-manager is the *only* agent that commits, runs *last* (DAG terminal), and produces exactly one atomic commit per burst (corpus change + `.factory/STATE.md` together). The orchestrator holds no Write tool; no other agent's body invokes a commit. It refuses to commit if review verdicts aren't recorded or the adversary said REVISE.
**Example:** `state-manager.md:17,25-27` (Iron Law); structurally Pass 3 BC-041 (`commit` is the lobster terminal) + BC-073/074.
**Consistency:** CONSISTENT structurally (commit-terminal in 7/7 workflows; orchestrator has no Write); the no-REVISE-commit *precondition* is prose-only (Pass 3 BC-074, LOW — no checker enforces it).

### CV-040: Single-Source-of-Truth for canonical values
**Rule:** each canonical metric (track count, vendor count, canonical dates) lives in exactly one authoritative file (`editorial.canonical_values` path); everything else cites it, nothing re-derives it.
**Example:** `state-manager.md:46`; `research-protocol.md:9` (Pass 2 rule #11); config key `editorial.canonical_values` (Pass 2 §2a.6).
**Consistency:** CONSISTENT as a stated rule across state-manager + research-protocol + config; enforcement is the adversary's "internal consistency" dimension (`adversary-reviewer.md:33`), not a hook.

### CV-041: Co-Authored-By trailer / "project commit-message convention"
**Rule:** `state-manager.md:47` instructs "Use the project commit-message convention." The engine itself ships no hardcoded co-author trailer (it was scrubbed for public-cleanliness, commit `31a377c`); the convention is the conventional-commits subject (CV-037) plus whatever co-author trailer the operating context mandates.
**Example:** `state-manager.md:47`; `chore: scrub company/org references from the public engine (#6)`.
**Consistency:** MOSTLY — the subject-line convention is consistent; the co-author trailer is contextual (deliberately not hardcoded in the public engine, per P10 / public-clean rule). This is a *deliberate* non-specification, not an inconsistency.

---

## 8. Config conventions

### CV-042: `factory.config.yaml` is the single per-market knob surface
**Rule:** all market variability is expressed in one `factory.config.yaml` (+ `seed/`); the engine carries zero market-specific logic (P10). The knob surface is fixed: identity (`market`/`slug`/`audience`/`phase`), `seed`, `vectors[]`, `tracks[]`, `editorial`, `review`, `autonomy_level`, `merge`, `budget`, `deliverables` (Pass 2 §2a.6 enumerates all 26 keys).
**Example:** `templates/factory.config.template.yaml`; validated by `factory-config.sh validate` (Pass 3 BC-052).
**Consistency:** CONSISTENT — Pass 2's P10 verdict: every variability axis is expressible as config; the only non-config market text (generic forbidden-phrase patterns) is deliberately generic with names deferred to config.

### CV-043: templates are the scaffolding source-of-truth; init-market copies, never generates code
**Rule:** standing up a market = `init-market` interview → write `factory.config.yaml` + `seed/` → copy the Action templates / corpus skeletons / portfolio entry. "Add a market = config + seed, not code" (the init-market skill description, P10).
**Example:** `skills/init-market/SKILL.md` frontmatter ("The 'add a market = config + seed, not code' command (P10)."); templates partition CV-012.
**Consistency:** CONSISTENT — no init path generates engine code; everything is template-copy + config-write (Pass 1 layer G, Pass 2 init-market operation).

### CV-044: per-market override convention — `*_extra` / `*_default` additive keys
**Rule:** market-specific *additions* to generic engine behavior use additive keys rather than replacing engine logic: `editorial.forbidden_phrases_extra` (adds to the generic guard), `editorial.per_track_sourcing_default` (default when a track omits `sourcing`). The engine pattern stays generic; the instance only *adds*.
**Example:** `forbidden-phrase-guard.sh:30-32` defers company names to `editorial.forbidden_phrases_extra`; `factory-config.sh:67` defaults a track's `sourcing` to `external-only` (Pass 3 BC-057).
**Consistency:** CONSISTENT — the additive-override convention (engine-generic + instance-`extra`/`default`) is exactly how P10 is kept honest; no config key *replaces* engine logic, it only parameterizes or extends it.

### CV-045: config-of-record self-test convention
**Rule:** the shipped template config is a test fixture that must itself `validate` PASS, guarding against template rot; required-field validation enumerates missing fields rather than failing on the first.
**Example:** `tests/config.bats:75-79` (template validates); `factory-config.sh:78-103` (per-field MISSING diagnostics, Pass 3 BC-053/060).
**Consistency:** CONSISTENT — the template-validates discipline matches the lobster "all shipped workflows validate" discipline (Pass 3 BC-039); both are self-dogfooding fixtures.

---

## 9. Pattern catalog (design patterns in use)

| Pattern | Where | Intent | Consistency |
|---|---|---|---|
| **Directory-as-registry** (convention-over-configuration) | `agents/ workflows/ skills/ commands/ hooks/` | discovery without a manifest; `plugin.json` is metadata only | CONSISTENT (CV-006) |
| **Pipeline-as-data** (interpreter pattern) | `workflows/*.lobster` + orchestrator | pipelines are declarative DAGs; behavior = data | CONSISTENT (CV-017…025) |
| **Thin-validator / thick-interpreter** | `lobster-parse` (structure) vs orchestrator (semantics) | deterministic DAG guarantees + LLM-interpreted runtime | CONSISTENT (CV-025; Pass 1 §3) |
| **Chain-of-responsibility, fail-closed** | the 4 PreToolUse:Write hooks | first-deny-wins gate chain before every Write | CONSISTENT (CV-031) |
| **Precision-hook / recall-agent pairing** | forbidden-phrase↔editorial-sweeper; require-citation↔citation-verifier | deterministic bright-line + reasoned nuance for one concern | CONSISTENT (CV-030) |
| **Strategy-by-config** | `on_cap`, `autonomy_level`, `sourcing`, `vectors[]` | per-market/per-workflow behavior selection without code | CONSISTENT (CV-020, CV-042) |
| **Information-asymmetry wall** | `context.exclude` + read-only tool grants + CI family split | structural blindness of reviewers (P6) | CONSISTENT (CV-021, CV-013) |
| **Sole-committer (single-writer)** | state-manager, DAG-terminal | one atomic commit per burst, no version races (P8) | CONSISTENT structurally (CV-039) |
| **Template-method** (agent body) | Announce → Iron Law/Asymmetry → Responsibilities → Boundaries | uniform prompt skeleton across 11 agents | MOSTLY (CV-014/015) |
| **Self-dogfooding fixtures** | template-config-validates, all-workflows-validate | the shipped scaffolds are their own regression tests | CONSISTENT (CV-035, CV-045) |
| **Capped convergence with honest fallback** | loop `on_cap` + gate `LOOP_CAPPED` disjunct | bounded adversarial loop that never silently no-ops or fakes PASS (P7) | CONSISTENT (CV-022) |

---

## 10. Anti-patterns / code smells / risks (grounded, not invented)

| # | Smell / risk | Where | Note |
|---|---|---|---|
| AP-1 | **Behavioral spec split across comment + prose + agent** | lobster runtime semantics live in `#` comments (CV-025) + `orchestrator.md` + each workflow; not in the validator | Deliberate (thin-validator), but means convergence/gate/asymmetry semantics have **no executable test** (Pass 3 Group 7 all MEDIUM/LOW). Drift risk between comment and orchestrator prose. |
| AP-2 | **Over-permissive citation matcher** | `require-citation.sh` `[a-z0-9_-]+\.md` (Pass 3 BC-014) | Any lowercase token ending `.md` anywhere in the body satisfies the gate — a possible false-allow with no negative test. |
| AP-3 | **Two divergent gate idioms** | boolean `pass_when` vs criteria-map (CV-023) | Gate semantics aren't uniform; the criteria-map path (pm-doc-chain) is orchestrator-only with no parser or test coverage (Pass 3 gap #6). |
| AP-4 | **Color field is non-unique, decorative** | agent frontmatter `color` (CV-013) | blue/green each reused; `color` carries no semantic key — harmless but a field that looks like metadata and isn't. |
| AP-5 | **Declared-but-unenforced budget governance** | `budget.thresholds` in config | Pass 2 gap #4 / Pass 3 gap #7: no hook/CLI/test enforces `warn/alert/pause/hard_stop` — config declares an NFR with no located enforcer (a Pass-4 target). |
| AP-6 | **Iron-Law honesty contracts are prose-only** | capped-exit no-fake-PASS (BC-071), no-REVISE-commit (BC-074) | The constitution's most load-bearing honesty rules are enforced by reasoning + structure (tool-grant absence, DAG-terminal), not by a checker. Strong but untestable. |

These are *characterizations of deliberate trade-offs*, not defects — the engine consciously trades testable enforcement for an LLM-interpreted contract on the agent-behavior surface, while keeping the *deterministic* surface (hooks, validators, config) fully tested.

---

## 11. Consistency scorecard (per pattern family)

| Pattern family | Verdict | Basis |
|---|---|---|
| Naming (kebab, name===stem, `Ln`, frontmatter fields) | **CONSISTENT** | 11/11 agents, 7/7 workflows, all slugs/files; CV-001…004 |
| Module organization (dir-as-registry, one-per-file) | **CONSISTENT** | clean partition, no leakage; CV-006…012 |
| Markdown-as-agent (frontmatter schema, Announce, prose-as-prompt) | **CONSISTENT** (Announce 11/11) / **MOSTLY** (Iron-Law-vs-Asymmetry naming) | CV-013…016 |
| Pipeline-as-data (`.lobster` idioms) | **CONSISTENT**, with **MOSTLY** on the two-gate-idiom split | CV-017…025 |
| Error/gate (fail-closed hooks) | **CONSISTENT** | 4/4 share skeleton, scope-ladder, deny-message shape; CV-026…031 |
| Test (bats) | **CONSISTENT** shape / **MOSTLY** coverage | CV-032…035; coverage gaps per Pass 3 |
| State/commit | **CONSISTENT** (sole-committer, state-branch, squash-PR) / **MOSTLY** (commit-subject across full history, co-author trailer contextual) | CV-036…041 |
| Config | **CONSISTENT** (single knob surface, additive overrides, self-test) | CV-042…045 |

**Headline:** the engine is unusually *internally consistent* for a system this declarative — because nearly every convention is also an enforced invariant (a hook, a validator, a DAG-terminal, or a CI step backs it). The few MOSTLY verdicts are all **principled variance** (role-appropriate section naming, the two deliberate gate idioms, contextual co-author trailer, tightening-over-time commit style), not sloppiness. The genuine soft spots are **coverage** (agent behavior + two declarative idioms untested) and **prose-only enforcement** of the honesty contracts — both already logged in Pass 3.

---

## Resume checkpoint

```yaml
pass: 5
status: complete
files_read_this_pass: 14   # 4 prior pass outputs (re-read) + all 11 agent frontmatters (awk) + build-track.lobster + pm-doc-chain.lobster + forbidden-phrase-guard.sh + hooks.json + run-all.sh + hooks-v05.bats + 3 command files + 2 SKILL frontmatters + L3-findings template + lobster-parse STEP_TYPES + state-manager.md + adversary-reviewer.md + git log -25
conventions_catalogued: 45   # CV-001 … CV-045
design_patterns: 11          # §9 pattern catalog
anti_patterns: 6             # AP-1 … AP-6 (deliberate trade-offs, grounded)
consistency_families: 8      # §11 scorecard
consistency_summary: {CONSISTENT: 6, MOSTLY-mixed: 2}   # naming/module/error/config fully consistent; agent-template, pipeline, test, state carry principled MOSTLY
timestamp: 2026-06-01T00:00:00Z
next_pass: 6
next_pass_name: Synthesis & Validation
```

## Remaining gaps / next candidate scope (for Pass 6 Synthesis + Pass-5 deepening)

1. **Naming across the unread Action templates / remaining corpus+pm templates.** This pass verified naming on agents/workflows/hooks/commands/skills + the L3 template directly; a Pass-5 deepening round should confirm the frontmatter/tag conventions hold across the 6 `*.yml` Action templates and the L2/L4/L6/track-summary/pm templates (Pass 2 read most; convention-conformance not separately audited).
2. **Cross-reference for Pass 6:** do the conventions (Pass 5) align with the architecture (Pass 1) and contracts (Pass 3)? Candidate checks — (a) every CV that claims "structurally enforced" should map to a Pass-3 BC or a Pass-1 mechanism; (b) AP-5 (budget) and AP-6 (prose-only honesty) are the convention↔NFR/contract inconsistencies Pass 6 must surface.
3. **Commit-convention drift over full history.** CV-037 is CONSISTENT recently but MOSTLY across the full log (`state(§11):`, `v0.9:` older forms). A deepening round could quantify the drift and confirm CI doesn't lint commit subjects (no commitlint found this pass).
4. **`color` field semantics (AP-4).** Confirm whether `color` is purely cosmetic or read by any tooling — none found this pass; worth a one-line confirmation in deepening.
5. **The `editorial-sweeper`/`consistency-validator`/`dashboard-builder` bodies** were not read in full this pass (frontmatter + section-presence scan only). A deepening round should confirm they follow the CV-014/015 body convention (Announce confirmed present; Iron-Law-section absent for the 2 reviewers and the 2 mechanical sweepers — verify that's principled, not omission).
6. **Hook-skeleton conformance of `require-citation.sh` / `layer-discipline-guard.sh` / `protect-secrets.sh`** was inferred from Pass 3 BCs + the `forbidden-phrase-guard.sh` exemplar read directly this pass; a deepening round should read all four side-by-side to confirm the skeleton (CV-026) is byte-for-byte uniform (e.g. identical `emit_allow`/`emit_deny` helpers).
```
