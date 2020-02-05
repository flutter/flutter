// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_VSYNC_RECORDER_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_VSYNC_RECORDER_H_

#include <optional>

#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/time/time_point.h"
#include "lib/ui/scenic/cpp/session.h"

namespace flutter_runner {

struct VsyncInfo {
  fml::TimePoint presentation_time;
  fml::TimeDelta presentation_interval;
};

class VsyncRecorder {
 public:
  static VsyncRecorder& GetInstance();

  // Retrieve the most recent |PresentationInfo| provided to us by scenic.
  // This function is safe to call from any thread.
  VsyncInfo GetCurrentVsyncInfo() const;

  // Update the next Vsync info to |next_presentation_info_|. This is expected
  // to be called in |scenic::Session::Present2| immedaite callbacks with the
  // presentation info provided by Scenic.  Only the next vsync
  // information will be saved (in order to handle edge cases involving
  // multiple Scenic sessions in the same process).  This function is safe to
  // call from any thread.
  void UpdateNextPresentationInfo(
      fuchsia::scenic::scheduling::FuturePresentationTimes info);

  void UpdateFramePresentedInfo(zx::time presentation_time);

  fml::TimePoint GetLastPresentationTime() const;

 private:
  VsyncRecorder() { next_presentation_info_.set_presentation_time(0); }

  fuchsia::scenic::scheduling::PresentationInfo next_presentation_info_;
  fml::TimePoint last_presentation_time_ = fml::TimePoint::Now();

  // Disallow copy and assignment.
  VsyncRecorder(const VsyncRecorder&) = delete;
  VsyncRecorder& operator=(const VsyncRecorder&) = delete;
};

}  // namespace flutter_runner

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_VSYNC_RECORDER_H_
