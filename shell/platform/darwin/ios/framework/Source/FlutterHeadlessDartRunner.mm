// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterHeadlessDartRunner.h"

#include <memory>

#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/common/null_platform_view.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterDartProject_Internal.h"

@interface FlutterHeadlessDartRunner ()
@end

@implementation FlutterHeadlessDartRunner {
  fml::scoped_nsprotocol<FlutterDartProject*> _dartProject;
  std::shared_ptr<shell::NullPlatformView> _platformView;
}

- (instancetype)init {
  _dartProject.reset([[FlutterDartProject alloc] initFromDefaultSourceForConfiguration]);
  _platformView = std::make_shared<shell::NullPlatformView>();
  _platformView->Attach();
  return self;
}

- (void)runWithEntrypoint:(NSString*)entrypoint {
  const enum VMType type = Dart_IsPrecompiledRuntime() ? VMTypePrecompilation : VMTypeInterpreter;
  [_dartProject launchInEngine:&_platformView->engine()
                withEntrypoint:entrypoint
                embedderVMType:type
                        result:^(BOOL success, NSString* message) {
                          if (!success)
                            NSLog(@"%@", message);
                        }];
}

@end
