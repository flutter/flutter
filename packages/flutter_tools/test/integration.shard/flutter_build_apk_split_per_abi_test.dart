// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

// Test that `flutter build apk --split-per-abi` generates a versionCode equal to abiIndex * 1000 + 1
void main() {
  testWithoutContext('APK versionCodes after --split-per-abi for all four ABIs follow '
      '"(abiIndex * 1000) + 1"', () async {
    final String workingDirectory = fileSystem.path.join(
      getFlutterRoot(),
      'examples',
      'hello_world',
    );

    final ProcessResult buildResult = processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'apk',
      '--debug',
      '--split-per-abi',
    ], workingDirectory: workingDirectory);

    expect(buildResult.exitCode, 0,
        reason:
            'Expected `flutter build apk --debug --split-per-abi` to succeed.\n'
            'stdout:\n${buildResult.stdout}\n'
            'stderr:\n${buildResult.stderr}');

    final Directory apkOutputDir = fileSystem.directory(workingDirectory)
        .childDirectory('build')
        .childDirectory('app')
        .childDirectory('outputs')
        .childDirectory('flutter-apk');
    expect(apkOutputDir, isDirectory,
        reason:
            'Expected build outputs directory to exist at ${apkOutputDir.path}');

    final List<File> apkFiles = apkOutputDir
        .listSync()
        .whereType<File>()
        .where((File f) => RegExp(r'app-.*-debug\.apk$').hasMatch(f.uri.pathSegments.last))
        .toList();

    expect(apkFiles.length, 4,
        reason:
            'Expected 4 ABI-specific debug APKs (armeabi-v7a, arm64-v8a, x86, x86_64); '
            'found ${apkFiles.map((File f) => f.path).join(", ")}');

    // ABI→index mapping (as in FlutterPluginConstants.ABI_VERSION):
    final Map<String, int> abiIndexMap = <String, int>{
      'armeabi-v7a': 1,
      'arm64-v8a': 2,
      'x86': 3,
      'x86_64': 4,
    };

    // For each APK, run `aapt dump badging` and extract versionCode
    for (final File apkFile in apkFiles) {
      final String filename = apkFile.uri.pathSegments.last;

      final RegExp nameRegex = RegExp(r'app-([^-]+(?:-[0-9a-z]+)*)-debug\.apk');
      final RegExpMatch? nameMatch = nameRegex.firstMatch(filename);
      expect(nameMatch, isNotNull,
          reason: 'Unexpected APK filename format: $filename');

      final String abi = nameMatch!.group(1)!;
      expect(abiIndexMap, contains(abi),
          reason: 'Found unexpected ABI suffix "$abi" in $filename');

      final int expectedVersionCode = abiIndexMap[abi]! * 1000 + 1;

      final ProcessResult aaptResult = processManager.runSync(<String>[
        'aapt',
        'dump',
        'badging',
        apkFile.path,
      ]);
      expect(aaptResult.exitCode, 0,
          reason: 'Expected `aapt dump badging` to succeed on ${apkFile.path}');

      final RegExp verCodeRegex = RegExp(r"versionCode='(\d+)'");
      final String stdoutString = aaptResult.stdout as String;
      final RegExpMatch? badgingMatch = verCodeRegex.firstMatch(stdoutString);
      expect(badgingMatch, isNotNull,
          reason:
              'Could not find versionCode in `aapt dump badging` for ${apkFile.path}');
      final int actualVersionCode = int.parse(badgingMatch!.group(1)!);

      expect(actualVersionCode, expectedVersionCode,
          reason:
              'For ABI "$abi", expected versionCode=$expectedVersionCode in $filename, got $actualVersionCode');
    }
  });
}
