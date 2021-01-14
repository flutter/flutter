// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

/**
 * Creates framebuffers and their backing textures.
 */
@interface FlutterFrameBufferProvider : NSObject

- (nullable instancetype)initWithOpenGLContext:(nonnull const NSOpenGLContext*)openGLContext;

/**
 * Returns the id of the framebuffer.
 */
- (uint32_t)glFrameBufferId;

/**
 * Returns the id of the backing texture..
 */
- (uint32_t)glTextureId;

@end
