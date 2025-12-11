#!/usr/bin/env bash
set -euo pipefail
set -x

workspace_root="$1"
vendor_dir="$2"

output_base=$(mktemp -d)

cd "$workspace_root"
bazelisk \
    --output_base="$output_base" \
    test \
    --experimental_convenience_symlinks=ignore \
    --color=yes \
    --curses=yes \
    --vendor_dir="$vendor_dir" \
    --test_env=BAZEL_VENDOR_DIR="$vendor_dir" \
    //...
