// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Windows doesn't support sending signals.
@TestOn('vm && !windows')

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:test_process/test_process.dart';

import '../io.dart';

String get _tempDir => p.join(d.sandbox, 'tmp');

// This test is inherently prone to race conditions. If it fails, it will likely
// do so flakily, but if it succeeds, it will succeed consistently. The tests
// represent a best effort to kill the test runner at certain times during its
// execution.
void main() {
  setUpAll(precompileTestExecutable);

  setUp(() => d.dir('tmp').create());

  group('during loading,', () {
    test('cleans up if killed while loading a VM test', () async {
      await d.file('test.dart', '''
void main() {
  print("in test.dart");
  // Spin for a long time so the test is probably killed while still loading.
  for (var i = 0; i < 100000000; i++) {}
}
''').create();

      var test = await _runTest(['test.dart']);
      await expectLater(test.stdout, emitsThrough('in test.dart'));
      await signalAndQuit(test);

      expectTempDirEmpty();
    });

    test('cleans up if killed while loading a browser test', () async {
      await d.file('test.dart', 'void main() {}').create();

      var test = await _runTest(['-p', 'chrome', 'test.dart']);
      await expectLater(
          test.stdout, emitsThrough(endsWith('compiling test.dart')));
      await signalAndQuit(test);

      expectTempDirEmpty(skip: 'Failing on Travis.');
    }, tags: 'chrome');

    test('exits immediately if ^C is sent twice', () async {
      await d.file('test.dart', '''
void main() {
  print("in test.dart");
  while (true) {}
}
''').create();

      var test = await _runTest(['test.dart']);
      await expectLater(test.stdout, emitsThrough('in test.dart'));
      test.signal(ProcessSignal.sigterm);

      // TODO(nweiz): Sending two signals in close succession can cause the
      // second one to be ignored, so we wait a bit before the second
      // one. Remove this hack when issue 23047 is fixed.
      await Future.delayed(Duration(seconds: 1));

      await signalAndQuit(test);
    });
  });

  group('during test running', () {
    test('waits for a VM test to finish running', () async {
      await d.file('test.dart', '''
import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  tearDownAll(() {
    File("output_all").writeAsStringSync("ran tearDownAll");
  });

  tearDown(() => File("output").writeAsStringSync("ran tearDown"));

  test("test", () {
    print("running test");
    return Future.delayed(Duration(seconds: 1));
  });
}
''').create();

      var test = await _runTest(['test.dart']);
      await expectLater(test.stdout, emitsThrough('running test'));
      await signalAndQuit(test);

      await d.file('output', 'ran tearDown').validate();
      await d.file('output_all', 'ran tearDownAll').validate();
      expectTempDirEmpty();
    });

    test('waits for an active tearDownAll to finish running', () async {
      await d.file('test.dart', '''
import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  tearDownAll(() async {
    print("running tearDownAll");
    await Future.delayed(Duration(seconds: 1));
    File("output").writeAsStringSync("ran tearDownAll");
  });

  test("test", () {});
}
''').create();

      var test = await _runTest(['test.dart']);
      await expectLater(test.stdout, emitsThrough('running tearDownAll'));
      await signalAndQuit(test);

      await d.file('output', 'ran tearDownAll').validate();
      expectTempDirEmpty();
    });

    test('kills a browser test immediately', () async {
      await d.file('test.dart', '''
import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("test", () {
    print("running test");

    // Allow an event loop to pass so the preceding print can be handled.
    return Future(() {
      // Loop forever so that if the test isn't stopped while running, it never
      // stops.
      while (true) {}
    });
  });
}
''').create();

      var test = await _runTest(['-p', 'chrome', 'test.dart']);
      await expectLater(test.stdout, emitsThrough('running test'));
      await signalAndQuit(test);

      expectTempDirEmpty(skip: 'Failing on Travis.');
    }, tags: 'chrome');

    test('kills a VM test immediately if ^C is sent twice', () async {
      await d.file('test.dart', '''
import 'package:test/test.dart';

void main() {
  test("test", () {
    print("running test");
    while (true) {}
  });
}
''').create();

      var test = await _runTest(['test.dart']);
      await expectLater(test.stdout, emitsThrough('running test'));
      test.signal(ProcessSignal.sigterm);

      // TODO(nweiz): Sending two signals in close succession can cause the
      // second one to be ignored, so we wait a bit before the second
      // one. Remove this hack when issue 23047 is fixed.
      await Future.delayed(Duration(seconds: 1));
      await signalAndQuit(test);
    });

    test('causes expectAsync() to always throw an error immediately', () async {
      await d.file('test.dart', '''
import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  var expectAsyncThrewError = false;

  tearDown(() {
    File("output").writeAsStringSync(expectAsyncThrewError.toString());
  });

  test("test", () async {
    print("running test");

    await Future.delayed(Duration(seconds: 1));
    try {
      expectAsync0(() {});
    } catch (_) {
      expectAsyncThrewError = true;
    }
  });
}
''').create();

      var test = await _runTest(['test.dart']);
      await expectLater(test.stdout, emitsThrough('running test'));
      await signalAndQuit(test);

      await d.file('output', 'true').validate();
      expectTempDirEmpty();
    });
  });
}

Future<TestProcess> _runTest(List<String> args, {bool forwardStdio = false}) =>
    runTest(args,
        environment: {'_UNITTEST_TEMP_DIR': _tempDir},
        forwardStdio: forwardStdio);

Future<void> signalAndQuit(TestProcess test) async {
  test.signal(ProcessSignal.sigterm);
  await test.shouldExit();
  await expectLater(test.stderr, emitsDone);
}

void expectTempDirEmpty({skip}) {
  expect(Directory(_tempDir).listSync(), isEmpty, skip: skip);
}
