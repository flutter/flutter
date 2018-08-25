// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'arena.dart';
import 'constants.dart';
import 'events.dart';
import 'recognizer.dart';

/// Signature for when a pointer has remained in contact with the screen at the
/// same location for a long period of time.
typedef void GestureLongPressCallback();

/// Recognizes when the user has pressed down at the same location for a long
/// period of time.
class LongPressGestureRecognizer extends PrimaryPointerGestureRecognizer {
  /// Creates a long-press gesture recognizer.
  ///
  /// Consider assigning the [onLongPress] callback after creating this object.
  LongPressGestureRecognizer({ Object debugOwner }) : super(deadline: kLongPressTimeout, debugOwner: debugOwner);

  /// Called when a long-press is recognized.
  GestureLongPressCallback onLongPress;

  @override
  void didExceedDeadline() {
    resolve(GestureDisposition.accepted);
    if (onLongPress != null)
      invokeCallback<void>('onLongPress', onLongPress);
  }

  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerUpEvent)
      resolve(GestureDisposition.rejected);
  }

  @override
  String get debugDescription => 'long press';
}
