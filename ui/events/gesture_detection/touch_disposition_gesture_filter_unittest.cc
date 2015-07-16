// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/basictypes.h"
#include "base/memory/scoped_ptr.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/events/gesture_detection/touch_disposition_gesture_filter.h"
#include "ui/events/test/mock_motion_event.h"

using ui::test::MockMotionEvent;

namespace ui {
namespace {

const int kDefaultEventFlags = EF_ALT_DOWN | EF_SHIFT_DOWN;

}  // namespace

class TouchDispositionGestureFilterTest
    : public testing::Test,
      public TouchDispositionGestureFilterClient {
 public:
  TouchDispositionGestureFilterTest()
      : cancel_after_next_gesture_(false), sent_gesture_count_(0) {}
  ~TouchDispositionGestureFilterTest() override {}

  // testing::Test
  void SetUp() override {
    queue_.reset(new TouchDispositionGestureFilter(this));
    touch_event_.set_flags(kDefaultEventFlags);
  }

  void TearDown() override {
    queue_.reset();
  }

  // TouchDispositionGestureFilterClient
  void ForwardGestureEvent(const GestureEventData& event) override {
    ++sent_gesture_count_;
    last_sent_gesture_.reset(new GestureEventData(event));
    sent_gestures_.push_back(event.type());
    if (event.type() == ET_GESTURE_SHOW_PRESS)
      show_press_bounding_box_ = event.details.bounding_box();
    if (cancel_after_next_gesture_) {
      cancel_after_next_gesture_ = false;
      CancelTouchPoint();
      SendTouchNotConsumedAck();
    }
  }

 protected:
  typedef std::vector<EventType> GestureList;

  ::testing::AssertionResult GesturesMatch(const GestureList& expected,
                                           const GestureList& actual) {
    if (expected.size() != actual.size()) {
      return ::testing::AssertionFailure()
          << "actual.size(" << actual.size()
          << ") != expected.size(" << expected.size() << ")";
    }

    for (size_t i = 0; i < expected.size(); ++i) {
      if (expected[i] != actual[i]) {
        return ::testing::AssertionFailure()
            << "actual[" << i << "] ("
            << actual[i]
            << ") != expected[" << i << "] ("
            << expected[i] << ")";
      }
    }

    return ::testing::AssertionSuccess();
  }

  GestureList Gestures(EventType type) {
    return GestureList(1, type);
  }

  GestureList Gestures(EventType type0, EventType type1) {
    GestureList gestures(2);
    gestures[0] = type0;
    gestures[1] = type1;
    return gestures;
  }

  GestureList Gestures(EventType type0,
                       EventType type1,
                       EventType type2) {
    GestureList gestures(3);
    gestures[0] = type0;
    gestures[1] = type1;
    gestures[2] = type2;
    return gestures;
  }

  GestureList Gestures(EventType type0,
                       EventType type1,
                       EventType type2,
                       EventType type3) {
    GestureList gestures(4);
    gestures[0] = type0;
    gestures[1] = type1;
    gestures[2] = type2;
    gestures[3] = type3;
    return gestures;
  }

  void SendTouchGestures() {
    touch_event_.set_event_time(base::TimeTicks::Now());
    EXPECT_EQ(TouchDispositionGestureFilter::SUCCESS,
              SendTouchGestures(touch_event_, pending_gesture_packet_));
    GestureEventDataPacket gesture_packet;
    std::swap(gesture_packet, pending_gesture_packet_);
  }

  TouchDispositionGestureFilter::PacketResult
  SendTouchGestures(const MotionEvent& touch,
                    const GestureEventDataPacket& packet) {
    GestureEventDataPacket touch_packet =
        GestureEventDataPacket::FromTouch(touch);
    for (size_t i = 0; i < packet.gesture_count(); ++i)
      touch_packet.Push(packet.gesture(i));
    return queue_->OnGesturePacket(touch_packet);
  }

  TouchDispositionGestureFilter::PacketResult
  SendTimeoutGesture(EventType type) {
    return queue_->OnGesturePacket(
        GestureEventDataPacket::FromTouchTimeout(CreateGesture(type)));
  }

  TouchDispositionGestureFilter::PacketResult
  SendGesturePacket(const GestureEventDataPacket& packet) {
    return queue_->OnGesturePacket(packet);
  }

  void SendTouchEventAck(bool event_consumed) {
    queue_->OnTouchEventAck(event_consumed);
  }

  void SendTouchConsumedAck() { SendTouchEventAck(true); }

  void SendTouchNotConsumedAck() { SendTouchEventAck(false); }

  void PushGesture(EventType type) {
    pending_gesture_packet_.Push(CreateGesture(type));
  }

  void PushGesture(EventType type, float x, float y, float diameter) {
    pending_gesture_packet_.Push(CreateGesture(type, x, y, diameter));
  }

  void PressTouchPoint(int x, int y) {
    touch_event_.PressPoint(x, y);
    touch_event_.SetRawOffset(raw_offset_.x(), raw_offset_.y());
    SendTouchGestures();
  }

  void MoveTouchPoint(size_t index, int x, int y) {
    touch_event_.MovePoint(index, x, y);
    touch_event_.SetRawOffset(raw_offset_.x(), raw_offset_.y());
    SendTouchGestures();
  }

  void ReleaseTouchPoint() {
    touch_event_.ReleasePoint();
    SendTouchGestures();
  }

  void CancelTouchPoint() {
    touch_event_.CancelPoint();
    SendTouchGestures();
  }

  void SetRawTouchOffset(const gfx::Vector2dF& raw_offset) {
    raw_offset_ = raw_offset;
  }

  void ResetTouchPoints() { touch_event_ = MockMotionEvent(); }

  bool GesturesSent() const { return !sent_gestures_.empty(); }

  base::TimeTicks LastSentGestureTime() const {
    CHECK(last_sent_gesture_);
    return last_sent_gesture_->time;
  }

  base::TimeTicks CurrentTouchTime() const {
    return touch_event_.GetEventTime();
  }

  bool IsEmpty() const { return queue_->IsEmpty(); }

  GestureList GetAndResetSentGestures() {
    GestureList sent_gestures;
    sent_gestures.swap(sent_gestures_);
    return sent_gestures;
  }

  gfx::PointF LastSentGestureLocation() const {
    CHECK(last_sent_gesture_);
    return gfx::PointF(last_sent_gesture_->x, last_sent_gesture_->y);
  }

  gfx::PointF LastSentGestureRawLocation() const {
    CHECK(last_sent_gesture_);
    return gfx::PointF(last_sent_gesture_->raw_x, last_sent_gesture_->raw_y);
  }

  int LastSentGestureFlags() const {
    CHECK(last_sent_gesture_);
    return last_sent_gesture_->flags;
  }

  const gfx::RectF& ShowPressBoundingBox() const {
    return show_press_bounding_box_;
  }

  void SetCancelAfterNextGesture(bool cancel_after_next_gesture) {
    cancel_after_next_gesture_ = cancel_after_next_gesture;
  }

  GestureEventData CreateGesture(EventType type) {
    return CreateGesture(type, 0, 0, 0);
  }

  GestureEventData CreateGesture(EventType type,
                                 float x,
                                 float y,
                                 float diameter) {
    return GestureEventData(
        GestureEventDetails(type),
        0,
        MotionEvent::TOOL_TYPE_FINGER,
        base::TimeTicks(),
        touch_event_.GetX(0),
        touch_event_.GetY(0),
        touch_event_.GetRawX(0),
        touch_event_.GetRawY(0),
        1,
        gfx::RectF(x - diameter / 2, y - diameter / 2, diameter, diameter),
        kDefaultEventFlags);
  }

 private:
  scoped_ptr<TouchDispositionGestureFilter> queue_;
  bool cancel_after_next_gesture_;
  MockMotionEvent touch_event_;
  GestureEventDataPacket pending_gesture_packet_;
  size_t sent_gesture_count_;
  GestureList sent_gestures_;
  gfx::Vector2dF raw_offset_;
  scoped_ptr<GestureEventData> last_sent_gesture_;
  gfx::RectF show_press_bounding_box_;
};

TEST_F(TouchDispositionGestureFilterTest, BasicNoGestures) {
  PressTouchPoint(1, 1);
  EXPECT_FALSE(GesturesSent());

  MoveTouchPoint(0, 2, 2);
  EXPECT_FALSE(GesturesSent());

  // No gestures should be dispatched by the ack, as the queued packets
  // contained no gestures.
  SendTouchConsumedAck();
  EXPECT_FALSE(GesturesSent());

  // Release the touch gesture.
  ReleaseTouchPoint();
  SendTouchConsumedAck();
  SendTouchConsumedAck();
  EXPECT_FALSE(GesturesSent());
}

TEST_F(TouchDispositionGestureFilterTest, BasicGestures) {
  // An unconsumed touch's gesture should be sent.
  PushGesture(ET_GESTURE_BEGIN);
  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  PressTouchPoint(1, 1);
  EXPECT_FALSE(GesturesSent());
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_BEGIN, ET_GESTURE_SCROLL_BEGIN),
                            GetAndResetSentGestures()));

  // Multiple gestures can be queued for a single event.
  PushGesture(ET_SCROLL_FLING_START);
  PushGesture(ET_SCROLL_FLING_CANCEL);
  PushGesture(ET_GESTURE_END);
  ReleaseTouchPoint();
  EXPECT_FALSE(GesturesSent());
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_SCROLL_FLING_START,
                                     ET_SCROLL_FLING_CANCEL,
                                     ET_GESTURE_END),
                            GetAndResetSentGestures()));
}

TEST_F(TouchDispositionGestureFilterTest, BasicGesturesConsumed) {
  // A consumed touch's gesture should not be sent.
  PushGesture(ET_GESTURE_BEGIN);
  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  PressTouchPoint(1, 1);
  SendTouchConsumedAck();
  EXPECT_FALSE(GesturesSent());

  PushGesture(ET_GESTURE_SCROLL_UPDATE);
  MoveTouchPoint(0, 2, 2);
  SendTouchConsumedAck();
  EXPECT_FALSE(GesturesSent());

  PushGesture(ET_SCROLL_FLING_START);
  PushGesture(ET_SCROLL_FLING_CANCEL);
  PushGesture(ET_GESTURE_END);
  ReleaseTouchPoint();
  SendTouchConsumedAck();
  EXPECT_FALSE(GesturesSent());
}

TEST_F(TouchDispositionGestureFilterTest, ConsumedThenNotConsumed) {
  // A consumed touch's gesture should not be sent.
  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  PressTouchPoint(1, 1);
  SendTouchConsumedAck();
  EXPECT_FALSE(GesturesSent());

  // Even if the subsequent touch is not consumed, continue dropping gestures.
  PushGesture(ET_GESTURE_SCROLL_UPDATE);
  MoveTouchPoint(0, 2, 2);
  SendTouchNotConsumedAck();
  EXPECT_FALSE(GesturesSent());

  // Even if the subsequent touch had no consumer, continue dropping gestures.
  PushGesture(ET_SCROLL_FLING_START);
  ReleaseTouchPoint();
  SendTouchNotConsumedAck();
  EXPECT_FALSE(GesturesSent());
}

TEST_F(TouchDispositionGestureFilterTest, NotConsumedThenConsumed) {
  // A not consumed touch's gesture should be sent.
  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SCROLL_BEGIN),
                            GetAndResetSentGestures()));

  // A newly consumed gesture should not be sent.
  PushGesture(ET_GESTURE_PINCH_BEGIN);
  PressTouchPoint(10, 10);
  SendTouchConsumedAck();
  EXPECT_FALSE(GesturesSent());

  // And subsequent non-consumed pinch updates should not be sent.
  PushGesture(ET_GESTURE_SCROLL_UPDATE);
  PushGesture(ET_GESTURE_PINCH_UPDATE);
  MoveTouchPoint(0, 2, 2);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SCROLL_UPDATE),
                            GetAndResetSentGestures()));

  // End events dispatched only when their start events were.
  PushGesture(ET_GESTURE_PINCH_END);
  ReleaseTouchPoint();
  SendTouchNotConsumedAck();
  EXPECT_FALSE(GesturesSent());

  PushGesture(ET_GESTURE_SCROLL_END);
  ReleaseTouchPoint();
  SendTouchConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SCROLL_END),
                            GetAndResetSentGestures()));
}

TEST_F(TouchDispositionGestureFilterTest, ScrollAlternatelyConsumed) {
  // A consumed touch's gesture should not be sent.
  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SCROLL_BEGIN),
                            GetAndResetSentGestures()));

  for (size_t i = 0; i < 3; ++i) {
    PushGesture(ET_GESTURE_SCROLL_UPDATE);
    MoveTouchPoint(0, 2, 2);
    SendTouchConsumedAck();
    EXPECT_FALSE(GesturesSent());

    PushGesture(ET_GESTURE_SCROLL_UPDATE);
    MoveTouchPoint(0, 3, 3);
    SendTouchNotConsumedAck();
    EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SCROLL_UPDATE),
                              GetAndResetSentGestures()));
  }

  PushGesture(ET_GESTURE_SCROLL_END);
  ReleaseTouchPoint();
  SendTouchConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SCROLL_END),
                            GetAndResetSentGestures()));
}

TEST_F(TouchDispositionGestureFilterTest, NotConsumedThenNoConsumer) {
  // An unconsumed touch's gesture should be sent.
  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SCROLL_BEGIN),
                            GetAndResetSentGestures()));

  // If the subsequent touch has no consumer (e.g., a secondary pointer is
  // pressed but not on a touch handling rect), send the gesture.
  PushGesture(ET_GESTURE_PINCH_BEGIN);
  PressTouchPoint(2, 2);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_PINCH_BEGIN),
                            GetAndResetSentGestures()));

  // End events should be dispatched when their start events were, independent
  // of the ack state.
  PushGesture(ET_GESTURE_PINCH_END);
  ReleaseTouchPoint();
  SendTouchConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_PINCH_END),
                            GetAndResetSentGestures()));

  PushGesture(ET_GESTURE_SCROLL_END);
  ReleaseTouchPoint();
  SendTouchConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SCROLL_END),
                            GetAndResetSentGestures()));
}

TEST_F(TouchDispositionGestureFilterTest, EndingEventsSent) {
  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SCROLL_BEGIN),
                            GetAndResetSentGestures()));

  PushGesture(ET_GESTURE_PINCH_BEGIN);
  PressTouchPoint(2, 2);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_PINCH_BEGIN),
                            GetAndResetSentGestures()));

  // Consuming the touchend event can't suppress the match end gesture.
  PushGesture(ET_GESTURE_PINCH_END);
  ReleaseTouchPoint();
  SendTouchConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_PINCH_END),
                            GetAndResetSentGestures()));

  // But other events in the same packet are still suppressed.
  PushGesture(ET_GESTURE_SCROLL_UPDATE);
  PushGesture(ET_GESTURE_SCROLL_END);
  ReleaseTouchPoint();
  SendTouchConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SCROLL_END),
                            GetAndResetSentGestures()));

  // ET_GESTURE_SCROLL_END and ET_SCROLL_FLING_START behave the same in this
  // regard.
  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SCROLL_BEGIN),
                            GetAndResetSentGestures()));

  PushGesture(ET_SCROLL_FLING_START);
  ReleaseTouchPoint();
  SendTouchConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_SCROLL_FLING_START),
                            GetAndResetSentGestures()));
}

TEST_F(TouchDispositionGestureFilterTest, EndingEventsNotSent) {
  // Consuming a begin event ensures no end events are sent.
  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  PressTouchPoint(1, 1);
  SendTouchConsumedAck();
  EXPECT_FALSE(GesturesSent());

  PushGesture(ET_GESTURE_PINCH_BEGIN);
  PressTouchPoint(2, 2);
  SendTouchNotConsumedAck();
  EXPECT_FALSE(GesturesSent());

  PushGesture(ET_GESTURE_PINCH_END);
  ReleaseTouchPoint();
  SendTouchNotConsumedAck();
  EXPECT_FALSE(GesturesSent());

  PushGesture(ET_GESTURE_SCROLL_END);
  ReleaseTouchPoint();
  SendTouchNotConsumedAck();
  EXPECT_FALSE(GesturesSent());
}

TEST_F(TouchDispositionGestureFilterTest, UpdateEventsSuppressedPerEvent) {
  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SCROLL_BEGIN),
                            GetAndResetSentGestures()));

  // Consuming a single scroll or pinch update should suppress only that event.
  PushGesture(ET_GESTURE_SCROLL_UPDATE);
  MoveTouchPoint(0, 2, 2);
  SendTouchConsumedAck();
  EXPECT_FALSE(GesturesSent());

  PushGesture(ET_GESTURE_PINCH_BEGIN);
  PressTouchPoint(2, 2);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_PINCH_BEGIN),
                            GetAndResetSentGestures()));

  PushGesture(ET_GESTURE_PINCH_UPDATE);
  MoveTouchPoint(1, 2, 3);
  SendTouchConsumedAck();
  EXPECT_FALSE(GesturesSent());

  // Subsequent updates should not be affected.
  PushGesture(ET_GESTURE_SCROLL_UPDATE);
  MoveTouchPoint(0, 4, 4);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SCROLL_UPDATE),
                            GetAndResetSentGestures()));

  PushGesture(ET_GESTURE_PINCH_UPDATE);
  MoveTouchPoint(0, 4, 5);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_PINCH_UPDATE),
                            GetAndResetSentGestures()));

  PushGesture(ET_GESTURE_PINCH_END);
  ReleaseTouchPoint();
  SendTouchConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_PINCH_END),
                            GetAndResetSentGestures()));

  PushGesture(ET_GESTURE_SCROLL_END);
  ReleaseTouchPoint();
  SendTouchConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SCROLL_END),
                            GetAndResetSentGestures()));
}

TEST_F(TouchDispositionGestureFilterTest, UpdateEventsDependOnBeginEvents) {
  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  PressTouchPoint(1, 1);
  SendTouchConsumedAck();
  EXPECT_FALSE(GesturesSent());

  // Scroll and pinch gestures depend on the scroll begin gesture being
  // dispatched.
  PushGesture(ET_GESTURE_SCROLL_UPDATE);
  MoveTouchPoint(0, 2, 2);
  SendTouchNotConsumedAck();
  EXPECT_FALSE(GesturesSent());

  PushGesture(ET_GESTURE_PINCH_BEGIN);
  PressTouchPoint(2, 2);
  SendTouchNotConsumedAck();
  EXPECT_FALSE(GesturesSent());

  PushGesture(ET_GESTURE_PINCH_UPDATE);
  MoveTouchPoint(1, 2, 3);
  SendTouchConsumedAck();
  EXPECT_FALSE(GesturesSent());

  PushGesture(ET_GESTURE_PINCH_END);
  ReleaseTouchPoint();
  SendTouchNotConsumedAck();
  EXPECT_FALSE(GesturesSent());

  PushGesture(ET_GESTURE_SCROLL_END);
  ReleaseTouchPoint();
  SendTouchNotConsumedAck();
  EXPECT_FALSE(GesturesSent());
}

TEST_F(TouchDispositionGestureFilterTest, MultipleTouchSequences) {
  // Queue two touch-to-gestures sequences.
  PushGesture(ET_GESTURE_TAP_DOWN);
  PressTouchPoint(1, 1);
  PushGesture(ET_GESTURE_TAP);
  ReleaseTouchPoint();
  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  PressTouchPoint(1, 1);
  PushGesture(ET_GESTURE_SCROLL_END);
  ReleaseTouchPoint();

  // The first gesture sequence should not be allowed.
  SendTouchConsumedAck();
  SendTouchNotConsumedAck();
  EXPECT_FALSE(GesturesSent());

  // The subsequent sequence should "reset" allowance.
  SendTouchNotConsumedAck();
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SCROLL_BEGIN,
                                     ET_GESTURE_SCROLL_END),
                            GetAndResetSentGestures()));
}

TEST_F(TouchDispositionGestureFilterTest, FlingCancelledOnNewTouchSequence) {
  const gfx::Vector2dF raw_offset(1.3f, 3.7f);
  SetRawTouchOffset(raw_offset);

  // Simulate a fling.
  PushGesture(ET_GESTURE_TAP_DOWN);
  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(
      Gestures(
          ET_GESTURE_TAP_DOWN, ET_GESTURE_TAP_CANCEL, ET_GESTURE_SCROLL_BEGIN),
      GetAndResetSentGestures()));
  PushGesture(ET_SCROLL_FLING_START);
  ReleaseTouchPoint();
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_SCROLL_FLING_START),
                            GetAndResetSentGestures()));

  // A new touch sequence should cancel the outstanding fling.
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_SCROLL_FLING_CANCEL),
                            GetAndResetSentGestures()));
  EXPECT_EQ(CurrentTouchTime(), LastSentGestureTime());
  EXPECT_EQ(LastSentGestureLocation(), gfx::PointF(1, 1));
  EXPECT_EQ(LastSentGestureRawLocation(), gfx::PointF(1, 1) + raw_offset);
  ReleaseTouchPoint();
  SendTouchNotConsumedAck();
  EXPECT_FALSE(GesturesSent());
}

TEST_F(TouchDispositionGestureFilterTest, ScrollEndedOnTouchReleaseIfNoFling) {
  // Simulate a scroll.
  PushGesture(ET_GESTURE_TAP_DOWN);
  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(
      Gestures(
          ET_GESTURE_TAP_DOWN, ET_GESTURE_TAP_CANCEL, ET_GESTURE_SCROLL_BEGIN),
      GetAndResetSentGestures()));
  ReleaseTouchPoint();
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SCROLL_END),
                            GetAndResetSentGestures()));
  EXPECT_EQ(CurrentTouchTime(), LastSentGestureTime());
  EXPECT_EQ(LastSentGestureLocation(), gfx::PointF(1, 1));
}

TEST_F(TouchDispositionGestureFilterTest, ScrollEndedOnNewTouchSequence) {
  // Simulate a scroll.
  PushGesture(ET_GESTURE_TAP_DOWN);
  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(
      Gestures(
          ET_GESTURE_TAP_DOWN, ET_GESTURE_TAP_CANCEL, ET_GESTURE_SCROLL_BEGIN),
      GetAndResetSentGestures()));

  // A new touch sequence should end the outstanding scroll.
  ResetTouchPoints();
  PressTouchPoint(2, 3);
  SendTouchConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SCROLL_END),
                            GetAndResetSentGestures()));
  EXPECT_EQ(CurrentTouchTime(), LastSentGestureTime());
  EXPECT_EQ(LastSentGestureLocation(), gfx::PointF(2, 3));
}

TEST_F(TouchDispositionGestureFilterTest, FlingCancelledOnScrollBegin) {
  // Simulate a fling sequence.
  PushGesture(ET_GESTURE_TAP_DOWN);
  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  PushGesture(ET_SCROLL_FLING_START);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_TAP_DOWN,
                                     ET_GESTURE_TAP_CANCEL,
                                     ET_GESTURE_SCROLL_BEGIN,
                                     ET_SCROLL_FLING_START),
                            GetAndResetSentGestures()));

  // The new fling should cancel the preceding one.
  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  PushGesture(ET_SCROLL_FLING_START);
  ReleaseTouchPoint();
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_SCROLL_FLING_CANCEL,
                                     ET_GESTURE_SCROLL_BEGIN,
                                     ET_SCROLL_FLING_START),
                            GetAndResetSentGestures()));
}

TEST_F(TouchDispositionGestureFilterTest, FlingNotCancelledIfGFCEventReceived) {
  // Simulate a fling that is started then cancelled.
  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  PushGesture(ET_SCROLL_FLING_START);
  MoveTouchPoint(0, 2, 3);
  SendTouchNotConsumedAck();
  PushGesture(ET_SCROLL_FLING_CANCEL);
  ReleaseTouchPoint();
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SCROLL_BEGIN,
                                     ET_SCROLL_FLING_START,
                                     ET_SCROLL_FLING_CANCEL),
                            GetAndResetSentGestures()));
  EXPECT_EQ(LastSentGestureLocation(), gfx::PointF(2, 3));

  // A new touch sequence will not inject a ET_SCROLL_FLING_CANCEL, as the fling
  // has already been cancelled.
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  ReleaseTouchPoint();
  SendTouchNotConsumedAck();
  EXPECT_FALSE(GesturesSent());
}

TEST_F(TouchDispositionGestureFilterTest, TapCancelledWhenScrollBegins) {
  PushGesture(ET_GESTURE_TAP_DOWN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_TAP_DOWN),
                            GetAndResetSentGestures()));

  // If the subsequent touch turns into a scroll, the tap should be cancelled.
  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  MoveTouchPoint(0, 2, 2);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_TAP_CANCEL,
                                     ET_GESTURE_SCROLL_BEGIN),
                            GetAndResetSentGestures()));
}

TEST_F(TouchDispositionGestureFilterTest, TapCancelledWhenTouchConsumed) {
  PushGesture(ET_GESTURE_TAP_DOWN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_TAP_DOWN),
                            GetAndResetSentGestures()));

  // If the subsequent touch is consumed, the tap should be cancelled.
  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  MoveTouchPoint(0, 2, 2);
  SendTouchConsumedAck();
  EXPECT_TRUE(
      GesturesMatch(Gestures(ET_GESTURE_TAP_CANCEL, ET_GESTURE_SCROLL_BEGIN),
                    GetAndResetSentGestures()));
  EXPECT_EQ(LastSentGestureLocation(), gfx::PointF(1, 1));
}

TEST_F(TouchDispositionGestureFilterTest,
       TapNotCancelledIfTapEndingEventReceived) {
  PushGesture(ET_GESTURE_TAP_DOWN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(
      GesturesMatch(Gestures(ET_GESTURE_TAP_DOWN), GetAndResetSentGestures()));

  PushGesture(ET_GESTURE_TAP);
  ReleaseTouchPoint();
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SHOW_PRESS, ET_GESTURE_TAP),
                            GetAndResetSentGestures()));

  // The tap should not be cancelled as it was terminated by a |ET_GESTURE_TAP|.
  PressTouchPoint(2, 2);
  SendTouchConsumedAck();
  EXPECT_FALSE(GesturesSent());
}

TEST_F(TouchDispositionGestureFilterTest, TimeoutGestures) {
  // If the sequence is allowed, and there are no preceding gestures, the
  // timeout gestures should be forwarded immediately.
  PushGesture(ET_GESTURE_TAP_DOWN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_TAP_DOWN),
                            GetAndResetSentGestures()));

  SendTimeoutGesture(ET_GESTURE_SHOW_PRESS);
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SHOW_PRESS),
                            GetAndResetSentGestures()));

  SendTimeoutGesture(ET_GESTURE_LONG_PRESS);
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_LONG_PRESS),
                            GetAndResetSentGestures()));

  PushGesture(ET_GESTURE_LONG_TAP);
  ReleaseTouchPoint();
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_TAP_CANCEL,
                                     ET_GESTURE_LONG_TAP),
                            GetAndResetSentGestures()));

  // If the sequence is disallowed, and there are no preceding gestures, the
  // timeout gestures should be dropped immediately.
  PushGesture(ET_GESTURE_TAP_DOWN);
  PressTouchPoint(1, 1);
  SendTouchConsumedAck();
  EXPECT_FALSE(GesturesSent());

  SendTimeoutGesture(ET_GESTURE_SHOW_PRESS);
  EXPECT_FALSE(GesturesSent());
  ReleaseTouchPoint();
  SendTouchNotConsumedAck();

  // If the sequence has a pending ack, the timeout gestures should
  // remain queued until the ack is received.
  PushGesture(ET_GESTURE_TAP_DOWN);
  PressTouchPoint(1, 1);
  EXPECT_FALSE(GesturesSent());

  SendTimeoutGesture(ET_GESTURE_LONG_PRESS);
  EXPECT_FALSE(GesturesSent());

  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_TAP_DOWN,
                                     ET_GESTURE_LONG_PRESS),
                            GetAndResetSentGestures()));
}

TEST_F(TouchDispositionGestureFilterTest, SpuriousAcksIgnored) {
  // Acks received when the queue is empty will be safely ignored.
  ASSERT_TRUE(IsEmpty());
  SendTouchConsumedAck();
  EXPECT_FALSE(GesturesSent());

  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  PressTouchPoint(1, 1);
  PushGesture(ET_GESTURE_SCROLL_UPDATE);
  MoveTouchPoint(0, 3,3);
  SendTouchNotConsumedAck();
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SCROLL_BEGIN,
                                     ET_GESTURE_SCROLL_UPDATE),
                            GetAndResetSentGestures()));

  // Even if all packets have been dispatched, the filter may not be empty as
  // there could be follow-up timeout events.  Spurious acks in such cases
  // should also be safely ignored.
  ASSERT_FALSE(IsEmpty());
  SendTouchConsumedAck();
  EXPECT_FALSE(GesturesSent());
}

TEST_F(TouchDispositionGestureFilterTest, PacketWithInvalidTypeIgnored) {
  GestureEventDataPacket packet;
  EXPECT_EQ(TouchDispositionGestureFilter::INVALID_PACKET_TYPE,
            SendGesturePacket(packet));
  EXPECT_TRUE(IsEmpty());
}

TEST_F(TouchDispositionGestureFilterTest, PacketsWithInvalidOrderIgnored) {
  EXPECT_EQ(TouchDispositionGestureFilter::INVALID_PACKET_ORDER,
            SendTimeoutGesture(ET_GESTURE_SHOW_PRESS));
  EXPECT_TRUE(IsEmpty());
}

TEST_F(TouchDispositionGestureFilterTest, ConsumedTouchCancel) {
  // An unconsumed touch's gesture should be sent.
  PushGesture(ET_GESTURE_TAP_DOWN);
  PressTouchPoint(1, 1);
  EXPECT_FALSE(GesturesSent());
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_TAP_DOWN),
                            GetAndResetSentGestures()));

  PushGesture(ET_GESTURE_TAP_CANCEL);
  PushGesture(ET_GESTURE_SCROLL_END);
  CancelTouchPoint();
  EXPECT_FALSE(GesturesSent());
  SendTouchConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_TAP_CANCEL,
                                     ET_GESTURE_SCROLL_END),
                            GetAndResetSentGestures()));
}

TEST_F(TouchDispositionGestureFilterTest, TimeoutEventAfterRelease) {
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_FALSE(GesturesSent());
  PushGesture(ET_GESTURE_TAP_DOWN);
  PushGesture(ET_GESTURE_TAP_UNCONFIRMED);
  ReleaseTouchPoint();
  SendTouchNotConsumedAck();
  EXPECT_TRUE(
      GesturesMatch(Gestures(ET_GESTURE_TAP_DOWN, ET_GESTURE_TAP_UNCONFIRMED),
                    GetAndResetSentGestures()));

  SendTimeoutGesture(ET_GESTURE_TAP);
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SHOW_PRESS, ET_GESTURE_TAP),
                            GetAndResetSentGestures()));
}

TEST_F(TouchDispositionGestureFilterTest, ShowPressInsertedBeforeTap) {
  PushGesture(ET_GESTURE_TAP_DOWN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_TAP_DOWN),
                            GetAndResetSentGestures()));

  SendTimeoutGesture(ET_GESTURE_TAP_UNCONFIRMED);
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_TAP_UNCONFIRMED),
                            GetAndResetSentGestures()));

  PushGesture(ET_GESTURE_TAP);
  ReleaseTouchPoint();
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SHOW_PRESS,
                                     ET_GESTURE_TAP),
                            GetAndResetSentGestures()));
}

TEST_F(TouchDispositionGestureFilterTest, ShowPressNotInsertedIfAlreadySent) {
  PushGesture(ET_GESTURE_TAP_DOWN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_TAP_DOWN),
                            GetAndResetSentGestures()));

  SendTimeoutGesture(ET_GESTURE_SHOW_PRESS);
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SHOW_PRESS),
                            GetAndResetSentGestures()));

  PushGesture(ET_GESTURE_TAP);
  ReleaseTouchPoint();
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_TAP),
                            GetAndResetSentGestures()));
}

TEST_F(TouchDispositionGestureFilterTest, TapAndScrollCancelledOnTouchCancel) {
  const gfx::Vector2dF raw_offset(1.3f, 3.7f);
  SetRawTouchOffset(raw_offset);

  PushGesture(ET_GESTURE_TAP_DOWN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_TAP_DOWN),
                            GetAndResetSentGestures()));

  // A cancellation motion event should cancel the tap.
  CancelTouchPoint();
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_TAP_CANCEL),
                            GetAndResetSentGestures()));
  EXPECT_EQ(CurrentTouchTime(), LastSentGestureTime());
  EXPECT_EQ(LastSentGestureLocation(), gfx::PointF(1, 1));
  EXPECT_EQ(LastSentGestureRawLocation(), gfx::PointF(1, 1) + raw_offset);

  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SCROLL_BEGIN),
                            GetAndResetSentGestures()));

  // A cancellation motion event should end the scroll, even if the touch was
  // consumed.
  CancelTouchPoint();
  SendTouchConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SCROLL_END),
                            GetAndResetSentGestures()));
  EXPECT_EQ(CurrentTouchTime(), LastSentGestureTime());
  EXPECT_EQ(LastSentGestureLocation(), gfx::PointF(1, 1));
  EXPECT_EQ(LastSentGestureRawLocation(), gfx::PointF(1, 1) + raw_offset);
}

TEST_F(TouchDispositionGestureFilterTest,
       ConsumedScrollUpdateMakesFlingScrollEnd) {
  // A consumed touch's gesture should not be sent.
  PushGesture(ET_GESTURE_BEGIN);
  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();

  EXPECT_TRUE(
      GesturesMatch(Gestures(ET_GESTURE_BEGIN, ET_GESTURE_SCROLL_BEGIN),
                    GetAndResetSentGestures()));

  PushGesture(ET_GESTURE_SCROLL_UPDATE);
  MoveTouchPoint(0, 2, 2);
  SendTouchConsumedAck();
  EXPECT_FALSE(GesturesSent());

  PushGesture(ET_SCROLL_FLING_START);
  PushGesture(ET_SCROLL_FLING_CANCEL);
  PushGesture(ET_GESTURE_END);
  ReleaseTouchPoint();
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SCROLL_END, ET_GESTURE_END),
                            GetAndResetSentGestures()));
  EXPECT_EQ(LastSentGestureLocation(), gfx::PointF(2, 2));

  PushGesture(ET_GESTURE_BEGIN);
  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_BEGIN, ET_GESTURE_SCROLL_BEGIN),
                            GetAndResetSentGestures()));
}

TEST_F(TouchDispositionGestureFilterTest, TapCancelledOnTouchCancel) {
  PushGesture(ET_GESTURE_TAP_DOWN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_TAP_DOWN),
                            GetAndResetSentGestures()));

  // A cancellation motion event should cancel the tap.
  CancelTouchPoint();
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_TAP_CANCEL),
                            GetAndResetSentGestures()));
  EXPECT_EQ(CurrentTouchTime(), LastSentGestureTime());
  EXPECT_EQ(LastSentGestureLocation(), gfx::PointF(1, 1));
}

// Test that a GestureEvent whose dispatch causes a cancel event to be fired
// won't cause a crash.
TEST_F(TouchDispositionGestureFilterTest, TestCancelMidGesture) {
  SetCancelAfterNextGesture(true);
  PushGesture(ET_GESTURE_TAP_DOWN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_TAP_DOWN,
                                     ET_GESTURE_TAP_CANCEL),
                            GetAndResetSentGestures()));
  EXPECT_EQ(LastSentGestureLocation(), gfx::PointF(1, 1));
}

// Test that a MultiFingerSwipe event is dispatched when appropriate.
TEST_F(TouchDispositionGestureFilterTest, TestAllowedMultiFingerSwipe) {
  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SCROLL_BEGIN),
                            GetAndResetSentGestures()));

  PushGesture(ET_GESTURE_PINCH_BEGIN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_PINCH_BEGIN),
                            GetAndResetSentGestures()));

  PushGesture(ET_GESTURE_SWIPE);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SWIPE),
                            GetAndResetSentGestures()));
}

  // Test that a MultiFingerSwipe event is dispatched when appropriate.
TEST_F(TouchDispositionGestureFilterTest, TestDisallowedMultiFingerSwipe) {
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();

  PushGesture(ET_GESTURE_SCROLL_BEGIN);
  MoveTouchPoint(0, 0, 0);
  SendTouchConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SCROLL_BEGIN),
                            GetAndResetSentGestures()));

  PushGesture(ET_GESTURE_PINCH_BEGIN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_PINCH_BEGIN),
                            GetAndResetSentGestures()));

  PushGesture(ET_GESTURE_SWIPE);
  PressTouchPoint(1, 1);
  SendTouchConsumedAck();
  EXPECT_FALSE(GesturesSent());
}

TEST_F(TouchDispositionGestureFilterTest, TapCancelOnSecondFingerDown) {
  PushGesture(ET_GESTURE_TAP_DOWN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_TAP_DOWN),
                            GetAndResetSentGestures()));

  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_TAP_CANCEL),
                            GetAndResetSentGestures()));
}

TEST_F(TouchDispositionGestureFilterTest, ShowPressBoundingBox) {
  PushGesture(ET_GESTURE_TAP_DOWN, 9, 9, 8);
  PressTouchPoint(9, 9);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(
      GesturesMatch(Gestures(ET_GESTURE_TAP_DOWN), GetAndResetSentGestures()));

  PushGesture(ET_GESTURE_TAP, 10, 10, 10);
  ReleaseTouchPoint();
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SHOW_PRESS, ET_GESTURE_TAP),
                            GetAndResetSentGestures()));
  EXPECT_EQ(gfx::RectF(5, 5, 10, 10), ShowPressBoundingBox());
}

TEST_F(TouchDispositionGestureFilterTest, TapCancelledBeforeGestureEnd) {
  PushGesture(ET_GESTURE_BEGIN);
  PushGesture(ET_GESTURE_TAP_DOWN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_BEGIN, ET_GESTURE_TAP_DOWN),
                            GetAndResetSentGestures()));
  SendTimeoutGesture(ET_GESTURE_SHOW_PRESS);
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_SHOW_PRESS),
                            GetAndResetSentGestures()));

  SendTimeoutGesture(ET_GESTURE_LONG_PRESS);
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_LONG_PRESS),
                            GetAndResetSentGestures()));
  PushGesture(ET_GESTURE_END);
  CancelTouchPoint();
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_TAP_CANCEL, ET_GESTURE_END),
                            GetAndResetSentGestures()));
}

TEST_F(TouchDispositionGestureFilterTest, EventFlagPropagation) {
  // Real gestures should propagate flags from their causal touches.
  PushGesture(ET_GESTURE_TAP_DOWN);
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(
      GesturesMatch(Gestures(ET_GESTURE_TAP_DOWN), GetAndResetSentGestures()));
  EXPECT_EQ(kDefaultEventFlags, LastSentGestureFlags());

  // Synthetic gestures lack flags.
  PressTouchPoint(1, 1);
  SendTouchNotConsumedAck();
  EXPECT_TRUE(GesturesMatch(Gestures(ET_GESTURE_TAP_CANCEL),
                            GetAndResetSentGestures()));
  EXPECT_EQ(0, LastSentGestureFlags());
}

}  // namespace ui
