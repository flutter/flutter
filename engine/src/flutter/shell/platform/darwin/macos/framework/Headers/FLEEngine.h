// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLEENGINE_H_
#define FLUTTER_FLEENGINE_H_

#import <Foundation/Foundation.h>

#include "FLEDartProject.h"
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
 * @param project The project configuration. If nil, a default FLEDartProject will be used.
 */
- (nonnull instancetype)initWithViewController:(nullable FLEViewController*)viewController
                                       project:(nullable FLEDartProject*)project
    NS_DESIGNATED_INITIALIZER;

/**
 * Runs `main()` from this engine's project.
 *
 * @return YES if the engine launched successfully.
 */
- (BOOL)run;

/**
 * The `FLEDartProject` associated with this engine. If nil, a default will be used for `run`.
 *
 * TODO(stuartmorgan): Remove this once FLEViewController takes the project as an initializer
 * argument. Blocked on currently needing to create it from a XIB due to the view issues
 * described in https://github.com/google/flutter-desktop-embedding/issues/10.
 */
@property(nonatomic, nullable) FLEDartProject* project;

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
