// Copyright 2020 terrier989@gmail.com.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

part of main_test;

class _HttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw StateError('ERROR');
  }
}

void _testHttpClient({required bool isBrowser}) async {
  group('HttpOverrides', () {
    setUp(() {
      HttpOverrides.global = _HttpOverrides();
    });
    tearDown(() {
      HttpOverrides.global = null;
    });
    test('findProxyFromEnvironment', () {
      final proxy = HttpClient.findProxyFromEnvironment(
        Uri.parse('http://example/path'),
      );
      expect(proxy, 'DIRECT');
    });
    test('createHttpClient', () {
      expect(() => HttpClient(), throwsStateError);
    });
  });

  group('HttpClient:', () {
    test('In VM: does NOT implement BrowserHttpClient', () async {
      final client = HttpClient();
      expect(client, isNot(isA<BrowserHttpClient>()));
    }, testOn: '!browser');

    test('In browser: does implement BrowserHttpClient', () async {
      final client = HttpClient();
      expect(client, isA<BrowserHttpClient>());
      if (client is BrowserHttpClient) {
        expect(client.onBrowserHttpClientRequestClose, isNull);
      }
    }, testOn: 'browser');

    test('In browser: requests implement BrowserHttpClientRequest', () async {
      final client = HttpClient();
      if (client is BrowserHttpClient) {
        client.onBrowserHttpClientRequestClose = expectAsync1(
          (request) {
            request.browserResponseType = 'text';
          },
          count: 1,
        );
      }
      final request = await client.openUrl(
        'GET',
        Uri.parse('http://localhost:$serverPort/greeting'),
      );
      expect(request, isA<BrowserHttpClientRequest>());
      if (request is BrowserHttpClientRequest) {
        expect(request.browserCredentialsMode, isFalse);
        expect(request.browserResponseType, isNull);
        await request.close();
        expect(request.browserCredentialsMode, isFalse);
        expect(request.browserResponseType, 'text');
      }
    }, testOn: 'browser');

    test('findProxyFromEnvironment', () {
      final proxy = HttpClient.findProxyFromEnvironment(
        Uri.parse('http://example/path'),
      );
      expect(proxy, 'DIRECT');
    });

    test('Non-existing server leads to SocketException', () async {
      final httpClient = HttpClient();
      final httpRequestFuture =
          httpClient.getUrl(Uri.parse('http://localhost:23456'));
      if (!isBrowser) {
        await expectLater(
            () => httpRequestFuture, throwsA(TypeMatcher<SocketException>()));
        return;
      }
      final httpRequest = await httpRequestFuture;
      final httpResponseFuture = httpRequest.close();
      await expectLater(
          () => httpResponseFuture, throwsA(TypeMatcher<SocketException>()));
    });

    test('GET', () async {
      await _testClient(
        request: _Request(
          method: 'GET',
          path: '/greeting',
        ),
        expectedResponse: _ExpectedResponse(
          body: 'Hello world! (GET)',
        ),
      );
    });

    test('GET (multiple chunks)', () async {
      // Send HTTP request
      final client = HttpClient();
      final request = await client.openUrl(
        'GET',
        Uri.parse('http://localhost:$serverPort/slow'),
      );
      if (request is BrowserHttpClientRequest) {
        request.browserResponseType = 'text';
      }
      final response = await request.close();
      final list = await response.toList();

      // Check that the data arrived in multiple parts.
      expect(list, hasLength(greaterThanOrEqualTo(2)));

      // Check that the content is correct.
      final bytes = list.fold(<int>[], (dynamic a, b) => a..addAll(b));
      expect(utf8.decode(bytes), 'First part.\nSecond part.\n');
    });

    test('POST', () async {
      await _testClient(
        request: _Request(
          method: 'POST',
          path: '/greeting',
          body: 'Hello from client',
        ),
        expectedResponse: _ExpectedResponse(
          body: 'Hello world! (POST)',
        ),
      );
    });

    test('Status 404', () async {
      await _testClient(
        request: _Request(
          method: 'GET',
          path: '/404',
        ),
        expectedResponse: _ExpectedResponse(
          status: 404,
        ),
      );
    });

    test('Receiving cookies fails without credentials mode', () async {
      if (isBrowser) {
        final response = (await _testClient(
          request: _Request(
            method: 'GET',
            path: '/set_cookie?name=x&value=y',
          ),
          expectedResponse: _ExpectedResponse(
            status: HttpStatus.ok,
          ),
        ))!;
        expect(response.cookies, []);
      } else {
        final response = (await _testClient(
          request: _Request(
            method: 'GET',
            path: '/set_cookie?name=x&value=y',
          ),
          expectedResponse: _ExpectedResponse(
            status: HttpStatus.ok,
          ),
        ))!;
        expect(response.cookies, hasLength(1));
        expect(response.cookies.single.name, 'x');
        expect(response.cookies.single.value, 'y');
      }
    });

    test('Receiving cookies succeeds with credentials mode', () async {
      final httpClient = HttpClient();
      await _testClient(
        existingHttpClient: httpClient,
        request: _Request(
          method: 'GET',
          path: '/expect_cookie?name=x&value=y',
          credentialsMode: true,
        ),
        expectedResponse: _ExpectedResponse(
          status: HttpStatus.unauthorized,
        ),
      );
      await _testClient(
        existingHttpClient: httpClient,
        request: _Request(
          method: 'GET',
          path: '/set_cookie?name=x&value=y',
          credentialsMode: true,
        ),
      );
      if (isBrowser) {
        (await _testClient(
          existingHttpClient: httpClient,
          request: _Request(
            method: 'GET',
            path: '/expect_cookie?name=x&value=y',
            credentialsMode: true,
          ),
        ))!;
      } else {
        await _testClient(
          existingHttpClient: httpClient,
          request: _Request(
            method: 'GET',
            path: '/expect_cookie?name=x&value=y',
            credentialsMode: true,
          ),
          expectedResponse: _ExpectedResponse(
            status: HttpStatus.unauthorized,
          ),
        );
      }
    });

    test('Sending cookies fails without credentials mode', () async {
      var expectedStatus = HttpStatus.ok;
      if (isBrowser) {
        expectedStatus = HttpStatus.unauthorized;
      }
      await _testClient(
        request: _Request(
          method: 'GET',
          path: '/expect_cookie?name=expectedCookie&value=value',
          headers: {
            'Cookie': Cookie('expectedCookie', 'value').toString(),
          },
        ),
        expectedResponse: _ExpectedResponse(
          status: expectedStatus,
        ),
      );
    });

    test("Sends 'Authorization' header", () async {
      await _testClient(
        request: _Request(
          method: 'POST',
          path: '/expect_authorization',
          headers: {
            HttpHeaders.authorizationHeader: 'expectedAuthorization',
          },
        ),
        expectedResponse: _ExpectedResponse(
          status: HttpStatus.ok,
          body: 'expectedAuthorization',
        ),
      );
    });

    // ------
    // DELETE
    // ------
    test('client.delete(...)', () async {
      await _testClientMethodWithoutUri(
        method: 'DELETE',
        openUrl: (client, host, port, path) => client.delete(host, port, path),
      );
    });

    test('client.deleteUrl(...)', () async {
      await _testClient(
        request: _Request(
          method: 'DELETE',
          path: '/greeting',
        ),
        expectedResponse: _ExpectedResponse(
          body: 'Hello world! (DELETE)',
        ),
        openUrl: (client, uri) => client.deleteUrl(uri),
      );
    });

    // ---
    // GET
    // ---

    test('client.get(...)', () async {
      await _testClientMethodWithoutUri(
        method: 'GET',
        openUrl: (client, host, port, path) => client.get(host, port, path),
      );
    });

    test('client.getUrl(...)', () async {
      await _testClient(
        request: _Request(
          method: 'GET',
          path: '/greeting',
        ),
        expectedResponse: _ExpectedResponse(
          body: 'Hello world! (GET)',
        ),
        openUrl: (client, uri) => client.getUrl(uri),
      );
    });

    // ----
    // HEAD
    // ----

    test('client.head(...)', () async {
      await _testClientMethodWithoutUri(
        method: 'HEAD',
        openUrl: (client, host, port, path) => client.head(host, port, path),
      );
    });

    test('client.headUrl(...)', () async {
      await _testClient(
        request: _Request(
          method: 'HEAD',
          path: '/greeting',
        ),
        expectedResponse: _ExpectedResponse(
          // HEAD response doesn't have body
          body: '',
        ),
        openUrl: (client, uri) => client.headUrl(uri),
      );
    });

    // -----
    // PATCH
    // -----

    test('client.patch(...)', () async {
      await _testClientMethodWithoutUri(
        method: 'PATCH',
        openUrl: (client, host, port, path) => client.patch(host, port, path),
      );
    });

    test('client.patchUrl(...)', () async {
      await _testClient(
        request: _Request(
          method: 'PATCH',
          path: '/greeting',
        ),
        expectedResponse: _ExpectedResponse(
          body: 'Hello world! (PATCH)',
        ),
        openUrl: (client, uri) => client.patchUrl(uri),
      );
    });

    // ----
    // POST
    // ----

    test('client.post(...)', () async {
      await _testClientMethodWithoutUri(
        method: 'POST',
        openUrl: (client, host, port, path) => client.post(host, port, path),
      );
    });

    test('client.postUrl(...)', () async {
      await _testClient(
        request: _Request(
          method: 'POST',
          path: '/greeting',
        ),
        expectedResponse: _ExpectedResponse(
          body: 'Hello world! (POST)',
        ),
        openUrl: (client, uri) => client.postUrl(uri),
      );
    });

    // ---
    // PUT
    // ---

    test('client.put(...)', () async {
      await _testClientMethodWithoutUri(
        method: 'PUT',
        openUrl: (client, host, port, path) => client.put(host, port, path),
      );
    });

    test('client.putUrl(...)', () async {
      await _testClient(
        request: _Request(
          method: 'PUT',
          path: '/greeting',
        ),
        expectedResponse: _ExpectedResponse(
          body: 'Hello world! (PUT)',
        ),
        openUrl: (client, uri) => client.putUrl(uri),
      );
    });

    test('TLS connection to a self-signed server fails', () async {
      final client = HttpClient();
      final uri = Uri.parse('https://localhost:$secureServerPort/greeting');
      if (isBrowser) {
        // In browser, request is sent only after it's closed.
        final request = await client.getUrl(uri);
        expect(() => request.close(), throwsA(TypeMatcher<SocketException>()));
      } else {
        expect(() => client.getUrl(uri),
            throwsA(TypeMatcher<HandshakeException>()));
      }
    });

    if (!isBrowser) {
      test(
          'TLS connection to a self-signed server succeeds with'
          " the help of 'badCertificateCallback'", () async {
        final client = HttpClient();
        client.badCertificateCallback = (certificate, host, port) {
          return true;
        };
        final uri = Uri.parse('https://localhost:$secureServerPort/greeting');
        final request = await client.getUrl(uri);
        final response = await request.close();
        expect(response.statusCode, 200);
      });
    }
  });
}

Future<HttpClientResponse?> _testClient({
  HttpClient? existingHttpClient,
  required _Request request,
  _ExpectedResponse expectedResponse = const _ExpectedResponse(),

  /// Function for opening HTTP request
  Future<HttpClientRequest> Function(HttpClient client, Uri uri)? openUrl,

  /// Are we expecting XMLHttpRequest error?
  bool xmlHttpRequestError = false,
}) async {
  // Send HTTP request
  final httpClient = existingHttpClient ?? HttpClient();
  HttpClientRequest httpClientRequest;
  final originalUri = Uri.parse(request.path);
  final queryParameters = <String, String>{
    ...originalUri.queryParameters,
  };
  if (request.credentialsMode) {
    queryParameters['credentials'] = 'true';
  }
  final uri = Uri(
    scheme: 'http',
    host: 'localhost',
    port: serverPort,
    path: originalUri.path,
    queryParameters: queryParameters,
  );
  if (openUrl != null) {
    // Use a custom method
    // (we test their correctness)
    httpClientRequest = await openUrl(
      httpClient,
      uri,
    ).timeout(const Duration(seconds: 5));
  } else {
    // Use 'openUrl'
    httpClientRequest = await httpClient
        .openUrl(request.method, uri)
        .timeout(const Duration(seconds: 5));
  }

  // Set headers
  request.headers.forEach((name, value) {
    httpClientRequest.headers.set(name, value);
  });

  if (httpClientRequest is BrowserHttpClientRequest) {
    if (request.responseType != null) {
      httpClientRequest.browserResponseType = request.responseType;
    }
    httpClientRequest.browserCredentialsMode = request.credentialsMode;
  }

  // If HTTP method supports a request body,
  // write it.
  final requestBody = request.body;
  if (requestBody != null) {
    httpClientRequest.write(requestBody);
  }

  // Do we expect XMLHttpRequest error?
  if (xmlHttpRequestError) {
    expect(() => httpClientRequest.close(),
        throwsA(TypeMatcher<SocketException>()));
    return null;
  }

  // Close HTTP request
  final response = await httpClientRequest
      .close()
      .timeout(const Duration(milliseconds: 500));
  final actualResponseBody = await utf8
      .decodeStream(response.cast<List<int>>())
      .timeout(const Duration(seconds: 5));

  // Check response status code
  expect(response, isNotNull);
  expect(response.statusCode, expectedResponse.status);

  // Check response headers
  expect(response.headers.value('X-Response-Header'), 'value');

  // Check response body
  final expectedBody = expectedResponse.body;
  if (expectedBody != null) {
    expect(actualResponseBody, expectedBody);
  }

  // Check the request that the server received
  expect(response.headers.value('X-Request-Method'), request.method);
  expect(response.headers.value('X-Request-Path'), uri.path);
  expect(response.headers.value('X-Request-Body'), requestBody ?? '');

  return response;
}

/// Tests methods like 'client.get(host,port,path)'.
///
/// These should default to TLS.
Future _testClientMethodWithoutUri({
  required String method,
  required OpenUrlFunction openUrl,
}) async {
  // Create a HTTP client
  final client = HttpClient();

  // Create a HTTP request
  final host = 'localhost';
  final path = '/greeting';
  final request = await openUrl(client, host, serverPort, path);

  // Test that the request seems correct
  expect(request.uri.scheme, 'http');
  expect(request.uri.host, 'localhost');
  expect(request.uri.port, serverPort);
  expect(request.uri.path, path);

  // Close request
  final response = await request.close();
  await utf8.decodeStream(response.cast<List<int>>());
  expect(response.statusCode, 200);
}

typedef OpenUrlFunction = Future<HttpClientRequest> Function(
  HttpClient client,
  String host,
  int port,
  String path,
);

class _ExpectedResponse {
  final int status;
  final String? body;

  const _ExpectedResponse({
    this.status = 200,
    this.body,
  });
}

class _Request {
  final String method;
  final String path;
  final Map<String, String> headers;
  final String? body;
  final String? responseType;
  final bool credentialsMode;

  const _Request({
    required this.method,
    required this.path,
    this.headers = const <String, String>{},
    this.body,
    this.responseType,
    this.credentialsMode = false,
  });
}
