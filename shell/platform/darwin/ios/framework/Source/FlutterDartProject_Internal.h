// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERDARTPROJECT_INTERNAL_H_
#define SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERDARTPROJECT_INTERNAL_H_

#include "flutter/shell/common/engine.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterDartProject.h"

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

- (void)launchInEngine:(shell::Engine*)engine
        embedderVMType:(VMType)type
                result:(LaunchResult)result;

- (void)launchInEngine:(shell::Engine*)engine
        withEntrypoint:(NSString*)entrypoint
        embedderVMType:(VMType)type
                result:(LaunchResult)result;

+ (NSString*)pathForFlutterAssetsFromBundle:(NSBundle*)bundle;

@end

#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERDARTPROJECT_INTERNAL_H_
