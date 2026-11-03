#!/usr/bin/env bash
#
# Runs `bazel test` on the examples that don't need other dependencies in
# 'examples/', with the MODULE.bazel in '$MODULE_FILE'. The other examples
# aren't loaded.

set -euo pipefail

cp "$RUNFILES_DIR/$MODULE_FILE" examples/MODULE.bazel

cd examples
exec "$BIT_BAZEL_BINARY" test \
  --lockfile_mode=off \
  --check_direct_dependencies=error \
  //compilation_mode/... \
  //features/... \
  //test/...
