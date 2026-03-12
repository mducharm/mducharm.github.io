#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
ESSAYS_DIR="$ROOT/essays"
TOOLS_DIR="$ROOT/tools"
TEMPLATE="$ROOT/template.html"

# --- Convert essays from .md to .html ---

for md in "$ESSAYS_DIR"/*.md; do
  [ -f "$md" ] || continue
  html="${md%.md}.html"
  pandoc "$md" \
    --template="$TEMPLATE" \
    --standalone \
    -o "$html"
done

# --- Generate index.html ---

# Collect essay metadata, sorted by date descending
essay_entries=""
for md in "$ESSAYS_DIR"/*.md; do
  [ -f "$md" ] || continue

  title=$(sed -n 's/^title: *//p' "$md" | head -1)
  date=$(sed -n 's/^date: *//p' "$md" | head -1)
  description=$(sed -n 's/^description: *//p' "$md" | head -1)
  slug=$(basename "${md%.md}")

  essay_entries+="$date	$title	$description	$slug"$'\n'
done

sorted_entries=$(echo -n "$essay_entries" | sort -t$'\t' -k1 -r)

# Build essay list HTML
essay_list_html=""
while IFS=$'\t' read -r date title description slug; do
  [ -z "$date" ] && continue
  essay_list_html+="    <li>"
  essay_list_html+="<a href=\"/essays/${slug}.html\" class=\"essay-title\">${title}</a>"
  essay_list_html+=" <span class=\"essay-date\">${date}</span>"
  if [ -n "$description" ]; then
    essay_list_html+=" <span class=\"essay-description\">${description}</span>"
  fi
  essay_list_html+="</li>"$'\n'
done <<< "$sorted_entries"

# Build tools list HTML
tools_list_html=""
if [ -d "$TOOLS_DIR" ]; then
  for tool_dir in "$TOOLS_DIR"/*/; do
    [ -d "$tool_dir" ] || continue
    tool_name=$(basename "$tool_dir")
    display_name=$(echo "$tool_name" | tr '-' ' ')
    tools_list_html+="    <li><a href=\"/tools/${tool_name}/\">${display_name}</a></li>"$'\n'
  done
fi

# Write index.html
cat > "$ROOT/index.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>mducharm</title>
  <link rel="stylesheet" href="/style.css">
</head>
<body>
  <header class="site-header">
    <a href="/">mducharm</a>
  </header>

  <section>
    <h2>Essays</h2>
    <ul class="essay-list">
${essay_list_html}    </ul>
  </section>

EOF

if [ -n "$tools_list_html" ]; then
  cat >> "$ROOT/index.html" << EOF
  <section class="tools-section">
    <h2>Tools</h2>
    <ul class="tools-list">
${tools_list_html}    </ul>
  </section>

EOF
fi

cat >> "$ROOT/index.html" << EOF
</body>
</html>
EOF

echo "Build complete."
