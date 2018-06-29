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

/// Signature for when the pointer ends to contat the same location for a long period of time on the screen
typedef void GestureLongPressUpCallback();

/// Recognizes when the user has pressed down at the same location for a long
/// period of time.
class LongPressGestureRecognizer extends PrimaryPointerGestureRecognizer {
  /// Creates a long-press gesture recognizer.
  ///
  /// Consider assigning the [onLongPress] callback after creating this object.
  LongPressGestureRecognizer({ Object debugOwner }) : super(deadline: kLongPressTimeout, debugOwner: debugOwner);

  //is a flag which is used to determine if the longPress action happened
  bool _longPressAccepted = false;

  /// Called when a long-press is recognized.
  GestureLongPressCallback onLongPress;
  /// Called when long-press is recognized and the pointer stops to contact the screen
  GestureLongPressUpCallback onLongPressUp;

  @override
  void didExceedDeadline() {
    resolve(GestureDisposition.accepted);
    _longPressAccepted = true;
    if (onLongPress != null)
      invokeCallback<void>('onLongPress', onLongPress);
  }

  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerUpEvent) {
      /// only accept the event if the pointer is for a longer period of a time on the screen
      /// and the onLongPressUp event is registered
      if( _longPressAccepted == true && onLongPressUp != null ) {
        _longPressAccepted= false;
        resolve(GestureDisposition.accepted);
        invokeCallback<void>('onLongPressUp', onLongPressUp);
      } else {
        resolve(GestureDisposition.rejected);
      }
    }
  }

  @override
  String get debugDescription => 'long press';
}
