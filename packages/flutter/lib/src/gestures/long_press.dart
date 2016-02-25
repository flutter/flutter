// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'arena.dart';
import 'constants.dart';
import 'events.dart';
import 'recognizer.dart';

typedef void GestureLongPressCallback();

/// The user has pressed down at this location for a long period of time.
class LongPressGestureRecognizer extends PrimaryPointerGestureRecognizer {
  LongPressGestureRecognizer() : super(deadline: kLongPressTimeout);

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

  String toStringShort() => 'long press';
}
