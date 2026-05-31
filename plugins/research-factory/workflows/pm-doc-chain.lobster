name: pm-doc-chain
description: >
  Graduate a selected L4/L5 finding into dev-ready product docs via the pm-process gate ladder.
  Human-gated at each judgment point (autonomy never auto-productizes). The downstream PM pipeline (§4)
  — consumes L4/L5, never adds corpus claims.
trigger: a finding selected for productization (human-initiated)

steps:
  - name: intake
    type: human-approval
    depends_on: []
    prompt: "Name the L4/L5 finding to productize. Confirm it is worth a PM spec?"

  - name: concept-narrative
    type: agent
    agent: pm-doc-writer
    depends_on: [intake]
    timeout: 1200
    # 2-pager: problem, goals, direction. Evidence (corpus) vs Assumptions kept separate.

  - name: gate-worth-pursuing
    type: human-approval
    depends_on: [concept-narrative]
    prompt: "Concept narrative reviewed — pursue this (proceed to 6-pager/PRD), or stop here?"

  - name: six-pager
    type: agent
    agent: pm-doc-writer
    depends_on: [gate-worth-pursuing]
    timeout: 1200

  - name: prd
    type: agent
    agent: pm-doc-writer
    depends_on: [six-pager]
    timeout: 1800
    # 7-section PRD; MVF vs Future separated; Section 4 = What it Eats/Does/Outputs; background → Appendix A.

  - name: dev-readiness-check
    type: gate
    depends_on: [prd]
    criteria:
      MVF_SCOPE: clear
      INPUTS_OUTPUTS: clear
      STATE_TRANSITIONS: clear
      INTEGRATION_ALERTING: clear
      DEPENDENCIES: clear
      STORY_DERIVATION_CRITERIA: clear
      QA_ACCEPTANCE_CRITERIA: clear
    # any one unclear blocks handoff → resolve as labeled Assumption + Open Question, not invention

  - name: user-stories
    type: agent
    agent: pm-doc-writer
    depends_on: [dev-readiness-check]
    timeout: 1200
    # 7 fields each: ID, persona, story(When/I want/So that), inputs, outputs, acceptance criteria, PRD ref

  - name: acceptance-plan
    type: agent
    agent: pm-doc-writer
    depends_on: [user-stories]
    timeout: 900

  - name: human-approval
    type: human-approval
    depends_on: [acceptance-plan]
    required: true
    prompt: "Approve the dev-ready doc set (PRD + stories + acceptance) for handoff? (productization is always human-gated)"

  - name: commit
    type: agent
    agent: state-manager
    depends_on: [human-approval]
    timeout: 300
