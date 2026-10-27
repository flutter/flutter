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

With `script`, the same tree and launcher run a script of the package on
the VM instead of the test runner -- a CI step of the form `dart <script>
<args>` (ci/check_build_configs.sh's check.dart over the builder files,
shell/testing/vm_service/test.dart over flutter_tester) -- with its
arguments, whose placeholders are checkout_script_test's.

A test runs in a writable view of the runfiles tree under TEST_TMPDIR
(checkout_view.bzl): the directories down to the package are real,
everything beside that path a symlink into the runfiles, and the package
itself a copy. Bazel mounts a runfiles tree read-only once it exists, and
flutter_frontend_server's test writes its kernels beside its fixtures, as it
does in the checkout (where they are ignored by git).
"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@host_platform//:host.bzl", "HOST_DART_SDK")
load(
    "//build_defs/config:checkout_view.bzl",
    "BUILD_DIRECTORY_ATTRS",
    "ENGINE_SRC",
    "build_directory_attrs",
    "build_directory_symlinks",
    "build_directory_variant",
    "checkout_view_prologue",
)
load(
    "//build_defs/testing:checkout_script_test.bzl",
    "script_argument",
)

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

def _external_path(ctx, f):
    """The path of a file of another repository, relative to that repository's root."""
    if not f.short_path.startswith("../"):
        fail("%s: %s is in this repository; list it in srcs, deps or data" % (ctx.label, f.short_path))
    return f.short_path.split("/", 2)[2]

def _dart_package_test_impl(ctx):
    package_config = ctx.file.package_config
    workspace = paths.dirname(paths.dirname(package_config.short_path))
    if paths.dirname(workspace) != ENGINE_SRC:
        fail("%s: the package configuration %s should be the engine's" % (ctx.label, package_config.short_path))
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
    build_directory = build_directory_symlinks(ctx, symlinks)

    dart = [f for f in ctx.files._sdk if f.short_path.endswith("/bin/dart")]
    if len(dart) != 1:
        fail("%s: the SDK should hold one bin/dart" % ctx.label)

    # The entry point: package:test's runner over the package's tests, or
    # a script of the package (a CI step's `dart <script> <args>`:
    # check_build_configs.sh's check.dart, the service protocol test) with
    # its arguments, the placeholders expanded as checkout_script_test's.
    script = ctx.file.script
    if script == None:
        entry = '"$tree/%s" --reporter=expanded' % runner
    else:
        if not script.short_path.startswith(package + "/"):
            fail("%s: the script %s should be a file of this package" % (ctx.label, script.short_path))
        variant = build_directory_variant(ctx)
        entry = " ".join(['"$tree/%s"' % script.short_path] + [script_argument(arg, variant) for arg in ctx.attr.script_args])

    launcher = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        output = launcher,
        content = checkout_view_prologue(package, build_directory) + """
exec "$root/{dart}" "--packages=$tree/{package_config}" {entry} "$@"
""".format(
            dart = dart[0].short_path,
            package_config = package_config.short_path,
            entry = entry,
        ),
        is_executable = True,
    )

    runfiles = ctx.runfiles(
        files = ctx.files.srcs + ctx.files.deps + ctx.files.data + ctx.files._sdk + [package_config] +
                ([script] if script != None else []),
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
        "env": attr.string_dict(
            doc = "Further environment variables for the run.",
        ),
        "script": attr.label(
            allow_single_file = [".dart"],
            doc = "A script of the package to run on the VM instead of the package's tests (a CI step's " +
                  "`dart <script> <args>`), with script_args.",
        ),
        "script_args": attr.string_list(
            doc = "The script's arguments; `{variant}` stands for the build directory's name, " +
                  "`{build_directory}` for its path in the view, `{engine_src}` for the view's engine/src.",
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
                HOST_DART_SDK + "//:dart",
                HOST_DART_SDK + "//:dartaotruntime",
            ],
            allow_files = True,
            doc = "The prebuilt SDK: dart with its libraries and snapshots, and the AOT runtime beside it " +
                  "(flutter_frontend_server's test runs the frontend server on it).",
        ),
    } | BUILD_DIRECTORY_ATTRS,
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
      **kwargs: deps, data, build_directory, env, args, script and
        script_args (a script of the package run on the VM in place of the
        package's tests: a CI step's `dart <script> <args>`), and the test
        attributes.
    """
    if srcs == None:
        srcs = native.glob(["**"], exclude = [".dart_tool/**"])
    _dart_package_test(
        name = name,
        srcs = srcs,
        package_trees = package_trees,
        size = size,
        **(build_directory_attrs() | kwargs)
    )
