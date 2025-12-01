// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('flutter_app_test.');
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  // Tests the behavior of abiFilters during the build process.
  // Without abiFilters set, third-party x86 libraries would be packaged into the resulting APK/bundle.
  // This would force Google Play to add x86 ABI to the list of supported ABIs, leading to crashes on x86 devices.
  testWithoutContext('3rd-party x86 library is not packaged (default settings)', () async {
    final Directory projectDir = createProjectWithThirdpartyLib(tempDir);
    processManager.runSync(<String>[flutterBin, 'build', 'apk'], workingDirectory: projectDir.path);

    // Verify that the library is valid and picked up by Gradle during transform tasks.
    // Note: Gradle transforms and merges all available native libraries by default;
    // abiFilters are not applied at this stage.
    expect(
      projectDir
          .childDirectory(
            'build/app/intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib/x86',
          )
          .childFile('libflutter.so'),
      exists,
    );

    // Verify that libflutter.so is not packaged in the APK for x86 architecture.
    expect(_checkLibIsInApk(projectDir, 'lib/x86/libflutter.so'), false);
  });

  testWithoutContext('abiFilters provided by the user take precedence over the default', () async {
    final Directory projectDir = createProjectWithThirdpartyLib(tempDir);
    final String buildGradleContents = projectDir
        .childFile('android/app/build.gradle.kts')
        .readAsStringSync();

    // Modify the project's build.gradle.kts file to include abiFilters for a single ABI only.
    final String updatedBuildGradleContents = buildGradleContents.replaceFirstMapped(
      RegExp(r'(buildTypes\s*\{\s*release\s*\{)([^}]*)\}', dotAll: true),
      (Match match) {
        final String before = match.group(1)!;
        final String body = match.group(2)!;
        const ndkBlock = '''
                ndk {
                    abiFilters.clear()
                    abiFilters.addAll(listOf("arm64-v8a"))
                }
    ''';
        return '$before$body$ndkBlock        }';
      },
    );
    projectDir
        .childFile('android/app/build.gradle.kts')
        .writeAsStringSync(updatedBuildGradleContents);

    processManager.runSync(<String>[flutterBin, 'build', 'apk'], workingDirectory: projectDir.path);

    expect(_checkLibIsInApk(projectDir, 'lib/arm64-v8a/libflutter.so'), true);
    expect(_checkLibIsInApk(projectDir, 'lib/x86_64/libflutter.so'), false);
    expect(_checkLibIsInApk(projectDir, 'lib/armeabi-v7a/libflutter.so'), false);
    expect(_checkLibIsInApk(projectDir, 'lib/x86/libflutter.so'), false);
  });

  testWithoutContext(
    'abiFilters in product flavors provided by the user take precedence over the default',
    () async {
      final Directory projectDir = createProjectWithThirdpartyLib(tempDir);
      final String buildGradleContents = projectDir
          .childFile('android/app/build.gradle.kts')
          .readAsStringSync();

      const productFlavorsBlock = '''
    flavorDimensions += listOf("device")
    productFlavors {
        create("arm64") {
            dimension = "device"
            ndk {
                abiFilters.clear()
                abiFilters.addAll(listOf("arm64-v8a"))
            }
        }
        create("armeabi") {
            dimension = "device"
            ndk {
                abiFilters.clear()
                abiFilters.addAll(listOf("armeabi-v7a"))
            }
        }
    }''';
      // Modify the project's build.gradle.kts file to include abiFilters for product flavors.
      final String updatedBuildGradleContents = buildGradleContents.replaceFirstMapped(
        RegExp(r'^(android\s*\{)', multiLine: true),
        (Match match) => '${match.group(1)!}\n$productFlavorsBlock',
      );
      projectDir
          .childFile('android/app/build.gradle.kts')
          .writeAsStringSync(updatedBuildGradleContents);

      processManager.runSync(<String>[
        flutterBin,
        'build',
        'apk',
        '--release',
        '--flavor',
        'arm64',
        '-P',
        'disable-abi-filtering=true',
      ], workingDirectory: projectDir.path);

      expect(
        _checkLibIsInApk(projectDir, 'lib/arm64-v8a/libflutter.so', productFlavor: 'arm64'),
        true,
      );
      expect(
        _checkLibIsInApk(projectDir, 'lib/x86_64/libflutter.so', productFlavor: 'arm64'),
        false,
      );
      expect(
        _checkLibIsInApk(projectDir, 'lib/armeabi-v7a/libflutter.so', productFlavor: 'arm64'),
        false,
      );
      expect(_checkLibIsInApk(projectDir, 'lib/x86/libflutter.so', productFlavor: 'arm64'), false);
    },
  );
}

Directory createProjectWithThirdpartyLib(Directory workingDir) {
  final Directory appDir = workingDir.childDirectory('app');

  processManager.runSync(<String>[
    flutterBin,
    'create',
    '--template=app',
    '--platforms=android',
    'app',
  ], workingDirectory: workingDir.path);

  // Generate a prebuilt x86_64 artifact by building a debug APK and extracting the valid libflutter.so.
  // This is the most straightforward way to obtain a valid library (*.so) for testing.
  // Any architecture can be used, because gradle does not check the architecture of the library – it only checks that it is a valid shared object file.
  processManager.runSync(<String>[
    flutterBin,
    'build',
    'apk',
    '--debug',
    '--target-platform',
    'android-x64',
  ], workingDirectory: appDir.path);

  final File prebuiltFlutterLib = appDir.childFile(
    'build/app/intermediates/stripped_native_libs/debug/stripDebugDebugSymbols/out/lib/x86_64/libflutter.so',
  );

  // Copies prebuilt debug library to directory from which gradle will pick it up during release build.
  final Directory x86Dir = appDir.childDirectory('android/app/src/main/jniLibs/x86');
  x86Dir.createSync(recursive: true);
  prebuiltFlutterLib.copySync(x86Dir.childFile('libflutter.so').path);

  return appDir;
}

bool _checkLibIsInApk(
  Directory appDir,
  String filename, {
  BuildMode buildMode = BuildMode.release,
  String productFlavor = '',
}) {
  final File localPropertiesFile = appDir.childDirectory('android').childFile('local.properties');
  if (!localPropertiesFile.existsSync()) {
    throw StateError('local.properties file not found at ${localPropertiesFile.path}');
  }

  final String fileContent = localPropertiesFile.readAsStringSync();
  final regex = RegExp(r'sdk\.dir=(.+)');
  final Match? match = regex.firstMatch(fileContent);
  final String sdkPath = match?.group(1) ?? '';

  if (sdkPath.isEmpty) {
    throw StateError('SDK path not found in local.properties');
  }

  final String apkAnalyzer = fileSystem
      .directory(sdkPath)
      .childDirectory('cmdline-tools/latest/bin')
      .childFile(Platform.isWindows ? 'apkanalyzer.bat' : 'apkanalyzer')
      .path;

  final apkName = (productFlavor.isEmpty)
      ? 'app-${buildMode.cliName}.apk'
      : 'app-$productFlavor-${buildMode.cliName}.apk';

  final String apkDir = (productFlavor.isEmpty)
      ? buildMode.cliName
      : '$productFlavor/${buildMode.cliName}';

  final File apkFile = appDir.childDirectory('build/app/outputs/apk/$apkDir').childFile(apkName);

  if (!apkFile.existsSync()) {
    throw StateError('APK file not found at ${apkFile.path}');
  }

  final ProcessResult result = processManager.runSync(<String>[
    apkAnalyzer,
    'files',
    'list',
    apkFile.path,
  ]);

  if (result.exitCode != 0) {
    throw ProcessException(
      apkAnalyzer,
      <String>['files', 'list', apkFile.path],
      'apkanalyzer failed with exit code ${result.exitCode}\n${result.stderr}',
      result.exitCode,
    );
  }

  return result.stdout.toString().contains(filename);
}
