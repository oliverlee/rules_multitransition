"""
Public bzl file for exporting implementations.
"""

load(
    ":multitransition_test.bzl",
    _multitransition_test = "multitransition_test",
)
load(
    ":transition_config.bzl",
    _default_transition_config_flags = "default_transition_config_flags",
    _make_transition_config_rules = "make_transition_config_rules",
    _transition_config = "transition_config",
)
load(
    ":transition_config_flag.bzl",
    _transition_config_flag = "transition_config_flag",
)

visibility("public")

multitransition_test = _multitransition_test
make_transition_config_rules = _make_transition_config_rules
transition_config = _transition_config
transition_config_flag = _transition_config_flag
DEFAULT_TRANSITION_CONFIG_FLAGS = _default_transition_config_flags
