# Fail-closed hooks

Deterministic PreToolUse gates (`set -euo pipefail`, jq-based, <100ms) that enforce
the Iron Laws at the harness level so agents can't bypass them. Plugin `hooks.json`
uses the wrapped `{"hooks":{<event>:[{matcher,hooks:[...]}]}}` shape; a blocking hook
emits `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"…"}}`.
Getting the JSON shape wrong makes gates fail **open** — CI asserts the shape and the tests assert real denies.

## Implemented (v0.1–v0.5) — tested

| Hook | Event | Blocks |
|---|---|---|
| `require-citation.sh` | Write | a corpus claim doc with substantive content but no source marker AND no explicit unsourced flag (anchor-not-strip aware) |
| `protect-secrets.sh` | Write | writing a credential to any file (provider key prefixes, private keys, GitHub/AWS tokens) |
| `layer-discipline-guard.sh` | Write | a corpus doc whose `layer-observes` ≠ the layer immediately below `layer` (L_n must observe L_(n-1)) |
| `forbidden-phrase-guard.sh` | Write | a corpus doc with first-person/company positioning or "what to build" language (bright-line; the nuanced sweep is the editorial-sweeper agent) |

All four are wired into `hooks.json` (PreToolUse:Write) and covered by `tests/hooks.bats`.

## Planned (state-dependent — require the workflow state machine; v0.5+/v0.8)

These depend on recorded pipeline state (review verdicts, prior-pass novelty, old-vs-new
content diffs), so they belong with the orchestrator/state-manager loop rather than a
pure content check. Documented here so the gap is explicit, not silent:

| Hook | Blocks | Needs |
|---|---|---|
| `source-faithfulness-guard.sh` | promoting a doc past "sourced" until the citation-verifier recorded PASS | recorded citation-verifier verdict in `.factory/reviews/` |
| `convergence-tracker.sh` | a "converged" declaration while finding novelty > threshold | per-pass novelty history |
| `anchor-not-strip-guard.sh` | deleting a flagged-but-real observation (must reframe, not strip) | old-vs-new content diff on Edit |
| `protect-canonical.sh` | unreviewed edits to `seed/canonical-values.md` (Single-Source-of-Truth) | change-review marker |
| `factory-branch-guard.sh` | corpus commits onto the `factory-artifacts` orphan branch (and vice versa) | branch context |
