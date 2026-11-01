"""
Implementation of 'multitransition.binary' macro.
"""

load("//:transition_config.bzl", "is_transition_config")
load("//private:rules.bzl", "transitioned_binary")
load("//private:transition_options.bzl", "transition_options")

visibility("private")

def multitransition_binary(
        binary_rule,
        *,
        name,
        transitions,
        tags = [],
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
      visibility: **list of labels**
          Visibility of the binary and its variants.
      **kwargs: Additional attributes to pass to the binary rule.
    """
    binary_rule(
        name = name,
        tags = tags,
        visibility = visibility,
        target_compatible_with = select({
            Label("//config:multitransition_binary_enabled"): [
                Label("@platforms//:incompatible"),
            ],
            Label("//config:multitransition_binary_disabled"): [],
        }),
        **kwargs
    )

    binary_rule(
        name = name + ".base",
        tags = tags if "manual" in tags else tags + ["manual"],
        visibility = ["//visibility:private"],
        target_compatible_with = select({
            Label("//config:multitransition_binary_enabled"): [],
            Label("//config:multitransition_binary_disabled"): [
                Label("@platforms//:incompatible"),
            ],
        }),
        **kwargs
    )

    for i, config in enumerate(transitions):
        if not is_transition_config(config):
            fail("Invalid transition config: '{}'. Use 'multitransition.transition'.".format(config))
        if config.aspect:
            fail("'aspect' is only supported by 'multitransition.target'")
        transitioned_binary(
            name = name + "." + (config.name or str(i)),
            src = name + ".base",
            options = transition_options(config),
            tags = tags,
            visibility = visibility,
            target_compatible_with = select({
                Label("//config:multitransition_binary_enabled"): [],
                Label("//config:multitransition_binary_disabled"): [
                    Label("@platforms//:incompatible"),
                ],
            }),
        )
