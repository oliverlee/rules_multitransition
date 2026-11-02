#!/usr/bin/env bash
#
# Runs '$RUNNER' in the archive of the working tree in '$ARCHIVE', like the
# release archive that the BCR presubmit tests. The output base of the inner
# Bazel is in the output base of the outer Bazel and persists across runs.

set -euo pipefail

# one directory per test, which may run at the same time
dir="$BAZEL_OUTPUT_BASE/examples_test/${TEST_TARGET##*:}"

rm -rf "$dir/src"
mkdir -p "$dir/src"
tar -x -f "$RUNFILES_DIR/$ARCHIVE" -C "$dir/src"

# ignored by git
if [[ -f "$BAZEL_WORKSPACE_ROOT/user.bazelrc" ]]; then
  ln -s "$BAZEL_WORKSPACE_ROOT/user.bazelrc" "$dir/src/user.bazelrc"
fi

# the default of bazelisk, instead of the runfiles directory
if [[ "$OSTYPE" == darwin* ]]; then
  export BAZELISK_HOME="$HOME/Library/Caches/bazelisk"
else
  export BAZELISK_HOME="${XDG_CACHE_HOME:-$HOME/.cache}/bazelisk"
fi
export BIT_STARTUP_OPTIONS="--output_base=$dir/output_base"

runner="$RUNFILES_DIR/$RUNNER"
cd "$dir/src"
exec "$runner" "$@"
