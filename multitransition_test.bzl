"""
Implementation of 'multitransition.test' macro.
"""

load("//:multitransition_executable.bzl", "multitransition_executable")
load("//private:rules.bzl", "transitioned_test")

visibility("private")

def multitransition_test(
        test_rule,
        *,
        name,
        transitions,
        tags = [],
        timeout = None,
        size = None,
        target_compatible_with = [],
        visibility = None,
        **kwargs):
    """
    Defines a test and additional variants using the specified transitions.

    Creates a test target along with test target variants, with one variant per
    item in `transitions`. All variants are aggregated with a `test_suite`
    target. With `--@rules_multitransition//config:multitransition_test=False`,
    only the underlying test target is compatible, built without a transition.
    To transition an existing test, use `alias` as `test_rule` with `actual`.

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
      visibility: **list of labels**
          Visibility of the test, its variants, and the `test_suite`.
      **kwargs: Additional attributes to pass to the test rule.
    """
    tests = multitransition_executable(
        rule = test_rule,
        transitioned_rule = transitioned_test,
        flag = "multitransition_test",
        exclusive = True,
        name = name,
        transitions = transitions,
        tags = tags,
        visibility = visibility,
        target_compatible_with = target_compatible_with,
        # only when set, as some rules, e.g. 'alias', don't have them
        attrs = {
            attr: value
            for attr, value in {
                "size": size,
                "timeout": timeout,
            }.items()
            if value != None
        },
        **kwargs
    )

    native.test_suite(
        name = name + ".suite",
        tests = tests,
        tags = tags if "manual" in tags else tags + ["manual"],
        visibility = visibility,
    )
