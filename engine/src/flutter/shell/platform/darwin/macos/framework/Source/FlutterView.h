// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_FLUTTERVIEW_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_FLUTTERVIEW_H_

#import <Cocoa/Cocoa.h>

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterViewController.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterSurfaceManager.h"

#include <stdint.h>
#include <optional>

@class FlutterView;

/**
 * Interface that facilitates process of sizing the FlutterView to its
 * content. It is used to determine the content constraints and to notify
 * the view container about the size change so that the parent view can
 * be resized (and repositioned) accordingly.
 */
@protocol FlutterViewSizingDelegate <NSObject>

/**
 * When view should be sized to content, this method should return the minimum
 * logical size of the view.
 * For views that are not sized to content, will return std::nullopt;
 */
- (std::optional<NSSize>)minimumViewSize:(nonnull FlutterView*)view;

/**
 * When view should be sized to content, this method should return the maximum
 * logical size of the view.
 * For views that are not sized to content, this method should return std::nullopt.
 */
- (std::optional<NSSize>)maximumViewSize:(nonnull FlutterView*)view;

/**
 * Called when the view's size changes. The container should update its
 * layout to accommodate the new size.
 */
- (void)viewDidUpdateContents:(nonnull FlutterView*)view withSize:(NSSize)newSize;

@end

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
                            viewIdentifier:(FlutterViewIdentifier)viewIdentifier
                           enableWideGamut:(BOOL)enableWideGamut NS_DESIGNATED_INITIALIZER;

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
 * Optional sizing delegate. If set, the view can be sized to its content.
 */
@property(readwrite, nonatomic, weak, nullable) id<FlutterViewSizingDelegate> sizingDelegate;

/**
 * By default, the `FlutterSurfaceManager` creates two layers to manage Flutter
 * content, the content layer and containing layer. To set the native background
 * color, onto which the Flutter content is drawn, call this method with the
 * NSColor which you would like to override the default, black background color
 * with.
 */
- (void)setBackgroundColor:(nonnull NSColor*)color;

/**
 * Called from the engine to notify the view that mouse cursor was updated while
 * the mouse is over the view. The view is responsible from restoring the cursor
 * when the mouse enters the view from another subview.
 */
- (void)didUpdateMouseCursor:(nonnull NSCursor*)cursor;

/**
 * Called from the controller to unblock resize synchronizer when shutting down.
 */
- (void)shutDown;

/**
 * Whether this view is sized to contents. If so, resize synchronization
 * will be disabled.
 */
@property(nonatomic, readonly) BOOL sizedToContents;

/**
 * When sized to contents, this property returns the minimum content size.
 * If not sized to contents, this property returns NSZeroSize.
 */
@property(nonatomic, readonly) CGSize minimumContentSize;

/**
 * When sized to contents, this property returns the maximum content size.
 * If not sized to contents, this property returns NSZeroSize.
 */
@property(nonatomic, readonly) CGSize maximumContentSize;

/**
 * Informs the view that layout constraints have changed. The view should
 * send reconfigure event to the engine so that new content matches the constraints.
 */
- (void)constraintsDidChange;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_FLUTTERVIEW_H_
