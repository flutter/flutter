// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/darwin/darwin.dart';
import 'package:flutter_tools/src/isolated/mustache_template.dart';
import 'package:flutter_tools/src/macos/swift_package_manager.dart';
import 'package:flutter_tools/src/platform_plugins.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';

const _doubleIndent = '        ';

void main() {
  const supportedPlatforms = <FlutterDarwinPlatform>[
    FlutterDarwinPlatform.ios,
    FlutterDarwinPlatform.macos,
  ];

  group('SwiftPackageManager', () {
    for (final platform in supportedPlatforms) {
      group('for ${platform.name}', () {
        group('generatePluginsSwiftPackage', () {
          testWithoutContext('skip if no dependencies and not already migrated', () async {
            final fs = MemoryFileSystem();
            final project = FakeXcodeProject(platform: platform.name, fileSystem: fs);

            final spm = SwiftPackageManager(
              fileSystem: fs,
              templateRenderer: const MustacheTemplateRenderer(),
            );
            await spm.generatePluginsSwiftPackage(<Plugin>[], platform, project);

            expect(project.flutterPluginSwiftPackageManifest.existsSync(), isFalse);
          });

          testWithoutContext('generate if no dependencies and already migrated', () async {
            final fs = MemoryFileSystem();
            final project = FakeXcodeProject(platform: platform.name, fileSystem: fs);
            project.xcodeProjectInfoFile.createSync(recursive: true);
            project.xcodeProjectInfoFile.writeAsStringSync('''
'		78A318202AECB46A00862997 /* FlutterGeneratedPluginSwiftPackage in Frameworks */ = {isa = PBXBuildFile; productRef = 78A3181F2AECB46A00862997 /* FlutterGeneratedPluginSwiftPackage */; };';
''');

            final spm = SwiftPackageManager(
              fileSystem: fs,
              templateRenderer: const MustacheTemplateRenderer(),
            );
            await spm.generatePluginsSwiftPackage(<Plugin>[], platform, project);

            final supportedPlatform = platform == FlutterDarwinPlatform.ios
                ? '.iOS("13.0")'
                : '.macOS("10.15")';
            expect(project.flutterPluginSwiftPackageManifest.existsSync(), isTrue);
            expect(project.flutterPluginSwiftPackageManifest.readAsStringSync(), '''
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
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
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
          });

          testWithoutContext('generate with single dependency', () async {
            final fs = MemoryFileSystem();
            final project = FakeXcodeProject(platform: platform.name, fileSystem: fs);

            final Directory validPlugin1Directory = fs.directory(
              '/local/path/to/plugins/valid_plugin_1',
            );
            validPlugin1Directory.childFile('Package.swift').createSync(recursive: true);

            final validPlugin1 = FakePlugin(
              name: 'valid_plugin_1',
              platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
              pluginSwiftPackagePath: validPlugin1Directory.path,
            );
            final spm = SwiftPackageManager(
              fileSystem: fs,
              templateRenderer: const MustacheTemplateRenderer(),
            );
            await spm.generatePluginsSwiftPackage(<Plugin>[validPlugin1], platform, project);

            final supportedPlatform = platform == FlutterDarwinPlatform.ios
                ? '.iOS("13.0")'
                : '.macOS("10.15")';
            expect(project.flutterPluginSwiftPackageManifest.existsSync(), isTrue);
            expect(project.relativeSwiftPackagesDirectory.childLink('valid_plugin_1'), exists);
            expect(
              project.relativeSwiftPackagesDirectory.childLink('valid_plugin_1').targetSync(),
              validPlugin1Directory.path,
            );
            expect(project.flutterPluginSwiftPackageManifest.readAsStringSync(), '''
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
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "valid_plugin_1", path: "../.packages/valid_plugin_1")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "valid-plugin-1", package: "valid_plugin_1")
            ]
        )
    ]
)
''');
          });

          testWithoutContext('generate with multiple dependencies', () async {
            final fs = MemoryFileSystem();
            final project = FakeXcodeProject(platform: platform.name, fileSystem: fs);
            final nonPlatformCompatiblePlugin = FakePlugin(
              name: 'invalid_plugin_due_to_incompatible_platform',
              platforms: <String, PluginPlatform>{},
              pluginSwiftPackagePath: '/some/path',
            );
            final pluginSwiftPackageManifestIsNull = FakePlugin(
              name: 'invalid_plugin_due_to_null_plugin_swift_package_path',
              platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
              pluginSwiftPackagePath: null,
            );
            final pluginSwiftPackageManifestNotExists = FakePlugin(
              name: 'invalid_plugin_due_to_plugin_swift_package_path_does_not_exist',
              platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
              pluginSwiftPackagePath: '/some/path',
            );

            final Directory validPlugin1Directory = fs.directory(
              '/local/path/to/plugins/valid_plugin_1',
            );
            validPlugin1Directory.childFile('Package.swift').createSync(recursive: true);
            final validPlugin1 = FakePlugin(
              name: 'valid_plugin_1',
              platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
              pluginSwiftPackagePath: validPlugin1Directory.path,
            );

            final Directory validPlugin2Directory = fs.directory(
              '/.pub-cache/plugins/valid_plugin_2',
            );
            validPlugin2Directory.childFile('Package.swift').createSync(recursive: true);

            final validPlugin2 = FakePlugin(
              name: 'valid_plugin_2',
              platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
              pluginSwiftPackagePath: validPlugin2Directory.path,
            );

            final spm = SwiftPackageManager(
              fileSystem: fs,
              templateRenderer: const MustacheTemplateRenderer(),
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

            final supportedPlatform = platform == FlutterDarwinPlatform.ios
                ? '.iOS("13.0")'
                : '.macOS("10.15")';
            expect(project.flutterPluginSwiftPackageManifest.existsSync(), isTrue);
            expect(project.relativeSwiftPackagesDirectory.childLink('valid_plugin_1'), exists);
            expect(
              project.relativeSwiftPackagesDirectory.childLink('valid_plugin_1').targetSync(),
              validPlugin1Directory.path,
            );
            expect(project.relativeSwiftPackagesDirectory.childLink('valid_plugin_2'), exists);
            expect(
              project.relativeSwiftPackagesDirectory.childLink('valid_plugin_2').targetSync(),
              validPlugin2Directory.path,
            );
            expect(project.flutterPluginSwiftPackageManifest.readAsStringSync(), '''
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
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "valid_plugin_1", path: "../.packages/valid_plugin_1"),
        .package(name: "valid_plugin_2", path: "../.packages/valid_plugin_2")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "valid-plugin-1", package: "valid_plugin_1"),
                .product(name: "valid-plugin-2", package: "valid_plugin_2")
            ]
        )
    ]
)
''');
          });
        });

        group('updateMinimumDeployment', () {
          testWithoutContext('return if invalid deploymentTarget', () {
            final fs = MemoryFileSystem();
            final project = FakeXcodeProject(platform: platform.name, fileSystem: fs);
            final supportedPlatform = platform == FlutterDarwinPlatform.ios
                ? '.iOS("13.0")'
                : '.macOS("10.15")';
            project.flutterPluginSwiftPackageManifest.createSync(recursive: true);
            project.flutterPluginSwiftPackageManifest.writeAsStringSync(supportedPlatform);
            SwiftPackageManager.updateMinimumDeployment(
              project: project,
              platform: platform,
              deploymentTarget: '',
            );
            expect(
              project.flutterPluginSwiftPackageManifest.readAsLinesSync(),
              contains(supportedPlatform),
            );
          });

          testWithoutContext('return if deploymentTarget is lower than default', () {
            final fs = MemoryFileSystem();
            final project = FakeXcodeProject(platform: platform.name, fileSystem: fs);
            final supportedPlatform = platform == FlutterDarwinPlatform.ios
                ? '.iOS("13.0")'
                : '.macOS("10.15")';
            project.flutterPluginSwiftPackageManifest.createSync(recursive: true);
            project.flutterPluginSwiftPackageManifest.writeAsStringSync(supportedPlatform);
            SwiftPackageManager.updateMinimumDeployment(
              project: project,
              platform: platform,
              deploymentTarget: '9.0',
            );
            expect(
              project.flutterPluginSwiftPackageManifest.readAsLinesSync(),
              contains(supportedPlatform),
            );
          });

          testWithoutContext('return if deploymentTarget is same than default', () {
            final fs = MemoryFileSystem();
            final project = FakeXcodeProject(platform: platform.name, fileSystem: fs);
            final supportedPlatform = platform == FlutterDarwinPlatform.ios
                ? '.iOS("13.0")'
                : '.macOS("10.15")';
            project.flutterPluginSwiftPackageManifest.createSync(recursive: true);
            project.flutterPluginSwiftPackageManifest.writeAsStringSync(supportedPlatform);
            SwiftPackageManager.updateMinimumDeployment(
              project: project,
              platform: platform,
              deploymentTarget: platform == FlutterDarwinPlatform.ios ? '13.0' : '10.15',
            );
            expect(
              project.flutterPluginSwiftPackageManifest.readAsLinesSync(),
              contains(supportedPlatform),
            );
          });

          testWithoutContext('update if deploymentTarget is higher than default', () {
            final fs = MemoryFileSystem();
            final project = FakeXcodeProject(platform: platform.name, fileSystem: fs);
            final supportedPlatform = platform == FlutterDarwinPlatform.ios
                ? '.iOS("13.0")'
                : '.macOS("10.15")';
            project.flutterPluginSwiftPackageManifest.createSync(recursive: true);
            project.flutterPluginSwiftPackageManifest.writeAsStringSync(supportedPlatform);
            SwiftPackageManager.updateMinimumDeployment(
              project: project,
              platform: platform,
              deploymentTarget: '14.0',
            );
            expect(
              project.flutterPluginSwiftPackageManifest.readAsLinesSync().contains(
                supportedPlatform,
              ),
              isFalse,
            );
            expect(
              project.flutterPluginSwiftPackageManifest.readAsLinesSync(),
              contains(platform == FlutterDarwinPlatform.ios ? '.iOS("14.0")' : '.macOS("14.0")'),
            );
          });
        });
      });
    }
  });
}

class FakeXcodeProject extends Fake implements IosProject {
  FakeXcodeProject({required MemoryFileSystem fileSystem, required String platform})
    : hostAppRoot = fileSystem.directory('app_name').childDirectory(platform);

  @override
  Directory hostAppRoot;

  @override
  Directory get xcodeProject => hostAppRoot.childDirectory('$hostAppProjectName.xcodeproj');

  @override
  File get xcodeProjectInfoFile => xcodeProject.childFile('project.pbxproj');

  @override
  String hostAppProjectName = 'Runner';

  @override
  Directory get flutterSwiftPackagesDirectory =>
      hostAppRoot.childDirectory('Flutter').childDirectory('ephemeral').childDirectory('Packages');

  @override
  Directory get relativeSwiftPackagesDirectory =>
      flutterSwiftPackagesDirectory.childDirectory('.packages');

  @override
  Directory get flutterPluginSwiftPackageDirectory =>
      flutterSwiftPackagesDirectory.childDirectory('FlutterGeneratedPluginSwiftPackage');

  @override
  File get flutterPluginSwiftPackageManifest =>
      flutterPluginSwiftPackageDirectory.childFile('Package.swift');

  @override
  bool get flutterPluginSwiftPackageInProjectSettings {
    return xcodeProjectInfoFile.existsSync() &&
        xcodeProjectInfoFile.readAsStringSync().contains('FlutterGeneratedPluginSwiftPackage');
  }
}

class FakePlugin extends Fake implements Plugin {
  FakePlugin({required this.name, required this.platforms, required String? pluginSwiftPackagePath})
    : _pluginSwiftPackagePath = pluginSwiftPackagePath;

  final String? _pluginSwiftPackagePath;

  @override
  final String name;

  @override
  final Map<String, PluginPlatform> platforms;

  @override
  String? pluginSwiftPackagePath(FileSystem fileSystem, String platform) {
    return _pluginSwiftPackagePath;
  }

  @override
  String? pluginSwiftPackageManifestPath(FileSystem fileSystem, String platform) {
    if (_pluginSwiftPackagePath == null) {
      return null;
    }
    return '$_pluginSwiftPackagePath/Package.swift';
  }
}

class FakePluginPlatform extends Fake implements PluginPlatform {}
