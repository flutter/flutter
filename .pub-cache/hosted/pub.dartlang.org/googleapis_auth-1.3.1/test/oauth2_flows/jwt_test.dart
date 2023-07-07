// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:googleapis_auth/src/known_uris.dart';
import 'package:googleapis_auth/src/oauth2_flows/jwt.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  Future<Response> successfulSignRequest(Request request) async {
    expect(request.method, equals('POST'));
    expect(request.url, googleOauth2TokenEndpoint);

    // We are not asserting what comes after '&assertion=' because this is
    // time dependent.
    expect(
        request.body,
        startsWith(
            'grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer'
            '&assertion='));
    final body = jsonEncode({
      'access_token': 'atok',
      'expires_in': 3600,
      'token_type': 'Bearer',
    });
    return Response(body, 200, headers: jsonContentType);
  }

  Future<Response> invalidAccessToken(Request request) async {
    final body = jsonEncode({
      // Missing 'expires_in' entry
      'access_token': 'atok',
      'token_type': 'Bearer',
    });
    return Response(body, 200, headers: jsonContentType);
  }

  group('jwt-flow', () {
    const clientEmail = 'a@b.com';
    final scopes = ['s1', 's2'];

    test('successful', () async {
      final flow = JwtFlow(
        clientEmail,
        testPrivateKey,
        null,
        scopes,
        mockClient(expectAsync1(successfulSignRequest), expectClose: false),
      );

      final credentials = await flow.run();
      expect(credentials.accessToken.data, equals('atok'));
      expect(credentials.accessToken.type, equals('Bearer'));
      expect(credentials.scopes, equals(['s1', 's2']));
      expectExpiryOneHourFromNow(credentials.accessToken);
    });

    test('successfull-with-user', () async {
      final flow = JwtFlow(clientEmail, testPrivateKey, 'x@y.com', scopes,
          mockClient(expectAsync1(successfulSignRequest), expectClose: false));

      final credentials = await flow.run();
      expect(credentials.accessToken.data, equals('atok'));
      expect(credentials.accessToken.type, equals('Bearer'));
      expect(credentials.scopes, equals(['s1', 's2']));
      expectExpiryOneHourFromNow(credentials.accessToken);
    });

    test('invalid-server-response', () {
      final flow = JwtFlow(
        clientEmail,
        testPrivateKey,
        null,
        scopes,
        mockClient(expectAsync1(invalidAccessToken), expectClose: false),
      );

      expect(flow.run(), throwsA(isServerRequestFailedException));
    });

    test('transport-failure', () {
      final flow =
          JwtFlow(clientEmail, testPrivateKey, null, scopes, transportFailure);

      expect(flow.run(), throwsA(isTransportException));
    });
  });
}
