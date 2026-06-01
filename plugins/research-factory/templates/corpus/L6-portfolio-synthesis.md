---
date: <YYYY-MM-DD>
layer: L6
layer-observes: L4/L5 (across markets)
tags: [scope/portfolio, type/synthesis, status/draft]
window: <rollup-window-or-release>
markets: [<market-a-slug>, <market-b-slug>]
---

# Portfolio Synthesis — Cross-Market (<window>)

<!-- L6: the ONLY cross-market layer. It observes each registered market's named L4 (cross-track
     synthesis) and L5 (judgment) — citing them by name — and never reaches down into any market's
     L3/L2/L1 (reaching across the market boundary into a lower layer is a layer-discipline violation).
     L6 is where cross-market JUDGMENT is expressed; unlike L1–L4 it is not pure observation. Every
     such judgment is LABELLED as judgment and traces to the named market L4/L5 it rests on. This
     layer is ALWAYS human-gated — the workflow ends at a required human approval. Quality is
     downward-capped: L6 ≤ min(contributing L4/L5). -->

## Scope

<!-- Which markets this rollup spans, the window/release it covers, and which named L4/L5 docs of
     each market it observes. Pulled from the portfolio manifest. -->

<!-- Markets observed:
     - <market-a>: [[<market-a>-l4-<window>]], [[<market-a>-l5-judgment-<topic>]]
     - <market-b>: [[<market-b>-l4-<window>]], [[<market-b>-l5-judgment-<topic>]] -->

## Cross-Market Observations

<!-- What only emerges by reading the markets TOGETHER — shared entities (vendors, agencies,
     standards bodies that appear across markets), convergent patterns, and tensions where the
     markets' L4/L5 disagree or diverge. Each traces to the named market L4/L5 it rests on.
     This section stays observational: it reports what each market's own layers established. -->

### <Shared entity / convergence 1>

<!-- e.g. a vendor or governance body present in multiple markets — cite each market's L4/L5
     that establishes its role there. -->

### <Cross-market tension 1>

<!-- Where the markets' established pictures pull in different directions; cite both sides. -->

## Market × Vector Roll-Up

<!-- The portfolio-level matrix: each market's vector schema is its own (vectors are per-instance
     config), so the columns are the UNION of the markets' vectors, or a normalized common set.
     Cells report each market's coverage strength, aggregated from that market's L4 vector picture.
     Still an observation — it restates each market's own roll-up side by side. -->

| Vector | <market-a> | <market-b> | Cross-market note |
|---|---|---|---|
| <shared-vector-1> | <Strong/Moderate/Weak/None> | <…> | <where they align or diverge> |
| <market-a-only-vector> | <…> | n/a | <market-specific> |
| <market-b-only-vector> | n/a | <…> | <market-specific> |

## Cross-Market Judgment

<!-- The one place L6 adds NEW judgment — explicitly labelled, and human-gated. Statements here are
     portfolio-level reads ("across these markets, X holds because their L4/L5 jointly show …"),
     each citing the named market L4/L5 it rests on. No "what to build" — productization is the PM
     pipeline, downstream of the corpus. This section is what the human approval gate scrutinizes. -->

- **Judgment:** <cross-market judgment statement> — rests on [[<market-a>-l4/l5>]], [[<market-b>-l4/l5>]].

## Structural Gaps (portfolio-level)

<!-- Gaps visible only across the portfolio — a vector strong in one market and absent in a sibling,
     a shared entity one market has not yet sourced, negative space between markets. -->

## Bottom Line

<!-- 3–5 sentences: the cross-market picture this rollup establishes, with the cross-market judgment
     clearly flagged as judgment. No recommendation to build — that is the PM pipeline's job. -->

## Related

<!-- [[wikilinks]] to every named market L4/L5 observed, and to any prior portfolio window this
     rollup extends. -->
