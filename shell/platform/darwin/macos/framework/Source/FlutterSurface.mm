// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterSurface.h"

#import <Metal/Metal.h>

@interface FlutterSurface () {
  CGSize _size;
  IOSurfaceRef _ioSurface;
  id<MTLTexture> _texture;
}
@end

@implementation FlutterSurface

- (IOSurfaceRef)ioSurface {
  return _ioSurface;
}

- (CGSize)size {
  return _size;
}

- (int64_t)textureId {
  return reinterpret_cast<int64_t>(_texture);
}

- (instancetype)initWithSize:(CGSize)size device:(id<MTLDevice>)device {
  if (self = [super init]) {
    self->_size = size;
    self->_ioSurface = [FlutterSurface createIOSurfaceWithSize:size];
    self->_texture = [FlutterSurface createTextureForIOSurface:_ioSurface size:size device:device];
  }
  return self;
}

static void ReleaseSurface(void* surface) {
  if (surface != nullptr) {
    CFBridgingRelease(surface);
  }
}

- (FlutterMetalTexture)asFlutterMetalTexture {
  FlutterMetalTexture res;
  memset(&res, 0, sizeof(FlutterMetalTexture));
  res.struct_size = sizeof(FlutterMetalTexture);
  res.texture = (__bridge void*)_texture;
  res.texture_id = self.textureId;
  res.user_data = (void*)CFBridgingRetain(self);
  res.destruction_callback = ReleaseSurface;
  return res;
}

+ (FlutterSurface*)fromFlutterMetalTexture:(const FlutterMetalTexture*)texture {
  return (__bridge FlutterSurface*)texture->user_data;
}

- (void)dealloc {
  CFRelease(_ioSurface);
}

+ (IOSurfaceRef)createIOSurfaceWithSize:(CGSize)size {
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

  IOSurfaceRef res = IOSurfaceCreate((CFDictionaryRef)options);
  IOSurfaceSetValue(res, CFSTR("IOSurfaceColorSpace"), kCGColorSpaceSRGB);
  return res;
}

+ (id<MTLTexture>)createTextureForIOSurface:(IOSurfaceRef)surface
                                       size:(CGSize)size
                                     device:(id<MTLDevice>)device {
  MTLTextureDescriptor* textureDescriptor =
      [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                         width:size.width
                                                        height:size.height
                                                     mipmapped:NO];
  textureDescriptor.usage =
      MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget | MTLTextureUsageShaderWrite;
  // plane = 0 for BGRA.
  return [device newTextureWithDescriptor:textureDescriptor iosurface:surface plane:0];
}

@end
