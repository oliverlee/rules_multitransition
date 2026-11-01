"""
Rule factory loaded by the `.bzl` that the 'multitransition_config' module
extension generates for each `multitransition_config.aspect` tag.
"""

load("//private:rules.bzl", "TRANSITION", "attrs")

# public so the generated '@multitransition_config' repo can load it
visibility("public")

def _output_group_impl(ctx):
    """
    Provides an output group of `src` as the default output.

    `src` is built in the transitioned configuration with the aspect applied.
    """
    groups = ctx.attr.src[OutputGroupInfo]
    if not hasattr(groups, ctx.attr.output_group):
        fail("{} has no output group '{}'".format(ctx.attr.src.label, ctx.attr.output_group))

    return [DefaultInfo(files = getattr(groups, ctx.attr.output_group))]

def multitransition_target_rule_for_aspect(aspect):
    """
    Creates a rule that builds `src` with `options` and applies `aspect` to it.

    Args:
      aspect: **aspect**
          The aspect to apply to `src`.

    Returns:
      A rule with `src`, `options`, and `output_group` attributes. Its default
      output is `output_group` of `aspect`.
    """
    return rule(
        implementation = _output_group_impl,
        cfg = TRANSITION,
        attrs = attrs([aspect]) | {
            "output_group": attr.string(
                mandatory = True,
                doc = "The output group of the aspect to use as the default output.",
            ),
        },
    )
