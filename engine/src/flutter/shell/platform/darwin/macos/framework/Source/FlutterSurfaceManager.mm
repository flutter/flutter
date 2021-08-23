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

// BackBuffer will be released after kIdleDelay if there is no activity.
static const double kIdleDelay = 1.0;

@implementation FlutterIOSurfaceManager {
  CALayer* _containingLayer;  // provided (parent layer)
  CALayer* _contentLayer;
  CATransform3D _contentTransform;

  CGSize _surfaceSize;
  FlutterIOSurfaceHolder* _ioSurfaces[kFlutterSurfaceManagerBufferCount];
  BOOL _frameInProgress;
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
    if (_ioSurfaces[i] != nil) {
      [_ioSurfaces[i] recreateIOSurfaceWithSize:size];
      [_delegate onUpdateSurface:_ioSurfaces[i] bufferIndex:i size:size];
    }
  }
}

- (void)swapBuffers {
#ifndef NDEBUG
  // swapBuffers should not be called unless a frame was drawn
  @synchronized(self) {
    assert(_frameInProgress);
  }
#endif

  _contentLayer.frame = _containingLayer.bounds;
  _contentLayer.transform = _contentTransform;
  IOSurfaceRef contentIOSurface = [_ioSurfaces[kFlutterSurfaceManagerBackBuffer] ioSurface];
  [_contentLayer setContents:(__bridge id)contentIOSurface];

  std::swap(_ioSurfaces[kFlutterSurfaceManagerBackBuffer],
            _ioSurfaces[kFlutterSurfaceManagerFrontBuffer]);
  [_delegate onSwapBuffers];

  // performSelector:withObject:afterDelay needs to be performed on RunLoop thread
  [self performSelectorOnMainThread:@selector(reschedule) withObject:nil waitUntilDone:NO];

  @synchronized(self) {
    _frameInProgress = NO;
  }
}

- (void)reschedule {
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(onIdle) object:nil];
  [self performSelector:@selector(onIdle) withObject:nil afterDelay:kIdleDelay];
}

- (void)onIdle {
  @synchronized(self) {
    if (!_frameInProgress) {
      // Release the back buffer and notify delegate. The buffer will be restored
      // on demand in ensureBackBuffer
      _ioSurfaces[kFlutterSurfaceManagerBackBuffer] = nil;
      [self.delegate onSurfaceReleased:kFlutterSurfaceManagerBackBuffer];
    }
  }
}

- (void)ensureBackBuffer {
  @synchronized(self) {
    _frameInProgress = YES;
    if (_ioSurfaces[kFlutterSurfaceManagerBackBuffer] == nil) {
      // Restore previously released backbuffer
      _ioSurfaces[kFlutterSurfaceManagerBackBuffer] = [[FlutterIOSurfaceHolder alloc] init];
      [_ioSurfaces[kFlutterSurfaceManagerBackBuffer] recreateIOSurfaceWithSize:_surfaceSize];
      [_delegate onUpdateSurface:_ioSurfaces[kFlutterSurfaceManagerBackBuffer]
                     bufferIndex:kFlutterSurfaceManagerBackBuffer
                            size:_surfaceSize];
    }
  };
  [self performSelectorOnMainThread:@selector(cancelIdle) withObject:nil waitUntilDone:NO];
}

- (void)cancelIdle {
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(onIdle) object:nil];
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
  }
  return self;
}

- (FlutterRenderBackingStore*)renderBuffer {
  [self ensureBackBuffer];
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
  if (_frameBuffers[index] == nil) {
    _frameBuffers[index] =
        [[FlutterFrameBufferProvider alloc] initWithOpenGLContext:_openGLContext];
  }
  MacOSGLContextSwitch context_switch(_openGLContext);
  GLuint fbo = [_frameBuffers[index] glFrameBufferId];
  GLuint texture = [_frameBuffers[index] glTextureId];
  [surface bindSurfaceToTexture:texture fbo:fbo size:size];
}

- (void)onSurfaceReleased:(size_t)index {
  _frameBuffers[index] = nil;
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
  [self ensureBackBuffer];
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

- (void)onSurfaceReleased:(size_t)index {
  _textures[index] = nil;
}

@end
