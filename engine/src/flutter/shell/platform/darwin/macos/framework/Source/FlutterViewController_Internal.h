// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterViewController.h"

#include <memory>

#import "flutter/shell/platform/darwin/macos/framework/Source/AccessibilityBridgeMac.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterKeyboardViewDelegate.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterTextInputPlugin.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterView.h"

@interface FlutterViewController () <FlutterKeyboardViewDelegate>

/**
 * The identifier for this view controller.
 *
 * The ID is assigned by FlutterEngine when the view controller is attached.
 *
 * If the view controller is unattached (see FlutterViewController#attached),
 * reading this property throws an assertion.
 */
@property(nonatomic, readonly) uint64_t viewId;

// The FlutterView for this view controller.
@property(nonatomic, readonly, nullable) FlutterView* flutterView;

/**
 * The text input plugin that handles text editing state for text fields.
 */
@property(nonatomic, readonly, nonnull) FlutterTextInputPlugin* textInputPlugin;

@property(nonatomic, readonly) std::weak_ptr<flutter::AccessibilityBridgeMac> accessibilityBridge;

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

/**
 * Called by the associated FlutterEngine when FlutterEngine#semanticsEnabled
 * has changed.
 */
- (void)notifySemanticsEnabledChanged;

/**
 * Notify from the framework that the semantics for this view needs to be
 * updated.
 */
- (void)updateSemantics:(nonnull const FlutterSemanticsUpdate2*)update;

@end

// Private methods made visible for testing
@interface FlutterViewController (TestMethods)
- (void)onAccessibilityStatusChanged:(BOOL)enabled;

/* Creates an accessibility bridge with the provided parameters.
 *
 * By default this method calls AccessibilityBridgeMac's initializer. Exposing
 * this method allows unit tests to override.
 */
- (std::shared_ptr<flutter::AccessibilityBridgeMac>)createAccessibilityBridgeWithEngine:
    (nonnull FlutterEngine*)engine;

- (nonnull FlutterView*)createFlutterViewWithMTLDevice:(nonnull id<MTLDevice>)device
                                          commandQueue:(nonnull id<MTLCommandQueue>)commandQueue;

@end
