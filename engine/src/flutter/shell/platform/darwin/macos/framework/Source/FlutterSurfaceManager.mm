// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterSurfaceManager.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterFrameBufferProvider.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterIOSurfaceHolder.h"

#include <OpenGL/gl.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/MacOSGLContextSwitch.h"

enum {
  kFlutterSurfaceManagerFrontBuffer = 0,
  kFlutterSurfaceManagerBackBuffer = 1,
  kFlutterSurfaceManagerBufferCount,
};

@interface FlutterSurfaceManager () {
  CGSize _surfaceSize;
  CALayer* _containingLayer;  // provided (parent layer)
  CALayer* _contentLayer;

  NSOpenGLContext* _openGLContext;

  FlutterIOSurfaceHolder* _ioSurfaces[kFlutterSurfaceManagerBufferCount];
  FlutterFrameBufferProvider* _frameBuffers[kFlutterSurfaceManagerBufferCount];
}
@end

@implementation FlutterSurfaceManager

- (instancetype)initWithLayer:(CALayer*)containingLayer
                openGLContext:(NSOpenGLContext*)openGLContext {
  if (self = [super init]) {
    _containingLayer = containingLayer;
    _openGLContext = openGLContext;

    // Layer for content. This is separate from provided layer, because it needs to be flipped
    // vertically if we render to OpenGL texture
    _contentLayer = [[CALayer alloc] init];
    [_containingLayer addSublayer:_contentLayer];

    _frameBuffers[0] = [[FlutterFrameBufferProvider alloc] initWithOpenGLContext:_openGLContext];
    _frameBuffers[1] = [[FlutterFrameBufferProvider alloc] initWithOpenGLContext:_openGLContext];

    _ioSurfaces[0] = [FlutterIOSurfaceHolder alloc];
    _ioSurfaces[1] = [FlutterIOSurfaceHolder alloc];
  }
  return self;
}

- (void)ensureSurfaceSize:(CGSize)size {
  if (CGSizeEqualToSize(size, _surfaceSize)) {
    return;
  }
  _surfaceSize = size;

  MacOSGLContextSwitch context_switch(_openGLContext);

  for (int i = 0; i < kFlutterSurfaceManagerBufferCount; ++i) {
    [_ioSurfaces[i] recreateIOSurfaceWithSize:size];

    GLuint fbo = [_frameBuffers[i] glFrameBufferId];
    GLuint texture = [_frameBuffers[i] glTextureId];
    [_ioSurfaces[i] bindSurfaceToTexture:texture fbo:fbo size:size];
  }
}

- (void)swapBuffers {
  _contentLayer.frame = _containingLayer.bounds;

  // The surface is an OpenGL texture, which means it has origin in bottom left corner
  // and needs to be flipped vertically
  _contentLayer.transform = CATransform3DMakeScale(1, -1, 1);
  IOSurfaceRef contentIOSurface = [_ioSurfaces[kFlutterSurfaceManagerBackBuffer] ioSurface];
  [_contentLayer setContents:(__bridge id)contentIOSurface];

  std::swap(_ioSurfaces[kFlutterSurfaceManagerBackBuffer],
            _ioSurfaces[kFlutterSurfaceManagerFrontBuffer]);
  std::swap(_frameBuffers[kFlutterSurfaceManagerBackBuffer],
            _frameBuffers[kFlutterSurfaceManagerFrontBuffer]);
}

- (uint32_t)glFrameBufferId {
  return [_frameBuffers[kFlutterSurfaceManagerBackBuffer] glFrameBufferId];
}

@end
