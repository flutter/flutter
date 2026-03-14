// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import '../src/common.dart';
import 'swift_package_manager_utils.dart';
import 'test_utils.dart';

void main() {
  final platforms = <String>['ios', 'macos'];
  for (final platformName in platforms) {
    test(
      'Create $platformName plugin with Swift Package Manager disabled',
      () async {
        final Directory workingDirectory = fileSystem.systemTempDirectory.createTempSync(
          'swift_package_manager_create_plugin_disabled.',
        );
        final String workingDirectoryPath = workingDirectory.path;
        try {
          await SwiftPackageManagerUtils.disableSwiftPackageManager(
            flutterBin,
            workingDirectoryPath,
          );

          final SwiftPackageManagerPlugin createdCocoaPodsPlugin =
              await SwiftPackageManagerUtils.createPlugin(
                flutterBin,
                workingDirectoryPath,
                platform: platformName,
              );

          final String appDirectoryPath = createdCocoaPodsPlugin.exampleAppPath;

          final File pbxprojFile = fileSystem
              .directory(appDirectoryPath)
              .childDirectory(platformName)
              .childDirectory('Runner.xcodeproj')
              .childFile('project.pbxproj');
          expect(pbxprojFile.existsSync(), isTrue);
          String pbxprojFileContents = pbxprojFile.readAsStringSync();
          expect(pbxprojFileContents.contains('FlutterGeneratedPluginSwiftPackage'), isFalse);
          expect(
            pbxprojFileContents.contains('784666492D4C4C64000A1A5F /* FlutterFramework */'),
            isFalse,
          );
          expect(
            pbxprojFileContents.contains(
              '78DABEA22ED26510000E7860 /* ${createdCocoaPodsPlugin.pluginName} */',
            ),
            isFalse,
          );

          final File xcschemeFile = fileSystem
              .directory(appDirectoryPath)
              .childDirectory(platformName)
              .childDirectory('Runner.xcodeproj')
              .childDirectory('xcshareddata')
              .childDirectory('xcschemes')
              .childFile('Runner.xcscheme');
          expect(xcschemeFile.existsSync(), isTrue);
          expect(
            xcschemeFile.readAsStringSync().contains('Run Prepare Flutter Framework Script'),
            isFalse,
          );

          final File podspec = fileSystem
              .directory(createdCocoaPodsPlugin.pluginPath)
              .childDirectory(platformName)
              .childFile('${createdCocoaPodsPlugin.pluginName}.podspec');
          expect(podspec.existsSync(), isTrue);
          // New plugins always use SwiftPM structure.
          expect(podspec.readAsStringSync(), contains('Sources'));
          expect(podspec.readAsStringSync().contains('Classes'), isFalse);

          // Even though the plugin uses SwiftPM structure, building with SwiftPM disabled
          // should fall back to CocoaPods at runtime.
          await SwiftPackageManagerUtils.buildApp(
            flutterBin,
            appDirectoryPath,
            options: <String>[platformName, '--debug', '-v'],
            expectedLines: SwiftPackageManagerUtils.expectedLines(
              platform: platformName,
              appDirectoryPath: appDirectoryPath,
              // Use cocoaPodsPlugin because the plugin is installed via CocoaPods when SwiftPM is disabled.
              cocoaPodsPlugin: createdCocoaPodsPlugin,
            ),
            unexpectedLines: SwiftPackageManagerUtils.unexpectedLines(
              platform: platformName,
              appDirectoryPath: appDirectoryPath,
              cocoaPodsPlugin: createdCocoaPodsPlugin,
            ),
          );

          await SwiftPackageManagerUtils.enableSwiftPackageManager(
            flutterBin,
            workingDirectoryPath,
          );

          await SwiftPackageManagerUtils.buildApp(
            flutterBin,
            appDirectoryPath,
            options: <String>[platformName, '--debug', '-v'],
          );
          pbxprojFileContents = pbxprojFile.readAsStringSync();
          expect(pbxprojFileContents.contains('FlutterGeneratedPluginSwiftPackage'), isTrue);
          expect(
            pbxprojFileContents.contains('784666492D4C4C64000A1A5F /* FlutterFramework */'),
            isTrue,
          );
          expect(
            pbxprojFileContents.contains(
              '78DABEA22ED26510000E7860 /* ${createdCocoaPodsPlugin.pluginName} */',
            ),
            isTrue,
          );
        } finally {
          await SwiftPackageManagerUtils.disableSwiftPackageManager(
            flutterBin,
            workingDirectoryPath,
          );
          ErrorHandlingFileSystem.deleteIfExists(workingDirectory, recursive: true);
        }
      },
      // [intended] Swift Package Manager only works on macos.
      skip: !platform.isMacOS,
    );

    test(
      'Create $platformName plugin with Swift Package Manager enabled',
      () async {
        final Directory workingDirectory = fileSystem.systemTempDirectory.createTempSync(
          'swift_package_manager_create_plugin_enabled.',
        );
        final String workingDirectoryPath = workingDirectory.path;
        try {
          await SwiftPackageManagerUtils.enableSwiftPackageManager(
            flutterBin,
            workingDirectoryPath,
          );

          final SwiftPackageManagerPlugin createdSwiftPackagePlugin =
              await SwiftPackageManagerUtils.createPlugin(
                flutterBin,
                workingDirectoryPath,
                platform: platformName,
              );

          final String appDirectoryPath = createdSwiftPackagePlugin.exampleAppPath;

          final File pbxprojFile = fileSystem
              .directory(appDirectoryPath)
              .childDirectory(platformName)
              .childDirectory('Runner.xcodeproj')
              .childFile('project.pbxproj');
          final String pbxprojFileContents = pbxprojFile.readAsStringSync();
          expect(pbxprojFile.existsSync(), isTrue);
          expect(pbxprojFileContents, contains('FlutterGeneratedPluginSwiftPackage'));
          expect(
            pbxprojFileContents.contains('784666492D4C4C64000A1A5F /* FlutterFramework */'),
            isTrue,
          );

          final File xcschemeFile = fileSystem
              .directory(appDirectoryPath)
              .childDirectory(platformName)
              .childDirectory('Runner.xcodeproj')
              .childDirectory('xcshareddata')
              .childDirectory('xcschemes')
              .childFile('Runner.xcscheme');
          expect(xcschemeFile.existsSync(), isTrue);
          expect(xcschemeFile.readAsStringSync(), contains('Run Prepare Flutter Framework Script'));

          final File podspec = fileSystem
              .directory(createdSwiftPackagePlugin.pluginPath)
              .childDirectory(platformName)
              .childFile('${createdSwiftPackagePlugin.pluginName}.podspec');
          expect(podspec.existsSync(), isTrue);
          expect(podspec.readAsStringSync(), contains('Sources'));
          expect(podspec.readAsStringSync().contains('Classes'), isFalse);

          // Verify that a plugin having a dependency on the FlutterFramework package
          // builds successfully.
          final File manifest = fileSystem
              .directory(createdSwiftPackagePlugin.swiftPackagePlatformPath)
              .childFile('Package.swift');
          expect(manifest.existsSync(), isTrue);
          const packageDependency =
              '.package(name: "FlutterFramework", path: "../FlutterFramework")';
          const targetDependency =
              '.product(name: "FlutterFramework", package: "FlutterFramework")';
          final String manifestContent = manifest
              .readAsStringSync()
              .replaceFirst('dependencies: [],', 'dependencies: [$packageDependency],')
              .replaceFirst('dependencies: [],', 'dependencies: [$targetDependency],');
          expect(manifestContent.contains(packageDependency), isTrue);
          expect(manifestContent.contains(targetDependency), isTrue);
          manifest.writeAsStringSync(manifestContent);

          await SwiftPackageManagerUtils.buildApp(
            flutterBin,
            appDirectoryPath,
            options: <String>[platformName, '--debug', '-v'],
            expectedLines: SwiftPackageManagerUtils.expectedLines(
              platform: platformName,
              appDirectoryPath: appDirectoryPath,
              swiftPackagePlugin: createdSwiftPackagePlugin,
              swiftPackageMangerEnabled: true,
            ),
            unexpectedLines: SwiftPackageManagerUtils.unexpectedLines(
              platform: platformName,
              appDirectoryPath: appDirectoryPath,
              swiftPackagePlugin: createdSwiftPackagePlugin,
              swiftPackageMangerEnabled: true,
            ),
          );
        } finally {
          await SwiftPackageManagerUtils.disableSwiftPackageManager(
            flutterBin,
            workingDirectoryPath,
          );
          ErrorHandlingFileSystem.deleteIfExists(workingDirectory, recursive: true);
        }
      },
      // [intended] Swift Package Manager only works on macos.
      skip: !platform.isMacOS,
    );
  }
}
