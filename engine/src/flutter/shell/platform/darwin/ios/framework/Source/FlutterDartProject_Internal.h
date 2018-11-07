// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERDARTPROJECT_INTERNAL_H_
#define SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERDARTPROJECT_INTERNAL_H_

#include "flutter/common/settings.h"
#include "flutter/shell/common/engine.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterDartProject.h"

@interface FlutterDartProject ()

- (const blink::Settings&)settings;

- (shell::RunConfiguration)runConfiguration;
- (shell::RunConfiguration)runConfigurationForEntrypoint:(NSString*)entrypointOrNil;
- (shell::RunConfiguration)runConfigurationForEntrypoint:(NSString*)entrypointOrNil
                                            libraryOrNil:(NSString*)dartLibraryOrNil;

+ (NSString*)flutterAssetsName:(NSBundle*)bundle;

@end

#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERDARTPROJECT_INTERNAL_H_
