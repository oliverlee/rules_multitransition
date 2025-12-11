"""
provides a 'transition_config' with a custom flag
"""

load(
    "@rules_multitransition//:defs.bzl",
    "DEFAULT_TRANSITION_CONFIG_FLAGS",
    "make_transition_config_rules",
    flag = "transition_config_flag",
)

# the binary and test rules need to be given names, even if not used directly
(
    transition_config_binary,
    transition_config_test,
    transition_config,
) = make_transition_config_rules(
    DEFAULT_TRANSITION_CONFIG_FLAGS + [
        flag.bool(
            name = "semihosting",
            option = Label("@cortex_m//config:semihosting"),
        ),
    ],
)
