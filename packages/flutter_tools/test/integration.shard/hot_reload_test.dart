// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:vm_service/vm_service.dart';

import '../src/common.dart';
import 'test_data/hot_reload_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  Directory tempDir;
  final HotReloadProject _project = HotReloadProject();
  FlutterRunTestDriver _flutter;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('hot_reload_test.');
    await _project.setUpIn(tempDir);
    _flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    await _flutter?.stop();
    tryToDelete(tempDir);
  });

  test('hot reload works without error', () async {
    await _flutter.run();
    await _flutter.hotReload();
  });

  test('newly added code executes during hot reload', () async {
    await _flutter.run();
    _project.uncommentHotReloadPrint();
    final StringBuffer stdout = StringBuffer();
    final StreamSubscription<String> subscription = _flutter.stdout.listen(stdout.writeln);
    try {
      await _flutter.hotReload();
      expect(stdout.toString(), contains('(((((RELOAD WORKED)))))'));
    } finally {
      await subscription.cancel();
    }
  });

  test('hot restart works without error', () async {
    await _flutter.run();
    await _flutter.hotRestart();
  });

  test('breakpoints are hit after hot reload', () async {
    Isolate isolate;
    await _flutter.run(withDebugger: true, startPaused: true);
    final Completer<void> sawTick1 = Completer<void>();
    final Completer<void> sawTick3 = Completer<void>();
    final Completer<void> sawDebuggerPausedMessage = Completer<void>();
    final StreamSubscription<String> subscription = _flutter.stdout.listen(
      (String line) {
        if (line.contains('((((TICK 1))))')) {
          expect(sawTick1.isCompleted, isFalse);
          sawTick1.complete();
        }
        if (line.contains('((((TICK 3))))')) {
          expect(sawTick3.isCompleted, isFalse);
          sawTick3.complete();
        }
        if (line.contains('The application is paused in the debugger on a breakpoint.')) {
          expect(sawDebuggerPausedMessage.isCompleted, isFalse);
          sawDebuggerPausedMessage.complete();
        }
      },
    );
    await _flutter.resume(); // we start paused so we can set up our TICK 1 listener before the app starts
    unawaited(sawTick1.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () { print('The test app is taking longer than expected to print its synchronization line...'); },
    ));
    await sawTick1.future; // after this, app is in steady state
    await _flutter.addBreakpoint(
      _project.scheduledBreakpointUri,
      _project.scheduledBreakpointLine,
    );
    await _flutter.hotReload(); // reload triggers code which eventually hits the breakpoint
    isolate = await _flutter.waitForPause();
    expect(isolate.pauseEvent.kind, equals(EventKind.kPauseBreakpoint));
    await _flutter.resume();
    await _flutter.addBreakpoint(
      _project.buildBreakpointUri,
      _project.buildBreakpointLine,
    );
    bool reloaded = false;
    final Future<void> reloadFuture = _flutter.hotReload().then((void value) { reloaded = true; });
    await sawTick3.future; // this should happen before it pauses
    isolate = await _flutter.waitForPause();
    expect(isolate.pauseEvent.kind, equals(EventKind.kPauseBreakpoint));
    await sawDebuggerPausedMessage.future;
    expect(reloaded, isFalse);
    await _flutter.resume();
    await reloadFuture;
    expect(reloaded, isTrue);
    reloaded = false;
    await subscription.cancel();
  });

  test('hot reload doesn\'t reassemble if paused', () async {
    await _flutter.run(withDebugger: true);
    final Completer<void> sawTick2 = Completer<void>();
    final Completer<void> sawTick3 = Completer<void>();
    final Completer<void> sawDebuggerPausedMessage1 = Completer<void>();
    final Completer<void> sawDebuggerPausedMessage2 = Completer<void>();
    final StreamSubscription<String> subscription = _flutter.stdout.listen(
      (String line) {
        if (line.contains('((((TICK 2))))')) {
          expect(sawTick2.isCompleted, isFalse);
          sawTick2.complete();
        }
        if (line.contains('The application is paused in the debugger on a breakpoint.')) {
          expect(sawDebuggerPausedMessage1.isCompleted, isFalse);
          sawDebuggerPausedMessage1.complete();
        }
        if (line.contains('The application is paused in the debugger on a breakpoint; interface might not update.')) {
          expect(sawDebuggerPausedMessage2.isCompleted, isFalse);
          sawDebuggerPausedMessage2.complete();
        }
      },
    );
    await _flutter.addBreakpoint(
      _project.buildBreakpointUri,
      _project.buildBreakpointLine,
    );
    bool reloaded = false;
    final Future<void> reloadFuture = _flutter.hotReload().then((void value) { reloaded = true; });
    await sawTick2.future; // this should happen before it pauses
    final Isolate isolate = await _flutter.waitForPause();
    expect(isolate.pauseEvent.kind, equals(EventKind.kPauseBreakpoint));
    expect(reloaded, isFalse);
    await sawDebuggerPausedMessage1.future; // this is the one where it say "uh, you broke into the debugger while reloading"
    await reloadFuture; // this is the one where it times out because you're in the debugger
    expect(reloaded, isTrue);
    await _flutter.hotReload(); // now we're already paused
    expect(sawTick3.isCompleted, isFalse);
    await sawDebuggerPausedMessage2.future; // so we just get told that nothing is going to happen
    await _flutter.resume();
    await subscription.cancel();
  });
}
