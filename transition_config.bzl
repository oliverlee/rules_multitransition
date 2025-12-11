"""
Implementation of 'transition_config' and helper functions.
"""

load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load("@rules_cc//cc/common:debug_package_info.bzl", "DebugPackageInfo")
load("//:transition_config_flag.bzl", flag = "transition_config_flag")

visibility("private")

def _transition_config_binary_impl(ctx):
    """
    Implementation function for a binary rule that forwards providers.
    """
    target = ctx.attr.src
    default_info = target[DefaultInfo]

    binary = default_info.files_to_run.executable
    runfiles = default_info.default_runfiles

    # DefaultInfo can't just be forwarded. The 'executable' provided by an
    # executable rule needs to be created by the same rule.
    out = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.symlink(
        output = out,
        target_file = binary,
    )

    env = {}
    inherit_env = []
    if RunEnvironmentInfo in target:
        env = target[RunEnvironmentInfo].environment
        inherit_env = target[RunEnvironmentInfo].inherited_environment

    return [
        DefaultInfo(
            executable = out,
            runfiles = runfiles,
        ),
        RunEnvironmentInfo(
            environment = env,
            inherited_environment = inherit_env,
        ),
    ] + [
        target[provider]
        for provider in [
            CcInfo,
            DebugPackageInfo,
            OutputGroupInfo,
            InstrumentedFilesInfo,
        ]
        if provider in target
    ]

def _make_transition(flag_config):
    """
    Creates the transition rule used by the transition config binary and test rules.

    Args:
      flag_config: list of 'transition_config_flag'

    Specifies a transition where options are updated based on the provided
    attributes.

    For each provided attribute, if the attr type:
      is a list, the value is concatenated to the input value
      if not a list, the value replaces the input value

    Input values are unchanged for unprovided attributes.
    """
    flags = {
        flag.name: flag
        for flag in flag_config
    }

    def impl(settings, attr):
        updated = {}

        for key in attr.provided_attrs:
            flag = flags[key]
            value = getattr(attr, flag.name)

            # platforms can only be a single element list
            # https://github.com/bazelbuild/bazel/issues/10154
            if flag.option == "//command_line_option:platforms":
                if type(value) == "list":
                    if (len(value) != 1):
                        fail("platforms must be a single element list")
                    updated[flag.option] = value
                else:
                    updated[flag.option] = [value]
            elif type(value) == "list":
                updated[flag.option] = settings[flag.option] + value
            else:
                updated[flag.option] = value

        return settings | updated

    options = [flag.option for flag in flag_config]

    return transition(
        implementation = impl,
        inputs = options,
        outputs = options,
    )

def _make_transition_attrs(flag_config):
    """
    Creates 'attrs' needed by the transition config binary and test rules.

    Args:
      flag_config: list of 'transition_config_flag'

    Transforms each item in 'flag_config' to an 'attr' of a binary or test rule.
    Returns a dict containing the transformed 'transition_config_flag' objects
    with the following additional attrs:
    * 'src': the source label for the transition
    * 'provided_attrs': list of attributes to update in the transition
    * '_allowlist_function_transition': label needed to enable a transition
    """
    base_attrs = {
        "src": attr.label(
            mandatory = True,
            doc = "The source label for the transition.",
        ),
        "provided_attrs": attr.string_list(
            mandatory = True,
            doc = (
                "The attributes to transition. Used to distinguish if an " +
                "attr has been set to the default value or has not been set."
            ),
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    }

    flag_attrs = {
        flag.name: getattr(attr, flag.kind)()
        for flag in flag_config
    }

    for key in base_attrs.keys():
        if key in flag_attrs:
            fail("'{}' is not a permitted name for a transition config attr".format(key))

    return base_attrs | flag_attrs

def is_transition_config(config):
    """
    Check if the object is a transition config.
    """
    return getattr(config, "type", None) == "transition_config"

def make_transition_config_rules(flag_config):
    """
    Creates rules and helper functions to generate 'transition_config' objects.

    Args:
      flag_config: list of 'transition_config_flag'

    Returns a tuple of (binary rule, test rule, config function). The config
    function is used to create a 'transition_config' object needed by
    'multitransition_test'.

    The binary rule and test rules are not directly used but must be named in a
    .bzl file.
    """
    binary_rule, test_rule = [
        rule(
            implementation = _transition_config_binary_impl,
            cfg = _make_transition(flag_config),
            attrs = _make_transition_attrs(flag_config),
            test = is_test,
            provides = [DefaultInfo, RunEnvironmentInfo],
        )
        for is_test in [False, True]
    ]

    def config(
            *,
            name = None,
            **kwargs):
        return struct(
            type = "transition_config",
            name = name,
            binary_rule = binary_rule,
            test_rule = test_rule,
            attrs = kwargs,
        )

    return (
        binary_rule,
        test_rule,
        config,
    )

default_transition_config_flags = [
    getattr(flag, kind)(
        name,
        option = "//command_line_option:{}".format(name),
    )
    for kind, name in [
        ("label_list", "extra_toolchains"),
        ("label", "platforms"),
        ("string", "compilation_mode"),
        ("string_list", "copt"),
        ("string_list", "cxxopt"),
        ("string_list", "linkopt"),
    ]
]

(
    transition_config_binary,
    transition_config_test,
    transition_config,
) = make_transition_config_rules(default_transition_config_flags)
