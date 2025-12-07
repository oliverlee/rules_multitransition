"""
Implementation of 'transition_config_flag' utility.
"""

visibility("private")

transition_config_flag = struct(
    bool = lambda name, option = None: struct(
        name = name,
        kind = "bool",
        option = option or name,
    ),
    string = lambda name, option = None: struct(
        name = name,
        kind = "string",
        option = option or name,
    ),
    string_list = lambda name, option = None: struct(
        name = name,
        kind = "string_list",
        option = option or name,
    ),
    label = lambda name, option = None: struct(
        name = name,
        kind = "label",
        option = option or name,
    ),
    label_list = lambda name, option = None: struct(
        name = name,
        kind = "label_list",
        option = option or name,
    ),
)
