// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:googleapis_auth/src/http_client_base.dart';
import 'package:googleapis_auth/src/known_uris.dart';
import 'package:googleapis_auth/src/utils.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

final _defaultResponse = Response('', 500);

Future<Response> _defaultResponseHandler(Request _) async => _defaultResponse;

void main() {
  test('access-token', () {
    final expiry = DateTime.now().subtract(const Duration(seconds: 1));
    final expiryUtc = expiry.toUtc();

    expect(() => AccessToken('foo', 'bar', expiry), throwsArgumentError);

    final token = AccessToken('foo', 'bar', expiryUtc);
    expect(token.type, equals('foo'));
    expect(token.data, equals('bar'));
    expect(token.expiry, equals(expiryUtc));
    expect(token.hasExpired, isTrue);

    final nonExpiredToken =
        AccessToken('foo', 'bar', expiryUtc.add(const Duration(days: 1)));
    expect(nonExpiredToken.hasExpired, isFalse);
  });

  test('access-credentials', () {
    final expiry = DateTime.now().add(const Duration(days: 1)).toUtc();
    final aToken = AccessToken('foo', 'bar', expiry);

    final credentials = AccessCredentials(aToken, 'refresh', ['scope']);
    expect(credentials.accessToken, equals(aToken));
    expect(credentials.refreshToken, equals('refresh'));
    expect(credentials.scopes, equals(['scope']));
  });

  test('client-id', () {
    final clientId = ClientId('id', 'secret');
    expect(clientId.identifier, equals('id'));
    expect(clientId.secret, equals('secret'));
  });

  group('service-account-credentials', () {
    final clientId = ClientId.serviceAccount('id');

    const credentials = {
      'private_key_id': '301029',
      'private_key': testPrivateKeyString,
      'client_email': 'a@b.com',
      'client_id': 'myid',
      'type': 'service_account'
    };

    test('from-valid-individual-params', () {
      final credentials =
          ServiceAccountCredentials('email', clientId, testPrivateKeyString);
      expect(credentials.email, equals('email'));
      expect(credentials.clientId, equals(clientId));
      expect(credentials.privateKey, equals(testPrivateKeyString));
      expect(credentials.impersonatedUser, isNull);
    });

    test('from-valid-individual-params-with-user', () {
      final credentials = ServiceAccountCredentials(
          'email', clientId, testPrivateKeyString,
          impersonatedUser: 'x@y.com');
      expect(credentials.email, equals('email'));
      expect(credentials.clientId, equals(clientId));
      expect(credentials.privateKey, equals(testPrivateKeyString));
      expect(credentials.impersonatedUser, equals('x@y.com'));
    });

    test('from-json-string', () {
      final credentialsFromJson =
          ServiceAccountCredentials.fromJson(jsonEncode(credentials));
      expect(credentialsFromJson.email, equals('a@b.com'));
      expect(credentialsFromJson.clientId.identifier, equals('myid'));
      expect(credentialsFromJson.clientId.secret, isNull);
      expect(credentialsFromJson.privateKey, equals(testPrivateKeyString));
      expect(credentialsFromJson.impersonatedUser, isNull);
    });

    test('from-json-string-with-user', () {
      final credentialsFromJson = ServiceAccountCredentials.fromJson(
          jsonEncode(credentials),
          impersonatedUser: 'x@y.com');
      expect(credentialsFromJson.email, equals('a@b.com'));
      expect(credentialsFromJson.clientId.identifier, equals('myid'));
      expect(credentialsFromJson.clientId.secret, isNull);
      expect(credentialsFromJson.privateKey, equals(testPrivateKeyString));
      expect(credentialsFromJson.impersonatedUser, equals('x@y.com'));
    });

    test('from-json-map', () {
      final credentialsFromJson =
          ServiceAccountCredentials.fromJson(credentials);
      expect(credentialsFromJson.email, equals('a@b.com'));
      expect(credentialsFromJson.clientId.identifier, equals('myid'));
      expect(credentialsFromJson.clientId.secret, isNull);
      expect(credentialsFromJson.privateKey, equals(testPrivateKeyString));
      expect(credentialsFromJson.impersonatedUser, isNull);
    });

    test('from-json-map-with-user', () {
      final credentialsFromJson = ServiceAccountCredentials.fromJson(
          credentials,
          impersonatedUser: 'x@y.com');
      expect(credentialsFromJson.email, equals('a@b.com'));
      expect(credentialsFromJson.clientId.identifier, equals('myid'));
      expect(credentialsFromJson.clientId.secret, isNull);
      expect(credentialsFromJson.privateKey, equals(testPrivateKeyString));
      expect(credentialsFromJson.impersonatedUser, equals('x@y.com'));
    });
  });

  group('client-wrappers', () {
    final clientId = ClientId('id', 'secret');
    final tomorrow = DateTime.now().add(const Duration(days: 1)).toUtc();
    final yesterday = DateTime.now().subtract(const Duration(days: 1)).toUtc();
    final aToken = AccessToken('Bearer', 'bar', tomorrow);
    final credentials = AccessCredentials(aToken, 'refresh', ['s1', 's2']);

    Future<Response> successfulRefresh(Request request) async {
      expect(request.method, equals('POST'));
      expect(request.url, googleOauth2TokenEndpoint);
      expect(
        request.body,
        equals(
          'client_id=id&'
          'client_secret=secret&'
          'refresh_token=refresh&'
          'grant_type=refresh_token',
        ),
      );
      final body = jsonEncode({
        'token_type': 'Bearer',
        'access_token': 'atoken',
        'expires_in': 3600,
      });

      return Response(body, 200, headers: jsonContentType);
    }

    Future<Response> refreshErrorResponse(Request request) async {
      final body = jsonEncode({'error': 'An error occurred'});
      return Response(body, 400, headers: jsonContentType);
    }

    Future<Response> serverError(Request request) =>
        Future<Response>.error(Exception('transport layer exception'));

    test('refreshCredentials-successful', () async {
      final newCredentials = await refreshCredentials(clientId, credentials,
          mockClient(expectAsync1(successfulRefresh), expectClose: false));
      final expectedResultUtc = DateTime.now()
          .toUtc()
          .add(const Duration(seconds: 3600 - maxExpectedTimeDiffInSeconds));

      final accessToken = newCredentials.accessToken;
      expect(accessToken.type, equals('Bearer'));
      expect(accessToken.data, equals('atoken'));
      expect(accessToken.expiry.difference(expectedResultUtc).inSeconds,
          equals(0));

      expect(newCredentials.refreshToken, equals('refresh'));
      expect(newCredentials.scopes, equals(['s1', 's2']));
    });

    test('refreshCredentials-http-error', () async {
      await expectLater(
        refreshCredentials(
          clientId,
          credentials,
          mockClient(serverError, expectClose: false),
        ),
        throwsA(
          isA<Exception>().having(
            (p0) => p0.toString(),
            'toString',
            'Exception: transport layer exception',
          ),
        ),
      );
    });

    test('refreshCredentials-error-response', () async {
      await expectLater(
        refreshCredentials(
          clientId,
          credentials,
          mockClient(refreshErrorResponse, expectClose: false),
        ),
        throwsA(isServerRequestFailedException),
      );
    });

    group('authenticatedClient', () {
      final url = Uri.parse('http://www.example.com');

      test('successful', () async {
        final client = authenticatedClient(
          mockClient(expectAsync1((request) async {
            expect(request.method, equals('POST'));
            expect(request.url, equals(url));
            expect(request.headers.length, equals(1));
            expect(request.headers['Authorization'], equals('Bearer bar'));

            return Response('', 204);
          }), expectClose: false),
          credentials,
        );
        expect(client.credentials, equals(credentials));

        final response = await client.send(RequestImpl('POST', url));
        expect(response.statusCode, equals(204));
      });

      test('access-denied', () {
        final client = authenticatedClient(
          mockClient(expectAsync1((request) async {
            expect(request.method, equals('POST'));
            expect(request.url, equals(url));
            expect(request.headers.length, equals(1));
            expect(request.headers['Authorization'], equals('Bearer bar'));

            const headers = {'www-authenticate': 'foobar'};
            return Response('', 401, headers: headers);
          }), expectClose: false),
          credentials,
        );
        expect(client.credentials, equals(credentials));

        expect(client.send(RequestImpl('POST', url)),
            throwsA(isAccessDeniedException));
      });

      test('non-bearer-token', () {
        final aToken = credentials.accessToken;
        final nonBearerCredentials = AccessCredentials(
            AccessToken('foobar', aToken.data, aToken.expiry),
            'refresh',
            ['s1', 's2']);

        expect(
          () => authenticatedClient(
            mockClient(_defaultResponseHandler, expectClose: false),
            nonBearerCredentials,
          ),
          throwsA(isArgumentError),
        );
      });
    });

    group('autoRefreshingClient', () {
      final url = Uri.parse('http://www.example.com');

      test('up-to-date', () async {
        final client = autoRefreshingClient(
          clientId,
          credentials,
          mockClient(
            expectAsync1((request) async => Response('', 200)),
            expectClose: false,
          ),
        );
        expect(client.credentials, equals(credentials));

        final response = await client.send(RequestImpl('POST', url));
        expect(response.statusCode, equals(200));
      });

      test('no-refresh-token', () {
        final credentials = AccessCredentials(
            AccessToken('Bearer', 'bar', yesterday), null, ['s1', 's2']);

        expect(
          () => autoRefreshingClient(
            clientId,
            credentials,
            mockClient(_defaultResponseHandler, expectClose: false),
          ),
          throwsA(isArgumentError),
        );
      });

      test('refresh-failed', () {
        final credentials = AccessCredentials(
            AccessToken('Bearer', 'bar', yesterday), 'refresh', ['s1', 's2']);

        final client = autoRefreshingClient(
          clientId,
          credentials,
          mockClient(expectAsync1((request) {
            // This should be a refresh request.
            expect(request.headers['foo'], isNull);
            return refreshErrorResponse(request);
          }), expectClose: false),
        );
        expect(client.credentials, equals(credentials));

        final request = RequestImpl('POST', url);
        request.headers.addAll({'foo': 'bar'});
        expect(client.send(request), throwsA(isServerRequestFailedException));
      });

      test('invalid-content-type', () {
        final credentials = AccessCredentials(
            AccessToken('Bearer', 'bar', yesterday), 'refresh', ['s1', 's2']);

        final client = autoRefreshingClient(
          clientId,
          credentials,
          mockClient(expectAsync1((request) async {
            // This should be a refresh request.
            expect(request.headers['foo'], isNull);
            final headers = {'content-type': 'image/png'};

            return Response('', 200, headers: headers);
          }), expectClose: false),
        );
        expect(client.credentials, equals(credentials));

        final request = RequestImpl('POST', url);
        request.headers.addAll({'foo': 'bar'});
        expect(client.send(request), throwsA(isServerRequestFailedException));
      });

      test('successful-refresh', () async {
        var serverInvocation = 0;

        final credentials = AccessCredentials(
            AccessToken('Bearer', 'bar', yesterday), 'refresh', ['s1']);

        final client = autoRefreshingClient(
            clientId,
            credentials,
            mockClient(
              expectAsync1(
                (request) async {
                  if (serverInvocation++ == 0) {
                    // This should be a refresh request.
                    expect(request.headers['foo'], isNull);
                    return successfulRefresh(request);
                  } else {
                    // This is the real request.
                    expect(request.headers['foo'], equals('bar'));
                    return Response('', 200);
                  }
                },
                count: 2,
              ),
            ));
        expect(client.credentials, equals(credentials));

        var executed = false;
        client.credentialUpdates.listen(
          expectAsync1((newCredentials) {
            expect(newCredentials.accessToken.type, equals('Bearer'));
            expect(newCredentials.accessToken.data, equals('atoken'));
            executed = true;
          }),
          onDone: expectAsync0(() {}),
        );

        final request = RequestImpl('POST', url);
        request.headers.addAll({'foo': 'bar'});

        final response = await client.send(request);
        expect(response.statusCode, equals(200));

        // The `client.send()` will have triggered a credentials refresh.
        expect(executed, isTrue);

        client.close();
      });
    });
  });
}
