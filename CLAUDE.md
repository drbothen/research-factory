# CLAUDE.md — research-factory engine

Instructions for any agent working **on the engine** (this repo). For working *inside a market
instance*, the instance carries its own `CLAUDE.md` (the market's editorial profile).

## What this repo is

The **research-factory engine**: a domain-agnostic, GitHub-Actions-backed pipeline that grows a
rigorously-sourced, auditable research corpus from a *seed* (L1→L4 observation), graduates judgment
(L5) and a portfolio view (L6), and feeds a PM productization pipeline. **A new market is a new
`factory.config.yaml` + `seed/`, never new code.** The engine ships as a Claude Code plugin
(`plugins/research-factory/`) published to a marketplace; instances enable it and differ only by config.

## Read this first to resume

**Live build state is `STATE.md` on the orphan `factory-artifacts` branch — NOT on `main`.** A fresh
`main` clone won't see it (`.factory/` is gitignored on `main`). Get it with:

```bash
git show origin/factory-artifacts:STATE.md            # read once
# or mount it as a worktree:
git fetch origin factory-artifacts && git worktree add .factory factory-artifacts
```

`BUILD-PLAN.md` is the full design (read top-to-bottom; self-contained). `git log` is the artifact trail.
`plugins/research-factory/docs/FACTORY.md` is the cold-start operator orientation.

## The constitution (non-negotiable — full text in `plugins/research-factory/docs/FACTORY-SOUL.md`)

1. **Generic engine, per-market config (P10).** No market-specific logic in the engine. If something
   can't be expressed in `factory.config.yaml` + `seed/`, stop and surface the gap — do not special-case it.
2. **Observe-and-report through L4; judgment only at L5; productization only in the PM pipeline (P5).**
   The corpus stays opinion-free — no ranking, recommendation, or "what to build" — until the L5 layer.
3. **Cite-or-flag-or-drop, source-faithfully (P3/P4).** Every claim traces to an external source that
   *actually supports it*. Real-but-unsourced claims (Type 1) get flagged (`[Source needed: …]`),
   never silently deleted. AI-invented claims (Type 2) are dropped immediately — zero Type-2 content.
4. **Builder ≠ reviewer, different model family (P6).** The adversary never sees the drafter's reasoning
   or prior review passes. These info-asymmetry walls are structural — never narrate around them.
5. **Quantitative convergence, not "looks done" (P7).** Adversarial review loops until finding novelty
   decays below threshold for N clean passes — **capped** at `convergence.max_passes` (commit-flagged on cap).
6. **State-manager is the sole committer, runs last (P8).** One burst → one atomic commit. No other agent commits.
7. **Layer discipline.** An L_n doc cites only L_(n-1). The L3 vector-coverage table is mandatory. Quality
   propagates downward-capped: L4 ≤ min(L3) ≤ min(L2). See `docs/LAYER-MODEL.md`.

## Repo layout

```
plugins/research-factory/          the plugin (the engine itself)
  agents/        12 subagents (orchestrator, researcher, citation-verifier, adversary-reviewer,
                 synthesizer, judgment-writer, pm-doc-writer, state-manager, …)
  workflows/     *.lobster — pipeline-as-data DAGs (build-track, ingest-source, cross-track-synth,
                 judgment, pm-doc-chain, maintenance)
  skills/        build-track, init-market (user-invocable)
  commands/      slash-command entry points
  hooks/         fail-closed PreToolUse gates (require-citation, layer-discipline, protect-secrets,
                 forbidden-phrase) + hooks.json
  bin/           lobster-parse (the .lobster validator/orderer), factory-config.sh
  templates/     factory.config.template.yaml · corpus/ · pm/ · github-action-templates/
  docs/          FACTORY.md · FACTORY-SOUL.md · LAYER-MODEL.md · AUTONOMY.md · HOOKS.md
  tests/         *.bats + run-all.sh
BUILD-PLAN.md  README.md  CHANGELOG.md  LICENSE  CLAUDE.md   (repo root)
.factory/      pipeline state — mounted from the factory-artifacts branch (gitignored on main)
```

## Build / test / validate

```bash
bash plugins/research-factory/tests/run-all.sh                     # the bats suite (config, hooks, lobster)
plugins/research-factory/bin/lobster-parse validate <workflow>     # schema + DAG check a workflow
plugins/research-factory/bin/factory-config.sh validate <config>   # validate an instance config
```

CI (`.github/workflows/ci.yml`) validates the plugin manifests, every `.lobster`, the Action templates,
the template config, and runs the suite. **Keep the suite green; add cases when you change behavior.**

## Conventions

- **Files & slugs:** kebab-case. Corpus docs carry layer frontmatter (`layer`, `layer-observes`, `tags`).
- **State model (§11):** never commit `.factory/` onto `main` or a corpus PR branch — it lives only on
  `factory-artifacts`. In CI the workflow owns the branch round-trip (restore-at-start + persist-at-end);
  the state-manager only *writes* the workspace `.factory/STATE.md`.
- **Commits:** branch off `main` (don't commit to `main` directly), open a PR, let CI's `test` gate pass,
  then squash-merge. Keep the engine public-clean — never commit secrets (keys live in GitHub Secrets/OIDC).
- **Irreversible/outward actions** (publish, external delivery, merging a paid bot PR) are human-gated.

## Pointers

`BUILD-PLAN.md` (design + §15 roadmap) · `docs/FACTORY.md` (operator orientation) ·
`docs/FACTORY-SOUL.md` (constitution) · `docs/LAYER-MODEL.md` (L1–L6) · `docs/AUTONOMY.md` (autonomy/budget) ·
`docs/HOOKS.md` (the gate contract) · `STATE.md` on `factory-artifacts` (live state).
