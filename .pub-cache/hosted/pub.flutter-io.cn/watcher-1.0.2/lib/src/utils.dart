// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io';

/// Returns `true` if [error] is a [FileSystemException] for a missing
/// directory.
bool isDirectoryNotFoundException(Object error) {
  if (error is! FileSystemException) return false;

  // See dartbug.com/12461 and tests/standalone/io/directory_error_test.dart.
  var notFoundCode = Platform.operatingSystem == 'windows' ? 3 : 2;
  return error.osError?.errorCode == notFoundCode;
}

/// Returns the union of all elements in each set in [sets].
Set<T> unionAll<T>(Iterable<Set<T>> sets) =>
    sets.fold(<T>{}, (union, set) => union.union(set));

extension BatchEvents<T> on Stream<T> {
  /// Batches all events that are sent at the same time.
  ///
  /// When multiple events are synchronously added to a stream controller, the
  /// [StreamController] implementation uses [scheduleMicrotask] to schedule the
  /// asynchronous firing of each event. In order to recreate the synchronous
  /// batches, this collates all the events that are received in "nearby"
  /// microtasks.
  Stream<List<T>> batchEvents() {
    var batch = Queue<T>();
    return StreamTransformer<T, List<T>>.fromHandlers(
        handleData: (event, sink) {
      batch.add(event);

      // [Timer.run] schedules an event that runs after any microtasks that have
      // been scheduled.
      Timer.run(() {
        if (batch.isEmpty) return;
        sink.add(batch.toList());
        batch.clear();
      });
    }, handleDone: (sink) {
      if (batch.isNotEmpty) {
        sink.add(batch.toList());
        batch.clear();
      }
      sink.close();
    }).bind(this);
  }
}
