// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

#import "FlutterChannels.h"
#import "FlutterCodecs.h"
#import "FlutterMacros.h"

// TODO: Merge this file and FlutterPluginRegistrarMacOS.h with the iOS FlutterPlugin.h, sharing
// all but the platform-specific methods.

@protocol FlutterPluginRegistrar;

/**
 * Implemented by the platform side of a Flutter plugin.
 *
 * Defines a set of optional callback methods and a method to set up the plugin
 * and register it to be called by other application components.
 *
 * Currently the macOS version of FlutterPlugin has very limited functionality, but is expected to
 * expand over time to more closely match the functionality of the iOS FlutterPlugin.
 */
FLUTTER_DARWIN_EXPORT
@protocol FlutterPlugin <NSObject>

/**
 * Creates an instance of the plugin to register with |registrar| using the desired
 * FlutterPluginRegistrar methods.
 */
+ (void)registerWithRegistrar:(nonnull id<FlutterPluginRegistrar>)registrar;

@optional

/**
 * Called when a message is sent from Flutter on a channel that a plugin instance has subscribed
 * to via -[FlutterPluginRegistrar addMethodCallDelegate:channel:].
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
