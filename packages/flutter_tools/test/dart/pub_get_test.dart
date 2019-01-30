// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/dart/pub.dart';

import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:quiver/testing/async.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  setUpAll(() {
    Cache.flutterRoot = getFlutterRoot();
  });

  testUsingContext('pub get 69', () async {
    String error;

    final MockProcessManager processMock = context[ProcessManager];

    FakeAsync().run((FakeAsync time) {
      expect(processMock.lastPubEnvironment, isNull);
      expect(testLogger.statusText, '');
      pubGet(context: PubContext.flutterTests, checkLastModified: false).then((void value) {
        error = 'test completed unexpectedly';
      }, onError: (dynamic thrownError) {
        error = 'test failed unexpectedly: $thrownError';
      });
      time.elapse(const Duration(milliseconds: 500));
      expect(testLogger.statusText,
        'Running "flutter packages get" in /...\n'
        'pub get failed (69) -- attempting retry 1 in 1 second...\n'
      );
      expect(processMock.lastPubEnvironment, contains('flutter_cli:flutter_tests'));
      expect(processMock.lastPubCache, isNull);
      time.elapse(const Duration(milliseconds: 500));
      expect(testLogger.statusText,
        'Running "flutter packages get" in /...\n'
        'pub get failed (69) -- attempting retry 1 in 1 second...\n'
        'pub get failed (69) -- attempting retry 2 in 2 seconds...\n'
      );
      time.elapse(const Duration(seconds: 1));
      expect(testLogger.statusText,
        'Running "flutter packages get" in /...\n'
        'pub get failed (69) -- attempting retry 1 in 1 second...\n'
        'pub get failed (69) -- attempting retry 2 in 2 seconds...\n'
      );
      time.elapse(const Duration(seconds: 100)); // from t=0 to t=100
      expect(testLogger.statusText,
        'Running "flutter packages get" in /...\n'
        'pub get failed (69) -- attempting retry 1 in 1 second...\n'
        'pub get failed (69) -- attempting retry 2 in 2 seconds...\n'
        'pub get failed (69) -- attempting retry 3 in 4 seconds...\n' // at t=1
        'pub get failed (69) -- attempting retry 4 in 8 seconds...\n' // at t=5
        'pub get failed (69) -- attempting retry 5 in 16 seconds...\n' // at t=13
        'pub get failed (69) -- attempting retry 6 in 32 seconds...\n' // at t=29
        'pub get failed (69) -- attempting retry 7 in 64 seconds...\n' // at t=61
      );
      time.elapse(const Duration(seconds: 200)); // from t=0 to t=200
      expect(testLogger.statusText,
        'Running "flutter packages get" in /...\n'
        'pub get failed (69) -- attempting retry 1 in 1 second...\n'
        'pub get failed (69) -- attempting retry 2 in 2 seconds...\n'
        'pub get failed (69) -- attempting retry 3 in 4 seconds...\n'
        'pub get failed (69) -- attempting retry 4 in 8 seconds...\n'
        'pub get failed (69) -- attempting retry 5 in 16 seconds...\n'
        'pub get failed (69) -- attempting retry 6 in 32 seconds...\n'
        'pub get failed (69) -- attempting retry 7 in 64 seconds...\n'
        'pub get failed (69) -- attempting retry 8 in 64 seconds...\n' // at t=39
        'pub get failed (69) -- attempting retry 9 in 64 seconds...\n' // at t=103
        'pub get failed (69) -- attempting retry 10 in 64 seconds...\n' // at t=167
      );
    });
    expect(testLogger.errorText, isEmpty);
    expect(error, isNull);
  }, overrides: <Type, Generator>{
    ProcessManager: () => MockProcessManager(69),
    FileSystem: () => MockFileSystem(),
    Platform: () => FakePlatform(
      environment: <String, String>{},
    ),
  });

  testUsingContext('pub cache in root is used', () async {
    String error;

    final MockProcessManager processMock = context[ProcessManager];
    final MockFileSystem fsMock = context[FileSystem];

    FakeAsync().run((FakeAsync time) {
      MockDirectory.findCache = true;
      expect(processMock.lastPubEnvironment, isNull);
      expect(processMock.lastPubCache, isNull);
      pubGet(context: PubContext.flutterTests, checkLastModified: false).then((void value) {
        error = 'test completed unexpectedly';
      }, onError: (dynamic thrownError) {
        error = 'test failed unexpectedly: $thrownError';
      });
      time.elapse(const Duration(milliseconds: 500));
      expect(processMock.lastPubCache, equals(fsMock.path.join(Cache.flutterRoot, '.pub-cache')));
      expect(error, isNull);
    });
  }, overrides: <Type, Generator>{
    ProcessManager: () => MockProcessManager(69),
    FileSystem: () => MockFileSystem(),
    Platform: () => FakePlatform(
      environment: <String, String>{},
    ),
  });

  testUsingContext('pub cache in environment is used', () async {
    String error;

    final MockProcessManager processMock = context[ProcessManager];

    FakeAsync().run((FakeAsync time) {
      MockDirectory.findCache = true;
      expect(processMock.lastPubEnvironment, isNull);
      expect(processMock.lastPubCache, isNull);
      pubGet(context: PubContext.flutterTests, checkLastModified: false).then((void value) {
        error = 'test completed unexpectedly';
      }, onError: (dynamic thrownError) {
        error = 'test failed unexpectedly: $thrownError';
      });
      time.elapse(const Duration(milliseconds: 500));
      expect(processMock.lastPubCache, equals('custom/pub-cache/path'));
      expect(error, isNull);
    });
  }, overrides: <Type, Generator>{
    ProcessManager: () => MockProcessManager(69),
    FileSystem: () => MockFileSystem(),
    Platform: () => FakePlatform(
      environment: <String, String>{'PUB_CACHE': 'custom/pub-cache/path'},
    ),
  });
}

typedef StartCallback = void Function(List<dynamic> command);

class MockProcessManager implements ProcessManager {
  MockProcessManager(this.fakeExitCode);

  final int fakeExitCode;

  String lastPubEnvironment;
  String lastPubCache;

  @override
  Future<Process> start(
    List<dynamic> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) {
    lastPubEnvironment = environment['PUB_ENVIRONMENT'];
    lastPubCache = environment['PUB_CACHE'];
    return Future<Process>.value(MockProcess(fakeExitCode));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockProcess implements Process {
  MockProcess(this.fakeExitCode);

  final int fakeExitCode;

  @override
  Stream<List<int>> get stdout => MockStream<List<int>>();

  @override
  Stream<List<int>> get stderr => MockStream<List<int>>();

  @override
  Future<int> get exitCode => Future<int>.value(fakeExitCode);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockStream<T> implements Stream<T> {
  @override
  Stream<S> transform<S>(StreamTransformer<T, S> streamTransformer) => MockStream<S>();

  @override
  Stream<T> where(bool test(T event)) => MockStream<T>();

  @override
  StreamSubscription<T> listen(void onData(T event), {Function onError, void onDone(), bool cancelOnError}) {
    return MockStreamSubscription<T>();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockStreamSubscription<T> implements StreamSubscription<T> {
  @override
  Future<E> asFuture<E>([E futureValue]) => Future<E>.value();

  @override
  Future<void> cancel() async { }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}


class MockFileSystem extends ForwardingFileSystem {
  MockFileSystem() : super(MemoryFileSystem());

  @override
  File file(dynamic path) {
    return MockFile();
  }

  @override
  Directory directory(dynamic path) {
    return MockDirectory(path);
  }
}

class MockFile implements File {
  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) async {
    return MockRandomAccessFile();
  }

  @override
  bool existsSync() => true;

  @override
  DateTime lastModifiedSync() => DateTime(0);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockDirectory implements Directory {
  MockDirectory(this.path);

  @override
  final String path;

  static bool findCache = false;

  @override
  bool existsSync() => findCache && path.endsWith('.pub-cache');

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockRandomAccessFile extends Mock implements RandomAccessFile {}
