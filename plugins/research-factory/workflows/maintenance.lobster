name: maintenance
description: >
  Weekly hygiene sweep: cross-doc consistency audit, corpus-wide editorial sweep,
  dashboard rebuild, then open a PR with the fixes (never auto-merge at autonomy 3).
trigger: weekly cron

steps:
  - name: consistency-sweep
    type: agent
    agent: consistency-validator
    depends_on: []
    timeout: 1800
    context:
      exclude: [prior-review-passes]   # fresh context every run

  - name: editorial-sweep-all
    type: agent
    agent: editorial-sweeper
    depends_on: []
    timeout: 1800

  - name: dashboard-rebuild
    type: agent
    agent: dashboard-builder
    depends_on: [consistency-sweep, editorial-sweep-all]
    timeout: 600

  - name: open-pr
    type: agent
    agent: state-manager
    depends_on: [dashboard-rebuild]
    timeout: 300
    # opens a PR; human merges (autonomy 3)
