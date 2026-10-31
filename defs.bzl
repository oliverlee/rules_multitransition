"""
Public bzl file for exporting implementations.
"""

load(
    ":multitransition_test.bzl",
    _multitransition_test = "multitransition_test",
)
load(
    ":transition_config.bzl",
    _transition_config = "transition_config",
)

visibility("public")

multitransition_test = _multitransition_test
transition_config = _transition_config
