"""Checks that 'build_config' is generated in the 'opt' configuration."""

import build_config

assert build_config.COMPILATION_MODE == "opt", build_config.COMPILATION_MODE
