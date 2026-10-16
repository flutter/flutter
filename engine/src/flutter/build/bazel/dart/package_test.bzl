# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A Dart package's own tests, with package:test: run_tests.py's --type dart-host.

testing/run_tests.py runs `dart test --reporter=expanded` in each Dart
package of build_dart_host_test_list (ci, flutter_frontend_server,
testing/skia_gold_client, tools/*, tools/pkg/*), from the package's directory
in the checkout, with the build directory's copy of the prebuilt Dart SDK and
FLUTTER_BUILD_DIRECTORY pointing at the build directory. The packages are
pure Dart: nothing of the engine is involved beyond what a few of their tests
read from the tree (ci/builders, .ci.yaml, lib/ui's API files, DEPS) and, for
flutter_frontend_server, the frontend server and the engine's platform
kernel out of the build directory.

dart_package_test runs the same suite from a runfiles tree shaped like the
checkout: the package's files at their paths under engine/src/flutter, the
engine's package configuration (the one `gclient sync` wrote, which names
every package by a path relative to itself), the packages of the pub
workspace that live in synced trees staged at those paths (`package_trees`,
as dart_package_root does for the kernel compiles), the in-tree packages a
test imports (`deps`) and what its tests read (`data`). Engine.findWithin()
-- which the tools use to find the checkout from the working directory --
finds `engine/src` in the runfiles tree the same way.

The launcher runs package:test's own entry point on the VM
(`dart --packages=<the configuration> .../test/bin/test.dart
--reporter=expanded`), which is what `dart test` delegates to once pub has
checked the workspace's resolution. That check wants every pubspec.yaml of
the workspace's 100 packages, the lock file, the pub cache the configuration
recorded and the members' workspace_ref.json files, and re-resolves (writing
into the tree) when any of it disagrees; the runner itself reads only the
configuration, so the tree stays as declared and nothing is rewritten.

FLUTTER_BUILD_DIRECTORY is `engine/src/out/<name>` of that tree, GN's own
place for a build directory, named as GN names one for the mode
(host_debug_unopt, host_release, ...) -- flutter_frontend_server's test
reads the mode off the name -- holding `build_directory`'s files; empty for
every other package, as the variable is set for every run.

A test runs in a writable view of the runfiles tree under TEST_TMPDIR: the
directories down to the package are real, everything beside that path a
symlink into the runfiles, and the package itself a copy. Bazel mounts a
runfiles tree read-only once it exists, and flutter_frontend_server's test
writes its kernels beside its fixtures, as it does in the checkout (where
they are ignored by git).
"""

load("@bazel_skylib//lib:paths.bzl", "paths")

# The packages of the engine's pub workspace that live in other repositories
# (the trees gclient syncs), each at the path the package configuration names
# it by. Every test stages them all: package:test and what it reaches (the
# analyzer among it), and the four packages under third_party/pkg that the
# tools import.
WORKSPACE_PACKAGE_TREES = {
    "@dart//:host_package_sources": "engine/src/flutter/third_party/dart",
    "@io//:dart_sources": "engine/src/flutter/third_party/pkg/io",
    "@node_preamble//:dart_sources": "engine/src/flutter/third_party/pkg/node_preamble",
    "@process//:dart_sources": "engine/src/flutter/third_party/pkg/process",
    "@process_runner//:dart_sources": "engine/src/flutter/third_party/pkg/process_runner",
}

# GN's build directory names by runtime mode (tools/gn: host_<mode>, with
# _unopt when not optimized), for FLUTTER_BUILD_DIRECTORY.
_BUILD_DIRECTORY_NAMES = {
    "//engine/src/flutter/common:runtime_mode_jit_release": "host_jit_release",
    "//engine/src/flutter/common:runtime_mode_profile": "host_profile",
    "//engine/src/flutter/common:runtime_mode_release": "host_release",
    "//conditions:default": "host_debug",
}

def _external_path(ctx, f):
    """The path of a file of another repository, relative to that repository's root."""
    if not f.short_path.startswith("../"):
        fail("%s: %s is in this repository; list it in srcs, deps or data" % (ctx.label, f.short_path))
    return f.short_path.split("/", 2)[2]

def _dart_package_test_impl(ctx):
    package_config = ctx.file.package_config
    workspace = paths.dirname(paths.dirname(package_config.short_path))
    package = ctx.label.package
    if not package.startswith(workspace + "/"):
        fail("%s: a dart_package_test belongs in a package under %s" % (ctx.label, workspace))

    # Other repositories' package trees at the paths the configuration names.
    symlinks = {}
    for target, virtual_path in ctx.attr.package_trees.items():
        for f in target[DefaultInfo].files.to_list():
            symlinks[paths.join(virtual_path.strip("/"), _external_path(ctx, f))] = f

    # package:test's entry point, from one of those trees.
    runner = None
    for path, f in symlinks.items():
        if f == ctx.file._runner:
            runner = path
    if runner == None:
        fail("%s: the test runner %s must come from one of package_trees" % (ctx.label, ctx.file._runner.short_path))

    # The build directory: GN's place and name for the mode, this target's
    # files under it.
    build_directory = paths.join(
        paths.dirname(workspace),
        "out",
        ctx.attr.build_directory_name + ("" if ctx.attr.optimized else "_unopt"),
    )
    for target, path in ctx.attr.build_directory.items():
        for f in target[DefaultInfo].files.to_list():
            symlinks[paths.join(build_directory, path.strip("/"), f.basename)] = f

    dart = [f for f in ctx.files._sdk if f.short_path.endswith("/bin/dart")]
    if len(dart) != 1:
        fail("%s: the SDK should hold one bin/dart" % ctx.label)

    launcher = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        output = launcher,
        content = """#!/bin/bash
set -euo pipefail
shopt -s dotglob nullglob
# The runfiles directory of this repository: bazel test's working directory.
root="$PWD"
# A writable view of it: real directories down to the package, symlinks to
# everything beside that path, the package itself a copy.
tree="$TEST_TMPDIR/tree"
package="{package}"
IFS=/ read -r -a parts <<< "$package"
dir=""
for part in "${{parts[@]}}"; do
  mkdir -p "$tree/$dir"
  for entry in "$root/$dir"*; do
    name="${{entry##*/}}"
    [ "$name" = "$part" ] || ln -s "$entry" "$tree/$dir$name"
  done
  dir="$dir$part/"
done
cp -RL "$root/$package" "$tree/$package"
export HOME="$TEST_TMPDIR/home"
export FLUTTER_BUILD_DIRECTORY="$tree/{build_directory}"
mkdir -p "$HOME" "$FLUTTER_BUILD_DIRECTORY"
cd "$tree/$package"
exec "$root/{dart}" "--packages=$tree/{package_config}" "$tree/{runner}" --reporter=expanded "$@"
""".format(
            build_directory = build_directory,
            package = package,
            dart = dart[0].short_path,
            package_config = package_config.short_path,
            runner = runner,
        ),
        is_executable = True,
    )

    runfiles = ctx.runfiles(
        files = ctx.files.srcs + ctx.files.deps + ctx.files.data + ctx.files._sdk + [package_config],
        symlinks = symlinks,
    )
    for target in ctx.attr.data + ctx.attr.build_directory.keys():
        runfiles = runfiles.merge(target[DefaultInfo].default_runfiles)
    return [
        DefaultInfo(executable = launcher, runfiles = runfiles),
        RunEnvironmentInfo(environment = dict(ctx.attr.env)),
    ]

_dart_package_test = rule(
    implementation = _dart_package_test_impl,
    test = True,
    doc = "run_tests.py's `dart test --reporter=expanded` in a Dart package of the tree (--type dart-host).",
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
            doc = "The package's files (pubspec.yaml, lib/, test/, bin/, fixtures).",
        ),
        "deps": attr.label_list(
            allow_files = True,
            doc = "The sources of the in-tree packages the package and its tests import (their dart_sources).",
        ),
        "data": attr.label_list(
            allow_files = True,
            doc = "What the tests read from the tree (Engine.findWithin() finds engine/src in the runfiles).",
        ),
        "package_trees": attr.label_keyed_string_dict(
            allow_files = True,
            doc = "Sources of workspace packages in other repositories, each mapped to the path under the " +
                  "source root where the package configuration names the package (WORKSPACE_PACKAGE_TREES).",
        ),
        "build_directory": attr.label_keyed_string_dict(
            allow_files = True,
            doc = "Files of FLUTTER_BUILD_DIRECTORY, each target mapped to the directory under it that " +
                  "holds its files by base name (`gen`, `flutter_patched_sdk`).",
        ),
        "build_directory_name": attr.string(
            mandatory = True,
            doc = "GN's name for the build directory in this mode (host_debug, host_release, ...).",
        ),
        "optimized": attr.bool(
            doc = "Whether this is an optimized build; GN's name carries _unopt otherwise.",
        ),
        "env": attr.string_dict(
            doc = "Further environment variables for the run.",
        ),
        "package_config": attr.label(
            default = "//engine/src/flutter:package_config",
            allow_single_file = True,
            doc = "The engine's package configuration, whose directory's parent is the workspace root.",
        ),
        "_runner": attr.label(
            default = "@dart//:test_runner",
            allow_single_file = True,
            doc = "package:test's bin/test.dart.",
        ),
        "_sdk": attr.label_list(
            default = [
                "@dart_sdk_linux_x64//:dart",
                "@dart_sdk_linux_x64//:dartaotruntime",
            ],
            allow_files = True,
            doc = "The prebuilt SDK: dart with its libraries and snapshots, and the AOT runtime beside it " +
                  "(flutter_frontend_server's test runs the frontend server on it).",
        ),
    },
)

def dart_package_test(name, srcs = None, package_trees = WORKSPACE_PACKAGE_TREES, size = "medium", **kwargs):
    """A Dart package's package:test suite, as run_tests.py --type dart-host runs it.

    Declare it in the package's own BUILD file (the working directory is the
    BUILD file's directory, under engine/src/flutter).

    Args:
      name: the target's name.
      srcs: the package's files; every file of the directory but the
        .dart_tool caches by default.
      package_trees: the workspace packages of other repositories to stage;
        all of them by default.
      size: medium by default (the suites take up to a minute).
      **kwargs: deps, data, build_directory, env, args and the test attributes.
    """
    if srcs == None:
        srcs = native.glob(["**"], exclude = [".dart_tool/**"])
    _dart_package_test(
        name = name,
        srcs = srcs,
        package_trees = package_trees,
        build_directory_name = select(_BUILD_DIRECTORY_NAMES),
        optimized = select({
            "//engine/src/flutter/build/bazel:optimized": True,
            "//conditions:default": False,
        }),
        size = size,
        **kwargs
    )
