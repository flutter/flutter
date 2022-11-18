// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterSurfaceManager.h"

#import <Metal/Metal.h>

#include <algorithm>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterIOSurfaceHolder.h"

enum {
  kFlutterSurfaceManagerFrontBuffer = 0,
  kFlutterSurfaceManagerBackBuffer = 1,
  kFlutterSurfaceManagerBufferCount,
};

// BackBuffer will be released after kIdleDelay if there is no activity.
static const double kIdleDelay = 1.0;

@interface FlutterSurfaceManager ()

/**
 * Cancels any previously-scheduled onIdle requests.
 */
- (void)cancelIdle;

/**
 * Creates a backing textures for the specified surface with the specified size.
 */
- (id<MTLTexture>)createTextureForSurface:(FlutterIOSurfaceHolder*)surface size:(CGSize)size;

@end

@implementation FlutterSurfaceManager {
  CALayer* _containingLayer;  // provided (parent layer)
  CALayer* _contentLayer;
  CATransform3D _contentTransform;

  CGSize _surfaceSize;
  FlutterIOSurfaceHolder* _ioSurfaces[kFlutterSurfaceManagerBufferCount];
  BOOL _frameInProgress;

  id<MTLDevice> _device;
  id<MTLCommandQueue> _commandQueue;
  id<MTLTexture> _textures[kFlutterSurfaceManagerBufferCount];
}

- (nullable instancetype)initWithDevice:(nonnull id<MTLDevice>)device
                           commandQueue:(nonnull id<MTLCommandQueue>)commandQueue
                                  layer:(nonnull CALayer*)containingLayer {
  self = [super init];
  if (self) {
    _containingLayer = containingLayer;
    _contentTransform = CATransform3DIdentity;
    _contentLayer = [[CALayer alloc] init];
    [_containingLayer addSublayer:_contentLayer];

    _ioSurfaces[0] = [[FlutterIOSurfaceHolder alloc] init];
    _ioSurfaces[1] = [[FlutterIOSurfaceHolder alloc] init];

    _device = device;
    _commandQueue = commandQueue;
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
      _textures[i] = [self createTextureForSurface:_ioSurfaces[i] size:size];
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
  std::swap(_textures[kFlutterSurfaceManagerBackBuffer],
            _textures[kFlutterSurfaceManagerFrontBuffer]);

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
      _textures[kFlutterSurfaceManagerBackBuffer] = nil;
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
      _textures[kFlutterSurfaceManagerBackBuffer] =
          [self createTextureForSurface:_ioSurfaces[kFlutterSurfaceManagerBackBuffer]
                                   size:_surfaceSize];
    }
  };
  [self performSelectorOnMainThread:@selector(cancelIdle) withObject:nil waitUntilDone:NO];
}

- (void)cancelIdle {
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(onIdle) object:nil];
}

- (nonnull FlutterRenderBackingStore*)renderBuffer {
  [self ensureBackBuffer];
  id<MTLTexture> texture = _textures[kFlutterSurfaceManagerBackBuffer];
  return [[FlutterRenderBackingStore alloc] initWithTexture:texture];
}

- (id<MTLTexture>)createTextureForSurface:(FlutterIOSurfaceHolder*)surface size:(CGSize)size {
  MTLTextureDescriptor* textureDescriptor =
      [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                         width:size.width
                                                        height:size.height
                                                     mipmapped:NO];
  textureDescriptor.usage =
      MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget | MTLTextureUsageShaderWrite;
  // plane = 0 for BGRA.
  return [_device newTextureWithDescriptor:textureDescriptor iosurface:[surface ioSurface] plane:0];
}

@end
