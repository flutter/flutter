// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
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
import 'package:flutter_tools/src/commands/darwin_add_to_app.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/darwin/darwin.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/isolated/mustache_template.dart';
import 'package:flutter_tools/src/macos/swift_packages.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/platform_plugins.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:test_api/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../integration.shard/test_utils.dart';
import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';

const _flutterAppPath = '/path/to/my_flutter_app';
const _flutterRoot = '/path/to/flutter';
const String _engineVersion = '1234567890abcdef1234567890abcdef12345678';
const String _iosSdkRoot =
    '/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk';

void main() {
  const flutterAppDartToolPath = '$_flutterAppPath/.dart_tool';
  const flutterAppBuildPath = '$flutterAppDartToolPath/flutter_build';
  const commandFilePath =
      '/path/to/flutter/packages/flutter_tools/lib/src/commands/build_swift_package.dart';
  const nativeIntegrationSwiftPackagePath = 'output/FlutterNativeIntegration';
  const pluginRegistrantSwiftPackagePath =
      '$nativeIntegrationSwiftPackagePath/FlutterPluginRegistrant';
  const debugModeDirectoryPath = '$nativeIntegrationSwiftPackagePath/Debug';
  const debugFrameworksDirectoryPath = '$debugModeDirectoryPath/Frameworks';
  const debugNativeAssetsDirectoryPath = '$debugFrameworksDirectoryPath/NativeAssets';
  const debugCocoaPodsDirectoryPath = '$debugFrameworksDirectoryPath/CocoaPods';
  const debugPackagesDirectoryPath = '$debugModeDirectoryPath/Packages';
  const releaseModeDirectoryPath = '$nativeIntegrationSwiftPackagePath/Release';
  const releaseFrameworksDirectoryPath = '$releaseModeDirectoryPath/Frameworks';
  const releaseNativeAssetsDirectoryPath = '$releaseFrameworksDirectoryPath/NativeAssets';
  const cacheDirectoryPath = 'output/.cache';
  const scriptsDirectoryPath = 'output/Scripts';
  const debugCocoapodCache = '$cacheDirectoryPath/Debug/CocoaPods';
  const pluginsDirectoryPath = '$nativeIntegrationSwiftPackagePath/.plugins';
  const flutterCachePath = '/path/to/flutter/bin/cache';
  const engineArtifactPath = '$flutterCachePath/artifacts/engine/ios/Flutter.xcframework';
  const codesignIdentity = 'Apple Development: Company (TEAM_ID)';
  const codesignIdentityFile = '$cacheDirectoryPath/.codesign_identity';

  group('BuildSwiftPackage', () {
    group('Argument Validation', () {
      testUsingContext('validate platform argument', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final processManager = FakeProcessManager.list([]);
        final command = BuildSwiftPackage(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
          featureFlags: FakeFeatureFlags(),
          verboseHelp: false,
          codesign: FakeDarwinAddToAppCodesigning(),
        );

        final runner = FlutterCommandRunner(verboseHelp: true);
        runner.addCommand(command);

        expect(
          () => runner.run(<String>['swift-package', '--platform', 'invalid']),
          throwsA(
            isA<UsageException>().having(
              (e) => e.message,
              'message',
              contains('"invalid" is not an allowed value for option "--platform"'),
            ),
          ),
        );
      });

      testUsingContext('validate build modes argument', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final processManager = FakeProcessManager.list([]);
        final command = BuildSwiftPackage(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
          featureFlags: FakeFeatureFlags(),
          verboseHelp: false,
          codesign: FakeDarwinAddToAppCodesigning(),
        );

        final runner = FlutterCommandRunner(verboseHelp: true);
        runner.addCommand(command);

        expect(
          () => runner.run(<String>['swift-package', '--build-mode', 'invalid']),
          throwsA(
            isA<UsageException>().having(
              (e) => e.message,
              'message',
              contains('"invalid" is not an allowed value for option "--build-mode"'),
            ),
          ),
        );
      });

      group('for output directory', () {
        late MemoryFileSystem fs;
        late FakeProcessManager processManager;
        setUpAll(() {
          fs = MemoryFileSystem.test();
          processManager = FakeProcessManager.list([]);
        });

        testUsingContext(
          'with relative path',
          () async {
            final logger = BufferLogger.test();
            final command = BuildSwiftPackage(
              analytics: FakeAnalytics(),
              artifacts: FakeArtifacts(engineArtifactPath),
              buildSystem: FakeBuildSystem(),
              cache: FakeCache(fs, _flutterRoot),
              fileSystem: fs,
              flutterVersion: FakeFlutterVersion(),
              logger: logger,
              platform: FakePlatform(),
              processManager: processManager,
              templateRenderer: const MustacheTemplateRenderer(),
              xcode: FakeXcode(),
              featureFlags: FakeFeatureFlags(),
              verboseHelp: false,
              codesign: FakeDarwinAddToAppCodesigning(),
            );

            final Directory projectDir = fs.directory('/project')..createSync(recursive: true);
            fs.currentDirectory = projectDir;
            projectDir.childDirectory('ios').createSync();
            projectDir.childFile('pubspec.yaml').createSync();
            projectDir.childDirectory('lib').childFile('main.dart').createSync(recursive: true);

            final runner = FlutterCommandRunner(verboseHelp: true);
            runner.addCommand(command);

            // We expect this to fail because we're not competely mocking it out, we're just testing the output creation
            await expectLater(
              () => runner.run(<String>[
                'swift-package',
                '--output',
                'custom_output',
                '--target',
                '/project/lib/main.dart',
                '--no-pub',
              ]),
              throwsToolExit(),
            );

            expect(
              fs.directory('/project/custom_output/.cache').existsSync(),
              isTrue,
              reason: 'Directory should exist at /project/custom_output/.cache',
            );
          },
          overrides: <Type, Generator>{
            FileSystem: () => fs,
            ProcessManager: () => processManager,
            Cache: () => FakeCache(fs, _flutterRoot),
          },
        );

        testUsingContext(
          'with absolute path',
          () async {
            final logger = BufferLogger.test();
            final command = BuildSwiftPackage(
              analytics: FakeAnalytics(),
              artifacts: FakeArtifacts(engineArtifactPath),
              buildSystem: FakeBuildSystem(),
              cache: FakeCache(fs, _flutterRoot),
              fileSystem: fs,
              flutterVersion: FakeFlutterVersion(),
              logger: logger,
              platform: FakePlatform(),
              processManager: processManager,
              templateRenderer: const MustacheTemplateRenderer(),
              xcode: FakeXcode(),
              featureFlags: FakeFeatureFlags(),
              verboseHelp: false,
              codesign: FakeDarwinAddToAppCodesigning(),
            );

            final Directory projectDir = fs.directory('/project')..createSync(recursive: true);
            fs.currentDirectory = projectDir;
            projectDir.childDirectory('ios').createSync();
            projectDir.childFile('pubspec.yaml').createSync();
            projectDir.childDirectory('lib').childFile('main.dart').createSync(recursive: true);

            final runner = FlutterCommandRunner(verboseHelp: true);
            runner.addCommand(command);

            // We expect this to fail because we're not competely mocking it out, we're just testing the output creation
            await expectLater(
              () => runner.run(<String>[
                'swift-package',
                '--output',
                '/custom_output',
                '--target',
                '/project/lib/main.dart',
                '--no-pub',
              ]),
              throwsToolExit(),
            );

            expect(
              fs.directory('/custom_output/.cache').existsSync(),
              isTrue,
              reason: 'Directory should exist at /custom_output/.cache',
            );
          },
          overrides: <Type, Generator>{
            FileSystem: () => fs,
            ProcessManager: () => processManager,
            Cache: () => FakeCache(fs, _flutterRoot),
          },
        );
      });
    });

    testUsingContext('createSourcesSymlink', () async {
      final fs = MemoryFileSystem.test();
      final logger = BufferLogger.test();
      final processManager = FakeProcessManager.list([]);
      final command = BuildSwiftPackage(
        analytics: FakeAnalytics(),
        artifacts: FakeArtifacts(engineArtifactPath),
        buildSystem: FakeBuildSystem(),
        cache: FakeCache(fs, _flutterRoot),
        fileSystem: fs,
        flutterVersion: FakeFlutterVersion(),
        logger: logger,
        platform: FakePlatform(),
        processManager: processManager,
        templateRenderer: const MustacheTemplateRenderer(),
        xcode: FakeXcode(),
        featureFlags: FakeFeatureFlags(),
        verboseHelp: false,
        codesign: FakeDarwinAddToAppCodesigning(),
      );
      final Directory swiftPackageOutput = fs.directory(nativeIntegrationSwiftPackagePath);
      swiftPackageOutput.createSync(recursive: true);
      command.createSourcesSymlink(swiftPackageOutput, 'Debug');
      final Link generatedSourcesLink = fs.link(pluginRegistrantSwiftPackagePath);
      expect(generatedSourcesLink, exists);
      expect(generatedSourcesLink.targetSync(), './Debug');
    });

    testUsingContext('generateLLDBInitFile', () async {
      final fs = MemoryFileSystem.test();
      final logger = BufferLogger.test();
      final processManager = FakeProcessManager.list([]);
      final command = BuildSwiftPackage(
        analytics: FakeAnalytics(),
        artifacts: FakeArtifacts(engineArtifactPath),
        buildSystem: FakeBuildSystem(),
        cache: FakeCache(fs, _flutterRoot),
        fileSystem: fs,
        flutterVersion: FakeFlutterVersion(),
        logger: logger,
        platform: FakePlatform(),
        processManager: processManager,
        templateRenderer: const MustacheTemplateRenderer(),
        xcode: FakeXcode(),
        featureFlags: FakeFeatureFlags(),
        verboseHelp: false,
        codesign: FakeDarwinAddToAppCodesigning(),
      );
      final Directory appPath = fs.currentDirectory.childDirectory('my_flutter_app');
      appPath.childFile('ios/Flutter/ephemeral/flutter_lldbinit').createSync(recursive: true);
      appPath.childFile('ios/Flutter/ephemeral/flutter_lldb_helper.py').createSync(recursive: true);
      final Directory scriptsOutput = fs.directory(scriptsDirectoryPath);
      command.generateLLDBInitFile(
        scriptsDirectory: scriptsOutput,
        buildInfos: [BuildInfo.debug],
        project: FakeIosProject(directory: appPath),
      );
      final File lldbInitFile = scriptsOutput.childFile('flutter_lldbinit');
      final File lldbHelperPythonFile = scriptsOutput.childFile('flutter_lldb_helper.py');
      expect(lldbInitFile, exists);
      expect(lldbHelperPythonFile, exists);
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
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterRoot: _flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: fs.directory(_flutterAppPath)),
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
        final flutterFrameworkDependency = FlutterFrameworkDependency(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final appAndNativeAssetsDependencies = AppFrameworkAndNativeAssetsDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        late final cocoapodDependencies = CocoaPodPluginDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );

        // Plugin A represents a SwiftPM plugin
        final Directory modeDirectory = fs.directory(debugModeDirectoryPath);
        final pluginA = FakePlugin(name: 'PluginA', darwinPlatform: targetPlatform);
        pluginSwiftDependencies.copiedPlugins.add((
          name: pluginA.name,
          swiftPackagePath: '$pluginsDirectoryPath/PluginA',
          packageMinimumSupportedPlatform: SwiftPackageSupportedPlatform(
            platform: SwiftPackagePlatform.ios,
            version: Version(13, 0, 0),
          ),
        ));

        // Plugin B represents a CocoaPod plugin
        final pluginB = FakePlugin(
          name: 'PluginB',
          darwinPlatform: targetPlatform,
          supportsSwiftPM: false,
        );
        fs
            .directory('$debugCocoaPodsDirectoryPath/PluginB.xcframework')
            .createSync(recursive: true);

        // Plugin C represents a Native Asset
        fs
            .directory('$debugNativeAssetsDirectoryPath/PluginC.xcframework')
            .createSync(recursive: true);

        await package.generateSwiftPackage(
          modeDirectory: modeDirectory,
          plugins: [pluginA, pluginB],
          xcodeBuildConfiguration: 'Debug',
          pluginSwiftDependencies: pluginSwiftDependencies,
          flutterFrameworkDependency: flutterFrameworkDependency,
          appAndNativeAssetsDependencies: appAndNativeAssetsDependencies,
          cocoapodDependencies: cocoapodDependencies,
          packagesForConfiguration: fs.directory(debugPackagesDirectoryPath),
          xcframeworkOutput: fs.directory(debugFrameworksDirectoryPath),
        );

        expect(logger.traceText, isEmpty);
        expect(processManager, hasNoRemainingExpectations);
        final File generatedPackageManifest = modeDirectory.childFile('Package.swift');
        expect(generatedPackageManifest, exists);
        expect(generatedPackageManifest.readAsStringSync(), '''
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
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
        .package(name: "FlutterFramework", path: "Packages/FlutterFramework"),
        .package(name: "PluginA", path: "Packages/PluginA")
    ],
    targets: [
        .target(
            name: "FlutterPluginRegistrant",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "PluginA", package: "PluginA"),
                .target(name: "PluginC"),
                .target(name: "App"),
                .target(name: "PluginB")
            ]
        ),
        .binaryTarget(
            name: "PluginC",
            path: "Frameworks/NativeAssets/PluginC.xcframework"
        ),
        .binaryTarget(
            name: "App",
            path: "Frameworks/App.xcframework"
        ),
        .binaryTarget(
            name: "PluginB",
            path: "Frameworks/CocoaPods/PluginB.xcframework"
        )
    ]
)
''');
        final File generatedSource = modeDirectory
            .childDirectory('Sources')
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
import PluginB

@objc public class GeneratedPluginRegistrant: NSObject {
    @objc public static func register(with registry: FlutterPluginRegistry) {
        if let pluginAPlugin = registry.registrar(forPlugin: "PluginAPlugin") {
            PluginAPlugin.register(with: pluginAPlugin)
        }
        if let pluginBPlugin = registry.registrar(forPlugin: "PluginBPlugin") {
            PluginBPlugin.register(with: pluginBPlugin)
        }
    }
}
''');
      });
    });

    group('FlutterFrameworkDependency', () {
      testWithoutContext('generateArtifacts', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final Directory xcframeworkOutput = fs.directory(debugFrameworksDirectoryPath);
        final processManager = FakeProcessManager.list([
          FakeCommand(
            command: [
              'rsync',
              '-av',
              '--delete',
              '--filter',
              '- .DS_Store/',
              '--chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r',
              engineArtifactPath,
              xcframeworkOutput.path,
            ],
          ),
        ]);
        const FlutterDarwinPlatform targetPlatform = .ios;
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterRoot: _flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: fs.directory(_flutterAppPath)),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final flutterFrameworkDependency = FlutterFrameworkDependency(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );

        await flutterFrameworkDependency.generateArtifacts(
          buildMode: BuildMode.debug,
          xcframeworkOutput: xcframeworkOutput,
          codesignIdentity: null,
        );
        expect(processManager, hasNoRemainingExpectations);
      });

      testWithoutContext('generateArtifacts and codesign', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final Directory xcframeworkOutput = fs.directory(debugFrameworksDirectoryPath);
        final Directory flutterXCFramework = xcframeworkOutput.childDirectory(
          'Flutter.xcframework',
        );
        final processManager = FakeProcessManager.list([
          FakeCommand(
            command: [
              'rsync',
              '-av',
              '--delete',
              '--filter',
              '- .DS_Store/',
              '--chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r',
              engineArtifactPath,
              xcframeworkOutput.path,
            ],
          ),
          FakeCommand(
            command: ['codesign', '-d', flutterXCFramework.path],
            stderr: '${flutterXCFramework.path}: code object is not signed at all',
          ),
          FakeCommand(
            command: [
              'codesign',
              '--force',
              '--sign',
              codesignIdentity,
              '--timestamp=none',
              flutterXCFramework.path,
            ],
          ),
        ]);
        const FlutterDarwinPlatform targetPlatform = .ios;
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterRoot: _flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: fs.directory(_flutterAppPath)),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final flutterFrameworkDependency = FlutterFrameworkDependency(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );

        await flutterFrameworkDependency.generateArtifacts(
          buildMode: BuildMode.debug,
          xcframeworkOutput: xcframeworkOutput,
          codesignIdentity: codesignIdentity,
        );
        expect(processManager, hasNoRemainingExpectations);
      });

      testWithoutContext('generateSwiftPackage', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();

        final processManager = FakeProcessManager.list([]);
        const FlutterDarwinPlatform targetPlatform = .ios;
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterRoot: _flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: fs.directory(_flutterAppPath)),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final flutterFrameworkDependency = FlutterFrameworkDependency(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final Directory packageDirectory = fs.directory(debugPackagesDirectoryPath);
        await flutterFrameworkDependency.generateSwiftPackage(packageDirectory);
        expect(packageDirectory.existsSync(), isTrue);
        final File manifest = packageDirectory
            .childDirectory('FlutterFramework')
            .childFile('Package.swift');
        expect(manifest.existsSync(), isTrue);
        expect(manifest.readAsStringSync(), '''
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterFramework",
    products: [
        .library(name: "FlutterFramework", targets: ["FlutterFramework"])
    ],
    dependencies: [\n        \n    ],
    targets: [
        .target(
            name: "FlutterFramework",
            dependencies: [
                .target(name: "Flutter")
            ]
        ),
        .binaryTarget(
            name: "Flutter",
            path: "../../Frameworks/Flutter.xcframework"
        )
    ]
)
''');
        final Directory xcframework = fs.directory(
          '$debugFrameworksDirectoryPath/Flutter.xcframework',
        )..createSync(recursive: true);
        expect(
          packageDirectory
              .childDirectory('FlutterFramework')
              .childDirectory('../../Frameworks/Flutter.xcframework')
              .resolveSymbolicLinksSync(),
          '/${xcframework.path}',
        );
      });
    });

    group('AppFrameworkAndNativeAssetsDependencies', () {
      testWithoutContext('generateArtifacts for Debug', () async {
        final fs = MemoryFileSystem.test();

        final logger = BufferLogger.test();
        final Directory xcframeworkOutput = fs.directory(debugFrameworksDirectoryPath);
        final Directory cacheDirectory = fs.directory(cacheDirectoryPath);
        final Directory appDirectory = fs.directory(_flutterAppPath)..createSync(recursive: true);

        fs.currentDirectory = appDirectory;

        final Directory generatedAppFramework = cacheDirectory.childDirectory(
          'Debug/macosx/App.framework',
        )..createSync(recursive: true);
        generatedAppFramework.childFile('Resources/flutter_assets/NativeAssetsManifest.json')
          ..createSync(recursive: true)
          ..writeAsStringSync(
            '{"native-assets":{"macos_x64":{"package:my_native_asset/my_native_asset.dylib":["absolute","my_native_asset.framework/my_native_asset"]},"macos_arm64":{"package:my_native_asset/my_native_asset.dylib":["absolute","my_native_asset.framework/my_native_asset"]}}}',
          );
        final Directory nativeAssetFramework = cacheDirectory.childDirectory(
          'Debug/macosx/native_assets/my_native_asset.framework',
        )..createSync(recursive: true);

        final processManager = FakeProcessManager.list([
          FakeCommand(
            command: [
              'xcrun',
              'xcodebuild',
              '-create-xcframework',
              '-framework',
              generatedAppFramework.path,
              '-output',
              '$debugFrameworksDirectoryPath/App.xcframework',
            ],
          ),
          FakeCommand(
            command: [
              'xcrun',
              'xcodebuild',
              '-create-xcframework',
              '-framework',
              nativeAssetFramework.path,
              '-output',
              '$debugNativeAssetsDirectoryPath/my_native_asset.xcframework',
            ],
          ),
        ]);
        const FlutterDarwinPlatform targetPlatform = .macos;
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(
            expectations: [
              BuildExpectations(
                expectedTargetName: 'debug_macos_bundle_flutter_assets',
                expectedProjectDirPath: _flutterAppPath,
                expectedPackageConfigPath: '$flutterAppDartToolPath/package_config.json',
                expectedOutputDirPath: '$cacheDirectoryPath/Debug/macosx',
                expectedBuildDirPath: '$flutterAppBuildPath/',
                expectedCacheDirPath: flutterCachePath,
                expectedFlutterRootDirPath: _flutterRoot,
                expectedEngineVersion: _engineVersion,
                expectedDefines: <String, String>{
                  'TargetFile': 'lib/main.dart',
                  'TargetPlatform': 'darwin',
                  'DarwinArchs': 'x86_64 arm64',
                  'BuildMode': 'debug',
                  'DartObfuscation': 'false',
                  'TrackWidgetCreation': 'true',
                  'TreeShakeIcons': 'false',
                  'BuildSwiftPackage': 'true',
                },
                expectedGenerateDartPluginRegistry: true,
              ),
            ],
          ),
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterRoot: _flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: fs.directory(_flutterAppPath)),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final appAndNativeAssetsDependencies = AppFrameworkAndNativeAssetsDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );

        await appAndNativeAssetsDependencies.generateArtifacts(
          buildInfo: BuildInfo.debug,
          cacheDirectory: cacheDirectory,
          packageConfigPath: '$flutterAppDartToolPath/package_config.json',
          targetFile: 'lib/main.dart',
          xcframeworkOutput: xcframeworkOutput,
          codesignIdentity: null,
        );
        expect(processManager, hasNoRemainingExpectations);
        expect(logger.warningText, isEmpty);
      });

      testWithoutContext('generateArtifacts for Release', () async {
        final fs = MemoryFileSystem.test();

        final logger = BufferLogger.test();
        final Directory xcframeworkOutput = fs.directory(releaseFrameworksDirectoryPath);
        final Directory cacheDirectory = fs.directory(cacheDirectoryPath);
        final Directory appDirectory = fs.directory(_flutterAppPath)..createSync(recursive: true);

        fs.currentDirectory = appDirectory;

        final Directory generatedAppFramework = cacheDirectory.childDirectory(
          'Release/macosx/App.framework',
        )..createSync(recursive: true);
        generatedAppFramework.childFile('Resources/flutter_assets/NativeAssetsManifest.json')
          ..createSync(recursive: true)
          ..writeAsStringSync(
            '{"native-assets":{"macos_x64":{"package:my_native_asset/my_native_asset.dylib":["absolute","my_native_asset.framework/my_native_asset"]},"macos_arm64":{"package:my_native_asset/my_native_asset.dylib":["absolute","my_native_asset.framework/my_native_asset"]}}}',
          );
        final Directory nativeAssetFramework = cacheDirectory.childDirectory(
          'Release/macosx/native_assets/my_native_asset.framework',
        )..createSync(recursive: true);
        final Directory nativeAssetDsym = cacheDirectory.childDirectory(
          'Release/macosx/native_assets/my_native_asset.framework.dSYM',
        )..createSync(recursive: true);

        final processManager = FakeProcessManager.list([
          FakeCommand(
            command: [
              'xcrun',
              'xcodebuild',
              '-create-xcframework',
              '-framework',
              generatedAppFramework.path,
              '-output',
              '$releaseFrameworksDirectoryPath/App.xcframework',
            ],
          ),
          FakeCommand(
            command: [
              'xcrun',
              'xcodebuild',
              '-create-xcframework',
              '-framework',
              nativeAssetFramework.path,
              '-debug-symbols',
              nativeAssetDsym.path,
              '-output',
              '$releaseNativeAssetsDirectoryPath/my_native_asset.xcframework',
            ],
          ),
        ]);
        const FlutterDarwinPlatform targetPlatform = .macos;
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(
            expectations: [
              BuildExpectations(
                expectedTargetName: 'release_macos_bundle_flutter_assets',
                expectedProjectDirPath: _flutterAppPath,
                expectedPackageConfigPath: '$flutterAppDartToolPath/package_config.json',
                expectedOutputDirPath: '$cacheDirectoryPath/Release/macosx',
                expectedBuildDirPath: '$flutterAppBuildPath/',
                expectedCacheDirPath: flutterCachePath,
                expectedFlutterRootDirPath: _flutterRoot,
                expectedEngineVersion: _engineVersion,
                expectedDefines: <String, String>{
                  'TargetFile': 'lib/main.dart',
                  'TargetPlatform': 'darwin',
                  'DarwinArchs': 'x86_64 arm64',
                  'BuildMode': 'release',
                  'DartObfuscation': 'false',
                  'TrackWidgetCreation': 'false',
                  'TreeShakeIcons': 'true',
                  'BuildSwiftPackage': 'true',
                },
                expectedGenerateDartPluginRegistry: true,
              ),
            ],
          ),
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterRoot: _flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: fs.directory(_flutterAppPath)),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final appAndNativeAssetsDependencies = AppFrameworkAndNativeAssetsDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );

        await appAndNativeAssetsDependencies.generateArtifacts(
          buildInfo: BuildInfo.release,
          cacheDirectory: cacheDirectory,
          packageConfigPath: '$flutterAppDartToolPath/package_config.json',
          targetFile: 'lib/main.dart',
          xcframeworkOutput: xcframeworkOutput,
          codesignIdentity: null,
        );
        expect(processManager, hasNoRemainingExpectations);
        expect(logger.warningText, isEmpty);
      });

      testWithoutContext('generateArtifacts and codesign', () async {
        final fs = MemoryFileSystem.test();

        final logger = BufferLogger.test();
        final Directory xcframeworkOutput = fs.directory(releaseFrameworksDirectoryPath);
        final Directory cacheDirectory = fs.directory(cacheDirectoryPath);
        final Directory appDirectory = fs.directory(_flutterAppPath)..createSync(recursive: true);

        fs.currentDirectory = appDirectory;

        final Directory generatedAppFramework = cacheDirectory.childDirectory(
          'Release/macosx/App.framework',
        )..createSync(recursive: true);
        generatedAppFramework.childFile('Resources/flutter_assets/NativeAssetsManifest.json')
          ..createSync(recursive: true)
          ..writeAsStringSync(
            '{"native-assets":{"macos_x64":{"package:my_native_asset/my_native_asset.dylib":["absolute","my_native_asset.framework/my_native_asset"]},"macos_arm64":{"package:my_native_asset/my_native_asset.dylib":["absolute","my_native_asset.framework/my_native_asset"]}}}',
          );
        final Directory nativeAssetFramework = cacheDirectory.childDirectory(
          'Release/macosx/native_assets/my_native_asset.framework',
        )..createSync(recursive: true);
        final Directory nativeAssetDsym = cacheDirectory.childDirectory(
          'Release/macosx/native_assets/my_native_asset.framework.dSYM',
        )..createSync(recursive: true);

        final processManager = FakeProcessManager.list([
          FakeCommand(
            command: [
              'xcrun',
              'xcodebuild',
              '-create-xcframework',
              '-framework',
              generatedAppFramework.path,
              '-output',
              '$releaseFrameworksDirectoryPath/App.xcframework',
            ],
          ),
          const FakeCommand(
            command: [
              'codesign',
              '--force',
              '--sign',
              codesignIdentity,
              '$releaseFrameworksDirectoryPath/App.xcframework',
            ],
          ),
          FakeCommand(
            command: [
              'xcrun',
              'xcodebuild',
              '-create-xcframework',
              '-framework',
              nativeAssetFramework.path,
              '-debug-symbols',
              nativeAssetDsym.path,
              '-output',
              '$releaseNativeAssetsDirectoryPath/my_native_asset.xcframework',
            ],
          ),
          const FakeCommand(
            command: [
              'codesign',
              '--force',
              '--sign',
              codesignIdentity,
              '$releaseNativeAssetsDirectoryPath/my_native_asset.xcframework',
            ],
          ),
        ]);
        const FlutterDarwinPlatform targetPlatform = .macos;
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(
            expectations: [
              BuildExpectations(
                expectedTargetName: 'release_macos_bundle_flutter_assets',
                expectedProjectDirPath: _flutterAppPath,
                expectedPackageConfigPath: '$flutterAppDartToolPath/package_config.json',
                expectedOutputDirPath: '$cacheDirectoryPath/Release/macosx',
                expectedBuildDirPath: '$flutterAppBuildPath/',
                expectedCacheDirPath: flutterCachePath,
                expectedFlutterRootDirPath: _flutterRoot,
                expectedEngineVersion: _engineVersion,
                expectedDefines: <String, String>{
                  'TargetFile': 'lib/main.dart',
                  'TargetPlatform': 'darwin',
                  'DarwinArchs': 'x86_64 arm64',
                  'BuildMode': 'release',
                  'DartObfuscation': 'false',
                  'TrackWidgetCreation': 'false',
                  'TreeShakeIcons': 'true',
                  'BuildSwiftPackage': 'true',
                },
                expectedGenerateDartPluginRegistry: true,
              ),
            ],
          ),
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterRoot: _flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: fs.directory(_flutterAppPath)),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final appAndNativeAssetsDependencies = AppFrameworkAndNativeAssetsDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );

        await appAndNativeAssetsDependencies.generateArtifacts(
          buildInfo: BuildInfo.release,
          cacheDirectory: cacheDirectory,
          packageConfigPath: '$flutterAppDartToolPath/package_config.json',
          targetFile: 'lib/main.dart',
          xcframeworkOutput: xcframeworkOutput,
          codesignIdentity: codesignIdentity,
        );
        expect(processManager, hasNoRemainingExpectations);
        expect(logger.warningText, isEmpty);
      });

      testWithoutContext('generateArtifacts prints warning for missing native asset sdk', () async {
        final fs = MemoryFileSystem.test();

        final logger = BufferLogger.test();
        final Directory xcframeworkOutput = fs.directory(debugFrameworksDirectoryPath);
        final Directory cacheDirectory = fs.directory(cacheDirectoryPath);
        final Directory appDirectory = fs.directory(_flutterAppPath)..createSync(recursive: true);

        fs.currentDirectory = appDirectory;

        final Directory generatedAppFramework = cacheDirectory.childDirectory(
          'Debug/iphoneos/App.framework',
        )..createSync(recursive: true);
        generatedAppFramework.childFile('flutter_assets/NativeAssetsManifest.json')
          ..createSync(recursive: true)
          ..writeAsStringSync(
            '{"native-assets":{"ios_arm64":{"package:my_native_asset/my_native_asset.dylib":["absolute","my_native_asset.framework/my_native_asset"]}}}',
          );
        final Directory nativeAssetFramework = cacheDirectory.childDirectory(
          'Debug/iphoneos/native_assets/my_native_asset.framework',
        )..createSync(recursive: true);
        final Directory generatedAppSimulatorFramework = cacheDirectory.childDirectory(
          'Debug/iphonesimulator/App.framework',
        )..createSync(recursive: true);
        generatedAppSimulatorFramework.childFile('flutter_assets/NativeAssetsManifest.json')
          ..createSync(recursive: true)
          ..writeAsStringSync('{"native-assets":{}}');

        final processManager = FakeProcessManager.list([
          FakeCommand(
            command: [
              'xcrun',
              'xcodebuild',
              '-create-xcframework',
              '-framework',
              generatedAppFramework.path,
              '-framework',
              generatedAppSimulatorFramework.path,
              '-output',
              '$debugFrameworksDirectoryPath/App.xcframework',
            ],
          ),
          FakeCommand(
            command: [
              'xcrun',
              'xcodebuild',
              '-create-xcframework',
              '-framework',
              nativeAssetFramework.path,
              '-output',
              '$debugNativeAssetsDirectoryPath/my_native_asset.xcframework',
            ],
          ),
        ]);
        const FlutterDarwinPlatform targetPlatform = .ios;
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(
            expectations: [
              BuildExpectations(
                expectedTargetName: 'debug_ios_bundle_flutter_assets',
                expectedProjectDirPath: _flutterAppPath,
                expectedPackageConfigPath: '$flutterAppDartToolPath/package_config.json',
                expectedOutputDirPath: '$cacheDirectoryPath/Debug/iphoneos',
                expectedBuildDirPath: '$flutterAppBuildPath/',
                expectedCacheDirPath: flutterCachePath,
                expectedFlutterRootDirPath: _flutterRoot,
                expectedEngineVersion: _engineVersion,
                expectedDefines: <String, String>{
                  'TargetFile': 'lib/main.dart',
                  'TargetPlatform': 'ios',
                  'IosArchs': 'arm64',
                  'SdkRoot': _iosSdkRoot,
                  'BuildMode': 'debug',
                  'DartObfuscation': 'false',
                  'TrackWidgetCreation': 'true',
                  'TreeShakeIcons': 'false',
                  'BuildSwiftPackage': 'true',
                },
                expectedGenerateDartPluginRegistry: true,
              ),
              BuildExpectations(
                expectedTargetName: 'debug_ios_bundle_flutter_assets',
                expectedProjectDirPath: _flutterAppPath,
                expectedPackageConfigPath: '$flutterAppDartToolPath/package_config.json',
                expectedOutputDirPath: '$cacheDirectoryPath/Debug/iphonesimulator',
                expectedBuildDirPath: '$flutterAppBuildPath/',
                expectedCacheDirPath: flutterCachePath,
                expectedFlutterRootDirPath: _flutterRoot,
                expectedEngineVersion: _engineVersion,
                expectedDefines: <String, String>{
                  'TargetFile': 'lib/main.dart',
                  'TargetPlatform': 'ios',
                  'IosArchs': 'x86_64 arm64',
                  'SdkRoot': _iosSdkRoot,
                  'BuildMode': 'debug',
                  'DartObfuscation': 'false',
                  'TrackWidgetCreation': 'true',
                  'TreeShakeIcons': 'false',
                  'BuildSwiftPackage': 'true',
                },
                expectedGenerateDartPluginRegistry: true,
              ),
            ],
          ),
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterRoot: _flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: fs.directory(_flutterAppPath)),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final appAndNativeAssetsDependencies = AppFrameworkAndNativeAssetsDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );

        await appAndNativeAssetsDependencies.generateArtifacts(
          buildInfo: BuildInfo.debug,
          cacheDirectory: cacheDirectory,
          packageConfigPath: '$flutterAppDartToolPath/package_config.json',
          targetFile: 'lib/main.dart',
          xcframeworkOutput: xcframeworkOutput,
          codesignIdentity: null,
        );

        expect(processManager, hasNoRemainingExpectations);
        expect(
          logger.warningText,
          contains('The asset "my_native_asset" does not support iOS Simulator (iphonesimulator)'),
        );
      });

      testWithoutContext(
        'generateArtifacts throws error when native asset framework name mismatch',
        () async {
          final fs = MemoryFileSystem.test();

          final logger = BufferLogger.test();
          final Directory xcframeworkOutput = fs.directory(debugFrameworksDirectoryPath);
          final Directory cacheDirectory = fs.directory(cacheDirectoryPath);
          final Directory appDirectory = fs.directory(_flutterAppPath)..createSync(recursive: true);

          fs.currentDirectory = appDirectory;

          final Directory generatedAppFramework = cacheDirectory.childDirectory(
            'Debug/iphoneos/App.framework',
          )..createSync(recursive: true);
          generatedAppFramework.childFile('flutter_assets/NativeAssetsManifest.json')
            ..createSync(recursive: true)
            ..writeAsStringSync(
              '{"native-assets":{"ios_arm64":{"package:my_native_asset/my_native_asset.dylib":["absolute","my_native_asset.framework/my_native_asset"]}}}',
            );
          cacheDirectory
              .childDirectory('Debug/iphoneos/native_assets/my_native_asset.framework')
              .createSync(recursive: true);
          final Directory generatedAppSimulatorFramework = cacheDirectory.childDirectory(
            'Debug/iphonesimulator/App.framework',
          )..createSync(recursive: true);
          generatedAppSimulatorFramework.childFile('flutter_assets/NativeAssetsManifest.json')
            ..createSync(recursive: true)
            ..writeAsStringSync(
              '{"native-assets":{"ios_x64":{"package:my_native_asset/my_native_asset.dylib":["absolute","my_native_asset_sim.framework/my_native_asset"]},"ios_arm64":{"package:my_native_asset/my_native_asset.dylib":["absolute","my_native_asset_sim.framework/my_native_asset"]}}}',
            );
          cacheDirectory
              .childDirectory('Debug/iphonesimulator/native_assets/my_native_asset_sim.framework')
              .createSync(recursive: true);

          final processManager = FakeProcessManager.list([
            FakeCommand(
              command: [
                'xcrun',
                'xcodebuild',
                '-create-xcframework',
                '-framework',
                generatedAppFramework.path,
                '-framework',
                generatedAppSimulatorFramework.path,
                '-output',
                '$debugFrameworksDirectoryPath/App.xcframework',
              ],
            ),
          ]);
          const FlutterDarwinPlatform targetPlatform = .ios;
          final testUtils = BuildSwiftPackageUtils(
            analytics: FakeAnalytics(),
            artifacts: FakeArtifacts(engineArtifactPath),
            buildSystem: FakeBuildSystem(
              expectations: [
                BuildExpectations(
                  expectedTargetName: 'debug_ios_bundle_flutter_assets',
                  expectedProjectDirPath: _flutterAppPath,
                  expectedPackageConfigPath: '$flutterAppDartToolPath/package_config.json',
                  expectedOutputDirPath: '$cacheDirectoryPath/Debug/iphoneos',
                  expectedBuildDirPath: '$flutterAppBuildPath/',
                  expectedCacheDirPath: flutterCachePath,
                  expectedFlutterRootDirPath: _flutterRoot,
                  expectedEngineVersion: _engineVersion,
                  expectedDefines: <String, String>{
                    'TargetFile': 'lib/main.dart',
                    'TargetPlatform': 'ios',
                    'IosArchs': 'arm64',
                    'SdkRoot': _iosSdkRoot,
                    'BuildMode': 'debug',
                    'DartObfuscation': 'false',
                    'TrackWidgetCreation': 'true',
                    'TreeShakeIcons': 'false',
                    'BuildSwiftPackage': 'true',
                  },
                  expectedGenerateDartPluginRegistry: true,
                ),
                BuildExpectations(
                  expectedTargetName: 'debug_ios_bundle_flutter_assets',
                  expectedProjectDirPath: _flutterAppPath,
                  expectedPackageConfigPath: '$flutterAppDartToolPath/package_config.json',
                  expectedOutputDirPath: '$cacheDirectoryPath/Debug/iphonesimulator',
                  expectedBuildDirPath: '$flutterAppBuildPath/',
                  expectedCacheDirPath: flutterCachePath,
                  expectedFlutterRootDirPath: _flutterRoot,
                  expectedEngineVersion: _engineVersion,
                  expectedDefines: <String, String>{
                    'TargetFile': 'lib/main.dart',
                    'TargetPlatform': 'ios',
                    'IosArchs': 'x86_64 arm64',
                    'SdkRoot': _iosSdkRoot,
                    'BuildMode': 'debug',
                    'DartObfuscation': 'false',
                    'TrackWidgetCreation': 'true',
                    'TreeShakeIcons': 'false',
                    'BuildSwiftPackage': 'true',
                  },
                  expectedGenerateDartPluginRegistry: true,
                ),
              ],
            ),
            cache: FakeCache(fs, _flutterRoot),
            fileSystem: fs,
            flutterRoot: _flutterRoot,
            flutterVersion: FakeFlutterVersion(),
            logger: logger,
            platform: FakePlatform(),
            processManager: processManager,
            project: FakeFlutterProject(directory: fs.directory(_flutterAppPath)),
            templateRenderer: const MustacheTemplateRenderer(),
            xcode: FakeXcode(),
          );
          final appAndNativeAssetsDependencies = AppFrameworkAndNativeAssetsDependencies(
            targetPlatform: targetPlatform,
            utils: testUtils,
          );
          await expectLater(
            () => appAndNativeAssetsDependencies.generateArtifacts(
              buildInfo: BuildInfo.debug,
              cacheDirectory: cacheDirectory,
              packageConfigPath: '$flutterAppDartToolPath/package_config.json',
              targetFile: 'lib/main.dart',
              xcframeworkOutput: xcframeworkOutput,
              codesignIdentity: null,
            ),
            throwsToolExit(
              message:
                  'The asset "my_native_asset" has different framework paths across platforms:\n'
                  '  - iphoneos: my_native_asset.framework/my_native_asset\n'
                  '  - iphonesimulator: my_native_asset_sim.framework/my_native_asset',
            ),
          );

          expect(processManager, hasNoRemainingExpectations);
          expect(logger.warningText, isEmpty);
        },
      );

      testWithoutContext('generateDependencies', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final processManager = FakeProcessManager.list([]);
        const FlutterDarwinPlatform targetPlatform = .ios;
        fs
            .directory('$debugNativeAssetsDirectoryPath/my_native_asset.xcframework')
            .createSync(recursive: true);
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterRoot: _flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: fs.directory(_flutterAppPath)),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final appAndNativeAssetsDependencies = AppFrameworkAndNativeAssetsDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final (
          List<SwiftPackageTargetDependency> targetDependencies,
          List<SwiftPackageTarget> packageTargets,
        ) = appAndNativeAssetsDependencies.generateDependencies(
          xcframeworkOutput: fs.directory(debugFrameworksDirectoryPath),
        );
        expect(targetDependencies.length, 2);
        expect(packageTargets.length, 2);
        expect(targetDependencies[0].format(), contains('.target(name: "my_native_asset")'));
        expect(packageTargets[0].format(), '''
.binaryTarget(
            name: "my_native_asset",
            path: "Frameworks/NativeAssets/my_native_asset.xcframework"
        )''');
        expect(targetDependencies[1].format(), contains('.target(name: "App")'));
        expect(packageTargets[1].format(), '''
.binaryTarget(
            name: "App",
            path: "Frameworks/App.xcframework"
        )''');
      });

      testWithoutContext('determineTarget', () {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final processManager = FakeProcessManager.list([]);
        const FlutterDarwinPlatform targetPlatform = .ios;
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterRoot: _flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: fs.directory(_flutterAppPath)),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final appAndNativeAssetsDependencies = AppFrameworkAndNativeAssetsDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final Target iphoneDebugTarget = appAndNativeAssetsDependencies.determineTarget(
          targetPlatform,
          XcodeSdk.IPhoneOS,
          BuildInfo.debug,
        );
        final Target iphoneProfileTarget = appAndNativeAssetsDependencies.determineTarget(
          targetPlatform,
          XcodeSdk.IPhoneOS,
          BuildInfo.profile,
        );
        final Target iphoneReleaseTarget = appAndNativeAssetsDependencies.determineTarget(
          targetPlatform,
          XcodeSdk.IPhoneOS,
          BuildInfo.release,
        );
        final Target simulatorDebugTarget = appAndNativeAssetsDependencies.determineTarget(
          targetPlatform,
          XcodeSdk.IPhoneSimulator,
          BuildInfo.debug,
        );
        final Target simulatorProfileTarget = appAndNativeAssetsDependencies.determineTarget(
          targetPlatform,
          XcodeSdk.IPhoneSimulator,
          BuildInfo.profile,
        );
        final Target simulatorReleaseTarget = appAndNativeAssetsDependencies.determineTarget(
          targetPlatform,
          XcodeSdk.IPhoneSimulator,
          BuildInfo.release,
        );
        expect(iphoneDebugTarget.name, 'debug_ios_bundle_flutter_assets');
        expect(iphoneProfileTarget.name, 'profile_ios_bundle_flutter_assets');
        expect(iphoneReleaseTarget.name, 'release_ios_bundle_flutter_assets');
        expect(simulatorDebugTarget.name, 'debug_ios_bundle_flutter_assets');
        expect(simulatorProfileTarget.name, 'debug_ios_bundle_flutter_assets');
        expect(simulatorReleaseTarget.name, 'debug_ios_bundle_flutter_assets');
      });
    });

    group('CocoaPodPluginDependencies', () {
      testWithoutContext('generateArtifacts', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        const FlutterDarwinPlatform targetPlatform = .ios;
        final Directory podsDirectory = fs.directory('$_flutterAppPath/${targetPlatform.name}/Pods')
          ..createSync(recursive: true);
        _createPodFingerprintFiles(fs: fs, platformName: targetPlatform.name);
        final Directory xcframeworkOutput = fs.directory(debugFrameworksDirectoryPath);
        const iphoneosDirPath = '$debugCocoapodCache/iphoneos';
        const iphoneosCocoapodPluginPath =
            '$iphoneosDirPath/Debug-iphoneos/cocoapod_plugin/cocoapod_plugin.framework';
        const simulatorDirPath = '$debugCocoapodCache/iphonesimulator';
        const simulatorCocoapodPluginPath =
            '$simulatorDirPath/Debug-iphonesimulator/cocoapod_plugin/cocoapod_plugin.framework';
        const cocoapodPluginXCFrameworkPath =
            '$debugCocoaPodsDirectoryPath/cocoapod_plugin.xcframework';
        final File identityFile = fs.file(codesignIdentityFile);
        identityFile
          ..createSync(recursive: true)
          ..writeAsStringSync('');

        final processManager = FakeProcessManager.list([
          FakeCommand(
            command: const [
              'xcrun',
              'xcodebuild',
              '-alltargets',
              '-sdk',
              'iphoneos',
              '-configuration',
              'Debug',
              'SYMROOT=$iphoneosDirPath',
              'ONLY_ACTIVE_ARCH=NO',
              'BUILD_LIBRARY_FOR_DISTRIBUTION=YES',
            ],
            onRun: (command) {
              fs.directory(iphoneosCocoapodPluginPath).createSync(recursive: true);
            },
            workingDirectory: podsDirectory.path,
          ),
          FakeCommand(
            command: const [
              'xcrun',
              'xcodebuild',
              '-alltargets',
              '-sdk',
              'iphonesimulator',
              '-configuration',
              'Debug',
              'SYMROOT=$simulatorDirPath',
              'ONLY_ACTIVE_ARCH=NO',
              'BUILD_LIBRARY_FOR_DISTRIBUTION=YES',
            ],
            onRun: (command) {
              fs.directory(simulatorCocoapodPluginPath).createSync(recursive: true);
            },
            workingDirectory: podsDirectory.path,
          ),
          FakeCommand(
            command: const [
              'xcrun',
              'xcodebuild',
              '-create-xcframework',
              '-framework',
              iphoneosCocoapodPluginPath,
              '-framework',
              simulatorCocoapodPluginPath,
              '-output',
              cocoapodPluginXCFrameworkPath,
            ],
            onRun: (command) {
              fs.directory(cocoapodPluginXCFrameworkPath).createSync(recursive: true);
            },
          ),
        ]);

        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterRoot: _flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: fs.directory(_flutterAppPath)),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final cocoapodDependencies = CocoaPodPluginDependenciesSkipPodProcessing(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final pluginSwiftDependencies = FlutterPluginSwiftDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );

        await cocoapodDependencies.generateArtifacts(
          buildInfo: BuildInfo.debug,
          cacheDirectory: fs.directory(cacheDirectoryPath),
          xcframeworkOutput: xcframeworkOutput,
          buildStatic: false,
          codesignIdentity: null,
          codesignIdentityFile: identityFile,
          pluginSwiftDependencies: pluginSwiftDependencies,
        );

        // Run again to verify fingerprinter caches
        await cocoapodDependencies.generateArtifacts(
          buildInfo: BuildInfo.debug,
          cacheDirectory: fs.directory(cacheDirectoryPath),
          xcframeworkOutput: xcframeworkOutput,
          buildStatic: false,
          codesignIdentity: null,
          codesignIdentityFile: identityFile,
          pluginSwiftDependencies: pluginSwiftDependencies,
        );
        expect(processManager, hasNoRemainingExpectations);
      });

      testWithoutContext('generateArtifacts module skips FlutterPluginRegistrant', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        const FlutterDarwinPlatform targetPlatform = .ios;
        fs.directory('$_flutterAppPath/${targetPlatform.name}/Pods').createSync(recursive: true);
        _createPodFingerprintFiles(fs: fs, platformName: targetPlatform.name);
        final Directory xcframeworkOutput = fs.directory(debugFrameworksDirectoryPath);
        const iphoneosDirPath = '$debugCocoapodCache/iphoneos';
        const simulatorDirPath = '$debugCocoapodCache/iphonesimulator';
        const iphoneosRegistrantPath =
            '$iphoneosDirPath/Debug-iphoneos/FlutterPluginRegistrant/FlutterPluginRegistrant.framework';
        final File identityFile = fs.file(codesignIdentityFile);
        identityFile
          ..createSync(recursive: true)
          ..writeAsStringSync('');

        final Directory podsDirectory = fs.directory(
          '$_flutterAppPath/${targetPlatform.name}/Pods',
        );

        final processManager = FakeProcessManager.list([
          FakeCommand(
            command: const [
              'xcrun',
              'xcodebuild',
              '-alltargets',
              '-sdk',
              'iphoneos',
              '-configuration',
              'Debug',
              'SYMROOT=$iphoneosDirPath',
              'ONLY_ACTIVE_ARCH=NO',
              'BUILD_LIBRARY_FOR_DISTRIBUTION=YES',
            ],
            onRun: (command) {
              fs.file(iphoneosRegistrantPath).createSync(recursive: true);
            },
            workingDirectory: podsDirectory.path,
          ),
          FakeCommand(
            command: const [
              'xcrun',
              'xcodebuild',
              '-alltargets',
              '-sdk',
              'iphonesimulator',
              '-configuration',
              'Debug',
              'SYMROOT=$simulatorDirPath',
              'ONLY_ACTIVE_ARCH=NO',
              'BUILD_LIBRARY_FOR_DISTRIBUTION=YES',
            ],
            onRun: (command) {
              const simulatorRegistrantPath =
                  '$simulatorDirPath/Debug-iphonesimulator/FlutterPluginRegistrant/FlutterPluginRegistrant.framework';
              fs.file(simulatorRegistrantPath).createSync(recursive: true);
            },
            workingDirectory: podsDirectory.path,
          ),
        ]);

        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterRoot: _flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: fs.directory(_flutterAppPath), isModule: true),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final cocoapodDependencies = CocoaPodPluginDependenciesSkipPodProcessing(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final pluginSwiftDependencies = FlutterPluginSwiftDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );

        await cocoapodDependencies.generateArtifacts(
          buildInfo: BuildInfo.debug,
          cacheDirectory: fs.directory(cacheDirectoryPath),
          xcframeworkOutput: xcframeworkOutput,
          buildStatic: false,
          codesignIdentity: null,
          codesignIdentityFile: identityFile,
          pluginSwiftDependencies: pluginSwiftDependencies,
        );

        expect(processManager, hasNoRemainingExpectations);
      });

      testWithoutContext('generateArtifacts module skips SwiftPM plugin', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        const FlutterDarwinPlatform targetPlatform = .ios;
        fs.directory('$_flutterAppPath/${targetPlatform.name}/Pods').createSync(recursive: true);
        _createPodFingerprintFiles(fs: fs, platformName: targetPlatform.name);
        final Directory xcframeworkOutput = fs.directory(debugFrameworksDirectoryPath);
        const iphoneosDirPath = '$debugCocoapodCache/iphoneos';
        const simulatorDirPath = '$debugCocoapodCache/iphonesimulator';
        const iphoneosPluginPath =
            '$iphoneosDirPath/Debug-iphoneos/swiftpm_plugin/swiftpm_plugin.framework';
        final File identityFile = fs.file(codesignIdentityFile);
        identityFile
          ..createSync(recursive: true)
          ..writeAsStringSync('');

        final Directory podsDirectory = fs.directory(
          '$_flutterAppPath/${targetPlatform.name}/Pods',
        );

        final processManager = FakeProcessManager.list([
          FakeCommand(
            command: const [
              'xcrun',
              'xcodebuild',
              '-alltargets',
              '-sdk',
              'iphoneos',
              '-configuration',
              'Debug',
              'SYMROOT=$iphoneosDirPath',
              'ONLY_ACTIVE_ARCH=NO',
              'BUILD_LIBRARY_FOR_DISTRIBUTION=YES',
            ],
            onRun: (command) {
              fs.file(iphoneosPluginPath).createSync(recursive: true);
            },
            workingDirectory: podsDirectory.path,
          ),
          FakeCommand(
            command: const [
              'xcrun',
              'xcodebuild',
              '-alltargets',
              '-sdk',
              'iphonesimulator',
              '-configuration',
              'Debug',
              'SYMROOT=$simulatorDirPath',
              'ONLY_ACTIVE_ARCH=NO',
              'BUILD_LIBRARY_FOR_DISTRIBUTION=YES',
            ],
            onRun: (command) {
              const simulatorPluginPath =
                  '$simulatorDirPath/Debug-iphonesimulator/swiftpm_plugin/swiftpm_plugin.framework';
              fs.file(simulatorPluginPath).createSync(recursive: true);
            },
            workingDirectory: podsDirectory.path,
          ),
        ]);

        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterRoot: _flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: fs.directory(_flutterAppPath), isModule: true),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final cocoapodDependencies = CocoaPodPluginDependenciesSkipPodProcessing(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final pluginSwiftDependencies = FlutterPluginSwiftDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );

        // Add the plugin to copiedPlugins so it gets skipped
        pluginSwiftDependencies.copiedPlugins.add((
          name: 'swiftpm_plugin',
          swiftPackagePath: 'some/path',
          packageMinimumSupportedPlatform: null,
        ));

        await cocoapodDependencies.generateArtifacts(
          buildInfo: BuildInfo.debug,
          cacheDirectory: fs.directory(cacheDirectoryPath),
          xcframeworkOutput: xcframeworkOutput,
          buildStatic: false,
          codesignIdentity: null,
          codesignIdentityFile: identityFile,
          pluginSwiftDependencies: pluginSwiftDependencies,
        );

        expect(processManager, hasNoRemainingExpectations);
      });

      testWithoutContext('generateArtifacts static', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        const FlutterDarwinPlatform targetPlatform = .ios;
        final Directory podsDirectory = fs.directory('$_flutterAppPath/${targetPlatform.name}/Pods')
          ..createSync(recursive: true);
        _createPodFingerprintFiles(fs: fs, platformName: targetPlatform.name);
        final Directory xcframeworkOutput = fs.directory(debugFrameworksDirectoryPath);
        const iphoneosDirPath = '$debugCocoapodCache/iphoneos';
        const iphoneosCocoapodPluginPath =
            '$iphoneosDirPath/Debug-iphoneos/cocoapod_plugin/cocoapod_plugin.framework';
        const simulatorDirPath = '$debugCocoapodCache/iphonesimulator';
        const simulatorCocoapodPluginPath =
            '$simulatorDirPath/Debug-iphonesimulator/cocoapod_plugin/cocoapod_plugin.framework';
        const cocoapodPluginXCFrameworkPath =
            '$debugCocoaPodsDirectoryPath/cocoapod_plugin.xcframework';
        final processManager = FakeProcessManager.list([
          FakeCommand(
            command: const [
              'xcrun',
              'xcodebuild',
              '-alltargets',
              '-sdk',
              'iphoneos',
              '-configuration',
              'Debug',
              'SYMROOT=$iphoneosDirPath',
              'ONLY_ACTIVE_ARCH=NO',
              'BUILD_LIBRARY_FOR_DISTRIBUTION=YES',
              'MACH_O_TYPE=staticlib',
            ],
            onRun: (command) {
              fs.directory(iphoneosCocoapodPluginPath).createSync(recursive: true);
            },
            workingDirectory: podsDirectory.path,
          ),
          FakeCommand(
            command: const [
              'xcrun',
              'xcodebuild',
              '-alltargets',
              '-sdk',
              'iphonesimulator',
              '-configuration',
              'Debug',
              'SYMROOT=$simulatorDirPath',
              'ONLY_ACTIVE_ARCH=NO',
              'BUILD_LIBRARY_FOR_DISTRIBUTION=YES',
              'MACH_O_TYPE=staticlib',
            ],
            onRun: (command) {
              fs.directory(simulatorCocoapodPluginPath).createSync(recursive: true);
            },
            workingDirectory: podsDirectory.path,
          ),
          FakeCommand(
            command: const [
              'xcrun',
              'xcodebuild',
              '-create-xcframework',
              '-framework',
              iphoneosCocoapodPluginPath,
              '-framework',
              simulatorCocoapodPluginPath,
              '-output',
              cocoapodPluginXCFrameworkPath,
            ],
            onRun: (command) {
              fs.directory(cocoapodPluginXCFrameworkPath).createSync(recursive: true);
            },
          ),
          FakeCommand(
            command: const [
              'xcrun',
              'xcodebuild',
              '-alltargets',
              '-sdk',
              'iphoneos',
              '-configuration',
              'Debug',
              'SYMROOT=$iphoneosDirPath',
              'ONLY_ACTIVE_ARCH=NO',
              'BUILD_LIBRARY_FOR_DISTRIBUTION=YES',
            ],
            onRun: (command) {
              fs.directory(iphoneosCocoapodPluginPath).createSync(recursive: true);
            },
            workingDirectory: podsDirectory.path,
          ),
          FakeCommand(
            command: const [
              'xcrun',
              'xcodebuild',
              '-alltargets',
              '-sdk',
              'iphonesimulator',
              '-configuration',
              'Debug',
              'SYMROOT=$simulatorDirPath',
              'ONLY_ACTIVE_ARCH=NO',
              'BUILD_LIBRARY_FOR_DISTRIBUTION=YES',
            ],
            onRun: (command) {
              fs.directory(simulatorCocoapodPluginPath).createSync(recursive: true);
            },
            workingDirectory: podsDirectory.path,
          ),
          FakeCommand(
            command: const [
              'xcrun',
              'xcodebuild',
              '-create-xcframework',
              '-framework',
              iphoneosCocoapodPluginPath,
              '-framework',
              simulatorCocoapodPluginPath,
              '-output',
              cocoapodPluginXCFrameworkPath,
            ],
            onRun: (command) {
              fs.directory(cocoapodPluginXCFrameworkPath).createSync(recursive: true);
            },
          ),
        ]);

        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterRoot: _flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: fs.directory(_flutterAppPath)),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final cocoapodDependencies = CocoaPodPluginDependenciesSkipPodProcessing(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final pluginSwiftDependencies = FlutterPluginSwiftDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );

        await cocoapodDependencies.generateArtifacts(
          buildInfo: BuildInfo.debug,
          cacheDirectory: fs.directory(cacheDirectoryPath),
          xcframeworkOutput: xcframeworkOutput,
          buildStatic: true,
          codesignIdentity: null,
          codesignIdentityFile: fs.file(codesignIdentityFile),
          pluginSwiftDependencies: pluginSwiftDependencies,
        );

        // Run again to verify fingerprinter does not match when static changes
        await cocoapodDependencies.generateArtifacts(
          buildInfo: BuildInfo.debug,
          cacheDirectory: fs.directory(cacheDirectoryPath),
          xcframeworkOutput: xcframeworkOutput,
          buildStatic: false,
          codesignIdentity: null,
          codesignIdentityFile: fs.file(codesignIdentityFile),
          pluginSwiftDependencies: pluginSwiftDependencies,
        );
        expect(processManager, hasNoRemainingExpectations);
      });

      testWithoutContext('generateArtifacts and codesign', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        const FlutterDarwinPlatform targetPlatform = .ios;
        final Directory podsDirectory = fs.directory('$_flutterAppPath/${targetPlatform.name}/Pods')
          ..createSync(recursive: true);
        _createPodFingerprintFiles(fs: fs, platformName: targetPlatform.name);
        final Directory xcframeworkOutput = fs.directory(debugFrameworksDirectoryPath);
        const iphoneosDirPath = '$debugCocoapodCache/iphoneos';
        const iphoneosCocoapodPluginPath =
            '$iphoneosDirPath/Debug-iphoneos/cocoapod_plugin/cocoapod_plugin.framework';
        const simulatorDirPath = '$debugCocoapodCache/iphonesimulator';
        const simulatorCocoapodPluginPath =
            '$simulatorDirPath/Debug-iphonesimulator/cocoapod_plugin/cocoapod_plugin.framework';
        const cocoapodPluginXCFrameworkPath =
            '$debugCocoaPodsDirectoryPath/cocoapod_plugin.xcframework';
        final File identityFile = fs.file(codesignIdentityFile);
        identityFile
          ..createSync(recursive: true)
          ..writeAsStringSync(codesignIdentity);
        final processManager = FakeProcessManager.list([
          FakeCommand(
            command: const [
              'xcrun',
              'xcodebuild',
              '-alltargets',
              '-sdk',
              'iphoneos',
              '-configuration',
              'Debug',
              'SYMROOT=$iphoneosDirPath',
              'ONLY_ACTIVE_ARCH=NO',
              'BUILD_LIBRARY_FOR_DISTRIBUTION=YES',
            ],
            onRun: (command) {
              fs.directory(iphoneosCocoapodPluginPath).createSync(recursive: true);
            },
            workingDirectory: podsDirectory.path,
          ),
          FakeCommand(
            command: const [
              'xcrun',
              'xcodebuild',
              '-alltargets',
              '-sdk',
              'iphonesimulator',
              '-configuration',
              'Debug',
              'SYMROOT=$simulatorDirPath',
              'ONLY_ACTIVE_ARCH=NO',
              'BUILD_LIBRARY_FOR_DISTRIBUTION=YES',
            ],
            onRun: (command) {
              fs.directory(simulatorCocoapodPluginPath).createSync(recursive: true);
            },
            workingDirectory: podsDirectory.path,
          ),
          FakeCommand(
            command: const [
              'xcrun',
              'xcodebuild',
              '-create-xcframework',
              '-framework',
              iphoneosCocoapodPluginPath,
              '-framework',
              simulatorCocoapodPluginPath,
              '-output',
              cocoapodPluginXCFrameworkPath,
            ],
            onRun: (command) {
              fs.directory(cocoapodPluginXCFrameworkPath).createSync(recursive: true);
            },
          ),
          const FakeCommand(
            command: [
              'codesign',
              '--force',
              '--sign',
              codesignIdentity,
              '--timestamp=none',
              cocoapodPluginXCFrameworkPath,
            ],
          ),
        ]);

        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterRoot: _flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: fs.directory(_flutterAppPath)),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final cocoapodDependencies = CocoaPodPluginDependenciesSkipPodProcessing(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final pluginSwiftDependencies = FlutterPluginSwiftDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );

        await cocoapodDependencies.generateArtifacts(
          buildInfo: BuildInfo.debug,
          cacheDirectory: fs.directory(cacheDirectoryPath),
          xcframeworkOutput: xcframeworkOutput,
          buildStatic: false,
          codesignIdentity: codesignIdentity,
          codesignIdentityFile: identityFile,
          pluginSwiftDependencies: pluginSwiftDependencies,
        );

        // Run again to verify fingerprinter caches
        await cocoapodDependencies.generateArtifacts(
          buildInfo: BuildInfo.debug,
          cacheDirectory: fs.directory(cacheDirectoryPath),
          xcframeworkOutput: xcframeworkOutput,
          buildStatic: false,
          codesignIdentity: codesignIdentity,
          codesignIdentityFile: identityFile,
          pluginSwiftDependencies: pluginSwiftDependencies,
        );
        expect(processManager, hasNoRemainingExpectations);
      });

      testWithoutContext('generateDependencies', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        fs
            .directory('$debugCocoaPodsDirectoryPath/cocoapod_plugin.xcframework')
            .createSync(recursive: true);
        const FlutterDarwinPlatform targetPlatform = .ios;
        final processManager = FakeProcessManager.list([]);
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterRoot: _flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: fs.directory(_flutterAppPath)),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final cocoapodDependencies = CocoaPodPluginDependenciesSkipPodProcessing(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );

        final (
          List<SwiftPackageTargetDependency> targetDependencies,
          List<SwiftPackageTarget> packageTargets,
        ) = cocoapodDependencies.generateDependencies(
          xcframeworkOutput: fs.directory(debugFrameworksDirectoryPath),
        );
        expect(targetDependencies.length, 1);
        expect(packageTargets.length, 1);
        expect(targetDependencies[0].format(), contains('.target(name: "cocoapod_plugin")'));
        expect(packageTargets[0].format(), '''
.binaryTarget(
            name: "cocoapod_plugin",
            path: "Frameworks/CocoaPods/cocoapod_plugin.xcframework"
        )''');
        expect(processManager, hasNoRemainingExpectations);
      });
    });

    group('FlutterPluginSwiftDependencies', () {
      testWithoutContext('processPlugins installs missing dependencies', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        const FlutterDarwinPlatform targetPlatform = .ios;

        final pluginA = FakePlugin(name: 'PluginA', darwinPlatform: targetPlatform);
        final pluginB = FakePlugin(
          name: 'PluginB',
          darwinPlatform: targetPlatform,
          supportsSwiftPM: false,
        );

        final Directory appDirectory = fs.directory('/path/to/my_flutter_app')
          ..createSync(recursive: true);
        fs.currentDirectory = appDirectory;

        fs.file(commandFilePath).createSync(recursive: true);
        fs
            .directory(pluginA.path)
            .childDirectory('ios')
            .childDirectory('PluginA')
            .childFile('Package.swift')
          ..createSync(recursive: true)
          ..writeAsStringSync(_pluginManifest(pluginName: 'PluginA'));

        final processManager = FakeProcessManager.list([
          const FakeCommand(
            command: ['swift', 'package', 'dump-package'],
            stdout: '''
{
  "platforms": [
    {
      "platformName": "ios",
      "version": "13.0"
    }
  ],
  "targets": [
    {
      "name": "PluginA",
      "type": "regular"
    }
  ],
  "dependencies": []
}
''',
          ),
          const FakeCommand(
            command: [
              'swift',
              'package',
              'add-dependency',
              '../FlutterFramework',
              '--type',
              'path',
            ],
          ),
          const FakeCommand(
            command: [
              'swift',
              'package',
              'add-target-dependency',
              'FlutterFramework',
              'PluginA',
              '--package',
              'FlutterFramework',
            ],
          ),
        ]);

        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(
            '/path/to/flutter/bin/cache/artifacts/engine/ios/Flutter.xcframework',
          ),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(fs, '/path/to/flutter'),
          fileSystem: fs,
          flutterRoot: '/path/to/flutter',
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: appDirectory),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );

        final pluginSwiftDependencies = FlutterPluginSwiftDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );

        final Directory cacheDir = fs.directory('output/.cache')..createSync(recursive: true);
        final Directory pluginsDir = appDirectory.childDirectory(
          'output/FlutterPluginRegistrant/Plugins',
        )..createSync(recursive: true);

        await pluginSwiftDependencies.processPlugins(
          cacheDirectory: cacheDir,
          plugins: [pluginA, pluginB],
          pluginsDirectory: pluginsDir,
        );

        expect(processManager, hasNoRemainingExpectations);
        expect(pluginSwiftDependencies.copiedPlugins.length, 1);
        expect(pluginSwiftDependencies.copiedPlugins[0].name, 'PluginA');
        expect(pluginSwiftDependencies.highestSupportedVersion.version, Version(13, 0, 0));

        final File cachedManifest = cacheDir
            .childDirectory('Manifests')
            .childDirectory('PluginA')
            .childFile('Package.swift');
        expect(cachedManifest.existsSync(), isTrue);
      });

      testWithoutContext('generateDependencies', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final processManager = FakeProcessManager.list([]);
        const FlutterDarwinPlatform targetPlatform = .ios;

        final Directory appDirectory = fs.directory('/path/to/my_flutter_app')
          ..createSync(recursive: true);
        fs.currentDirectory = appDirectory;

        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(
            '/path/to/flutter/bin/cache/artifacts/engine/ios/Flutter.xcframework',
          ),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(fs, '/path/to/flutter'),
          fileSystem: fs,
          flutterRoot: '/path/to/flutter',
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: appDirectory),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );

        final pluginSwiftDependencies = FlutterPluginSwiftDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );

        pluginSwiftDependencies.copiedPlugins.add((
          name: 'PluginA',
          swiftPackagePath: 'output/FlutterPluginRegistrant/Plugins/PluginA',
          packageMinimumSupportedPlatform: SwiftPackageSupportedPlatform(
            platform: SwiftPackagePlatform.ios,
            version: Version(13, 0, 0),
          ),
        ));

        final Directory packagesForConfiguration = fs.directory(
          'output/FlutterPluginRegistrant/Debug/Packages',
        );
        packagesForConfiguration.createSync(recursive: true);

        final (
          List<SwiftPackagePackageDependency> packageDependencies,
          List<SwiftPackageTargetDependency> targetDependencies,
        ) = pluginSwiftDependencies.generateDependencies(
          packagesForConfiguration: packagesForConfiguration,
        );

        expect(packageDependencies.length, 1);
        expect(packageDependencies[0].format(), contains('.package(name: "PluginA"'));

        expect(targetDependencies.length, 1);
        expect(
          targetDependencies[0].format(),
          contains('.product(name: "PluginA", package: "PluginA")'),
        );

        final Link symlink = packagesForConfiguration.childLink('PluginA');
        expect(symlink.existsSync(), isTrue);
        expect(symlink.targetSync(), '../../Plugins/PluginA');
      });

      testWithoutContext('processPlugins uses caching', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        const FlutterDarwinPlatform targetPlatform = .ios;

        final pluginA = FakePlugin(name: 'PluginA', darwinPlatform: targetPlatform);

        final Directory appDirectory = fs.directory('/path/to/my_flutter_app')
          ..createSync(recursive: true);
        fs.currentDirectory = appDirectory;

        fs.file(commandFilePath).createSync(recursive: true);
        fs
            .directory(pluginA.path)
            .childDirectory('ios')
            .childDirectory('PluginA')
            .childFile('Package.swift')
          ..createSync(recursive: true)
          ..writeAsStringSync(_pluginManifest(pluginName: 'PluginA'));

        final processManager = FakeProcessManager.list([
          const FakeCommand(
            command: ['swift', 'package', 'dump-package'],
            stdout: '''
{
  "platforms": [
    {
      "platformName": "ios",
      "version": "13.0"
    }
  ],
  "targets": [
    {
      "name": "PluginA",
      "type": "regular"
    }
  ],
  "dependencies": []
}
''',
          ),
          const FakeCommand(
            command: [
              'swift',
              'package',
              'add-dependency',
              '../FlutterFramework',
              '--type',
              'path',
            ],
          ),
          const FakeCommand(
            command: [
              'swift',
              'package',
              'add-target-dependency',
              'FlutterFramework',
              'PluginA',
              '--package',
              'FlutterFramework',
            ],
          ),
        ]);

        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(
            '/path/to/flutter/bin/cache/artifacts/engine/ios/Flutter.xcframework',
          ),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(fs, '/path/to/flutter'),
          fileSystem: fs,
          flutterRoot: '/path/to/flutter',
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: appDirectory),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );

        final pluginSwiftDependencies = FlutterPluginSwiftDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );

        final Directory cacheDir = fs.directory('output/.cache')..createSync(recursive: true);
        final Directory pluginsDir = appDirectory.childDirectory(
          'output/FlutterPluginRegistrant/Plugins',
        )..createSync(recursive: true);

        // First run will process normally and cache the result
        await pluginSwiftDependencies.processPlugins(
          cacheDirectory: cacheDir,
          plugins: [pluginA],
          pluginsDirectory: pluginsDir,
        );
        expect(processManager, hasNoRemainingExpectations);

        // Clear copied plugins for the second run
        pluginSwiftDependencies.copiedPlugins.clear();

        // Second run should use cache (ProcessManager has no commands left to consume)
        await pluginSwiftDependencies.processPlugins(
          cacheDirectory: cacheDir,
          plugins: [pluginA],
          pluginsDirectory: pluginsDir,
        );

        expect(processManager, hasNoRemainingExpectations);
        expect(pluginSwiftDependencies.copiedPlugins.length, 1);
        expect(pluginSwiftDependencies.copiedPlugins[0].name, 'PluginA');
        expect(pluginSwiftDependencies.highestSupportedVersion.version, Version(13, 0, 0));
        expect(logger.statusText, contains('Skipping processing plugins. No change detected.'));
      });

      testWithoutContext('processPlugins determines highest supported version', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        const FlutterDarwinPlatform targetPlatform = .ios;

        final pluginA = FakePlugin(name: 'PluginA', darwinPlatform: targetPlatform);
        final pluginC = FakePlugin(name: 'PluginC', darwinPlatform: targetPlatform);

        final Directory appDirectory = fs.directory('/path/to/my_flutter_app')
          ..createSync(recursive: true);
        fs.currentDirectory = appDirectory;

        fs.file(commandFilePath).createSync(recursive: true);
        fs
            .directory(pluginA.path)
            .childDirectory('ios')
            .childDirectory('PluginA')
            .childFile('Package.swift')
          ..createSync(recursive: true)
          ..writeAsStringSync(_pluginManifest(pluginName: 'PluginA'));

        fs
            .directory(pluginC.path)
            .childDirectory('ios')
            .childDirectory('PluginC')
            .childFile('Package.swift')
          ..createSync(recursive: true)
          ..writeAsStringSync(_pluginManifest(pluginName: 'PluginC'));

        final processManager = FakeProcessManager.list([
          const FakeCommand(
            command: ['swift', 'package', 'dump-package'],
            stdout:
                '{"platforms": [{"platformName": "ios", "version": "13.0"}], "targets": [{"name": "PluginA", "type": "regular"}], "dependencies": []}',
          ),
          const FakeCommand(
            command: [
              'swift',
              'package',
              'add-dependency',
              '../FlutterFramework',
              '--type',
              'path',
            ],
          ),
          const FakeCommand(
            command: [
              'swift',
              'package',
              'add-target-dependency',
              'FlutterFramework',
              'PluginA',
              '--package',
              'FlutterFramework',
            ],
          ),
          const FakeCommand(
            command: ['swift', 'package', 'dump-package'],
            stdout:
                '{"platforms": [{"platformName": "ios", "version": "14.0"}], "targets": [{"name": "PluginC", "type": "regular"}], "dependencies": []}',
          ),
          const FakeCommand(
            command: [
              'swift',
              'package',
              'add-dependency',
              '../FlutterFramework',
              '--type',
              'path',
            ],
          ),
          const FakeCommand(
            command: [
              'swift',
              'package',
              'add-target-dependency',
              'FlutterFramework',
              'PluginC',
              '--package',
              'FlutterFramework',
            ],
          ),
        ]);

        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(
            '/path/to/flutter/bin/cache/artifacts/engine/ios/Flutter.xcframework',
          ),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(fs, '/path/to/flutter'),
          fileSystem: fs,
          flutterRoot: '/path/to/flutter',
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: appDirectory),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );

        final pluginSwiftDependencies = FlutterPluginSwiftDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );

        final Directory cacheDir = fs.directory('output/.cache')..createSync(recursive: true);
        final Directory pluginsDir = appDirectory.childDirectory(
          'output/FlutterPluginRegistrant/Plugins',
        )..createSync(recursive: true);

        await pluginSwiftDependencies.processPlugins(
          cacheDirectory: cacheDir,
          plugins: [pluginA, pluginC],
          pluginsDirectory: pluginsDir,
        );

        expect(processManager, hasNoRemainingExpectations);
        expect(pluginSwiftDependencies.highestSupportedVersion.version, Version(14, 0, 0));
        expect(pluginSwiftDependencies.copiedPlugins.length, 2);
      });

      testWithoutContext(
        'processPlugins selects the platform version that matches the target platform when multiple platforms are defined',
        () async {
          final fs = MemoryFileSystem.test();
          final logger = BufferLogger.test();
          const FlutterDarwinPlatform targetPlatform = .ios;

          final pluginA = FakePlugin(name: 'PluginA', darwinPlatform: targetPlatform);

          final Directory appDirectory = fs.directory('/path/to/my_flutter_app')
            ..createSync(recursive: true);
          fs.currentDirectory = appDirectory;

          fs.file(commandFilePath).createSync(recursive: true);
          fs
              .directory(pluginA.path)
              .childDirectory('ios')
              .childDirectory('PluginA')
              .childFile('Package.swift')
            ..createSync(recursive: true)
            ..writeAsStringSync(_pluginManifest(pluginName: 'PluginA'));

          final processManager = FakeProcessManager.list([
            const FakeCommand(
              command: ['swift', 'package', 'dump-package'],
              stdout: '''
{
  "platforms": [
    {
      "platformName": "macos",
      "version": "14.0"
    },
    {
      "platformName": "ios",
      "version": "13.0"
    }
  ],
  "targets": [
    {
      "name": "PluginA",
      "type": "regular"
    }
  ],
  "dependencies": []
}
''',
            ),
            const FakeCommand(
              command: [
                'swift',
                'package',
                'add-dependency',
                '../FlutterFramework',
                '--type',
                'path',
              ],
            ),
            const FakeCommand(
              command: [
                'swift',
                'package',
                'add-target-dependency',
                'FlutterFramework',
                'PluginA',
                '--package',
                'FlutterFramework',
              ],
            ),
          ]);

          final testUtils = BuildSwiftPackageUtils(
            analytics: FakeAnalytics(),
            artifacts: FakeArtifacts(
              '/path/to/flutter/bin/cache/artifacts/engine/ios/Flutter.xcframework',
            ),
            buildSystem: FakeBuildSystem(),
            cache: FakeCache(fs, '/path/to/flutter'),
            fileSystem: fs,
            flutterRoot: '/path/to/flutter',
            flutterVersion: FakeFlutterVersion(),
            logger: logger,
            platform: FakePlatform(),
            processManager: processManager,
            project: FakeFlutterProject(directory: appDirectory),
            templateRenderer: const MustacheTemplateRenderer(),
            xcode: FakeXcode(),
          );

          final pluginSwiftDependencies = FlutterPluginSwiftDependencies(
            targetPlatform: targetPlatform,
            utils: testUtils,
          );

          final Directory cacheDir = fs.directory('output/.cache')..createSync(recursive: true);
          final Directory pluginsDir = appDirectory.childDirectory(
            'output/FlutterPluginRegistrant/Plugins',
          )..createSync(recursive: true);

          await pluginSwiftDependencies.processPlugins(
            cacheDirectory: cacheDir,
            plugins: [pluginA],
            pluginsDirectory: pluginsDir,
          );

          expect(processManager, hasNoRemainingExpectations);
          expect(pluginSwiftDependencies.copiedPlugins.length, 1);
          expect(pluginSwiftDependencies.copiedPlugins[0].name, 'PluginA');
          expect(pluginSwiftDependencies.highestSupportedVersion.version, Version(13, 0, 0));
        },
      );

      testWithoutContext(
        'processPlugins skips injecting Flutter dependency if already present',
        () async {
          final fs = MemoryFileSystem.test();
          final logger = BufferLogger.test();
          const FlutterDarwinPlatform targetPlatform = .ios;

          final pluginA = FakePlugin(name: 'PluginA', darwinPlatform: targetPlatform);

          final Directory appDirectory = fs.directory('/path/to/my_flutter_app')
            ..createSync(recursive: true);
          fs.currentDirectory = appDirectory;

          fs.file(commandFilePath).createSync(recursive: true);
          fs
              .directory(pluginA.path)
              .childDirectory('ios')
              .childDirectory('PluginA')
              .childFile('Package.swift')
            ..createSync(recursive: true)
            ..writeAsStringSync(_pluginManifest(pluginName: 'PluginA'));

          final processManager = FakeProcessManager.list([
            const FakeCommand(
              command: ['swift', 'package', 'dump-package'],
              stdout: '''
{
  "platforms": [
    {
      "platformName": "ios",
      "version": "13.0"
    }
  ],
  "targets": [
    {
      "name": "PluginA",
      "type": "regular"
    }
  ],
  "dependencies": [
    {
      "fileSystem": [
        {
          "identity": "flutterframework"
        }
      ]
    }
  ]
}
''',
            ),
          ]);

          final testUtils = BuildSwiftPackageUtils(
            analytics: FakeAnalytics(),
            artifacts: FakeArtifacts(
              '/path/to/flutter/bin/cache/artifacts/engine/ios/Flutter.xcframework',
            ),
            buildSystem: FakeBuildSystem(),
            cache: FakeCache(fs, '/path/to/flutter'),
            fileSystem: fs,
            flutterRoot: '/path/to/flutter',
            flutterVersion: FakeFlutterVersion(),
            logger: logger,
            platform: FakePlatform(),
            processManager: processManager,
            project: FakeFlutterProject(directory: appDirectory),
            templateRenderer: const MustacheTemplateRenderer(),
            xcode: FakeXcode(),
          );

          final pluginSwiftDependencies = FlutterPluginSwiftDependencies(
            targetPlatform: targetPlatform,
            utils: testUtils,
          );

          final Directory cacheDir = fs.directory('output/.cache')..createSync(recursive: true);
          final Directory pluginsDir = appDirectory.childDirectory(
            'output/FlutterPluginRegistrant/Plugins',
          )..createSync(recursive: true);

          await pluginSwiftDependencies.processPlugins(
            cacheDirectory: cacheDir,
            plugins: [pluginA],
            pluginsDirectory: pluginsDir,
          );

          expect(processManager, hasNoRemainingExpectations);
        },
      );
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
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterRoot: _flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: fs.directory(_flutterAppPath)),
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
        final flutterFrameworkDependency = FlutterFrameworkDependency(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final appAndNativeAssetsDependencies = AppFrameworkAndNativeAssetsDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        late final cocoapodDependencies = CocoaPodPluginDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final Directory modeDirectory = fs.directory(debugModeDirectoryPath);
        final pluginA = FakePlugin(name: 'PluginA', darwinPlatform: targetPlatform);
        pluginSwiftDependencies.copiedPlugins.add((
          name: pluginA.name,
          swiftPackagePath: '$pluginsDirectoryPath/PluginA',
          packageMinimumSupportedPlatform: SwiftPackageSupportedPlatform(
            platform: SwiftPackagePlatform.macos,
            version: Version(13, 0, 0),
          ),
        ));

        await package.generateSwiftPackage(
          modeDirectory: modeDirectory,
          plugins: [pluginA],
          xcodeBuildConfiguration: 'Debug',
          pluginSwiftDependencies: pluginSwiftDependencies,
          flutterFrameworkDependency: flutterFrameworkDependency,
          appAndNativeAssetsDependencies: appAndNativeAssetsDependencies,
          cocoapodDependencies: cocoapodDependencies,
          packagesForConfiguration: fs.directory(debugPackagesDirectoryPath),
          xcframeworkOutput: fs.directory(debugFrameworksDirectoryPath),
        );

        expect(logger.traceText, isEmpty);
        expect(processManager, hasNoRemainingExpectations);
        final File generatedPackageManifest = modeDirectory.childFile('Package.swift');
        expect(generatedPackageManifest, exists);
        expect(generatedPackageManifest.readAsStringSync(), '''
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
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
        .package(name: "FlutterFramework", path: "Packages/FlutterFramework"),
        .package(name: "PluginA", path: "Packages/PluginA")
    ],
    targets: [
        .target(
            name: "FlutterPluginRegistrant",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "PluginA", package: "PluginA"),
                .target(name: "App")
            ]
        ),
        .binaryTarget(
            name: "App",
            path: "Frameworks/App.xcframework"
        )
    ]
)
''');
        final File generatedSourceImplementation = modeDirectory
            .childDirectory('Sources')
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

public func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  PluginAPlugin.register(with: registry.registrar(forPlugin: "PluginAPlugin"))
}
''');
      });
    });

    group('AppFrameworkAndNativeAssetsDependencies', () {
      testWithoutContext('generateArtifacts', () async {
        final fs = MemoryFileSystem.test();

        final logger = BufferLogger.test();
        final Directory xcframeworkOutput = fs.directory(debugFrameworksDirectoryPath);
        final Directory cacheDirectory = fs.directory(cacheDirectoryPath);
        final Directory appDirectory = fs.directory(_flutterAppPath)..createSync(recursive: true);

        fs.currentDirectory = appDirectory;

        final Directory generatedAppFramework = cacheDirectory.childDirectory(
          'Debug/iphoneos/App.framework',
        )..createSync(recursive: true);
        generatedAppFramework.childFile('flutter_assets/NativeAssetsManifest.json')
          ..createSync(recursive: true)
          ..writeAsStringSync(
            '{"native-assets":{"ios_arm64":{"package:my_native_asset/my_native_asset.dylib":["absolute","my_native_asset.framework/my_native_asset"]}}}',
          );
        final Directory nativeAssetFramework = cacheDirectory.childDirectory(
          'Debug/iphoneos/native_assets/my_native_asset.framework',
        )..createSync(recursive: true);
        final Directory generatedAppSimulatorFramework = cacheDirectory.childDirectory(
          'Debug/iphonesimulator/App.framework',
        )..createSync(recursive: true);
        generatedAppSimulatorFramework.childFile('flutter_assets/NativeAssetsManifest.json')
          ..createSync(recursive: true)
          ..writeAsStringSync(
            '{"native-assets":{"ios_x64":{"package:my_native_asset/my_native_asset.dylib":["absolute","my_native_asset.framework/my_native_asset"]},"ios_arm64":{"package:my_native_asset/my_native_asset.dylib":["absolute","my_native_asset.framework/my_native_asset"]}}}',
          );
        final Directory nativeAssetSimulatorFramework = cacheDirectory.childDirectory(
          'Debug/iphonesimulator/native_assets/my_native_asset.framework',
        )..createSync(recursive: true);

        final processManager = FakeProcessManager.list([
          FakeCommand(
            command: [
              'xcrun',
              'xcodebuild',
              '-create-xcframework',
              '-framework',
              generatedAppFramework.path,
              '-framework',
              generatedAppSimulatorFramework.path,
              '-output',
              '$debugFrameworksDirectoryPath/App.xcframework',
            ],
          ),
          FakeCommand(
            command: [
              'xcrun',
              'xcodebuild',
              '-create-xcframework',
              '-framework',
              nativeAssetFramework.path,
              '-framework',
              nativeAssetSimulatorFramework.path,
              '-output',
              '$debugNativeAssetsDirectoryPath/my_native_asset.xcframework',
            ],
          ),
        ]);
        const FlutterDarwinPlatform targetPlatform = .ios;
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(
            expectations: [
              BuildExpectations(
                expectedTargetName: 'debug_ios_bundle_flutter_assets',
                expectedProjectDirPath: _flutterAppPath,
                expectedPackageConfigPath: '$flutterAppDartToolPath/package_config.json',
                expectedOutputDirPath: '$cacheDirectoryPath/Debug/iphoneos',
                expectedBuildDirPath: '$flutterAppBuildPath/',
                expectedCacheDirPath: flutterCachePath,
                expectedFlutterRootDirPath: _flutterRoot,
                expectedEngineVersion: _engineVersion,
                expectedDefines: <String, String>{
                  'TargetFile': 'lib/main.dart',
                  'TargetPlatform': 'ios',
                  'IosArchs': 'arm64',
                  'SdkRoot': _iosSdkRoot,
                  'BuildMode': 'debug',
                  'DartObfuscation': 'false',
                  'TrackWidgetCreation': 'true',
                  'TreeShakeIcons': 'false',
                  'BuildSwiftPackage': 'true',
                },
                expectedGenerateDartPluginRegistry: true,
              ),
              BuildExpectations(
                expectedTargetName: 'debug_ios_bundle_flutter_assets',
                expectedProjectDirPath: _flutterAppPath,
                expectedPackageConfigPath: '$flutterAppDartToolPath/package_config.json',
                expectedOutputDirPath: '$cacheDirectoryPath/Debug/iphonesimulator',
                expectedBuildDirPath: '$flutterAppBuildPath/',
                expectedCacheDirPath: flutterCachePath,
                expectedFlutterRootDirPath: _flutterRoot,
                expectedEngineVersion: _engineVersion,
                expectedDefines: <String, String>{
                  'TargetFile': 'lib/main.dart',
                  'TargetPlatform': 'ios',
                  'IosArchs': 'x86_64 arm64',
                  'SdkRoot': _iosSdkRoot,
                  'BuildMode': 'debug',
                  'DartObfuscation': 'false',
                  'TrackWidgetCreation': 'true',
                  'TreeShakeIcons': 'false',
                  'BuildSwiftPackage': 'true',
                },
                expectedGenerateDartPluginRegistry: true,
              ),
            ],
          ),
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterRoot: _flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: fs.directory(_flutterAppPath)),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final appAndNativeAssetsDependencies = AppFrameworkAndNativeAssetsDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );

        await appAndNativeAssetsDependencies.generateArtifacts(
          buildInfo: BuildInfo.debug,
          cacheDirectory: cacheDirectory,
          packageConfigPath: '$flutterAppDartToolPath/package_config.json',
          targetFile: 'lib/main.dart',
          xcframeworkOutput: xcframeworkOutput,
          codesignIdentity: null,
        );
        expect(processManager, hasNoRemainingExpectations);
        expect(logger.warningText, isEmpty);
      });

      testWithoutContext('generateDependencies', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final processManager = FakeProcessManager.list([]);
        const FlutterDarwinPlatform targetPlatform = .macos;
        fs
            .directory('$debugNativeAssetsDirectoryPath/my_native_asset.xcframework')
            .createSync(recursive: true);
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterRoot: _flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: fs.directory(_flutterAppPath)),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final appAndNativeAssetsDependencies = AppFrameworkAndNativeAssetsDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final (
          List<SwiftPackageTargetDependency> targetDependencies,
          List<SwiftPackageTarget> packageTargets,
        ) = appAndNativeAssetsDependencies.generateDependencies(
          xcframeworkOutput: fs.directory(debugFrameworksDirectoryPath),
        );
        expect(targetDependencies.length, 2);
        expect(packageTargets.length, 2);
        expect(targetDependencies[0].format(), contains('.target(name: "my_native_asset")'));
        expect(packageTargets[0].format(), '''
.binaryTarget(
            name: "my_native_asset",
            path: "Frameworks/NativeAssets/my_native_asset.xcframework"
        )''');
        expect(targetDependencies[1].format(), contains('.target(name: "App")'));
        expect(packageTargets[1].format(), '''
.binaryTarget(
            name: "App",
            path: "Frameworks/App.xcframework"
        )''');
      });

      testWithoutContext('determineTarget', () {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final processManager = FakeProcessManager.list([]);
        const FlutterDarwinPlatform targetPlatform = .macos;
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterRoot: _flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: fs.directory(_flutterAppPath)),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final appAndNativeAssetsDependencies = AppFrameworkAndNativeAssetsDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final Target macosDebugTarget = appAndNativeAssetsDependencies.determineTarget(
          targetPlatform,
          XcodeSdk.MacOSX,
          BuildInfo.debug,
        );
        final Target macosProfileTarget = appAndNativeAssetsDependencies.determineTarget(
          targetPlatform,
          XcodeSdk.MacOSX,
          BuildInfo.profile,
        );
        final Target macosReleaseTarget = appAndNativeAssetsDependencies.determineTarget(
          targetPlatform,
          XcodeSdk.MacOSX,
          BuildInfo.release,
        );

        expect(macosDebugTarget.name, 'debug_macos_bundle_flutter_assets');
        expect(macosProfileTarget.name, 'profile_macos_bundle_flutter_assets');
        expect(macosReleaseTarget.name, 'release_macos_bundle_flutter_assets');
      });
    });

    group('CocoaPodPluginDependencies', () {
      testWithoutContext('generateArtifacts', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        const FlutterDarwinPlatform targetPlatform = .macos;
        final Directory podsDirectory = fs.directory('$_flutterAppPath/${targetPlatform.name}/Pods')
          ..createSync(recursive: true);
        _createPodFingerprintFiles(fs: fs, platformName: targetPlatform.name);
        final Directory xcframeworkOutput = fs.directory(debugFrameworksDirectoryPath);
        const macosCacheDirPath = '$debugCocoapodCache/macosx';
        const cocoapodPluginPath =
            '$macosCacheDirPath/Debug/cocoapod_plugin/cocoapod_plugin.framework';
        const cocoapodPluginXCFrameworkPath =
            '$debugCocoaPodsDirectoryPath/cocoapod_plugin.xcframework';
        final File identityFile = fs.file(codesignIdentityFile);
        identityFile
          ..createSync(recursive: true)
          ..writeAsStringSync('');
        final processManager = FakeProcessManager.list([
          FakeCommand(
            command: const [
              'xcrun',
              'xcodebuild',
              '-alltargets',
              '-sdk',
              'macosx',
              '-configuration',
              'Debug',
              'SYMROOT=$macosCacheDirPath',
              'ONLY_ACTIVE_ARCH=NO',
              'BUILD_LIBRARY_FOR_DISTRIBUTION=YES',
            ],
            onRun: (command) {
              fs.directory(cocoapodPluginPath).createSync(recursive: true);
            },
            workingDirectory: podsDirectory.path,
          ),

          FakeCommand(
            command: const [
              'xcrun',
              'xcodebuild',
              '-create-xcframework',
              '-framework',
              cocoapodPluginPath,
              '-output',
              cocoapodPluginXCFrameworkPath,
            ],
            onRun: (command) {
              fs.directory(cocoapodPluginXCFrameworkPath).createSync(recursive: true);
            },
          ),
        ]);

        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterRoot: _flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: fs.directory(_flutterAppPath)),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final cocoapodDependencies = CocoaPodPluginDependenciesSkipPodProcessing(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );
        final pluginSwiftDependencies = FlutterPluginSwiftDependencies(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );

        await cocoapodDependencies.generateArtifacts(
          buildInfo: BuildInfo.debug,
          cacheDirectory: fs.directory(cacheDirectoryPath),
          xcframeworkOutput: xcframeworkOutput,
          buildStatic: false,
          codesignIdentity: null,
          codesignIdentityFile: identityFile,
          pluginSwiftDependencies: pluginSwiftDependencies,
        );

        // Run again to verify fingerprinter caches
        await cocoapodDependencies.generateArtifacts(
          buildInfo: BuildInfo.debug,
          cacheDirectory: fs.directory(cacheDirectoryPath),
          xcframeworkOutput: xcframeworkOutput,
          buildStatic: false,
          codesignIdentity: null,
          codesignIdentityFile: identityFile,
          pluginSwiftDependencies: pluginSwiftDependencies,
        );
        expect(processManager, hasNoRemainingExpectations);
      });

      testWithoutContext('generateDependencies', () async {
        final fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        fs
            .directory('$debugCocoaPodsDirectoryPath/cocoapod_plugin.xcframework')
            .createSync(recursive: true);
        const FlutterDarwinPlatform targetPlatform = .macos;
        final processManager = FakeProcessManager.list([]);
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterRoot: _flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: fs.directory(_flutterAppPath)),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );
        final cocoapodDependencies = CocoaPodPluginDependenciesSkipPodProcessing(
          targetPlatform: targetPlatform,
          utils: testUtils,
        );

        final (
          List<SwiftPackageTargetDependency> targetDependencies,
          List<SwiftPackageTarget> packageTargets,
        ) = cocoapodDependencies.generateDependencies(
          xcframeworkOutput: fs.directory(debugFrameworksDirectoryPath),
        );
        expect(targetDependencies.length, 1);
        expect(packageTargets.length, 1);
        expect(targetDependencies[0].format(), contains('.target(name: "cocoapod_plugin")'));
        expect(packageTargets[0].format(), '''
.binaryTarget(
            name: "cocoapod_plugin",
            path: "Frameworks/CocoaPods/cocoapod_plugin.xcframework"
        )''');
        expect(processManager, hasNoRemainingExpectations);
      });
    });
  });

  group('FlutterNativeIntegrationSwiftPackage', () {
    testUsingContext(
      'generateSwiftPackage without tests',
      () async {
        final FileSystem fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final processManager = FakeProcessManager.list([]);
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterRoot: _flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: fs.directory(_flutterAppPath)),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );

        // Set up templates in fs
        for (final FileSystemEntity fileEntity
            in fileSystem
                .directory(
                  '${Cache.flutterRoot}/packages/flutter_tools/templates/add_to_app/darwin',
                )
                .listSync(recursive: true)) {
          if (fileEntity is File) {
            fs.file(fileEntity.path).createSync(recursive: true);
            fs.file(fileEntity.path).writeAsStringSync(fileEntity.readAsStringSync());
          }
        }

        // Set up package_config.json for template imageDirectory
        final File packagesFile = fs.file(
          '${Cache.flutterRoot}/packages/flutter_tools/.dart_tool/package_config.json',
        )..createSync(recursive: true);
        packagesFile.writeAsStringSync(
          json.encode(<String, Object>{
            'configVersion': 2,
            'packages': <Object>[
              <String, Object>{
                'name': 'flutter_template_images',
                'rootUri':
                    'file:///path/to/.pub-cache/hosted/pub.dev/flutter_template_images-5.0.0',
                'packageUri': 'lib/',
                'languageVersion': '3.4',
              },
            ],
          }),
        );

        final Directory outputDirectory = fs.directory('output')..createSync();
        final Directory flutterIntegrationPackage = fs.directory(nativeIntegrationSwiftPackagePath)
          ..createSync();

        final integrationPackage = FlutterNativeIntegrationSwiftPackage(
          utils: testUtils,
          generateTests: false,
          targetPlatform: FlutterDarwinPlatform.ios,
        );
        await integrationPackage.generateSwiftPackages(
          outputDirectory: outputDirectory,
          flutterIntegrationPackage: flutterIntegrationPackage,
          highestSupportedVersion: FlutterDarwinPlatform.ios.supportedPackagePlatform,
        );

        expect(flutterIntegrationPackage.childFile('Package.swift'), exists);
        expect(flutterIntegrationPackage.childFile('Package.swift').readAsStringSync(), '''
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterNativeIntegration",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "FlutterNativeIntegration", targets: ["FlutterNativeIntegration"])
    ],
    dependencies: [
        .package(name: "FlutterNativeTools", path: "FlutterNativeTools"),
        .package(name: "FlutterPluginRegistrant", path: "FlutterPluginRegistrant")
    ],
    targets: [
        .target(
            name: "FlutterNativeIntegration",
            dependencies: [
                .product(name: "FlutterPluginRegistrant", package: "FlutterPluginRegistrant")
            ]
        )
    ]
)
''');

        final Directory nativeToolsPackage = flutterIntegrationPackage.childDirectory(
          'FlutterNativeTools',
        );
        expect(nativeToolsPackage.childFile('Package.swift'), exists);
        expect(nativeToolsPackage.childFile('Package.swift').readAsStringSync(), '''
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterNativeTools",
    products: [
        .plugin(name: "FlutterBuildModePlugin", targets: ["Switch to Debug Mode", "Switch to Profile Mode", "Switch to Release Mode"]),
        .executable(name: "flutter-assemble-tool", targets: ["FlutterAssembleTool"]),
        .executable(name: "flutter-prebuild-tool", targets: ["FlutterPrebuildTool"])
    ],
    dependencies: [\n        \n    ],
    targets: [
        .target(
            name: "FlutterToolHelper"
        ),
        .executableTarget(
            name: "FlutterAssembleTool",
            dependencies: [
                .target(name: "FlutterToolHelper")
            ]
        ),
        .executableTarget(
            name: "FlutterPrebuildTool",
            dependencies: [
                .target(name: "FlutterToolHelper")
            ]
        ),
        .executableTarget(
            name: "FlutterPluginTool",
            dependencies: [
                .target(name: "FlutterToolHelper")
            ]
        ),
        .plugin(
            name: "Switch to Debug Mode",
            capability: .command(
                intent: .custom(verb: "switch-to-debug", description: "Updates package to use the Debug mode Flutter framework"),
                permissions: [
                    .writeToPackageDirectory(reason: "Updates package to use the Debug mode Flutter framework"),
                ]
            ),
            dependencies: [
                .target(name: "FlutterPluginTool")
            ],
            path: "Plugins/Debug"
        ),
        .plugin(
            name: "Switch to Profile Mode",
            capability: .command(
                intent: .custom(verb: "switch-to-profile", description: "Updates package to use the Profile mode Flutter framework"),
                permissions: [
                    .writeToPackageDirectory(reason: "Updates package to use the Profile mode Flutter framework"),
                ]
            ),
            dependencies: [
                .target(name: "FlutterPluginTool")
            ],
            path: "Plugins/Profile"
        ),
        .plugin(
            name: "Switch to Release Mode",
            capability: .command(
                intent: .custom(verb: "switch-to-release", description: "Updates package to use the Release mode Flutter framework"),
                permissions: [
                    .writeToPackageDirectory(reason: "Updates package to use the Release mode Flutter framework"),
                ]
            ),
            dependencies: [
                .target(name: "FlutterPluginTool")
            ],
            path: "Plugins/Release"
        )
    ]
)
''');

        expect(
          nativeToolsPackage
              .childDirectory('Plugins')
              .childDirectory('Debug')
              .childFile('FlutterBuildModePlugin.swift')
              .readAsStringSync(),
          contains('let buildMode = "Debug"'),
        );
        expect(
          nativeToolsPackage
              .childDirectory('Plugins')
              .childDirectory('Profile')
              .childFile('FlutterBuildModePlugin.swift')
              .readAsStringSync(),
          contains('let buildMode = "Profile"'),
        );
        expect(
          nativeToolsPackage
              .childDirectory('Plugins')
              .childDirectory('Release')
              .childFile('FlutterBuildModePlugin.swift')
              .readAsStringSync(),
          contains('let buildMode = "Release"'),
        );
        expect(
          nativeToolsPackage.childDirectory('Sources').childDirectory('FlutterAssembleTool'),
          exists,
        );
        expect(
          nativeToolsPackage.childDirectory('Sources').childDirectory('FlutterPluginTool'),
          exists,
        );
        expect(
          nativeToolsPackage.childDirectory('Sources').childDirectory('FlutterToolHelper'),
          exists,
        );
        expect(
          flutterIntegrationPackage
              .childDirectory('Sources')
              .childDirectory('FlutterNativeIntegration'),
          exists,
        );
        expect(nativeToolsPackage.childDirectory('Tests'), isNot(exists));
      },
      // [intended] SwiftPM is only available on macOS and Windows fails with templating setup
      skip: !platform.isMacOS,
    );

    testUsingContext(
      'generateSwiftPackage with tests',
      () async {
        final FileSystem fs = MemoryFileSystem.test();
        final logger = BufferLogger.test();
        final processManager = FakeProcessManager.list([]);
        final testUtils = BuildSwiftPackageUtils(
          analytics: FakeAnalytics(),
          artifacts: FakeArtifacts(engineArtifactPath),
          buildSystem: FakeBuildSystem(),
          cache: FakeCache(fs, _flutterRoot),
          fileSystem: fs,
          flutterRoot: _flutterRoot,
          flutterVersion: FakeFlutterVersion(),
          logger: logger,
          platform: FakePlatform(),
          processManager: processManager,
          project: FakeFlutterProject(directory: fs.directory(_flutterAppPath)),
          templateRenderer: const MustacheTemplateRenderer(),
          xcode: FakeXcode(),
        );

        // Set up templates in fs
        for (final FileSystemEntity fileEntity
            in fileSystem
                .directory(
                  '${Cache.flutterRoot}/packages/flutter_tools/templates/add_to_app/darwin',
                )
                .listSync(recursive: true)) {
          if (fileEntity is File) {
            fs.file(fileEntity.path).createSync(recursive: true);
            fs.file(fileEntity.path).writeAsStringSync(fileEntity.readAsStringSync());
          }
        }

        // Set up package_config.json for template imageDirectory
        final File packagesFile = fs.file(
          '${Cache.flutterRoot}/packages/flutter_tools/.dart_tool/package_config.json',
        )..createSync(recursive: true);
        packagesFile.writeAsStringSync(
          json.encode(<String, Object>{
            'configVersion': 2,
            'packages': <Object>[
              <String, Object>{
                'name': 'flutter_template_images',
                'rootUri':
                    'file:///path/to/.pub-cache/hosted/pub.dev/flutter_template_images-5.0.0',
                'packageUri': 'lib/',
                'languageVersion': '3.4',
              },
            ],
          }),
        );

        final Directory outputDirectory = fs.directory('output')..createSync();
        final Directory flutterIntegrationPackage = fs.directory(nativeIntegrationSwiftPackagePath)
          ..createSync();

        final integrationPackage = FlutterNativeIntegrationSwiftPackage(
          utils: testUtils,
          generateTests: true,
          targetPlatform: FlutterDarwinPlatform.macos,
        );
        await integrationPackage.generateSwiftPackages(
          outputDirectory: outputDirectory,
          flutterIntegrationPackage: flutterIntegrationPackage,
          highestSupportedVersion: FlutterDarwinPlatform.macos.supportedPackagePlatform,
        );

        expect(flutterIntegrationPackage.childFile('Package.swift'), exists);
        expect(flutterIntegrationPackage.childFile('Package.swift').readAsStringSync(), '''
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterNativeIntegration",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "FlutterNativeIntegration", targets: ["FlutterNativeIntegration"])
    ],
    dependencies: [
        .package(name: "FlutterNativeTools", path: "FlutterNativeTools"),
        .package(name: "FlutterPluginRegistrant", path: "FlutterPluginRegistrant")
    ],
    targets: [
        .target(
            name: "FlutterNativeIntegration",
            dependencies: [
                .product(name: "FlutterPluginRegistrant", package: "FlutterPluginRegistrant")
            ]
        )
    ]
)
''');

        final Directory nativeToolsPackage = flutterIntegrationPackage.childDirectory(
          'FlutterNativeTools',
        );
        expect(nativeToolsPackage.childFile('Package.swift'), exists);
        expect(nativeToolsPackage.childFile('Package.swift').readAsStringSync(), '''
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterNativeTools",
    products: [
        .plugin(name: "FlutterBuildModePlugin", targets: ["Switch to Debug Mode", "Switch to Profile Mode", "Switch to Release Mode"]),
        .executable(name: "flutter-assemble-tool", targets: ["FlutterAssembleTool"]),
        .executable(name: "flutter-prebuild-tool", targets: ["FlutterPrebuildTool"])
    ],
    dependencies: [\n        \n    ],
    targets: [
        .target(
            name: "FlutterToolHelper"
        ),
        .executableTarget(
            name: "FlutterAssembleTool",
            dependencies: [
                .target(name: "FlutterToolHelper")
            ]
        ),
        .executableTarget(
            name: "FlutterPrebuildTool",
            dependencies: [
                .target(name: "FlutterToolHelper")
            ]
        ),
        .executableTarget(
            name: "FlutterPluginTool",
            dependencies: [
                .target(name: "FlutterToolHelper")
            ]
        ),
        .plugin(
            name: "Switch to Debug Mode",
            capability: .command(
                intent: .custom(verb: "switch-to-debug", description: "Updates package to use the Debug mode Flutter framework"),
                permissions: [
                    .writeToPackageDirectory(reason: "Updates package to use the Debug mode Flutter framework"),
                ]
            ),
            dependencies: [
                .target(name: "FlutterPluginTool")
            ],
            path: "Plugins/Debug"
        ),
        .plugin(
            name: "Switch to Profile Mode",
            capability: .command(
                intent: .custom(verb: "switch-to-profile", description: "Updates package to use the Profile mode Flutter framework"),
                permissions: [
                    .writeToPackageDirectory(reason: "Updates package to use the Profile mode Flutter framework"),
                ]
            ),
            dependencies: [
                .target(name: "FlutterPluginTool")
            ],
            path: "Plugins/Profile"
        ),
        .plugin(
            name: "Switch to Release Mode",
            capability: .command(
                intent: .custom(verb: "switch-to-release", description: "Updates package to use the Release mode Flutter framework"),
                permissions: [
                    .writeToPackageDirectory(reason: "Updates package to use the Release mode Flutter framework"),
                ]
            ),
            dependencies: [
                .target(name: "FlutterPluginTool")
            ],
            path: "Plugins/Release"
        ),
        .testTarget(
            name: "FlutterToolTests",
            dependencies: [
                .target(name: "FlutterPluginTool"),
                .target(name: "FlutterToolHelper"),
                .target(name: "FlutterAssembleTool")
            ]
        )
    ]
)
''');

        expect(
          nativeToolsPackage
              .childDirectory('Plugins')
              .childDirectory('Debug')
              .childFile('FlutterBuildModePlugin.swift')
              .readAsStringSync(),
          contains('let buildMode = "Debug"'),
        );
        expect(
          nativeToolsPackage
              .childDirectory('Plugins')
              .childDirectory('Profile')
              .childFile('FlutterBuildModePlugin.swift')
              .readAsStringSync(),
          contains('let buildMode = "Profile"'),
        );
        expect(
          nativeToolsPackage
              .childDirectory('Plugins')
              .childDirectory('Release')
              .childFile('FlutterBuildModePlugin.swift')
              .readAsStringSync(),
          contains('let buildMode = "Release"'),
        );
        expect(
          nativeToolsPackage.childDirectory('Sources').childDirectory('FlutterAssembleTool'),
          exists,
        );
        expect(
          nativeToolsPackage.childDirectory('Sources').childDirectory('FlutterPluginTool'),
          exists,
        );
        expect(
          nativeToolsPackage.childDirectory('Sources').childDirectory('FlutterToolHelper'),
          exists,
        );
        expect(
          flutterIntegrationPackage
              .childDirectory('Sources')
              .childDirectory('FlutterNativeIntegration'),
          exists,
        );
        expect(nativeToolsPackage.childDirectory('Tests'), exists);
      },
      // [intended] SwiftPM is only available on macOS and Windows fails with templating setup
      skip: !platform.isMacOS,
    );
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

/// Creates Pod directory, Podfile, Podfile.lock, and Manifest.lock. Returns the Pods directory.
void _createPodFingerprintFiles({required FileSystem fs, required String platformName}) {
  fs.file('$_flutterAppPath/$platformName/Podfile').createSync(recursive: true);
  fs.file('$_flutterAppPath/$platformName/Podfile.lock').createSync(recursive: true);
  fs.file('$_flutterAppPath/$platformName/Pods/Manifest.lock').createSync(recursive: true);
  fs.file('$_flutterRoot/packages/flutter_tools/bin/podhelper.rb').createSync(recursive: true);
  fs
      .file('$_flutterRoot/packages/flutter_tools/lib/src/commands/build_swift_package.dart')
      .createSync(recursive: true);
  fs
      .file('$_flutterAppPath/$platformName/Runner.xcodeproj/project.pbxproj')
      .createSync(recursive: true);
}

class FakeAnalytics extends Fake implements Analytics {}

class FakeXcode extends Fake implements Xcode {
  @override
  Version get currentVersion => Version(15, 0, 0);

  @override
  Future<String> sdkLocation(EnvironmentType environmentType) async {
    return _iosSdkRoot;
  }

  @override
  List<String> xcrunCommand() => ['xcrun'];
}

class FakeFlutterVersion extends Fake implements FlutterVersion {
  @override
  String get engineRevision => _engineVersion;
}

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

  @override
  LocalEngineInfo? get localEngineInfo => null;

  @override
  bool get usesLocalArtifacts => false;
}

class BuildExpectations {
  BuildExpectations({
    this.expectedTargetName,
    this.expectedProjectDirPath,
    this.expectedPackageConfigPath,
    this.expectedOutputDirPath,
    this.expectedBuildDirPath,
    this.expectedCacheDirPath,
    this.expectedFlutterRootDirPath,
    this.expectedEngineVersion,
    this.expectedDefines,
    this.expectedGenerateDartPluginRegistry,
  });
  String? expectedTargetName;
  String? expectedProjectDirPath;
  String? expectedPackageConfigPath;
  String? expectedOutputDirPath;
  String? expectedBuildDirPath;
  String? expectedCacheDirPath;
  String? expectedFlutterRootDirPath;
  String? expectedEngineVersion;
  Map<String, String>? expectedDefines;
  bool? expectedGenerateDartPluginRegistry;

  void expectationsMatch(Target target, Environment environment) {
    expect(target.name, expectedTargetName);
    expect(environment.projectDir.path, expectedProjectDirPath);
    expect(environment.packageConfigPath, expectedPackageConfigPath);
    expect(environment.outputDir.path, expectedOutputDirPath);
    expect(environment.buildDir.path, startsWith(expectedBuildDirPath ?? ''));
    expect(environment.cacheDir.path, expectedCacheDirPath);
    expect(environment.flutterRootDir.path, expectedFlutterRootDirPath);
    expect(environment.defines, expectedDefines);
    expect(environment.engineVersion, expectedEngineVersion);
    expect(environment.generateDartPluginRegistry, expectedGenerateDartPluginRegistry);
  }
}

class FakeBuildSystem extends Fake implements BuildSystem {
  FakeBuildSystem({this.expectations = const []});

  List<BuildExpectations> expectations;

  @override
  Future<BuildResult> build(
    Target target,
    Environment environment, {
    BuildSystemConfig buildSystemConfig = const BuildSystemConfig(),
  }) async {
    if (expectations.isNotEmpty) {
      expectations.first.expectationsMatch(target, environment);
      expectations.removeAt(0);
    }

    return BuildResult(success: true);
  }
}

class FakeCache extends Fake implements Cache {
  FakeCache(this._fileSystem, this.flutterRoot);

  final FileSystem _fileSystem;
  final String flutterRoot;

  @override
  Directory getRoot() {
    return _fileSystem.directory(_fileSystem.path.join(flutterRoot, 'bin', 'cache'));
  }

  @override
  Future<void> lock() async {}

  @override
  Future<void> updateAll(Set<DevelopmentArtifact> artifacts, {bool offline = false}) async {}

  @override
  void releaseLock() {}
}

class FakeFlutterProject extends Fake implements FlutterProject {
  FakeFlutterProject({required this.directory, this.isModule = false});

  @override
  final Directory directory;

  @override
  final bool isModule;

  @override
  Directory get dartTool => directory.childDirectory('.dart_tool');

  @override
  late final ios = FakeIosProject(directory: directory);

  @override
  late final macos = FakeMacosProject(directory: directory);
}

class FakeIosProject extends Fake implements IosProject {
  FakeIosProject({required this.directory});

  final Directory directory;

  @override
  Directory get hostAppRoot {
    return directory.childDirectory('ios');
  }

  @override
  File get podfile => hostAppRoot.childFile('Podfile');

  @override
  File get podfileLock => hostAppRoot.childFile('Podfile.lock');

  @override
  File get podManifestLock => hostAppRoot.childDirectory('Pods').childFile('Manifest.lock');

  @override
  Directory get xcodeProject => hostAppRoot.childDirectory('Runner.xcodeproj');

  @override
  File get xcodeProjectInfoFile => xcodeProject.childFile('project.pbxproj');

  @override
  File get flutterPluginSwiftPackageManifest => hostAppRoot.childFile(
    'Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift',
  );

  @override
  File get lldbInitFile => hostAppRoot.childFile('Flutter/ephemeral/flutter_lldbinit');

  @override
  File get lldbHelperPythonFile =>
      hostAppRoot.childFile('Flutter/ephemeral/flutter_lldb_helper.py');
}

class FakeMacosProject extends Fake implements MacOSProject {
  FakeMacosProject({required this.directory});

  final Directory directory;

  @override
  Directory get hostAppRoot {
    return directory.childDirectory('macos');
  }

  @override
  File get podfile => hostAppRoot.childFile('Podfile');

  @override
  File get podfileLock => hostAppRoot.childFile('Podfile.lock');

  @override
  File get podManifestLock => hostAppRoot.childDirectory('Pods').childFile('Manifest.lock');

  @override
  Directory get xcodeProject => hostAppRoot.childDirectory('Runner.xcodeproj');

  @override
  File get xcodeProjectInfoFile => xcodeProject.childFile('project.pbxproj');

  @override
  File get flutterPluginSwiftPackageManifest => hostAppRoot.childFile(
    'Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift',
  );
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
    return fileSystem.path.join(overridePath ?? path, platform, name);
  }

  @override
  bool supportSwiftPackageManagerForPlatform(FileSystem fileSystem, String platform) {
    return supportsSwiftPM;
  }
}

class FakeFeatureFlags extends Fake implements FeatureFlags {
  @override
  bool get isSwiftPackageManagerEnabled => true;
}

class CocoaPodPluginDependenciesSkipPodProcessing extends CocoaPodPluginDependencies {
  CocoaPodPluginDependenciesSkipPodProcessing({
    required super.targetPlatform,
    required super.utils,
  });

  @override
  Future<void> processPods(XcodeBasedProject xcodeProject, BuildInfo buildInfo) async {}
}

class FakeDarwinAddToAppCodesigning extends Fake implements DarwinAddToAppCodesigning {}
