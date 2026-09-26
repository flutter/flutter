// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_VSYNC_WAITER_IOS_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_VSYNC_WAITER_IOS_H_

#include <CoreFoundation/CoreFoundation.h>

#include "flutter/fml/macros.h"
#include "flutter/shell/common/variable_refresh_rate_reporter.h"
#include "flutter/shell/common/vsync_waiter.h"

@class FlutterVSyncClient;
@class FlutterDisplayLinkManager;
@class UIView;
@class CALayer;

namespace flutter {

class VsyncWaiterIOS final : public VsyncWaiter, public VariableRefreshRateReporter {
 public:
  VsyncWaiterIOS(const flutter::TaskRunners& task_runners,
                 FlutterDisplayLinkManager* display_link_manager);

  ~VsyncWaiterIOS() override;

  // |VariableRefreshRateReporter|
  double GetRefreshRate() const override;

  // @brief Snaps the duration to the nearest whole Hz value and provides safe
  //        fallbacks. This ensures we don't introduce frame timing issues due
  //        to floating point error. e.g.
  //        59.998, 60.004, 59.995, ... --> 60.000
  //
  //        Additionally, guards against divide-by-zero and non-positive
  //        durations, which can occur on paused/unpaused transitions.
  //
  // Visible for testing.
  static CFTimeInterval SnapDuration(CFTimeInterval duration, double max_refresh_rate);

  // |VsyncWaiter|
  // Made public for testing.
  void AwaitVSync() override;

  // Visible for testing.
  double GetMaxRefreshRateForTesting() const { return max_refresh_rate_; }

  // Notifies the waiter that Flutter view has been updated or attached.
  void UpdateFlutterView(UIView* flutterView);

  // Notifies the waiter that a frame has been submitted. Must be called on main thread.
  void FrameSubmitted();

 private:
  // This is called right before CA Commit from the layout trampoline view layout callback.
  void OnBeforeCACommit();

  FlutterVSyncClient* client_;
  FlutterDisplayLinkManager* display_link_manager_;
  double max_refresh_rate_;

  // True if client requested vsync. If false will cause the display link to pause
  // on next tick.
  bool waiting_for_vsync_ = false;

  // True if next OnBeforeCACommit callback should trigger a vsync signal. This is set
  // on first vsync request (while displaylink is still paused) to avoid wasting
  // entire frame cycle.
  bool pending_vsync_on_ca_commit_ = false;

  // Whether content is expected for the current frame. This will cause the main
  // thread being blocked right after the implicit CACommit until content is available.
  bool waiting_for_content_ = false;

  // The trampoline view used to hook into the layout cycle.
  UIView* layout_trampoline_view_;

  FML_DISALLOW_COPY_AND_ASSIGN(VsyncWaiterIOS);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_VSYNC_WAITER_IOS_H_
