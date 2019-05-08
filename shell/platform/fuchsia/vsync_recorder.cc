// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vsync_recorder.h"

#include <mutex>

namespace flutter_runner {

namespace {

std::mutex g_mutex;

// Since we don't have any presentation info until we call |Present| for the
// first time, assume a 60hz refresh rate in the meantime.
constexpr fml::TimeDelta kDefaultPresentationInterval =
    fml::TimeDelta::FromSecondsF(1.0 / 60.0);

}  // namespace

VsyncRecorder& VsyncRecorder::GetInstance() {
  static VsyncRecorder vsync_recorder;
  return vsync_recorder;
}

VsyncInfo VsyncRecorder::GetCurrentVsyncInfo() const {
  {
    std::unique_lock<std::mutex> lock(g_mutex);
    if (last_presentation_info_) {
      return {fml::TimePoint::FromEpochDelta(fml::TimeDelta::FromNanoseconds(
                  last_presentation_info_->presentation_time)),
              fml::TimeDelta::FromNanoseconds(
                  last_presentation_info_->presentation_interval)};
    }
  }
  return {fml::TimePoint::Now(), kDefaultPresentationInterval};
}

void VsyncRecorder::UpdateVsyncInfo(
    fuchsia::images::PresentationInfo presentation_info) {
  std::unique_lock<std::mutex> lock(g_mutex);
  if (last_presentation_info_ &&
      presentation_info.presentation_time >
          last_presentation_info_->presentation_time) {
    last_presentation_info_ = presentation_info;
  } else if (!last_presentation_info_) {
    last_presentation_info_ = presentation_info;
  }
}

}  // namespace flutter_runner
