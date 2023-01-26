// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterViewController.h"

#import "flutter/shell/platform/darwin/macos/framework/Source/AccessibilityBridgeMac.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterKeyboardViewDelegate.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterTextInputPlugin.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterView.h"

@interface FlutterViewController () <FlutterKeyboardViewDelegate>

// The FlutterView for this view controller.
@property(nonatomic, readonly, nullable) FlutterView* flutterView;

/**
 * The text input plugin that handles text editing state for text fields.
 */
@property(nonatomic, readonly, nonnull) FlutterTextInputPlugin* textInputPlugin;

/**
 * Returns YES if provided event is being currently redispatched by keyboard manager.
 */
- (BOOL)isDispatchingKeyEvent:(nonnull NSEvent*)event;

/**
 * Set the `engine` and `id` of this controller.
 *
 * This method is called by FlutterEngine.
 */
- (void)attachToEngine:(nonnull FlutterEngine*)engine withId:(uint64_t)viewId;

/**
 * Reset the `engine` and `id` of this controller.
 *
 * This method is called by FlutterEngine.
 */
- (void)detachFromEngine;

@end

// Private methods made visible for testing
@interface FlutterViewController (TestMethods)
- (void)onAccessibilityStatusChanged:(BOOL)enabled;

- (nonnull FlutterView*)createFlutterViewWithMTLDevice:(nonnull id<MTLDevice>)device
                                          commandQueue:(nonnull id<MTLCommandQueue>)commandQueue;

@end
