// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import '../utils.dart';

void sharedTests() {
  test('does not notify for changes when there are no subscribers', () async {
    // Note that this test doesn't rely as heavily on the test functions in
    // utils.dart because it needs to be very explicit about when the event
    // stream is and is not subscribed.
    var watcher = createWatcher();
    var queue = StreamQueue(watcher.events);
    unawaited(queue.hasNext);

    var future =
        expectLater(queue, emits(isWatchEvent(ChangeType.ADD, 'file.txt')));
    expect(queue, neverEmits(anything));

    await watcher.ready;

    writeFile('file.txt');

    await future;

    // Unsubscribe.
    await queue.cancel(immediate: true);

    // Now write a file while we aren't listening.
    writeFile('unwatched.txt');

    queue = StreamQueue(watcher.events);
    future =
        expectLater(queue, emits(isWatchEvent(ChangeType.ADD, 'added.txt')));
    expect(queue, neverEmits(isWatchEvent(ChangeType.ADD, 'unwatched.txt')));

    // Wait until the watcher is ready to dispatch events again.
    await watcher.ready;

    // And add a third file.
    writeFile('added.txt');

    // Wait until we get an event for the third file.
    await future;

    await queue.cancel(immediate: true);
  });
}
