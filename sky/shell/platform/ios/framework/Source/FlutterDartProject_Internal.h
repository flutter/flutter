// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERDARTPROJECT_INTERNAL_H_
#define SKY_SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERDARTPROJECT_INTERNAL_H_

#include "flutter/sky/shell/platform/ios/framework/Headers/FlutterDartProject.h"

#include "flutter/services/engine/sky_engine.mojom.h"

enum VMType {
  // An invalid VM configuration.
  VMTypeInvalid = 0,
  // VM can execute Dart code as an interpreter.
  VMTypeInterpreter,
  // VM can execute precompiled Dart code.
  VMTypePrecompilation,
};

typedef void (^LaunchResult)(BOOL success, NSString* message);

@interface FlutterDartProject ()

- (void)launchInEngine:(sky::SkyEnginePtr&)engine
        embedderVMType:(VMType)type
                result:(LaunchResult)result;

@end

#endif  // SKY_SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERDARTPROJECT_INTERNAL_H_
