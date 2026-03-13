# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build

Requires `pandoc`. Run `./build.sh` to convert `essays/*.md` → HTML and regenerate `index.html`.

A pre-commit hook (`.githooks/pre-commit`) runs the build and stages generated HTML automatically. Set up with `git config core.hooksPath .githooks`.

## Key Points

- Static site for GitHub Pages — no framework, no bundler, no package manager.
- `build.sh` is the entire build system: pandoc templates essays, parses YAML frontmatter for the index, and auto-discovers tools in `tools/`.
- `essays/*.html` and `index.html` are generated — don't edit them directly.
- New essay: create `essays/<slug>.md` with `title`, `date`, `description` frontmatter.
- New tool: add a `tools/<name>/` directory with an `index.html`.
