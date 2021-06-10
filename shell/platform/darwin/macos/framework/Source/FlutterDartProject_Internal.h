// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_FLUTTERDARTPROJECT_INTERNAL_H_
#define SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_FLUTTERDARTPROJECT_INTERNAL_H_

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterDartProject.h"

#include <string>
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
 */
@property(nonatomic, readonly) std::vector<std::string> switches;

/**
 * Instead of looking up the assets and ICU data path in the application bundle, this initializer
 * allows callers to create a Dart project with custom locations specified for the both.
 */
- (nonnull instancetype)initWithAssetsPath:(nonnull NSString*)assets
                               ICUDataPath:(nonnull NSString*)icuPath NS_DESIGNATED_INITIALIZER;

@end

#endif  // SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_FLUTTERDARTPROJECT_INTERNAL_H_
