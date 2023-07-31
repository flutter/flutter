// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/workspace/blaze.dart';
import 'package:analyzer/src/workspace/blaze_watcher.dart';
import 'package:async/async.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:watcher/watcher.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BlazeWatcherTest);
  });
}

@reflectiveTest
class BlazeWatcherTest with ResourceProviderMixin {
  late final BlazeWorkspace workspace;

  void test_blazeFileWatcher() async {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
    ]);
    var candidates = [
      convertPath('/workspace/blaze-bin/my/module/test1.dart'),
      convertPath('/workspace/blaze-genfiles/my/module/test1.dart'),
    ];
    var watcher = BlazeFilePoller(resourceProvider, candidates);

    // First do some tests with the first candidate path.
    _addResources([candidates[0]]);

    var event = watcher.poll()!;

    expect(event.type, ChangeType.ADD);
    expect(event.path, candidates[0]);

    modifyFile(candidates[0], 'const foo = 42;');

    event = watcher.poll()!;

    expect(event.type, ChangeType.MODIFY);
    expect(event.path, candidates[0]);

    _deleteResources([candidates[0]]);

    event = watcher.poll()!;

    expect(event.type, ChangeType.REMOVE);
    expect(event.path, candidates[0]);

    // Now check that if we add the *second* candidate, we'll get the
    // notification for it.
    _addResources([candidates[1]]);

    event = watcher.poll()!;

    expect(event.type, ChangeType.ADD);
    expect(event.path, candidates[1]);

    // Next poll should be `null` since there were no changes.
    expect(watcher.poll(), isNull);
  }

  void test_blazeFileWatcherIsolate() async {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
    ]);
    var candidates1 = [
      convertPath('/workspace/blaze-bin/my/module/test1.dart'),
      convertPath('/workspace/blaze-genfiles/my/module/test1.dart'),
    ];
    var candidates2 = [
      convertPath('/workspace/blaze-bin/my/module/test2.dart'),
      convertPath('/workspace/blaze-genfiles/my/module/test2.dart'),
    ];
    var trigger = _MockPollTrigger();
    var recPort = ReceivePort();
    // Note that we provide below a dummy `ReceivePort` that will *not* be used.
    // We'll directly call `handleRequest` to avoid any problems with various
    // interleavings of async functions.
    var dummyRecPort = ReceivePort();
    var watcher = BlazeFileWatcherIsolate(
        dummyRecPort, recPort.sendPort, resourceProvider,
        pollTriggerFactory: (_) => trigger)
      ..start();
    var queue = StreamQueue(recPort);

    await queue.next as BlazeWatcherIsolateStarted;

    watcher.handleRequest(BlazeWatcherStartWatching(
        convertPath('/workspace'),
        BlazeSearchInfo(
            convertPath('/workspace/my/module/test1.dart'), candidates1)));
    watcher.handleRequest(BlazeWatcherStartWatching(
        convertPath('/workspace'),
        BlazeSearchInfo(
            convertPath('/workspace/my/module/test2.dart'), candidates2)));

    // First do some tests with the first candidate path.
    _addResources([candidates1[0]]);

    trigger.controller.add('');
    var events = (await queue.next as BlazeWatcherEvents).events;

    expect(events, hasLength(1));
    expect(events[0].path, candidates1[0]);
    expect(events[0].type, ChangeType.ADD);

    // Now let's take a look at the second file.
    _addResources([candidates2[1]]);

    trigger.controller.add('');
    events = (await queue.next as BlazeWatcherEvents).events;

    expect(events, hasLength(1));
    expect(events[0].path, candidates2[1]);
    expect(events[0].type, ChangeType.ADD);

    expect(watcher.numWatchedFiles(), 2);

    watcher.handleRequest(BlazeWatcherStopWatching(convertPath('/workspace'),
        convertPath('/workspace/my/module/test1.dart')));

    expect(watcher.numWatchedFiles(), 1);

    watcher.handleRequest(BlazeWatcherStopWatching(convertPath('/workspace'),
        convertPath('/workspace/my/module/test2.dart')));

    expect(watcher.numWatchedFiles(), 0);

    watcher.handleRequest(BlazeWatcherShutdownIsolate());
    await watcher.hasFinished;

    // We need to do this manually, since it's the callers responsibility to
    // close this port (the one owned by `watcher` should've been closed when
    // handling the "shutdown" request).
    recPort.close();
  }

  void test_blazeFileWatcherIsolate_multipleWorkspaces() async {
    _addResources([
      '/workspace1/${file_paths.blazeWorkspaceMarker}',
      '/workspace2/${file_paths.blazeWorkspaceMarker}',
    ]);
    var candidates1 = [
      convertPath('/workspace1/blaze-bin/my/module/test1.dart'),
      convertPath('/workspace1/blaze-genfiles/my/module/test1.dart'),
    ];
    var candidates2 = [
      convertPath('/workspace2/blaze-bin/my/module/test2.dart'),
      convertPath('/workspace2/blaze-genfiles/my/module/test2.dart'),
    ];
    _MockPollTrigger? trigger1;
    _MockPollTrigger? trigger2;
    _MockPollTrigger triggerFactory(String workspace) {
      if (workspace == convertPath('/workspace1')) {
        trigger1 = _MockPollTrigger();
        return trigger1!;
      } else if (workspace == convertPath('/workspace2')) {
        trigger2 = _MockPollTrigger();
        return trigger2!;
      } else {
        throw ArgumentError('Got unexpected workspace: `$workspace`');
      }
    }

    var recPort = ReceivePort();
    // Note that we provide below a dummy `ReceivePort` that will *not* be used.
    // We'll directly call `handleRequest` to avoid any problems with various
    // interleavings of async functions.
    var dummyRecPort = ReceivePort();
    var watcher = BlazeFileWatcherIsolate(
        dummyRecPort, recPort.sendPort, resourceProvider,
        pollTriggerFactory: triggerFactory)
      ..start();
    var queue = StreamQueue(recPort);

    await queue.next as BlazeWatcherIsolateStarted;

    watcher.handleRequest(BlazeWatcherStartWatching(
        convertPath('/workspace1'),
        BlazeSearchInfo(
            convertPath('/workspace1/my/module/test1.dart'), candidates1)));
    watcher.handleRequest(BlazeWatcherStartWatching(
        convertPath('/workspace2'),
        BlazeSearchInfo(
            convertPath('/workspace2/my/module/test2.dart'), candidates2)));

    // First do some tests with the first candidate path.
    _addResources([candidates1[0]]);

    trigger1!.controller.add('');
    var events = (await queue.next as BlazeWatcherEvents).events;

    expect(events, hasLength(1));
    expect(events[0].path, candidates1[0]);
    expect(events[0].type, ChangeType.ADD);

    // Now let's take a look at the second file.
    _addResources([candidates2[1]]);

    trigger2!.controller.add('');
    events = (await queue.next as BlazeWatcherEvents).events;

    expect(events, hasLength(1));
    expect(events[0].path, candidates2[1]);
    expect(events[0].type, ChangeType.ADD);

    expect(watcher.numWatchedFiles(), 2);

    watcher.handleRequest(BlazeWatcherStopWatching(convertPath('/workspace1'),
        convertPath('/workspace1/my/module/test1.dart')));

    expect(watcher.numWatchedFiles(), 1);

    watcher.handleRequest(BlazeWatcherStopWatching(convertPath('/workspace2'),
        convertPath('/workspace2/my/module/test2.dart')));

    expect(watcher.numWatchedFiles(), 0);

    watcher.handleRequest(BlazeWatcherShutdownIsolate());
    await watcher.hasFinished;

    // We need to do this manually, since it's the callers responsibility to
    // close this port (the one owned by `watcher` should've been closed when
    // handling the "shutdown" request).
    recPort.close();
  }

  void test_blazeFileWatcherWithFolder() async {
    _addResources([
      '/workspace/${file_paths.blazeWorkspaceMarker}',
    ]);

    // The `_addResources`/`_deleteResources` functions recognize a folder by a
    // trailing `/`, but everywhere else we need to use normalized paths.
    void addFolder(path) => _addResources(['$path/']);
    void deleteFolder(path) => _deleteResources(['$path/']);

    var candidates = [
      convertPath('/workspace/blaze-out'),
      convertPath('/workspace/blaze-out'),
    ];
    var watcher = BlazeFilePoller(resourceProvider, candidates);

    // First do some tests with the first candidate path.
    addFolder(candidates[0]);
    var event = watcher.poll()!;

    expect(event.type, ChangeType.ADD);
    expect(event.path, candidates[0]);

    deleteFolder(candidates[0]);
    event = watcher.poll()!;

    expect(event.type, ChangeType.REMOVE);
    expect(event.path, candidates[0]);

    // Now check that if we add the *second* candidate, we'll get the
    // notification for it.
    addFolder(candidates[1]);
    event = watcher.poll()!;

    expect(event.type, ChangeType.ADD);
    expect(event.path, candidates[1]);

    // Next poll should be `null` since there were no changes.
    expect(watcher.poll(), isNull);
  }

  /// Create new files and directories from [paths].
  void _addResources(List<String> paths) {
    for (String path in paths) {
      if (path.endsWith('/')) {
        newFolder(path.substring(0, path.length - 1));
      } else {
        newFile(path, '');
      }
    }
  }

  /// Create new files and directories from [paths].
  void _deleteResources(List<String> paths) {
    for (String path in paths) {
      if (path.endsWith('/')) {
        deleteFolder(path.substring(0, path.length - 1));
      } else {
        deleteFile(path);
      }
    }
  }
}

class _MockPollTrigger implements PollTrigger {
  final controller = StreamController<Object>();

  @override
  Stream<Object> get stream => controller.stream;

  @override
  void cancel() {
    return;
  }
}
