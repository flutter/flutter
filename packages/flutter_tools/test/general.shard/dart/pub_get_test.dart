// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:quiver/testing/async.dart';
import 'package:platform/platform.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart' as mocks;
import '../../src/testbed.dart';

void main() {
  setUpAll(() {
    Cache.flutterRoot = getFlutterRoot();
  });

  tearDown(() {
    MockDirectory.findCache = false;
  });

  testUsingContext('pub get 69', () async {
    String error;

    final MockProcessManager processMock = context.get<ProcessManager>() as MockProcessManager;

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
    FileSystem: () => MockFileSystem(),
    ProcessManager: () => MockProcessManager(69),
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
    FileSystem: () => MockFileSystem(),
    ProcessManager: () => MockProcessManager(69),
    Platform: () => FakePlatform(
      environment: UnmodifiableMapView<String, String>(<String, String>{}),
    ),
    Pub: () => const Pub(),
  });

  testUsingContext('pub cache in environment is used', () async {
    String error;

    final MockProcessManager processMock = context.get<ProcessManager>() as MockProcessManager;

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
    FileSystem: () => MockFileSystem(),
    ProcessManager: () => MockProcessManager(69),
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
    FileSystem: () => MockFileSystem(),
    ProcessManager: () => MockProcessManager(0),
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
    FileSystem: () => MockFileSystem(),
    ProcessManager: () => MockProcessManager(1),
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
    FileSystem: () => MockFileSystem(),
    ProcessManager: () => MockProcessManager(
      1,
      stderr: 'version solving failed',
    ),
    Platform: () => FakePlatform(
      environment: UnmodifiableMapView<String, String>(<String, String>{
        'PUB_CACHE': 'custom/pub-cache/path',
      }),
    ),
    Usage: () => MockUsage(),
    Pub: () => const Pub(),
  });

  test('Pub error handling', () async {
    final MemoryFileSystem fileSystem = MemoryFileSystem();
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: const <String>[
          '/bin/cache/dart-sdk/bin/pub',
          '--verbosity=warning',
          'get',
          '--no-precompile',
        ],
        onRun: () {
          globals.fs.file('.packages')
            ..setLastModifiedSync(DateTime(2002));
        }
      ),
      const FakeCommand(
        command: <String>[
          '/bin/cache/dart-sdk/bin/pub',
          '--verbosity=warning',
          'get',
          '--no-precompile',
        ],
      ),
      FakeCommand(
        command: const <String>[
          '/bin/cache/dart-sdk/bin/pub',
          '--verbosity=warning',
          'get',
          '--no-precompile',
        ],
        onRun: () {
          globals.fs.file('pubspec.yaml')
            ..setLastModifiedSync(DateTime(2002));
        }
      ),
      const FakeCommand(
        command: <String>[
          '/bin/cache/dart-sdk/bin/pub',
          '--verbosity=warning',
          'get',
          '--no-precompile',
        ],
      ),
    ]);
    await Testbed().run(() async {
      // the good scenario: .packages is old, pub updates the file.
      globals.fs.file('.packages')
        ..createSync()
        ..setLastModifiedSync(DateTime(2000));
      globals.fs.file('pubspec.yaml')
        ..createSync()
        ..setLastModifiedSync(DateTime(2001));
      await pub.get(context: PubContext.flutterTests, checkLastModified: true); // pub sets date of .packages to 2002
      expect(testLogger.statusText, 'Running "flutter pub get" in /...\n');
      expect(testLogger.errorText, isEmpty);
      expect(globals.fs.file('pubspec.yaml').lastModifiedSync(), DateTime(2001)); // because nothing should touch it
      expect(globals.fs.file('.packages').lastModifiedSync(), isNot(DateTime(2000))); // because pub changes it to 2002
      expect(globals.fs.file('.packages').lastModifiedSync(), isNot(DateTime(2002))); // because we set the timestamp again after pub
      testLogger.clear();
      // bad scenario 1: pub doesn't update file; doesn't matter, because we do instead
      globals.fs.file('.packages')
        ..setLastModifiedSync(DateTime(2000));
      globals.fs.file('pubspec.yaml')
        ..setLastModifiedSync(DateTime(2001));
      await pub.get(context: PubContext.flutterTests, checkLastModified: true); // pub does nothing
      expect(testLogger.statusText, 'Running "flutter pub get" in /...\n');
      expect(testLogger.errorText, isEmpty);
      expect(globals.fs.file('pubspec.yaml').lastModifiedSync(), DateTime(2001)); // because nothing should touch it
      expect(globals.fs.file('.packages').lastModifiedSync(), isNot(DateTime(2000))); // because we set the timestamp
      expect(globals.fs.file('.packages').lastModifiedSync(), isNot(DateTime(2002))); // just in case FakeProcessManager is buggy
      testLogger.clear();
      // bad scenario 2: pub changes pubspec.yaml instead
      globals.fs.file('.packages')
        ..setLastModifiedSync(DateTime(2000));
      globals.fs.file('pubspec.yaml')
        ..setLastModifiedSync(DateTime(2001));
      try {
        await pub.get(context: PubContext.flutterTests, checkLastModified: true);
        expect(true, isFalse, reason: 'pub.get did not throw');
      } catch (error) {
        expect(error, isA<Exception>());
        expect(error.message, '/: unexpected concurrent modification of pubspec.yaml while running pub.');
      }
      expect(testLogger.statusText, 'Running "flutter pub get" in /...\n');
      expect(testLogger.errorText, isEmpty);
      expect(globals.fs.file('pubspec.yaml').lastModifiedSync(), DateTime(2002)); // because fake pub above touched it
      expect(globals.fs.file('.packages').lastModifiedSync(), DateTime(2000)); // because nothing touched it
      // bad scenario 3: pubspec.yaml was created in the future
      globals.fs.file('.packages')
        ..setLastModifiedSync(DateTime(2000));
      globals.fs.file('pubspec.yaml')
        ..setLastModifiedSync(DateTime(9999));
      assert(DateTime(9999).isAfter(DateTime.now()));
      await pub.get(context: PubContext.flutterTests, checkLastModified: true); // pub does nothing
      expect(testLogger.statusText, contains('Running "flutter pub get" in /...\n'));
      expect(testLogger.errorText, startsWith(
        'Warning: File "/pubspec.yaml" was created in the future. Optimizations that rely on '
        'comparing time stamps will be unreliable. Check your system clock for accuracy.\n'
        'The timestamp was:'
      ));
      testLogger.clear();
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Pub: () => const Pub(),
      Platform: () => FakePlatform(
        operatingSystem: 'linux', // so that the command executed is consistent
        environment: <String, String>{},
      ),
      BotDetector: () => const BotDetectorAlwaysNo(), // so that the test never adds --trace to the pub command
    });
  });
}

class BotDetectorAlwaysNo implements BotDetector {
  const BotDetectorAlwaysNo();
  @override
  bool get isRunningOnBot => false;
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
    return MockDirectory(path as String);
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
