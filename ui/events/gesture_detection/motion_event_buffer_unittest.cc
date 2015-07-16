// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/basictypes.h"
#include "base/logging.h"
#include "base/time/time.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/events/gesture_detection/motion_event_buffer.h"
#include "ui/events/test/mock_motion_event.h"

using base::TimeDelta;
using base::TimeTicks;
using ui::test::MockMotionEvent;

namespace ui {

const int kSmallDeltaMs = 1;
const int kLargeDeltaMs = 50;
const int kResampleDeltaMs = 5;
const float kVelocityEpsilon = 0.01f;
const float kDeltaEpsilon = 0.1f;

#define EXPECT_EVENT_EQ(A, B)         \
  {                                   \
    SCOPED_TRACE(testing::Message()); \
    ExpectEquals((A), (B));           \
  }
#define EXPECT_EVENT_IGNORING_HISTORY_EQ(A, B) \
  {                                            \
    SCOPED_TRACE(testing::Message());          \
    ExpectEqualsIgnoringHistory((A), (B));     \
  }
#define EXPECT_EVENT_HISTORY_EQ(A, I, B)     \
  {                                          \
    SCOPED_TRACE(testing::Message());        \
    ExpectEqualsHistoryIndex((A), (I), (B)); \
  }

class MotionEventBufferTest : public testing::Test,
                              public MotionEventBufferClient {
 public:
  MotionEventBufferTest() : needs_flush_(false) {}
  ~MotionEventBufferTest() override {}

  // MotionEventBufferClient implementation.
  void ForwardMotionEvent(const MotionEvent& event) override {
    forwarded_events_.push_back(event.Clone().release());
  }

  void SetNeedsFlush() override { needs_flush_ = true; }

  bool GetAndResetNeedsFlush() {
    bool needs_flush = needs_flush_;
    needs_flush_ = false;
    return needs_flush;
  }

  ScopedVector<MotionEvent> GetAndResetForwardedEvents() {
    ScopedVector<MotionEvent> forwarded_events;
    forwarded_events.swap(forwarded_events_);
    return forwarded_events.Pass();
  }

  const MotionEvent* GetLastEvent() const {
    return forwarded_events_.empty() ? NULL : forwarded_events_.back();
  }

  static base::TimeDelta LargeDelta() {
    return base::TimeDelta::FromMilliseconds(kLargeDeltaMs);
  }

  static base::TimeDelta SmallDelta() {
    return base::TimeDelta::FromMilliseconds(kSmallDeltaMs);
  }

  static base::TimeDelta ResampleDelta() {
    return base::TimeDelta::FromMilliseconds(kResampleDeltaMs);
  }

  static void ExpectEqualsImpl(const MotionEvent& a,
                               const MotionEvent& b,
                               bool ignore_history) {
    EXPECT_EQ(a.GetId(), b.GetId());
    EXPECT_EQ(a.GetAction(), b.GetAction());
    EXPECT_EQ(a.GetActionIndex(), b.GetActionIndex());
    EXPECT_EQ(a.GetButtonState(), b.GetButtonState());
    EXPECT_EQ(a.GetEventTime(), b.GetEventTime());

    ASSERT_EQ(a.GetPointerCount(), b.GetPointerCount());
    for (size_t i = 0; i < a.GetPointerCount(); ++i) {
      int bi = b.FindPointerIndexOfId(a.GetPointerId(i));
      ASSERT_NE(bi, -1);
      EXPECT_EQ(a.GetX(i), b.GetX(bi));
      EXPECT_EQ(a.GetY(i), b.GetY(bi));
      EXPECT_EQ(a.GetRawX(i), b.GetRawX(bi));
      EXPECT_EQ(a.GetRawY(i), b.GetRawY(bi));
      EXPECT_EQ(a.GetTouchMajor(i), b.GetTouchMajor(bi));
      EXPECT_EQ(a.GetTouchMinor(i), b.GetTouchMinor(bi));
      EXPECT_EQ(a.GetOrientation(i), b.GetOrientation(bi));
      EXPECT_EQ(a.GetPressure(i), b.GetPressure(bi));
      EXPECT_EQ(a.GetToolType(i), b.GetToolType(bi));
    }

    if (ignore_history)
      return;

    ASSERT_EQ(a.GetHistorySize(), b.GetHistorySize());
    for (size_t h = 0; h < a.GetHistorySize(); ++h)
      ExpectEqualsHistoryIndex(a, h, b);
  }

  // Verify that all public data of |a|, excluding history, equals that of |b|.
  static void ExpectEqualsIgnoringHistory(const MotionEvent& a,
                                          const MotionEvent& b) {
    const bool ignore_history = true;
    ExpectEqualsImpl(a, b, ignore_history);
  }

  // Verify that all public data of |a| equals that of |b|.
  static void ExpectEquals(const MotionEvent& a, const MotionEvent& b) {
    const bool ignore_history = false;
    ExpectEqualsImpl(a, b, ignore_history);
  }

  // Verify that the historical data of |a| given by |historical_index|
  // corresponds to the *raw* data of |b|.
  static void ExpectEqualsHistoryIndex(const MotionEvent& a,
                                       size_t history_index,
                                       const MotionEvent& b) {
    ASSERT_LT(history_index, a.GetHistorySize());
    EXPECT_EQ(a.GetPointerCount(), b.GetPointerCount());
    EXPECT_TRUE(a.GetHistoricalEventTime(history_index) == b.GetEventTime());

    for (size_t i = 0; i < a.GetPointerCount(); ++i) {
      int bi = b.FindPointerIndexOfId(a.GetPointerId(i));
      ASSERT_NE(bi, -1);
      EXPECT_EQ(a.GetHistoricalX(i, history_index), b.GetX(bi));
      EXPECT_EQ(a.GetHistoricalY(i, history_index), b.GetY(bi));
      EXPECT_EQ(a.GetHistoricalTouchMajor(i, history_index),
                b.GetTouchMajor(bi));
    }
  }

 protected:
  void RunResample(base::TimeDelta flush_time_delta,
                   base::TimeDelta event_time_delta) {
    for (base::TimeDelta offset; offset < event_time_delta;
         offset += event_time_delta / 3) {
      SCOPED_TRACE(testing::Message()
                   << "Resample(offset="
                   << static_cast<int>(offset.InMilliseconds()) << "ms)");
      RunResample(flush_time_delta, event_time_delta, offset);
    }
  }

  // Given an event and flush sampling frequency, inject a stream of events,
  // flushing at appropriate points in the stream. Verify that the continuous
  // velocity sampled by the *input* stream matches the discrete velocity
  // as computed from the resampled *output* stream.
  void RunResample(base::TimeDelta flush_time_delta,
                   base::TimeDelta event_time_delta,
                   base::TimeDelta event_time_offset) {
    base::TimeTicks event_time = base::TimeTicks::Now();
    base::TimeTicks flush_time =
        event_time + flush_time_delta - event_time_offset;
    base::TimeTicks max_event_time =
        event_time + base::TimeDelta::FromSecondsD(0.5f);
    const size_t min_expected_events =
        static_cast<size_t>((max_event_time - flush_time) /
                            std::max(event_time_delta, flush_time_delta));

    MotionEventBuffer buffer(this, true);

    gfx::Vector2dF velocity(33.f, -11.f);
    gfx::PointF position(17.f, 42.f);
    scoped_ptr<MotionEvent> last_flushed_event;
    size_t events = 0;
    float last_dx = 0, last_dy = 0;
    base::TimeDelta last_dt;
    while (event_time < max_event_time) {
      position += gfx::ScaleVector2d(velocity, event_time_delta.InSecondsF());
      MockMotionEvent move(
          MotionEvent::ACTION_MOVE, event_time, position.x(), position.y());
      buffer.OnMotionEvent(move);
      event_time += event_time_delta;

      while (flush_time < event_time) {
        buffer.Flush(flush_time);
        flush_time += flush_time_delta;
        const MotionEvent* current_flushed_event = GetLastEvent();
        if (current_flushed_event) {
          if (!last_flushed_event) {
            last_flushed_event = current_flushed_event->Clone();
            continue;
          }

          base::TimeDelta dt = current_flushed_event->GetEventTime() -
                               last_flushed_event->GetEventTime();
          EXPECT_GE(dt.ToInternalValue(), 0);
          // A time delta of 0 is possible if the flush rate is greater than the
          // event rate, in which case we can simply skip forward.
          if (dt == base::TimeDelta())
            continue;

          const float dx =
              current_flushed_event->GetX() - last_flushed_event->GetX();
          const float dy =
              current_flushed_event->GetY() - last_flushed_event->GetY();
          const float dt_s = (current_flushed_event->GetEventTime() -
                              last_flushed_event->GetEventTime()).InSecondsF();

          // The discrete velocity should mirror the constant velocity.
          EXPECT_NEAR(velocity.x(), dx / dt_s, kVelocityEpsilon);
          EXPECT_NEAR(velocity.y(), dy / dt_s, kVelocityEpsilon);

          // The impulse delta for each frame should remain constant.
          if (last_dy)
            EXPECT_NEAR(dx, last_dx, kDeltaEpsilon);
          if (last_dy)
            EXPECT_NEAR(dy, last_dy, kDeltaEpsilon);

          // The timestamp delta should remain constant.
          if (last_dt != base::TimeDelta())
            EXPECT_TRUE((dt - last_dt).InMillisecondsF() < kDeltaEpsilon);

          last_dx = dx;
          last_dy = dy;
          last_dt = dt;
          last_flushed_event = current_flushed_event->Clone();
          events += GetAndResetForwardedEvents().size();
        }
      }
    }
    events += GetAndResetForwardedEvents().size();
    EXPECT_GE(events, min_expected_events);
  }

 private:
  ScopedVector<MotionEvent> forwarded_events_;
  bool needs_flush_;
};

TEST_F(MotionEventBufferTest, BufferEmpty) {
  MotionEventBuffer buffer(this, true);

  buffer.Flush(base::TimeTicks::Now());
  EXPECT_FALSE(GetAndResetNeedsFlush());
  EXPECT_FALSE(GetLastEvent());
}

TEST_F(MotionEventBufferTest, BufferWithOneMoveNotResampled) {
  base::TimeTicks event_time = base::TimeTicks::Now();
  MotionEventBuffer buffer(this, true);

  MockMotionEvent move(MotionEvent::ACTION_MOVE, event_time, 4.f, 4.f);
  buffer.OnMotionEvent(move);
  EXPECT_TRUE(GetAndResetNeedsFlush());
  EXPECT_FALSE(GetLastEvent());

  buffer.Flush(event_time + ResampleDelta());
  EXPECT_FALSE(GetAndResetNeedsFlush());
  ASSERT_TRUE(GetLastEvent());
  EXPECT_EVENT_EQ(move, *GetLastEvent());
  EXPECT_EQ(1U, GetAndResetForwardedEvents().size());
}

TEST_F(MotionEventBufferTest, BufferFlushedOnNonActionMove) {
  base::TimeTicks event_time = base::TimeTicks::Now();
  MotionEventBuffer buffer(this, true);

  MockMotionEvent move0(MotionEvent::ACTION_MOVE, event_time, 1.f, 1.f);
  buffer.OnMotionEvent(move0);
  EXPECT_TRUE(GetAndResetNeedsFlush());
  EXPECT_FALSE(GetLastEvent());

  event_time += base::TimeDelta::FromMilliseconds(5);

  // The second move should remain buffered.
  MockMotionEvent move1(MotionEvent::ACTION_MOVE, event_time, 2.f, 2.f);
  buffer.OnMotionEvent(move1);
  EXPECT_FALSE(GetAndResetNeedsFlush());
  EXPECT_FALSE(GetLastEvent());

  // The third move should remain buffered.
  MockMotionEvent move2(MotionEvent::ACTION_MOVE, event_time, 3.f, 3.f);
  buffer.OnMotionEvent(move2);
  EXPECT_FALSE(GetAndResetNeedsFlush());
  EXPECT_FALSE(GetLastEvent());

  // The up should flush the buffer.
  MockMotionEvent up(MotionEvent::ACTION_UP, event_time, 4.f, 4.f);
  buffer.OnMotionEvent(up);
  EXPECT_FALSE(GetAndResetNeedsFlush());

  // The flushed events should include the up and the moves, with the latter
  // combined into a single event with history.
  ScopedVector<MotionEvent> events = GetAndResetForwardedEvents();
  ASSERT_EQ(2U, events.size());
  EXPECT_EVENT_EQ(up, *events.back());
  EXPECT_EQ(2U, events.front()->GetHistorySize());
  EXPECT_EVENT_IGNORING_HISTORY_EQ(*events.front(), move2);
  EXPECT_EVENT_HISTORY_EQ(*events.front(), 0, move0);
  EXPECT_EVENT_HISTORY_EQ(*events.front(), 1, move1);
}

TEST_F(MotionEventBufferTest, BufferFlushedOnIncompatibleActionMove) {
  base::TimeTicks event_time = base::TimeTicks::Now();
  MotionEventBuffer buffer(this, true);

  MockMotionEvent move0(MotionEvent::ACTION_MOVE, event_time, 1.f, 1.f);
  buffer.OnMotionEvent(move0);
  EXPECT_TRUE(GetAndResetNeedsFlush());
  EXPECT_FALSE(GetLastEvent());

  event_time += base::TimeDelta::FromMilliseconds(5);

  // The second move has a different pointer count, flushing the first.
  MockMotionEvent move1(
      MotionEvent::ACTION_MOVE, event_time, 2.f, 2.f, 3.f, 3.f);
  buffer.OnMotionEvent(move1);
  EXPECT_FALSE(GetAndResetNeedsFlush());
  ASSERT_TRUE(GetLastEvent());
  EXPECT_EVENT_EQ(move0, *GetLastEvent());

  event_time += base::TimeDelta::FromMilliseconds(5);

  // The third move has differing tool types, flushing the second.
  MockMotionEvent move2(move1);
  move2.SetToolType(0, MotionEvent::TOOL_TYPE_STYLUS);
  buffer.OnMotionEvent(move2);
  EXPECT_FALSE(GetAndResetNeedsFlush());
  EXPECT_EVENT_EQ(move1, *GetLastEvent());

  event_time += base::TimeDelta::FromMilliseconds(5);

  // The flushed event should only include the latest move event.
  buffer.Flush(event_time);
  ScopedVector<MotionEvent> events = GetAndResetForwardedEvents();
  ASSERT_EQ(3U, events.size());
  EXPECT_EVENT_EQ(move2, *events.back());
  EXPECT_FALSE(GetAndResetNeedsFlush());

  event_time += base::TimeDelta::FromMilliseconds(5);

  // Events with different pointer ids should not combine.
  PointerProperties pointer0(5.f, 5.f);
  pointer0.id = 1;
  PointerProperties pointer1(10.f, 10.f);
  pointer1.id = 2;
  MotionEventGeneric move3(MotionEvent::ACTION_MOVE, event_time, pointer0);
  move3.PushPointer(pointer1);
  buffer.OnMotionEvent(move3);
  ASSERT_FALSE(GetLastEvent());
  EXPECT_TRUE(GetAndResetNeedsFlush());

  MotionEventGeneric move4(MotionEvent::ACTION_MOVE, event_time, pointer0);
  pointer1.id = 7;
  move4.PushPointer(pointer1);
  buffer.OnMotionEvent(move2);
  EXPECT_FALSE(GetAndResetNeedsFlush());
  ASSERT_TRUE(GetLastEvent());
  EXPECT_EVENT_EQ(move3, *GetLastEvent());
}

TEST_F(MotionEventBufferTest, OnlyActionMoveBuffered) {
  base::TimeTicks event_time = base::TimeTicks::Now();
  MotionEventBuffer buffer(this, true);

  MockMotionEvent down(MotionEvent::ACTION_DOWN, event_time, 1.f, 1.f);
  buffer.OnMotionEvent(down);
  EXPECT_FALSE(GetAndResetNeedsFlush());
  ASSERT_TRUE(GetLastEvent());
  EXPECT_EVENT_EQ(down, *GetLastEvent());

  GetAndResetForwardedEvents();

  MockMotionEvent up(MotionEvent::ACTION_UP, event_time, 2.f, 2.f);
  buffer.OnMotionEvent(up);
  EXPECT_FALSE(GetAndResetNeedsFlush());
  ASSERT_TRUE(GetLastEvent());
  EXPECT_EVENT_EQ(up, *GetLastEvent());

  GetAndResetForwardedEvents();

  MockMotionEvent cancel(MotionEvent::ACTION_CANCEL, event_time, 3.f, 3.f);
  buffer.OnMotionEvent(cancel);
  EXPECT_FALSE(GetAndResetNeedsFlush());
  ASSERT_TRUE(GetLastEvent());
  EXPECT_EVENT_EQ(cancel, *GetLastEvent());

  GetAndResetForwardedEvents();

  MockMotionEvent move(MotionEvent::ACTION_MOVE, event_time, 4.f, 4.f);
  buffer.OnMotionEvent(move);
  EXPECT_TRUE(GetAndResetNeedsFlush());
  EXPECT_FALSE(GetLastEvent());

  base::TimeTicks flush_time = move.GetEventTime() + ResampleDelta();
  buffer.Flush(flush_time);
  EXPECT_FALSE(GetAndResetNeedsFlush());
  ASSERT_TRUE(GetLastEvent());
  EXPECT_EVENT_EQ(move, *GetLastEvent());
}

TEST_F(MotionEventBufferTest, OutOfOrderPointersBuffered) {
  base::TimeTicks event_time = base::TimeTicks::Now();
  MotionEventBuffer buffer(this, true);

  PointerProperties p0(1.f, 2.f);
  p0.id = 1;
  PointerProperties p1(2.f, 1.f);
  p1.id = 2;

  MotionEventGeneric move0(MotionEvent::ACTION_MOVE, event_time, p0);
  move0.PushPointer(p1);
  buffer.OnMotionEvent(move0);
  EXPECT_TRUE(GetAndResetNeedsFlush());
  ASSERT_FALSE(GetLastEvent());

  event_time += base::TimeDelta::FromMilliseconds(5);

  // The second move should remain buffered even if the logical pointers are
  // in a different order.
  MotionEventGeneric move1(MotionEvent::ACTION_MOVE, event_time, p1);
  move1.PushPointer(p0);
  buffer.OnMotionEvent(move1);
  EXPECT_FALSE(GetAndResetNeedsFlush());
  ASSERT_FALSE(GetLastEvent());

  // As the two events are logically the same but for ordering and time, the
  // synthesized event should yield a logically identical event.
  base::TimeTicks flush_time = move1.GetEventTime() + ResampleDelta();
  buffer.Flush(flush_time);
  EXPECT_FALSE(GetAndResetNeedsFlush());
  ASSERT_TRUE(GetLastEvent());
  ScopedVector<MotionEvent> events = GetAndResetForwardedEvents();
  ASSERT_EQ(1U, events.size());
  EXPECT_EVENT_IGNORING_HISTORY_EQ(move1, *events.front());
  EXPECT_EVENT_HISTORY_EQ(*events.front(), 0, move0);
}

TEST_F(MotionEventBufferTest, FlushedEventsNeverLaterThanFlushTime) {
  base::TimeTicks event_time = base::TimeTicks::Now();
  MotionEventBuffer buffer(this, true);

  MockMotionEvent move0(MotionEvent::ACTION_MOVE, event_time, 1.f, 1.f);
  buffer.OnMotionEvent(move0);
  ASSERT_FALSE(GetLastEvent());
  EXPECT_TRUE(GetAndResetNeedsFlush());

  // The second move should remain buffered.
  event_time += LargeDelta();
  MockMotionEvent move1(MotionEvent::ACTION_MOVE, event_time, 2.f, 2.f);
  buffer.OnMotionEvent(move1);
  ASSERT_FALSE(GetLastEvent());
  EXPECT_FALSE(GetAndResetNeedsFlush());

  // A flush occurring too early should not forward any events.
  base::TimeTicks flush_time = move0.GetEventTime() - ResampleDelta();
  buffer.Flush(flush_time);
  ASSERT_FALSE(GetLastEvent());
  EXPECT_TRUE(GetAndResetNeedsFlush());

  // With resampling enabled, a flush occurring before the resample
  // offset should not forward any events.
  flush_time = move0.GetEventTime();
  buffer.Flush(flush_time);
  ASSERT_FALSE(GetLastEvent());
  EXPECT_TRUE(GetAndResetNeedsFlush());

  // Only the first event should get flushed, as the flush timestamp precedes
  // the second's timestamp by a sufficient amount (preventing interpolation).
  flush_time = move0.GetEventTime() + ResampleDelta();
  buffer.Flush(flush_time);

  // There should only be one flushed event.
  EXPECT_TRUE(GetAndResetNeedsFlush());
  ASSERT_TRUE(GetLastEvent());
  EXPECT_TRUE(GetLastEvent()->GetEventTime() <= flush_time);
  GetAndResetForwardedEvents();

  // Flushing again with a similar timestamp should have no effect other than
  // triggering another flush request.
  flush_time += base::TimeDelta::FromMilliseconds(1);
  buffer.Flush(flush_time);
  EXPECT_FALSE(GetLastEvent());
  EXPECT_TRUE(GetAndResetNeedsFlush());

  // Flushing after the second move's time should trigger forwarding.
  flush_time = move1.GetEventTime() + ResampleDelta();
  buffer.Flush(flush_time);
  ASSERT_TRUE(GetLastEvent());
  EXPECT_EVENT_EQ(move1, *GetLastEvent());
  EXPECT_FALSE(GetAndResetNeedsFlush());
}

TEST_F(MotionEventBufferTest, NoResamplingWhenDisabled) {
  base::TimeTicks event_time = base::TimeTicks::Now();
  const bool resampling_enabled = false;
  MotionEventBuffer buffer(this, resampling_enabled);

  // Queue two events.
  MockMotionEvent move0(MotionEvent::ACTION_MOVE, event_time, 5.f, 10.f);
  buffer.OnMotionEvent(move0);
  ASSERT_FALSE(GetLastEvent());
  EXPECT_TRUE(GetAndResetNeedsFlush());

  event_time += base::TimeDelta::FromMilliseconds(5);
  MockMotionEvent move1(MotionEvent::ACTION_MOVE, event_time, 15.f, 30.f);
  buffer.OnMotionEvent(move1);
  ASSERT_FALSE(GetLastEvent());
  EXPECT_FALSE(GetAndResetNeedsFlush());

  // Flush at a time between the first and second events.
  base::TimeTicks interpolated_time =
      move0.GetEventTime() + (move1.GetEventTime() - move0.GetEventTime()) / 2;
  base::TimeTicks flush_time = interpolated_time;
  buffer.Flush(flush_time);
  ASSERT_TRUE(GetLastEvent());
  EXPECT_TRUE(GetAndResetNeedsFlush());

  // There should only be one flushed event, with the second remaining buffered
  // and no resampling having occurred.
  ScopedVector<MotionEvent> events = GetAndResetForwardedEvents();
  ASSERT_EQ(1U, events.size());
  EXPECT_EVENT_EQ(move0, *events.front());

  // The second move should be flushed without resampling.
  flush_time = move1.GetEventTime();
  buffer.Flush(flush_time);
  ASSERT_TRUE(GetLastEvent());
  EXPECT_EVENT_EQ(move1, *GetLastEvent());
  GetAndResetForwardedEvents();

  // Now queue two more events.
  move0 = MockMotionEvent(MotionEvent::ACTION_MOVE, event_time, 5.f, 10.f);
  buffer.OnMotionEvent(move0);
  ASSERT_FALSE(GetLastEvent());
  EXPECT_TRUE(GetAndResetNeedsFlush());

  // The second move should remain buffered.
  event_time += base::TimeDelta::FromMilliseconds(5);
  move1 = MockMotionEvent(MotionEvent::ACTION_MOVE, event_time, 10.f, 20.f);
  buffer.OnMotionEvent(move1);
  ASSERT_FALSE(GetLastEvent());
  EXPECT_FALSE(GetAndResetNeedsFlush());

  // Sample at a time beyond the first and second events.
  flush_time =
      move1.GetEventTime() + (move1.GetEventTime() - move0.GetEventTime());
  buffer.Flush(flush_time);
  ASSERT_TRUE(GetLastEvent());
  EXPECT_FALSE(GetAndResetNeedsFlush());

  // There should only be one flushed event, with the first event in the history
  // and the second event as the actual event data (no resampling).
  events = GetAndResetForwardedEvents();
  ASSERT_EQ(1U, events.size());
  EXPECT_EQ(1U, events.front()->GetHistorySize());
  EXPECT_EVENT_IGNORING_HISTORY_EQ(*events.front(), move1);
  EXPECT_EVENT_HISTORY_EQ(*events.front(), 0, move0);
}

TEST_F(MotionEventBufferTest, NoResamplingWithOutOfOrderActionMove) {
  base::TimeTicks event_time = base::TimeTicks::Now();
  MotionEventBuffer buffer(this, true);

  MockMotionEvent move0(MotionEvent::ACTION_MOVE, event_time, 5.f, 10.f);
  buffer.OnMotionEvent(move0);
  ASSERT_FALSE(GetLastEvent());
  EXPECT_TRUE(GetAndResetNeedsFlush());

  // The second move should remain buffered.
  event_time += base::TimeDelta::FromMilliseconds(10);
  MockMotionEvent move1(MotionEvent::ACTION_MOVE, event_time, 10.f, 20.f);
  buffer.OnMotionEvent(move1);
  ASSERT_FALSE(GetLastEvent());
  EXPECT_FALSE(GetAndResetNeedsFlush());

  // Sample at a time beyond the first and second events.
  base::TimeTicks extrapolated_time =
      move1.GetEventTime() + (move1.GetEventTime() - move0.GetEventTime());
  base::TimeTicks flush_time = extrapolated_time + ResampleDelta();
  buffer.Flush(flush_time);
  ASSERT_TRUE(GetLastEvent());
  EXPECT_FALSE(GetAndResetNeedsFlush());

  // There should only be one flushed event, with the event extrapolated from
  // the two events.
  base::TimeTicks expected_time =
      move1.GetEventTime() + (move1.GetEventTime() - move0.GetEventTime()) / 2;
  ScopedVector<MotionEvent> events0 = GetAndResetForwardedEvents();
  ASSERT_EQ(1U, events0.size());
  EXPECT_EQ(2U, events0.front()->GetHistorySize());
  EXPECT_EQ(expected_time, events0.front()->GetEventTime());
  EXPECT_FALSE(GetAndResetNeedsFlush());

  // Try enqueuing an event *after* the second event but *before* the
  // extrapolated event. It should be dropped.
  event_time = move1.GetEventTime() + base::TimeDelta::FromMilliseconds(1);
  MockMotionEvent move2(MotionEvent::ACTION_MOVE, event_time, 15.f, 25.f);
  buffer.OnMotionEvent(move1);
  ASSERT_FALSE(GetLastEvent());
  EXPECT_FALSE(GetAndResetNeedsFlush());

  // Finally queue an event *after* the extrapolated event.
  event_time = expected_time + base::TimeDelta::FromMilliseconds(1);
  MockMotionEvent move3(MotionEvent::ACTION_MOVE, event_time, 15.f, 25.f);
  buffer.OnMotionEvent(move3);
  ASSERT_FALSE(GetLastEvent());
  EXPECT_TRUE(GetAndResetNeedsFlush());

  // The flushed event should simply be the latest event.
  flush_time = event_time + ResampleDelta();
  buffer.Flush(flush_time);
  ASSERT_TRUE(GetLastEvent());
  ScopedVector<MotionEvent> events1 = GetAndResetForwardedEvents();
  ASSERT_EQ(1U, events1.size());
  EXPECT_EVENT_EQ(move3, *events1.front());
  EXPECT_FALSE(GetAndResetNeedsFlush());
}

TEST_F(MotionEventBufferTest, NoResamplingWithSmallTimeDeltaBetweenMoves) {
  base::TimeTicks event_time = base::TimeTicks::Now();
  MotionEventBuffer buffer(this, true);

  // The first move should be buffered.
  MockMotionEvent move0(MotionEvent::ACTION_MOVE, event_time, 1.f, 1.f);
  buffer.OnMotionEvent(move0);
  ASSERT_FALSE(GetLastEvent());
  EXPECT_TRUE(GetAndResetNeedsFlush());

  // The second move should remain buffered.
  event_time += SmallDelta();
  MockMotionEvent move1(MotionEvent::ACTION_MOVE, event_time, 2.f, 2.f);
  buffer.OnMotionEvent(move1);
  ASSERT_FALSE(GetLastEvent());
  EXPECT_FALSE(GetAndResetNeedsFlush());

  base::TimeTicks flush_time = event_time + ResampleDelta();
  buffer.Flush(flush_time);
  EXPECT_FALSE(GetAndResetNeedsFlush());

  // There should only be one flushed event, and no resampling should have
  // occured between the first and the second as they were temporally too close.
  ScopedVector<MotionEvent> events = GetAndResetForwardedEvents();
  ASSERT_EQ(1U, events.size());
  EXPECT_EQ(1U, events.front()->GetHistorySize());
  EXPECT_EVENT_IGNORING_HISTORY_EQ(*events.front(), move1);
  EXPECT_EVENT_HISTORY_EQ(*events.front(), 0, move0);
}

TEST_F(MotionEventBufferTest, NoResamplingWithMismatchBetweenMoves) {
  base::TimeTicks event_time = base::TimeTicks::Now();
  MotionEventBuffer buffer(this, true);

  // The first move should be buffered.
  MockMotionEvent move0(MotionEvent::ACTION_MOVE, event_time, 1.f, 1.f);
  buffer.OnMotionEvent(move0);
  ASSERT_FALSE(GetLastEvent());
  EXPECT_TRUE(GetAndResetNeedsFlush());

  // The second move should remain buffered.
  event_time += SmallDelta();
  MockMotionEvent move1(MotionEvent::ACTION_MOVE, event_time, 2.f, 2.f);
  buffer.OnMotionEvent(move1);
  ASSERT_FALSE(GetLastEvent());
  EXPECT_FALSE(GetAndResetNeedsFlush());

  base::TimeTicks flush_time = event_time + ResampleDelta();
  buffer.Flush(flush_time);
  EXPECT_FALSE(GetAndResetNeedsFlush());

  // There should only be one flushed event, and no resampling should have
  // occured between the first and the second as they were temporally too close.
  ScopedVector<MotionEvent> events = GetAndResetForwardedEvents();
  ASSERT_EQ(1U, events.size());
  EXPECT_EQ(1U, events.front()->GetHistorySize());
  EXPECT_EVENT_IGNORING_HISTORY_EQ(*events.front(), move1);
  EXPECT_EVENT_HISTORY_EQ(*events.front(), 0, move0);
}

TEST_F(MotionEventBufferTest, Interpolation) {
  base::TimeTicks event_time = base::TimeTicks::Now();
  MotionEventBuffer buffer(this, true);

  MockMotionEvent move0(MotionEvent::ACTION_MOVE, event_time, 5.f, 10.f);
  buffer.OnMotionEvent(move0);
  ASSERT_FALSE(GetLastEvent());
  EXPECT_TRUE(GetAndResetNeedsFlush());

  // The second move should remain buffered.
  event_time += base::TimeDelta::FromMilliseconds(5);
  MockMotionEvent move1(MotionEvent::ACTION_MOVE, event_time, 15.f, 30.f);
  buffer.OnMotionEvent(move1);
  ASSERT_FALSE(GetLastEvent());
  EXPECT_FALSE(GetAndResetNeedsFlush());

  // Sample at a time between the first and second events.
  base::TimeTicks interpolated_time =
      move0.GetEventTime() + (move1.GetEventTime() - move0.GetEventTime()) / 3;
  base::TimeTicks flush_time = interpolated_time + ResampleDelta();
  buffer.Flush(flush_time);
  ASSERT_TRUE(GetLastEvent());
  EXPECT_TRUE(GetAndResetNeedsFlush());

  // There should only be one flushed event, with the event interpolated between
  // the two events. The second event should remain buffered.
  float alpha = (interpolated_time - move0.GetEventTime()).InMillisecondsF() /
                (move1.GetEventTime() - move0.GetEventTime()).InMillisecondsF();
  MockMotionEvent interpolated_event(
      MotionEvent::ACTION_MOVE,
      interpolated_time,
      move0.GetX(0) + (move1.GetX(0) - move0.GetX(0)) * alpha,
      move0.GetY(0) + (move1.GetY(0) - move0.GetY(0)) * alpha);
  ScopedVector<MotionEvent> events = GetAndResetForwardedEvents();
  ASSERT_EQ(1U, events.size());
  EXPECT_EQ(1U, events.front()->GetHistorySize());
  EXPECT_EVENT_IGNORING_HISTORY_EQ(*events.front(), interpolated_event);
  EXPECT_EVENT_HISTORY_EQ(*events.front(), 0, move0);

  // The second move should be flushed without resampling.
  flush_time = move1.GetEventTime() + ResampleDelta();
  buffer.Flush(flush_time);
  ASSERT_TRUE(GetLastEvent());
  EXPECT_EVENT_EQ(move1, *GetLastEvent());
}

TEST_F(MotionEventBufferTest, Extrapolation) {
  base::TimeTicks event_time = base::TimeTicks::Now();
  MotionEventBuffer buffer(this, true);

  MockMotionEvent move0(MotionEvent::ACTION_MOVE, event_time, 5.f, 10.f);
  buffer.OnMotionEvent(move0);
  ASSERT_FALSE(GetLastEvent());
  EXPECT_TRUE(GetAndResetNeedsFlush());

  // The second move should remain buffered.
  event_time += base::TimeDelta::FromMilliseconds(5);
  MockMotionEvent move1(MotionEvent::ACTION_MOVE, event_time, 10.f, 20.f);
  buffer.OnMotionEvent(move1);
  ASSERT_FALSE(GetLastEvent());
  EXPECT_FALSE(GetAndResetNeedsFlush());

  // Sample at a time beyond the first and second events.
  base::TimeTicks extrapolated_time =
      move1.GetEventTime() + (move1.GetEventTime() - move0.GetEventTime());
  base::TimeTicks flush_time = extrapolated_time + ResampleDelta();
  buffer.Flush(flush_time);
  ASSERT_TRUE(GetLastEvent());
  EXPECT_FALSE(GetAndResetNeedsFlush());

  // There should only be one flushed event, with the event extrapolated from
  // the two events. The first and second events should be in the history.
  // Note that the maximum extrapolation is limited by *half* of the time delta
  // between the two events, hence we divide the relative delta by 2 in
  // determining the extrapolated event.
  base::TimeTicks expected_time =
      move1.GetEventTime() + (move1.GetEventTime() - move0.GetEventTime()) / 2;
  float expected_alpha =
      (expected_time - move0.GetEventTime()).InMillisecondsF() /
      (move1.GetEventTime() - move0.GetEventTime()).InMillisecondsF();
  MockMotionEvent extrapolated_event(
      MotionEvent::ACTION_MOVE,
      expected_time,
      move0.GetX(0) + (move1.GetX(0) - move0.GetX(0)) * expected_alpha,
      move0.GetY(0) + (move1.GetY(0) - move0.GetY(0)) * expected_alpha);
  ScopedVector<MotionEvent> events = GetAndResetForwardedEvents();
  ASSERT_EQ(1U, events.size());
  EXPECT_EQ(2U, events.front()->GetHistorySize());
  EXPECT_EVENT_IGNORING_HISTORY_EQ(*events.front(), extrapolated_event);
  EXPECT_EVENT_HISTORY_EQ(*events.front(), 0, move0);
  EXPECT_EVENT_HISTORY_EQ(*events.front(), 1, move1);
}

TEST_F(MotionEventBufferTest, ExtrapolationHorizonLimited) {
  base::TimeTicks event_time = base::TimeTicks::Now();
  MotionEventBuffer buffer(this, true);

  MockMotionEvent move0(MotionEvent::ACTION_MOVE, event_time, 5.f, 10.f);
  buffer.OnMotionEvent(move0);
  ASSERT_FALSE(GetLastEvent());
  EXPECT_TRUE(GetAndResetNeedsFlush());

  // The second move should remain buffered.
  event_time += base::TimeDelta::FromMilliseconds(24);
  MockMotionEvent move1(MotionEvent::ACTION_MOVE, event_time, 10.f, 20.f);
  buffer.OnMotionEvent(move1);
  ASSERT_FALSE(GetLastEvent());
  EXPECT_FALSE(GetAndResetNeedsFlush());

  // Sample at a time beyond the first and second events.
  base::TimeTicks extrapolated_time =
      event_time + base::TimeDelta::FromMilliseconds(24);
  base::TimeTicks flush_time = extrapolated_time + ResampleDelta();
  buffer.Flush(flush_time);
  ASSERT_TRUE(GetLastEvent());
  EXPECT_FALSE(GetAndResetNeedsFlush());

  // There should only be one flushed event, with the event extrapolated from
  // the two events. The first and second events should be in the history.
  // Note that the maximum extrapolation is limited by 8 ms.
  base::TimeTicks expected_time =
      move1.GetEventTime() + base::TimeDelta::FromMilliseconds(8);
  float expected_alpha =
      (expected_time - move0.GetEventTime()).InMillisecondsF() /
      (move1.GetEventTime() - move0.GetEventTime()).InMillisecondsF();
  MockMotionEvent extrapolated_event(
      MotionEvent::ACTION_MOVE,
      expected_time,
      move0.GetX(0) + (move1.GetX(0) - move0.GetX(0)) * expected_alpha,
      move0.GetY(0) + (move1.GetY(0) - move0.GetY(0)) * expected_alpha);
  ScopedVector<MotionEvent> events = GetAndResetForwardedEvents();
  ASSERT_EQ(1U, events.size());
  EXPECT_EQ(2U, events.front()->GetHistorySize());
  EXPECT_EVENT_IGNORING_HISTORY_EQ(*events.front(), extrapolated_event);
  EXPECT_EVENT_HISTORY_EQ(*events.front(), 0, move0);
  EXPECT_EVENT_HISTORY_EQ(*events.front(), 1, move1);
}

TEST_F(MotionEventBufferTest, ResamplingWithReorderedPointers) {

}

TEST_F(MotionEventBufferTest, Resampling30to60) {
  base::TimeDelta flush_time_delta =
      base::TimeDelta::FromMillisecondsD(1000. / 60.);
  base::TimeDelta event_time_delta =
      base::TimeDelta::FromMillisecondsD(1000. / 30.);

  RunResample(flush_time_delta, event_time_delta);
}

TEST_F(MotionEventBufferTest, Resampling60to60) {
  base::TimeDelta flush_time_delta =
      base::TimeDelta::FromMillisecondsD(1000. / 60.);
  base::TimeDelta event_time_delta =
      base::TimeDelta::FromMillisecondsD(1000. / 60.);

  RunResample(flush_time_delta, event_time_delta);
}

TEST_F(MotionEventBufferTest, Resampling100to60) {
  base::TimeDelta flush_time_delta =
      base::TimeDelta::FromMillisecondsD(1000. / 60.);
  base::TimeDelta event_time_delta =
      base::TimeDelta::FromMillisecondsD(1000. / 100.);

  RunResample(flush_time_delta, event_time_delta);
}

TEST_F(MotionEventBufferTest, Resampling120to60) {
  base::TimeDelta flush_time_delta =
      base::TimeDelta::FromMillisecondsD(1000. / 60.);
  base::TimeDelta event_time_delta =
      base::TimeDelta::FromMillisecondsD(1000. / 120.);

  RunResample(flush_time_delta, event_time_delta);
}

TEST_F(MotionEventBufferTest, Resampling150to60) {
  base::TimeDelta flush_time_delta =
      base::TimeDelta::FromMillisecondsD(1000. / 60.);
  base::TimeDelta event_time_delta =
      base::TimeDelta::FromMillisecondsD(1000. / 150.);

  RunResample(flush_time_delta, event_time_delta);
}

}  // namespace ui
