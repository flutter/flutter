// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import '../src/common.dart';
import 'swift_package_manager_utils.dart';
import 'test_utils.dart';

void main() {
  final platforms = <String>['ios', 'macos'];
  for (final platformName in platforms) {
    final SwiftPackageManagerPlugin integrationTestPlugin =
        SwiftPackageManagerUtils.integrationTestPlugin(platformName);

    test(
      'Swift Package Manager integration for $platformName',
      () async {
        final Directory workingDirectory = fileSystem.systemTempDirectory.createTempSync(
          'swift_package_manager_enabled.',
        );
        final String workingDirectoryPath = workingDirectory.path;

        addTearDown(() async {
          await SwiftPackageManagerUtils.disableSwiftPackageManager(
            flutterBin,
            workingDirectoryPath,
          );
          ErrorHandlingFileSystem.deleteIfExists(workingDirectory, recursive: true);
        });

        // Create and build an app using the CocoaPods version of
        // integration_test.
        await SwiftPackageManagerUtils.disableSwiftPackageManager(flutterBin, workingDirectoryPath);
        final String appDirectoryPath = await SwiftPackageManagerUtils.createApp(
          flutterBin,
          workingDirectoryPath,
          platform: platformName,
          options: <String>['--platforms=$platformName'],
        );
        SwiftPackageManagerUtils.addDependency(
          appDirectoryPath: appDirectoryPath,
          plugin: integrationTestPlugin,
        );
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
          fileSystem.directory(appDirectoryPath).childDirectory(platformName).childFile('Podfile'),
          exists,
        );
        final File generatedSwiftPackage = fileSystem
            .directory(appDirectoryPath)
            .childDirectory(platformName)
            .childDirectory('Flutter')
            .childDirectory('ephemeral')
            .childDirectory('Packages')
            .childDirectory('FlutterGeneratedPluginSwiftPackage')
            .childFile('Package.swift');
        expect(generatedSwiftPackage, isNot(exists));

        final SwiftPackageManagerPlugin createdCocoaPodsPlugin =
            await SwiftPackageManagerUtils.createPlugin(
              flutterBin,
              workingDirectoryPath,
              platform: platformName,
            );

        // Rebuild app with Swift Package Manager enabled, migrating the app and using the Swift Package Manager version of
        // integration_test.
        await SwiftPackageManagerUtils.enableSwiftPackageManager(flutterBin, workingDirectoryPath);

        // Create a SwiftPM plugin that depends on native code from another SwiftPM plugin
        final SwiftPackageManagerPlugin createdSwiftPMPlugin =
            await SwiftPackageManagerUtils.createPlugin(
              flutterBin,
              workingDirectoryPath,
              platform: platformName,
              usesSwiftPackageManager: true,
            );
        final File swiftPMPluginPackageManifest = fileSystem
            .directory(createdSwiftPMPlugin.pluginPath)
            .childDirectory(platformName)
            .childDirectory(createdSwiftPMPlugin.pluginName)
            .childFile('Package.swift');
        final String manifestContents = swiftPMPluginPackageManifest.readAsStringSync();
        swiftPMPluginPackageManifest.writeAsStringSync(
          manifestContents
              .replaceFirst(
                'dependencies: []',
                'dependencies: [.package(name: "${integrationTestPlugin.pluginName}", path: "../${integrationTestPlugin.pluginName}")]',
              )
              .replaceFirst(
                'dependencies: []',
                'dependencies: [.product(name: "${integrationTestPlugin.pluginName.replaceAll('_', '-')}", package: "${integrationTestPlugin.pluginName}")]',
              ),
        );
        final File swiftPMPluginPodspec = fileSystem
            .directory(createdSwiftPMPlugin.pluginPath)
            .childDirectory(platformName)
            .childFile('${createdSwiftPMPlugin.pluginName}.podspec');
        final String podspecContents = swiftPMPluginPodspec.readAsStringSync();
        swiftPMPluginPodspec.writeAsStringSync(
          podspecContents.replaceFirst(
            '\nend',
            "\n  s.dependency '${integrationTestPlugin.pluginName}'\n\nend",
          ),
        );
        final pluginClassFileName = '${createdSwiftPMPlugin.className}.swift';
        final pluginClassFileImport = 'import ${integrationTestPlugin.pluginName}';
        final File pluginClassFile = fileSystem
            .directory(createdSwiftPMPlugin.pluginPath)
            .childDirectory(platformName)
            .childDirectory(createdSwiftPMPlugin.pluginName)
            .childDirectory('Sources')
            .childDirectory(createdSwiftPMPlugin.pluginName)
            .childFile(pluginClassFileName);
        final String pluginClassFileContent = pluginClassFile.readAsStringSync();
        pluginClassFile.writeAsStringSync('$pluginClassFileImport\n$pluginClassFileContent');
        SwiftPackageManagerUtils.addDependency(
          appDirectoryPath: createdSwiftPMPlugin.pluginPath,
          plugin: integrationTestPlugin,
        );

        SwiftPackageManagerUtils.addDependency(
          appDirectoryPath: appDirectoryPath,
          plugin: createdSwiftPMPlugin,
        );

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
          fileSystem.directory(appDirectoryPath).childDirectory(platformName).childFile('Podfile'),
          exists,
        );
        expect(generatedSwiftPackage, exists);

        // Validate targeted configuration matches the embedded Flutter Framework configuration
        final Directory buildDir = fileSystem
            .directory(appDirectoryPath)
            .childDirectory('build')
            .childDirectory(platformName);
        validateFrameworkConfiguration(buildDir, 'Debug', platformName);

        // Validate targeted configuration matches the embedded Flutter Framework configuration
        // when switching configuration directly with Xcode
        await SwiftPackageManagerUtils.xcodebuildApp(
          '$appDirectoryPath/$platformName',
          platformName: platformName,
          configuration: 'Release',
          buildDir: buildDir.path,
        );
        validateFrameworkConfiguration(buildDir, 'Release', platformName);

        await SwiftPackageManagerUtils.xcodebuildApp(
          '$appDirectoryPath/$platformName',
          platformName: platformName,
          configuration: 'Debug',
          buildDir: buildDir.path,
        );
        validateFrameworkConfiguration(buildDir, 'Debug', platformName);

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
          fileSystem.directory(appDirectoryPath).childDirectory(platformName).childFile('Podfile'),
          exists,
        );
        expect(generatedSwiftPackage, exists);

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
        SwiftPackageManagerUtils.disableSwiftPackageManagerByPubspec(
          appDirectoryPath: appDirectoryPath,
        );
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
      },
      skip: !platform.isMacOS, // [intended] Swift Package Manager only works on macos.
    );

    test('Build $platformName-framework with non-module app uses CocoaPods', () async {
      final Directory workingDirectory = fileSystem.systemTempDirectory.createTempSync(
        'swift_package_manager_build_framework.',
      );
      final String workingDirectoryPath = workingDirectory.path;

      addTearDown(() async {
        await SwiftPackageManagerUtils.disableSwiftPackageManager(flutterBin, workingDirectoryPath);
        ErrorHandlingFileSystem.deleteIfExists(workingDirectory, recursive: true);
      });

      // Create and build an app using the Swift Package Manager version of
      // integration_test.
      await SwiftPackageManagerUtils.enableSwiftPackageManager(flutterBin, workingDirectoryPath);

      final String appDirectoryPath = await SwiftPackageManagerUtils.createApp(
        flutterBin,
        workingDirectoryPath,
        platform: platformName,
        usesSwiftPackageManager: true,
        options: <String>['--platforms=$platformName'],
      );
      SwiftPackageManagerUtils.addDependency(
        appDirectoryPath: appDirectoryPath,
        plugin: integrationTestPlugin,
      );

      // Create and build framework using the CocoaPods version of
      // integration_test even though Swift Package Manager is enabled.
      await SwiftPackageManagerUtils.buildApp(
        flutterBin,
        appDirectoryPath,
        options: <String>['$platformName-framework', '--no-debug', '--no-profile', '-v'],
        expectedLines: <String>[
          'Swift Package Manager does not yet support this command. CocoaPods will be used instead.',
        ],
      );

      // Verify the generated Swift Package Manager manifest file has no dependencies.
      final File generatedManifestFile = fileSystem
          .directory(appDirectoryPath)
          .childDirectory(platformName)
          .childDirectory('Flutter')
          .childDirectory('ephemeral')
          .childDirectory('Packages')
          .childDirectory('FlutterGeneratedPluginSwiftPackage')
          .childFile('Package.swift');

      expect(generatedManifestFile, exists);

      final String generatedManifest = generatedManifestFile.readAsStringSync();
      const expected = 'dependencies: [\n        \n    ],\n';
      expect(generatedManifest, contains(expected));

      expect(
        fileSystem
            .directory(appDirectoryPath)
            .childDirectory('build')
            .childDirectory(platformName)
            .childDirectory('framework')
            .childDirectory('Release')
            .childDirectory('${integrationTestPlugin.pluginName}.xcframework'),
        exists,
      );
    }, skip: !platform.isMacOS); // [intended] Swift Package Manager only works on macos.

    test(
      'Caches build targets between builds with Swift Package Manager on $platformName',
      () async {
        final Directory workingDirectory = fileSystem.systemTempDirectory.createTempSync(
          'swift_package_manager_caching.',
        );
        final String workingDirectoryPath = workingDirectory.path;

        addTearDown(() async {
          await SwiftPackageManagerUtils.disableSwiftPackageManager(
            flutterBin,
            workingDirectoryPath,
          );
          ErrorHandlingFileSystem.deleteIfExists(workingDirectory, recursive: true);
        });

        // Create and build an app using the Swift Package Manager version of
        // integration_test.
        await SwiftPackageManagerUtils.enableSwiftPackageManager(flutterBin, workingDirectoryPath);

        final String appDirectoryPath = await SwiftPackageManagerUtils.createApp(
          flutterBin,
          workingDirectoryPath,
          platform: platformName,
          usesSwiftPackageManager: true,
          options: <String>['--platforms=$platformName'],
        );
        SwiftPackageManagerUtils.addDependency(
          appDirectoryPath: appDirectoryPath,
          plugin: integrationTestPlugin,
        );

        final unpackTarget = 'debug_unpack_$platformName';
        final bundleFlutterAssetsTarget = 'debug_${platformName}_bundle_flutter_assets';
        final noCodesign = platformName == 'ios';
        await SwiftPackageManagerUtils.buildApp(
          flutterBin,
          appDirectoryPath,
          options: <String>[platformName, '--debug', '-v', if (noCodesign) '--no-codesign'],
          expectedLines: <Pattern>[
            r'SchemeAction Run\ Prepare\ Flutter\ Framework\ Script',
            '-dXcodeBuildScript=prepare',
            '$unpackTarget: Starting due to',
            '-dXcodeBuildScript=build',
            'Skipping target: $unpackTarget',
          ],
          unexpectedLines: <String>[],
        );

        await SwiftPackageManagerUtils.buildApp(
          flutterBin,
          appDirectoryPath,
          options: <String>[platformName, '--debug', '-v', if (noCodesign) '--no-codesign'],
          expectedLines: <Pattern>[
            r'SchemeAction Run\ Prepare\ Flutter\ Framework\ Script',
            'Skipping target: $unpackTarget',
            'Skipping target: $bundleFlutterAssetsTarget',
          ],
          unexpectedLines: <String>['Starting due to'],
        );
      },
      skip: !platform.isMacOS, // [intended] Swift Package Manager only works on macos.
    );
  }

  test('Build ios-framework with module app uses CocoaPods', () async {
    final Directory workingDirectory = fileSystem.systemTempDirectory.createTempSync(
      'swift_package_manager_build_framework_module.',
    );
    final String workingDirectoryPath = workingDirectory.path;

    addTearDown(() async {
      await SwiftPackageManagerUtils.disableSwiftPackageManager(flutterBin, workingDirectoryPath);
      ErrorHandlingFileSystem.deleteIfExists(workingDirectory, recursive: true);
    });

    // Create and build module and framework using the CocoaPods version of
    // integration_test even though Swift Package Manager is enabled.
    await SwiftPackageManagerUtils.enableSwiftPackageManager(flutterBin, workingDirectoryPath);

    final String appDirectoryPath = await SwiftPackageManagerUtils.createApp(
      flutterBin,
      workingDirectoryPath,
      platform: 'ios',
      usesSwiftPackageManager: true,
      options: <String>['--template=module'],
    );
    final SwiftPackageManagerPlugin integrationTestPlugin =
        SwiftPackageManagerUtils.integrationTestPlugin('ios');
    SwiftPackageManagerUtils.addDependency(
      appDirectoryPath: appDirectoryPath,
      plugin: integrationTestPlugin,
    );

    await SwiftPackageManagerUtils.buildApp(
      flutterBin,
      appDirectoryPath,
      options: <String>['ios', '--config-only', '-v'],
    );

    expect(
      fileSystem.directory(appDirectoryPath).childDirectory('.ios').childFile('Podfile'),
      exists,
    );
    expect(
      fileSystem
          .directory(appDirectoryPath)
          .childDirectory('.ios')
          .childDirectory('Flutter')
          .childDirectory('ephemeral')
          .childDirectory('Packages')
          .childDirectory('FlutterGeneratedPluginSwiftPackage'),
      isNot(exists),
    );
    final File pbxprojFile = fileSystem
        .directory(appDirectoryPath)
        .childDirectory('.ios')
        .childDirectory('Runner.xcodeproj')
        .childFile('project.pbxproj');
    expect(pbxprojFile, exists);
    expect(pbxprojFile.readAsStringSync(), isNot(contains('FlutterGeneratedPluginSwiftPackage')));
    final File xcschemeFile = fileSystem
        .directory(appDirectoryPath)
        .childDirectory('.ios')
        .childDirectory('Runner.xcodeproj')
        .childDirectory('xcshareddata')
        .childDirectory('xcschemes')
        .childFile('Runner.xcscheme');
    expect(xcschemeFile, exists);
    expect(
      xcschemeFile.readAsStringSync(),
      isNot(contains('Run Prepare Flutter Framework Script')),
    );

    await SwiftPackageManagerUtils.buildApp(
      flutterBin,
      appDirectoryPath,
      options: <String>['ios-framework', '--no-debug', '--no-profile', '-v'],
      unexpectedLines: <String>[
        'Adding Swift Package Manager integration...',
        'Swift Package Manager does not yet support this command. CocoaPods will be used instead.',
      ],
    );

    expect(
      fileSystem
          .directory(appDirectoryPath)
          .childDirectory('build')
          .childDirectory('ios')
          .childDirectory('framework')
          .childDirectory('Release')
          .childDirectory('${integrationTestPlugin.pluginName}.xcframework'),
      exists,
    );
  }, skip: !platform.isMacOS); // [intended] Swift Package Manager only works on macos.

  test('Build ios-framework with non module app uses CocoaPods', () async {
    final Directory workingDirectory = fileSystem.systemTempDirectory.createTempSync(
      'swift_package_manager_build_framework_non_module.',
    );
    final String workingDirectoryPath = workingDirectory.path;

    addTearDown(() async {
      await SwiftPackageManagerUtils.disableSwiftPackageManager(flutterBin, workingDirectoryPath);
      ErrorHandlingFileSystem.deleteIfExists(workingDirectory, recursive: true);
    });

    // Create and build a regular app and framework using the CocoaPods version of
    // integration_test even though Swift Package Manager is enabled.
    await SwiftPackageManagerUtils.enableSwiftPackageManager(flutterBin, workingDirectoryPath);

    final String appDirectoryPath = await SwiftPackageManagerUtils.createApp(
      flutterBin,
      workingDirectoryPath,
      platform: 'ios',
      usesSwiftPackageManager: true,
      options: <String>[],
    );
    final SwiftPackageManagerPlugin integrationTestPlugin =
        SwiftPackageManagerUtils.integrationTestPlugin('ios');
    SwiftPackageManagerUtils.addDependency(
      appDirectoryPath: appDirectoryPath,
      plugin: integrationTestPlugin,
    );

    await SwiftPackageManagerUtils.cleanApp(flutterBin, appDirectoryPath);

    await SwiftPackageManagerUtils.buildApp(
      flutterBin,
      appDirectoryPath,
      options: <String>['ios-framework', '--xcframework', '--no-debug', '--no-profile', '-v'],
      expectedLines: <String>[
        'Swift Package Manager does not yet support this command. CocoaPods will be used instead.',
      ],
      unexpectedLines: <String>['Adding Swift Package Manager integration...'],
    );

    expect(fileSystem.directory(appDirectoryPath).childDirectory('.ios'), isNot(exists));

    // Verify the generated Swift Package Manager manifest file has no dependencies.
    final File generatedManifestFile = fileSystem
        .directory(appDirectoryPath)
        .childDirectory('ios')
        .childDirectory('Flutter')
        .childDirectory('ephemeral')
        .childDirectory('Packages')
        .childDirectory('FlutterGeneratedPluginSwiftPackage')
        .childFile('Package.swift');

    expect(generatedManifestFile, exists);

    final String generatedManifest = generatedManifestFile.readAsStringSync();
    const expected = 'dependencies: [\n        \n    ],\n';
    expect(generatedManifest, contains(expected));

    expect(
      fileSystem
          .directory(appDirectoryPath)
          .childDirectory('build')
          .childDirectory('ios')
          .childDirectory('framework')
          .childDirectory('Release')
          .childDirectory('${integrationTestPlugin.pluginName}.xcframework'),
      exists,
    );

    final File flutterPluginsDependenciesFile = fileSystem
        .directory(appDirectoryPath)
        .childFile('.flutter-plugins-dependencies');

    expect(flutterPluginsDependenciesFile, exists);

    final String dependenciesString = flutterPluginsDependenciesFile.readAsStringSync();
    final dependenciesJson = json.decode(dependenciesString) as Map<String, dynamic>?;
    final swiftPackageManagerEnabled =
        dependenciesJson?['swift_package_manager_enabled'] as Map<String, dynamic>?;
    final swiftPackageManagerEnabledIos = swiftPackageManagerEnabled?['ios'] as bool?;

    expect(swiftPackageManagerEnabledIos, isFalse);
  }, skip: !platform.isMacOS); // [intended] Swift Package Manager only works on macos.

  test("Generated Swift package uses iOS's project minimum deployment", () async {
    final Directory workingDirectory = fileSystem.systemTempDirectory.createTempSync(
      'swift_package_manager_minimum_deployment_ios.',
    );
    final String workingDirectoryPath = workingDirectory.path;

    addTearDown(() async {
      await SwiftPackageManagerUtils.disableSwiftPackageManager(flutterBin, workingDirectoryPath);
      ErrorHandlingFileSystem.deleteIfExists(workingDirectory, recursive: true);
    });

    await SwiftPackageManagerUtils.enableSwiftPackageManager(flutterBin, workingDirectoryPath);
    final String appDirectoryPath = await SwiftPackageManagerUtils.createApp(
      flutterBin,
      workingDirectoryPath,
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

    expect(generatedManifestFile, exists);

    final String generatedManifest = generatedManifestFile.readAsStringSync();
    const expected = '''
    platforms: [
        .iOS("15.1")
    ],
''';

    expect(generatedManifest.contains(expected), isTrue);
  }, skip: !platform.isMacOS); // [intended] Swift Package Manager only works on macos.

  test("Generated Swift package uses macOS's project minimum deployment", () async {
    final Directory workingDirectory = fileSystem.systemTempDirectory.createTempSync(
      'swift_package_manager_minimum_deployment_macos.',
    );
    final String workingDirectoryPath = workingDirectory.path;

    addTearDown(() async {
      await SwiftPackageManagerUtils.disableSwiftPackageManager(flutterBin, workingDirectoryPath);
      ErrorHandlingFileSystem.deleteIfExists(workingDirectory, recursive: true);
    });

    await SwiftPackageManagerUtils.enableSwiftPackageManager(flutterBin, workingDirectoryPath);
    final String appDirectoryPath = await SwiftPackageManagerUtils.createApp(
      flutterBin,
      workingDirectoryPath,
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

    expect(generatedManifestFile, exists);

    final String generatedManifest = generatedManifestFile.readAsStringSync();
    const expected = '''
    platforms: [
        .macOS("15.1")
    ],
''';

    expect(generatedManifest, contains(expected));
  }, skip: !platform.isMacOS); // [intended] Swift Package Manager only works on macos.

  test('Removing the last plugin updates the generated Swift package', () async {
    final Directory workingDirectory = fileSystem.systemTempDirectory.createTempSync(
      'swift_package_manager_remove_last_plugin.',
    );
    final String workingDirectoryPath = workingDirectory.path;

    addTearDown(() async {
      await SwiftPackageManagerUtils.disableSwiftPackageManager(flutterBin, workingDirectoryPath);
      ErrorHandlingFileSystem.deleteIfExists(workingDirectory, recursive: true);
    });

    await SwiftPackageManagerUtils.enableSwiftPackageManager(flutterBin, workingDirectoryPath);

    // Create an app with a plugin.
    final String appDirectoryPath = await SwiftPackageManagerUtils.createApp(
      flutterBin,
      workingDirectoryPath,
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

    expect(generatedManifestFile, exists);

    String generatedManifest = generatedManifestFile.readAsStringSync();
    const generatedSwiftDependency = '''
    dependencies: [
        .package(name: "integration_test", path: "../.packages/integration_test"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
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
    expect(generatedManifestFile, exists);

    generatedManifest = generatedManifestFile.readAsStringSync();
    const emptyDependencies = '''
    dependencies: [
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
''';
    expect(generatedManifest, isNot(contains(generatedSwiftDependency)));
    expect(generatedManifest, contains(emptyDependencies));
  }, skip: !platform.isMacOS); // [intended] Swift Package Manager only works on macos.

  test('Migrated app builds after Swift Package Manager is turned off', () async {
    final Directory workingDirectory = fileSystem.systemTempDirectory.createTempSync(
      'swift_package_manager_turned_off.',
    );
    final String workingDirectoryPath = workingDirectory.path;

    addTearDown(() async {
      await SwiftPackageManagerUtils.disableSwiftPackageManager(flutterBin, workingDirectoryPath);
      ErrorHandlingFileSystem.deleteIfExists(workingDirectory, recursive: true);
    });

    await SwiftPackageManagerUtils.enableSwiftPackageManager(flutterBin, workingDirectoryPath);

    // Create an app with a plugin and Swift Package Manager integration.
    final String appDirectoryPath = await SwiftPackageManagerUtils.createApp(
      flutterBin,
      workingDirectoryPath,
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

    expect(xcodeProjectFile, exists);
    expect(generatedManifestFile, exists);
    expect(cocoaPodsPluginFramework, isNot(exists));

    String xcodeProject = xcodeProjectFile.readAsStringSync();
    String generatedManifest = generatedManifestFile.readAsStringSync();
    const generatedSwiftDependency = '''
    dependencies: [
        .package(name: "integration_test", path: "../.packages/integration_test"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
''';

    expect(xcodeProject, contains('FlutterGeneratedPluginSwiftPackage'));
    expect(generatedManifest, contains(generatedSwiftDependency));

    // Disable Swift Package Manager and do a clean re-build of the app.
    // The build should succeed.
    await SwiftPackageManagerUtils.disableSwiftPackageManager(flutterBin, workingDirectoryPath);

    await SwiftPackageManagerUtils.cleanApp(flutterBin, appDirectoryPath);

    await SwiftPackageManagerUtils.buildApp(
      flutterBin,
      appDirectoryPath,
      options: <String>['ios', '-v'],
    );

    // The app should still have SwiftPM integration,
    // but the plugin should be added using CocoaPods.
    expect(xcodeProjectFile, exists);
    expect(generatedManifestFile, exists);

    xcodeProject = xcodeProjectFile.readAsStringSync();
    generatedManifest = generatedManifestFile.readAsStringSync();
    const emptyDependencies = 'dependencies: [\n        \n    ],\n';

    expect(xcodeProject, contains('FlutterGeneratedPluginSwiftPackage'));
    expect(generatedManifest, isNot(contains('integration_test')));
    expect(generatedManifest, contains(emptyDependencies));
    expect(cocoaPodsPluginFramework, exists);
  }, skip: !platform.isMacOS); // [intended] Swift Package Manager only works on macos.
}

void validateFrameworkConfiguration(Directory buildDir, String configuration, String platformName) {
  final File frameworkInfoPlist;
  final Directory dsym;
  if (platformName == 'macos') {
    frameworkInfoPlist = buildDir
        .childDirectory('Build')
        .childDirectory('Products')
        .childDirectory(configuration)
        .childDirectory('macos_default_app.app')
        .childDirectory('Contents')
        .childDirectory('Frameworks')
        .childDirectory('FlutterMacOS.framework')
        .childDirectory('Resources')
        .childFile('Info.plist');

    dsym = buildDir
        .childDirectory('Build')
        .childDirectory('Products')
        .childDirectory(configuration)
        .childDirectory('FlutterMacOS.framework.dSYM');
  } else {
    frameworkInfoPlist = buildDir
        .childDirectory('$configuration-iphoneos')
        .childDirectory('Runner.app')
        .childDirectory('Frameworks')
        .childDirectory('Flutter.framework')
        .childFile('Info.plist');
    dsym = buildDir
        .childDirectory('$configuration-iphoneos')
        .childDirectory('Flutter.framework.dSYM');
  }
  expect(frameworkInfoPlist, exists);
  expect(
    frameworkInfoPlist.readAsStringSync().replaceAll(' ', '').replaceAll('\t', ''),
    contains('''
<key>BuildMode</key>
<string>${configuration.toLowerCase()}</string>
'''),
  );
  if (configuration == 'Release') {
    expect(dsym, exists);
  }
}
