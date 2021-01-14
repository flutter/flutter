// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/src/datastore_impl.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:metrics_center/src/common.dart';
import 'package:metrics_center/src/legacy_flutter.dart';

import 'common.dart';
import 'utility.dart';

const String kTestSourceId = 'test';

void main() {
  final Map<String, dynamic> credentialsJson = getTestGcpCredentialsJson();
  test(
      'LegacyFlutterDestination integration test: '
      'update does not crash.', () async {
    final LegacyFlutterDestination dst =
        await LegacyFlutterDestination.makeFromCredentialsJson(credentialsJson);
    await dst.update(<MetricPoint>[MetricPoint(1.0, const <String, String>{})]);
  }, skip: credentialsJson == null);

  test(
      'LegacyFlutterDestination integration test: '
      'can update with an access token.', () async {
    final AutoRefreshingAuthClient client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson(credentialsJson),
      DatastoreImpl.SCOPES,
    );
    final String token = client.credentials.accessToken.data;
    final LegacyFlutterDestination dst =
        LegacyFlutterDestination.makeFromAccessToken(
      token,
      credentialsJson[kProjectId] as String,
    );
    await dst.update(<MetricPoint>[MetricPoint(1.0, const <String, String>{})]);
  }, skip: credentialsJson == null);
}
