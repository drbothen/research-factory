---
date: <YYYY-MM-DD>
layer: L3
layer-observes: L2
tags: [topic/<market-slug>, topic/<track-slug>, type/findings, status/draft]
---

# <Market> — <Track Name>: L3 Findings

<!-- L3: synthesizes this track's L2 docs ONLY (cite named L2 docs, never reach down to L1 or a raw URL).
     Observe-and-report — no judgment/ranking/recommendation. The Vector Coverage table below is MANDATORY:
     a missing table is a MUST-FIX at review; an uncovered vector with no explanation is a SHOULD-FIX. -->

---

## Vector Coverage

<!-- One row per market evidence vector (the set comes from factory.config.yaml → vectors).
     Coverage ∈ {Strong, Moderate, Weak, None}. Every row needs an Evidence basis (or "—") and a
     Structural note — for a None/Weak vector, the note must say WHY (out of scope for this lens / not
     sourced / handled by track X), not leave it blank. -->

| Vector | Coverage | Evidence basis | Structural note |
|---|---|---|---|
| V1 <vector-1-name> | <Strong/Moderate/Weak/None> | <named L2 evidence, or —> | <why this coverage level; which track owns it if not this one> |
| V2 <vector-2-name> | … | … | … |
| V3 <vector-3-name> | … | … | … |
| Vn <vector-n-name> | … | … | … |

---

## Finding 1: <single-sentence observable claim, stated as an observation>

<!-- Each finding: the claim as a heading, then 1–3 short paragraphs tracing it to named L2 docs.
     No new raw sourcing here — L3 observes L2. Keep it observational. -->

---

## Finding 2: <…>

---

## Finding 3: <…>

<!-- Add as many findings as the L2 evidence supports. Number them sequentially. -->

---

## Bottom Line

<!-- 2–4 sentences: what the track's findings collectively establish, and the evidence-depth/tier honestly
     (e.g. "baseline scaffolding depth; anchors deeply sourced, broader cohort not yet at dimension depth").
     Anchor to sections above; introduce no new claims. -->

---

## Related

<!-- [[wikilinks]]: the L2 baseline/TLDR this observes, sibling tracks, the findings-TLDR and summary. -->

- Baseline (L2): `<market>-<track-slug>.md`
- Findings TL;DR: `<market>-<track-slug>-findings-tldr.md`
- Track summary (L4-consumption): `<market>-<track-slug>-summary.md`
