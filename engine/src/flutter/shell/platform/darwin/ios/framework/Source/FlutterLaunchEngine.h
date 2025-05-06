// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERLAUNCHENGINE_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERLAUNCHENGINE_H_

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngine.h"

@interface FlutterLaunchEngine : NSObject

@property(nonatomic, strong, nullable, readonly) FlutterEngine* engine;

- (nullable FlutterEngine*)grabEngine;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERLAUNCHENGINE_H_
