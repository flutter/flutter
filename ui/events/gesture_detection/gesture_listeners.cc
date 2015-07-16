// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/gesture_detection/gesture_listeners.h"

namespace ui {

bool SimpleGestureListener::OnDown(const MotionEvent& e) {
  return false;
}

void SimpleGestureListener::OnShowPress(const MotionEvent& e) {
}

bool SimpleGestureListener::OnSingleTapUp(const MotionEvent& e) {
  return false;
}

void SimpleGestureListener::OnLongPress(const MotionEvent& e) {
}

bool SimpleGestureListener::OnScroll(const MotionEvent& e1,
                                     const MotionEvent& e2,
                                     float distance_x,
                                     float distance_y) {
  return false;
}

bool SimpleGestureListener::OnFling(const MotionEvent& e1,
                                    const MotionEvent& e2,
                                    float velocity_x,
                                    float velocity_y) {
  return false;
}

bool SimpleGestureListener::OnSwipe(const MotionEvent& e1,
                                    const MotionEvent& e2,
                                    float velocity_x,
                                    float velocity_y) {
  return false;
}

bool SimpleGestureListener::OnTwoFingerTap(const MotionEvent& e1,
                                           const MotionEvent& e2) {
  return false;
}

bool SimpleGestureListener::OnSingleTapConfirmed(const MotionEvent& e) {
  return false;
}

bool SimpleGestureListener::OnDoubleTap(const MotionEvent& e) {
  return false;
}

bool SimpleGestureListener::OnDoubleTapEvent(const MotionEvent& e) {
  return false;
}

}  // namespace ui
