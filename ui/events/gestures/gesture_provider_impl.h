// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_GESTURE_DETECTION_UI_GESTURE_PROVIDER_H_
#define UI_EVENTS_GESTURE_DETECTION_UI_GESTURE_PROVIDER_H_

#include "base/basictypes.h"
#include "base/memory/scoped_vector.h"
#include "ui/events/event.h"
#include "ui/events/events_export.h"
#include "ui/events/gesture_detection/filtered_gesture_provider.h"
#include "ui/events/gesture_detection/gesture_event_data_packet.h"
#include "ui/events/gesture_detection/touch_disposition_gesture_filter.h"
#include "ui/events/gestures/motion_event_impl.h"

namespace ui {

class EVENTS_EXPORT GestureProviderImplClient {
 public:
  virtual ~GestureProviderImplClient() {}
  virtual void OnGestureEvent(GestureEvent* event) = 0;
};

// Provides gesture detection and dispatch given a sequence of touch events
// and touch event acks.
class EVENTS_EXPORT GestureProviderImpl : public GestureProviderClient {
 public:
  GestureProviderImpl(GestureProviderImplClient* client);
  ~GestureProviderImpl() override;

  bool OnTouchEvent(const TouchEvent& event);
  void OnTouchEventAck(bool event_consumed);
  const MotionEventImpl& pointer_state() { return pointer_state_; }
  ScopedVector<GestureEvent>* GetAndResetPendingGestures();

  // GestureProviderClient implementation
  void OnGestureEvent(const GestureEventData& gesture) override;

 private:
  bool IsConsideredDoubleTap(const GestureEventData& previous_tap,
                             const GestureEventData& current_tap) const;

  scoped_ptr<GestureEventData> previous_tap_;

  GestureProviderImplClient* client_;
  MotionEventImpl pointer_state_;
  FilteredGestureProvider filtered_gesture_provider_;

  ui::LatencyInfo last_touch_event_latency_info_;
  bool handling_event_;
  ScopedVector<GestureEvent> pending_gestures_;

  DISALLOW_COPY_AND_ASSIGN(GestureProviderImpl);
};

}  // namespace ui

#endif  // UI_EVENTS_GESTURE_DETECTION_UI_GESTURE_PROVIDER_H_
