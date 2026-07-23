// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERFMLTASKRUNNERTESTHELPER_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERFMLTASKRUNNERTESTHELPER_H_

#import <Foundation/Foundation.h>

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFMLTaskRunner.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFMLTaskRunners.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(TaskRunnerTestHelper)
@interface FlutterFMLTaskRunnerTestHelper : NSObject

/**
 * Returns a FlutterFMLTaskRunner for the current thread.
 */
+ (FlutterFMLTaskRunner*)makeCurrentThreadTaskRunner;

/**
 * Returns a FlutterFMLTaskRunner running on a new background thread with the given label.
 */
+ (FlutterFMLTaskRunner*)makeTaskRunnerWithLabel:(NSString*)label;

/**
 * Returns a FlutterFMLTaskRunners object where all runners point to the same task runner.
 */
+ (FlutterFMLTaskRunners*)makeTaskRunnersWithLabel:(NSString*)label
                                        taskRunner:(FlutterFMLTaskRunner*)taskRunner;

@end

NS_ASSUME_NONNULL_END

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERFMLTASKRUNNERTESTHELPER_H_
