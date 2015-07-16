// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_GESTURE_DETECTION_SCALE_GESTURE_LISTENERS_H_
#define UI_EVENTS_GESTURE_DETECTION_SCALE_GESTURE_LISTENERS_H_

#include "ui/events/gesture_detection/gesture_detection_export.h"

namespace ui {

class MotionEvent;
class ScaleGestureDetector;

// Client through which |ScaleGestureDetector| signals scale detection.
class GESTURE_DETECTION_EXPORT ScaleGestureListener {
 public:
  virtual ~ScaleGestureListener() {}
  virtual bool OnScale(const ScaleGestureDetector& detector,
                       const MotionEvent& e) = 0;
  virtual bool OnScaleBegin(const ScaleGestureDetector& detector,
                            const MotionEvent& e) = 0;
  virtual void OnScaleEnd(const ScaleGestureDetector& detector,
                          const MotionEvent& e) = 0;
};

// A convenience class to extend when you only want to listen for a subset of
// scaling-related events. This implements all methods in
// |ScaleGestureListener| but does nothing.
// |OnScale()| returns false so that a subclass can retrieve the accumulated
// scale factor in an overridden |OnScaleEnd()|.
// |OnScaleBegin() returns true.
class GESTURE_DETECTION_EXPORT SimpleScaleGestureListener
    : public ScaleGestureListener {
 public:
  // ScaleGestureListener implementation.
  bool OnScale(const ScaleGestureDetector&, const MotionEvent&) override;
  bool OnScaleBegin(const ScaleGestureDetector&, const MotionEvent&) override;
  void OnScaleEnd(const ScaleGestureDetector&, const MotionEvent&) override;
};

}  // namespace ui

#endif  // UI_EVENTS_GESTURE_DETECTION_SCALE_GESTURE_LISTENERS_H_
