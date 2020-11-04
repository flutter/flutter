// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

@class FlutterResizeSynchronizer;

/**
 * Implemented by FlutterView.
 */
@protocol FlutterResizeSynchronizerDelegate

/**
 * Invoked on raster thread; Delegate should flush the OpenGL context.
 */
- (void)resizeSynchronizerFlush:(nonnull FlutterResizeSynchronizer*)synchronizer;

/**
 * Invoked on platform thread; Delegate should flip the surfaces.
 */
- (void)resizeSynchronizerCommit:(nonnull FlutterResizeSynchronizer*)synchronizer;

@end

/**
 * Encapsulates the logic for blocking platform thread during window resize as
 * well as synchronizing the raster and platform thread during commit (presenting frame).
 *
 * Flow during window resize
 *
 * 1. Platform thread calls [synchronizer beginResize:notify:]
 *    This will hold the platform thread until we're ready to display contents.
 * 2. Raster thread calls [synchronizer shouldEnsureSurfaceForSize:] with target size
 *    This will return false for any size other than target size
 * 3. Raster thread calls [synchronizer requestCommit]
 *    Any commit calls before shouldEnsureSurfaceForSize: is called with the right
 *    size are simply ignored; There's no point rasterizing and displaying frames
 *    with wrong size.
 * Both delegate methods (flush/commit) will be invoked before beginResize returns
 *
 * Flow during regular operation (no resizing)
 *
 * 1. Raster thread calls [synchronizer requestCommit]
 *    This will invoke [delegate flush:] on raster thread and
 *    [delegate commit:] on platform thread. The requestCommit call will be blocked
 *    until this is done. This is necessary to ensure that rasterizer won't start
 *    rasterizing next frame before we flipped the surface, which must be performed
 *    on platform thread
 */
@interface FlutterResizeSynchronizer : NSObject

- (nullable instancetype)initWithDelegate:(nonnull id<FlutterResizeSynchronizerDelegate>)delegate;

/**
 * Blocks the platform thread until
 * - shouldEnsureSurfaceForSize is called with proper size and
 * - requestCommit is called
 * All requestCommit calls before `shouldEnsureSurfaceForSize` is called with
 * expected size are ignored;
 * The notify block is invoked immediately after synchronizer mutex is acquired.
 */
- (void)beginResize:(CGSize)size notify:(nonnull dispatch_block_t)notify;

/**
 * Returns whether the view should ensure surfaces with given size;
 * This will be false during resizing for any size other than size specified
 * during beginResize.
 */
- (BOOL)shouldEnsureSurfaceForSize:(CGSize)size;

/**
 * Called from rasterizer thread, will block until delegate resizeSynchronizerCommit:
 * method is called (on platform thread).
 */
- (void)requestCommit;

@end
