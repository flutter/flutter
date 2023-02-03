// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_VSYNC_WAITER_IOS_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_VSYNC_WAITER_IOS_H_

#include <QuartzCore/CADisplayLink.h>

#include "flutter/fml/macros.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/common/variable_refresh_rate_reporter.h"
#include "flutter/shell/common/vsync_waiter.h"

@interface DisplayLinkManager : NSObject

// Whether the max refresh rate on iPhone Pro-motion devices are enabled.
// This reflects the value of `CADisableMinimumFrameDurationOnPhone` in the
// info.plist file.
//
// Note on iPads that support Pro-motion, the max refresh rate is always enabled.
@property(class, nonatomic, readonly) BOOL maxRefreshRateEnabledOnIPhone;

//------------------------------------------------------------------------------
/// @brief      The display refresh rate used for reporting purposes. The engine does not care
///             about this for frame scheduling. It is only used by tools for instrumentation. The
///             engine uses the duration field of the link per frame for frame scheduling.
///
/// @attention  Do not use the this call in frame scheduling. It is only meant for reporting.
///
/// @return     The refresh rate in frames per second.
///
+ (double)displayRefreshRate;

@end

@interface VSyncClient : NSObject

//------------------------------------------------------------------------------
/// @brief      Default value is YES. Vsync client will pause vsync callback after receiving
///             a vsync signal. Setting this property to NO can avoid this and vsync client
///             will trigger vsync callback continuously.
///
///
/// @param allowPauseAfterVsync Allow vsync client to pause after receiving a vsync signal.
///
@property(nonatomic, assign) BOOL allowPauseAfterVsync;

- (instancetype)initWithTaskRunner:(fml::RefPtr<fml::TaskRunner>)task_runner
                          callback:(flutter::VsyncWaiter::Callback)callback;

- (void)await;

- (void)pause;

- (void)invalidate;

- (double)getRefreshRate;

- (void)setMaxRefreshRate:(double)refreshRate;

@end

namespace flutter {

class VsyncWaiterIOS final : public VsyncWaiter, public VariableRefreshRateReporter {
 public:
  explicit VsyncWaiterIOS(const flutter::TaskRunners& task_runners);

  ~VsyncWaiterIOS() override;

  // |VariableRefreshRateReporter|
  double GetRefreshRate() const override;

  // Made public for testing.
  fml::scoped_nsobject<VSyncClient> GetVsyncClient() const;

  // |VsyncWaiter|
  // Made public for testing.
  void AwaitVSync() override;

 private:
  fml::scoped_nsobject<VSyncClient> client_;
  double max_refresh_rate_;

  FML_DISALLOW_COPY_AND_ASSIGN(VsyncWaiterIOS);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_VSYNC_WAITER_IOS_H_
