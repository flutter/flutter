// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// Cycle the event loop to ensure timers are started, then wait for a delay
/// longer than [milliseconds] to allow for the timer to fire.
Future<void> waitForTimer(int milliseconds) =>
    Future(() {/* ensure Timer is started*/})
        .then((_) => Future.delayed(Duration(milliseconds: milliseconds + 1)));

StreamController<T> createController<T>(String streamType) {
  switch (streamType) {
    case 'single subscription':
      return StreamController<T>();
    case 'broadcast':
      return StreamController<T>.broadcast();
    default:
      throw ArgumentError.value(
          streamType, 'streamType', 'Must be one of $streamTypes');
  }
}

const streamTypes = ['single subscription', 'broadcast'];
