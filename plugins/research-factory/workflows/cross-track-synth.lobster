name: cross-track-synth
description: >
  L4 cross-track synthesis. Loads track summaries (index-only) across all tracks
  at Beta or better, synthesizes the cross-vector view, validates consistency,
  runs the adversary loop, then a required human approval before the L4 lands.
trigger: all tracks >= Beta (manual)

steps:
  - name: load-summaries
    type: skill
    skill: load-track-summaries
    depends_on: []
    timeout: 600
    # index/summary files only — never full L3 source docs (token + drift discipline)

  - name: synthesize-l4
    type: agent
    agent: synthesizer
    depends_on: [load-summaries]
    timeout: 1800

  - name: consistency-check
    type: agent
    agent: consistency-validator
    depends_on: [synthesize-l4]
    timeout: 900
    context:
      exclude: [prior-review-passes]   # fresh-context every gate: "previously converged != correct"

  - name: editorial-sweep
    type: agent
    agent: editorial-sweeper
    depends_on: [synthesize-l4]
    timeout: 300

  - name: adversary-review
    type: loop
    agent: adversary-reviewer
    depends_on: [consistency-check, editorial-sweep]
    timeout: 1800
    convergence:
      novelty_threshold: 0.15
      clean_passes_required: 3
    context:
      exclude: [prior-review-passes, drafter-reasoning]

  - name: human-approval
    type: human-approval
    depends_on: [adversary-review]
    prompt: "Approve the L4 cross-track synthesis for merge?"

  - name: commit
    type: agent
    agent: state-manager
    depends_on: [human-approval]
    timeout: 300
