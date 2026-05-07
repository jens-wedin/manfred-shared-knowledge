---
name: lint-marketplace
description: Use when running static QA over the manfred-shared-knowledge marketplace — anyone says "lint marketplace", "QA the plugins", "marketplace quality check", "check plugin attribution", "voice scan the marketplace", "are the plugins clean", "run tier 1 QA", "static QA pass", "is the marketplace shippable", or wants a re-runnable quality report on the plugin set. Manfred-flavoured: wraps `scripts/qa-marketplace.sh` — 10 deterministic checks (JSON validity, frontmatter, cross-refs, voice, hex, attribution, layout, command frontmatter, plugin-table consistency, body sanity), HARD vs SOFT, exit-non-zero on hard failures.
---

# lint-marketplace

Run the Tier 1 static QA over the `manfred-shared-knowledge` marketplace and surface what needs attention before a release. The script is the verification — this skill explains what it covers, how to read the output, and what to do when something fails.

## When to use

- About to bump `marketplace.json` or a plugin `version` and want a clean baseline
- After adding / moving / renaming a SKILL.md, command, or plugin
- After a voice pass on shared docs or a SKILL.md
- Cross-references between plugins changed (especially during a transition where the same skill name lives in two plugins)
- The user asks "are the plugins clean", "is the marketplace shippable", or any phrasing about QA-ing the plugin set

**Skip when:**

- Verifying a single skill's own logic — that's the skill's own RED→GREEN→REFACTOR loop, not Tier 1 static QA
- Running runtime accessibility checks on a deployed app — that's `manfred-design-systems:a11y-qa`
- Pre-merge QA for a Vite/React product feature — that's `manfred-dev:test-my-code`

## How to invoke

From the repo root:

```bash
bash scripts/qa-marketplace.sh
```

Pipe to a file when you want to keep the report:

```bash
bash scripts/qa-marketplace.sh > /tmp/qa-marketplace-$(date +%Y-%m-%d).md
```

No flags, no model calls, no external services. Re-runnable. Same input → same report.

## What the 10 checks cover

Every check emits one of three statuses: **PASS** (clean), **SOFT** (warning, often acceptable), **HARD** (must fix before release).

| # | Check | Type | What it verifies |
|---|---|---|---|
| 1 | JSON validity | HARD | `marketplace.json` + every `plugin.json` parse with `jq` |
| 2 | Frontmatter compliance | HARD | Every `SKILL.md` has `name` + `description`, `name` matches parent dir, lowercase-hyphenated, description ≤ 1024 chars |
| 3 | Cross-reference resolution | HARD | Every `plugin:skill` reference in markdown points at a real `SKILL.md` or command file (allowlist for historical refs to plugins removed in v1.0.0) |
| 4 | Voice scan | SOFT | Marketing verbs / corporate adjectives outside intentional anti-pattern callouts. Code blocks + backtick spans skipped (CSS `transform` isn't a voice violation) |
| 5 | Hex scan | SOFT | Raw 6-digit hex outside intentional anti-pattern examples — tokens-only is the rule |
| 6 | Attribution audit | SOFT | Lists every `SKILL.md` *without* the "Structurally adapted from…" footer for human review (catches adapted-but-missing-footer) |
| 7 | Plugin layout | HARD | Every plugin has `.claude-plugin/plugin.json` + `README.md` + ≥ 1 `SKILL.md` |
| 8 | Command frontmatter | SOFT | Every command file has `description:` + `argument-hint:` |
| 9 | Plugin-table consistency | HARD on disk⇔marketplace, SOFT on README | Plugin folders ⇔ `marketplace.json` ⇔ `README.md` plugin table all align |
| 10 | Skill body sanity | SOFT | Every `SKILL.md` body ≥ 200 non-whitespace chars (catches stub files) |

## HARD vs SOFT

- **HARD** — script exits non-zero. Don't claim release quality with hard failures open. Fix or escalate.
- **SOFT** — script still exits 0. Many soft warnings are acceptable: intentional anti-pattern callouts in voice / hex scans, Manfred-original skills without an attribution footer in check 6. Read each one, decide.
- **CLEAN** — all 10 pass. Ship.

## Reading the output

The script writes a single markdown report to stdout. Structure:

```
## Tier 1 — Static QA

Generated <ISO timestamp> by `scripts/qa-marketplace.sh`.

### 1. JSON validity — ✅ PASS
…
### 10. Skill body sanity — …

### Tier 1 summary

- HARD failures: **N**
- SOFT warnings: **M**

**Status: <CLEAN | PASS WITH WARNINGS | HARD FAIL>**
```

For voice / hex / cross-ref failures, the report includes the offending file + line + snippet so you can jump straight to the source.

## Where reports land

By default — stdout. Convention for archived reports: `qa-reports/<ISO-date-or-tag>.md` (per `docs/manfred-skill-template.md` rule 3 on Manfred outputs). Don't commit one-off ad-hoc reports; commit the ones tied to a release tag.

## What to do on failure

**HARD failure on JSON validity (check 1):**
Open the named manifest, fix the syntax error. Run `jq . <file>` to confirm.

**HARD failure on frontmatter (check 2):**
The report names the offending file + the missing or malformed field. Edit the SKILL.md frontmatter directly.

**HARD failure on cross-references (check 3):**
A `plugin:skill` reference points at a file that doesn't exist. Either the reference is stale (rename / move the target moved) or the target needs to land. The allowlist in the script covers refs to plugins removed in v1.0.0 — if a new transition adds another removed plugin, extend the allowlist in the script (not in this SKILL.md).

**HARD failure on plugin layout (check 7):**
Plugin missing `plugin.json`, `README.md`, or any `SKILL.md`. Scaffold the missing piece per `docs/manfred-skill-template.md`.

**HARD failure on plugin-table consistency (check 9, marketplace side):**
A plugin folder exists but isn't in `marketplace.json`, or vice versa. Bring them into sync. README divergence is SOFT — fix it in the same pass.

**SOFT warning on voice scan (check 4):**
Each hit is a marketing-verb / corporate-adjective candidate. Verify it's an intentional anti-pattern citation (in a "never" / "anti-pattern" / "red flag" callout). If not — rewrite. The script already strips fenced code blocks and backtick spans, so CSS `transform` etc. won't trip it.

**SOFT warning on hex scan (check 5):**
Same posture as voice. If a hex literal is in a "❌ never generate this" example, leave it. Otherwise rewrite to a token reference per `~/.claude/shared/DESIGN.md`.

**SOFT warning on attribution audit (check 6):**
Reads as a list of skills *without* the footer. Cross-check against the adapted-skill ledger (the `Owl-Listener/designer-skills` mirrors). Manfred-original skills are expected to appear here — that's correct, no action. Adapted skills missing the footer are the failure mode this catches; add the footer per `docs/manfred-skill-template.md` rule 8.

**SOFT warning on command frontmatter (check 8):**
Add the missing `description:` or `argument-hint:` to the named command file.

**SOFT warning on body sanity (check 10):**
Stub SKILL.md (< 200 non-whitespace chars in the body). Either flesh it out or delete it.

## Manfred lens

This is QA work, not discovery work — Cagan / Torres lens doesn't apply. The skill maps to the QA tier model:

- **Tier 1 — Static QA** (this skill) — deterministic, no model calls, re-runnable in seconds. Surfaces structure / convention drift.
- **Tier 2 — Skill-level RED→GREEN→REFACTOR** — per `superpowers:writing-skills`. Surfaces rationalisation drift in a single skill.
- **Tier 3 — Cross-skill behavioural** — does the network of skills route work correctly under pressure?
- **Tier 4 — Live use** — usage signals from real sessions.

Tier 1 catches what the others can't see (a typo in `marketplace.json`, a dangling cross-reference) and runs cheaply enough to gate every release.

## Common rationalizations

| Excuse | Reality |
|---|---|
| "The HARD failures are minor, ship anyway" | HARD means the marketplace is structurally broken. A user installing a plugin with a malformed `plugin.json` gets a confusing error, not a graceful degrade. Fix first. |
| "The voice scan is over-eager, mute it" | The script already strips code blocks + backticks. If it's still firing, it's prose. Rewrite or add the hit to an explicit anti-pattern callout. |
| "Attribution warnings are just noise" | They're a no-count assertion by design — every release, somebody eyeballs the list. The pattern this catches is rare, the cost of catching it is one minute. |
| "The README plugin table will catch up later" | "Later" is how `marketplace.json` and `README.md` drift apart. Fix it in the same pass that ran the linter. |

## Red flags — STOP

- Tagging a release with HARD failures unresolved
- Disabling a check by editing the script to bypass output (extend the allowlist with a comment + Linear ticket instead)
- Treating a SOFT warning as PASS without reading the hit list

## Cross-references

- `manfred-knowledge:markitdown-convert` — sibling utility (batch document → markdown conversion)
- `manfred-knowledge:clippings-linter` — sibling utility (Obsidian vault hygiene); same posture as this skill — deterministic, fast, re-runnable, report-first
- `superpowers:writing-skills` — Tier 2 (skill-level TDD-for-skills); complements Tier 1 by catching rationalisation drift this script can't see
- `docs/manfred-skill-template.md` — the conventions this script enforces; if a check fails, the fix lives in the template's rules

## Tools used

- Bash — `bash scripts/qa-marketplace.sh`
- `jq` — JSON validity (check 1) + plugin-table consistency (check 9)
- `awk`, `grep`, `perl`, `find`, `xargs` — used inside the script; nothing to invoke directly
