// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  final String flutterBin = fileSystem.path.join(
    getFlutterRoot(),
    'bin',
    'flutter',
  );

  final List<String> platforms = <String>['ios', 'macos'];
  for (final String platformName in platforms) {
    final List<String> iosLanguages = <String>[
      if (platformName == 'ios') 'objc',
      'swift',
    ];
    final _Plugin integrationTestPlugin = _integrationTestPlugin(platformName);

    for (final String iosLanguage in iosLanguages) {
      test('Swift Package Manager not used when feature is disabled for $platformName with $iosLanguage', () async {
        final Directory workingDirectory = fileSystem.systemTempDirectory
            .createTempSync('swift_package_manager_disabled.');
        final String workingDirectoryPath = workingDirectory.path;
        try {
          await _disableSwiftPackageManager(flutterBin, workingDirectoryPath);

          // Create and build an app using the CocoaPods version of
          // integration_test.
          final String appDirectoryPath = await _createApp(
            flutterBin,
            workingDirectoryPath,
            iosLanguage: iosLanguage,
            platform: platformName,
            options: <String>['--platforms=$platformName'],
          );
          _addDependency(
            appDirectoryPath: appDirectoryPath,
            plugin: integrationTestPlugin,
          );
          await _buildApp(
            flutterBin,
            appDirectoryPath,
            options: <String>[platformName, '--debug', '-v'],
            expectedLines: _expectedLines(
              platform: platformName,
              appDirectoryPath: appDirectoryPath,
              cococapodsPlugin: integrationTestPlugin,
            ),
            unexpectedLines: _unexpectedLines(
              platform: platformName,
              appDirectoryPath: appDirectoryPath,
              cococapodsPlugin: integrationTestPlugin,
            ),
          );
          expect(
            fileSystem
                .directory(appDirectoryPath)
                .childDirectory(platformName)
                .childFile('Podfile')
                .existsSync(),
            isTrue,
          );
          expect(
            fileSystem
                .directory(appDirectoryPath)
                .childDirectory(platformName)
                .childDirectory('Flutter')
                .childDirectory('ephemeral')
                .childDirectory('Packages')
                .childDirectory('FlutterGeneratedPluginSwiftPackage')
                .existsSync(),
            isFalse,
          );
        } finally {
          ErrorHandlingFileSystem.deleteIfExists(
            workingDirectory,
            recursive: true,
          );
        }
      }, skip: !platform.isMacOS); // [intended] Swift Package Manager only works on macos.

      test('Swift Package Manager integration for $platformName with $iosLanguage', () async {
        final Directory workingDirectory = fileSystem.systemTempDirectory
            .createTempSync('swift_package_manager_enabled.');
        final String workingDirectoryPath = workingDirectory.path;
        try {
          // Create and build an app using the Swift Package Manager version of
          // integration_test.
          await _enableSwiftPackageManager(flutterBin, workingDirectoryPath);

          final String appDirectoryPath = await _createApp(
            flutterBin,
            workingDirectoryPath,
            iosLanguage: iosLanguage,
            platform: platformName,
            usesSwiftPackageManager: true,
            options: <String>['--platforms=$platformName'],
          );
          _addDependency(appDirectoryPath: appDirectoryPath, plugin: integrationTestPlugin);
          await _buildApp(
            flutterBin,
            appDirectoryPath,
            options: <String>[platformName, '--debug', '-v'],
            expectedLines: _expectedLines(
              platform: platformName,
              appDirectoryPath: appDirectoryPath,
              swiftPackageMangerEnabled: true,
              swiftPackagePlugin: integrationTestPlugin,
            ),
            unexpectedLines: _unexpectedLines(
              platform: platformName,
              appDirectoryPath: appDirectoryPath,
              swiftPackageMangerEnabled: true,
              swiftPackagePlugin: integrationTestPlugin,
            ),
          );

          expect(
            fileSystem
                .directory(appDirectoryPath)
                .childDirectory(platformName)
                .childFile('Podfile')
                .existsSync(),
            isFalse,
          );
          expect(
            fileSystem
                .directory(appDirectoryPath)
                .childDirectory(platformName)
                .childDirectory('Flutter')
                .childDirectory('ephemeral')
                .childDirectory('Packages')
                .childDirectory('FlutterGeneratedPluginSwiftPackage')
                .existsSync(),
            isTrue,
          );

          // Build an app using both a CocoaPods and Swift Package Manager plugin.
          await _cleanApp(flutterBin, appDirectoryPath);
          final _Plugin createdCocoaPodsPlugin = await _createPlugin(
            flutterBin,
            workingDirectoryPath,
            platform: platformName,
            iosLanguage: iosLanguage,
          );
          _addDependency(
            appDirectoryPath: appDirectoryPath,
            plugin: createdCocoaPodsPlugin,
          );
          await _buildApp(
            flutterBin,
            appDirectoryPath,
            options: <String>[platformName, '--debug', '-v'],
            expectedLines: _expectedLines(
              platform: platformName,
              appDirectoryPath: appDirectoryPath,
              cococapodsPlugin: createdCocoaPodsPlugin,
              swiftPackageMangerEnabled: true,
              swiftPackagePlugin: integrationTestPlugin,
            ),
            unexpectedLines: _unexpectedLines(
              platform: platformName,
              appDirectoryPath: appDirectoryPath,
              cococapodsPlugin: createdCocoaPodsPlugin,
              swiftPackageMangerEnabled: true,
              swiftPackagePlugin: integrationTestPlugin,
            ),
          );

          expect(
            fileSystem
                .directory(appDirectoryPath)
                .childDirectory(platformName)
                .childFile('Podfile')
                .existsSync(),
            isTrue,
          );
          expect(
            fileSystem
                .directory(appDirectoryPath)
                .childDirectory(platformName)
                .childDirectory('Flutter')
                .childDirectory('ephemeral')
                .childDirectory('Packages')
                .childDirectory('FlutterGeneratedPluginSwiftPackage')
                .existsSync(),
            isTrue,
          );

          // Build app again but with Swift Package Manager disabled by config.
          // App will now use CocoaPods version of integration_test plugin.
          await _disableSwiftPackageManager(flutterBin, workingDirectoryPath);
          await _cleanApp(flutterBin, appDirectoryPath);
          await _buildApp(
            flutterBin,
            appDirectoryPath,
            options: <String>[platformName, '--debug', '-v'],
            expectedLines: _expectedLines(
              platform: platformName,
              appDirectoryPath: appDirectoryPath,
              cococapodsPlugin: integrationTestPlugin,
            ),
            unexpectedLines: _unexpectedLines(
              platform: platformName,
              appDirectoryPath: appDirectoryPath,
              cococapodsPlugin: integrationTestPlugin,
            ),
          );

          // Build app again but with Swift Package Manager disabled by pubspec.
          // App will still use CocoaPods version of integration_test plugin.
          await _enableSwiftPackageManager(flutterBin, workingDirectoryPath);
          await _cleanApp(flutterBin, appDirectoryPath);
          _disableSwiftPackageManagerByPubspec(appDirectoryPath: appDirectoryPath);
          await _buildApp(
            flutterBin,
            appDirectoryPath,
            options: <String>[platformName, '--debug', '-v'],
            expectedLines: _expectedLines(
              platform: platformName,
              appDirectoryPath: appDirectoryPath,
              cococapodsPlugin: integrationTestPlugin,
            ),
            unexpectedLines: _unexpectedLines(
              platform: platformName,
              appDirectoryPath: appDirectoryPath,
              cococapodsPlugin: integrationTestPlugin,
            ),
          );
        } finally {
          await _disableSwiftPackageManager(flutterBin, workingDirectoryPath);
          ErrorHandlingFileSystem.deleteIfExists(
            workingDirectory,
            recursive: true,
          );
        }
      }, skip: !platform.isMacOS); // [intended] Swift Package Manager only works on macos.
    }

    test('Build $platformName-framework with non-module app uses CocoaPods', () async {
      final Directory workingDirectory = fileSystem.systemTempDirectory
          .createTempSync('swift_package_manager_build_framework.');
      final String workingDirectoryPath = workingDirectory.path;
      try {
        // Create and build an app using the Swift Package Manager version of
        // integration_test.
        await _enableSwiftPackageManager(flutterBin, workingDirectoryPath);

        final String appDirectoryPath = await _createApp(
          flutterBin,
          workingDirectoryPath,
          iosLanguage: 'swift',
          platform: platformName,
          usesSwiftPackageManager: true,
          options: <String>['--platforms=$platformName'],
        );
        _addDependency(appDirectoryPath: appDirectoryPath, plugin: integrationTestPlugin);

        await _buildApp(
          flutterBin,
          appDirectoryPath,
          options: <String>[platformName, '--config-only', '-v'],
          expectedLines: <String>[
            'Adding Swift Package Manager integration...'
          ]
        );

        expect(
          fileSystem
              .directory(appDirectoryPath)
              .childDirectory(platformName)
              .childFile('Podfile')
              .existsSync(),
          isFalse,
        );
        expect(
          fileSystem
              .directory(appDirectoryPath)
              .childDirectory(platformName)
              .childDirectory('Flutter')
              .childDirectory('ephemeral')
              .childDirectory('Packages')
              .childDirectory('FlutterGeneratedPluginSwiftPackage')
              .existsSync(),
          isTrue,
        );

        // Create and build framework using the CocoaPods version of
        // integration_test even though Swift Package Manager is enabled.
        await _buildApp(
          flutterBin,
          appDirectoryPath,
          options: <String>[
            '$platformName-framework',
            '--no-debug',
            '--no-profile',
            '-v',
          ],
          expectedLines: <String>[
            'Swift Package Manager does not yet support this command. CocoaPods will be used instead.'
          ]
        );

        expect(
          fileSystem
              .directory(appDirectoryPath)
              .childDirectory('build')
              .childDirectory(platformName)
              .childDirectory('framework')
              .childDirectory('Release')
              .childDirectory('${integrationTestPlugin.pluginName}.xcframework')
              .existsSync(),
          isTrue,
        );
      } finally {
        await _disableSwiftPackageManager(flutterBin, workingDirectoryPath);
        ErrorHandlingFileSystem.deleteIfExists(
          workingDirectory,
          recursive: true,
        );
      }
    }, skip: !platform.isMacOS); // [intended] Swift Package Manager only works on macos.
  }

  test('Build ios-framework with module app uses CocoaPods', () async {
    final Directory workingDirectory = fileSystem.systemTempDirectory
        .createTempSync('swift_package_manager_build_framework_module.');
    final String workingDirectoryPath = workingDirectory.path;
    try {
      // Create and build module and framework using the CocoaPods version of
      // integration_test even though Swift Package Manager is enabled.
      await _enableSwiftPackageManager(flutterBin, workingDirectoryPath);

      final String appDirectoryPath = await _createApp(
        flutterBin,
        workingDirectoryPath,
        iosLanguage: 'swift',
        platform: 'ios',
        usesSwiftPackageManager: true,
        options: <String>['--template=module'],
      );
      final _Plugin integrationTestPlugin = _integrationTestPlugin('ios');
      _addDependency(appDirectoryPath: appDirectoryPath, plugin: integrationTestPlugin);

      await _buildApp(
        flutterBin,
        appDirectoryPath,
        options: <String>['ios', '--config-only', '-v'],
        unexpectedLines: <String>[
          'Adding Swift Package Manager integration...'
        ]
      );

      expect(
        fileSystem
            .directory(appDirectoryPath)
            .childDirectory('.ios')
            .childFile('Podfile')
            .existsSync(),
        isTrue,
      );
      expect(
        fileSystem
            .directory(appDirectoryPath)
            .childDirectory('.ios')
            .childDirectory('Flutter')
            .childDirectory('ephemeral')
            .childDirectory('Packages')
            .childDirectory('FlutterGeneratedPluginSwiftPackage')
            .existsSync(),
        isFalse,
      );

      await _buildApp(
        flutterBin,
        appDirectoryPath,
        options: <String>[
          'ios-framework',
          '--no-debug',
          '--no-profile',
          '-v',
        ],
        unexpectedLines: <String>[
          'Adding Swift Package Manager integration...',
          'Swift Package Manager does not yet support this command. CocoaPods will be used instead.'
        ]
      );

      expect(
        fileSystem
            .directory(appDirectoryPath)
            .childDirectory('build')
            .childDirectory('ios')
            .childDirectory('framework')
            .childDirectory('Release')
            .childDirectory('${integrationTestPlugin.pluginName}.xcframework')
            .existsSync(),
        isTrue,
      );
    } finally {
      await _disableSwiftPackageManager(flutterBin, workingDirectoryPath);
      ErrorHandlingFileSystem.deleteIfExists(
        workingDirectory,
        recursive: true,
      );
    }
  }, skip: !platform.isMacOS); // [intended] Swift Package Manager only works on macos.
}

Future<void> _enableSwiftPackageManager(
  String flutterBin,
  String workingDirectory,
) async {
  final ProcessResult result = await processManager.run(
    <String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'config',
      '--enable-swift-package-manager',
      '-v',
    ],
    workingDirectory: workingDirectory,
  );
  expect(
    result.exitCode,
    0,
    reason: 'Failed to enable Swift Package Manager: \n'
        'stdout: \n${result.stdout}\n'
        'stderr: \n${result.stderr}\n',
    verbose: true,
  );
}

Future<void> _disableSwiftPackageManager(
  String flutterBin,
  String workingDirectory,
) async {
  final ProcessResult result = await processManager.run(
    <String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'config',
      '--no-enable-swift-package-manager',
      '-v',
    ],
    workingDirectory: workingDirectory,
  );
  expect(
    result.exitCode,
    0,
    reason: 'Failed to disable Swift Package Manager: \n'
        'stdout: \n${result.stdout}\n'
        'stderr: \n${result.stderr}\n',
    verbose: true,
  );
}

Future<String> _createApp(
  String flutterBin,
  String workingDirectory, {
  required String platform,
  required String iosLanguage,
  required List<String> options,
  bool usesSwiftPackageManager = false,
}) async {
  final String appTemplateType = usesSwiftPackageManager ? 'spm' : 'default';

  final String appName = '${platform}_${iosLanguage}_${appTemplateType}_app';
  final ProcessResult result = await processManager.run(
    <String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'create',
      '--org',
      'io.flutter.devicelab',
      '-i',
      iosLanguage,
      ...options,
      appName,
    ],
    workingDirectory: workingDirectory,
  );

  expect(
    result.exitCode,
    0,
    reason: 'Failed to create app: \n'
        'stdout: \n${result.stdout}\n'
        'stderr: \n${result.stderr}\n',
  );

  return fileSystem.path.join(
    workingDirectory,
    appName,
  );
}

Future<void> _buildApp(
  String flutterBin,
  String workingDirectory, {
  required List<String> options,
  List<Pattern>? expectedLines,
  List<String>? unexpectedLines,
}) async {
  final List<Pattern> remainingExpectedLines = expectedLines ?? <Pattern>[];
  final List<String> unexpectedLinesFound = <String>[];
  final List<String> command = <String>[
    flutterBin,
    ...getLocalEngineArguments(),
    'build',
    ...options,
  ];

  final ProcessResult result = await processManager.run(
    command,
    workingDirectory: workingDirectory,
  );

  final List<String> stdout = LineSplitter.split(result.stdout.toString()).toList();
  final List<String> stderr = LineSplitter.split(result.stderr.toString()).toList();
  final List<String> output = stdout + stderr;
  for (final String line in output) {
    // Remove "[   +3 ms] " prefix
    String trimmedLine = line.trim();
    if (trimmedLine.startsWith('[')) {
      final int prefixEndIndex = trimmedLine.indexOf(']');
      if (prefixEndIndex > 0) {
        trimmedLine = trimmedLine
            .substring(prefixEndIndex + 1, trimmedLine.length)
            .trim();
      }
    }
    remainingExpectedLines.remove(trimmedLine);
    remainingExpectedLines.removeWhere((Pattern expectedLine) => trimmedLine.contains(expectedLine));
    if (unexpectedLines != null && unexpectedLines.contains(trimmedLine)) {
      unexpectedLinesFound.add(trimmedLine);
    }
  }
  expect(
    result.exitCode,
    0,
    reason: 'Failed to build app for "${command.join(' ')}":\n'
        'stdout: \n${result.stdout}\n'
        'stderr: \n${result.stderr}\n',
  );
  expect(
    remainingExpectedLines,
    isEmpty,
    reason: 'Did not find expected lines for "${command.join(' ')}":\n'
        'stdout: \n${result.stdout}\n'
        'stderr: \n${result.stderr}\n',
  );
  expect(
    unexpectedLinesFound,
    isEmpty,
    reason: 'Found unexpected lines for "${command.join(' ')}":\n'
        'stdout: \n${result.stdout}\n'
        'stderr: \n${result.stderr}\n',
  );
}

Future<void> _cleanApp(String flutterBin, String workingDirectory) async {
  final ProcessResult result = await processManager.run(
    <String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'clean',
    ],
    workingDirectory: workingDirectory,
  );
  expect(
    result.exitCode,
    0,
    reason: 'Failed to clean app: \n'
        'stdout: \n${result.stdout}\n'
        'stderr: \n${result.stderr}\n',
  );
}

Future<_Plugin> _createPlugin(
  String flutterBin,
  String workingDirectory, {
  required String platform,
  required String iosLanguage,
  bool usesSwiftPackageManager = false,
}) async {
  final String dependencyManager = usesSwiftPackageManager ? 'spm' : 'cocoapods';

  // Create plugin
  final String pluginName = '${platform}_${iosLanguage}_${dependencyManager}_plugin';
  final ProcessResult result = await processManager.run(
    <String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'create',
      '--org',
      'io.flutter.devicelab',
      '--template=plugin',
      '--platforms=$platform',
      '-i',
      iosLanguage,
      pluginName,
    ],
    workingDirectory: workingDirectory,
  );

  expect(
    result.exitCode,
    0,
    reason: 'Failed to create plugin: \n'
        'stdout: \n${result.stdout}\n'
        'stderr: \n${result.stderr}\n',
  );

  final Directory pluginDirectory = fileSystem.directory(
    fileSystem.path.join(workingDirectory, pluginName),
  );

  return _Plugin(
    pluginName: pluginName,
    pluginPath: pluginDirectory.path,
    platform: platform,
  );
}

void _addDependency({
  required _Plugin plugin,
  required String appDirectoryPath,
}) {
  final File pubspec = fileSystem.file(
    fileSystem.path.join(appDirectoryPath, 'pubspec.yaml'),
  );
  final String pubspecContent = pubspec.readAsStringSync();
  pubspec.writeAsStringSync(
    pubspecContent.replaceFirst(
      '\ndependencies:\n',
      '\ndependencies:\n  ${plugin.pluginName}:\n    path: ${plugin.pluginPath}\n',
    ),
  );
}

void _disableSwiftPackageManagerByPubspec({
  required String appDirectoryPath,
}) {
  final File pubspec = fileSystem.file(
    fileSystem.path.join(appDirectoryPath, 'pubspec.yaml'),
  );
  final String pubspecContent = pubspec.readAsStringSync();
  pubspec.writeAsStringSync(
    pubspecContent.replaceFirst(
      '\n# The following section is specific to Flutter packages.\nflutter:\n',
      '\n# The following section is specific to Flutter packages.\nflutter:\n  disable-swift-package-manager: true',
    ),
  );
}

_Plugin _integrationTestPlugin(String platform) {
  final String flutterRoot = getFlutterRoot();
  return _Plugin(
    platform: platform,
    pluginName:
        (platform == 'ios') ? 'integration_test' : 'integration_test_macos',
    pluginPath: (platform == 'ios')
        ? fileSystem.path.join(flutterRoot, 'packages', 'integration_test')
        : fileSystem.path.join(flutterRoot, 'packages', 'integration_test', 'integration_test_macos'),
  );
}

List<Pattern> _expectedLines({
  required String platform,
  required String appDirectoryPath,
  _Plugin? cococapodsPlugin,
  _Plugin? swiftPackagePlugin,
  bool swiftPackageMangerEnabled = false,
}) {
  final String frameworkName = platform == 'ios' ? 'Flutter' : 'FlutterMacOS';
  final String appPlatformDirectoryPath = fileSystem.path.join(
    appDirectoryPath,
    platform,
  );

  final List<Pattern> expectedLines = <Pattern>[];
  if (swiftPackageMangerEnabled) {
    expectedLines.addAll(<String>[
      'FlutterGeneratedPluginSwiftPackage: $appPlatformDirectoryPath/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage',
      "➜ Explicit dependency on target 'FlutterGeneratedPluginSwiftPackage' in project 'FlutterGeneratedPluginSwiftPackage'",
    ]);
  }
  if (swiftPackagePlugin != null) {
    // If using a Swift Package plugin, but Swift Package Manager is not enabled, it falls back to being used as a CocoaPods plugin.
    if (swiftPackageMangerEnabled) {
      expectedLines.addAll(<Pattern>[
        RegExp('${swiftPackagePlugin.pluginName}: [/private]*${swiftPackagePlugin.pluginPath}/$platform/${swiftPackagePlugin.pluginName} @ local'),
        "➜ Explicit dependency on target '${swiftPackagePlugin.pluginName}' in project '${swiftPackagePlugin.pluginName}'",
      ]);
    } else {
      expectedLines.addAll(<String>[
        '-> Installing ${swiftPackagePlugin.pluginName} (0.0.1)',
        "➜ Explicit dependency on target '${swiftPackagePlugin.pluginName}' in project 'Pods'",
      ]);
    }
  }
  if (cococapodsPlugin != null) {
    expectedLines.addAll(<String>[
      'Running pod install...',
      '-> Installing $frameworkName (1.0.0)',
      '-> Installing ${cococapodsPlugin.pluginName} (0.0.1)',
      "Target 'Pods-Runner' in project 'Pods'",
      "➜ Explicit dependency on target '$frameworkName' in project 'Pods'",
      "➜ Explicit dependency on target '${cococapodsPlugin.pluginName}' in project 'Pods'",
    ]);
  }
  return expectedLines;
}

List<String> _unexpectedLines({
  required String platform,
  required String appDirectoryPath,
  _Plugin? cococapodsPlugin,
  _Plugin? swiftPackagePlugin,
  bool swiftPackageMangerEnabled = false,
}) {
  final String frameworkName = platform == 'ios' ? 'Flutter' : 'FlutterMacOS';
  final List<String> unexpectedLines = <String>[];
  if (cococapodsPlugin == null) {
    unexpectedLines.addAll(<String>[
      'Running pod install...',
      '-> Installing $frameworkName (1.0.0)',
      "Target 'Pods-Runner' in project 'Pods'",
    ]);
  }
  if (swiftPackagePlugin != null) {
    if (swiftPackageMangerEnabled) {
      unexpectedLines.addAll(<String>[
        '-> Installing ${swiftPackagePlugin.pluginName} (0.0.1)',
        "➜ Explicit dependency on target '${swiftPackagePlugin.pluginName}' in project 'Pods'",
      ]);
    } else {
      unexpectedLines.addAll(<String>[
        '${swiftPackagePlugin.pluginName}: ${swiftPackagePlugin.pluginPath}/$platform/${swiftPackagePlugin.pluginName} @ local',
        "➜ Explicit dependency on target '${swiftPackagePlugin.pluginName}' in project '${swiftPackagePlugin.pluginName}'",
      ]);
    }
  }
  return unexpectedLines;
}

class _Plugin {
  _Plugin({
    required this.pluginName,
    required this.pluginPath,
    required this.platform,
  });

  final String pluginName;
  final String pluginPath;
  final String platform;
  String get exampleAppPath => fileSystem.path.join(pluginPath, 'example');
  String get exampleAppPlatformPath => fileSystem.path.join(exampleAppPath, platform);
}
