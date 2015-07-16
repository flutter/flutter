// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// MSVC++ requires this to be set before any other includes to get M_PI.
#define _USE_MATH_DEFINES

#include <cmath>

#include "testing/gtest/include/gtest/gtest.h"
#include "ui/events/event.h"
#include "ui/events/gestures/motion_event_impl.h"

namespace {

ui::TouchEvent TouchWithType(ui::EventType type, int id) {
  return ui::TouchEvent(
      type, gfx::PointF(0, 0), id, base::TimeDelta::FromMilliseconds(0));
}

ui::TouchEvent TouchWithPosition(ui::EventType type,
                                 int id,
                                 float x,
                                 float y,
                                 float raw_x,
                                 float raw_y) {
  ui::TouchEvent event(type,
                       gfx::PointF(x, y),
                       0,
                       id,
                       base::TimeDelta::FromMilliseconds(0),
                       0,
                       0,
                       0,
                       0);
  event.set_root_location(gfx::PointF(raw_x, raw_y));
  return event;
}

ui::TouchEvent TouchWithTapParams(ui::EventType type,
                                 int id,
                                 float radius_x,
                                 float radius_y,
                                 float rotation_angle,
                                 float pressure) {
  ui::TouchEvent event(type,
                       gfx::PointF(1, 1),
                       0,
                       id,
                       base::TimeDelta::FromMilliseconds(0),
                       radius_x,
                       radius_y,
                       rotation_angle,
                       pressure);
  event.set_root_location(gfx::PointF(1, 1));
  return event;
}

ui::TouchEvent TouchWithTime(ui::EventType type, int id, int ms) {
  return ui::TouchEvent(
      type, gfx::PointF(0, 0), id, base::TimeDelta::FromMilliseconds(ms));
}

base::TimeTicks MsToTicks(int ms) {
  return base::TimeTicks() + base::TimeDelta::FromMilliseconds(ms);
}

}  // namespace

namespace ui {

TEST(MotionEventImplTest, PointerCountAndIds) {
  // Test that |PointerCount()| returns the correct number of pointers, and ids
  // are assigned correctly.
  int ids[] = {4, 6, 1};

  MotionEventImpl event;
  EXPECT_EQ(0U, event.GetPointerCount());

  TouchEvent press0 = TouchWithType(ET_TOUCH_PRESSED, ids[0]);
  event.OnTouch(press0);
  EXPECT_EQ(1U, event.GetPointerCount());

  EXPECT_EQ(ids[0], event.GetPointerId(0));

  TouchEvent press1 = TouchWithType(ET_TOUCH_PRESSED, ids[1]);
  event.OnTouch(press1);
  EXPECT_EQ(2U, event.GetPointerCount());

  EXPECT_EQ(ids[0], event.GetPointerId(0));
  EXPECT_EQ(ids[1], event.GetPointerId(1));

  TouchEvent press2 = TouchWithType(ET_TOUCH_PRESSED, ids[2]);
  event.OnTouch(press2);
  EXPECT_EQ(3U, event.GetPointerCount());

  EXPECT_EQ(ids[0], event.GetPointerId(0));
  EXPECT_EQ(ids[1], event.GetPointerId(1));
  EXPECT_EQ(ids[2], event.GetPointerId(2));

  TouchEvent release1 = TouchWithType(ET_TOUCH_RELEASED, ids[1]);
  event.OnTouch(release1);
  event.CleanupRemovedTouchPoints(release1);
  EXPECT_EQ(2U, event.GetPointerCount());

  EXPECT_EQ(ids[0], event.GetPointerId(0));
  EXPECT_EQ(ids[2], event.GetPointerId(1));

  // Test cloning of pointer count and id information.
  // TODO(mustaq): Make a separate clone test
  scoped_ptr<MotionEvent> clone = event.Clone();
  EXPECT_EQ(2U, clone->GetPointerCount());
  EXPECT_EQ(ids[0], clone->GetPointerId(0));
  EXPECT_EQ(ids[2], clone->GetPointerId(1));

  TouchEvent release0 = TouchWithType(ET_TOUCH_RELEASED, ids[0]);
  event.OnTouch(release0);
  event.CleanupRemovedTouchPoints(release0);
  EXPECT_EQ(1U, event.GetPointerCount());

  EXPECT_EQ(ids[2], event.GetPointerId(0));

  TouchEvent release2 = TouchWithType(ET_TOUCH_RELEASED, ids[2]);
  event.OnTouch(release2);
  event.CleanupRemovedTouchPoints(release2);
  EXPECT_EQ(0U, event.GetPointerCount());
}

TEST(MotionEventImplTest, GetActionIndexAfterRemoval) {
  // Test that |GetActionIndex()| returns the correct index when points have
  // been removed.
  int ids[] = {4, 6, 9};

  MotionEventImpl event;
  EXPECT_EQ(0U, event.GetPointerCount());

  TouchEvent press0 = TouchWithType(ET_TOUCH_PRESSED, ids[0]);
  event.OnTouch(press0);
  TouchEvent press1 = TouchWithType(ET_TOUCH_PRESSED, ids[1]);
  event.OnTouch(press1);
  TouchEvent press2 = TouchWithType(ET_TOUCH_PRESSED, ids[2]);
  event.OnTouch(press2);
  EXPECT_EQ(3U, event.GetPointerCount());

  TouchEvent release1 = TouchWithType(ET_TOUCH_RELEASED, ids[1]);
  event.OnTouch(release1);
  event.CleanupRemovedTouchPoints(release1);
  EXPECT_EQ(1, event.GetActionIndex());
  EXPECT_EQ(2U, event.GetPointerCount());

  TouchEvent release2 = TouchWithType(ET_TOUCH_RELEASED, ids[0]);
  event.OnTouch(release2);
  event.CleanupRemovedTouchPoints(release2);
  EXPECT_EQ(0, event.GetActionIndex());
  EXPECT_EQ(1U, event.GetPointerCount());

  TouchEvent release0 = TouchWithType(ET_TOUCH_RELEASED, ids[2]);
  event.OnTouch(release0);
  event.CleanupRemovedTouchPoints(release0);
  EXPECT_EQ(0U, event.GetPointerCount());
}

TEST(MotionEventImplTest, PointerLocations) {
  // Test that location information is stored correctly.
  MotionEventImpl event;

  const float kRawOffsetX = 11.1f;
  const float kRawOffsetY = 13.3f;

  int ids[] = {15, 13};
  float x;
  float y;
  float raw_x;
  float raw_y;

  x = 14.4f;
  y = 17.3f;
  raw_x = x + kRawOffsetX;
  raw_y = y + kRawOffsetY;
  TouchEvent press0 =
      TouchWithPosition(ET_TOUCH_PRESSED, ids[0], x, y, raw_x, raw_y);
  event.OnTouch(press0);

  EXPECT_EQ(1U, event.GetPointerCount());
  EXPECT_FLOAT_EQ(x, event.GetX(0));
  EXPECT_FLOAT_EQ(y, event.GetY(0));
  EXPECT_FLOAT_EQ(raw_x, event.GetRawX(0));
  EXPECT_FLOAT_EQ(raw_y, event.GetRawY(0));

  x = 17.8f;
  y = 12.1f;
  raw_x = x + kRawOffsetX;
  raw_y = y + kRawOffsetY;
  TouchEvent press1 =
      TouchWithPosition(ET_TOUCH_PRESSED, ids[1], x, y, raw_x, raw_y);
  event.OnTouch(press1);

  EXPECT_EQ(2U, event.GetPointerCount());
  EXPECT_FLOAT_EQ(x, event.GetX(1));
  EXPECT_FLOAT_EQ(y, event.GetY(1));
  EXPECT_FLOAT_EQ(raw_x, event.GetRawX(1));
  EXPECT_FLOAT_EQ(raw_y, event.GetRawY(1));

  // Test cloning of pointer location information.
  scoped_ptr<MotionEvent> clone = event.Clone();
  {
    const MotionEventImpl* raw_clone_aura =
        static_cast<MotionEventImpl*>(clone.get());
    EXPECT_EQ(2U, raw_clone_aura->GetPointerCount());
    EXPECT_FLOAT_EQ(x, raw_clone_aura->GetX(1));
    EXPECT_FLOAT_EQ(y, raw_clone_aura->GetY(1));
    EXPECT_FLOAT_EQ(raw_x, raw_clone_aura->GetRawX(1));
    EXPECT_FLOAT_EQ(raw_y, raw_clone_aura->GetRawY(1));
  }

  x = 27.9f;
  y = 22.3f;
  raw_x = x + kRawOffsetX;
  raw_y = y + kRawOffsetY;
  TouchEvent move1 =
      TouchWithPosition(ET_TOUCH_MOVED, ids[1], x, y, raw_x, raw_y);
  event.OnTouch(move1);

  EXPECT_FLOAT_EQ(x, event.GetX(1));
  EXPECT_FLOAT_EQ(y, event.GetY(1));
  EXPECT_FLOAT_EQ(raw_x, event.GetRawX(1));
  EXPECT_FLOAT_EQ(raw_y, event.GetRawY(1));

  x = 34.6f;
  y = 23.8f;
  raw_x = x + kRawOffsetX;
  raw_y = y + kRawOffsetY;
  TouchEvent move0 =
      TouchWithPosition(ET_TOUCH_MOVED, ids[0], x, y, raw_x, raw_y);
  event.OnTouch(move0);

  EXPECT_FLOAT_EQ(x, event.GetX(0));
  EXPECT_FLOAT_EQ(y, event.GetY(0));
  EXPECT_FLOAT_EQ(raw_x, event.GetRawX(0));
  EXPECT_FLOAT_EQ(raw_y, event.GetRawY(0));
}

TEST(MotionEventImplTest, TapParams) {
  // Test that touch params are stored correctly.
  MotionEventImpl event;

  int ids[] = {15, 13};

  float radius_x;
  float radius_y;
  float rotation_angle;
  float pressure;

  radius_x = 123.45f;
  radius_y = 67.89f;
  rotation_angle = 23.f;
  pressure = 0.123f;
  TouchEvent press0 = TouchWithTapParams(
      ET_TOUCH_PRESSED, ids[0], radius_x, radius_y, rotation_angle, pressure);
  event.OnTouch(press0);

  EXPECT_EQ(1U, event.GetPointerCount());
  EXPECT_FLOAT_EQ(radius_x, event.GetTouchMajor(0) / 2);
  EXPECT_FLOAT_EQ(radius_y, event.GetTouchMinor(0) / 2);
  EXPECT_FLOAT_EQ(rotation_angle, event.GetOrientation(0) * 180 / M_PI + 90);
  EXPECT_FLOAT_EQ(pressure, event.GetPressure(0));

  radius_x = 67.89f;
  radius_y = 123.45f;
  rotation_angle = 46.f;
  pressure = 0.456f;
  TouchEvent press1 = TouchWithTapParams(
      ET_TOUCH_PRESSED, ids[1], radius_x, radius_y, rotation_angle, pressure);
  event.OnTouch(press1);

  EXPECT_EQ(2U, event.GetPointerCount());
  EXPECT_FLOAT_EQ(radius_y, event.GetTouchMajor(1) / 2);
  EXPECT_FLOAT_EQ(radius_x, event.GetTouchMinor(1) / 2);
  EXPECT_FLOAT_EQ(rotation_angle, event.GetOrientation(1) * 180 / M_PI);
  EXPECT_FLOAT_EQ(pressure, event.GetPressure(1));

  // Test cloning of tap params
  scoped_ptr<MotionEvent> clone = event.Clone();
  {
    const MotionEventImpl* raw_clone_aura =
        static_cast<MotionEventImpl*>(clone.get());
    EXPECT_EQ(2U, raw_clone_aura->GetPointerCount());
    EXPECT_FLOAT_EQ(radius_y, raw_clone_aura->GetTouchMajor(1) / 2);
    EXPECT_FLOAT_EQ(radius_x, raw_clone_aura->GetTouchMinor(1) / 2);
    EXPECT_FLOAT_EQ(
        rotation_angle, raw_clone_aura->GetOrientation(1) * 180 / M_PI);
    EXPECT_FLOAT_EQ(pressure, raw_clone_aura->GetPressure(1));
  }

  radius_x = 76.98f;
  radius_y = 321.54f;
  rotation_angle = 64.f;
  pressure = 0.654f;
  TouchEvent move1 = TouchWithTapParams(
      ET_TOUCH_MOVED, ids[1], radius_x, radius_y, rotation_angle, pressure);
  event.OnTouch(move1);

  EXPECT_EQ(2U, event.GetPointerCount());
  EXPECT_FLOAT_EQ(radius_y, event.GetTouchMajor(1) / 2);
  EXPECT_FLOAT_EQ(radius_x, event.GetTouchMinor(1) / 2);
  EXPECT_FLOAT_EQ(rotation_angle, event.GetOrientation(1) * 180 / M_PI);
  EXPECT_FLOAT_EQ(pressure, event.GetPressure(1));
}

TEST(MotionEventImplTest, Timestamps) {
  // Test that timestamp information is stored and converted correctly.
  MotionEventImpl event;
  int ids[] = {7, 13};
  int times_in_ms[] = {59436, 60263, 82175};

  TouchEvent press0 = TouchWithTime(
      ui::ET_TOUCH_PRESSED, ids[0], times_in_ms[0]);
  event.OnTouch(press0);
  EXPECT_EQ(MsToTicks(times_in_ms[0]), event.GetEventTime());

  TouchEvent press1 = TouchWithTime(
      ui::ET_TOUCH_PRESSED, ids[1], times_in_ms[1]);
  event.OnTouch(press1);
  EXPECT_EQ(MsToTicks(times_in_ms[1]), event.GetEventTime());

  TouchEvent move0 = TouchWithTime(
      ui::ET_TOUCH_MOVED, ids[0], times_in_ms[2]);
  event.OnTouch(move0);
  EXPECT_EQ(MsToTicks(times_in_ms[2]), event.GetEventTime());

  // Test cloning of timestamp information.
  scoped_ptr<MotionEvent> clone = event.Clone();
  EXPECT_EQ(MsToTicks(times_in_ms[2]), clone->GetEventTime());
}

TEST(MotionEventImplTest, CachedAction) {
  // Test that the cached action and cached action index are correct.
  int ids[] = {4, 6};
  MotionEventImpl event;

  TouchEvent press0 = TouchWithType(ET_TOUCH_PRESSED, ids[0]);
  event.OnTouch(press0);
  EXPECT_EQ(MotionEvent::ACTION_DOWN, event.GetAction());
  EXPECT_EQ(1U, event.GetPointerCount());

  TouchEvent press1 = TouchWithType(ET_TOUCH_PRESSED, ids[1]);
  event.OnTouch(press1);
  EXPECT_EQ(MotionEvent::ACTION_POINTER_DOWN, event.GetAction());
  EXPECT_EQ(1, event.GetActionIndex());
  EXPECT_EQ(2U, event.GetPointerCount());

  // Test cloning of CachedAction information.
  scoped_ptr<MotionEvent> clone = event.Clone();
  EXPECT_EQ(MotionEvent::ACTION_POINTER_DOWN, clone->GetAction());
  EXPECT_EQ(1, clone->GetActionIndex());

  TouchEvent move0 = TouchWithType(ET_TOUCH_MOVED, ids[0]);
  event.OnTouch(move0);
  EXPECT_EQ(MotionEvent::ACTION_MOVE, event.GetAction());
  EXPECT_EQ(2U, event.GetPointerCount());

  TouchEvent release0 = TouchWithType(ET_TOUCH_RELEASED, ids[0]);
  event.OnTouch(release0);
  EXPECT_EQ(MotionEvent::ACTION_POINTER_UP, event.GetAction());
  EXPECT_EQ(2U, event.GetPointerCount());
  event.CleanupRemovedTouchPoints(release0);
  EXPECT_EQ(1U, event.GetPointerCount());

  TouchEvent release1 = TouchWithType(ET_TOUCH_RELEASED, ids[1]);
  event.OnTouch(release1);
  EXPECT_EQ(MotionEvent::ACTION_UP, event.GetAction());
  EXPECT_EQ(1U, event.GetPointerCount());
  event.CleanupRemovedTouchPoints(release1);
  EXPECT_EQ(0U, event.GetPointerCount());
}

TEST(MotionEventImplTest, Cancel) {
  int ids[] = {4, 6};
  MotionEventImpl event;

  TouchEvent press0 = TouchWithType(ET_TOUCH_PRESSED, ids[0]);
  event.OnTouch(press0);
  EXPECT_EQ(MotionEvent::ACTION_DOWN, event.GetAction());
  EXPECT_EQ(1U, event.GetPointerCount());

  TouchEvent press1 = TouchWithType(ET_TOUCH_PRESSED, ids[1]);
  event.OnTouch(press1);
  EXPECT_EQ(MotionEvent::ACTION_POINTER_DOWN, event.GetAction());
  EXPECT_EQ(1, event.GetActionIndex());
  EXPECT_EQ(2U, event.GetPointerCount());

  scoped_ptr<MotionEvent> cancel = event.Cancel();
  EXPECT_EQ(MotionEvent::ACTION_CANCEL, cancel->GetAction());
  EXPECT_EQ(2U, static_cast<MotionEventImpl*>(cancel.get())->GetPointerCount());
}

TEST(MotionEventImplTest, ToolType) {
  MotionEventImpl event;

  // For now, all pointers have an unknown tool type.
  // TODO(jdduke): Expand this test when ui::TouchEvent identifies the source
  // touch type, crbug.com/404128.
  event.OnTouch(TouchWithType(ET_TOUCH_PRESSED, 7));
  ASSERT_EQ(1U, event.GetPointerCount());
  EXPECT_EQ(MotionEvent::TOOL_TYPE_UNKNOWN, event.GetToolType(0));
}

TEST(MotionEventImplTest, Flags) {
  int ids[] = {7, 11};
  MotionEventImpl event;

  TouchEvent press0 = TouchWithType(ET_TOUCH_PRESSED, ids[0]);
  press0.set_flags(EF_CONTROL_DOWN);
  event.OnTouch(press0);
  EXPECT_EQ(EF_CONTROL_DOWN, event.GetFlags());

  TouchEvent press1 = TouchWithType(ET_TOUCH_PRESSED, ids[1]);
  press1.set_flags(EF_CONTROL_DOWN | EF_CAPS_LOCK_DOWN);
  event.OnTouch(press1);
  EXPECT_EQ(EF_CONTROL_DOWN | EF_CAPS_LOCK_DOWN, event.GetFlags());
}

}  // namespace ui
