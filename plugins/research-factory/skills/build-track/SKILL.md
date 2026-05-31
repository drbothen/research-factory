---
name: build-track
description: "Use to build or advance one research track through the two-pass loop: draft L1/L2 observations (researcher) → source-faithfulness pass (citation-verifier) → adversarial review (adversary-reviewer, loop to PASS) → atomic commit (state-manager). The v0.1 core production loop."
argument-hint: "<track-slug>"
---

# Build Track

Drive a single research track through one full production burst of the factory loop. This is the v0.1 acceptance workhorse: it reproduces the corpus's proven "draft → review → converge → commit" two-pass process on one track.

## Iron Law

**No corpus document leaves this loop until the adversary returns PASS (zero MUST-FIX) and every claim is source-faithful.** Builder ≠ reviewer; the reviewer never sees prior passes.

## Announce at Start

Before any other action, say verbatim:

> Running build-track on `<track-slug>`. I will draft, then run the citation-faithfulness and adversarial passes, loop until PASS with no MUST-FIX, and commit only via the state-manager. I will not self-approve.

## Red Flags — stop if you catch yourself thinking…

| Rationalization | Reality |
|---|---|
| "The citation is present, so the claim is fine." | Presence ≠ faithfulness. The citation-verifier must confirm the source *supports* the claim (P3). |
| "I'll let the reviewer see what I already fixed, to save time." | The adversary must stay blind to prior passes — that asymmetry is what catches blind spots. Never feed it summaries. |
| "This claim is obviously true; it doesn't need a source." | Obvious-sounding claims are exactly where Type-2 inference hides. Cite it or flag it or drop it. |
| "It looks done — let's commit." | "Looks done" ≠ converged. Loop until novelty < threshold for the required clean passes. |
| "I'll just commit it myself, the state-manager is a formality." | The state-manager is the *sole* committer and runs last — committing mid-burst causes version races. |
| "No source exists, but it's probably right — I'll keep it." | That is Type-2 content. Drop it. Only Type-1 (real-but-unsourced) gets a `[Source needed]` flag. |

## Steps

1. **Load minimal context.** Read `factory.config.yaml` for this track's name, sourcing rule, and the market's vector schema. Read the track's existing docs (index/TLDR only, not every source). Do not read the whole corpus.
2. **Draft (researcher).** Dispatch the `researcher` agent to gather sources and draft/advance the track's L1/L2 observations, honoring the per-track sourcing rule. Every claim gets a citation or an explicit flag. (L3 synthesis with the `synthesizer` agent arrives at v0.5; in v0.1 produce the sourced L1/L2 base.)
3. **Citation-faithfulness pass.** Dispatch the `citation-verifier` (read-only, sees claim+source only). Resolve every UNSUPPORTED/CONTRADICTED verdict: reword to match the source, flag, or drop. Re-run until clean.
4. **Adversarial review (loop).** Dispatch the `adversary-reviewer` (read-only, fresh context, no prior passes). Apply MUST-FIX findings. Re-dispatch a *fresh* review each pass. Continue until **PASS with zero MUST-FIX** and finding novelty < the configured threshold for the required consecutive clean passes.
5. **Commit (state-manager).** Only after PASS: dispatch the `state-manager` to update `STATE.md` and commit the burst as one atomic change. No other agent commits.
6. **Report.** Summarize: docs produced/advanced, citation verdicts, the adversary PASS, and what was flagged or dropped (and why). Surface any `[Access required]` items for a later paid-access pass.

## Honor the constitution

Observe-and-report only through L4 (no judgment, ranking, or "what to build"). See `${CLAUDE_PLUGIN_ROOT}/docs/FACTORY-SOUL.md` and `${CLAUDE_PLUGIN_ROOT}/docs/LAYER-MODEL.md`.
