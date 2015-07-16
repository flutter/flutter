// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/gesture_detection/motion_event.h"

#include "base/logging.h"

namespace ui {

size_t MotionEvent::GetHistorySize() const {
  return 0;
}

base::TimeTicks MotionEvent::GetHistoricalEventTime(
    size_t historical_index) const {
  NOTIMPLEMENTED();
  return base::TimeTicks();
}

float MotionEvent::GetHistoricalTouchMajor(size_t pointer_index,
                                           size_t historical_index) const {
  NOTIMPLEMENTED();
  return 0.f;
}

float MotionEvent::GetHistoricalX(size_t pointer_index,
                                  size_t historical_index) const {
  NOTIMPLEMENTED();
  return 0.f;
}

float MotionEvent::GetHistoricalY(size_t pointer_index,
                                  size_t historical_index) const {
  NOTIMPLEMENTED();
  return 0.f;
}

int MotionEvent::FindPointerIndexOfId(int id) const {
  const size_t pointer_count = GetPointerCount();
  for (size_t i = 0; i < pointer_count; ++i) {
    if (GetPointerId(i) == id)
      return static_cast<int>(i);
  }
  return -1;
}

bool operator==(const MotionEvent& lhs, const MotionEvent& rhs) {
  if (lhs.GetId() != rhs.GetId() || lhs.GetAction() != rhs.GetAction() ||
      lhs.GetActionIndex() != rhs.GetActionIndex() ||
      lhs.GetPointerCount() != rhs.GetPointerCount() ||
      lhs.GetButtonState() != rhs.GetButtonState() ||
      lhs.GetEventTime() != rhs.GetEventTime() ||
      lhs.GetHistorySize() != rhs.GetHistorySize())
    return false;

  for (size_t i = 0; i < lhs.GetPointerCount(); ++i) {
    int rhsi = rhs.FindPointerIndexOfId(lhs.GetPointerId(i));
    if (rhsi == -1)
      return false;

    if (lhs.GetX(i) != rhs.GetX(rhsi) || lhs.GetY(i) != rhs.GetY(rhsi) ||
        lhs.GetRawX(i) != rhs.GetRawX(rhsi) ||
        lhs.GetRawY(i) != rhs.GetRawY(rhsi) ||
        lhs.GetTouchMajor(i) != rhs.GetTouchMajor(rhsi) ||
        lhs.GetTouchMinor(i) != rhs.GetTouchMinor(rhsi) ||
        lhs.GetOrientation(i) != rhs.GetOrientation(rhsi) ||
        lhs.GetPressure(i) != rhs.GetPressure(rhsi) ||
        lhs.GetToolType(i) != rhs.GetToolType(rhsi))
      return false;

    for (size_t h = 0; h < lhs.GetHistorySize(); ++h) {
      if (lhs.GetHistoricalX(i, h) != rhs.GetHistoricalX(rhsi, h) ||
          lhs.GetHistoricalY(i, h) != rhs.GetHistoricalY(rhsi, h) ||
          lhs.GetHistoricalTouchMajor(i, h) !=
              rhs.GetHistoricalTouchMajor(rhsi, h))
        return false;
    }
  }

  for (size_t h = 0; h < lhs.GetHistorySize(); ++h) {
    if (lhs.GetHistoricalEventTime(h) != rhs.GetHistoricalEventTime(h))
      return false;
  }

  return true;
}

bool operator!=(const MotionEvent& lhs, const MotionEvent& rhs) {
  return !(lhs == rhs);
}

}  // namespace ui
