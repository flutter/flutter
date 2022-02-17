// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flatland_connection.h"

#include <zircon/status.h>

#include "flutter/fml/logging.h"

namespace flutter_runner {

FlatlandConnection::FlatlandConnection(
    std::string debug_label,
    fuchsia::ui::composition::FlatlandHandle flatland,
    fml::closure error_callback,
    on_frame_presented_event on_frame_presented_callback,
    uint64_t max_frames_in_flight,
    fml::TimeDelta vsync_offset)
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
  if (!threadsafe_state_.first_present_called_) {
    std::scoped_lock<std::mutex> lock(threadsafe_state_.mutex_);
    threadsafe_state_.first_present_called_ = true;
  }
  if (present_credits_ > 0) {
    DoPresent();
  } else {
    present_pending_ = true;
  }
}

// This method is called from the raster thread.
void FlatlandConnection::DoPresent() {
  FML_CHECK(present_credits_ > 0);
  --present_credits_;

  fuchsia::ui::composition::PresentArgs present_args;
  // TODO(fxbug.dev/94000): compute a better presentation time;
  present_args.set_requested_presentation_time(0);
  present_args.set_acquire_fences(std::move(acquire_fences_));
  present_args.set_release_fences(std::move(previous_present_release_fences_));
  present_args.set_unsquashable(false);
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
  std::scoped_lock<std::mutex> lock(threadsafe_state_.mutex_);

  // Immediately fire callbacks until the first Present. We might receive
  // multiple requests for AwaitVsync() until the first Present, which relies on
  // receiving size on FlatlandPlatformView::OnGetLayout() at an uncertain time.
  if (!threadsafe_state_.first_present_called_) {
    fml::TimePoint now = fml::TimePoint::Now();
    callback(now, now + kDefaultFlatlandPresentationInterval);
    return;
  }

  threadsafe_state_.fire_callback_ = callback;

  if (threadsafe_state_.fire_callback_pending_) {
    fml::TimePoint now = fml::TimePoint::Now();
    // TODO(fxbug.dev/94000): Calculate correct frame times.
    threadsafe_state_.fire_callback_(
        now, now + kDefaultFlatlandPresentationInterval);
    threadsafe_state_.fire_callback_ = nullptr;
    threadsafe_state_.fire_callback_pending_ = false;
  }
}

// This method is called from the UI thread.
void FlatlandConnection::AwaitVsyncForSecondaryCallback(
    FireCallbackCallback callback) {
  fml::TimePoint now = fml::TimePoint::Now();
  callback(now, now);
}

void FlatlandConnection::OnError(
    fuchsia::ui::composition::FlatlandError error) {
  FML_LOG(ERROR) << "Flatland error: " << static_cast<int>(error);
  error_callback_();
}

// This method is called from the raster thread.
void FlatlandConnection::OnNextFrameBegin(
    fuchsia::ui::composition::OnNextFrameBeginValues values) {
  present_credits_ += values.additional_present_credits();

  if (present_pending_ && present_credits_ > 0) {
    DoPresent();
    present_pending_ = false;
  }

  if (present_credits_ > 0) {
    std::scoped_lock<std::mutex> lock(threadsafe_state_.mutex_);
    if (threadsafe_state_.fire_callback_) {
      fml::TimePoint now = fml::TimePoint::Now();
      // TODO(fxbug.dev/94000): Calculate correct frame times.
      threadsafe_state_.fire_callback_(
          now, now + kDefaultFlatlandPresentationInterval);
      threadsafe_state_.fire_callback_ = nullptr;
    } else {
      threadsafe_state_.fire_callback_pending_ = true;
    }
  }
}

// This method is called from the raster thread.
void FlatlandConnection::OnFramePresented(
    fuchsia::scenic::scheduling::FramePresentedInfo info) {
  on_frame_presented_callback_(std::move(info));
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
