"""
The transition and the transitioned target, binary, and test rules.

The transition can set the options in `OPTIONS`, which the
`multitransition_config` module extension generates from the declarations in
the module graph.
"""

load("@multitransition_config//:defs.bzl", _OPTIONS = "OPTIONS")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load("@rules_cc//cc/common:debug_package_info.bzl", "DebugPackageInfo")

visibility("//...")

OPTIONS = _OPTIONS

_PLATFORMS = "//command_line_option:platforms"

_BOOLS = {
    "0": False,
    "1": True,
    "false": False,
    "true": True,
}

def _convert(option, current, values):
    """
    Converts the string values for `option` to the type of its current value.

    Lists are appended to, except `platforms`, which is replaced. Scalars
    take exactly one value.
    """
    kind = type(current)

    if kind == "list":
        if option == _PLATFORMS:
            # replaced with the single label checked by 'transition_options'
            # https://github.com/bazelbuild/bazel/issues/10154
            return values
        return current + values

    if len(values) != 1:
        fail("'{}' takes exactly one value, got {}".format(option, values))
    value = values[0]

    if kind == "bool":
        if value.lower() not in _BOOLS:
            fail("'{}' expects one of {}, got '{}'".format(
                option,
                _BOOLS.keys(),
                value,
            ))
        return _BOOLS[value.lower()]
    if kind == "int":
        return int(value)

    # string, Label, NoneType (no default to infer a type from), or a native
    # enum option, e.g. 'CompilationMode'. Enum options expose their Java type,
    # so they can't be listed exhaustively.
    return value

def _transition_impl(settings, attr):
    return settings | {
        option: _convert(option, settings[option], values)
        for option, values in attr.options.items()
    }

_FORWARDED_PROVIDERS = [
    CcInfo,
    DebugPackageInfo,
    OutputGroupInfo,
    InstrumentedFilesInfo,
]

def _forwarded_providers(target):
    return [
        target[provider]
        for provider in _FORWARDED_PROVIDERS
        if provider in target
    ]

def _forward_target_impl(ctx):
    """
    Forwards the providers of `src`, built in the transitioned configuration.
    """
    target = ctx.attr.src
    default_info = target[DefaultInfo]

    return [
        DefaultInfo(
            files = default_info.files,
            runfiles = default_info.default_runfiles,
        ),
    ] + _forwarded_providers(target)

def _forward_executable_impl(ctx):
    """
    Forwards the providers of executable `src`.

    `src` is built in the transitioned configuration.
    """
    target = ctx.attr.src
    default_info = target[DefaultInfo]

    # DefaultInfo can't just be forwarded. The 'executable' provided by an
    # executable rule needs to be created by the same rule.
    out = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.symlink(
        output = out,
        target_file = default_info.files_to_run.executable,
    )

    env = {}
    inherit_env = []
    if RunEnvironmentInfo in target:
        env = target[RunEnvironmentInfo].environment
        inherit_env = target[RunEnvironmentInfo].inherited_environment

    return [
        DefaultInfo(
            executable = out,
            runfiles = default_info.default_runfiles,
        ),
        RunEnvironmentInfo(
            environment = env,
            inherited_environment = inherit_env,
        ),
    ] + _forwarded_providers(target)

TRANSITION = transition(
    implementation = _transition_impl,
    inputs = OPTIONS,
    outputs = OPTIONS,
)

def attrs(aspects = []):
    """
    Attributes of a transitioned rule.

    Args:
      aspects: **list of aspects**
          The aspects to apply to `src`.

    Returns:
      A dict with the `options` and `src` attributes.
    """
    return {
        "options": attr.string_list_dict(
            doc = "Option to values. Only listed options are changed.",
        ),
        "src": attr.label(
            mandatory = True,
            aspects = aspects,
            doc = "The target to build in the transitioned configuration.",
        ),
    }

transitioned_target = rule(
    implementation = _forward_target_impl,
    cfg = TRANSITION,
    attrs = attrs(),
)

transitioned_binary = rule(
    implementation = _forward_executable_impl,
    cfg = TRANSITION,
    attrs = attrs(),
    executable = True,
    provides = [DefaultInfo, RunEnvironmentInfo],
)

transitioned_test = rule(
    implementation = _forward_executable_impl,
    cfg = TRANSITION,
    attrs = attrs(),
    test = True,
    provides = [DefaultInfo, RunEnvironmentInfo],
)
