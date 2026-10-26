# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""What flutter_tools writes into a project it runs in, for the globs of the projects tests copy.

`flutter run`, `flutter test` and `flutter build` in a project's directory
leave files behind that git ignores: pub's `.dart_tool/`, `build/`, and
the platform tooling the tool regenerates each time -- `android/local.properties`,
the generated plugin registrants, the `ephemeral/` directories, iOS's
`Generated.xcconfig`. The projects the tool's integration tests copy or run
in (examples/hello_world, dev/integration_tests/*) are `filegroup`s of
globs over the source tree, so after a developer's `flutter test` in one of
them those files would be in the runfiles too -- read-only symlinks into
the source tree -- and the tool under test, rewriting
`android/local.properties`, fails with "the file system is read-only".
Every such filegroup excludes FLUTTER_PROJECT_GENERATED.
"""

FLUTTER_PROJECT_GENERATED = [
    "**/.dart_tool/**",
    "build/**",
    ".flutter-plugins-dependencies",
    "android/local.properties",
    "android/app/src/main/java/io/flutter/plugins/**",
    "ios/Flutter/Generated.xcconfig",
    "ios/Flutter/flutter_export_environment.sh",
    "ios/Runner/GeneratedPluginRegistrant.*",
    "macos/Flutter/GeneratedPluginRegistrant.swift",
    "**/ephemeral/**",
    "**/generated_plugin_registrant.*",
    "**/generated_plugins.cmake",
]
