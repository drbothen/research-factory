# Changelog — research-factory engine

Build progress is tracked authoritatively in [`.factory/STATE.md`](./.factory/STATE.md).
This file records what each phase delivered.

## Unreleased — toward v1.0

- **build-track iteration cap** (#1): `convergence.max_passes` (default 6) threaded through the 4 loop
  workflows + orchestrator + build-track skill + nightly/ingest Actions. The adversary loop no longer
  runs away on a non-converging draft — on cap it commits what it has and flags the PR
  "did not fully converge, M MUST-FIX remain." Autonomous loops commit-flagged; human-gated loops
  surface-to-human.
- **Night-shift state-restore** (#2): the persist-only state loop was a no-op (it pushed nothing because
  the workspace `.factory/` started empty). Added a "Restore pipeline state from factory-artifacts" step
  to `nightly-research.yml` (mirror of persist) and clarified the state-manager's CI role: the workflow
  owns the branch round-trip; the agent only writes the workspace `.factory/STATE.md`.
- **Cold-start prerequisites:** engine `LICENSE` (MIT) · root `CLAUDE.md` (engine constitution + layout +
  build/test) · `docs/FACTORY.md` (operator orientation) · `templates/corpus/` (generic L2/L3/summary/L4
  doc skeletons a cold market scaffolds from — wired into the build-track and init-market skills).

## 0.9.0 — PM pipeline (2026-05-31)

- `pm-doc-writer` agent (from pm-process/pm-docs-gpt-prompt.md): principal-PM voice, MVF-vs-Future,
  never-invent → labeled Assumptions + Open Questions.
- `pm-doc-chain.lobster`: intake → concept → [worth-pursuing gate] → 6-pager → PRD → [Dev-Readiness Check
  gate, 7 failure modes] → user-stories → acceptance-plan → human-approval → commit. Each judgment point human-gated.
- `templates/pm/`: concept-narrative, six-pager, 7-section PRD, 7-field user-stories, acceptance-plan
  (derived from the spec + the OPRA worked example).
- Command shim `/pm-doc-chain`. Acceptance: OT operationalization-gap finding → concept + 7-section PRD + 7-field stories; Dev-Readiness Check ran faithfully (flags → labeled Assumptions/Open-Questions, no invention).

## 0.8.0 — Actions autonomy + market instantiation (2026-05-31)

- 4 per-instance GitHub Action templates wiring the 3 vendor CLIs: `ingest`, `nightly-research`,
  `on-pr-review` (Codex adversary + Gemini citation), `weekly-maintenance`.
- `/init-market` skill + `research-factory-template` repo (created, marked as a GitHub template).
- Autonomy ladder (3/3.5/4) + cross-vendor budget plumbing (`docs/AUTONOMY.md`).
- **Proven live:** night-shift run advanced a track → PR #1 (real fixes, autonomy 3); Codex+Gemini
  review green. Ten deployment issues found + fixed in the templates (see `.factory/STATE.md`).
- researcher prefers MCP search (Perplexity/Tavily), built-in web tools as fallback.

## 0.5.0 — L1→L5 pipeline (2026-05-31)

- `.lobster` workflow engine (`bin/lobster-parse`) + 5 workflows (ingest-source, build-track,
  cross-track-synth, judgment, maintenance) with info-asymmetry walls + convergence loops.
- 6 agents: orchestrator, synthesizer, judgment-writer, consistency-validator, editorial-sweeper,
  dashboard-builder.
- 3 more fail-closed hooks (layer-discipline, protect-secrets, forbidden-phrase) — 4 PreToolUse:Write total.
- **Acceptance:** L3→L4 synthesis → adversary PASS; one L5 judgment through the human gate.

## 0.1.0 — engine skeleton + OT instance #1 (2026-05-31)

- Double-manifest plugin; 4 agents (researcher, citation-verifier, adversary-reviewer, state-manager);
  `build-track` skill; FACTORY-SOUL + LAYER-MODEL docs; config loader (`bin/factory-config.sh`).
- `require-citation` PreToolUse:Write hook — proven to block an uncited corpus write in a headless run.
- OT instance migrated (`1898andCo/ot-ics-research`); build-track → adversary PASS on one track.

## P0 — prerequisites (2026-05-31)

- 3 vendor keys (Anthropic/OpenAI/Gemini) provisioned + validated; secrets hygiene (`.gitignore` `.mcp.json`).
