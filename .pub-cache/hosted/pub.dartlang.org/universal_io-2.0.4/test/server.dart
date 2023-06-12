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

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:stream_channel/stream_channel.dart';

void hybridMain(StreamChannel streamChannel, Object message) async {
  final securityContext = SecurityContext();
  const testSuitePath = 'test/src';
  securityContext.useCertificateChain(
    '$testSuitePath/localhost.crt',
  );
  securityContext.usePrivateKey(
    '$testSuitePath/localhost.key',
  );

  final server = await HttpServer.bind(
    'localhost',
    0,
  );
  print('Server #1 is listening at: http://localhost:${server.port}/');
  streamChannel.sink.add(server.port);

  final secureServer = await HttpServer.bindSecure(
    'localhost',
    0,
    securityContext,
  );
  print('Server #2 is listening at: https://localhost:${secureServer.port}/');
  streamChannel.sink.add(secureServer.port);

  try {
    final f0 = server.listen(_handleHttpRequest).asFuture();
    final f1 = secureServer.listen(_handleHttpRequest).asFuture();
    await Future.wait([f0, f1]);
  } finally {
    await Future.wait([server.close(), secureServer.close()]);
  }
}

void _handleHttpRequest(HttpRequest request) async {
  // Respond based on the path
  final requestBody = await utf8.decodeStream(request);
  final response = request.response;
  try {
    // Check that the request is from loopback
    if (!request.connectionInfo!.remoteAddress.isLoopback) {
      throw StateError('Unauthorized remote address');
    }
    final origin = request.headers.value('Origin') ?? '*';
    final userAgent = request.headers.value('User-Agent') ?? '';
    if (origin == '*' && !userAgent.contains('Dart')) {
      print('INVALID ORIGIN: $origin');
    }
    response.headers.set(
      'Access-Control-Allow-Origin',
      '*',
    );
    response.headers.set(
      'Access-Control-Allow-Methods',
      '*',
    );
    response.headers.set(
      'Access-Control-Expose-Headers',
      '*',
    );
    final isCredentialsMode =
        request.uri.queryParameters['credentials'] == 'true';
    if (isCredentialsMode) {
      response.headers.set(
        'Access-Control-Allow-Origin',
        origin,
      );
      response.headers.set(
        'Access-Control-Allow-Credentials',
        'true',
      );
      response.headers.set(
        'Access-Control-Allow-Methods',
        'DELETE, GET, HEAD, PATCH, POST, PUT',
      );
      response.headers.set(
        'Access-Control-Expose-Headers',
        'X-Request-Method, X-Request-Path, X-Request-Body, X-Response-Header',
      );
    }
    response.headers.set('X-Request-Method', request.method);
    response.headers.set('X-Request-Path', request.uri.path);
    response.headers.set('X-Request-Body', requestBody);
    response.headers.set('X-Response-Header', 'value');
    response.headers.contentType = ContentType.text;

    switch (request.uri.path) {
      case '/greeting':
        response.statusCode = HttpStatus.ok;
        response.write('Hello world! (${request.method})');
        break;

      case '/slow':
        response.bufferOutput = false;
        response.statusCode = HttpStatus.ok;
        response.headers.set('Cache-Control', 'no-cache');
        response.headers.chunkedTransferEncoding = true;
        response.writeln('First part.');
        await response.flush();
        await Future.delayed(const Duration(milliseconds: 500));

        response.writeln('Second part.');
        await response.flush();
        await Future.delayed(const Duration(milliseconds: 500));
        break;

      case '/set_cookie':
        final name = request.uri.queryParameters['name']!;
        final value = request.uri.queryParameters['value']!;
        response.statusCode = HttpStatus.ok;
        response.cookies.add(Cookie(name, value));
        break;

      case '/expect_cookie':
        final name = request.uri.queryParameters['name']!;
        final value = request.uri.queryParameters['value']!;
        // Not tested in browser
        final ok = request.cookies.any(
          (cookie) => cookie.name == name && cookie.value == value,
        );
        if (ok) {
          response.statusCode = HttpStatus.ok;
        } else {
          response.statusCode = HttpStatus.unauthorized;
        }
        break;

      case '/expect_authorization':
        response.headers.set(
          'Access-Control-Allow-Credentials',
          'true',
        );
        response.headers.set(
          'Access-Control-Allow-Headers',
          'Authorization',
        );

        // Is this a preflight?
        if (request.method == 'OPTIONS') {
          response.statusCode = HttpStatus.ok;
          return;
        }

        final authorization =
            request.headers.value(HttpHeaders.authorizationHeader);

        if (authorization == 'expectedAuthorization') {
          response.statusCode = HttpStatus.ok;
        } else {
          response.statusCode = HttpStatus.unauthorized;
        }
        response.write(authorization);
        break;

      case '/404':
        response.statusCode = HttpStatus.notFound;
        break;

      default:
        response.statusCode = HttpStatus.internalServerError;
        response.write("Invalid path '${request.uri.path}'");
        break;
    }
  } finally {
    await response.close();
  }
}
