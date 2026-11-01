#!/usr/bin/env bash
set -euo pipefail

for generated in "$@"; do
  dest="$BUILD_WORKSPACE_DIRECTORY/${generated%_generated.md}.md"
  cp -f "$generated" "$dest"
  chmod 644 "$dest"
done
