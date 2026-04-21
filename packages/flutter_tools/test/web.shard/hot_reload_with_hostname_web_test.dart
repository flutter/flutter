// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Tags(<String>['flutter-test-driver'])
library;

import 'dart:async';
import 'dart:io';

import 'package:file/file.dart';

import '../integration.shard/test_data/hot_reload_project.dart';
import '../integration.shard/test_data/hot_reload_test_common.dart';
import '../integration.shard/test_driver.dart';
import '../integration.shard/test_utils.dart';
import '../src/common.dart';

// Test that hot reload correctly uses relative paths for reload by forcing a
// host name.

Future<List<String>> _getIps() async {
  final List<String> ips = [];
  final List<NetworkInterface> interfaces = await NetworkInterface.list();

  if (interfaces.isNotEmpty) {
    for (final interface in interfaces) {
      for (final InternetAddress address in interface.addresses) {
        ips.add(address.address);
      }
    }
  }

  return ips;
}

void main() async {
  final List<String> ips = await _getIps();

  group('test hot reload', () {
    late Directory tempDir;
    final project = HotReloadProject();
    late FlutterRunTestDriver flutter;

    setUp(() async {
      tempDir = createResolvedTempDirectorySync('hot_reload_test.');
      await project.setUpIn(tempDir);
      flutter = FlutterRunTestDriver(tempDir);
    });

    tearDown(() async {
      await flutter.stop();
      tryToDelete(tempDir);
    });

    // No need to run the entire test suite to verify relative paths.
    testWithoutContext(
      'newly added code executes during hot reload',
      () async => testAddedCodeHotReload(
        flutter: flutter,
        project: project,
        chrome: true,
        additionalCommandArgs: <String>[
          '--web-experimental-hot-reload',
          '--no-web-resources-cdn',
          '--web-hostname=${ips.single}',
          '--web-port=8080',
        ],
      ),
    );
  });
}
