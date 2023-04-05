// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_DEFAULT_FLATLAND_CONNECTION_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_DEFAULT_FLATLAND_CONNECTION_H_

#include <fuchsia/ui/composition/cpp/fidl.h>

#include "flutter/fml/closure.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/time/time_point.h"

#include "vsync_waiter.h"

#include <cstdint>
#include <mutex>
#include <string>

namespace flutter_runner {

using on_frame_presented_event =
    std::function<void(fuchsia::scenic::scheduling::FramePresentedInfo)>;

// 2ms interval to target vsync is only used until Scenic sends presentation
// feedback, or when we run out of present credits.
static constexpr fml::TimeDelta kDefaultFlatlandPresentationInterval =
    fml::TimeDelta::FromMilliseconds(2);

// The component residing on the raster thread that is responsible for
// maintaining the Flatland instance connection and presenting updates.
class FlatlandConnection final {
 public:
  FlatlandConnection(std::string debug_label,
                     fuchsia::ui::composition::FlatlandHandle flatland,
                     fml::closure error_callback,
                     on_frame_presented_event on_frame_presented_callback,
                     uint64_t max_frames_in_flight,
                     fml::TimeDelta vsync_offset);

  ~FlatlandConnection();

  void Present();

  // Used to implement VsyncWaiter functionality.
  // Note that these two methods are called from the UI thread while the
  // rest of the methods on this class are called from the raster thread.
  void AwaitVsync(FireCallbackCallback callback);
  void AwaitVsyncForSecondaryCallback(FireCallbackCallback callback);

  fuchsia::ui::composition::Flatland* flatland() { return flatland_.get(); }

  fuchsia::ui::composition::TransformId NextTransformId() {
    return {++next_transform_id_};
  }

  fuchsia::ui::composition::ContentId NextContentId() {
    return {++next_content_id_};
  }

  void EnqueueAcquireFence(zx::event fence);
  void EnqueueReleaseFence(zx::event fence);

 private:
  void OnError(fuchsia::ui::composition::FlatlandError error);

  void OnNextFrameBegin(
      fuchsia::ui::composition::OnNextFrameBeginValues values);
  void OnFramePresented(fuchsia::scenic::scheduling::FramePresentedInfo info);
  void DoPresent();

  fuchsia::ui::composition::FlatlandPtr flatland_;

  fml::closure error_callback_;

  uint64_t next_transform_id_ = 0;
  uint64_t next_content_id_ = 0;

  on_frame_presented_event on_frame_presented_callback_;
  uint32_t present_credits_ = 1;
  bool present_waiting_for_credit_ = false;

  // A flow event trace id for following |Flatland::Present| calls into Scenic.
  uint64_t next_present_trace_id_ = 0;

  // This struct contains state that is accessed from both from the UI thread
  // (in AwaitVsync) and the raster thread (in OnNextFrameBegin and Present).
  // You should always lock mutex_ before touching anything in this struct
  struct {
    std::mutex mutex_;
    FireCallbackCallback fire_callback_;
    bool first_present_called_ = false;
    bool on_next_frame_pending_ = false;
    fml::TimePoint next_presentation_time_;
  } threadsafe_state_;

  std::vector<zx::event> acquire_fences_;
  std::vector<zx::event> current_present_release_fences_;
  std::vector<zx::event> previous_present_release_fences_;

  FML_DISALLOW_COPY_AND_ASSIGN(FlatlandConnection);
};

}  // namespace flutter_runner

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_DEFAULT_FLATLAND_CONNECTION_H_
