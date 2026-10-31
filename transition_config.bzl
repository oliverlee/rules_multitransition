"""
Implementation of 'transition_config'.
"""

visibility("private")

def is_transition_config(config):
    """
    Check if the object is a transition config.
    """
    return getattr(config, "type", None) == "transition_config"

def transition_config(*, name = None, flags = {}, **kwargs):
    """
    Describes a configuration to transition a target to.

    Args:
      name: string
        Name of the configuration. 'multitransition_test' uses it as the
        suffix of the variant target, '<test>.<name>', and defaults to the
        index.
      flags: dict
        Build setting label or option to value. Use this for Starlark build
        settings, e.g. {"@cortex_m//config:semihosting": True}.
      **kwargs:
        Native option name to value, e.g. compilation_mode = "dbg". The
        target platform is set with platform = <label> (a single label).

    Returns:
      A 'transition_config' struct for 'multitransition_test'.

    Values may be a string, bool, int, Label, or a list of these. List
    options are appended to. Every option must be a default option or
    declared with the 'multitransition' module extension.
    """
    for key in kwargs:
        if key in flags:
            fail("'{}' is set both as a keyword argument and in 'flags'".format(key))

    return struct(
        type = "transition_config",
        name = name,
        flags = flags | kwargs,
    )
