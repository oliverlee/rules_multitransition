# rules_multitransition

These rules provide an interface for running tests with multiple configurations.
This is especially useful when testing a project with multiple toolchains.

## Usage

Setup the test with the desired configuration by using `multitransition.test`

```bzl
# //:BUILD.bazel
load("@rules_cc//cc:cc_test.bzl", "cc_test")
load("@rules_multitransition//:defs.bzl", "multitransition")

multitransition.test(
    cc_test,
    name = "my_test",
    transitions = [
        multitransition.transition(
            name = "gcc-dbg",
            compilation_mode = "dbg",
            extra_toolchains = ["@gcc_toolchain//:..."],
        ),
        multitransition.transition(
            name = "llvm-dbg",
            compilation_mode = "dbg",
            extra_toolchains = ["@llvm_toolchain//:..."],
        ),
        multitransition.transition(
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
load("@rules_multitransition//:defs.bzl", "multitransition")

default_transitions = [
    multitransition.transition(...),
    ...
]

def cc_multi_test(
    *,
    transitions = default_transitions,
    **kwargs):
    multitransition.test(
        cc_test,
        transitions = transitions,
        **kwargs
    )
)
```

### Options

`multitransition.transition` can set these native options as keyword arguments
without any setup: `compilation_mode`, `copt`, `cxxopt`, `extra_toolchains`,
`features`, `linkopt`, `platform` (a single label, sets `--platforms`).

Other native options and Starlark build settings must be declared in
`MODULE.bazel`. Declarations from all modules in the dependency graph are
combined:

```bzl
# MODULE.bazel
multitransition_config = use_extension(
    "@rules_multitransition//:extensions.bzl",
    "multitransition_config",
    dev_dependency = True,
)
multitransition_config.extend(
    command_line_options = ["conlyopt"],
    flags = ["@cortex_m//config:semihosting"],
)
```

Use `dev_dependency = True` when the declarations are only needed for your
own tests. Omit it if your module provides a macro around
`multitransition.test` that other modules call with these options, so the
declarations apply when your module is a dependency.

Set a native option by passing its name as a keyword argument to
`multitransition.transition`, e.g. `features = [...]`, or in `flags` with the
key `//command_line_option:<name>`. Set a Starlark build setting in `flags`
with its label as the key:

```bzl
multitransition.transition(
    name = "cortex-m3",
    platform = "@cortex_m//platform:lm3s6965evb",
    features = ["treat_warnings_as_errors"],
    flags = {
        "//command_line_option:copt": ["-DNDEBUG"],
        "@cortex_m//config:semihosting": True,
    },
)
```

The target platform is the exception: set it with `platform` and a single
label, which replaces `--platforms`. Setting `platforms` directly fails, as
a transition supports only one target platform
([bazelbuild/bazel#10154](https://github.com/bazelbuild/bazel/issues/10154)).

Values are converted to the type of the option. List options are appended
to.

For `features`, prefix a feature with `-` to disable it. A negative feature
overrides a positive one, so a variant can disable a feature enabled on the
command line, but can't enable a feature disabled on the command line. See
`//examples/features`.

### Aspects

`multitransition.target` builds a target in each configuration. Each
`<name>.<config>` target forwards the providers of `src`. A configuration may
also apply an aspect with `multitransition.aspect`; the default output of that
target is then the aspect's `output_group`. Declare the aspect in
`MODULE.bazel`:

```bzl
# MODULE.bazel
multitransition_config.extend(
    aspects = ["@rules_clang_tidy//:aspects.bzl%check"],
)
```

```bzl
# BUILD.bazel
multitransition.target(
    name = "lib_transitioned",
    src = ":lib",
    transitions = [
        multitransition.transition(
            name = "clang-tidy-report",
            aspect = multitransition.aspect(
                aspect = "@rules_clang_tidy//:aspects.bzl%check",
                output_group = "report",
            ),
        ),
    ],
)
```

```sh
$ bazel build //:lib_transitioned.clang-tidy-report
```

See `//examples/aspect`.

### Running

Run all the `multitransition.test` targets with Bazel:

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
