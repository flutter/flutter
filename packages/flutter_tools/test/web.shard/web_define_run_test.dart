// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Tags(<String>['flutter-test-driver'])
library;

import 'dart:convert';
import 'dart:io' as io;

import 'package:file/file.dart';

import '../integration.shard/test_data/web_define_project.dart';
import '../integration.shard/test_driver.dart';
import '../integration.shard/test_utils.dart';
import '../src/common.dart';

import 'test_data/web_server_test_common.dart';

/// Fetches the body served at [url]; the bare app URL serves index.html.
Future<String> _fetch(String url) async {
  final client = io.HttpClient();
  try {
    final io.HttpClientRequest request = await client.getUrl(Uri.parse(url));
    final io.HttpClientResponse response = await request.close();
    final String body = await response.transform(utf8.decoder).join();
    if (response.statusCode != io.HttpStatus.ok) {
      throw Exception('GET $url returned HTTP ${response.statusCode}, body:\n$body');
    }
    return body;
  } finally {
    client.close(force: true);
  }
}

/// Asserts --web-define placeholders were substituted and none remain.
void _expectSubstituted(String body) {
  expect(body, contains(WebDefineProject.kVersion));
  expect(body, contains(WebDefineProject.kApiUrl));
  expect(body, isNot(contains('{{MY_VERSION}}')));
  expect(body, isNot(contains('{{API_URL}}')));
}

void main() {
  late Directory tempDir;
  final project = WebDefineProject();
  late FlutterRunTestDriver flutter;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('web_define_run_test.');
    await project.setUpIn(tempDir);
    flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    await flutter.stop();
    tryToDelete(tempDir);
  });

  const webDefineArgs = <String>[
    '--no-web-resources-cdn',
    '--web-define=MY_VERSION=${WebDefineProject.kVersion}',
    '--web-define=API_URL=${WebDefineProject.kApiUrl}',
  ];

  testWithoutContext('flutter run (debug) substitutes --web-define in served index.html '
      'and keeps it substituted across hot reload and hot restart', () async {
    final testRunner = WebServerDeviceTestRunner(flutter);
    try {
      final String appUrl = await testRunner.runWebServerDevice(
        additionalCommandArgs: webDefineArgs,
      );
      _expectSubstituted(await _fetch(appUrl));

      await testRunner.hotReload();
      _expectSubstituted(await _fetch(appUrl));

      await testRunner.hotRestart();
      _expectSubstituted(await _fetch(appUrl));
    } finally {
      await testRunner.cleanup();
    }
  });

  testWithoutContext('flutter run --profile substitutes --web-define in served index.html '
      'and keeps it substituted across hot restart', () async {
    final testRunner = WebServerDeviceTestRunner(flutter);
    try {
      final String appUrl = await testRunner.runWebServerDevice(
        additionalCommandArgs: <String>[...webDefineArgs, '--profile'],
      );
      _expectSubstituted(await _fetch(appUrl));

      // Hot reload is debug-only.
      await testRunner.hotRestart();
      _expectSubstituted(await _fetch(appUrl));
    } finally {
      await testRunner.cleanup();
    }
  });

  testWithoutContext('flutter run --release substitutes --web-define in served index.html '
      'and keeps it substituted across hot restart', () async {
    final testRunner = WebServerDeviceTestRunner(flutter);
    try {
      final String appUrl = await testRunner.runWebServerDevice(
        additionalCommandArgs: <String>[...webDefineArgs, '--release'],
      );
      _expectSubstituted(await _fetch(appUrl));

      await testRunner.hotRestart();
      _expectSubstituted(await _fetch(appUrl));
    } finally {
      await testRunner.cleanup();
    }
  });
}
