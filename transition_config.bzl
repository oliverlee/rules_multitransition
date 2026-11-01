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

    Values may be a string, bool, int, Label, or a list of these. List
    options are appended to. Every option must be a default option or
    added with `multitransition_config.extend`.

    Args:
      name: **string**
          The name of the configuration, used as the suffix of each variant
          target, `<name>.<config name>`. Defaults to the index.
      flags: **dict**
          Build setting label or `//command_line_option:<name>` to value, e.g.
          `{"@cortex_m//config:semihosting": True}`.
      aspect: **`multitransition.aspect`**
          Only for `multitransition.target`: the aspect to apply, whose output
          group becomes the default output.
      **kwargs: Native option name to value, e.g. `compilation_mode = "dbg"`.
          Set the target platform with `platform = <label>`, a single label.

    Returns:
      A configuration for `multitransition.test` or `multitransition.target`.
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
