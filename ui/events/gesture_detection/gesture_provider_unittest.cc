// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/basictypes.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/message_loop/message_loop.h"
#include "base/time/time.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/events/event_constants.h"
#include "ui/events/gesture_detection/gesture_event_data.h"
#include "ui/events/gesture_detection/gesture_provider.h"
#include "ui/events/gesture_detection/motion_event.h"
#include "ui/events/test/mock_motion_event.h"
#include "ui/gfx/geometry/point_f.h"

using base::TimeDelta;
using base::TimeTicks;
using ui::test::MockMotionEvent;

namespace ui {
namespace {

const float kFakeCoordX = 42.f;
const float kFakeCoordY = 24.f;
const TimeDelta kOneSecond = TimeDelta::FromSeconds(1);
const TimeDelta kOneMicrosecond = TimeDelta::FromMicroseconds(1);
const TimeDelta kDeltaTimeForFlingSequences = TimeDelta::FromMilliseconds(5);
const float kMockTouchRadius = MockMotionEvent::TOUCH_MAJOR / 2;
const float kMaxTwoFingerTapSeparation = 300;

GestureProvider::Config CreateDefaultConfig() {
  GestureProvider::Config sConfig;
  // The longpress timeout is non-zero only to indicate ordering with respect to
  // the showpress timeout.
  sConfig.gesture_detector_config.showpress_timeout = base::TimeDelta();
  sConfig.gesture_detector_config.longpress_timeout = kOneMicrosecond;

  // A valid doubletap timeout should always be non-zero. The value is used not
  // only to trigger the timeout that confirms the tap event, but also to gate
  // whether the second tap is in fact a double-tap (using a strict inequality
  // between times for the first up and the second down events). We use 4
  // microseconds simply to allow several intermediate events to occur before
  // the second tap at microsecond intervals.
  sConfig.gesture_detector_config.double_tap_timeout = kOneMicrosecond * 4;
  sConfig.gesture_detector_config.double_tap_min_time = kOneMicrosecond * 2;
  return sConfig;
}

gfx::RectF BoundsForSingleMockTouchAtLocation(float x, float y) {
  float diameter = MockMotionEvent::TOUCH_MAJOR;
  return gfx::RectF(x - diameter / 2, y - diameter / 2, diameter, diameter);
}

}  // namespace

class GestureProviderTest : public testing::Test, public GestureProviderClient {
 public:
  GestureProviderTest() {}
  ~GestureProviderTest() override {}

  static MockMotionEvent ObtainMotionEvent(base::TimeTicks event_time,
                                           MotionEvent::Action action,
                                           float x,
                                           float y) {
    return MockMotionEvent(action, event_time, x, y);
  }

  static MockMotionEvent ObtainMotionEvent(base::TimeTicks event_time,
                                           MotionEvent::Action action,
                                           float x0,
                                           float y0,
                                           float x1,
                                           float y1) {
    return MockMotionEvent(action, event_time, x0, y0, x1, y1);
  }

  static MockMotionEvent ObtainMotionEvent(base::TimeTicks event_time,
                                           MotionEvent::Action action,
                                           float x0,
                                           float y0,
                                           float x1,
                                           float y1,
                                           float x2,
                                           float y2) {
    return MockMotionEvent(action, event_time, x0, y0, x1, y1, x2, y2);
  }

  static MockMotionEvent ObtainMotionEvent(
      base::TimeTicks event_time,
      MotionEvent::Action action,
      const std::vector<gfx::PointF>& positions) {
    switch (positions.size()) {
      case 1:
        return MockMotionEvent(
            action, event_time, positions[0].x(), positions[0].y());
      case 2:
        return MockMotionEvent(action,
                               event_time,
                               positions[0].x(),
                               positions[0].y(),
                               positions[1].x(),
                               positions[1].y());
      case 3:
        return MockMotionEvent(action,
                               event_time,
                               positions[0].x(),
                               positions[0].y(),
                               positions[1].x(),
                               positions[1].y(),
                               positions[2].x(),
                               positions[2].y());
      default:
        CHECK(false) << "MockMotionEvent only supports 1-3 pointers";
        return MockMotionEvent();
    }
  }

  static MockMotionEvent ObtainMotionEvent(base::TimeTicks event_time,
                                           MotionEvent::Action action) {
    return ObtainMotionEvent(event_time, action, kFakeCoordX, kFakeCoordY);
  }

  // Test
  void SetUp() override { SetUpWithConfig(GetDefaultConfig()); }

  void TearDown() override {
    gestures_.clear();
    gesture_provider_.reset();
  }

  // GestureProviderClient
  void OnGestureEvent(const GestureEventData& gesture) override {
    if (gesture.type() == ET_GESTURE_SCROLL_BEGIN)
      active_scroll_begin_event_.reset(new GestureEventData(gesture));
    gestures_.push_back(gesture);
  }

  void SetUpWithConfig(const GestureProvider::Config& config) {
    gesture_provider_.reset(new GestureProvider(config, this));
    gesture_provider_->SetMultiTouchZoomSupportEnabled(false);
  }

  void ResetGestureDetection() {
    CancelActiveTouchSequence();
    gestures_.clear();
  }
  bool CancelActiveTouchSequence() {
    if (!gesture_provider_->current_down_event())
      return false;
    return gesture_provider_->OnTouchEvent(
        *gesture_provider_->current_down_event()->Cancel());
  }

  bool HasReceivedGesture(EventType type) const {
    for (size_t i = 0; i < gestures_.size(); ++i) {
      if (gestures_[i].type() == type)
        return true;
    }
    return false;
  }

  const GestureEventData& GetMostRecentGestureEvent() const {
    EXPECT_FALSE(gestures_.empty());
    return gestures_.back();
  }

  EventType GetMostRecentGestureEventType() const {
    EXPECT_FALSE(gestures_.empty());
    return gestures_.back().type();
  }

  size_t GetReceivedGestureCount() const { return gestures_.size(); }

  const GestureEventData& GetReceivedGesture(size_t index) const {
    EXPECT_LT(index, GetReceivedGestureCount());
    return gestures_[index];
  }

  const GestureEventData* GetActiveScrollBeginEvent() const {
    return active_scroll_begin_event_ ? active_scroll_begin_event_.get() : NULL;
  }

  const GestureProvider::Config& GetDefaultConfig() const {
    static GestureProvider::Config sConfig = CreateDefaultConfig();
    return sConfig;
  }

  float GetTouchSlop() const {
    return GetDefaultConfig().gesture_detector_config.touch_slop;
  }

  float GetMinScalingSpan() const {
    return GetDefaultConfig().scale_gesture_detector_config.min_scaling_span;
  }

  float GetMinSwipeVelocity() const {
    return GetDefaultConfig().gesture_detector_config.minimum_swipe_velocity;
  }

  base::TimeDelta GetLongPressTimeout() const {
    return GetDefaultConfig().gesture_detector_config.longpress_timeout;
  }

  base::TimeDelta GetShowPressTimeout() const {
    return GetDefaultConfig().gesture_detector_config.showpress_timeout;
  }

  base::TimeDelta GetDoubleTapTimeout() const {
    return GetDefaultConfig().gesture_detector_config.double_tap_timeout;
  }

  base::TimeDelta GetDoubleTapMinTime() const {
    return GetDefaultConfig().gesture_detector_config.double_tap_min_time;
  }

  base::TimeDelta GetValidDoubleTapDelay() const {
    return (GetDoubleTapTimeout() + GetDoubleTapMinTime()) / 2;
  }

  void EnableBeginEndTypes() {
    GestureProvider::Config config = GetDefaultConfig();
    config.gesture_begin_end_types_enabled = true;
    SetUpWithConfig(config);
  }

  void EnableSwipe() {
    GestureProvider::Config config = GetDefaultConfig();
    config.gesture_detector_config.swipe_enabled = true;
    SetUpWithConfig(config);
  }

  void EnableTwoFingerTap(float max_distance_for_two_finger_tap,
                          base::TimeDelta two_finger_tap_timeout) {
    GestureProvider::Config config = GetDefaultConfig();
    config.gesture_detector_config.two_finger_tap_enabled = true;
    config.gesture_detector_config.two_finger_tap_max_separation =
        max_distance_for_two_finger_tap;
    config.gesture_detector_config.two_finger_tap_timeout =
        two_finger_tap_timeout;
    SetUpWithConfig(config);
  }

  void SetMinPinchUpdateSpanDelta(float min_pinch_update_span_delta) {
    GestureProvider::Config config = GetDefaultConfig();
    config.scale_gesture_detector_config.min_pinch_update_span_delta =
        min_pinch_update_span_delta;
    SetUpWithConfig(config);
  }

  void SetMinMaxGestureBoundsLength(float min_gesture_bound_length,
                                    float max_gesture_bound_length) {
    GestureProvider::Config config = GetDefaultConfig();
    config.min_gesture_bounds_length = min_gesture_bound_length;
    config.max_gesture_bounds_length = max_gesture_bound_length;
    SetUpWithConfig(config);
  }

  void SetShowPressAndLongPressTimeout(base::TimeDelta showpress_timeout,
                                       base::TimeDelta longpress_timeout) {
    GestureProvider::Config config = GetDefaultConfig();
    config.gesture_detector_config.showpress_timeout = showpress_timeout;
    config.gesture_detector_config.longpress_timeout = longpress_timeout;
    SetUpWithConfig(config);
  }

  bool HasDownEvent() const { return gesture_provider_->current_down_event(); }

 protected:
  void CheckScrollEventSequenceForEndActionType(
      MotionEvent::Action end_action_type) {
    base::TimeTicks event_time = base::TimeTicks::Now();
    const float scroll_to_x = kFakeCoordX + 100;
    const float scroll_to_y = kFakeCoordY + 100;
    int motion_event_id = 0;
    int motion_event_flags = EF_SHIFT_DOWN | EF_CAPS_LOCK_DOWN;

    MockMotionEvent event =
        ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);
    event.set_id(++motion_event_id);
    event.set_flags(motion_event_flags);

    EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
    EXPECT_EQ(motion_event_flags, GetMostRecentGestureEvent().flags);

    event = ObtainMotionEvent(event_time + kOneSecond,
                              MotionEvent::ACTION_MOVE,
                              scroll_to_x,
                              scroll_to_y);
    event.SetToolType(0, MotionEvent::TOOL_TYPE_FINGER);
    event.set_id(++motion_event_id);
    event.set_flags(motion_event_flags);

    EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
    EXPECT_TRUE(gesture_provider_->IsScrollInProgress());
    EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SCROLL_BEGIN));
    EXPECT_EQ(motion_event_id, GetMostRecentGestureEvent().motion_event_id);
    EXPECT_EQ(motion_event_flags, GetMostRecentGestureEvent().flags);
    EXPECT_EQ(event.GetToolType(0),
              GetMostRecentGestureEvent().primary_tool_type);
    EXPECT_EQ(ET_GESTURE_SCROLL_UPDATE, GetMostRecentGestureEventType());
    EXPECT_EQ(BoundsForSingleMockTouchAtLocation(scroll_to_x, scroll_to_y),
              GetMostRecentGestureEvent().details.bounding_box());
    ASSERT_EQ(3U, GetReceivedGestureCount()) << "Only TapDown, "
                                                "ScrollBegin and ScrollBy "
                                                "should have been sent";

    EXPECT_EQ(ET_GESTURE_SCROLL_BEGIN, GetReceivedGesture(1).type());
    EXPECT_EQ(motion_event_id, GetReceivedGesture(1).motion_event_id);
    EXPECT_EQ(event_time + kOneSecond, GetReceivedGesture(1).time)
        << "ScrollBegin should have the time of the ACTION_MOVE";

    event = ObtainMotionEvent(
        event_time + kOneSecond, end_action_type, scroll_to_x, scroll_to_y);
    event.SetToolType(0, MotionEvent::TOOL_TYPE_FINGER);
    event.set_id(++motion_event_id);

    gesture_provider_->OnTouchEvent(event);
    EXPECT_FALSE(gesture_provider_->IsScrollInProgress());
    EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SCROLL_END));
    EXPECT_EQ(ET_GESTURE_SCROLL_END, GetMostRecentGestureEventType());
    EXPECT_EQ(motion_event_id, GetMostRecentGestureEvent().motion_event_id);
    EXPECT_EQ(event.GetToolType(0),
              GetMostRecentGestureEvent().primary_tool_type);
    EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
    EXPECT_EQ(BoundsForSingleMockTouchAtLocation(scroll_to_x, scroll_to_y),
              GetMostRecentGestureEvent().details.bounding_box());
  }

  void OneFingerSwipe(float vx, float vy) {
    std::vector<gfx::Vector2dF> velocities;
    velocities.push_back(gfx::Vector2dF(vx, vy));
    MultiFingerSwipe(velocities);
  }

  void TwoFingerSwipe(float vx0, float vy0, float vx1, float vy1) {
    std::vector<gfx::Vector2dF> velocities;
    velocities.push_back(gfx::Vector2dF(vx0, vy0));
    velocities.push_back(gfx::Vector2dF(vx1, vy1));
    MultiFingerSwipe(velocities);
  }

  void ThreeFingerSwipe(float vx0,
                        float vy0,
                        float vx1,
                        float vy1,
                        float vx2,
                        float vy2) {
    std::vector<gfx::Vector2dF> velocities;
    velocities.push_back(gfx::Vector2dF(vx0, vy0));
    velocities.push_back(gfx::Vector2dF(vx1, vy1));
    velocities.push_back(gfx::Vector2dF(vx2, vy2));
    MultiFingerSwipe(velocities);
  }

  void MultiFingerSwipe(std::vector<gfx::Vector2dF> velocities) {
    ASSERT_GT(velocities.size(), 0U);

    base::TimeTicks event_time = base::TimeTicks::Now();

    std::vector<gfx::PointF> positions(velocities.size());
    for (size_t i = 0; i < positions.size(); ++i)
      positions[i] = gfx::PointF(kFakeCoordX * (i + 1), kFakeCoordY * (i + 1));

    float dt = kDeltaTimeForFlingSequences.InSecondsF();

    // Each pointer down should be a separate event.
    for (size_t i = 0; i < positions.size(); ++i) {
      const size_t pointer_count = i + 1;
      std::vector<gfx::PointF> event_positions(pointer_count);
      event_positions.assign(positions.begin(),
                             positions.begin() + pointer_count);
      MockMotionEvent event =
          ObtainMotionEvent(event_time,
                            pointer_count > 1 ? MotionEvent::ACTION_POINTER_DOWN
                                              : MotionEvent::ACTION_DOWN,
                            event_positions);
      EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
    }

    for (size_t i = 0; i < positions.size(); ++i)
      positions[i] += gfx::ScaleVector2d(velocities[i], dt);
    MockMotionEvent event =
        ObtainMotionEvent(event_time + kDeltaTimeForFlingSequences,
                          MotionEvent::ACTION_MOVE,
                          positions);
    EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

    for (size_t i = 0; i < positions.size(); ++i)
      positions[i] += gfx::ScaleVector2d(velocities[i], dt);
    event = ObtainMotionEvent(event_time + 2 * kDeltaTimeForFlingSequences,
                              MotionEvent::ACTION_MOVE,
                              positions);
    EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

    event = ObtainMotionEvent(event_time + 2 * kDeltaTimeForFlingSequences,
                              MotionEvent::ACTION_POINTER_UP,
                              positions);
    EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  }

  static void RunTasksAndWait(base::TimeDelta delay) {
    base::MessageLoop::current()->PostDelayedTask(
        FROM_HERE, base::MessageLoop::QuitClosure(), delay);
    base::MessageLoop::current()->Run();
  }

  std::vector<GestureEventData> gestures_;
  scoped_ptr<GestureProvider> gesture_provider_;
  scoped_ptr<GestureEventData> active_scroll_begin_event_;
  base::MessageLoopForUI message_loop_;
};

// Verify that a DOWN followed shortly by an UP will trigger a single tap.
TEST_F(GestureProviderTest, GestureTap) {
  base::TimeTicks event_time = base::TimeTicks::Now();
  int motion_event_id = 0;
  int motion_event_flags = EF_CONTROL_DOWN | EF_ALT_DOWN;

  gesture_provider_->SetDoubleTapSupportForPlatformEnabled(false);

  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);
  event.SetToolType(0, MotionEvent::TOOL_TYPE_FINGER);
  event.set_id(++motion_event_id);
  event.set_flags(motion_event_flags);

  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_EQ(event.GetToolType(0),
            GetMostRecentGestureEvent().primary_tool_type);
  EXPECT_EQ(motion_event_flags, GetMostRecentGestureEvent().flags);
  EXPECT_EQ(BoundsForSingleMockTouchAtLocation(kFakeCoordX, kFakeCoordY),
            GetMostRecentGestureEvent().details.bounding_box());

  event = ObtainMotionEvent(event_time + kOneMicrosecond,
                            MotionEvent::ACTION_UP);
  event.SetToolType(0, MotionEvent::TOOL_TYPE_FINGER);
  event.set_id(++motion_event_id);
  event.set_flags(motion_event_flags);

  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP, GetMostRecentGestureEventType());
  // Ensure tap details have been set.
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.tap_count());
  EXPECT_EQ(event.GetToolType(0),
            GetMostRecentGestureEvent().primary_tool_type);
  EXPECT_EQ(motion_event_id, GetMostRecentGestureEvent().motion_event_id);
  EXPECT_EQ(motion_event_flags, GetMostRecentGestureEvent().flags);
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_EQ(BoundsForSingleMockTouchAtLocation(kFakeCoordX, kFakeCoordY),
            GetMostRecentGestureEvent().details.bounding_box());
}

// Verify that a DOWN followed shortly by an UP will trigger
// a ET_GESTURE_TAP_UNCONFIRMED event if double-tap is enabled.
TEST_F(GestureProviderTest, GestureTapWithDelay) {
  base::TimeTicks event_time = base::TimeTicks::Now();
  int motion_event_id = 0;
  int motion_event_flags = EF_CONTROL_DOWN | EF_ALT_DOWN | EF_CAPS_LOCK_DOWN;

  gesture_provider_->SetDoubleTapSupportForPlatformEnabled(true);

  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);
  event.set_id(++motion_event_id);
  event.set_flags(motion_event_flags);

  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(motion_event_id, GetMostRecentGestureEvent().motion_event_id);
  EXPECT_EQ(motion_event_flags, GetMostRecentGestureEvent().flags);
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_EQ(BoundsForSingleMockTouchAtLocation(kFakeCoordX, kFakeCoordY),
            GetMostRecentGestureEvent().details.bounding_box());

  event = ObtainMotionEvent(event_time + kOneMicrosecond,
                            MotionEvent::ACTION_UP);
  event.set_id(++motion_event_id);
  event.set_flags(motion_event_flags);

  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_UNCONFIRMED, GetMostRecentGestureEventType());
  // Ensure tap details have been set.
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.tap_count());
  EXPECT_EQ(motion_event_id, GetMostRecentGestureEvent().motion_event_id);
  EXPECT_EQ(motion_event_flags, GetMostRecentGestureEvent().flags);
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_EQ(BoundsForSingleMockTouchAtLocation(kFakeCoordX, kFakeCoordY),
            GetMostRecentGestureEvent().details.bounding_box());

  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_TAP));
  RunTasksAndWait(GetDoubleTapTimeout());
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_TAP));
}

// Verify that a DOWN followed by a MOVE will trigger fling (but not LONG).
TEST_F(GestureProviderTest, GestureFlingAndCancelLongPress) {
  base::TimeTicks event_time = TimeTicks::Now();
  base::TimeDelta delta_time = kDeltaTimeForFlingSequences;
  int motion_event_id = 0;
  int motion_event_flags = EF_ALT_DOWN;

  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);
  event.set_id(++motion_event_id);
  event.set_flags(motion_event_flags);

  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(motion_event_id, GetMostRecentGestureEvent().motion_event_id);
  EXPECT_EQ(motion_event_flags, GetMostRecentGestureEvent().flags);
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());

  event = ObtainMotionEvent(event_time + delta_time,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX * 10,
                            kFakeCoordY * 10);
  event.set_id(++motion_event_id);
  event.set_flags(motion_event_flags);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  event = ObtainMotionEvent(event_time + delta_time * 2,
                            MotionEvent::ACTION_UP,
                            kFakeCoordX * 10,
                            kFakeCoordY * 10);
  event.set_id(++motion_event_id);
  event.set_flags(motion_event_flags);

  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_SCROLL_FLING_START, GetMostRecentGestureEventType());
  EXPECT_EQ(motion_event_id, GetMostRecentGestureEvent().motion_event_id);
  EXPECT_EQ(motion_event_flags, GetMostRecentGestureEvent().flags);
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_LONG_PRESS));
  EXPECT_EQ(
      BoundsForSingleMockTouchAtLocation(kFakeCoordX * 10, kFakeCoordY * 10),
      GetMostRecentGestureEvent().details.bounding_box());
}

// Verify that for a normal scroll the following events are sent:
// - ET_GESTURE_SCROLL_BEGIN
// - ET_GESTURE_SCROLL_UPDATE
// - ET_GESTURE_SCROLL_END
TEST_F(GestureProviderTest, ScrollEventActionUpSequence) {
  CheckScrollEventSequenceForEndActionType(MotionEvent::ACTION_UP);
}

// Verify that for a cancelled scroll the following events are sent:
// - ET_GESTURE_SCROLL_BEGIN
// - ET_GESTURE_SCROLL_UPDATE
// - ET_GESTURE_SCROLL_END
TEST_F(GestureProviderTest, ScrollEventActionCancelSequence) {
  CheckScrollEventSequenceForEndActionType(MotionEvent::ACTION_CANCEL);
}

// Verify that for a normal fling (fling after scroll) the following events are
// sent:
// - ET_GESTURE_SCROLL_BEGIN
// - ET_SCROLL_FLING_START
TEST_F(GestureProviderTest, FlingEventSequence) {
  base::TimeTicks event_time = base::TimeTicks::Now();
  base::TimeDelta delta_time = kDeltaTimeForFlingSequences;
  int motion_event_id = 0;

  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);
  event.set_id(++motion_event_id);

  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  event = ObtainMotionEvent(event_time + delta_time,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX * 5,
                            kFakeCoordY * 5);
  event.set_id(++motion_event_id);

  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_TRUE(gesture_provider_->IsScrollInProgress());
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SCROLL_BEGIN));
  EXPECT_EQ(ET_GESTURE_SCROLL_UPDATE, GetMostRecentGestureEventType());
  EXPECT_EQ(motion_event_id, GetMostRecentGestureEvent().motion_event_id);
  ASSERT_EQ(3U, GetReceivedGestureCount());
  ASSERT_EQ(ET_GESTURE_SCROLL_BEGIN, GetReceivedGesture(1).type());
  EXPECT_EQ(motion_event_id, GetReceivedGesture(1).motion_event_id);

  // We don't want to take a dependency here on exactly how hints are calculated
  // for a fling (eg. may depend on velocity), so just validate the direction.
  int hint_x = GetReceivedGesture(1).details.scroll_x_hint();
  int hint_y = GetReceivedGesture(1).details.scroll_y_hint();
  EXPECT_TRUE(hint_x > 0 && hint_y > 0 && hint_x > hint_y)
      << "ScrollBegin hint should be in positive X axis";

  event = ObtainMotionEvent(event_time + delta_time * 2,
                            MotionEvent::ACTION_UP,
                            kFakeCoordX * 10,
                            kFakeCoordY * 10);
  event.set_id(++motion_event_id);

  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_FALSE(gesture_provider_->IsScrollInProgress());
  EXPECT_EQ(ET_SCROLL_FLING_START, GetMostRecentGestureEventType());
  EXPECT_EQ(motion_event_id, GetMostRecentGestureEvent().motion_event_id);
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_SCROLL_END));
  EXPECT_EQ(event_time + delta_time * 2, GetMostRecentGestureEvent().time)
      << "FlingStart should have the time of the ACTION_UP";
}

TEST_F(GestureProviderTest, GestureCancelledWhenWindowFocusLost) {
  const base::TimeTicks event_time = TimeTicks::Now();

  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());

  RunTasksAndWait(GetLongPressTimeout() + GetShowPressTimeout() +
                  kOneMicrosecond);
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SHOW_PRESS));
  EXPECT_EQ(ET_GESTURE_LONG_PRESS, GetMostRecentGestureEventType());

  // The long press triggers window focus loss by opening a context menu.
  EXPECT_TRUE(CancelActiveTouchSequence());
  EXPECT_FALSE(HasDownEvent());

  // A final ACTION_UP should have no effect.
  event = ObtainMotionEvent(event_time + kOneMicrosecond * 2,
                            MotionEvent::ACTION_UP);
  EXPECT_FALSE(gesture_provider_->OnTouchEvent(event));
}

TEST_F(GestureProviderTest, NoTapAfterScrollBegins) {
  base::TimeTicks event_time = base::TimeTicks::Now();

  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);

  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  event = ObtainMotionEvent(event_time + kOneMicrosecond,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX + 50,
                            kFakeCoordY + 50);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_SCROLL_UPDATE, GetMostRecentGestureEventType());

  event = ObtainMotionEvent(event_time + kOneSecond,
                            MotionEvent::ACTION_UP,
                            kFakeCoordX + 50,
                            kFakeCoordY + 50);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_SCROLL_END, GetMostRecentGestureEventType());
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_LONG_TAP));
}

TEST_F(GestureProviderTest, DoubleTap) {
  base::TimeTicks event_time = base::TimeTicks::Now();

  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());

  event = ObtainMotionEvent(event_time + kOneMicrosecond,
                            MotionEvent::ACTION_UP,
                            kFakeCoordX,
                            kFakeCoordY);
  gesture_provider_->OnTouchEvent(event);
  EXPECT_EQ(ET_GESTURE_TAP_UNCONFIRMED, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());

  event_time += GetValidDoubleTapDelay();
  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_DOWN,
                            kFakeCoordX,
                            kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());

  // Moving a very small amount of distance should not trigger the double tap
  // drag zoom mode.
  event = ObtainMotionEvent(event_time + kOneMicrosecond,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX,
                            kFakeCoordY + 1);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());

  event = ObtainMotionEvent(event_time + kOneMicrosecond * 2,
                            MotionEvent::ACTION_UP,
                            kFakeCoordX,
                            kFakeCoordY + 1);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  const GestureEventData& double_tap = GetMostRecentGestureEvent();
  EXPECT_EQ(ET_GESTURE_DOUBLE_TAP, double_tap.type());
  // Ensure tap details have been set.
  EXPECT_EQ(10, double_tap.details.bounding_box().width());
  EXPECT_EQ(10, double_tap.details.bounding_box().height());
  EXPECT_EQ(1, double_tap.details.tap_count());
}

TEST_F(GestureProviderTest, DoubleTapDragZoomBasic) {
  const base::TimeTicks down_time_1 = TimeTicks::Now();
  const base::TimeTicks down_time_2 = down_time_1 + GetValidDoubleTapDelay();

  MockMotionEvent event =
      ObtainMotionEvent(down_time_1, MotionEvent::ACTION_DOWN);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  event = ObtainMotionEvent(down_time_1 + kOneMicrosecond,
                            MotionEvent::ACTION_UP,
                            kFakeCoordX,
                            kFakeCoordY);
  gesture_provider_->OnTouchEvent(event);
  EXPECT_EQ(ET_GESTURE_TAP_UNCONFIRMED, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());

  event = ObtainMotionEvent(
      down_time_2, MotionEvent::ACTION_DOWN, kFakeCoordX, kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());

  event = ObtainMotionEvent(down_time_2 + kOneMicrosecond,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX,
                            kFakeCoordY + 100);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SCROLL_BEGIN));
  ASSERT_EQ(ET_GESTURE_PINCH_BEGIN, GetMostRecentGestureEventType());
  EXPECT_EQ(BoundsForSingleMockTouchAtLocation(kFakeCoordX, kFakeCoordY + 100),
            GetMostRecentGestureEvent().details.bounding_box());

  event = ObtainMotionEvent(down_time_2 + kOneMicrosecond * 2,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX,
                            kFakeCoordY + 200);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  ASSERT_EQ(ET_GESTURE_PINCH_UPDATE, GetMostRecentGestureEventType());
  EXPECT_LT(1.f, GetMostRecentGestureEvent().details.scale());
  EXPECT_EQ(BoundsForSingleMockTouchAtLocation(kFakeCoordX, kFakeCoordY + 200),
            GetMostRecentGestureEvent().details.bounding_box());

  event = ObtainMotionEvent(down_time_2 + kOneMicrosecond * 3,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX,
                            kFakeCoordY + 100);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  ASSERT_EQ(ET_GESTURE_PINCH_UPDATE, GetMostRecentGestureEventType());
  EXPECT_GT(1.f, GetMostRecentGestureEvent().details.scale());
  EXPECT_EQ(BoundsForSingleMockTouchAtLocation(kFakeCoordX, kFakeCoordY + 100),
            GetMostRecentGestureEvent().details.bounding_box());

  event = ObtainMotionEvent(down_time_2 + kOneMicrosecond * 4,
                            MotionEvent::ACTION_UP,
                            kFakeCoordX,
                            kFakeCoordY - 200);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_PINCH_END));
  EXPECT_EQ(ET_GESTURE_SCROLL_END, GetMostRecentGestureEventType());
  EXPECT_EQ(BoundsForSingleMockTouchAtLocation(kFakeCoordX, kFakeCoordY - 200),
            GetMostRecentGestureEvent().details.bounding_box());
}

// Generate a scroll gesture and verify that the resulting scroll motion event
// has both absolute and relative position information.
TEST_F(GestureProviderTest, ScrollUpdateValues) {
  const float delta_x = 16;
  const float delta_y = 84;
  const float raw_offset_x = 17.3f;
  const float raw_offset_y = 13.7f;

  const base::TimeTicks event_time = TimeTicks::Now();

  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  // Move twice so that we get two ET_GESTURE_SCROLL_UPDATE events and can
  // compare the relative and absolute coordinates.
  event = ObtainMotionEvent(event_time + kOneMicrosecond,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX - delta_x / 2,
                            kFakeCoordY - delta_y / 2);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  event = ObtainMotionEvent(event_time + kOneMicrosecond * 2,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX - delta_x,
                            kFakeCoordY - delta_y);
  event.SetRawOffset(raw_offset_x, raw_offset_y);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  // Make sure the reported gesture event has all the expected details.
  ASSERT_LT(0U, GetReceivedGestureCount());
  GestureEventData gesture = GetMostRecentGestureEvent();
  EXPECT_EQ(ET_GESTURE_SCROLL_UPDATE, gesture.type());
  EXPECT_EQ(event_time + kOneMicrosecond * 2, gesture.time);
  EXPECT_EQ(kFakeCoordX - delta_x, gesture.x);
  EXPECT_EQ(kFakeCoordY - delta_y, gesture.y);
  EXPECT_EQ(kFakeCoordX - delta_x + raw_offset_x, gesture.raw_x);
  EXPECT_EQ(kFakeCoordY - delta_y + raw_offset_y, gesture.raw_y);
  EXPECT_EQ(1, gesture.details.touch_points());

  // No horizontal delta because of snapping.
  EXPECT_EQ(0, gesture.details.scroll_x());
  EXPECT_EQ(-delta_y / 2, gesture.details.scroll_y());
}

// Verify that fractional scroll deltas are rounded as expected and that
// fractional scrolling doesn't break scroll snapping.
TEST_F(GestureProviderTest, FractionalScroll) {
  const float delta_x = 0.4f;
  const float delta_y = 5.2f;

  const base::TimeTicks event_time = TimeTicks::Now();

  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  // Skip past the touch slop and move back.
  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX,
                            kFakeCoordY + 100);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_MOVE);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  // Now move up slowly, mostly vertically but with a (fractional) bit of
  // horizontal motion.
  for(int i = 1; i <= 10; i++) {
    event = ObtainMotionEvent(event_time + kOneMicrosecond * i,
                              MotionEvent::ACTION_MOVE,
                              kFakeCoordX + delta_x * i,
                              kFakeCoordY + delta_y * i);
    EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

    ASSERT_LT(0U, GetReceivedGestureCount());
    GestureEventData gesture = GetMostRecentGestureEvent();
    EXPECT_EQ(ET_GESTURE_SCROLL_UPDATE, gesture.type());
    EXPECT_EQ(event_time + kOneMicrosecond * i, gesture.time);
    EXPECT_EQ(1, gesture.details.touch_points());

    // Verify that the event co-ordinates are still the precise values we
    // supplied.
    EXPECT_EQ(kFakeCoordX + delta_x * i, gesture.x);
    EXPECT_FLOAT_EQ(kFakeCoordY + delta_y * i, gesture.y);

    // Verify that we're scrolling vertically by the expected amount
    // (modulo rounding).
    EXPECT_GE(gesture.details.scroll_y(), (int)delta_y);
    EXPECT_LE(gesture.details.scroll_y(), ((int)delta_y) + 1);

    // And that there has been no horizontal motion at all.
    EXPECT_EQ(0, gesture.details.scroll_x());
  }
}

// Generate a scroll gesture and verify that the resulting scroll begin event
// has the expected hint values.
TEST_F(GestureProviderTest, ScrollBeginValues) {
  const float delta_x = 13;
  const float delta_y = 89;

  const base::TimeTicks event_time = TimeTicks::Now();

  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  // Move twice such that the first event isn't sufficient to start
  // scrolling on it's own.
  event = ObtainMotionEvent(event_time + kOneMicrosecond,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX + 2,
                            kFakeCoordY + 1);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_FALSE(gesture_provider_->IsScrollInProgress());

  event = ObtainMotionEvent(event_time + kOneMicrosecond * 2,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX + delta_x,
                            kFakeCoordY + delta_y);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_TRUE(gesture_provider_->IsScrollInProgress());

  const GestureEventData* scroll_begin_gesture = GetActiveScrollBeginEvent();
  ASSERT_TRUE(!!scroll_begin_gesture);
  EXPECT_EQ(delta_x, scroll_begin_gesture->details.scroll_x_hint());
  EXPECT_EQ(delta_y, scroll_begin_gesture->details.scroll_y_hint());
}

TEST_F(GestureProviderTest, LongPressAndTapCancelledWhenScrollBegins) {
  base::TimeTicks event_time = base::TimeTicks::Now();

  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  event = ObtainMotionEvent(event_time + kOneMicrosecond,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX * 5,
                            kFakeCoordY * 5);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  event = ObtainMotionEvent(event_time + kOneMicrosecond * 2,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX * 10,
                            kFakeCoordY * 10);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  const base::TimeDelta long_press_timeout =
      GetLongPressTimeout() + GetShowPressTimeout() + kOneMicrosecond;
  RunTasksAndWait(long_press_timeout);

  // No LONG_TAP as the LONG_PRESS timer is cancelled.
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_LONG_PRESS));
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_LONG_TAP));
}

// Verify that LONG_TAP is triggered after LONG_PRESS followed by an UP.
TEST_F(GestureProviderTest, GestureLongTap) {
  base::TimeTicks event_time = base::TimeTicks::Now();

  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  const base::TimeDelta long_press_timeout =
      GetLongPressTimeout() + GetShowPressTimeout() + kOneMicrosecond;
  RunTasksAndWait(long_press_timeout);

  EXPECT_EQ(ET_GESTURE_LONG_PRESS, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_EQ(BoundsForSingleMockTouchAtLocation(kFakeCoordX, kFakeCoordY),
            GetMostRecentGestureEvent().details.bounding_box());

  event = ObtainMotionEvent(event_time + kOneSecond, MotionEvent::ACTION_UP);
  gesture_provider_->OnTouchEvent(event);
  EXPECT_EQ(ET_GESTURE_LONG_TAP, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_EQ(BoundsForSingleMockTouchAtLocation(kFakeCoordX, kFakeCoordY),
            GetMostRecentGestureEvent().details.bounding_box());
}

TEST_F(GestureProviderTest, GestureLongPressDoesNotPreventScrolling) {
  base::TimeTicks event_time = base::TimeTicks::Now();

  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  const base::TimeDelta long_press_timeout =
      GetLongPressTimeout() + GetShowPressTimeout() + kOneMicrosecond;
  RunTasksAndWait(long_press_timeout);

  EXPECT_EQ(ET_GESTURE_LONG_PRESS, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  event = ObtainMotionEvent(event_time + long_press_timeout,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX + 100,
                            kFakeCoordY + 100);
  gesture_provider_->OnTouchEvent(event);

  EXPECT_EQ(ET_GESTURE_SCROLL_UPDATE, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SCROLL_BEGIN));

  event = ObtainMotionEvent(event_time + long_press_timeout,
                            MotionEvent::ACTION_UP);
  gesture_provider_->OnTouchEvent(event);
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_LONG_TAP));
}

TEST_F(GestureProviderTest, NoGestureLongPressDuringDoubleTap) {
  base::TimeTicks event_time = base::TimeTicks::Now();
  int motion_event_id = 0;

  MockMotionEvent event = ObtainMotionEvent(
      event_time, MotionEvent::ACTION_DOWN, kFakeCoordX, kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  event = ObtainMotionEvent(event_time + kOneMicrosecond,
                            MotionEvent::ACTION_UP,
                            kFakeCoordX,
                            kFakeCoordY);
  gesture_provider_->OnTouchEvent(event);
  EXPECT_EQ(ET_GESTURE_TAP_UNCONFIRMED, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());

  event_time += GetValidDoubleTapDelay();
  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_DOWN,
                            kFakeCoordX,
                            kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_TRUE(gesture_provider_->IsDoubleTapInProgress());

  const base::TimeDelta long_press_timeout =
      GetLongPressTimeout() + GetShowPressTimeout() + kOneMicrosecond;
  RunTasksAndWait(long_press_timeout);
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_LONG_PRESS));

  event = ObtainMotionEvent(event_time + long_press_timeout,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX + 20,
                            kFakeCoordY + 20);
  event.set_id(++motion_event_id);

  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_PINCH_BEGIN, GetMostRecentGestureEventType());
  EXPECT_EQ(motion_event_id, GetMostRecentGestureEvent().motion_event_id);
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_TRUE(gesture_provider_->IsDoubleTapInProgress());

  event = ObtainMotionEvent(event_time + long_press_timeout + kOneMicrosecond,
                            MotionEvent::ACTION_UP,
                            kFakeCoordX,
                            kFakeCoordY + 1);
  event.set_id(++motion_event_id);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_SCROLL_END, GetMostRecentGestureEventType());
  EXPECT_EQ(motion_event_id, GetMostRecentGestureEvent().motion_event_id);
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_FALSE(gesture_provider_->IsDoubleTapInProgress());
}

// Verify that the touch slop region is removed from the first scroll delta to
// avoid a jump when starting to scroll.
TEST_F(GestureProviderTest, TouchSlopRemovedFromScroll) {
  const float touch_slop = GetTouchSlop();
  const float scroll_delta = 5;

  base::TimeTicks event_time = base::TimeTicks::Now();

  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  event = ObtainMotionEvent(event_time + kOneMicrosecond * 2,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX,
                            kFakeCoordY + touch_slop + scroll_delta);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  EXPECT_EQ(ET_GESTURE_SCROLL_UPDATE, GetMostRecentGestureEventType());
  GestureEventData gesture = GetMostRecentGestureEvent();
  EXPECT_EQ(0, gesture.details.scroll_x());
  EXPECT_EQ(scroll_delta, gesture.details.scroll_y());
  EXPECT_EQ(1, gesture.details.touch_points());
}

// Verify that movement within the touch slop region does not generate a scroll,
// and that the slop region is correct even when using fractional coordinates.
TEST_F(GestureProviderTest, NoScrollWithinTouchSlop) {
  const float touch_slop = GetTouchSlop();
  const float scale_factor = 2.5f;
  const int touch_slop_pixels = static_cast<int>(scale_factor * touch_slop);

  base::TimeTicks event_time = base::TimeTicks::Now();

  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  event = ObtainMotionEvent(event_time + kOneMicrosecond * 2,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX + touch_slop_pixels / scale_factor,
                            kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_SCROLL_BEGIN));

  event = ObtainMotionEvent(event_time + kOneMicrosecond * 2,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX,
                            kFakeCoordY + touch_slop_pixels / scale_factor);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_SCROLL_BEGIN));

  event = ObtainMotionEvent(event_time + kOneMicrosecond * 2,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX - touch_slop_pixels / scale_factor,
                            kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_SCROLL_BEGIN));

  event = ObtainMotionEvent(event_time + kOneMicrosecond * 2,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX,
                            kFakeCoordY - touch_slop_pixels / scale_factor);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_SCROLL_BEGIN));

  event =
      ObtainMotionEvent(event_time + kOneMicrosecond * 2,
                        MotionEvent::ACTION_MOVE,
                        kFakeCoordX,
                        kFakeCoordY + (touch_slop_pixels + 1.f) / scale_factor);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SCROLL_BEGIN));
}

TEST_F(GestureProviderTest, NoDoubleTapWhenTooRapid) {
  base::TimeTicks event_time = base::TimeTicks::Now();

  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());

  event = ObtainMotionEvent(event_time + kOneMicrosecond,
                            MotionEvent::ACTION_UP,
                            kFakeCoordX,
                            kFakeCoordY);
  gesture_provider_->OnTouchEvent(event);
  EXPECT_EQ(ET_GESTURE_TAP_UNCONFIRMED, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());

  // If the second tap follows the first in too short a time span, no double-tap
  // will occur.
  event_time += (GetDoubleTapMinTime() / 2);
  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_DOWN,
                            kFakeCoordX,
                            kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());

  event = ObtainMotionEvent(event_time + kOneMicrosecond,
                            MotionEvent::ACTION_UP,
                            kFakeCoordX,
                            kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_UNCONFIRMED, GetMostRecentGestureEventType());
}

TEST_F(GestureProviderTest, NoDoubleTapWhenExplicitlyDisabled) {
  // Ensure that double-tap gestures can be disabled.
  gesture_provider_->SetDoubleTapSupportForPlatformEnabled(false);

  base::TimeTicks event_time = base::TimeTicks::Now();
  MockMotionEvent event = ObtainMotionEvent(
      event_time, MotionEvent::ACTION_DOWN, kFakeCoordX, kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());

  event = ObtainMotionEvent(event_time + kOneMicrosecond,
                            MotionEvent::ACTION_UP,
                            kFakeCoordX,
                            kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP, GetMostRecentGestureEventType());

  event_time += GetValidDoubleTapDelay();
  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_DOWN,
                            kFakeCoordX,
                            kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());

  event = ObtainMotionEvent(event_time + kOneMicrosecond,
                            MotionEvent::ACTION_UP,
                            kFakeCoordX,
                            kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP, GetMostRecentGestureEventType());

  // Ensure that double-tap gestures can be interrupted.
  gesture_provider_->SetDoubleTapSupportForPlatformEnabled(true);

  event_time = base::TimeTicks::Now();
  event = ObtainMotionEvent(
      event_time, MotionEvent::ACTION_DOWN, kFakeCoordX, kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(5U, GetReceivedGestureCount());

  event = ObtainMotionEvent(event_time + kOneMicrosecond,
                            MotionEvent::ACTION_UP,
                            kFakeCoordX,
                            kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_UNCONFIRMED, GetMostRecentGestureEventType());

  gesture_provider_->SetDoubleTapSupportForPlatformEnabled(false);
  EXPECT_EQ(ET_GESTURE_TAP, GetMostRecentGestureEventType());

  // Ensure that double-tap gestures can be resumed.
  gesture_provider_->SetDoubleTapSupportForPlatformEnabled(true);

  event_time += GetValidDoubleTapDelay();
  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_DOWN,
                            kFakeCoordX,
                            kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());

  event = ObtainMotionEvent(event_time + kOneMicrosecond,
                            MotionEvent::ACTION_UP,
                            kFakeCoordX,
                            kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_UNCONFIRMED, GetMostRecentGestureEventType());

  event_time += GetValidDoubleTapDelay();
  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_DOWN,
                            kFakeCoordX,
                            kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());

  event = ObtainMotionEvent(event_time + kOneMicrosecond,
                            MotionEvent::ACTION_UP,
                            kFakeCoordX,
                            kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_DOUBLE_TAP, GetMostRecentGestureEventType());
}

TEST_F(GestureProviderTest, NoDelayedTapWhenDoubleTapSupportToggled) {
  gesture_provider_->SetDoubleTapSupportForPlatformEnabled(true);

  base::TimeTicks event_time = base::TimeTicks::Now();
  MockMotionEvent event = ObtainMotionEvent(
      event_time, MotionEvent::ACTION_DOWN, kFakeCoordX, kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(1U, GetReceivedGestureCount());

  event = ObtainMotionEvent(event_time + kOneMicrosecond,
                            MotionEvent::ACTION_UP,
                            kFakeCoordX,
                            kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_UNCONFIRMED, GetMostRecentGestureEventType());
  EXPECT_EQ(2U, GetReceivedGestureCount());

  // Disabling double-tap during the tap timeout should flush the delayed tap.
  gesture_provider_->SetDoubleTapSupportForPlatformEnabled(false);
  EXPECT_EQ(ET_GESTURE_TAP, GetMostRecentGestureEventType());
  EXPECT_EQ(3U, GetReceivedGestureCount());

  // No further timeout gestures should arrive.
  const base::TimeDelta long_press_timeout =
      GetLongPressTimeout() + GetShowPressTimeout() + kOneMicrosecond;
  RunTasksAndWait(long_press_timeout);
  EXPECT_EQ(3U, GetReceivedGestureCount());
}

TEST_F(GestureProviderTest, NoDoubleTapDragZoomWhenDisabledOnPlatform) {
  const base::TimeTicks down_time_1 = TimeTicks::Now();
  const base::TimeTicks down_time_2 = down_time_1 + GetValidDoubleTapDelay();

  gesture_provider_->SetDoubleTapSupportForPlatformEnabled(false);

  MockMotionEvent event =
      ObtainMotionEvent(down_time_1, MotionEvent::ACTION_DOWN);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  event = ObtainMotionEvent(down_time_1 + kOneMicrosecond,
                            MotionEvent::ACTION_UP,
                            kFakeCoordX,
                            kFakeCoordY);
  gesture_provider_->OnTouchEvent(event);

  event = ObtainMotionEvent(
      down_time_2, MotionEvent::ACTION_DOWN, kFakeCoordX, kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  event = ObtainMotionEvent(down_time_2 + kOneMicrosecond,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX,
                            kFakeCoordY + 100);

  // The move should become a scroll, as doubletap drag zoom is disabled.
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SCROLL_BEGIN));
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_PINCH_BEGIN));

  event = ObtainMotionEvent(down_time_2 + kOneMicrosecond * 2,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX,
                            kFakeCoordY + 200);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_SCROLL_UPDATE, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_EQ(down_time_2 + kOneMicrosecond * 2,
            GetMostRecentGestureEvent().time);
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_PINCH_UPDATE));

  event = ObtainMotionEvent(down_time_2 + kOneMicrosecond * 3,
                            MotionEvent::ACTION_UP,
                            kFakeCoordX,
                            kFakeCoordY + 200);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_PINCH_END));
}

// Verify that double tap drag zoom feature is not invoked when the gesture
// handler is told to disable double tap gesture detection.
// The second tap sequence should be treated just as the first would be.
TEST_F(GestureProviderTest, NoDoubleTapDragZoomWhenDisabledOnPage) {
  const base::TimeTicks down_time_1 = TimeTicks::Now();
  const base::TimeTicks down_time_2 = down_time_1 + GetValidDoubleTapDelay();

  gesture_provider_->SetDoubleTapSupportForPageEnabled(false);

  MockMotionEvent event =
      ObtainMotionEvent(down_time_1, MotionEvent::ACTION_DOWN);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  event = ObtainMotionEvent(down_time_1 + kOneMicrosecond,
                            MotionEvent::ACTION_UP,
                            kFakeCoordX,
                            kFakeCoordY);
  gesture_provider_->OnTouchEvent(event);

  event = ObtainMotionEvent(
      down_time_2, MotionEvent::ACTION_DOWN, kFakeCoordX, kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  event = ObtainMotionEvent(down_time_2 + kOneMicrosecond,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX,
                            kFakeCoordY + 100);

  // The move should become a scroll, as double tap drag zoom is disabled.
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SCROLL_BEGIN));
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_PINCH_BEGIN));

  event = ObtainMotionEvent(down_time_2 + kOneMicrosecond * 2,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX,
                            kFakeCoordY + 200);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_SCROLL_UPDATE, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_PINCH_UPDATE));

  event = ObtainMotionEvent(down_time_2 + kOneMicrosecond * 3,
                            MotionEvent::ACTION_UP,
                            kFakeCoordX,
                            kFakeCoordY + 200);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_PINCH_END));
}

// Verify that updating double tap support during a double tap drag zoom
// disables double tap detection after the gesture has ended.
TEST_F(GestureProviderTest, FixedPageScaleDuringDoubleTapDragZoom) {
  base::TimeTicks down_time_1 = TimeTicks::Now();
  base::TimeTicks down_time_2 = down_time_1 + GetValidDoubleTapDelay();

  gesture_provider_->SetDoubleTapSupportForPageEnabled(true);
  gesture_provider_->SetDoubleTapSupportForPlatformEnabled(true);

  // Start a double-tap drag gesture.
  MockMotionEvent event =
      ObtainMotionEvent(down_time_1, MotionEvent::ACTION_DOWN);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  event = ObtainMotionEvent(down_time_1 + kOneMicrosecond,
                            MotionEvent::ACTION_UP,
                            kFakeCoordX,
                            kFakeCoordY);
  gesture_provider_->OnTouchEvent(event);
  event = ObtainMotionEvent(
      down_time_2, MotionEvent::ACTION_DOWN, kFakeCoordX, kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  event = ObtainMotionEvent(down_time_2 + kOneMicrosecond,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX,
                            kFakeCoordY + 100);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SCROLL_BEGIN));
  EXPECT_EQ(ET_GESTURE_PINCH_BEGIN, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());

  // Simulate setting a fixed page scale (or a mobile viewport);
  // this should not disrupt the current double-tap gesture.
  gesture_provider_->SetDoubleTapSupportForPageEnabled(false);

  // Double tap zoom updates should continue.
  event = ObtainMotionEvent(down_time_2 + kOneMicrosecond * 2,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX,
                            kFakeCoordY + 200);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_PINCH_UPDATE, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_LT(1.f, GetMostRecentGestureEvent().details.scale());
  event = ObtainMotionEvent(down_time_2 + kOneMicrosecond * 3,
                            MotionEvent::ACTION_UP,
                            kFakeCoordX,
                            kFakeCoordY + 200);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_PINCH_END));
  EXPECT_EQ(ET_GESTURE_SCROLL_END, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());

  // The double-tap gesture has finished, but the page scale is fixed.
  // The same event sequence should not generate any double tap getsures.
  gestures_.clear();
  down_time_1 += kOneMicrosecond * 40;
  down_time_2 += kOneMicrosecond * 40;

  // Start a double-tap drag gesture.
  event = ObtainMotionEvent(down_time_1, MotionEvent::ACTION_DOWN);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  event = ObtainMotionEvent(down_time_1 + kOneMicrosecond,
                            MotionEvent::ACTION_UP,
                            kFakeCoordX,
                            kFakeCoordY);
  gesture_provider_->OnTouchEvent(event);
  event = ObtainMotionEvent(
      down_time_2, MotionEvent::ACTION_DOWN, kFakeCoordX, kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  event = ObtainMotionEvent(down_time_2 + kOneMicrosecond,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX,
                            kFakeCoordY + 100);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SCROLL_BEGIN));
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_PINCH_BEGIN));

  // Double tap zoom updates should not be sent.
  // Instead, the second tap drag becomes a scroll gesture sequence.
  event = ObtainMotionEvent(down_time_2 + kOneMicrosecond * 2,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX,
                            kFakeCoordY + 200);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SCROLL_UPDATE));
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_PINCH_UPDATE));
  event = ObtainMotionEvent(down_time_2 + kOneMicrosecond * 3,
                            MotionEvent::ACTION_UP,
                            kFakeCoordX,
                            kFakeCoordY + 200);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_PINCH_END));
}

// Verify that pinch zoom sends the proper event sequence.
TEST_F(GestureProviderTest, PinchZoom) {
  base::TimeTicks event_time = base::TimeTicks::Now();
  const float touch_slop = GetTouchSlop();
  const float raw_offset_x = 3.2f;
  const float raw_offset_y = 4.3f;
  int motion_event_id = 0;

  gesture_provider_->SetDoubleTapSupportForPageEnabled(false);
  gesture_provider_->SetDoubleTapSupportForPlatformEnabled(true);
  gesture_provider_->SetMultiTouchZoomSupportEnabled(true);

  int secondary_coord_x = kFakeCoordX + 20 * touch_slop;
  int secondary_coord_y = kFakeCoordY + 20 * touch_slop;

  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);
  event.set_id(++motion_event_id);
  event.SetRawOffset(raw_offset_x, raw_offset_y);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(kFakeCoordX, GetMostRecentGestureEvent().x);
  EXPECT_EQ(kFakeCoordY, GetMostRecentGestureEvent().y);
  EXPECT_EQ(kFakeCoordX + raw_offset_x, GetMostRecentGestureEvent().raw_x);
  EXPECT_EQ(kFakeCoordY + raw_offset_y, GetMostRecentGestureEvent().raw_y);
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_EQ(BoundsForSingleMockTouchAtLocation(kFakeCoordX, kFakeCoordY),
            GetMostRecentGestureEvent().details.bounding_box());

  // Toggling double-tap support should not take effect until the next sequence.
  gesture_provider_->SetDoubleTapSupportForPageEnabled(true);

  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_POINTER_DOWN,
                            kFakeCoordX,
                            kFakeCoordY,
                            secondary_coord_x,
                            secondary_coord_y);
  event.set_id(++motion_event_id);
  event.SetRawOffset(raw_offset_x, raw_offset_y);

  gesture_provider_->OnTouchEvent(event);
  EXPECT_EQ(1U, GetReceivedGestureCount());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_EQ(BoundsForSingleMockTouchAtLocation(kFakeCoordX, kFakeCoordY),
            GetMostRecentGestureEvent().details.bounding_box());

  secondary_coord_x += 5 * touch_slop;
  secondary_coord_y += 5 * touch_slop;
  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX,
                            kFakeCoordY,
                            secondary_coord_x,
                            secondary_coord_y);
  event.set_id(++motion_event_id);
  event.SetRawOffset(raw_offset_x, raw_offset_y);

  // Toggling double-tap support should not take effect until the next sequence.
  gesture_provider_->SetDoubleTapSupportForPageEnabled(false);

  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(motion_event_id, GetMostRecentGestureEvent().motion_event_id);
  EXPECT_EQ(2, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_PINCH_BEGIN));
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SCROLL_BEGIN));
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SCROLL_UPDATE));

  EXPECT_EQ((kFakeCoordX + secondary_coord_x) / 2, GetReceivedGesture(3).x);
  EXPECT_EQ((kFakeCoordY + secondary_coord_y) / 2, GetReceivedGesture(3).y);
  EXPECT_EQ((kFakeCoordX + secondary_coord_x) / 2 + raw_offset_x,
            GetReceivedGesture(3).raw_x);
  EXPECT_EQ((kFakeCoordY + secondary_coord_y) / 2 + raw_offset_y,
            GetReceivedGesture(3).raw_y);

  EXPECT_EQ(
      gfx::RectF(kFakeCoordX - kMockTouchRadius,
                 kFakeCoordY - kMockTouchRadius,
                 secondary_coord_x - kFakeCoordX + kMockTouchRadius * 2,
                 secondary_coord_y - kFakeCoordY + kMockTouchRadius * 2),
      GetMostRecentGestureEvent().details.bounding_box());

  secondary_coord_x += 2 * touch_slop;
  secondary_coord_y += 2 * touch_slop;
  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX,
                            kFakeCoordY,
                            secondary_coord_x,
                            secondary_coord_y);
  event.set_id(++motion_event_id);

  // Toggling double-tap support should not take effect until the next sequence.
  gesture_provider_->SetDoubleTapSupportForPageEnabled(true);

  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(motion_event_id, GetMostRecentGestureEvent().motion_event_id);
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SCROLL_UPDATE));
  EXPECT_EQ(ET_GESTURE_PINCH_UPDATE, GetMostRecentGestureEventType());
  EXPECT_EQ(2, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_LT(1.f, GetMostRecentGestureEvent().details.scale());
  EXPECT_EQ(
      gfx::RectF(kFakeCoordX - kMockTouchRadius,
                 kFakeCoordY - kMockTouchRadius,
                 secondary_coord_x - kFakeCoordX + kMockTouchRadius * 2,
                 secondary_coord_y - kFakeCoordY + kMockTouchRadius * 2),
      GetMostRecentGestureEvent().details.bounding_box());

  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_POINTER_UP,
                            kFakeCoordX,
                            kFakeCoordY,
                            secondary_coord_x,
                            secondary_coord_y);
  event.set_id(++motion_event_id);

  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(motion_event_id, GetMostRecentGestureEvent().motion_event_id);
  EXPECT_EQ(ET_GESTURE_PINCH_END, GetMostRecentGestureEventType());
  EXPECT_EQ(2, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_SCROLL_END));
  EXPECT_EQ(
      gfx::RectF(kFakeCoordX - kMockTouchRadius,
                 kFakeCoordY - kMockTouchRadius,
                 secondary_coord_x - kFakeCoordX + kMockTouchRadius * 2,
                 secondary_coord_y - kFakeCoordY + kMockTouchRadius * 2),
      GetMostRecentGestureEvent().details.bounding_box());

  event = ObtainMotionEvent(event_time, MotionEvent::ACTION_UP);
  gesture_provider_->OnTouchEvent(event);
  EXPECT_EQ(ET_GESTURE_SCROLL_END, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_EQ(gfx::RectF(kFakeCoordX - kMockTouchRadius,
                       kFakeCoordY - kMockTouchRadius,
                       kMockTouchRadius * 2,
                       kMockTouchRadius * 2),
            GetMostRecentGestureEvent().details.bounding_box());
}

// Verify that no accidental pinching occurs if the touch size is large relative
// to the min scaling span when the touch major value is used in scaling.
TEST_F(GestureProviderTest, NoPinchZoomWithFatFinger) {
  base::TimeTicks event_time = base::TimeTicks::Now();
  const float kFatFingerSize = GetMinScalingSpan() * 3.f;

  gesture_provider_->SetDoubleTapSupportForPlatformEnabled(false);
  gesture_provider_->SetMultiTouchZoomSupportEnabled(true);

  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(1U, GetReceivedGestureCount());

  event = ObtainMotionEvent(event_time + kOneSecond,
                            MotionEvent::ACTION_MOVE);
  event.SetTouchMajor(0.1f);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(1U, GetReceivedGestureCount());

  event = ObtainMotionEvent(event_time + kOneSecond * 2,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX + 1.f,
                            kFakeCoordY);
  event.SetTouchMajor(1.f);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(1U, GetReceivedGestureCount());

  event = ObtainMotionEvent(event_time + kOneSecond * 3,
                            MotionEvent::ACTION_MOVE);
  event.SetTouchMajor(kFatFingerSize * 3.5f);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(1U, GetReceivedGestureCount());

  event = ObtainMotionEvent(event_time + kOneSecond * 4,
                            MotionEvent::ACTION_MOVE);
  event.SetTouchMajor(kFatFingerSize * 5.f);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(1U, GetReceivedGestureCount());

  event = ObtainMotionEvent(event_time + kOneSecond * 4,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX + 50.f,
                            kFakeCoordY - 25.f);
  event.SetTouchMajor(kFatFingerSize * 10.f);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_PINCH_BEGIN));

  event = ObtainMotionEvent(event_time + kOneSecond * 4,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX + 100.f,
                            kFakeCoordY - 50.f);
  event.SetTouchMajor(kFatFingerSize * 5.f);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_PINCH_BEGIN));
}

// Verify that multi-finger swipe sends the proper event sequence.
TEST_F(GestureProviderTest, MultiFingerSwipe) {
  EnableSwipe();
  gesture_provider_->SetMultiTouchZoomSupportEnabled(false);
  const float min_swipe_velocity = GetMinSwipeVelocity();

  // One finger - swipe right
  OneFingerSwipe(2 * min_swipe_velocity, 0);
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SWIPE));
  EXPECT_TRUE(GetMostRecentGestureEvent().details.swipe_right());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  ResetGestureDetection();

  // One finger - swipe left
  OneFingerSwipe(-2 * min_swipe_velocity, 0);
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SWIPE));
  EXPECT_TRUE(GetMostRecentGestureEvent().details.swipe_left());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  ResetGestureDetection();

  // One finger - swipe down
  OneFingerSwipe(0, 2 * min_swipe_velocity);
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SWIPE));
  EXPECT_TRUE(GetMostRecentGestureEvent().details.swipe_down());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  ResetGestureDetection();

  // One finger - swipe up
  OneFingerSwipe(0, -2 * min_swipe_velocity);
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SWIPE));
  EXPECT_TRUE(GetMostRecentGestureEvent().details.swipe_up());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  ResetGestureDetection();

  // Two fingers
  // Swipe right.
  TwoFingerSwipe(min_swipe_velocity * 2, 0, min_swipe_velocity * 2, 0);
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SWIPE));
  EXPECT_TRUE(GetMostRecentGestureEvent().details.swipe_right());
  EXPECT_EQ(2, GetMostRecentGestureEvent().details.touch_points());
  ResetGestureDetection();

  // Swipe left.
  TwoFingerSwipe(-min_swipe_velocity * 2, 0, -min_swipe_velocity * 2, 0);
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SWIPE));
  EXPECT_TRUE(GetMostRecentGestureEvent().details.swipe_left());
  EXPECT_EQ(2, GetMostRecentGestureEvent().details.touch_points());
  ResetGestureDetection();

  // No swipe with different touch directions.
  TwoFingerSwipe(min_swipe_velocity * 2, 0, -min_swipe_velocity * 2, 0);
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_SWIPE));
  ResetGestureDetection();

  // No swipe without a dominant direction.
  TwoFingerSwipe(min_swipe_velocity * 2,
                 min_swipe_velocity * 2,
                 min_swipe_velocity * 2,
                 min_swipe_velocity * 2);
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_SWIPE));
  ResetGestureDetection();

  // Swipe down with non-zero velocities on both axes and dominant direction.
  TwoFingerSwipe(-min_swipe_velocity,
                 min_swipe_velocity * 4,
                 -min_swipe_velocity,
                 min_swipe_velocity * 4);
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SWIPE));
  EXPECT_TRUE(GetMostRecentGestureEvent().details.swipe_down());
  EXPECT_FALSE(GetMostRecentGestureEvent().details.swipe_left());
  EXPECT_EQ(2, GetMostRecentGestureEvent().details.touch_points());
  ResetGestureDetection();

  // Swipe up with non-zero velocities on both axes.
  TwoFingerSwipe(min_swipe_velocity,
                 -min_swipe_velocity * 4,
                 min_swipe_velocity,
                 -min_swipe_velocity * 4);
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SWIPE));
  EXPECT_TRUE(GetMostRecentGestureEvent().details.swipe_up());
  EXPECT_FALSE(GetMostRecentGestureEvent().details.swipe_right());
  EXPECT_EQ(2, GetMostRecentGestureEvent().details.touch_points());
  ResetGestureDetection();

  // No swipe without sufficient velocity.
  TwoFingerSwipe(min_swipe_velocity / 2, 0, 0, 0);
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_SWIPE));
  ResetGestureDetection();

  // Swipe up with one small and one medium velocity in slightly different but
  // not opposing directions.
  TwoFingerSwipe(min_swipe_velocity / 2,
                 min_swipe_velocity / 2,
                 0,
                 min_swipe_velocity * 2);
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SWIPE));
  EXPECT_TRUE(GetMostRecentGestureEvent().details.swipe_down());
  EXPECT_FALSE(GetMostRecentGestureEvent().details.swipe_right());
  EXPECT_EQ(2, GetMostRecentGestureEvent().details.touch_points());
  ResetGestureDetection();

  // No swipe in orthogonal directions.
  TwoFingerSwipe(min_swipe_velocity * 2, 0, 0, min_swipe_velocity * 7);
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_SWIPE));
  ResetGestureDetection();

  // Three finger swipe in same directions.
  ThreeFingerSwipe(min_swipe_velocity * 2,
                   0,
                   min_swipe_velocity * 3,
                   0,
                   min_swipe_velocity * 4,
                   0);
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SWIPE));
  EXPECT_TRUE(GetMostRecentGestureEvent().details.swipe_right());
  EXPECT_EQ(3, GetMostRecentGestureEvent().details.touch_points());
  ResetGestureDetection();

  // No three finger swipe in different directions.
  ThreeFingerSwipe(min_swipe_velocity * 2,
                   0,
                   0,
                   min_swipe_velocity * 3,
                   min_swipe_velocity * 4,
                   0);
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_SWIPE));
}

// Verify that the timer of LONG_PRESS will be cancelled when scrolling begins
// so LONG_PRESS and LONG_TAP won't be triggered.
TEST_F(GestureProviderTest, GesturesCancelledAfterLongPressCausesLostFocus) {
  base::TimeTicks event_time = base::TimeTicks::Now();

  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  const base::TimeDelta long_press_timeout =
      GetLongPressTimeout() + GetShowPressTimeout() + kOneMicrosecond;
  RunTasksAndWait(long_press_timeout);
  EXPECT_EQ(ET_GESTURE_LONG_PRESS, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());

  EXPECT_TRUE(CancelActiveTouchSequence());
  EXPECT_FALSE(HasDownEvent());

  event = ObtainMotionEvent(event_time + long_press_timeout,
                            MotionEvent::ACTION_UP);
  gesture_provider_->OnTouchEvent(event);
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_LONG_TAP));
}

// Verify that inserting a touch cancel event will trigger proper touch and
// gesture sequence cancellation.
TEST_F(GestureProviderTest, CancelActiveTouchSequence) {
  base::TimeTicks event_time = base::TimeTicks::Now();
  int motion_event_id = 0;

  EXPECT_FALSE(CancelActiveTouchSequence());
  EXPECT_EQ(0U, GetReceivedGestureCount());

  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);
  event.set_id(++motion_event_id);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(motion_event_id, GetMostRecentGestureEvent().motion_event_id);
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());

  ASSERT_TRUE(CancelActiveTouchSequence());
  EXPECT_FALSE(HasDownEvent());

  // Subsequent MotionEvent's are dropped until ACTION_DOWN.
  event = ObtainMotionEvent(event_time + kOneMicrosecond,
                            MotionEvent::ACTION_MOVE);
  EXPECT_FALSE(gesture_provider_->OnTouchEvent(event));

  event = ObtainMotionEvent(event_time + kOneMicrosecond * 2,
                            MotionEvent::ACTION_UP);
  EXPECT_FALSE(gesture_provider_->OnTouchEvent(event));

  event = ObtainMotionEvent(event_time + kOneMicrosecond * 3,
                            MotionEvent::ACTION_DOWN);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
}

TEST_F(GestureProviderTest, DoubleTapDragZoomCancelledOnSecondaryPointerDown) {
  const base::TimeTicks down_time_1 = TimeTicks::Now();
  const base::TimeTicks down_time_2 = down_time_1 + GetValidDoubleTapDelay();

  gesture_provider_->SetDoubleTapSupportForPlatformEnabled(true);

  MockMotionEvent event =
      ObtainMotionEvent(down_time_1, MotionEvent::ACTION_DOWN);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());

  event =
      ObtainMotionEvent(down_time_1 + kOneMicrosecond, MotionEvent::ACTION_UP);
  gesture_provider_->OnTouchEvent(event);
  EXPECT_EQ(ET_GESTURE_TAP_UNCONFIRMED, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());

  event = ObtainMotionEvent(down_time_2, MotionEvent::ACTION_DOWN);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());

  event = ObtainMotionEvent(down_time_2 + kOneMicrosecond,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX,
                            kFakeCoordY - 30);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SCROLL_BEGIN));
  EXPECT_EQ(ET_GESTURE_PINCH_BEGIN, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());

  event = ObtainMotionEvent(down_time_2 + kOneMicrosecond * 2,
                            MotionEvent::ACTION_POINTER_DOWN,
                            kFakeCoordX,
                            kFakeCoordY - 30,
                            kFakeCoordX + 50,
                            kFakeCoordY + 50);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_PINCH_END, GetMostRecentGestureEventType());
  EXPECT_EQ(2, GetMostRecentGestureEvent().details.touch_points());

  const size_t gesture_count = GetReceivedGestureCount();
  event = ObtainMotionEvent(down_time_2 + kOneMicrosecond * 3,
                            MotionEvent::ACTION_POINTER_UP,
                            kFakeCoordX,
                            kFakeCoordY - 30,
                            kFakeCoordX + 50,
                            kFakeCoordY + 50);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(gesture_count, GetReceivedGestureCount());

  event = ObtainMotionEvent(down_time_2 + kOneSecond,
                            MotionEvent::ACTION_UP);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(gesture_count + 1, GetReceivedGestureCount());
  EXPECT_EQ(ET_GESTURE_SCROLL_END, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
}

// Verify that gesture begin and gesture end events are dispatched correctly.
TEST_F(GestureProviderTest, GestureBeginAndEnd) {
  EnableBeginEndTypes();
  base::TimeTicks event_time = base::TimeTicks::Now();
  const float raw_offset_x = 7.5f;
  const float raw_offset_y = 5.7f;

  EXPECT_EQ(0U, GetReceivedGestureCount());
  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN, 1, 1);
  event.SetRawOffset(raw_offset_x, raw_offset_y);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_BEGIN, GetReceivedGesture(0).type());
  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(2U, GetReceivedGestureCount());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_EQ(1, GetMostRecentGestureEvent().x);
  EXPECT_EQ(1, GetMostRecentGestureEvent().y);
  EXPECT_EQ(1 + raw_offset_x, GetMostRecentGestureEvent().raw_x);
  EXPECT_EQ(1 + raw_offset_y, GetMostRecentGestureEvent().raw_y);
  EXPECT_EQ(gfx::RectF(1 - kMockTouchRadius,
                       1 - kMockTouchRadius,
                       kMockTouchRadius * 2,
                       kMockTouchRadius * 2),
            GetMostRecentGestureEvent().details.bounding_box());

  event = ObtainMotionEvent(
      event_time, MotionEvent::ACTION_POINTER_DOWN, 1, 1, 2, 2);
  event.SetRawOffset(raw_offset_x, raw_offset_y);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_BEGIN, GetMostRecentGestureEventType());
  EXPECT_EQ(3U, GetReceivedGestureCount());
  EXPECT_EQ(2, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_EQ(2, GetMostRecentGestureEvent().x);
  EXPECT_EQ(2, GetMostRecentGestureEvent().y);
  EXPECT_EQ(2 + raw_offset_x, GetMostRecentGestureEvent().raw_x);
  EXPECT_EQ(2 + raw_offset_y, GetMostRecentGestureEvent().raw_y);

  event = ObtainMotionEvent(
      event_time, MotionEvent::ACTION_POINTER_DOWN, 1, 1, 2, 2, 3, 3);
  event.SetRawOffset(raw_offset_x, raw_offset_y);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_BEGIN, GetMostRecentGestureEventType());
  EXPECT_EQ(4U, GetReceivedGestureCount());
  EXPECT_EQ(3, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_EQ(3, GetMostRecentGestureEvent().x);
  EXPECT_EQ(3, GetMostRecentGestureEvent().y);
  EXPECT_EQ(3 + raw_offset_x, GetMostRecentGestureEvent().raw_x);
  EXPECT_EQ(3 + raw_offset_y, GetMostRecentGestureEvent().raw_y);

  event = ObtainMotionEvent(
      event_time, MotionEvent::ACTION_POINTER_UP, 1, 1, 2, 2, 3, 3);
  event.SetRawOffset(raw_offset_x, raw_offset_y);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_END, GetMostRecentGestureEventType());
  EXPECT_EQ(5U, GetReceivedGestureCount());
  EXPECT_EQ(3, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_EQ(1, GetMostRecentGestureEvent().x);
  EXPECT_EQ(1, GetMostRecentGestureEvent().y);
  EXPECT_EQ(1 + raw_offset_x, GetMostRecentGestureEvent().raw_x);
  EXPECT_EQ(1 + raw_offset_y, GetMostRecentGestureEvent().raw_y);

  event = ObtainMotionEvent(
      event_time, MotionEvent::ACTION_POINTER_DOWN, 2, 2, 3, 3, 4, 4);
  event.SetRawOffset(raw_offset_x, raw_offset_y);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_BEGIN, GetMostRecentGestureEventType());
  EXPECT_EQ(6U, GetReceivedGestureCount());
  EXPECT_EQ(3, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_EQ(4, GetMostRecentGestureEvent().x);
  EXPECT_EQ(4, GetMostRecentGestureEvent().y);
  EXPECT_EQ(4 + raw_offset_x, GetMostRecentGestureEvent().raw_x);
  EXPECT_EQ(4 + raw_offset_y, GetMostRecentGestureEvent().raw_y);

  event = ObtainMotionEvent(
      event_time, MotionEvent::ACTION_POINTER_UP, 2, 2, 3, 3, 4, 4);
  event.SetRawOffset(raw_offset_x, raw_offset_y);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_END, GetMostRecentGestureEventType());
  EXPECT_EQ(7U, GetReceivedGestureCount());
  EXPECT_EQ(3, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_EQ(2, GetMostRecentGestureEvent().x);
  EXPECT_EQ(2, GetMostRecentGestureEvent().y);
  EXPECT_EQ(2 + raw_offset_x, GetMostRecentGestureEvent().raw_x);
  EXPECT_EQ(2 + raw_offset_y, GetMostRecentGestureEvent().raw_y);

  event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_POINTER_UP, 3, 3, 4, 4);
  event.SetRawOffset(raw_offset_x, raw_offset_y);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_END, GetMostRecentGestureEventType());
  EXPECT_EQ(8U, GetReceivedGestureCount());
  EXPECT_EQ(2, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_EQ(3, GetMostRecentGestureEvent().x);
  EXPECT_EQ(3, GetMostRecentGestureEvent().y);
  EXPECT_EQ(3 + raw_offset_x, GetMostRecentGestureEvent().raw_x);
  EXPECT_EQ(3 + raw_offset_y, GetMostRecentGestureEvent().raw_y);


  event = ObtainMotionEvent(event_time, MotionEvent::ACTION_UP, 4, 4);
  event.SetRawOffset(raw_offset_x, raw_offset_y);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_END, GetMostRecentGestureEventType());
  EXPECT_EQ(9U, GetReceivedGestureCount());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_EQ(4, GetMostRecentGestureEvent().x);
  EXPECT_EQ(4, GetMostRecentGestureEvent().y);
  EXPECT_EQ(4 + raw_offset_x, GetMostRecentGestureEvent().raw_x);
  EXPECT_EQ(4 + raw_offset_y, GetMostRecentGestureEvent().raw_y);
}

// Verify that gesture begin and gesture end events are dispatched correctly
// when an ACTION_CANCEL is received.
TEST_F(GestureProviderTest, GestureBeginAndEndOnCancel) {
  EnableBeginEndTypes();
  base::TimeTicks event_time = base::TimeTicks::Now();

  EXPECT_EQ(0U, GetReceivedGestureCount());
  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN, 1, 1);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_BEGIN, GetReceivedGesture(0).type());
  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(2U, GetReceivedGestureCount());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_EQ(gfx::RectF(1 - kMockTouchRadius,
                       1 - kMockTouchRadius,
                       kMockTouchRadius * 2,
                       kMockTouchRadius * 2),
            GetMostRecentGestureEvent().details.bounding_box());
  EXPECT_EQ(1, GetMostRecentGestureEvent().x);
  EXPECT_EQ(1, GetMostRecentGestureEvent().y);

  event = ObtainMotionEvent(
      event_time, MotionEvent::ACTION_POINTER_DOWN, 1, 1, 2, 2);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_BEGIN, GetMostRecentGestureEventType());
  EXPECT_EQ(3U, GetReceivedGestureCount());
  EXPECT_EQ(2, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_EQ(2, GetMostRecentGestureEvent().x);
  EXPECT_EQ(2, GetMostRecentGestureEvent().y);

  event = ObtainMotionEvent(
      event_time, MotionEvent::ACTION_POINTER_DOWN, 1, 1, 2, 2, 3, 3);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_BEGIN, GetMostRecentGestureEventType());
  EXPECT_EQ(4U, GetReceivedGestureCount());
  EXPECT_EQ(3, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_EQ(3, GetMostRecentGestureEvent().x);
  EXPECT_EQ(3, GetMostRecentGestureEvent().y);

  event = ObtainMotionEvent(
      event_time, MotionEvent::ACTION_CANCEL, 1, 1, 2, 2, 3, 3);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(5U, GetReceivedGestureCount());
  EXPECT_EQ(3, GetReceivedGesture(4).details.touch_points());
  EXPECT_EQ(ET_GESTURE_END, GetReceivedGesture(4).type());
  EXPECT_EQ(1, GetMostRecentGestureEvent().x);
  EXPECT_EQ(1, GetMostRecentGestureEvent().y);

  event = ObtainMotionEvent(
      event_time, MotionEvent::ACTION_CANCEL, 1, 1, 3, 3);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(6U, GetReceivedGestureCount());
  EXPECT_EQ(2, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_EQ(ET_GESTURE_END, GetMostRecentGestureEvent().type());
  EXPECT_EQ(1, GetMostRecentGestureEvent().x);
  EXPECT_EQ(1, GetMostRecentGestureEvent().y);

  event = ObtainMotionEvent(
      event_time, MotionEvent::ACTION_CANCEL, 3, 3);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_EQ(ET_GESTURE_END, GetMostRecentGestureEvent().type());
  EXPECT_EQ(3, GetMostRecentGestureEvent().x);
  EXPECT_EQ(3, GetMostRecentGestureEvent().y);
}

// Test a simple two finger tap
TEST_F(GestureProviderTest, TwoFingerTap) {
  // The time between ACTION_POINTER_DOWN and ACTION_POINTER_UP must be <= the
  // two finger tap delay.
  EnableTwoFingerTap(kMaxTwoFingerTapSeparation, base::TimeDelta());
  const float scaled_touch_slop = GetTouchSlop();

  base::TimeTicks event_time = base::TimeTicks::Now();

  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN, 0, 0);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_MOVE,
                            0,
                            scaled_touch_slop / 2);

  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_POINTER_DOWN,
                            0,
                            0,
                            kMaxTwoFingerTapSeparation / 2,
                            0);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  event =
      ObtainMotionEvent(event_time,
                        MotionEvent::ACTION_MOVE,
                        0,
                        -scaled_touch_slop / 2,
                        kMaxTwoFingerTapSeparation / 2 + scaled_touch_slop / 2,
                        0);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_POINTER_UP,
                            0,
                            0,
                            kMaxTwoFingerTapSeparation,
                            0);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetReceivedGesture(0).type());
  EXPECT_EQ(ET_GESTURE_SCROLL_BEGIN, GetReceivedGesture(1).type());
  EXPECT_EQ(ET_GESTURE_TWO_FINGER_TAP, GetReceivedGesture(2).type());
  EXPECT_EQ(3U, GetReceivedGestureCount());

  EXPECT_EQ(kMockTouchRadius * 2,
            GetReceivedGesture(2).details.first_finger_width());
  EXPECT_EQ(kMockTouchRadius * 2,
            GetReceivedGesture(2).details.first_finger_height());
}

// Test preventing a two finger tap via finger movement.
TEST_F(GestureProviderTest, TwoFingerTapCancelledByFingerMovement) {
  EnableTwoFingerTap(kMaxTwoFingerTapSeparation, base::TimeDelta());
  const float scaled_touch_slop = GetTouchSlop();
  base::TimeTicks event_time = base::TimeTicks::Now();

  MockMotionEvent event = ObtainMotionEvent(
      event_time, MotionEvent::ACTION_DOWN, kFakeCoordX, kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_POINTER_DOWN,
                            kFakeCoordX,
                            kFakeCoordY,
                            kFakeCoordX,
                            kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX,
                            kFakeCoordY,
                            kFakeCoordX + scaled_touch_slop + 0.1,
                            kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_POINTER_UP,
                            kFakeCoordX,
                            kFakeCoordY,
                            kFakeCoordX,
                            kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetReceivedGesture(0).type());
  EXPECT_EQ(ET_GESTURE_SCROLL_BEGIN, GetReceivedGesture(1).type());
  EXPECT_EQ(2U, GetReceivedGestureCount());
}

// Test preventing a two finger tap by waiting too long before releasing the
// secondary pointer.
TEST_F(GestureProviderTest, TwoFingerTapCancelledByDelay) {
  base::TimeDelta two_finger_tap_timeout = kOneSecond;
  EnableTwoFingerTap(kMaxTwoFingerTapSeparation, two_finger_tap_timeout);
  base::TimeTicks event_time = base::TimeTicks::Now();

  MockMotionEvent event = ObtainMotionEvent(
      event_time, MotionEvent::ACTION_DOWN, kFakeCoordX, kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX,
                            kFakeCoordY);

  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_POINTER_DOWN,
                            kFakeCoordX,
                            kFakeCoordY,
                            kFakeCoordX + kMaxTwoFingerTapSeparation / 2,
                            kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  event = ObtainMotionEvent(event_time + kOneSecond + kOneMicrosecond,
                            MotionEvent::ACTION_POINTER_UP,
                            kFakeCoordX,
                            kFakeCoordY,
                            kFakeCoordX + kMaxTwoFingerTapSeparation / 2,
                            kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetReceivedGesture(0).type());
  EXPECT_EQ(1U, GetReceivedGestureCount());
}

// Test preventing a two finger tap by pressing the secondary pointer too far
// from the first
TEST_F(GestureProviderTest, TwoFingerTapCancelledByDistanceBetweenPointers) {
  EnableTwoFingerTap(kMaxTwoFingerTapSeparation, base::TimeDelta());
  base::TimeTicks event_time = base::TimeTicks::Now();

  MockMotionEvent event = ObtainMotionEvent(
      event_time, MotionEvent::ACTION_DOWN, kFakeCoordX, kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_POINTER_DOWN,
                            kFakeCoordX,
                            kFakeCoordY,
                            kFakeCoordX + kMaxTwoFingerTapSeparation,
                            kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_POINTER_UP,
                            kFakeCoordX,
                            kFakeCoordY,
                            kFakeCoordX + kMaxTwoFingerTapSeparation,
                            kFakeCoordY);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetReceivedGesture(0).type());
  EXPECT_EQ(1U, GetReceivedGestureCount());
}

// Verify that pinch zoom only sends updates which exceed the
// min_pinch_update_span_delta.
TEST_F(GestureProviderTest, PinchZoomWithThreshold) {
  const float kMinPinchUpdateDistance = 5;

  base::TimeTicks event_time = base::TimeTicks::Now();
  const float touch_slop = GetTouchSlop();

  SetMinPinchUpdateSpanDelta(kMinPinchUpdateDistance);
  gesture_provider_->SetDoubleTapSupportForPageEnabled(false);
  gesture_provider_->SetDoubleTapSupportForPlatformEnabled(true);
  gesture_provider_->SetMultiTouchZoomSupportEnabled(true);

  int secondary_coord_x = kFakeCoordX + 20 * touch_slop;
  int secondary_coord_y = kFakeCoordY + 20 * touch_slop;

  // First finger down.
  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());

  // Second finger down.
  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_POINTER_DOWN,
                            kFakeCoordX,
                            kFakeCoordY,
                            secondary_coord_x,
                            secondary_coord_y);

  gesture_provider_->OnTouchEvent(event);
  EXPECT_EQ(1U, GetReceivedGestureCount());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());

  // Move second finger.
  secondary_coord_x += 5 * touch_slop;
  secondary_coord_y += 5 * touch_slop;
  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX,
                            kFakeCoordY,
                            secondary_coord_x,
                            secondary_coord_y);

  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(2, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_PINCH_BEGIN));
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_PINCH_UPDATE));
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SCROLL_BEGIN));
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_SCROLL_UPDATE));

  // Small move, shouldn't trigger pinch.
  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX,
                            kFakeCoordY,
                            secondary_coord_x + kMinPinchUpdateDistance,
                            secondary_coord_y);

  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_FALSE(HasReceivedGesture(ET_GESTURE_PINCH_UPDATE));
  EXPECT_EQ(2, GetMostRecentGestureEvent().details.touch_points());

  // Small move, but combined with the previous move, should trigger pinch. We
  // need to overshoot kMinPinchUpdateDistance by a fair bit, as the span
  // calculation factors in touch radius.
  const float kOvershootMinPinchUpdateDistance = 3;
  event = ObtainMotionEvent(event_time,
                            MotionEvent::ACTION_MOVE,
                            kFakeCoordX,
                            kFakeCoordY,
                            secondary_coord_x + kMinPinchUpdateDistance +
                                kOvershootMinPinchUpdateDistance,
                            secondary_coord_y);

  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_TRUE(HasReceivedGesture(ET_GESTURE_PINCH_UPDATE));
  EXPECT_EQ(2, GetMostRecentGestureEvent().details.touch_points());
}

// Verify that the min gesture bound setting is honored.
TEST_F(GestureProviderTest, MinGestureBoundsLength) {
  const float kMinGestureBoundsLength = 10.f * kMockTouchRadius;
  SetMinMaxGestureBoundsLength(kMinGestureBoundsLength, 0.f);
  gesture_provider_->SetDoubleTapSupportForPlatformEnabled(false);

  base::TimeTicks event_time = base::TimeTicks::Now();
  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(kMinGestureBoundsLength,
            GetMostRecentGestureEvent().details.bounding_box_f().width());
  EXPECT_EQ(kMinGestureBoundsLength,
            GetMostRecentGestureEvent().details.bounding_box_f().height());

  event =
      ObtainMotionEvent(event_time + kOneMicrosecond, MotionEvent::ACTION_UP);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP, GetMostRecentGestureEventType());
  EXPECT_EQ(kMinGestureBoundsLength,
            GetMostRecentGestureEvent().details.bounding_box_f().width());
  EXPECT_EQ(kMinGestureBoundsLength,
            GetMostRecentGestureEvent().details.bounding_box_f().height());
}

TEST_F(GestureProviderTest, MaxGestureBoundsLength) {
  const float kMaxGestureBoundsLength = kMockTouchRadius / 10.f;
  SetMinMaxGestureBoundsLength(0.f, kMaxGestureBoundsLength);
  gesture_provider_->SetDoubleTapSupportForPlatformEnabled(false);

  base::TimeTicks event_time = base::TimeTicks::Now();
  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(kMaxGestureBoundsLength,
            GetMostRecentGestureEvent().details.bounding_box_f().width());
  EXPECT_EQ(kMaxGestureBoundsLength,
            GetMostRecentGestureEvent().details.bounding_box_f().height());

  event =
      ObtainMotionEvent(event_time + kOneMicrosecond, MotionEvent::ACTION_UP);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP, GetMostRecentGestureEventType());
  EXPECT_EQ(kMaxGestureBoundsLength,
            GetMostRecentGestureEvent().details.bounding_box_f().width());
  EXPECT_EQ(kMaxGestureBoundsLength,
            GetMostRecentGestureEvent().details.bounding_box_f().height());
}

TEST_F(GestureProviderTest, ZeroRadiusBoundingBox) {
  base::TimeTicks event_time = base::TimeTicks::Now();
  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN, 10, 20);
  event.SetTouchMajor(0);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(gfx::RectF(10, 20, 0, 0),
            GetMostRecentGestureEvent().details.bounding_box());

  event = ObtainMotionEvent(
      event_time, MotionEvent::ACTION_POINTER_DOWN, 10, 20, 110, 120);
  event.SetTouchMajor(0);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  event = ObtainMotionEvent(
      event_time, MotionEvent::ACTION_MOVE, 10, 20, 110, 150);
  event.SetTouchMajor(0);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  EXPECT_EQ(gfx::RectF(10, 20, 100, 130),
            GetMostRecentGestureEvent().details.bounding_box());
}

// Verify that the min/max gesture bound settings are not applied to stylus
// or mouse-derived MotionEvents.
TEST_F(GestureProviderTest, NoMinOrMaxGestureBoundsLengthWithStylusOrMouse) {
  const float kMinGestureBoundsLength = 5.f * kMockTouchRadius;
  const float kMaxGestureBoundsLength = 10.f * kMockTouchRadius;
  SetMinMaxGestureBoundsLength(kMinGestureBoundsLength,
                               kMaxGestureBoundsLength);
  gesture_provider_->SetDoubleTapSupportForPlatformEnabled(false);

  base::TimeTicks event_time = base::TimeTicks::Now();
  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);
  event.SetTouchMajor(0);
  event.SetToolType(0, MotionEvent::TOOL_TYPE_MOUSE);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));

  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(MotionEvent::TOOL_TYPE_MOUSE,
            GetMostRecentGestureEvent().primary_tool_type);
  EXPECT_EQ(0.f, GetMostRecentGestureEvent().details.bounding_box_f().width());
  EXPECT_EQ(0.f, GetMostRecentGestureEvent().details.bounding_box_f().height());

  event =
      ObtainMotionEvent(event_time + kOneMicrosecond, MotionEvent::ACTION_UP);
  event.SetTouchMajor(1);
  event.SetToolType(0, MotionEvent::TOOL_TYPE_STYLUS);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP, GetMostRecentGestureEventType());
  EXPECT_EQ(MotionEvent::TOOL_TYPE_STYLUS,
            GetMostRecentGestureEvent().primary_tool_type);
  EXPECT_EQ(0, GetMostRecentGestureEvent().details.bounding_box_f().width());
  EXPECT_EQ(0, GetMostRecentGestureEvent().details.bounding_box_f().height());

  event = ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN);
  event.SetTouchMajor(2.f * kMaxGestureBoundsLength);
  event.SetToolType(0, MotionEvent::TOOL_TYPE_MOUSE);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(MotionEvent::TOOL_TYPE_MOUSE,
            GetMostRecentGestureEvent().primary_tool_type);
  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(2.f * kMaxGestureBoundsLength,
            GetMostRecentGestureEvent().details.bounding_box_f().width());
  EXPECT_EQ(2.f * kMaxGestureBoundsLength,
            GetMostRecentGestureEvent().details.bounding_box_f().height());

  event =
      ObtainMotionEvent(event_time + kOneMicrosecond, MotionEvent::ACTION_UP);
  event.SetTouchMajor(2.f * kMaxGestureBoundsLength);
  event.SetToolType(0, MotionEvent::TOOL_TYPE_ERASER);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP, GetMostRecentGestureEventType());
  EXPECT_EQ(MotionEvent::TOOL_TYPE_ERASER,
            GetMostRecentGestureEvent().primary_tool_type);
  EXPECT_EQ(2.f * kMaxGestureBoundsLength,
            GetMostRecentGestureEvent().details.bounding_box_f().width());
  EXPECT_EQ(2.f * kMaxGestureBoundsLength,
            GetMostRecentGestureEvent().details.bounding_box_f().height());
}

// Test the bounding box for show press and tap gestures.
TEST_F(GestureProviderTest, BoundingBoxForShowPressAndTapGesture) {
  base::TimeTicks event_time = base::TimeTicks::Now();
  gesture_provider_->SetDoubleTapSupportForPlatformEnabled(false);
  base::TimeDelta showpress_timeout = kOneMicrosecond;
  base::TimeDelta longpress_timeout = kOneSecond;
  SetShowPressAndLongPressTimeout(showpress_timeout, longpress_timeout);

  MockMotionEvent event =
      ObtainMotionEvent(event_time, MotionEvent::ACTION_DOWN, 10, 10);
  event.SetTouchMajor(10);

  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP_DOWN, GetMostRecentGestureEventType());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_EQ(gfx::RectF(5, 5, 10, 10),
            GetMostRecentGestureEvent().details.bounding_box());

  event = ObtainMotionEvent(
      event_time + kOneMicrosecond, MotionEvent::ACTION_MOVE, 11, 9);
  event.SetTouchMajor(20);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  event = ObtainMotionEvent(
      event_time + kOneMicrosecond, MotionEvent::ACTION_MOVE, 8, 11);
  event.SetTouchMajor(10);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  RunTasksAndWait(showpress_timeout + kOneMicrosecond);
  EXPECT_EQ(ET_GESTURE_SHOW_PRESS, GetMostRecentGestureEventType());
  EXPECT_EQ(gfx::RectF(0, 0, 20, 20),
            GetMostRecentGestureEvent().details.bounding_box());

  event =
      ObtainMotionEvent(event_time + kOneMicrosecond, MotionEvent::ACTION_UP);
  event.SetTouchMajor(30);
  EXPECT_TRUE(gesture_provider_->OnTouchEvent(event));
  EXPECT_EQ(ET_GESTURE_TAP, GetMostRecentGestureEventType());

  EXPECT_EQ(1, GetMostRecentGestureEvent().details.tap_count());
  EXPECT_EQ(1, GetMostRecentGestureEvent().details.touch_points());
  EXPECT_EQ(gfx::RectF(0, 0, 20, 20),
            GetMostRecentGestureEvent().details.bounding_box());
}

}  // namespace ui
