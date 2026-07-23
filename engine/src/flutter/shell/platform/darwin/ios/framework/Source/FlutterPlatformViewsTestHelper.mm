// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViewsTestHelper.h"
#include "flutter/fml/message_loop.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFMLTaskRunner+FML.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFMLTaskRunner.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViewsController.h"

namespace flutter {
namespace testing {

FlutterFMLTaskRunner* GetDefaultTaskRunner() {
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  return [[FlutterFMLTaskRunner alloc]
      initWithTaskRunner:fml::MessageLoop::GetCurrent().GetTaskRunner()];
}

FlutterFMLTaskRunners* CreateTestTaskRunners(NSString* label) {
  return [[FlutterFMLTaskRunners alloc] initWithLabel:label
                                   platformTaskRunner:GetDefaultTaskRunner()
                                     rasterTaskRunner:GetDefaultTaskRunner()
                                         uiTaskRunner:GetDefaultTaskRunner()
                                         ioTaskRunner:GetDefaultTaskRunner()];
}

FlutterPlatformViewsController* CreateTestPlatformViewsController(NSString* label) {
  FlutterPlatformViewsController* controller = [[FlutterPlatformViewsController alloc] init];
  controller.taskRunner = GetDefaultTaskRunner();
  return controller;
}

}  // namespace testing
}  // namespace flutter
