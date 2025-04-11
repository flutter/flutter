// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/features.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;
  late Directory projectDir;

  setUpAll(() async {
    // TODO(team-ios): Remove after `explicit-package-dependencies` is enabled by default.
    // See https://github.com/flutter/flutter/issues/160257 for details.
    if (!explicitPackageDependencies.master.enabledByDefault) {
      processManager.runSync(<String>[flutterBin, 'config', '--explicit-package-dependencies']);
    }

    tempDir = createResolvedTempDirectorySync('xcode_dev_dependencies_test.');
    projectDir = tempDir.childDirectory('project')..createSync();
    final Directory tempPluginADir = tempDir.childDirectory('plugin_a')..createSync();

    // Create a Flutter project.
    await processManager.run(<String>[
      flutterBin,
      'create',
      projectDir.path,
      '--project-name=testapp',
    ], workingDirectory: projectDir.path);

    // Create a Flutter plugin to add as a dev dependency to the Flutter project.
    await processManager.run(<String>[
      flutterBin,
      'create',
      tempPluginADir.path,
      '--template=plugin',
      '--project-name=plugin_a',
      '--platforms=ios,macos',
    ], workingDirectory: tempPluginADir.path);

    // Add a dev dependency on plugin_a
    await processManager.run(<String>[
      flutterBin,
      'pub',
      'add',
      'dev:plugin_a',
      '--path',
      tempPluginADir.path,
    ], workingDirectory: projectDir.path);
  });

  tearDownAll(() {
    // TODO(team-ios): Remove after `explicit-package-dependencies` is enabled by default.
    // See https://github.com/flutter/flutter/issues/160257 for details.
    if (!explicitPackageDependencies.master.enabledByDefault) {
      processManager.runSync(<String>[flutterBin, 'config', '--no-explicit-package-dependencies']);
    }

    tryToDelete(tempDir);
  });

  group(
    'Xcode build iOS app',
    () {
      test('succeeds after flutter build ios --config-only', () async {
        final List<String> flutterCommand = <String>[
          flutterBin,
          ...getLocalEngineArguments(),
          'build',
          'ios',
          '--config-only',
          '--debug',
        ];
        final ProcessResult flutterResult = await processManager.run(
          flutterCommand,
          workingDirectory: projectDir.path,
        );

        expect(flutterResult, const ProcessResultMatcher());

        final List<String> xcodeCommand = <String>[
          'xcodebuild',
          '-workspace',
          'ios/Runner.xcworkspace',
          '-scheme',
          'Runner',
          'CODE_SIGNING_ALLOWED=NO',
          'CODE_SIGNING_REQUIRED=NO',
          'CODE_SIGN_IDENTITY=-',
          'EXPANDED_CODE_SIGN_IDENTITY=-',
          'COMPILER_INDEX_STORE_ENABLE=NO',
          'VERBOSE_SCRIPT_LOGGING=true',
          '-configuration',
          'Debug',
        ];
        final ProcessResult xcodeResult = await processManager.run(
          xcodeCommand,
          workingDirectory: projectDir.path,
        );

        expect(xcodeResult, const ProcessResultMatcher(stdoutPattern: '** BUILD SUCCEEDED **'));
      });

      test('fails in Release mode if dev dependencies enabled', () async {
        // Enable dev dependencies by generating debug configuration files
        final List<String> flutterCommand = <String>[
          flutterBin,
          ...getLocalEngineArguments(),
          'build',
          'ios',
          '--config-only',
          '--debug',
        ];
        final ProcessResult flutterResult = await processManager.run(
          flutterCommand,
          workingDirectory: projectDir.path,
        );

        expect(flutterResult, const ProcessResultMatcher());

        // Xcode release build should error that dev dependencies are enabled.
        final List<String> xcodeCommand = <String>[
          'xcodebuild',
          '-workspace',
          'ios/Runner.xcworkspace',
          '-scheme',
          'Runner',
          'CODE_SIGNING_ALLOWED=NO',
          'CODE_SIGNING_REQUIRED=NO',
          'CODE_SIGN_IDENTITY=-',
          'EXPANDED_CODE_SIGN_IDENTITY=-',
          'COMPILER_INDEX_STORE_ENABLE=NO',
          'VERBOSE_SCRIPT_LOGGING=true',
          '-configuration',
          'Release',
        ];
        final ProcessResult xcodeResult = await processManager.run(
          xcodeCommand,
          workingDirectory: projectDir.path,
        );

        expect(
          xcodeResult,
          const ProcessResultMatcher(
            exitCode: 65,
            stdoutPattern: 'Release builds should not have Dart dev dependencies enabled',
            stderrPattern: '** BUILD FAILED **',
          ),
        );
      });

      test('fails in Debug mode if dev dependencies disabled', () async {
        // Disable dev dependencies by generating debug configuration files
        final List<String> flutterCommand = <String>[
          flutterBin,
          ...getLocalEngineArguments(),
          'build',
          'ios',
          '--config-only',
          '--release',
        ];
        final ProcessResult flutterResult = await processManager.run(
          flutterCommand,
          workingDirectory: projectDir.path,
        );

        expect(flutterResult, const ProcessResultMatcher());

        // Xcode debug build should error that dev dependencies are disabled.
        final List<String> xcodeCommand = <String>[
          'xcodebuild',
          '-workspace',
          'ios/Runner.xcworkspace',
          '-scheme',
          'Runner',
          'CODE_SIGNING_ALLOWED=NO',
          'CODE_SIGNING_REQUIRED=NO',
          'CODE_SIGN_IDENTITY=-',
          'EXPANDED_CODE_SIGN_IDENTITY=-',
          'COMPILER_INDEX_STORE_ENABLE=NO',
          'VERBOSE_SCRIPT_LOGGING=true',
          '-configuration',
          'Debug',
        ];
        final ProcessResult xcodeResult = await processManager.run(
          xcodeCommand,
          workingDirectory: projectDir.path,
        );

        expect(
          xcodeResult,
          const ProcessResultMatcher(
            exitCode: 65,
            stdoutPattern: 'Debug builds require Dart dev dependencies',
            stderrPattern: '** BUILD FAILED **',
          ),
        );
      });
    },
    skip: !platform.isMacOS, // [intended] iOS builds only work on macos.
  );

  group(
    'Xcode build iOS module',
    () {
      test('succeeds after flutter build ios --config-only', () async {
        final String appDirectory = fileSystem.path.join(
          getFlutterRoot(),
          'dev',
          'integration_tests',
          'ios_add2app_life_cycle',
        );
        final String moduleDirectory = fileSystem.path.join(appDirectory, 'flutterapp');

        final List<String> flutterCommand = <String>[
          flutterBin,
          ...getLocalEngineArguments(),
          'build',
          'ios',
          '--config-only',
          '--debug',
        ];
        final ProcessResult flutterResult = await processManager.run(
          flutterCommand,
          workingDirectory: moduleDirectory,
        );

        expect(flutterResult, const ProcessResultMatcher());

        final ProcessResult podResult = await processManager.run(
          const <String>['pod', 'install'],
          workingDirectory: appDirectory,
          environment: const <String, String>{'LANG': 'en_US.UTF-8'},
        );

        expect(podResult, const ProcessResultMatcher());

        final List<String> xcodeCommand = <String>[
          'xcodebuild',
          '-workspace',
          'ios_add2app.xcworkspace',
          '-scheme',
          'ios_add2app',
          '-sdk',
          'iphonesimulator',
          'CODE_SIGNING_ALLOWED=NO',
          'CODE_SIGNING_REQUIRED=NO',
          'CODE_SIGN_IDENTITY=-',
          'EXPANDED_CODE_SIGN_IDENTITY=-',
          'COMPILER_INDEX_STORE_ENABLE=NO',
          'VERBOSE_SCRIPT_LOGGING=true',
          '-configuration',
          'Debug',
        ];
        final ProcessResult xcodeResult = await processManager.run(
          xcodeCommand,
          workingDirectory: appDirectory,
        );

        expect(xcodeResult, const ProcessResultMatcher(stdoutPattern: '** BUILD SUCCEEDED **'));
      });

      test('fails in Release mode if dev dependencies enabled', () async {
        final String appDirectory = fileSystem.path.join(
          getFlutterRoot(),
          'dev',
          'integration_tests',
          'ios_add2app_life_cycle',
        );
        final String moduleDirectory = fileSystem.path.join(appDirectory, 'flutterapp');

        // Enable dev dependencies by generating debug configuration files
        final List<String> flutterCommand = <String>[
          flutterBin,
          ...getLocalEngineArguments(),
          'build',
          'ios',
          '--config-only',
          '--debug',
        ];
        final ProcessResult flutterResult = await processManager.run(
          flutterCommand,
          workingDirectory: moduleDirectory,
        );

        expect(flutterResult, const ProcessResultMatcher());

        final ProcessResult podResult = await processManager.run(
          const <String>['pod', 'install'],
          workingDirectory: appDirectory,
          environment: const <String, String>{'LANG': 'en_US.UTF-8'},
        );

        expect(podResult, const ProcessResultMatcher());

        // Xcode release build should error that dev dependencies are enabled.
        final List<String> xcodeCommand = <String>[
          'xcodebuild',
          '-workspace',
          'ios_add2app.xcworkspace',
          '-scheme',
          'ios_add2app',
          '-sdk',
          'iphonesimulator',
          'CODE_SIGNING_ALLOWED=NO',
          'CODE_SIGNING_REQUIRED=NO',
          'CODE_SIGN_IDENTITY=-',
          'EXPANDED_CODE_SIGN_IDENTITY=-',
          'COMPILER_INDEX_STORE_ENABLE=NO',
          'VERBOSE_SCRIPT_LOGGING=true',
          '-configuration',
          'Release',
        ];
        final ProcessResult xcodeResult = await processManager.run(
          xcodeCommand,
          workingDirectory: appDirectory,
        );

        expect(
          xcodeResult,
          const ProcessResultMatcher(
            exitCode: 65,
            stdoutPattern: 'Release builds should not have Dart dev dependencies enabled',
            stderrPattern: '** BUILD FAILED **',
          ),
        );
      });

      test('abc fails in Debug mode if dev dependencies disabled', () async {
        final String appDirectory = fileSystem.path.join(
          getFlutterRoot(),
          'dev',
          'integration_tests',
          'ios_add2app_life_cycle',
        );
        final String moduleDirectory = fileSystem.path.join(appDirectory, 'flutterapp');

        // Disable dev dependencies by generating release configuration files
        final List<String> flutterCommand = <String>[
          flutterBin,
          ...getLocalEngineArguments(),
          'build',
          'ios',
          '--config-only',
          '--release',
        ];
        final ProcessResult flutterResult = await processManager.run(
          flutterCommand,
          workingDirectory: moduleDirectory,
        );

        expect(flutterResult, const ProcessResultMatcher());

        final ProcessResult podResult = await processManager.run(
          const <String>['pod', 'install'],
          workingDirectory: appDirectory,
          environment: const <String, String>{'LANG': 'en_US.UTF-8'},
        );

        expect(podResult, const ProcessResultMatcher());

        // Xcode debug build should error that dev dependencies are disabled.
        final List<String> xcodeCommand = <String>[
          'xcodebuild',
          '-workspace',
          'ios_add2app.xcworkspace',
          '-scheme',
          'ios_add2app',
          '-sdk',
          'iphonesimulator',
          'CODE_SIGNING_ALLOWED=NO',
          'CODE_SIGNING_REQUIRED=NO',
          'CODE_SIGN_IDENTITY=-',
          'EXPANDED_CODE_SIGN_IDENTITY=-',
          'COMPILER_INDEX_STORE_ENABLE=NO',
          'VERBOSE_SCRIPT_LOGGING=true',
          '-configuration',
          'Debug',
        ];
        final ProcessResult xcodeResult = await processManager.run(
          xcodeCommand,
          workingDirectory: appDirectory,
        );

        expect(
          xcodeResult,
          const ProcessResultMatcher(
            exitCode: 65,
            stdoutPattern: 'Debug builds require Dart dev dependencies',
            stderrPattern: '** BUILD FAILED **',
          ),
        );
      });
    },
    skip: !platform.isMacOS, // [intended] iOS builds only work on macos.
  );

  group(
    'Xcode build macOS app',
    () {
      test('succeeds after flutter build macos --config-only', () async {
        final List<String> flutterCommand = <String>[
          flutterBin,
          ...getLocalEngineArguments(),
          'build',
          'macos',
          '--config-only',
          '--debug',
        ];
        final ProcessResult flutterResult = await processManager.run(
          flutterCommand,
          workingDirectory: projectDir.path,
        );

        expect(flutterResult, const ProcessResultMatcher());

        final List<String> xcodeCommand = <String>[
          'xcodebuild',
          '-workspace',
          'macos/Runner.xcworkspace',
          '-scheme',
          'Runner',
          'CODE_SIGNING_ALLOWED=NO',
          'CODE_SIGNING_REQUIRED=NO',
          'CODE_SIGN_IDENTITY=-',
          'EXPANDED_CODE_SIGN_IDENTITY=-',
          'COMPILER_INDEX_STORE_ENABLE=NO',
          'VERBOSE_SCRIPT_LOGGING=true',
          '-configuration',
          'Debug',
        ];
        final ProcessResult xcodeResult = await processManager.run(
          xcodeCommand,
          workingDirectory: projectDir.path,
        );

        expect(xcodeResult, const ProcessResultMatcher(stdoutPattern: '** BUILD SUCCEEDED **'));
      });

      test('fails in Release mode if dev dependencies enabled', () async {
        // Enable dev dependencies by generating debug configuration files
        final List<String> flutterCommand = <String>[
          flutterBin,
          ...getLocalEngineArguments(),
          'build',
          'macos',
          '--config-only',
          '--debug',
        ];
        final ProcessResult flutterResult = await processManager.run(
          flutterCommand,
          workingDirectory: projectDir.path,
        );

        expect(flutterResult, const ProcessResultMatcher());

        // Xcode release build should error that dev dependencies are enabled.
        final List<String> xcodeCommand = <String>[
          'xcodebuild',
          '-workspace',
          'macos/Runner.xcworkspace',
          '-scheme',
          'Runner',
          'CODE_SIGNING_ALLOWED=NO',
          'CODE_SIGNING_REQUIRED=NO',
          'CODE_SIGN_IDENTITY=-',
          'EXPANDED_CODE_SIGN_IDENTITY=-',
          'COMPILER_INDEX_STORE_ENABLE=NO',
          'VERBOSE_SCRIPT_LOGGING=true',
          '-configuration',
          'Release',
        ];
        final ProcessResult xcodeResult = await processManager.run(
          xcodeCommand,
          workingDirectory: projectDir.path,
        );

        expect(
          xcodeResult,
          const ProcessResultMatcher(
            exitCode: 65,
            stdoutPattern: 'error: Release builds should not have Dart dev dependencies enabled',
            stderrPattern: '** BUILD FAILED **',
          ),
        );
      });

      test('fails in Debug mode if dev dependencies disabled', () async {
        // Disable dev dependencies by generating debug configuration files
        final List<String> flutterCommand = <String>[
          flutterBin,
          ...getLocalEngineArguments(),
          'build',
          'macos',
          '--config-only',
          '--release',
        ];
        final ProcessResult flutterResult = await processManager.run(
          flutterCommand,
          workingDirectory: projectDir.path,
        );

        expect(flutterResult, const ProcessResultMatcher());

        // Xcode debug build should error that dev dependencies are disabled.
        final List<String> xcodeCommand = <String>[
          'xcodebuild',
          '-workspace',
          'macos/Runner.xcworkspace',
          '-scheme',
          'Runner',
          'CODE_SIGNING_ALLOWED=NO',
          'CODE_SIGNING_REQUIRED=NO',
          'CODE_SIGN_IDENTITY=-',
          'EXPANDED_CODE_SIGN_IDENTITY=-',
          'COMPILER_INDEX_STORE_ENABLE=NO',
          'VERBOSE_SCRIPT_LOGGING=true',
          '-configuration',
          'Debug',
        ];
        final ProcessResult xcodeResult = await processManager.run(
          xcodeCommand,
          workingDirectory: projectDir.path,
        );

        expect(
          xcodeResult,
          const ProcessResultMatcher(
            exitCode: 65,
            stdoutPattern: 'error: Debug builds require Dart dev dependencies',
            stderrPattern: '** BUILD FAILED **',
          ),
        );
      });
    },
    skip: !platform.isMacOS, // [intended] iOS builds only work on macos.
  );
}
