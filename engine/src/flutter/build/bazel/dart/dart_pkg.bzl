# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""GN's dart_pkg.py action (//flutter/build/dart/tools/dart_pkg.py) as a rule.

sky/packages/sky_engine's `action("sky_engine")` runs the script to assemble
the sky_engine package directory in the build directory's gen/dart-pkg/:
the package's own files (pubspec.yaml, LICENSE, README.md, lib/_empty.dart)
at their paths under the package, the SDK extension sources under sdk_ext/,
and a stamp. The libraries the package carries (lib/async, lib/ui, ...) are
copies of their own, deps of the action, which land beside these through
install (BuildDirectoryInfo). Here the script runs the same way into a
directory artifact, which install copies under gen/dart-pkg/.
"""

load("//engine/src/flutter/build/bazel:build_directory.bzl", "BuildDirectoryInfo")
load("//engine/src/flutter/build/bazel/gn_action:gn_action.bzl", "PYTHON_ATTRS", "run_python")

def _dart_pkg_impl(ctx):
    directory = ctx.actions.declare_directory(ctx.label.name + ".dart-pkg")
    stamp = ctx.actions.declare_file(ctx.label.name + ".stamp")
    args = ctx.actions.args()
    args.add("--package-name", ctx.attr.package)
    args.add("--pkg-directory", directory.path)
    args.add("--stamp-file", stamp)
    args.add("--package-sources")
    args.add_all(ctx.files.srcs)
    args.add("--sdk-ext-directories")
    args.add("--sdk-ext-files")
    args.add_all(ctx.files.sdk_ext)
    args.add("--sdk-ext-mappings")
    run_python(
        ctx,
        script = ctx.file._script,
        arguments = [args],
        inputs = ctx.files.srcs + ctx.files.sdk_ext,
        outputs = [directory, stamp],
        mnemonic = "DartPkg",
        progress_message = "Assembling the Dart package %{label}",
    )
    return [
        DefaultInfo(files = depset([directory, stamp])),
        BuildDirectoryInfo(entries = depset([(directory, "gen/dart-pkg")])),
    ]

dart_pkg = rule(
    implementation = _dart_pkg_impl,
    doc = "A package directory assembled by GN's dart_pkg.py, for install to place under gen/dart-pkg/.",
    attrs = {
        "package": attr.string(
            mandatory = True,
            doc = "The package's name (GN's package_name): the directory under gen/dart-pkg/.",
        ),
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
            doc = "The package's own files (GN's sources: pubspec.yaml among them), placed at " +
                  "their paths under their common directory.",
        ),
        "sdk_ext": attr.label_list(
            allow_files = True,
            doc = "The SDK extension sources (GN's sdk_ext_files), placed under sdk_ext/ by name.",
        ),
        "deps": attr.label_list(
            doc = "The copies that fill the package's lib/ (GN's deps), for install to find through this target.",
        ),
        "_script": attr.label(
            default = "//engine/src/flutter/build:dart/tools/dart_pkg.py",
            allow_single_file = True,
        ),
    } | PYTHON_ATTRS,
)
