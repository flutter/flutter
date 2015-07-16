// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <vector>

#include "base/basictypes.h"
#include "base/time/time.h"
#include "ui/events/gesture_detection/motion_event_generic.h"
#include "ui/gfx/geometry/point_f.h"

namespace ui {
namespace test {

struct MockMotionEvent : public MotionEventGeneric {
  enum { TOUCH_MAJOR = 10 };

  MockMotionEvent();
  explicit MockMotionEvent(Action action);
  MockMotionEvent(Action action, base::TimeTicks time, float x, float y);
  MockMotionEvent(Action action,
                  base::TimeTicks time,
                  float x0,
                  float y0,
                  float x1,
                  float y1);
  MockMotionEvent(Action action,
                  base::TimeTicks time,
                  float x0,
                  float y0,
                  float x1,
                  float y1,
                  float x2,
                  float y2);
  MockMotionEvent(Action action,
                  base::TimeTicks time,
                  const std::vector<gfx::PointF>& positions);
  MockMotionEvent(const MockMotionEvent& other);

  ~MockMotionEvent() override;

  // MotionEvent methods.
  scoped_ptr<MotionEvent> Clone() const override;
  scoped_ptr<MotionEvent> Cancel() const override;

  // Utility methods.
  void PressPoint(float x, float y);
  void MovePoint(size_t index, float x, float y);
  void ReleasePoint();
  void CancelPoint();
  void SetTouchMajor(float new_touch_major);
  void SetRawOffset(float raw_offset_x, float raw_offset_y);
  void SetToolType(size_t index, ToolType tool_type);

 private:
  void PushPointer(float x, float y);
  void ResolvePointers();
};

}  // namespace test
}  // namespace ui
