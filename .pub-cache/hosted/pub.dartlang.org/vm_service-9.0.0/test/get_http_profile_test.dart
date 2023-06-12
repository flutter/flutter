// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--timeline_streams=Dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

final rng = Random();

// Enable to test redirects.
const shouldTestRedirects = false;

const maxRequestDelayMs = 3000;
const maxResponseDelayMs = 500;
const serverShutdownDelayMs = 2000;

void randomlyAddCookie(HttpResponse response) {
  if (rng.nextInt(3) == 0) {
    response.cookies.add(Cookie('Cookie-Monster', 'Me-want-cookie!'));
  }
}

Future<bool> randomlyRedirect(HttpServer server, HttpResponse response) async {
  if (shouldTestRedirects && rng.nextInt(5) == 0) {
    final redirectUri = Uri(host: 'www.google.com', port: 80);
    await response.redirect(redirectUri);
    return true;
  }
  return false;
}

// Execute HTTP requests with random delays so requests have some overlap. This
// way we can be certain that timeline events are matching up properly even when
// connections are interrupted or can't be established.
Future<void> executeWithRandomDelay(Function f) =>
    Future<void>.delayed(Duration(milliseconds: rng.nextInt(maxRequestDelayMs)))
        .then((_) async {
      try {
        await f();
      } on HttpException catch (_) {} on SocketException catch (_) {} on StateError catch (_) {} on OSError catch (_) {}
    });

Uri randomlyAddRequestParams(Uri uri) {
  const possiblePathSegments = <String>['foo', 'bar', 'baz', 'foobar'];
  final segmentSubset =
      possiblePathSegments.sublist(0, rng.nextInt(possiblePathSegments.length));
  uri = uri.replace(pathSegments: segmentSubset);
  if (rng.nextInt(3) == 0) {
    uri = uri.replace(queryParameters: {
      'foo': 'bar',
      'year': '2019',
    });
  }
  return uri;
}

Future<HttpServer> startServer() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    final response = request.response;
    response.write(request.method);
    randomlyAddCookie(response);
    if (await randomlyRedirect(server, response)) {
      // Redirect calls close() on the response.
      return;
    }
    // Randomly delay response.
    await Future.delayed(
        Duration(milliseconds: rng.nextInt(maxResponseDelayMs)));
    await response.close();
  });
  return server;
}

Future<void> testMain() async {
  final server = await startServer();
  HttpClient.enableTimelineLogging = true;
  final client = HttpClient();
  final requests = <Future>[];
  final address =
      Uri(scheme: 'http', host: server.address.host, port: server.port);

  // HTTP DELETE
  for (int i = 0; i < 10; ++i) {
    final future = executeWithRandomDelay(() async {
      final r = await client.deleteUrl(randomlyAddRequestParams(address));
      final string = 'DELETE $address';
      r.headers.add(HttpHeaders.contentLengthHeader, string.length);
      r.write(string);
      final response = await r.close();
      response.listen((_) {});
    });
    requests.add(future);
  }

  // HTTP GET
  for (int i = 0; i < 10; ++i) {
    final future = executeWithRandomDelay(() async {
      final r = await client.getUrl(randomlyAddRequestParams(address));
      r.headers.add('cookie-eater', 'Cookie-Monster !');
      final response = await r.close();
      await response.drain();
    });
    requests.add(future);
  }
  // HTTP HEAD
  for (int i = 0; i < 10; ++i) {
    final future = executeWithRandomDelay(() async {
      final r = await client.headUrl(randomlyAddRequestParams(address));
      await r.close();
    });
    requests.add(future);
  }

  // HTTP CONNECT
  for (int i = 0; i < 10; ++i) {
    final future = executeWithRandomDelay(() async {
      final r =
          await client.openUrl('connect', randomlyAddRequestParams(address));
      await r.close();
    });
    requests.add(future);
  }

  // HTTP PATCH
  for (int i = 0; i < 10; ++i) {
    final future = executeWithRandomDelay(() async {
      final r = await client.patchUrl(randomlyAddRequestParams(address));
      final response = await r.close();
      response.listen(null);
    });
    requests.add(future);
  }

  // HTTP POST
  for (int i = 0; i < 10; ++i) {
    final future = executeWithRandomDelay(() async {
      final r = await client.postUrl(randomlyAddRequestParams(address));
      r.add(Uint8List.fromList([0, 1, 2]));
      await r.close();
    });
    requests.add(future);
  }

  // HTTP PUT
  for (int i = 0; i < 10; ++i) {
    final future = executeWithRandomDelay(() async {
      final r = await client.putUrl(randomlyAddRequestParams(address));
      await r.close();
    });
    requests.add(future);
  }

  // Purposefully close server before some connections can be made to ensure
  // that refused / interrupted connections correctly create finish timeline
  // events.
  await Future.delayed(Duration(milliseconds: serverShutdownDelayMs));
  await server.close();

  // Ensure all requests complete before finishing.
  await Future.wait(requests);
}

late VmService vmService;

Future<void> hasValidHttpRequests(HttpProfile profile, String method) async {
  final requests = profile.requests
      .where(
        (element) => element.method == method,
      )
      .toList();
  expect(requests.length, 10);

  for (final r in requests) {
    final fullRequest =
        await vmService.getHttpProfileRequest(r.isolateId, r.id);
    if (r.isRequestComplete) {
      final requestData = fullRequest.request!;

      if (r.request!.hasError) {
        void expectThrows(Function f) {
          try {
            f();
            fail('Excepted exception');
          } on HttpProfileRequestError {
            // Expected.
          }
        }

        expect(requestData.error, isNotNull);
        expect(requestData.error!.isNotEmpty, true);

        // Some data is available even if a request errored out.
        expect(requestData.events.length, greaterThanOrEqualTo(0));
        expect(fullRequest.requestBody!.length, greaterThanOrEqualTo(0));

        // Accessing the following properties should cause an exception for
        // requests which have encountered an error.
        expectThrows(() => requestData.contentLength);
        expectThrows(() => requestData.cookies);
        expectThrows(() => requestData.followRedirects);
        expectThrows(() => requestData.headers);
        expectThrows(() => requestData.maxRedirects);
        expectThrows(() => requestData.method);
        expectThrows(() => requestData.persistentConnection);
      } else {
        // Invoke all non-nullable getters to ensure each is present in the JSON
        // response.
        requestData.connectionInfo;
        requestData.contentLength;
        requestData.cookies;
        requestData.headers;
        expect(requestData.maxRedirects, greaterThanOrEqualTo(0));
        requestData.persistentConnection;
        // If proxyInfo is non-null, uri and port _must_ be non-null.
        if (requestData.proxyDetails != null) {
          final proxyInfo = requestData.proxyDetails!;
          expect(proxyInfo.host, true);
          expect(proxyInfo.port, true);
        }

        // Check body of request has been sent and recorded correctly.
        if (method == 'DELETE' || method == 'POST') {
          if (method == 'POST') {
            // add() was used
            expect(
              <int>[0, 1, 2],
              fullRequest.requestBody!,
            );
          } else {
            // write() was used.
            expect(
              utf8.decode(fullRequest.requestBody!).startsWith('$method http'),
              true,
            );
          }
        }

        if (r.isResponseComplete) {
          final responseData = r.response!;
          expect(responseData.statusCode, greaterThanOrEqualTo(100));
          expect(responseData.endTime, isNotNull);
          expect(responseData.startTime > r.endTime!, true);
          expect(responseData.endTime! >= responseData.startTime, true);
          expect(utf8.decode(fullRequest.responseBody!), method);
          responseData.headers;
          responseData.compressionState;
          responseData.connectionInfo;
          responseData.contentLength;
          responseData.cookies;
          responseData.isRedirect;
          responseData.persistentConnection;
          responseData.reasonPhrase;
          responseData.redirects;
          expect(responseData.hasError, false);
          expect(responseData.error, null);
        }
      }
    }
  }
}

void hasValidHttpProfile(HttpProfile profile, String method) {
  expect(profile.requests.where((e) => e.method == method).length, 10);
}

Future<void> hasValidHttpCONNECTs(HttpProfile profile) =>
    hasValidHttpRequests(profile, 'CONNECT');
Future<void> hasValidHttpDELETEs(HttpProfile profile) =>
    hasValidHttpRequests(profile, 'DELETE');
Future<void> hasValidHttpGETs(HttpProfile profile) =>
    hasValidHttpRequests(profile, 'GET');
Future<void> hasValidHttpHEADs(HttpProfile profile) =>
    hasValidHttpRequests(profile, 'HEAD');
Future<void> hasValidHttpPATCHs(HttpProfile profile) =>
    hasValidHttpRequests(profile, 'PATCH');
Future<void> hasValidHttpPOSTs(HttpProfile profile) =>
    hasValidHttpRequests(profile, 'POST');
Future<void> hasValidHttpPUTs(HttpProfile profile) =>
    hasValidHttpRequests(profile, 'PUT');

void hasDefaultRequestHeaders(HttpProfile profile) {
  for(final request in profile.requests) {
    if(!request.request!.hasError) {
      expect(request.request?.headers['host'], isNotNull);
      expect(request.request?.headers['user-agent'], isNotNull);
    }
  }
}

void hasCustomRequestHeaders(HttpProfile profile) {
  var requests = profile.requests.where((e) => e.method == "GET").toList();
  for(final request in requests) {
    if(!request.request!.hasError) {
      expect(request.request?.headers['cookie-eater'], isNotNull);
    }
  }
}

var tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    vmService = service;
    final isolateId = isolateRef.id!;

    final httpProfile = await service.getHttpProfile(isolateId);
    expect(httpProfile.requests.length, 70);

    // Verify timeline events.
    await hasValidHttpCONNECTs(httpProfile);
    await hasValidHttpDELETEs(httpProfile);
    await hasValidHttpGETs(httpProfile);
    await hasValidHttpHEADs(httpProfile);
    await hasValidHttpPATCHs(httpProfile);
    await hasValidHttpPOSTs(httpProfile);
    await hasValidHttpPUTs(httpProfile);
    hasDefaultRequestHeaders(httpProfile);
    hasCustomRequestHeaders(httpProfile);
  },
];

main(args) async => runIsolateTests(
      args,
      tests,
      'get_http_profile_test.dart',
      testeeBefore: testMain,
    );
