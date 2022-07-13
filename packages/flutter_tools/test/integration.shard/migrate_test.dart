// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/migrate/migrate_compute.dart';
import 'package:flutter_tools/src/migrate/migrate_result.dart';
import 'package:flutter_tools/src/migrate/migrate_utils.dart';
import 'package:flutter_tools/src/project.dart';

import '../src/common.dart';
import '../src/context.dart';
import 'test_data/migrate_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';


void main() {
  Directory tempDir;
  FlutterRunTestDriver flutter;
  BufferLogger logger;
  MigrateUtils utils;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('run_test.');
    flutter = FlutterRunTestDriver(tempDir);
    logger = BufferLogger.test();
    utils = MigrateUtils(
      logger: logger,
      fileSystem: fileSystem,
      platform: globals.platform,
      processManager: globals.processManager,
    );
  });

  tearDown(() async {
    await flutter.stop();
    tryToDelete(tempDir);
  });

  // Migrates a clean untouched app generated with flutter create
  testUsingContext('vanilla migrate process succeeds', () async {
    // Flutter Stable 1.22.6 hash: 9b2d32b605630f28625709ebd9d78ab3016b2bf6
    await MigrateProject.installProject('version:1.22.6_stable', tempDir);
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');

    ProcessResult result = await processManager.run(<String>[
      flutterBin,
      'migrate',
      'start',
      '--verbose',
    ], workingDirectory: tempDir.path);
    expect(result.stdout.toString(), contains('Working directory created at'));
    expect(result.stdout.toString(), contains('''Added files:
             - android/app/src/main/res/values-night/styles.xml
             - android/app/src/main/res/drawable-v21/launch_background.xml
             - analysis_options.yaml
           Modified files:
             - .metadata
             - ios/Runner/Info.plist
             - ios/Runner.xcodeproj/project.xcworkspace/contents.xcworkspacedata
             - ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme
             - ios/Flutter/AppFrameworkInfo.plist
             - ios/.gitignore
             - pubspec.yaml
             - .gitignore
             - android/app/build.gradle
             - android/app/src/profile/AndroidManifest.xml
             - android/app/src/main/res/values/styles.xml
             - android/app/src/main/AndroidManifest.xml
             - android/app/src/debug/AndroidManifest.xml
             - android/gradle/wrapper/gradle-wrapper.properties
             - android/.gitignore
             - android/build.gradle'''));

    result = await processManager.run(<String>[
      flutterBin,
      'migrate',
      'apply',
      '--verbose',
    ], workingDirectory: tempDir.path);
    logger.printStatus('${result.exitCode}', color: TerminalColor.blue);
    logger.printStatus(result.stdout, color: TerminalColor.green);
    logger.printStatus(result.stderr, color: TerminalColor.red);
    expect(result.exitCode, 0);
    expect(result.stdout.toString(), contains('Migration complete'));

    expect(tempDir.childFile('.metadata').readAsStringSync(), contains('migration:\n  platforms:\n    - platform: root\n'));

    expect(tempDir.childFile('android/app/src/main/res/values-night/styles.xml').existsSync(), true);
    expect(tempDir.childFile('analysis_options.yaml').existsSync(), true);
  });

  // Migrates a clean untouched app generated with flutter create
  testUsingContext('vanilla migrate builds', () async {
    // Flutter Stable 2.0.0 hash: 60bd88df915880d23877bfc1602e8ddcf4c4dd2a
    await MigrateProject.installProject('version:2.0.0_stable', tempDir, main: '''
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Container(),
    );
  }
}
''');
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');

    ProcessResult result = await processManager.run(<String>[
      flutterBin,
      'migrate',
      'start',
      '--verbose',
    ], workingDirectory: tempDir.path);
    expect(result.stdout.toString(), contains('Working directory created at'));

    result = await processManager.run(<String>[
      flutterBin,
      'migrate',
      'apply',
      '--verbose',
    ], workingDirectory: tempDir.path);
    logger.printStatus('${result.exitCode}', color: TerminalColor.blue);
    logger.printStatus(result.stdout, color: TerminalColor.green);
    logger.printStatus(result.stderr, color: TerminalColor.red);
    expect(result.exitCode, 0);
    expect(result.stdout.toString(), contains('Migration complete'));

    result = await processManager.run(<String>[
      flutterBin,
      'build',
      'apk',
      '--debug',
    ], workingDirectory: tempDir.path);
    expect(result.exitCode, 0);
    expect(result.stdout.toString(), contains('app-debug.apk'));
  });

  testUsingContext('migrate abandon', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');

    // Abandon in an empty dir fails.
    ProcessResult result = await processManager.run(<String>[
      flutterBin,
      'migrate',
      'abandon',
      '--verbose',
    ], workingDirectory: tempDir.path);
    expect(result.exitCode, 1);
    expect(result.stderr.toString(), contains('Error: No pubspec.yaml file found'));
    expect(result.stderr.toString(), contains('This command should be run from the root of your Flutter project'));

    final File manifestFile = tempDir.childFile('migrate_working_dir/.migrate_manifest');
    expect(manifestFile.existsSync(), false);

    // Flutter Stable 1.22.6 hash: 9b2d32b605630f28625709ebd9d78ab3016b2bf6
    await MigrateProject.installProject('version:1.22.6_stable', tempDir);

    // Initialized repo fails.
    result = await processManager.run(<String>[
      flutterBin,
      'migrate',
      'abandon',
      '--verbose',
    ], workingDirectory: tempDir.path);
    expect(result.exitCode, 0);
    expect(result.stdout.toString(), contains('No migration'));

    // Create migration.
    manifestFile.createSync(recursive: true);

    // Directory with manifest_working_dir succeeds.
    result = await processManager.run(<String>[
      flutterBin,
      'migrate',
      'abandon',
      '--verbose',
    ], workingDirectory: tempDir.path);
    expect(result.exitCode, 0);
    expect(result.stdout.toString(), contains('Abandon complete'));
  });

  testUsingContext('migrate compute', () async {
    // Flutter Stable 1.22.6 hash: 9b2d32b605630f28625709ebd9d78ab3016b2bf6
    await MigrateProject.installProject('version:1.22.6_stable', tempDir);

    final FlutterProjectFactory flutterFactory = FlutterProjectFactory(logger: logger, fileSystem: fileSystem);
    final FlutterProject flutterProject = flutterFactory.fromDirectory(tempDir);

    final MigrateResult result = await computeMigration(
      verbose: true,
      flutterProject: flutterProject,
      deleteTempDirectories: false,
      fileSystem: fileSystem,
      logger: logger,
      migrateUtils: utils,
    );
    expect(result.sdkDirs.length, equals(1));
    expect(result.deletedFiles.isEmpty, true);
    expect(result.addedFiles.isEmpty, false);
    expect(result.mergeResults.isEmpty, false);
    expect(result.generatedBaseTemplateDirectory, isNotNull);
    expect(result.generatedTargetTemplateDirectory, isNotNull);
  });

  // Migrates a user-modified app
  testUsingContext('modified migrate process succeeds', () async {
    // Flutter Stable 1.22.6 hash: 9b2d32b605630f28625709ebd9d78ab3016b2bf6
    await MigrateProject.installProject('version:1.22.6_stable', tempDir, vanilla: false);
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');

    ProcessResult result = await processManager.run(<String>[
      flutterBin,
      'migrate',
      'apply',
      '--verbose',
    ], workingDirectory: tempDir.path);
    expect(result.exitCode, 0);
    expect(result.stdout.toString(), contains('No migration'));

    result = await processManager.run(<String>[
      flutterBin,
      'migrate',
      'status',
      '--verbose',
    ], workingDirectory: tempDir.path);
    expect(result.exitCode, 0);
    expect(result.stdout.toString(), contains('No migration'));

    result = await processManager.run(<String>[
      flutterBin,
      'migrate',
      'start',
      '--verbose',
    ], workingDirectory: tempDir.path);
    expect(result.exitCode, 0);
    expect(result.stdout.toString(), contains('Working directory created at'));
    expect(result.stdout.toString(), contains('''Modified files:
             - .metadata
             - ios/Runner/Info.plist
             - ios/Runner.xcodeproj/project.xcworkspace/contents.xcworkspacedata
             - ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme
             - ios/Flutter/AppFrameworkInfo.plist
             - ios/.gitignore
             - .gitignore
             - android/app/build.gradle
             - android/app/src/profile/AndroidManifest.xml
             - android/app/src/main/res/values/styles.xml
             - android/app/src/main/AndroidManifest.xml
             - android/app/src/debug/AndroidManifest.xml
             - android/gradle/wrapper/gradle-wrapper.properties
             - android/.gitignore
             - android/build.gradle
           Merge conflicted files:
[        ]   - pubspec.yaml'''));

    // Call apply with conflicts remaining. Should fail.
    result = await processManager.run(<String>[
      flutterBin,
      'migrate',
      'apply',
      '--verbose',
    ], workingDirectory: tempDir.path);
    expect(result.exitCode, 0);
    expect(result.stdout.toString(), contains('Conflicting files found. Resolve these conflicts and try again.'));
    expect(result.stdout.toString(), contains(']   - pubspec.yaml'));

    result = await processManager.run(<String>[
      flutterBin,
      'migrate',
      'status',
      '--verbose',
    ], workingDirectory: tempDir.path);
    expect(result.exitCode, 0);
    expect(result.stdout.toString(), contains('Modified files'));
    expect(result.stdout.toString(), contains('Merge conflicted files'));

    // Manually resolve conflics. The correct contents for resolution may change over time,
    // but it shouldnt matter for this test.
    final File metadataFile = tempDir.childFile('migrate_working_dir/.metadata');
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
    final File pubspecYamlFile = tempDir.childFile('migrate_working_dir/pubspec.yaml');
    pubspecYamlFile.writeAsStringSync('''
name: vanilla_app_1_22_6_stable
description: This is a modified description from the default.

# The following line prevents the package from being accidentally published to
# pub.dev using `flutter pub publish`. This is preferred for private packages.
publish_to: 'none' # Remove this line if you wish to publish to pub.dev

# The following defines the version and build number for your application.
# A version number is three numbers separated by dots, like 1.2.43
# followed by an optional build number separated by a +.
# Both the version and the builder number may be overridden in flutter
# build by specifying --build-name and --build-number, respectively.
# In Android, build-name is used as versionName while build-number used as versionCode.
# Read more about Android versioning at https://developer.android.com/studio/publish/versioning
# In iOS, build-name is used as CFBundleShortVersionString while build-number used as CFBundleVersion.
# Read more about iOS versioning at
# https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html
version: 1.0.0+1

environment:
  sdk: ">=2.17.0-79.0.dev <3.0.0"

# Dependencies specify other packages that your package needs in order to work.
# To automatically upgrade your package dependencies to the latest versions
# consider running `flutter pub upgrade --major-versions`. Alternatively,
# dependencies can be manually updated by changing the version numbers below to
# the latest version available on pub.dev. To see which dependencies have newer
# versions available, run `flutter pub outdated`.
dependencies:
  flutter:
    sdk: flutter


  # The following adds the Cupertino Icons font to your application.
  # Use with the CupertinoIcons class for iOS style icons.
  cupertino_icons: ^1.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter

  # The "flutter_lints" package below contains a set of recommended lints to
  # encourage good coding practices. The lint set provided by the package is
  # activated in the `analysis_options.yaml` file located at the root of your
  # package. See that file for information about deactivating specific lint
  # rules and activating additional ones.
  flutter_lints: ^1.0.0

# For information on the generic Dart part of this file, see the
# following page: https://dart.dev/tools/pub/pubspec

# The following section is specific to Flutter packages.
flutter:

  # The following line ensures that the Material Icons font is
  # included with your application, so that you can use the icons in
  # the material Icons class.
  uses-material-design: true

  # To add assets to your application, add an assets section, like this:
  assets:
    - images/a_dot_burr.jpeg
    - images/a_dot_ham.jpeg

  # An image asset can refer to one or more resolution-specific "variants", see
  # https://flutter.dev/assets-and-images/#resolution-aware.

  # For details regarding adding assets from package dependencies, see
  # https://flutter.dev/assets-and-images/#from-packages

  # To add custom fonts to your application, add a fonts section here,
  # in this "flutter" section. Each entry in this list should have a
  # "family" key with the font family name, and a "fonts" key with a
  # list giving the asset and other descriptors for the font. For
  # example:
  # fonts:
  #   - family: Schyler
  #     fonts:
  #       - asset: fonts/Schyler-Regular.ttf
  #       - asset: fonts/Schyler-Italic.ttf
  #         style: italic
  #   - family: Trajan Pro
  #     fonts:
  #       - asset: fonts/TrajanPro.ttf
  #       - asset: fonts/TrajanPro_Bold.ttf
  #         weight: 700
  #
  # For details regarding fonts from package dependencies,
  # see https://flutter.dev/custom-fonts/#from-packages

''', flush: true);

    result = await processManager.run(<String>[
      flutterBin,
      'migrate',
      'status',
      '--verbose',
    ], workingDirectory: tempDir.path);
    expect(result.exitCode, 0);
    expect(result.stdout.toString(), contains('Modified files'));
    expect(result.stdout.toString(), contains('diff --git'));
    expect(result.stdout.toString(), contains('@@'));
    expect(result.stdout.toString(), isNot(contains('Merge conflicted files')));

    result = await processManager.run(<String>[
      flutterBin,
      'migrate',
      'apply',
      '--verbose',
    ], workingDirectory: tempDir.path);
    expect(result.exitCode, 0);
    expect(result.stdout.toString(), contains('Migration complete'));

    expect(tempDir.childFile('.metadata').readAsStringSync(), contains('e96a72392696df66755ca246ff291dfc6ca6c4ad'));
    expect(tempDir.childFile('pubspec.yaml').readAsStringSync(), isNot(contains('">=2.6.0 <3.0.0"')));
    expect(tempDir.childFile('pubspec.yaml').readAsStringSync(), contains('">=2.17.0-79.0.dev <3.0.0"'));
    expect(tempDir.childFile('pubspec.yaml').readAsStringSync(), contains('description: This is a modified description from the default.'));
    expect(tempDir.childFile('lib/main.dart').readAsStringSync(), contains('OtherWidget()'));
    expect(tempDir.childFile('lib/other.dart').existsSync(), true);
    expect(tempDir.childFile('lib/other.dart').readAsStringSync(), contains('class OtherWidget'));

    expect(tempDir.childFile('android/app/src/main/res/values-night/styles.xml').existsSync(), true);
    expect(tempDir.childFile('analysis_options.yaml').existsSync(), true);
  });
}
