<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Module extension that declares which options transitions may set and which
aspects `multitransition.target` may apply.

```bzl
# MODULE.bazel
multitransition_config = use_extension(
    "@rules_multitransition//:extensions.bzl",
    "multitransition_config",
    dev_dependency = True,
)
multitransition_config.extend(
    aspects = [
        "@rules_clang_tidy//:aspects.bzl%check",
    ],
    command_line_options = [
        "conlyopt",
    ],
    flags = [
        "@cortex_m//config:semihosting",
    ],
)
```

Tags from every module in the dependency graph are combined into a single
transition. Use `dev_dependency = True` unless other modules rely on the
declarations, e.g. through a macro wrapping `multitransition.test`; dev
tags are ignored when the module is not the root.

rules_multitransition's own usage is not a dev dependency: it provides the
`@multitransition_config` repo that `defs.bzl` loads for every user.

<a id="multitransition_config"></a>

## multitransition_config

<pre>
multitransition_config = use_extension("@rules_multitransition//:extensions.bzl", "multitransition_config")
multitransition_config.extend(<a href="#multitransition_config.extend-aspects">aspects</a>, <a href="#multitransition_config.extend-command_line_options">command_line_options</a>, <a href="#multitransition_config.extend-flags">flags</a>)
</pre>


**TAG CLASSES**

<a id="multitransition_config.extend"></a>

### extend

Extends the options transitions may set and the aspects `multitransition.target` may apply.

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="multitransition_config.extend-aspects"></a>aspects |  Aspects `multitransition.target` may apply, as `<bzl file>%<name>`, e.g. `@rules_clang_tidy//:aspects.bzl%check`.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="multitransition_config.extend-command_line_options"></a>command_line_options |  Native options `multitransition.transition` may set, without leading dashes, e.g. `conlyopt`.   | List of strings | optional |  `[]`  |
| <a id="multitransition_config.extend-flags"></a>flags |  Starlark build settings `multitransition.transition` may set, e.g. a `bool_flag`.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |


