// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERENGINE_TASKRUNNERS_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERENGINE_TASKRUNNERS_H_

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngine.h"

@class FlutterFMLTaskRunner;

@interface FlutterEngine (TaskRunners)

- (nullable FlutterFMLTaskRunner*)platformTaskRunner;
- (nullable FlutterFMLTaskRunner*)uiTaskRunner;
- (nullable FlutterFMLTaskRunner*)rasterTaskRunner;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERENGINE_TASKRUNNERS_H_
