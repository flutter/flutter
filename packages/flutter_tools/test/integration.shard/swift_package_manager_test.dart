// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import '../src/common.dart';
import 'swift_package_manager_utils.dart';
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
    final SwiftPackageManagerPlugin integrationTestPlugin = SwiftPackageManagerUtils.integrationTestPlugin(platformName);

    for (final String iosLanguage in iosLanguages) {
      test('Swift Package Manager integration for $platformName with $iosLanguage', () async {
        final Directory workingDirectory = fileSystem.systemTempDirectory
            .createTempSync('swift_package_manager_enabled.');
        final String workingDirectoryPath = workingDirectory.path;
        try {
          // Create and build an app using the CocoaPods version of
          // integration_test.
          await SwiftPackageManagerUtils.disableSwiftPackageManager(flutterBin, workingDirectoryPath);
          final String appDirectoryPath = await SwiftPackageManagerUtils.createApp(
            flutterBin,
            workingDirectoryPath,
            iosLanguage: iosLanguage,
            platform: platformName,
            usesSwiftPackageManager: true,
            options: <String>['--platforms=$platformName'],
          );
          SwiftPackageManagerUtils.addDependency(appDirectoryPath: appDirectoryPath, plugin: integrationTestPlugin);
          await SwiftPackageManagerUtils.buildApp(
            flutterBin,
            appDirectoryPath,
            options: <String>[platformName, '--debug', '-v'],
            expectedLines: SwiftPackageManagerUtils.expectedLines(
              platform: platformName,
              appDirectoryPath: appDirectoryPath,
              cocoaPodsPlugin: integrationTestPlugin,
            ),
            unexpectedLines: SwiftPackageManagerUtils.unexpectedLines(
              platform: platformName,
              appDirectoryPath: appDirectoryPath,
              cocoaPodsPlugin: integrationTestPlugin,
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

          final SwiftPackageManagerPlugin createdCocoaPodsPlugin = await SwiftPackageManagerUtils.createPlugin(
            flutterBin,
            workingDirectoryPath,
            platform: platformName,
            iosLanguage: iosLanguage,
          );

          // Rebuild app with Swift Package Manager enabled, migrating the app and using the Swift Package Manager version of
          // integration_test.
          await SwiftPackageManagerUtils.enableSwiftPackageManager(flutterBin, workingDirectoryPath);
          await SwiftPackageManagerUtils.buildApp(
            flutterBin,
            appDirectoryPath,
            options: <String>[platformName, '--debug', '-v'],
            expectedLines: SwiftPackageManagerUtils.expectedLines(
              platform: platformName,
              appDirectoryPath: appDirectoryPath,
              swiftPackageMangerEnabled: true,
              swiftPackagePlugin: integrationTestPlugin,
              migrated: true,
            ),
            unexpectedLines: SwiftPackageManagerUtils.unexpectedLines(
              platform: platformName,
              appDirectoryPath: appDirectoryPath,
              swiftPackageMangerEnabled: true,
              swiftPackagePlugin: integrationTestPlugin,
              migrated: true,
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

          // Build an app using both a CocoaPods and Swift Package Manager plugin.
          SwiftPackageManagerUtils.addDependency(
            appDirectoryPath: appDirectoryPath,
            plugin: createdCocoaPodsPlugin,
          );
          await SwiftPackageManagerUtils.buildApp(
            flutterBin,
            appDirectoryPath,
            options: <String>[platformName, '--debug', '-v'],
            expectedLines: SwiftPackageManagerUtils.expectedLines(
              platform: platformName,
              appDirectoryPath: appDirectoryPath,
              cocoaPodsPlugin: createdCocoaPodsPlugin,
              swiftPackageMangerEnabled: true,
              swiftPackagePlugin: integrationTestPlugin,
            ),
            unexpectedLines: SwiftPackageManagerUtils.unexpectedLines(
              platform: platformName,
              appDirectoryPath: appDirectoryPath,
              cocoaPodsPlugin: createdCocoaPodsPlugin,
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
          await SwiftPackageManagerUtils.disableSwiftPackageManager(flutterBin, workingDirectoryPath);
          await SwiftPackageManagerUtils.cleanApp(flutterBin, appDirectoryPath);
          await SwiftPackageManagerUtils.buildApp(
            flutterBin,
            appDirectoryPath,
            options: <String>[platformName, '--debug', '-v'],
            expectedLines: SwiftPackageManagerUtils.expectedLines(
              platform: platformName,
              appDirectoryPath: appDirectoryPath,
              cocoaPodsPlugin: integrationTestPlugin,
            ),
            unexpectedLines: SwiftPackageManagerUtils.unexpectedLines(
              platform: platformName,
              appDirectoryPath: appDirectoryPath,
              cocoaPodsPlugin: integrationTestPlugin,
            ),
          );

          // Build app again but with Swift Package Manager disabled by pubspec.
          // App will still use CocoaPods version of integration_test plugin.
          await SwiftPackageManagerUtils.enableSwiftPackageManager(flutterBin, workingDirectoryPath);
          await SwiftPackageManagerUtils.cleanApp(flutterBin, appDirectoryPath);
          SwiftPackageManagerUtils.disableSwiftPackageManagerByPubspec(appDirectoryPath: appDirectoryPath);
          await SwiftPackageManagerUtils.buildApp(
            flutterBin,
            appDirectoryPath,
            options: <String>[platformName, '--debug', '-v'],
            expectedLines: SwiftPackageManagerUtils.expectedLines(
              platform: platformName,
              appDirectoryPath: appDirectoryPath,
              cocoaPodsPlugin: integrationTestPlugin,
            ),
            unexpectedLines: SwiftPackageManagerUtils.unexpectedLines(
              platform: platformName,
              appDirectoryPath: appDirectoryPath,
              cocoaPodsPlugin: integrationTestPlugin,
            ),
          );
        } finally {
          await SwiftPackageManagerUtils.disableSwiftPackageManager(flutterBin, workingDirectoryPath);
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
        await SwiftPackageManagerUtils.enableSwiftPackageManager(flutterBin, workingDirectoryPath);

        final String appDirectoryPath = await SwiftPackageManagerUtils.createApp(
          flutterBin,
          workingDirectoryPath,
          iosLanguage: 'swift',
          platform: platformName,
          usesSwiftPackageManager: true,
          options: <String>['--platforms=$platformName'],
        );
        SwiftPackageManagerUtils.addDependency(appDirectoryPath: appDirectoryPath, plugin: integrationTestPlugin);

        await SwiftPackageManagerUtils.buildApp(
          flutterBin,
          appDirectoryPath,
          options: <String>[platformName, '--config-only', '-v'],
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
        await SwiftPackageManagerUtils.buildApp(
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
        await SwiftPackageManagerUtils.disableSwiftPackageManager(flutterBin, workingDirectoryPath);
        ErrorHandlingFileSystem.deleteIfExists(
          workingDirectory,
          recursive: true,
        );
      }
    }, skip: !platform.isMacOS); // [intended] Swift Package Manager only works on macos.

    test('Caches build targets between builds with Swift Package Manager on $platformName', () async {
      final Directory workingDirectory = fileSystem.systemTempDirectory
            .createTempSync('swift_package_manager_caching.');
        final String workingDirectoryPath = workingDirectory.path;
        try {
          // Create and build an app using the Swift Package Manager version of
          // integration_test.
          await SwiftPackageManagerUtils.enableSwiftPackageManager(flutterBin, workingDirectoryPath);

          final String appDirectoryPath = await SwiftPackageManagerUtils.createApp(
            flutterBin,
            workingDirectoryPath,
            iosLanguage: 'swift',
            platform: platformName,
            usesSwiftPackageManager: true,
            options: <String>['--platforms=$platformName'],
          );
          SwiftPackageManagerUtils.addDependency(appDirectoryPath: appDirectoryPath, plugin: integrationTestPlugin);

          final String unpackTarget = 'debug_unpack_$platformName';
          final String bundleFlutterAssetsTarget = 'debug_${platformName}_bundle_flutter_assets';
          final bool noCodesign = platformName == 'ios';
          await SwiftPackageManagerUtils.buildApp(
            flutterBin,
            appDirectoryPath,
            options: <String>[
              platformName,
              '--debug',
              '-v',
              if (noCodesign)
                '--no-codesign',
            ],
            expectedLines: <Pattern>[
              r'SchemeAction Run\ Prepare\ Flutter\ Framework\ Script',
              '$unpackTarget: Starting due to',
              '-dPreBuildAction=PrepareFramework $unpackTarget',
            ],
            unexpectedLines: <String>[],
          );

          await SwiftPackageManagerUtils.buildApp(
            flutterBin,
            appDirectoryPath,
            options: <String>[
              platformName,
              '--debug',
              '-v',
              if (noCodesign)
                '--no-codesign',
            ],
            expectedLines: <Pattern>[
              r'SchemeAction Run\ Prepare\ Flutter\ Framework\ Script',
              'Skipping target: $unpackTarget',
              'Skipping target: $bundleFlutterAssetsTarget',
            ],
            unexpectedLines: <String>[
              'Starting due to',
            ],
          );

        } finally {
          await SwiftPackageManagerUtils.disableSwiftPackageManager(flutterBin, workingDirectoryPath);
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
      await SwiftPackageManagerUtils.enableSwiftPackageManager(flutterBin, workingDirectoryPath);

      final String appDirectoryPath = await SwiftPackageManagerUtils.createApp(
        flutterBin,
        workingDirectoryPath,
        iosLanguage: 'swift',
        platform: 'ios',
        usesSwiftPackageManager: true,
        options: <String>['--template=module'],
      );
      final SwiftPackageManagerPlugin integrationTestPlugin = SwiftPackageManagerUtils.integrationTestPlugin('ios');
      SwiftPackageManagerUtils.addDependency(appDirectoryPath: appDirectoryPath, plugin: integrationTestPlugin);

      await SwiftPackageManagerUtils.buildApp(
        flutterBin,
        appDirectoryPath,
        options: <String>['ios', '--config-only', '-v'],
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
      final File pbxprojFile = fileSystem
          .directory(appDirectoryPath)
          .childDirectory('.ios')
          .childDirectory('Runner.xcodeproj')
          .childFile('project.pbxproj');
      expect(pbxprojFile.existsSync(), isTrue);
      expect(
        pbxprojFile.readAsStringSync().contains('FlutterGeneratedPluginSwiftPackage'),
        isFalse,
      );
      final File xcschemeFile = fileSystem
          .directory(appDirectoryPath)
          .childDirectory('.ios')
          .childDirectory('Runner.xcodeproj')
          .childDirectory('xcshareddata')
          .childDirectory('xcschemes')
          .childFile('Runner.xcscheme');
      expect(xcschemeFile.existsSync(), isTrue);
      expect(
        xcschemeFile.readAsStringSync().contains('Run Prepare Flutter Framework Script'),
        isFalse,
      );

      await SwiftPackageManagerUtils.buildApp(
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
      await SwiftPackageManagerUtils.disableSwiftPackageManager(flutterBin, workingDirectoryPath);
      ErrorHandlingFileSystem.deleteIfExists(
        workingDirectory,
        recursive: true,
      );
    }
  }, skip: !platform.isMacOS); // [intended] Swift Package Manager only works on macos.
}
