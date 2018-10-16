// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'arena.dart';
import 'constants.dart';
import 'events.dart';
import 'recognizer.dart';

/// Signature for when a pointer has remained in contact with the screen at the
/// same location for a long period of time.
typedef GestureLongPressCallback = void Function();

/// Signature for when a pointer stops contacting the screen after a long press gesture was detected.
typedef GestureLongPressUpCallback = void Function();

/// Recognizes when the user has pressed down at the same location for a long
/// period of time.
class LongPressGestureRecognizer extends PrimaryPointerGestureRecognizer {
  /// Creates a long-press gesture recognizer.
  ///
  /// Consider assigning the [onLongPress] callback after creating this object.
  LongPressGestureRecognizer({ Object debugOwner })
      : super(deadline: kLongPressTimeout, debugOwner: debugOwner);

  bool _longPressAccepted = false;

  /// Called when a long press gesture has been recognized.
  GestureLongPressCallback onLongPress;

  /// Called when the pointer stops contacting the screen after the long-press gesture has been recognized.
  GestureLongPressUpCallback onLongPressUp;

  @override
  void didExceedDeadline() {
    resolve(GestureDisposition.accepted);
    _longPressAccepted = true;
    if (onLongPress != null) {
      invokeCallback<void>('onLongPress', onLongPress);
    }
  }

  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerUpEvent) {
      if (_longPressAccepted == true && onLongPressUp != null) {
        _longPressAccepted = false;
        invokeCallback<void>('onLongPressUp', onLongPressUp);
      } else {
        resolve(GestureDisposition.rejected);
      }
    } else if (event is PointerDownEvent || event is PointerCancelEvent) {
      // the first touch, initialize the  flag with false
      _longPressAccepted = false;
    }
  }

  @override
  String get debugDescription => 'long press';
}
