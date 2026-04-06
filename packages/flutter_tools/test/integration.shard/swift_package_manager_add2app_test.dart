// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/darwin/darwin.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';

import '../src/common.dart';
import 'swift_package_manager_utils.dart';
import 'test_utils.dart';

const nativeAssetName = 'native_add';
const migratedSwiftPackagePluginName = 'migrated_spm_plugin';
const partialSwiftPackagePluginName = 'partial_spm_plugin';
const cocoaPodsPluginName = 'cocoapods_plugin';
const appName = 'my_flutter_app';

void main() {
  final platforms = <FlutterDarwinPlatform>[.ios, .macos];
  for (final targetPlatform in platforms) {
    test(
      'Generate and embed Flutter app in native ${targetPlatform.name} app using SwiftPM',
      () async {
        final Directory workingDirectory = fileSystem.systemTempDirectory.createTempSync(
          'swift_package_manager_add2app_test_${targetPlatform.name}.',
        )..createSync(recursive: true);
        final String workingDirectoryPath = workingDirectory.path;
        try {
          // Create an app
          final String appDirectoryPath = await SwiftPackageManagerUtils.createApp(
            flutterBin,
            workingDirectoryPath,
            platform: targetPlatform.name,
            options: <String>['--platforms=${targetPlatform.name}'],
            name: appName,
          );
          await _addPlugins(
            platform: targetPlatform.name,
            workingDirectoryPath: workingDirectoryPath,
            appDirectoryPath: appDirectoryPath,
          );

          // Build Swift package
          final String firstBuildOutput = await _buildFlutterSwiftPackage(
            buildModes: 'debug',
            targetPlatform: targetPlatform,
            appDirectoryPath: appDirectoryPath,
            includeTests: true,
          );
          final firstExpectedLogs = [
            'Processing plugins...',
            'Using code-signing identity: -',
            'Building for Debug...',
            '   ├─Copying ${targetPlatform.binaryName}.xcframework...',
            '   ├─Building App.xcframework and native assets...',
            '   ├─Building CocoaPod frameworks...',
            '   ├─Generating swift packages...',
          ];
          for (final expectedLog in firstExpectedLogs) {
            expect(firstBuildOutput, contains(expectedLog), reason: firstBuildOutput);
          }

          // Verify file structure
          final Directory appDir = fileSystem.directory(appDirectoryPath);
          final Directory buildDir = appDir
              .childDirectory('build')
              .childDirectory(targetPlatform.name)
              .childDirectory('SwiftPackages');
          _verifyModeAgnosticFiles(
            buildDir: buildDir,
            platform: targetPlatform.name,
            includeTests: true,
          );
          _verifyFilesForBuildMode(
            buildDir: buildDir,
            buildMode: 'Debug',
            platform: targetPlatform,
          );
          await _verifyCodeSigning(
            buildDir: buildDir,
            buildMode: 'Debug',
            platform: targetPlatform,
          );
          final Link pluginRegistrantLink = buildDir.childLink(
            'FlutterNativeIntegration/FlutterPluginRegistrant',
          );
          expect(pluginRegistrantLink.existsSync(), true);
          expect(pluginRegistrantLink.targetSync(), './Debug');

          // Verify and run Swift package tools and plugins tests
          final Directory toolsPackage = buildDir
              .childDirectory('FlutterNativeIntegration')
              .childDirectory('FlutterNativeTools');
          expect(toolsPackage.childFile('Package.swift').existsSync(), true);
          expect(toolsPackage.childDirectory('Tests').existsSync(), true);
          final ProcessResult swiftTestResult = await processManager.run(<String>[
            'swift',
            'test',
            '-Xswiftc',
            '-warnings-as-errors',
          ], workingDirectory: toolsPackage.path);
          expect(
            swiftTestResult.exitCode,
            0,
            reason: 'stdout: ${swiftTestResult.stdout}\nstderr: ${swiftTestResult.stderr}',
          );

          // Test caching
          final String secondBuildOutput = await _buildFlutterSwiftPackage(
            appDirectoryPath: appDirectoryPath,
            buildModes: 'debug,profile,release',
            targetPlatform: targetPlatform,
          );
          final secondExpectedLogs = [
            'Processing plugins...',
            '   │   └── Skipping processing plugins. No change detected.',
            'Using code-signing identity: -',
            'Building for Debug...',
            '   ├─Copying ${targetPlatform.binaryName}.xcframework...',
            '   ├─Building App.xcframework and native assets...',
            '   ├─Building CocoaPod frameworks...',
            '   │   └── Skipping building CocoaPod plugins. No change detected.',
            '   ├─Generating swift packages...',
            'Building for Profile...',
            '   ├─Copying ${targetPlatform.binaryName}.xcframework...',
            '   ├─Building App.xcframework and native assets...',
            '   ├─Building CocoaPod frameworks...',
            '   ├─Generating swift packages...',
            'Building for Release...',
            '   ├─Copying ${targetPlatform.binaryName}.xcframework...',
            '   ├─Building App.xcframework and native assets...',
            '   ├─Building CocoaPod frameworks...',
            '   ├─Generating swift packages...',
          ];
          for (final expectedLog in secondExpectedLogs) {
            expect(secondBuildOutput, contains(expectedLog), reason: secondBuildOutput);
          }
          _verifyModeAgnosticFiles(
            buildDir: buildDir,
            platform: targetPlatform.name,
            includeTests: false,
          );
          _verifyFilesForBuildMode(
            buildDir: buildDir,
            buildMode: 'Debug',
            platform: targetPlatform,
          );
          _verifyFilesForBuildMode(
            buildDir: buildDir,
            buildMode: 'Profile',
            platform: targetPlatform,
          );
          _verifyFilesForBuildMode(
            buildDir: buildDir,
            buildMode: 'Release',
            platform: targetPlatform,
          );
          expect(pluginRegistrantLink.targetSync(), './Debug');

          // Test integration
          final String flutterRoot = getFlutterRoot();
          final nativeProjectName = targetPlatform == .macos
              ? 'MacOSNativeProject'
              : 'iOSNativeProject';
          final Directory nativeProjectTemplate = fileSystem.directory(
            fileSystem.path.join(
              flutterRoot,
              'dev',
              'integration_tests',
              'darwin_add2app_swiftpm',
              nativeProjectName,
            ),
          );
          final XcodeSdk sdk = targetPlatform == .macos ? XcodeSdk.MacOSX : XcodeSdk.IPhoneOS;
          final Directory nativeProject = workingDirectory.childDirectory(nativeProjectName);
          copyDirectory(nativeProjectTemplate, nativeProject);
          final Directory nativeBuildDir = nativeProject.childDirectory('build');

          // CI code-signing is not set up for macOS.
          final codesign = targetPlatform == .ios;

          // When sandboxing is disabled and the application path is set, we use "flutter assemble"
          // to rebuild the App.framework and copy in the correct Flutter framework.
          await _buildNativeProject(
            nativeProjectPath: nativeProject.path,
            nativeProjectName: nativeProjectName,
            buildDir: nativeBuildDir.path,
            buildMode: 'Release',
            sdk: sdk,
            platform: targetPlatform,
            buildSettings: [
              r'ENABLE_USER_SCRIPT_SANDBOXING=NO',
              'FLUTTER_APPLICATION_PATH=\$SRCROOT/../$appName',
            ],
            codesign: codesign,
            expectedOutput: [
              "Build of product 'flutter-prebuild-tool' complete!",
              'FlutterPluginRegistrant symlink updated to ./Release',
              "Build of product 'flutter-assemble-tool' complete!",
              'flutter --verbose assemble',
              'release_unpack_${targetPlatform.name.toLowerCase()}: Starting',
            ],
          );
          expect(pluginRegistrantLink.targetSync(), './Release');

          // When sandboxing is disabled and the application path is not set, the swift package
          // copies in the correct Flutter framework.
          await _buildNativeProject(
            nativeProjectPath: nativeProject.path,
            nativeProjectName: nativeProjectName,
            buildDir: nativeBuildDir.path,
            buildMode: 'Debug',
            sdk: sdk,
            platform: targetPlatform,
            buildSettings: [r'ENABLE_USER_SCRIPT_SANDBOXING=NO'],
            codesign: codesign,
            expectedOutput: [
              'FlutterPluginRegistrant symlink updated to ./Debug',
              'Verification complete.',
            ],
            unexpectedOutput: [
              "Build of product 'flutter-prebuild-tool' complete!",
              "Build of product 'flutter-assemble-tool' complete!",
              'flutter --verbose assemble',
              'note: Transfer starting',
            ],
          );
          expect(pluginRegistrantLink.targetSync(), './Debug');

          // When sandboxing is enabled, it will throw if build mode is incorrect
          await _buildNativeProject(
            nativeProjectPath: nativeProject.path,
            nativeProjectName: nativeProjectName,
            buildDir: nativeBuildDir.path,
            buildMode: 'Release',
            sdk: sdk,
            platform: targetPlatform,
            buildSettings: [
              r'ENABLE_USER_SCRIPT_SANDBOXING=YES',
              'FLUTTER_APPLICATION_PATH=\$SRCROOT/../$appName',
            ],
            codesign: codesign,
            expectedOutput: [
              'FlutterPluginRegistrant symlink updated to ./Release',
              'Verification complete.',
              'warning: ENABLE_USER_SCRIPT_SANDBOXING is enabled. Flutter is unable to rebuild the Flutter app when sandboxing is enabled.',
              'warning: To rebuild the Flutter app as part of the Xcode build, please set ENABLE_USER_SCRIPT_SANDBOXING=NO in your build settings.',
              'warning: Otherwise, to build any changes to your Flutter app, you will need to re-run "flutter build swift-package" from within your Flutter application.',
              'warning: Alternatively, you can remove FLUTTER_APPLICATION_PATH from your build settings to dismiss this warning.',
            ],
            unexpectedOutput: [
              "Build of product 'flutter-prebuild-tool' complete!",
              "Build of product 'flutter-assemble-tool' complete!",
              'flutter --verbose assemble',
              'note: Transfer starting',
            ],
          );
          expect(pluginRegistrantLink.targetSync(), './Release');

          // When sandboxing is enabled, and build mode is correct, it will run
          await _buildNativeProject(
            nativeProjectPath: nativeProject.path,
            nativeProjectName: nativeProjectName,
            buildDir: nativeBuildDir.path,
            buildMode: 'Release',
            sdk: sdk,
            platform: targetPlatform,
            buildSettings: [r'ENABLE_USER_SCRIPT_SANDBOXING=YES'],
            codesign: codesign,
            expectedOutput: ['Verification complete.'],
            unexpectedOutput: [
              'FlutterPluginRegistrant symlink updated to ./Release',
              "Build of product 'flutter-prebuild-tool' complete!",
              "Build of product 'flutter-assemble-tool' complete!",
              'flutter --verbose assemble',
              'note: Transfer starting',
            ],
          );
          expect(pluginRegistrantLink.targetSync(), './Release');

          // Test switching build mode via plugin
          final ProcessResult pluginResult = await processManager.run(<String>[
            'swift',
            'package',
            'plugin',
            '--allow-writing-to-package-directory',
            'switch-to-profile',
          ], workingDirectory: buildDir.childDirectory('FlutterNativeIntegration').path);
          expect(pluginResult.exitCode, 0, reason: pluginResult.stderr.toString());
          expect(pluginRegistrantLink.targetSync(), './Profile');
        } finally {
          ErrorHandlingFileSystem.deleteIfExists(workingDirectory, recursive: true);
        }
      },
      skip: !platform.isMacOS, // [intended] Swift Package Manager only works on macos.
    );
  }

  test(
    'Generate and embed Flutter module in native iOS app using SwiftPM',
    () async {
      const FlutterDarwinPlatform targetPlatform = .ios;
      final Directory workingDirectory = fileSystem.systemTempDirectory.createTempSync(
        'swift_package_manager_add2app_test_ios_module.',
      )..createSync(recursive: true);
      final String workingDirectoryPath = workingDirectory.path;
      try {
        // Create an app
        final String appDirectoryPath = await SwiftPackageManagerUtils.createApp(
          flutterBin,
          workingDirectoryPath,
          platform: targetPlatform.name,
          options: <String>['--template=module'],
          name: appName,
        );
        await _addPlugins(
          platform: targetPlatform.name,
          workingDirectoryPath: workingDirectoryPath,
          appDirectoryPath: appDirectoryPath,
        );

        // Build Swift package
        final String firstBuildOutput = await _buildFlutterSwiftPackage(
          buildModes: 'debug,release',
          targetPlatform: targetPlatform,
          appDirectoryPath: appDirectoryPath,
          includeTests: true,
        );
        final firstExpectedLogs = [
          'Processing plugins...',
          'Using code-signing identity: -',
          'Building for Debug...',
          '   ├─Copying Flutter.xcframework...',
          '   ├─Building App.xcframework and native assets...',
          '   ├─Building CocoaPod frameworks...',
          '   ├─Generating swift packages...',
          'Building for Release...',
          '   ├─Copying Flutter.xcframework...',
          '   ├─Building App.xcframework and native assets...',
          '   ├─Building CocoaPod frameworks...',
          '   ├─Generating swift packages...',
        ];
        for (final expectedLog in firstExpectedLogs) {
          expect(firstBuildOutput, contains(expectedLog), reason: firstBuildOutput);
        }

        // Verify file structure
        final Directory appDir = fileSystem.directory(appDirectoryPath);
        final Directory buildDir = appDir
            .childDirectory('build')
            .childDirectory(targetPlatform.name)
            .childDirectory('SwiftPackages');
        _verifyModeAgnosticFiles(
          buildDir: buildDir,
          platform: targetPlatform.name,
          includeTests: true,
        );
        _verifyFilesForBuildMode(buildDir: buildDir, buildMode: 'Debug', platform: targetPlatform);
        await _verifyCodeSigning(buildDir: buildDir, buildMode: 'Debug', platform: targetPlatform);
        final Link pluginRegistrantLink = buildDir.childLink(
          'FlutterNativeIntegration/FlutterPluginRegistrant',
        );
        expect(pluginRegistrantLink.existsSync(), true);
        expect(pluginRegistrantLink.targetSync(), './Debug');

        // Test integration
        final String flutterRoot = getFlutterRoot();
        const nativeProjectName = 'iOSNativeProject';
        final Directory nativeProjectTemplate = fileSystem.directory(
          fileSystem.path.join(
            flutterRoot,
            'dev',
            'integration_tests',
            'darwin_add2app_swiftpm',
            nativeProjectName,
          ),
        );
        const XcodeSdk sdk = XcodeSdk.IPhoneOS;
        final Directory nativeProject = workingDirectory.childDirectory(nativeProjectName);
        copyDirectory(nativeProjectTemplate, nativeProject);
        final Directory nativeBuildDir = nativeProject.childDirectory('build');

        // When sandboxing is disabled and the application path is set, we use "flutter assemble"
        // to rebuild the App.framework and copy in the correct Flutter framework.
        await _buildNativeProject(
          nativeProjectPath: nativeProject.path,
          nativeProjectName: nativeProjectName,
          buildDir: nativeBuildDir.path,
          buildMode: 'Release',
          sdk: sdk,
          platform: targetPlatform,
          codesign: true,
          buildSettings: [
            r'ENABLE_USER_SCRIPT_SANDBOXING=NO',
            'FLUTTER_APPLICATION_PATH=\$SRCROOT/../$appName',
          ],
          expectedOutput: [
            "Build of product 'flutter-assemble-tool' complete!",
            'FlutterPluginRegistrant symlink updated to ./Release',
            'flutter --verbose assemble',
            'release_unpack_${targetPlatform.name.toLowerCase()}: Starting',
          ],
        );
        expect(pluginRegistrantLink.targetSync(), './Release');
      } finally {
        ErrorHandlingFileSystem.deleteIfExists(workingDirectory, recursive: true);
      }
    },
    skip: !platform.isMacOS, // [intended] Swift Package Manager only works on macos.
  );
}

Future<String> _buildFlutterSwiftPackage({
  required String appDirectoryPath,
  required String buildModes,
  required FlutterDarwinPlatform targetPlatform,
  int expectedExitCode = 0,
  bool includeTests = false,
}) async {
  final ProcessResult result = await processManager.run(<String>[
    flutterBin,
    ...getLocalEngineArguments(),
    'build',
    'swift-package',
    '--codesign-identity',
    '-',
    if (includeTests) '--ci',
    '--platform=${targetPlatform.name}',
    '--build-mode',
    buildModes,
  ], workingDirectory: appDirectoryPath);
  expect(
    result.exitCode,
    expectedExitCode,
    reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}',
  );
  return result.stdout.toString();
}

Future<String> _buildNativeProject({
  required String nativeProjectPath,
  required String nativeProjectName,
  required String buildDir,
  required String buildMode,
  required XcodeSdk sdk,
  required FlutterDarwinPlatform platform,
  required List<String> buildSettings,
  bool expectFailure = false,
  List<String> expectedOutput = const [],
  List<String> unexpectedOutput = const [],
  required bool codesign,
}) async {
  final Map<String, String> environment = Platform.environment;
  final List<String> codesignArguments;
  if (codesign) {
    final String developmentTeam = environment['FLUTTER_XCODE_DEVELOPMENT_TEAM'] ?? 'S8QB4VV633';
    final String? codeSignStyle = environment['FLUTTER_XCODE_CODE_SIGN_STYLE'];
    final String? provisioningProfile = environment['FLUTTER_XCODE_PROVISIONING_PROFILE_SPECIFIER'];
    codesignArguments = [
      'DEVELOPMENT_TEAM=$developmentTeam',
      if (codeSignStyle != null) 'CODE_SIGN_STYLE=$codeSignStyle',
      if (provisioningProfile != null) 'PROVISIONING_PROFILE_SPECIFIER=$provisioningProfile',
    ];
  } else {
    codesignArguments = [
      'CODE_SIGNING_ALLOWED=NO',
      'CODE_SIGNING_REQUIRED=NO',
      'CODE_SIGNING_IDENTITY=""',
    ];
  }

  final ProcessResult result = await processManager.run(<String>[
    'xcrun',
    'xcodebuild',
    '-project',
    '$nativeProjectName.xcodeproj',
    '-scheme',
    nativeProjectName,
    '-configuration',
    buildMode,
    '-sdk',
    sdk.platformName,
    '-destination',
    sdk.genericPlatform,
    'build',
    'BUILD_DIR=$buildDir',
    ...codesignArguments,
    'FLUTTER_SWIFT_PACKAGE_OUTPUT=\$SRCROOT/../$appName/build/${platform.name}/SwiftPackages',
    r'VERBOSE_SCRIPT_LOGGING=YES',
    ...buildSettings,
  ], workingDirectory: nativeProjectPath);

  final output = 'stdout: ${result.stdout}\nstderr: ${result.stderr}';
  expect(result.exitCode, expectFailure ? isNot(0) : 0, reason: output);
  for (final expectedLog in expectedOutput) {
    expect(output, contains(expectedLog), reason: output);
  }
  for (final unexpectedLog in unexpectedOutput) {
    expect(output, isNot(contains(unexpectedLog)), reason: output);
  }
  if (!expectFailure) {
    final modeDirName = platform == FlutterDarwinPlatform.macos
        ? buildMode
        : '$buildMode-${sdk.platformName}';
    final plistPath = platform == FlutterDarwinPlatform.macos
        ? 'Contents/Frameworks/${platform.binaryName}.framework/Resources/Info.plist'
        : 'Frameworks/${platform.binaryName}.framework/Info.plist';
    expect(
      fileSystem
          .directory(buildDir)
          .childDirectory(modeDirName)
          .childDirectory('$nativeProjectName.app')
          .childFile(plistPath)
          .readAsStringSync(),
      contains('<string>${buildMode.toLowerCase()}</string>'),
    );
  }
  return output;
}

/// Create a SwiftPM plugin, a SwiftPM plugin without a dependency on the FlutterFramework, a
/// CocoaPods plugin, and a native asset and adds them as a dependency to the app.
Future<void> _addPlugins({
  required String platform,
  required String workingDirectoryPath,
  required String appDirectoryPath,
}) async {
  // Create a SwiftPM plugin
  final SwiftPackageManagerPlugin completeSwiftpmPlugin =
      await SwiftPackageManagerUtils.createPlugin(
        flutterBin,
        workingDirectoryPath,
        platform: platform,
        usesSwiftPackageManager: true,
        name: migratedSwiftPackagePluginName,
      );
  SwiftPackageManagerUtils.addDependency(
    plugin: completeSwiftpmPlugin,
    appDirectoryPath: appDirectoryPath,
  );

  // Create a SwiftPM plugin without FlutterFramework dependency
  final SwiftPackageManagerPlugin incompleteSwiftpmPlugin =
      await SwiftPackageManagerUtils.createPlugin(
        flutterBin,
        workingDirectoryPath,
        platform: platform,
        usesSwiftPackageManager: true,
        name: partialSwiftPackagePluginName,
      );
  final File packageSwiftFile = fileSystem
      .directory(incompleteSwiftpmPlugin.swiftPackagePlatformPath)
      .childFile('Package.swift');
  packageSwiftFile.writeAsStringSync(
    packageSwiftFile
        .readAsStringSync()
        .replaceAll('.package(path: "../FlutterFramework"),', '')
        .replaceAll('.product(name: "FlutterFramework", package: "FlutterFramework"),', ''),
  );
  SwiftPackageManagerUtils.addDependency(
    plugin: incompleteSwiftpmPlugin,
    appDirectoryPath: appDirectoryPath,
  );

  // Create a CocoaPod plugin
  final SwiftPackageManagerPlugin cocoaPodsPlugin = await SwiftPackageManagerUtils.createPlugin(
    flutterBin,
    workingDirectoryPath,
    platform: platform,
    name: cocoaPodsPluginName,
  );
  SwiftPackageManagerUtils.convertToLegacyCocoaPodsPlugin(cocoaPodsPlugin, platform: platform);
  SwiftPackageManagerUtils.addDependency(
    plugin: cocoaPodsPlugin,
    appDirectoryPath: appDirectoryPath,
  );

  // Create a native asset
  final Directory nativeAssetDirectory = await SwiftPackageManagerUtils.createPackage(
    flutterBin,
    workingDirectoryPath,
    nativeAssetName,
    template: 'package_ffi',
  );
  SwiftPackageManagerUtils.addNativeAssetDependency(
    name: nativeAssetName,
    path: nativeAssetDirectory.path,
    appDirectoryPath: appDirectoryPath,
  );
}

void _verifyModeAgnosticFiles({
  required Directory buildDir,
  required String platform,
  required bool includeTests,
}) {
  expect(buildDir, exists);

  // Verify Scripts
  expect(buildDir.childFile('Scripts/FlutterAssembleInputs.xcfilelist'), exists);
  expect(buildDir.childFile('Scripts/flutter_integration.sh'), exists);

  // Verify FlutterNativeIntegration
  final Directory packageDir = buildDir.childDirectory('FlutterNativeIntegration');
  expect(packageDir, exists);
  expect(packageDir.childFile('Package.swift'), exists);
  expect(
    packageDir.childFile('Sources/FlutterNativeIntegration/FlutterNativeIntegration.swift'),
    exists,
  );

  // Verify FlutterNativeTools
  final Directory toolsPackageDir = packageDir.childDirectory('FlutterNativeTools');
  expect(toolsPackageDir.childFile('Package.swift'), exists);
  expect(toolsPackageDir.childFile('Plugins/Debug/FlutterBuildModePlugin.swift'), exists);
  expect(toolsPackageDir.childFile('Plugins/Profile/FlutterBuildModePlugin.swift'), exists);
  expect(toolsPackageDir.childFile('Plugins/Release/FlutterBuildModePlugin.swift'), exists);
  expect(
    toolsPackageDir.childFile('Sources/FlutterAssembleTool/FlutterAssembleTool.swift'),
    exists,
  );
  expect(toolsPackageDir.childFile('Sources/FlutterPluginTool/FlutterPluginTool.swift'), exists);
  expect(toolsPackageDir.childFile('Sources/FlutterToolHelper/FlutterToolHelper.swift'), exists);
  expect(
    toolsPackageDir.childFile('Sources/FlutterToolHelper/FlutterAssembleToolHelper.swift'),
    exists,
  );

  expect(toolsPackageDir.childDirectory('Tests'), includeTests ? exists : isNot(exists));
  if (includeTests) {
    expect(toolsPackageDir.childFile('Tests/FlutterToolTests/FlutterTestMocks.swift'), exists);
    expect(
      toolsPackageDir.childFile('Tests/FlutterToolTests/FlutterAssembleToolTests.swift'),
      exists,
    );
    expect(
      toolsPackageDir.childFile('Tests/FlutterToolTests/FlutterPluginToolTests.swift'),
      exists,
    );
    expect(
      toolsPackageDir.childFile('Tests/FlutterToolTests/FlutterToolHelperTests.swift'),
      exists,
    );
  }

  // Verify plugins
  final Directory pluginsDir = packageDir.childDirectory('.plugins');
  expect(pluginsDir, exists);
  final File migratedSwiftPackageManifest = pluginsDir.childFile(
    '$migratedSwiftPackagePluginName/$platform/$migratedSwiftPackagePluginName/Package.swift',
  );
  expect(migratedSwiftPackageManifest, exists);
  expect(migratedSwiftPackageManifest.readAsStringSync(), contains('../FlutterFramework'));

  final File partialMigratedSwiftPackageManifest = pluginsDir.childFile(
    '$partialSwiftPackagePluginName/$platform/$partialSwiftPackagePluginName/Package.swift',
  );
  expect(partialMigratedSwiftPackageManifest, exists);
  expect(partialMigratedSwiftPackageManifest.readAsStringSync(), contains('../FlutterFramework'));
}

void _verifyFilesForBuildMode({
  required Directory buildDir,
  required String buildMode,
  required FlutterDarwinPlatform platform,
}) {
  expect(buildDir.childFile('FlutterNativeIntegration/$buildMode/Package.swift'), exists);
  expect(
    buildDir.childFile(
      'FlutterNativeIntegration/$buildMode/Sources/FlutterPluginRegistrant/GeneratedPluginRegistrant.swift',
    ),
    exists,
  );

  // Verify frameworks
  expect(
    buildDir.childDirectory('FlutterNativeIntegration/$buildMode/Frameworks/App.xcframework'),
    exists,
  );
  expect(
    buildDir.childDirectory(
      'FlutterNativeIntegration/$buildMode/Frameworks/CocoaPods/$cocoaPodsPluginName.xcframework',
    ),
    exists,
  );
  expect(
    buildDir.childDirectory(
      'FlutterNativeIntegration/$buildMode/Frameworks/${platform.binaryName}.xcframework',
    ),
    exists,
  );
  expect(
    buildDir.childDirectory(
      'FlutterNativeIntegration/$buildMode/Frameworks/NativeAssets/$nativeAssetName.xcframework',
    ),
    exists,
  );

  // Verify Packages
  expect(
    buildDir.childDirectory('FlutterNativeIntegration/$buildMode/Packages/FlutterFramework'),
    exists,
  );
  expect(
    buildDir
        .childLink('FlutterNativeIntegration/$buildMode/Packages/$migratedSwiftPackagePluginName')
        .targetSync(),
    '../../.plugins/$migratedSwiftPackagePluginName/${platform.name}/$migratedSwiftPackagePluginName',
  );
  expect(
    buildDir
        .childLink('FlutterNativeIntegration/$buildMode/Packages/$partialSwiftPackagePluginName')
        .targetSync(),
    '../../.plugins/$partialSwiftPackagePluginName/${platform.name}/$partialSwiftPackagePluginName',
  );
}

Future<void> _verifyCodeSigning({
  required Directory buildDir,
  required String buildMode,
  required FlutterDarwinPlatform platform,
}) async {
  final frameworks = <String>[
    'FlutterNativeIntegration/$buildMode/Frameworks/App.xcframework',
    'FlutterNativeIntegration/$buildMode/Frameworks/CocoaPods/$cocoaPodsPluginName.xcframework',
    'FlutterNativeIntegration/$buildMode/Frameworks/${platform.binaryName}.xcframework',
    'FlutterNativeIntegration/$buildMode/Frameworks/NativeAssets/$nativeAssetName.xcframework',
  ];
  for (final framework in frameworks) {
    final ProcessResult result = await processManager.run(<String>[
      'xcrun',
      'codesign',
      '--display',
      '-vv',
      buildDir.childDirectory(framework).path,
    ]);
    final output = 'stdout: ${result.stdout}\nstderr: ${result.stderr}';
    expect(
      output,
      contains('Signature=adhoc'),
      reason: '$framework not codesigned correctly: \n$output',
    );
  }
}
