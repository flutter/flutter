// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFMLTaskRunners.h"

#include <memory>

#include "flutter/common/task_runners.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFMLTaskRunner+FML.h"

@interface FlutterFMLTaskRunners () {
  std::unique_ptr<flutter::TaskRunners> _taskRunners;
}
@end

@implementation FlutterFMLTaskRunners

- (instancetype)initWithLabel:(nonnull NSString*)label
           platformTaskRunner:(nonnull FlutterFMLTaskRunner*)platformTaskRunner
             rasterTaskRunner:(nonnull FlutterFMLTaskRunner*)rasterTaskRunner
                 uiTaskRunner:(nonnull FlutterFMLTaskRunner*)uiTaskRunner
                 ioTaskRunner:(nonnull FlutterFMLTaskRunner*)ioTaskRunner {
  self = [super init];
  if (self) {
    _label = label;
    _platformTaskRunner = platformTaskRunner;
    _rasterTaskRunner = rasterTaskRunner;
    _uiTaskRunner = uiTaskRunner;
    _ioTaskRunner = ioTaskRunner;

    _taskRunners = std::make_unique<flutter::TaskRunners>(
        label.UTF8String, platformTaskRunner.taskRunner, rasterTaskRunner.taskRunner,
        uiTaskRunner.taskRunner, ioTaskRunner.taskRunner);
  }
  return self;
}

- (const flutter::TaskRunners&)taskRunners {
  return *_taskRunners;
}

@end
