# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A test's writable view of a checkout-shaped runfiles tree, with GN's build directory.

run_tests.py runs some of the engine's tests from their directories in the
checkout, against `engine/src/out/<variant>`: a Dart package's suite
(dart/package_test.bzl), font-subset's test.py (checkout_script_test.bzl).
Under Bazel the runfiles tree is shaped like the checkout -- the files at
their paths under engine/src -- and the test runs in a writable view of it
under TEST_TMPDIR: the directories down to the test's own directory are
real, everything beside that path a symlink into the runfiles, and the
directory itself a copy. Bazel mounts a runfiles tree read-only once it
exists, and these tests write beside their fixtures (kernels, subset fonts),
as they do in the checkout where git ignores the files.

The build directory is `engine/src/out/<name>` of that tree, GN's place for
one, named as tools/gn names it for the mode (host_debug_unopt,
host_release, ...): a test reads the mode off the name, or is handed it as
`--variant`. It holds the files the test's `build_directory` maps there, by
base name under the subdirectory each target is mapped to.
"""

load("@bazel_skylib//lib:paths.bzl", "paths")

# The checkout's engine/src, under which GN's build directory lives.
ENGINE_SRC = "engine/src"

# GN's build directory names (tools/gn's get_out_dir): what is built for --
# `host` for the host's own build, `wasm` for --web, `linux` for the Linux
# arm64 cross build (--target-os=linux), `android` for --android -- then the
# runtime mode, then `_unopt` when not optimized, then the CPU when not the
# target's default (`_arm64`, `_x64`; Android's default is arm, Linux's the
# host's): `host_debug_unopt`, `wasm_release`, `linux_debug_arm64`,
# `android_debug_unopt_arm64`.
BUILD_DIRECTORY_TARGETS = {
    "@platforms//os:emscripten": "wasm",
    "@platforms//os:android": "android",
    "//engine/src/flutter/common:platform_linux_arm64": "linux",
    "//conditions:default": "host",
}

BUILD_DIRECTORY_MODES = {
    "//engine/src/flutter/common:runtime_mode_jit_release": "jit_release",
    "//engine/src/flutter/common:runtime_mode_profile": "profile",
    "//engine/src/flutter/common:runtime_mode_release": "release",
    "//conditions:default": "debug",
}

BUILD_DIRECTORY_CPUS = {
    "@platforms//cpu:aarch64": "_arm64",
    "@platforms//cpu:riscv64": "_riscv64",
    "//engine/src/flutter/common:platform_android_x64": "_x64",
    "//engine/src/flutter/common:platform_android_x86": "_x86",
    "//conditions:default": "",
}

def build_directory_attrs():
    """The rule attributes a macro sets for the build directory's name: `build_directory_name`, `optimized` and `build_directory_cpu`."""
    return {
        "build_directory_name": select(BUILD_DIRECTORY_TARGETS) + "_" + select(BUILD_DIRECTORY_MODES),
        "build_directory_cpu": select(BUILD_DIRECTORY_CPUS),
        "optimized": select({
            "//engine/src/flutter/build/bazel:optimized": True,
            "//conditions:default": False,
        }),
    }

BUILD_DIRECTORY_ATTRS = {
    "build_directory": attr.label_keyed_string_dict(
        allow_files = True,
        doc = "Files of the build directory, each target mapped to the directory under it that " +
              "holds its files by base name (``, `gen`, `zip_archives/linux-x64`).",
    ),
    "build_directory_name": attr.string(
        mandatory = True,
        doc = "GN's name for the build directory of this configuration, up to the mode (host_debug, host_release, wasm_release, ...): build_directory_attrs().",
    ),
    "build_directory_cpu": attr.string(
        doc = "The CPU suffix of GN's name for the build directory, after _unopt (`_arm64`, or nothing): build_directory_attrs().",
    ),
    "optimized": attr.bool(
        doc = "Whether this is an optimized build; GN's name carries _unopt otherwise: build_directory_attrs().",
    ),
}

def build_directory_variant(ctx):
    """GN's name for the build directory of this configuration (`host_debug_unopt`, `android_debug_unopt_arm64`)."""
    return ctx.attr.build_directory_name + ("" if ctx.attr.optimized else "_unopt") + ctx.attr.build_directory_cpu

def build_directory_symlinks(ctx, symlinks):
    """Places the `build_directory` files in the runfiles tree.

    Args:
      ctx: the rule context, with BUILD_DIRECTORY_ATTRS.
      symlinks: the runfiles symlinks (paths to files) to add them to.

    Returns:
      the build directory's runfiles path (`engine/src/out/host_debug_unopt`).
    """
    build_directory = paths.join(ENGINE_SRC, "out", build_directory_variant(ctx))
    for target, path in ctx.attr.build_directory.items():
        for f in target[DefaultInfo].files.to_list():
            symlinks[paths.join(build_directory, path.strip("/"), f.basename)] = f
    return build_directory

def checkout_view_prologue(directory, build_directory):
    """The launcher's opening: the writable view, HOME and FLUTTER_BUILD_DIRECTORY, the working directory.

    Args:
      directory: the test's own directory, as a runfiles path (the package).
      build_directory: the build directory's runfiles path.

    Returns:
      bash, from the shebang to a `cd` into the directory's copy; `$root` is
      the runfiles directory and `$tree` the view.
    """
    return """#!/bin/bash
set -euo pipefail
shopt -s dotglob nullglob
# The runfiles directory of this repository: bazel test's working directory.
root="$PWD"
# A writable view of it: real directories down to the test's own directory,
# symlinks to everything beside that path, the directory itself a copy.
tree="$TEST_TMPDIR/tree"
directory="{directory}"
IFS=/ read -r -a parts <<< "$directory"
dir=""
for part in "${{parts[@]}}"; do
  mkdir -p "$tree/$dir"
  for entry in "$root/$dir"*; do
    name="${{entry##*/}}"
    [ "$name" = "$part" ] || ln -s "$entry" "$tree/$dir$name"
  done
  dir="$dir$part/"
done
cp -RL "$root/$directory" "$tree/$directory"
export HOME="$TEST_TMPDIR/home"
export FLUTTER_BUILD_DIRECTORY="$tree/{build_directory}"
mkdir -p "$HOME" "$FLUTTER_BUILD_DIRECTORY"
cd "$tree/$directory"
""".format(
        directory = directory,
        build_directory = build_directory,
    )
