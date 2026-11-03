#!/usr/bin/env bash
#
# Runs `bazel test //...` in 'examples/'.
#
# Arguments, e.g. from `--test_arg`, replace the target pattern `//...`.

set -euo pipefail

if (($# == 0)); then
  set -- //...
fi

cd examples
# shellcheck disable=SC2086
exec "$BIT_BAZEL_BINARY" test $BAZEL_TEST_OPTS "$@"
