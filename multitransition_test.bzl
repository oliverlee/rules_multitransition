"""
Implementation of 'multitransition_test' macro.
"""

load("//:transition_config.bzl", "is_transition_config")
load("//private:rules.bzl", "OPTIONS", "transitioned_test")

visibility("private")

_NATIVE_PREFIX = "//command_line_option:"

# `--platforms` is list-typed but only one target platform is supported.
# https://github.com/bazelbuild/bazel/issues/10154
_PLATFORM_KEY = "platform"
_PLATFORMS_OPTION = _NATIVE_PREFIX + "platforms"

def _append_if_missing(values, item):
    """
    Appends an element to a list if not already present.
    """
    if item in values:
        return values
    return values + [item]

def _canonical_label(value):
    return str(native.package_relative_label(value))

def _option_key(key):
    """
    Converts a 'transition_config' key to a transition option.

    Returns '//command_line_option:<name>' or a canonical label.
    """
    if type(key) == "Label":
        return str(key)
    if key.startswith(_NATIVE_PREFIX):
        return key
    if key.startswith(("@", "//", ":")):
        return _canonical_label(key)

    if key == _PLATFORM_KEY:
        return _PLATFORMS_OPTION
    return _NATIVE_PREFIX + key

def _option_value(value):
    """
    Converts one value to a string.

    Labels are resolved against the calling package, as the transition would
    otherwise resolve them against this repo, where e.g. '@cortex_m' isn't
    visible.
    """
    if type(value) == "bool":
        return "true" if value else "false"
    if type(value) == "Label":
        return str(value)
    value = str(value)
    if value.startswith(("@", ":", "//")):
        return _canonical_label(value)
    return value

def _option_values(value):
    if type(value) in ("list", "tuple"):
        return [_option_value(v) for v in value]
    return [_option_value(value)]

def _flags(config):
    flags = {}
    for key, value in config.flags.items():
        option = _option_key(key)
        if option == _PLATFORMS_OPTION and key != _PLATFORM_KEY:
            fail("Use 'platform' to set the target platform, not '{}'.".format(key))
        if option not in OPTIONS:
            fail(
                ("'{}' ({}) can't be set by 'transition_config'. Declare it in " +
                 "MODULE.bazel with 'multitransition.flag(setting = ...)' or " +
                 "'multitransition.command_line_option(name = ...)'.").format(key, option),
            )
        if option == _PLATFORMS_OPTION and type(value) in ("list", "tuple"):
            fail("'platform' takes a single label, got {}".format(value))
        flags[option] = _option_values(value)
    return flags

def multitransition_test(
        test_rule,
        *,
        name,
        transitions,
        tags = [],
        timeout = None,
        size = None,
        target_compatible_with = [],
        **kwargs):
    """
    Defines a test and additional variants using the specified transitions.

    Args:
      test_rule: rule
        Underlying test rule to use.
      name: string
        Name for the underlying test target. Additional test variants use this
        as the base name.
      transitions: list of 'transition_config'
        Configurations for each variant test target.
      tags: string_list
        Tags to apply to all test targets.
      timeout: string
        Applies to all test targets.
      size: string
        Applies to all test targets.
      target_compatible_with: label_list
        Use of this attr is not permitted.
      **kwargs:
        Additional keyword arguments to pass to the test rule.

    Creates a test target along with test target variants, with one variant per
    item in 'transitions'. All variants are aggregated with a 'test_suite'
    target.
    """
    if target_compatible_with:
        fail("'target_compatible_with' is not settable with 'multitransition_test'")
    tags_with_manual = _append_if_missing(tags, "manual")

    test_rule(
        name = name,
        tags = tags,
        timeout = timeout,
        size = size,
        target_compatible_with = select({
            Label("//config:multitransition_test_enabled"): [
                Label("@platforms//:incompatible"),
            ],
            Label("//config:multitransition_test_disabled"): [],
        }),
        **kwargs
    )

    test_rule(
        name = name + ".base",
        tags = tags_with_manual,
        timeout = timeout,
        size = size,
        target_compatible_with = select({
            Label("//config:multitransition_test_enabled"): [],
            Label("//config:multitransition_test_disabled"): [
                Label("@platforms//:incompatible"),
            ],
        }),
        **kwargs
    )

    tests = []
    for i, config in enumerate(transitions):
        if not is_transition_config(config):
            fail("Invalid transition config: '{}'. Use 'transition_config'.".format(config))

        transitioned_test_name = name + "." + (config.name or str(i))
        tests.append(transitioned_test_name)
        transitioned_test(
            name = transitioned_test_name,
            src = name + ".base",
            flags = _flags(config),
            tags = tags,
            timeout = timeout,
            size = size,
            target_compatible_with = select({
                Label("//config:multitransition_test_enabled"): [],
                Label("//config:multitransition_test_disabled"): [
                    Label("@platforms//:incompatible"),
                ],
            }),
        )

    native.test_suite(
        name = name + ".suite",
        tests = tests,
        tags = tags_with_manual,
    )
