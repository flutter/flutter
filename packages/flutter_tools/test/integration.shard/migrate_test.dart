// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_data/migrate_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';


void main() {
  Directory tempDir;
  FlutterRunTestDriver flutter;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('run_test.');
    flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    await flutter.stop();
    tryToDelete(tempDir);
  });

  testWithoutContext('simple vanilla migrate process succeeds', () async {
    // Flutter Stable 1.22.6 hash: 9b2d32b605630f28625709ebd9d78ab3016b2bf6
    final MigrateProject project = MigrateProject('vanilla_app_1_22_6_stable');
    await project.setUpIn(tempDir);
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');

    // Init a git repo to test uncommitted changes checks
    await processManager.run(<String>[
      'git',
      'init',
    ], workingDirectory: tempDir.path);
    await processManager.run(<String>[
      'git',
      'checkout',
      '-b',
      'master',
    ], workingDirectory: tempDir.path);
    await processManager.run(<String>[
      'git',
      'add',
      '.',
    ], workingDirectory: tempDir.path);
    await processManager.run(<String>[
      'git',
      'commit',
      '-m',
      '"Initial commit"',
    ], workingDirectory: tempDir.path);

    ProcessResult result = await processManager.run(<String>[
      flutterBin,
      'migrate',
      'apply',
      '--verbose',
    ], workingDirectory: tempDir.path);
    expect(result.exitCode, 1);
    expect(result.stderr.toString(), contains('No migration'));

    result = await processManager.run(<String>[
      flutterBin,
      'migrate',
      'start',
      '--verbose',
    ], workingDirectory: tempDir.path);
    // print(result.stdout);
    expect(result.exitCode, 0);
    expect(result.stdout.toString(), contains('Working directory created at'));
    expect(result.stdout.toString(), contains('''Added files:
[        ]   - macos/Runner.xcworkspace/contents.xcworkspacedata
[        ]   - macos/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist
[        ]   - macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png
[        ]   - macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png
[        ]   - macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png
[        ]   - macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png
[        ]   - macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png
[        ]   - macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png
[        ]   - macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json
[        ]   - macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png
[        ]   - macos/Runner/DebugProfile.entitlements
[        ]   - macos/Runner/Base.lproj/MainMenu.xib
[        ]   - macos/Runner/MainFlutterWindow.swift
[        ]   - macos/Runner/Configs/AppInfo.xcconfig
[        ]   - macos/Runner/Configs/Debug.xcconfig
[        ]   - macos/Runner/Configs/Release.xcconfig
[        ]   - macos/Runner/Configs/Warnings.xcconfig
[        ]   - macos/Runner/AppDelegate.swift
[        ]   - macos/Runner/Info.plist
[        ]   - macos/Runner/Release.entitlements
[        ]   - macos/Runner.xcodeproj/project.pbxproj
[        ]   - macos/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist
[        ]   - macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme
[        ]   - macos/Flutter/Flutter-Debug.xcconfig
[        ]   - macos/Flutter/GeneratedPluginRegistrant.swift
[        ]   - macos/Flutter/Flutter-Release.xcconfig
[        ]   - macos/Flutter/ephemeral/flutter_export_environment.sh
[        ]   - macos/Flutter/ephemeral/Flutter-Generated.xcconfig
[        ]   - macos/.gitignore
[        ]   - macos/.migrate_config
[        ]   - web/index.html
[        ]   - web/favicon.png
[        ]   - web/icons/Icon-192.png
[        ]   - web/icons/Icon-maskable-192.png
[        ]   - web/icons/Icon-maskable-512.png
[        ]   - web/icons/Icon-512.png
[        ]   - web/manifest.json
[        ]   - ios/.migrate_config
[        ]   - linux/main.cc
[        ]   - linux/CMakeLists.txt
[        ]   - linux/my_application.h
[        ]   - linux/my_application.cc
[        ]   - linux/flutter/generated_plugin_registrant.cc
[        ]   - linux/flutter/CMakeLists.txt
[        ]   - linux/flutter/generated_plugins.cmake
[        ]   - linux/flutter/generated_plugin_registrant.h
[        ]   - linux/.gitignore
[        ]   - linux/.migrate_config
[        ]   - android/app/src/main/res/values-night/styles.xml
[        ]   - android/app/src/main/res/drawable-v21/launch_background.xml
[        ]   - android/.migrate_config
[        ]   - .migrate_config
[        ]   - analysis_options.yaml
[        ]   - .dart_tool/package_config_subset
[        ]   - .dart_tool/version
[        ]   - windows/CMakeLists.txt
[        ]   - windows/runner/flutter_window.cpp
[        ]   - windows/runner/utils.h
[        ]   - windows/runner/utils.cpp
[        ]   - windows/runner/runner.exe.manifest
[        ]   - windows/runner/CMakeLists.txt
[        ]   - windows/runner/win32_window.h
[        ]   - windows/runner/win32_window.cpp
[        ]   - windows/runner/resources/app_icon.ico
[        ]   - windows/runner/resource.h
[        ]   - windows/runner/Runner.rc
[        ]   - windows/runner/main.cpp
[        ]   - windows/runner/flutter_window.h
[        ]   - windows/flutter/generated_plugin_registrant.cc
[        ]   - windows/flutter/CMakeLists.txt
[        ]   - windows/flutter/generated_plugins.cmake
[        ]   - windows/flutter/generated_plugin_registrant.h
[        ]   - windows/.gitignore
[        ]   - windows/.migrate_config
[        ] Modified files:
[        ]   - test/widget_test.dart
[        ]   - ios/Runner/Info.plist
[        ]   - ios/Runner.xcodeproj/project.pbxproj
[        ]   - ios/Runner.xcodeproj/project.xcworkspace/contents.xcworkspacedata
[        ]   - ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme
[        ]   - ios/Flutter/AppFrameworkInfo.plist
[        ]   - ios/.gitignore
[        ]   - README.md
[        ]   - pubspec.yaml
[        ]   - .gitignore
[        ]   - android/app/build.gradle
[        ]   - android/app/src/profile/AndroidManifest.xml
[        ]   - android/app/src/main/res/values/styles.xml
[        ]   - android/app/src/main/AndroidManifest.xml
[        ]   - android/app/src/debug/AndroidManifest.xml
[        ]   - android/gradle/wrapper/gradle-wrapper.properties
[        ]   - android/.gitignore
[        ]   - android/build.gradle
[        ]   - lib/main.dart'''));

    // Call apply with conflicts remaining. Should fail.
    result = await processManager.run(<String>[
      flutterBin,
      'migrate',
      'apply',
      '--verbose',
    ], workingDirectory: tempDir.path);
    expect(result.exitCode, 1);
    expect(result.stdout.toString(), contains('''[        ] Unable to apply migration. The following files in the migration working directory still have unresolved conflicts:
[        ]   - .metadata
[        ]   - pubspec.lock'''));

    // Manually resolve conflics.
    File metadataFile = tempDir.childFile('migrate_working_dir/.metadata');
    metadataFile.writeAsStringSync('''
# This file tracks properties of this Flutter project.
# Used by Flutter tool to assess capabilities and perform upgrades etc.
#
# This file should be version controlled and should not be manually edited.

version:
  revision: e96a72392696df66755ca246ff291dfc6ca6c4ad
  channel: unknown

project_type: app

''', flush: true);
    File pubspecLockFile = tempDir.childFile('migrate_working_dir/pubspec.lock');
    pubspecLockFile.writeAsStringSync('''
# Generated by pub
# See https://dart.dev/tools/pub/glossary#lockfile
packages:
  async:
    dependency: transitive
    description:
      name: async
      url: "https://pub.dartlang.org"
    source: hosted
    version: "2.8.2"
  boolean_selector:
    dependency: transitive
    description:
      name: boolean_selector
      url: "https://pub.dartlang.org"
    source: hosted
    version: "2.1.0"
  characters:
    dependency: transitive
    description:
      name: characters
      url: "https://pub.dartlang.org"
    source: hosted
    version: "1.2.0"
  charcode:
    dependency: transitive
    description:
      name: charcode
      url: "https://pub.dartlang.org"
    source: hosted
    version: "1.3.1"
  clock:
    dependency: transitive
    description:
      name: clock
      url: "https://pub.dartlang.org"
    source: hosted
    version: "1.1.0"
  collection:
    dependency: transitive
    description:
      name: collection
      url: "https://pub.dartlang.org"
    source: hosted
    version: "1.15.0"
  cupertino_icons:
    dependency: "direct main"
    description:
      name: cupertino_icons
      url: "https://pub.dartlang.org"
    source: hosted
    version: "1.0.4"
  fake_async:
    dependency: transitive
    description:
      name: fake_async
      url: "https://pub.dartlang.org"
    source: hosted
    version: "1.2.0"
  flutter:
    dependency: "direct main"
    description: flutter
    source: sdk
    version: "0.0.0"
  flutter_lints:
    dependency: "direct dev"
    description:
      name: flutter_lints
      url: "https://pub.dartlang.org"
    source: hosted
    version: "1.0.4"
  flutter_test:
    dependency: "direct dev"
    description: flutter
    source: sdk
    version: "0.0.0"
  lints:
    dependency: transitive
    description:
      name: lints
      url: "https://pub.dartlang.org"
    source: hosted
    version: "1.0.1"
  matcher:
    dependency: transitive
    description:
      name: matcher
      url: "https://pub.dartlang.org"
    source: hosted
    version: "0.12.11"
  material_color_utilities:
    dependency: transitive
    description:
      name: material_color_utilities
      url: "https://pub.dartlang.org"
    source: hosted
    version: "0.1.4"
  meta:
    dependency: transitive
    description:
      name: meta
      url: "https://pub.dartlang.org"
    source: hosted
    version: "1.7.0"
  path:
    dependency: transitive
    description:
      name: path
      url: "https://pub.dartlang.org"
    source: hosted
    version: "1.8.1"
  sky_engine:
    dependency: transitive
    description: flutter
    source: sdk
    version: "0.0.99"
  source_span:
    dependency: transitive
    description:
      name: source_span
      url: "https://pub.dartlang.org"
    source: hosted
    version: "1.8.2"
  stack_trace:
    dependency: transitive
    description:
      name: stack_trace
      url: "https://pub.dartlang.org"
    source: hosted
    version: "1.10.0"
  stream_channel:
    dependency: transitive
    description:
      name: stream_channel
      url: "https://pub.dartlang.org"
    source: hosted
    version: "2.1.0"
  string_scanner:
    dependency: transitive
    description:
      name: string_scanner
      url: "https://pub.dartlang.org"
    source: hosted
    version: "1.1.0"
  term_glyph:
    dependency: transitive
    description:
      name: term_glyph
      url: "https://pub.dartlang.org"
    source: hosted
    version: "1.2.0"
  test_api:
    dependency: transitive
    description:
      name: test_api
      url: "https://pub.dartlang.org"
    source: hosted
    version: "0.4.9"
  typed_data:
    dependency: transitive
    description:
      name: typed_data
      url: "https://pub.dartlang.org"
    source: hosted
    version: "1.3.0"
  vector_math:
    dependency: transitive
    description:
      name: vector_math
      url: "https://pub.dartlang.org"
    source: hosted
    version: "2.1.2"
sdks:
  dart: ">=2.17.0-79.0.dev <3.0.0"

''', flush: true);

    // // Create an uncommitted change
    // File metadataOriginalFile = tempDir.childFile('migrate_working_dir/README.md');
    // String metadataOriginalContents = metadataOriginalFile.readAsStringSync();
    // metadataOriginalFile.writeAsStringSync('$metadataOriginalContents hello extra stuff', flush: true);
    // result = await processManager.run(<String>[
    //   flutterBin,
    //   'migrate',
    //   'apply',
    //   '--verbose',
    // ], workingDirectory: tempDir.path);
    // print(result.stdout);
    // print(result.stderr);
    // // print(tempDir.childFile('flutter_01.log').readAsStringSync());
    // expect(result.exitCode, 1);
    // expect(result.stderr.toString(), contains('There are uncommitted changes in your project. Please commit, abandon, or stash your changes before trying again.'));

    // metadataOriginalFile.writeAsStringSync(metadataOriginalContents, flush: true);

    result = await processManager.run(<String>[
      flutterBin,
      'migrate',
      'apply',
      '--verbose',
    ], workingDirectory: tempDir.path);
    print(result.stdout);
    print(result.stderr);
    expect(result.exitCode, 0);
    expect(result.stdout.toString(), contains('Migration complete'));
  });
}
