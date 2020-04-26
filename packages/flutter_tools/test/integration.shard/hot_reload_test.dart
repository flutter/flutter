// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import '../src/common.dart';
import 'test_data/hot_reload_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

final HotReloadProject project = HotReloadProject();

void main() {
  Directory tempDir;
  FlutterRunTestDriver flutter;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('hot_reload_test.');
    await project.setUpIn(tempDir);
    flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    await flutter?.stop();
    tryToDelete(tempDir);
  });

  test('hot reload works without error', () async {
    await flutter.run();
    await flutter.hotReload();
  });

  test('hot restart works without error', () async {
    await flutter.run();
    await flutter.hotRestart();
  });

  test('newly added code executes during hot reload', () async {
    await flutter.run();

    project.uncommentHotReloadPrint();
    unawaited(flutter.hotReload());

    await expectLater(flutter.stdout,
      emitsThrough(contains('(((((RELOAD WORKED)))))')));
  });

  test('reloadMethod triggers hot reload behavior', () async {
    await flutter.run();

    project.uncommentHotReloadPrint();
    final String libraryId = project.buildBreakpointUri.toString();
    unawaited(flutter.reloadMethod(libraryId: libraryId, classId: 'MyApp'));

    await expectLater(flutter.stdout,
      emitsThrough(contains('(((((RELOAD WORKED)))))')));
  });

  test('breakpoints are hit after hot reload', () async {
    final Future<void> didStart = flutter.run(withDebugger: true);
    await expectLater(flutter.stdout,
      emitsThrough(contains('((((TICK 1))))')));

    // Add first breakpoint and verify it is set.
    await didStart;
    await flutter.addBreakpoint(
      project.scheduledBreakpointUri,
      project.scheduledBreakpointLine,
    );

    // reload triggers code which eventually hits the breakpoint
    await flutter.hotReload();
    await flutter.waitForPause();

    // Resume and add a breakpoint to the build method.
    await flutter.resume();
    await flutter.addBreakpoint(
      project.buildBreakpointUri,
      project.buildBreakpointLine,
    );

    // Start a hot reload and verify that we pause.
    final Future<void> pendingHotReload = flutter.hotReload();

    await expectLater(flutter.stdout, emitsThrough(contains(
      'The application is paused in the debugger on a breakpoint.'
    )));
    await flutter.waitForPause();

    // Verify that a resume leads to hot reload completion.
    await flutter.resume();
    await expectLater(pendingHotReload, completes);
  });

  test('hot reload does not reassemble if paused', () async {
    final Future<void> didStart = flutter.run(withDebugger: true);

    await expectLater(flutter.stdout,
      emitsThrough(contains('((((TICK 1))))')));

    await didStart;
    await flutter.addBreakpoint(
      project.buildBreakpointUri,
      project.buildBreakpointLine,
    );

    final Future<void> pendingHotReload = flutter.hotReload();
    await expectLater(flutter.stdout, emitsThrough(contains(
      'The application is paused in the debugger on a breakpoint.'
    )));
    await expectLater(pendingHotReload, completes);

    unawaited(flutter.hotReload());

    await expectLater(flutter.stdout, emitsThrough(contains(
      'The application is paused in the debugger on a breakpoint; '
      'interface might not update.'
    )));
    await flutter.resume();
  });
}
