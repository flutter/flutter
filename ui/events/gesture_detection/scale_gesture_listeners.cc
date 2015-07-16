// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/gesture_detection/scale_gesture_listeners.h"

namespace ui {

bool SimpleScaleGestureListener::OnScale(const ScaleGestureDetector&,
                                         const MotionEvent&) {
  return false;
}

bool SimpleScaleGestureListener::OnScaleBegin(const ScaleGestureDetector&,
                                              const MotionEvent&) {
  return true;
}

void SimpleScaleGestureListener::OnScaleEnd(const ScaleGestureDetector&,
                                            const MotionEvent&) {
}

}  // namespace ui
