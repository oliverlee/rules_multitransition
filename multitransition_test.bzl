"""
Implementation of 'multitransition.test' macro.
"""

load("//:transition_config.bzl", "is_transition_config")
load("//private:rules.bzl", "transitioned_test")
load("//private:transition_options.bzl", "transition_options")

visibility("private")

def _append_if_missing(values, item):
    """
    Appends an element to a list if not already present.
    """
    if item in values:
        return values
    return values + [item]

def multitransition_test(
        test_rule,
        *,
        name,
        transitions,
        tags = [],
        timeout = None,
        size = None,
        target_compatible_with = [],
        **kwargs):
    """
    Defines a test and additional variants using the specified transitions.

    Creates a test target along with test target variants, with one variant per
    item in `transitions`. All variants are aggregated with a `test_suite`
    target.

    Args:
      test_rule: **rule**
          The test rule to use, e.g. `cc_test`.
      name: **string**
          The name of the underlying test target. Additional test variants use
          it as the base name.
      transitions: **list of `multitransition.transition`**
          One per variant test target.
      tags: **list of strings**
          Tags to apply to all test targets.
      timeout: **string**
          Applies to all test targets.
      size: **string**
          Applies to all test targets.
      target_compatible_with: **list of labels**
          Applies to all test targets.
      **kwargs: Additional attributes to pass to the test rule.
    """
    tags_with_manual = _append_if_missing(tags, "manual")

    test_rule(
        name = name,
        tags = tags,
        timeout = timeout,
        size = size,
        target_compatible_with = target_compatible_with + select({
            Label("//config:multitransition_test_enabled"): [
                Label("@platforms//:incompatible"),
            ],
            Label("//config:multitransition_test_disabled"): [],
        }),
        **kwargs
    )

    test_rule(
        name = name + ".base",
        tags = tags_with_manual,
        timeout = timeout,
        size = size,
        target_compatible_with = target_compatible_with + select({
            Label("//config:multitransition_test_enabled"): [],
            Label("//config:multitransition_test_disabled"): [
                Label("@platforms//:incompatible"),
            ],
        }),
        **kwargs
    )

    tests = []
    for i, config in enumerate(transitions):
        if not is_transition_config(config):
            fail("Invalid transition config: '{}'. Use 'multitransition.transition'.".format(config))
        if config.aspect:
            fail("'aspect' is only supported by 'multitransition.target'")

        transitioned_test_name = name + "." + (config.name or str(i))
        tests.append(transitioned_test_name)
        transitioned_test(
            name = transitioned_test_name,
            src = name + ".base",
            options = transition_options(config),
            tags = tags,
            timeout = timeout,
            size = size,
            target_compatible_with = target_compatible_with + select({
                Label("//config:multitransition_test_enabled"): [],
                Label("//config:multitransition_test_disabled"): [
                    Label("@platforms//:incompatible"),
                ],
            }),
        )

    native.test_suite(
        name = name + ".suite",
        tests = tests,
        tags = tags_with_manual,
    )
