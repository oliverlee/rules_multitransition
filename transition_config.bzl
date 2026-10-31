"""
Implementation of 'multitransition.transition'.
"""

load("//:aspect_config.bzl", "is_aspect_config")

visibility("private")

_TYPE = "_RULES_MULTITRANSITION_TRANSITION_CONFIG_"

def is_transition_config(config):
    """
    Check if the object is a transition config.
    """
    return getattr(config, "type", None) == _TYPE

def transition_config(*, name = None, flags = {}, aspect = None, **kwargs):
    """
    Describes a configuration to transition a target to.

    Args:
      name: string
        Name of the configuration. 'multitransition.test' uses it as the
        suffix of the variant target, '<test>.<name>', and defaults to the
        index.
      flags: dict
        Build setting label or option to value. Use this for Starlark build
        settings, e.g. {"@cortex_m//config:semihosting": True}.
      aspect: 'multitransition.aspect'
        Optional, only for 'multitransition.target'. The aspect to apply and
        its output group to use as the default output.
      **kwargs:
        Native option name to value, e.g. compilation_mode = "dbg". The
        target platform is set with platform = <label> (a single label).

    Returns:
      A 'multitransition.transition' struct for 'multitransition.test' or
      'multitransition.target'.

    Values may be a string, bool, int, Label, or a list of these. List
    options are appended to. Every option must be a default option or
    declared with the 'multitransition_config' module extension.
    """
    for key in kwargs:
        if key in flags:
            fail("'{}' is set both as a keyword argument and in 'flags'".format(key))

    if aspect != None and not is_aspect_config(aspect):
        fail("Invalid aspect config: '{}'. Use 'multitransition.aspect'.".format(aspect))

    return struct(
        type = _TYPE,
        name = name,
        flags = flags | kwargs,
        aspect = aspect,
    )
