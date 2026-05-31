---
description: "Graduate a selected L4/L5 finding into dev-ready PM docs (concept → 6-pager → PRD → stories → acceptance), human-gated"
argument-hint: "<finding-name>"
---

Run the `pm-doc-chain` workflow (`${CLAUDE_PLUGIN_ROOT}/workflows/pm-doc-chain.lobster`) via the orchestrator,
using the `pm-doc-writer` agent. Each ladder step is human-gated; productization never auto-runs.

Finding to productize: $ARGUMENTS
