"""
Options that every generated transition can set without a `multitransition`
extension tag.
"""

visibility("//...")

DEFAULT_OPTIONS = [
    "//command_line_option:{}".format(name)
    for name in [
        "compilation_mode",
        "copt",
        "cxxopt",
        "extra_toolchains",
        "features",
        "linkopt",
        "platforms",
    ]
]
