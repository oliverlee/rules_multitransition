"""
Implementation of 'transition_config_flag' utility.
"""

visibility("private")

def _stringify(label):
    """
    Converts a label to a string.

    Args:
      label: None|string|Label
        The option to transition on.

    If 'label' is 'None', returns 'None'.
    If 'label' is a string (e.g. '//command_line_option:extra_toolchains'),
    returns the string unchanged.
    If 'label' is a Label (e.g. '@cortex_m//config:semihosting'), returns the
    string representation of the label.
    """
    if label == None:
        return None
    return str(label)

transition_config_flag = struct(
    bool = lambda name, option = None: struct(
        name = name,
        kind = "bool",
        option = _stringify(option) or name,
    ),
    string = lambda name, option = None: struct(
        name = name,
        kind = "string",
        option = _stringify(option) or name,
    ),
    string_list = lambda name, option = None: struct(
        name = name,
        kind = "string_list",
        option = _stringify(option) or name,
    ),
    label = lambda name, option = None: struct(
        name = name,
        kind = "label",
        option = _stringify(option) or name,
    ),
    label_list = lambda name, option = None: struct(
        name = name,
        kind = "label_list",
        option = _stringify(option) or name,
    ),
)
