// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERLAUNCHENGINE_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERLAUNCHENGINE_H_

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngine.h"

/**
 * A lazy container for an engine that will only dispense one engine.
 *
 * This is used to hold an engine for plugin registration when the
 * GeneratedPluginRegistrant is called on a FlutterAppDelegate before the first
 * FlutterViewController is set up. This is the typical flow after the
 * UISceneDelegate migration.
 *
 * The launch engine is intended to work only with first FlutterViewController
 * instantiated with a NIB since that is the only FlutterEngine that registers
 * plugins through the FlutterAppDelegate.
 */
@interface FlutterLaunchEngine : NSObject

/**
 * Accessor for the launch engine.
 *
 * Getting this may allocate an engine.
 */
@property(nonatomic, strong, nullable, readonly) FlutterEngine* engine;

/**
 * Take ownership of the launch engine.
 *
 * After this is called `self.engine` and `takeEngine` will always return nil.
 */
- (nullable FlutterEngine*)takeEngine;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERLAUNCHENGINE_H_
