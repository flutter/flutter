// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterEngine.h"

#import <Cocoa/Cocoa.h>

#include <memory>

#include "flutter/shell/platform/common/accessibility_bridge.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterCompositor.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterPlatformViewController.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterRenderer.h"

@interface FlutterEngine ()

/**
 * True if the engine is currently running.
 */
@property(nonatomic, readonly) BOOL running;

/**
 * Provides the renderer config needed to initialize the engine and also handles external
 * texture management.
 */
@property(nonatomic, readonly, nullable) id<FlutterRenderer> renderer;

/**
 * Function pointers for interacting with the embedder.h API.
 */
@property(nonatomic) FlutterEngineProcTable& embedderAPI;

@property(nonatomic, readonly) std::weak_ptr<flutter::AccessibilityBridge> accessibilityBridge;

/**
 * True if the semantics is enabled. The Flutter framework starts sending
 * semantics update through the embedder as soon as it is set to YES.
 */
@property(nonatomic) BOOL semanticsEnabled;

/**
 * The executable name for the current process.
 */
@property(nonatomic, readonly, nonnull) NSString* executableName;

/**
 * This just returns the NSPasteboard so that it can be mocked in the tests.
 */
@property(nonatomic, readonly, nonnull) NSPasteboard* pasteboard;

/**
 * Informs the engine that the associated view controller's view size has changed.
 */
- (void)updateWindowMetrics;

/**
 * Dispatches the given pointer event data to engine.
 */
- (void)sendPointerEvent:(const FlutterPointerEvent&)event;

/**
 * Dispatches the given pointer event data to engine.
 */
- (void)sendKeyEvent:(const FlutterKeyEvent&)event
            callback:(nullable FlutterKeyEventCallback)callback
            userData:(nullable void*)userData;

/**
 * Registers an external texture with the given id. Returns YES on success.
 */
- (BOOL)registerTextureWithID:(int64_t)textureId;

/**
 * Marks texture with the given id as available. Returns YES on success.
 */
- (BOOL)markTextureFrameAvailable:(int64_t)textureID;

/**
 * Unregisters an external texture with the given id. Returns YES on success.
 */
- (BOOL)unregisterTextureWithID:(int64_t)textureID;

- (nonnull FlutterPlatformViewController*)platformViewController;

// Accessibility API.

/**
 * Dispatches semantics action back to the framework. The semantics must be enabled by calling
 * the updateSemanticsEnabled before dispatching semantics actions.
 */
- (void)dispatchSemanticsAction:(FlutterSemanticsAction)action
                       toTarget:(uint16_t)target
                       withData:(fml::MallocMapping)data;

@end
