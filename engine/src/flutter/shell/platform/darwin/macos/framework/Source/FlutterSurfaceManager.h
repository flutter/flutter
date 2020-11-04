// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

// Manages the IOSurfaces for FlutterView
@interface FlutterSurfaceManager : NSObject

- (nullable instancetype)initWithLayer:(nonnull CALayer*)containingLayer
                         openGLContext:(nonnull NSOpenGLContext*)opengLContext;

- (void)ensureSurfaceSize:(CGSize)size;
- (void)swapBuffers;

- (uint32_t)glFrameBufferId;

@end
