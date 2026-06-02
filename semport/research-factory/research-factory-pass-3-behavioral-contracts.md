# Pass 3: Behavioral Contracts — research-factory engine

> Scope of record: `/Users/jmagady/Dev/research-factory/plugins/research-factory/` (the plugin = the engine).
> Builds on Pass 0 (inventory, 64 files), Pass 1 (7 engine layers, 2 surfaces, convergence SM), Pass 2 (domain model).
> Resolves Pass-2 gap #1 (function-level claim-disposition contract from the bats suites) and Pass-1 gap #6 (extract BCs from tests).
>
> **Confidence policy (per skill spec):**
> - **HIGH** = a passing `@test` directly asserts the behavior (executable contract; the bats case is the truth).
> - **MEDIUM** = derived from deterministic hook/CLI *logic* (regex, control flow) but not exercised by a named test.
> - **LOW** = inferred from agent prose / Iron Laws / frontmatter; not test-backed and not deterministically enforced.
>
> **Source-of-truth note:** the 4 fail-closed hooks and the 2 bin tools are the only places where a contract is *mechanically enforced*. Agent "Iron Laws" are prompt-level contracts: real intent, but enforced by reasoning + the structural walls (tool-grant absence, `context.exclude`, CI family split), not by a checker — hence MEDIUM/LOW unless a test pins them.
>
> **One-shot example of the BC shape used below:**
> > ### BC-000: <one-line statement>
> > **GIVEN** <precondition> **WHEN** <action> **THEN** <expected outcome / exit code / allow|deny / ordering>.
> > **Error/edge:** <what happens off the happy path>.
> > **Source:** `<file>:<lines>` or `<test name>`. **Confidence:** HIGH | MEDIUM | LOW.

---

## Component index

| Group | Component | BCs | Highest confidence source |
|---|---|---|---|
| 1 | `hooks/require-citation.sh` | BC-001 … BC-014 | `tests/hooks.bats` (9 tests) + hook logic |
| 2 | `hooks/layer-discipline-guard.sh` | BC-015 … BC-024 | `tests/hooks-v05.bats` (5 tests) + hook logic |
| 3 | `hooks/protect-secrets.sh` | BC-025 … BC-031 | `tests/hooks-v05.bats` (3 tests) + hook logic |
| 4 | `hooks/forbidden-phrase-guard.sh` | BC-032 … BC-038 | `tests/hooks-v05.bats` (3 tests) + hook logic |
| 5 | `bin/lobster-parse` | BC-039 … BC-051 | `tests/lobster.bats` (8 tests) + parser logic |
| 6 | `bin/factory-config.sh` | BC-052 … BC-063 | `tests/config.bats` (7 tests) + script logic |
| 7 | Orchestrator / agent Iron Laws | BC-064 … BC-076 | agent frontmatter + bodies (mostly MEDIUM/LOW) |

---

# Group 1 — `require-citation.sh` (cite-or-flag-or-drop gate, P3/P4)

Resolves Pass-2 gap #1. The gate's job: a **guarded corpus claim doc** with substantive prose and **neither a citation nor an explicit flag** → `deny`; everything else → `allow`. Output envelope is always `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"|"deny"[,"permissionDecisionReason":…]}}` and the script **exits 0 even on a deny** (the decision is carried in JSON, not the exit code). Guarded path = a `file_path` containing `/corpus/` and ending `.md`.

### BC-001: Denies a substantive corpus claim doc with no source marker and no flag
**GIVEN** a `Write` to `*/corpus/*.md` **AND** the body has ≥ `MIN_CLAIM_LINES` (default 3) substantive prose lines **AND** the content contains no citation marker and no unsourced-flag **WHEN** the hook runs **THEN** emit `permissionDecision:"deny"` with the anchor-not-strip reason, exit 0.
**Source:** `tests/hooks.bats:13-19` ("denies a corpus claim doc with substantive prose and no source marker"); `require-citation.sh:99-103`. **Confidence:** HIGH.

### BC-002: Allows a corpus claim doc carrying a URL citation
**GIVEN** a guarded corpus doc whose content matches `https?://` (e.g. a markdown link to a URL) **WHEN** the hook runs **THEN** emit `permissionDecision:"allow"`, exit 0.
**Source:** `tests/hooks.bats:21-27`; `require-citation.sh:99-100`. **Confidence:** HIGH.

### BC-003: Allows a corpus doc whose claims are explicitly flagged (anchor-not-strip)
**GIVEN** a guarded corpus doc containing an explicit unsourced flag — `[Source needed: …]` and/or `[Access required: …]` — and no URL **WHEN** the hook runs **THEN** `allow` (Type-1 claims are flagged, not deleted).
**Source:** `tests/hooks.bats:29-35`; `require-citation.sh:97,99`. **Confidence:** HIGH.

### BC-004: Allows any non-corpus write regardless of citations
**GIVEN** a `Write` whose `file_path` does not contain `/corpus/…​.md` (e.g. `/x/notes/scratch.md`), even with many uncited prose lines **WHEN** the hook runs **THEN** `allow` immediately (scope: corpus claim docs only).
**Source:** `tests/hooks.bats:37-42`; `require-citation.sh:54-57`. **Confidence:** HIGH.

### BC-005: Allows a corpus stub below the claim-line threshold
**GIVEN** a guarded corpus doc with fewer than `MIN_CLAIM_LINES` substantive prose lines (e.g. `# Title\n\nTODO.`) **WHEN** the hook runs **THEN** `allow` (treated as scaffold/stub).
**Source:** `tests/hooks.bats:44-49`; `require-citation.sh:88-90`. **Confidence:** HIGH.

### BC-006: Exempts template paths even with uncited claims
**GIVEN** a path containing `/templates/` (e.g. `/x/corpus/templates/findings.md`) with substantive uncited prose **WHEN** the hook runs **THEN** `allow` (scaffolds carry placeholder claims). Exempt segments: `*/templates/*`, `*/_meta/*`, `*/seed/*`.
**Source:** `tests/hooks.bats:51-57`; `require-citation.sh:60-62`. **Confidence:** HIGH.

### BC-007: Accepts an internal `.md` doc reference as a downward citation (synthesis layers)
**GIVEN** an L4 synthesis doc whose claims reference named lower-layer docs by `<name>.md` (e.g. `(ot-…-findings-tldr.md)`) and no external URL **WHEN** the hook runs **THEN** `allow` — synthesis layers (L3/L4/L5) cite *downward* by named doc, not by external URL.
**Source:** `tests/hooks.bats:59-65`; `require-citation.sh:99` (`[a-z0-9_-]+\.md` alternative). **Confidence:** HIGH.

### BC-008: Accepts a `[[wikilink]]` as a citation marker
**GIVEN** a guarded corpus doc whose content contains `[[…]]` (e.g. `[[ot-security-hearings-findings-tldr]]`) **WHEN** the hook runs **THEN** `allow`.
**Source:** `tests/hooks.bats:67-73`; `require-citation.sh:99` (`\[\[`). **Confidence:** HIGH.

### BC-009: Accepts a frontmatter `sources:` (or `cites:`/`source:`) field as a citation
**GIVEN** a guarded corpus doc whose frontmatter declares `sources:` (or `cites:`/`source:`), even though body claims carry no inline citation **WHEN** the hook runs **THEN** `allow`.
**Source:** `tests/hooks.bats:75-81`; `require-citation.sh:99` (`^[[:space:]]*(cites|source|sources):`). **Confidence:** HIGH.

### BC-010: Accepts a footnote marker `[^…]` as a citation (logic-derived)
**GIVEN** a guarded corpus doc whose body contains a footnote reference `[^foo]` **WHEN** the hook runs **THEN** `allow`. (No dedicated test, but the regex alternative `\[\^` is present.)
**Source:** `require-citation.sh:99` (`\[\^`). **Confidence:** MEDIUM.

### BC-011: Empty content is allowed (placeholder creation)
**GIVEN** a guarded corpus path with empty `tool_input.content` **WHEN** the hook runs **THEN** `allow` (creating a placeholder file).
**Source:** `require-citation.sh:69` (`[ -z "$CONTENT" ] && emit_allow`). **Confidence:** MEDIUM.

### BC-012: Basename-exempt structural files are allowed
**GIVEN** a guarded corpus path whose basename is `README.md`, `STATE.md`, `MEMORY.md`, `*-index.md`, or `index.md` **WHEN** the hook runs **THEN** `allow` (structural/non-claim files).
**Source:** `require-citation.sh:63-66`. **Confidence:** MEDIUM.

### BC-013: Claim-line counting excludes headings, blank lines, and table/rule/list/blockquote delimiters
**GIVEN** body text **WHEN** counting substantive prose lines **THEN** exclude blank lines, lines starting `#` (headings), pure delimiter lines (`-*+|>` runs, `---`/`===`/`|||` rules) — only the remainder counts toward `MIN_CLAIM_LINES`; YAML frontmatter is stripped before counting.
**Source:** `require-citation.sh:72-85`. **Confidence:** MEDIUM.

### BC-014: Threshold is overridable via env, but matchers are case-insensitive and substring-wide
**GIVEN** `REQUIRE_CITATION_MIN_LINES` set in the environment **WHEN** the hook runs **THEN** that value replaces the default 3. The citation/flag scan runs over the *whole content* (not just body) case-insensitively (`grep -qiE`), so a marker anywhere (incl. frontmatter) satisfies the gate.
**Source:** `require-citation.sh:24,99`. **Confidence:** MEDIUM.
**Risk/edge (LOW):** the `.md` matcher (`[a-z0-9_-]+\.md`) is broad — any lowercase token ending `.md` anywhere in the body (even a non-citation filename mention) satisfies the gate. Untested over-permissive path (see Gaps).

---

# Group 2 — `layer-discipline-guard.sh` (layer spine: L_n observes only L_(n-1))

Reads frontmatter `layer:` and `layer-observes:`; for a guarded corpus doc with a numeric `layer`, denies unless `layer-observes == L(layer-1)` (or, for L1, observes the external world). Same exempt-path/scope rules as Group 1. Always exits 0; decision in JSON.

### BC-015: Allows L3 declaring it observes L2
**GIVEN** a guarded corpus doc with `layer: L3` / `layer-observes: L2` **WHEN** the guard runs **THEN** `allow`.
**Source:** `tests/hooks-v05.bats:8-12`; `layer-discipline-guard.sh:51-58`. **Confidence:** HIGH.

### BC-016: Denies an L4 doc that declares it observes L2 (skipping L3)
**GIVEN** `layer: L4` / `layer-observes: L2` **WHEN** the guard runs **THEN** `deny` (L4 must observe L3, the layer immediately below).
**Source:** `tests/hooks-v05.bats:14-18`; `layer-discipline-guard.sh:56-58`. **Confidence:** HIGH.

### BC-017: Denies an L3 doc missing `layer-observes`
**GIVEN** `layer: L3` with no `layer-observes:` **WHEN** the guard runs **THEN** `deny` (an L_n (n≥2) doc must declare its `layer-observes`).
**Source:** `tests/hooks-v05.bats:20-24`; `layer-discipline-guard.sh:52-54`. **Confidence:** HIGH.

### BC-018: Allows L1 declaring it observes `external`
**GIVEN** `layer: L1` / `layer-observes: external` **WHEN** the guard runs **THEN** `allow` (L1 observes the external world).
**Source:** `tests/hooks-v05.bats:26-30`; `layer-discipline-guard.sh:44-47`. **Confidence:** HIGH.

### BC-019: Allows a non-corpus path regardless of layer frontmatter
**GIVEN** a `Write` outside `*/corpus/*.md` (e.g. `/x/notes/foo.md`) even with `layer: L4` / `layer-observes: L1` **WHEN** the guard runs **THEN** `allow` (scope: corpus only).
**Source:** `tests/hooks-v05.bats:32-35`; `layer-discipline-guard.sh:24`. **Confidence:** HIGH.

### BC-020: A doc with no `layer:` tag is not this guard's concern
**GIVEN** a guarded corpus doc with no `layer:` frontmatter **WHEN** the guard runs **THEN** `allow` (other guards still apply; this guard only constrains layer-tagged docs).
**Source:** `layer-discipline-guard.sh:38`. **Confidence:** MEDIUM.

### BC-021: L1 with an invalid `layer-observes` is denied
**GIVEN** `layer: L1` / `layer-observes:` set to anything other than empty/`external`/`External`/`L0` (e.g. `L1` or `L3`) **WHEN** the guard runs **THEN** `deny` ("an L1 doc observes the external world").
**Source:** `layer-discipline-guard.sh:44-47`. **Confidence:** MEDIUM.

### BC-022: A non-numeric `layer` label is skipped (allowed)
**GIVEN** a guarded corpus doc whose `layer:` value is non-numeric after stripping the `L` prefix (e.g. `layer: draft`) **WHEN** the guard runs **THEN** `allow` ("non-standard layer label → skip").
**Source:** `layer-discipline-guard.sh:42`. **Confidence:** MEDIUM.

### BC-023: A non-numeric `layer-observes` on an L_n (n≥2) doc is denied
**GIVEN** `layer: L3` with `layer-observes:` non-numeric/non-empty (e.g. `L2-baseline`) **WHEN** the guard runs **THEN** `deny` ("not a valid layer").
**Source:** `layer-discipline-guard.sh:55`. **Confidence:** MEDIUM.

### BC-024: Frontmatter extraction stops at the closing `---` and unquotes values
**GIVEN** YAML frontmatter delimited by `---` on line 1 **WHEN** extracting `layer`/`layer-observes` **THEN** read only within the frontmatter block, strip surrounding quotes, take the first match. Empty content and basename/path exemptions short-circuit to `allow` before extraction.
**Source:** `layer-discipline-guard.sh:25-32`. **Confidence:** MEDIUM.

---

# Group 3 — `protect-secrets.sh` (credential hygiene, all files)

Scope: **every** file (not corpus-limited). Denies if content matches a high-precision secret signature. Always exits 0; decision in JSON.

### BC-025: Denies writing a Perplexity (`pplx-`) key to any file
**GIVEN** a `Write` whose content contains `pplx-` followed by ≥20 alnum chars **WHEN** the guard runs **THEN** `deny` ("Refusing to write a credential…").
**Source:** `tests/hooks-v05.bats:38-41`; `protect-secrets.sh:21,23-24`. **Confidence:** HIGH.

### BC-026: Denies writing a PEM private-key block to any file
**GIVEN** content containing `-----BEGIN … PRIVATE KEY-----` (e.g. an OpenSSH/PEM block) **WHEN** the guard runs **THEN** `deny`.
**Source:** `tests/hooks-v05.bats:43-46`; `protect-secrets.sh:21`. **Confidence:** HIGH.

### BC-027: Allows ordinary prose that merely mentions "api keys" conceptually
**GIVEN** content like "The vendor rotates its API keys quarterly per policy." with no secret-shaped token **WHEN** the guard runs **THEN** `allow` (high precision: conceptual mention is not a credential).
**Source:** `tests/hooks-v05.bats:48-51`; `protect-secrets.sh:21-26`. **Confidence:** HIGH.

### BC-028: Denies provider-key prefixes `sk-` and `tvly-` (logic-derived)
**GIVEN** content matching `sk-[A-Za-z0-9]{20,}` or `tvly-(prod|dev)?-?[A-Za-z0-9]{16,}` **WHEN** the guard runs **THEN** `deny`.
**Source:** `protect-secrets.sh:21`. **Confidence:** MEDIUM.

### BC-029: Denies GitHub tokens and AWS access-key IDs (logic-derived)
**GIVEN** content matching `gh[pousr]_[A-Za-z0-9]{30,}` (GitHub token) or `AKIA[0-9A-Z]{16}` (AWS access key) or `xox[baprs]-…` (Slack) **WHEN** the guard runs **THEN** `deny`.
**Source:** `protect-secrets.sh:21`. **Confidence:** MEDIUM.

### BC-030: Empty content is allowed
**GIVEN** an empty `tool_input.content` **WHEN** the guard runs **THEN** `allow` immediately.
**Source:** `protect-secrets.sh:18`. **Confidence:** MEDIUM.

### BC-031: Secret scan is case-sensitive (`grep -qE`, not `-i`)
**GIVEN** the secret signatures **WHEN** scanning **THEN** matching is case-sensitive (unlike the citation/forbidden-phrase scans). A lowercased/obfuscated variant of a prefix would not match — by design the patterns target the exact provider casing.
**Source:** `protect-secrets.sh:23`. **Confidence:** MEDIUM.

---

# Group 4 — `forbidden-phrase-guard.sh` (observe-and-report integrity, P5 bright lines)

Scope: corpus docs only (same exempt rules as Groups 1/2). Denies on a narrow set of first-person/positioning/"what to build" phrases. Deliberately narrow (high precision); the nuanced sweep is the editorial-sweeper agent's job. Always exits 0.

### BC-032: Denies company-positioning / "we should build" language in a corpus doc
**GIVEN** a guarded corpus doc whose content matches a forbidden phrase (e.g. "we should build a consequence-reduction product") **WHEN** the guard runs **THEN** `deny`, quoting the first hit, advising to reframe as a sourced observation or move judgment to L5.
**Source:** `tests/hooks-v05.bats:54-58`; `forbidden-phrase-guard.sh:33,35-37`. **Confidence:** HIGH.

### BC-033: Allows a sourced observation without positioning
**GIVEN** a guarded corpus doc that states an attributed, sourced observation (e.g. "Walsh describes translation as the binding constraint ([talk](https://x.com))") **WHEN** the guard runs **THEN** `allow`.
**Source:** `tests/hooks-v05.bats:60-64`; `forbidden-phrase-guard.sh:35-39`. **Confidence:** HIGH.

### BC-034: Allows positioning language *outside* the corpus (e.g. plan/docs files)
**GIVEN** a `Write` outside `*/corpus/*.md` (e.g. `/x/docs/plan.md`) containing "We should build the engine first." **WHEN** the guard runs **THEN** `allow` (positioning is legitimate in plan docs; only the observe-only corpus is constrained).
**Source:** `tests/hooks-v05.bats:66-69`; `forbidden-phrase-guard.sh:25`. **Confidence:** HIGH.

### BC-035: The forbidden set is the generic positioning phrase list (logic-derived)
**GIVEN** corpus content **WHEN** scanning **THEN** the denied set is exactly: `we should build`, `we recommend building`, `the product we should build`, `our recommendation is to build`, `the moat is`, `where we should invest`, `pick a winner`, `we should prioritize building` — matched case-insensitively (`grep -qiE`).
**Source:** `forbidden-phrase-guard.sh:33,35`. **Confidence:** MEDIUM.

### BC-036: Market-specific company names are NOT in the generic guard (P10)
**GIVEN** a market-specific positioning phrase using a company name **WHEN** the engine is generic **THEN** the guard does NOT match it; such names belong in the instance's `editorial.forbidden_phrases_extra` (no market-specific logic in the engine).
**Source:** `forbidden-phrase-guard.sh:30-32`. **Confidence:** MEDIUM.

### BC-037: Empty content / exempt paths short-circuit to allow
**GIVEN** empty content, or a `*/templates/*`/`*/_meta/*`/`*/seed/*` path, or basename `README.md`/`STATE.md`/`MEMORY.md`/`*-index.md`/`index.md` **WHEN** the guard runs **THEN** `allow` before scanning.
**Source:** `forbidden-phrase-guard.sh:25-28`. **Confidence:** MEDIUM.

### BC-038: Deny reason quotes the matched hit
**GIVEN** a forbidden-phrase match **WHEN** denying **THEN** the reason embeds the first matched phrase (`grep -ioE … | head -1`) so the author sees exactly what tripped the gate.
**Source:** `forbidden-phrase-guard.sh:36-37`. **Confidence:** MEDIUM.

---

## Cross-cutting hook contract (all four gates)

### BC-HOOK-A: Fail-closed on missing `jq`
**GIVEN** `jq` is not on `PATH` **WHEN** any hook runs **THEN** it prints an error to stderr and `exit 1` (the hook itself errors out — a non-zero exit is a fail-closed posture, not an allow).
**Source:** `require-citation.sh:26-29`, `layer-discipline-guard.sh:15`, `protect-secrets.sh:10`, `forbidden-phrase-guard.sh:16`. **Confidence:** MEDIUM.

### BC-HOOK-B: Decision is carried in JSON; allow/deny both exit 0
**GIVEN** any allow or deny decision **WHEN** the hook completes **THEN** it prints the PreToolUse envelope and exits 0; the deny envelope adds `permissionDecisionReason`. (The earlier-in-chain a deny fires, the sooner the Write is blocked; chain order is `protect-secrets → require-citation → layer-discipline-guard → forbidden-phrase-guard`, each `timeout 5` — Pass 1 §A.)
**Source:** all four `emit_allow`/`emit_deny`; `hooks/hooks.json` (chain order, from Pass 0/1). **Confidence:** MEDIUM.

---

# Group 5 — `bin/lobster-parse` (the .lobster DAG validator/orderer)

Subcommands: `validate` (schema+DAG, exit 0 PASS / 1 FAIL / 2 usage), `order` (Kahn topo order to stdout), `steps` (`name\ttype\tref`). YAML loaded via `yq -o=json`. The orchestrator runs `validate` then `order` before dispatch.

### BC-039: Every shipped workflow validates PASS
**GIVEN** each `workflows/*.lobster` (≥7 files) **WHEN** `validate` runs **THEN** exit 0 and stdout contains `PASS`. The suite also fails if fewer than 7 workflows are found (guards an empty glob).
**Source:** `tests/lobster.bats:10-21`; `lobster-parse:123-130`. **Confidence:** HIGH.

### BC-040: `order` emits a topological order — a dependency precedes its dependent
**GIVEN** `build-track.lobster` **WHEN** `order` runs **THEN** exit 0 and `draft` appears before `synthesize` in the output (a dependency precedes its dependent).
**Source:** `tests/lobster.bats:31-43`; `lobster-parse:89-113`. **Confidence:** HIGH.

### BC-041: `commit` (state-manager) is the last step in build-track order
**GIVEN** `build-track.lobster` **WHEN** `order` runs **THEN** the final line of output is `commit` (sole-committer-runs-last, realized as a DAG terminal).
**Source:** `tests/lobster.bats:42`. **Confidence:** HIGH.

### BC-042: portfolio-synth (L6) order contains a `human-approval` step and ends at `commit`
**GIVEN** `portfolio-synth.lobster` **WHEN** `order` runs **THEN** exit 0, output contains `human-approval`, and the last line is `commit` — the cross-market judgment layer passes a human gate before the terminal commit.
**Source:** `tests/lobster.bats:23-29`. **Confidence:** HIGH.

### BC-043: Detects a dependency cycle and fails
**GIVEN** a workflow where step `a` depends on `b` and `b` depends on `a` **WHEN** `validate` runs **THEN** exit ≠ 0 and stderr contains `cycle` (Kahn leaves nodes unordered → "dependency cycle detected among: …"). `order` is then refused.
**Source:** `tests/lobster.bats:45-55`; `lobster-parse:108-111`. **Confidence:** HIGH.

### BC-044: Rejects `depends_on` referencing an unknown step
**GIVEN** a step whose `depends_on` names a step that does not exist **WHEN** `validate` runs **THEN** exit ≠ 0 and stderr contains `unknown step`.
**Source:** `tests/lobster.bats:57-66`; `lobster-parse:84-86`. **Confidence:** HIGH.

### BC-045: Rejects an invalid step `type`
**GIVEN** a step with `type: frobnicate` (not in the 7-member `STEP_TYPES` set) **WHEN** `validate` runs **THEN** exit ≠ 0 and stderr contains `not in` (the sorted valid-type set is named in the message).
**Source:** `tests/lobster.bats:68-77`; `lobster-parse:67-68`. **Confidence:** HIGH.

### BC-046: An `agent` step missing its `agent:` field is rejected
**GIVEN** a step `type: agent` with no `agent:` field **WHEN** `validate` runs **THEN** exit ≠ 0 and stderr contains `requires field 'agent'`. (Same `TYPE_REQUIRES` rule: `skill`→`skill`, `sub-workflow`→`workflow`.)
**Source:** `tests/lobster.bats:79-88`; `lobster-parse:21,69-71`. **Confidence:** HIGH.

### BC-047: An empty `steps` list is rejected
**GIVEN** a workflow with `steps: []` **WHEN** `validate` runs **THEN** exit ≠ 0 and stderr contains `non-empty list`.
**Source:** `tests/lobster.bats:90-98`; `lobster-parse:50-52`. **Confidence:** HIGH.

### BC-048: Missing top-level `name` is an error
**GIVEN** a workflow document with no top-level `name` **WHEN** `validate` runs **THEN** it records the error `missing top-level 'name'` and FAILs (exit 1).
**Source:** `lobster-parse:47-48`. **Confidence:** MEDIUM.

### BC-049: Duplicate step names are an error
**GIVEN** two steps sharing a `name` **WHEN** `validate` runs **THEN** error `duplicate step name: <nm>` and FAIL.
**Source:** `lobster-parse:63-64`. **Confidence:** MEDIUM.

### BC-050: Topological order is deterministic (ties broken by sorted name)
**GIVEN** multiple steps with in-degree 0 (independent) **WHEN** `order` runs **THEN** ready nodes are emitted in `sorted()` name order (the Kahn queue is sorted on insert), so the order is stable/reproducible across runs.
**Source:** `lobster-parse:99-107`. **Confidence:** MEDIUM.

### BC-051: `order` refuses an invalid workflow; usage errors exit 2
**GIVEN** a workflow that fails `validate` **WHEN** `order` is requested **THEN** it dies ("cannot emit order: workflow is invalid") with exit 2. Wrong argument count or unknown subcommand also exit 2 via `die`. A missing/unparseable YAML (or missing `yq`) likewise exits 2.
**Source:** `lobster-parse:24-26,116-119,131-133,142-143,29-39`. **Confidence:** MEDIUM.

---

# Group 6 — `bin/factory-config.sh` (config-of-record validator/reader)

Subcommands: `path`, `validate`, `get <yq-expr>`, `vectors`, `tracks`, `editorial`. Config resolution order: explicit arg → `$FACTORY_CONFIG` → nearest `factory.config.yaml` walking up from `$PWD`. Dependency: `yq` (mikefarah v4).

### BC-052: `validate` PASSes a well-formed config (exit 0, "PASS")
**GIVEN** a config with `market`, `slug`, `seed.scope_doc`, `seed.source_inventory`, a non-empty `vectors[]` (each id+name) and `tracks[]` (each slug+name) **WHEN** `validate` runs **THEN** exit 0 and output contains `PASS`.
**Source:** `tests/config.bats:29-33`; `factory-config.sh:91-103`. **Confidence:** HIGH.

### BC-053: `validate` FAILs when a required field is missing (exit ≠ 0, "FAIL")
**GIVEN** a config missing required fields (e.g. no `slug`, no `tracks`) **WHEN** `validate` runs **THEN** exit ≠ 0 and output contains `FAIL` (per-missing-field `MISSING:`/`EMPTY/MISSING list:` diagnostics on stderr).
**Source:** `tests/config.bats:35-47`; `factory-config.sh:78-103`. **Confidence:** HIGH.

### BC-054: `get` extracts a scalar field
**GIVEN** a valid config **WHEN** `get '.market' <cfg>` runs **THEN** exit 0 and output is the raw scalar (e.g. `OT/ICS Security`).
**Source:** `tests/config.bats:49-53`; `factory-config.sh:54-58`. **Confidence:** HIGH.

### BC-055: `vectors` lists `id\tname` per vector, one line each
**GIVEN** a config with N vectors **WHEN** `vectors <cfg>` runs **THEN** exit 0, line 0 is `<id>\t<name>` (e.g. `V1\tVendor/competitor`), and exactly N lines are emitted.
**Source:** `tests/config.bats:55-60`; `factory-config.sh:60-63`. **Confidence:** HIGH.

### BC-056: `tracks` lists `slug\tname\tsourcing` per track
**GIVEN** a config with tracks **WHEN** `tracks <cfg>` runs **THEN** exit 0 and each line is `<slug>\t<name>\t<sourcing>` (e.g. `competitive-analysis\tCompetitive Analysis\texternal-only`).
**Source:** `tests/config.bats:62-67`; `factory-config.sh:65-68`. **Confidence:** HIGH.

### BC-057: A track with no `sourcing` defaults to `external-only`
**GIVEN** a track entry omitting `sourcing` **WHEN** `tracks` runs **THEN** the emitted sourcing column is `external-only` (`.sourcing // "external-only"`).
**Source:** `factory-config.sh:67`; consistent with `tests/config.bats:62-67` (2nd track has `primary-source`). **Confidence:** MEDIUM.

### BC-058: Resolves the config via `$FACTORY_CONFIG` when no path argument is given
**GIVEN** `FACTORY_CONFIG` set to a file and no path arg **WHEN** `get '.slug'` runs **THEN** exit 0 and output is the value from that file (e.g. `ot-ics`).
**Source:** `tests/config.bats:69-73`; `factory-config.sh:34-37`. **Confidence:** HIGH.

### BC-059: The shipped template config validates
**GIVEN** `templates/factory.config.template.yaml` **WHEN** `validate` runs **THEN** exit 0 and output contains `PASS` (the template is itself a valid config — protects against template rot).
**Source:** `tests/config.bats:75-79`. **Confidence:** HIGH.

### BC-060: Vector/track entries missing `id`/`name`/`slug` are counted as errors
**GIVEN** a config where some vector lacks `id` or `name`, or some track lacks `slug` or `name` **WHEN** `validate` runs **THEN** each bad entry increments the error count and FAILs (`<n> vector(s) missing id or name`, `<n> track(s) missing slug or name`).
**Source:** `factory-config.sh:98-101`. **Confidence:** MEDIUM.

### BC-061: A config that is not valid YAML dies before field checks
**GIVEN** a config that `yq -e '.'` cannot parse **WHEN** `validate` runs **THEN** it dies "config is not valid YAML" (exit 1) before the required-field loop.
**Source:** `factory-config.sh:90`. **Confidence:** MEDIUM.

### BC-062: Missing config file / unresolvable path dies with exit 1
**GIVEN** an explicit path to a nonexistent file, or `$FACTORY_CONFIG` pointing at a missing file, or no config found walking up from `$PWD` **WHEN** any subcommand resolves the config **THEN** `die` with a specific message, exit 1.
**Source:** `factory-config.sh:30-43`. **Confidence:** MEDIUM.

### BC-063: Unknown subcommand or missing `yq` dies with exit 1
**GIVEN** an unrecognized first arg, or `yq` not on `PATH` **WHEN** the script runs **THEN** `die` ("unknown command…" / "yq … is required"), exit 1.
**Source:** `factory-config.sh:25,46,106-108`. **Confidence:** MEDIUM.

---

# Group 7 — Orchestrator & agent Iron Laws (structural/prose contracts)

These are **not test-backed**. They are enforced by (a) absence of a Write-tool grant, (b) `context.exclude` in workflows, (c) the CI model-family split, and (d) prompt-level Iron Laws the LLM is told to honor. Confidence is MEDIUM where a structural mechanism backs the prose, LOW where only prose asserts it.

### BC-064: The orchestrator never writes, reviews, judges, or commits
**GIVEN** the orchestrator agent **WHEN** it runs a workflow **THEN** it coordinates only — dispatches agents, runs the loop, honors gates — and writes no corpus file and makes no commit. Structurally backed: its `tools:` grant is `[Read, Grep, Glob, Bash]` (no `Write`).
**Source:** `orchestrator.md:6-11` (tool grant), `:24-25` (Iron Law). **Confidence:** MEDIUM (tool-absence is structural; "Bash" still allows a `git commit` in principle, so the no-commit law itself is prose).

### BC-065: The orchestrator refuses to run an invalid workflow
**GIVEN** a `.lobster` workflow **WHEN** the orchestrator starts **THEN** it runs `lobster-parse validate` then `order` first and refuses to run if validation fails. (Mechanically, `order` exits 2 on an invalid workflow — BC-051 — so the orchestrator has no order to dispatch.)
**Source:** `orchestrator.md:29`; reinforced by `lobster-parse:131-133`. **Confidence:** MEDIUM.

### BC-066: The orchestrator dispatches each step only after its `depends_on` complete; independent steps may run together
**GIVEN** a validated topo order **WHEN** dispatching **THEN** a step launches only after all its dependencies finish; independent steps may run concurrently.
**Source:** `orchestrator.md:30`. **Confidence:** MEDIUM (topo order from `lobster-parse` is the structural backbone; concurrency is prose).

### BC-067: The orchestrator honors `context.exclude` info-asymmetry walls and does not narrate around them
**GIVEN** a review step with `context.exclude` (e.g. `[prior-review-passes, drafter-reasoning, orchestrator-summary]`) **WHEN** dispatching that reviewer **THEN** the orchestrator never passes the excluded context and does not summarize it back in. Structurally reinforced by read-only reviewer tool grants.
**Source:** `orchestrator.md:31`; `adversary-reviewer.md:22-24`; `citation-verifier.md:24-26`. **Confidence:** MEDIUM.

### BC-068: The convergence loop re-dispatches a FRESH reviewer each pass and is hard-capped
**GIVEN** a `loop` step **WHEN** the orchestrator runs it **THEN** it re-dispatches a fresh reviewer each pass, tracks novelty = new/(new+dup), continues until `VERDICT: PASS` with novelty < `novelty_threshold` for `clean_passes_required` consecutive passes, **and stops at `max_passes` (default 6)** even if not converged.
**Source:** `orchestrator.md:32`; `build-track/SKILL.md:37`. **Confidence:** MEDIUM.

### BC-069: A capped exit sets `LOOP_CAPPED=true`, carries `MUST_FIX_REMAINING`, and is NOT a failure
**GIVEN** the loop reaches `max_passes` without converging **WHEN** it exits **THEN** set `LOOP_CAPPED = true`, carry the remaining MUST-FIX count forward, do NOT abort.
**Source:** `orchestrator.md:32`; `build-track/SKILL.md:13,40`. **Confidence:** MEDIUM.

### BC-070: At a capped gate, proceed to a FLAGGED commit; otherwise stop if criteria unmet
**GIVEN** a `gate` step **WHEN** evaluated **THEN** stop the workflow if criteria unmet — **except** if the preceding loop capped and the step declares `on_capped_exit`, in which case proceed to commit and carry the `flag_pr` text ("did not fully converge — M MUST-FIX remain after N passes") downstream. For `on_cap: surface-to-human`, carry the unconverged status into the `human-approval` prompt.
**Source:** `orchestrator.md:33`; `build-track/SKILL.md:40`. **Confidence:** MEDIUM.

### BC-071: A capped draft is NEVER presented as a PASS
**GIVEN** a capped exit **WHEN** committing/reporting **THEN** the branch/PR is explicitly flagged; "never silently present a capped draft as converged." A capped exit is not a license to bail early — "you still loop to the cap."
**Source:** `build-track/SKILL.md:13,40`. **Confidence:** LOW (prose-only honesty contract).

### BC-072: At a `human-approval` step, the orchestrator stops and never self-approves
**GIVEN** a `human-approval` step **WHEN** reached **THEN** stop and surface for human sign-off; never self-approve. (Irreversible/outward actions — publish, external delivery — are always human-gated.)
**Source:** `orchestrator.md:33,39`. **Confidence:** MEDIUM (structurally a workflow terminal; enforcement is prose).

### BC-073: The state-manager is the SOLE committer and runs LAST
**GIVEN** a production burst **WHEN** committing **THEN** only the state-manager commits — one burst → one atomic commit, authored only by it, after researcher/citation-verifier/adversary finish. Structurally: `commit` is the DAG-terminal step (BC-041) and no other agent's body invokes a commit.
**Source:** `state-manager.md:17,25-27`; reinforced by `tests/lobster.bats:42` (BC-041). **Confidence:** MEDIUM.

### BC-074: The state-manager refuses to commit without recorded review verdicts / on a REVISE
**GIVEN** a burst **WHEN** the state-manager prepares to commit **THEN** it first verifies citation-verifier verdicts and the adversary PASS/REVISE exist; it never commits a doc the adversary marked REVISE or with unresolved MUST-FIX — surface the gap instead.
**Source:** `state-manager.md:27,31`. **Confidence:** LOW (prose-only; no checker enforces the precondition).

### BC-075: In CI the state-manager only WRITES `.factory/STATE.md`; the workflow owns the branch round-trip
**GIVEN** a CI runner (fresh checkout) **WHEN** the state-manager runs **THEN** it writes the workspace `.factory/STATE.md` only and does NOT fetch/commit/push `factory-artifacts` (the Action's restore/persist steps own that); if `STATE.md` is absent it creates it (first run). Locally, it commits+pushes the branch itself. It never commits `.factory/` onto `main` or a corpus PR branch.
**Source:** `state-manager.md:34-45`. **Confidence:** MEDIUM (structural branch model; CI/local split is prose).

### BC-076: Reviewers are blind by construction (read-only tools + asymmetry)
**GIVEN** the adversary-reviewer and citation-verifier **WHEN** they run **THEN** they see only the artifact-as-written (adversary) or claim+source (verifier) — never prior passes, drafter reasoning, or orchestrator summaries; they emit findings only and do not edit the corpus. Structurally: both have `tools: [Read, Grep, Glob(, WebFetch, WebSearch)]` — no `Write`/`Edit`. In CI the adversary runs as a different model family (P6).
**Source:** `adversary-reviewer.md:1-10,22-24,38`; `citation-verifier.md:1-12,24-26,39`. **Confidence:** MEDIUM (tool-absence + CI family split are structural; the "blindness" itself is enforced by `context.exclude` + prompt).

---

## Confidence ledger

| Confidence | Count | Where |
|---|---:|---|
| **HIGH** (test-backed) | 31 | BC-001…009, 015…019, 025…027, 032…034, 039…047, 052…056, 058, 059 |
| **MEDIUM** (logic-derived) | 39 | BC-010…014, 020…024, 028…031, 035…038, 048…051, 057, 060…076 (the structural-backed subset), HOOK-A/B |
| **LOW** (prose-inferred) | 4 | BC-014 risk-edge note, BC-071, BC-074; plus the LOW caveat on BC-064 |

> Headline counts (BC IDs only, the two HOOK-* cross-cutting contracts counted under MEDIUM): **76 numbered BCs + 2 cross-cutting = 78 contracts.** HIGH: 31 · MEDIUM: 43 · LOW: 4. (BC-014 and BC-064 carry an embedded LOW caveat but are filed at their primary confidence.)

---

## Cross-reference to prior passes (alignment check)

- **Pass 2 §2b.2 rule #1 (cite-or-flag-or-drop)** ↔ BC-001…014: the hook is the deterministic third enforcement leg; the bats cases pin the exact accept-set (URL, `.md` ref, `[[wikilink]]`, `[^]`, frontmatter `sources:`, the four flags) and the `MIN_CLAIM_LINES` stub threshold — resolving Pass-2 gap #1. **Aligned.**
- **Pass 2 rule #4 (layer discipline)** ↔ BC-015…024: confirms L_n must observe L_(n-1); L1→external; missing/skip/non-numeric `layer-observes` denied. **Aligned.**
- **Pass 2 rule #5 (observe-and-report, P5)** ↔ BC-032…038: the bright-line hook is the precision half; the editorial-sweeper is the recall half (not test-backed here). **Aligned.**
- **Pass 1 §3 (lobster step semantics)** ↔ BC-039…051: tests confirm validate/order/cycle/unknown-step/bad-type/missing-required/empty-steps and the topo guarantees; `commit`-last and `human-approval`-in-L6 are asserted in the order output. **Aligned.**
- **Pass 1/2 sole-committer & convergence cap** ↔ BC-068…075: the *structure* (commit-terminal, read-only reviewers, branch model) is verified; the *honesty* of the capped exit (BC-071) and the no-REVISE-commit precondition (BC-074) are prose-only — flagged LOW.

---

## Resume checkpoint

```yaml
pass: 3
status: complete
files_read_this_pass: 11   # 3 prior pass outputs + 4 bats suites + 4 hooks + lobster-parse + factory-config.sh (+ 4 agents/skill for Group 7)
bcs_drafted: 78            # 76 numbered + 2 cross-cutting (HOOK-A/B)
confidence: {HIGH: 31, MEDIUM: 43, LOW: 4}
components_covered: {require-citation, layer-discipline-guard, protect-secrets, forbidden-phrase-guard, lobster-parse, factory-config.sh, orchestrator+agent-iron-laws}
test_suites_covered: [config.bats(7), hooks.bats(9), hooks-v05.bats(11), lobster.bats(8)]   # 35 @tests total
gaps_resolved: [pass2-gap-1 claim-disposition-function-contract, pass1-gap-6 BCs-from-tests]
timestamp: 2026-06-01T00:00:00Z
next_pass: 4
next_pass_name: NFR Extraction
```

## Remaining gaps / next candidate scope (untested behaviors, function-level depth)

1. **No agent behavior is test-backed (the entire Group 7 is MEDIUM/LOW).** The convergence-loop math (novelty < 0.15 × 3 clean passes, cap at 6), the sole-committer/no-REVISE precondition, and the info-asymmetry walls have **no executable test** — only prompt prose + structural tool-grants. A high-value future test would simulate a capped exit and assert the PR-flag text. **Candidate Pass-3 deepening target.**
2. **Hook over-permissiveness, untested.** BC-014's `[a-z0-9_-]+\.md` matcher means *any* lowercase token ending `.md` (even a non-citation filename) satisfies require-citation — a possible false-allow with no negative test. Likewise the citation scan runs over the *whole content* (frontmatter included), so a stray `sources:`-looking line passes. Worth a negative bats case.
3. **No test exercises the `jq`-missing / `yq`-missing fail-closed paths** (BC-HOOK-A, BC-063) — asserted from `command -v` guards only. MEDIUM until a test stubs a missing dependency.
4. **`lobster-parse steps` subcommand has no test** (BC adjacent to BC-039…051; the `steps` output format `name\ttype\tref` is logic-only). Add to the suite for completeness.
5. **factory-config `editorial` and `path` subcommands untested** — `vectors`/`tracks`/`get`/`validate` are covered; `editorial` (JSON dump) and `path` (resolution print) are logic-only.
6. **Gate `criteria`-map idiom (pm-doc-chain `dev-readiness-check`) is unverified by tests** — Pass 1 §3.4 found two gate idioms; only the boolean `pass_when` path is reachable from build-track's order. The criteria-map (`MVF_SCOPE: clear`, …) is orchestrator-interpreted with no parser or test coverage.
7. **Budget-threshold enforcement (Pass-2 gap #4) still has no located enforcer** — `budget.thresholds` is declarative config; no hook/CLI/test enforces `warn/alert/pause/hard_stop`. Pass 4 (NFR) should confirm whether enforcement is in an Action template or unimplemented (a real gap).
8. **Chain-ordering / first-deny-wins behavior** (BC-HOOK-B) is asserted from `hooks.json` order, not from an integration test running all four hooks against one payload. A composite test would pin "protect-secrets fires before require-citation."
```
