name: build-track
description: >
  Build or advance one research track through the two-pass loop: draft L1/L2/L3,
  source-faithfulness pass, adversarial review to convergence, then atomic commit.
  Formalizes the loop validated by hand in v0.1.
trigger: per-track (manual or nightly-research)

steps:
  - name: draft
    type: agent
    agent: researcher
    depends_on: []
    timeout: 1800
    on_failure: abort

  - name: synthesize
    type: agent
    agent: synthesizer
    depends_on: [draft]
    timeout: 1200
    # L3 findings + the mandatory vector-coverage table

  - name: editorial-sweep
    type: agent
    agent: editorial-sweeper
    depends_on: [synthesize]
    timeout: 300

  - name: citation-verify
    type: agent
    agent: citation-verifier
    depends_on: [editorial-sweep]
    timeout: 1200
    context:
      exclude: [drafter-reasoning, orchestrator-summary]   # info-asymmetry: sees claim+source only

  - name: adversary-review
    type: loop
    agent: adversary-reviewer
    depends_on: [citation-verify]
    timeout: 1800
    # loop until VERDICT: PASS with novelty < threshold for clean_passes_required
    convergence:
      novelty_threshold: 0.15
      clean_passes_required: 3
    context:
      exclude: [prior-review-passes, drafter-reasoning, orchestrator-summary]

  - name: gate-pass
    type: gate
    depends_on: [adversary-review]
    criteria:
      ADVERSARY_VERDICT: PASS
      MUST_FIX_REMAINING: 0

  - name: commit
    type: agent
    agent: state-manager
    depends_on: [gate-pass]
    timeout: 300
    # sole committer, runs last — one burst, one atomic commit
