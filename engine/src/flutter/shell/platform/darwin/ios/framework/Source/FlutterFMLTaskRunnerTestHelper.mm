// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFMLTaskRunnerTestHelper.h"

#include "flutter/fml/message_loop.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFMLTaskRunner+FML.h"

@implementation FlutterFMLTaskRunnerTestHelper

+ (FlutterFMLTaskRunner*)makeCurrentThreadTaskRunner {
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  return [[FlutterFMLTaskRunner alloc]
      initWithTaskRunner:fml::MessageLoop::GetCurrent().GetTaskRunner()];
}

+ (FlutterFMLTaskRunners*)makeTaskRunnersWithLabel:(NSString*)label
                                        taskRunner:(FlutterFMLTaskRunner*)taskRunner {
  return [[FlutterFMLTaskRunners alloc] initWithLabel:label
                                   platformTaskRunner:taskRunner
                                     rasterTaskRunner:taskRunner
                                         uiTaskRunner:taskRunner
                                         ioTaskRunner:taskRunner];
}

@end
