// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:googleapis_auth/src/known_uris.dart';
import 'package:googleapis_auth/src/oauth2_flows/authorization_code_grant_manual_flow.dart';
import 'package:googleapis_auth/src/oauth2_flows/authorization_code_grant_server_flow.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

typedef RequestHandler = Future<Response> Function(Request _);

final _browserFlowRedirectMatcher = predicate<String>((object) {
  if (object.startsWith('redirect_uri=')) {
    final url = Uri.parse(
        Uri.decodeComponent(object.substring('redirect_uri='.length)));
    expect(url.scheme, equals('http'));
    expect(url.host, equals('localhost'));
    return true;
  }
  return false;
});

void main() {
  final clientId = ClientId('id', 'secret');
  final scopes = ['s1', 's2'];

  // Validation + Responses from the authorization server.

  RequestHandler successFullResponse({required bool manual}) =>
      (Request request) async {
        expect(request.method, equals('POST'));
        expect(request.url, googleOauth2TokenEndpoint);
        expect(
          request.headers['content-type']!,
          startsWith('application/x-www-form-urlencoded'),
        );

        final pairs = request.body.split('&');
        expect(pairs, hasLength(6));

        expect(
          pairs,
          containsAll([
            'grant_type=authorization_code',
            'code=mycode',
            'client_id=id',
            'client_secret=secret',
            allOf(
              startsWith('code_verifier='),
              hasLength(142), // happens to be the output length as implemented!
            ),
            if (manual) 'redirect_uri=urn%3Aietf%3Awg%3Aoauth%3A2.0%3Aoob',
            if (!manual) _browserFlowRedirectMatcher
          ]),
        );

        final result = {
          'token_type': 'Bearer',
          'access_token': 'tokendata',
          'expires_in': 3600,
          'refresh_token': 'my-refresh-token',
          'id_token': 'my-id-token',
          'scope': 's1 s2',
        };
        return Response(
          jsonEncode(result),
          200,
          headers: jsonContentType,
        );
      };

  Future<Response> invalidResponse(Request request) async {
    // Missing expires_in field!
    final result = {
      'token_type': 'Bearer',
      'access_token': 'tokendata',
      'refresh_token': 'my-refresh-token',
      'id_token': 'my-id-token',
    };
    return Response(jsonEncode(result), 200, headers: jsonContentType);
  }

  // Validation functions for user prompt and access credentials.

  void validateAccessCredentials(AccessCredentials credentials) {
    expect(credentials.accessToken.data, equals('tokendata'));
    expect(credentials.accessToken.type, equals('Bearer'));
    expect(credentials.scopes, equals(['s1', 's2']));
    expect(credentials.refreshToken, equals('my-refresh-token'));
    expect(credentials.idToken, equals('my-id-token'));
    expectExpiryOneHourFromNow(credentials.accessToken);
  }

  Uri validateUserPromptUri(String url, {bool manual = false}) {
    final uri = Uri.parse(url);
    expect(uri.scheme, googleOauth2AuthorizationEndpoint.scheme);
    expect(uri.authority, googleOauth2AuthorizationEndpoint.authority);
    expect(uri.path, googleOauth2AuthorizationEndpoint.path);
    expect(uri.queryParameters, {
      'client_id': clientId.identifier,
      'response_type': 'code',
      'scope': 's1 s2',
      'redirect_uri': isNotEmpty,
      'code_challenge': hasLength(43),
      'code_challenge_method': 'S256',
      if (!manual) 'state': hasLength(32),
    });

    final redirectUri = Uri.parse(uri.queryParameters['redirect_uri']!);

    if (manual) {
      expect('$redirectUri', equals('urn:ietf:wg:oauth:2.0:oob'));
    } else {
      expect(uri.queryParameters['state'], isNotNull);
      expect(redirectUri.scheme, equals('http'));
      expect(redirectUri.host, equals('localhost'));
    }

    return redirectUri;
  }

  group('authorization-code-flow', () {
    group('manual-copy-paste', () {
      Future<String> manualUserPrompt(String url) async {
        validateUserPromptUri(url, manual: true);
        return 'mycode';
      }

      test('successful', () async {
        final flow = AuthorizationCodeGrantManualFlow(
          clientId,
          scopes,
          mockClient(successFullResponse(manual: true), expectClose: false),
          manualUserPrompt,
        );
        validateAccessCredentials(await flow.run());
      });

      test('user-exception', () async {
        // We use a TransportException here for convenience.
        Future<String> manualUserPromptError(String url) =>
            Future.error(TransportException());

        final flow = AuthorizationCodeGrantManualFlow(
          clientId,
          scopes,
          mockClient(successFullResponse(manual: true), expectClose: false),
          manualUserPromptError,
        );
        await expectLater(flow.run(), throwsA(isTransportException));
      });

      test('transport-exception', () async {
        final flow = AuthorizationCodeGrantManualFlow(
          clientId,
          scopes,
          transportFailure,
          manualUserPrompt,
        );
        await expectLater(flow.run(), throwsA(isTransportException));
      });

      test('invalid-server-response', () async {
        final flow = AuthorizationCodeGrantManualFlow(
          clientId,
          scopes,
          mockClient(invalidResponse, expectClose: false),
          manualUserPrompt,
        );
        await expectLater(flow.run(), throwsA(isServerRequestFailedException));
      });
    });

    group('http-server', () {
      Future<void> callRedirectionEndpoint(Uri authCodeCall) async {
        final ioClient = HttpClient();

        final closeMe = expectAsync0(ioClient.close);

        try {
          final request = await ioClient.getUrl(authCodeCall);
          final response = await request.close();
          await response.drain();
        } finally {
          closeMe();
        }
      }

      void userPrompt(String url) {
        final redirectUri = validateUserPromptUri(url);
        final authCodeCall = Uri(
            scheme: redirectUri.scheme,
            host: redirectUri.host,
            port: redirectUri.port,
            path: redirectUri.path,
            queryParameters: {
              'state': Uri.parse(url).queryParameters['state'],
              'code': 'mycode',
            });
        callRedirectionEndpoint(authCodeCall);
      }

      void userPromptInvalidAuthCodeCallback(String url) {
        final redirectUri = validateUserPromptUri(url);
        final authCodeCall = Uri(
            scheme: redirectUri.scheme,
            host: redirectUri.host,
            port: redirectUri.port,
            path: redirectUri.path,
            queryParameters: {
              'state': Uri.parse(url).queryParameters['state'],
              'error': 'failed to authenticate',
            });
        callRedirectionEndpoint(authCodeCall);
      }

      test('successful', () async {
        final flow = AuthorizationCodeGrantServerFlow(
          clientId,
          scopes,
          mockClient(successFullResponse(manual: false), expectClose: false),
          expectAsync1(userPrompt),
        );
        validateAccessCredentials(await flow.run());
      });

      test('transport-exception', () async {
        final flow = AuthorizationCodeGrantServerFlow(
          clientId,
          scopes,
          transportFailure,
          expectAsync1(userPrompt),
        );
        await expectLater(flow.run(), throwsA(isTransportException));
      });

      test('invalid-server-response', () async {
        final flow = AuthorizationCodeGrantServerFlow(
          clientId,
          scopes,
          mockClient(invalidResponse, expectClose: false),
          expectAsync1(userPrompt),
        );
        await expectLater(flow.run(), throwsA(isServerRequestFailedException));
      });

      test('failed-authentication', () async {
        final flow = AuthorizationCodeGrantServerFlow(
          clientId,
          scopes,
          mockClient(successFullResponse(manual: false), expectClose: false),
          expectAsync1(userPromptInvalidAuthCodeCallback),
        );
        await expectLater(flow.run(), throwsA(isUserConsentException));
      });
    }, testOn: '!browser');
  });
}
