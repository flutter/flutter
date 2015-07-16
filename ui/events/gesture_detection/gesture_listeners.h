// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_GESTURE_DETECTION_GESTURE_LISTENERS_H_
#define UI_EVENTS_GESTURE_DETECTION_GESTURE_LISTENERS_H_

#include "ui/events/gesture_detection/gesture_detection_export.h"

namespace ui {

class MotionEvent;

// Client through which |GestureDetector| signals gesture detection.
class GESTURE_DETECTION_EXPORT GestureListener {
 public:
  virtual ~GestureListener() {}
  virtual bool OnDown(const MotionEvent& e) = 0;
  virtual void OnShowPress(const MotionEvent& e) = 0;
  virtual bool OnSingleTapUp(const MotionEvent& e) = 0;
  virtual void OnLongPress(const MotionEvent& e) = 0;
  virtual bool OnScroll(const MotionEvent& e1,
                        const MotionEvent& e2,
                        float distance_x,
                        float distance_y) = 0;
  virtual bool OnFling(const MotionEvent& e1,
                       const MotionEvent& e2,
                       float velocity_x,
                       float velocity_y) = 0;
  // Added for Chromium (Aura).
  virtual bool OnSwipe(const MotionEvent& e1,
                       const MotionEvent& e2,
                       float velocity_x,
                       float velocity_y) = 0;
  virtual bool OnTwoFingerTap(const MotionEvent& e1, const MotionEvent& e2) = 0;
};

// Client through which |GestureDetector| signals double-tap detection.
class GESTURE_DETECTION_EXPORT DoubleTapListener {
 public:
  virtual ~DoubleTapListener() {}
  virtual bool OnSingleTapConfirmed(const MotionEvent& e) = 0;
  virtual bool OnDoubleTap(const MotionEvent& e) = 0;
  virtual bool OnDoubleTapEvent(const MotionEvent& e) = 0;
};

// A convenience class to extend when you only want to listen for a subset
// of all the gestures. This implements all methods in the
// |GestureListener| and |DoubleTapListener| but does
// nothing and returns false for all applicable methods.
class GESTURE_DETECTION_EXPORT SimpleGestureListener
    : public GestureListener,
      public DoubleTapListener {
 public:
  // GestureListener implementation.
  bool OnDown(const MotionEvent& e) override;
  void OnShowPress(const MotionEvent& e) override;
  bool OnSingleTapUp(const MotionEvent& e) override;
  void OnLongPress(const MotionEvent& e) override;
  bool OnScroll(const MotionEvent& e1,
                const MotionEvent& e2,
                float distance_x,
                float distance_y) override;
  bool OnFling(const MotionEvent& e1,
               const MotionEvent& e2,
               float velocity_x,
               float velocity_y) override;
  bool OnSwipe(const MotionEvent& e1,
               const MotionEvent& e2,
               float velocity_x,
               float velocity_y) override;
  bool OnTwoFingerTap(const MotionEvent& e1, const MotionEvent& e2) override;

  // DoubleTapListener implementation.
  bool OnSingleTapConfirmed(const MotionEvent& e) override;
  bool OnDoubleTap(const MotionEvent& e) override;
  bool OnDoubleTapEvent(const MotionEvent& e) override;
};

}  // namespace ui

#endif  // UI_EVENTS_GESTURE_DETECTION_GESTURE_LISTENERS_H_
