// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';

import '../utils.dart';

void sharedTests() {
  test('ready does not complete until after subscription', () async {
    var watcher = createWatcher();

    var ready = false;
    unawaited(watcher.ready.then((_) {
      ready = true;
    }));
    await pumpEventQueue();

    expect(ready, isFalse);

    // Subscribe to the events.
    var subscription = watcher.events.listen((event) {});

    await watcher.ready;

    // Should eventually be ready.
    expect(watcher.isReady, isTrue);

    await subscription.cancel();
  });

  test('ready completes immediately when already ready', () async {
    var watcher = createWatcher();

    // Subscribe to the events.
    var subscription = watcher.events.listen((event) {});

    // Allow watcher to become ready
    await watcher.ready;

    // Ensure ready completes immediately
    expect(
        watcher.ready.timeout(Duration(milliseconds: 0),
            onTimeout: () => throw 'Does not complete immedately'),
        completes);

    await subscription.cancel();
  });

  test('ready returns a future that does not complete after unsubscribing',
      () async {
    var watcher = createWatcher();

    // Subscribe to the events.
    var subscription = watcher.events.listen((event) {});

    // Wait until ready.
    await watcher.ready;

    // Now unsubscribe.
    await subscription.cancel();

    // Should be back to not ready.
    expect(watcher.ready, doesNotComplete);
  });

  test('completes even if directory does not exist', () async {
    var watcher = createWatcher(path: 'does/not/exist');

    // Subscribe to the events (else ready will never fire).
    var subscription = watcher.events.listen((event) {}, onError: (error) {});

    // Expect ready still completes.
    await watcher.ready;

    // Now unsubscribe.
    await subscription.cancel();
  });
}
