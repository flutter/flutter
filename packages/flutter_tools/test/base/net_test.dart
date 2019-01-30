// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/io.dart' as io;
import 'package:flutter_tools/src/base/net.dart';
import 'package:quiver/testing/async.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  testUsingContext('retry from 500', () async {
    String error;
    FakeAsync().run((FakeAsync time) {
      fetchUrl(Uri.parse('http://example.invalid/')).then((List<int> value) {
        error = 'test completed unexpectedly';
      }, onError: (dynamic exception) {
        error = 'test failed unexpectedly: $exception';
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
    HttpClientFactory: () => () => MockHttpClient(500),
  });

  testUsingContext('retry from network error', () async {
    String error;
    FakeAsync().run((FakeAsync time) {
      fetchUrl(Uri.parse('http://example.invalid/')).then((List<int> value) {
        error = 'test completed unexpectedly';
      }, onError: (dynamic exception) {
        error = 'test failed unexpectedly: $exception';
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
    HttpClientFactory: () => () => MockHttpClient(200),
  });

  testUsingContext('retry from SocketException', () async {
    String error;
    FakeAsync().run((FakeAsync time) {
      fetchUrl(Uri.parse('http://example.invalid/')).then((List<int> value) {
        error = 'test completed unexpectedly';
      }, onError: (dynamic exception) {
        error = 'test failed unexpectedly: $exception';
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
    expect(testLogger.traceText, contains('Download error: SocketException'));
  }, overrides: <Type, Generator>{
    HttpClientFactory: () => () => MockHttpClientThrowing(
      const io.SocketException('test exception handling'),
    ),
  });

  testUsingContext('no retry from HandshakeException', () async {
    String error;
    FakeAsync().run((FakeAsync time) {
      fetchUrl(Uri.parse('http://example.invalid/')).then((List<int> value) {
        error = 'test completed unexpectedly';
      }, onError: (dynamic exception) {
        error = 'test failed: $exception';
      });
      expect(testLogger.statusText, '');
      time.elapse(const Duration(milliseconds: 10000));
      expect(testLogger.statusText, '');
    });
    expect(error, startsWith('test failed'));
    expect(testLogger.traceText, contains('HandshakeException'));
  }, overrides: <Type, Generator>{
    HttpClientFactory: () => () => MockHttpClientThrowing(
      const io.HandshakeException('test exception handling'),
    ),
  });

  testUsingContext('remote file non-existant', () async {
    final Uri invalid = Uri.parse('http://example.invalid/');
    final bool result = await doesRemoteFileExist(invalid);
    expect(result, false);
  }, overrides: <Type, Generator>{
    HttpClientFactory: () => () => MockHttpClient(404),
  });

  testUsingContext('remote file server error', () async {
    final Uri valid = Uri.parse('http://example.valid/');
    final bool result = await doesRemoteFileExist(valid);
    expect(result, false);
  }, overrides: <Type, Generator>{
    HttpClientFactory: () => () => MockHttpClient(500),
  });

  testUsingContext('remote file exists', () async {
    final Uri valid = Uri.parse('http://example.valid/');
    final bool result = await doesRemoteFileExist(valid);
    expect(result, true);
  }, overrides: <Type, Generator>{
    HttpClientFactory: () => () => MockHttpClient(200),
  });
}

class MockHttpClientThrowing implements io.HttpClient {
  MockHttpClientThrowing(this.exception);

  final Exception exception;

  @override
  Future<io.HttpClientRequest> getUrl(Uri url) async {
    throw exception;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw 'io.HttpClient - $invocation';
  }
}

class MockHttpClient implements io.HttpClient {
  MockHttpClient(this.statusCode);

  final int statusCode;

  @override
  Future<io.HttpClientRequest> getUrl(Uri url) async {
    return MockHttpClientRequest(statusCode);
  }

  @override
  Future<io.HttpClientRequest> headUrl(Uri url) async {
    return MockHttpClientRequest(statusCode);
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
    return MockHttpClientResponse(statusCode);
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
    return Stream<List<int>>.fromFuture(Future<List<int>>.error(const io.SocketException('test')))
      .listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw 'io.HttpClientResponse - $invocation';
  }
}
