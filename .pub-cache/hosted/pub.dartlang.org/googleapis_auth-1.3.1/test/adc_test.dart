@TestOn('vm')
library googleapis_auth.adc_test;

import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/src/adc_utils.dart'
    show fromApplicationsCredentialsFile;
import 'package:googleapis_auth/src/known_uris.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('fromApplicationsCredentialsFile', () async {
    final tmp = await Directory.systemTemp.createTemp('googleapis_auth-test');
    try {
      final credsFile = File.fromUri(tmp.uri.resolve('creds.json'));
      await credsFile.writeAsString(json.encode({
        'client_id': 'id',
        'client_secret': 'secret',
        'refresh_token': 'refresh',
        'type': 'authorized_user'
      }));
      final c = await fromApplicationsCredentialsFile(
        credsFile,
        'test-credentials-file',
        [],
        mockClient((Request request) async {
          final url = request.url;
          if (url == googleOauth2TokenEndpoint) {
            expect(request.method, equals('POST'));
            expect(
                request.body,
                equals('client_id=id&'
                    'client_secret=secret&'
                    'refresh_token=refresh&'
                    'grant_type=refresh_token'));
            final body = jsonEncode({
              'token_type': 'Bearer',
              'access_token': 'atoken',
              'expires_in': 3600,
            });
            return Response(body, 200, headers: jsonContentType);
          }
          if (url.toString() ==
              'https://storage.googleapis.com/b/bucket/o/obj') {
            expect(request.method, equals('GET'));
            expect(request.headers['Authorization'], equals('Bearer atoken'));
            expect(request.headers['X-Goog-User-Project'], isNull);
            return Response('hello world', 200);
          }
          return Response('bad', 404);
        }),
      );
      expect(c.credentials.accessToken.data, equals('atoken'));

      final r =
          await c.get(Uri.https('storage.googleapis.com', '/b/bucket/o/obj'));
      expect(r.statusCode, equals(200));
      expect(r.body, equals('hello world'));

      c.close();
    } finally {
      await tmp.delete(recursive: true);
    }
  });

  test('fromApplicationsCredentialsFile w. quota_project_id', () async {
    final tmp = await Directory.systemTemp.createTemp('googleapis_auth-test');
    try {
      final credsFile = File.fromUri(tmp.uri.resolve('creds.json'));
      await credsFile.writeAsString(json.encode({
        'client_id': 'id',
        'client_secret': 'secret',
        'refresh_token': 'refresh',
        'type': 'authorized_user',
        'quota_project_id': 'project'
      }));
      final c = await fromApplicationsCredentialsFile(
        credsFile,
        'test-credentials-file',
        [],
        mockClient((Request request) async {
          final url = request.url;
          if (url == googleOauth2TokenEndpoint) {
            expect(request.method, equals('POST'));
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
          if (url.toString() ==
              'https://storage.googleapis.com/b/bucket/o/obj') {
            expect(request.method, equals('GET'));
            expect(request.headers['Authorization'], equals('Bearer atoken'));
            expect(request.headers['X-Goog-User-Project'], equals('project'));
            return Response('hello world', 200);
          }
          return Response('bad', 404);
        }),
      );
      expect(c.credentials.accessToken.data, equals('atoken'));

      final r =
          await c.get(Uri.https('storage.googleapis.com', '/b/bucket/o/obj'));
      expect(r.statusCode, equals(200));
      expect(r.body, equals('hello world'));

      c.close();
    } finally {
      await tmp.delete(recursive: true);
    }
  });
}
