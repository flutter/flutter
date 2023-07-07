// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('!browser')
library usage.usage_impl_io_test;

import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:usage/src/usage_impl_io.dart';

void main() => defineTests();

void defineTests() {
  group('IOPostHandler', () {
    test('sendPost', () async {
      var mockClient = MockHttpClient();

      var postHandler = IOPostHandler(client: mockClient);
      var args = [
        <String, String>{'utv': 'varName', 'utt': '123'},
      ];
      await postHandler.sendPost(
          'http://www.google.com', args.map(postHandler.encodeHit).toList());
      expect(mockClient.requests.single.buffer.toString(), '''
Request to http://www.google.com with ${createUserAgent()}
utv=varName&utt=123''');
      expect(mockClient.requests.single.response.drained, isTrue);
    });
  });

  group('IOPersistentProperties', () {
    test('add', () {
      var props = IOPersistentProperties('foo_props');
      props['foo'] = 'bar';
      expect(props['foo'], 'bar');
    });

    test('remove', () {
      var props = IOPersistentProperties('foo_props');
      props['foo'] = 'bar';
      expect(props['foo'], 'bar');
      props['foo'] = null;
      expect(props['foo'], null);
    });
  });

  group('usage_impl_io', () {
    test('getDartVersion', () {
      expect(getDartVersion(), isNotNull);
    });

    test('getPlatformLocale', () {
      expect(getPlatformLocale(), isNotNull);
    });
  });

  group('batching', () {
    test('with 0 batch-delay hits from the same sync span are batched together',
        () async {
      var mockClient = MockHttpClient();

      final analytics = AnalyticsIO('<TRACKING-ID', 'usage-test', '0.0.1',
          client: mockClient, batchingDelay: Duration());
      unawaited(analytics.sendEvent('my-event1', 'something'));
      unawaited(analytics.sendEvent('my-event2', 'something'));
      unawaited(analytics.sendEvent('my-event3', 'something'));
      unawaited(analytics.sendEvent('my-event4', 'something'));
      unawaited(analytics.sendEvent('my-event5', 'something'));
      unawaited(analytics.sendEvent('my-event6', 'something'));
      unawaited(analytics.sendEvent('my-event7', 'something'));
      unawaited(analytics.sendEvent('my-event8', 'something'));
      unawaited(analytics.sendEvent('my-event9', 'something'));
      unawaited(analytics.sendEvent('my-event10', 'something'));
      unawaited(analytics.sendEvent('my-event11', 'something'));
      unawaited(analytics.sendEvent('my-event12', 'something'));
      unawaited(analytics.sendEvent('my-event13', 'something'));
      unawaited(analytics.sendEvent('my-event14', 'something'));
      unawaited(analytics.sendEvent('my-event15', 'something'));
      unawaited(analytics.sendEvent('my-event16', 'something'));
      unawaited(analytics.sendEvent('my-event17', 'something'));
      unawaited(analytics.sendEvent('my-event18', 'something'));
      unawaited(analytics.sendEvent('my-event19', 'something'));
      unawaited(analytics.sendEvent('my-event20', 'something'));
      unawaited(analytics.sendEvent('my-event21', 'something'));
      await Future(() {});
      expect(mockClient.requests.length, 2);
      unawaited(analytics.sendEvent('my-event-not-batched', 'something'));
      await Future(() {});

      // Try and isolate this test from the specific platform ul.
      var ul = getPlatformLocale() ?? 'en-us';
      final ulParam = '&ul=$ul'; // &ul=en-us

      await analytics.waitForLastPing();
      analytics.close();
      expect(mockClient.closed, isTrue);
      expect(mockClient.requests.length, 3);
      final clientId = analytics.clientId;
      expect(mockClient.requests[0].buffer.toString(), '''
Request to https://www.google-analytics.com/batch with ${createUserAgent()}
ec=my-event1&ea=something&an=usage-test&av=0.0.1$ulParam&v=1&tid=%3CTRACKING-ID&cid=$clientId&t=event
ec=my-event2&ea=something&an=usage-test&av=0.0.1$ulParam&v=1&tid=%3CTRACKING-ID&cid=$clientId&t=event
ec=my-event3&ea=something&an=usage-test&av=0.0.1$ulParam&v=1&tid=%3CTRACKING-ID&cid=$clientId&t=event
ec=my-event4&ea=something&an=usage-test&av=0.0.1$ulParam&v=1&tid=%3CTRACKING-ID&cid=$clientId&t=event
ec=my-event5&ea=something&an=usage-test&av=0.0.1$ulParam&v=1&tid=%3CTRACKING-ID&cid=$clientId&t=event
ec=my-event6&ea=something&an=usage-test&av=0.0.1$ulParam&v=1&tid=%3CTRACKING-ID&cid=$clientId&t=event
ec=my-event7&ea=something&an=usage-test&av=0.0.1$ulParam&v=1&tid=%3CTRACKING-ID&cid=$clientId&t=event
ec=my-event8&ea=something&an=usage-test&av=0.0.1$ulParam&v=1&tid=%3CTRACKING-ID&cid=$clientId&t=event
ec=my-event9&ea=something&an=usage-test&av=0.0.1$ulParam&v=1&tid=%3CTRACKING-ID&cid=$clientId&t=event
ec=my-event10&ea=something&an=usage-test&av=0.0.1$ulParam&v=1&tid=%3CTRACKING-ID&cid=$clientId&t=event
ec=my-event11&ea=something&an=usage-test&av=0.0.1$ulParam&v=1&tid=%3CTRACKING-ID&cid=$clientId&t=event
ec=my-event12&ea=something&an=usage-test&av=0.0.1$ulParam&v=1&tid=%3CTRACKING-ID&cid=$clientId&t=event
ec=my-event13&ea=something&an=usage-test&av=0.0.1$ulParam&v=1&tid=%3CTRACKING-ID&cid=$clientId&t=event
ec=my-event14&ea=something&an=usage-test&av=0.0.1$ulParam&v=1&tid=%3CTRACKING-ID&cid=$clientId&t=event
ec=my-event15&ea=something&an=usage-test&av=0.0.1$ulParam&v=1&tid=%3CTRACKING-ID&cid=$clientId&t=event
ec=my-event16&ea=something&an=usage-test&av=0.0.1$ulParam&v=1&tid=%3CTRACKING-ID&cid=$clientId&t=event
ec=my-event17&ea=something&an=usage-test&av=0.0.1$ulParam&v=1&tid=%3CTRACKING-ID&cid=$clientId&t=event
ec=my-event18&ea=something&an=usage-test&av=0.0.1$ulParam&v=1&tid=%3CTRACKING-ID&cid=$clientId&t=event
ec=my-event19&ea=something&an=usage-test&av=0.0.1$ulParam&v=1&tid=%3CTRACKING-ID&cid=$clientId&t=event
ec=my-event20&ea=something&an=usage-test&av=0.0.1$ulParam&v=1&tid=%3CTRACKING-ID&cid=$clientId&t=event''');
      expect(mockClient.requests[1].buffer.toString(), '''
Request to https://www.google-analytics.com/collect with ${createUserAgent()}
ec=my-event21&ea=something&an=usage-test&av=0.0.1$ulParam&v=1&tid=%3CTRACKING-ID&cid=$clientId&t=event''');
      expect(mockClient.requests[2].buffer.toString(), '''
Request to https://www.google-analytics.com/collect with ${createUserAgent()}
ec=my-event-not-batched&ea=something&an=usage-test&av=0.0.1$ulParam&v=1&tid=%3CTRACKING-ID&cid=$clientId&t=event''');
    });
  });
}

class MockHttpClient implements HttpClient {
  final List<MockHttpClientRequest> requests = <MockHttpClientRequest>[];
  @override
  String? userAgent;
  bool closed = false;

  MockHttpClient();

  @override
  Future<HttpClientRequest> postUrl(Uri uri) async {
    if (closed) throw StateError('Posting after close');
    final request = MockHttpClientRequest();
    request.buffer.writeln('Request to $uri with $userAgent');
    requests.add(request);
    return request;
  }

  @override
  void close({bool force = false}) {
    if (closed) throw StateError('Double close');
    closed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Unexpected call');
  }
}

class MockHttpClientRequest implements HttpClientRequest {
  final buffer = StringBuffer();
  final MockHttpClientResponse response = MockHttpClientResponse();
  bool closed = false;

  MockHttpClientRequest();

  @override
  void write(Object? o) {
    buffer.write(o);
  }

  @override
  Future<HttpClientResponse> close() async {
    if (closed) throw StateError('Double close');
    closed = true;
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Unexpected call');
  }
}

class MockHttpClientResponse implements HttpClientResponse {
  bool drained = false;
  MockHttpClientResponse();

  @override
  Future<E> drain<E>([E? futureValue]) async {
    drained = true;
    return futureValue as E;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Unexpected call');
  }
}
