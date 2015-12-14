// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'arena.dart';
import 'constants.dart';
import 'events.dart';
import 'pointer_router.dart';
import 'recognizer.dart';

typedef void GestureLongPressCallback();

class LongPressGestureRecognizer extends PrimaryPointerGestureRecognizer {
  LongPressGestureRecognizer({
    PointerRouter router,
    GestureArena gestureArena,
    this.onLongPress
  }) : super(
    router: router,
    gestureArena: gestureArena,
    deadline: kLongPressTimeout
  );

  GestureLongPressCallback onLongPress;

  void didExceedDeadline() {
    resolve(GestureDisposition.accepted);
    if (onLongPress != null)
      onLongPress();
  }

  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerUpEvent)
      resolve(GestureDisposition.rejected);
  }
}
