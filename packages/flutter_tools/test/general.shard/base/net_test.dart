// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:platform/platform.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' as io;
import 'package:flutter_tools/src/base/net.dart';

import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:quiver/testing/async.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group('successful fetch', () {
    const String responseString = 'response string';
    List<int> responseData;

    setUp(() {
      responseData = utf8.encode(responseString);
    });

    testUsingContext('fetchUrl() gets the data', () async {
      final List<int> data = await fetchUrl(Uri.parse('http://example.invalid/'));
      expect(data, equals(responseData));
    }, overrides: <Type, Generator>{
      HttpClientFactory: () => () => FakeHttpClient(200, data: responseString),
    });

    testUsingContext('fetchUrl(destFile) writes the data to a file', () async {
      final File destFile = globals.fs.file('dest_file')..createSync();
      final List<int> data = await fetchUrl(
        Uri.parse('http://example.invalid/'),
        destFile: destFile,
      );
      expect(data, equals(<int>[]));
      expect(destFile.readAsStringSync(), equals(responseString));
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
      HttpClientFactory: () => () => FakeHttpClient(200, data: responseString),
      ProcessManager: () => FakeProcessManager.any(),
    });
  });

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
        'Download failed -- attempting retry 4 in 8 seconds...\n',
      );
    });
    expect(testLogger.errorText, isEmpty);
    expect(error, isNull);
  }, overrides: <Type, Generator>{
    HttpClientFactory: () => () => FakeHttpClient(500),
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
        'Download failed -- attempting retry 4 in 8 seconds...\n',
      );
    });
    expect(testLogger.errorText, isEmpty);
    expect(error, isNull);
  }, overrides: <Type, Generator>{
    HttpClientFactory: () => () => FakeHttpClient(200),
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
        'Download failed -- attempting retry 4 in 8 seconds...\n',
      );
    });
    expect(testLogger.errorText, isEmpty);
    expect(error, isNull);
    expect(testLogger.traceText, contains('Download error: SocketException'));
  }, overrides: <Type, Generator>{
    HttpClientFactory: () => () => FakeHttpClientThrowing(
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
    HttpClientFactory: () => () => FakeHttpClientThrowing(
      const io.HandshakeException('test exception handling'),
    ),
  });

  testUsingContext('check for bad override on ArgumentError', () async {
    String error;
    FakeAsync().run((FakeAsync time) {
      fetchUrl(Uri.parse('example.invalid/')).then((List<int> value) {
        error = 'test completed unexpectedly';
      }, onError: (dynamic exception) {
        error = 'test failed: $exception';
      });
      expect(testLogger.statusText, '');
      time.elapse(const Duration(milliseconds: 10000));
      expect(testLogger.statusText, '');
    });
    expect(error, startsWith('test failed'));
    expect(testLogger.errorText, contains('Invalid argument'));
    expect(error, contains('FLUTTER_STORAGE_BASE_URL'));
  }, overrides: <Type, Generator>{
    HttpClientFactory: () => () => FakeHttpClientThrowing(
      ArgumentError('test exception handling'),
    ),
    Platform: () => FakePlatform.fromPlatform(const LocalPlatform())
      ..environment = <String, String>{
        'FLUTTER_STORAGE_BASE_URL': 'example.invalid',
      },
  });

  testUsingContext('retry from HttpException', () async {
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
        'Download failed -- attempting retry 4 in 8 seconds...\n',
      );
    });
    expect(testLogger.errorText, isEmpty);
    expect(error, isNull);
    expect(testLogger.traceText, contains('Download error: HttpException'));
  }, overrides: <Type, Generator>{
    HttpClientFactory: () => () => FakeHttpClientThrowing(
      const io.HttpException('test exception handling'),
    ),
  });

  testUsingContext('retry from HttpException when request throws', () async {
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
        'Download failed -- attempting retry 4 in 8 seconds...\n',
      );
    });
    expect(testLogger.errorText, isEmpty);
    expect(error, isNull);
    expect(testLogger.traceText, contains('Download error: HttpException'));
  }, overrides: <Type, Generator>{
    HttpClientFactory: () => () => FakeHttpClientThrowingRequest(
      const io.HttpException('test exception handling'),
    ),
  });

  testUsingContext('max attempts', () async {
    String error;
    List<int> actualResult;
    FakeAsync().run((FakeAsync time) {
      fetchUrl(Uri.parse('http://example.invalid/'), maxAttempts: 3).then((List<int> value) {
        actualResult = value;
      }, onError: (dynamic exception) {
        error = 'test failed unexpectedly: $exception';
      });
      expect(testLogger.statusText, '');
      time.elapse(const Duration(milliseconds: 10000));
      expect(testLogger.statusText,
        'Download failed -- attempting retry 1 in 1 second...\n'
        'Download failed -- attempting retry 2 in 2 seconds...\n'
        'Download failed -- retry 3\n',
      );
    });
    expect(testLogger.errorText, isEmpty);
    expect(error, isNull);
    expect(actualResult, isNull);
  }, overrides: <Type, Generator>{
    HttpClientFactory: () => () => FakeHttpClient(500),
  });

  testUsingContext('remote file non-existant', () async {
    final Uri invalid = Uri.parse('http://example.invalid/');
    final bool result = await doesRemoteFileExist(invalid);
    expect(result, false);
  }, overrides: <Type, Generator>{
    HttpClientFactory: () => () => FakeHttpClient(404),
  });

  testUsingContext('remote file server error', () async {
    final Uri valid = Uri.parse('http://example.valid/');
    final bool result = await doesRemoteFileExist(valid);
    expect(result, false);
  }, overrides: <Type, Generator>{
    HttpClientFactory: () => () => FakeHttpClient(500),
  });

  testUsingContext('remote file exists', () async {
    final Uri valid = Uri.parse('http://example.valid/');
    final bool result = await doesRemoteFileExist(valid);
    expect(result, true);
  }, overrides: <Type, Generator>{
    HttpClientFactory: () => () => FakeHttpClient(200),
  });
}

class FakeHttpClientThrowing implements io.HttpClient {
  FakeHttpClientThrowing(this.exception);

  final Object exception;

  @override
  Future<io.HttpClientRequest> getUrl(Uri url) async {
    throw exception;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw 'io.HttpClient - $invocation';
  }
}

class FakeHttpClient implements io.HttpClient {
  FakeHttpClient(this.statusCode, { this.data });

  final int statusCode;
  final String data;

  @override
  Future<io.HttpClientRequest> getUrl(Uri url) async {
    return FakeHttpClientRequest(statusCode, data: data);
  }

  @override
  Future<io.HttpClientRequest> headUrl(Uri url) async {
    return FakeHttpClientRequest(statusCode);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw 'io.HttpClient - $invocation';
  }
}

class FakeHttpClientThrowingRequest implements io.HttpClient {
  FakeHttpClientThrowingRequest(this.exception);

  final Object exception;

  @override
  Future<io.HttpClientRequest> getUrl(Uri url) async {
    return FakeHttpClientRequestThrowing(exception);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw 'io.HttpClient - $invocation';
  }
}

class FakeHttpClientRequest implements io.HttpClientRequest {
  FakeHttpClientRequest(this.statusCode, { this.data });

  final int statusCode;
  final String data;

  @override
  Future<io.HttpClientResponse> close() async {
    return FakeHttpClientResponse(statusCode, data: data);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw 'io.HttpClientRequest - $invocation';
  }
}

class FakeHttpClientRequestThrowing implements io.HttpClientRequest {
  FakeHttpClientRequestThrowing(this.exception);

  final Object exception;

  @override
  Future<io.HttpClientResponse> close() async {
    throw exception;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw 'io.HttpClientRequest - $invocation';
  }
}

class FakeHttpClientResponse implements io.HttpClientResponse {
  FakeHttpClientResponse(this.statusCode, { this.data });

  @override
  final int statusCode;

  final String data;

  @override
  String get reasonPhrase => '<reason phrase>';

  @override
  StreamSubscription<List<int>> listen(
    void onData(List<int> event), {
    Function onError,
    void onDone(),
    bool cancelOnError,
  }) {
    if (data == null) {
      return Stream<List<int>>.fromFuture(Future<List<int>>.error(
        const io.SocketException('test'),
      )).listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
    } else {
      return Stream<List<int>>.fromFuture(Future<List<int>>.value(
        utf8.encode(data),
      )).listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
    }
  }

  @override
  Future<dynamic> forEach(void Function(List<int> element) action) async {
    if (data == null) {
      return Future<void>.error(const io.SocketException('test'));
    } else {
      return Future<void>.microtask(() => action(utf8.encode(data)));
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw 'io.HttpClientResponse - $invocation';
  }
}
