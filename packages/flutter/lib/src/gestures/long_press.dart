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
  LongPressGestureRecognizer() : super(deadline: kLongPressTimeout);

  /// Called when a long-press is recongized.
  GestureLongPressCallback onLongPress;

  @override
  void didExceedDeadline() {
    resolve(GestureDisposition.accepted);
    if (onLongPress != null)
      invokeCallback<Null>('onLongPress', onLongPress); // ignore: STRONG_MODE_INVALID_CAST_FUNCTION_EXPR, https://github.com/dart-lang/sdk/issues/27504
  }

  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerUpEvent)
      resolve(GestureDisposition.rejected);
  }

  @override
  String toStringShort() => 'long press';
}
