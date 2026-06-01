name: portfolio-synth
description: >
  L6 cross-market portfolio synthesis. Pulls each registered instance's named L4/L5 outputs
  (index/summary level — never reaching down into a market's L3/L2), synthesizes the cross-market
  view (shared vendors, shared governance, convergences and tensions across markets), runs the
  adversary loop (capped), then a REQUIRED human approval before the L6 brief lands. L6 is the
  only cross-market layer and the only place cross-market judgment is expressed — so it is ALWAYS
  human-gated, exactly like L5 within a market. Runs in the portfolio repo, not an instance.
trigger: cron in the portfolio repo (portfolio-rollup.yml, Mon 0 9 * * 1) or manual

steps:
  - name: load-instance-outputs
    type: skill
    skill: load-instance-outputs
    depends_on: []
    timeout: 600
    # Read each registered instance's named L4 (cross-track synthesis) and L5 (judgment) docs only —
    # via the portfolio manifest. NEVER pull a market's raw L3/L2/L1 (that is a layer-discipline
    # violation across the market boundary, and it blows the token budget). Index/summary level only.

  - name: synthesize-l6
    type: agent
    agent: synthesizer
    depends_on: [load-instance-outputs]
    timeout: 1800
    # Builds the L6 doc: every cross-market observation cites the NAMED L4/L5 of the market it rests
    # on (e.g. "[[ot-ics-l4-window-3]]", "[[medical-device-l5-judgment]]"). Carries a market×vector
    # roll-up. Any genuinely cross-market JUDGMENT is labeled as judgment — it does not silently
    # become "observation," and it only lands behind the human gate below.

  - name: consistency-check
    type: agent
    agent: consistency-validator
    depends_on: [synthesize-l6]
    timeout: 900
    context:
      exclude: [prior-review-passes]   # fresh-context every gate: "previously converged != correct"

  - name: editorial-sweep
    type: agent
    agent: editorial-sweeper
    depends_on: [synthesize-l6]
    timeout: 300

  - name: adversary-review
    type: loop
    agent: adversary-reviewer
    depends_on: [consistency-check, editorial-sweep]
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
    # L6 is cross-market judgment — ALWAYS human-gated, never auto-merged at any autonomy level.
    # On a capped exit, state the unconverged status in the prompt: "loop hit max_passes with
    # M MUST-FIX remaining" — the human decides whether to approve, revise further, or drop.
    prompt: "Approve this L6 cross-market portfolio brief for merge? (L6 always requires a human gate)"

  - name: commit
    type: agent
    agent: state-manager
    depends_on: [human-approval]
    timeout: 300
