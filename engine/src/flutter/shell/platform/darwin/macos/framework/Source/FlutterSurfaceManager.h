// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CAMetalLayer.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterBackingStore.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterIOSurfaceHolder.h"

/**
 * Manages the render surfaces and their corresponding backing stores.
 */
@protocol FlutterSurfaceManager

/**
 * Updates the backing store size of the managed IOSurfaces to `size`. If the surfaces are already
 * of the same size, this is a no-op.
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

/**
 * Methods for managing the IOSurfaces held by FlutterIOSurfaceManager.
 */
@protocol FlutterIOSurfaceManagerDelegate

/**
 * Tells the delegate that the front and back IOSurfaces are swapped.
 */
- (void)onSwapBuffers;

/**
 * Tells the delegate that the IOSurfaces have been resized. `bufferIndex` is to indicate the front
 * vs back buffer. `size` is the new size of the IOSurface.
 */
- (void)onUpdateSurface:(nonnull FlutterIOSurfaceHolder*)surface
            bufferIndex:(size_t)index
                   size:(CGSize)size;

/**
 * Tells the delegate that IOSurface with given index has been released. Delegate should free
 * all resources associated with the surface
 */
- (void)onSurfaceReleased:(size_t)index;

@end

/**
 * Manages IOSurfaces for the FlutterEngine to render to.
 *
 * The backing store when rendering with OpenGL is a frame buffer backed by a texture, on Metal its
 * a Metal texture. There are two IOSurfaces created during initialization, FlutterSurfaceManager
 * manages the lifecycle of these.
 */
@interface FlutterIOSurfaceManager : NSObject <FlutterSurfaceManager>

/**
 * The object that acts as the delegate for the FlutterIOSurfaceManager. See:
 * FlutterIOSurfaceManagerDelegate.
 */
@property(nullable, nonatomic, weak) id<FlutterIOSurfaceManagerDelegate> delegate;

/**
 * Initializes and returns an IOSurface manager that renders to a child layer (referred to as the
 * content layer) of the containing layer and applies the transform to the contents of the content
 * layer.
 */
- (nullable instancetype)initWithLayer:(nonnull CALayer*)containingLayer
                      contentTransform:(CATransform3D)transform;

@end

/**
 * FlutterSurfaceManager implementation where the IOSurfaces managed are backed by a frame buffers
 * which are bound to offscreen textures.
 */
@interface FlutterGLSurfaceManager : FlutterIOSurfaceManager <FlutterIOSurfaceManagerDelegate>

/**
 * Creates two IOSurfaces backed by frame buffers and their backing textures.
 */
- (nullable instancetype)initWithLayer:(nonnull CALayer*)containingLayer
                         openGLContext:(nonnull NSOpenGLContext*)openGLContext;

@end

/**
 * FlutterSurfaceManager implementation where the IOSurfaces managed are backed by a Metal textures.
 */
@interface FlutterMetalSurfaceManager : FlutterIOSurfaceManager <FlutterIOSurfaceManagerDelegate>

/**
 * Creates two IOSurfaces backed by Metal textures.
 */
- (nullable instancetype)initWithDevice:(nonnull id<MTLDevice>)device
                           commandQueue:(nonnull id<MTLCommandQueue>)commandQueue
                                  layer:(nonnull CALayer*)containingLayer;

@end
