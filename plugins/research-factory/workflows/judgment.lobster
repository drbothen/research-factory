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
      max_passes: 6            # hard cap; default mirrors factory.config convergence.max_passes
      on_cap: surface-to-human # already human-gated → carry the unconverged status into approval
    context:
      exclude: [prior-review-passes, drafter-reasoning]

  - name: human-approval
    type: human-approval
    depends_on: [adversary-review]
    required: true
    # On a capped exit, state the unconverged status in the prompt: "loop hit max_passes with
    # M MUST-FIX remaining" — the human decides whether to approve, revise further, or drop.
    prompt: "Approve this L5 judgment? (judgment always requires a human gate)"

  - name: commit
    type: agent
    agent: state-manager
    depends_on: [human-approval]
    timeout: 300
