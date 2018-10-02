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
const ProcessManager _kLocalProcessManager = LocalProcessManager();

/// The active process manager.
ProcessManager get processManager => context[ProcessManager] ?? _kLocalProcessManager;

/// Gets a [ProcessManager] that will record process invocation activity to the
/// specified base recording [location].
///
/// Activity will be recorded in a subdirectory of [location] named `"process"`.
/// It is permissible for [location] to represent an existing non-empty
/// directory as long as there is no collision with the `"process"`
/// subdirectory.
RecordingProcessManager getRecordingProcessManager(String location) {
  final Directory dir = getRecordingSink(location, _kRecordingType);
  const ProcessManager delegate = LocalProcessManager();
  final RecordingProcessManager manager = RecordingProcessManager(delegate, dir);
  addShutdownHook(() async {
    await manager.flush(finishRunningProcesses: true);
  }, ShutdownStage.SERIALIZE_RECORDING);
  return manager;
}

/// Gets a [ProcessManager] that replays process activity from a previously
/// recorded set of invocations.
///
/// [location] must represent a directory to which process activity has been
/// recorded (i.e. the result of having been previously passed to
/// [getRecordingProcessManager]), or a [ToolExit] will be thrown.
Future<ReplayProcessManager> getReplayProcessManager(String location) async {
  final Directory dir = getReplaySource(location, _kRecordingType);

  ProcessManager manager;
  try {
    manager = await ReplayProcessManager.create(dir);
  } on ArgumentError catch (error) {
    throwToolExit('Invalid replay-from: $error');
  }

  return manager;
}
