// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "default_session_connection.h"

#include "flutter/fml/make_copyable.h"
#include "flutter/fml/trace_event.h"

#include "vsync_waiter.h"

namespace flutter_runner {

// This function takes in all relevant information to determining when should
// the next frame be scheduled. It returns a pair of (frame_start_time,
// frame_end_time) to be passed into FireCallback().
//
// Importantly, there are two invariants for correct and performant scheduling
// that this function upholds:
// 1. Schedule the next frame at least half a vsync interval from the previous
// one. In practice, this means that every vsync interval Flutter produces
// exactly one frame in steady state behavior.
// 2. Only produce frames beginning in the future.
//
// |vsync_offset| - the time from the next vsync that the animator should begin
// working on the next frame. For instance if vsyncs are at 0ms, 16ms, and 33ms,
// and the |vsync_offset| is 5ms, then frames should begin at 11ms and 28ms.
//
// |vsync_interval| - the interval between vsyncs. Would be 16.6ms for a 60Hz
// display.
//
// |last_targeted_vsync| - the last vsync targeted, which is usually the
// frame_end_time returned from the last invocation of this function
//
// |now| - the current time
//
// |next_vsync| - the next vsync after |now|. This can be generated using the
// SnapToNextPhase function.
FlutterFrameTimes DefaultSessionConnection::GetTargetTimes(
    fml::TimeDelta vsync_offset,
    fml::TimeDelta vsync_interval,
    fml::TimePoint last_targeted_vsync,
    fml::TimePoint now,
    fml::TimePoint next_vsync) {
  FML_DCHECK(vsync_offset <= vsync_interval);
  FML_DCHECK(vsync_interval > fml::TimeDelta::FromMilliseconds(0));
  FML_DCHECK(now < next_vsync && next_vsync < now + vsync_interval);

  // This makes the math much easier below, since we live in a (mod
  // vsync_interval) world.
  if (vsync_offset == fml::TimeDelta::FromNanoseconds(0)) {
    vsync_offset = vsync_interval;
  }

  // Start the frame after Scenic has finished its CPU work. This is
  // accomplished using the vsync_offset.
  fml::TimeDelta vsync_offset2 = vsync_interval - vsync_offset;
  fml::TimePoint frame_start_time =
      (next_vsync - vsync_interval) + vsync_offset2;

  fml::TimePoint frame_end_time = next_vsync;

  // Advance to next available slot, keeping in mind the two invariants.
  while (frame_end_time < (last_targeted_vsync + (vsync_interval / 2)) ||
         frame_start_time < now) {
    frame_start_time = frame_start_time + vsync_interval;
    frame_end_time = frame_end_time + vsync_interval;
  }

  // Useful knowledge for analyzing traces.
  fml::TimePoint previous_vsync = next_vsync - vsync_interval;
  TRACE_DURATION(
      "flutter", "DefaultSessionConnection::GetTargetTimes",
      "previous_vsync(ms)", previous_vsync.ToEpochDelta().ToMilliseconds(),
      "last_targeted(ms)", last_targeted_vsync.ToEpochDelta().ToMilliseconds(),
      "now(ms)", fml::TimePoint::Now().ToEpochDelta().ToMilliseconds(),
      "next_vsync(ms))", next_vsync.ToEpochDelta().ToMilliseconds(),
      "frame_start_time(ms)", frame_start_time.ToEpochDelta().ToMilliseconds(),
      "frame_end_time(ms)", frame_end_time.ToEpochDelta().ToMilliseconds());

  return {frame_start_time, frame_end_time};
}

fml::TimePoint DefaultSessionConnection::CalculateNextLatchPoint(
    fml::TimePoint present_requested_time,
    fml::TimePoint now,
    fml::TimePoint last_latch_point_targeted,
    fml::TimeDelta flutter_frame_build_time,
    fml::TimeDelta vsync_interval,
    std::deque<std::pair<fml::TimePoint, fml::TimePoint>>&
        future_presentation_infos) {
  // The minimum latch point is the largest of:
  // Now
  // When we expect the Flutter work for the frame to be completed
  // The last latch point targeted
  fml::TimePoint minimum_latch_point_to_target =
      std::max(std::max(now, present_requested_time + flutter_frame_build_time),
               last_latch_point_targeted);

  for (auto& info : future_presentation_infos) {
    fml::TimePoint latch_point = info.first;

    if (latch_point >= minimum_latch_point_to_target) {
      return latch_point;
    }
  }

  // We could not find a suitable latch point in the list given to us from
  // Scenic, so aim for the smallest safe value.
  return minimum_latch_point_to_target;
}
/// Returns the system time at which the next frame is likely to be presented.
///
/// Consider the following scenarios, where in both the
/// scenarios the result will be the same.
///
/// Scenario 1:
/// presentation_interval is 2
/// ^     ^     ^     ^     ^
/// +     +     +     +     +
/// 0--1--2--3--4--5--6--7--8--9--
/// +        +  +
/// |        |  +---------> result: next_presentation_time
/// |        v
/// v        now
/// last_presentation_time
///
/// Scenario 2:
/// presentation_interval is 2
/// ^     ^     ^     ^     ^
/// +     +     +     +     +
/// 0--1--2--3--4--5--6--7--8--9--
///       +  +  +
///       |  |  +--------->result: next_presentation_time
///       |  |
///       |  +>now
///       |
///       +->last_presentation_time
fml::TimePoint DefaultSessionConnection::SnapToNextPhase(
    const fml::TimePoint now,
    const fml::TimePoint last_frame_presentation_time,
    const fml::TimeDelta presentation_interval) {
  if (presentation_interval <= fml::TimeDelta::Zero()) {
    FML_LOG(WARNING)
        << "Presentation interval must be positive. The value was: "
        << presentation_interval.ToMilliseconds() << "ms.";
    return now;
  }

  if (last_frame_presentation_time >= now) {
    FML_LOG(WARNING)
        << "Last frame was presented in the future. Clamping to now.";
    return now + presentation_interval;
  }

  const fml::TimeDelta time_since_last_presentation =
      now - last_frame_presentation_time;
  // this will be the most likely scenario if we are rendering at a good
  // frame rate, short circuiting the other checks in this case.
  if (time_since_last_presentation < presentation_interval) {
    return last_frame_presentation_time + presentation_interval;
  } else {
    const int64_t num_phases_passed =
        (time_since_last_presentation / presentation_interval);
    return last_frame_presentation_time +
           (presentation_interval * (num_phases_passed + 1));
  }
}

DefaultSessionConnection::DefaultSessionConnection(
    std::string debug_label,
    fidl::InterfaceHandle<fuchsia::ui::scenic::Session> session,
    fml::closure session_error_callback,
    on_frame_presented_event on_frame_presented_callback,
    uint64_t max_frames_in_flight,
    fml::TimeDelta vsync_offset)
    : session_wrapper_(session.Bind(), nullptr),
      on_frame_presented_callback_(std::move(on_frame_presented_callback)),
      kMaxFramesInFlight(max_frames_in_flight),
      vsync_offset_(vsync_offset) {
  next_presentation_info_.set_presentation_time(0);

  session_wrapper_.set_error_handler(
      [callback = session_error_callback](zx_status_t status) { callback(); });

  // Set the |fuchsia::ui::scenic::OnFramePresented()| event handler that will
  // fire every time a set of one or more frames is presented.
  session_wrapper_.set_on_frame_presented_handler(
      [this](fuchsia::scenic::scheduling::FramePresentedInfo info) {
        // Update Scenic's limit for our remaining frames in flight allowed.
        size_t num_presents_handled = info.presentation_infos.size();
        frames_in_flight_allowed_ = info.num_presents_allowed;

        // A frame was presented: Update our |frames_in_flight| to match the
        // updated unfinalized present requests.
        frames_in_flight_ -= num_presents_handled;
        TRACE_DURATION("gfx", "OnFramePresented", "frames_in_flight",
                       frames_in_flight_, "max_frames_in_flight",
                       kMaxFramesInFlight, "num_presents_handled",
                       num_presents_handled);
        FML_DCHECK(frames_in_flight_ >= 0);

        last_presentation_time_ = fml::TimePoint::FromEpochDelta(
            fml::TimeDelta::FromNanoseconds(info.actual_presentation_time));

        // Call the client-provided callback once we are done using |info|.
        on_frame_presented_callback_(std::move(info));

        if (present_session_pending_) {
          PresentSession();
        }

        {
          std::lock_guard<std::mutex> lock(mutex_);
          if (fire_callback_request_pending_) {
            FireCallbackMaybe();
          }
        }
      }  // callback
  );

  session_wrapper_.SetDebugName(debug_label);

  // Get information to finish initialization and only then allow Present()s.
  session_wrapper_.RequestPresentationTimes(
      /*requested_prediction_span=*/0,
      [this](fuchsia::scenic::scheduling::FuturePresentationTimes info) {
        frames_in_flight_allowed_ = info.remaining_presents_in_flight_allowed;

        // If Scenic alloted us 0 frames to begin with, we should fail here.
        FML_CHECK(frames_in_flight_allowed_ > 0);

        next_presentation_info_ =
            UpdatePresentationInfo(std::move(info), next_presentation_info_);

        initialized_ = true;

        PresentSession();
      });
  FML_LOG(INFO) << "Flutter DefaultSessionConnection: Set vsync_offset to "
                << vsync_offset_.ToMicroseconds() << "us";
}

DefaultSessionConnection::~DefaultSessionConnection() = default;

void DefaultSessionConnection::Present() {
  TRACE_DURATION("gfx", "DefaultSessionConnection::Present", "frames_in_flight",
                 frames_in_flight_, "max_frames_in_flight", kMaxFramesInFlight);

  TRACE_FLOW_BEGIN("gfx", "DefaultSessionConnection::PresentSession",
                   next_present_session_trace_id_);
  next_present_session_trace_id_++;

  present_requested_time_ = fml::TimePoint::Now();

  // Throttle frame submission to Scenic if we already have the maximum amount
  // of frames in flight. This allows the paint tasks for this frame to execute
  // in parallel with the presentation of previous frame but still provides
  // back-pressure to prevent us from enqueuing even more work.
  if (initialized_ && frames_in_flight_ < kMaxFramesInFlight) {
    PresentSession();
  } else {
    // We should never exceed the max frames in flight.
    FML_CHECK(frames_in_flight_ <= kMaxFramesInFlight);

    present_session_pending_ = true;
  }
}

void DefaultSessionConnection::AwaitVsync(FireCallbackCallback callback) {
  std::lock_guard<std::mutex> lock(mutex_);
  TRACE_DURATION("flutter", "DefaultSessionConnection::AwaitVsync");
  fire_callback_ = callback;

  FireCallbackMaybe();
}

void DefaultSessionConnection::AwaitVsyncForSecondaryCallback(
    FireCallbackCallback callback) {
  std::lock_guard<std::mutex> lock(mutex_);
  TRACE_DURATION("flutter",
                 "DefaultSessionConnection::AwaitVsyncForSecondaryCallback");
  fire_callback_ = callback;

  FlutterFrameTimes times = GetTargetTimesHelper(/*secondary_callback=*/true);
  fire_callback_(times.frame_start, times.frame_target);
}

void DefaultSessionConnection::PresentSession() {
  TRACE_DURATION("gfx", "DefaultSessionConnection::PresentSession");

  // If we cannot call Present2() because we have no more Scenic frame budget,
  // then we must wait until the OnFramePresented() event fires so we can
  // continue our work.
  if (frames_in_flight_allowed_ == 0) {
    FML_CHECK(!initialized_ || present_session_pending_);
    return;
  }

  present_session_pending_ = false;

  while (processed_present_session_trace_id_ < next_present_session_trace_id_) {
    TRACE_FLOW_END("gfx", "DefaultSessionConnection::PresentSession",
                   processed_present_session_trace_id_);
    processed_present_session_trace_id_++;
  }
  TRACE_FLOW_BEGIN("gfx", "Session::Present", next_present_trace_id_);
  next_present_trace_id_++;

  ++frames_in_flight_;

  // Flush all session ops. Paint tasks may not yet have executed but those are
  // fenced. The compositor can start processing ops while we finalize paint
  // tasks.

  fml::TimeDelta presentation_interval =
      GetCurrentVsyncInfo().presentation_interval;

  fml::TimePoint next_latch_point = CalculateNextLatchPoint(
      fml::TimePoint::Now(), present_requested_time_,
      last_latch_point_targeted_,
      fml::TimeDelta::FromMicroseconds(0),  // flutter_frame_build_time
      presentation_interval, future_presentation_infos_);

  last_latch_point_targeted_ = next_latch_point;

  session_wrapper_.Present2(
      /*requested_presentation_time=*/next_latch_point.ToEpochDelta()
          .ToNanoseconds(),
      /*requested_prediction_span=*/presentation_interval.ToNanoseconds() * 10,
      [this](fuchsia::scenic::scheduling::FuturePresentationTimes info) {
        // Clear |future_presentation_infos_| and replace it with the updated
        // information.
        std::deque<std::pair<fml::TimePoint, fml::TimePoint>>().swap(
            future_presentation_infos_);

        for (fuchsia::scenic::scheduling::PresentationInfo& presentation_info :
             info.future_presentations) {
          future_presentation_infos_.push_back(
              {fml::TimePoint::FromEpochDelta(fml::TimeDelta::FromNanoseconds(
                   presentation_info.latch_point())),
               fml::TimePoint::FromEpochDelta(fml::TimeDelta::FromNanoseconds(
                   presentation_info.presentation_time()))});
        }

        frames_in_flight_allowed_ = info.remaining_presents_in_flight_allowed;
        next_presentation_info_ =
            UpdatePresentationInfo(std::move(info), next_presentation_info_);
      });
}

// Postcondition: Either a frame is scheduled or fire_callback_request_pending_
// is set to true, meaning we will attempt to schedule a frame on the next
// |OnVsync|.
void DefaultSessionConnection::FireCallbackMaybe() {
  TRACE_DURATION("flutter", "FireCallbackMaybe");

  if (frames_in_flight_ < kMaxFramesInFlight) {
    FlutterFrameTimes times =
        GetTargetTimesHelper(/*secondary_callback=*/false);

    last_targeted_vsync_ = times.frame_target;
    fire_callback_request_pending_ = false;

    fire_callback_(times.frame_start, times.frame_target);
  } else {
    fire_callback_request_pending_ = true;
  }
}

// A helper function for GetTargetTimes(), since many of the fields it takes
// have to be derived from other state.
FlutterFrameTimes DefaultSessionConnection::GetTargetTimesHelper(
    bool secondary_callback) {
  fml::TimeDelta presentation_interval =
      GetCurrentVsyncInfo().presentation_interval;

  fml::TimePoint next_vsync = GetCurrentVsyncInfo().presentation_time;
  fml::TimePoint now = fml::TimePoint::Now();
  fml::TimePoint last_presentation_time = last_presentation_time_;
  if (next_vsync <= now) {
    next_vsync =
        SnapToNextPhase(now, last_presentation_time, presentation_interval);
  }

  fml::TimePoint last_targeted_vsync =
      secondary_callback ? fml::TimePoint::Min() : last_targeted_vsync_;
  return GetTargetTimes(vsync_offset_, presentation_interval,
                        last_targeted_vsync, now, next_vsync);
}

fuchsia::scenic::scheduling::PresentationInfo

DefaultSessionConnection::UpdatePresentationInfo(
    fuchsia::scenic::scheduling::FuturePresentationTimes future_info,
    fuchsia::scenic::scheduling::PresentationInfo& presentation_info) {
  fuchsia::scenic::scheduling::PresentationInfo new_presentation_info;
  new_presentation_info.set_presentation_time(
      presentation_info.presentation_time());

  auto next_time = presentation_info.presentation_time();
  // Get the earliest vsync time that is after our recorded |presentation_time|.
  for (auto& presentation_info : future_info.future_presentations) {
    auto current_time = presentation_info.presentation_time();

    if (current_time > next_time) {
      new_presentation_info.set_presentation_time(current_time);
      return new_presentation_info;
    }
  }

  return new_presentation_info;
}

VsyncInfo DefaultSessionConnection::GetCurrentVsyncInfo() const {
  return {fml::TimePoint::FromEpochDelta(fml::TimeDelta::FromNanoseconds(
              next_presentation_info_.presentation_time())),
          kDefaultPresentationInterval};
}

}  // namespace flutter_runner
