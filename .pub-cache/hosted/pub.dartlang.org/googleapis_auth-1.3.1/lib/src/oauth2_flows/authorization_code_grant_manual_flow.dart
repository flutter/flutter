// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:http/http.dart' as http;

import '../access_credentials.dart';
import '../client_id.dart';
import '../typedefs.dart';
import 'auth_code.dart';
import 'authorization_code_grant_abstract_flow.dart';

/// Runs an oauth2 authorization code grant flow using manual Copy&Paste.
///
/// This class is able to run an oauth2 authorization flow. It takes a user
/// supplied function which will be called with an URI. The user is expected
/// to navigate to that URI and to grant access to the client.
///
/// Google will give the resource owner a code. The user supplied function needs
/// to complete with that code.
///
/// The authorization code will then be used to obtain access credentials.
class AuthorizationCodeGrantManualFlow
    extends AuthorizationCodeGrantAbstractFlow {
  final PromptUserForConsentManual userPrompt;

  AuthorizationCodeGrantManualFlow(
    ClientId clientId,
    List<String> scopes,
    http.Client client,
    this.userPrompt, {
    String? hostedDomain,
  }) : super(clientId, scopes, client, hostedDomain: hostedDomain);

  @override
  Future<AccessCredentials> run() async {
    final codeVerifier = createCodeVerifier();

    // Prompt user and wait until they goes to URL and copy&pastes the auth code
    // in.
    final code = await userPrompt(
      authenticationUri(
        _redirectionUri,
        codeVerifier: codeVerifier,
      ).toString(),
    );
    // Use code to obtain credentials
    return obtainAccessCredentialsUsingCodeImpl(
      code,
      _redirectionUri,
      codeVerifier: codeVerifier,
    );
  }
}

const _redirectionUri = 'urn:ietf:wg:oauth:2.0:oob';
