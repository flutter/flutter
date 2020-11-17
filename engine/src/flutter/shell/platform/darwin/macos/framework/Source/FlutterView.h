// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

/**
 * Listener for view resizing.
 */
@protocol FlutterViewReshapeListener <NSObject>
/**
 * Called when the view's backing store changes size.
 */
- (void)viewDidReshape:(nonnull NSView*)view;
@end

/**
 * View capable of acting as a rendering target and input source for the Flutter
 * engine.
 */
@interface FlutterView : NSView

- (nullable instancetype)initWithFrame:(NSRect)frame
                           mainContext:(nonnull NSOpenGLContext*)mainContext
                       reshapeListener:(nonnull id<FlutterViewReshapeListener>)reshapeListener
    NS_DESIGNATED_INITIALIZER;

- (nullable instancetype)initWithMainContext:(nonnull NSOpenGLContext*)mainContext
                             reshapeListener:
                                 (nonnull id<FlutterViewReshapeListener>)reshapeListener;

- (nullable instancetype)initWithFrame:(NSRect)frameRect
                           pixelFormat:(nullable NSOpenGLPixelFormat*)format NS_UNAVAILABLE;
- (nonnull instancetype)initWithFrame:(NSRect)frameRect NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(nonnull NSCoder*)coder NS_UNAVAILABLE;
- (nonnull instancetype)init NS_UNAVAILABLE;

/**
 * Flushes the OpenGL context and flips the surfaces. Expected to be called on raster thread.
 */
- (void)present;

/**
 * Ensures that framebuffer with requested size exists and returns the ID. Expected to be called on
 * raster thread.
 */
- (int)frameBufferIDForSize:(CGSize)size;

@end
