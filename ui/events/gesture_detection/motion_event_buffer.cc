// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/gesture_detection/motion_event_buffer.h"

#include "base/trace_event/trace_event.h"
#include "ui/events/gesture_detection/motion_event.h"
#include "ui/events/gesture_detection/motion_event_generic.h"

namespace ui {
namespace {

// Latency added during resampling. A few milliseconds doesn't hurt much but
// reduces the impact of mispredicted touch positions.
const int kResampleLatencyMs = 5;

// Minimum time difference between consecutive samples before attempting to
// resample.
const int kResampleMinDeltaMs = 2;

// Maximum time to predict forward from the last known state, to avoid
// predicting too far into the future.  This time is further bounded by 50% of
// the last time delta.
const int kResampleMaxPredictionMs = 8;

typedef ScopedVector<MotionEvent> MotionEventVector;

float Lerp(float a, float b, float alpha) {
  return a + alpha * (b - a);
}

bool CanAddSample(const MotionEvent& event0, const MotionEvent& event1) {
  DCHECK_EQ(event0.GetAction(), MotionEvent::ACTION_MOVE);
  if (event1.GetAction() != MotionEvent::ACTION_MOVE)
    return false;

  const size_t pointer_count = event0.GetPointerCount();
  if (pointer_count != event1.GetPointerCount())
    return false;

  for (size_t event0_i = 0; event0_i < pointer_count; ++event0_i) {
    const int id = event0.GetPointerId(event0_i);
    const int event1_i = event1.FindPointerIndexOfId(id);
    if (event1_i == -1)
      return false;
    if (event0.GetToolType(event0_i) != event1.GetToolType(event1_i))
      return false;
  }

  return true;
}

bool ShouldResampleTool(MotionEvent::ToolType tool) {
  return tool == MotionEvent::TOOL_TYPE_UNKNOWN ||
         tool == MotionEvent::TOOL_TYPE_FINGER;
}

size_t CountSamplesNoLaterThan(const MotionEventVector& batch,
                               base::TimeTicks time) {
  size_t count = 0;
  while (count < batch.size() && batch[count]->GetEventTime() <= time)
    ++count;
  return count;
}

MotionEventVector ConsumeSamplesNoLaterThan(MotionEventVector* batch,
                                            base::TimeTicks time) {
  DCHECK(batch);
  size_t count = CountSamplesNoLaterThan(*batch, time);
  DCHECK_GE(batch->size(), count);
  if (count == 0)
    return MotionEventVector();

  if (count == batch->size())
    return batch->Pass();

  // TODO(jdduke): Use a ScopedDeque to work around this mess.
  MotionEventVector unconsumed_batch;
  unconsumed_batch.insert(
      unconsumed_batch.begin(), batch->begin() + count, batch->end());
  batch->weak_erase(batch->begin() + count, batch->end());

  unconsumed_batch.swap(*batch);
  DCHECK_GE(unconsumed_batch.size(), 1U);
  return unconsumed_batch.Pass();
}

PointerProperties PointerFromMotionEvent(const MotionEvent& event,
                                         size_t pointer_index) {
  PointerProperties result;
  result.id = event.GetPointerId(pointer_index);
  result.tool_type = event.GetToolType(pointer_index);
  result.x = event.GetX(pointer_index);
  result.y = event.GetY(pointer_index);
  result.raw_x = event.GetRawX(pointer_index);
  result.raw_y = event.GetRawY(pointer_index);
  result.pressure = event.GetPressure(pointer_index);
  result.touch_major = event.GetTouchMajor(pointer_index);
  result.touch_minor = event.GetTouchMinor(pointer_index);
  result.orientation = event.GetOrientation(pointer_index);
  return result;
}

PointerProperties ResamplePointer(const MotionEvent& event0,
                                  const MotionEvent& event1,
                                  size_t event0_pointer_index,
                                  size_t event1_pointer_index,
                                  float alpha) {
  DCHECK_EQ(event0.GetPointerId(event0_pointer_index),
            event1.GetPointerId(event1_pointer_index));
  // If the tool should not be resampled, use the latest event in the valid
  // horizon (i.e., the event no later than the time interpolated by alpha).
  if (!ShouldResampleTool(event0.GetToolType(event0_pointer_index))) {
    if (alpha > 1)
      return PointerFromMotionEvent(event1, event1_pointer_index);
    else
      return PointerFromMotionEvent(event0, event0_pointer_index);
  }

  PointerProperties p(PointerFromMotionEvent(event0, event0_pointer_index));
  p.x = Lerp(p.x, event1.GetX(event1_pointer_index), alpha);
  p.y = Lerp(p.y, event1.GetY(event1_pointer_index), alpha);
  p.raw_x = Lerp(p.raw_x, event1.GetRawX(event1_pointer_index), alpha);
  p.raw_y = Lerp(p.raw_y, event1.GetRawY(event1_pointer_index), alpha);
  return p;
}

scoped_ptr<MotionEvent> ResampleMotionEvent(const MotionEvent& event0,
                                            const MotionEvent& event1,
                                            base::TimeTicks resample_time) {
  DCHECK_EQ(MotionEvent::ACTION_MOVE, event0.GetAction());
  DCHECK_EQ(event0.GetPointerCount(), event1.GetPointerCount());

  const base::TimeTicks time0 = event0.GetEventTime();
  const base::TimeTicks time1 = event1.GetEventTime();
  DCHECK(time0 < time1);
  DCHECK(time0 <= resample_time);

  const float alpha = (resample_time - time0).InMillisecondsF() /
                      (time1 - time0).InMillisecondsF();

  scoped_ptr<MotionEventGeneric> event;
  const size_t pointer_count = event0.GetPointerCount();
  DCHECK_EQ(pointer_count, event1.GetPointerCount());
  for (size_t event0_i = 0; event0_i < pointer_count; ++event0_i) {
    int event1_i = event1.FindPointerIndexOfId(event0.GetPointerId(event0_i));
    DCHECK_NE(event1_i, -1);
    PointerProperties pointer = ResamplePointer(
        event0, event1, event0_i, static_cast<size_t>(event1_i), alpha);

    if (event0_i == 0) {
      event.reset(new MotionEventGeneric(
          MotionEvent::ACTION_MOVE, resample_time, pointer));
    } else {
      event->PushPointer(pointer);
    }
  }

  DCHECK(event);
  event->set_id(event0.GetId());
  event->set_action_index(event0.GetActionIndex());
  event->set_button_state(event0.GetButtonState());

  return event.Pass();
}

// MotionEvent implementation for storing multiple events, with the most
// recent event used as the base event, and prior events used as the history.
class CompoundMotionEvent : public ui::MotionEvent {
 public:
  explicit CompoundMotionEvent(MotionEventVector events)
      : events_(events.Pass()) {
    DCHECK_GE(events_.size(), 1U);
  }
  ~CompoundMotionEvent() override {}

  int GetId() const override { return latest().GetId(); }

  Action GetAction() const override { return latest().GetAction(); }

  int GetActionIndex() const override { return latest().GetActionIndex(); }

  size_t GetPointerCount() const override { return latest().GetPointerCount(); }

  int GetPointerId(size_t pointer_index) const override {
    return latest().GetPointerId(pointer_index);
  }

  float GetX(size_t pointer_index) const override {
    return latest().GetX(pointer_index);
  }

  float GetY(size_t pointer_index) const override {
    return latest().GetY(pointer_index);
  }

  float GetRawX(size_t pointer_index) const override {
    return latest().GetRawX(pointer_index);
  }

  float GetRawY(size_t pointer_index) const override {
    return latest().GetRawY(pointer_index);
  }

  float GetTouchMajor(size_t pointer_index) const override {
    return latest().GetTouchMajor(pointer_index);
  }

  float GetTouchMinor(size_t pointer_index) const override {
    return latest().GetTouchMinor(pointer_index);
  }

  float GetOrientation(size_t pointer_index) const override {
    return latest().GetOrientation(pointer_index);
  }

  float GetPressure(size_t pointer_index) const override {
    return latest().GetPressure(pointer_index);
  }

  ToolType GetToolType(size_t pointer_index) const override {
    return latest().GetToolType(pointer_index);
  }

  int GetButtonState() const override { return latest().GetButtonState(); }

  int GetFlags() const override { return latest().GetFlags(); }

  base::TimeTicks GetEventTime() const override {
    return latest().GetEventTime();
  }

  size_t GetHistorySize() const override { return events_.size() - 1; }

  base::TimeTicks GetHistoricalEventTime(
      size_t historical_index) const override {
    DCHECK_LT(historical_index, GetHistorySize());
    return events_[historical_index]->GetEventTime();
  }

  float GetHistoricalTouchMajor(size_t pointer_index,
                                size_t historical_index) const override {
    DCHECK_LT(historical_index, GetHistorySize());
    return events_[historical_index]->GetTouchMajor();
  }

  float GetHistoricalX(size_t pointer_index,
                       size_t historical_index) const override {
    DCHECK_LT(historical_index, GetHistorySize());
    return events_[historical_index]->GetX(pointer_index);
  }

  float GetHistoricalY(size_t pointer_index,
                       size_t historical_index) const override {
    DCHECK_LT(historical_index, GetHistorySize());
    return events_[historical_index]->GetY(pointer_index);
  }

  scoped_ptr<MotionEvent> Clone() const override {
    MotionEventVector cloned_events;
    cloned_events.reserve(events_.size());
    for (size_t i = 0; i < events_.size(); ++i)
      cloned_events.push_back(events_[i]->Clone().release());
    return scoped_ptr<MotionEvent>(
        new CompoundMotionEvent(cloned_events.Pass()));
  }

  scoped_ptr<MotionEvent> Cancel() const override { return latest().Cancel(); }

  // Returns the new, resampled event, or NULL if none was created.
  // TODO(jdduke): Revisit resampling to handle cases where alternating frames
  // are resampled or resampling is otherwise inconsistent, e.g., a 90hz input
  // and 60hz frame signal could phase-align such that even frames yield an
  // extrapolated event and odd frames are not resampled, crbug.com/399381.
  const MotionEvent* TryResample(base::TimeTicks resample_time,
                                 const ui::MotionEvent* next) {
    DCHECK_EQ(GetAction(), ACTION_MOVE);
    const ui::MotionEvent* event0 = NULL;
    const ui::MotionEvent* event1 = NULL;
    if (next) {
      DCHECK(resample_time < next->GetEventTime());
      // Interpolate between current sample and future sample.
      event0 = events_.back();
      event1 = next;
    } else if (events_.size() >= 2) {
      // Extrapolate future sample using current sample and past sample.
      event0 = events_[events_.size() - 2];
      event1 = events_[events_.size() - 1];

      const base::TimeTicks time1 = event1->GetEventTime();
      base::TimeTicks max_predict =
          time1 +
          std::min((event1->GetEventTime() - event0->GetEventTime()) / 2,
                   base::TimeDelta::FromMilliseconds(kResampleMaxPredictionMs));
      if (resample_time > max_predict) {
        TRACE_EVENT_INSTANT2("input",
                             "MotionEventBuffer::TryResample prediction adjust",
                             TRACE_EVENT_SCOPE_THREAD,
                             "original(ms)",
                             (resample_time - time1).InMilliseconds(),
                             "adjusted(ms)",
                             (max_predict - time1).InMilliseconds());
        resample_time = max_predict;
      }
    } else {
      TRACE_EVENT_INSTANT0("input",
                           "MotionEventBuffer::TryResample insufficient data",
                           TRACE_EVENT_SCOPE_THREAD);
      return NULL;
    }

    DCHECK(event0);
    DCHECK(event1);
    const base::TimeTicks time0 = event0->GetEventTime();
    const base::TimeTicks time1 = event1->GetEventTime();
    base::TimeDelta delta = time1 - time0;
    if (delta < base::TimeDelta::FromMilliseconds(kResampleMinDeltaMs)) {
      TRACE_EVENT_INSTANT1("input",
                           "MotionEventBuffer::TryResample failure",
                           TRACE_EVENT_SCOPE_THREAD,
                           "event_delta_too_small(ms)",
                           delta.InMilliseconds());
      return NULL;
    }

    events_.push_back(
        ResampleMotionEvent(*event0, *event1, resample_time).release());
    return events_.back();
  }

  size_t samples() const { return events_.size(); }

 private:
  const MotionEvent& latest() const { return *events_.back(); }

  // Events are in order from oldest to newest.
  MotionEventVector events_;

  DISALLOW_COPY_AND_ASSIGN(CompoundMotionEvent);
};

}  // namespace

MotionEventBuffer::MotionEventBuffer(MotionEventBufferClient* client,
                                     bool enable_resampling)
    : client_(client), resample_(enable_resampling) {
}

MotionEventBuffer::~MotionEventBuffer() {
}

void MotionEventBuffer::OnMotionEvent(const MotionEvent& event) {
  if (event.GetAction() != MotionEvent::ACTION_MOVE) {
    last_extrapolated_event_time_ = base::TimeTicks();
    if (!buffered_events_.empty())
      FlushWithoutResampling(buffered_events_.Pass());
    client_->ForwardMotionEvent(event);
    return;
  }

  // Guard against events that are *older* than the last one that may have been
  // artificially synthesized.
  if (!last_extrapolated_event_time_.is_null()) {
    DCHECK(buffered_events_.empty());
    if (event.GetEventTime() < last_extrapolated_event_time_)
      return;
    last_extrapolated_event_time_ = base::TimeTicks();
  }

  scoped_ptr<MotionEvent> clone = event.Clone();
  if (buffered_events_.empty()) {
    buffered_events_.push_back(clone.release());
    client_->SetNeedsFlush();
    return;
  }

  if (CanAddSample(*buffered_events_.front(), *clone)) {
    DCHECK(buffered_events_.back()->GetEventTime() <= clone->GetEventTime());
  } else {
    FlushWithoutResampling(buffered_events_.Pass());
  }

  buffered_events_.push_back(clone.release());
  // No need to request another flush as the first event will have requested it.
}

void MotionEventBuffer::Flush(base::TimeTicks frame_time) {
  if (buffered_events_.empty())
    return;

  // Shifting the sample time back slightly minimizes the potential for
  // misprediction when extrapolating events.
  if (resample_)
    frame_time -= base::TimeDelta::FromMilliseconds(kResampleLatencyMs);

  // TODO(jdduke): Use a persistent MotionEventVector vector for temporary
  // storage.
  MotionEventVector events(
      ConsumeSamplesNoLaterThan(&buffered_events_, frame_time));
  if (events.empty()) {
    DCHECK(!buffered_events_.empty());
    client_->SetNeedsFlush();
    return;
  }

  if (!resample_ || (events.size() == 1 && buffered_events_.empty())) {
    FlushWithoutResampling(events.Pass());
    if (!buffered_events_.empty())
      client_->SetNeedsFlush();
    return;
  }

  CompoundMotionEvent resampled_event(events.Pass());
  base::TimeTicks original_event_time = resampled_event.GetEventTime();
  const MotionEvent* next_event =
      !buffered_events_.empty() ? buffered_events_.front() : NULL;

  // Try to interpolate/extrapolate a new event at |frame_time|. Note that
  // |new_event|, if non-NULL, is owned by |resampled_event_|.
  const MotionEvent* new_event =
      resampled_event.TryResample(frame_time, next_event);

  // Log the extrapolated event time, guarding against subsequently queued
  // events that might have an earlier timestamp.
  if (!next_event && new_event &&
      new_event->GetEventTime() > original_event_time) {
    last_extrapolated_event_time_ = new_event->GetEventTime();
  } else {
    last_extrapolated_event_time_ = base::TimeTicks();
  }

  client_->ForwardMotionEvent(resampled_event);
  if (!buffered_events_.empty())
    client_->SetNeedsFlush();
}

void MotionEventBuffer::FlushWithoutResampling(MotionEventVector events) {
  last_extrapolated_event_time_ = base::TimeTicks();
  if (events.empty())
    return;

  if (events.size() == 1) {
    // Avoid CompoundEvent creation to prevent unnecessary allocations.
    scoped_ptr<MotionEvent> event(events.front());
    events.weak_clear();
    client_->ForwardMotionEvent(*event);
    return;
  }

  CompoundMotionEvent compound_event(events.Pass());
  client_->ForwardMotionEvent(compound_event);
}

}  // namespace ui
