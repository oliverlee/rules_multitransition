"""
extension for obtaining the local workspace directory
"""

visibility("//...")

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
BAZEL_EXTERNAL_DIRECTORY = "{external}"
BAZEL_WORKSPACE_ROOT = "{workspace_root}"
""".format(
            external = str(rctx.path(".").realpath)
                .removesuffix(rctx.name),
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
