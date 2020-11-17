// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterEngine.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterView.h"
#import "flutter/shell/platform/embedder/embedder.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Provides the renderer config needed to initialize the embedder engine and also handles external
 * texture management. This is initialized during FlutterEngine creation and then attached to the
 * FlutterView once the FlutterViewController is initializer.
 */
@interface FlutterOpenGLRenderer : NSObject <FlutterTextureRegistry>

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
 * Intializes the renderer with the given FlutterEngine.
 */
- (instancetype)initWithFlutterEngine:(FLUTTER_API_SYMBOL(FlutterEngine))engine;

/**
 * Attaches to the FlutterView and sets up the renderers main OpenGL context.
 */
- (void)attachToFlutterView:(FlutterView*)view;

/**
 * Called by the engine to make the context the engine should draw into current.
 */
- (bool)makeCurrent;

/**
 * Called by the engine to clear the context the engine should draw into.
 */
- (bool)clearCurrent;

/**
 * Called by the engine when the context's buffers should be swapped.
 */
- (bool)present;

/**
 * Called by the engine when framebuffer object ID is requested.
 */
- (uint32_t)getFBO:(const FlutterFrameInfo*)info;

/**
 * Makes the resource context the current context.
 */
- (bool)makeResourceCurrent;

/**
 * Called by the engine to unset the resource context.
 */
- (void)clearResourceContext;

/**
 * Populates the texture registry with the provided openGLTexture.
 */
- (BOOL)populateTextureWithIdentifier:(int64_t)textureID
                        openGLTexture:(FlutterOpenGLTexture*)openGLTexture;

/**
 * Creates a FlutterRendererConfig that renders using OpenGL context(s) held
 * by this class.
 */
- (FlutterRendererConfig)createRendererConfig;

@end

NS_ASSUME_NONNULL_END
