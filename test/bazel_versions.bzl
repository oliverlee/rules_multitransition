"""
Versions of Bazel for the integration tests.
"""

visibility(["//test/..."])

# the versions of Bazel and their flags, starting with the minimum version
BAZEL_VERSIONS = [
    {
        "flags": ["--lockfile_mode=off", "--config=bazel7"],
        "version": "7.1.0",
    },
    {
        "flags": [],
        "version": "pinned",
    },
    {
        "flags": ["--lockfile_mode=off"],
        "version": "8.x",
    },
    {
        "flags": ["--lockfile_mode=off"],
        "version": "9.x",
    },
]
