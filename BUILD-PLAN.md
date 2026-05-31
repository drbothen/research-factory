# Research Factory — Build Plan

**Status:** Plan / pre-build (v0).
**Author context:** synthesized 2026-05-30 from the OT/ICS research corpus process, the `vsdd-factory` / `secops-factory` / `brain-factory` reference implementations, the StrongDM "Dark Factory" manifesto, the `pm-process` operating model, and external validation research (cited inline).
**Audience:** an agent or engineer with **no prior context**. This document is self-contained: read it top to bottom and you can build the system.

---

## 0. TL;DR — what we are building

A **generic, dynamic "research factory"**: an autonomous, GitHub-Actions-backed pipeline that takes a *seed* (a topic/market/segment described in a few sentences plus a source list) and grows a **rigorously-sourced, auditable research corpus**, then graduates that corpus into **product-management deliverables** (concept narratives → PRDs → user stories).

It is **dynamic**: the machinery is domain-agnostic. A new market = a new **config + seed**, not new code. The first instance is the **OT/ICS Security market**; the design assumes many more will follow, plus a **cross-market portfolio layer** that rolls findings up across all markets.

Three things make this concrete and low-risk to build:
1. It is a **Claude Code plugin** following the exact packaging contract already proven in `secops-factory` and `brain-factory` (both authored under GitHub `drbothen`, where the engine will also live).
2. Its research+review loop is a **direct generalization of the OT corpus's existing "Claude drafts → Codex reviews" two-pass process** and its L1→L5 layer model — a process that already works by hand.
3. The orchestrator → parallel specialist subagents → **separate citation-verification pass** → external state architecture is the **independently-validated industry consensus** (Anthropic's multi-agent research system; see §13).

**What it is NOT:** it is *not* a "no human review" factory. The Dark Factory's "code must not be reviewed by humans" rule does **not** transfer to research — a corpus's correctness is *faithfulness to source*, which has no automated oracle and is exactly where LLMs fail silently. Human + adversarial review gates are **load-bearing**, not optional (see §13.3, §10).

---

## 1. Design principles (the constitution)

Adapted from the Dark Factory manifesto, tempered by the validation research (§13). These go in the engine's `docs/FACTORY-SOUL.md` and are injected into every agent.

| # | Principle | Origin | Adaptation for research |
|---|---|---|---|
| P1 | **Seed → validation harness → feedback loop. Tokens are the fuel.** | Dark Factory | Seed = topic + scope + source inventory. Validation = the Citation Test + adversarial review. Feedback = review findings re-enter as work items until the corpus converges. |
| P2 | **Agents draft; agents *and humans* review.** | Dark Factory (modified) | Code factories have a hard oracle (does it run?). Research does not — keep the adversarial reviewer **and** a human gate on judgment/publication. "No human review" is rejected for research. |
| P3 | **Every claim must be *source-faithful*, not merely cited.** | OT Citation Test + 2025 RAG research | A URL is not enough; the cited source must actually *support* the claim. A dedicated citation-verifier checks this (NLI-style), catching the "correctness ≠ faithfulness" failure. |
| P4 | **Anchor-not-strip.** | OT corpus | Imperfect/unsourced claims are flagged + reframed, never silently deleted. Drop only AI-invented (Type-2) content. |
| P5 | **Observe-and-report through L4; judgment only at L5; productization only in the PM pipeline.** | OT corpus | The corpus stays opinion-free until the explicit judgment layer. This is the *same boundary* as PM intake — see §4. |
| P6 | **Cognitive diversity: builder ≠ reviewer (different model family).** | vsdd/secops/brain | The adversarial reviewer must run a different model family than the drafting agent. |
| P7 | **Quantitative convergence, not "looks done."** | vsdd-factory | Adversarial review loops until *finding novelty* decays below threshold for N consecutive passes (§10). |
| P8 | **External filesystem is memory; state survives sessions.** | Dark Factory + vsdd | All pipeline state lives on disk (`.factory/`) so any session resumes with zero prior context. |
| P9 | **Scale effort to the task; document what you dropped.** | Anthropic research findings | Explicit effort-scaling rules prevent agent over-spawning; "document the failed sourcing attempt" prevents silent truncation. |
| P10 | **Generic engine, per-market config.** | This project's core requirement | No market-specific logic in the engine. Markets differ only by config + seed. |

---

## 2. Architecture at a glance

```
                         ┌──────────────────────────────────────────────┐
                         │  ENGINE  (research-factory plugin, versioned) │
                         │  domain-agnostic: agents, skills, workflows,  │
                         │  hooks, gates, templates, layer model L1–L6   │
                         └───────────────┬──────────────────────────────┘
                    installed + pinned by every instance
        ┌───────────────────────┬───────┴───────────┬───────────────────────┐
        ▼                       ▼                   ▼                        ▼
┌───────────────┐      ┌───────────────┐    ┌───────────────┐       ┌──────────────────┐
│ ot-ics-research│     │ market2-research│   │ market3-research│      │ research-portfolio│
│  (instance #1) │     │  (instance #2) │   │  (instance #3) │      │   (L6 cross-market)│
│ config + seed  │     │ config + seed  │   │ config + seed  │      │ reads each L4/L5   │
│ + corpus + .factory│ │ + corpus       │   │ + corpus       │      │ → portfolio briefs │
│ + Actions caller│    │ + Actions caller│   │ + Actions caller│     │ + Actions          │
└───────────────┘      └───────────────┘    └───────────────┘       └──────────────────┘
  ENGINE + TEMPLATE → org `drbothen` (generic tooling)
  INSTANCES + PORTFOLIO → org `1898andCo` (company research content)
```

**Org split:** the **engine is generic tooling** and lives under `drbothen` alongside the other factories (`drbothen/vsdd-factory`, `drbothen/brain-factory`, `drbothen/secops-factory`). The **research corpora are 1898 business content** and live under `1898andCo`. Cross-org templating works because the owner (`drbothen`) is a member of `1898andCo`.

- **Engine** = one Claude Code plugin repo, `drbothen/research-factory`. Stateless, read-only at runtime. Versioned + released to the `drbothen/claude-mp` marketplace family.
- **Template** = `drbothen/research-factory-template`, the thin starter an instance is generated from (engine-adjacent tooling).
- **Instance** = one repo per market (`1898andCo/ot-ics-research`, …). Holds config, seed, the growing corpus, per-instance `.factory/` state, and a thin GitHub Actions caller that invokes the engine headlessly.
- **Portfolio** = `1898andCo/research-portfolio`. Reads each instance's L4/L5 outputs (git submodules or the GitHub API) and produces the cross-market L6 synthesis (decision per §6 / user: build in v1).

---

## 3. The generic layer model (L1–L6)

The OT corpus's L1–L5 stack, generalized and extended with a cross-market L6. **Each layer observes only the layer below it** — this is what keeps every conclusion auditable, and it is the engine's spine.

| Layer | Role | Citation target | Per-instance? |
|---|---|---|---|
| **L1** | Raw external sourcing (per source) | a named external primary source (URL, doc, person+venue+date) | instance |
| **L2** | Artifact observation (per L1 artifact) | a specific L1 artifact/section | instance |
| **L3** | Track synthesis (across L2 in one track) | L2 docs in this track | instance |
| **L4** | Cross-track synthesis (within one market) | named L3 findings docs | instance |
| **L5** | Judgment (within one market) | named L4 observations, *labeled as judgment* | instance |
| **L6** | **Portfolio synthesis (across markets)** | named L4/L5 of each market | **portfolio repo** |

L1–L4 are pure observation. **L5 is the only place opinion enters within a market.** L6 is cross-market judgment. The **PM pipeline (§4) consumes L4/L5** — productization ("what to build") is downstream of the corpus, never inside it.

> The set of **evidence vectors** (OT has 7: Vendor, Operator, Influencer, Hearings, Governance, Incident, Capital) is **per-instance config**, not hardwired. Every market defines its own vector schema; the engine only enforces that *some* vector-coverage table exists at L3. This is the key generalization that makes the factory dynamic.

---

## 4. The two coupled pipelines: Research → Productization

The factory automates **two** chained processes. The research corpus is the upstream; the PM documentation chain is the downstream consumer. They meet at the L5 judgment boundary.

```
SEED ─▶ [Research pipeline]                         [PM / productization pipeline]
        L1 ▸ L2 ▸ L3 ▸ L4 ───────(observe)        intake ▸ evaluation ▸ concept narrative
                         └▶ L5 (judgment) ─────────▶  ▸ 6-pager ▸ PRD ▸ user stories ▸ acceptance plan
                              (the same boundary)        (the pm-process gate ladder)
```

- **Research pipeline** = the OT-corpus process: ingest sources → build per-track L2/L3 → synthesize L4 → (optional) L5 judgment. Pure observe-and-report through L4.
- **PM pipeline** = the documented `pm-process` six-stage operating model (intake → evaluation → pipeline → delivery → distribution → sales-readiness) and its **doc gate ladder** (intake ticket → 2-pager concept narrative → 6-pager → 7-section PRD → user stories → acceptance plan). It takes a market finding/judgment as *intake* and produces dev-ready specs. The `pm-process` repo already contains a deployable doc-generation agent (`pm-docs-gpt-prompt.md`) and a worked example chain (the "OPRA" assessment built from the OT corpus) — these become engine skills/templates directly.

This coupling is why the factory is valuable: it doesn't just produce research, it **graduates research into productizable, sourced, gated deliverables** — exactly the "machine" the PM operating model (Steve's PROC-MODEL) describes.

---

## 5. Engine ⟷ Instance split (the config contract)

Everything domain-specific lives in a per-instance `factory.config.yaml` + a `seed/` directory. The engine reads these; it contains **zero** market logic.

### 5.1 `factory.config.yaml` schema (every instance provides this)

```yaml
# --- identity ---
market: "OT/ICS Security"            # human name
slug: "ot-ics"                        # kebab id used in paths/branches
audience: "Burns & McDonnell / 1898 & Co. colleagues + their AI assistants"
phase: "observe-and-report"           # or "judgment" | "productization"

# --- the seed (Dark Factory P1) ---
seed:
  scope_doc: "seed/scope.md"          # what "done" looks like; the research question
  source_inventory: "seed/sources.md" # where evidence comes from
  existing_corpus: "corpus/"          # path if migrating an existing corpus (OT has one)

# --- evidence vectors (PER-MARKET — this is the key generalization) ---
vectors:
  - {id: V1, name: "Vendor/competitor",      desc: "what vendors build/say/sell"}
  - {id: V2, name: "Operator/user",          desc: "what buyers experience"}
  - {id: V3, name: "Influencer/practitioner",desc: "what tracked experts say publicly"}
  - {id: V4, name: "Hearings/conference",    desc: "testimony, keynotes"}
  - {id: V5, name: "Governance/regulation",  desc: "regs, standards, audit regimes"}
  - {id: V6, name: "Incident/forensic",      desc: "named events as empirical tests"}
  - {id: V7, name: "Capital/market",         desc: "M&A, hiring, investment flows"}

# --- tracks (the research domains; per-market) ---
tracks:
  - {slug: competitive-analysis, name: "Competitive Analysis", sourcing: external-only}
  - {slug: regulatory-governance, name: "Regulatory & Governance", sourcing: primary-source}
  # ... 27 for OT; a new market defines its own

# --- editorial profile (per-market, mostly inherited generic defaults) ---
editorial:
  forbidden_phrases_extra: []         # market-specific additions to the generic inventory
  per_track_sourcing_default: external-only
  canonical_values: "seed/canonical-values.md"  # source-of-truth counts/dates/facts

# --- review + autonomy ---
review:
  builder_model_tier: implementation  # sonnet
  reviewer_model_tier: adversary      # MUST be a different family than builder
  convergence:
    novelty_threshold: 0.15
    clean_passes_required: 3
autonomy_level: 3                      # 3 = human gate on every merge (start here)

# --- deliverables this market produces ---
deliverables:
  research: [l3-findings, l3-tldr, track-summary, l4-synthesis]
  pm: [concept-narrative, six-pager, prd, user-stories, acceptance-plan]  # opt-in per finding
```

### 5.2 What is generic (engine) vs per-instance (config)

| Generic engine (build once) | Per-instance config/seed |
|---|---|
| L1–L6 layer model + the "observe only below" rule | the topic/scope (the seed) |
| Citation Test, anchor-not-strip, source-faithfulness check | the evidence-vector schema |
| The 6 review dimensions + quantitative convergence | the track list + per-track sourcing rules |
| Quality tiers + promotion gates | the canonical-values / source-of-truth set |
| Orchestrator + all specialist agents | the forbidden-phrase additions / editorial profile |
| `.lobster` workflows, hooks, gates, state mgmt | the source inventory |
| Dashboard generator, editorial-sweep, consistency-check | target audience + which deliverables to emit |
| GitHub Actions workflows + the headless runner | the per-instance Actions caller + secrets |
| The PM doc gate ladder + templates | which findings to graduate into PM docs |

---

## 6. Repo topology & how markets are instantiated

(Per user decision: **engine-as-plugin + repo-per-topic**, and **L6 portfolio in v1**.)

```
drbothen/                     ← generic tooling (with the other factories)
  research-factory            ← ENGINE plugin (versioned, released to marketplace)
  research-factory-template   ← thin starter repo (config stub + seed stub + Actions caller)
1898andCo/                    ← company research content
  ot-ics-research             ← INSTANCE #1 (OT/ICS) — migrate the existing 27-track corpus here
  <market2>-research          ← INSTANCE #2 (created from template)
  research-portfolio          ← L6 cross-market synthesis (reads each instance's L4/L5)
```

**Adding a market** (the dynamic requirement, made concrete) — `/research-factory:init-market <slug>`:
1. `gh repo create 1898andCo/<slug>-research --template drbothen/research-factory-template --private`
2. The `init-market` skill interviews for the seed (scope, vectors, tracks, sources), writes `factory.config.yaml` + `seed/`.
3. Installs the per-instance GitHub Actions (the engine's `templates/github-action-templates/*`).
4. Initializes `.factory/` state (orphan-branch worktree) + writes `STATE.md`.
5. Registers the market in `research-portfolio`'s manifest so L6 rollups include it.
6. First run is human-gated end-to-end (autonomy 3) until the market's editorial profile is tuned.

> **Engine update propagation:** instances pin the engine plugin by version. A `bump-engine` Action opens a PR in each instance to move to a new engine version, re-running CI before merge — so engine upgrades roll out controllably across N markets.

---

## 7. Plugin anatomy (the engine)

> **Yes, the engine is a Claude Code plugin** — because the *builder, orchestration, and fail-closed gate layer* run on Claude Code (the primary harness), matching all three reference factories and the existing OT process. Codex and Gemini do **not** load Claude Code plugins; they run as review steps that consume **vendor-neutral** files from the same repo via `prompt-file`. So the repo holds two kinds of content:
>
> | Plugin-native (Claude Code only) | Vendor-neutral (any CLI, via prompt-file) |
> |---|---|
> | `agents/*.md`, `skills/*/SKILL.md`, `commands/*.md`, `hooks/hooks.json` | `rules/`, `checklists/`, `docs/review-spec.md` (= the OT `codex-review-process.md`), `templates/`, `*.lobster` (plain YAML) |
>
> **Design rule:** keep every cross-vendor-consumed artifact vendor-neutral (plain markdown/YAML, no Claude-Code-only constructs) so Codex/Gemini read the same source of truth Claude does. Only the Claude-side execution machinery is plugin-specific. The fail-closed **hook gate layer is the main reason not to go harness-neutral** — it's a Claude Code mechanism a plain repo would lose. (Cross-CLI sequencing lives in the GitHub Actions workflow YAML, §12; within-Claude sequencing lives in the plugin's `.lobster`/orchestrator.)

Follows the **proven Claude Code factory packaging contract** observed in `secops-factory` (shipped) and specified in `brain-factory`. Non-negotiable invariants:

1. **Double-manifest nesting.** Root `.claude-plugin/marketplace.json` (registry) + `plugins/research-factory/.claude-plugin/plugin.json` (the plugin). Both are **metadata-only** (name/version/author/license/keywords) — they never enumerate agents/skills.
2. **Convention-over-config discovery.** Capabilities found by directory: `agents/*.md`, `skills/<name>/SKILL.md`, `commands/<name>.md`, `hooks/hooks.json`.
3. **`${CLAUDE_PLUGIN_ROOT}` everywhere** for internal references (the relocatability anchor).
4. **Engine vs target separation.** Plugin is stateless/read-only; all mutable state lives in the *instance* repo's `.factory/`. An `/init-market` skill scaffolds the target.
5. **Self-dogfooding.** The engine repo carries its own `.factory/` (built by `vsdd-factory`).

```
research-factory/
├── .claude-plugin/marketplace.json
├── plugins/research-factory/
│   ├── .claude-plugin/plugin.json            # metadata only
│   ├── agents/
│   │   ├── orchestrator/orchestrator.md       # coordinator; NEVER writes/executes
│   │   ├── orchestrator/*-sequence.md         # per-pipeline playbooks (disable-model-invocation)
│   │   ├── researcher.md                       # builder (sonnet) — gathers + drafts L1/L2
│   │   ├── synthesizer.md                      # builder — L3/L4 synthesis
│   │   ├── judgment-writer.md                  # L5 (judgment, human-gated)
│   │   ├── citation-verifier.md                # source-faithfulness pass (P3) — read-only
│   │   ├── adversary-reviewer.md               # different model family; read-only; info-asymmetry
│   │   ├── consistency-validator.md            # fresh-context cross-doc audit
│   │   ├── pm-doc-writer.md                     # concept→PRD→stories (from pm-process)
│   │   ├── editorial-sweeper.md                # forbidden-phrase + drift scan
│   │   ├── state-manager.md                     # sole committer of .factory/ (runs LAST)
│   │   ├── dashboard-builder.md                 # regenerates status data
│   │   └── github-ops.md                        # gh CLI on behalf of no-shell agents
│   ├── skills/<verb>/SKILL.md                  # Iron Law + Announce + Red Flags + Steps
│   ├── commands/<verb>.md                      # one-line shims → Skill tool
│   ├── workflows/*.lobster                     # YAML pipeline DAGs (§9)
│   │   └── phases/                              # nested sub-workflows
│   ├── hooks/{hooks.json, *.sh}                # fail-closed gates (§10)
│   ├── templates/
│   │   ├── corpus/                              # L2/L3/track-summary/L4 doc templates
│   │   ├── pm/                                  # concept-narrative/6-pager/PRD/stories/acceptance
│   │   └── github-action-templates/*.yml       # installed into instances (§12)
│   ├── data/                                    # generic knowledge (the layer model, vectors concept)
│   ├── rules/research-protocol.md              # commit format, naming, path conventions
│   ├── checklists/                              # the 6 review-dimension checklists
│   ├── docs/{FACTORY.md, FACTORY-SOUL.md, CONVERGENCE.md, LAYER-MODEL.md}
│   ├── bin/{lobster-parse}                     # workflow parser (headless exec = vendor CLI Actions, §8/§12)
│   └── tests/{*.bats, run-all.sh}
├── .github/workflows/{ci.yml, release.yml}
└── README.md  CHANGELOG.md  LICENSE  CLAUDE.md
```

**SKILL.md anatomy** (the proven 5-part template): frontmatter (`name`, `description`, `argument-hint`) → **Iron Law** (one-line non-negotiable, e.g. *"No claim ships without a source-faithfulness check"*) → **Announce at Start** (verbatim persona line) → **Red Flags** table (rationalization ↔ reality) → ordered **Steps** referencing `${CLAUDE_PLUGIN_ROOT}/...`.

---

## 8. Agents & model routing

**Roster** (model tier in frontmatter; cross-family adversary independence per P6):

| Agent | Tier / model | Writes? | Role |
|---|---|---|---|
| `orchestrator` | coordinator (no model invocation of its own) | no | parse `.lobster`, dispatch agents in `depends_on` order; never writes/executes |
| `researcher` | implementation (Sonnet) | yes (drafts) | gather sources, draft L1/L2 with citations |
| `synthesizer` | implementation (Sonnet) | yes | L3 findings (+ vector-coverage table), L4 cross-track |
| `judgment-writer` | judgment (Opus) | yes (human-gated) | L5 judgment; every statement cites an L4 obs |
| `citation-verifier` | judgment (Opus) | findings only | **source-faithfulness**: does the cited source actually support the claim? (P3) |
| `adversary-reviewer` | **adversary (different family — OpenAI `gpt-5.5` / `gpt-5.3-codex`)** | findings only | the 6-dimension review; info-asymmetry wall (never sees prior passes) |
| `consistency-validator` | validation | findings only | fresh-context cross-doc audit (broken links, count drift, layer-tag) |
| `pm-doc-writer` | implementation/judgment | yes | concept narrative → PRD → user stories from L4/L5 (pm-process) |
| `editorial-sweeper` | validation (Haiku) | findings only | forbidden-phrase + corpus-voice drift scan |
| `state-manager` | validation | `.factory/` only | **sole committer** of state; runs **last** in every burst (prevents citation version races) |
| `dashboard-builder` | validation | yes | regenerate status/dashboard data |
| `github-ops` | restricted | no | execute `gh` for agents lacking shell |

**Model routing = three vendor CLIs as GitHub Actions (validated — §12.1).** Cross-family independence (P6) is achieved natively by assigning each role to a different vendor's official CLI Action, not a LiteLLM proxy. This directly continues the OT corpus's existing "Claude drafts → Codex reviews" loop and adds Gemini as a third independent family.

| Role | Executor (pinned Action) | Model literal (verify at build, see ⚠) | Why |
|---|---|---|---|
| builder (researcher/synthesizer/judgment/pm-doc/state-manager) | **Claude Code** `anthropics/claude-code-action@v1` | `claude-opus-4-8` (judgment) · `claude-sonnet-4-6` (impl) · `claude-haiku-4-5` (validation) | loads the engine plugin + skills (see ⚠ plugin-enable note); the drafting agents live here |
| adversary-reviewer | **OpenAI Codex** `openai/codex-action@v1` (`codex exec`) | `gpt-5.5` (default) or `gpt-5.3-codex` | different family than builder; runs the review spec as a `prompt-file` (the existing `codex-review-process.md`); read-only sandbox |
| citation-verifier / consistency tie-break | **Gemini CLI** `google-github-actions/run-gemini-cli@v0` | `gemini-3-pro` (confirm exact ID at build) | a *third* independent family for source-faithfulness + cross-doc audit |

Within the Claude builder, sub-tiers still apply (`judgment`=Opus · `implementation`=Sonnet · `validation`=Haiku) selectable via `--model`. Codex/Gemini don't load Claude Code plugins, so reviewers receive a **markdown prompt-file** (review spec) + the target doc + the checklist — exactly how the OT corpus already drives Codex. (A local LiteLLM proxy remains an *optional* convenience for off-CI/local dev only — it is not required for the Actions path.)

> **⚠ Build-time verification (validated 2026-05-30, fast-moving):** Model IDs and Action tags age quickly — confirm against vendor docs at build time. Current as of this writing: Anthropic `claude-opus-4-8`/`claude-sonnet-4-6`/`claude-haiku-4-5` ([models](https://platform.claude.com/docs)); OpenAI Codex `gpt-5.5`/`gpt-5.4`/`gpt-5.3-codex`, select via `codex exec --model <id>` ([Codex models](https://developers.openai.com/codex/models)); Gemini via `gemini -p` (literal model ID e.g. `gemini-3-pro` — reconfirm). Headless invocation: `claude -p` · `codex exec` · `gemini -p` (all confirmed). `run-gemini-cli` latest stable = v0.1.22 (pin `@v0`).
>
> **⚠ Plugin-enable note (load-bearing):** Claude Code headless mode reuses the same hooks/settings/permissions as interactive ([headless docs](https://code.claude.com/docs/en/headless)), so the fail-closed hook gates DO fire in CI — **but the engine plugin must be explicitly enabled in the Action's environment** (marketplace install or a `.claude/settings.json` plugin reference). It is *not* auto-active merely by living in the repo. The v0.1 acceptance test (§15) must confirm a `require-citation` PreToolUse hook actually blocks a write in a headless run before any autonomy is granted.

**Rules:** adversary + citation-verifier never share a family with the builder and are never skipped; **budget caps span three vendors** (Anthropic + OpenAI + Google keys, each a separate GitHub Secret) with warn/alert/pause/hard-stop tiers; if budget forces a downgrade on the critical path, **pause** rather than continue underpowered (compounding-correctness constraint).

> **The CLIs are workers, not the orchestrator.** Each Action runs one agent's job. Sequencing (researcher → citation-verify → adversary → consistency), the convergence loop (≥3 clean passes, novelty<0.15), and state hand-off are the engine's `.lobster` DAG + the workflow YAML (`needs:`/matrix) + `.factory/` state — not provided by any single CLI.

---

## 9. Workflows (`.lobster` — pipeline as data)

Pipelines are **YAML DAGs**, not prose, parsed by `bin/lobster-parse`. Each step: `name`, `type` (`agent`|`skill`|`gate`|`human-approval`|`loop`|`parallel`|`sub-workflow`), `agent`/`skill`, `depends_on`, `on_failure`, `max_retries`, `timeout`, optional `condition`, optional `context.exclude` (info-asymmetry walls).

Core workflows the engine ships:

| Workflow | Trigger | Shape |
|---|---|---|
| `ingest-source.lobster` | new source dropped in `seed/inbox/` or cron | capture → quarantine-fetch → researcher (L1) → editorial-sweep → citation-verify → adversary → state-manager → commit |
| `build-track.lobster` | per track | parallel researcher legs per dimension → synthesizer (L3 findings + vector table) → editorial-sweep → citation-verify → adversary loop (≥3 clean) → state-manager |
| `cross-track-synth.lobster` | all tracks ≥ Beta | load track summaries (index-only) → synthesizer (L4) → consistency-validator → adversary loop → human-approval |
| `judgment.lobster` | human-initiated | judgment-writer (L5, each claim cites L4) → adversary → **human-approval (required)** |
| `pm-doc-chain.lobster` | a finding is selected for productization | intake → concept-narrative → [gate: worth pursuing?] → 6-pager → PRD → [Dev-Readiness Check] → user-stories → acceptance-plan; each step gated per pm-process ladder |
| `portfolio-synth.lobster` | cron (portfolio repo) | pull each instance's L4/L5 → synthesizer (L6) → adversary → human-approval → cross-market brief |
| `maintenance.lobster` | weekly cron | consistency-validator sweep → editorial-sweep all → dashboard rebuild → open PR with fixes |

**Effort scaling (P9)** is encoded in the orchestrator prompt: 1 researcher for a simple source, 2–4 for comparisons, matrix fan-out for a full track. This prevents the documented over-spawning failure.

---

## 10. Gates & verification (three layers)

**(a) Declarative gates** in `.lobster`: `type: gate` (criteria like `CITATION_FAITHFULNESS: PASS`) and `type: human-approval` (judgment, L4 sign-off, publication, PM productization).

**(b) Fail-closed hooks** (`hooks/hooks.json`, deterministic bash, `set -euo pipefail`, <100ms) enforce Iron Laws at the harness level so agents can't bypass. A blocking `PreToolUse` hook emits the exact deny contract — `{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "<why>"}}` (verified against the [Claude Code hooks reference](https://code.claude.com/docs/en/hooks)); **plugin `hooks.json` uses the wrapped `{"hooks": {<event>: [...]}}` format** with a `matcher` per tool (`"Write"`, `"Bash"`, `"*"`). Getting this JSON shape wrong = gates fail *open*, so the v0.1 test must assert a real deny. Hooks:
- `require-citation.sh` (PreToolUse:Write) — block writing a corpus claim with no source marker.
- `source-faithfulness-guard.sh` — block promoting a doc past "sourced" until the citation-verifier pass recorded PASS.
- `forbidden-phrase-guard.sh` — block corpus-voice drift (superlatives, "what should exist", positioning) before review.
- `anchor-not-strip-guard.sh` — block deletion of a flagged-but-real observation (must reframe).
- `layer-discipline-guard.sh` — block an L_n doc from citing below L_(n-1).
- `protect-canonical.sh` / `protect-secrets.sh` / `factory-branch-guard.sh`.
- `convergence-tracker.sh` — block a "converged" declaration if novelty > threshold.

**(c) Information-asymmetry walls** via `.lobster` `context.exclude` (structural, not soft instructions): the adversary-reviewer never sees prior review passes; the citation-verifier sees the claim + source but not the drafter's reasoning; the consistency-validator runs fresh-context every gate ("previously-converged ≠ correct").

**Quantitative convergence (P7):** adversarial review loops until **novelty = new/(new+dup) < 0.15 for ≥ N consecutive passes** (config), with ≥3 clean passes required. Corpus-level "release" check = a multi-dimensional gate (every claim source-faithful · all tracks ≥ Beta · zero unresolved markers · no broken cross-refs · vector-coverage tables present).

**Quality tiers** (assigned by review, never self-reported): Production (0 markers + L3 + adversary PASS) · Beta (0 markers + one of those) · Alpha (SHOULD-FIX remain) · Revise (MUST-FIX). Quality propagates downward-capped (L4 ≤ min(L3) ≤ min(L2)).

**Autonomy levels** (`autonomy_level` in config, drives merge): **3** = human gate on every merge (start here) · **3.5** = auto-merge low-risk (0 markers, adversary PASS, no editorial drift), human for judgment/PM/publication · **4** = full auto for research-layer corpus updates, human still required for L5/L6/PM/publish. Irreversible/outward-facing actions (publish, external delivery) are **always** human-gated.

---

## 11. State management

- **`.factory/` per instance**, mounted as a **git worktree on an orphan `factory-artifacts` branch** — pipeline state gets its own commit history, separate from the corpus.
- **`STATE.md`** — single zero-context-resume file: phase, current step, decisions log, active branches, drift items. Size-capped (a hook enforces it); history extracted to cycle files.
- **INDEX + detail sharding**: large artifacts decomposed into an INDEX + 800–1,200-token detail files, each with `traces_to:` its index (research-backed: faster + fewer tokens). The orchestrator reads **index files only** for gate decisions.
- **Single-Source-of-Truth rule**: each metric (track count, vendor count, canonical dates) has exactly one authoritative file; everything else cites, never re-derives.
- **state-manager is the sole committer** and runs **last** in every burst to avoid version races.

---

## 12. GitHub Actions backbone

### 12.1 Three official vendor CLI Actions = the execution + cross-family-review layer (validated)

All three coding-agent CLIs run as **first-class, official GitHub Actions** — this is what makes the cross-family design (P6) buildable without custom routing infra:

| CLI | Official Action | Role in the factory | Modes |
|---|---|---|---|
| **Claude Code** | `anthropics/claude-code-action@v1` | **builder** — runs the engine plugin/skills; respects `CLAUDE.md`; model selectable incl. Opus | automation (`prompt`) + interactive (`@claude`) |
| **OpenAI Codex** | `openai/codex-action@v1` (`codex exec`) | **adversary reviewer** — runs the review spec as a `prompt-file`; posts review/gates; `sandbox`/`model`/`effort`/`safety-strategy: drop-sudo` | non-interactive CI |
| **Gemini CLI** | `google-github-actions/run-gemini-cli@v0` | **citation-verifier / tie-break** — third independent family; pre-built PR-review workflow; `GEMINI_API_KEY` (or Vertex/WIF) | non-interactive + PR bot |

Two usage patterns, both used here: **(a) review-bot** (Codex/Gemini auto-review a PR diff — the *gate*) and **(b) headless task runner** (`codex exec`/`claude -p`/`gemini -p` driven by the orchestration to run a research *production* step). This replaces the earlier `run-skill.mjs` raw-API runner — the vendor CLIs carry their own harness, sandboxing, and secret handling. Pattern lifted from `brain-factory`'s cron Action templates, generalized to three vendors.

> **Caveat (decision-relevant):** these Actions are the *workers*. The orchestrator that chains them (`needs:`/matrix + the `.lobster` DAG) and the convergence loop (state in `.factory/`) are still engine code you build. The CLIs make the riskiest part (cross-family routing) trivial; they do not replace the orchestration/state/gate engine.

### 12.2 Per-instance Actions and limits

Per-instance Actions (installed by `init-market` from `templates/github-action-templates/`):

| Action | Trigger | Does |
|---|---|---|
| `ingest.yml` | push to `seed/inbox/**` | run `ingest-source` workflow on the new source |
| `nightly-research.yml` | `cron: 0 7 * * *` | advance the next open track/work-item; open a PR (never auto-merge at autonomy 3) |
| `weekly-maintenance.yml` | `cron: 0 8 * * 1` | consistency + editorial sweep + dashboard rebuild → PR |
| `on-pr-review.yml` | PR opened | run adversary-reviewer + citation-verifier on the diff; post findings as review comments |
| `release-corpus.yml` | tag `v*` | build the shareable dashboard/exports; publish |

Portfolio repo Action: `portfolio-rollup.yml` (`cron: 0 9 * * 1`) runs `portfolio-synth` across registered instances → L6 brief → human-gated PR.

**Hard constraints to design around** (validated, §13.2):
- **6-hour hosted-runner cap** is the binding limit → keep each Action a *bounded* unit (one track, one synthesis), not "do the whole corpus." Use **self-hosted runners** (5-day cap) only for deep batch runs.
- **Matrix fan-out ≤ 256 jobs** = the native parallelism primitive → one matrix leg per research thread / track (maps onto orchestrator-worker).
- `GITHUB_TOKEN` 1,000 req/hr/repo → agents must not poll aggressively.
- **Default human gate**: claude-code-action does **not** auto-create PRs by default (returns a branch + PR link). Keep this. Secrets via GitHub Secrets / OIDC only; `show_full_output: false` (output is public on public repos).

---

## 13. Validation summary (why this design is sound) — cited

| Claim | Evidence |
|---|---|
| Orchestrator → parallel subagents → **separate citation pass** → external state is the validated consensus | [Anthropic — multi-agent research system, 2025](https://www.anthropic.com/engineering/multi-agent-research-system) |
| A dedicated **CitationAgent** stage is production-proven | same |
| "Correctness ≠ faithfulness": a cited source may not support the claim → need source-supports-claim verification, not URL presence | [Wallat et al., 2025](https://staff.fnwi.uva.nl/m.derijke/wp-content/papercite-data/pdf/wallat-2025-correctness.pdf); [VeriCite, SIGIR 2025](https://dl.acm.org/doi/10.1145/3767695.3769505) |
| LLM-as-judge rubric (factual accuracy, citation accuracy, completeness, source quality) works but **humans still catch edge cases** | [Anthropic, 2025](https://www.anthropic.com/engineering/multi-agent-research-system) |
| Agents bias toward **SEO content farms over primary sources** → enforce source-tier rules in the judge rubric | same |
| GitHub Actions is the recommended backbone for unattended autonomy; scheduled `cron` is first-class | [Claude Code GitHub Actions](https://code.claude.com/docs/en/github-actions); [scheduled tasks](https://code.claude.com/docs/en/scheduled-tasks) |
| **All three coding-agent CLIs run as official GitHub Actions** → native cross-family review (Claude builds, Codex reviews, Gemini verifies) without a routing proxy | Claude: [docs](https://code.claude.com/docs/en/github-actions) · Codex: [openai/codex-action](https://github.com/openai/codex-action), [OpenAI docs](https://developers.openai.com/codex/github-action) · Gemini: [run-gemini-cli](https://github.com/google-github-actions/run-gemini-cli), [Google blog](https://blog.google/technology/developers/introducing-gemini-cli-github-actions/) |
| 6-hr hosted / 5-day self-hosted runner caps; matrix ≤256 | [GitHub Actions limits](https://docs.github.com/en/actions/reference/limits) |
| Multi-agent ≈ 15× chat tokens (inherent); the StrongDM "$1,000/engineer/day" is **marketing, not a target** | [Anthropic, 2025](https://www.anthropic.com/engineering/multi-agent-research-system); [Simon Willison, 2026](https://simonwillison.net/2026/Feb/7/software-factory/); [Pragmatic CTO, 2026](https://www.thepragmaticcto.com/p/the-software-factory-when-no-human) |
| "No human review" breaches (Replit wiped 1,200+ orgs Jul 2025; Moltbook leaked 1.5M keys Jan 2026) → keep human gates on irreversible actions | [Pragmatic CTO, 2026](https://www.thepragmaticcto.com/p/the-software-factory-when-no-human) |
| Failure modes to design against: over-spawning, duplicated work, content-farm bias, citation-unsupported, reward hacking, context rot | [Anthropic, 2025](https://www.anthropic.com/engineering/multi-agent-research-system); [DEV/Saplin, 2026](https://dev.to/maximsaplin/ai-agent-failure-modes-beyond-hallucination-208g) |

**The one honest gap:** there is no public, validated case study of an autonomous *research/PM-documentation* factory at scale — all proven cases are *software* factories. Transfer is inferred (strongly, from the shared architecture), not demonstrated. This argues for the phased, human-gated rollout in §15.

---

## 14. The OT/ICS instance (worked example, instance #1)

The OT corpus already exists (27 tracks, 545 files, L1–L5, the two-pass Claude→Codex process) — it is the **ideal first instance and migration test**.

- `factory.config.yaml`: `market: "OT/ICS Security"`, `slug: ot-ics`, the 7 OT vectors verbatim, the 27 tracks with their existing sourcing rules, `canonical_values` = the existing source-of-truth set (19 vendors, 8 archetypes, Volt Typhoon 7 seals, Salt Typhoon 22 seals, etc.).
- `seed/scope.md` = the existing `_meta/ot-security-research-goal.md`; `seed/sources.md` = the existing `_meta/source-inventory.md`.
- `corpus/` = the migrated 27 tracks.
- The existing process docs map 1:1 to engine concepts: CLAUDE.md → editorial profile; codex-review-process → adversary-reviewer + the 6 dimensions; track-summary-spec → L4 loading; the reconstructed `research-standards.md` → `FACTORY-SOUL.md`; the `ot-build-and-curate-playbook.md` → the instance README. The personal `ot-*` skills already built become the engine's first skills.
- **Migration is the v0.1 acceptance test**: if the engine can reproduce the OT corpus's existing review loop on a known track and land an adversary PASS, the engine works.

---

## 15. Build roadmap (phased, human-gated)

Every first-class component (the 7 workflows §9, 12 agents §8, 4 repos §6, the config contract §5, the autonomy/budget plumbing §8/§10) is scheduled into exactly one phase below. Phases are cumulative; each ends at a human-verified acceptance gate. The layer model is built **bottom-up** (L1→L2→L3 in v0.1, **L4+L5 in v0.5**, PM in v0.9, **L6 in v1.0**) so the corpus is always usable at its current ceiling.

| Phase | Deliverables | Acceptance gate |
|---|---|---|
| **P0 — Prerequisites** (no engine code) | 🔴 **Rotate the exposed `pm-process/.mcp.json` Perplexity/Tavily keys** + verify no secrets in OT mirror's `.mcp.json` (§17). Provision **3 vendor credentials** as GitHub Secrets / OIDC (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GEMINI_API_KEY`). Verify current model IDs + Action tags against the §8 ⚠ note. | All 3 keys validate in a hello-world Action; zero secrets committed in any repo. |
| **v0.1 — Engine skeleton + config loader + OT instance (manual)** | `research-factory` plugin minimal skeleton (double manifests, CI, hook gates, SKILL.md anatomy); **config loader** (reads `factory.config.yaml` → vectors/tracks/editorial profile, §5); agents `researcher` + `citation-verifier` + `adversary-reviewer` + `state-manager`; `build-track` skill. Create `ot-ics-research`; **migrate the 27-track OT corpus + encode its editorial profile** (CLAUDE.md→profile, codex-review-process→`review-spec.md`, canonical-values, 7 vectors; existing `ot-*` skills become the first engine skills). Run `build-track` on ONE track **by hand** (no Actions). | Reproduces the two-pass loop + adversary PASS on one track **AND** a `require-citation` PreToolUse hook actually blocks a write in a *headless* run (validates §8 plugin-enable + §13 deny-contract). |
| **v0.5 — Full layer pipeline (L1→L5) + gates** | `.lobster` workflows incl. `ingest-source`, `build-track`, **`cross-track-synth` (L4)**, **`judgment` (L5)**, `maintenance`; agents `orchestrator`, `synthesizer`, **`judgment-writer`**, `consistency-validator`, `editorial-sweeper`, `dashboard-builder`; fail-closed hooks + info-asymmetry walls + quantitative convergence; `release.yml`. | OT corpus regenerates **L3→L4** with adversary PASS, zero human edits inside the loop; one **L5 judgment** doc passes its required human gate. |
| **v0.8 — Actions autonomy + market-instantiation machinery** | Per-instance Action templates (`ingest`, `nightly-research`, `on-pr-review`, `weekly-maintenance`) wiring the three CLI Actions (`anthropics/claude-code-action@v1` builder + `openai/codex-action@v1` + `google-github-actions/run-gemini-cli@v0` reviewers — vendor CLIs are the headless runners). **Autonomy + budget plumbing** (`autonomy_level`/`merge-config`; budget warn/alert/pause/hard-stop across 3 vendors, §8/§10). **`research-factory-template` repo** + **`/init-market` skill** (interview→config→seed→install Actions→init `.factory/`→register in portfolio). | A cron run advances a track overnight → reviewable PR (human merges at level 3); `/init-market` scaffolds a throwaway test instance end-to-end. |
| **v0.9 — PM pipeline** | `pm-doc-chain.lobster` + `pm-doc-writer` agent + the pm-process templates (concept→6-pager→PRD→stories→acceptance) + the Dev-Readiness-Check gate. | A selected OT finding produces a dev-ready PRD + stories passing the readiness check. |
| **v1.0 — Portfolio (L6) + 2nd market + engine release** | `research-portfolio` repo + `portfolio-synth` (L6); stand up a **real second market** cold via `/init-market` (proves the dynamic requirement); **engine marketplace publish + `bump-engine` cross-instance version-propagation Action** (§6); port hooks to the shared WASM `factory-dispatcher`; consider autonomy 3.5 for research-layer merges. | Second market reaches Beta from a cold seed; an L6 cross-market brief is human-approved; an engine version bump propagates to both instances via PR. |

---

## 16. Operating the factory — day-in-the-life

This section describes the **v1.0 steady-state rhythm**. (Phasing caveat: in v0.1–v0.5 there are no Actions yet — all work is interactive Claude, by hand, proving the loop on one track. Actions arrive at v0.8. The calendar below is what you graduate into once the gates are trustworthy.)

### 16.1 The mental model: two shifts

The Dark Factory "Shift Work" technique, made literal:
- **🌙 Night shift = GitHub Actions (autonomous).** Drafts, self-reviews, and *opens PRs* — but at autonomy level 3 it **never merges**. Repetitive, fully-specified work, unattended.
- **☀️ Day shift = you + Claude Code (interactive).** Seed, judge, approve/merge, productize. High-judgment, human-in-the-loop work.
- **🚦 The gate = you, in GitHub.** Every corpus change lands as a PR you review and merge. Nothing reaches the corpus without both a machine review (Codex/Gemini) *and* a human merge.

### 16.2 Initialization (one-time, interactive in Claude)

| Step | Where | What happens |
|---|---|---|
| 1. Build the engine | Claude Code (local) | Scaffold the `research-factory` plugin (v0.1 skeleton). |
| 2. Create the instance repo | `gh` (you) | `gh repo create 1898andCo/ot-ics-research --template drbothen/research-factory-template --private` |
| 3. Seed it | Claude Code, interactive | `/research-factory:init-market ot-ics` — Claude **interviews you** (scope, 7 vectors, 27 tracks, sources) → writes `factory.config.yaml` + `seed/`. |
| 4. Migrate the OT corpus | Claude Code | Move the 27 tracks into `corpus/`; map existing process docs to the editorial profile. |
| 5. Install Actions | `/init-market` | Copies Action templates into `.github/workflows/`; sets cron schedules. |
| 6. Add 3 vendor secrets | GitHub UI (you) | `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GEMINI_API_KEY`. |
| 7. Prove the loop by hand | Claude Code | Run `build-track` on ONE track manually (draft → Codex review → converge → you merge). **This is the v0.1 acceptance test.** Only then turn schedules on. |

### 16.3 A week in steady state

```
        🌙 AUTONOMOUS (GitHub Actions)                ☀️ YOU + CLAUDE (interactive)
MON 08:00 weekly-maintenance → consistency +      09:30 Review weekend PRs in GitHub; merge clean ones
          editorial sweep + dashboard → PR        10:00 Claude: pick this week's tracks; tune profile
    09:00 portfolio-rollup → L6 brief → PR
TUE 07:00 nightly-research → next work-item → PR   Morning review+merge; ad-hoc skill runs
    (PR)  on-pr-review → Codex + Gemini review
WED 07:00 nightly-research; ingest on inbox drop   Claude: author/approve an L5 judgment; or
                                                   productize a finding → kick off pm-doc-chain
THU 07:00 nightly-research                         Review+merge; spot-audit a "sourced" claim (P3)
FRI 07:00 nightly-research                         Review+merge; tag a release → release-corpus builds exports
SAT/SUN   nightly-research keeps drafting PRs      (optional) glance at the queue
```

Cadence: **the machine proposes nightly; you dispose each morning** (~15–30 min review-and-merge). You never draft raw research.

### 16.4 Trace: one work item, end to end

A new CISA advisory relevant to `regulatory-governance`:
1. You drop the URL in `seed/inbox/` → **`ingest.yml`** → Claude Action drafts the L1/L2 observation with citations (PR).
2. **`on-pr-review.yml`** → **Codex** runs the review spec (`docs/review-spec.md`) + **Gemini** runs the source-faithfulness check → findings post as PR comments.
3. MUST-FIX findings → next **`nightly-research`** run fixes + re-reviews, looping until **≥3 clean passes, novelty < 0.15**. Autonomous.
4. You get a machine-clean PR, spot-check one citation, **merge** (~2 min).
5. Track hits 0 markers + Codex PASS → nightly rolls it into an **L4 synthesis PR** → you review more carefully and merge.
6. You decide to productize → Claude session runs **`pm-doc-chain`**: concept narrative → *gate "worth pursuing?"* (you) → 6-pager → PRD → Dev-Readiness Check → user stories. Each a PR you approve.

The machine drafted and reviewed everything; you made ~4 judgment calls.

### 16.5 What runs where

| Task | ☀️ Claude (interactive) | 🌙 Actions (autonomous) | 🚦 You (gate) |
|---|:---:|:---:|:---:|
| Seed / scope a market | ✅ interview | | |
| Draft L1/L2 from a source | ✅ on demand | ✅ nightly + on-ingest | |
| L3/L4 synthesis | ✅ on demand | ✅ when track ready | |
| Adversarial + citation review | can run | ✅ Codex + Gemini on every PR | |
| Fix review findings (the loop) | can run | ✅ until convergence | |
| **Merge any corpus change** | | | ✅ always (level 3) |
| **L5 judgment** | ✅ author/approve | drafts only | ✅ approve |
| **Productize → PRD/stories** | ✅ you drive | | ✅ each gate |
| **Publish / external delivery** | | | ✅ always |
| Maintenance sweep + dashboard | can run | ✅ weekly | merge PR |
| Portfolio L6 brief | can run | ✅ weekly | ✅ approve |

**Anything an Action does, you can also trigger interactively in Claude** (same skills) via `workflow_dispatch` or a session. Actions = the scheduled, unattended execution of a subset; Claude interactive is the superset (everything + judgment).

### 16.6 Schedules

| Workflow | Trigger | Output | Auto-merge? |
|---|---|---|---|
| `ingest.yml` | push to `seed/inbox/**` | L1/L2 draft PR | no — you |
| `nightly-research.yml` | daily `0 7 * * *` | advances 1 work-item → PR | no — you |
| `on-pr-review.yml` | any PR opened | Codex + Gemini review comments | n/a |
| `weekly-maintenance.yml` | Mon `0 8 * * 1` | consistency + sweep + dashboard PR | no — you |
| `portfolio-rollup.yml` | Mon `0 9 * * 1` (portfolio repo) | L6 cross-market brief PR | no — you |
| `release-corpus.yml` | tag `v*` (you push) | shareable dashboard/exports | n/a |

### 16.7 Scaling & the autonomy dial

- **Market #2:** one `gh repo create --template` + `/init-market` interview. Its nightly/weekly Actions start immediately; it joins the Monday `portfolio-rollup` automatically.
- **Autonomy dial:** start at **level 3** (you merge everything). Once gates prove out on OT, move *research-layer* merges to **3.5** (machine-clean low-risk PRs auto-merge; judgment/PM/publish stay human forever). The night shift then merges its own clean research; you touch only synthesis, judgment, and productization.

---

## 17. Risks, open decisions, and a critical security finding

**🔴 Security (act before any build):** `/Users/jmagady/Dev/pm-process/.mcp.json` contains **live-looking Perplexity (`pplx-…`) and Tavily (`tvly-prod-…`) API keys committed in plaintext**. Rotate them and `.gitignore` the file before reusing that repo as a factory base. (The OT mirror also has an untracked `.mcp.json` — verify it carries no secrets before any commit.) The factory must store all keys in **GitHub Secrets / OIDC only**, never in-repo.

**Open decisions for the human:**
- **Model families — RESOLVED to three vendor CLI Actions** (Claude builds · Codex reviews · Gemini verifies/tie-breaks; §8, §12.1). Remaining sub-decision: provision **three vendor credentials** (Anthropic + OpenAI + Google) as GitHub Secrets and set a **cross-vendor budget**. The LiteLLM proxy is now optional (local dev only), not on the critical path.
- **Token budget cap per run** and the warn/pause thresholds (§8). Frame as cost-*per-verified-finding*, not a spend floor; "$1,000/day" is explicitly rejected as a target.
- **Repo visibility** (private vs public) per instance — affects Action output exposure (`show_full_output`) and secret handling.
- **Self-hosted runners**: needed for deep batch runs beyond 6 hrs? (adds infra + secret-exposure surface — defer until a real run hits the cap).
- **Engine substrate caveat:** `vsdd-factory`'s `FACTORY.md` references an older "OpenClaw/NemoClaw" engine; the **current** substrate is Claude Code subagents + plugin hooks. Build on the Claude Code layer; treat OpenClaw references as historical.

**Risks (with mitigations already in the design):** over-spawning → effort-scaling rules (P9); content-farm bias → source-tier rules in the judge rubric; citation-unsupported → the citation-verifier (P3); reward hacking → human spot-audit + holdout-style checks the agent can't see; context rot → external state + validators after every edit; cost → bounded Action units + budget caps.

---

## 18. Bootstrap instructions for a fresh agent

If you are an agent picking this up cold:
1. Read this file fully, then read the three reference factories for concrete patterns: `vsdd-factory/plugins/vsdd-factory/docs/FACTORY.md` (orchestration/state/gates), `secops-factory/plugins/secops-factory/` (the minimal shipped skeleton — copy its manifest/hook/agent/skill shapes), `brain-factory/docs/planning/llm-second-brain-plugin-plan.md` (the full skeleton incl. cron Actions + `run-skill.mjs` + engine/target split). brain-factory is the closest analog.
2. Read the OT instance's process docs (in `ot-security-research/`): `CLAUDE.md`, `_meta/ot-corpus-layer-model.md`, `_meta/ot-security-codex-review-process.md`, `_meta/ot-build-and-curate-playbook.md`, `_meta/reconstructed/research-standards.md`. These ARE the v0.1 editorial profile + review spec.
3. Read `pm-process/` for the downstream pipeline: `practice-operating-model.md`, `pm-docs-gpt-prompt.md`, and the `examples/ot-operationalization-assessment/` chain.
4. Build **v0.1** first (§15) — engine skeleton + OT migration + one track by hand. Do not build Actions or autonomy until one track passes the loop manually.
5. Honor the constitution (§1), especially P2 (keep human review), P3 (source-faithfulness, not just citations), and P10 (no market logic in the engine).
6. Start at autonomy level 3 (human gate every merge). Earn higher autonomy per-layer only after the gates prove themselves.

---

## Appendix A — source map (where each design element came from)

| Element | Source |
|---|---|
| Seed/validation/feedback, tokens-as-fuel, Scenario/Satisfaction/DTU | StrongDM Dark Factory (factory.strongdm.ai: /principles, /techniques, /products, /weather-report) |
| Orchestrator-never-executes, `.lobster` DAGs, `.factory/` orphan-branch state, INDEX+detail sharding, info-asymmetry walls, quantitative convergence, autonomy levels, LiteLLM routing | `vsdd-factory` |
| Plugin packaging contract (double manifest, convention discovery, `${CLAUDE_PLUGIN_ROOT}`, engine/target split, SKILL.md 5-part anatomy, producer/reviewer cognitive diversity), cron Action templates + `run-skill.mjs` headless runner, `/init` lifecycle skill, `policies.yaml` | `secops-factory` (shipped) + `brain-factory` (specified) |
| L1–L5 layer model, Citation Test, anchor-not-strip, 6 review dimensions, quality tiers, vector coverage, two-pass review, track pattern | OT/ICS corpus (`ot-security-research`) |
| Six-stage operating model, doc gate ladder, 7-section PRD, Dev-Readiness Check, the deployable doc-agent prompt, the OPRA worked example | `pm-process` |
| Multi-agent architecture validation, citation-faithfulness, GitHub Actions limits/patterns, cost, anti-patterns | External research (§13, cited) |
