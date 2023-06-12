// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:watcher/src/stat.dart';
import 'package:watcher/watcher.dart';

typedef WatcherFactory = Watcher Function(String directory);

/// Sets the function used to create the watcher.
set watcherFactory(WatcherFactory factory) {
  _watcherFactory = factory;
}

/// The mock modification times (in milliseconds since epoch) for each file.
///
/// The actual file system has pretty coarse granularity for file modification
/// times. This means using the real file system requires us to put delays in
/// the tests to ensure we wait long enough between operations for the mod time
/// to be different.
///
/// Instead, we'll just mock that out. Each time a file is written, we manually
/// increment the mod time for that file instantly.
final _mockFileModificationTimes = <String, int>{};

late WatcherFactory _watcherFactory;

/// Creates a new [Watcher] that watches a temporary file or directory.
///
/// If [path] is provided, watches a subdirectory in the sandbox with that name.
Watcher createWatcher({String? path}) {
  if (path == null) {
    path = d.sandbox;
  } else {
    path = p.join(d.sandbox, path);
  }

  return _watcherFactory(path);
}

/// The stream of events from the watcher started with [startWatcher].
late StreamQueue<WatchEvent> _watcherEvents;

/// Whether the event stream has been closed.
///
/// If this is not done by a test (by calling [startClosingEventStream]) it will
/// be done automatically via [addTearDown] in [startWatcher].
var _hasClosedStream = true;

/// Creates a new [Watcher] that watches a temporary file or directory and
/// starts monitoring it for events.
///
/// If [path] is provided, watches a path in the sandbox with that name.
Future<void> startWatcher({String? path}) async {
  mockGetModificationTime((path) {
    final normalized = p.normalize(p.relative(path, from: d.sandbox));

    // Make sure we got a path in the sandbox.
    assert(p.isRelative(normalized) && !normalized.startsWith('..'),
        'Path is not in the sandbox: $path not in ${d.sandbox}');

    var mtime = _mockFileModificationTimes[normalized];
    return DateTime.fromMillisecondsSinceEpoch(mtime ?? 0);
  });

  // We want to wait until we're ready *after* we subscribe to the watcher's
  // events.
  var watcher = createWatcher(path: path);
  _watcherEvents = StreamQueue(watcher.events);
  // Forces a subscription to the underlying stream.
  unawaited(_watcherEvents.hasNext);

  _hasClosedStream = false;
  addTearDown(startClosingEventStream);

  await watcher.ready;
}

/// Schedule closing the watcher stream after the event queue has been pumped.
///
/// This is necessary when events are allowed to occur, but don't have to occur,
/// at the end of a test. Otherwise, if they don't occur, the test will wait
/// indefinitely because they might in the future and because the watcher is
/// normally only closed after the test completes.
void startClosingEventStream() async {
  if (_hasClosedStream) return;
  _hasClosedStream = true;
  await pumpEventQueue();
  await _watcherEvents.cancel(immediate: true);
}

/// A list of [StreamMatcher]s that have been collected using
/// [_collectStreamMatcher].
List<StreamMatcher>? _collectedStreamMatchers;

/// Collects all stream matchers that are registered within [block] into a
/// single stream matcher.
///
/// The returned matcher will match each of the collected matchers in order.
StreamMatcher _collectStreamMatcher(void Function() block) {
  var oldStreamMatchers = _collectedStreamMatchers;
  var collectedStreamMatchers = _collectedStreamMatchers = <StreamMatcher>[];
  try {
    block();
    return emitsInOrder(collectedStreamMatchers);
  } finally {
    _collectedStreamMatchers = oldStreamMatchers;
  }
}

/// Either add [streamMatcher] as an expectation to [_watcherEvents], or collect
/// it with [_collectStreamMatcher].
///
/// [streamMatcher] can be a [StreamMatcher], a [Matcher], or a value.
Future _expectOrCollect(streamMatcher) {
  var collectedStreamMatchers = _collectedStreamMatchers;
  if (collectedStreamMatchers != null) {
    collectedStreamMatchers.add(emits(streamMatcher));
    return Future.sync(() {});
  } else {
    return expectLater(_watcherEvents, emits(streamMatcher));
  }
}

/// Expects that [matchers] will match emitted events in any order.
///
/// [matchers] may be [Matcher]s or values, but not [StreamMatcher]s.
Future inAnyOrder(Iterable matchers) {
  matchers = matchers.toSet();
  return _expectOrCollect(emitsInAnyOrder(matchers));
}

/// Expects that the expectations established in either [block1] or [block2]
/// will match the emitted events.
///
/// If both blocks match, the one that consumed more events will be used.
Future allowEither(void Function() block1, void Function() block2) =>
    _expectOrCollect(emitsAnyOf(
        [_collectStreamMatcher(block1), _collectStreamMatcher(block2)]));

/// Allows the expectations established in [block] to match the emitted events.
///
/// If the expectations in [block] don't match, no error will be raised and no
/// events will be consumed. If this is used at the end of a test,
/// [startClosingEventStream] should be called before it.
Future allowEvents(void Function() block) =>
    _expectOrCollect(mayEmit(_collectStreamMatcher(block)));

/// Returns a StreamMatcher that matches a [WatchEvent] with the given [type]
/// and [path].
Matcher isWatchEvent(ChangeType type, String path) {
  return predicate((e) {
    return e is WatchEvent &&
        e.type == type &&
        e.path == p.join(d.sandbox, p.normalize(path));
  }, 'is $type $path');
}

/// Returns a [Matcher] that matches a [WatchEvent] for an add event for [path].
Matcher isAddEvent(String path) => isWatchEvent(ChangeType.ADD, path);

/// Returns a [Matcher] that matches a [WatchEvent] for a modification event for
/// [path].
Matcher isModifyEvent(String path) => isWatchEvent(ChangeType.MODIFY, path);

/// Returns a [Matcher] that matches a [WatchEvent] for a removal event for
/// [path].
Matcher isRemoveEvent(String path) => isWatchEvent(ChangeType.REMOVE, path);

/// Expects that the next event emitted will be for an add event for [path].
Future expectAddEvent(String path) =>
    _expectOrCollect(isWatchEvent(ChangeType.ADD, path));

/// Expects that the next event emitted will be for a modification event for
/// [path].
Future expectModifyEvent(String path) =>
    _expectOrCollect(isWatchEvent(ChangeType.MODIFY, path));

/// Expects that the next event emitted will be for a removal event for [path].
Future expectRemoveEvent(String path) =>
    _expectOrCollect(isWatchEvent(ChangeType.REMOVE, path));

/// Consumes a modification event for [path] if one is emitted at this point in
/// the schedule, but doesn't throw an error if it isn't.
///
/// If this is used at the end of a test, [startClosingEventStream] should be
/// called before it.
Future allowModifyEvent(String path) =>
    _expectOrCollect(mayEmit(isWatchEvent(ChangeType.MODIFY, path)));

/// Schedules writing a file in the sandbox at [path] with [contents].
///
/// If [contents] is omitted, creates an empty file. If [updateModified] is
/// `false`, the mock file modification time is not changed.
void writeFile(String path, {String? contents, bool? updateModified}) {
  contents ??= '';
  updateModified ??= true;

  var fullPath = p.join(d.sandbox, path);

  // Create any needed subdirectories.
  var dir = Directory(p.dirname(fullPath));
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  File(fullPath).writeAsStringSync(contents);

  if (updateModified) {
    path = p.normalize(path);

    _mockFileModificationTimes.update(path, (value) => value + 1,
        ifAbsent: () => 1);
  }
}

/// Schedules deleting a file in the sandbox at [path].
void deleteFile(String path) {
  File(p.join(d.sandbox, path)).deleteSync();
}

/// Schedules renaming a file in the sandbox from [from] to [to].
void renameFile(String from, String to) {
  File(p.join(d.sandbox, from)).renameSync(p.join(d.sandbox, to));

  // Make sure we always use the same separator on Windows.
  to = p.normalize(to);

  _mockFileModificationTimes.update(to, (value) => value + 1,
      ifAbsent: () => 1);
}

/// Schedules creating a directory in the sandbox at [path].
void createDir(String path) {
  Directory(p.join(d.sandbox, path)).createSync();
}

/// Schedules renaming a directory in the sandbox from [from] to [to].
void renameDir(String from, String to) {
  Directory(p.join(d.sandbox, from)).renameSync(p.join(d.sandbox, to));
}

/// Schedules deleting a directory in the sandbox at [path].
void deleteDir(String path) {
  Directory(p.join(d.sandbox, path)).deleteSync(recursive: true);
}

/// Runs [callback] with every permutation of non-negative numbers for each
/// argument less than [limit].
///
/// Returns a set of all values returns by [callback].
///
/// [limit] defaults to 3.
Set<S> withPermutations<S>(S Function(int, int, int) callback, {int? limit}) {
  limit ??= 3;
  var results = <S>{};
  for (var i = 0; i < limit; i++) {
    for (var j = 0; j < limit; j++) {
      for (var k = 0; k < limit; k++) {
        results.add(callback(i, j, k));
      }
    }
  }
  return results;
}
