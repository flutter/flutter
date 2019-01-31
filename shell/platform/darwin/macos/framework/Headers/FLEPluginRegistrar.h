// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

#import "FLEPlugin.h"

#if defined(FLUTTER_FRAMEWORK)
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterBinaryMessenger.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterChannels.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterMacros.h"
#else
#import "FlutterBinaryMessenger.h"
#import "FlutterChannels.h"
#import "FlutterMacros.h"
#endif

/**
 * The protocol for an object managing registration for a plugin. It provides access to application
 * context, as as allowing registering for callbacks for handling various conditions.
 *
 * Currently FLEPluginRegistrar has very limited functionality, but is expected to expand over time
 * to more closely match the functionality of FlutterPluginRegistrar.
 */
FLUTTER_EXPORT
@protocol FLEPluginRegistrar <NSObject>

/**
 * The binary messenger used for creating channels to communicate with the Flutter engine.
 */
@property(nonnull, readonly) id<FlutterBinaryMessenger> messenger;

/**
 * The view displaying Flutter content.
 *
 * WARNING: If/when multiple Flutter views within the same application are supported (#98), this
 * API will change.
 */
@property(nullable, readonly) NSView* view;

/**
 * Registers |delegate| to receive handleMethodCall:result: callbacks for the given |channel|.
 */
- (void)addMethodCallDelegate:(nonnull id<FLEPlugin>)delegate
                      channel:(nonnull FlutterMethodChannel*)channel;

@end
