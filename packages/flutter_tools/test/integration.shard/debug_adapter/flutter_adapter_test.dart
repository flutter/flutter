// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:dds/src/dap/protocol_generated.dart';
import 'package:file/file.dart';
import 'package:flutter_tools/src/cache.dart';

import '../../src/common.dart';
import '../test_data/basic_project.dart';
import '../test_data/compile_error_project.dart';
import '../test_utils.dart';
import 'test_client.dart';
import 'test_support.dart';

void main() {
  Directory tempDir;
  /*late*/ DapTestSession dap;
  final String relativeMainPath = 'lib${fileSystem.path.separator}main.dart';

  setUpAll(() {
    Cache.flutterRoot = getFlutterRoot();
  });

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('flutter_adapter_test.');
    dap = await DapTestSession.setUp();
  });

  tearDown(() async {
    await dap.tearDown();
    tryToDelete(tempDir);
  });

  testWithoutContext('can run and terminate a Flutter app in debug mode', () async {
    final BasicProject _project = BasicProject();
    await _project.setUpIn(tempDir);

    // Once the "topLevelFunction" output arrives, we can terminate the app.
    unawaited(
      dap.client.outputEvents
          .firstWhere((OutputEventBody output) => output.output.startsWith('topLevelFunction'))
          .whenComplete(() => dap.client.terminate()),
    );

    final List<OutputEventBody> outputEvents = await dap.client.collectAllOutput(
      launch: () => dap.client
          .launch(
            cwd: _project.dir.path,
            toolArgs: <String>['-d', 'flutter-tester'],
          ),
    );

    final String output = _uniqueOutputLines(outputEvents);

    expectLines(output, <Object>[
      'Launching $relativeMainPath on Flutter test device in debug mode...',
      startsWith('Connecting to VM Service at'),
      'topLevelFunction',
      '',
      startsWith('Exited'),
    ]);
  });

  testWithoutContext('can run and terminate a Flutter app in noDebug mode', () async {
    final BasicProject _project = BasicProject();
    await _project.setUpIn(tempDir);

    // Once the "topLevelFunction" output arrives, we can terminate the app.
    unawaited(
      dap.client.outputEvents
          .firstWhere((OutputEventBody output) => output.output.startsWith('topLevelFunction'))
          .whenComplete(() => dap.client.terminate()),
    );

    final List<OutputEventBody> outputEvents = await dap.client.collectAllOutput(
      launch: () => dap.client
          .launch(
            cwd: _project.dir.path,
            noDebug: true,
            toolArgs: <String>['-d', 'flutter-tester'],
          ),
    );

    final String output = _uniqueOutputLines(outputEvents);

    expectLines(output, <Object>[
      'Launching $relativeMainPath on Flutter test device in debug mode...',
      'topLevelFunction',
      '',
      startsWith('Exited'),
    ]);
  });

  testWithoutContext('correctly outputs launch errors and terminates', () async {
    final CompileErrorProject _project = CompileErrorProject();
    await _project.setUpIn(tempDir);

    final List<OutputEventBody> outputEvents = await dap.client.collectAllOutput(
      launch: () => dap.client
          .launch(
            cwd: _project.dir.path,
            toolArgs: <String>['-d', 'flutter-tester'],
          ),
    );

    final String output = _uniqueOutputLines(outputEvents);
    expect(output, contains('this code does not compile'));
    expect(output, contains('Exception: Failed to build'));
    expect(output, contains('Exited (1)'));
  });

  testWithoutContext('can hot reload', () async {
    final BasicProject _project = BasicProject();
    await _project.setUpIn(tempDir);

    // Launch the app and wait for it to print "topLevelFunction".
    await Future.wait(<Future<Object>>[
      dap.client.outputEvents.firstWhere((OutputEventBody output) => output.output.startsWith('topLevelFunction')),
      dap.client.start(
        launch: () => dap.client.launch(
          cwd: _project.dir.path,
          noDebug: true,
          toolArgs: <String>['-d', 'flutter-tester'],
        ),
      ),
    ], eagerError: true);

    // Capture the next two output events that we expect to be the Reload
    // notification and then topLevelFunction being printed again.
    final Future<List<String>> outputEventsFuture = dap.client.output
        // But skip any topLevelFunctions that come before the reload.
        .skipWhile((String output) => output.startsWith('topLevelFunction'))
        .take(2)
        .toList();

    await dap.client.hotReload();

    expectLines(
        (await outputEventsFuture).join(),
        <Object>[
          startsWith('Reloaded'),
          'topLevelFunction',
        ],
    );

    await dap.client.terminate();
  });

  testWithoutContext('can hot restart', () async {
    final BasicProject _project = BasicProject();
    await _project.setUpIn(tempDir);

    // Launch the app and wait for it to print "topLevelFunction".
    await Future.wait(<Future<Object>>[
      dap.client.outputEvents.firstWhere((OutputEventBody output) => output.output.startsWith('topLevelFunction')),
      dap.client.start(
        launch: () => dap.client.launch(
          cwd: _project.dir.path,
          noDebug: true,
          toolArgs: <String>['-d', 'flutter-tester'],
        ),
      ),
    ], eagerError: true);

    // Capture the next two output events that we expect to be the Restart
    // notification and then topLevelFunction being printed again.
    final Future<List<String>> outputEventsFuture = dap.client.output
        // But skip any topLevelFunctions that come before the restart.
        .skipWhile((String output) => output.startsWith('topLevelFunction'))
        .take(2)
        .toList();

    await dap.client.hotRestart();

    expectLines(
        (await outputEventsFuture).join(),
        <Object>[
          startsWith('Restarted application'),
          'topLevelFunction',
        ],
    );

    await dap.client.terminate();
  });

  testWithoutContext('can hot restart when exceptions occur on outgoing isolates', () async {
    final BasicProjectThatThrows _project = BasicProjectThatThrows();
    await _project.setUpIn(tempDir);

    // Launch the app and wait for it to stop at an exception.
    int originalThreadId, newThreadId;
    await Future.wait(<Future<Object>>[
      // Capture the thread ID of the stopped thread.
      dap.client.stoppedEvents.first.then((StoppedEventBody event) => originalThreadId = event.threadId),
      dap.client.start(
        exceptionPauseMode: 'All', // Ensure we stop on all exceptions
        launch: () => dap.client.launch(
          cwd: _project.dir.path,
          toolArgs: <String>['-d', 'flutter-tester'],
        ),
      ),
    ], eagerError: true);

    // Hot restart, ensuring it completes and capturing the ID of the new thread
    // to pause.
    await Future.wait(<Future<Object>>[
      // Capture the thread ID of the newly stopped thread.
      dap.client.stoppedEvents.first.then((StoppedEventBody event) => newThreadId = event.threadId),
      dap.client.hotRestart(),
    ], eagerError: true);

    // We should not have stopped on the original thread, but the new thread
    // from after the restart.
    expect(newThreadId, isNot(equals(originalThreadId)));

    await dap.client.terminate();
  });

  testWithoutContext('sends events for extension state updates', () async {
    final BasicProject _project = BasicProject();
    await _project.setUpIn(tempDir);
    const String debugPaintRpc = 'ext.flutter.debugPaint';

    // Create a future to capture the isolate ID when the debug paint service
    // extension loads, as we'll need that to call it later.
    final Future<String> isolateIdForDebugPaint = dap.client
        .serviceExtensionAdded(debugPaintRpc)
        .then((Map<String, Object/*?*/> body) => body['isolateId'] as String);

    // Launch the app and wait for it to print "topLevelFunction" so we know
    // it's up and running.
    await Future.wait(<Future<Object>>[
      dap.client.outputEvents.firstWhere((OutputEventBody output) =>
          output.output.startsWith('topLevelFunction')),
      dap.client.start(
        launch: () => dap.client.launch(
          cwd: _project.dir.path,
          toolArgs: <String>['-d', 'flutter-tester'],
        ),
      ),
    ], eagerError: true);

    // Capture the next relevant state-change event (which should occur as a
    // result of the call below).
    final Future<Map<String, Object/*?*/>> stateChangeEventFuture =
        dap.client.serviceExtensionStateChanged(debugPaintRpc);

    // Enable debug paint to trigger the state change.
    await dap.client.custom(
      'callService',
      <String, Object/*?*/>{
        'method': debugPaintRpc,
        'params': <String, Object/*?*/>{
          'enabled': true,
          'isolateId': await isolateIdForDebugPaint,
        },
      },
    );

    // Ensure the event occurred, and its value was as expected.
    final Map<String, Object/*?*/> stateChangeEvent = await stateChangeEventFuture;
    expect(stateChangeEvent['value'], 'true'); // extension state change values are always strings

    await dap.client.terminate();
  });
}

/// Extracts the output from a set of [OutputEventBody], removing any
/// adjacent duplicates and combining into a single string.
String _uniqueOutputLines(List<OutputEventBody> outputEvents) {
  String/*?*/ lastItem;
  return outputEvents
      .map((OutputEventBody e) => e.output)
      .where((String output) {
        // Skip the item if it's the same as the previous one.
        final bool isDupe = output == lastItem;
        lastItem = output;
        return !isDupe;
      })
      .join();
}
