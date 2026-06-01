name: ingest-source
description: >
  Ingest one new external source into L1/L2: capture, quarantine-fetch, draft the
  observation with citations, sweep, verify faithfulness, adversary review, commit.
trigger: new source in seed/inbox/ (or cron)

steps:
  - name: capture
    type: skill
    skill: capture-source
    depends_on: []
    timeout: 300

  - name: quarantine-fetch
    type: skill
    skill: quarantine-fetch
    depends_on: [capture]
    timeout: 600
    on_failure: flag-access-required   # paywall/dead → [Access required], not a drop

  - name: draft-observation
    type: agent
    agent: researcher
    depends_on: [quarantine-fetch]
    timeout: 1200

  - name: editorial-sweep
    type: agent
    agent: editorial-sweeper
    depends_on: [draft-observation]
    timeout: 300

  - name: citation-verify
    type: agent
    agent: citation-verifier
    depends_on: [editorial-sweep]
    timeout: 900
    context:
      exclude: [drafter-reasoning]

  - name: adversary-review
    type: loop
    agent: adversary-reviewer
    depends_on: [citation-verify]
    timeout: 1200
    convergence:
      novelty_threshold: 0.15
      clean_passes_required: 3
      max_passes: 6            # hard cap; default mirrors factory.config convergence.max_passes
      on_cap: commit-flagged   # cap hit without convergence → still commit, but flag the PR
    context:
      exclude: [prior-review-passes, drafter-reasoning]

  - name: commit
    type: agent
    agent: state-manager
    depends_on: [adversary-review]
    timeout: 300
