// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFMLTaskRunner+FML.h"

#include <utility>

#include "flutter/fml/logging.h"

@implementation FlutterFMLTaskRunner {
  fml::RefPtr<fml::TaskRunner> _taskRunner;
}

- (instancetype)initWithTaskRunner:(fml::RefPtr<fml::TaskRunner>)task_runner {
  FML_DCHECK(task_runner);
  if (self = [super init]) {
    _taskRunner = std::move(task_runner);
  }
  return self;
}

- (void)postTask:(void (^)(void))task {
  FML_DCHECK(task);
  _taskRunner->PostTask([task]() { task(); });
}

- (void)runNowOrPostTask:(void (^)(void))task {
  FML_DCHECK(task);
  fml::TaskRunner::RunNowOrPostTask(_taskRunner, [task]() { task(); });
}

- (void)postTaskWithDelay:(NSTimeInterval)delay task:(void (^)(void))task {
  FML_DCHECK(task);
  _taskRunner->PostDelayedTask([task]() { task(); }, fml::TimeDelta::FromSecondsF(delay));
}

- (BOOL)runsTasksOnCurrentThread {
  return _taskRunner->RunsTasksOnCurrentThread();
}

- (fml::RefPtr<fml::TaskRunner>)taskRunner {
  return _taskRunner;
}

@end
