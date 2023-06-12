// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../access_credentials.dart';
import '../client_id.dart';
import '../exceptions.dart';
import '../typedefs.dart';
import 'auth_code.dart';
import 'authorization_code_grant_abstract_flow.dart';

/// Runs an oauth2 authorization code grant flow using an HTTP server.
///
/// This class is able to run an oauth2 authorization flow. It takes a user
/// supplied function which will be called with an URI. The user is expected
/// to navigate to that URI and to grant access to the client.
///
/// Once the user has granted access to the client, Google will redirect the
/// user agent to a URL pointing to a locally running HTTP server. Which in turn
/// will be able to extract the authorization code from the URL and use it to
/// obtain access credentials.
class AuthorizationCodeGrantServerFlow
    extends AuthorizationCodeGrantAbstractFlow {
  final PromptUserForConsent userPrompt;

  AuthorizationCodeGrantServerFlow(
    ClientId clientId,
    List<String> scopes,
    http.Client client,
    this.userPrompt, {
    String? hostedDomain,
  }) : super(clientId, scopes, client, hostedDomain: hostedDomain);

  @override
  Future<AccessCredentials> run() async {
    final server = await HttpServer.bind('localhost', 0);

    try {
      final port = server.port;
      final redirectionUri = 'http://localhost:$port';
      final state = randomState();
      final codeVerifier = createCodeVerifier();

      // Prompt user and wait until they goes to URL and the google
      // authorization server calls back to our locally running HTTP server.
      userPrompt(
        authenticationUri(
          redirectionUri,
          state: state,
          codeVerifier: codeVerifier,
        ).toString(),
      );

      final request = await server.first;
      final uri = request.uri;

      try {
        if (request.method != 'GET') {
          throw Exception(
            'Invalid response from server '
            '(expected GET request callback, got: ${request.method}).',
          );
        }

        final returnedState = uri.queryParameters['state'];
        if (state != returnedState) {
          throw Exception(
            'Invalid response from server (state did not match).',
          );
        }

        final error = uri.queryParameters['error'];
        if (error != null) {
          throw UserConsentException(
            'Error occurred while obtaining access credentials: $error',
          );
        }

        final code = uri.queryParameters['code'];
        if (code == null || code.isEmpty) {
          throw Exception(
            'Invalid response from server (no auth code transmitted).',
          );
        }
        final credentials = await obtainAccessCredentialsUsingCodeImpl(
          code,
          redirectionUri,
          codeVerifier: codeVerifier,
        );

        // TODO: We could introduce a user-defined redirect page.
        request.response
          ..statusCode = 200
          ..headers.set('content-type', 'text/html; charset=UTF-8')
          ..write(
            '''
<!DOCTYPE html>

<html>
  <head>
    <meta charset="utf-8">
    <title>Authorization successful.</title>
  </head>

  <body>
    <h2 style="text-align: center">Application has successfully obtained access credentials</h2>
    <p style="text-align: center">This window can be closed now.</p>
  </body>
</html>''',
          );
        await request.response.close();
        return credentials;
      } catch (e) {
        request.response.statusCode = 500;
        await request.response.close().catchError((_) {});
        rethrow;
      }
    } finally {
      await server.close();
    }
  }
}
