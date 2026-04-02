// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/logger.dart' show BufferLogger;
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/darwin/darwin.dart';
import 'package:flutter_tools/src/isolated/mustache_template.dart';
import 'package:flutter_tools/src/macos/swift_package_manager.dart';
import 'package:flutter_tools/src/platform_plugins.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

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
            final processManager = FakeProcessManager.any();
            final logger = BufferLogger.test();
            final project = FakeXcodeProject(platform: platform.name, fileSystem: fs);

            final spm = SwiftPackageManager(
              fileSystem: fs,
              templateRenderer: const MustacheTemplateRenderer(),
              processUtils: ProcessUtils(processManager: processManager, logger: logger),
              config: FakeConfig(),
            );
            await spm.generatePluginsSwiftPackage(<Plugin>[], platform, project);

            expect(project.flutterPluginSwiftPackageManifest.existsSync(), isFalse);
          });

          testWithoutContext('generate if no dependencies and already migrated', () async {
            final fs = MemoryFileSystem();
            final processManager = FakeProcessManager.any();
            final logger = BufferLogger.test();
            final project = FakeXcodeProject(platform: platform.name, fileSystem: fs);
            project.xcodeProjectInfoFile.createSync(recursive: true);
            project.xcodeProjectInfoFile.writeAsStringSync('''
'		78A318202AECB46A00862997 /* FlutterGeneratedPluginSwiftPackage in Frameworks */ = {isa = PBXBuildFile; productRef = 78A3181F2AECB46A00862997 /* FlutterGeneratedPluginSwiftPackage */; };';
''');

            final spm = SwiftPackageManager(
              fileSystem: fs,
              templateRenderer: const MustacheTemplateRenderer(),
              processUtils: ProcessUtils(processManager: processManager, logger: logger),
              config: FakeConfig(),
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
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
''');

            expect(
              project.flutterFrameworkSwiftPackageDirectory.childFile('Package.swift').existsSync(),
              isTrue,
            );
            expect(
              project.flutterFrameworkSwiftPackageDirectory
                  .childFile('Package.swift')
                  .readAsStringSync(),
              '''
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
//  Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterFramework",
    products: [
        .library(name: "FlutterFramework", targets: ["FlutterFramework"])
    ],
    dependencies: [
$_doubleIndent
    ],
    targets: [
        .target(
            name: "FlutterFramework"
        )
    ]
)
''',
            );
          });

          testWithoutContext(
            'generate if no dependencies, no Flutter dependency, and already migrated',
            () async {
              final fs = MemoryFileSystem();
              final processManager = FakeProcessManager.any();
              final logger = BufferLogger.test();
              final project = FakeXcodeProject(platform: platform.name, fileSystem: fs);
              project.xcodeProjectInfoFile.createSync(recursive: true);
              project.xcodeProjectInfoFile.writeAsStringSync('''
'		78A318202AECB46A00862997 /* FlutterGeneratedPluginSwiftPackage in Frameworks */ = {isa = PBXBuildFile; productRef = 78A3181F2AECB46A00862997 /* FlutterGeneratedPluginSwiftPackage */; };';
''');

              final spm = SwiftPackageManager(
                fileSystem: fs,
                templateRenderer: const MustacheTemplateRenderer(),
                processUtils: ProcessUtils(processManager: processManager, logger: logger),
                config: FakeConfig(),
              );
              await spm.generatePluginsSwiftPackage(
                <Plugin>[],
                platform,
                project,
                flutterAsADependency: false,
              );

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
            },
          );

          testWithoutContext('generate with single dependency', () async {
            final fs = MemoryFileSystem();
            final processManager = FakeProcessManager.any();
            final logger = BufferLogger.test();
            final project = FakeXcodeProject(platform: platform.name, fileSystem: fs);

            final validPlugin1 = FakePlugin(
              name: 'valid_plugin_1',
              platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
            );
            fs
                .file('${validPlugin1.path}/${platform.name}/${validPlugin1.name}/Package.swift')
                .createSync(recursive: true);
            final spm = SwiftPackageManager(
              fileSystem: fs,
              templateRenderer: const MustacheTemplateRenderer(),
              processUtils: ProcessUtils(processManager: processManager, logger: logger),
              config: FakeConfig(),
            );
            await spm.generatePluginsSwiftPackage(<Plugin>[validPlugin1], platform, project);

            final supportedPlatform = platform == FlutterDarwinPlatform.ios
                ? '.iOS("13.0")'
                : '.macOS("10.15")';
            expect(project.flutterPluginSwiftPackageManifest.existsSync(), isTrue);
            expect(
              project.relativeSwiftPackagesDirectory.childLink('valid_plugin_1-1.0.0'),
              exists,
            );
            expect(
              project.relativeSwiftPackagesDirectory.childLink('valid_plugin_1-1.0.0').targetSync(),
              '${validPlugin1.path}/${platform.name}/valid_plugin_1',
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
        .package(name: "valid_plugin_1", path: "../.packages/valid_plugin_1-1.0.0"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "valid-plugin-1", package: "valid_plugin_1"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
''');
          });

          testWithoutContext('generate with multiple dependencies', () async {
            final fs = MemoryFileSystem();
            final processManager = FakeProcessManager.any();
            final logger = BufferLogger.test();
            final project = FakeXcodeProject(platform: platform.name, fileSystem: fs);
            final nonPlatformCompatiblePlugin = FakePlugin(
              name: 'invalid_plugin_due_to_incompatible_platform',
              platforms: <String, PluginPlatform>{},
            );
            final pluginSwiftPackageManifestIsNull = FakePlugin(
              name: 'invalid_plugin_due_to_null_plugin_swift_package_path',
              platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
              hasSwiftPackage: false,
            );
            final pluginSwiftPackageManifestNotExists = FakePlugin(
              name: 'invalid_plugin_due_to_plugin_swift_package_path_does_not_exist',
              platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
            );

            final validPlugin1 = FakePlugin(
              name: 'valid_plugin_1',
              platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
            );
            fs
                .file('${validPlugin1.path}/${platform.name}/${validPlugin1.name}/Package.swift')
                .createSync(recursive: true);

            final validPlugin2 = FakePlugin(
              name: 'valid_plugin_2',
              platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
            );
            fs
                .file('${validPlugin2.path}/${platform.name}/${validPlugin2.name}/Package.swift')
                .createSync(recursive: true);

            final spm = SwiftPackageManager(
              fileSystem: fs,
              templateRenderer: const MustacheTemplateRenderer(),
              processUtils: ProcessUtils(processManager: processManager, logger: logger),
              config: FakeConfig(),
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
            expect(
              project.relativeSwiftPackagesDirectory.childLink('valid_plugin_1-1.0.0'),
              exists,
            );
            expect(
              project.relativeSwiftPackagesDirectory.childLink('valid_plugin_1-1.0.0').targetSync(),
              '${validPlugin1.path}/${platform.name}/valid_plugin_1',
            );
            expect(
              project.relativeSwiftPackagesDirectory.childLink('valid_plugin_2-1.0.0'),
              exists,
            );
            expect(
              project.relativeSwiftPackagesDirectory.childLink('valid_plugin_2-1.0.0').targetSync(),
              '${validPlugin2.path}/${platform.name}/valid_plugin_2',
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
        .package(name: "valid_plugin_1", path: "../.packages/valid_plugin_1-1.0.0"),
        .package(name: "valid_plugin_2", path: "../.packages/valid_plugin_2-1.0.0"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "valid-plugin-1", package: "valid_plugin_1"),
                .product(name: "valid-plugin-2", package: "valid_plugin_2"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
''');
          });

          testWithoutContext('generate with plugin with dependency on plugin', () async {
            final fs = MemoryFileSystem();
            final logger = BufferLogger.test();
            final project = FakeXcodeProject(platform: platform.name, fileSystem: fs);

            final buildSourcePackagesPath = '/build/${platform.name}/SourcePackages';
            final validPlugin1 = FakePlugin(
              name: 'valid_plugin_1',
              platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
            );
            const plugin1ManifestContents = '''
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "valid_plugin_1",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "valid-plugin-1", targets: ["valid-plugin-1"])
    ],
    dependencies: [
        .package(name: "valid_plugin_2", path: "../valid_plugin_2"),
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(name: "valid_plugin_3", path: "../valid_plugin_3")
    ],
    targets: [
        .target(
            name: "valid-plugin-1",
            dependencies: [
                .product(name: "valid-plugin-2", package: "valid_plugin_2"),
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "valid-plugin-3", package: "valid_plugin_3")
            ],
            path: "../Classes",
        )
    ]
)
''';
            final File plugin1ManifestFile = fs.file(
              '${validPlugin1.path}/${platform.name}/${validPlugin1.name}/Package.swift',
            );
            plugin1ManifestFile
              ..createSync(recursive: true)
              ..writeAsStringSync(plugin1ManifestContents);
            final File plugin1CopiedManifest = fs.file(
              '$buildSourcePackagesPath/valid_plugin_1-1.0.0/${platform.name}/valid_plugin_1/Package.swift',
            );

            final validPlugin2 = FakePlugin(
              name: 'valid_plugin_2',
              platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
            );
            fs
                .file('${validPlugin2.path}/${platform.name}/${validPlugin2.name}/Package.swift')
                .createSync(recursive: true);

            final validPlugin3 = FakePlugin(
              name: 'valid_plugin_3',
              platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
            );
            fs
                .file('${validPlugin3.path}/${platform.name}/${validPlugin3.name}/Package.swift')
                .createSync(recursive: true);

            final processManager = FakeProcessManager.list([
              FakeCommand(
                command: [
                  'rsync',
                  '-8',
                  '-av',
                  '--delete',
                  validPlugin1.path,
                  '$buildSourcePackagesPath/valid_plugin_1-1.0.0',
                ],
                onRun: (_) {
                  plugin1CopiedManifest
                    ..createSync(recursive: true)
                    ..writeAsStringSync(plugin1ManifestContents);
                },
              ),
            ]);

            final spm = SwiftPackageManager(
              fileSystem: fs,
              templateRenderer: const MustacheTemplateRenderer(),
              processUtils: ProcessUtils(processManager: processManager, logger: logger),
              config: FakeConfig(),
            );
            await spm.generatePluginsSwiftPackage(
              <Plugin>[validPlugin1, validPlugin2, validPlugin3],
              platform,
              project,
            );

            final supportedPlatform = platform == FlutterDarwinPlatform.ios
                ? '.iOS("13.0")'
                : '.macOS("10.15")';
            expect(project.flutterPluginSwiftPackageManifest.existsSync(), isTrue);
            expect(
              project.relativeSwiftPackagesDirectory.childLink('valid_plugin_1-1.0.0'),
              exists,
            );
            expect(
              project.relativeSwiftPackagesDirectory.childLink('valid_plugin_1-1.0.0').targetSync(),
              '$buildSourcePackagesPath/valid_plugin_1-1.0.0/${platform.name}/valid_plugin_1',
            );
            expect(plugin1CopiedManifest.readAsStringSync(), '''
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "valid_plugin_1",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "valid-plugin-1", targets: ["valid-plugin-1"])
    ],
    dependencies: [
        .package(name: "valid_plugin_2", path: "../valid_plugin_2-1.0.0"),
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(name: "valid_plugin_3", path: "../valid_plugin_3-1.0.0")
    ],
    targets: [
        .target(
            name: "valid-plugin-1",
            dependencies: [
                .product(name: "valid-plugin-2", package: "valid_plugin_2"),
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "valid-plugin-3", package: "valid_plugin_3")
            ],
            path: "../Classes",
        )
    ]
)
''');
            expect(
              project.relativeSwiftPackagesDirectory.childLink('valid_plugin_2-1.0.0'),
              exists,
            );
            expect(
              project.relativeSwiftPackagesDirectory.childLink('valid_plugin_2-1.0.0').targetSync(),
              '${validPlugin2.path}/${platform.name}/valid_plugin_2',
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
        .package(name: "valid_plugin_1", path: "../.packages/valid_plugin_1-1.0.0"),
        .package(name: "valid_plugin_2", path: "../.packages/valid_plugin_2-1.0.0"),
        .package(name: "valid_plugin_3", path: "../.packages/valid_plugin_3-1.0.0"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "valid-plugin-1", package: "valid_plugin_1"),
                .product(name: "valid-plugin-2", package: "valid_plugin_2"),
                .product(name: "valid-plugin-3", package: "valid_plugin_3"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
''');
            expect(processManager, hasNoRemainingExpectations);
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
  Directory get flutterFrameworkSwiftPackageDirectory =>
      relativeSwiftPackagesDirectory.childDirectory('FlutterFramework');

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
  FakePlugin({required this.name, required this.platforms, this.hasSwiftPackage = true})
    : path = '/local/path/to/plugins/$name-1.0.0';

  @override
  final String name;

  @override
  final String path;

  @override
  final Map<String, PluginPlatform> platforms;

  final bool hasSwiftPackage;

  @override
  String? pluginSwiftPackagePath(FileSystem fileSystem, String platform, {String? overridePath}) {
    if (!hasSwiftPackage) {
      return null;
    }
    if (overridePath != null) {
      return '$overridePath/$platform/$name';
    }
    return '$path/$platform/$name';
  }

  @override
  String? pluginSwiftPackageManifestPath(FileSystem fileSystem, String platform) {
    if (!hasSwiftPackage) {
      return null;
    }
    return '$path/$platform/$name/Package.swift';
  }
}

class FakePluginPlatform extends Fake implements PluginPlatform {}

class FakeConfig extends Fake implements Config {
  @override
  Object? getValue(String key) => null;
}
