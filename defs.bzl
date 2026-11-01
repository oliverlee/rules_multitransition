"""
Public bzl file for exporting implementations.
"""

load(":aspect_config.bzl", "aspect_config")
load(":multitransition_binary.bzl", "multitransition_binary")
load(":multitransition_target.bzl", "multitransition_target")
load(":multitransition_test.bzl", "multitransition_test")
load(":transition_config.bzl", "transition_config")

visibility("public")

multitransition = struct(
    aspect = aspect_config,
    binary = multitransition_binary,
    target = multitransition_target,
    test = multitransition_test,
    transition = transition_config,
)
