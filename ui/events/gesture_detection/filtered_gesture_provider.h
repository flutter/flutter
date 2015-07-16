// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_GESTURE_DETECTION_FILTERED_GESTURE_PROVIDER_H_
#define UI_EVENTS_GESTURE_DETECTION_FILTERED_GESTURE_PROVIDER_H_

#include "base/basictypes.h"
#include "ui/events/gesture_detection/gesture_event_data_packet.h"
#include "ui/events/gesture_detection/gesture_provider.h"
#include "ui/events/gesture_detection/touch_disposition_gesture_filter.h"

namespace ui {

// Provides filtered gesture detection and dispatch given a sequence of touch
// events and touch event acks.
class GESTURE_DETECTION_EXPORT FilteredGestureProvider
    : public ui::TouchDispositionGestureFilterClient,
      public ui::GestureProviderClient {
 public:
  // |client| will be offered all gestures detected by the |gesture_provider_|
  // and allowed by the |gesture_filter_|.
  FilteredGestureProvider(const GestureProvider::Config& config,
                          GestureProviderClient* client);

  // Returns true if |event| was both valid and successfully handled by the
  // gesture provider.  Otherwise, returns false, in which case the caller
  // should drop |event|, not forwarding it to the renderer.
  bool OnTouchEvent(const MotionEvent& event);

  // To be called upon ack of an event that was forwarded after a successful
  // call to |OnTouchEvent()|.
  void OnTouchEventAck(bool event_consumed);

  // Methods delegated to |gesture_provider_|.
  void SetMultiTouchZoomSupportEnabled(bool enabled);
  void SetDoubleTapSupportForPlatformEnabled(bool enabled);
  void SetDoubleTapSupportForPageEnabled(bool enabled);
  const ui::MotionEvent* GetCurrentDownEvent() const;

 private:
  // GestureProviderClient implementation.
  void OnGestureEvent(const ui::GestureEventData& event) override;

  // TouchDispositionGestureFilterClient implementation.
  void ForwardGestureEvent(const ui::GestureEventData& event) override;

  GestureProviderClient* const client_;

  ui::GestureProvider gesture_provider_;
  ui::TouchDispositionGestureFilter gesture_filter_;

  bool handling_event_;
  ui::GestureEventDataPacket pending_gesture_packet_;

  DISALLOW_COPY_AND_ASSIGN(FilteredGestureProvider);
};

}  // namespace ui

#endif  // UI_EVENTS_GESTURE_DETECTION_FILTERED_GESTURE_PROVIDER_H_
