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
          expect(podspec.readAsStringSync(), contains('Classes'));
          expect(podspec.readAsStringSync().contains('Sources'), isFalse);

          await SwiftPackageManagerUtils.buildApp(
            flutterBin,
            appDirectoryPath,
            options: <String>[platformName, '--debug', '-v'],
            expectedLines: SwiftPackageManagerUtils.expectedLines(
              platform: platformName,
              appDirectoryPath: appDirectoryPath,
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

          // Convert CocoaPod plugin to support SwiftPM
          fileSystem
              .directory(createdCocoaPodsPlugin.pluginPath)
              .childDirectory(platformName)
              .childDirectory(createdCocoaPodsPlugin.pluginName)
              .childFile('Package.swift')
            ..createSync(recursive: true)
            ..writeAsStringSync('''
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
let package = Package(
    name: "${createdCocoaPodsPlugin.pluginName}",
    products: [
        .library(name: "${createdCocoaPodsPlugin.pluginName.replaceAll('_', '-')}", targets: ["${createdCocoaPodsPlugin.pluginName}"])
    ],
    targets: [
        .target(
            name: "${createdCocoaPodsPlugin.pluginName}"
        )
    ]
)
''');
          fileSystem
              .directory(createdCocoaPodsPlugin.pluginPath)
              .childDirectory(platformName)
              .childDirectory(createdCocoaPodsPlugin.pluginName)
              .childDirectory('Sources')
              .childDirectory(createdCocoaPodsPlugin.pluginName)
              .childFile('${createdCocoaPodsPlugin.className}.swift')
            ..createSync(recursive: true)
            ..writeAsStringSync(
              fileSystem
                  .directory(createdCocoaPodsPlugin.pluginPath)
                  .childDirectory(platformName)
                  .childDirectory('Classes')
                  .childFile('${createdCocoaPodsPlugin.className}.swift')
                  .readAsStringSync(),
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

          final File swiftManifest = fileSystem
              .directory(createdSwiftPackagePlugin.pluginPath)
              .childDirectory(platformName)
              .childDirectory(createdSwiftPackagePlugin.pluginName)
              .childFile('Package.swift');
          expect(swiftManifest.existsSync(), isTrue);
          expect(
            swiftManifest.readAsStringSync().contains(
              '.package(name: "FlutterFramework", path: "../FlutterFramework")',
            ),
            isTrue,
          );

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
