# Skill usage log

Tier 4 of the marketplace QA: the only level that catches "skill triggers correctly + reads cleanly + still produces useless output."

No automation can substitute for actually using skills in real client / team work and noting whether they earned their keep.

## How to use this log

- Add a row whenever you invoke a Manfred skill in real work (client engagement, team workshop, internal tooling — anything that isn't a test run).
- Be brutally honest in the **Useful?** column. The point is to find skills the team avoids in practice.
- Review monthly. Skills that consistently log `useful=N` get rewritten or retired.

## Cadence

- **Weekly**: aim for 1+ row per Trio member (informal, async)
- **Monthly**: 30-minute review — tally usefulness, identify candidates for rewrite or removal
- **Quarterly**: post the summary to the team channel as a "what's working / what's not" thread

## Worked example (delete this row when adopting)

| Skill | When used | Artifact | Useful (Y/N + 1-line) | Revision needed (Y/N) |
|---|---|---|---|---|
| `manfred-discovery:cagan-risks` | 2026-05-04 — pre-sprint risk pass on the new self-serve cancellation flow | `discovery-reports/cagan-risks-self-serve-cancel-2026-05-04.md` posted to STU-72 | Y — surfaced a viability risk (legal not consulted) before engineering committed; saved a likely mid-sprint pivot | N — refusal pattern held; output was the right shape |

## Log

| Skill | When used | Artifact | Useful (Y/N + 1-line) | Revision needed (Y/N) |
|---|---|---|---|---|
| `plugin:skill` | YYYY-MM-DD — one-line situation | path or "no file" | Y / N + 1-line | Y / N + what to change |

---

## Patterns to watch for

These are the signals that mean a skill needs intervention:

- **Useful=N + Revision=Y** repeated for the same skill → rewrite the SKILL.md (probable failure mode: the skill triggers but the output is generic / wrong-shape)
- **Useful=N + Revision=N** repeated for the same skill → consider retiring (the skill triggers but the user prefers a different tool / approach)
- **Skill never appears in the log** for a quarter → either nobody knows it exists (visibility problem) or nobody needs it (retire candidate)
- **Skill appears 5+ times with Useful=Y** in a month → that's a load-bearing skill; protect it, write evals around it, treat any regression as P1

## Related

- `qa-reports/marketplace-quality-<date>.md` — automated tier 1–3 findings
- `qa-reports/linear-tickets.md` — open work tracked from QA
- `scripts/qa-marketplace.sh` — re-runnable static QA
- `superpowers:writing-skills` — RED → GREEN → REFACTOR pattern for rewriting any skill that fails this log
