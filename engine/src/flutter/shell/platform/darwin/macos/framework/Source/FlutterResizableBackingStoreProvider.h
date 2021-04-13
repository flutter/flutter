// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterBackingStore.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterResizeSynchronizer.h"

/**
 * Represents a buffer that can be resized.
 */
@protocol FlutterResizableBackingStoreProvider <FlutterResizeSynchronizerDelegate>

/**
 * Notify of the required backing store size updates. Called during window resize.
 */
- (void)onBackingStoreResized:(CGSize)size;

/**
 * Returns the FlutterBackingStore corresponding to the latest size.
 */
- (nonnull FlutterRenderBackingStore*)backingStore;

@end

/**
 * OpenGL-backed FlutterResizableBackingStoreProvider. Backing store in this context implies a frame
 * buffer.
 */
@interface FlutterOpenGLResizableBackingStoreProvider
    : NSObject <FlutterResizableBackingStoreProvider>

/**
 * Creates a resizable backing store provider for the given CALayer.
 */
- (nonnull instancetype)initWithMainContext:(nonnull NSOpenGLContext*)mainContext
                                      layer:(nonnull CALayer*)layer;

@end

/**
 * Metal-backed FlutterResizableBackingStoreProvider. Backing store in this context implies a
 * MTLTexture.
 */
@interface FlutterMetalResizableBackingStoreProvider
    : NSObject <FlutterResizableBackingStoreProvider>

/**
 * Creates a resizable backing store provider for the given CAMetalLayer.
 */
- (nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device
                          commandQueue:(nonnull id<MTLCommandQueue>)commandQueue
                                 layer:(nonnull CALayer*)layer;

@end
