// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterEngine.h"

#import <Cocoa/Cocoa.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterRenderer.h"
#include "flutter/shell/platform/embedder/embedder.h"

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

/**
 * Informs the engine that the associated view controller's view size has changed.
 */
- (void)updateWindowMetrics;

/**
 * Dispatches the given pointer event data to engine.
 */
- (void)sendPointerEvent:(const FlutterPointerEvent&)event;

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

@end
