// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:http/http.dart';

import 'src/adc_utils.dart';
import 'src/auth_http_utils.dart';
import 'src/http_client_base.dart';
import 'src/metadata_server_client.dart' show clientViaMetadataServer;
import 'src/oauth2_flows/authorization_code_grant_manual_flow.dart';
import 'src/oauth2_flows/authorization_code_grant_server_flow.dart';
import 'src/service_account_credentials.dart';
import 'src/typedefs.dart';

export 'googleapis_auth.dart';
export 'src/metadata_server_client.dart';
export 'src/oauth2_flows/auth_code.dart'
    show obtainAccessCredentialsViaCodeExchange;
export 'src/service_account_client.dart';
export 'src/typedefs.dart';

/// Create a client using
/// [Application Default Credentials](https://cloud.google.com/docs/authentication/production).
///
/// Looks for credentials in the following order of preference:
///  1. A JSON file whose path is specified by `GOOGLE_APPLICATION_CREDENTIALS`,
///     this file typically contains [exported service account keys][svc-keys].
///  2. A JSON file created by
///     [`gcloud auth application-default login`][gcloud-login]
///     in a well-known location (`%APPDATA%/gcloud/application_default_credentials.json`
///     on Windows and `$HOME/.config/gcloud/application_default_credentials.json` on Linux/Mac).
///  3. On Google Compute Engine and App Engine Flex we fetch credentials from
///     [GCE metadata service][metadata].
///
/// [metadata]: https://cloud.google.com/compute/docs/storing-retrieving-metadata
/// [svc-keys]: https://cloud.google.com/docs/authentication/getting-started
/// [gcloud-login]: https://cloud.google.com/sdk/gcloud/reference/auth/application-default/login
///
/// {@macro googleapis_auth_baseClient_param}
///
/// {@macro googleapis_auth_returned_auto_refresh_client}
Future<AutoRefreshingAuthClient> clientViaApplicationDefaultCredentials({
  required List<String> scopes,
  Client? baseClient,
}) async {
  if (baseClient == null) {
    baseClient = Client();
  } else {
    baseClient = nonClosingClient(baseClient);
  }

  // If env var specifies a file to load credentials from we'll do that.
  final credsEnv = Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'];
  if (credsEnv != null && credsEnv.isNotEmpty) {
    // If env var is specific and not empty, we always try to load, even if
    // the file doesn't exist.
    return await fromApplicationsCredentialsFile(
      File(credsEnv),
      'GOOGLE_APPLICATION_CREDENTIALS',
      scopes,
      baseClient,
    );
  }

  // Attempt to use file created by `gcloud auth application-default login`
  File credFile;
  if (Platform.isWindows) {
    credFile = File.fromUri(
      Uri.directory(Platform.environment['APPDATA']!)
          .resolve('gcloud/application_default_credentials.json'),
    );
  } else {
    credFile = File.fromUri(
      Uri.directory(Platform.environment['HOME']!)
          .resolve('.config/gcloud/application_default_credentials.json'),
    );
  }
  // Only try to load from credFile if it exists.
  if (await credFile.exists()) {
    return await fromApplicationsCredentialsFile(
      credFile,
      '`gcloud auth application-default login`',
      scopes,
      baseClient,
    );
  }

  return await clientViaMetadataServer(baseClient: baseClient);
}

/// Obtains oauth2 credentials and returns an authenticated HTTP client.
///
/// See [obtainAccessCredentialsViaUserConsent] for specifics about the
/// arguments used for obtaining access credentials.
///
/// {@macro googleapis_auth_clientId_param}
///
/// {@macro googleapis_auth_returned_auto_refresh_client}
///
/// {@macro googleapis_auth_baseClient_param}
///
/// {@template googleapis_auth_hostedDomain_param}
/// If provided, restricts sign-in to Google Apps hosted accounts at
/// [hostedDomain]. For more details, see
/// https://developers.google.com/identity/protocols/oauth2/openid-connect#hd-param
/// {@endtemplate}
///
/// {@macro googleapis_auth_close_the_client}
/// {@macro googleapis_auth_not_close_the_baseClient}
Future<AutoRefreshingAuthClient> clientViaUserConsent(
  ClientId clientId,
  List<String> scopes,
  PromptUserForConsent userPrompt, {
  Client? baseClient,
  String? hostedDomain,
}) async {
  var closeUnderlyingClient = false;
  if (baseClient == null) {
    baseClient = Client();
    closeUnderlyingClient = true;
  }

  final flow = AuthorizationCodeGrantServerFlow(
    clientId,
    scopes,
    baseClient,
    userPrompt,
    hostedDomain: hostedDomain,
  );

  AccessCredentials credentials;

  try {
    credentials = await flow.run();
  } catch (e) {
    if (closeUnderlyingClient) {
      baseClient.close();
    }
    rethrow;
  }
  return AutoRefreshingClient(
    baseClient,
    clientId,
    credentials,
    closeUnderlyingClient: closeUnderlyingClient,
  );
}

/// Obtains oauth2 credentials and returns an authenticated HTTP client.
///
/// See [obtainAccessCredentialsViaUserConsentManual] for specifics about the
/// arguments used for obtaining access credentials.
///
/// {@macro googleapis_auth_clientId_param}
///
/// {@macro googleapis_auth_returned_auto_refresh_client}
///
/// {@macro googleapis_auth_baseClient_param}
///
/// {@macro googleapis_auth_hostedDomain_param}
///
/// {@macro googleapis_auth_close_the_client}
/// {@macro googleapis_auth_not_close_the_baseClient}
Future<AutoRefreshingAuthClient> clientViaUserConsentManual(
  ClientId clientId,
  List<String> scopes,
  PromptUserForConsentManual userPrompt, {
  Client? baseClient,
  String? hostedDomain,
}) async {
  var closeUnderlyingClient = false;
  if (baseClient == null) {
    baseClient = Client();
    closeUnderlyingClient = true;
  }

  final flow = AuthorizationCodeGrantManualFlow(
    clientId,
    scopes,
    baseClient,
    userPrompt,
    hostedDomain: hostedDomain,
  );

  AccessCredentials credentials;

  try {
    credentials = await flow.run();
  } catch (e) {
    if (closeUnderlyingClient) {
      baseClient.close();
    }
    rethrow;
  }

  return AutoRefreshingClient(
    baseClient,
    clientId,
    credentials,
    closeUnderlyingClient: closeUnderlyingClient,
  );
}

/// Obtain oauth2 [AccessCredentials] using the oauth2 authentication code flow.
///
/// {@macro googleapis_auth_clientId_param}
///
/// [userPrompt] will be used for directing the user/user-agent to a URI. See
/// [PromptUserForConsent] for more information.
///
/// {@macro googleapis_auth_client_for_creds}
///
/// {@macro googleapis_auth_hostedDomain_param}
///
/// {@macro googleapis_auth_user_consent_return}
Future<AccessCredentials> obtainAccessCredentialsViaUserConsent(
  ClientId clientId,
  List<String> scopes,
  Client client,
  PromptUserForConsent userPrompt, {
  String? hostedDomain,
}) =>
    AuthorizationCodeGrantServerFlow(
      clientId,
      scopes,
      client,
      userPrompt,
      hostedDomain: hostedDomain,
    ).run();

/// Obtain oauth2 [AccessCredentials] using the oauth2 authentication code flow.
///
/// {@macro googleapis_auth_clientId_param}
///
/// [userPrompt] will be used for directing the user/user-agent to a URI. See
/// [PromptUserForConsentManual] for more information.
///
/// {@macro googleapis_auth_client_for_creds}
///
/// {@macro googleapis_auth_hostedDomain_param}
///
/// {@macro googleapis_auth_user_consent_return}
Future<AccessCredentials> obtainAccessCredentialsViaUserConsentManual(
  ClientId clientId,
  List<String> scopes,
  Client client,
  PromptUserForConsentManual userPrompt, {
  String? hostedDomain,
}) =>
    AuthorizationCodeGrantManualFlow(
      clientId,
      scopes,
      client,
      userPrompt,
      hostedDomain: hostedDomain,
    ).run();
