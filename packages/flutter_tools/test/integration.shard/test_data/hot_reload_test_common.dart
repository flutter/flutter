// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/tester/flutter_tester.dart';
import 'package:flutter_tools/src/web/web_device.dart' show GoogleChromeDevice;
import 'package:vm_service/vm_service.dart';

import '../../src/common.dart';
import '../test_driver.dart';
import '../test_utils.dart';
import 'hot_reload_project.dart';

void testAll({bool chrome = false, List<String> additionalCommandArgs = const <String>[]}) {
  group('chrome: $chrome'
      '${additionalCommandArgs.isEmpty ? '' : ' with args: $additionalCommandArgs'}', () {
    late Directory tempDir;
    final project = HotReloadProject();
    late FlutterRunTestDriver flutter;

    setUp(() async {
      tempDir = createResolvedTempDirectorySync('hot_reload_test.');
      await project.setUpIn(tempDir);
      flutter = FlutterRunTestDriver(tempDir);
    });

    tearDown(() async {
      await flutter.stop();
      tryToDelete(tempDir);
    });

    testWithoutContext('single and multiple hot reloads', () async {
      await runFlutterWithDevice(
        flutter,
        chrome: chrome,
        additionalCommandArgs: additionalCommandArgs,
      );

      // Hot reload works without error.
      await flutter.hotReload();

      // Multiple overlapping hot reloads are debounced and queued.

      // Capture how many *real* hot reloads occur.
      var numReloads = 0;
      final StreamSubscription<void> subscription = flutter.stdout
          .map(parseFlutterResponse)
          .where(_isHotReloadCompletionEvent)
          .listen((_) => numReloads++);

      // To reduce tests flaking, override the debounce timer to something higher than
      // the default to ensure the hot reloads that are supposed to arrive within the
      // debounce period will even on slower CI machines.
      const hotReloadDebounceOverrideMs = 250;
      const delay = Duration(milliseconds: hotReloadDebounceOverrideMs * 2);

      Future<void> doReload([void _]) => flutter.hotReload(
        debounce: true,
        debounceDurationOverrideMs: hotReloadDebounceOverrideMs,
      );

      try {
        await Future.wait<void>(<Future<void>>[
          doReload(),
          doReload(),
          Future<void>.delayed(delay).then(doReload),
          Future<void>.delayed(delay).then(doReload),
        ]);

        // We should only get two reloads, as the first two will have been
        // merged together by the debounce, and the second two also.
        expect(numReloads, equals(2));
      } finally {
        await subscription.cancel();
      }
    });

    testWithoutContext('newly added code executes during hot reload', () async {
      final stdout = StringBuffer();
      final sawTick1 = Completer<void>();
      final sawTick2 = Completer<void>();
      final StreamSubscription<String> subscription = flutter.stdout.listen((String e) {
        stdout.writeln(e);
        // Initial run should run the build method before we try and hot reload.
        if (e.contains('(((TICK 1)))')) {
          sawTick1.complete();
        }
        // If hot reload properly executes newly added code, the 'RELOAD WORKED' message should
        // be printed before 'TICK 2'. If we don't wait for some signal that the build method
        // has executed after the reload, this test can encounter a race.
        if (e.contains('((((TICK 2))))')) {
          sawTick2.complete();
        }
      });
      await runFlutterWithDevice(
        flutter,
        chrome: chrome,
        additionalCommandArgs: additionalCommandArgs,
      );
      await sawTick1.future;
      project.uncommentHotReloadPrint();
      try {
        await flutter.hotReload();
        await sawTick2.future;
        expect(stdout.toString(), contains('(((((RELOAD WORKED)))))'));
      } finally {
        await subscription.cancel();
      }
    });

    testWithoutContext('hot restart works without error', () async {
      await runFlutterWithDevice(
        flutter,
        chrome: chrome,
        verbose: true,
        additionalCommandArgs: additionalCommandArgs,
      );
      await flutter.hotRestart();
    });

    testWithoutContext(
      'breakpoints are hit after hot reload',
      () async {
        Isolate isolate;
        final sawTick1 = Completer<void>();
        final sawDebuggerPausedMessage = Completer<void>();
        final StreamSubscription<String> subscription = flutter.stdout.listen((String line) {
          if (line.contains('((((TICK 1))))')) {
            expect(sawTick1.isCompleted, isFalse);
            sawTick1.complete();
          }
          if (line.contains('The application is paused in the debugger on a breakpoint.')) {
            expect(sawDebuggerPausedMessage.isCompleted, isFalse);
            sawDebuggerPausedMessage.complete();
          }
        });
        await runFlutterWithDevice(
          flutter,
          chrome: chrome,
          withDebugger: true,
          startPaused: true,
          additionalCommandArgs: additionalCommandArgs,
        );
        await flutter
            .resume(); // we start paused so we can set up our TICK 1 listener before the app starts
        unawaited(
          sawTick1.future.timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              // This print is useful for people debugging this test. Normally we would avoid printing
              // in a test but this is an exception because it's useful ambient information.
              // ignore: avoid_print
              print(
                'The test app is taking longer than expected to print its synchronization line...',
              );
            },
          ),
        );
        printOnFailure('waiting for synchronization line...');
        await sawTick1.future; // after this, app is in steady state
        await flutter.addBreakpoint(
          project.scheduledBreakpointUri,
          project.scheduledBreakpointLine,
        );
        await Future<void>.delayed(const Duration(seconds: 2));
        await flutter.hotReload(); // reload triggers code which eventually hits the breakpoint
        isolate = await flutter.waitForPause();
        expect(isolate.pauseEvent?.kind, equals(EventKind.kPauseBreakpoint));
        await flutter.resume();
        await flutter.addBreakpoint(project.buildBreakpointUri, project.buildBreakpointLine);
        var reloaded = false;
        final Future<void> reloadFuture = flutter.hotReload().then((void value) {
          reloaded = true;
        });
        printOnFailure('waiting for pause...');
        isolate = await flutter.waitForPause();
        expect(isolate.pauseEvent?.kind, equals(EventKind.kPauseBreakpoint));
        if (!chrome) {
          // TODO(srujzs): Implement paused event messages for the web.
          // https://github.com/flutter/flutter/issues/162500
          printOnFailure('waiting for debugger message...');
          await sawDebuggerPausedMessage.future;
        }
        expect(reloaded, isFalse);
        printOnFailure('waiting for resume...');
        await flutter.resume();
        printOnFailure('waiting for reload future...');
        await reloadFuture;
        expect(reloaded, isTrue);
        reloaded = false;
        printOnFailure('subscription cancel...');
        await subscription.cancel();
      },
      // Hot reload on web does not reregister breakpoints correctly yet.
      // https://github.com/dart-lang/sdk/issues/60186
      skip: chrome,
    );

    testWithoutContext(
      "hot reload doesn't reassemble if paused",
      () async {
        final sawTick1 = Completer<void>();
        final sawDebuggerPausedMessage1 = Completer<void>();
        final sawDebuggerPausedMessage2 = Completer<void>();
        final StreamSubscription<String> subscription = flutter.stdout.listen((String line) {
          printOnFailure('[LOG]:"$line"');
          if (line.contains('(((TICK 1)))')) {
            expect(sawTick1.isCompleted, isFalse);
            sawTick1.complete();
          }
          if (line.contains('The application is paused in the debugger on a breakpoint.')) {
            expect(sawDebuggerPausedMessage1.isCompleted, isFalse);
            sawDebuggerPausedMessage1.complete();
          }
          if (line.contains(
            'The application is paused in the debugger on a breakpoint; interface might not '
            'update.',
          )) {
            expect(sawDebuggerPausedMessage2.isCompleted, isFalse);
            sawDebuggerPausedMessage2.complete();
          }
        });
        await runFlutterWithDevice(
          flutter,
          chrome: chrome,
          withDebugger: true,
          additionalCommandArgs: additionalCommandArgs,
        );
        await Future<void>.delayed(const Duration(seconds: 1));
        await sawTick1.future;
        await flutter.addBreakpoint(project.buildBreakpointUri, project.buildBreakpointLine);
        var reloaded = false;
        await Future<void>.delayed(const Duration(seconds: 1));
        final Future<void> reloadFuture = flutter.hotReload().then((void value) {
          reloaded = true;
        });
        final Isolate isolate = await flutter.waitForPause();
        expect(isolate.pauseEvent?.kind, equals(EventKind.kPauseBreakpoint));
        expect(reloaded, isFalse);
        // this is the one where it say "uh, you broke into the debugger while reloading"
        await sawDebuggerPausedMessage1.future;
        await reloadFuture; // this is the one where it times out because you're in the debugger
        expect(reloaded, isTrue);
        await flutter.hotReload(); // now we're already paused
        await sawDebuggerPausedMessage2
            .future; // so we just get told that nothing is going to happen
        await flutter.resume();
        await subscription.cancel();
      },
      // On the web, hot reload cannot continue as the browser is paused and there are no multiple
      // isolates, so this test will wait forever.
      skip: chrome,
    );
  });
}

bool _isHotReloadCompletionEvent(Map<String, Object?>? event) {
  return event != null &&
      event['event'] == 'app.progress' &&
      event['params'] != null &&
      (event['params']! as Map<String, Object?>)['progressId'] == 'hot.reload' &&
      (event['params']! as Map<String, Object?>)['finished'] == true;
}

// Helper to run flutter with or without device param based on chrome flag.
Future<void> runFlutterWithDevice(
  FlutterRunTestDriver flutter, {
  required bool chrome,
  bool verbose = false,
  bool withDebugger = false,
  bool startPaused = false,
  List<String> additionalCommandArgs = const <String>[],
}) => flutter.run(
  verbose: verbose,
  withDebugger: withDebugger,
  startPaused: startPaused,
  device: chrome ? GoogleChromeDevice.kChromeDeviceId : FlutterTesterDevices.kTesterDeviceId,
  additionalCommandArgs: additionalCommandArgs,
);
