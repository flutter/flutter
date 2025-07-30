// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import '../src/common.dart';
import 'test_data/hot_restart_with_paused_child_isolate_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;
  final project = HotRestartWithPausedChildIsolateProject();
  late FlutterRunTestDriver flutter;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('hot_restart_test.');
    await project.setUpIn(tempDir);
    flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    await flutter.stop();
    tryToDelete(tempDir);
  });

  // Possible regression test for https://github.com/flutter/flutter/issues/161466
  testWithoutContext("Hot restart doesn't hang when an unhandled exception is "
      'thrown in the UI isolate', () async {
    await flutter.run(withDebugger: true, startPaused: true, pauseOnExceptions: true);
    final VmService vmService = await vmServiceConnectUri(flutter.vmServiceWsUri.toString());
    final Isolate root = await flutter.getFlutterIsolate();

    // The UI isolate has already started paused. Setup a listener for the
    // child isolate that will spawn when the isolate resumes. Resume the
    // spawned child which will pause on start, and then wait for it to execute
    // the `debugger()` call.
    final childIsolatePausedCompleter = Completer<void>();
    vmService.onDebugEvent.listen((Event event) async {
      if (event.kind == EventKind.kPauseStart) {
        await vmService.resume(event.isolate!.id!);
      } else if (event.kind == EventKind.kPauseBreakpoint) {
        if (!childIsolatePausedCompleter.isCompleted) {
          await vmService.streamCancel(EventStreams.kDebug);
          childIsolatePausedCompleter.complete();
        }
      }
    });
    await vmService.streamListen(EventStreams.kDebug);

    await vmService.resume(root.id!);
    await childIsolatePausedCompleter.future;

    // This call will fail to return if the UI isolate pauses on an unhandled
    // exception due to the isolate spawned by `Isolate.run` not completing.
    await flutter.hotRestart();
  });
}
