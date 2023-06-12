// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../access_credentials.dart';
import '../client_id.dart';
import '../exceptions.dart';
import '../known_uris.dart';
import '../utils.dart';

Uri createAuthenticationUri({
  required String redirectUri,
  required String clientId,
  required Iterable<String> scopes,
  required String codeVerifier,
  String? hostedDomain,
  String? state,
  bool offline = false,
}) {
  final queryValues = {
    'client_id': clientId,
    'response_type': 'code',
    'redirect_uri': redirectUri,
    'scope': scopes.join(' '),
    'code_challenge': _codeVerifierShaEncode(codeVerifier),
    'code_challenge_method': 'S256',
    if (offline) 'access_type': 'offline',
    if (hostedDomain != null) 'hd': hostedDomain,
    if (state != null) 'state': state,
  };
  return googleOauth2AuthorizationEndpoint.replace(
    queryParameters: queryValues,
  );
}

/// https://developers.google.com/identity/protocols/oauth2/native-app#create-code-challenge
/// https://datatracker.ietf.org/doc/html/rfc7636#section-4.1
String createCodeVerifier() {
  final rnd = Random.secure();

  return List.generate(128, (index) => _safe[rnd.nextInt(_safe.length)]).join();
}

/// See https://developers.google.com/identity/protocols/oauth2/openid-connect#createxsrftoken
String randomState() {
  final rnd = Random.secure();

  final list = Uint32List(6);
  for (var i = 0; i < list.length; i++) {
    list[i] = rnd.nextInt(1 << 32);
  }

  final value = base64UrlEncode(Uint8List.view(list.buffer));
  return _stripBase64Equals(value);
}

// https://datatracker.ietf.org/doc/html/rfc3986#section-2.3
const _safe = '0123456789-._~'
    'abcdefghijklmnopqrstuvwxyz'
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

String _codeVerifierShaEncode(String codeVerifier) {
  final asciiBytes = ascii.encode(codeVerifier);
  final sha26Bytes = sha256.convert(asciiBytes).bytes;
  final output = base64UrlEncode(sha26Bytes);
  return _stripBase64Equals(output);
}

String _stripBase64Equals(String value) {
  while (value.endsWith('=')) {
    value = value.substring(0, value.length - 1);
  }
  return value;
}

/// Obtain oauth2 [AccessCredentials] by exchanging an authorization code.
///
/// Running a hybrid oauth2 flow as described in the
/// `googleapis_auth.auth_browser` library results in a `HybridFlowResult` which
/// contains short-lived [AccessCredentials] for the client and an authorization
/// code. This authorization code needs to be transferred to the server, which
/// can exchange it against long-lived [AccessCredentials].
///
/// {@macro googleapis_auth_client_for_creds}
///
/// {@macro googleapis_auth_clientId_param}
///
/// If the authorization code was obtained using the mentioned hybrid flow, the
/// [redirectUrl] must be `"postmessage"` (default).
///
/// If you obtained the authorization code using a different mechanism, the
/// [redirectUrl] must be the same that was used to obtain the code.
///
/// NOTE: Only the server application will know the `client secret` - which is
/// necessary to exchange an authorization code against access tokens.
///
/// NOTE: It is important to transmit the authorization code in a secure manner
/// to the server. You should use "anti-request forgery state tokens" to guard
/// against "cross site request forgery" attacks.
Future<AccessCredentials> obtainAccessCredentialsViaCodeExchange(
  http.Client client,
  ClientId clientId,
  String code, {
  String redirectUrl = 'postmessage',
  String? codeVerifier,
}) async {
  final jsonMap = await client.oauthTokenRequest(
    {
      'client_id': clientId.identifier,
      'client_secret': clientId.secret ?? '',
      'code': code,
      if (codeVerifier != null) 'code_verifier': codeVerifier,
      'grant_type': 'authorization_code',
      'redirect_uri': redirectUrl,
    },
  );
  final accessToken = parseAccessToken(jsonMap);

  final idToken = jsonMap['id_token'] as String?;
  final refreshToken = jsonMap['refresh_token'] as String?;

  final scope = jsonMap['scope'];
  if (scope is! String) {
    throw ServerRequestFailedException(
      'The response did not include a `scope` value of type `String`.',
      responseContent: json,
    );
  }
  final scopes = scope.split(' ').toList();

  return AccessCredentials(
    accessToken,
    refreshToken,
    scopes,
    idToken: idToken,
  );
}

List<String> parseScopes(Map<String, dynamic> json) {
  final scope = json['scope'];
  if (scope is! String) {
    throw ServerRequestFailedException(
      'The response did not include a `scope` value of type `String`.',
      responseContent: json,
    );
  }
  return scope.split(' ').toList();
}
