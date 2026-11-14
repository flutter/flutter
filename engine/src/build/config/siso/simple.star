# -*- bazel-starlark -*-
# Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Siso configuration for simple steps."""

load("@builtin//struct.star", "module")

def __filegroups(ctx):
    return {}

def __copy(ctx, cmd):
    input = cmd.inputs[0]
    out = cmd.outputs[0]
    ctx.actions.copy(input, out, recursive = ctx.fs.is_dir(input))
    ctx.actions.exit(exit_status = 0)

def __copy_bundle_data(ctx, cmd):
    input = cmd.inputs[0]
    out = cmd.outputs[0]
    ctx.actions.copy(input, out, recursive = ctx.fs.is_dir(input))
    ctx.actions.exit(exit_status = 0)

def __stamp(ctx, cmd):
    if len(cmd.outputs) > 1:
        return
    out = cmd.outputs[0]
    if ctx.fs.exists(out):
        ctx.actions.write(out, ctx.fs.read(out))
    else:
        ctx.actions.write(out)
    ctx.actions.exit(exit_status = 0)

__handlers = {
    "copy": __copy,
    "copy_bundle_data": __copy_bundle_data,
    "stamp": __stamp,
}

def __step_config(ctx, step_config):
    step_config["rules"].extend([
        {
            "name": "simple/copy",
            "action": "(.*_)?copy",
            "handler": "copy",
        },
        {
            "name": "simple/copy_bundle_data",
            "action": "(.*)?copy_bundle_data",
            "handler": "copy_bundle_data",
        },
        {
            "name": "simple/stamp",
            "action": "(.*_)?stamp",
            "handler": "stamp",
            "replace": True,
        },
    ])
    return step_config

simple = module(
    "simple",
    step_config = __step_config,
    filegroups = __filegroups,
    handlers = __handlers,
)
