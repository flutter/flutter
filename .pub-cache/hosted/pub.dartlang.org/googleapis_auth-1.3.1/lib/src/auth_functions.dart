// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:http/http.dart';

import 'access_credentials.dart';
import 'auth_client.dart';
import 'auth_http_utils.dart';
import 'client_id.dart';
import 'http_client_base.dart';
import 'utils.dart';

/// Obtains a [Client] which uses the given [apiKey] for making HTTP
/// requests.
///
/// {@macro googleapis_auth_baseClient_param}
///
/// Note that the returned client should *only* be used for making HTTP requests
/// to Google Services. The [apiKey] should not be disclosed to third parties.
///
/// {@template googleapis_auth_close_the_client}
/// The user is responsible for closing the returned HTTP [Client].
/// {@endtemplate}
/// {@template googleapis_auth_not_close_the_baseClient}
/// Closing the returned [Client] will not close [baseClient].
/// {@endtemplate}
Client clientViaApiKey(
  String apiKey, {
  Client? baseClient,
}) {
  if (baseClient == null) {
    baseClient = Client();
  } else {
    baseClient = nonClosingClient(baseClient);
  }
  return ApiKeyClient(baseClient, apiKey);
}

/// Obtain a [Client] which automatically authenticates requests using
/// [credentials].
///
/// Note that the returned [AuthClient] will not auto-refresh the given
/// [credentials].
///
/// {@macro googleapis_auth_close_the_client}
/// {@macro googleapis_auth_not_close_the_baseClient}
AuthClient authenticatedClient(
  Client baseClient,
  AccessCredentials credentials,
) {
  if (credentials.accessToken.type != 'Bearer') {
    throw ArgumentError('Only Bearer access tokens are accepted.');
  }
  return AuthenticatedClient(baseClient, credentials);
}

/// Creates an [AutoRefreshingAuthClient] which automatically refreshes
/// [credentials] before they expire.
///
/// {@template googleapis_auth_clientId_param}
/// The [clientId] that you obtain from the API Console
/// [Credentials page](https://console.developers.google.com/apis/credentials),
/// as described in
/// [Obtain OAuth 2.0 credentials](https://developers.google.com/identity/protocols/oauth2/openid-connect#getcredentials).
/// {@endtemplate}
///
/// Uses [baseClient] to make authenticated HTTP requests and to refresh
/// [credentials].
///
/// {@macro googleapis_auth_close_the_client}
/// {@macro googleapis_auth_not_close_the_baseClient}
AutoRefreshingAuthClient autoRefreshingClient(
  ClientId clientId,
  AccessCredentials credentials,
  Client baseClient,
) {
  if (credentials.accessToken.type != 'Bearer') {
    throw ArgumentError('Only Bearer access tokens are accepted.');
  }
  if (credentials.refreshToken == null) {
    throw ArgumentError('Refresh token in AccessCredentials was `null`.');
  }
  return AutoRefreshingClient(baseClient, clientId, credentials);
}

/// Obtains refreshed [AccessCredentials] for [clientId] and [credentials].
///
/// {@macro googleapis_auth_clientId_param}
///
/// {@macro googleapis_auth_client_for_creds}
Future<AccessCredentials> refreshCredentials(
  ClientId clientId,
  AccessCredentials credentials,
  Client client,
) async {
  final secret = clientId.secret;
  if (secret == null) {
    throw ArgumentError('clientId.secret cannot be null.');
  }

  final refreshToken = credentials.refreshToken;
  if (refreshToken == null) {
    throw ArgumentError('clientId.refreshToken cannot be null.');
  }

  // https://developers.google.com/identity/protocols/oauth2/native-app#offline
  final jsonMap = await client.oauthTokenRequest({
    'client_id': clientId.identifier,
    'client_secret': secret,
    'refresh_token': refreshToken,
    'grant_type': 'refresh_token',
  });

  final accessToken = parseAccessToken(jsonMap);

  final idToken = jsonMap['id_token'] as String?;

  return AccessCredentials(
    accessToken,
    credentials.refreshToken,
    credentials.scopes,
    idToken: idToken,
  );
}
