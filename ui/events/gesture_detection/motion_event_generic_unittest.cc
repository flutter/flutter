// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "testing/gtest/include/gtest/gtest.h"
#include "ui/events/event_constants.h"
#include "ui/events/gesture_detection/motion_event_generic.h"

namespace ui {

TEST(MotionEventGenericTest, Basic) {
  base::TimeTicks event_time = base::TimeTicks::Now();
  MotionEventGeneric event(
      MotionEvent::ACTION_DOWN, event_time, PointerProperties());
  EXPECT_EQ(1U, event.GetPointerCount());
  EXPECT_EQ(0U, event.GetHistorySize());
  EXPECT_EQ(event_time, event.GetEventTime());

  event.PushPointer(PointerProperties(8.3f, 4.7f));
  ASSERT_EQ(2U, event.GetPointerCount());
  EXPECT_EQ(8.3f, event.GetX(1));
  EXPECT_EQ(4.7f, event.GetY(1));

  event.PushPointer(PointerProperties(2.3f, -3.7f));
  ASSERT_EQ(3U, event.GetPointerCount());
  EXPECT_EQ(2.3f, event.GetX(2));
  EXPECT_EQ(-3.7f, event.GetY(2));

  event.set_id(1);
  EXPECT_EQ(1, event.GetId());

  event.set_action(MotionEvent::ACTION_POINTER_DOWN);
  EXPECT_EQ(MotionEvent::ACTION_POINTER_DOWN, event.GetAction());

  event_time += base::TimeDelta::FromMilliseconds(5);
  event.set_event_time(event_time);
  EXPECT_EQ(event_time, event.GetEventTime());

  event.set_button_state(MotionEvent::BUTTON_PRIMARY);
  EXPECT_EQ(MotionEvent::BUTTON_PRIMARY, event.GetButtonState());

  event.set_flags(EF_ALT_DOWN | EF_SHIFT_DOWN);
  EXPECT_EQ(EF_ALT_DOWN | EF_SHIFT_DOWN, event.GetFlags());

  event.set_action_index(1);
  EXPECT_EQ(1, event.GetActionIndex());
}

TEST(MotionEventGenericTest, Clone) {
  MotionEventGeneric event(MotionEvent::ACTION_DOWN,
                           base::TimeTicks::Now(),
                           PointerProperties(8.3f, 4.7f));
  event.set_id(1);
  event.set_button_state(MotionEvent::BUTTON_PRIMARY);

  scoped_ptr<MotionEvent> clone = event.Clone();
  ASSERT_TRUE(clone);
  EXPECT_EQ(event, *clone);
}

TEST(MotionEventGenericTest, Cancel) {
  MotionEventGeneric event(MotionEvent::ACTION_UP,
                           base::TimeTicks::Now(),
                           PointerProperties(8.7f, 4.3f));
  event.set_id(2);
  event.set_button_state(MotionEvent::BUTTON_SECONDARY);

  scoped_ptr<MotionEvent> cancel = event.Cancel();
  event.set_action(MotionEvent::ACTION_CANCEL);
  ASSERT_TRUE(cancel);
  EXPECT_EQ(event, *cancel);
}

TEST(MotionEventGenericTest, FindPointerIndexOfId) {
  base::TimeTicks event_time = base::TimeTicks::Now();
  PointerProperties pointer;
  pointer.id = 0;
  MotionEventGeneric event0(MotionEvent::ACTION_DOWN, event_time, pointer);
  EXPECT_EQ(0, event0.FindPointerIndexOfId(0));
  EXPECT_EQ(-1, event0.FindPointerIndexOfId(1));
  EXPECT_EQ(-1, event0.FindPointerIndexOfId(-1));

  MotionEventGeneric event1(event0);
  pointer.id = 7;
  event1.PushPointer(pointer);
  EXPECT_EQ(0, event1.FindPointerIndexOfId(0));
  EXPECT_EQ(1, event1.FindPointerIndexOfId(7));
  EXPECT_EQ(-1, event1.FindPointerIndexOfId(6));
  EXPECT_EQ(-1, event1.FindPointerIndexOfId(1));

  MotionEventGeneric event2(event1);
  pointer.id = 3;
  event2.PushPointer(pointer);
  EXPECT_EQ(0, event2.FindPointerIndexOfId(0));
  EXPECT_EQ(1, event2.FindPointerIndexOfId(7));
  EXPECT_EQ(2, event2.FindPointerIndexOfId(3));
  EXPECT_EQ(-1, event2.FindPointerIndexOfId(1));
  EXPECT_EQ(-1, event2.FindPointerIndexOfId(2));
}

}  // namespace ui
