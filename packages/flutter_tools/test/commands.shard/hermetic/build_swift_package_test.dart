// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_swift_package.dart';
import 'package:flutter_tools/src/darwin/darwin.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/isolated/mustache_template.dart';
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
  const pluginRegistrantSwiftPackagePath = 'output/FlutterPluginRegistrant';
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
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(),
          fileSystem: fs,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final package = FlutterPluginRegistrantSwiftPackage(
          targetPlatform: FlutterDarwinPlatform.ios,
          utils: testUtils,
        );
        final Directory swiftPackageOutput = fs.directory(pluginRegistrantSwiftPackagePath);
        final pluginA = FakePlugin(name: 'PluginA', darwinPlatform: FlutterDarwinPlatform.ios);

        await package.generateSwiftPackage(
          pluginRegistrantSwiftPackage: swiftPackageOutput,
          plugins: [pluginA],
          xcodeBuildConfiguration: 'Debug',
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
    products: [
        .library(name: "FlutterPluginRegistrant", type: .static, targets: ["FlutterPluginRegistrant"])
    ],
    dependencies: [\n        \n    ],
    targets: [
        .target(
            name: "FlutterPluginRegistrant"
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
  });

  group('macos', () {
    group('FlutterPluginRegistrantSwiftPackage', () {
      testWithoutContext('generateSwiftPackage', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final processManager = FakeProcessManager.list([]);
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(),
          fileSystem: fs,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final package = FlutterPluginRegistrantSwiftPackage(
          targetPlatform: FlutterDarwinPlatform.macos,
          utils: testUtils,
        );
        final Directory swiftPackageOutput = fs.directory(pluginRegistrantSwiftPackagePath);
        final pluginA = FakePlugin(name: 'PluginA', darwinPlatform: FlutterDarwinPlatform.macos);

        await package.generateSwiftPackage(
          pluginRegistrantSwiftPackage: swiftPackageOutput,
          plugins: [pluginA],
          xcodeBuildConfiguration: 'Debug',
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
    products: [
        .library(name: "FlutterPluginRegistrant", type: .static, targets: ["FlutterPluginRegistrant"])
    ],
    dependencies: [\n        \n    ],
    targets: [
        .target(
            name: "FlutterPluginRegistrant"
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
  });
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
  FakePlugin({required this.name, required this.darwinPlatform});

  @override
  final String name;

  final FlutterDarwinPlatform darwinPlatform;

  @override
  String get path => '/path/to/$name';

  @override
  late final Map<String, PluginPlatform> platforms = {
    darwinPlatform.name: darwinPlatform == FlutterDarwinPlatform.macos
        ? MacOSPlugin(name: name, pluginClass: '${name}Plugin')
        : IOSPlugin(name: name, classPrefix: '', pluginClass: '${name}Plugin'),
  };
}

class FakeFeatureFlags extends Fake implements FeatureFlags {}
