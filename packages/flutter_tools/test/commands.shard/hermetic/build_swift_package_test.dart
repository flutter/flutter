// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/template.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_swift_package.dart';
import 'package:flutter_tools/src/darwin/darwin.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:test_api/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';

void main() {
  const cachedPluginsDirectoryPath = 'output/Plugins';
  const engineArtifactPath = '/flutter/bin/cache/artifacts/engine/ios/Flutter.xcframework';

  group('BuildSwiftPackage', () {
    // TODO(vashworth): Test args validation for BuildSwiftPackage once command has been added as
    // a subcommand of BuildCommand. This is required for TestFlutterCommandRunner.
  });

  group('FlutterPluginDependencies', () {
    testWithoutContext('copyPlugins', () async {
      final fs = MemoryFileSystem.test();
      final logger = BufferLogger.test();
      final Directory cachedPluginsDirectory = fs.directory(cachedPluginsDirectoryPath);

      final pluginA = FakePlugin(
        name: 'PluginA',
        supportSwiftPackageManager: false,
        darwinPlatform: FlutterDarwinPlatform.ios,
      ); // skipped because no SwiftPM support
      fs.directory(pluginA.path).createSync(recursive: true);

      final pluginB = FakePlugin(
        name: 'PluginB',
        cachedPluginsDirectory: cachedPluginsDirectory,
        darwinPlatform: FlutterDarwinPlatform.ios,
      ); // copied and added FlutterFramework
      final String originalManifestPluginB = _validPackageManifest(pluginB);
      fs.file(pluginB.swiftPackageManifestPath)
        ..createSync(recursive: true)
        ..writeAsStringSync(originalManifestPluginB);

      final pluginC = FakePlugin(
        name: 'PluginC',
        cachedPluginsDirectory: cachedPluginsDirectory,
        darwinPlatform: FlutterDarwinPlatform.ios,
      ); // copied and changes
      final String originalManifestPluginC = _validPackageManifest(
        pluginC,
        includeFlutterDependency: true,
      );
      fs.file(pluginC.swiftPackageManifestPath)
        ..createSync(recursive: true)
        ..writeAsStringSync(originalManifestPluginC);

      final processManager = FakeProcessManager.list([
        FakeCommand(
          command: const ['swift', 'package', 'dump-package'],
          stdout: _packageAsJson(pluginB),
          workingDirectory: pluginB.copiedSwiftManifest!.parent.path,
        ),
        const FakeCommand(
          command: ['swift', 'package', 'add-dependency', '../FlutterFramework', '--type', 'path'],
        ),
        FakeCommand(
          command: [
            'swift',
            'package',
            'add-target-dependency',
            'FlutterFramework',
            pluginB.name,
            '--package',
            'FlutterFramework',
          ],
          onRun: (command) {
            expect(pluginB.copiedSwiftManifest, exists);
            pluginB.copiedSwiftManifest!.writeAsStringSync(
              _validPackageManifest(pluginB, includeFlutterDependency: true),
            );
          },
        ),
        FakeCommand(
          command: const ['swift', 'package', 'dump-package'],
          stdout: _packageAsJson(pluginC, includeFlutterDependency: true),
          workingDirectory: pluginC.copiedSwiftManifest!.parent.path,
        ),
      ]);
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
        targetPlatform: FlutterDarwinPlatform.ios,
        templateRenderer: FakeTemplateRenderer(),
        xcode: FakeXcode(),
      );

      final pluginDependencies = FlutterPluginDependencies(utils: testUtils);
      await pluginDependencies.copyPlugins(
        plugins: [pluginA, pluginB, pluginC],
        cachedPluginsDirectory: cachedPluginsDirectory,
      );

      expect(logger.traceText, isEmpty);
      expect(processManager.hasRemainingExpectations, false);
      expect(cachedPluginsDirectory.listSync().length, 2);

      // Validate Plugin B was copied and the Package.swift was updated
      expect(pluginB.copiedSwiftManifest, exists);
      expect(pluginB.copiedSwiftManifest!.readAsStringSync(), isNot(originalManifestPluginB));
      expect(
        pluginB.copiedSwiftManifest!.readAsStringSync(),
        _validPackageManifest(pluginB, includeFlutterDependency: true),
      );

      // Validate Plugin C was copied and Package.swift matches original
      expect(pluginC.copiedSwiftManifest, exists);
      expect(pluginC.copiedSwiftManifest!.readAsStringSync(), originalManifestPluginC);
    });
  });

  testWithoutContext('copyPlugins fails if unable to parse plugin', () async {
    final fs = MemoryFileSystem.test();
    final logger = BufferLogger.test();
    final Directory cachedPluginsDirectory = fs.directory(cachedPluginsDirectoryPath);

    final pluginA = FakePlugin(
      name: 'PluginB',
      cachedPluginsDirectory: cachedPluginsDirectory,
      darwinPlatform: FlutterDarwinPlatform.ios,
    ); // skipped because no SwiftPM support
    fs.directory(pluginA.path).createSync(recursive: true);
    const originalManifestPluginA = 'invalid manifest';
    fs.file(pluginA.swiftPackageManifestPath)
      ..createSync(recursive: true)
      ..writeAsStringSync(originalManifestPluginA);

    final processManager = FakeProcessManager.list([
      FakeCommand(
        command: const ['swift', 'package', 'dump-package'],
        stdout: 'invalid json',
        workingDirectory: pluginA.copiedSwiftManifest!.parent.path,
      ),
    ]);
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
      targetPlatform: FlutterDarwinPlatform.ios,
      templateRenderer: FakeTemplateRenderer(),
      xcode: FakeXcode(),
    );

    final pluginDependencies = FlutterPluginDependencies(utils: testUtils);
    await expectLater(
      pluginDependencies.copyPlugins(
        plugins: [pluginA],
        cachedPluginsDirectory: cachedPluginsDirectory,
      ),
      throwsToolExit(message: 'Failed to validate'),
    );

    expect(logger.traceText, contains('Failed to parse'));
    expect(processManager.hasRemainingExpectations, false);
  });

  testWithoutContext('copyPlugins fails if unable to add package dependency', () async {
    final fs = MemoryFileSystem.test();
    final logger = BufferLogger.test();
    final Directory cachedPluginsDirectory = fs.directory(cachedPluginsDirectoryPath);

    final pluginA = FakePlugin(
      name: 'PluginA',
      cachedPluginsDirectory: cachedPluginsDirectory,
      darwinPlatform: FlutterDarwinPlatform.ios,
    ); // copied and added FlutterFramework
    final String originalManifestPluginA = _validPackageManifest(pluginA);
    fs.file(pluginA.swiftPackageManifestPath)
      ..createSync(recursive: true)
      ..writeAsStringSync(originalManifestPluginA);

    final processManager = FakeProcessManager.list([
      FakeCommand(
        command: const ['swift', 'package', 'dump-package'],
        stdout: _packageAsJson(pluginA),
        workingDirectory: pluginA.copiedSwiftManifest!.parent.path,
      ),
      const FakeCommand(
        command: ['swift', 'package', 'add-dependency', '../FlutterFramework', '--type', 'path'],
        exitCode: 1,
      ),
    ]);
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
      targetPlatform: FlutterDarwinPlatform.ios,
      templateRenderer: FakeTemplateRenderer(),
      xcode: FakeXcode(),
    );

    final pluginDependencies = FlutterPluginDependencies(utils: testUtils);
    await expectLater(
      pluginDependencies.copyPlugins(
        plugins: [pluginA],
        cachedPluginsDirectory: cachedPluginsDirectory,
      ),
      throwsToolExit(
        message: 'Plugin ${pluginA.name} does not have a dependency on the FlutterFramework.',
      ),
    );

    expect(logger.traceText, contains('Failed to add FlutterFramework to plugin'));
    expect(processManager.hasRemainingExpectations, false);
  });

  testWithoutContext('copyPlugins fails if unable to add target dependency', () async {
    final fs = MemoryFileSystem.test();
    final logger = BufferLogger.test();
    final Directory cachedPluginsDirectory = fs.directory(cachedPluginsDirectoryPath);

    final pluginA = FakePlugin(
      name: 'PluginA',
      cachedPluginsDirectory: cachedPluginsDirectory,
      darwinPlatform: FlutterDarwinPlatform.ios,
    ); // copied and added FlutterFramework
    final String originalManifestPluginA = _validPackageManifest(pluginA);
    fs.file(pluginA.swiftPackageManifestPath)
      ..createSync(recursive: true)
      ..writeAsStringSync(originalManifestPluginA);

    final processManager = FakeProcessManager.list([
      FakeCommand(
        command: const ['swift', 'package', 'dump-package'],
        stdout: _packageAsJson(pluginA),
        workingDirectory: pluginA.copiedSwiftManifest!.parent.path,
      ),
      FakeCommand(
        command: const [
          'swift',
          'package',
          'add-dependency',
          '../FlutterFramework',
          '--type',
          'path',
        ],
        onRun: (command) {
          expect(pluginA.copiedSwiftManifest, exists);
          pluginA.copiedSwiftManifest!.writeAsStringSync(
            _validPackageManifest(pluginA, includeFlutterDependency: true),
          );
        },
      ),
      FakeCommand(
        command: [
          'swift',
          'package',
          'add-target-dependency',
          'FlutterFramework',
          pluginA.name,
          '--package',
          'FlutterFramework',
        ],
        exitCode: 1,
      ),
    ]);
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
      targetPlatform: FlutterDarwinPlatform.ios,
      templateRenderer: FakeTemplateRenderer(),
      xcode: FakeXcode(),
    );

    final pluginDependencies = FlutterPluginDependencies(utils: testUtils);
    await expectLater(
      pluginDependencies.copyPlugins(
        plugins: [pluginA],
        cachedPluginsDirectory: cachedPluginsDirectory,
      ),
      throwsToolExit(
        message: 'Plugin ${pluginA.name} does not have a dependency on the FlutterFramework.',
      ),
    );

    expect(logger.traceText, contains('Failed to add FlutterFramework as a target dependency'));
    expect(processManager.hasRemainingExpectations, false);
    expect(fs.file(pluginA.swiftPackageManifestPath).readAsStringSync(), originalManifestPluginA);
  });
}

String _validPackageManifest(FakePlugin plugin, {bool includeFlutterDependency = false}) {
  var packageDependency = '';
  var targetDependency = '';
  if (includeFlutterDependency) {
    packageDependency = '.package(name: "FlutterFramework", path: "../FlutterFramework")';
    targetDependency = '.product(name: "FlutterFramework", package: "FlutterFramework")';
  }
  return '''
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "${plugin.name}",
    products: [
        .library(name: "${plugin.name.replaceAll('_', '-')}", targets: ["${plugin.name}"])
    ],
    dependencies: [$packageDependency],
    targets: [
        .target(
            name: "${plugin.name}",
            dependencies: [$targetDependency]
        )
    ]
)
''';
}

String _packageAsJson(FakePlugin plugin, {bool includeFlutterDependency = false}) {
  var packageDependency = '';
  var targetDependency = '';
  if (includeFlutterDependency) {
    packageDependency = '''
{
      "fileSystem" : [
        {
          "identity" : "flutterframework",
          "nameForTargetDependencyResolutionOnly" : "FlutterFramework",
          "path" : "/Users/vashworth/Development/experiment/xcode/FlutterFramework",
          "productFilter" : null,
          "traits" : [
            {
              "name" : "default"
            }
          ]
        }
      ]
    }
''';
    targetDependency = '''
{
          "product" : [
            "FlutterFramework",
            "FlutterFramework",
            null,
            null
          ]
        }
''';
  }
  return '''
{
  "cLanguageStandard" : null,
  "cxxLanguageStandard" : null,
  "dependencies" : [
    $packageDependency
  ],
  "name" : "${plugin.name}",
  "packageKind" : {
    "root" : [
      "${plugin.path}"
    ]
  },
  "pkgConfig" : null,
  "platforms" : [

  ],
  "products" : [
    {
      "name" : "${plugin.name.replaceAll('_', '-')}",
      "settings" : [

      ],
      "targets" : [
        "${plugin.name}"
      ],
      "type" : {
        "library" : [
          "automatic"
        ]
      }
    }
  ],
  "providers" : null,
  "swiftLanguageVersions" : null,
  "targets" : [
    {
      "dependencies" : [
        $targetDependency
      ],
      "exclude" : [

      ],
      "name" : "${plugin.name}",
      "packageAccess" : true,
      "resources" : [

      ],
      "settings" : [

      ],
      "type" : "regular"
    }
  ],
  "toolsVersion" : {
    "_version" : "6.2.0"
  },
  "traits" : [

  ]
}
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

class FakeFlutterProject extends Fake implements FlutterProject {}

class FakeTemplateRenderer extends Fake implements TemplateRenderer {}

class FakePlugin extends Fake implements Plugin {
  FakePlugin({
    required this.name,
    required this.darwinPlatform,
    this.supportSwiftPackageManager = true,
    this.cachedPluginsDirectory,
  });

  @override
  final String name;

  final FlutterDarwinPlatform darwinPlatform;
  final bool supportSwiftPackageManager;
  final Directory? cachedPluginsDirectory;

  @override
  String get path => '/path/to/$name';

  String get swiftPackageManifestPath => '$path/${darwinPlatform.name}/$name/Package.swift';

  File? get copiedSwiftManifest => cachedPluginsDirectory
      ?.childDirectory(name)
      .childDirectory(darwinPlatform.name)
      .childDirectory(name)
      .childFile('Package.swift');

  @override
  bool supportSwiftPackageManagerForPlatform(FileSystem fileSystem, String platform) {
    return supportSwiftPackageManager;
  }

  @override
  String? pluginSwiftPackagePath(FileSystem fileSystem, String platform, {String? overridePath}) {
    expect(overridePath, '${cachedPluginsDirectory!.path}/$name');
    return '$overridePath/$platform/$name';
  }
}
