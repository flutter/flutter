// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/gesture_detection/filtered_gesture_provider.h"

#include "base/auto_reset.h"
#include "base/logging.h"
#include "ui/events/gesture_detection/motion_event.h"

namespace ui {

FilteredGestureProvider::FilteredGestureProvider(
    const GestureProvider::Config& config,
    GestureProviderClient* client)
    : client_(client),
      gesture_provider_(config, this),
      gesture_filter_(this),
      handling_event_(false) {}

bool FilteredGestureProvider::OnTouchEvent(const MotionEvent& event) {
  DCHECK(!handling_event_);
  base::AutoReset<bool> handling_event(&handling_event_, true);

  pending_gesture_packet_ = GestureEventDataPacket::FromTouch(event);

  if (!gesture_provider_.OnTouchEvent(event))
    return false;

  TouchDispositionGestureFilter::PacketResult result =
      gesture_filter_.OnGesturePacket(pending_gesture_packet_);
  if (result != TouchDispositionGestureFilter::SUCCESS) {
    NOTREACHED() << "Invalid touch gesture sequence detected.";
    return false;
  }

  return true;
}

void FilteredGestureProvider::OnTouchEventAck(bool event_consumed) {
  gesture_filter_.OnTouchEventAck(event_consumed);
}

void FilteredGestureProvider::SetMultiTouchZoomSupportEnabled(
    bool enabled) {
  gesture_provider_.SetMultiTouchZoomSupportEnabled(enabled);
}

void FilteredGestureProvider::SetDoubleTapSupportForPlatformEnabled(
    bool enabled) {
  gesture_provider_.SetDoubleTapSupportForPlatformEnabled(enabled);
}

void FilteredGestureProvider::SetDoubleTapSupportForPageEnabled(bool enabled) {
  gesture_provider_.SetDoubleTapSupportForPageEnabled(enabled);
}

const ui::MotionEvent* FilteredGestureProvider::GetCurrentDownEvent() const {
  return gesture_provider_.current_down_event();
}

void FilteredGestureProvider::OnGestureEvent(const GestureEventData& event) {
  if (handling_event_) {
    pending_gesture_packet_.Push(event);
    return;
  }

  gesture_filter_.OnGesturePacket(
      GestureEventDataPacket::FromTouchTimeout(event));
}

void FilteredGestureProvider::ForwardGestureEvent(
    const GestureEventData& event) {
  client_->OnGestureEvent(event);
}

}  // namespace ui
