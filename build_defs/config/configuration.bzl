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
`--config=host_release` is `-c opt --//engine/src/flutter/common:runtime_mode=release
--platforms=...:linux_x64_release`, `--config=wasm_release` the same with
`...:wasm32_emscripten_release`: every runtime mode of a platform is a
platform of its own, platforms.bzl), and in_configuration builds one target
under such a configuration from another -- a Starlark transition on the
dependency edge -- for a consumer that lays the builds side by side: the
tests' SDK facsimile (local_engine.bzl's bundle_directory over
//flutter/build/archives' and web_sdk's bundles). The transitioned target's
files and its archive entries (ZipBundleInfo) are forwarded.
"""

load("@host_platform//:host.bzl", "HOST_PLATFORM")
load("//build_defs/dist:zip_bundle.bzl", "ZipBundleInfo")
load(":platforms.bzl", "RUNTIME_MODES", "RUNTIME_MODE_FLAG", "runtime_mode_platform_base", "runtime_mode_platform_name")

# The engine's platforms (build/bazel/toolchains; the web's under
# emscripten/): where the host's modeless platform (Bazel's own, when no
# --platforms is given) is replaced by the mode's.
_TOOLCHAINS = "//engine/src/flutter/build/bazel/toolchains"

def runtime_mode_platform(current, mode):
    """The platform `current` (a label string) becomes under `mode`: the mode's sibling of its base.

    `//engine/src/flutter/build/bazel/toolchains:android_arm64_debug` under
    profile is `...:android_arm64_profile`; a modeless platform (the web's
    `wasm32_emscripten`, given to in_configuration) gets the mode's child;
    Bazel's own host platform (`@platforms//host`, the default when no
    --platforms is given) is the host's platform of the build
    (@host_platform's HOST_PLATFORM: linux_x64, macos_arm64, ...) under the
    mode.

    Args:
      current: the current platform, as a transition reads --platforms.
      mode: the runtime mode wanted.

    Returns:
      The label string of the mode's platform.
    """
    package, _, name = current.rpartition(":")
    if not package.endswith(_TOOLCHAINS) and not package.endswith(_TOOLCHAINS + "/emscripten"):
        # Bazel's host platform, or any other outside the engine's: the host's.
        return "%s:%s" % (_TOOLCHAINS, runtime_mode_platform_name(HOST_PLATFORM, mode))
    return "%s:%s" % (package, runtime_mode_platform_name(runtime_mode_platform_base(name), mode))

def _configuration_transition_impl(settings, attr):
    # tools/gn builds every mode but debug optimized (--unoptimized is the
    # debug mode's own switch): -c opt as the builder configurations have it;
    # `compilation_mode` says otherwise (the Android builders build debug
    # optimized too, android_debug_<cpu>).
    mode = attr.runtime_mode or settings[RUNTIME_MODE_FLAG]
    compilation_mode = attr.compilation_mode or (settings["//command_line_option:compilation_mode"] if mode == "debug" else "opt")

    # The mode's platform: of the one given, or of the current one. The
    # platform's flag sets the mode in the target configuration; the flag is
    # set here too, for the execution configuration the target's tools are
    # built in (see platforms.bzl).
    current = str(attr.platform) if attr.platform else str(settings["//command_line_option:platforms"][0])
    return {
        "//command_line_option:compilation_mode": compilation_mode,
        "//command_line_option:platforms": [runtime_mode_platform(current, mode)],
        RUNTIME_MODE_FLAG: mode,
        "//engine/src/flutter/build/bazel:lto": _tristate(attr.lto, settings["//engine/src/flutter/build/bazel:lto"]),
        "//engine/src/flutter/build/bazel:stripped": _tristate(attr.stripped, settings["//engine/src/flutter/build/bazel:stripped"]),
    }

def _tristate(value, current):
    """A "true"/"false" attribute's value, or the current setting when it is unset."""
    if value == "":
        return current
    return value == "true"

_configuration_transition = transition(
    implementation = _configuration_transition_impl,
    inputs = [
        "//command_line_option:compilation_mode",
        "//command_line_option:platforms",
        RUNTIME_MODE_FLAG,
        "//engine/src/flutter/build/bazel:lto",
        "//engine/src/flutter/build/bazel:stripped",
    ],
    outputs = [
        "//command_line_option:compilation_mode",
        "//command_line_option:platforms",
        RUNTIME_MODE_FLAG,
        "//engine/src/flutter/build/bazel:lto",
        "//engine/src/flutter/build/bazel:stripped",
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
            doc = "The platform to build for (--platforms), or the base of one: the runtime mode's platform of " +
                  "it is used (platforms.bzl); the current platform's if unset.",
        ),
        "compilation_mode": attr.string(
            values = ["", "fastbuild", "dbg", "opt"],
            doc = "The compilation mode (-c): opt for every runtime mode but debug by default, debug keeping the " +
                  "current one; `opt` for a debug build the builders build optimized (Android's).",
        ),
        "lto": attr.string(
            values = ["", "true", "false"],
            doc = "GN's enable_lto (//engine/src/flutter/build/bazel:lto): the current setting if empty; `true` " +
                  "for a build the builders make with it (the Android profile and release builds).",
        ),
        "stripped": attr.string(
            values = ["", "true", "false"],
            doc = "tools/gn's stripped_symbols (//engine/src/flutter/build/bazel:stripped): the current setting " +
                  "if empty; `false` for a build the builders make with --no-stripped (every Android build: " +
                  "the embedding's jar carries the unstripped libflutter.so, whose symbols an app's build " +
                  "extracts and strips itself).",
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)
