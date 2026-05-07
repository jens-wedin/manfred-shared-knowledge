# Attribution Audit — 2026-05-07 (STU-70)

Tier 1 attribution check: 82 SKILL.md total, 44 carried the standard `Structurally adapted from [Owl-Listener/designer-skills]` footer. **38** did not. This audit classifies each.

## Summary

| Bucket | Count |
|---|---|
| Total SKILL.md | 82 |
| Standard footer present (pre-audit) | 44 |
| Missing footer (pre-audit) | 38 |
| Classified `original` (no footer needed) | 28 |
| Classified `missing-footer-bug` (footer appended) | 10 |
| Standard footer present (post-audit) | 54 |
| Remaining unattributed (post-audit, all originals) | 28 |

Verification: `54 + 28 = 82` and `44 + 10 = 54`. Counts reconcile.

## Classification table

| Skill (plugin:skill) | Decision | Reason |
|---|---|---|
| manfred-design-ops:handoff-spec | original | Foundational TDD'd skill (in ticket original list); fully Manfred-built |
| manfred-design-research:affinity-diagram | missing-footer-bug | Same-name upstream exists; non-standard footer replaced/supplemented with standard |
| manfred-design-research:card-sort-analysis | missing-footer-bug | Same-name upstream exists; non-standard footer present, standard appended |
| manfred-design-research:diary-study-plan | missing-footer-bug | Same-name upstream exists; non-standard footer present, standard appended |
| manfred-design-research:empathy-map | missing-footer-bug | Same-name upstream exists; non-standard footer present, standard appended |
| manfred-design-research:interview-script | missing-footer-bug | Same-name upstream exists; non-standard footer present, standard appended |
| manfred-design-research:jobs-to-be-done | missing-footer-bug | Same-name upstream exists; non-standard footer present, standard appended |
| manfred-design-research:journey-map | missing-footer-bug | Same-name upstream exists; non-standard footer present, standard appended |
| manfred-design-research:summarize-interview | missing-footer-bug | Same-name upstream exists; non-standard footer present, standard appended |
| manfred-design-research:transcript-anonymizer | original | No upstream; Manfred-original (PII scrubbing) |
| manfred-design-research:usability-test-plan | missing-footer-bug | Same-name upstream exists; non-standard footer present, standard appended |
| manfred-design-research:user-archetype | original | Manfred rename + reframe of upstream `user-persona`; ticket flags as original (archetype-based reframing) |
| manfred-design-systems:a11y-design | original | Close call — descends from upstream `accessibility-audit` but is one of three Manfred role-splits (design/dev/qa), 5x size, fully rebuilt |
| manfred-design-systems:a11y-dev | original | Same as a11y-design — role-split rewrite, 10x upstream size |
| manfred-design-systems:a11y-qa | original | Same as a11y-design — role-split rewrite, 6x upstream size |
| manfred-design-systems:design-token | original | Foundational TDD'd skill |
| manfred-dev:deploy | original | manfred-dev plugin original |
| manfred-dev:release | original | manfred-dev plugin original |
| manfred-dev:test-my-code | original | manfred-dev plugin original |
| manfred-discovery:assumption-test | original | Manfred-discovery original (Torres/Cagan synthesis) |
| manfred-discovery:cagan-risks | original | Foundational TDD'd skill |
| manfred-discovery:customer-touchpoint-plan | original | Foundational TDD'd skill |
| manfred-discovery:discovery-readout | original | Manfred-discovery original |
| manfred-discovery:discovery-rituals | original | Manfred-discovery original |
| manfred-discovery:opportunity-solution-tree | original | Manfred-discovery original |
| manfred-discovery:product-brief | original | Manfred-discovery original |
| manfred-interaction-design:error-handling-ux | original | Foundational TDD'd skill |
| manfred-knowledge:clippings-linter | original | manfred-knowledge plugin original |
| manfred-knowledge:markitdown-convert | original | manfred-knowledge plugin original |
| manfred-prototyping-testing:prototype-strategy | original | Foundational TDD'd skill |
| manfred-toolkit:linkedin-reflect | original | LinkedIn trio — Manfred voice original |
| manfred-toolkit:linkedin-show-and-tell | original | LinkedIn trio — Manfred voice original |
| manfred-toolkit:linkedin-teach | original | LinkedIn trio — Manfred voice original |
| manfred-toolkit:meeting-summary | original | Manfred-toolkit original |
| manfred-toolkit:ux-writing | original | Foundational TDD'd skill |
| manfred-ui-design:color-system | original | Foundational TDD'd skill |
| manfred-ux-strategy:design-principles | original | Foundational TDD'd skill |
| manfred-ux-strategy:north-star-vision | missing-footer-bug | Same-name upstream exists in `ux-strategy/skills/north-star-vision`; no original-list membership; standard footer appended |

## Footers added

The standard footer (per `docs/manfred-skill-template.md` rule 8) was appended to:

```
---

*Structurally adapted from [Owl-Listener/designer-skills](https://github.com/Owl-Listener/designer-skills) under MIT license. Voice, examples, and Manfred-specific guidance are original.*
```

Files modified:
1. `plugins/manfred-design-research/skills/affinity-diagram/SKILL.md`
2. `plugins/manfred-design-research/skills/card-sort-analysis/SKILL.md`
3. `plugins/manfred-design-research/skills/diary-study-plan/SKILL.md`
4. `plugins/manfred-design-research/skills/empathy-map/SKILL.md`
5. `plugins/manfred-design-research/skills/interview-script/SKILL.md`
6. `plugins/manfred-design-research/skills/jobs-to-be-done/SKILL.md`
7. `plugins/manfred-design-research/skills/journey-map/SKILL.md`
8. `plugins/manfred-design-research/skills/summarize-interview/SKILL.md`
9. `plugins/manfred-design-research/skills/usability-test-plan/SKILL.md`
10. `plugins/manfred-ux-strategy/skills/north-star-vision/SKILL.md`

## Close-call notes

- **a11y-design / a11y-dev / a11y-qa**: classified `original`. Upstream has a single 26-line `accessibility-audit` skill; Manfred shipped three role-specific skills totalling 551 lines, fundamentally rebuilt. No same-name upstream exists for any of the three. If a future audit takes a stricter view ("any structural inspiration deserves credit"), these would tip to `missing-footer-bug` and need the standard footer.
- **user-archetype**: classified `original` per ticket guidance. Reframes upstream `user-persona` (different name, different epistemics: behaviour-and-role over invented names/photos). Worth a reviewer's eye if the project decides reframes always credit the seed.
- **9 of 10 fixed bugs already had a non-standard `*Adapted from...*` footer** in the body. Per ticket constraint ("only append the footer block at the very end"), the standard footer was appended after the existing one rather than rewriting it. Result is a stacked attribution block — accurate but slightly redundant. A follow-up cleanup pass could consolidate to a single canonical line.

## Verification command

```bash
for f in plugins/*/skills/*/SKILL.md; do
  grep -L "Structurally adapted from" "$f"
done | wc -l
# Expected: 28 (all originals)
```
