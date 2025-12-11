#!/usr/bin/env bash
set -euo pipefail

workspace_root="$1"
target="$2"
pattern="$3"

cd "$workspace_root"

bazelisk aquery \
    "mnemonic(CppCompile, deps($target))" \
    --curses=yes \
    --output=jsonproto \
    "${BAZEL_VENDOR_DIR:+--vendor_dir="$BAZEL_VENDOR_DIR"}" \
  | jq -r '.actions[].arguments[]' \
  | grep --word-regexp -- "$pattern"
