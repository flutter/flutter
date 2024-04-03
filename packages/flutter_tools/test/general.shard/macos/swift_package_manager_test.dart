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
  const List<SupportedPlatform> supportedPlatforms = <SupportedPlatform>[
    SupportedPlatform.ios,
    SupportedPlatform.macos,
  ];

  group('SwiftPackageManager', () {
    for (final SupportedPlatform platform in supportedPlatforms) {
      group('for ${platform.name}', () {

        group('generatePluginsSwiftPackage', () {
          testWithoutContext('throw if invalid platform', () async {
            final MemoryFileSystem fs = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: fs,
            );

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
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: fs,
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
              <Plugin>[],
              platform,
              project,
            );

            expect(project.flutterPluginSwiftPackageManifest.existsSync(), isFalse);
            expect(spm.migrated, isFalse);
          });

          testWithoutContext('generate if no dependencies and already migrated', () async {
            final MemoryFileSystem fs = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: fs,
            );
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

            expect(
              project.flutterPluginSwiftPackageManifest.existsSync(),
              isTrue,
            );
            expect(
              project.ephemeralSwiftPackageDirectory
                  .childDirectory('.symlinks')
                  .existsSync(),
              isTrue,
            );
            expect(
              project.ephemeralSwiftPackageDirectory
                  .childDirectory('.symlinks')
                  .childDirectory('plugins')
                  .listSync(),
              isEmpty,
            );
            expect(
              project.flutterFrameworkSwiftPackageDirectory.existsSync(),
              isFalse,
            );
            final String supportedPlatform = platform == SupportedPlatform.ios ? '.iOS("12.0")' : '.macOS("10.14")';
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
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: fs,
            );
            final FakePlugin validPlugin1 = _fakePluginWithManifest(
              name: 'valid_plugin_1',
              platform: platform,
              fs: fs,
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
              <Plugin>[validPlugin1],
              platform,
              project,
            );

            // Validate plugin symlinks and Package.swift
            _validatePlugin(
              plugin: validPlugin1,
              platform: platform,
              project: project,
              fs: fs,
            );

            // Validate Flutter framework
            final String supportedPlatform = platform == SupportedPlatform.ios
                ? '.iOS("12.0")'
                : '.macOS("10.14")';
            _validateFlutterFramework(project, platform, supportedPlatform, fs);

            // Validate FlutterGeneratedPluginSwiftPackage
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
        .library(name: "FlutterGeneratedPluginSwiftPackage", targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "valid_plugin_1", path: "../.symlinks/plugins/valid_plugin_1/${platform.name}/valid_plugin_1")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "valid_plugin_1", package: "valid_plugin_1")
            ]
        )
    ]
)
''');
            expect(spm.migrated, isTrue);
          });

          testWithoutContext('generate with multiple dependencies', () async {
            final MemoryFileSystem fs = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: fs,
            );
            final FakePlugin nonPlatformCompatiblePlugin = FakePlugin(
              name: 'invalid_plugin_due_to_incompatible_platform',
              path: '/path/to/invalid_plugin_due_to_incompatible_platform',
              platforms: <String, PluginPlatform>{},
              pluginSwiftPackageManifestPath: '/some/path',
            );
            final FakePlugin pluginSwiftPackageManifestIsNull = FakePlugin(
              name: 'invalid_plugin_due_to_null_plugin_swift_package_path',
              path: '/path/to/invalid_plugin_due_to_null_plugin_swift_package_path',
              platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
              pluginSwiftPackageManifestPath: null,
            );
            final FakePlugin pluginSwiftPackageManifestNotExists = FakePlugin(
              name: 'invalid_plugin_due_to_plugin_swift_package_path_does_not_exist',
              path: '/path/to/invalid_plugin_due_to_plugin_swift_package_path_does_not_exist',
              platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
              pluginSwiftPackageManifestPath: '/some/path',
            );

            final FakePlugin validPlugin1 = _fakePluginWithManifest(
              name: 'valid_plugin_1',
              platform: platform,
              fs: fs,
            );
            final FakePlugin validPlugin2 = _fakePluginWithManifest(
              name: 'valid_plugin_2',
              path: '/.pub-cache/plugins/valid_plugin_2',
              platform: platform,
              fs: fs,
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

            // Validate plugin symlinks and Package.swift
            _validatePlugin(
              plugin: validPlugin1,
              platform: platform,
              project: project,
              fs: fs,
            );
            _validatePlugin(
              plugin: validPlugin2,
              platform: platform,
              project: project,
              fs: fs,
            );

            // Validate Flutter framework
            final String supportedPlatform = platform == SupportedPlatform.ios
                ? '.iOS("12.0")'
                : '.macOS("10.14")';
            _validateFlutterFramework(project, platform, supportedPlatform, fs);

            // Validate FlutterGeneratedPluginSwiftPackage
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
        .library(name: "FlutterGeneratedPluginSwiftPackage", targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "valid_plugin_1", path: "../.symlinks/plugins/valid_plugin_1/${platform.name}/valid_plugin_1"),
        .package(name: "valid_plugin_2", path: "../.symlinks/plugins/valid_plugin_2/${platform.name}/valid_plugin_2")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "valid_plugin_1", package: "valid_plugin_1"),
                .product(name: "valid_plugin_2", package: "valid_plugin_2")
            ]
        )
    ]
)
''');
            expect(spm.migrated, isTrue);
          });

          testWithoutContext('throws when missing "swift-tools-version"', () async {
            final MemoryFileSystem fs = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: fs,
            );
            final FakePlugin validPlugin1 = _fakePluginWithManifest(
              name: 'valid_plugin_1',
              platform: platform,
              manifestContents: '',
              fs: fs,
            );

            final FakeSwiftPackageManager spm = FakeSwiftPackageManager(
              artifacts: Artifacts.test(fileSystem: fs),
              fileSystem: fs,
              logger: testLogger,
              templateRenderer: const MustacheTemplateRenderer(),
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              plistParser: FakePlistParser(),
            );
            await expectLater(
              spm.generatePluginsSwiftPackage(
                <Plugin>[validPlugin1],
                platform,
                project,
              ),
              throwsToolExit(
                message: 'Invalid Package.swift for valid_plugin_1. Swift tools version is not '
                  'specified. Add the following at the top of Package.swift:\n'
                  '  // swift-tools-version: 5.9',
              ),
            );
          });


          testWithoutContext('throws when missing "flutterFrameworkDependency"', () async {
            final MemoryFileSystem fs = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: fs,
            );
            final FakePlugin validPlugin1 = _fakePluginWithManifest(
              name: 'valid_plugin_1',
              platform: platform,
              manifestContents: _manifestSwiftToolVersion,
              fs: fs,
            );

            final FakeSwiftPackageManager spm = FakeSwiftPackageManager(
              artifacts: Artifacts.test(fileSystem: fs),
              fileSystem: fs,
              logger: testLogger,
              templateRenderer: const MustacheTemplateRenderer(),
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              plistParser: FakePlistParser(),
            );
            await expectLater(
              spm.generatePluginsSwiftPackage(
                <Plugin>[validPlugin1],
                platform,
                project,
              ),
              throwsToolExit(
                message: 'Invalid Package.swift for valid_plugin_1. Missing or altered "flutterFrameworkDependency".',
              ),
            );
          });

          testWithoutContext('throws when missing "flutterMinimumIOSVersion"', () async {
            final MemoryFileSystem fs = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: fs,
            );
            final FakePlugin validPlugin1 = _fakePluginWithManifest(
              name: 'valid_plugin_1',
              platform: platform,
              manifestContents:
                  '$_manifestSwiftToolVersion\n\n'
                  '${_manifestFlutterFrameworkDependencyFunction('flutterFrameworkPackagePath')}\n',
              fs: fs,
            );

            final FakeSwiftPackageManager spm = FakeSwiftPackageManager(
              artifacts: Artifacts.test(fileSystem: fs),
              fileSystem: fs,
              logger: testLogger,
              templateRenderer: const MustacheTemplateRenderer(),
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              plistParser: FakePlistParser(),
            );
            await expectLater(
              spm.generatePluginsSwiftPackage(
                <Plugin>[validPlugin1],
                platform,
                project,
              ),
              throwsToolExit(
                message: 'Invalid Package.swift for valid_plugin_1. Missing or altered "flutterMinimumIOSVersion".',
              ),
            );
          });

          testWithoutContext('throws when missing "flutterMinimumMacOSVersion"', () async {
            final MemoryFileSystem fs = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: fs,
            );
            final FakePlugin validPlugin1 = _fakePluginWithManifest(
              name: 'valid_plugin_1',
              platform: platform,
              manifestContents:
                  '$_manifestSwiftToolVersion\n\n'
                  '${_manifestFlutterFrameworkDependencyFunction('flutterFrameworkPackagePath')}\n'
                  '$_manifestFlutterMinimumIOSVersionFunction',
              fs: fs,
            );

            final FakeSwiftPackageManager spm = FakeSwiftPackageManager(
              artifacts: Artifacts.test(fileSystem: fs),
              fileSystem: fs,
              logger: testLogger,
              templateRenderer: const MustacheTemplateRenderer(),
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              plistParser: FakePlistParser(),
            );
            await expectLater(
              spm.generatePluginsSwiftPackage(
                <Plugin>[validPlugin1],
                platform,
                project,
              ),
              throwsToolExit(
                message: 'Invalid Package.swift for valid_plugin_1. Missing or altered "flutterMinimumMacOSVersion".',
              ),
            );
          });
        });

        group('linkFlutterFramework', () {
          testWithoutContext('throw if invalid platform', () {
            final MemoryFileSystem fs = MemoryFileSystem();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: fs,
            );
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
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: fs,
            );
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
            expect(testLogger.traceText, contains('Flutter Swift Package does not exist, skipping adding link to $frameworkName.'));
          });

          testWithoutContext('creates link if missing', () async {
            final MemoryFileSystem fs = MemoryFileSystem();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: fs,
            );
            final BufferLogger testLogger = BufferLogger.test();
            project.flutterFrameworkSwiftPackageManifest.createSync(recursive: true);

            SwiftPackageManager.linkFlutterFramework(
              platform,
              project,
              BuildMode.debug,
              artifacts: Artifacts.test(fileSystem: fs),
              fileSystem: fs,
              logger: testLogger,
            );
            final String frameworkName = platform == SupportedPlatform.ios ? 'Flutter' : 'FlutterMacOS';
            final Link engineLink = fs.link('${project.flutterFrameworkSwiftPackageDirectory.path}/$frameworkName.xcframework');
            final String expectedArtifactPath = platform == SupportedPlatform.ios ? 'Artifact.flutterXcframework.TargetPlatform.ios.debug' : 'Artifact.flutterMacOSXcframework.TargetPlatform.darwin.debug';
            expect(testLogger.traceText, isEmpty);
            expect(await engineLink.target(), expectedArtifactPath);
          });

          testWithoutContext('updates link if changed', () async {
            final MemoryFileSystem fs = MemoryFileSystem();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: fs,
            );
            final BufferLogger testLogger = BufferLogger.test();
            fs.file(project.flutterFrameworkSwiftPackageManifest).createSync(recursive: true);

            final String frameworkName = platform == SupportedPlatform.ios ? 'Flutter' : 'FlutterMacOS';
            final Link engineLink = fs.link('${project.flutterFrameworkSwiftPackageDirectory.path}/$frameworkName.xcframework');
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

        group('updateMinimumDeployment', () {
          testWithoutContext('return if invalid deploymentTarget', () {
            final MemoryFileSystem fs = MemoryFileSystem();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: fs,
            );
            final String supportedPlatform = platform == SupportedPlatform.ios ? '.iOS("12.0")' : '.macOS("10.14")';
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
            final MemoryFileSystem fs = MemoryFileSystem();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: fs,
            );
            final String supportedPlatform = platform == SupportedPlatform.ios ? '.iOS("12.0")' : '.macOS("10.14")';
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
            final MemoryFileSystem fs = MemoryFileSystem();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: fs,
            );
            final String supportedPlatform = platform == SupportedPlatform.ios ? '.iOS("12.0")' : '.macOS("10.14")';
            project.flutterPluginSwiftPackageManifest.createSync(recursive: true);
            project.flutterPluginSwiftPackageManifest.writeAsStringSync(supportedPlatform);
            SwiftPackageManager.updateMinimumDeployment(
              project: project,
              platform: platform,
              deploymentTarget: platform == SupportedPlatform.ios ? '12.0' : '10.14',
            );
            expect(
              project.flutterPluginSwiftPackageManifest.readAsLinesSync(),
              contains(supportedPlatform),
            );
          });

          testWithoutContext('update if deploymentTarget is higher than default', () {
            final MemoryFileSystem fs = MemoryFileSystem();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: fs,
            );
            final String supportedPlatform = platform == SupportedPlatform.ios ? '.iOS("12.0")' : '.macOS("10.14")';
            project.flutterPluginSwiftPackageManifest.createSync(recursive: true);
            project.flutterPluginSwiftPackageManifest.writeAsStringSync(supportedPlatform);
            SwiftPackageManager.updateMinimumDeployment(
              project: project,
              platform: platform,
              deploymentTarget: '14.0',
            );
            expect(
              project.flutterPluginSwiftPackageManifest
                  .readAsLinesSync()
                  .contains(supportedPlatform),
              isFalse,
            );
            expect(
              project.flutterPluginSwiftPackageManifest.readAsLinesSync(),
              contains(platform == SupportedPlatform.ios ? '.iOS("14.0")' : '.macOS("14.0")'),
            );
          });
        });
      });
    }
  });
}

FakePlugin _fakePluginWithManifest({
  required String name,
  String? path,
  String? manifestContents,
  required SupportedPlatform platform,
  required FileSystem fs,
}) {
  final Directory validPlugin1Directory = fs.directory(path ?? '/local/path/to/plugins/$name');
  final File validPlugin1Manifest = fs.file('${validPlugin1Directory.path}/${platform.name}/$name/Package.swift')
      ..createSync(recursive: true)
      ..writeAsStringSync(manifestContents ?? _fakePluginSwiftPackage(name, 'flutterFrameworkPackagePath', false));
  validPlugin1Directory.childFile('childFile.txt').createSync();
  validPlugin1Directory.childDirectory('childDirectory').createSync();
  return FakePlugin(
    name: name,
    path: validPlugin1Directory.path,
    platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
    pluginSwiftPackageManifestPath: validPlugin1Manifest.path,
  );
}

void _validatePlugin({
  required Plugin plugin,
  required SupportedPlatform platform,
  required XcodeBasedProject project,
  required FileSystem fs,
}) {
  final Directory symlinkPluginDirectory = project.ephemeralSwiftPackageDirectory
      .childDirectory('.symlinks')
      .childDirectory('plugins');
  expect(symlinkPluginDirectory.existsSync(), isTrue);
  expect(
    symlinkPluginDirectory
        .childDirectory(plugin.name)
        .childLink('childFile.txt')
        .targetSync(),
    fs.directory(plugin.path)
        .childFile('childFile.txt')
        .path,
  );
  expect(
    symlinkPluginDirectory
        .childDirectory(plugin.name)
        .childLink('childDirectory')
        .targetSync(),
    symlinkPluginDirectory.fileSystem
        .directory(plugin.path)
        .childDirectory('childDirectory')
        .path,
  );

  // Validate plugin Package.swift is valid
  final File symlinkPluginSwiftManifest = symlinkPluginDirectory
      .childDirectory(plugin.name)
      .childDirectory(platform.name)
      .childDirectory(plugin.name)
      .childFile('Package.swift');
  expect(symlinkPluginSwiftManifest.existsSync(), isTrue);
  expect(
    symlinkPluginSwiftManifest.readAsStringSync(),
    _fakePluginSwiftPackage(plugin.name, '"app_name/${platform.name}/Flutter/Packages/ephemeral/Flutter"', true),
  );
}

void _validateFlutterFramework(
  XcodeBasedProject project,
  SupportedPlatform platform,
  String supportedPlatformForManifest,
  FileSystem fs,
) {
  final String frameworkName = platform == SupportedPlatform.ios ? 'Flutter' : 'FlutterMacOS';
  expect(project.flutterFrameworkSwiftPackageManifest.existsSync(), isTrue);
  expect(
    project.flutterFrameworkSwiftPackageManifest.readAsStringSync(),
    _expectedFlutterFrameworkSwiftPackage(frameworkName, supportedPlatformForManifest),
  );
  final Link engineLink = fs.link('${project.flutterFrameworkSwiftPackageDirectory.path}/$frameworkName.xcframework');
  final String expectedArtifactPath = platform == SupportedPlatform.ios
      ? 'Artifact.flutterXcframework.TargetPlatform.ios.release'
      : 'Artifact.flutterMacOSXcframework.TargetPlatform.darwin.release';
  expect(engineLink.targetSync(), expectedArtifactPath);
}

String _fakePluginSwiftPackage(
  String name,
  String frameworkPath,
  bool generated,
) {
  String generatedComment = '';
  if (generated) {
    generatedComment =  '//\n//  Generated file. Do not edit.\n//\n\n';
  }
  return '''
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
$generatedComment
import PackageDescription

let pluginMinimumIOSVersion = Version("12.0.0")
let pluginMinimumMacOSVersion = Version("10.14.0")

let package = Package(
    name: "$name",
    platforms: [
        flutterMinimumIOSVersion(pluginTargetVersion: pluginMinimumIOSVersion),
        flutterMinimumMacOSVersion(pluginTargetVersion: pluginMinimumMacOSVersion),
    ],
    products: [
        .library(name: "$name", targets: ["$name"])
    ],
    dependencies: [
        flutterFrameworkDependency(),
    ],
    targets: [
        .target(
            name: "$name",
            dependencies: [
                .product(name: "Flutter", package: "Flutter")
            ]
        )
    ]
)

${_manifestFlutterFrameworkDependencyFunction(frameworkPath)}

$_manifestFlutterMinimumIOSVersionFunction

$_manifestFlutterMinimumMacOSVersionFunction
''';
}

String _manifestSwiftToolVersion = '// swift-tools-version: 5.9';
String _manifestFlutterFrameworkDependencyFunction(String frameworkPath) {
  return '''
func flutterFrameworkDependency(localFrameworkPath: String? = nil) -> Package.Dependency {
    let flutterFrameworkPackagePath = localFrameworkPath ?? ""
    return .package(name: "Flutter", path: $frameworkPath)
}
''';
}

String _manifestFlutterMinimumIOSVersionFunction = '''
func flutterMinimumIOSVersion(pluginTargetVersion: Version) -> SupportedPlatform {
    let iosFlutterMinimumVersion = Version("12.0.0")
    var versionString = pluginTargetVersion.description
    if iosFlutterMinimumVersion > pluginTargetVersion {
        versionString = iosFlutterMinimumVersion.description
    }
    return SupportedPlatform.iOS(versionString)
}
''';

String _manifestFlutterMinimumMacOSVersionFunction = '''
func flutterMinimumMacOSVersion(pluginTargetVersion: Version) -> SupportedPlatform {
    let macosFlutterMinimumVersion = Version("10.14.0")
    var versionString = pluginTargetVersion.description
    if macosFlutterMinimumVersion > pluginTargetVersion {
        versionString = macosFlutterMinimumVersion.description
    }
    return SupportedPlatform.macOS(versionString)
}
''';


String _expectedFlutterFrameworkSwiftPackage(String frameworkName, String supportedPlatform) {
  return '''
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
//  Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "Flutter",
    platforms: [
        $supportedPlatform
    ],
    products: [
        .library(name: "Flutter", targets: ["$frameworkName"])
    ],
    dependencies: [
$_doubleIndent
    ],
    targets: [
        .binaryTarget(
            name: "$frameworkName",
            path: "$frameworkName.xcframework"
        )
    ]
)
''';
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

class FakeXcodeProject extends Fake implements IosProject {
  FakeXcodeProject({
    required MemoryFileSystem fileSystem,
    required String platform,
  }) : hostAppRoot = fileSystem.directory('app_name').childDirectory(platform);

  @override
  Directory hostAppRoot;

  @override
  Directory get xcodeProject => hostAppRoot.childDirectory('$hostAppProjectName.xcodeproj');

  @override
  File get xcodeProjectInfoFile => xcodeProject.childFile('project.pbxproj');

  @override
  String hostAppProjectName = 'Runner';

  @override
  Directory get ephemeralSwiftPackageDirectory => hostAppRoot
      .childDirectory('Flutter')
      .childDirectory('Packages')
      .childDirectory('ephemeral');

  @override
  Directory get flutterPluginSwiftPackageDirectory => ephemeralSwiftPackageDirectory
      .childDirectory('FlutterGeneratedPluginSwiftPackage');

  @override
  File get flutterFrameworkSwiftPackageManifest =>
      flutterFrameworkSwiftPackageDirectory.childFile('Package.swift');

  @override
  Directory get flutterFrameworkSwiftPackageDirectory => ephemeralSwiftPackageDirectory
      .childDirectory('Flutter');

  @override
  File get flutterPluginSwiftPackageManifest =>
      flutterPluginSwiftPackageDirectory.childFile('Package.swift');

  @override
  bool get flutterPluginSwiftPackageInProjectSettings {
    return xcodeProjectInfoFile.existsSync() &&
        xcodeProjectInfoFile
            .readAsStringSync()
            .contains('FlutterGeneratedPluginSwiftPackage');
  }
}

class FakePlugin extends Fake implements Plugin {
  FakePlugin({
    required this.name,
    required this.path,
    required this.platforms,
    required String? pluginSwiftPackageManifestPath,
  }) : _pluginSwiftPackageManifestPath = pluginSwiftPackageManifestPath;

  final String? _pluginSwiftPackageManifestPath;

  @override
  final String name;

  @override
  final String path;

  @override
  final Map<String, PluginPlatform> platforms;

  @override
  String? pluginSwiftPackageManifestPath(
    FileSystem fileSystem,
    String platform,
  ) {
    return _pluginSwiftPackageManifestPath;
  }

  @override
  String? darwinPluginDirectoryName(String platform) {
    return platform;
  }
}

class FakePluginPlatform extends Fake implements PluginPlatform {}

class FakeXcodeProjectInterpreter extends Fake implements XcodeProjectInterpreter {}

class FakePlistParser extends Fake implements PlistParser {}
