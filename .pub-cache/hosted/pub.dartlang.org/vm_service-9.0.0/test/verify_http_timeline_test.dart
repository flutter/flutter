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
  print('starting');
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
  print('done');
}

bool isStartEvent(Map event) => (event['ph'] == 'b');
bool isFinishEvent(Map event) => (event['ph'] == 'e');

bool hasCompletedEvents(List<TimelineEvent> traceEvents) {
  final events = <String, int>{};
  for (final event in traceEvents) {
    final id = event.json!['id'];
    events.putIfAbsent(id, () => 0);
    if (isStartEvent(event.json!)) {
      events[id] = events[id]! + 1;
    } else if (isFinishEvent(event.json!)) {
      events[id] = events[id]! - 1;
    }
  }
  bool valid = true;
  events.forEach((id, count) {
    if (count != 0) {
      valid = false;
    }
  });
  return valid;
}

List<TimelineEvent> filterEventsByName(
        List<TimelineEvent> traceEvents, String name) =>
    traceEvents.where((e) => e.json!.containsKey(name)).toList();

List<TimelineEvent> filterEventsByIdAndName(
        List<TimelineEvent> traceEvents, String id, String name) =>
    traceEvents
        .where((e) => e.json!['id'] == id && e.json!['name'].contains(name))
        .toList();

void hasValidHttpConnections(List<TimelineEvent> traceEvents) {
  final events = filterEventsByName(traceEvents, 'HTTP Connection');
  expect(hasCompletedEvents(events), isTrue);
}

void validateHttpStartEvent(Map event, String method) {
  expect(event.containsKey('args'), isTrue);
  final args = event['args'];
  expect(args.containsKey('method'), isTrue);
  expect(args['method'], method);
  expect(args['filterKey'], 'HTTP/client');
  expect(args.containsKey('uri'), isTrue);
}

void validateHttpFinishEvent(Map event) {
  expect(event.containsKey('args'), isTrue);
  final args = event['args'];
  expect(args['filterKey'], 'HTTP/client');
  if (!args.containsKey('error')) {
    expect(args.containsKey('requestHeaders'), isTrue);
    expect(args['requestHeaders'] != null, isTrue);
    expect(args.containsKey('compressionState'), isTrue);
    expect(args.containsKey('connectionInfo'), isTrue);
    expect(args.containsKey('contentLength'), isTrue);
    expect(args.containsKey('cookies'), isTrue);
    expect(args.containsKey('responseHeaders'), isTrue);
    expect(args.containsKey('isRedirect'), isTrue);
    expect(args.containsKey('persistentConnection'), isTrue);
    expect(args.containsKey('reasonPhrase'), isTrue);
    expect(args.containsKey('redirects'), isTrue);
    expect(args.containsKey('statusCode'), isTrue);
    // If proxyInfo is non-null, uri and port _must_ be non-null.
    if (args.containsKey('proxyInfo')) {
      final proxyInfo = args['proxyInfo'];
      expect(proxyInfo.containsKey('uri'), isTrue);
      expect(proxyInfo.containsKey('port'), isTrue);
    }
  }
}

void hasValidHttpRequests(
    HttpProfile profile, List<TimelineEvent> traceEvents, String method) {
  final requests = profile.requests
      .where(
        (element) => element.method == method,
      )
      .toList();
  expect(requests.length, 10);

  var events = filterEventsByName(traceEvents, 'HTTP CLIENT $method');
  for (final event in events) {
    final json = event.json!;
    if (isStartEvent(json)) {
      validateHttpStartEvent(event.json!, method);
      final id = json['id'];

      // HttpProfile request IDs should match up with their corresponding
      // timeline event IDS.
      final httpProfileRequest =
          requests.singleWhere((element) => element.id == id);
      expect(httpProfileRequest.id, id);
    } else if (isFinishEvent(json)) {
      validateHttpFinishEvent(json);
    } else {
      fail('unexpected event type: ${json["ph"]}');
    }
  }

  // Check response body matches string stored in the map.
  events = filterEventsByName(traceEvents, 'HTTP CLIENT response of $method');
  if (method == 'DELETE') {
    // It called listen().
    expect(hasCompletedEvents(events), isTrue);
  }
  for (final event in events) {
    final json = event.json!;
    // Each response will be associated with a request.
    if (isFinishEvent(json)) {
      continue;
    }
    final id = json['id'];
    final data = filterEventsByIdAndName(traceEvents, id, 'Response body');
    if (data.isNotEmpty) {
      expect(data.length, 1);
      expect(utf8.encode(method), data[0].json!['args']['data']);
    }
  }
}

void hasValidHttpProfile(HttpProfile profile, String method) {
  expect(profile.requests.where((e) => e.method == method).length, 10);
}

void hasValidHttpCONNECTs(
        HttpProfile profile, List<TimelineEvent> traceEvents) =>
    hasValidHttpRequests(profile, traceEvents, 'CONNECT');
void hasValidHttpDELETEs(
        HttpProfile profile, List<TimelineEvent> traceEvents) =>
    hasValidHttpRequests(profile, traceEvents, 'DELETE');
void hasValidHttpGETs(HttpProfile profile, List<TimelineEvent> traceEvents) =>
    hasValidHttpRequests(profile, traceEvents, 'GET');
void hasValidHttpHEADs(HttpProfile profile, List<TimelineEvent> traceEvents) =>
    hasValidHttpRequests(profile, traceEvents, 'HEAD');
void hasValidHttpPATCHs(HttpProfile profile, List<TimelineEvent> traceEvents) =>
    hasValidHttpRequests(profile, traceEvents, 'PATCH');
void hasValidHttpPOSTs(HttpProfile profile, List<TimelineEvent> traceEvents) =>
    hasValidHttpRequests(profile, traceEvents, 'POST');
void hasValidHttpPUTs(HttpProfile profile, List<TimelineEvent> traceEvents) =>
    hasValidHttpRequests(profile, traceEvents, 'PUT');

var tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;

    final httpProfile = await service.getHttpProfile(isolateId);
    expect(httpProfile.requests.length, 70);

    // Verify timeline events.
    final result = await service.getVMTimeline();
    final traceEvents = result.traceEvents!;
    expect(traceEvents.isNotEmpty, isTrue);
    hasValidHttpConnections(traceEvents);
    hasValidHttpCONNECTs(httpProfile, traceEvents);
    hasValidHttpDELETEs(httpProfile, traceEvents);
    hasValidHttpGETs(httpProfile, traceEvents);
    hasValidHttpHEADs(httpProfile, traceEvents);
    hasValidHttpPATCHs(httpProfile, traceEvents);
    hasValidHttpPOSTs(httpProfile, traceEvents);
    hasValidHttpPUTs(httpProfile, traceEvents);
  },
];

main(args) async => runIsolateTests(
      args,
      tests,
      'verify_http_timeline_test.dart',
      testeeBefore: testMain,
    );
