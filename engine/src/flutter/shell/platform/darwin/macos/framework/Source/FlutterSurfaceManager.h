// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CAMetalLayer.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterBackingStore.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterIOSurfaceHolder.h"

/**
 * Manages render surfaces and corresponding backing stores used by the engine.
 *
 * The backing store when rendering with on Metal is a Metal texture. There are two IOSurfaces
 * created during initialization, FlutterSurfaceManager manages the lifecycle of these.
 */
@interface FlutterSurfaceManager : NSObject

/**
 * Initializes and returns a surface manager that renders to a child layer (referred to as the
 * content layer) of the containing layer and applies the transform to the contents of the content
 * layer.
 */
- (nullable instancetype)initWithDevice:(nonnull id<MTLDevice>)device
                           commandQueue:(nonnull id<MTLCommandQueue>)commandQueue
                                  layer:(nonnull CALayer*)containingLayer;

/**
 * Updates the backing store size of the managed IOSurfaces the specified size. If the surfaces are
 * already of this size, this is a no-op.
 */
- (void)ensureSurfaceSize:(CGSize)size;

/**
 * Swaps the front and the back buffer.
 */
- (void)swapBuffers;

/**
 * Returns the backing store for the back buffer.
 */
- (nonnull FlutterRenderBackingStore*)renderBuffer;

@end
