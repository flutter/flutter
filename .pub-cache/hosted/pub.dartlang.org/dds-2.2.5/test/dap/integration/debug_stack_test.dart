// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

  group('debug mode stack trace', () {
    test('includes expected names and async boundaries', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleAsyncProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      final stack = await client.getValidStack(
        stop.threadId!,
        startFrame: 0,
        numFrames: 8,
      );

      expect(
        stack.stackFrames.map((f) => f.name),
        equals([
          'four',
          'three',
          '<asynchronous gap>',
          'two',
          '<asynchronous gap>',
          'one',
          '<asynchronous gap>',
          'main',
        ]),
      );

      // Ensure async gaps have their presentationHint set to 'label'.
      expect(
        stack.stackFrames.map((f) => f.presentationHint),
        equals([
          null,
          null,
          'label',
          null,
          'label',
          null,
          'label',
          null,
        ]),
      );
    });

    test('only sets canRestart where VM can rewind', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleAsyncProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      final stack = await client.getValidStack(
        stop.threadId!,
        startFrame: 0,
        numFrames: 8,
      );

      expect(
        stack.stackFrames.map((f) => f.canRestart ?? false),
        equals([
          // Top frame cannot be rewound to:
          // https://github.com/dart-lang/sdk/blob/master/runtime/vm/service/service.md#resume
          isFalse,
          // Other frames can
          isTrue,
          // Until after an async boundary
          isFalse,
          isFalse,
          isFalse,
          isFalse,
          isFalse,
          isFalse,
        ]),
      );
    });

    test('deemphasizes SDK frames when debugSdk=false', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(sdkStackFrameProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(
        testFile,
        breakpointLine,
        launch: () => client.launch(testFile.path, debugSdkLibraries: false),
      );
      final stack = await client.getValidStack(
        stop.threadId!,
        startFrame: 0,
        numFrames: 100,
      );

      // Get all frames that are SDK Frames
      final sdkFrames = stack.stackFrames
          .where((frame) => frame.source?.name?.startsWith('dart:') ?? false)
          .toList();
      // Ensure we got some frames for the test to be valid.
      expect(sdkFrames, isNotEmpty);

      for (final sdkFrame in sdkFrames) {
        expect(
          sdkFrame.source?.presentationHint,
          equals('deemphasize'),
          reason: '${sdkFrame.source!.name} should be deemphasized',
        );
      }
    });

    test('does not deemphasize SDK frames when debugSdk=true', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(sdkStackFrameProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(
        testFile,
        breakpointLine,
        launch: () => client.launch(testFile.path, debugSdkLibraries: true),
      );
      final stack = await client.getValidStack(
        stop.threadId!,
        startFrame: 0,
        numFrames: 100,
      );

      // Get all frames that are SDK Frames
      final sdkFrames = stack.stackFrames
          .where((frame) => frame.source?.name?.startsWith('dart:') ?? false)
          .toList();
      // Ensure we got some frames for the test to be valid.
      expect(sdkFrames, isNotEmpty);

      for (final sdkFrame in sdkFrames) {
        expect(
          sdkFrame.source?.presentationHint,
          isNot(equals('deemphasize')),
          reason: '${sdkFrame.source!.name} should not be deemphasized',
        );
        expect(
          sdkFrame.source?.origin,
          equals('from the SDK'),
          reason: '${sdkFrame.source!.name} should be labelled as SDK code',
        );
      }
    });
    // These tests can be slow due to starting up the external server process.
  }, timeout: Timeout.none);
}
