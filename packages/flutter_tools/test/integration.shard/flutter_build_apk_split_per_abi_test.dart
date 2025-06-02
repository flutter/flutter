// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

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

    expect(
      buildResult.exitCode,
      0,
      reason:
          'Expected `flutter build apk --debug --split-per-abi` to succeed.\n'
          'stdout:\n${buildResult.stdout}\n'
          'stderr:\n${buildResult.stderr}',
    );

    final File metadataFile = fileSystem
        .directory(workingDirectory)
        .childDirectory('build')
        .childDirectory('app')
        .childDirectory('outputs')
        .childDirectory('apk')
        .childDirectory('debug')
        .childFile('output-metadata.json');
    expect(
      metadataFile,
      exists,
      reason: 'Expected output-metadata.json file to exist at ${metadataFile.path}',
    );

    final Map<String, dynamic> decodedJson =
        jsonDecode(await metadataFile.readAsString()) as Map<String, dynamic>;

    final List<dynamic> elements = decodedJson['elements'] as List<dynamic>;

    final Map<String, int> actualVersionCodes = <String, int>{};
    for (final dynamic rawElement in elements) {
      final Map<String, dynamic> element = rawElement as Map<String, dynamic>;

      final List<dynamic>? filters = element['filters'] as List<dynamic>?;
      expect(
        filters,
        isNotNull,
        reason: 'Could not find filters in ${metadataFile.path} entry: $element',
      );

      String? abi;
      for (final dynamic rawFilter in filters!) {
        final Map<String, dynamic> filter = rawFilter as Map<String, dynamic>;
        if (filter['filterType'] == 'ABI') {
          abi = filter['value'] as String?;
          break;
        }
      }
      expect(
        abi,
        isNotNull,
        reason: 'Could not find an ABI filter in ${metadataFile.path} entry: $element',
      );

      final int? versionCode = element['versionCode'] as int?;
      expect(
        versionCode,
        isNotNull,
        reason: 'Could not find versionCode in ${metadataFile.path} entry: $element',
      );

      actualVersionCodes[abi!] = versionCode!;
    }

    // ABI→index mapping (as in FlutterPluginConstants.ABI_VERSION):
    final Map<String, int> abiIndexMap = <String, int>{
      'armeabi-v7a': 1,
      'arm64-v8a': 2,
      'x86': 3,
      'x86_64': 4,
    };

    for (final MapEntry<String, int> kv in abiIndexMap.entries) {
      final String abi = kv.key;
      final int abiIndex = kv.value;

      expect(
        actualVersionCodes,
        contains(abi),
        reason: '${metadataFile.path} did not contain an entry for ABI="$abi"',
      );

      final int actual = actualVersionCodes[abi]!;
      final int expected = abiIndex * 1000 + 1;
      expect(
        actual,
        expected,
        reason: 'For ABI="$abi", expected versionCode=$expected, but got $actual instead',
      );
    }
  });
}
