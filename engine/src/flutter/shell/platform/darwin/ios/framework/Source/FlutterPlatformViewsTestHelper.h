// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTER_PLATFORM_VIEWS_TEST_HELPER_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTER_PLATFORM_VIEWS_TEST_HELPER_H_

#import <Foundation/Foundation.h>
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFMLTaskRunners.h"

@class FlutterPlatformViewsController;

namespace flutter {
namespace testing {
FlutterFMLTaskRunner* GetDefaultTaskRunner();
FlutterFMLTaskRunners* CreateTestTaskRunners(NSString* label);
FlutterPlatformViewsController* CreateTestPlatformViewsController(NSString* label);
}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTER_PLATFORM_VIEWS_TEST_HELPER_H_
