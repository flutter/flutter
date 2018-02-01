// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:process/process.dart';
import 'package:process/record_replay.dart';

import 'common.dart';
import 'context.dart';
import 'file_system.dart';
import 'process.dart';

const String _kRecordingType = 'process';
const ProcessManager _kLocalProcessManager = const LocalProcessManager();

/// The active process manager.
ProcessManager get processManager {
  return context == null
      ? _kLocalProcessManager
      : context[ProcessManager];
}

/// Enables recording of process invocation activity to the specified base
/// recording [location].
///
/// This sets the [active process manager](processManager) to one that records
/// all process activity before delegating to a [LocalProcessManager].
///
/// Activity will be recorded in a subdirectory of [location] named `"process"`.
/// It is permissible for [location] to represent an existing non-empty
/// directory as long as there is no collision with the `"process"`
/// subdirectory.
void enableRecordingProcessManager(String location) {
  final ProcessManager originalProcessManager = processManager;
  final Directory dir = getRecordingSink(location, _kRecordingType);
  const ProcessManager delegate = const LocalProcessManager();
  final RecordingProcessManager manager = new RecordingProcessManager(delegate, dir);
  addShutdownHook(() async {
    await manager.flush(finishRunningProcesses: true);
    context.setVariable(ProcessManager, originalProcessManager);
  }, ShutdownStage.SERIALIZE_RECORDING);
  context.setVariable(ProcessManager, manager);
}

/// Enables process invocation replay mode.
///
/// This sets the [active process manager](processManager) to one that replays
/// process activity from a previously recorded set of invocations.
///
/// [location] must represent a directory to which process activity has been
/// recorded (i.e. the result of having been previously passed to
/// [enableRecordingProcessManager]), or a [ToolExit] will be thrown.
Future<Null> enableReplayProcessManager(String location) async {
  final Directory dir = getReplaySource(location, _kRecordingType);

  ProcessManager manager;
  try {
    manager = await ReplayProcessManager.create(dir,
      // TODO(tvolkert): Once https://github.com/flutter/flutter/issues/7166 is
      //     resolved, we can use the default `streamDelay`. In the
      //     meantime, native file I/O operations cause our `tail` process
      //     streams to flush before our protocol discovery is listening on
      //     them, causing us to timeout waiting for the observatory port.
      streamDelay: const Duration(milliseconds: 50),
    );
  } on ArgumentError catch (error) {
    throwToolExit('Invalid replay-from: $error');
  }

  context.setVariable(ProcessManager, manager);
}
