#!/usr/bin/env bash
#
# qa-marketplace.sh — Tier 1 static QA for manfred-shared-knowledge.
#
# Re-runnable. No model calls, no external services. Emits a markdown report
# section to stdout and exits non-zero on any HARD failure (soft warnings
# don't block the exit code).
#
# Usage:
#   bash scripts/qa-marketplace.sh                # markdown to stdout
#   bash scripts/qa-marketplace.sh > qa.md        # to file
#
# Checks (10 of them, each PASS / SOFT / HARD):
#   1. JSON validity (jq parse on marketplace + plugin manifests)
#   2. Frontmatter compliance (name, description, parent-dir match, length)
#   3. Cross-reference resolution (manfred-X:Y -> real file)
#   4. Voice scan (anti-pattern words outside intentional callouts)
#   5. Hex scan (raw hex outside intentional anti-pattern examples)
#   6. Attribution audit (footer count vs adapted-skill ledger)
#   7. Plugin layout compliance (.claude-plugin/plugin.json + README + skills)
#   8. Command frontmatter (description + argument-hint)
#   9. Plugin-table <-> disk consistency (README + marketplace.json)
#  10. Skill body sanity (non-empty body beyond frontmatter)
#
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

HARD_FAILS=0
SOFT_FAILS=0

# Anti-pattern callout containers: skip findings inside these block forms.
# (We grep with line context and post-filter known-acceptable contexts.)

# ------- helpers ----------------------------------------------------------
emit() { printf '%s\n' "$*"; }

# emit_check <id> <title> <status (PASS|SOFT|HARD)> <body...>
emit_check() {
  local id="$1" title="$2" status="$3"
  shift 3
  local emoji
  case "$status" in
    PASS) emoji="✅" ;;
    SOFT) emoji="⚠️"; SOFT_FAILS=$((SOFT_FAILS + 1)) ;;
    HARD) emoji="❌"; HARD_FAILS=$((HARD_FAILS + 1)) ;;
  esac
  emit ""
  emit "### $id. $title — $emoji $status"
  emit ""
  if [ "$#" -gt 0 ]; then
    emit "$*"
  fi
}

# All SKILL.md files under plugins/ (excludes References/, .git/)
all_skills() {
  find plugins -name SKILL.md -not -path '*/.*' | sort
}

# All command files
all_commands() {
  find plugins -path '*/commands/*.md' -not -path '*/.*' | sort
}

# All plugin folders
all_plugins() {
  find plugins -maxdepth 1 -mindepth 1 -type d -not -path '*/.*' | sort
}

# ------- header -----------------------------------------------------------
emit "## Tier 1 — Static QA"
emit ""
emit "Generated $(date -Iseconds) by \`scripts/qa-marketplace.sh\`."
emit ""
emit "Repo root: \`$REPO_ROOT\`"

# ------- check 1: JSON validity ------------------------------------------
{
  bad=()
  for f in .claude-plugin/marketplace.json plugins/*/.claude-plugin/plugin.json; do
    if ! jq . "$f" >/dev/null 2>&1; then
      bad+=("$f")
    fi
  done
  if [ "${#bad[@]}" -eq 0 ]; then
    emit_check 1 "JSON validity" PASS "All $(ls plugins/*/.claude-plugin/plugin.json | wc -l | tr -d ' ') plugin manifests + marketplace.json parse cleanly."
  else
    emit_check 1 "JSON validity" HARD "Invalid JSON: $(printf '\n- `%s`' "${bad[@]}")"
  fi
}

# ------- check 2: frontmatter compliance ---------------------------------
{
  fails=()
  while IFS= read -r skill; do
    # extract frontmatter block (between leading --- markers)
    fm=$(awk '/^---$/{c++; next} c==1' "$skill")
    [ -z "$fm" ] && { fails+=("$skill — no frontmatter"); continue; }
    name=$(printf '%s\n' "$fm" | awk -F': *' '/^name:/{print $2; exit}')
    desc=$(printf '%s\n' "$fm" | awk -F': *' '/^description:/{$1=""; sub(/^ /,""); print; exit}')
    parent=$(basename "$(dirname "$skill")")
    [ -z "$name" ] && { fails+=("$skill — missing \`name:\`"); continue; }
    [ -z "$desc" ] && { fails+=("$skill — missing \`description:\`"); continue; }
    if [ "$name" != "$parent" ]; then
      fails+=("$skill — name '$name' ≠ parent dir '$parent'")
    fi
    if ! printf '%s' "$name" | grep -qE '^[a-z][a-z0-9]*(-[a-z0-9]+)*$'; then
      fails+=("$skill — name '$name' not lowercase-alphanumeric-hyphenated")
    fi
    desc_len=${#desc}
    if [ "$desc_len" -gt 1024 ]; then
      fails+=("$skill — description $desc_len chars > 1024")
    fi
  done < <(all_skills)
  total=$(all_skills | wc -l | tr -d ' ')
  if [ "${#fails[@]}" -eq 0 ]; then
    emit_check 2 "Frontmatter compliance ($total SKILL.md)" PASS "name/description present; name matches parent dir; lowercase-hyphenated; description ≤ 1024 chars."
  else
    out="${#fails[@]} of $total failures:"
    for f in "${fails[@]}"; do out+=$'\n'"- $f"; done
    emit_check 2 "Frontmatter compliance ($total SKILL.md)" HARD "$out"
  fi
}

# ------- check 3: cross-reference resolution -----------------------------
# Allowlist: refs to plugins removed in v1.0.0 are intentional historical
# pointers in README migration table + CHANGELOG migration entry.
{
  unresolved=()
  allow_prefix='manfred-a11y:|manfred-product:|manfred-writing:'
  # capture refs; require trailing word boundary so we don't pick up the
  # trailing dash from "manfred-toolkit:linkedin-*" wildcard mentions.
  # Perl gives us proper greedy matching with word boundaries — BSD grep on
  # macOS lacks -P, and ERE backtracking emits partial captures like
  # "manfred-toolkit:linkedin" alongside "manfred-toolkit:linkedin-teach".
  refs=$(find plugins docs shared -name '*.md' 2>/dev/null; \
         echo README.md; echo CHANGELOG.md) || true
  # The (?!-) lookahead avoids false positives on wildcard idioms like
  # "manfred-toolkit:linkedin-*" (used in docs to mean "the linkedin trio").
  refs=$(printf '%s\n' "$refs" | xargs perl -nle 'print $& while /\bmanfred-[a-z-]+:[a-z][a-z0-9]+(?:-[a-z0-9]+)*\b(?!-)/g' 2>/dev/null \
    | grep -vE "^($allow_prefix)" \
    | sort -u)
  for ref in $refs; do
    plugin="${ref%:*}"
    skill="${ref#*:}"
    if [ ! -f "plugins/$plugin/skills/$skill/SKILL.md" ] && [ ! -f "plugins/$plugin/commands/$skill.md" ]; then
      unresolved+=("$ref")
    fi
  done
  ref_count=$(printf '%s\n' "$refs" | grep -c . || true)
  if [ "${#unresolved[@]}" -eq 0 ]; then
    emit_check 3 "Cross-reference resolution ($ref_count unique active refs)" PASS "Every \`manfred-X:Y\` reference resolves to a real SKILL.md or command file. (Allowlisted historical refs to removed plugins not counted.)"
  else
    out="${#unresolved[@]} dangling refs (locations below):"
    for r in "${unresolved[@]}"; do
      loc=$(grep -rln -F "$r" --include='*.md' . 2>/dev/null | grep -v 'qa-reports/' | head -3 | sed 's|^|    |')
      out+=$'\n'"- \`$r\`"$'\n'"$loc"
    done
    emit_check 3 "Cross-reference resolution ($ref_count unique active refs)" HARD "$out"
  fi
}

# ------- check 4: voice scan ---------------------------------------------
# Pre-processing: per-file, blank out (a) lines inside ``` fenced code blocks
# and (b) backtick-quoted spans on each line. We blank rather than delete so
# line numbers in the report still match the source. Marketing-verb mentions
# inside `code` or fenced blocks are technical references (e.g. CSS
# `transform`), not voice violations.
{
  pattern='leverage|transform|empower|unlock|synergy|world-class|cutting-edge|best-in-class|passionate about|let.s get you started|supercharge'
  preprocess() {
    awk '
      BEGIN { fence = 0 }
      {
        line = $0
        # Toggle fence state on lines that start with ``` (optionally after
        # whitespace). Blank the fence line itself + everything inside.
        if (line ~ /^[[:space:]]*```/) {
          fence = !fence
          print ""
          next
        }
        if (fence) { print ""; next }
        # Strip inline backtick spans. Repeat until no pair remains so multiple
        # spans on one line are all removed.
        while (match(line, /`[^`]*`/)) {
          line = substr(line, 1, RSTART - 1) substr(line, RSTART + RLENGTH)
        }
        print line
      }
    ' "$1"
  }
  hits=""
  while IFS= read -r skill; do
    file_hits=$(preprocess "$skill" \
      | grep -nEi "\b($pattern)\b" 2>/dev/null \
      | grep -viE 'never:|anti-pattern|red flag|don.t use|avoid:|forbidden|ban list|skip when|negative|excuse|refuses|❌|→ Stop' || true)
    [ -z "$file_hits" ] && continue
    # Re-attach the original line text (preprocessed line may have backtick
    # spans stripped, which would mislead the reader) using the line number.
    while IFS= read -r h; do
      [ -z "$h" ] && continue
      lineno="${h%%:*}"
      orig=$(awk -v n="$lineno" 'NR==n{print; exit}' "$skill")
      hits+="$skill:$lineno:$orig"$'\n'
    done <<< "$file_hits"
  done < <(all_skills)
  hits="${hits%$'\n'}"
  hit_count=$(printf '%s\n' "$hits" | grep -c . 2>/dev/null || true)
  hit_count=${hit_count:-0}
  if [ "$hit_count" -eq 0 ]; then
    emit_check 4 "Voice scan (anti-pattern words)" PASS "No marketing verbs / corporate adjectives outside intentional callouts."
  else
    snippet=$(printf '%s\n' "$hits" | head -20)
    out=$'```\n'"$snippet"$'\n```\n\n'"$hit_count hits — verify each is an intentional anti-pattern callout. If not, rewrite. (Backtick / fenced code blocks are skipped.)"
    emit_check 4 "Voice scan (anti-pattern words)" SOFT "$out"
  fi
}

# ------- check 5: hex scan -----------------------------------------------
{
  hits=$(grep -rEni '#[0-9a-fA-F]{6}\b' --include='SKILL.md' plugins/ 2>/dev/null \
    | grep -viE 'never|anti-pattern|don.t|avoid|❌|hex literal|raw hex|do not generate|reject|refuses' || true)
  hit_count=$(printf '%s\n' "$hits" | grep -c . 2>/dev/null || true)
  hit_count=${hit_count:-0}
  if [ "$hit_count" -eq 0 ]; then
    emit_check 5 "Hex scan (raw 6-digit hex)" PASS "No raw hex outside intentional anti-pattern examples."
  else
    snippet=$(printf '%s\n' "$hits" | head -20)
    out=$'```\n'"$snippet"$'\n```\n\n'"$hit_count hits — verify each is intentional. Tokens-only is the rule."
    emit_check 5 "Hex scan (raw 6-digit hex)" SOFT "$out"
  fi
}

# ------- check 6: attribution audit --------------------------------------
# We don't assert a count (the ledger drifts with new originals). Instead we
# list every skill WITHOUT the footer for human review — adapted skills
# missing the footer are the failure mode this catches.
{
  total=$(all_skills | wc -l | tr -d ' ')
  with_footer=$(grep -rl 'Structurally adapted from' --include='SKILL.md' plugins/ 2>/dev/null | wc -l | tr -d ' ')
  without_footer=$(all_skills | xargs grep -L 'Structurally adapted from' 2>/dev/null | sort)
  without_count=$((total - with_footer))
  preview=$(printf '%s\n' "$without_footer" | sed 's|plugins/||; s|/SKILL.md||' | head -30)
  body="**$with_footer/$total** SKILL.md carry the standard attribution footer. **$without_count** do NOT (Manfred-original by construction, OR adapted-but-missing-footer — review)."$'\n\n'"<details><summary>List ($without_count skills without footer)</summary>"$'\n\n```\n'"$preview"$'\n```\n</details>'
  emit_check 6 "Attribution audit (no-count assertion)" SOFT "$body"
}

# ------- check 7: plugin layout compliance -------------------------------
{
  fails=()
  while IFS= read -r p; do
    [ -f "$p/.claude-plugin/plugin.json" ] || fails+=("$p — missing .claude-plugin/plugin.json")
    [ -f "$p/README.md" ] || fails+=("$p — missing README.md")
    skill_count=$(find "$p/skills" -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')
    [ "$skill_count" -ge 1 ] || fails+=("$p — no SKILL.md found under skills/")
  done < <(all_plugins)
  total=$(all_plugins | wc -l | tr -d ' ')
  if [ "${#fails[@]}" -eq 0 ]; then
    emit_check 7 "Plugin layout ($total plugins)" PASS "Every plugin has plugin.json + README.md + ≥ 1 SKILL.md."
  else
    out="${#fails[@]} fails:"
    for f in "${fails[@]}"; do out+=$'\n'"- $f"; done
    emit_check 7 "Plugin layout ($total plugins)" HARD "$out"
  fi
}

# ------- check 8: command frontmatter ------------------------------------
{
  fails=()
  while IFS= read -r cmd; do
    has_desc=$(grep -c '^description:' "$cmd" 2>/dev/null || echo 0)
    has_hint=$(grep -c '^argument-hint:' "$cmd" 2>/dev/null || echo 0)
    [ "$has_desc" -ge 1 ] || fails+=("$cmd — missing \`description:\`")
    [ "$has_hint" -ge 1 ] || fails+=("$cmd — missing \`argument-hint:\`")
  done < <(all_commands)
  total=$(all_commands | wc -l | tr -d ' ')
  if [ "${#fails[@]}" -eq 0 ]; then
    emit_check 8 "Command frontmatter ($total commands)" PASS "Every command file has \`description:\` + \`argument-hint:\`."
  else
    out="${#fails[@]} fails:"
    for f in "${fails[@]}"; do out+=$'\n'"- $f"; done
    emit_check 8 "Command frontmatter ($total commands)" SOFT "$out"
  fi
}

# ------- check 9: plugin-table <-> disk consistency ----------------------
{
  on_disk=$(all_plugins | xargs -n1 basename | sort)
  in_marketplace=$(jq -r '.plugins[].name' .claude-plugin/marketplace.json | sort)
  diff_out=$(diff <(printf '%s\n' "$on_disk") <(printf '%s\n' "$in_marketplace") || true)
  if [ -z "$diff_out" ]; then
    in_readme=$(grep -oE '^\| `manfred-[a-z-]+`' README.md | sed 's/^| `//; s/`$//' | sort)
    readme_diff=$(diff <(printf '%s\n' "$on_disk") <(printf '%s\n' "$in_readme") || true)
    if [ -z "$readme_diff" ]; then
      emit_check 9 "Plugin-table consistency" PASS "Plugin folders ⇔ marketplace.json ⇔ README plugin table all align."
    else
      emit_check 9 "Plugin-table consistency" SOFT $'README plugin table diverges from disk:\n```\n'"$readme_diff"$'\n```'
    fi
  else
    emit_check 9 "Plugin-table consistency" HARD $'marketplace.json diverges from disk:\n```\n'"$diff_out"$'\n```'
  fi
}

# ------- check 10: skill body sanity -------------------------------------
{
  fails=()
  while IFS= read -r skill; do
    # everything after the second `---` (the frontmatter close);
    # don't count further `---` lines (those are markdown horizontal rules).
    body=$(awk 'BEGIN{c=0; body=0} /^---$/ && c<2 {c++; if(c==2)body=1; next} body' "$skill" | tr -d '[:space:]')
    body_chars=${#body}
    if [ "$body_chars" -lt 200 ]; then
      fails+=("$skill — body only $body_chars non-whitespace chars")
    fi
  done < <(all_skills)
  total=$(all_skills | wc -l | tr -d ' ')
  if [ "${#fails[@]}" -eq 0 ]; then
    emit_check 10 "Skill body sanity ($total SKILL.md)" PASS "Every skill has ≥ 200 non-whitespace body chars (no empty / stub files)."
  else
    out="${#fails[@]} fails:"
    for f in "${fails[@]}"; do out+=$'\n'"- $f"; done
    emit_check 10 "Skill body sanity ($total SKILL.md)" SOFT "$out"
  fi
}

# ------- summary ---------------------------------------------------------
emit ""
emit "### Tier 1 summary"
emit ""
emit "- HARD failures: **$HARD_FAILS**"
emit "- SOFT warnings: **$SOFT_FAILS**"
emit ""
if [ "$HARD_FAILS" -gt 0 ]; then
  emit "**Status: ❌ HARD FAIL** — fix the hard failures above before claiming v1.0.0 quality."
  exit 1
fi
if [ "$SOFT_FAILS" -gt 0 ]; then
  emit "**Status: ⚠️ PASS WITH WARNINGS** — review soft warnings; many are acceptable (intentional anti-pattern callouts)."
  exit 0
fi
emit "**Status: ✅ CLEAN** — all 10 static checks pass."
exit 0
