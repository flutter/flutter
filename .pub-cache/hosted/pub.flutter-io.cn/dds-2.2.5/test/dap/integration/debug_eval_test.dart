// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dds/src/dap/adapters/dart.dart';
import 'package:test/test.dart';

import 'test_client.dart';
import 'test_scripts.dart';
import 'test_support.dart';

main() {
  late DapTestSession dap;
  setUp(() async {
    dap = await DapTestSession.setUp();
  });
  tearDown(() => dap.tearDown());

  group('debug mode evaluation', () {
    test('evaluates expressions with simple results', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) {
  var a = 1;
  var b = 2;
  var c = 'test';
  print('Hello!'); $breakpointMarker
}''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      final topFrameId = await client.getTopFrameId(stop.threadId!);
      await client.expectEvalResult(topFrameId, 'a', '1');
      await client.expectEvalResult(topFrameId, 'a * b', '2');
      await client.expectEvalResult(topFrameId, 'c', '"test"');
    });

    test('evaluates expressions with complex results', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      final topFrameId = await client.getTopFrameId(stop.threadId!);
      final result = await client.expectEvalResult(
        topFrameId,
        'DateTime(2000, 1, 1)',
        'DateTime',
      );

      // Check we got a variablesReference that maps on to the fields.
      expect(result.variablesReference, isPositive);
      await client.expectVariables(
        result.variablesReference,
        '''
            isUtc: false, eval: DateTime(2000, 1, 1).isUtc
        ''',
      );
    });

    test('evaluates expressions ending with semicolons', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) {
  var a = 1;
  var b = 2;
  print('Hello!'); $breakpointMarker
}''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      final topFrameId = await client.getTopFrameId(stop.threadId!);
      await client.expectEvalResult(topFrameId, 'a + b;', '3');
    });

    test(
        'evaluates complex expressions expressions with evaluateToStringInDebugViews=true',
        () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(
        testFile,
        breakpointLine,
        launch: () =>
            client.launch(testFile.path, evaluateToStringInDebugViews: true),
      );

      final topFrameId = await client.getTopFrameId(stop.threadId!);
      await client.expectEvalResult(
        topFrameId,
        'DateTime(2000, 1, 1)',
        'DateTime (2000-01-01 00:00:00.000)',
      );
    });

    test(
        'evaluates $threadExceptionExpression to the threads exception (simple type)',
        () async {
      final client = dap.client;
      final testFile = dap.createTestFile(r'''
void main(List<String> args) {
  throw 'my error';
}''');

      final stop = await client.hitException(testFile);
      final topFrameId = await client.getTopFrameId(stop.threadId!);
      final result = await client.expectEvalResult(
        topFrameId,
        threadExceptionExpression,
        '"my error"',
      );
      expect(result.variablesReference, equals(0));
    });

    test(
        'evaluates $threadExceptionExpression to the threads exception (complex type)',
        () async {
      final client = dap.client;
      final testFile = dap.createTestFile(r'''
void main(List<String> args) {
  throw Exception('my error');
}''');

      final stop = await client.hitException(testFile);
      final topFrameId = await client.getTopFrameId(stop.threadId!);
      final result = await client.expectEvalResult(
        topFrameId,
        threadExceptionExpression,
        '_Exception',
      );
      expect(result.variablesReference, isPositive);
    });

    test(
        'evaluates $threadExceptionExpression.x.y to x.y on the threads exception',
        () async {
      final client = dap.client;
      final testFile = dap.createTestFile(r'''
void main(List<String> args) {
  throw Exception('12345');
}
    ''');

      final stop = await client.hitException(testFile);
      final topFrameId = await client.getTopFrameId(stop.threadId!);
      await client.expectEvalResult(
        topFrameId,
        '$threadExceptionExpression.message.length',
        '5',
      );
    });

    test('can evaluate expressions in non-top frames', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) {
  var a = 999;
  foo();
}

void foo() {
  var a = 111; $breakpointMarker
}''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      final stack = await client.getValidStack(stop.threadId!,
          startFrame: 0, numFrames: 2);
      final secondFrameId = stack.stackFrames[1].id;

      await client.expectEvalResult(secondFrameId, 'a', '999');
    });

    test('returns the full message for evaluation errors', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      final topFrameId = await client.getTopFrameId(stop.threadId!);
      expectResponseError(
        client.evaluate(
          '1 + "a"',
          frameId: topFrameId,
        ),
        allOf([
          contains('evaluateInFrame: (113) Expression compilation error'),
          contains("'String' can't be assigned to a variable of type 'num'."),
          contains(
            '1 + "a"\n'
            '    ^',
          )
        ]),
      );
    });

    test('returns short errors for evaluation in "watch" context', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      final topFrameId = await client.getTopFrameId(stop.threadId!);
      expectResponseError(
        client.evaluate(
          '1 + "a"',
          frameId: topFrameId,
          context: 'watch',
        ),
        equals(
          "A value of type 'String' can't be assigned "
          "to a variable of type 'num'.",
        ),
      );
    });
    // These tests can be slow due to starting up the external server process.
  }, timeout: Timeout.none);
}
