# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A directory of package:flutter's tests under Bazel (framework_tests).

What every directory of packages/flutter/test shares, given once:
package:flutter's name and pubspec, the test tree's package
configurations, prelude kernel, asset directory, test configuration and
helpers, and the two SDK-cache paths tests read through FLUTTER_ROOT
(flutter_sdk_cache.bzl). A directory's BUILD file names its tests and
anything of its own.
"""

load("//engine/src/flutter/build/bazel/dart:flutter_test.bzl", "flutter_tests")

def framework_tests(name, tests, data = [], deps = [], **kwargs):
    """One flutter_test per file of `tests`, as `flutter test` runs packages/flutter's, and a suite.

    Args:
      name: the suite's name (the directory's).
      tests: the test files (a glob of `*_test.dart`).
      data: what the tests read at run time besides the directory's non-Dart files.
      deps: other files the compiles may read besides the test tree's helpers.
      **kwargs: flutter_tests' other arguments (flaky, size, tags, network).
    """
    flutter_tests(
        name = name,
        tests = tests,
        app_name = "flutter",
        pubspec = "//packages/flutter:pubspec.yaml",
        assets = "//packages/flutter/test:test_assets",
        # What a test reads at run time: the directory's files that are not
        # Dart, and the SDK cache's two paths (the Dart SDK the engine builds
        # with, the Material fonts).
        data = native.glob(
            ["**"],
            allow_empty = True,
            exclude = [
                "**/*.dart",
                "BUILD.bazel",
            ],
        ) + data,
        cache = {
            "@dart_sdk_linux_x64//:dart": "dart-sdk",
            "@material_fonts//:fonts": "artifacts/material_fonts",
        },
        package_config = "//packages/flutter/test:package_config",
        prelude = "//packages/flutter/test:prelude",
        runtime_package_config = "//packages/flutter/test:runtime_package_config",
        test_config = "//packages/flutter/test:flutter_test_config.dart",
        # The test tree's helpers, this directory's among them.
        deps = ["//packages/flutter/test:helpers"] + deps,
        **kwargs
    )
