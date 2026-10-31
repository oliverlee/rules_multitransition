"""
Test that the C++ compile actions of a target include or omit a flag.
"""

load("@bazel_skylib//lib:shell.bzl", "shell")

visibility("public")

_CompileActionsInfo = provider(
    doc = "The 'CppCompile' actions of a target and its 'src'.",
    fields = {
        "actions": "list of struct(argv, output): command line and object file path",
    },
)

def _compile_actions_aspect_impl(target, ctx):
    actions = [
        struct(
            argv = action.argv,
            output = action.outputs.to_list()[0].path,
        )
        for action in target.actions
        if action.mnemonic == "CppCompile" and action.argv
    ]

    # 'src' of a 'multitransition.test' variant, built in the transitioned
    # configuration
    src = getattr(ctx.rule.attr, "src", None)
    if src and _CompileActionsInfo in src:
        actions += src[_CompileActionsInfo].actions

    return [_CompileActionsInfo(actions = actions)]

_compile_actions_aspect = aspect(
    implementation = _compile_actions_aspect_impl,
    attr_aspects = ["src"],
)

_PASS_SCRIPT = """\
#!/usr/bin/env bash
exit 0
"""

_FAIL_SCRIPT = """\
#!/usr/bin/env bash
echo {} >&2
exit 1
"""

def _compile_flags_test_impl(ctx):
    actions = ctx.attr.target[_CompileActionsInfo].actions
    expected = ctx.attr.expect == "present"

    # e.g. on Linux, 'opt' compiles both a PIC and a non-PIC object
    mismatched = [
        action.output
        for action in actions
        if (ctx.attr.flag in action.argv) != expected
    ]

    error = None
    if not actions:
        error = "no CppCompile actions in {}".format(ctx.attr.target.label)
    elif mismatched:
        error = "expected '{}' to be {} in every CppCompile action of {}, not in: {}".format(
            ctx.attr.flag,
            ctx.attr.expect,
            ctx.attr.target.label,
            ", ".join(mismatched),
        )

    script = ctx.actions.declare_file(ctx.label.name + ".bash")
    ctx.actions.write(
        output = script,
        content = _FAIL_SCRIPT.format(shell.quote(error)) if error else _PASS_SCRIPT,
        is_executable = True,
    )
    return [DefaultInfo(executable = script)]

compile_flags_test = rule(
    implementation = _compile_flags_test_impl,
    test = True,
    attrs = {
        "expect": attr.string(
            mandatory = True,
            values = ["present", "absent"],
            doc = "Whether 'flag' is expected in every compile action.",
        ),
        "flag": attr.string(
            mandatory = True,
            doc = "A compiler argument, matched exactly, e.g. '-O2'.",
        ),
        "target": attr.label(
            mandatory = True,
            aspects = [_compile_actions_aspect],
            doc = "The target whose compile actions are checked.",
        ),
    },
    doc = "Checks that every 'CppCompile' action of 'target' includes or omits 'flag'.",
)
