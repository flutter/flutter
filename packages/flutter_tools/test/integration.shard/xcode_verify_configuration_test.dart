// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;
  late Directory projectDir;

  setUpAll(() async {
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
    tryToDelete(tempDir);
  });

  group(
    'Xcode build iOS app',
    () {
      test(
        'succeeds when Flutter CLI last used configuration matches Xcode configuration',
        () async {
          final flutterCommand = <String>[
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

          final xcodeCommand = <String>[
            'xcodebuild',
            '-workspace',
            'ios/Runner.xcworkspace',
            '-scheme',
            'Runner',
            '-destination',
            'generic/platform=iOS Simulator',
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
        },
      );

      test(
        'fails if Flutter CLI last used configuration does not match Xcode configuration when archiving',
        () async {
          final flutterCommand = <String>[
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

          final xcodeCommand = <String>[
            'xcodebuild',
            'archive',
            '-workspace',
            'ios/Runner.xcworkspace',
            '-scheme',
            'Runner',
            '-destination',
            'generic/platform=iOS',
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
              stdoutPattern: 'error: Your Flutter project is currently configured for debug mode.',
              stderrPattern: '** ARCHIVE FAILED **',
            ),
          );
        },
      );

      test(
        'warns if Flutter CLI last used configuration does not match Xcode configuration when building',
        () async {
          final flutterCommand = <String>[
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

          final xcodeCommand = <String>[
            'xcodebuild',
            '-workspace',
            'ios/Runner.xcworkspace',
            '-scheme',
            'Runner',
            '-destination',
            'generic/platform=iOS',
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
              stdoutPattern:
                  'warning: Your Flutter project is currently configured for release mode.',
            ),
          );
        },
      );
    },
    skip: !platform.isMacOS, // [intended] iOS builds only work on macos.
  );

  group(
    'Xcode build iOS module',
    () {
      test(
        'succeeds when Flutter CLI last used configuration matches Xcode configuration',
        () async {
          final Directory moduleDirectory = projectDir.childDirectory('hello');
          await processManager.run(<String>[
            flutterBin,
            'create',
            moduleDirectory.path,
            '--template=module',
            '--project-name=hello',
          ], workingDirectory: projectDir.path);

          final flutterCommand = <String>[
            flutterBin,
            ...getLocalEngineArguments(),
            'build',
            'ios',
            '--config-only',
            '--debug',
          ];
          final ProcessResult flutterResult = await processManager.run(
            flutterCommand,
            workingDirectory: moduleDirectory.path,
          );

          expect(flutterResult, const ProcessResultMatcher());

          final Directory hostAppDirectory = projectDir.childDirectory('hello_host_app');
          hostAppDirectory.createSync();

          copyDirectory(
            fileSystem.directory(
              fileSystem.path.join(getFlutterRoot(), 'dev', 'integration_tests', 'ios_host_app'),
            ),
            hostAppDirectory,
          );

          final ProcessResult podResult = await processManager.run(
            const <String>['pod', 'install'],
            workingDirectory: hostAppDirectory.path,
            environment: const <String, String>{'LANG': 'en_US.UTF-8'},
          );

          expect(podResult, const ProcessResultMatcher());

          final xcodeCommand = <String>[
            'xcodebuild',
            '-workspace',
            'Host.xcworkspace',
            '-scheme',
            'Host',
            '-destination',
            'generic/platform=iOS',
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
            workingDirectory: hostAppDirectory.path,
          );

          expect(xcodeResult, const ProcessResultMatcher(stdoutPattern: '** BUILD SUCCEEDED **'));
        },
      );

      test(
        'fails if Flutter CLI last used configuration does not match Xcode configuration when archiving',
        () async {
          final Directory moduleDirectory = projectDir.childDirectory('hello');
          await processManager.run(<String>[
            flutterBin,
            'create',
            moduleDirectory.path,
            '--template=module',
            '--project-name=hello',
          ], workingDirectory: projectDir.path);

          final flutterCommand = <String>[
            flutterBin,
            ...getLocalEngineArguments(),
            'build',
            'ios',
            '--config-only',
            '--debug',
          ];
          final ProcessResult flutterResult = await processManager.run(
            flutterCommand,
            workingDirectory: moduleDirectory.path,
          );

          expect(flutterResult, const ProcessResultMatcher());

          final Directory hostAppDirectory = projectDir.childDirectory('hello_host_app');
          hostAppDirectory.createSync();

          copyDirectory(
            fileSystem.directory(
              fileSystem.path.join(getFlutterRoot(), 'dev', 'integration_tests', 'ios_host_app'),
            ),
            hostAppDirectory,
          );

          final ProcessResult podResult = await processManager.run(
            const <String>['pod', 'install'],
            workingDirectory: hostAppDirectory.path,
            environment: const <String, String>{'LANG': 'en_US.UTF-8'},
          );

          expect(podResult, const ProcessResultMatcher());

          final xcodeCommand = <String>[
            'xcodebuild',
            'archive',
            '-workspace',
            'Host.xcworkspace',
            '-scheme',
            'Host',
            '-destination',
            'generic/platform=iOS',
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
            workingDirectory: hostAppDirectory.path,
          );

          expect(
            xcodeResult,
            const ProcessResultMatcher(
              exitCode: 65,
              stdoutPattern: 'error: Your Flutter project is currently configured for debug mode.',
              stderrPattern: '** ARCHIVE FAILED **',
            ),
          );
        },
      );

      test(
        'warns if Flutter CLI last used configuration does not match Xcode configuration when building',
        () async {
          final Directory moduleDirectory = projectDir.childDirectory('hello');
          await processManager.run(<String>[
            flutterBin,
            'create',
            moduleDirectory.path,
            '--template=module',
            '--project-name=hello',
          ], workingDirectory: projectDir.path);

          final flutterCommand = <String>[
            flutterBin,
            ...getLocalEngineArguments(),
            'build',
            'ios',
            '--config-only',
          ];
          final ProcessResult flutterResult = await processManager.run(
            flutterCommand,
            workingDirectory: moduleDirectory.path,
          );

          expect(flutterResult, const ProcessResultMatcher());

          final Directory hostAppDirectory = projectDir.childDirectory('hello_host_app');
          hostAppDirectory.createSync();

          copyDirectory(
            fileSystem.directory(
              fileSystem.path.join(getFlutterRoot(), 'dev', 'integration_tests', 'ios_host_app'),
            ),
            hostAppDirectory,
          );

          final ProcessResult podResult = await processManager.run(
            const <String>['pod', 'install'],
            workingDirectory: hostAppDirectory.path,
            environment: const <String, String>{'LANG': 'en_US.UTF-8'},
          );

          expect(podResult, const ProcessResultMatcher());

          final xcodeCommand = <String>[
            'xcodebuild',
            '-workspace',
            'Host.xcworkspace',
            '-scheme',
            'Host',
            '-destination',
            'generic/platform=iOS',
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
            workingDirectory: hostAppDirectory.path,
          );

          expect(
            xcodeResult,
            const ProcessResultMatcher(
              stdoutPattern:
                  'warning: Your Flutter project is currently configured for release mode.',
            ),
          );
        },
      );
    },
    skip: !platform.isMacOS, // [intended] iOS builds only work on macos.
  );

  group(
    'Xcode build macOS app',
    () {
      test(
        'succeeds when Flutter CLI last used configuration matches Xcode configuration',
        () async {
          final flutterCommand = <String>[
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

          final xcodeCommand = <String>[
            'xcodebuild',
            '-workspace',
            'macos/Runner.xcworkspace',
            '-scheme',
            'Runner',
            '-destination',
            'platform=macOS',
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
        },
      );

      test(
        'fails if Flutter CLI last used configuration does not match Xcode configuration when archiving',
        () async {
          final flutterCommand = <String>[
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

          final xcodeCommand = <String>[
            'xcodebuild',
            'archive',
            '-workspace',
            'macos/Runner.xcworkspace',
            '-scheme',
            'Runner',
            '-destination',
            'platform=macOS',
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
              stdoutPattern: 'error: Your Flutter project is currently configured for debug mode.',
              stderrPattern: '** ARCHIVE FAILED **',
            ),
          );
        },
      );

      test(
        'warns if Flutter CLI last used configuration does not match Xcode configuration when building',
        () async {
          final flutterCommand = <String>[
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

          final xcodeCommand = <String>[
            'xcodebuild',
            '-workspace',
            'macos/Runner.xcworkspace',
            '-scheme',
            'Runner',
            '-destination',
            'platform=macOS',
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
              stdoutPattern:
                  'warning: Your Flutter project is currently configured for release mode.',
            ),
          );
        },
      );
    },
    skip: !platform.isMacOS, // [intended] iOS builds only work on macos.
  );
}
