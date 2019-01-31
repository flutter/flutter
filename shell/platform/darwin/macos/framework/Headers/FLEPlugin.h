// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

#if defined(FLUTTER_FRAMEWORK)
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterChannels.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterCodecs.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterMacros.h"
#else
#import "FlutterChannels.h"
#import "FlutterCodecs.h"
#import "FlutterMacros.h"
#endif

@protocol FLEPluginRegistrar;

/**
 * Implemented by the platform side of a Flutter plugin.
 *
 * Defines a set of optional callback methods and a method to set up the plugin
 * and register it to be called by other application components.
 *
 * Currently FLEPlugin has very limited functionality, but is expected to expand over time to
 * more closely match the functionality of FlutterPlugin.
 */
FLUTTER_EXPORT
@protocol FLEPlugin <NSObject>

/**
 * Creates an instance of the plugin to register with |registrar| using the desired
 * FLEPluginRegistrar methods.
 */
+ (void)registerWithRegistrar:(nonnull id<FLEPluginRegistrar>)registrar;

@optional

/**
 * Called when a message is sent from Flutter on a channel that a plugin instance has subscribed
 * to via -[FLEPluginRegistrar addMethodCallDelegate:channel:].
 *
 * The |result| callback must be called exactly once, with one of:
 * - FlutterMethodNotImplemented, if the method call is unknown.
 * - A FlutterError, if the method call was understood but there was a
 *   problem handling it.
 * - Any other value (including nil) to indicate success. The value will
 *   be returned to the Flutter caller, and must be serializable to JSON.
 */
- (void)handleMethodCall:(nonnull FlutterMethodCall*)call result:(nonnull FlutterResult)result;

@end
