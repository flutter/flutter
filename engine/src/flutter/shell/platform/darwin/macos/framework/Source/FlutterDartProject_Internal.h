// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_FLUTTERDARTPROJECT_INTERNAL_H_
#define SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_FLUTTERDARTPROJECT_INTERNAL_H_

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterDartProject.h"

#include <vector>

/**
 * Provides access to data needed to construct a FlutterProjectArgs for the project.
 */
@interface FlutterDartProject ()

/**
 * The path to the Flutter assets directory.
 */
@property(nonatomic, readonly, nullable) NSString* assetsPath;

/**
 * The path to the ICU data file.
 */
@property(nonatomic, readonly, nullable) NSString* ICUDataPath;

/**
 * The command line arguments array for the engine.
 *
 * WARNING: The pointers in this array are valid only until the next call to set `engineSwitches`.
 * The returned vector should be used immediately, then discarded. It is returned this way for
 * ease of use with FlutterProjectArgs.
 */
@property(nonatomic, readonly) std::vector<const char*> argv;

@end

#endif  // SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_FLUTTERDARTPROJECT_INTERNAL_H_
