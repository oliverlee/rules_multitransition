"""
Shared implementation of 'multitransition.test' and 'multitransition.binary'.
"""

load("//:transition_config.bzl", "is_transition_config")
load("//private:transition_options.bzl", "transition_options")

visibility("private")

def _compatible_when(flag, enabled):
    """
    Returns a 'target_compatible_with' value for when 'flag' is 'enabled'.
    """
    incompatible = [Label("@platforms//:incompatible")]
    return select({
        Label("//config:{}_enabled".format(flag)): [] if enabled else incompatible,
        Label("//config:{}_disabled".format(flag)): incompatible if enabled else [],
    })

def multitransition_executable(
        *,
        rule,
        transitioned_rule,
        flag,
        name,
        transitions,
        tags,
        visibility,
        target_compatible_with,
        attrs,
        **kwargs):
    """
    Defines '<name>', '<name>.base', and a variant per transition.

    With 'flag' enabled, '<name>' is incompatible and each variant transitions
    '<name>.base'. With 'flag' disabled, only '<name>' is compatible.

    Args:
      rule: The rule creating '<name>' and '<name>.base'.
      transitioned_rule: The rule creating each variant.
      flag: The name of the bool flag in '//config'.
      name: The name of the underlying target.
      transitions: A list of 'multitransition.transition'.
      tags: Tags to apply to all targets.
      visibility: Visibility of '<name>' and the variants.
      target_compatible_with: Constraints to apply to all targets.
      attrs: Attributes to apply unchanged to all targets, e.g. 'timeout'.
      **kwargs: Attributes to pass to 'rule'.

    Returns:
      The names of the variants.
    """
    rule(
        name = name,
        tags = tags,
        visibility = visibility,
        target_compatible_with = target_compatible_with + _compatible_when(flag, False),
        **(attrs | kwargs)
    )

    rule(
        name = name + ".base",
        tags = tags if "manual" in tags else tags + ["manual"],
        visibility = ["//visibility:private"],
        target_compatible_with = target_compatible_with + _compatible_when(flag, True),
        **(attrs | kwargs)
    )

    variants = []
    for i, config in enumerate(transitions):
        if not is_transition_config(config):
            fail("Invalid transition config: '{}'. Use 'multitransition.transition'.".format(config))
        if config.aspect:
            fail("'aspect' is only supported by 'multitransition.target'")

        variant = name + "." + (config.name or str(i))
        variants.append(variant)
        transitioned_rule(
            name = variant,
            src = name + ".base",
            options = transition_options(config),
            tags = tags,
            visibility = visibility,
            target_compatible_with = target_compatible_with + _compatible_when(flag, True),
            **attrs
        )

    return variants
