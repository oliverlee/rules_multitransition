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
            ("'{}' ({}) can't be applied by 'multitransition.target'. Declare it " +
             "in MODULE.bazel with 'multitransition_config.aspect(aspect = \"{}\")'.").format(
                config.aspect.aspect,
                aspect,
                config.aspect.aspect,
            ),
        )

    return RULES[aspect], {"output_group": config.aspect.output_group}

def multitransition_target(*, name, src, transitions, **kwargs):
    """
    Builds a target in each of the specified transitions.

    Args:
      name: string
        Base name of the targets. Each transition creates '<name>.<config>'.
      src: label
        The target to transition.
      transitions: list of 'multitransition.transition'
        Configurations to build 'src' in.
      **kwargs:
        Common attributes to apply to all targets, e.g. 'tags'.

    Each '<name>.<config>' target forwards the providers of 'src'. If the
    transition sets 'aspect', the aspect is applied to 'src' instead and its
    'output_group' is the default output.
    """
    for i, config in enumerate(transitions):
        if not is_transition_config(config):
            fail("Invalid transition config: '{}'. Use 'multitransition.transition'.".format(config))
        rule, attrs = _rule_and_attrs(config)
        rule(
            name = name + "." + (config.name or str(i)),
            src = src,
            options = transition_options(config),
            **(attrs | kwargs)
        )
