"""
extension for obtaining the local workspace directory
"""

def _local_workspace_directory_impl(rctx):
    rctx.file(
        "BUILD.bazel",
        content = """\
exports_files(["defs.bzl"])
        """,
        executable = False,
    )

    rctx.file(
        "defs.bzl",
        content = """
WORKSPACE_ROOT = "{workspace_root}"
""".format(
            workspace_root = rctx.workspace_root,
        ),
        executable = False,
    )

_local_workspace_directory = repository_rule(
    implementation = _local_workspace_directory_impl,
    local = True,
)

def _local_config_impl(_mctx):
    _local_workspace_directory(
        name = "local_workspace_directory",
    )

local_config = module_extension(
    implementation = _local_config_impl,
)
