# LAYER-MODEL — L1 through L6

The corpus is a layered observation stack. **Each layer observes only the layer immediately below it.** This is the engine's spine: it is what keeps every conclusion auditable and prevents drift/circular reasoning from compounding up the stack.

| Layer | Role | Citation target | Scope |
|---|---|---|---|
| **L1** | Raw external sourcing (per source) | a named external primary source (URL, doc, person+venue+date) | instance |
| **L2** | Artifact observation (per L1 artifact) | a specific L1 artifact/section | instance |
| **L3** | Track synthesis (across L2 in one track) | named L2 docs in this track | instance |
| **L4** | Cross-track synthesis (within one market) | named L3 findings docs | instance |
| **L5** | Judgment (within one market) | named L4 observations, *labeled as judgment* | instance |
| **L6** | Portfolio synthesis (across markets) | named L4/L5 of each market | portfolio repo |

- **L1–L4 are pure observation.** No judgment, ranking, recommendation, or "what to build."
- **L5 is the only place opinion enters within a market** — and every judgment must cite the L4 observation it rests on.
- **L6** is cross-market judgment, in the portfolio repo.
- The **PM pipeline consumes L4/L5**; productization is downstream of the corpus, never inside it.

## Frontmatter

Every document sets its layer so reviewers can calibrate the citation test:

```yaml
---
date: YYYY-MM-DD
layer: L3
layer-observes: L2
tags: [topic/<market>, type/findings, status/active]
---
```

## Layer discipline (enforced)

- An L_n document may cite only L_(n-1) sources. Reaching further down (e.g., an L4 doc citing a raw L1 source directly) is a layer-discipline violation.
- **Vector coverage is mandatory at L3:** every L3 findings doc carries a vector-coverage table rating each of the market's evidence vectors Strong / Moderate / Weak / None. A missing table is a MUST-FIX; an uncovered vector with no explanation is a SHOULD-FIX.
- **Quality propagates downward-capped:** L4 quality ≤ min(L3) ≤ min(L2). A weak lower layer caps everything above it.

The set of evidence **vectors** is per-market config (OT has 7: Vendor, Operator, Influencer, Hearings, Governance, Incident, Capital). The engine enforces only that *some* vector schema exists and that the L3 coverage table is present — it does not hardwire the vectors.
