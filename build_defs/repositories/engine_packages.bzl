# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The engine's Dart package configuration, for a checkout that has none.

`gclient sync` ends with DEPS' pub_get_offline hook: `dart pub get --offline`
in engine/src/flutter, the root of the engine's pub workspace, whose
packages are all path dependencies into the synced trees (the Dart SDK's
`pkg` and `third_party/pkg`, `third_party/pkg/*`). It writes
engine/src/flutter/.dart_tool/package_config.json, which the engine's Dart
compiles and its Dart packages' tests read, and the GN converter's own
imports resolve through.

A checkout that was never synced has neither the file nor the trees. This
repository is then the same resolution over the fetched trees
(git_deps.bzl): a view of the checkout with those trees at their paths
(repositories.bzl's checkout_view), in which the same `pub get --offline`
runs with the same Dart SDK (the Dart tree's bootstrap SDK). pub writes into
the view -- the workspace's and its members' `.dart_tool`, the lock file --
and never into the checkout. The configuration names every package by a
path relative to itself, so it reads the same wherever it is laid at
engine/src/flutter/.dart_tool/ beside the packages, as the tests' trees lay
it; and the view stays, for what runs straight from it (the converter).

@host_platform's ENGINE_PACKAGE_CONFIG says which of the two a build reads:
the checkout's file where there is one.
"""

load(":repositories.bzl", "checkout_root", "checkout_view", "fetched_tree_directory", "in_checkout")

_FLUTTER = "engine/src/flutter"

_BAZEL_FILE_NAMES = ["BUILD", "BUILD.bazel", "MODULE.bazel", "REPO.bazel", "WORKSPACE", "WORKSPACE.bazel"]

# The view of the checkout, in the repository, and the configuration in it.
ENGINE_PACKAGE_CONFIG_VIEW = "checkout"
ENGINE_PACKAGE_CONFIG_FILE = ENGINE_PACKAGE_CONFIG_VIEW + "/" + _FLUTTER + "/.dart_tool/package_config.json"

# The `dart` DEPS' hook runs pub with (tools/pub_get_offline.py): the Dart
# tree's bootstrap SDK, relative to engine/src/flutter.
_DART = "third_party/dart/tools/sdks/dart-sdk/bin/dart"

# What pub records as its cache: a path that is the same on every machine
# and no directory (git_deps.bzl's, for the Dart tree's own configuration).
# Every package is a path dependency; --offline reads none from a cache.
_PUB_CACHE = "/dev/null/pub-cache"

def _workspace_members(pubspec):
    """The `workspace:` list of a pubspec (paths relative to it), read off its lines."""
    members = []
    inside = False
    for line in pubspec.splitlines():
        if line.startswith("workspace:"):
            inside = True
        elif inside:
            stripped = line.strip()
            if stripped.startswith("- "):
                members.append(stripped[2:].strip().strip("'\""))
            elif stripped and not stripped.startswith("#"):
                break
    return members

def _path_dependencies(pubspec):
    """The directories a pubspec's `path:` dependencies name, relative to it, normalized."""
    paths = []
    for line in pubspec.splitlines():
        stripped = line.strip()
        if not stripped.startswith("path:"):
            continue
        parts = []
        for part in stripped[len("path:"):].strip().strip("'\"").split("/"):
            if part == "..":
                if not parts:
                    fail("engine_package_config: a path dependency outside engine/src/flutter: %s" % stripped)
                parts.pop()
            elif part and part != ".":
                parts.append(part)
        if parts:
            paths.append("/".join(parts))
    return paths

def _engine_package_config_impl(rctx):
    checkout = checkout_root(rctx)
    flutter = checkout.get_child(_FLUTTER)
    pubspec_file = flutter.get_child("pubspec.yaml")
    rctx.watch(pubspec_file)
    pubspec = rctx.read(pubspec_file)
    members = _workspace_members(pubspec)
    if not members:
        fail("engine_package_config: %s names no workspace members" % pubspec_file)
    for member in members:
        rctx.watch(flutter.get_child(member).get_child("pubspec.yaml"))

    # The trees the workspace's path dependencies are in, where the checkout
    # lacks them: fetched.
    # The outermost dependency of DEPS a package is in has the package: what
    # DEPS nests in a tree comes with the tree.
    fetchable = {path: label for label, path in rctx.attr.trees.items()}
    trees = {}
    for dependency in _path_dependencies(pubspec):
        directory = _FLUTTER + "/" + dependency
        around = [path for path in fetchable if directory == path or directory.startswith(path + "/")]
        if not around:
            continue
        path = sorted(around, key = len)[0]
        if path not in trees and not in_checkout(rctx, path):
            trees[path] = fetched_tree_directory(rctx, fetchable[path])

    # pub writes the configuration and the lock file beside the workspace's
    # pubspec and a `.dart_tool` into every member: those directories are
    # the view's own, and what a synced checkout has of them stays out. So
    # do the checkout's Bazel files in the directories down to the
    # workspace's: with one of them, the directory would be a package of
    # this repository and the configuration no file of the root package's,
    # which is how the build names it.
    checkout_view(
        rctx,
        ENGINE_PACKAGE_CONFIG_VIEW,
        trees,
        directories = [_FLUTTER] + [_FLUTTER + "/" + member for member in members],
        skip = [".dart_tool", "pubspec.lock"] + _BAZEL_FILE_NAMES,
    )
    workspace = rctx.path(ENGINE_PACKAGE_CONFIG_VIEW).get_child(_FLUTTER)
    dart = workspace.get_child(_DART)
    if not dart.exists:
        fail("engine_package_config: %s does not exist (the Dart tree's bootstrap SDK, which runs pub)" % dart)
    result = rctx.execute(
        [dart, "pub", "--suppress-analytics", "get", "--offline"],
        working_directory = str(workspace),
        environment = {"HOME": str(rctx.path("home")), "PUB_CACHE": _PUB_CACHE},
        timeout = 600,
    )
    if result.return_code != 0:
        fail("engine_package_config: `dart pub get --offline` failed in the view of %s:\n%s%s" % (flutter, result.stdout, result.stderr))
    rctx.delete("home")
    if not rctx.path(ENGINE_PACKAGE_CONFIG_FILE).exists:
        fail("engine_package_config: pub wrote no %s" % ENGINE_PACKAGE_CONFIG_FILE)
    rctx.file("BUILD.bazel", """\
# The engine's package configuration, resolved over fetched packages
# (build_defs/repositories/engine_packages.bzl).
exports_files(["{file}"])
""".format(file = ENGINE_PACKAGE_CONFIG_FILE))
    rctx.file("REPO.bazel", "")

engine_package_config = repository_rule(
    implementation = _engine_package_config_impl,
    doc = "The engine's pub workspace resolved (`dart pub get --offline`) over fetched trees: " +
          "engine/src/flutter/.dart_tool/package_config.json for a checkout without `gclient sync`.",
    attrs = {
        "trees": attr.label_keyed_string_dict(
            doc = "Every git dependency of DEPS that has a fetched tree (the BUILD file of the tree's " +
                  "repository, to the dependency's path relative to the repository root); those the " +
                  "workspace's path dependencies are in are fetched where the checkout lacks them.",
        ),
    },
)
