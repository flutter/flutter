// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:http/http.dart';

import 'access_credentials.dart';
import 'auth_client.dart';
import 'oauth2_flows/base_flow.dart';
import 'oauth2_flows/metadata_server.dart';

/// Obtain oauth2 [AccessCredentials] using the metadata API on ComputeEngine.
///
/// In case the VM was not configured with access to the requested scopes or an
/// error occurs the returned future will complete with an `Exception`.
///
/// {@template googleapis_auth_client_for_creds}
/// [client] will be used for making the HTTP requests needed to create the
/// returned [AccessCredentials].
/// {@endtemplate}
///
/// No credentials are needed. But this function is only intended to work on a
/// Google Compute Engine VM with configured access to Google APIs.
Future<AccessCredentials> obtainAccessCredentialsViaMetadataServer(
  Client client,
) =>
    MetadataServerAuthorizationFlow(client).run();

/// Obtains oauth2 credentials and returns an authenticated HTTP client.
///
/// See [obtainAccessCredentialsViaMetadataServer] for specifics about the
/// arguments used for obtaining access credentials.
///
/// {@macro googleapis_auth_returned_auto_refresh_client}
///
/// {@macro googleapis_auth_baseClient_param}
///
/// {@macro googleapis_auth_close_the_client}
/// {@macro googleapis_auth_not_close_the_baseClient}
Future<AutoRefreshingAuthClient> clientViaMetadataServer({
  Client? baseClient,
}) async =>
    await clientFromFlow(
      (c) => MetadataServerAuthorizationFlow(c),
      baseClient: baseClient,
    );
