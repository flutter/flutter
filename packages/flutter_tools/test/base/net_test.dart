// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/io.dart' as io;
import 'package:flutter_tools/src/base/net.dart';
import 'package:quiver/testing/async.dart';
import 'package:test/test.dart';

import '../src/context.dart';

void main() {
  testUsingContext('retry from 500', () async {
    String error;
    new FakeAsync().run((FakeAsync time) {
      fetchUrl(Uri.parse('http://example.invalid/')).then((List<int> value) {
        error = 'test completed unexpectedly';
      }, onError: (dynamic error) {
        error = 'test failed unexpectedly';
      });
      expect(testLogger.statusText, '');
      time.elapse(const Duration(milliseconds: 10000));
      expect(testLogger.statusText,
        'Download failed -- attempting retry 1 in 1 second...\n'
        'Download failed -- attempting retry 2 in 2 seconds...\n'
        'Download failed -- attempting retry 3 in 4 seconds...\n'
        'Download failed -- attempting retry 4 in 8 seconds...\n'
      );
    });
    expect(testLogger.errorText, isEmpty);
    expect(error, isNull);
  }, overrides: <Type, Generator>{
    HttpClientFactory: () => () => new MockHttpClient(500),
  });

  testUsingContext('retry from network error', () async {
    String error;
    new FakeAsync().run((FakeAsync time) {
      fetchUrl(Uri.parse('http://example.invalid/')).then((List<int> value) {
        error = 'test completed unexpectedly';
      }, onError: (dynamic error) {
        error = 'test failed unexpectedly';
      });
      expect(testLogger.statusText, '');
      time.elapse(const Duration(milliseconds: 10000));
      expect(testLogger.statusText,
        'Download failed -- attempting retry 1 in 1 second...\n'
        'Download failed -- attempting retry 2 in 2 seconds...\n'
        'Download failed -- attempting retry 3 in 4 seconds...\n'
        'Download failed -- attempting retry 4 in 8 seconds...\n'
      );
    });
    expect(testLogger.errorText, isEmpty);
    expect(error, isNull);
  }, overrides: <Type, Generator>{
    HttpClientFactory: () => () => new MockHttpClient(200),
  });
}

class MockHttpClient implements io.HttpClient {
  MockHttpClient(this.statusCode);

  final int statusCode;

  @override
  Future<io.HttpClientRequest> getUrl(Uri url) async {
    return new MockHttpClientRequest(statusCode);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw 'io.HttpClient - $invocation';
  }
}

class MockHttpClientRequest implements io.HttpClientRequest {
  MockHttpClientRequest(this.statusCode);

  final int statusCode;

  @override
  Future<io.HttpClientResponse> close() async {
    return new MockHttpClientResponse(statusCode);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw 'io.HttpClientRequest - $invocation';
  }
}

class MockHttpClientResponse extends Stream<List<int>> implements io.HttpClientResponse {
  MockHttpClientResponse(this.statusCode);

  @override
  final int statusCode;

  @override
  String get reasonPhrase => '<reason phrase>';

  @override
  StreamSubscription<List<int>> listen(void onData(List<int> event), {
    Function onError, void onDone(), bool cancelOnError
  }) {
    return new Stream<List<int>>.fromFuture(new Future<List<int>>.error(const io.SocketException('test')))
      .listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw 'io.HttpClientResponse - $invocation';
  }
}
