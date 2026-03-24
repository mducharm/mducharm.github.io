#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
ESSAYS_DIR="$ROOT/essays"
TOOLS_DIR="$ROOT/tools"
GUIDES_DIR="$ROOT/guides"
TEMPLATE="$ROOT/template.html"
GUIDES_TEMPLATE="$ROOT/guides/template.html"

# --- Convert essays from .md to .html ---

for md in "$ESSAYS_DIR"/*.md; do
  [ -f "$md" ] || continue
  html="${md%.md}.html"
  pandoc "$md" \
    --template="$TEMPLATE" \
    --standalone \
    -o "$html"
done

# --- Convert guides from .md to .html ---

for md in "$GUIDES_DIR"/*.md; do
  [ -f "$md" ] || continue
  html="${md%.md}.html"
  pandoc "$md" \
    --template="$GUIDES_TEMPLATE" \
    --standalone \
    -o "$html"
done

# --- Generate guides/index.html ---

guide_entries=""
for md in "$GUIDES_DIR"/*.md; do
  [ -f "$md" ] || continue

  title=$(sed -n 's/^title: *//p' "$md" | head -1)
  date=$(sed -n 's/^date: *//p' "$md" | head -1)
  description=$(sed -n 's/^description: *//p' "$md" | head -1)
  slug=$(basename "${md%.md}")

  guide_entries+="$date	$title	$description	$slug"$'\n'
done

sorted_guides=$(echo -n "$guide_entries" | sort -t$'\t' -k1 -r)

guide_list_html=""
while IFS=$'\t' read -r date title description slug; do
  [ -z "$date" ] && continue
  guide_list_html+="    <li>"
  guide_list_html+="<a href=\"/guides/${slug}.html\">${title}</a>"
  if [ -n "$description" ]; then
    guide_list_html+=" <span class=\"guide-desc\">${description}</span>"
  fi
  guide_list_html+="</li>"$'\n'
done <<< "$sorted_guides"

cat > "$GUIDES_DIR/index.html" << GUIDESEOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Guides</title>
  <link rel="stylesheet" href="/guides/guide-style.css">
</head>
<body>
  <a href="/" class="back-link">&larr; back</a>
  <h1>Guides</h1>
  <p class="guide-description">Steam Deck setup, mods, and other things I figured out so you don't have to.</p>
  <ul class="guide-list">
${guide_list_html}  </ul>
</body>
</html>
GUIDESEOF

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

if [ -n "$guide_list_html" ]; then
  # Build a simpler list for the main index
  index_guide_html=""
  while IFS=$'\t' read -r date title description slug; do
    [ -z "$date" ] && continue
    index_guide_html+="    <li><a href=\"/guides/${slug}.html\">${title}</a></li>"$'\n'
  done <<< "$sorted_guides"

  cat >> "$ROOT/index.html" << EOF
  <section class="tools-section">
    <h2>Guides</h2>
    <ul class="tools-list">
${index_guide_html}    </ul>
  </section>

EOF
fi

cat >> "$ROOT/index.html" << EOF
</body>
</html>
EOF

echo "Build complete."
