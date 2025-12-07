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
