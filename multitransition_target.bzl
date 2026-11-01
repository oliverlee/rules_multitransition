"""
Implementation of 'multitransition.target' macro.
"""

load("@multitransition_config//:aspects.bzl", "RULES")
load("//:transition_config.bzl", "is_transition_config")
load("//private:rules.bzl", "transitioned_target")
load("//private:transition_options.bzl", "transition_options")

visibility("private")

def _canonical_aspect(aspect):
    """
    Converts '<bzl file>%<name>' to its canonical form.
    """
    return str(native.package_relative_label(aspect))

def _rule_and_attrs(config):
    """
    Returns the rule to create for a transition and its rule-specific attrs.

    A transition without an aspect forwards the providers of 'src'. With an
    aspect, the rule generated for it provides its 'output_group'.
    """
    if not config.aspect:
        return transitioned_target, {}

    aspect = _canonical_aspect(config.aspect.aspect)
    if aspect not in RULES:
        fail(
            ("'{}' ({}) can't be applied by 'multitransition.target'. Add it " +
             "in MODULE.bazel with 'multitransition_config.extend(aspects = [\"{}\"])'.").format(
                config.aspect.aspect,
                aspect,
                config.aspect.aspect,
            ),
        )

    return RULES[aspect], {"output_group": config.aspect.output_group}

def multitransition_target(
        rule,
        *,
        name,
        transitions,
        tags = [],
        testonly = False,
        visibility = None,
        **kwargs):
    """
    Defines a target and additional variants using the specified transitions.

    Creates a target along with target variants, with one variant per item in
    `transitions`. Each `<name>.<config name>` variant forwards the providers of
    the target built in that transition. If the transition sets `aspect`, the
    aspect is applied to the target instead and its `output_group` is the
    default output. To transition an existing target, use `alias` as `rule`
    with `actual`.

    Args:
      rule: **rule**
          The rule to use, e.g. `cc_library`.
      name: **string**
          The name of the underlying target. Additional target variants use it
          as the base name.
      transitions: **list of `multitransition.transition`**
          One per variant target.
      tags: **list of strings**
          Tags to apply to all targets.
      testonly: **bool**
          Applies to all targets. Required if `rule` creates a test, e.g.
          `cc_test`.
      visibility: **list of labels**
          Visibility of the target and its variants.
      **kwargs: Additional attributes to pass to the rule.
    """
    rule(
        name = name,
        tags = tags,
        testonly = testonly,
        visibility = visibility,
        **kwargs
    )

    for i, config in enumerate(transitions):
        if not is_transition_config(config):
            fail("Invalid transition config: '{}'. Use 'multitransition.transition'.".format(config))
        variant_rule, attrs = _rule_and_attrs(config)
        variant_rule(
            name = name + "." + (config.name or str(i)),
            src = name,
            options = transition_options(config),
            tags = tags,
            testonly = testonly,
            visibility = visibility,
            **attrs
        )
