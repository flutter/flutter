// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_GESTURE_DETECTION_MOTION_EVENT_BUFFER_H_
#define UI_EVENTS_GESTURE_DETECTION_MOTION_EVENT_BUFFER_H_

#include "base/memory/scoped_ptr.h"
#include "base/memory/scoped_vector.h"
#include "base/time/time.h"
#include "ui/events/gesture_detection/gesture_detection_export.h"

namespace ui {

class MotionEvent;

// Allows event forwarding and flush requests from a |MotionEventBuffer|.
class MotionEventBufferClient {
 public:
  virtual ~MotionEventBufferClient() {}
  virtual void ForwardMotionEvent(const MotionEvent& event) = 0;
  virtual void SetNeedsFlush() = 0;
};

// Utility class for buffering streamed MotionEventVector until a given flush.
// Events that can be combined will remain buffered, and depending on the flush
// time and buffered events, a resampled event with history will be synthesized.
// The primary purpose of this class is to ensure a smooth output motion signal
// by resampling a discrete input signal that may run on a different frequency
// or lack alignment with the output display signal.
// Note that this class is largely based on code from Android's existing touch
// pipeline (in particular, logic from ImageTransport, http://goo.gl/Ixsb0D).
// See the design doc at http://goo.gl/MdmpCf for more details.
class GESTURE_DETECTION_EXPORT MotionEventBuffer {
 public:
  // The provided |client| must not be null, and |enable_resampling| determines
  // resampling behavior (see |resample_|).
  MotionEventBuffer(MotionEventBufferClient* client, bool enable_resampling);
  ~MotionEventBuffer();

  // Should be called upon receipt of an event from the platform, prior to event
  // dispatch to UI or content components. Events that can be coalesced will
  // remain buffered until the next |Flush()|, while other events will be
  // forwarded immediately (incidentally flushing currently buffered events).
  void OnMotionEvent(const MotionEvent& event);

  // Forward any buffered events, resampling if necessary (see |resample_|)
  // according to the provided |frame_time|. This should be called in response
  // to |SetNeedsFlush()| calls on the client. If the buffer is empty, no
  // events will be forwarded, and if another flush is necessary it will be
  // requested.
  void Flush(base::TimeTicks frame_time);

 private:
  typedef ScopedVector<MotionEvent> MotionEventVector;

  void FlushWithoutResampling(MotionEventVector events);

  MotionEventBufferClient* const client_;
  MotionEventVector buffered_events_;

  // Time of the most recently extrapolated event. This will be 0 if the
  // last sent event was not extrapolated. Used internally to guard against
  // conflicts between events received from the platfrom that may have an
  // earlier timestamp than that synthesized at the latest resample.
  base::TimeTicks last_extrapolated_event_time_;

  // Whether buffered events should be resampled upon |Flush()|. If true, short
  // horizon interpolation/extrapolation will be used to synthesize the
  // forwarded event. Otherwise the most recently buffered event will be
  // forwarded, with preceding events as historical entries. Defaults to true.
  bool resample_;

  DISALLOW_COPY_AND_ASSIGN(MotionEventBuffer);
};

}  // namespace ui

#endif  // UI_EVENTS_GESTURE_DETECTION_MOTION_EVENT_BUFFER_H_
