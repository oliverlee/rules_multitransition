"""
Implementation of 'multitransition.binary' macro.
"""

load("//:multitransition_executable.bzl", "multitransition_executable")
load("//private:rules.bzl", "transitioned_binary")

visibility("private")

def multitransition_binary(
        binary_rule,
        *,
        name,
        transitions,
        tags = [],
        target_compatible_with = [],
        visibility = None,
        **kwargs):
    """
    Defines a binary and additional variants using the specified transitions.

    Creates a binary target along with binary target variants, with one
    variant per item in `transitions`. Each `<name>.<config name>` variant
    runs the binary built in that transition with `bazel run`. With
    `--@rules_multitransition//config:multitransition_binary=False`, only the
    underlying binary target is compatible, built without a transition.

    Args:
      binary_rule: **rule**
          The binary rule to use, e.g. `cc_binary`.
      name: **string**
          The name of the underlying binary target. Additional binary variants
          use it as the base name.
      transitions: **list of `multitransition.transition`**
          One per variant binary target.
      tags: **list of strings**
          Tags to apply to all binary targets.
      target_compatible_with: **list of labels**
          Applies to all binary targets.
      visibility: **list of labels**
          Visibility of the binary and its variants.
      **kwargs: Additional attributes to pass to the binary rule.
    """
    multitransition_executable(
        rule = binary_rule,
        transitioned_rule = transitioned_binary,
        flag = "multitransition_binary",
        name = name,
        transitions = transitions,
        tags = tags,
        visibility = visibility,
        target_compatible_with = target_compatible_with,
        attrs = {},
        **kwargs
    )
