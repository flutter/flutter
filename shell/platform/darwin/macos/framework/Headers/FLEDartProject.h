// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLEDARTPROJECT_H_
#define FLUTTER_FLEDARTPROJECT_H_

#import <Foundation/Foundation.h>

#include "FlutterMacros.h"

/**
 * A set of Flutter and Dart assets used by a `FlutterEngine` to initialize execution.
 *
 * TODO(stuartmorgan): Align API with FlutterDartProject.
 */
FLUTTER_EXPORT
@interface FLEDartProject : NSObject

/**
 * Initializes a Flutter Dart project from a bundle.
 *
 * The bundle must either contain a flutter_assets resource directory, or set the Info.plist key
 * FLTAssetsPath to override that name (if you are doing a custom build using a different name).
 *
 * @param bundle The bundle containing the Flutter assets directory. If nil, the main bundle is
 *               used.
 */
- (nonnull instancetype)initWithBundle:(nullable NSBundle*)bundle NS_DESIGNATED_INITIALIZER;

/**
 * Switches to pass to the Flutter engine. See
 * https://github.com/flutter/engine/blob/master/shell/common/switches.h
 * for details. Not all switches will apply to embedding mode.
 *
 * Note: This property is likely to be removed in the future in favor of exposing specific switches
 * via their own APIs.
 */
@property(nullable) NSArray<NSString*>* engineSwitches;

@end

#endif  // FLUTTER_FLEDARTPROJECT_H_
