---
date: <YYYY-MM-DD>
layer: L3
layer-observes: L2
tags: [topic/<market-slug>, type/summary, status/draft]
track: <track-slug>
tier: <Alpha|Beta|Production>
release: <vX.Y>
---

# <Track Name> — Track Summary

<!-- The L4-CONSUMPTION artifact. L4 cross-track synthesis reads THIS, not the TLDRs. It is a COMPLETE
     structured index of every L3 finding in the track — not a highlight reel. If a finding exists in the
     findings doc, it appears here. Observe-and-report only. See _meta/track-summary-spec.md in the
     instance for the authoritative format. -->

<!-- Optional one-line orientation: what this track covers and its current tier/depth. -->

---

## Findings

<!-- Every L3 finding, each as a compact entry: the finding statement + its evidence anchor + the L3
     finding it traces to. Complete coverage — number them to match the findings doc. -->

- **F1 — <finding statement>.** <evidence anchor / named L2-3 basis>. (→ Finding 1)
- **F2 — <finding statement>.** <evidence anchor>. (→ Finding 2)
- **Fn — <finding statement>.** <evidence anchor>. (→ Finding n)

---

## Vector Coverage

| Vector | Coverage | Notes |
|---|---|---|
| V1 <vector-1-name> | <Strong/Moderate/Weak/None> | <basis or structural reason> |
| V2 <vector-2-name> | … | … |
| Vn <vector-n-name> | … | … |

---

## Structural Gaps

<!-- The named, observable gaps this track surfaces (carried from the baseline/findings). These feed
     work-item generation and L4 synthesis. Observations, not recommendations. -->

---

## Bottom Line

<!-- 2–4 sentences an L4 synthesizer can lift directly: what this track contributes to the market picture
     and at what evidence depth. -->

---

## Related

- Findings (L3): `<market>-<track-slug>-findings.md`
- Baseline (L2): `<market>-<track-slug>.md`
