// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterRenderer.h"

/**
 * Provides the renderer config needed to initialize the embedder engine and also handles external
 * texture management. This is initialized during FlutterEngine creation and then attached to the
 * FlutterView once the FlutterViewController is initializer.
 */
@interface FlutterOpenGLRenderer : FlutterTextureRegistrar <FlutterRenderer>

/**
 * The resource context used by the engine for texture uploads. FlutterViews associated with this
 * engine should be created to share with this context.
 */
@property(nonatomic, readonly, nullable) NSOpenGLContext* resourceContext;

/**
 * The main OpenGL which will be used for rendering contents to the FlutterView.
 */
@property(readwrite, nonatomic, nonnull) NSOpenGLContext* openGLContext;

/**
 * Called by the engine to make the context the engine should draw into current.
 */
- (BOOL)makeCurrent;

/**
 * Called by the engine to clear the context the engine should draw into.
 */
- (BOOL)clearCurrent;

/**
 * Called by the engine when the context's buffers should be swapped.
 */
- (BOOL)glPresent;

/**
 * Called by the engine when framebuffer object ID is requested.
 */
- (uint32_t)fboForFrameInfo:(nonnull const FlutterFrameInfo*)info;

/**
 * Makes the resource context the current context.
 */
- (BOOL)makeResourceCurrent;

/**
 * Populates the texture registry with the provided openGLTexture.
 */
- (BOOL)populateTextureWithIdentifier:(int64_t)textureID
                        openGLTexture:(nonnull FlutterOpenGLTexture*)openGLTexture;

@end
