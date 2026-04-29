// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERFMLTASKRUNNER_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERFMLTASKRUNNER_H_

#import <Foundation/Foundation.h>

NS_SWIFT_NAME(TaskRunner)
@interface FlutterFMLTaskRunner : NSObject

- (void)postTask:(void (^)(void))task;
- (void)runNowOrPostTask:(void (^)(void))task;
- (void)postTaskWithDelay:(NSTimeInterval)delay
                     task:(void (^)(void))task NS_SWIFT_NAME(postTask(delay:task:));

- (BOOL)runsTasksOnCurrentThread;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERFMLTASKRUNNER_H_
