// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:io';

import 'package:test/test.dart';

void main() {
  // In order to run this test, one should download a service account
  // credentials json from a test GCP project, and put that json as
  // `secret/test_gcp_credentials.json`. There's a `flutter-test` project for
  // Flutter team members.
  test('parse_and_send with example json does not crash.', () async {
    final String testCred =
        File('secret/test_gcp_credentials.json').readAsStringSync();
    Process.runSync('dart', <String>[
      'bin/parse_and_send.dart',
      'example/txt_benchmarks.json',
    ], environment: <String, String>{
      'BENCHMARK_GCP_CREDENTIALS': testCred,
    });
  });
}
