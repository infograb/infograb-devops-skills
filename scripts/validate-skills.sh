#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ERRORS=0
CHECKED=0

SKIP_DIRS=".git|.github|.claude-plugin|docs|packages|scripts|node_modules"

for dir in "$REPO_ROOT"/*/; do
  dirname="$(basename "$dir")"

  if echo "$dirname" | grep -qE "^($SKIP_DIRS)$"; then
    continue
  fi

  skill_file="$dir/SKILL.md"
  if [ ! -f "$skill_file" ]; then
    continue
  fi

  CHECKED=$((CHECKED + 1))

  first_line="$(head -1 "$skill_file")"
  if [ "$first_line" != "---" ]; then
    echo "FAIL: $dirname/SKILL.md - frontmatter missing"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # macOS 호환: head -n -1 대신 sed로 마지막 줄(---) 제거
  frontmatter="$(sed -n '2,/^---$/p' "$skill_file" | sed '$d')"

  name_value="$(echo "$frontmatter" | grep -E "^name:" | sed 's/^name:[[:space:]]*//')"
  if [ -z "$name_value" ]; then
    echo "FAIL: $dirname/SKILL.md - name field missing"
    ERRORS=$((ERRORS + 1))
  elif [ "$name_value" != "$dirname" ]; then
    echo "FAIL: $dirname/SKILL.md - name '$name_value' != dir '$dirname'"
    ERRORS=$((ERRORS + 1))
  fi

  desc_value="$(echo "$frontmatter" | grep -E "^description:" | sed 's/^description:[[:space:]]*//')"
  if [ -z "$desc_value" ]; then
    echo "FAIL: $dirname/SKILL.md - description field missing"
    ERRORS=$((ERRORS + 1))
  fi

  echo "OK: $dirname/SKILL.md"
done

echo ""
echo "Checked: $CHECKED skills, $ERRORS errors"

if [ "$ERRORS" -gt 0 ]; then
  exit 1
fi

if [ "$CHECKED" -eq 0 ]; then
  echo "No skills found to validate."
fi
