"""
Repository rule with the workspace root and the output base of Bazel.
"""

visibility("private")

_PATHS_BZL = """\
OUTPUT_BASE = {output_base}
WORKSPACE_ROOT = {workspace_root}
"""

def _escape_make_variables(path):
    # 'env' expands Make variables
    return path.replace("$", "$$")

def _local_config_bazel_impl(rctx):
    rctx.file("paths.bzl", _PATHS_BZL.format(
        # the directory of this repository is '<output_base>/external/<name>'
        output_base = repr(_escape_make_variables(str(rctx.path(".").dirname.dirname))),
        workspace_root = repr(_escape_make_variables(str(rctx.workspace_root))),
    ))
    rctx.file("BUILD.bazel", "")

local_config_bazel = repository_rule(
    implementation = _local_config_bazel_impl,
)
