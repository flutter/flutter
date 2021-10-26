// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_GFX_SESSION_CONNECTION_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_GFX_SESSION_CONNECTION_H_

#include <fuchsia/scenic/scheduling/cpp/fidl.h>
#include <fuchsia/ui/scenic/cpp/fidl.h>
#include <lib/async/dispatcher.h>
#include <lib/fidl/cpp/interface_handle.h>
#include <lib/inspect/cpp/inspect.h>
#include <lib/ui/scenic/cpp/session.h>

#include "flutter/fml/closure.h"
#include "flutter/fml/macros.h"

#include "fml/time/time_delta.h"
#include "vsync_waiter.h"

#include <mutex>

namespace flutter_runner {

using on_frame_presented_event =
    std::function<void(fuchsia::scenic::scheduling::FramePresentedInfo)>;

struct FlutterFrameTimes {
  fml::TimePoint frame_start;
  fml::TimePoint frame_target;
};

struct VsyncInfo {
  fml::TimePoint presentation_time;
  fml::TimeDelta presentation_interval;
};

// Assume a 60hz refresh rate before we have enough past
// |fuchsia::scenic::scheduling::PresentationInfo|s to calculate it ourselves.
static constexpr fml::TimeDelta kDefaultPresentationInterval =
    fml::TimeDelta::FromSecondsF(1.0 / 60.0);

// The component residing on the raster thread that is responsible for
// maintaining the Scenic session connection and presenting node updates.
class GfxSessionConnection final {
 public:
  static FlutterFrameTimes GetTargetTimes(fml::TimeDelta vsync_offset,
                                          fml::TimeDelta vsync_interval,
                                          fml::TimePoint last_targeted_vsync,
                                          fml::TimePoint now,
                                          fml::TimePoint next_vsync);

  static fml::TimePoint CalculateNextLatchPoint(
      fml::TimePoint present_requested_time,
      fml::TimePoint now,
      fml::TimePoint last_latch_point_targeted,
      fml::TimeDelta flutter_frame_build_time,
      fml::TimeDelta vsync_interval,
      std::deque<std::pair<fml::TimePoint, fml::TimePoint>>&
          future_presentation_infos);

  static fml::TimePoint SnapToNextPhase(
      const fml::TimePoint now,
      const fml::TimePoint last_frame_presentation_time,
      const fml::TimeDelta presentation_interval);

  // Update the next Vsync info to |next_presentation_info_|. This is expected
  // to be called in |scenic::Session::Present2| immedaite callbacks with the
  // presentation info provided by Scenic.  Only the next vsync
  // information will be saved (in order to handle edge cases involving
  // multiple Scenic sessions in the same process). This function is safe to
  // call from any thread.
  static fuchsia::scenic::scheduling::PresentationInfo UpdatePresentationInfo(
      fuchsia::scenic::scheduling::FuturePresentationTimes future_info,
      fuchsia::scenic::scheduling::PresentationInfo& presentation_info);

  GfxSessionConnection(std::string debug_label,
                       inspect::Node inspect_node,
                       fuchsia::ui::scenic::SessionHandle session,
                       fml::closure session_error_callback,
                       on_frame_presented_event on_frame_presented_callback,
                       uint64_t max_frames_in_flight,
                       fml::TimeDelta vsync_offset);

  ~GfxSessionConnection();

  scenic::Session* get() { return &session_wrapper_; }

  // Call to request that the all enqueued Session ops since the last |Present|
  // be sent to Scenic.
  void Present();

  // Used to implement VsyncWaiter functionality.
  void AwaitVsync(FireCallbackCallback callback);
  void AwaitVsyncForSecondaryCallback(FireCallbackCallback callback);

 private:
  void PresentSession();

  void FireCallbackMaybe();

  FlutterFrameTimes GetTargetTimesHelper(bool secondary_callback);
  VsyncInfo GetCurrentVsyncInfo() const;

  scenic::Session session_wrapper_;

  inspect::Node inspect_node_;
  inspect::UintProperty secondary_vsyncs_completed_;
  inspect::UintProperty vsyncs_requested_;
  inspect::UintProperty vsyncs_completed_;
  inspect::UintProperty presents_requested_;
  inspect::UintProperty presents_submitted_;
  inspect::UintProperty presents_completed_;
  inspect::IntProperty last_secondary_vsync_completed_;
  inspect::IntProperty last_vsync_requested_;
  inspect::IntProperty last_vsync_completed_;
  inspect::IntProperty last_frame_requested_;
  inspect::IntProperty last_frame_presented_;
  inspect::IntProperty last_frame_completed_;
  async_dispatcher_t* inspect_dispatcher_;

  on_frame_presented_event on_frame_presented_callback_;

  fml::TimePoint last_latch_point_targeted_;
  fml::TimePoint present_requested_time_;

  std::deque<std::pair<fml::TimePoint, fml::TimePoint>>
      future_presentation_infos_ = {};

  bool initialized_ = false;

  // A flow event trace id for following |Session::Present| calls into
  // Scenic.  This will be incremented each |Session::Present| call.  By
  // convention, the Scenic side will also contain its own trace id that
  // begins at 0, and is incremented each |Session::Present| call.
  uint64_t next_present_trace_id_ = 0;
  uint64_t next_present_session_trace_id_ = 0;
  uint64_t processed_present_session_trace_id_ = 0;

  // The maximum number of frames Flutter sent to Scenic that it can have
  // outstanding at any time. This is equivalent to how many times it has
  // called Present2() before receiving an OnFramePresented() event.
  const int kMaxFramesInFlight;

  int frames_in_flight_ = 0;
  bool present_session_pending_ = false;

  // The time from vsync that the Flutter animator should begin its frames. This
  // is non-zero so that Flutter and Scenic compete less for CPU and GPU time.
  fml::TimeDelta vsync_offset_;

  // Variables for recording past and future vsync info, as reported by Scenic.
  fml::TimePoint last_presentation_time_;
  fuchsia::scenic::scheduling::PresentationInfo next_presentation_info_;

  // Flutter framework pipeline logic.

  // The following fields can be accessed from both the raster and UI threads,
  // so guard them with this mutex. If performance dictates, this could probably
  // be made lock-free, but it's much easier to reason about with this mutex.
  std::mutex mutex_;

  // This is the last Vsync we submitted as the frame_target_time to
  // FireCallback(). This value should be strictly increasing in order to
  // guarantee that animation code that relies on target vsyncs works correctly,
  // and that Flutter is not producing multiple frames in a small interval.
  fml::TimePoint last_targeted_vsync_;

  // This is true iff AwaitVSync() was called but we could not schedule a frame.
  bool fire_callback_request_pending_ = false;

  // The callback passed in from VsyncWaiter which eventually runs on the UI
  // thread.
  FireCallbackCallback fire_callback_;

  // Generates WeakPtrs to the instance of the class so callbacks can verify
  // that the instance is still in-scope before accessing state.
  // This must be the last field in the class.
  fml::WeakPtrFactory<GfxSessionConnection> weak_factory_;

  FML_DISALLOW_COPY_AND_ASSIGN(GfxSessionConnection);
};

}  // namespace flutter_runner

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_GFX_SESSION_CONNECTION_H_
