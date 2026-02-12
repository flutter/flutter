// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_swift_package.dart';
import 'package:flutter_tools/src/darwin/darwin.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/isolated/mustache_template.dart';
import 'package:flutter_tools/src/macos/swift_packages.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/platform_plugins.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:test_api/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  const flutterRoot = '/path/to/flutter';
  const commandFilePath =
      '/path/to/flutter/packages/flutter_tools/lib/src/commands/build_swift_package.dart';
  const pluginRegistrantSwiftPackagePath = 'output/FlutterPluginRegistrant';
  const cacheDirectoryPath = 'output/.cache';
  const pluginsDirectoryPath = '$pluginRegistrantSwiftPackagePath/Plugins';
  const engineArtifactPath = '/flutter/bin/cache/artifacts/engine/ios/Flutter.xcframework';

  group('BuildSwiftPackage', () {
    // TODO(vashworth): Test args validation for BuildSwiftPackage once command has been added as
    // a subcommand of BuildCommand (https://github.com/flutter/flutter/issues/181223). This is
    // required for TestFlutterCommandRunner.

    testUsingContext('createSourcesSymlink', () async {
      final fs = MemoryFileSystem.test();
      final logger = BufferLogger.test();
      final processManager = FakeProcessManager.list([]);
      final command = BuildSwiftPackage(
        analytics: FakeAnalytics(),
        artifacts: FakeArtifacts(engineArtifactPath),
        buildSystem: FakeBuildSystem(),
        cache: FakeCache(),
        fileSystem: fs,
        flutterVersion: FakeFlutterVersion(),
        logger: logger,
        platform: FakePlatform(),
        processManager: processManager,
        templateRenderer: const MustacheTemplateRenderer(),
        xcode: FakeXcode(),
        featureFlags: FakeFeatureFlags(),
        verboseHelp: false,
      );
      final Directory swiftPackageOutput = fs.directory(pluginRegistrantSwiftPackagePath);
      swiftPackageOutput.createSync(recursive: true);
      command.createSourcesSymlink(swiftPackageOutput, 'Debug');
      final Link generatedSourcesLink = swiftPackageOutput.childLink('Sources');
      expect(generatedSourcesLink, exists);
      expect(generatedSourcesLink.targetSync(), './Debug');

      final Link generatedManifestLink = swiftPackageOutput.childLink('Package.swift');
      expect(generatedManifestLink, exists);
      expect(generatedManifestLink.targetSync(), './Debug/Package.swift');
    });
  });

  group('ios', () {
    group('FlutterPluginRegistrantSwiftPackage', () {
      testWithoutContext('generateSwiftPackage', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final processManager = FakeProcessManager.list([]);
        const FlutterDarwinPlatform targetPlatform = .ios;
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(),
          fileSystem: fs,
          flutterRoot: flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final package = FlutterPluginRegistrantSwiftPackage(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final pluginSwiftDependencies = FlutterPluginSwiftDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final Directory swiftPackageOutput = fs.directory(pluginRegistrantSwiftPackagePath);
        final pluginA = FakePlugin(name: 'PluginA', darwinPlatform: targetPlatform);
        pluginSwiftDependencies.copiedPlugins.add((pluginA, '$pluginsDirectoryPath/PluginA'));

        await package.generateSwiftPackage(
          pluginRegistrantSwiftPackage: swiftPackageOutput,
          plugins: [pluginA],
          xcodeBuildConfiguration: 'Debug',
          pluginSwiftDependencies: pluginSwiftDependencies,
        );

        expect(logger.traceText, isEmpty);
        expect(processManager.hasRemainingExpectations, false);
        final File generatedPackageManifest = swiftPackageOutput
            .childDirectory('Debug')
            .childFile('Package.swift');
        expect(generatedPackageManifest, exists);
        expect(generatedPackageManifest.readAsStringSync(), '''
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
//  Generated file. Do not edit.
//

import PackageDescription

// Debug

let package = Package(
    name: "FlutterPluginRegistrant",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "FlutterPluginRegistrant", type: .static, targets: ["FlutterPluginRegistrant"])
    ],
    dependencies: [
        .package(name: "PluginA", path: "Sources/Packages/PluginA")
    ],
    targets: [
        .target(
            name: "FlutterPluginRegistrant",
            dependencies: [
                .product(name: "PluginA", package: "PluginA")
            ]
        )
    ]
)
''');
        final File generatedSource = swiftPackageOutput
            .childDirectory('Debug')
            .childDirectory('FlutterPluginRegistrant')
            .childFile('GeneratedPluginRegistrant.swift');
        expect(generatedSource, exists);
        expect(generatedSource.readAsStringSync(), '''
//
//  Generated file. Do not edit.
//
import Flutter
import UIKit

import PluginA

@objc public class GeneratedPluginRegistrant: NSObject {
    @objc public static func register(with registry: FlutterPluginRegistry) {
        if let pluginAPlugin = registry.registrar(forPlugin: "PluginAPlugin") {
            PluginAPlugin.register(with: pluginAPlugin)
        }
    }
}
''');
      });
    });

    group('FlutterPluginDependencies', () {
      testWithoutContext('processPlugins', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final processManager = FakeProcessManager.list([]);
        const FlutterDarwinPlatform targetPlatform = .ios;
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(),
          fileSystem: fs,
          flutterRoot: flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final pluginSwiftDependencies = FlutterPluginSwiftDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final pluginA = FakePlugin(name: 'PluginA', darwinPlatform: targetPlatform);
        fs.file(
            fs.path.join(pluginA.pluginSwiftPackagePath(fs, targetPlatform.name)!, 'Package.swift'),
          )
          ..createSync(recursive: true)
          ..writeAsStringSync(_pluginManifest(pluginName: 'PluginA', platforms: '.iOS("15.0")'));
        final pluginB = FakePlugin(
          name: 'PluginB',
          darwinPlatform: targetPlatform,
          supportsSwiftPM: false,
        );
        final pluginC = FakePlugin(name: 'PluginC', darwinPlatform: targetPlatform);
        fs.file(
            fs.path.join(pluginC.pluginSwiftPackagePath(fs, targetPlatform.name)!, 'Package.swift'),
          )
          ..createSync(recursive: true)
          ..writeAsStringSync(_pluginManifest(pluginName: 'PluginC'));

        final Directory pluginsDirectory = fs.directory(pluginsDirectoryPath);
        await pluginSwiftDependencies.processPlugins(
          cacheDirectory: fs.directory(cacheDirectoryPath),
          plugins: [pluginA, pluginB, pluginC],
          pluginsDirectory: pluginsDirectory,
        );
        expect(pluginsDirectory.listSync().length, 2);
        expect(pluginSwiftDependencies.highestSupportedVersion.version, Version(15, 0, 0));
      });

      testWithoutContext('determineHighestSupportedVersion matches using regex', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final processManager = FakeProcessManager.list([]);
        const FlutterDarwinPlatform targetPlatform = .ios;
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(),
          fileSystem: fs,
          flutterRoot: flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final pluginSwiftDependencies = FlutterPluginSwiftDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final Directory cacheDirectory = fs.directory(cacheDirectoryPath);
        final List<File> manifests = [
          fs.file('PluginA/Package.swift')
            ..createSync(recursive: true)
            ..writeAsStringSync(_pluginManifest(pluginName: 'PluginA', platforms: '.iOS("15.0")')),
        ];
        final (Version highestVersion, bool skipped) = await pluginSwiftDependencies
            .determineHighestSupportedVersion(manifests: manifests, cacheDirectory: cacheDirectory);
        expect(highestVersion, Version(15, 0, 0));
        expect(skipped, isFalse);

        manifests.add(
          fs.file('PluginB/Package.swift')
            ..createSync(recursive: true)
            ..writeAsStringSync(
              _pluginManifest(pluginName: 'PluginB', platforms: '.iOS( .v16 ),\n .macOS("26.0")'),
            ),
        );
        final (Version retryHighestVersion, bool retrySkipped) = await pluginSwiftDependencies
            .determineHighestSupportedVersion(manifests: manifests, cacheDirectory: cacheDirectory);
        expect(retryHighestVersion, Version(16, 0, 0));
        expect(retrySkipped, isFalse);
      });

      testWithoutContext('determineHighestSupportedVersion matches using swift', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        fs.file(commandFilePath).createSync(recursive: true);
        final processManager = FakeProcessManager.list([
          const FakeCommand(
            command: ['swift', 'package', 'dump-package'],
            workingDirectory: 'PluginA',
            stdout: '''
{
  "name" : "PluginA",
  "platforms" : [
    {
      "options" : [

      ],
      "platformName" : "ios",
      "version" : "15.0"
    },
    {
      "options" : [

      ],
      "platformName" : "macos",
      "version" : "26.0"
    }
  ]
}
''',
          ),
        ]);
        const FlutterDarwinPlatform targetPlatform = .ios;
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(),
          fileSystem: fs,
          flutterRoot: flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final pluginSwiftDependencies = FlutterPluginSwiftDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final Directory cacheDirectory = fs.directory(cacheDirectoryPath);
        final List<File> manifests = [
          fs.file('PluginA/Package.swift')
            ..createSync(recursive: true)
            ..writeAsStringSync(_pluginManifest(pluginName: 'PluginA', platforms: 'someVar')),
        ];
        final (Version highestVersion, bool skipped) = await pluginSwiftDependencies
            .determineHighestSupportedVersion(manifests: manifests, cacheDirectory: cacheDirectory);
        expect(highestVersion, Version(15, 0, 0));
        expect(skipped, isFalse);

        // Verify it uses cache next time it runs (process is not called again)
        final (Version retryHighestVersion, bool retrySkipped) = await pluginSwiftDependencies
            .determineHighestSupportedVersion(manifests: manifests, cacheDirectory: cacheDirectory);
        expect(retryHighestVersion, Version(15, 0, 0));
        expect(retrySkipped, isTrue);
      });

      testWithoutContext('generateDependencies', () {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final processManager = FakeProcessManager.list([]);
        const FlutterDarwinPlatform targetPlatform = .ios;
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(),
          fileSystem: fs,
          flutterRoot: flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final pluginSwiftDependencies = FlutterPluginSwiftDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final pluginA = FakePlugin(name: 'plugin_a', darwinPlatform: targetPlatform);
        fs.file(
            fs.path.join(pluginA.pluginSwiftPackagePath(fs, targetPlatform.name)!, 'Package.swift'),
          )
          ..createSync(recursive: true)
          ..writeAsStringSync(_pluginManifest(pluginName: 'plugin_a'));
        pluginSwiftDependencies.copiedPlugins.add((pluginA, '$pluginsDirectoryPath/plugin_a'));

        final Directory packagesForConfiguration = fs.directory(
          '$pluginRegistrantSwiftPackagePath/Release/Packages',
        );

        final (
          List<SwiftPackagePackageDependency> pluginPackageDependencies,
          List<SwiftPackageTargetDependency> pluginTargetDependencies,
        ) = pluginSwiftDependencies.generateDependencies(
          packagesForConfiguration: fs.directory(
            '$pluginRegistrantSwiftPackagePath/Release/Packages',
          ),
        );
        expect(
          packagesForConfiguration.childLink(pluginA.name).targetSync(),
          '../../Plugins/plugin_a',
        );
        expect(
          pluginPackageDependencies.first.format().endsWith(
            '.package(name: "plugin_a", path: "Sources/Packages/plugin_a")',
          ),
          isTrue,
        );
        expect(
          pluginTargetDependencies.first.format().endsWith(
            '.product(name: "plugin-a", package: "plugin_a")',
          ),
          isTrue,
        );
      });
    });
  });

  group('macos', () {
    group('FlutterPluginRegistrantSwiftPackage', () {
      testWithoutContext('generateSwiftPackage', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final processManager = FakeProcessManager.list([]);
        const FlutterDarwinPlatform targetPlatform = .macos;
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(),
          fileSystem: fs,
          flutterRoot: flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final package = FlutterPluginRegistrantSwiftPackage(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final pluginSwiftDependencies = FlutterPluginSwiftDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final Directory swiftPackageOutput = fs.directory(pluginRegistrantSwiftPackagePath);
        final pluginA = FakePlugin(name: 'PluginA', darwinPlatform: targetPlatform);
        pluginSwiftDependencies.copiedPlugins.add((pluginA, '$pluginsDirectoryPath/PluginA'));

        await package.generateSwiftPackage(
          pluginRegistrantSwiftPackage: swiftPackageOutput,
          plugins: [pluginA],
          xcodeBuildConfiguration: 'Debug',
          pluginSwiftDependencies: pluginSwiftDependencies,
        );

        expect(logger.traceText, isEmpty);
        expect(processManager.hasRemainingExpectations, false);
        final File generatedPackageManifest = swiftPackageOutput
            .childDirectory('Debug')
            .childFile('Package.swift');
        expect(generatedPackageManifest, exists);
        expect(generatedPackageManifest.readAsStringSync(), '''
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
//  Generated file. Do not edit.
//

import PackageDescription

// Debug

let package = Package(
    name: "FlutterPluginRegistrant",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "FlutterPluginRegistrant", type: .static, targets: ["FlutterPluginRegistrant"])
    ],
    dependencies: [
        .package(name: "PluginA", path: "Sources/Packages/PluginA")
    ],
    targets: [
        .target(
            name: "FlutterPluginRegistrant",
            dependencies: [
                .product(name: "PluginA", package: "PluginA")
            ]
        )
    ]
)
''');
        final File generatedSourceImplementation = swiftPackageOutput
            .childDirectory('Debug')
            .childDirectory('FlutterPluginRegistrant')
            .childFile('GeneratedPluginRegistrant.swift');
        expect(generatedSourceImplementation, exists);
        expect(generatedSourceImplementation.readAsStringSync(), '''
//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import PluginA

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  PluginAPlugin.register(with: registry.registrar(forPlugin: "PluginAPlugin"))
}
''');
      });
    });

    group('FlutterPluginDependencies', () {
      testWithoutContext('processPlugins', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final processManager = FakeProcessManager.list([]);
        const FlutterDarwinPlatform targetPlatform = .macos;
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(),
          fileSystem: fs,
          flutterRoot: flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final pluginSwiftDependencies = FlutterPluginSwiftDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final pluginA = FakePlugin(name: 'PluginA', darwinPlatform: targetPlatform);
        fs.file(
            fs.path.join(pluginA.pluginSwiftPackagePath(fs, targetPlatform.name)!, 'Package.swift'),
          )
          ..createSync(recursive: true)
          ..writeAsStringSync(_pluginManifest(pluginName: 'PluginA', platforms: '.macOS("11")'));
        final pluginB = FakePlugin(
          name: 'PluginB',
          darwinPlatform: targetPlatform,
          supportsSwiftPM: false,
        );
        final pluginC = FakePlugin(name: 'PluginC', darwinPlatform: targetPlatform);
        fs.file(
            fs.path.join(pluginC.pluginSwiftPackagePath(fs, targetPlatform.name)!, 'Package.swift'),
          )
          ..createSync(recursive: true)
          ..writeAsStringSync(_pluginManifest(pluginName: 'PluginC'));

        final Directory pluginsDirectory = fs.directory(pluginsDirectoryPath);
        await pluginSwiftDependencies.processPlugins(
          cacheDirectory: fs.directory(cacheDirectoryPath),
          plugins: [pluginA, pluginB, pluginC],
          pluginsDirectory: pluginsDirectory,
        );
        expect(pluginsDirectory.listSync().length, 2);
        expect(pluginSwiftDependencies.highestSupportedVersion.version, Version(11, 0, 0));
      });

      testWithoutContext('determineHighestSupportedVersion matches using regex', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final processManager = FakeProcessManager.list([]);
        const FlutterDarwinPlatform targetPlatform = .macos;
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(),
          fileSystem: fs,
          flutterRoot: flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final pluginSwiftDependencies = FlutterPluginSwiftDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final Directory cacheDirectory = fs.directory(cacheDirectoryPath);
        final List<File> manifests = [
          fs.file('PluginA/Package.swift')
            ..createSync(recursive: true)
            ..writeAsStringSync(
              _pluginManifest(pluginName: 'PluginA', platforms: '.macOS("10.16")'),
            ),
        ];
        final (Version highestVersion, bool skipped) = await pluginSwiftDependencies
            .determineHighestSupportedVersion(manifests: manifests, cacheDirectory: cacheDirectory);
        expect(highestVersion, Version(10, 16, 0));
        expect(skipped, isFalse);

        manifests.add(
          fs.file('PluginB/Package.swift')
            ..createSync(recursive: true)
            ..writeAsStringSync(
              _pluginManifest(
                pluginName: 'PluginB',
                platforms: '.iOS( .v16 ),\n .macOS( .v11_15 )',
              ),
            ),
        );
        final (Version retryHighestVersion, bool retrySkipped) = await pluginSwiftDependencies
            .determineHighestSupportedVersion(manifests: manifests, cacheDirectory: cacheDirectory);
        expect(retryHighestVersion, Version(11, 15, 0));
        expect(retrySkipped, isFalse);
      });

      testWithoutContext('determineHighestSupportedVersion matches using swift', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        fs.file(commandFilePath).createSync(recursive: true);
        final processManager = FakeProcessManager.list([
          const FakeCommand(
            command: ['swift', 'package', 'dump-package'],
            workingDirectory: 'PluginA',
            stdout: '''
{
  "name" : "PluginA",
  "platforms" : [
    {
      "options" : [

      ],
      "platformName" : "ios",
      "version" : "15.0"
    },
    {
      "options" : [

      ],
      "platformName" : "macos",
      "version" : "26.0"
    }
  ]
}
''',
          ),
        ]);
        const FlutterDarwinPlatform targetPlatform = .macos;
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(),
          fileSystem: fs,
          flutterRoot: flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final pluginSwiftDependencies = FlutterPluginSwiftDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final Directory cacheDirectory = fs.directory(cacheDirectoryPath);
        final List<File> manifests = [
          fs.file('PluginA/Package.swift')
            ..createSync(recursive: true)
            ..writeAsStringSync(_pluginManifest(pluginName: 'PluginA', platforms: 'someVar')),
        ];
        final (Version highestVersion, bool skipped) = await pluginSwiftDependencies
            .determineHighestSupportedVersion(manifests: manifests, cacheDirectory: cacheDirectory);
        expect(highestVersion, Version(26, 0, 0));
        expect(skipped, isFalse);

        // Verify it uses cache next time it runs (process is not called again)
        final (Version retryHighestVersion, bool retrySkipped) = await pluginSwiftDependencies
            .determineHighestSupportedVersion(manifests: manifests, cacheDirectory: cacheDirectory);
        expect(retryHighestVersion, Version(26, 0, 0));
        expect(retrySkipped, isTrue);
      });

      testWithoutContext('generateDependencies', () {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final processManager = FakeProcessManager.list([]);
        const FlutterDarwinPlatform targetPlatform = .macos;
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(),
          fileSystem: fs,
          flutterRoot: flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final pluginSwiftDependencies = FlutterPluginSwiftDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final pluginA = FakePlugin(name: 'plugin_a', darwinPlatform: targetPlatform);
        fs.file(
            fs.path.join(pluginA.pluginSwiftPackagePath(fs, targetPlatform.name)!, 'Package.swift'),
          )
          ..createSync(recursive: true)
          ..writeAsStringSync(_pluginManifest(pluginName: 'plugin_a'));
        pluginSwiftDependencies.copiedPlugins.add((pluginA, '$pluginsDirectoryPath/plugin_a'));

        final Directory packagesForConfiguration = fs.directory(
          '$pluginRegistrantSwiftPackagePath/Release/Packages',
        );

        final (
          List<SwiftPackagePackageDependency> pluginPackageDependencies,
          List<SwiftPackageTargetDependency> pluginTargetDependencies,
        ) = pluginSwiftDependencies.generateDependencies(
          packagesForConfiguration: fs.directory(
            '$pluginRegistrantSwiftPackagePath/Release/Packages',
          ),
        );
        expect(
          packagesForConfiguration.childLink(pluginA.name).targetSync(),
          '../../Plugins/plugin_a',
        );
        expect(
          pluginPackageDependencies.first.format().endsWith(
            '.package(name: "plugin_a", path: "Sources/Packages/plugin_a")',
          ),
          isTrue,
        );
        expect(
          pluginTargetDependencies.first.format().endsWith(
            '.product(name: "plugin-a", package: "plugin_a")',
          ),
          isTrue,
        );
      });
    });
  });
}

String _pluginManifest({required String pluginName, String platforms = ''}) {
  if (platforms.isNotEmpty) {
    platforms =
        '''
    platforms: [
        $platforms
    ],
''';
  }
  return '''
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "$pluginName",$platforms
    products: [
        .library(name: "${pluginName.replaceAll('_', '-')}", targets: ["$pluginName"])
    ],
    targets: [
        .target(
            name: "$pluginName",
        )
    ]
)
''';
}

class FakeAnalytics extends Fake implements Analytics {}

class FakeXcode extends Fake implements Xcode {}

class FakeFlutterVersion extends Fake implements FlutterVersion {}

class FakeArtifacts extends Fake implements Artifacts {
  FakeArtifacts(this.engineArtifactPath);

  final String engineArtifactPath;
  @override
  String getArtifactPath(
    Artifact artifact, {
    TargetPlatform? platform,
    BuildMode? mode,
    EnvironmentType? environmentType,
  }) {
    return engineArtifactPath;
  }
}

class FakeBuildSystem extends Fake implements BuildSystem {}

class FakeCache extends Fake implements Cache {}

class FakeFlutterProject extends Fake implements FlutterProject {
  @override
  bool get isModule => false;
}

class FakePlugin extends Fake implements Plugin {
  FakePlugin({required this.name, required this.darwinPlatform, this.supportsSwiftPM = true});

  @override
  final String name;

  final FlutterDarwinPlatform darwinPlatform;
  final bool supportsSwiftPM;

  @override
  String get path => '/path/to/$name';

  @override
  late final Map<String, PluginPlatform> platforms = {
    darwinPlatform.name: darwinPlatform == FlutterDarwinPlatform.macos
        ? MacOSPlugin(name: name, pluginClass: '${name}Plugin')
        : IOSPlugin(name: name, classPrefix: '', pluginClass: '${name}Plugin'),
  };

  @override
  String? pluginSwiftPackagePath(FileSystem fileSystem, String platform, {String? overridePath}) {
    return fileSystem.path.join(path, platform, name);
  }

  @override
  bool supportSwiftPackageManagerForPlatform(FileSystem fileSystem, String platform) {
    return supportsSwiftPM;
  }
}

class FakeFeatureFlags extends Fake implements FeatureFlags {}
