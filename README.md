# rules_multitransition

Build and run a target under several configurations in a single Bazel
invocation, e.g. with multiple toolchains, compilation modes, or target
platforms. Each configuration defines a `<name>.<config>` target:
`bazel test //...` runs a test in all configurations, and
`bazel run //:app.opt` runs a binary in one configuration.

```bzl
load("@rules_cc//cc:cc_test.bzl", "cc_test")
load("@rules_multitransition//:multitransition.bzl", "multitransition")

multitransition.test(
    cc_test,
    name = "my_test",
    srcs = ["my_test.cpp"],
    transitions = [
        multitransition.transition(
            name = "gcc",
            extra_toolchains = ["@gcc_toolchain//:..."],
        ),
        multitransition.transition(
            name = "llvm-opt",
            compilation_mode = "opt",
            extra_toolchains = ["@llvm_toolchain//:..."],
        ),
    ],
)
```

```sh
$ bazel test //...  # runs //:my_test.gcc and //:my_test.llvm-opt
```

## Installation

Add the module to `MODULE.bazel`. Requires Bazel 7.1.0 or later.

```bzl
bazel_dep(name = "rules_multitransition", version = "0.1.0")
```

## Usage

Each macro takes the rule to instantiate, its `name`, and a list of
configurations. The remaining arguments are passed to the rule. Every macro
creates `<name>` and one `<name>.<config>` target per configuration:

| Macro                    | `<name>.<config>`                     | Also creates   |
| ------------------------ | ------------------------------------- | -------------- |
| `multitransition.test`   | a test, run by `bazel test`           | `<name>.suite` |
| `multitransition.binary` | an executable, run by `bazel run`     |                |
| `multitransition.target` | any target, optionally with an aspect |                |

See [`examples`](examples) for each macro in use.

### Configurations

`multitransition.transition` describes one configuration. These native
options can be set as keyword arguments without any setup:

- `compilation_mode`
- `copt`
- `cxxopt`
- `extra_toolchains`
- `features`
- `linkopt`
- `platform` (a single label, sets `--platforms`)

Values are converted to the type of the option. Values of list options are
appended to the current value.

The target platform is the exception: set it with `platform` and a single
label, which replaces `--platforms`. Setting `platforms` directly fails: a
transition supports only one target platform
([bazelbuild/bazel#10154](https://github.com/bazelbuild/bazel/issues/10154)).

For `features`, prefix a feature with `-` to disable it. A negative feature
overrides a positive one: a configuration can disable a feature enabled on the
command line, but can't enable one disabled there.

Other native options and Starlark build settings must be declared first (see
[Declaring options and aspects](#declaring-options-and-aspects)). Set them in
`flags`, with `//command_line_option:<name>` or the build setting's label as
the key:

```bzl
multitransition.transition(
    name = "cortex-m3",
    platform = "@cortex_m//platform:lm3s6965evb",
    flags = {
        "//command_line_option:conlyopt": ["-std=c11"],
        "@cortex_m//config:semihosting": True,
    },
)
```

### Tests

`multitransition.test` creates a test variant per configuration, and a
[`test_suite`](https://bazel.build/reference/be/general#test_suite) named
`<name>.suite` of the variants. By default the untransitioned `<name>` is
skipped and `bazel test //...` runs only the variants:

```sh
$ bazel test //...                # every variant
$ bazel test //:my_test.suite     # every variant of 'my_test'
$ bazel test //:my_test.gcc       # one variant
```

`tags`, `size`, `timeout`, `target_compatible_with`, and `visibility` apply to
every target the macro creates.

### Binaries

`multitransition.binary` creates an executable variant per configuration:

```bzl
multitransition.binary(
    cc_binary,
    name = "app",
    srcs = ["app.cpp"],
    transitions = [
        multitransition.transition(
            name = "opt",
            compilation_mode = "opt",
        ),
    ],
)
```

```sh
$ bazel run //:app.opt
```

Unlike with `multitransition.test`, the untransitioned `<name>` is an ordinary
binary: `bazel run //:app` runs it without any transition.

### Other targets and aspects

`multitransition.target` creates a variant per configuration that forwards
the providers of the target built in that configuration. `<name>` is an
ordinary target that others can depend on.

A configuration may also apply an aspect with `multitransition.aspect`. The
default output of that variant is then the aspect's `output_group`:

```bzl
CLANG_TIDY = multitransition.transition(
    name = "clang-tidy-report",
    aspect = multitransition.aspect(
        aspect = "@rules_clang_tidy//:aspects.bzl%check",
        output_group = "report",
    ),
)

multitransition.target(
    cc_library,
    name = "lib",
    srcs = ["lib.cpp"],
    transitions = [CLANG_TIDY],
)

multitransition.target(
    cc_test,
    name = "lib_test",
    testonly = True,
    srcs = ["lib_test.cpp"],
    transitions = [CLANG_TIDY],
    deps = [":lib"],
)
```

```sh
$ bazel build //:lib.clang-tidy-report //:lib_test.clang-tidy-report
```

The rule may be a test or a binary. A test needs `testonly = True`: its
variants depend on it. `lib_test` is then an ordinary test, and
`lib_test.clang-tidy-report` is the aspect's output. `multitransition.test`
and `multitransition.binary` don't accept an aspect: their variants must be
runnable.

With Bazel 7, a `multitransition.target` of a test fails with conflicting
actions when the test and a variant are built together, e.g. with
`bazel test //...`, and the variant's configuration only applies an aspect.
Bazel 7 trims the test options from the variant, which builds the test in a
second configuration with the same output directory. Pass
`--experimental_retain_test_configuration_across_testonly` to keep the test
options for `testonly` targets.

The aspect must be declared (see
[Declaring options and aspects](#declaring-options-and-aspects)).

### Existing targets

To transition a target defined elsewhere, e.g. in another package or
repository, pass [`alias`](https://bazel.build/reference/be/general#alias) as
the rule with `actual`:

```bzl
multitransition.test(
    alias,
    name = "dep_test",
    actual = "@some_repo//:test",
    transitions = [...],
)

multitransition.binary(
    alias,
    name = "dep_tool",
    actual = "@some_repo//:tool",
    transitions = [...],
)

multitransition.target(
    alias,
    name = "dep",
    actual = "@some_repo//:lib",
    transitions = [...],
)
```

The variants are `dep_test.<config>`, `dep_tool.<config>`, and
`dep.<config>`. Note that `alias` has no `size` or `timeout` attributes; test
variants use the defaults.

### Wrapping in a macro

To reuse a set of configurations, wrap `multitransition.test` in your own
macro:

```bzl
# //:cc_multi_test.bzl
load("@rules_cc//cc:cc_test.bzl", "cc_test")
load("@rules_multitransition//:multitransition.bzl", "multitransition")

TRANSITIONS = [
    multitransition.transition(...),
    ...
]

def cc_multi_test(*, transitions = TRANSITIONS, **kwargs):
    multitransition.test(cc_test, transitions = transitions, **kwargs)
```

## Declaring options and aspects

Native options other than those listed above, Starlark build settings, and
aspects must be declared in `MODULE.bazel`. Declarations from all modules in
the dependency graph are combined:

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

Use `dev_dependency = True` when only your own module uses the declarations.
Omit it if your module provides a macro that other modules call with these
options; the declarations then apply when your module is a dependency.

## Flags

Two flags in `@rules_multitransition//config` disable the variants, e.g. to
build and run without any transition:

- `multitransition_test`: When `False`, only the underlying `<name>` test of
  each `multitransition.test` is compatible, built and run without a
  transition. Defaults to `True`, which skips `<name>` and runs the variants.
- `multitransition_binary`: When `False`, the variants of each
  `multitransition.binary` are incompatible, leaving only `<name>`, which is
  always compatible. Defaults to `True`, which builds the variants too.

```sh
$ bazel test --@rules_multitransition//config:multitransition_test=False //:my_test
$ bazel build --@rules_multitransition//config:multitransition_binary=False //...
```

## Reference

- [`multitransition.bzl`](docs/multitransition.md)
  - `multitransition.test`
  - `multitransition.binary`
  - `multitransition.target`
  - `multitransition.transition`
  - `multitransition.aspect`
- [`extensions.bzl`](docs/extensions.md)
  - `multitransition_config`
