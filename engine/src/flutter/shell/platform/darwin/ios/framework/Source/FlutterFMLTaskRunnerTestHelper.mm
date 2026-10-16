// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFMLTaskRunnerTestHelper.h"

#include <pthread/qos.h>

#include "flutter/fml/message_loop.h"
#include "flutter/fml/thread.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFMLTaskRunner+FML.h"

// Set the thread to user-interactive QoS to match the real value used in
// the actual embedder.
static void ConfigureThread(const fml::Thread::ThreadConfig& config) {
  fml::Thread::SetCurrentThreadName(config);
  pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0);
}

// A FlutterFMLTaskRunner that owns the fml::Thread it runs on.
@interface FlutterFMLThreadTaskRunner : FlutterFMLTaskRunner
@end

@implementation FlutterFMLThreadTaskRunner {
  std::unique_ptr<fml::Thread> _thread;
}

- (instancetype)initWithLabel:(NSString*)label {
  _thread = std::make_unique<fml::Thread>(ConfigureThread,
                                          fml::Thread::ThreadConfig(label ? label.UTF8String : ""));
  self = [super initWithTaskRunner:_thread->GetTaskRunner()];
  return self;
}

@end

@implementation FlutterFMLTaskRunnerTestHelper

+ (FlutterFMLTaskRunner*)makeCurrentThreadTaskRunner {
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  return [[FlutterFMLTaskRunner alloc]
      initWithTaskRunner:fml::MessageLoop::GetCurrent().GetTaskRunner()];
}

+ (FlutterFMLTaskRunner*)makeTaskRunnerWithLabel:(NSString*)label {
  return [[FlutterFMLThreadTaskRunner alloc] initWithLabel:label];
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
