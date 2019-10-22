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
@interface FlutterView : NSOpenGLView

- (nullable instancetype)initWithFrame:(NSRect)frame
                          shareContext:(nonnull NSOpenGLContext*)shareContext
                       reshapeListener:(nonnull id<FlutterViewReshapeListener>)reshapeListener
    NS_DESIGNATED_INITIALIZER;

- (nullable instancetype)initWithShareContext:(nonnull NSOpenGLContext*)shareContext
                              reshapeListener:
                                  (nonnull id<FlutterViewReshapeListener>)reshapeListener;

- (nullable instancetype)initWithFrame:(NSRect)frameRect
                           pixelFormat:(nullable NSOpenGLPixelFormat*)format NS_UNAVAILABLE;
- (nonnull instancetype)initWithFrame:(NSRect)frameRect NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(nonnull NSCoder*)coder NS_UNAVAILABLE;
- (nonnull instancetype)init NS_UNAVAILABLE;

@end
