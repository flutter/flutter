// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/file.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/io.dart';

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
    id("kotlin-android")
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

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
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

// Check that `flutter build apk --split-per-abi` generates a versionCode equal to abiIndex * 1000 + buildNumber
Future<void> _assertSplitPerAbiVersionCodes(
  int? buildNumber,
  Directory workingDirectory,
  bool usingCustomAppGradleFile,
) async {
  if (usingCustomAppGradleFile) {
    // Replace the app level build.gradle with one that modifies the version code.
    final File appBuildGradle = fileSystem
        .directory(workingDirectory)
        .childDirectory('android')
        .childDirectory('app')
        .childFile('build.gradle.kts');

    await appBuildGradle.writeAsString(_appGradleWithVersionCodeModification);
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
    final int expected =
        (abiIndex * 1000) + ((buildNumber ?? 1) * (usingCustomAppGradleFile ? 10000 : 1));
    expect(
      actual,
      expected,
      reason:
          'For ABI="$abi" with '
          '${buildNumber != null ? "buildNumber=$buildNumber" : "no explicit build-number"} '
          'expected versionCode=$expected but got $actual.',
    );
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
  testWithoutContext(
    'APK versionCodes after --split-per-abi (no explicit build-number) follow "(abiIndex * 1000) + 1"',
    () async {
      await _assertSplitPerAbiVersionCodes(null, appDir, false);
    },
  );

  // Check with custom buildNumber=42
  testWithoutContext(
    'APK versionCodes after --split-per-abi with custom build-number=42 follow "(abiIndex * 1000) + 42"',
    () async {
      await _assertSplitPerAbiVersionCodes(42, appDir, false);
    },
  );

  // Check with custom buildNumber=42 and custom gradle file which multiplies build number by 10000
  testWithoutContext(
    'APK versionCodes after --split-per-abi with custom build-number=42 and gradle file follow "(abiIndex * 1000) + (42 * 10000)"',
    () async {
      await _assertSplitPerAbiVersionCodes(42, appDir, true);
    },
  );
}
