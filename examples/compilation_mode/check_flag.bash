#!/usr/bin/env bash
set -euo pipefail

# usage: check_flag.bash <workspace root> <target> <flag> <present|absent>
workspace_root="$1"
target="$2"
flag="$3"
expect="$4"

cd "$workspace_root"

bazelisk aquery \
    "mnemonic(CppCompile, deps($target))" \
    --color=yes \
    --curses=yes \
    --output=jsonproto \
    "${BAZEL_VENDOR_DIR:+--vendor_dir="$BAZEL_VENDOR_DIR"}" \
  | jq -e --arg flag "$flag" --arg expect "$expect" '
      if $expect | IN("present", "absent") | not then
        error("expect must be present or absent, got \($expect)")
      else
        any(.actions[].arguments[]; . == $flag) == ($expect == "present")
      end' \
  > /dev/null \
  || {
    echo "expected '$flag' to be $expect in CppCompile actions of $target" >&2
    exit 1
  }
