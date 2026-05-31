name: judgment
description: >
  L5 judgment — the only layer where opinion enters within a market. Each judgment
  statement must cite the L4 observation it rests on. Adversary review, then a
  REQUIRED human approval before anything lands.
trigger: human-initiated

steps:
  - name: draft-judgment
    type: agent
    agent: judgment-writer
    depends_on: []
    timeout: 1800
    # every statement cites a named L4 observation, labeled as judgment

  - name: adversary-review
    type: loop
    agent: adversary-reviewer
    depends_on: [draft-judgment]
    timeout: 1800
    convergence:
      novelty_threshold: 0.15
      clean_passes_required: 3
    context:
      exclude: [prior-review-passes, drafter-reasoning]

  - name: human-approval
    type: human-approval
    depends_on: [adversary-review]
    required: true
    prompt: "Approve this L5 judgment? (judgment always requires a human gate)"

  - name: commit
    type: agent
    agent: state-manager
    depends_on: [human-approval]
    timeout: 300
