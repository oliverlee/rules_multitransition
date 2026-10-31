# rules_multitransition

These rules provide an interface for running tests with multiple configurations.
This is especially useful when testing a project with multiple toolchains.

## Usage

Setup the test with the desired configuration by using `multitransition_test`

```bzl
# //:BUILD.bazel
load("@rules_cc//cc:cc_test.bzl", "cc_test")
load(
    "@rules_multitransition//:defs.bzl",
    "multitransition_test",
    "transition_config",
)

multitransition_test(
    cc_test,
    name = "my_test",
    transitions = [
        transition_config(
            name = "gcc-dbg",
            compilation_mode = "dbg",
            extra_toolchains = ["@gcc_toolchain//:..."],
        ),
        transition_config(
            name = "llvm-dbg",
            compilation_mode = "dbg",
            extra_toolchains = ["@llvm_toolchain//:..."],
        ),
        transition_config(
            name = "gcc-opt",
            compilation_mode = "opt",
            extra_toolchains = ["@gcc_toolchain//:..."],
        ),
        ...
    ],
    # other 'cc_test' args
    srcs = [...],
    deps = [...],
)
```

or wrapping it with a macro

```bzl
# //:cc_multi_test.bzl
load("@rules_cc//cc:cc_test.bzl", "cc_test")
load(
    "@rules_multitransition//:defs.bzl",
    "multitransition_test",
    "transition_config",
)

default_transitions = [
    transition_config(...),
    ...
]

def cc_multi_test(
    *,
    transitions = default_transitions,
    **kwargs):
    multitransition_test(
        cc_test,
        transitions = transitions,
        **kwargs
    )
)
```

### Options

`transition_config` can set these native options as keyword arguments
without any setup: `compilation_mode`, `copt`, `cxxopt`, `extra_toolchains`,
`features`, `linkopt`, `platform` (a single label, sets `--platforms`).

Other native options and Starlark build settings must be declared in
`MODULE.bazel`. Declarations from all modules in the dependency graph are
combined:

```bzl
# MODULE.bazel
multitransition = use_extension(
    "@rules_multitransition//:extensions.bzl",
    "multitransition",
    dev_dependency = True,
)
multitransition.flag(setting = "@cortex_m//config:semihosting")
multitransition.command_line_option(name = "conlyopt")
```

Use `dev_dependency = True` when the declarations are only needed for your
own tests. Omit it if your module provides a macro around
`multitransition_test` that other modules call with these options, so the
declarations apply when your module is a dependency.

Native options are passed as keyword arguments and build settings in
`flags`:

```bzl
transition_config(
    name = "cortex-m3",
    platform = "@cortex_m//platform:lm3s6965evb",
    flags = {
        "@cortex_m//config:semihosting": True,
    },
)
```

Values are converted to the type of the option. List options are appended
to.

For `features`, prefix a feature with `-` to disable it. A negative feature
overrides a positive one, so a variant can disable a feature enabled on the
command line, but can't enable a feature disabled on the command line. See
`//examples/features`.

### Running

Run all the `multitransition_test` targets with Bazel:

```sh
$ bazel test //...
```

Run the associated `test_suite`

```sh
$ bazel test //:my_test.suite
```

Run the base test target

```sh
$ bazel test \
  --@rules_multitransition//config:multitransition_test=False \
  //:my_test
```
