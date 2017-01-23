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

/// The active process manager.
ProcessManager get processManager => context[ProcessManager];

/// Enables recording of process invocation activity to the specified location.
///
/// This sets the [active process manager](processManager) to one that records
/// all process activity before delegating to a [LocalProcessManager].
///
/// [location] must either represent a valid, empty directory or a non-existent
/// file system entity, in which case a directory will be created at that path.
/// Process invocation activity will be serialized to opaque files in that
/// directory. The resulting (populated) directory will be suitable for use
/// with [enableReplayProcessManager].
void enableRecordingProcessManager(String location) {
  if (location.isEmpty)
    throwToolExit('record-to location not specified');
  switch (fs.typeSync(location, followLinks: false)) {
    case FileSystemEntityType.FILE:
    case FileSystemEntityType.LINK:
      throwToolExit('record-to location must reference a directory');
      break;
    case FileSystemEntityType.DIRECTORY:
      if (fs.directory(location).listSync(followLinks: false).isNotEmpty)
        throwToolExit('record-to directory must be empty');
      break;
    case FileSystemEntityType.NOT_FOUND:
      fs.directory(location).createSync(recursive: true);
  }
  Directory dir = fs.directory(location);

  ProcessManager delegate = new LocalProcessManager();
  RecordingProcessManager manager = new RecordingProcessManager(delegate, dir);
  addShutdownHook(() async {
    await manager.flush(finishRunningProcesses: true);
  });

  context.setVariable(ProcessManager, manager);
}

/// Enables process invocation replay mode.
///
/// This sets the [active process manager](processManager) to one that replays
/// process activity from a previously recorded set of invocations.
///
/// [location] must represent a directory to which process activity has been
/// recorded (i.e. the result of having been previously passed to
/// [enableRecordingProcessManager]).
Future<Null> enableReplayProcessManager(String location) async {
  if (location.isEmpty)
    throwToolExit('replay-from location not specified');
  Directory dir = fs.directory(location);
  if (!dir.existsSync())
    throwToolExit('replay-from location must reference a directory');

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
