#!/usr/bin/env bash
# The public API is what the skill documents, and all of it has DocC.
# Fails on a public declaration without a /// comment, or whose name does
# not appear in references/api.md, or on a link-like Text literal.
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
# A Text("...") literal is a localized key with markdown: an email or a URL
# in it draws as a blue link. Scenes write such words with Text(verbatim:).
while IFS= read -r hit; do
  echo "link-like Text literal (use Text(verbatim:)): $hit"; fail=1
done < <(grep -rnE 'Text\("[^"]*([A-Za-z0-9]@[A-Za-z0-9]|://|www\.)[^"]*"\)' "$here/examples" "$here/tools/Runner/App" "$src" || true)
[[ $fail == 0 ]] && echo "api ok"
exit $fail
