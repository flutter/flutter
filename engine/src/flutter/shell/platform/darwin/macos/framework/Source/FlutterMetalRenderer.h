// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterRenderer.h"

/**
 * Provides the renderer config needed to initialize the embedder engine. This is initialized during
 * FlutterEngine creation and then attached to the FlutterView once the FlutterViewController is
 * initialized.
 */
@interface FlutterMetalRenderer : FlutterTextureRegistrar <FlutterRenderer>

/**
 * Interface to the system GPU. Used to issue all the rendering commands.
 */
@property(nonatomic, readonly, nonnull) id<MTLDevice> device;

/**
 * Used to get the command buffers for the MTLDevice to render to.
 */
@property(nonatomic, readonly, nonnull) id<MTLCommandQueue> commandQueue;

/**
 * Creates a Metal texture for the given size.
 */
- (FlutterMetalTexture)createTextureForSize:(CGSize)size;

/**
 * Presents the texture specified by the texture id.
 */
- (BOOL)present:(int64_t)textureID;

/**
 * Populates the texture registry with the provided metalTexture.
 */
- (BOOL)populateTextureWithIdentifier:(int64_t)textureID
                         metalTexture:(nonnull FlutterMetalExternalTexture*)metalTexture;

@end
