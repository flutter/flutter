// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12

import 'dart:async';
import 'dart:collection';

import 'package:async_helper/async_helper.dart';
import 'package:async_helper/async_minitest.dart';
import 'package:litetest/src/test.dart';
import 'package:litetest/src/test_suite.dart';

Future<void> main() async {
  asyncStart();

  test('test', () async {
    final StringBuffer buffer = StringBuffer();
    final TestLifecycle lifecycle = TestLifecycle();
    final TestSuite ts = TestSuite(
      logger: buffer,
      lifecycle: lifecycle,
    );

    ts.test('Test', () {
      expect(1, equals(1));
    });
    final bool result = await lifecycle.result;

    expect(result, true);
    expect(buffer.toString(), equals(
      'Test "Test": Started\nTest "Test": Passed\n',
    ));
  });

  test('multiple tests', () async {
    final StringBuffer buffer = StringBuffer();
    final TestLifecycle lifecycle = TestLifecycle();
    final TestSuite ts = TestSuite(
      logger: buffer,
      lifecycle: lifecycle,
    );

    ts.test('Test1', () {
      expect(1, equals(1));
    });
    ts.test('Test2', () {
      expect(2, equals(2));
    });
    ts.test('Test3', () {
      expect(3, equals(3));
    });
    final bool result = await lifecycle.result;

    expect(result, true);
    expect(buffer.toString(), equals('''
Test "Test1": Started
Test "Test1": Passed
Test "Test2": Started
Test "Test2": Passed
Test "Test3": Started
Test "Test3": Passed
''',
    ));
  });

  test('multiple tests with failure', () async {
    final StringBuffer buffer = StringBuffer();
    final TestLifecycle lifecycle = TestLifecycle();
    final TestSuite ts = TestSuite(
      logger: buffer,
      lifecycle: lifecycle,
    );

    ts.test('Test1', () {
      expect(1, equals(1));
    });
    ts.test('Test2', () {
      expect(2, equals(3));
    });
    ts.test('Test3', () {
      expect(3, equals(3));
    });
    final bool result = await lifecycle.result;
    final String output = buffer.toString();

    expect(result, false);
    expect(output.contains('Test "Test1": Started'), true);
    expect(output.contains('Test "Test1": Passed'), true);
    expect(output.contains('Test "Test2": Started'), true);
    expect(output.contains('Test "Test2": Failed'), true);
    expect(output.contains(
      'In test "Test2" Expect.deepEquals(expected: <3>, actual: <2>) fails.',
    ), true);
    expect(output.contains('Test "Test3": Started'), true);
    expect(output.contains('Test "Test3": Passed'), true);
  });

  test('test fail', () async {
    final StringBuffer buffer = StringBuffer();
    final TestLifecycle lifecycle = TestLifecycle();
    final TestSuite ts = TestSuite(
      logger: buffer,
      lifecycle: lifecycle,
    );

    ts.test('Test', () {
      expect(1, equals(2));
    });
    final bool result = await lifecycle.result;
    final String output = buffer.toString();

    expect(result, false);
    expect(output.contains('Test "Test": Started'), true);
    expect(output.contains('Test "Test": Failed'), true);
    expect(
      output.contains(
        'In test "Test" Expect.deepEquals(expected: <2>, actual: <1>) fails.',
      ),
      true,
    );
  });

  test('async test', () async {
    final StringBuffer buffer = StringBuffer();
    final TestLifecycle lifecycle = TestLifecycle();
    final TestSuite ts = TestSuite(
      logger: buffer,
      lifecycle: lifecycle,
    );

    ts.test('Test', () async {
      final Completer<void> completer = Completer<void>();
      Timer.run(() {
        completer.complete();
      });
      await completer.future;
      expect(1, equals(1));
    });
    final bool result = await lifecycle.result;

    expect(result, true);
    expect(buffer.toString(), equals(
      'Test "Test": Started\nTest "Test": Passed\n',
    ));
  });

  test('async test fail', () async {
    final StringBuffer buffer = StringBuffer();
    final TestLifecycle lifecycle = TestLifecycle();
    final TestSuite ts = TestSuite(
      logger: buffer,
      lifecycle: lifecycle,
    );

    ts.test('Test', () async {
      final Completer<void> completer = Completer<void>();
      Timer.run(() {
        completer.complete();
      });
      await completer.future;
      expect(1, equals(2));
    });
    final bool result = await lifecycle.result;
    final String output = buffer.toString();

    expect(result, false);
    expect(output.contains('Test "Test": Started'), true);
    expect(output.contains('Test "Test": Failed'), true);
    expect(
      output.contains(
        'In test "Test" Expect.deepEquals(expected: <2>, actual: <1>) fails.',
      ),
      true,
    );
  });

  test('throws StateError on async test() call', () async {
    final StringBuffer buffer = StringBuffer();
    final TestLifecycle lifecycle = TestLifecycle();
    final TestSuite ts = TestSuite(
      logger: buffer,
      lifecycle: lifecycle,
    );

    ts.test('Test', () {
      expect(1, equals(1));
    });

    bool caughtError = false;
    try {
      await Future<void>(() async {
        ts.test('Bad Test', () {});
      });
    } on StateError catch (e) {
      caughtError = true;
      expect(e.message.contains(
        'Test "Bad Test" added after tests have started to run.',
      ), true);
    }
    expect(caughtError, true);

    final bool result = await lifecycle.result;

    expect(result, true);
    expect(buffer.toString(), equals(
      'Test "Test": Started\nTest "Test": Passed\n',
    ));
  });

  asyncEnd();
}

class TestLifecycle implements Lifecycle {
  final Completer<bool> _testCompleter = Completer<bool>();

  Future<bool> get result => _testCompleter.future;

  @override
  void onStart() {}

  @override
  void onDone(Queue<Test> tests) {
    bool testsSucceeded = true;
    for (final Test t in tests) {
      testsSucceeded = testsSucceeded && (t.state == TestState.succeeded);
    }
    _testCompleter.complete(testsSucceeded);
  }
}
