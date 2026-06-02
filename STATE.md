---
document_type: pipeline-state
level: ops
version: "2.0"
status: active
producer: state-manager
timestamp: 2026-06-01T23:23:05
phase: 0
inputs: []
input-hash: "[live-state]"
traces_to: ""
project: "research-factory"
mode: "brownfield"
current_step: "Phase 0 brownfield ingest COMPLETE — ready for Phase 1 spec crystallization"
current_cycle: "v1.0-brownfield-migration"
dtu_required: false
---

# Pipeline State: research-factory engine

> Migrated 2026-06-01 from a hand-rolled hybrid-vsdd STATE to the full vsdd-factory plugin
> (dogfood swap: the engine stays the product; vsdd-factory is now the tool that builds it).
> Full pre-migration history preserved verbatim at
> `cycles/v1.0-brownfield-migration/legacy-research-factory-state.md`.

## Project Metadata

| Field | Value |
|-------|-------|
| **Product** | research-factory engine (domain-agnostic research pipeline, ships as a Claude Code plugin) |
| **Repository** | github.com/drbothen/research-factory |
| **Mode** | brownfield |
| **Language** | Bash + Lobster workflows + Markdown agents/skills |
| **Target Workspace** | plugins/research-factory/ |
| **Started** | 2026-06-01 (vsdd onboarding) |
| **Last Updated** | 2026-06-01 |
| **Current Phase** | 0 → 1 (ingest complete) |
| **Current Step** | Phase 0 complete; ready for Phase 1 |

## Phase Progress

| Phase | Status | Started | Completed | Gate | Finding Progression |
|-------|--------|---------|-----------|------|---------------------|
| 0: Codebase Ingestion | passed | 2026-06-01 | 2026-06-01 | B.5+B.6 PASS | 6 passes → NITPICK |
| 1: Spec Crystallization | ready | | | | |
| 2: Story Decomposition | not-started | | | | |
| 3: TDD Implementation | not-started | | | | |
| 4: Holdout Evaluation | not-started | | | | |
| 5: Adversarial Refinement | not-started | | | | |
| 6: Formal Hardening | not-started | | | | |
| 7: Convergence | not-started | | | | |

## Current Phase Steps

| Step | Agent | Status | Output |
|------|-------|--------|--------|
| Activate vsdd-factory | human | done | .claude/settings.local.json (agent=orchestrator, platform=darwin-arm64) |
| Mount .factory + scaffold skeleton | state-manager | done | specs/ stories/ cycles/ … |
| Migrate STATE → v2.0 schema | state-manager | done | this file |
| Brownfield ingest of existing engine | codebase-analyzer | done | semport/research-factory/ (15 files, ~4.2K ln) |
| Phase C final synthesis + 16-item backlog | codebase-analyzer | done | research-factory-pass-8-deep-synthesis.md |

## Brownfield Subject — engine roadmap carried forward (pre-vsdd axis)

> The engine's own delivery roadmap (BUILD-PLAN.md §15), distinct from the vsdd phases above.
> Detail + evidence: `cycles/v1.0-brownfield-migration/legacy-research-factory-state.md`.

| Engine item | Status | Evidence |
|---|---|---|
| 1 — build-track iteration cap | ✅ done | engine PR #1 (`bee28fa`) |
| 2 — cold-start prerequisites | ✅ done | engine PR #3 (`caf4cea`) |
| 3 — 2nd market cold via /init-market | ✅ done | medical-device regulatory-governance → adversary PASS |
| 4 — L6 portfolio | 🟡 machinery done, first run BLOCKED | engine PR #7 (`9ced663`); see Blocking Issues |
| 5 — engine release (marketplace + bump-engine) | ⬜ not-started | closes v1.0 |

## Decisions Log

| ID | Decision | Rationale | Phase | Date | Made By |
|----|----------|-----------|-------|------|---------|
| D-001 | Migrate hybrid-vsdd → full vsdd-factory plugin | Adopt the maintained plugin's agents/hooks/skills instead of the hand-rolled subset | 0 | 2026-06-01 | human |
| D-002 | Dogfood swap, not engine replacement | The research-factory engine stays the product; vsdd-factory is the build tool | 0 | 2026-06-01 | human |
| D-003 | Migrate in place on factory-artifacts (no history rewrite) | Preserve the build trail; legacy STATE kept as a cycle file | 0 | 2026-06-01 | human |
| D-004 | mode = brownfield | Engine is a mature existing codebase; vsdd ingests then carries items #4/#5 as features | 0 | 2026-06-01 | state-manager |
| D-008 | Ran full brownfield-ingest (Phase A + B convergence + B.5/B.6 + C); analyzed engine in-place | Produce the vsdd semantic understanding + improvement backlog feeding Phase 1 | 0 | 2026-06-01 | orchestrator |
| D-005 | max_passes cap = 6 (factory.config convergence.max_passes) | Adversary-loop runaway guard; instance-tunable | — | 2026-06-01 | human |
| D-006 | Workflow (not state-manager agent) owns factory-artifacts round-trip in CI | Deterministic restore+persist; avoids double-push | — | 2026-06-01 | human |
| D-007 | Engine repo public, MIT license | Public marketplace others clone from | — | 2026-06-01 | human |

## Skip Log

| Step | Skipped? | Justification |
|------|----------|---------------|
| UX Spec | yes | Engine is CLI + GitHub Actions + Markdown agents; no UI surfaces |
| DTU | yes | No third-party service behavioral clones required to build the engine |

## Blocking Issues

| ID | Issue | Severity | Blocking Phase | Owner | Resolution |
|----|-------|----------|---------------|-------|------------|
| B-001 | First real L6 cross-market brief blocked: medical-device has no merged L4/L5 (L3 in unmerged PRs #2/#3); OT-only would not be cross-market | high | engine item #4 | human | Options A/B/C in legacy STATE "unblock step 4"; needs operator pick + portfolio repo secrets (incl. INSTANCE_READ_TOKEN) |

## Session Resume Checkpoint

| Field | Value |
|-------|-------|
| **Date** | 2026-06-01 |
| **Position** | Phase 0 brownfield ingest COMPLETE (6 passes→NITPICK, B.5/B.6 PASS). Synthesis + 16-item backlog (P0:3 P1:4 P2:4 P3:5) at semport/research-factory/research-factory-pass-8-deep-synthesis.md. Next = Phase 1 spec crystallization (/vsdd-factory:create-brief using the synthesis as input), OR resolve B-001 to finish engine item #4 |
| **Convergence counter** | n/a (pre-adversarial) |

## Historical Content

| Content | Location |
|---------|----------|
| Pre-migration hand-rolled STATE (222 lines: deployment fixes, open items, full decisions) | `cycles/v1.0-brownfield-migration/legacy-research-factory-state.md` |
| Phase-0 brownfield ingest (15 analysis files, ~4.2K ln) + 16-item backlog | `semport/research-factory/` (synthesis = `…-pass-8-deep-synthesis.md`) |
| Engine design + roadmap | `BUILD-PLAN.md` (on main) §15 / §15.1 |
| Artifact trail | `git log` (main + factory-artifacts) |
