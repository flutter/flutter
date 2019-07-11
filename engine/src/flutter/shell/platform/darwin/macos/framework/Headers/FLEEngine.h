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
 * @param labelPrefix Currently unused; in the future, may be used for labelling threads
 *                    as with the iOS FlutterEngine.
 * @param project The project configuration. If nil, a default FLEDartProject will be used.
 */
- (nonnull instancetype)initWithName:(nonnull NSString*)labelPrefix
                             project:(nullable FLEDartProject*)project;

/**
 * Initializes an engine with the given viewController.
 *
 * @param labelPrefix Currently unused; in the future, may be used for labelling threads
 *                    as with the iOS FlutterEngine.
 * @param project The project configuration. If nil, a default FLEDartProject will be used.
 */
- (nonnull instancetype)initWithName:(nonnull NSString*)labelPrefix
                             project:(nullable FLEDartProject*)project
              allowHeadlessExecution:(BOOL)allowHeadlessExecution NS_DESIGNATED_INITIALIZER;

- (nonnull instancetype)init NS_UNAVAILABLE;

/**
 * Runs a Dart program on an Isolate from the main Dart library (i.e. the library that
 * contains `main()`).
 *
 * The first call to this method will create a new Isolate. Subsequent calls will return
 * immediately.
 *
 * @param entrypoint The name of a top-level function from the same Dart
 *   library that contains the app's main() function.  If this is nil, it will
 *   default to `main()`.  If it is not the app's main() function, that function
 *   must be decorated with `@pragma(vm:entry-point)` to ensure the method is not
 *   tree-shaken by the Dart compiler.
 * @return YES if the call succeeds in creating and running a Flutter Engine instance; NO otherwise.
 */
- (BOOL)runWithEntrypoint:(nullable NSString*)entrypoint;

/**
 * The `FLEViewController` associated with this engine, if any.
 */
@property(nonatomic, nullable, weak) FLEViewController* viewController;

/**
 * The `FlutterBinaryMessenger` for communicating with this engine.
 */
@property(nonatomic, nonnull, readonly) id<FlutterBinaryMessenger> binaryMessenger;

@end

#endif  // FLUTTER_FLEENGINE_H_
