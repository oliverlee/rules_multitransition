<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public bzl file for exporting implementations.

<a id="multitransition.aspect"></a>

## multitransition.aspect

<pre>
load("@rules_multitransition//:defs.bzl", "multitransition")

multitransition.aspect(*, <a href="#multitransition.aspect-aspect">aspect</a>, <a href="#multitransition.aspect-output_group">output_group</a>)
</pre>

Describes an aspect to apply and the output group to use from it.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="multitransition.aspect-aspect"></a>aspect |  **string** The aspect as `<bzl file>%<name>`, e.g. `@rules_clang_tidy//:aspects.bzl%check`. It must be added in `MODULE.bazel` with `multitransition_config.extend(aspects = [...])`.   |  none |
| <a id="multitransition.aspect-output_group"></a>output_group |  **string** The output group of `aspect` to use as the default output, e.g. `report`.   |  none |

**RETURNS**

An aspect config for `multitransition.transition`.


<a id="multitransition.binary"></a>

## multitransition.binary

<pre>
load("@rules_multitransition//:defs.bzl", "multitransition")

multitransition.binary(<a href="#multitransition.binary-binary_rule">binary_rule</a>, *, <a href="#multitransition.binary-name">name</a>, <a href="#multitransition.binary-transitions">transitions</a>, <a href="#multitransition.binary-tags">tags</a>, <a href="#multitransition.binary-visibility">visibility</a>, <a href="#multitransition.binary-kwargs">**kwargs</a>)
</pre>

Defines a binary and additional variants using the specified transitions.

Creates a binary target along with binary target variants, with one
variant per item in `transitions`. Each `<name>.<config name>` variant
runs the binary built in that transition with `bazel run`. With
`--@rules_multitransition//config:multitransition_binary=False`, only the
underlying binary target is compatible, built without a transition.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="multitransition.binary-binary_rule"></a>binary_rule |  **rule** The binary rule to use, e.g. `cc_binary`.   |  none |
| <a id="multitransition.binary-name"></a>name |  **string** The name of the underlying binary target. Additional binary variants use it as the base name.   |  none |
| <a id="multitransition.binary-transitions"></a>transitions |  **list of `multitransition.transition`** One per variant binary target.   |  none |
| <a id="multitransition.binary-tags"></a>tags |  **list of strings** Tags to apply to all binary targets.   |  `[]` |
| <a id="multitransition.binary-visibility"></a>visibility |  **list of labels** Visibility of the binary and its variants.   |  `None` |
| <a id="multitransition.binary-kwargs"></a>kwargs |  Additional attributes to pass to the binary rule.   |  none |


<a id="multitransition.target"></a>

## multitransition.target

<pre>
load("@rules_multitransition//:defs.bzl", "multitransition")

multitransition.target(*, <a href="#multitransition.target-name">name</a>, <a href="#multitransition.target-src">src</a>, <a href="#multitransition.target-transitions">transitions</a>, <a href="#multitransition.target-kwargs">**kwargs</a>)
</pre>

Builds a target in each of the specified transitions.

Each `<name>.<config name>` target forwards the providers of `src`. If the
transition sets `aspect`, the aspect is applied to `src` instead and its
`output_group` is the default output.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="multitransition.target-name"></a>name |  **string** The base name of the targets. Each transition creates `<name>.<config name>`.   |  none |
| <a id="multitransition.target-src"></a>src |  **label** The target to transition.   |  none |
| <a id="multitransition.target-transitions"></a>transitions |  **list of `multitransition.transition`** The configurations to build `src` in.   |  none |
| <a id="multitransition.target-kwargs"></a>kwargs |  Common attributes to apply to all targets, e.g. `tags`.   |  none |


<a id="multitransition.test"></a>

## multitransition.test

<pre>
load("@rules_multitransition//:defs.bzl", "multitransition")

multitransition.test(<a href="#multitransition.test-test_rule">test_rule</a>, *, <a href="#multitransition.test-name">name</a>, <a href="#multitransition.test-transitions">transitions</a>, <a href="#multitransition.test-tags">tags</a>, <a href="#multitransition.test-timeout">timeout</a>, <a href="#multitransition.test-size">size</a>, <a href="#multitransition.test-target_compatible_with">target_compatible_with</a>,
                     <a href="#multitransition.test-visibility">visibility</a>, <a href="#multitransition.test-kwargs">**kwargs</a>)
</pre>

Defines a test and additional variants using the specified transitions.

Creates a test target along with test target variants, with one variant per
item in `transitions`. All variants are aggregated with a `test_suite`
target. With `--@rules_multitransition//config:multitransition_test=False`,
only the underlying test target is compatible, built without a transition.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="multitransition.test-test_rule"></a>test_rule |  **rule** The test rule to use, e.g. `cc_test`.   |  none |
| <a id="multitransition.test-name"></a>name |  **string** The name of the underlying test target. Additional test variants use it as the base name.   |  none |
| <a id="multitransition.test-transitions"></a>transitions |  **list of `multitransition.transition`** One per variant test target.   |  none |
| <a id="multitransition.test-tags"></a>tags |  **list of strings** Tags to apply to all test targets.   |  `[]` |
| <a id="multitransition.test-timeout"></a>timeout |  **string** Applies to all test targets.   |  `None` |
| <a id="multitransition.test-size"></a>size |  **string** Applies to all test targets.   |  `None` |
| <a id="multitransition.test-target_compatible_with"></a>target_compatible_with |  **list of labels** Applies to all test targets.   |  `[]` |
| <a id="multitransition.test-visibility"></a>visibility |  **list of labels** Visibility of the test, its variants, and the `test_suite`.   |  `None` |
| <a id="multitransition.test-kwargs"></a>kwargs |  Additional attributes to pass to the test rule.   |  none |


<a id="multitransition.transition"></a>

## multitransition.transition

<pre>
load("@rules_multitransition//:defs.bzl", "multitransition")

multitransition.transition(*, <a href="#multitransition.transition-name">name</a>, <a href="#multitransition.transition-flags">flags</a>, <a href="#multitransition.transition-aspect">aspect</a>, <a href="#multitransition.transition-kwargs">**kwargs</a>)
</pre>

Describes a configuration to transition a target to.

Values may be a string, bool, int, Label, or a list of these. List
options are appended to. Every option must be a default option or
added with `multitransition_config.extend`.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="multitransition.transition-name"></a>name |  **string** The name of the configuration, used as the suffix of each variant target, `<name>.<config name>`. Defaults to the index.   |  `None` |
| <a id="multitransition.transition-flags"></a>flags |  **dict** Build setting label or `//command_line_option:<name>` to value, e.g. `{"@cortex_m//config:semihosting": True}`.   |  `{}` |
| <a id="multitransition.transition-aspect"></a>aspect |  **`multitransition.aspect`** Only for `multitransition.target`: the aspect to apply, whose output group becomes the default output.   |  `None` |
| <a id="multitransition.transition-kwargs"></a>kwargs |  Native option name to value, e.g. `compilation_mode = "dbg"`. Set the target platform with `platform = <label>`, a single label.   |  none |

**RETURNS**

A configuration for `multitransition.test`, `multitransition.binary`, or
`multitransition.target`.


