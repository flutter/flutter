// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/file.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/version.dart';

import '../src/common.dart';
import 'test_utils.dart';

/// ABI → index map (same as FlutterPluginConstants.ABI_VERSION)
const _abiIndexMap = <String, int>{'armeabi-v7a': 1, 'arm64-v8a': 2, 'x86_64': 4};

const _appGradleWithVersionCodeModification = r'''
import com.android.build.api.variant.FilterConfiguration.FilterType.*
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.splitperabi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.splitperabi"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

val abiCodes = mapOf("x86_64" to 1, "armeabi-v7a" to 2, "arm64-v8a" to 3, "universal" to 4)

androidComponents {
    onVariants { variant ->

        variant.outputs.forEach { output ->
            val name = output.filters.find { it.filterType == ABI }?.identifier

            val baseAbiCode = abiCodes[name ?: "universal"]
            if (baseAbiCode != null) {
                output.versionCode.set(output.versionCode.get() * 10000)
            }
        }
    }
}

''';

// Check that `flutter build apk --split-per-abi` sets versionCode to abiIndex * 1000 + buildNumber
// (times 10000 with [usingCustomAppGradleFile]) and copies each per-ABI APK into flutter-apk.
// [compatibilityModeOff] sets `android.compatibility.enableLegacyApi=false`.
Future<void> _assertSplitPerAbiVersionCodes(
  int? buildNumber,
  Directory workingDirectory,
  bool usingCustomAppGradleFile, {
  bool compatibilityModeOff = false,
}) async {
  if (usingCustomAppGradleFile) {
    // Replace the app level build.gradle with one that modifies the version code.
    final File appBuildGradle = fileSystem
        .directory(workingDirectory)
        .childDirectory('android')
        .childDirectory('app')
        .childFile('build.gradle.kts');

    await appBuildGradle.writeAsString(_appGradleWithVersionCodeModification);
  }

  if (compatibilityModeOff) {
    final File gradleProperties = fileSystem
        .directory(workingDirectory)
        .childDirectory('android')
        .childFile('gradle.properties');
    await gradleProperties.writeAsString(
      '\nandroid.compatibility.enableLegacyApi=false\n',
      mode: FileMode.append,
    );
  }

  final args = <String>[
    flutterBin,
    ...getLocalEngineArguments(),
    'build',
    'apk',
    '--debug',
    '--split-per-abi',
  ];

  if (buildNumber != null) {
    args.addAll(<String>['--build-number', buildNumber.toString()]);
  }

  final ProcessResult result = processManager.runSync(
    args,
    workingDirectory: workingDirectory.path,
  );
  expect(
    result.exitCode,
    0,
    reason:
        'Expected flutter build apk --debug --split-per-abi'
        '${buildNumber != null ? " --build-number $buildNumber" : ""} to succeed.\n'
        'stdout:\n${result.stdout}\n'
        'stderr:\n${result.stderr}',
  );

  final File metadataFile = fileSystem
      .directory(workingDirectory)
      .childDirectory('build')
      .childDirectory('app')
      .childDirectory('outputs')
      .childDirectory('apk')
      .childDirectory('debug')
      .childFile('output-metadata.json');
  expect(metadataFile, exists, reason: 'Expected output-metadata.json at ${metadataFile.path}');

  final decodedJson = jsonDecode(await metadataFile.readAsString()) as Map<String, dynamic>;
  final elements = decodedJson['elements'] as List<dynamic>;

  final actualVersionCodes = <String, int>{};
  for (final dynamic rawElement in elements) {
    final element = rawElement as Map<String, dynamic>;

    final filters = element['filters'] as List<dynamic>?;
    expect(
      filters,
      isNotNull,
      reason: 'No "filters" array for element $element in ${metadataFile.path}',
    );

    String? abi;
    for (final Map<String, Object?> filter in filters!.cast<Map<String, Object?>>()) {
      if (filter['filterType'] == 'ABI') {
        abi = filter['value'] as String?;
        break;
      }
    }
    expect(abi, isNotNull, reason: 'Could not find an ABI filter in element $element');

    final versionCode = element['versionCode'] as int?;
    expect(versionCode, isNotNull, reason: 'No "versionCode" field in element $element');

    actualVersionCodes[abi!] = versionCode!;
  }

  for (final MapEntry<String, int> kv in _abiIndexMap.entries) {
    final String abi = kv.key;
    final int abiIndex = kv.value;

    expect(
      actualVersionCodes,
      contains(abi),
      reason: 'Missing entry for ABI="$abi" in output-metadata.json',
    );

    final int actual = actualVersionCodes[abi]!;
    // The custom app build file's onVariants runs after Flutter's and multiplies by 10000.
    final int baseVersionCode = (abiIndex * 1000) + (buildNumber ?? 1);
    final int expected = usingCustomAppGradleFile ? baseVersionCode * 10000 : baseVersionCode;
    expect(
      actual,
      expected,
      reason:
          'For ABI="$abi" with '
          '${buildNumber != null ? "buildNumber=$buildNumber" : "no explicit build-number"} '
          'expected versionCode=$expected but got $actual.',
    );

    // The Flutter tool reads the APKs from flutter-apk, under per-ABI names.
    final File flutterApk = fileSystem
        .directory(workingDirectory)
        .childDirectory('build')
        .childDirectory('app')
        .childDirectory('outputs')
        .childDirectory('flutter-apk')
        .childFile('app-$abi-debug.apk');
    expect(flutterApk, exists, reason: 'Expected the per-ABI APK at ${flutterApk.path}');
  }
}

/// Returns the versionCode that `aapt2 dump badging` reports for [apk].
int _badgingVersionCode(Directory workingDirectory, File apk) {
  final String localProperties = fileSystem
      .directory(workingDirectory)
      .childDirectory('android')
      .childFile('local.properties')
      .readAsStringSync();
  final String sdkPath = RegExp(r'sdk\.dir=(.*)').firstMatch(localProperties)!.group(1)!.trim();
  final List<Directory> buildTools =
      fileSystem
          .directory(sdkPath)
          .childDirectory('build-tools')
          .listSync()
          .whereType<Directory>()
          .where((Directory dir) => Version.parse(dir.basename) != null)
          .toList()
        ..sort(
          (Directory a, Directory b) =>
              Version.parse(a.basename)!.compareTo(Version.parse(b.basename)!),
        );
  final String aapt2 = buildTools.last.childFile(platform.isWindows ? 'aapt2.exe' : 'aapt2').path;
  final ProcessResult result = processManager.runSync(<String>[aapt2, 'dump', 'badging', apk.path]);
  expect(result.exitCode, 0, reason: 'aapt2 dump badging ${apk.path} failed:\n${result.stderr}');
  final String? versionCode = RegExp(r"versionCode='(\d+)'")
      .firstMatch(result.stdout as String)
      ?.group(1);
  expect(versionCode, isNotNull, reason: 'No versionCode in:\n${result.stdout}');
  return int.parse(versionCode!);
}

// Check that `flutter build apk --split-per-abi` offsets a versionCode that is set only in
// AndroidManifest.xml, not in the android {} block, as abiIndex * 1000 + versionCode.
Future<void> _assertSplitPerAbiOffsetsManifestVersionCode(
  Directory workingDirectory, {
  bool compatibilityModeOff = false,
  bool versionCodeInManifest = true,
  bool configurationCache = false,
}) async {
  final Directory androidDir = workingDirectory.childDirectory('android');
  final File appBuildGradle = androidDir.childDirectory('app').childFile('build.gradle.kts');
  final String gradle = appBuildGradle.readAsStringSync();
  expect(gradle, contains('versionCode = flutter.versionCode'));
  appBuildGradle.writeAsStringSync(gradle.replaceFirst('versionCode = flutter.versionCode', ''));
  final File manifest = androidDir
      .childDirectory('app')
      .childDirectory('src')
      .childDirectory('main')
      .childFile('AndroidManifest.xml');
  final String manifestContent = manifest.readAsStringSync();
  const manifestTag = '<manifest xmlns:android="http://schemas.android.com/apk/res/android"';
  expect(manifestContent, contains(manifestTag));
  if (versionCodeInManifest) {
    manifest.writeAsStringSync(
      manifestContent.replaceFirst(manifestTag, '$manifestTag android:versionCode="7"'),
    );
  }
  if (compatibilityModeOff) {
    androidDir
        .childFile('gradle.properties')
        .writeAsStringSync(
          '\nandroid.compatibility.enableLegacyApi=false\n',
          mode: FileMode.append,
        );
  }
  if (configurationCache) {
    // problems=warn because FlutterTask still reads Task.project at execution time.
    androidDir
        .childFile('gradle.properties')
        .writeAsStringSync(
          '\norg.gradle.configuration-cache=true\norg.gradle.configuration-cache.problems=warn\n'
          'android.newDsl=true\nandroid.builtInKotlin=true\n',
          mode: FileMode.append,
        );
  }

  ProcessResult build() => processManager.runSync(<String>[
    flutterBin,
    ...getLocalEngineArguments(),
    'build',
    'apk',
    '--debug',
    '--split-per-abi',
    // Verbose output shows whether Gradle reused the configuration cache.
    if (configurationCache) '-v',
  ], workingDirectory: workingDirectory.path);

  void expectVersionCodes(ProcessResult result, int base) {
    expect(result.exitCode, 0, reason: 'stdout:\n${result.stdout}\nstderr:\n${result.stderr}');
    for (final MapEntry<String, int> kv in _abiIndexMap.entries) {
      final File apk = workingDirectory
          .childDirectory('build')
          .childDirectory('app')
          .childDirectory('outputs')
          .childDirectory('flutter-apk')
          .childFile('app-${kv.key}-debug.apk');
      expect(apk, exists);
      expect(
        _badgingVersionCode(workingDirectory, apk),
        kv.value * 1000 + base,
        reason: 'versionCode of ${apk.path}',
      );
    }
  }

  final ProcessResult result = build();
  if (!versionCodeInManifest) {
    // Split APKs that share a versionCode would be rejected by Google Play, so the build fails.
    expect(result.exitCode, isNot(0));
    expect('${result.stdout}${result.stderr}', contains('cannot give each split APK of variant'));
    return;
  }
  expectVersionCodes(result, 7);

  if (configurationCache) {
    // The first build creates flutter_build.d, which Gradle tracks, so the second build stores
    // the cache entry again. The third build reuses it.
    expectVersionCodes(build(), 7);
    // A manifest edit must reach a build that reuses the configuration cache.
    ProcessResult rebuild = build();
    expect(rebuild.stdout, contains('Reusing configuration cache'));
    expectVersionCodes(rebuild, 7);
    manifest.writeAsStringSync(
      manifest.readAsStringSync().replaceFirst(
        'android:versionCode="7"',
        'android:versionCode="6"',
      ),
    );
    rebuild = build();
    expect(rebuild.stdout, contains('Reusing configuration cache'));
    expectVersionCodes(rebuild, 6);
  }
}

void main() {
  late Directory tempDir;
  late Directory appDir;
  setUp(() async {
    tempDir = createResolvedTempDirectorySync('flutter_split_per_abi_test.');

    processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'create',
      '--platforms=android',
      'splitperabi',
    ], workingDirectory: tempDir.path);
    appDir = tempDir.childDirectory('splitperabi');
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  // Check with no build-number
  testWithoutContext('APK versionCodes after --split-per-abi (no explicit build-number) follow "(abiIndex * 1000) + 1"', () async {
    await _assertSplitPerAbiVersionCodes(null, appDir, false);
  });

  // Check with custom buildNumber=42
  testWithoutContext('APK versionCodes after --split-per-abi with custom build-number=42 follow "(abiIndex * 1000) + 42"', () async {
    await _assertSplitPerAbiVersionCodes(42, appDir, false);
  });

  // Check with custom buildNumber=42 and custom gradle file which multiplies build number by 10000
  testWithoutContext('APK versionCodes after --split-per-abi with custom build-number=42 and gradle file follow "((abiIndex * 1000) + 42) * 10000"', () async {
    await _assertSplitPerAbiVersionCodes(42, appDir, true);
  });

  // Check with custom buildNumber=42 and AGP's compatibility mode off
  testWithoutContext('APK versionCodes after --split-per-abi with custom build-number=42 and enableLegacyApi=false follow "(abiIndex * 1000) + 42"', () async {
    await _assertSplitPerAbiVersionCodes(42, appDir, false, compatibilityModeOff: true);
  });

  testWithoutContext(
    'APK versionCodes after --split-per-abi offset a versionCode set only in the manifest',
    () async {
      await _assertSplitPerAbiOffsetsManifestVersionCode(appDir);
    },
  );

  testWithoutContext('APK versionCodes after --split-per-abi offset a manifest-only versionCode with enableLegacyApi=false', () async {
    await _assertSplitPerAbiOffsetsManifestVersionCode(appDir, compatibilityModeOff: true);
  });

  testWithoutContext('APK versionCodes after --split-per-abi follow manifest edits with the configuration cache, newDsl and enableLegacyApi=false', () async {
    await _assertSplitPerAbiOffsetsManifestVersionCode(
      appDir,
      compatibilityModeOff: true,
      configurationCache: true,
    );
  });

  testWithoutContext(
    '--split-per-abi fails when neither the DSL nor the manifest sets a versionCode',
    () async {
      await _assertSplitPerAbiOffsetsManifestVersionCode(appDir, versionCodeInManifest: false);
    },
  );
}
