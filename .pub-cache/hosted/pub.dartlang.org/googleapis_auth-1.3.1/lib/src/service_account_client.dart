// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:http/http.dart';

import 'oauth2_flows/base_flow.dart';
import 'oauth2_flows/jwt.dart';
import 'service_account_credentials.dart';

/// Obtain oauth2 [AccessCredentials] using service account credentials.
///
/// In case the service account has no access to the requested scopes or another
/// error occurs the returned future will complete with an `Exception`.
///
/// {@macro googleapis_auth_client_for_creds}
///
/// The [ServiceAccountCredentials] can be obtained in the Google Cloud Console.
Future<AccessCredentials> obtainAccessCredentialsViaServiceAccount(
  ServiceAccountCredentials clientCredentials,
  List<String> scopes,
  Client client,
) =>
    JwtFlow(
      clientCredentials.email,
      clientCredentials.privateRSAKey,
      clientCredentials.impersonatedUser,
      scopes,
      client,
    ).run();

/// Obtains oauth2 credentials and returns an authenticated HTTP client.
///
/// See [obtainAccessCredentialsViaServiceAccount] for specifics about the
/// arguments used for obtaining access credentials.
///
/// {@macro googleapis_auth_returned_auto_refresh_client}
///
/// {@macro googleapis_auth_baseClient_param}
///
/// {@macro googleapis_auth_close_the_client}
/// {@macro googleapis_auth_not_close_the_baseClient}
Future<AutoRefreshingAuthClient> clientViaServiceAccount(
  ServiceAccountCredentials clientCredentials,
  List<String> scopes, {
  Client? baseClient,
}) async =>
    await clientFromFlow(
      (c) => JwtFlow(
        clientCredentials.email,
        clientCredentials.privateRSAKey,
        clientCredentials.impersonatedUser,
        scopes,
        c,
      ),
      baseClient: baseClient,
    );
