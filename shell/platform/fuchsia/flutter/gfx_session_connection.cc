// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gfx_session_connection.h"

#include <lib/async/cpp/task.h>
#include <lib/async/cpp/time.h>
#include <lib/async/default.h>
#include <lib/fit/function.h>
#include <zircon/status.h>

#include "flutter/fml/make_copyable.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/fml/trace_event.h"

#include "vsync_waiter.h"

namespace flutter_runner {
namespace {

fml::TimePoint Now() {
  return fml::TimePoint::FromEpochDelta(fml::TimeDelta::FromNanoseconds(
      async::Now(async_get_default_dispatcher()).get()));
}

}  // namespace

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
FlutterFrameTimes GfxSessionConnection::GetTargetTimes(
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
      "flutter", "GfxSessionConnection::GetTargetTimes", "previous_vsync(ms)",
      previous_vsync.ToEpochDelta().ToMilliseconds(), "last_targeted(ms)",
      last_targeted_vsync.ToEpochDelta().ToMilliseconds(), "now(ms)",
      now.ToEpochDelta().ToMilliseconds(), "next_vsync(ms))",
      next_vsync.ToEpochDelta().ToMilliseconds(), "frame_start_time(ms)",
      frame_start_time.ToEpochDelta().ToMilliseconds(), "frame_end_time(ms)",
      frame_end_time.ToEpochDelta().ToMilliseconds());

  return {frame_start_time, frame_end_time};
}

fml::TimePoint GfxSessionConnection::CalculateNextLatchPoint(
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
fml::TimePoint GfxSessionConnection::SnapToNextPhase(
    const fml::TimePoint now,
    const fml::TimePoint last_frame_presentation_time,
    const fml::TimeDelta presentation_interval) {
  if (presentation_interval <= fml::TimeDelta::Zero()) {
    FML_LOG(WARNING)
        << "Presentation interval must be positive. The value was: "
        << presentation_interval.ToMilliseconds() << "ms.";
    return now;
  }

  if (last_frame_presentation_time > now) {
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

GfxSessionConnection::GfxSessionConnection(
    std::string debug_label,
    inspect::Node inspect_node,
    fuchsia::ui::scenic::SessionHandle session,
    fml::closure session_error_callback,
    on_frame_presented_event on_frame_presented_callback,
    uint64_t max_frames_in_flight,
    fml::TimeDelta vsync_offset)
    : session_wrapper_(session.Bind(), nullptr),
      inspect_node_(std::move(inspect_node)),
      secondary_vsyncs_completed_(
          inspect_node_.CreateUint("SecondaryVsyncsCompleted", 0u)),
      vsyncs_requested_(inspect_node_.CreateUint("VsyncsRequested", 0u)),
      vsyncs_completed_(inspect_node_.CreateUint("VsyncsCompleted", 0u)),
      presents_requested_(inspect_node_.CreateUint("PresentsRequested", 0u)),
      presents_submitted_(inspect_node_.CreateUint("PresentsSubmitted", 0u)),
      presents_completed_(inspect_node_.CreateUint("PresentsCompleted", 0u)),
      last_secondary_vsync_completed_(
          inspect_node_.CreateInt("LastSecondaryVsyncCompleteTime", 0)),
      last_vsync_requested_(inspect_node_.CreateInt("LastVsyncRequestTime", 0)),
      last_vsync_completed_(
          inspect_node_.CreateInt("LastVsyncCompleteTime", 0)),
      last_frame_requested_(
          inspect_node_.CreateInt("LastPresentRequestTime", 0)),
      last_frame_presented_(
          inspect_node_.CreateInt("LastPresentSubmitTime", 0)),
      last_frame_completed_(
          inspect_node_.CreateInt("LastSubmitCompleteTime", 0)),
      inspect_dispatcher_(async_get_default_dispatcher()),
      on_frame_presented_callback_(std::move(on_frame_presented_callback)),
      kMaxFramesInFlight(max_frames_in_flight),
      vsync_offset_(vsync_offset),
      weak_factory_(this) {
  FML_CHECK(kMaxFramesInFlight > 0);
  last_presentation_time_ = Now();

  next_presentation_info_.set_presentation_time(0);

  session_wrapper_.set_error_handler([callback = session_error_callback](
                                         zx_status_t status) {
    FML_LOG(ERROR) << "scenic::Session error: " << zx_status_get_string(status);
    callback();
  });

  // Set the |fuchsia::ui::scenic::OnFramePresented()| event handler that will
  // fire every time a set of one or more frames is presented.
  session_wrapper_.set_on_frame_presented_handler(
      [weak = weak_factory_.GetWeakPtr()](
          fuchsia::scenic::scheduling::FramePresentedInfo info) {
        if (!weak) {
          return;
        }

        std::lock_guard<std::mutex> lock(weak->mutex_);

        // Update Scenic's limit for our remaining frames in flight allowed.
        size_t num_presents_handled = info.presentation_infos.size();

        // A frame was presented: Update our |frames_in_flight| to match the
        // updated unfinalized present requests.
        weak->frames_in_flight_ -= num_presents_handled;

        TRACE_DURATION("gfx", "OnFramePresented5", "frames_in_flight",
                       weak->frames_in_flight_, "max_frames_in_flight",
                       weak->kMaxFramesInFlight, "num_presents_handled",
                       num_presents_handled);
        FML_DCHECK(weak->frames_in_flight_ >= 0);

        weak->last_presentation_time_ = fml::TimePoint::FromEpochDelta(
            fml::TimeDelta::FromNanoseconds(info.actual_presentation_time));

        // Scenic retired a given number of frames, so mark them as completed.
        // Inspect updates must run on the inspect dispatcher.
        //
        // TODO(akbiggs): It might not be necessary to post an async task for
        // the inspect updates. Read over the Inspect API's thread safety and
        // adjust accordingly.
        async::PostTask(weak->inspect_dispatcher_, [weak, now = Now(),
                                                    num_presents_handled]() {
          if (!weak) {
            return;
          }

          weak->presents_completed_.Add(num_presents_handled);
          weak->last_frame_completed_.Set(now.ToEpochDelta().ToNanoseconds());
        });

        if (weak->fire_callback_request_pending_) {
          weak->FireCallbackMaybe();
        }

        if (weak->present_session_pending_) {
          weak->PresentSession();
        }

        // Call the client-provided callback once we are done using |info|.
        weak->on_frame_presented_callback_(std::move(info));
      });

  session_wrapper_.SetDebugName(debug_label);

  // Get information to finish initialization and only then allow Present()s.
  session_wrapper_.RequestPresentationTimes(
      /*requested_prediction_span=*/0,
      [weak = weak_factory_.GetWeakPtr()](
          fuchsia::scenic::scheduling::FuturePresentationTimes info) {
        if (!weak) {
          return;
        }

        std::lock_guard<std::mutex> lock(weak->mutex_);

        weak->next_presentation_info_ = UpdatePresentationInfo(
            std::move(info), weak->next_presentation_info_);

        weak->initialized_ = true;

        weak->PresentSession();
      });
  FML_LOG(INFO) << "Flutter GfxSessionConnection: Set vsync_offset to "
                << vsync_offset_.ToMicroseconds() << "us";
}

GfxSessionConnection::~GfxSessionConnection() = default;

void GfxSessionConnection::Present() {
  std::lock_guard<std::mutex> lock(mutex_);

  TRACE_DURATION("gfx", "GfxSessionConnection::Present", "frames_in_flight",
                 frames_in_flight_, "max_frames_in_flight", kMaxFramesInFlight);

  TRACE_FLOW_BEGIN("gfx", "GfxSessionConnection::PresentSession",
                   next_present_session_trace_id_);
  ++next_present_session_trace_id_;

  auto now = Now();
  present_requested_time_ = now;

  // Flutter is requesting a frame here, so mark it as such.
  // Inspect updates must run on the inspect dispatcher.
  async::PostTask(inspect_dispatcher_, [this, now]() {
    presents_requested_.Add(1);
    last_frame_requested_.Set(now.ToEpochDelta().ToNanoseconds());
  });

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

void GfxSessionConnection::AwaitVsync(FireCallbackCallback callback) {
  std::lock_guard<std::mutex> lock(mutex_);
  TRACE_DURATION("flutter", "GfxSessionConnection::AwaitVsync");
  fire_callback_ = callback;

  // Flutter is requesting a vsync here, so mark it as such.
  // Inspect updates must run on the inspect dispatcher.
  async::PostTask(inspect_dispatcher_, [this, now = Now()]() {
    vsyncs_requested_.Add(1);
    last_vsync_requested_.Set(now.ToEpochDelta().ToNanoseconds());
  });

  FireCallbackMaybe();
}

void GfxSessionConnection::AwaitVsyncForSecondaryCallback(
    FireCallbackCallback callback) {
  std::lock_guard<std::mutex> lock(mutex_);
  TRACE_DURATION("flutter",
                 "GfxSessionConnection::AwaitVsyncForSecondaryCallback");
  fire_callback_ = callback;

  // Flutter is requesting a secondary vsync here, so mark it as such.
  // Inspect updates must run on the inspect dispatcher.
  async::PostTask(inspect_dispatcher_, [this, now = Now()]() {
    secondary_vsyncs_completed_.Add(1);
    last_secondary_vsync_completed_.Set(now.ToEpochDelta().ToNanoseconds());
  });

  FlutterFrameTimes times = GetTargetTimesHelper(/*secondary_callback=*/true);
  fire_callback_(times.frame_start, times.frame_target);
}

// Precondition: |mutex_| is held
void GfxSessionConnection::PresentSession() {
  TRACE_DURATION("gfx", "GfxSessionConnection::PresentSession");

  present_session_pending_ = false;

  while (processed_present_session_trace_id_ < next_present_session_trace_id_) {
    TRACE_FLOW_END("gfx", "GfxSessionConnection::PresentSession",
                   processed_present_session_trace_id_);
    ++processed_present_session_trace_id_;
  }
  TRACE_FLOW_BEGIN("gfx", "Session::Present", next_present_trace_id_);
  ++next_present_trace_id_;

  ++frames_in_flight_;

  fml::TimeDelta presentation_interval =
      GetCurrentVsyncInfo().presentation_interval;

  fml::TimePoint next_latch_point = CalculateNextLatchPoint(
      Now(), present_requested_time_, last_latch_point_targeted_,
      fml::TimeDelta::FromMicroseconds(0),  // flutter_frame_build_time
      presentation_interval, future_presentation_infos_);

  last_latch_point_targeted_ = next_latch_point;

  // Flutter is presenting a frame here, so mark it as such.
  // Inspect updates must run on the inspect dispatcher.
  async::PostTask(inspect_dispatcher_, [this, now = Now()]() {
    presents_submitted_.Add(1);
    last_frame_presented_.Set(now.ToEpochDelta().ToNanoseconds());
  });

  session_wrapper_.Present2(
      /*requested_presentation_time=*/next_latch_point.ToEpochDelta()
          .ToNanoseconds(),
      /*requested_prediction_span=*/presentation_interval.ToNanoseconds() * 10,
      [weak = weak_factory_.GetWeakPtr()](
          fuchsia::scenic::scheduling::FuturePresentationTimes info) {
        if (!weak) {
          return;
        }

        std::lock_guard<std::mutex> lock(weak->mutex_);

        // Clear |future_presentation_infos_| and replace it with the updated
        // information.
        std::deque<std::pair<fml::TimePoint, fml::TimePoint>>().swap(
            weak->future_presentation_infos_);

        for (fuchsia::scenic::scheduling::PresentationInfo& presentation_info :
             info.future_presentations) {
          weak->future_presentation_infos_.push_back(
              {fml::TimePoint::FromEpochDelta(fml::TimeDelta::FromNanoseconds(
                   presentation_info.latch_point())),
               fml::TimePoint::FromEpochDelta(fml::TimeDelta::FromNanoseconds(
                   presentation_info.presentation_time()))});
        }

        weak->next_presentation_info_ = UpdatePresentationInfo(
            std::move(info), weak->next_presentation_info_);
      });
}

// Precondition: |mutex_| is held.
//
// Postcondition: Either a frame is scheduled or fire_callback_request_pending_
// is set to true, meaning we will attempt to schedule a frame on the next
// |OnFramePresented|.
void GfxSessionConnection::FireCallbackMaybe() {
  TRACE_DURATION("flutter", "FireCallbackMaybe");

  if (frames_in_flight_ < kMaxFramesInFlight) {
    FlutterFrameTimes times =
        GetTargetTimesHelper(/*secondary_callback=*/false);

    last_targeted_vsync_ = times.frame_target;
    fire_callback_request_pending_ = false;

    // Scenic completed a vsync here, so mark it as such.
    // Inspect updates must run on the inspect dispatcher.
    async::PostTask(inspect_dispatcher_, [this, now = Now()]() {
      vsyncs_completed_.Add(1);
      last_vsync_completed_.Set(now.ToEpochDelta().ToNanoseconds());
    });

    fire_callback_(times.frame_start, times.frame_target);
  } else {
    fire_callback_request_pending_ = true;
  }
}

// Precondition: |mutex_| is held
//
// A helper function for GetTargetTimes(), since many of the fields it takes
// have to be derived from other state.
FlutterFrameTimes GfxSessionConnection::GetTargetTimesHelper(
    bool secondary_callback) {
  fml::TimeDelta presentation_interval =
      GetCurrentVsyncInfo().presentation_interval;

  fml::TimePoint next_vsync = GetCurrentVsyncInfo().presentation_time;
  fml::TimePoint now = Now();
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
GfxSessionConnection::UpdatePresentationInfo(
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

// Precondition: |mutex_| is held
VsyncInfo GfxSessionConnection::GetCurrentVsyncInfo() const {
  return {fml::TimePoint::FromEpochDelta(fml::TimeDelta::FromNanoseconds(
              next_presentation_info_.presentation_time())),
          kDefaultPresentationInterval};
}

}  // namespace flutter_runner
