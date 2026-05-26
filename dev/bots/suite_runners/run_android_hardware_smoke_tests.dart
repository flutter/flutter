// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as path;

import '../run_command.dart';
import '../utils.dart';
import 'run_android_engine_tests.dart';

String _impellerBackendMetadata({required String value}) =>
    '<meta-data android:name="io.flutter.embedding.android.ImpellerBackend" android:value="$value" />';

/// Runs the Android Hardware Smoke Test golden suite in CI.
Future<void> runAndroidHardwareSmokeTests({required ImpellerBackend backend}) async {
  printProgress('Running Android Hardware Smoke Tests Shard (backend=${backend.name})');

  final String testDir = path.join('dev', 'integration_tests', 'android_hardware_smoke_test');

  final File androidManifestXml = const LocalFileSystem().file(
    path.join(testDir, 'android', 'app', 'src', 'main', 'AndroidManifest.xml'),
  );
  final String androidManifestContents = androidManifestXml.readAsStringSync();

  try {
    // Replace whatever the current backend is with the specified backend.
    final impellerBackendMetadata = RegExp(_impellerBackendMetadata(value: '.*'));
    androidManifestXml.writeAsStringSync(
      androidManifestContents.replaceFirst(
        impellerBackendMetadata,
        _impellerBackendMetadata(value: backend.name),
      ),
    );

    await runCommand(
      'flutter',
      <String>[
        'drive',
        '--driver=test_driver/driver_test.dart',
        '--target=integration_test/integration_test_wrapper.dart',
        '--no-dds',
        '--no-enable-dart-profiling',
      ],
      workingDirectory: testDir,
      environment: <String, String>{'ANDROID_HARDWARE_SMOKE_TEST_GOLDEN_VARIANT': backend.name},
    );
  } finally {
    // Restore original contents.
    androidManifestXml.writeAsStringSync(androidManifestContents);
  }
}
