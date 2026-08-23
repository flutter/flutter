// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWSTESTHELPER_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWSTESTHELPER_H_

#import <Foundation/Foundation.h>
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFMLTaskRunners.h"

@class FlutterPlatformViewsController;

namespace flutter {
namespace testing {

/**
 * Returns a task runner mapped to the current message loop on this thread.
 */
FlutterFMLTaskRunner* GetDefaultTaskRunner();

/**
 * Returns a task runners wrapper where all task runners map to the default test thread runner.
 */
FlutterFMLTaskRunners* CreateTestTaskRunners(NSString* label);

/**
 * Returns a FlutterPlatformViewsController pre-configured for testing with the default task runner.
 */
FlutterPlatformViewsController* CreateTestPlatformViewsController(NSString* label);

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWSTESTHELPER_H_
