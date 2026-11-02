"""
Macro for the integration tests that run Bazel in the archive of the working tree.
"""

load("@local_config_bazel//:paths.bzl", "OUTPUT_BASE", "WORKSPACE_ROOT")
load(
    "@rules_bazel_integration_test//bazel_integration_test:defs.bzl",
    _bazel_integration_test = "bazel_integration_test",
)

visibility("private")

def bazel_integration_test(
        *,
        name,
        bazel_binary,
        runner,
        env = {}):
    """
    Runs a script with Bazel in the archive of the working tree.

    `setup.bash` extracts the archive to a persistent directory in the output
    base of the outer Bazel, and runs `runner` in it with the arguments of the
    test.

    Args:
      name: **str**
        the name of the test
      bazel_binary: **label**
        the inner Bazel, from `bazel_binaries.label`
      runner: **label**
        the script that runs the inner Bazel in `$BIT_BAZEL_BINARY`
      env: **dict[str, str]**
        additional environment variables of `runner`
    """
    _bazel_integration_test(
        name = name,
        # The values of these variables differ between machines and are part of
        # the cache key of this test. The actions of the inner Bazel are still
        # shared through the remote cache.
        additional_env_inherit = [
            # tools that the examples find on 'PATH', e.g. 'nix' for 'cortex_m'
            "PATH",
            # caches of Bazel and bazelisk
            "HOME",
        ] + select({
            "@platforms//os:macos": [
                # the CA certificates for 'nix', which installers set on macOS
                "NIX_SSL_CERT_FILE",
            ],
            "//conditions:default": [
                # the cache of bazelisk
                "XDG_CACHE_HOME",
            ],
        }),
        bazel_binary = bazel_binary,
        data = [
            runner,
            "@git_archive//:archive.tar",
        ],
        env = env | {
            "ARCHIVE": "$(rlocationpath @git_archive//:archive.tar)",
            "BAZEL_OUTPUT_BASE": OUTPUT_BASE,
            "BAZEL_WORKSPACE_ROOT": WORKSPACE_ROOT,
            "RUNNER": "$(rlocationpath {})".format(runner),
        },
        tags = [
            "no-sandbox",
            "requires-network",
        ],
        test_runner = "//test:setup",
    )
