"""
Implementation of 'multitransition.aspect'.
"""

visibility("private")

_TYPE = "_RULES_MULTITRANSITION_ASPECT_CONFIG_"

def is_aspect_config(config):
    """
    Check if the object is an aspect config.
    """
    return getattr(config, "type", None) == _TYPE

def aspect_config(*, aspect, output_group):
    """
    Describes an aspect to apply and the output group to use from it.

    Args:
      aspect: string
        The aspect as '<bzl file>%<name>', e.g.
        '@rules_clang_tidy//:aspects.bzl%check'. It must be declared with
        'multitransition_config.aspect' in MODULE.bazel.
      output_group: string
        The output group of 'aspect' to use as the default output, e.g.
        'report'.

    Returns:
      An aspect config struct for 'multitransition.transition'.
    """
    return struct(
        type = _TYPE,
        aspect = aspect,
        output_group = output_group,
    )
