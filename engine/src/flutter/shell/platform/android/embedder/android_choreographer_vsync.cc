// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/embedder/android_choreographer_vsync.h"

#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace flutter {

namespace {

constexpr uint64_t kNanosPerSecond = 1000000000ULL;
constexpr uint64_t kDefaultRefreshPeriodNanos = 16666666ULL;  // ~60 Hz

uint64_t ComputeRefreshPeriodNanos(double fps) {
  if (fps <= 1.0) {
    return kDefaultRefreshPeriodNanos;
  }
  return static_cast<uint64_t>(static_cast<double>(kNanosPerSecond) / fps);
}

}  // namespace

AndroidChoreographerVsync::AndroidChoreographerVsync(
    std::shared_ptr<JniDelegate> jni_delegate,
    const FlutterEngineProcTable& proc_table,
    double initial_refresh_rate_fps)
    : jni_delegate_(std::move(jni_delegate)),
      embedder_api_(proc_table),
      refresh_period_nanos_(
          ComputeRefreshPeriodNanos(initial_refresh_rate_fps)) {}

AndroidChoreographerVsync::~AndroidChoreographerVsync() {
  CancelPendingBatons();
}

void AndroidChoreographerVsync::SetRefreshRateFps(double refresh_rate_fps) {
  std::lock_guard<std::mutex> lock(mutex_);
  refresh_period_nanos_ = ComputeRefreshPeriodNanos(refresh_rate_fps);
}

uint64_t AndroidChoreographerVsync::GetRefreshPeriodNanos() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return refresh_period_nanos_;
}

void AndroidChoreographerVsync::RequestVsync(intptr_t baton) {
  TRACE_EVENT0("flutter", "AndroidChoreographerVsync::RequestVsync");
  if (baton == 0) {
    return;
  }
  {
    std::lock_guard<std::mutex> lock(mutex_);
    pending_batons_.insert(baton);
    accept_unsolicited_batons_ = false;
  }
  if (jni_delegate_ != nullptr) {
    jni_delegate_->RequestVsync(baton);
  }
}

bool AndroidChoreographerVsync::OnChoreographerFrame(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    intptr_t baton,
    uint64_t frame_start_time_nanos,
    uint64_t frame_target_time_nanos) {
  TRACE_EVENT0("flutter", "AndroidChoreographerVsync::OnChoreographerFrame");
  if (engine == nullptr || baton == 0 || embedder_api_.OnVsync == nullptr) {
    return false;
  }

  uint64_t target_nanos = frame_target_time_nanos;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = pending_batons_.find(baton);
    if (it != pending_batons_.end()) {
      pending_batons_.erase(it);
    } else if (!accept_unsolicited_batons_) {
      // Reject duplicate or cancelled vsync batons so the engine is never
      // signaled twice with the same baton pointer.
      return false;
    }

    if (target_nanos <= frame_start_time_nanos) {
      target_nanos = frame_start_time_nanos + refresh_period_nanos_;
    }
  }

  return embedder_api_.OnVsync(engine, baton, frame_start_time_nanos,
                               target_nanos) == kSuccess;
}

void AndroidChoreographerVsync::CancelPendingBatons() {
  std::lock_guard<std::mutex> lock(mutex_);
  pending_batons_.clear();
  accept_unsolicited_batons_ = false;
}

size_t AndroidChoreographerVsync::GetPendingBatonCount() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return pending_batons_.size();
}

}  // namespace flutter
