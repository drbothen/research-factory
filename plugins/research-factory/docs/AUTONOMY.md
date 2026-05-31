# Autonomy & budget

How much the night shift (Actions) may do on its own, and how spend is bounded. Both are
per-instance config (`factory.config.yaml`); the engine reads them, contains no hardcoded policy.

## Autonomy ladder (`autonomy_level`)

Start at **3**. Earn higher autonomy per-layer only after the gates prove themselves on a real instance.

| Level | Research-layer merges (L1–L4) | Judgment / PM / publish |
|---|---|---|
| **3** (start here) | human merges every PR | human |
| **3.5** | auto-merge *low-risk* PRs (adversary PASS · 0 MUST-FIX · 0 markers · no editorial drift) | human |
| **4** | full auto for research-layer corpus updates | human still required |

**Always human-gated, at every level** (`merge.always_human`): L5 judgment, L6 portfolio,
PM productization, and any publish / external delivery. Irreversible or outward-facing actions
never auto-execute (the lesson from the "no human review" breaches, BUILD-PLAN §13).

The night shift (Actions) drafts and self-reviews but, at level 3, **opens PRs and never merges**
— `claude-code-action` returns a branch + PR link by default, and we keep that. The morning human
pass disposes (~15–30 min review-and-merge).

## Budget (`budget`) — cross-vendor

Spend spans three vendors (Anthropic + OpenAI + Google), each key a separate GitHub Secret.
Tiers escalate: **warn → alert → pause → hard_stop**. `per_run_cap` bounds a single run.

Frame cost as **per verified finding**, not a spend floor — the StrongDM "$1,000/engineer/day"
figure is explicitly rejected as a target (BUILD-PLAN §13). If budget would force a model
downgrade *on the critical path*, **pause** rather than continue underpowered
(`on_critical_path_downgrade: pause`) — compounding-correctness matters more than throughput.

The 6-hour hosted-runner cap is the binding execution limit: keep each Action a **bounded unit**
(one track, one synthesis), never "do the whole corpus" (BUILD-PLAN §12.2).
