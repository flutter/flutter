// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library googleapis_auth.metadata_server;

import 'dart:async';
import 'dart:convert';

import 'package:googleapis_auth/src/oauth2_flows/metadata_server.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  const apiUrl = 'http://metadata.google.internal/computeMetadata/v1';
  const apiHeaderKey = 'Metadata-Flavor';
  const apiHeaderValue = 'Google';
  const tokenUrl = '$apiUrl/instance/service-accounts/default/token';
  const scopesUrl = '$apiUrl/instance/service-accounts/default/scopes';

  Future<Response> successfulAccessToken(Request request) async {
    expect(request.method, equals('GET'));
    expect(request.url.toString(), equals(tokenUrl));
    expect(request.headers[apiHeaderKey], equals(apiHeaderValue));

    final body = jsonEncode({
      'access_token': 'atok',
      'expires_in': 3600,
      'token_type': 'Bearer',
    });
    return Response(body, 200, headers: jsonContentType);
  }

  Future<Response> invalidAccessToken(Request request) async {
    expect(request.method, equals('GET'));
    expect(request.url.toString(), equals(tokenUrl));
    expect(request.headers[apiHeaderKey], equals(apiHeaderValue));

    final body = jsonEncode({
      // Missing 'expires_in' entry
      'access_token': 'atok',
      'token_type': 'Bearer',
    });
    return Response(body, 200, headers: jsonContentType);
  }

  Future<Response> successfulScopes(Request request) {
    expect(request.method, equals('GET'));
    expect(request.url.toString(), equals(scopesUrl));
    expect(request.headers[apiHeaderKey], equals(apiHeaderValue));

    return Future.value(Response('s1\ns2', 200));
  }

  group('metadata-server-authorization-flow', () {
    test('successful', () async {
      final flow = MetadataServerAuthorizationFlow(mockClient(
          expectAsync1((request) {
            final url = request.url.toString();
            if (url == tokenUrl) {
              return successfulAccessToken(request);
            } else if (url == scopesUrl) {
              return successfulScopes(request);
            } else {
              fail('Invalid URL $url (expected: $tokenUrl or $scopesUrl).');
            }
          }, count: 2),
          expectClose: false));

      final credentials = await flow.run();
      expect(credentials.accessToken.data, equals('atok'));
      expect(credentials.accessToken.type, equals('Bearer'));
      expect(credentials.scopes, equals(['s1', 's2']));
      expectExpiryOneHourFromNow(credentials.accessToken);
    });

    test('invalid-server-response', () {
      var requestNr = 0;
      final flow = MetadataServerAuthorizationFlow(mockClient(
          expectAsync1((request) {
            if (requestNr++ == 0) {
              return invalidAccessToken(request);
            } else {
              return successfulScopes(request);
            }
          }, count: 2),
          expectClose: false));
      expect(flow.run(), throwsA(isServerRequestFailedException));
    });

    test('token-transport-error', () {
      var requestNr = 0;
      final flow = MetadataServerAuthorizationFlow(mockClient(
          expectAsync1((request) {
            if (requestNr++ == 0) {
              return transportFailure.get(Uri.http('failure', ''));
            } else {
              return successfulScopes(request);
            }
          }, count: 2),
          expectClose: false));
      expect(flow.run(), throwsA(isTransportException));
    });

    test('scopes-transport-error', () {
      var requestNr = 0;
      final flow = MetadataServerAuthorizationFlow(mockClient(
          expectAsync1((request) {
            if (requestNr++ == 0) {
              return successfulAccessToken(request);
            } else {
              return transportFailure.get(Uri.http('failure', ''));
            }
          }, count: 2),
          expectClose: false));
      expect(flow.run(), throwsA(isTransportException));
    });
  });
}
