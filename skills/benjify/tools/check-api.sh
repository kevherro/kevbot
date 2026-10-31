#!/usr/bin/env bash
# The public API is what the skill documents, and all of it has DocC.
# Fails on a public declaration without a /// comment, or whose name does
# not appear in references/api.md.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
src="$here/StageshowKit/Sources/StageshowKit"
api="$here/references/api.md"
fail=0
for f in "$src"/*.swift; do
  while IFS= read -r line; do
    echo "undocumented: $line"; fail=1
  done < <(awk -v f="$(basename "$f")" '
    /^[[:space:]]*(@[A-Za-z]+ )*public / { if (prev !~ /\/\/\// && prev !~ /^[[:space:]]*@/) print f ":" NR ": " $0 }
    !/^[[:space:]]*$/ { prev = $0 }' "$f")
done
names=$(grep -hoE '^[[:space:]]*(@[A-Za-z]+ )*public (static |indirect |final |nonisolated )*(func|var|let|struct|enum|class|typealias|case|init|subscript)[[:space:]]*[A-Za-z_]*' "$src"/*.swift \
  | sed -E 's/.*(func|var|let|struct|enum|class|typealias|case)[[:space:]]+//; s/.*(init|subscript).*/\1/' | sort -u)
for n in $names; do
  case $n in init|subscript|body|callAsFunction) continue ;; esac
  grep -q "\b$n\b" "$api" || { echo "not in api.md: $n"; fail=1; }
done
[[ $fail == 0 ]] && echo "api ok"
exit $fail
