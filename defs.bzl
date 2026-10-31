"""
Public bzl file for exporting implementations.
"""

load(":multitransition_test.bzl", "multitransition_test")
load(":transition_config.bzl", "transition_config")

visibility("public")

multitransition = struct(
    test = multitransition_test,
    transition = transition_config,
)
