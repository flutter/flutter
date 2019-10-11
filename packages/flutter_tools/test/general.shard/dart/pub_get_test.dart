// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';

import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:quiver/testing/async.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart' as mocks;

void main() {
  setUpAll(() {
    Cache.flutterRoot = getFlutterRoot();
  });

  testUsingContext('pub get 69', () async {
    String error;

    final MockProcessManager processMock = context.get<ProcessManager>();

    FakeAsync().run((FakeAsync time) {
      expect(processMock.lastPubEnvironment, isNull);
      expect(testLogger.statusText, '');
      pub.get(context: PubContext.flutterTests, checkLastModified: false).then((void value) {
        error = 'test completed unexpectedly';
      }, onError: (dynamic thrownError) {
        error = 'test failed unexpectedly: $thrownError';
      });
      time.elapse(const Duration(milliseconds: 500));
      expect(testLogger.statusText,
        'Running "flutter pub get" in /...\n'
        'pub get failed (server unavailable) -- attempting retry 1 in 1 second...\n',
      );
      expect(processMock.lastPubEnvironment, contains('flutter_cli:flutter_tests'));
      expect(processMock.lastPubCache, isNull);
      time.elapse(const Duration(milliseconds: 500));
      expect(testLogger.statusText,
        'Running "flutter pub get" in /...\n'
        'pub get failed (server unavailable) -- attempting retry 1 in 1 second...\n'
        'pub get failed (server unavailable) -- attempting retry 2 in 2 seconds...\n',
      );
      time.elapse(const Duration(seconds: 1));
      expect(testLogger.statusText,
        'Running "flutter pub get" in /...\n'
        'pub get failed (server unavailable) -- attempting retry 1 in 1 second...\n'
        'pub get failed (server unavailable) -- attempting retry 2 in 2 seconds...\n',
      );
      time.elapse(const Duration(seconds: 100)); // from t=0 to t=100
      expect(testLogger.statusText,
        'Running "flutter pub get" in /...\n'
        'pub get failed (server unavailable) -- attempting retry 1 in 1 second...\n'
        'pub get failed (server unavailable) -- attempting retry 2 in 2 seconds...\n'
        'pub get failed (server unavailable) -- attempting retry 3 in 4 seconds...\n' // at t=1
        'pub get failed (server unavailable) -- attempting retry 4 in 8 seconds...\n' // at t=5
        'pub get failed (server unavailable) -- attempting retry 5 in 16 seconds...\n' // at t=13
        'pub get failed (server unavailable) -- attempting retry 6 in 32 seconds...\n' // at t=29
        'pub get failed (server unavailable) -- attempting retry 7 in 64 seconds...\n', // at t=61
      );
      time.elapse(const Duration(seconds: 200)); // from t=0 to t=200
      expect(testLogger.statusText,
        'Running "flutter pub get" in /...\n'
        'pub get failed (server unavailable) -- attempting retry 1 in 1 second...\n'
        'pub get failed (server unavailable) -- attempting retry 2 in 2 seconds...\n'
        'pub get failed (server unavailable) -- attempting retry 3 in 4 seconds...\n'
        'pub get failed (server unavailable) -- attempting retry 4 in 8 seconds...\n'
        'pub get failed (server unavailable) -- attempting retry 5 in 16 seconds...\n'
        'pub get failed (server unavailable) -- attempting retry 6 in 32 seconds...\n'
        'pub get failed (server unavailable) -- attempting retry 7 in 64 seconds...\n'
        'pub get failed (server unavailable) -- attempting retry 8 in 64 seconds...\n' // at t=39
        'pub get failed (server unavailable) -- attempting retry 9 in 64 seconds...\n' // at t=103
        'pub get failed (server unavailable) -- attempting retry 10 in 64 seconds...\n', // at t=167
      );
    });
    expect(testLogger.errorText, isEmpty);
    expect(error, isNull);
  }, overrides: <Type, Generator>{
    ProcessManager: () => MockProcessManager(69),
    FileSystem: () => MockFileSystem(),
    Platform: () => FakePlatform(
      environment: UnmodifiableMapView<String, String>(<String, String>{}),
    ),
    Pub: () => const Pub(),
  });

  testUsingContext('pub get 66 shows message from pub', () async {
    try {
      await pub.get(context: PubContext.flutterTests, checkLastModified: false);
      throw AssertionError('pubGet did not fail');
    } on ToolExit catch (error) {
      expect(error.message, 'pub get failed (66; err3)');
    }
    expect(testLogger.statusText,
      'Running "flutter pub get" in /...\n'
      'out1\n'
      'out2\n'
      'out3\n'
    );
    expect(testLogger.errorText,
      'err1\n'
      'err2\n'
      'err3\n'
    );
  }, overrides: <Type, Generator>{
    ProcessManager: () => MockProcessManager(66, stderr: 'err1\nerr2\nerr3\n', stdout: 'out1\nout2\nout3\n'),
    FileSystem: () => MockFileSystem(),
    Platform: () => FakePlatform(
      environment: UnmodifiableMapView<String, String>(<String, String>{}),
    ),
    Pub: () => const Pub(),
  });

  testUsingContext('pub cache in root is used', () async {
    String error;

    final MockProcessManager processMock = context.get<ProcessManager>() as MockProcessManager;
    final MockFileSystem fsMock = context.get<FileSystem>() as MockFileSystem;

    FakeAsync().run((FakeAsync time) {
      MockDirectory.findCache = true;
      expect(processMock.lastPubEnvironment, isNull);
      expect(processMock.lastPubCache, isNull);
      pub.get(context: PubContext.flutterTests, checkLastModified: false).then((void value) {
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
      environment: UnmodifiableMapView<String, String>(<String, String>{}),
    ),
    Pub: () => const Pub(),
  });

  testUsingContext('pub cache in environment is used', () async {
    String error;

    final MockProcessManager processMock = context.get<ProcessManager>();

    FakeAsync().run((FakeAsync time) {
      MockDirectory.findCache = true;
      expect(processMock.lastPubEnvironment, isNull);
      expect(processMock.lastPubCache, isNull);
      pub.get(context: PubContext.flutterTests, checkLastModified: false).then((void value) {
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
      environment: UnmodifiableMapView<String, String>(<String, String>{
        'PUB_CACHE': 'custom/pub-cache/path',
      }),
    ),
    Pub: () => const Pub(),
  });

  testUsingContext('analytics sent on success', () async {
    MockDirectory.findCache = true;
    await pub.get(context: PubContext.flutterTests, checkLastModified: false);
    verify(flutterUsage.sendEvent('pub-result', 'flutter-tests', label: 'success')).called(1);
  }, overrides: <Type, Generator>{
    ProcessManager: () => MockProcessManager(0),
    FileSystem: () => MockFileSystem(),
    Platform: () => FakePlatform(
      environment: UnmodifiableMapView<String, String>(<String, String>{
        'PUB_CACHE': 'custom/pub-cache/path',
      }),
    ),
    Usage: () => MockUsage(),
    Pub: () => const Pub(),
  });

  testUsingContext('analytics sent on failure', () async {
    MockDirectory.findCache = true;
    try {
      await pub.get(context: PubContext.flutterTests, checkLastModified: false);
    } on ToolExit {
      // Ignore.
    }
    verify(flutterUsage.sendEvent('pub-result', 'flutter-tests', label: 'failure')).called(1);
  }, overrides: <Type, Generator>{
    ProcessManager: () => MockProcessManager(1),
    FileSystem: () => MockFileSystem(),
    Platform: () => FakePlatform(
      environment: UnmodifiableMapView<String, String>(<String, String>{
        'PUB_CACHE': 'custom/pub-cache/path',
      }),
    ),
    Usage: () => MockUsage(),
    Pub: () => const Pub(),
  });

  testUsingContext('analytics sent on failed version solve', () async {
    MockDirectory.findCache = true;
    try {
      await pub.get(context: PubContext.flutterTests, checkLastModified: false);
    } on ToolExit {
      // Ignore.
    }
    verify(flutterUsage.sendEvent('pub-result', 'flutter-tests', label: 'version-solving-failed')).called(1);
  }, overrides: <Type, Generator>{
    ProcessManager: () => MockProcessManager(
      1,
      stderr: 'version solving failed',
    ),
    FileSystem: () => MockFileSystem(),
    Platform: () => FakePlatform(
      environment: UnmodifiableMapView<String, String>(<String, String>{
        'PUB_CACHE': 'custom/pub-cache/path',
      }),
    ),
    Usage: () => MockUsage(),
    Pub: () => const Pub(),
  });
}

typedef StartCallback = void Function(List<dynamic> command);

class MockProcessManager implements ProcessManager {
  MockProcessManager(this.fakeExitCode, {
    this.stdout = '',
    this.stderr = '',
  });

  final int fakeExitCode;
  final String stdout;
  final String stderr;

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
    return Future<Process>.value(mocks.createMockProcess(
      exitCode: fakeExitCode,
      stdout: stdout,
      stderr: stderr,
    ));
  }

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
  Future<RandomAccessFile> open({ FileMode mode = FileMode.read }) async {
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

class MockUsage extends Mock implements Usage {}
