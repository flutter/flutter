// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLEENGINE_H_
#define FLUTTER_FLEENGINE_H_

#import <Foundation/Foundation.h>

#include "FlutterBinaryMessenger.h"
#include "FlutterMacros.h"
#include "FlutterPluginRegistrarMacOS.h"

@class FLEViewController;

/**
 * Coordinates a single instance of execution of a Flutter engine.
 *
 * TODO(stuartmorgan): Finish aligning this (and ideally merging) with FlutterEngine. Currently
 * this is largely usable only as an implementation detail of FLEViewController.
 */
FLUTTER_EXPORT
@interface FLEEngine : NSObject <FlutterPluginRegistry>

/**
 * Initializes an engine with the given viewController.
 *
 * @param viewController The view controller associated with this engine. If nil, the engine
 *                       will be run headless.
 */
- (nonnull instancetype)initWithViewController:(nullable FLEViewController*)viewController;

/**
 * Launches the Flutter engine with the provided configuration.
 *
 * @param assets The path to the flutter_assets folder for the Flutter application to be run.
 * @param arguments Arguments to pass to the Flutter engine. See
 *                  https://github.com/flutter/engine/blob/master/shell/common/switches.h
 *                  for details. Not all arguments will apply to embedding mode.
 *                  Note: This API layer will abstract arguments in the future, instead of
 *                  providing a direct passthrough.
 * @return YES if the engine launched successfully.
 */
- (BOOL)launchEngineWithAssetsPath:(nonnull NSURL*)assets
              commandLineArguments:(nullable NSArray<NSString*>*)arguments;

/**
 * The `FLEViewController` associated with this engine, if any.
 */
@property(nonatomic, nullable, readonly, weak) FLEViewController* viewController;

/**
 * The `FlutterBinaryMessenger` for communicating with this engine.
 */
@property(nonatomic, nonnull, readonly) id<FlutterBinaryMessenger> binaryMessenger;

@end

#endif  // FLUTTER_FLEENGINE_H_
