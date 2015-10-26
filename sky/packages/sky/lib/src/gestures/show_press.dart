// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'arena.dart';
import 'constants.dart';
import 'events.dart';
import 'recognizer.dart';

typedef void GestureShowPressCallback();

class ShowPressGestureRecognizer extends PrimaryPointerGestureRecognizer {
  ShowPressGestureRecognizer({ PointerRouter router, this.onShowPress })
    : super(router: router, deadline: kPressTimeout);

  GestureShowPressCallback onShowPress;

  void didExceedDeadline() {
    // Show press isn't an exclusive gesture. We can recognize a show press
    // as well as another gesture, like a long press.
    resolve(GestureDisposition.rejected);
    onShowPress();
  }

  void handlePrimaryPointer(PointerInputEvent event) {
    if (event.type == 'pointerup')
      resolve(GestureDisposition.rejected);
  }
}
