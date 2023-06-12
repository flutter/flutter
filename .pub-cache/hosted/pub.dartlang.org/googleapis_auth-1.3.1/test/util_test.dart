@Timeout(Duration(seconds: 2))
import 'dart:convert';

import 'package:googleapis_auth/src/utils.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('not valid UTF-8', () async {
    const body = [
      // https://man7.org/linux/man-pages/man7/utf-8.7.html
      // 0xC0 is never used in UTF8-encoding!
      0xC0,
    ];
    final client = mockClient(
      (request) async => Response.bytes(body, 200, headers: jsonContentType),
      expectClose: false,
    );

    await expectLater(
      client.requestJson(Request('GET', Uri.parse('localhost:8080')), 'bob'),
      throwsA(
        isServerRequestFailedException
            .having(
              (p0) => p0.message,
              'message',
              contains('The response was not valid UTF-8.'),
            )
            .having(
              (p0) => p0.responseContent,
              'responseContent',
              body,
            ),
      ),
    );
  });

  test('not JSON', () async {
    const body = 'this is not good json!';
    final client = mockClient(
      (request) async => Response(body, 200, headers: jsonContentType),
      expectClose: false,
    );

    await expectLater(
      client.requestJson(Request('GET', Uri.parse('localhost:8080')), 'bob'),
      throwsA(
        isServerRequestFailedException
            .having(
              (p0) => p0.message,
              'message',
              contains('Could not decode the response as JSON.'),
            )
            .having(
              (p0) => p0.responseContent,
              'responseContent',
              body,
            ),
      ),
    );
  });

  test('not a map', () async {
    final body = [];
    final client = mockClient(
      (request) async =>
          Response(jsonEncode(body), 200, headers: jsonContentType),
      expectClose: false,
    );

    await expectLater(
      client.requestJson(Request('GET', Uri.parse('localhost:8080')), 'bob'),
      throwsA(
        isServerRequestFailedException
            .having(
              (p0) => p0.message,
              'message',
              'The returned JSON response was not a Map.',
            )
            .having(
              (p0) => p0.responseContent,
              'responseContent',
              body,
            ),
      ),
    );
  });

  test('invalid-server-status-code', () async {
    final client = mockClient(
      (request) async =>
          Response(jsonEncode({}), 500, headers: jsonContentType),
      expectClose: false,
    );

    await expectLater(
      client.requestJson(Request('GET', Uri.parse('localhost:8080')), 'bob'),
      throwsA(
        isServerRequestFailedException.having(
          (p0) => p0.statusCode,
          'statusCode',
          500,
        ),
      ),
    );
  });
}
