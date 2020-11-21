// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterSurfaceManager.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterFrameBufferProvider.h"

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

  IOSurfaceRef _ioSurface[kFlutterSurfaceManagerBufferCount];
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
    if (_ioSurface[i]) {
      CFRelease(_ioSurface[i]);
    }
    unsigned pixelFormat = 'BGRA';
    unsigned bytesPerElement = 4;

    size_t bytesPerRow =
        IOSurfaceAlignProperty(kIOSurfaceBytesPerRow, size.width * bytesPerElement);
    size_t totalBytes = IOSurfaceAlignProperty(kIOSurfaceAllocSize, size.height * bytesPerRow);
    NSDictionary* options = @{
      (id)kIOSurfaceWidth : @(size.width),
      (id)kIOSurfaceHeight : @(size.height),
      (id)kIOSurfacePixelFormat : @(pixelFormat),
      (id)kIOSurfaceBytesPerElement : @(bytesPerElement),
      (id)kIOSurfaceBytesPerRow : @(bytesPerRow),
      (id)kIOSurfaceAllocSize : @(totalBytes),
    };
    _ioSurface[i] = IOSurfaceCreate((CFDictionaryRef)options);

    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, [_frameBuffers[i] glTextureId]);

    CGLTexImageIOSurface2D(CGLGetCurrentContext(), GL_TEXTURE_RECTANGLE_ARB, GL_RGBA,
                           int(size.width), int(size.height), GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV,
                           _ioSurface[i], 0 /* plane */);
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);

    glBindFramebuffer(GL_FRAMEBUFFER, [_frameBuffers[i] glFrameBufferId]);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_RECTANGLE_ARB,
                           [_frameBuffers[i] glTextureId], 0);

    NSAssert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE,
             @"Framebuffer status check failed");
  }
}

- (void)swapBuffers {
  _contentLayer.frame = _containingLayer.bounds;

  // The surface is an OpenGL texture, which means it has origin in bottom left corner
  // and needs to be flipped vertically
  _contentLayer.transform = CATransform3DMakeScale(1, -1, 1);
  [_contentLayer setContents:(__bridge id)_ioSurface[kFlutterSurfaceManagerBackBuffer]];

  std::swap(_ioSurface[kFlutterSurfaceManagerBackBuffer],
            _ioSurface[kFlutterSurfaceManagerFrontBuffer]);
  std::swap(_frameBuffers[kFlutterSurfaceManagerBackBuffer],
            _frameBuffers[kFlutterSurfaceManagerFrontBuffer]);
}

- (uint32_t)glFrameBufferId {
  return [_frameBuffers[kFlutterSurfaceManagerBackBuffer] glFrameBufferId];
}

- (void)dealloc {
  for (int i = 0; i < kFlutterSurfaceManagerBufferCount; ++i) {
    if (_ioSurface[i]) {
      CFRelease(_ioSurface[i]);
    }
  }
}

@end
