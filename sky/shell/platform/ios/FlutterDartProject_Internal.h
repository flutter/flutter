// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/ios/public/FlutterDartProject.h"

#include "sky/services/engine/sky_engine.mojom.h"

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
