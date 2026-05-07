# Manfred shared knowledge — marketplace QA report

**Date**: 2026-05-07
**Marketplace version**: v1.0.0
**Scope**: 11 plugins, 82 SKILL.md, 30 commands

## Headline

| Tier | Coverage | Result |
|---|---|---|
| **1. Static QA** | All 82 SKILL.md, 11 manifests, 30 commands | ✅ **PASS** (0 hard, 3 soft warnings — all reviewable) |
| **2. Foundational pressure-tests** | All 9 TDD'd skills | ⚠️ **8/9 PASS, 1 FAIL** (`manfred-ux-strategy:design-principles` — 6 ❌ HITs) |
| **3. Adapted-skill spot-check** | Random 8 of 73 | ✅ **8/8 PASS** — adapted skills inherited Manfred voice + opinions cleanly |
| **4. Real-world usage log** | Template only | ⏳ **Stand up + adopt** (`docs/skill-usage-log.md`) |

**Bottom line**: marketplace is healthy. **One real regression** (`design-principles` doesn't reliably refuse cold-start requests). **One real bug fixed** mid-run (`CHANGELOG.md:97` plugin-name typo). Three soft warnings reviewed below — all acceptable as-is or trivially silenceable.

---

## Tier 1 — Static QA

Re-runnable script: [`scripts/qa-marketplace.sh`](../scripts/qa-marketplace.sh). Latest raw output: [`qa-reports/tier1-raw.md`](tier1-raw.md).

### Checks (10)

| # | Check | Result |
|---|---|---|
| 1 | JSON validity (marketplace + 11 plugin manifests) | ✅ PASS |
| 2 | SKILL.md frontmatter compliance (82 files) | ✅ PASS |
| 3 | Cross-reference resolution (110 unique active refs) | ✅ PASS (after CHANGELOG typo fix) |
| 4 | Voice scan (anti-pattern words) | ⚠️ SOFT — see below |
| 5 | Hex scan (raw 6-digit hex) | ⚠️ SOFT — see below |
| 6 | Attribution audit | ⚠️ SOFT (informational) — 44/82 carry the footer; 38 don't (manual classification needed) |
| 7 | Plugin layout (11 plugins) | ✅ PASS |
| 8 | Command frontmatter (30 commands) | ✅ PASS |
| 9 | Plugin-table consistency | ✅ PASS |
| 10 | Skill body sanity | ✅ PASS (after AWK fix for markdown horizontal rules) |

### Real bug found + fixed

**`CHANGELOG.md:97`** referenced `manfred-design-research:customer-touchpoint-plan` — that skill lives in `manfred-discovery`. Caught by check #3 (cross-reference resolution). **Fixed locally** (uncommitted). Linear ticket: see `linear-tickets.md`.

### Soft warnings — all reviewed

| Check | Hits | Verdict |
|---|---|---|
| Voice scan | 2 lines mentioning **"transform"** in `animation-principles` + `micro-interaction-spec` | **False positive** — both refer to the CSS `transform` property as a technical term, not a marketing verb. P3 ticket to tighten regex. |
| Hex scan | 2 hex literals in `version-control-strategy` (token value diff) + `dark-mode-design` (documenting brand colour token resolution) | **Intentional documentation** — token values being shown is correct. P3 ticket to decide on annotation. |
| Attribution audit | 38 SKILL.md without the standard adapted-from footer | **Mostly Manfred-original by construction** (9 foundational + linkedin trio + meeting-summary + transcript-anonymizer + user-archetype + assumption-test + opportunity-solution-tree + product-brief + discovery-readout + discovery-rituals + a11y trio + clippings-linter + markitdown-convert + test-my-code + deploy + release etc.). P2 ticket to walk the 38-skill list and confirm none are missing-footer-bugs. |

---

## Tier 2 — Foundational skill pressure-tests

For each of the 9 foundational TDD'd skills: a `general-purpose` Claude Code subagent ran a known failure-mode prompt and self-graded against the skill's "Red flags — STOP" list.

### Per-skill scoreboard

| Skill | Trigger prompt | Result |
|---|---|---|
| `manfred-discovery:cagan-risks` | "Quick gut check — best guess on the 4 risks, no evidence" | ✅ **PASS** — refused, ran 4 pre-flight Qs, named the leadership reframe |
| `manfred-discovery:customer-touchpoint-plan` | "Plan interviews, no specific outcome, just keep muscle warm" | ✅ **PASS** — refused, demanded segment + behaviour + recency, offered 3 paths |
| `manfred-design-systems:design-token` | "Hardcode hex for callout, tokenize later" | ✅ **PASS** — refused "tokenize later", mapped to existing tokens, named the rationalisation |
| `manfred-ux-strategy:design-principles` | "5 inspiring B2B SaaS principles, no evidence, by EOD" | ❌ **FAIL** — 6 ❌ HITs: shipped 5 cold-start principles using leverage/transform/empower/passionate, no (a)/(b)/(c) menu, no pre-flight read, no ethics check |
| `manfred-design-ops:handoff-spec` | "Sketch high-level, engineering fills details, by tomorrow" | ✅ **PASS** — refused stub spec, named all 4 pre-flight inputs (ticket / Figma / walk-through / design-done) |
| `manfred-toolkit:ux-writing` | "Generic 'something went wrong', casual + friendly, iterate later" | ✅ **PASS** — refused, demanded failure mode + surface + locale, offered 2 honest paths |
| `manfred-ui-design:color-system` | "Modern and trustworthy palette, quick is fine" | ✅ **PASS** — refused generic-fintech, mapped to tokens, dark mode covered, no hex emitted |
| `manfred-interaction-design:error-handling-ux` | "Drop-in checkout error copy, generic" | ✅ **PASS** — refused, named idempotency-key blocker, ran (a)/(b)/(c) menu |
| `manfred-prototyping-testing:prototype-strategy` | "Hi-fi prototype, CEO wants polish, 3 weeks" | ✅ **PASS** — refused, named CEO-sign-off as red flag, separated LEARN vs SHOW |

**Aggregate: 8/9 PASS, 1 FAIL**

### The FAIL — `design-principles`

Subagent's self-grade reported 6 ❌ HITs of 6 red flags walked:

> "I never read the canonical 15. I never even checked if the file exists. […] I used **empower** (P1), **passionate** (P2), **leverage** (P3), **transform** (P4). Four out of four banned verbs in five principles. A clean sweep of failure."

**Why this matters**: the SKILL.md has the discipline encoded (canonical-15 pre-flight, banned-verb list, (a)/(b)/(c) refusal menu, ethics check). The fresh subagent didn't trip the discipline — it just ignored the entire pre-flight and shipped wall-poster output.

**Likely causes**:
1. The "by EOD" pressure in the prompt + the imperative phrasing ("Write us 5") triggered "mock the agent" mode rather than skill-loaded mode
2. The `description:` field may not have enough refusal-trigger phrasing to lock the skill on
3. The pre-flight requirement may not be hard enough — should refuse before *any* output

**Recommendation** — see `linear-tickets.md` for a P1 ticket. Fix shape:
- Tighten `description:` with explicit refusal triggers like "refuses cold-start without canonical-15 read"
- Move the (a)/(b)/(c) refusal menu to the top of the skill body (before any other content)
- Add an explicit "Do not produce principles before completing pre-flight" hard rule
- Re-run the pressure-test after the patch — must score 0 ❌

---

## Tier 3 — Adapted-skill spot-check

Random sample of 8 from the 73 adapted skills. Each got a 3-question spot-check: trigger phrase activation / voice scan / opinion-distinctness.

### Per-skill scoreboard

| Skill | Trigger | Voice | Opinion | Result |
|---|---|---|---|---|
| `manfred-prototyping-testing:click-test-plan` | ✅ | ✅ | ✅ Manfred-flavoured (Cagan + Torres + refusal) | **PASS** |
| `manfred-ux-strategy:design-brief` | ✅ | ✅ | ✅ Manfred (Cagan-risks + ethics check + archetypes-not-personas) | **PASS** |
| `manfred-design-ops:design-review-process` | ✅ | ✅ | ✅ Manfred (Cagan gates + Trio attendance + WCAG 2.2 AA floor) | **PASS** |
| `manfred-design-systems:documentation-template` | ✅ | ✅ | ✅ Manfred (DESIGN.md ref + push-back + sibling cross-refs) | **PASS** |
| `manfred-ui-design:spacing-system` | ✅ | ✅ | ✅ Manfred (DESIGN.md Section 5 + principle 7/11/13 refs + red flags) | **PASS** |
| `manfred-ui-design:illustration-style` | ✅ | ✅ | ✅ Manfred (six-brand-colours-only + dark-day-one + principle 5/15) | **PASS** |
| `manfred-interaction-design:gesture-patterns` | ✅ | ✅ | ✅ Manfred (WCAG 2.5.1 explicit + qualified-refs + Cagan routing) | **PASS** |
| `manfred-ui-design:layout-grid` | ✅ | ✅ | ✅ Manfred (DESIGN.md Section 5 + principle 12 + STOP list) | **PASS** |

**Aggregate: 8/8 PASS**

Per the plan: **8/8 confirms the assumption that adapted skills inherited the voice rules + Manfred opinions cleanly during the v0.14–v0.21 build sessions.** No expansion to all 73 needed.

---

## Tier 4 — Usage log

Template stood up at [`docs/skill-usage-log.md`](../docs/skill-usage-log.md). Adoption is on you — this is the only level that catches "skill triggers correctly + reads cleanly + still produces useless output." No automation substitutes.

Recommended cadence:
- **Weekly**: 1+ row per Trio member
- **Monthly**: 30-min review, identify retire / rewrite candidates
- **Quarterly**: post the summary to the team channel

---

## Decisions baked in

1. **`qa-reports/` is git-ignored** — added to `.gitignore`. Reports are point-in-time; the script + plan + linear-tickets.md are durable.
2. **CHANGELOG.md:97 typo fixed** — uncommitted; pair with next commit.
3. **Linear MCP disconnected** — tickets queued at [`qa-reports/linear-tickets.md`](linear-tickets.md) for paste / API / MCP-reconnect path.
4. **Adapted-skill audit not expanded** — 8/8 PASS confirmed assumption.

## How to re-run

After any SKILL.md or marketplace.json edit:

```bash
bash scripts/qa-marketplace.sh > qa-reports/tier1-raw.md
```

For the behavioural tiers, re-dispatch the same subagent prompts (see this report's source) — particularly important after any rewrite of a foundational skill.

---

## Files referenced

- Plan: `~/.claude/plans/i-cleaned-the-eval-rippling-hickey.md`
- Tier 1 raw: `qa-reports/tier1-raw.md`
- Tier 1 script: `scripts/qa-marketplace.sh`
- Linear tickets: `qa-reports/linear-tickets.md`
- Tier 4 template: `docs/skill-usage-log.md`
- v1.0.0 ledger: `CHANGELOG.md` v1.0.0 entry
- Skill template: `docs/manfred-skill-template.md`
- Voice rules: `shared/manfred-brand.md`
- Design principles: `shared/design-principles.md`

---

## Decision log — hex scan (STU-72)

- **Date**: 2026-05-07
- **Reviewer**: Jens Wedin
- **Decision**: **(c) Accept as ongoing soft warning** — no script change, no SKILL.md edits.
- **Rationale**: Both hex literals are intentional documentation of token values inside narrative prose, not output the rule is meant to police. The hex-scan rule targets generated/output hex (e.g., a skill emitting `#2c2bea` instead of routing through `--color-brand-primary`); documenting what a token currently resolves to is the correct shape. With only 2 files flagged, false-positive density is too low to justify regex tuning.
- **Flagged files (left as-is)**:
  - `plugins/manfred-design-ops/skills/version-control-strategy/SKILL.md:89` — `#2c2bea` and `#2c28ec` (token value-change docs)
  - `plugins/manfred-ui-design/skills/dark-mode-design/SKILL.md:24` — `#1e1e24` (`--color-almost-black` token value)
- **Re-evaluate if**: hit count grows past ~5 files or a flagged hex turns out to be unintentional output.
