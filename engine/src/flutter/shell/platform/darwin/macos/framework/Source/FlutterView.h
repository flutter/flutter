// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterSurfaceManager.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterThreadSynchronizer.h"

#include <stdint.h>

typedef int64_t FlutterViewId;

/**
 * The view ID for APIs that don't support multi-view.
 *
 * Some single-view APIs will eventually be replaced by their multi-view
 * variant. During the deprecation period, the single-view APIs will coexist with
 * and work with the multi-view APIs as if the other views don't exist.  For
 * backward compatibility, single-view APIs will always operate on the view with
 * this ID. Also, the first view assigned to the engine will also have this ID.
 */
constexpr FlutterViewId kFlutterImplicitViewId = 0ll;

/**
 * Delegate for FlutterView.
 */
@protocol FlutterViewDelegate <NSObject>
/**
 * Called when the view's backing store changes size.
 */
- (void)viewDidReshape:(nonnull NSView*)view;

/**
 * Called to determine whether the view should accept first responder status.
 */
- (BOOL)viewShouldAcceptFirstResponder:(nonnull NSView*)view;

@end

/**
 * View capable of acting as a rendering target and input source for the Flutter
 * engine.
 */
@interface FlutterView : NSView

/**
 * Initialize a FlutterView that will be rendered to using Metal rendering apis.
 */
- (nullable instancetype)initWithMTLDevice:(nonnull id<MTLDevice>)device
                              commandQueue:(nonnull id<MTLCommandQueue>)commandQueue
                                  delegate:(nonnull id<FlutterViewDelegate>)delegate
                        threadSynchronizer:(nonnull FlutterThreadSynchronizer*)threadSynchronizer
                                    viewId:(int64_t)viewId NS_DESIGNATED_INITIALIZER;

- (nullable instancetype)initWithFrame:(NSRect)frameRect
                           pixelFormat:(nullable NSOpenGLPixelFormat*)format NS_UNAVAILABLE;
- (nonnull instancetype)initWithFrame:(NSRect)frameRect NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(nonnull NSCoder*)coder NS_UNAVAILABLE;
- (nonnull instancetype)init NS_UNAVAILABLE;

/**
 * Returns SurfaceManager for this view. SurfaceManager is responsible for
 * providing and presenting render surfaces.
 */
@property(readonly, nonatomic, nonnull) FlutterSurfaceManager* surfaceManager;

/**
 * By default, the `FlutterSurfaceManager` creates two layers to manage Flutter
 * content, the content layer and containing layer. To set the native background
 * color, onto which the Flutter content is drawn, call this method with the
 * NSColor which you would like to override the default, black background color
 * with.
 */
- (void)setBackgroundColor:(nonnull NSColor*)color;

@end
