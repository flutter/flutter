# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A target built under another configuration's flags: GN's per-build-directory outputs, gathered.

GN builds each runtime mode and each target platform as a build directory
of its own (host_debug, host_profile, host_release, wasm_release:
tools/gn --runtime-mode, --web), and the SDK's cache gathers their
archives under one tree (`bin/cache/artifacts/engine/linux-x64`,
`linux-x64-profile`, `linux-x64-release`, `bin/cache/flutter_web_sdk`).
Bazel's builds of them are configurations (ci/builders/configs.bazelrc:
`--config=host_release` is `-c opt --//engine/src/flutter/common:runtime_mode=release`,
`--config=wasm_release` that plus `--platforms=...:wasm32_emscripten`), and
in_configuration builds one target under such a configuration from
another -- a Starlark transition on the dependency edge -- for a consumer
that lays the builds side by side: the tests' SDK facsimile
(local_engine.bzl's bundle_directory over //flutter/build/archives' and
web_sdk's bundles). The transitioned target's files and its archive
entries (ZipBundleInfo) are forwarded.
"""

load("//build_defs/dist:zip_bundle.bzl", "ZipBundleInfo")

RUNTIME_MODES = ["debug", "profile", "release", "jit_release"]

def _configuration_transition_impl(settings, attr):
    # tools/gn builds every mode but debug optimized (--unoptimized is the
    # debug mode's own switch): -c opt as the builder configurations have it.
    mode = attr.runtime_mode or settings["//engine/src/flutter/common:runtime_mode"]
    return {
        "//command_line_option:compilation_mode": settings["//command_line_option:compilation_mode"] if mode == "debug" else "opt",
        "//command_line_option:platforms": [str(attr.platform)] if attr.platform else settings["//command_line_option:platforms"],
        "//engine/src/flutter/common:runtime_mode": mode,
    }

_configuration_transition = transition(
    implementation = _configuration_transition_impl,
    inputs = [
        "//command_line_option:compilation_mode",
        "//command_line_option:platforms",
        "//engine/src/flutter/common:runtime_mode",
    ],
    outputs = [
        "//command_line_option:compilation_mode",
        "//command_line_option:platforms",
        "//engine/src/flutter/common:runtime_mode",
    ],
)

def _in_configuration_impl(ctx):
    target = ctx.attr.target[0]
    providers = [DefaultInfo(files = target[DefaultInfo].files)]
    if ZipBundleInfo in target:
        providers.append(target[ZipBundleInfo])
    return providers

in_configuration = rule(
    implementation = _in_configuration_impl,
    doc = "`target` built under another configuration -- a runtime mode (-c opt and the engine's runtime_mode " +
          "flag, as --config=host_<mode>) and/or a platform (the web engine's wasm32_emscripten): its files, " +
          "and its archive entries when it is a zip_bundle.",
    attrs = {
        "target": attr.label(
            mandatory = True,
            cfg = _configuration_transition,
            doc = "The target to build under the other configuration.",
        ),
        "runtime_mode": attr.string(
            values = [""] + RUNTIME_MODES,
            doc = "GN's flutter_runtime_mode: debug, profile, release or jit_release; the current one if empty.",
        ),
        "platform": attr.label(
            doc = "The platform to build for (--platforms); the current one if unset.",
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)
