// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERVIEWCONTROLLER_INTERNAL_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERVIEWCONTROLLER_INTERNAL_H_

#include "flutter/shell/common/shell.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"

@interface FlutterViewController ()

- (shell::Shell&)shell;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERVIEWCONTROLLER_INTERNAL_H_
