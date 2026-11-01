"""
Aspect that lists the source files of a target and its transitive 'deps'.
"""

visibility("public")

_TransitiveSourceFilesInfo = provider(
    doc = "Source files of a target and its transitive 'deps'.",
    fields = {
        "files": "depset of File",
    },
)

def _transitive_source_files_impl(target, ctx):
    files = depset(
        [
            f
            for attr in ["srcs", "hdrs"]
            for src in getattr(ctx.rule.attr, attr, [])
            for f in src.files.to_list()
            if f.is_source
        ],
        transitive = [
            dep[_TransitiveSourceFilesInfo].files
            for dep in getattr(ctx.rule.attr, "deps", [])
        ],
    )

    out = ctx.actions.declare_file(target.label.name + ".source_files.txt")
    ctx.actions.write(
        output = out,
        content = "".join(sorted([f.basename + "\n" for f in files.to_list()])),
    )

    return [
        _TransitiveSourceFilesInfo(files = files),
        OutputGroupInfo(transitive_source_files = depset([out])),
    ]

transitive_source_files = aspect(
    implementation = _transitive_source_files_impl,
    attr_aspects = ["deps"],
    doc = """\
Writes '<name>.source_files.txt' with the basenames of the 'srcs' and 'hdrs' of
a target and its transitive 'deps', in the 'transitive_source_files' output
group.
""",
)
