# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A package's flutter_test tests under Bazel (flutter_package_tests).

What every package of the repository that tests with flutter_test shares,
given once: the package configurations over its dependencies, a prelude
kernel of the framework and the package, the asset directory with the
framework's shaders, the SDK-cache paths tests read through FLUTTER_ROOT,
and one flutter_test per file, each with the flutter_test_config.dart
`flutter test` would apply. A package's test/BUILD.bazel names its tests,
helpers and anything of its own (packages/flutter_localizations/test).

package:flutter's own test tree, with its many directories, has
//packages/flutter/test:framework_tests.bzl instead.
"""

load("//engine/src/flutter/build/bazel/dart:flutter_assets.bzl", "flutter_test_assets")
load("//engine/src/flutter/build/bazel/dart:flutter_test.bzl", "flutter_test_prelude", "flutter_tests")
load("//engine/src/flutter/build/bazel/dart:pub.bzl", "pub_package_config")

# The framework's shaders, which flutter_tools compiles into every bundle.
FRAMEWORK_SHADERS = {
    "//packages/flutter:lib/src/material/shaders/ink_sparkle.frag": "shaders/ink_sparkle.frag",
    "//packages/flutter:lib/src/widgets/shaders/stretch_effect.frag": "shaders/stretch_effect.frag",
}

# The SDK cache's two paths tests read through FLUTTER_ROOT: the Dart SDK the
# engine builds with and the Material fonts
# (engine/src/flutter/build/bazel/dart/flutter_sdk_cache.bzl).
SDK_CACHE = {
    "@dart_sdk_linux_x64//:dart": "dart-sdk",
    "@material_fonts//:fonts": "artifacts/material_fonts",
}

# The libraries every package's tests reach, compiled once into the prelude;
# a package whose tests reach more gives `imports` (FRAMEWORK_IMPORTS + its
# own library).
FRAMEWORK_IMPORTS = [
    "package:flutter/cupertino.dart",
    "package:flutter/material.dart",
    "package:flutter/widgets.dart",
    "package:flutter_test/flutter_test.dart",
    "package:test_core/src/direct_run.dart",
]

def flutter_package_tests(
        name,
        package,
        tests,
        directory = None,
        srcs = [],
        deps = [],
        data = [],
        packages = {},
        roots = [],
        dev_roots = None,
        without = [],
        imports = None,
        compile_args = [],
        assets = [],
        shaders = FRAMEWORK_SHADERS,
        cache = SDK_CACHE,
        test_configs = None,
        **kwargs):
    """One flutter_test per file of a package's test tree, as `flutter test` runs it, and a suite.

    Args:
      name: the suite's name.
      package: the package's name (its pubspec's).
      tests: the test files (a glob of `**/*_test.dart`).
      directory: the package's directory, `packages/<package>` by default;
        its BUILD file declares the package's files as `sources` and
        exports its `pubspec.yaml`.
      srcs: the tree's other Dart files, which tests import (helpers,
        the configurations).
      deps: other files the compiles may read.
      data: what the tests read at run time besides the tree's non-Dart
        files (the package's sources when they read its files).
      packages: workspace packages the tests reach besides flutter,
        flutter_test and the package itself: each one's files to its name,
        as pub_package_config takes them.
      roots: packages whose dependencies the configurations cover besides
        the package and test_core.
      dev_roots: packages whose dev dependencies they cover; the package
        itself by default.
      without: packages of the closure left out (a dev dependency no test
        imports, with what only it reaches); sky_engine always is.
      imports: the libraries compiled into the prelude: FRAMEWORK_IMPORTS by
        default; a package with a library of its own adds it
        (`FRAMEWORK_IMPORTS + ["package:<package>/<package>.dart"]`), an
        application's tests import its programs file by file.
      compile_args: further frontend server arguments for the prelude and
        the tests alike (`-Ddart.vm.product=true` for a tree run with
        `flutter test --dart-define`; a later define overrides the default).
      assets: the package's own asset files, as its pubspec declares them
        (labels in the package's BUILD file; keyed by their paths under
        the package's directory).
      shaders: the asset directory's shaders; the framework's by default.
      cache: the SDK-cache paths; the Dart SDK and the fonts by default.
      test_configs: the tree's `flutter_test_config.dart` and `pubspec.yaml`
        files; a glob of both by default (flutter_tests' test_configs).
      **kwargs: flutter_tests' other arguments (flaky, size, tags, network,
        vm_service).
    """
    package_label = "//" + (directory if directory != None else "packages/" + package)
    workspace_packages = {
        "//packages/flutter:sources": "flutter",
        "//packages/flutter_test:sources": "flutter_test",
    } | {package_label + ":sources": package} | packages
    config_roots = [package, "test_core"] + roots
    config_dev_roots = [package] if dev_roots == None else dev_roots
    config_without = ["sky_engine"] + without
    pub_package_config(
        name = name + "_package_config",
        out = name + "_package_config.json",
        dev_roots = config_dev_roots,
        packages = workspace_packages,
        roots = config_roots,
        without = config_without,
    )
    pub_package_config(
        name = name + "_runtime_package_config",
        out = name + "_runtime_package_config.json",
        dev_roots = config_dev_roots,
        layout = "runfiles",
        packages = workspace_packages,
        roots = config_roots,
        without = config_without,
    )
    flutter_test_assets(
        name = name + "_assets",
        assets = assets,
        assets_root = package_label[2:],
        shaders = shaders,
    )
    flutter_test_prelude(
        name = name + "_prelude",
        imports = FRAMEWORK_IMPORTS if imports == None else imports,
        compile_args = compile_args,
        package_config = ":" + name + "_package_config",
    )
    if test_configs == None:
        test_configs = native.glob(
            [
                "**/flutter_test_config.dart",
                "**/pubspec.yaml",
            ],
            allow_empty = True,
        )
    flutter_tests(
        name = name,
        tests = tests,
        srcs = srcs,
        deps = deps,
        # What a test reads at run time: the tree's files that are not Dart
        # (fixtures), and what the package names.
        data = native.glob(
            ["**"],
            allow_empty = True,
            exclude = [
                "**/*.dart",
                "BUILD.bazel",
            ],
        ) + data,
        app_name = package,
        pubspec = package_label + ":pubspec.yaml",
        assets = ":" + name + "_assets",
        cache = cache,
        package_config = ":" + name + "_package_config",
        prelude = ":" + name + "_prelude",
        runtime_package_config = ":" + name + "_runtime_package_config",
        test_configs = test_configs,
        compile_args = compile_args,
        **kwargs
    )
