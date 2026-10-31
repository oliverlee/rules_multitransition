"""
Converts 'multitransition.transition' keys and values to transition options.
"""

load("//private:rules.bzl", "OPTIONS")

visibility("//...")

_NATIVE_PREFIX = "//command_line_option:"

# `--platforms` is list-typed but only one target platform is supported.
# https://github.com/bazelbuild/bazel/issues/10154
_PLATFORM_KEY = "platform"
_PLATFORMS_OPTION = _NATIVE_PREFIX + "platforms"

def _canonical_label(value):
    return str(native.package_relative_label(value))

def _option_key(key):
    """
    Converts a 'multitransition.transition' key to a transition option.

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

def _check_platform(key, value):
    """
    Checks that the target platform is set with a single 'platform' label.
    """
    if key != _PLATFORM_KEY:
        fail("Use 'platform' to set the target platform, not '{}'.".format(key))
    if type(value) in ("list", "tuple"):
        fail("'platform' takes a single label, got {}".format(value))

# Not a macro: it only calls 'native.package_relative_label' to resolve labels.
# buildifier: disable=unnamed-macro
def transition_options(config):
    """
    Converts a 'multitransition.transition' to a transitioned rule's 'options'.

    Args:
      config: 'multitransition.transition'
        The configuration to convert.

    Returns:
      A dict of transition option to a list of string values.
    """
    options = {}
    for key, value in config.flags.items():
        option = _option_key(key)
        if option == _PLATFORMS_OPTION:
            _check_platform(key, value)
        if option not in OPTIONS:
            fail(
                ("'{}' ({}) can't be set by 'multitransition.transition'. Declare it in " +
                 "MODULE.bazel with 'multitransition_config.flag(setting = ...)' or " +
                 "'multitransition_config.command_line_option(name = ...)'.").format(key, option),
            )
        options[option] = _option_values(value)
    return options
