// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterIOSurfaceHolder.h"

#import <OpenGL/gl.h>

@interface FlutterIOSurfaceHolder () {
  IOSurfaceRef _ioSurface;
}
@end

@implementation FlutterIOSurfaceHolder

- (void)bindSurfaceToTexture:(GLuint)texture fbo:(GLuint)fbo size:(CGSize)size {
  [self recreateIOSurfaceWithSize:size];

  glBindTexture(GL_TEXTURE_RECTANGLE_ARB, texture);

  CGLTexImageIOSurface2D(CGLGetCurrentContext(), GL_TEXTURE_RECTANGLE_ARB, GL_RGBA, int(size.width),
                         int(size.height), GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, _ioSurface,
                         0 /* plane */);
  glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);

  glBindFramebuffer(GL_FRAMEBUFFER, fbo);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_RECTANGLE_ARB, texture,
                         0);

  NSAssert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE,
           @"Framebuffer status check failed");
}

- (void)recreateIOSurfaceWithSize:(CGSize)size {
  if (_ioSurface) {
    CFRelease(_ioSurface);
  }

  unsigned pixelFormat = 'BGRA';
  unsigned bytesPerElement = 4;

  size_t bytesPerRow = IOSurfaceAlignProperty(kIOSurfaceBytesPerRow, size.width * bytesPerElement);
  size_t totalBytes = IOSurfaceAlignProperty(kIOSurfaceAllocSize, size.height * bytesPerRow);
  NSDictionary* options = @{
    (id)kIOSurfaceWidth : @(size.width),
    (id)kIOSurfaceHeight : @(size.height),
    (id)kIOSurfacePixelFormat : @(pixelFormat),
    (id)kIOSurfaceBytesPerElement : @(bytesPerElement),
    (id)kIOSurfaceBytesPerRow : @(bytesPerRow),
    (id)kIOSurfaceAllocSize : @(totalBytes),
  };

  _ioSurface = IOSurfaceCreate((CFDictionaryRef)options);
  IOSurfaceSetValue(_ioSurface, CFSTR("IOSurfaceColorSpace"), kCGColorSpaceSRGB);
}

- (const IOSurfaceRef&)ioSurface {
  return _ioSurface;
}

- (void)dealloc {
  if (_ioSurface) {
    CFRelease(_ioSurface);
  }
}

@end
