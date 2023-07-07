// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
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

  group('debug mode breakpoints', () {
    test('stops at a line breakpoint', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      await client.hitBreakpoint(testFile, breakpointLine);
    });

    test('does not stop at a removed breakpoint', () async {
      final testFile = dap.createTestFile('''
void main(List<String> args) async {
  print('Hello!'); $breakpointMarker
  print('Hello!'); $breakpointMarker
}
    ''');

      final client = dap.client;
      final breakpoint1Line = lineWith(testFile, breakpointMarker);
      final breakpoint2Line = breakpoint1Line + 1;

      // Hit the first breakpoint.
      final stop = await client.hitBreakpoint(testFile, breakpoint1Line,
          additionalBreakpoints: [breakpoint2Line]);

      // Remove all breakpoints.
      await client.setBreakpoints(testFile, []);

      // Resume and expect termination (should not hit the second breakpoint).
      await Future.wait([
        client.event('terminated'),
        client.continue_(stop.threadId!),
      ], eagerError: true);
    });

    test('does not fail updating breakpoints after a removal', () async {
      // https://github.com/flutter/flutter/issues/106369 was caused by us not
      // tracking removals correctly, meaning we could try to remove a removed
      // breakpoint a second time.
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      await client.hitBreakpoint(testFile, breakpointLine);

      // Remove the breakpoint.
      await client.setBreakpoints(testFile, []);

      // Send another breakpoint update to ensure it doesn't try to re-remove
      // the previously removed breakpoint.
      await client.setBreakpoints(testFile, []);
    });

    test('stops at a line breakpoint in the SDK set via local sources',
        () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);

      // Add the breakpoint to the first line inside the SDK's print function.
      final sdkFile = File(path.join(sdkRoot, 'lib', 'core', 'print.dart'));
      final breakpointLine = lineWith(sdkFile, 'print(Object? object) {') + 1;

      await client.hitBreakpoint(sdkFile, breakpointLine, entryFile: testFile);
    });

    test('stops at a line breakpoint and can be resumed', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      // Hit the initial breakpoint.
      final stop = await client.hitBreakpoint(testFile, breakpointLine);

      // Resume and expect termination (as the script will get to the end).
      await Future.wait([
        client.event('terminated'),
        client.continue_(stop.threadId!),
      ], eagerError: true);
    });

    test('stops at a line breakpoint and can step over (next)', () async {
      final testFile = dap.createTestFile('''
void main(List<String> args) async {
  print('Hello!'); $breakpointMarker
  print('Hello!'); $stepMarker
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);
      final stepLine = lineWith(testFile, stepMarker);

      // Hit the initial breakpoint.
      final stop = await dap.client.hitBreakpoint(testFile, breakpointLine);

      // Step and expect stopping on the next line with a 'step' stop type.
      await Future.wait([
        dap.client.expectStop('step', file: testFile, line: stepLine),
        dap.client.next(stop.threadId!),
      ], eagerError: true);
    });

    test(
        'stops at a line breakpoint and can step over (next) '
        'when stepping granularity was included', () async {
      final testFile = dap.createTestFile('''
void main(List<String> args) async {
  print('Hello!'); $breakpointMarker
  print('Hello!'); $stepMarker
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);
      final stepLine = lineWith(testFile, stepMarker);

      // Hit the initial breakpoint.
      final stop = await dap.client.hitBreakpoint(testFile, breakpointLine);

      // Step and expect stopping on the next line with a 'step' stop type.
      await Future.wait([
        dap.client.expectStop('step', file: testFile, line: stepLine),
        dap.client.next(stop.threadId!, granularity: 'statement'),
      ], eagerError: true);
    });

    test(
        'stops at a line breakpoint and can step over (next) an async boundary',
        () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
Future<void> main(List<String> args) async {
  await asyncPrint('Hello!'); $breakpointMarker
  await asyncPrint('Hello!'); $stepMarker
}

Future<void> asyncPrint(String message) async {
  await Future.delayed(const Duration(milliseconds: 1));
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);
      final stepLine = lineWith(testFile, stepMarker);

      // Hit the initial breakpoint.
      final stop = await dap.client.hitBreakpoint(testFile, breakpointLine);

      // The first step will move from `asyncPrint` to the `await`.
      await Future.wait([
        client.expectStop('step', file: testFile, line: breakpointLine),
        client.next(stop.threadId!),
      ], eagerError: true);

      // The next step should go over the async boundary and to stepLine (if
      // we did not correctly send kOverAsyncSuspension we would end up in
      // the asyncPrint method).
      await Future.wait([
        client.expectStop('step', file: testFile, line: stepLine),
        client.next(stop.threadId!),
      ], eagerError: true);
    });

    test('stops at a line breakpoint and can step in', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) async {
  log('Hello!'); $breakpointMarker
}

void log(String message) { $stepMarker
  print(message);
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);
      final stepLine = lineWith(testFile, stepMarker);

      // Hit the initial breakpoint.
      final stop = await client.hitBreakpoint(testFile, breakpointLine);

      // Step and expect stopping in the inner function with a 'step' stop type.
      await Future.wait([
        client.expectStop('step', file: testFile, line: stepLine),
        client.stepIn(stop.threadId!),
      ], eagerError: true);
    });

    test('stops at a line breakpoint and can step out', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) async {
  log('Hello!');
  log('Hello!'); $stepMarker
}

void log(String message) {
  print(message); $breakpointMarker
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);
      final stepLine = lineWith(testFile, stepMarker);

      // Hit the initial breakpoint.
      final stop = await client.hitBreakpoint(testFile, breakpointLine);

      // Step and expect stopping in the inner function with a 'step' stop type.
      await Future.wait([
        client.expectStop('step', file: testFile, line: stepLine),
        client.stepOut(stop.threadId!),
      ], eagerError: true);
    });

    test('does not step into SDK code with debugSdkLibraries=false', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) async {
  print('Hello!'); $breakpointMarker
  print('Hello!'); $stepMarker
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);
      final stepLine = lineWith(testFile, stepMarker);

      // Hit the initial breakpoint.
      final stop = await client.hitBreakpoint(
        testFile,
        breakpointLine,
        launch: () => client.launch(
          testFile.path,
          debugSdkLibraries: false,
        ),
      );

      // Step in and expect stopping on the next line (don't go into print).
      await Future.wait([
        client.expectStop('step', file: testFile, line: stepLine),
        client.stepIn(stop.threadId!),
      ], eagerError: true);
    });

    test('steps into SDK code with debugSdkLibraries=true', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) async {
  print('Hello!'); $breakpointMarker
  print('Hello!');
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      // Hit the initial breakpoint.
      final stop = await dap.client.hitBreakpoint(
        testFile,
        breakpointLine,
        launch: () => client.launch(
          testFile.path,
          debugSdkLibraries: true,
        ),
      );

      // Step in and expect to go into print.
      await Future.wait([
        client.expectStop('step', sourceName: 'dart:core/print.dart'),
        client.stepIn(stop.threadId!),
      ], eagerError: true);
    });

    test(
        'does not step into external package code with debugExternalPackageLibraries=false',
        () async {
      final client = dap.client;
      final otherPackageUri = await dap.createFooPackage();
      final testFile = dap.createTestFile('''
import '$otherPackageUri';

void main(List<String> args) async {
  foo(); $breakpointMarker
  foo(); $stepMarker
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);
      final stepLine = lineWith(testFile, stepMarker);

      // Hit the initial breakpoint.
      final stop = await client.hitBreakpoint(
        testFile,
        breakpointLine,
        launch: () => client.launch(
          testFile.path,
          debugExternalPackageLibraries: false,
        ),
      );

      // Step in and expect stopping on the next line (don't go into the package).
      await Future.wait([
        client.expectStop('step', file: testFile, line: stepLine),
        client.stepIn(stop.threadId!),
      ], eagerError: true);
    });

    test(
        'steps into external package code with debugExternalPackageLibraries=true',
        () async {
      final client = dap.client;
      final otherPackageUri = await dap.createFooPackage();
      final testFile = dap.createTestFile('''
import '$otherPackageUri';

void main(List<String> args) async {
  foo(); $breakpointMarker
  foo();
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      // Hit the initial breakpoint.
      final stop = await dap.client.hitBreakpoint(
        testFile,
        breakpointLine,
        launch: () => client.launch(
          testFile.path,
          debugExternalPackageLibraries: true,
        ),
      );

      // Step in and expect to go into the package.
      await Future.wait([
        client.expectStop('step', sourceName: '$otherPackageUri'),
        client.stepIn(stop.threadId!),
      ], eagerError: true);
    });

    test(
        'steps into other-project package code with debugExternalPackageLibraries=false',
        () async {
      final client = dap.client;
      final otherPackageUri = await dap.createFooPackage();
      final testFile = dap.createTestFile('''
import '$otherPackageUri';

void main(List<String> args) async {
  foo(); $breakpointMarker
  foo();
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      // Hit the initial breakpoint.
      final stop = await client.hitBreakpoint(
        testFile,
        breakpointLine,
        launch: () => client.launch(
          testFile.path,
          debugExternalPackageLibraries: false,
          // Include the packages folder as an additional project path so that
          // it will be treated as local code.
          additionalProjectPaths: [dap.testPackagesDir.path],
        ),
      );

      // Step in and expect stopping in the other package.
      await Future.wait([
        client.expectStop('step', sourceName: '$otherPackageUri'),
        client.stepIn(stop.threadId!),
      ], eagerError: true);
    });

    test('allows changing debug settings during session', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) async {
  print('Hello!'); $breakpointMarker
  print('Hello!'); $stepMarker
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);
      final stepLine = lineWith(testFile, stepMarker);

      // Start with debugSdkLibraryes _enabled_ and hit the breakpoint.
      final stop = await client.hitBreakpoint(
        testFile,
        breakpointLine,
        launch: () => client.launch(
          testFile.path,
          debugSdkLibraries: true,
        ),
      );

      // Turn off debugSdkLibraries.
      await client.custom('updateDebugOptions', {
        'debugSdkLibraries': false,
      });

      // Step in and expect stopping on the next line (don't go into print
      // because we turned off SDK debugging).
      await Future.wait([
        client.expectStop('step', file: testFile, line: stepLine),
        client.stepIn(stop.threadId!),
      ], eagerError: true);
    });
  }, timeout: Timeout.none);

  group('debug mode conditional breakpoints', () {
    test('stops with condition evaluating to true', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      await client.hitBreakpoint(
        testFile,
        breakpointLine,
        condition: '1 == 1',
      );
    });

    test('does not stop with condition evaluating to false', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      await client.doNotHitBreakpoint(
        testFile,
        breakpointLine,
        condition: '1 == 2',
      );
    });

    test('stops with condition evaluating to non-zero', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      await client.hitBreakpoint(
        testFile,
        breakpointLine,
        condition: '1 + 1',
      );
    });

    test('does not stop with condition evaluating to zero', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      await client.doNotHitBreakpoint(
        testFile,
        breakpointLine,
        condition: '1 - 1',
      );
    });

    test('reports evaluation errors for conditions', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final outputEventsFuture = client.outputEvents.toList();

      await client.doNotHitBreakpoint(
        testFile,
        breakpointLine,
        condition: "1 + 'a'",
      );

      final outputEvents = await outputEventsFuture;
      final outputMessages = outputEvents.map((e) => e.output);

      final hasPrefix = startsWith(
          'Debugger failed to evaluate breakpoint condition "1 + \'a\'": '
          'evaluateInFrame: (113) Expression compilation error');
      final hasDescriptiveMessage = contains(
          "A value of type 'String' can't be assigned to a variable of type 'num'");

      expect(
        outputMessages,
        containsAll([allOf(hasPrefix, hasDescriptiveMessage)]),
      );
    });
    // These tests can be slow due to starting up the external server process.
  }, timeout: Timeout.none);

  group('debug mode logpoints', () {
    /// A helper that tests a LogPoint using [logMessage] and expecting the
    /// script not to pause and [expectedMessage] to show up in the output.
    Future<void> _testLogPoint(
      DapTestSession dap,
      String logMessage,
      String expectedMessage,
    ) async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final outputEventsFuture = client.outputEvents.toList();

      await client.doNotHitBreakpoint(
        testFile,
        breakpointLine,
        logMessage: logMessage,
      );

      final outputEvents = await outputEventsFuture;
      final outputMessages = outputEvents.map((e) => e.output.trim());

      expect(
        outputMessages,
        contains(expectedMessage),
      );
    }

    test('print simple messages', () async {
      await _testLogPoint(
        dap,
        r'This is a test message',
        'This is a test message',
      );
    });

    test('print messages with Dart interpolation', () async {
      await _testLogPoint(
        dap,
        r'This is a test message in ${DateTime(2000, 1, 1).year}',
        'This is a test message in ${DateTime(2000, 1, 1).year}',
      );
    });

    test('print messages with just {braces}', () async {
      await _testLogPoint(
        dap,
        // The DAP spec says "Expressions within {} are interpolated" so in the DA
        // we just prefix them with $ and treat them like other Dart interpolation
        // expressions.
        r'This is a test message in {DateTime(2000, 1, 1).year}',
        'This is a test message in ${DateTime(2000, 1, 1).year}',
      );
    });

    test('allows \\{escaped braces}', () async {
      await _testLogPoint(
        dap,
        // Since we treat things in {braces} as expressions, we need to support
        // escaping them.
        r'This is a test message with \{escaped braces}',
        r'This is a test message with {escaped braces}',
      );
    });

    // These tests can be slow due to starting up the external server process.
  }, timeout: Timeout.none);
}
