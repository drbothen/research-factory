# templates/corpus — generic corpus document templates

The starter doc skeletons a **cold market** copies when scaffolding a track. They encode the engine's
structural contract (layer frontmatter, the mandatory L3 vector-coverage table, the L4-consumption
summary shape) without any market-specific content. `init-market` and a market's `new-track` scaffolder
copy these and substitute placeholders; the `researcher`/`synthesizer` agents then fill them.

## The per-track document set

Each track produces five documents; a market also has one L4 synthesis per release window.

| Template | Instance filename | Layer | Role |
|---|---|---|---|
| `L2-baseline.md` | `<market>-<track-slug>.md` | L2 | the track's observation base |
| `L2-baseline-tldr.md` | `<market>-<track-slug>-tldr.md` | L2 | compressed baseline |
| `L3-findings.md` | `<market>-<track-slug>-findings.md` | L3 | structured findings + **vector-coverage table** |
| `L3-findings-tldr.md` | `<market>-<track-slug>-findings-tldr.md` | L3 | compressed findings |
| `track-summary.md` | `<market>-<track-slug>-summary.md` | L3→L4 | the complete L4-consumption index |
| `L4-cross-track-synthesis.md` | `<market>-synthesis-<window>.md` | L4 | cross-track synthesis (per market) |

## Placeholders to substitute

| Placeholder | Meaning | Example |
|---|---|---|
| `<market>` | market filename prefix | `ot-security` |
| `<market-slug>` | market topic tag | `ot-security` |
| `<track-slug>` | kebab-case track id | `international-cohort` |
| `<Track Name>` | human track title | `International Practitioner Cohort` |
| `<YYYY-MM-DD>` | authoring date | `2026-05-31` |
| `V1 <vector-1-name> … Vn <vector-n-name>` | the market's evidence vectors | from `factory.config.yaml` → `vectors` |

## Hard rules (enforced by hooks / adversary)

- **Layer frontmatter is mandatory** — `layer` + `layer-observes` + `tags`. An L_n doc cites only L_(n-1).
- **The L3 vector-coverage table is mandatory** — one row per market vector, each rated
  `Strong` / `Moderate` / `Weak` / `None`. A missing table is a MUST-FIX; an uncovered vector with no
  explanation is a SHOULD-FIX. The vector *set* is per-market config — the engine does not hardwire it.
- **Observe-and-report only** (L2–L4): no ranking, recommendation, superlative, or "what to build."
- **Cite-or-flag-or-drop:** every claim gets a citation, a `[Source needed: …]` / `[Access required: …]`
  flag (Type-1 real-but-unsourced), or deletion (Type-2 AI inference). Zero Type-2 content.

Remove all `<!-- guidance -->` comments before the doc enters review.
