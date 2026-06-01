// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERFMLTASKRUNNER_FML_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERFMLTASKRUNNER_FML_H_

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFMLTaskRunner.h"

#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/fml/task_runner.h"

@interface FlutterFMLTaskRunner ()

- (instancetype)initWithTaskRunner:(fml::RefPtr<fml::TaskRunner>)task_runner;

- (fml::RefPtr<fml::TaskRunner>)taskRunner;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERFMLTASKRUNNER_FML_H_
