// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterSurfaceManager.h"

#import <Metal/Metal.h>
#import <OpenGL/gl.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterFrameBufferProvider.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterIOSurfaceHolder.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/MacOSGLContextSwitch.h"

enum {
  kFlutterSurfaceManagerFrontBuffer = 0,
  kFlutterSurfaceManagerBackBuffer = 1,
  kFlutterSurfaceManagerBufferCount,
};

@implementation FlutterIOSurfaceManager {
  CALayer* _containingLayer;  // provided (parent layer)
  CALayer* _contentLayer;
  CATransform3D _contentTransform;

  CGSize _surfaceSize;
  FlutterIOSurfaceHolder* _ioSurfaces[kFlutterSurfaceManagerBufferCount];
}

- (instancetype)initWithLayer:(CALayer*)containingLayer contentTransform:(CATransform3D)transform {
  self = [super init];
  if (self) {
    _containingLayer = containingLayer;
    _contentTransform = transform;
    _contentLayer = [[CALayer alloc] init];
    [_containingLayer addSublayer:_contentLayer];

    _ioSurfaces[0] = [[FlutterIOSurfaceHolder alloc] init];
    _ioSurfaces[1] = [[FlutterIOSurfaceHolder alloc] init];
  }
  return self;
}

- (void)ensureSurfaceSize:(CGSize)size {
  if (CGSizeEqualToSize(size, _surfaceSize)) {
    return;
  }
  _surfaceSize = size;
  for (int i = 0; i < kFlutterSurfaceManagerBufferCount; ++i) {
    [_ioSurfaces[i] recreateIOSurfaceWithSize:size];
    [_delegate onUpdateSurface:_ioSurfaces[i] bufferIndex:i size:size];
  }
}

- (void)swapBuffers {
  _contentLayer.frame = _containingLayer.bounds;
  _contentLayer.transform = _contentTransform;
  IOSurfaceRef contentIOSurface = [_ioSurfaces[kFlutterSurfaceManagerBackBuffer] ioSurface];
  [_contentLayer setContents:(__bridge id)contentIOSurface];

  std::swap(_ioSurfaces[kFlutterSurfaceManagerBackBuffer],
            _ioSurfaces[kFlutterSurfaceManagerFrontBuffer]);
  [_delegate onSwapBuffers];
}

- (nonnull FlutterRenderBackingStore*)renderBuffer {
  @throw([NSException exceptionWithName:@"Sub-classes FlutterIOSurfaceManager of"
                                         " must override renderBuffer."
                                 reason:nil
                               userInfo:nil]);
}

@end

@implementation FlutterGLSurfaceManager {
  NSOpenGLContext* _openGLContext;

  FlutterFrameBufferProvider* _frameBuffers[kFlutterSurfaceManagerBufferCount];
}

- (instancetype)initWithLayer:(CALayer*)containingLayer
                openGLContext:(NSOpenGLContext*)openGLContext {
  self = [super initWithLayer:containingLayer contentTransform:CATransform3DMakeScale(1, -1, 1)];

  if (self) {
    super.delegate = self;
    _openGLContext = openGLContext;

    _frameBuffers[0] = [[FlutterFrameBufferProvider alloc] initWithOpenGLContext:_openGLContext];
    _frameBuffers[1] = [[FlutterFrameBufferProvider alloc] initWithOpenGLContext:_openGLContext];
  }
  return self;
}

- (FlutterRenderBackingStore*)renderBuffer {
  uint32_t fboID = [_frameBuffers[kFlutterSurfaceManagerBackBuffer] glFrameBufferId];
  return [[FlutterOpenGLRenderBackingStore alloc] initWithFrameBufferID:fboID];
}

- (void)onSwapBuffers {
  std::swap(_frameBuffers[kFlutterSurfaceManagerBackBuffer],
            _frameBuffers[kFlutterSurfaceManagerFrontBuffer]);
}

- (void)onUpdateSurface:(FlutterIOSurfaceHolder*)surface
            bufferIndex:(size_t)index
                   size:(CGSize)size {
  MacOSGLContextSwitch context_switch(_openGLContext);
  GLuint fbo = [_frameBuffers[index] glFrameBufferId];
  GLuint texture = [_frameBuffers[index] glTextureId];
  [surface bindSurfaceToTexture:texture fbo:fbo size:size];
}

@end

@implementation FlutterMetalSurfaceManager {
  id<MTLDevice> _device;
  id<MTLCommandQueue> _commandQueue;

  id<MTLTexture> _textures[kFlutterSurfaceManagerBufferCount];
}

- (nullable instancetype)initWithDevice:(nonnull id<MTLDevice>)device
                           commandQueue:(nonnull id<MTLCommandQueue>)commandQueue
                                  layer:(nonnull CALayer*)containingLayer {
  self = [super initWithLayer:containingLayer contentTransform:CATransform3DIdentity];
  if (self) {
    super.delegate = self;
    _device = device;
    _commandQueue = commandQueue;
  }
  return self;
}

- (FlutterRenderBackingStore*)renderBuffer {
  id<MTLTexture> texture = _textures[kFlutterSurfaceManagerBackBuffer];
  return [[FlutterMetalRenderBackingStore alloc] initWithTexture:texture];
}

- (void)onSwapBuffers {
  std::swap(_textures[kFlutterSurfaceManagerBackBuffer],
            _textures[kFlutterSurfaceManagerFrontBuffer]);
}

- (void)onUpdateSurface:(FlutterIOSurfaceHolder*)surface
            bufferIndex:(size_t)index
                   size:(CGSize)size {
  MTLTextureDescriptor* textureDescriptor =
      [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                         width:size.width
                                                        height:size.height
                                                     mipmapped:NO];
  textureDescriptor.usage =
      MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget | MTLTextureUsageShaderWrite;
  // plane = 0 for BGRA.
  _textures[index] = [_device newTextureWithDescriptor:textureDescriptor
                                             iosurface:[surface ioSurface]
                                                 plane:0];
}

@end
