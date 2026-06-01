---
name: init-market
description: "Use to stand up a new research market (instance) from the template: interview for the seed, write factory.config.yaml + seed/, install the per-instance GitHub Action templates, initialize .factory state, and register the market in the portfolio. The 'add a market = config + seed, not code' command (P10)."
argument-hint: "<slug>"
---

# Init Market

Scaffold a new research-factory instance for one market. A new market is **config + seed, not code** (P10) — this skill produces exactly that, then wires the autonomy machinery.

## Iron Law

**A market differs from every other market only by its config + seed. Write zero market-specific logic into the engine.** If something can't be expressed in `factory.config.yaml` + `seed/`, stop and surface it.

## Announce at Start

Before any other action, say verbatim:

> Running init-market for `<slug>`. I'll interview you for the seed, then write the config + seed, install the Action templates, init .factory state, and register the market. First run is human-gated end-to-end (autonomy 3).

## Red Flags

| Rationalization | Reality |
|---|---|
| "I'll add a special case in the engine for this market." | No. Markets differ only by config + seed (P10). Express it there or surface the gap. |
| "I'll guess the vectors/tracks to save time." | The vector schema and track list are the heart of the instance — interview for them, don't invent. |
| "I'll turn the cron schedules on now." | First run is human-gated end-to-end. Prove one track by hand before enabling autonomy. |
| "I'll commit the secrets into the new repo." | Never. Keys live in GitHub Secrets/OIDC only; `.mcp.json`/`.env` are gitignored. |

## Steps

1. **Create the instance repo** from the template:
   `gh repo create <org>/<slug>-research --template drbothen/research-factory-template --private`
   (Instances live under the company org; the engine + template live under `drbothen`.)
2. **Interview for the seed** (do not invent):
   - market name, slug, audience, phase
   - the **evidence-vector schema** (per-market — this is the key generalization)
   - the **track list** + each track's sourcing rule (external-only / primary-source / public-record / local-mirror)
   - the seed: scope (what "done" looks like), source inventory, canonical values (the source-of-truth set)
   - editorial profile additions (forbidden phrases, per-track defaults)
3. **Write** `factory.config.yaml` (from `${CLAUDE_PLUGIN_ROOT}/templates/factory.config.template.yaml`) and `seed/{scope.md,sources.md,canonical-values.md}`. Validate: `${CLAUDE_PLUGIN_ROOT}/bin/factory-config.sh validate factory.config.yaml`.
4. **Install the Action templates** from `${CLAUDE_PLUGIN_ROOT}/templates/github-action-templates/*.yml` into the instance's `.github/workflows/`. Leave schedules defined but expect the first runs to be human-reviewed.
5. **Enable the engine plugin** for the instance (`.claude/settings.json` → `enabledPlugins: {"research-factory@research-factory": true}`).
6. **Initialize `.factory/`** — write `STATE.md` (phase, decisions log) on the factory-artifacts branch/worktree.
7. **Register in the portfolio** — add the market to `research-portfolio`'s manifest so L6 rollups include it.
8. **Prove one track by hand** before enabling autonomy: run `build-track` on a single track to an adversary PASS — its doc set scaffolds from `${CLAUDE_PLUGIN_ROOT}/templates/corpus/` (the generic L2/L3/summary/L4 skeletons; a cold market has nothing of its own to copy). Only then turn the cron schedules on. Start at `autonomy_level: 3`.

## Reference

Config schema + autonomy/budget: `${CLAUDE_PLUGIN_ROOT}/docs/AUTONOMY.md`, `${CLAUDE_PLUGIN_ROOT}/templates/factory.config.template.yaml`. Layer model: `${CLAUDE_PLUGIN_ROOT}/docs/LAYER-MODEL.md`.
