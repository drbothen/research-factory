# FACTORY.md — operator orientation

The cold-start map of the research-factory: what it does, how the pieces fit, and how to operate it.
Read this after `CLAUDE.md` (the laws) and before `BUILD-PLAN.md` (the full design). For live build
state, read `STATE.md` on the `factory-artifacts` branch.

## What the factory does

It turns a **seed** (a market's topic + scope + source inventory) into a **rigorously-sourced,
auditable research corpus**, then graduates that corpus into judgment and product-management
deliverables — autonomously, on GitHub Actions, with human gates where correctness can't be automated.

The spine is a **layered observation stack** (`docs/LAYER-MODEL.md`): each layer observes only the one
below it, so every conclusion is auditable down to an external primary source.

| Layer | Produces | Observes |
|---|---|---|
| L1 | raw sourcing (per source) | external primary sources |
| L2 | artifact observations (per source) | L1 |
| L3 | track findings (per track) + the **mandatory vector-coverage table** | L2 |
| L4 | cross-track synthesis (per market) | L3 |
| L5 | judgment (per market, human-gated) | L4 |
| L6 | portfolio synthesis (across markets) | L4/L5 |
| PM | concept → PRD → stories (downstream of the corpus) | L4/L5 |

**L1–L4 are pure observation** — no ranking, recommendation, or "what to build." Opinion enters only at
L5, behind a human gate.

## The production loop (every track)

Drafting and review are separated by an **information-asymmetry wall**: the reviewer never sees the
drafter's reasoning or prior passes. That asymmetry is what catches blind spots.

```
draft (researcher) → synthesize L3 (synthesizer) → editorial-sweep → citation-verify (claim+source only)
   → adversary-review LOOP  → gate → commit (state-manager, sole committer, runs last)
```

The adversary loop re-dispatches a *fresh* reviewer each pass and continues until **VERDICT: PASS** with
finding novelty < `convergence.novelty_threshold` for `clean_passes_required` consecutive passes —
**capped** at `convergence.max_passes` (default 6). On a capped exit it commits what it has and flags the
PR *"did not fully converge, M MUST-FIX remain"* rather than running away.

## The workflows (`workflows/*.lobster` — pipeline-as-data)

A `.lobster` file is a YAML DAG of steps; `bin/lobster-parse` validates it and emits a topological order;
the `orchestrator` agent dispatches each step's agent in `depends_on` order, honoring the asymmetry walls.

| Workflow | Does | Gate |
|---|---|---|
| `build-track` | advance one track through the full loop | adversary PASS (or capped-flagged) |
| `ingest-source` | capture a new source → L1/L2 observation | adversary PASS (or capped-flagged) |
| `cross-track-synth` | L4 synthesis across a market's L3 findings | adversary PASS → **human** |
| `judgment` | L5 judgment over L4 | adversary PASS → **human** (always) |
| `pm-doc-chain` | concept → PRD → stories from an L4/L5 finding | Dev-Readiness check → **human** |
| `maintenance` | periodic corpus QA / drift sweep | per-sweep |

## How to operate

- **Advance a track (interactive):** `/build-track <track-slug>` (uses the `build-track` skill).
- **Stand up a new market:** `/init-market <slug>` — interview for the seed, write `factory.config.yaml`
  + `seed/`, install the Action templates, init `.factory/`, register in the portfolio. **Config + seed,
  not code.** Prove one track by hand before enabling autonomy.
- **Unattended (the night shift):** per-instance GitHub Actions (`templates/github-action-templates/`)
  run `build-track` / `ingest-source` on a schedule, open a PR, and run cross-family review
  (`on-pr-review`). At **autonomy 3** a human merges every PR.

## Autonomy & budget (`docs/AUTONOMY.md`)

| Level | Behavior |
|---|---|
| 3 | human gate on every merge (**start here**) |
| 3.5 | auto-merge low-risk research PRs (0 markers, adversary PASS, no editorial drift); human for judgment/PM/publish |
| 4 | full auto for the research layer; human still for L5/L6/PM/publish |

Judgment (L5), portfolio (L6), PM productization, and publication/external delivery are **always
human-gated**, at any autonomy level. Budget thresholds (warn/alert/pause/hard-stop) live in
`factory.config.yaml` → `budget`; frame cost as *per verified finding*, not a spend floor.

## Repos

| Repo | Role | Visibility |
|---|---|---|
| `drbothen/research-factory` | the engine (this repo) | public (marketplace clone) |
| `drbothen/research-factory-template` | thin instance starter | private |
| `<org>/<market>-research` | a market instance (e.g. `<your-org>/ot-ics-research`) | private |
| `research-portfolio` | L6 cross-market rollups | private |

## State & resume (§11)

Pipeline state (`.factory/`, incl. `STATE.md`) lives on the **orphan `factory-artifacts` branch**,
gitignored on `main`, so state history is separate from code/corpus history. To resume cold, read
`STATE.md` from that branch (see `CLAUDE.md`). In CI the workflow owns the branch round-trip
(restore-at-start + persist-at-end); the `state-manager` only writes the workspace `.factory/STATE.md`.

## The gates (fail-closed, `docs/HOOKS.md`)

PreToolUse hooks block writes that violate the constitution: `require-citation` (no unsourced corpus
claim), `layer-discipline` (frontmatter + no cross-layer reach), `protect-secrets` (no keys committed),
`forbidden-phrase` (no corpus-voice drift / positioning language). These are deny-by-default and run
headless in CI.
