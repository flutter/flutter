# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""impellerc as the build's tool: built without the target's fontconfig.

The shader rules (shaders.bzl) and a test's shader assets
(//build_defs/dart:flutter_assets.bzl) run impellerc in the exec
configuration, which Bazel derives from the target's: the Starlark flags
come along, and so the Linux desktop builds' `--//engine/src/flutter/txt:
use_fontconfig` (tools/gn's --enable-fontconfig, ci/builders/configs.bazelrc)
reaches the tool, whose Skia then carries fontmgr_fontconfig and a link
against the sysroot's libfontconfig.so.1 -- a library impellerc never calls
(GN builds its host impellerc the same way, incidentally, and runs it where
fontconfig is installed). On a remote worker (the root .bazelrc's build:rbe,
CI's Linux builders) there is no libfontconfig.so.1 to load, and the first
RBE run of the desktop builds failed on exactly that, every shader of them:
"error while loading shared libraries: libfontconfig.so.1". So the tool is
built with the flag off, whatever the build's setting: the one impellerc for
every configuration, which is also the one every builder's remote cache
shares. The impellerc the artifacts ship (//engine/src/flutter/build/
archives) is the target configuration's, untouched.
"""

def _without_fontconfig_impl(_settings, _attr):
    return {"//engine/src/flutter/txt:use_fontconfig": False}

_without_fontconfig = transition(
    implementation = _without_fontconfig_impl,
    inputs = [],
    outputs = ["//engine/src/flutter/txt:use_fontconfig"],
)

def _impellerc_tool_impl(ctx):
    binary = ctx.attr.binary[0][DefaultInfo]
    executable = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.symlink(
        output = executable,
        target_file = binary.files_to_run.executable,
        is_executable = True,
    )
    return [DefaultInfo(
        executable = executable,
        files = depset([executable]),
        runfiles = binary.default_runfiles,
    )]

impellerc_tool = rule(
    implementation = _impellerc_tool_impl,
    doc = "The impellerc binary with --//engine/src/flutter/txt:use_fontconfig off: the tool the shader rules run (see the file's docstring).",
    attrs = {
        "binary": attr.label(
            mandatory = True,
            executable = True,
            cfg = _without_fontconfig,
            doc = "//engine/src/flutter/impeller/compiler:impellerc.",
        ),
    },
    executable = True,
)
