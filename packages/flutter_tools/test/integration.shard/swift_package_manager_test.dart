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

  test("Generated Swift package uses iOS's project minimum deployment", () async {
    final Directory workingDirectory = fileSystem.systemTempDirectory
      .createTempSync('swift_package_manager_minimum_deployment_ios.');
    final String workingDirectoryPath = workingDirectory.path;
    try {
      await SwiftPackageManagerUtils.enableSwiftPackageManager(flutterBin, workingDirectoryPath);
      final String appDirectoryPath = await SwiftPackageManagerUtils.createApp(
        flutterBin,
        workingDirectoryPath,
        iosLanguage: 'swift',
        platform: 'ios',
        usesSwiftPackageManager: true,
        options: <String>['--platforms=ios'],
      );

      // Modify the project to raise the deployment version.
      final File projectFile = fileSystem
        .directory(appDirectoryPath)
        .childDirectory('ios')
        .childDirectory('Runner.xcodeproj')
        .childFile('project.pbxproj');

      final String oldProject = projectFile.readAsStringSync();
      final String newProject = oldProject.replaceAll(
        RegExp(r'IPHONEOS_DEPLOYMENT_TARGET = \d+\.\d+;'),
        'IPHONEOS_DEPLOYMENT_TARGET = 15.1;',
      );

      projectFile.writeAsStringSync(newProject);

      // Build the app. This generates Flutter's Swift package.
      await SwiftPackageManagerUtils.buildApp(
        flutterBin,
        appDirectoryPath,
        options: <String>['ios', '--debug', '-v'],
      );

      // Verify the generated Swift package uses the project's minimum deployment.
      final File generatedManifestFile = fileSystem
        .directory(appDirectoryPath)
        .childDirectory('ios')
        .childDirectory('Flutter')
        .childDirectory('ephemeral')
        .childDirectory('Packages')
        .childDirectory('FlutterGeneratedPluginSwiftPackage')
        .childFile('Package.swift');

      expect(generatedManifestFile.existsSync(), isTrue);

      final String generatedManifest = generatedManifestFile.readAsStringSync();
      const String expected = '''
    platforms: [
        .iOS("15.1")
    ],
''';

      expect(generatedManifest.contains(expected), isTrue);
    } finally {
      await SwiftPackageManagerUtils.disableSwiftPackageManager(flutterBin, workingDirectoryPath);
      ErrorHandlingFileSystem.deleteIfExists(
        workingDirectory,
        recursive: true,
      );
    }
  }, skip: !platform.isMacOS); // [intended] Swift Package Manager only works on macos.

  test("Generated Swift package uses macOS's project minimum deployment", () async {
    final Directory workingDirectory = fileSystem.systemTempDirectory
      .createTempSync('swift_package_manager_minimum_deployment_macos.');
    final String workingDirectoryPath = workingDirectory.path;
    try {
      await SwiftPackageManagerUtils.enableSwiftPackageManager(flutterBin, workingDirectoryPath);
      final String appDirectoryPath = await SwiftPackageManagerUtils.createApp(
        flutterBin,
        workingDirectoryPath,
        iosLanguage: 'swift',
        platform: 'macos',
        usesSwiftPackageManager: true,
        options: <String>['--platforms=macos'],
      );

      // Modify the project to raise the deployment version.
      final File projectFile = fileSystem
        .directory(appDirectoryPath)
        .childDirectory('macos')
        .childDirectory('Runner.xcodeproj')
        .childFile('project.pbxproj');

      final String oldProject = projectFile.readAsStringSync();
      final String newProject = oldProject.replaceAll(
        RegExp(r'MACOSX_DEPLOYMENT_TARGET = \d+\.\d+;'),
        'MACOSX_DEPLOYMENT_TARGET = 15.1;',
      );

      projectFile.writeAsStringSync(newProject);

      // Build the app. This generates Flutter's Swift package.
      await SwiftPackageManagerUtils.buildApp(
        flutterBin,
        appDirectoryPath,
        options: <String>['macos', '--debug', '-v'],
      );

      // Verify the generated Swift package uses the project's minimum deployment.
      final File generatedManifestFile = fileSystem
        .directory(appDirectoryPath)
        .childDirectory('macos')
        .childDirectory('Flutter')
        .childDirectory('ephemeral')
        .childDirectory('Packages')
        .childDirectory('FlutterGeneratedPluginSwiftPackage')
        .childFile('Package.swift');

      expect(generatedManifestFile.existsSync(), isTrue);

      final String generatedManifest = generatedManifestFile.readAsStringSync();
      const String expected = '''
    platforms: [
        .macOS("15.1")
    ],
''';

      expect(generatedManifest.contains(expected), isTrue);
    } finally {
      await SwiftPackageManagerUtils.disableSwiftPackageManager(flutterBin, workingDirectoryPath);
      ErrorHandlingFileSystem.deleteIfExists(
        workingDirectory,
        recursive: true,
      );
    }
  }, skip: !platform.isMacOS); // [intended] Swift Package Manager only works on macos.

  test('Removing the last plugin updates the generated Swift package', () async {
    final Directory workingDirectory = fileSystem.systemTempDirectory
      .createTempSync('swift_package_manager_remove_last_plugin.');
    final String workingDirectoryPath = workingDirectory.path;
    try {
      await SwiftPackageManagerUtils.enableSwiftPackageManager(
        flutterBin,
        workingDirectoryPath,
      );

      // Create an app with a plugin.
      final String appDirectoryPath = await SwiftPackageManagerUtils.createApp(
        flutterBin,
        workingDirectoryPath,
        iosLanguage: 'swift',
        platform: 'ios',
        usesSwiftPackageManager: true,
        options: <String>['--platforms=ios'],
      );

      final SwiftPackageManagerPlugin integrationTestPlugin =
        SwiftPackageManagerUtils.integrationTestPlugin('ios');

      SwiftPackageManagerUtils.addDependency(
        appDirectoryPath: appDirectoryPath,
        plugin: integrationTestPlugin,
      );

      // Build the app to generate the Swift package.
      await SwiftPackageManagerUtils.buildApp(
        flutterBin,
        appDirectoryPath,
        options: <String>['ios', '--config-only', '-v'],
      );

      // Verify the generated Swift package depends on the plugin.
      final File generatedManifestFile = fileSystem
        .directory(appDirectoryPath)
        .childDirectory('ios')
        .childDirectory('Flutter')
        .childDirectory('ephemeral')
        .childDirectory('Packages')
        .childDirectory('FlutterGeneratedPluginSwiftPackage')
        .childFile('Package.swift');

      expect(generatedManifestFile.existsSync(), isTrue);

      String generatedManifest = generatedManifestFile.readAsStringSync();
      final String generatedSwiftDependency = '''
    dependencies: [
        .package(name: "integration_test", path: "${integrationTestPlugin.swiftPackagePlatformPath}")
    ],
''';

      expect(generatedManifest.contains(generatedSwiftDependency), isTrue);

      // Remove the plugin and rebuild the app to re-generate the Swift package.
      SwiftPackageManagerUtils.removeDependency(
        appDirectoryPath: appDirectoryPath,
        plugin: integrationTestPlugin,
      );

      await SwiftPackageManagerUtils.buildApp(
        flutterBin,
        appDirectoryPath,
        options: <String>['ios', '--config-only', '-v'],
      );

      // Verify the generated Swift package does not depend on the plugin.
      expect(generatedManifestFile.existsSync(), isTrue);

      generatedManifest = generatedManifestFile.readAsStringSync();
      const String emptyDependencies = 'dependencies: [\n        \n    ],\n';

      expect(generatedManifest.contains(generatedSwiftDependency), isFalse);
      expect(generatedManifest.contains(emptyDependencies), isTrue);
    } finally {
      await SwiftPackageManagerUtils.disableSwiftPackageManager(flutterBin, workingDirectoryPath);
      ErrorHandlingFileSystem.deleteIfExists(
        workingDirectory,
        recursive: true,
      );
    }
  }, skip: !platform.isMacOS); // [intended] Swift Package Manager only works on macos.

  test('Migrated app builds after Swift Package Manager is turned off', () async {
    final Directory workingDirectory = fileSystem.systemTempDirectory
      .createTempSync('swift_package_manager_turned_off.');
    final String workingDirectoryPath = workingDirectory.path;
    try {
      await SwiftPackageManagerUtils.enableSwiftPackageManager(
        flutterBin,
        workingDirectoryPath,
      );

      // Create an app with a plugin and Swift Package Manager integration.
      final String appDirectoryPath = await SwiftPackageManagerUtils.createApp(
        flutterBin,
        workingDirectoryPath,
        iosLanguage: 'swift',
        platform: 'ios',
        usesSwiftPackageManager: true,
        options: <String>['--platforms=ios'],
      );

      final SwiftPackageManagerPlugin integrationTestPlugin =
        SwiftPackageManagerUtils.integrationTestPlugin('ios');

      SwiftPackageManagerUtils.addDependency(
        appDirectoryPath: appDirectoryPath,
        plugin: integrationTestPlugin,
      );

      // Build the app.
      await SwiftPackageManagerUtils.buildApp(
        flutterBin,
        appDirectoryPath,
        options: <String>['ios', '--config-only', '-v'],
      );

      // The app should have SwiftPM integration.
      final File xcodeProjectFile = fileSystem
        .directory(appDirectoryPath)
        .childDirectory('ios')
        .childDirectory('Runner.xcodeproj')
        .childFile('project.pbxproj');
      final File generatedManifestFile = fileSystem
        .directory(appDirectoryPath)
        .childDirectory('ios')
        .childDirectory('Flutter')
        .childDirectory('ephemeral')
        .childDirectory('Packages')
        .childDirectory('FlutterGeneratedPluginSwiftPackage')
        .childFile('Package.swift');
      final Directory cocoaPodsPluginFramework = fileSystem
        .directory(appDirectoryPath)
        .childDirectory('build')
        .childDirectory('ios')
        .childDirectory('iphoneos')
        .childDirectory('Runner.app')
        .childDirectory('Frameworks')
        .childDirectory('${integrationTestPlugin.pluginName}.framework');

      expect(xcodeProjectFile.existsSync(), isTrue);
      expect(generatedManifestFile.existsSync(), isTrue);
      expect(cocoaPodsPluginFramework.existsSync(), isFalse);

      String xcodeProject = xcodeProjectFile.readAsStringSync();
      String generatedManifest = generatedManifestFile.readAsStringSync();
      final String generatedSwiftDependency = '''
    dependencies: [
        .package(name: "integration_test", path: "${integrationTestPlugin.swiftPackagePlatformPath}")
    ],
''';

      expect(xcodeProject.contains('FlutterGeneratedPluginSwiftPackage'), isTrue);
      expect(generatedManifest.contains(generatedSwiftDependency), isTrue);

      // Disable Swift Package Manager and do a clean re-build of the app.
      // The build should succeed.
      await SwiftPackageManagerUtils.disableSwiftPackageManager(
        flutterBin,
        workingDirectoryPath,
      );

      await SwiftPackageManagerUtils.cleanApp(flutterBin, appDirectoryPath);

      await SwiftPackageManagerUtils.buildApp(
        flutterBin,
        appDirectoryPath,
        options: <String>['ios', '-v'],
      );

      // The app should still have SwiftPM integration,
      // but the plugin should be added using CocoaPods.
      expect(xcodeProjectFile.existsSync(), isTrue);
      expect(generatedManifestFile.existsSync(), isTrue);

      xcodeProject = xcodeProjectFile.readAsStringSync();
      generatedManifest = generatedManifestFile.readAsStringSync();
      const String emptyDependencies = 'dependencies: [\n        \n    ],\n';

      expect(xcodeProject.contains('FlutterGeneratedPluginSwiftPackage'), isTrue);
      expect(generatedManifest.contains('integration_test'), isFalse);
      expect(generatedManifest.contains(emptyDependencies), isTrue);
      expect(cocoaPodsPluginFramework.existsSync(), isTrue);
    } finally {
      await SwiftPackageManagerUtils.disableSwiftPackageManager(flutterBin, workingDirectoryPath);
      ErrorHandlingFileSystem.deleteIfExists(
        workingDirectory,
        recursive: true,
      );
    }
  }, skip: !platform.isMacOS); // [intended] Swift Package Manager only works on macos.
}
