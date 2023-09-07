// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flatland_connection.h"

#include <zircon/status.h>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace flutter_runner {

namespace {

// Helper function for traces.
double DeltaFromNowInNanoseconds(const fml::TimePoint& now,
                                 const fml::TimePoint& time) {
  return (time - now).ToNanoseconds();
}

}  // namespace

FlatlandConnection::FlatlandConnection(
    std::string debug_label,
    fuchsia::ui::composition::FlatlandHandle flatland,
    fml::closure error_callback,
    on_frame_presented_event on_frame_presented_callback)
    : flatland_(flatland.Bind()),
      error_callback_(error_callback),
      on_frame_presented_callback_(std::move(on_frame_presented_callback)) {
  flatland_.set_error_handler([callback = error_callback_](zx_status_t status) {
    FML_LOG(ERROR) << "Flatland disconnected: " << zx_status_get_string(status);
    callback();
  });
  flatland_->SetDebugName(debug_label);
  flatland_.events().OnError =
      fit::bind_member(this, &FlatlandConnection::OnError);
  flatland_.events().OnFramePresented =
      fit::bind_member(this, &FlatlandConnection::OnFramePresented);
  flatland_.events().OnNextFrameBegin =
      fit::bind_member(this, &FlatlandConnection::OnNextFrameBegin);
}

FlatlandConnection::~FlatlandConnection() = default;

// This method is called from the raster thread.
void FlatlandConnection::Present() {
  TRACE_DURATION("flutter", "FlatlandConnection::Present");
  std::scoped_lock<std::mutex> lock(threadsafe_state_.mutex_);
  if (threadsafe_state_.present_credits_ > 0) {
    DoPresent();
  } else {
    present_waiting_for_credit_ = true;
  }
}

// This method is called from the raster thread.
void FlatlandConnection::DoPresent() {
  TRACE_DURATION("flutter", "FlatlandConnection::DoPresent");
  TRACE_FLOW_BEGIN("gfx", "Flatland::Present", next_present_trace_id_);
  ++next_present_trace_id_;

  FML_CHECK(threadsafe_state_.present_credits_ > 0);
  --threadsafe_state_.present_credits_;

  fuchsia::ui::composition::PresentArgs present_args;
  present_args.set_requested_presentation_time(0);
  present_args.set_acquire_fences(std::move(acquire_fences_));
  present_args.set_release_fences(std::move(previous_present_release_fences_));
  // Frame rate over latency.
  present_args.set_unsquashable(true);
  flatland_->Present(std::move(present_args));

  // In Flatland, release fences apply to the content of the previous present.
  // Keeping track of the old frame's release fences and swapping ensure we set
  // the correct ones for VulkanSurface's interpretation.
  previous_present_release_fences_.clear();
  previous_present_release_fences_.swap(current_present_release_fences_);
  acquire_fences_.clear();
}

// This method is called from the UI thread.
void FlatlandConnection::AwaitVsync(FireCallbackCallback callback) {
  TRACE_DURATION("flutter", "FlatlandConnection::AwaitVsync");

  std::scoped_lock<std::mutex> lock(threadsafe_state_.mutex_);
  threadsafe_state_.pending_fire_callback_ = nullptr;
  const auto now = fml::TimePoint::Now();

  // Initial case.
  if (MaybeRunInitialVsyncCallback(now, callback))
    return;

  // Throttle case.
  if (threadsafe_state_.present_credits_ == 0) {
    threadsafe_state_.pending_fire_callback_ = callback;
    return;
  }

  // Regular case.
  RunVsyncCallback(now, callback);
}

// This method is called from the UI thread.
void FlatlandConnection::AwaitVsyncForSecondaryCallback(
    FireCallbackCallback callback) {
  TRACE_DURATION("flutter",
                 "FlatlandConnection::AwaitVsyncForSecondaryCallback");

  std::scoped_lock<std::mutex> lock(threadsafe_state_.mutex_);
  const auto now = fml::TimePoint::Now();

  // Initial case.
  if (MaybeRunInitialVsyncCallback(now, callback))
    return;

  // Regular case.
  RunVsyncCallback(now, callback);
}

// This method is called from the raster thread.
void FlatlandConnection::OnError(
    fuchsia::ui::composition::FlatlandError error) {
  FML_LOG(ERROR) << "Flatland error: " << static_cast<int>(error);
  error_callback_();
}

// This method is called from the raster thread.
void FlatlandConnection::OnNextFrameBegin(
    fuchsia::ui::composition::OnNextFrameBeginValues values) {
  // Collect now before locking because this is an important timing information
  // from Scenic.
  const auto now = fml::TimePoint::Now();

  std::scoped_lock<std::mutex> lock(threadsafe_state_.mutex_);
  threadsafe_state_.first_feedback_received_ = true;
  threadsafe_state_.present_credits_ += values.additional_present_credits();
  TRACE_DURATION("flutter", "FlatlandConnection::OnNextFrameBegin",
                 "present_credits", threadsafe_state_.present_credits_);

  if (present_waiting_for_credit_ && threadsafe_state_.present_credits_ > 0) {
    DoPresent();
    present_waiting_for_credit_ = false;
  }

  // Update vsync_interval_ by calculating the difference between the first two
  // presentation times. Flatland always returns >1 presentation_infos, so this
  // check is to guard against any changes to this assumption.
  if (values.has_future_presentation_infos() &&
      values.future_presentation_infos().size() > 1) {
    threadsafe_state_.vsync_interval_ = fml::TimeDelta::FromNanoseconds(
        values.future_presentation_infos().at(1).presentation_time() -
        values.future_presentation_infos().at(0).presentation_time());
  } else {
    FML_LOG(WARNING)
        << "Flatland didn't send enough future_presentation_infos to update "
           "vsync interval.";
  }

  // Update next_presentation_times_.
  std::queue<fml::TimePoint> new_times;
  for (const auto& info : values.future_presentation_infos()) {
    new_times.emplace(fml::TimePoint::FromEpochDelta(
        fml::TimeDelta::FromNanoseconds(info.presentation_time())));
  }
  threadsafe_state_.next_presentation_times_.swap(new_times);

  // Update vsync_offset_.
  // We use modulo here because Flatland may point to the following vsync if
  // OnNextFrameBegin() is called after the current frame's latch point.
  auto vsync_offset =
      (fml::TimePoint::FromEpochDelta(fml::TimeDelta::FromNanoseconds(
           values.future_presentation_infos().front().presentation_time())) -
       now) %
      threadsafe_state_.vsync_interval_;
  // Thread contention may result in OnNextFrameBegin() being called after the
  // presentation time. Ignore these outliers.
  if (vsync_offset > fml::TimeDelta::Zero()) {
    threadsafe_state_.vsync_offset_ = vsync_offset;
  }

  // Throttle case.
  if (threadsafe_state_.pending_fire_callback_ &&
      threadsafe_state_.present_credits_ > 0) {
    RunVsyncCallback(now, threadsafe_state_.pending_fire_callback_);
    threadsafe_state_.pending_fire_callback_ = nullptr;
  }
}

// This method is called from the raster thread.
void FlatlandConnection::OnFramePresented(
    fuchsia::scenic::scheduling::FramePresentedInfo info) {
  on_frame_presented_callback_(std::move(info));
}

// Parses and updates next_presentation_times_.
fml::TimePoint FlatlandConnection::GetNextPresentationTime(
    const fml::TimePoint& now) {
  const fml::TimePoint& cutoff =
      now > threadsafe_state_.last_presentation_time_
          ? now
          : threadsafe_state_.last_presentation_time_;

  // Remove presentation times that may have been passed. This may happen after
  // a long draw call.
  while (!threadsafe_state_.next_presentation_times_.empty() &&
         threadsafe_state_.next_presentation_times_.front() <= cutoff) {
    threadsafe_state_.next_presentation_times_.pop();
  }

  // Calculate a presentation time based on
  // |threadsafe_state_.last_presentation_time_| that is later than cutoff using
  // |vsync_interval| increments if we don't have any future presentation times
  // left.
  if (threadsafe_state_.next_presentation_times_.empty()) {
    auto result = threadsafe_state_.last_presentation_time_;
    while (result <= cutoff) {
      result = result + threadsafe_state_.vsync_interval_;
    }
    return result;
  }

  // Return the next presentation time in the queue for the regular case.
  const auto result = threadsafe_state_.next_presentation_times_.front();
  threadsafe_state_.next_presentation_times_.pop();
  return result;
}

// This method is called from the UI thread.
bool FlatlandConnection::MaybeRunInitialVsyncCallback(
    const fml::TimePoint& now,
    FireCallbackCallback& callback) {
  if (!threadsafe_state_.first_feedback_received_) {
    TRACE_DURATION("flutter",
                   "FlatlandConnection::MaybeRunInitialVsyncCallback");
    const auto frame_end = now + kInitialFlatlandVsyncOffset;
    threadsafe_state_.last_presentation_time_ = frame_end;
    callback(now, frame_end);
    return true;
  }
  return false;
}

// This method may be called from the raster or UI thread, but it is safe
// because VsyncWaiter posts the vsync callback on UI thread.
void FlatlandConnection::RunVsyncCallback(const fml::TimePoint& now,
                                          FireCallbackCallback& callback) {
  const auto& frame_end = GetNextPresentationTime(now);
  const auto& frame_start = frame_end - threadsafe_state_.vsync_offset_;
  threadsafe_state_.last_presentation_time_ = frame_end;
  TRACE_DURATION("flutter", "FlatlandConnection::RunVsyncCallback",
                 "frame_start_delta",
                 DeltaFromNowInNanoseconds(now, frame_start), "frame_end_delta",
                 DeltaFromNowInNanoseconds(now, frame_end));
  callback(frame_start, frame_end);
}

// This method is called from the raster thread.
void FlatlandConnection::EnqueueAcquireFence(zx::event fence) {
  acquire_fences_.push_back(std::move(fence));
}

// This method is called from the raster thread.
void FlatlandConnection::EnqueueReleaseFence(zx::event fence) {
  current_present_release_fences_.push_back(std::move(fence));
}

}  // namespace flutter_runner
