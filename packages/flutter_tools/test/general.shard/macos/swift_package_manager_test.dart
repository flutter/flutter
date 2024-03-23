// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/isolated/mustache_template.dart';
import 'package:flutter_tools/src/macos/swift_package_manager.dart';
import 'package:flutter_tools/src/platform_plugins.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';

const String _doubleIndent = '        ';

void main() {
  const List<SupportedPlatform> supportedPlatforms = <SupportedPlatform>[SupportedPlatform.ios, SupportedPlatform.macos];

  group('SwiftPackageManager', () {
    for (final SupportedPlatform platform in supportedPlatforms) {
      group('for ${platform.name}', () {

        group('generatePluginsSwiftPackage', () {
          testWithoutContext('throw if invalid platform', () async {
            final MemoryFileSystem fs = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(fileSystem: fs);

            final FakeSwiftPackageManager spm = FakeSwiftPackageManager(
              artifacts: Artifacts.test(fileSystem: fs),
              fileSystem: fs,
              logger: testLogger,
              templateRenderer: const MustacheTemplateRenderer(),
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              plistParser: FakePlistParser(),
            );

            await expectLater(() => spm.generatePluginsSwiftPackage(
                <Plugin>[],
                SupportedPlatform.android,
                project,
              ),
              throwsToolExit(message: 'The platform android is not compatible with Swift Package Manager. Only iOS and macOS is allowed.'),
            );
          });

          testWithoutContext('skip if no dependencies and not already migrated', () async {
            final MemoryFileSystem fs = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(fileSystem: fs);

            final FakeSwiftPackageManager spm = FakeSwiftPackageManager(
              artifacts: Artifacts.test(fileSystem: fs),
              fileSystem: fs,
              logger: testLogger,
              templateRenderer: const MustacheTemplateRenderer(),
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              plistParser: FakePlistParser(),
            );
            await spm.generatePluginsSwiftPackage(
              <Plugin>[],
              platform,
              project,
            );

            final File swiftManifest = fs.file('app_name/ios/Flutter/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift');
            expect(swiftManifest.existsSync(), isFalse);
            expect(spm.migrated, isFalse);
          });

          testWithoutContext('generate if no dependencies and already migrated', () async {
            final MemoryFileSystem fs = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(fileSystem: fs);
            project.xcodeProjectInfoFile.createSync(recursive: true);
            project.xcodeProjectInfoFile.writeAsStringSync('''
'		78A318202AECB46A00862997 /* FlutterGeneratedPluginSwiftPackage in Frameworks */ = {isa = PBXBuildFile; productRef = 78A3181F2AECB46A00862997 /* FlutterGeneratedPluginSwiftPackage */; };';
''');

            final FakeSwiftPackageManager spm = FakeSwiftPackageManager(
              artifacts: Artifacts.test(fileSystem: fs),
              fileSystem: fs,
              logger: testLogger,
              templateRenderer: const MustacheTemplateRenderer(),
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              plistParser: FakePlistParser(),
            );
            await spm.generatePluginsSwiftPackage(
              <Plugin>[],
              platform,
              project,
            );

            final File swiftManifest = fs.file('app_name/ios/Flutter/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift');
            expect(swiftManifest.existsSync(), isTrue);
            final String supportedPlatform = platform == SupportedPlatform.ios ? '.iOS("12.0")' : '.macOS("10.14")';
            expect(swiftManifest.readAsStringSync(), '''
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
//  Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        $supportedPlatform
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
$_doubleIndent
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage"
        )
    ]
)
''');
            expect(spm.migrated, isTrue);
          });

          testWithoutContext('generate with single dependency', () async {
            final MemoryFileSystem fs = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(fileSystem: fs);

            final File validPlugin1Manifest = fs.file('/local/path/to/plugins/valid_plugin_1/Package.swift')..createSync(recursive: true);
            final FakePlugin validPlugin1 = FakePlugin(
              name: 'valid_plugin_1',
              platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
              pluginSwiftPackageManifestPath: validPlugin1Manifest.path,
            );
            final FakeSwiftPackageManager spm = FakeSwiftPackageManager(
              artifacts: Artifacts.test(fileSystem: fs),
              fileSystem: fs,
              logger: testLogger,
              templateRenderer: const MustacheTemplateRenderer(),
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              plistParser: FakePlistParser(),
            );
            await spm.generatePluginsSwiftPackage(
              <Plugin>[
                validPlugin1,
              ],
              platform,
              project,
            );
            final File swiftManifest = fs.file('app_name/ios/Flutter/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift');

            final String supportedPlatform = platform == SupportedPlatform.ios ? '.iOS("12.0")' : '.macOS("10.14")';
            final String frameworkName = platform == SupportedPlatform.ios ? 'Flutter' : 'FlutterMacOS';
            expect(swiftManifest.existsSync(), isTrue);
            expect(swiftManifest.readAsStringSync(), '''
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
//  Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        $supportedPlatform
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "valid_plugin_1", path: "/local/path/to/plugins/valid_plugin_1")
    ],
    targets: [
        .binaryTarget(
            name: "$frameworkName",
            path: "$frameworkName.xcframework"
        ),
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .target(name: "$frameworkName"),
                .product(name: "valid_plugin_1", package: "valid_plugin_1")
            ]
        )
    ]
)
''');
            final Link engineLink = fs.link('app_name/ios/Flutter/Packages/FlutterGeneratedPluginSwiftPackage/$frameworkName.xcframework');
            final String expectedArtifactPath = platform == SupportedPlatform.ios ? 'Artifact.flutterXcframework.TargetPlatform.ios.release' : 'Artifact.flutterMacOSXcframework.TargetPlatform.darwin.release';
            expect(await engineLink.target(), expectedArtifactPath);
            expect(spm.migrated, isTrue);
          });

          testWithoutContext('generate with multiple dependencies', () async {
            final MemoryFileSystem fs = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(fileSystem: fs);

            final FakePlugin nonPlatformCompatiblePlugin = FakePlugin(
              name: 'invalid_plugin_due_to_incompatible_platform',
              platforms: <String, PluginPlatform>{},
              pluginSwiftPackageManifestPath: '/some/path',
            );
            final FakePlugin pluginSwiftPackageManifestIsNull = FakePlugin(
              name: 'invalid_plugin_due_to_null_plugin_swift_package_path',
              platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
              pluginSwiftPackageManifestPath: null,
            );
            final FakePlugin pluginSwiftPackageManifestNotExists = FakePlugin(
              name: 'invalid_plugin_due_to_plugin_swift_package_path_does_not_exist',
              platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
              pluginSwiftPackageManifestPath: '/some/path',
            );

            final File validPlugin1Manifest = fs.file('/local/path/to/plugins/valid_plugin_1/Package.swift')..createSync(recursive: true);
            final FakePlugin validPlugin1 = FakePlugin(
              name: 'valid_plugin_1',
              platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
              pluginSwiftPackageManifestPath: validPlugin1Manifest.path,
            );
            final File validPlugin2Manifest = fs.file('/.pub-cache/plugins/valid_plugin_2/Package.swift')..createSync(recursive: true);
            final FakePlugin validPlugin2 = FakePlugin(
              name: 'valid_plugin_2',
              platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
              pluginSwiftPackageManifestPath: validPlugin2Manifest.path,
            );

            final FakeSwiftPackageManager spm = FakeSwiftPackageManager(
              artifacts: Artifacts.test(fileSystem: fs),
              fileSystem: fs,
              logger: testLogger,
              templateRenderer: const MustacheTemplateRenderer(),
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              plistParser: FakePlistParser(),
            );
            await spm.generatePluginsSwiftPackage(
              <Plugin>[
                nonPlatformCompatiblePlugin,
                pluginSwiftPackageManifestIsNull,
                pluginSwiftPackageManifestNotExists,
                validPlugin1,
                validPlugin2,
              ],
              platform,
              project,
            );
            final File swiftManifest = fs.file('app_name/ios/Flutter/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift');

            final String supportedPlatform = platform == SupportedPlatform.ios ? '.iOS("12.0")' : '.macOS("10.14")';
            final String frameworkName = platform == SupportedPlatform.ios ? 'Flutter' : 'FlutterMacOS';
            expect(swiftManifest.existsSync(), isTrue);
            expect(swiftManifest.readAsStringSync(), '''
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
//  Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        $supportedPlatform
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "valid_plugin_1", path: "/local/path/to/plugins/valid_plugin_1"),
        .package(name: "valid_plugin_2", path: "/.pub-cache/plugins/valid_plugin_2")
    ],
    targets: [
        .binaryTarget(
            name: "$frameworkName",
            path: "$frameworkName.xcframework"
        ),
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .target(name: "$frameworkName"),
                .product(name: "valid_plugin_1", package: "valid_plugin_1"),
                .product(name: "valid_plugin_2", package: "valid_plugin_2")
            ]
        )
    ]
)
''');
            final Link engineLink = fs.link('app_name/ios/Flutter/Packages/FlutterGeneratedPluginSwiftPackage/$frameworkName.xcframework');
            final String expectedArtifactPath = platform == SupportedPlatform.ios ? 'Artifact.flutterXcframework.TargetPlatform.ios.release' : 'Artifact.flutterMacOSXcframework.TargetPlatform.darwin.release';
            expect(await engineLink.target(), expectedArtifactPath);
            expect(spm.migrated, isTrue);
          });
        });

        group('flutterSwiftPackageInProjectSettings', () {
          testWithoutContext('is false if pbxproj missing', () {
            final MemoryFileSystem fs = MemoryFileSystem();
            final FakeIosProject project = FakeIosProject(fileSystem: fs);
            expect(SwiftPackageManager.flutterSwiftPackageInProjectSettings(project), isFalse);
          });

          testWithoutContext('is false if pbxproj does not contain FlutterGeneratedPluginSwiftPackage in build process', () {
            final MemoryFileSystem fs = MemoryFileSystem();
            final FakeIosProject project = FakeIosProject(fileSystem: fs);
            project.xcodeProjectInfoFile.createSync(recursive: true);
            expect(SwiftPackageManager.flutterSwiftPackageInProjectSettings(project), isFalse);
          });

          testWithoutContext('is true if pbxproj does contain FlutterGeneratedPluginSwiftPackage in build process', () {
            final MemoryFileSystem fs = MemoryFileSystem();
            final FakeIosProject project = FakeIosProject(fileSystem: fs);
            project.xcodeProjectInfoFile.createSync(recursive: true);
            project.xcodeProjectInfoFile.writeAsStringSync('''
'		78A318202AECB46A00862997 /* FlutterGeneratedPluginSwiftPackage in Frameworks */ = {isa = PBXBuildFile; productRef = 78A3181F2AECB46A00862997 /* FlutterGeneratedPluginSwiftPackage */; };';
''');
            expect(SwiftPackageManager.flutterSwiftPackageInProjectSettings(project), isTrue);
          });
        });

        group('linkFlutterFramework', () {
          testWithoutContext('throw if invalid platform', () {
            final MemoryFileSystem fs = MemoryFileSystem();
            final FakeIosProject project = FakeIosProject(fileSystem: fs);
            final BufferLogger testLogger = BufferLogger.test();

            expect(() => SwiftPackageManager.linkFlutterFramework(
                SupportedPlatform.android,
                project,
                BuildMode.debug,
                artifacts: Artifacts.test(fileSystem: fs),
                fileSystem: fs,
                logger: testLogger,
              ),
              throwsToolExit(message: 'The platform android is not compatible with Swift Package Manager. Only iOS and macOS is allowed.'),
            );
          });

          testWithoutContext('skips if missing FlutterGeneratedPluginSwiftPackage', () {
            final MemoryFileSystem fs = MemoryFileSystem();
            final FakeIosProject project = FakeIosProject(fileSystem: fs);
            final BufferLogger testLogger = BufferLogger.test();

            SwiftPackageManager.linkFlutterFramework(
              platform,
              project,
              BuildMode.debug,
              artifacts: Artifacts.test(fileSystem: fs),
              fileSystem: fs,
              logger: testLogger,
            );
            final String frameworkName = platform == SupportedPlatform.ios ? 'Flutter' : 'FlutterMacOS';
            expect(testLogger.traceText, contains('FlutterGeneratedPluginSwiftPackage does not exist, skipping adding link to $frameworkName.'));
          });

          testWithoutContext('creates link if missing', () async {
            final MemoryFileSystem fs = MemoryFileSystem();
            final FakeIosProject project = FakeIosProject(fileSystem: fs);
            final BufferLogger testLogger = BufferLogger.test();
            fs.file('app_name/ios/Flutter/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift').createSync(recursive: true);

            SwiftPackageManager.linkFlutterFramework(
              platform,
              project,
              BuildMode.debug,
              artifacts: Artifacts.test(fileSystem: fs),
              fileSystem: fs,
              logger: testLogger,
            );
            final String frameworkName = platform == SupportedPlatform.ios ? 'Flutter' : 'FlutterMacOS';
            final Link engineLink = fs.link('app_name/ios/Flutter/Packages/FlutterGeneratedPluginSwiftPackage/$frameworkName.xcframework');
            final String expectedArtifactPath = platform == SupportedPlatform.ios ? 'Artifact.flutterXcframework.TargetPlatform.ios.debug' : 'Artifact.flutterMacOSXcframework.TargetPlatform.darwin.debug';
            expect(testLogger.traceText, isEmpty);
            expect(await engineLink.target(), expectedArtifactPath);
          });

          testWithoutContext('updates link if changed', () async {
            final MemoryFileSystem fs = MemoryFileSystem();
            final FakeIosProject project = FakeIosProject(fileSystem: fs);
            final BufferLogger testLogger = BufferLogger.test();
            fs.file('app_name/ios/Flutter/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift').createSync(recursive: true);

            final String frameworkName = platform == SupportedPlatform.ios ? 'Flutter' : 'FlutterMacOS';
            final Link engineLink = fs.link('app_name/ios/Flutter/Packages/FlutterGeneratedPluginSwiftPackage/$frameworkName.xcframework');
            const String originalTarget = 'Artifact.flutterXcframework.TargetPlatform.ios.debug';
            engineLink.createSync(originalTarget, recursive: true);
            expect(await engineLink.target(), originalTarget);

            SwiftPackageManager.linkFlutterFramework(
              platform,
              project,
              BuildMode.release,
              artifacts: Artifacts.test(fileSystem: fs),
              fileSystem: fs,
              logger: testLogger,
            );
            final String expectedArtifactPath = platform == SupportedPlatform.ios ? 'Artifact.flutterXcframework.TargetPlatform.ios.release' : 'Artifact.flutterMacOSXcframework.TargetPlatform.darwin.release';
            expect(testLogger.traceText, isEmpty);
            expect(await engineLink.target(), expectedArtifactPath);
          });
        });
      });
    }
  });
}

class FakeSwiftPackageManager extends SwiftPackageManager {
  FakeSwiftPackageManager({
    required super.artifacts,
    required super.fileSystem,
    required super.logger,
    required super.templateRenderer,
    required super.xcodeProjectInterpreter,
    required super.plistParser,
  });

  bool migrated = false;

  @override
  Future<void> migrateProject(XcodeBasedProject project, SupportedPlatform platform) async {
    migrated = true;
  }
}

class FakeIosProject extends Fake implements IosProject {
  FakeIosProject({
    required MemoryFileSystem fileSystem,
  }) : hostAppRoot = fileSystem.directory('app_name').childDirectory('ios'),
       xcodeProjectInfoFile = fileSystem.directory('app_name').childDirectory('ios').childDirectory('Runner.xcodeproj').childFile('project.pbxproj'),
       flutterPluginSwiftPackageDirectory = fileSystem.directory('app_name').childDirectory('ios').childDirectory('Flutter').childDirectory('Packages').childDirectory('FlutterGeneratedPluginSwiftPackage'),
       flutterPluginSwiftPackageManifest = fileSystem.directory('app_name').childDirectory('ios').childDirectory('Flutter').childDirectory('Packages').childDirectory('FlutterGeneratedPluginSwiftPackage').childFile('Package.swift');

  @override
  Directory hostAppRoot;

  @override
  File xcodeProjectInfoFile;

  @override
  String hostAppProjectName = 'Runner';

  @override
  Directory flutterPluginSwiftPackageDirectory;

  @override
  File flutterPluginSwiftPackageManifest;
}

class FakePlugin extends Fake implements Plugin {
  FakePlugin({
    required this.name,
    required this.platforms,
    required String? pluginSwiftPackageManifestPath,
  }) : _pluginSwiftPackageManifestPath = pluginSwiftPackageManifestPath;

  final String? _pluginSwiftPackageManifestPath;

  @override
  final String name;

  @override
  final Map<String, PluginPlatform> platforms;

  @override
  String? pluginSwiftPackageManifestPath(
    FileSystem fileSystem,
    String platform,
  ) {
    return _pluginSwiftPackageManifestPath;
  }
}

class FakePluginPlatform extends Fake implements PluginPlatform {}

class FakeXcodeProjectInterpreter extends Fake implements XcodeProjectInterpreter {}

class FakePlistParser extends Fake implements PlistParser {}
