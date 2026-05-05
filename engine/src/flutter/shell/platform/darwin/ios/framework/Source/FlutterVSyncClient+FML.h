// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERVSYNCCLIENT_FML_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERVSYNCCLIENT_FML_H_

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterVSyncClient.h"

#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/fml/task_runner.h"
#include "flutter/shell/common/vsync_waiter.h"

@interface FlutterVSyncClient ()

//------------------------------------------------------------------------------
/// @brief      Initializes the vsync client with a C++ task runner and task callback.
///             This is for backward-compatibility and should not be used in new code.
///
/// @param      task_runner                  The C++ task runner to use for posting tasks.
/// @param      isVariableRefreshRateEnabled Whether variable refresh rate should be enabled.
/// @param      maxRefreshRate               The maximum refresh rate to configure the display link
///                                          with.
/// @param      callback                     The C++ callback to invoke when a vsync signal is
/// received.
///
- (instancetype)initWithTaskRunnerPtr:(fml::RefPtr<fml::TaskRunner>)task_runner
         isVariableRefreshRateEnabled:(BOOL)isVariableRefreshRateEnabled
                       maxRefreshRate:(double)maxRefreshRate
                             callback:(flutter::VsyncWaiter::Callback)callback;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERVSYNCCLIENT_FML_H_
