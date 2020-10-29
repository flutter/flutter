// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:convert';
import 'dart:io';

import 'package:gcloud/src/datastore_impl.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  // In order to run these tests, one should download a service account
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

  test('parse_and_send succeeds with access token.', () async {
    final dynamic testCred =
        jsonDecode(File('secret/test_gcp_credentials.json').readAsStringSync())
            as Map<String, dynamic>;
    final AutoRefreshingAuthClient client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson(testCred),
      DatastoreImpl.SCOPES,
    );
    final String tokenPath =
        path.join(Directory.systemTemp.absolute.path, 'parse_and_send_token');
    File(tokenPath).writeAsStringSync(client.credentials.accessToken.data);
    final ProcessResult result = Process.runSync('dart', <String>[
      'bin/parse_and_send.dart',
      'example/txt_benchmarks.json',
    ], environment: <String, String>{
      'TOKEN_PATH': tokenPath,
      'GCP_PROJECT': testCred['project_id'] as String,
    });
    expect(result.exitCode, 0);
  });
}
