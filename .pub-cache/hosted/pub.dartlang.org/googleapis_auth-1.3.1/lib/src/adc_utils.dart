// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';

import 'auth_functions.dart';
import 'auth_http_utils.dart';
import 'service_account_client.dart';
import 'service_account_credentials.dart';

Future<AutoRefreshingAuthClient> fromApplicationsCredentialsFile(
  File file,
  String fileSource,
  List<String> scopes,
  Client baseClient,
) async {
  Object? credentials;
  try {
    credentials = json.decode(await file.readAsString());
  } on IOException {
    throw Exception(
      'Failed to read credentials file from $fileSource',
    );
  } on FormatException {
    throw Exception(
      'Failed to parse JSON from credentials file from $fileSource',
    );
  }

  if (credentials is Map && credentials['type'] == 'authorized_user') {
    final clientId = ClientId(
      credentials['client_id'] as String,
      credentials['client_secret'] as String?,
    );
    return AutoRefreshingClient(
      baseClient,
      clientId,
      await refreshCredentials(
        clientId,
        AccessCredentials(
          // Hack: Create empty credentials that have expired.
          AccessToken('Bearer', '', DateTime(0).toUtc()),
          credentials['refresh_token'] as String?,
          scopes,
        ),
        baseClient,
      ),
      quotaProject: credentials['quota_project_id'] as String?,
    );
  }
  return await clientViaServiceAccount(
    ServiceAccountCredentials.fromJson(credentials),
    scopes,
    baseClient: baseClient,
  );
}
