// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterIOSurfaceHolder.h"

@interface FlutterIOSurfaceHolder () {
  IOSurfaceRef _ioSurface;
}
@end

@implementation FlutterIOSurfaceHolder

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
