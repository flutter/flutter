// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterMetalLayer.h"

#include <CoreMedia/CoreMedia.h>
#include <IOSurface/IOSurfaceObjC.h>
#include <Metal/Metal.h>
#include <UIKit/UIKit.h>

#import "flutter/shell/platform/darwin/common/InternalFlutterSwiftCommon/InternalFlutterSwiftCommon.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/InternalFlutterSwift/InternalFlutterSwift.h"

FLUTTER_ASSERT_ARC

@class FlutterTexture;
@class FlutterDrawable;

@interface FlutterMetalLayer () {
  CGSize _drawableSize;

  NSUInteger _nextDrawableId;

  // Access to these variables must be synchronized.
  NSMutableSet<FlutterTexture*>* _availableTextures;
  NSUInteger _totalTextures;
  FlutterTexture* _front;
}

- (void)presentTexture:(FlutterTexture*)texture;
- (void)returnTexture:(FlutterTexture*)texture;
- (id<CAMetalDrawable>)acquirePresentationDrawable;

@end

@interface FlutterTexture : NSObject

@property(readonly, nonatomic) id<MTLTexture> texture;
@property(readonly, nonatomic) IOSurface* surface;
@property(readwrite, nonatomic) CFTimeInterval presentedTime;
@property(readwrite, atomic) BOOL waitingForCompletion;

@end

@implementation FlutterTexture

- (instancetype)initWithTexture:(id<MTLTexture>)texture surface:(IOSurface*)surface {
  if (self = [super init]) {
    _texture = texture;
    _surface = surface;
  }
  return self;
}

@end

@interface FlutterDrawable : NSObject <FlutterMetalDrawable> {
  FlutterTexture* _texture;
  __weak FlutterMetalLayer* _layer;
  id<CAMetalDrawable> _presentationDrawable;
  NSUInteger _drawableId;
  BOOL _presented;
}

- (instancetype)initWithTexture:(FlutterTexture*)texture
                          layer:(FlutterMetalLayer*)layer
                     drawableId:(NSUInteger)drawableId;

@end

@implementation FlutterDrawable

- (instancetype)initWithTexture:(FlutterTexture*)texture
                          layer:(FlutterMetalLayer*)layer
                     drawableId:(NSUInteger)drawableId {
  if (self = [super init]) {
    _texture = texture;
    _layer = layer;
    _drawableId = drawableId;
  }
  return self;
}

- (id<MTLTexture>)texture {
  return self->_texture.texture;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
- (CAMetalLayer*)layer {
  return (id)self->_layer;
}
#pragma clang diagnostic pop

- (NSUInteger)drawableID {
  return self->_drawableId;
}

- (CFTimeInterval)presentedTime {
  return 0;
}

- (void)present {
  [_presentationDrawable present];
  _presentationDrawable = nil;
  [_layer presentTexture:self->_texture];
  self->_presented = YES;
}

- (void)dealloc {
  if (!_presented) {
    [_layer returnTexture:self->_texture];
  }
}

- (void)addPresentedHandler:(nonnull MTLDrawablePresentedHandler)block {
  [FlutterLogger logWarning:@"FlutterMetalLayer drawable does not implement addPresentedHandler:"];
}

- (void)presentAtTime:(CFTimeInterval)presentationTime {
  [FlutterLogger logWarning:@"FlutterMetalLayer drawable does not implement presentAtTime:"];
}

- (void)presentAfterMinimumDuration:(CFTimeInterval)duration {
  [FlutterLogger
      logWarning:@"FlutterMetalLayer drawable does not implement presentAfterMinimumDuration:"];
}

- (void)flutterPrepareForPresent:(nonnull id<MTLCommandBuffer>)commandBuffer {
  FlutterTexture* texture = _texture;
  texture.waitingForCompletion = YES;

  id<CAMetalDrawable> presentationDrawable = [_layer acquirePresentationDrawable];
  id<MTLTexture> presentationTexture = presentationDrawable.texture;

  // A resize can leave an old Flutter texture in flight. Do not copy
  // it into a drawable created for the new layer configuration.
  const BOOL canCopy = presentationTexture != nil &&
                       presentationTexture.width == texture.texture.width &&
                       presentationTexture.height == texture.texture.height &&
                       presentationTexture.pixelFormat == texture.texture.pixelFormat;

  if (canCopy) {
    // Copy the IOSurface-backed Flutter result into the drawable owned by this CAMetalLayer.
    // Encoding the copy and presentation on the render command buffer preserves GPU ordering
    // without making the CPU wait.
    id<MTLBlitCommandEncoder> blit = [commandBuffer blitCommandEncoder];
    MTLOrigin origin = MTLOriginMake(0, 0, 0);
    MTLSize size = MTLSizeMake(texture.texture.width, texture.texture.height, 1);
    [blit copyFromTexture:texture.texture
              sourceSlice:0
              sourceLevel:0
             sourceOrigin:origin
               sourceSize:size
                toTexture:presentationTexture
         destinationSlice:0
         destinationLevel:0
        destinationOrigin:origin];
    [blit endEncoding];
    // Defer presentation until the command buffer is scheduled so the native
    // drawable can join the Core Animation transaction used by platform views.
    _presentationDrawable = presentationDrawable;
  }
  [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
    texture.waitingForCompletion = NO;
  }];
}

@end

@implementation FlutterMetalLayer

- (instancetype)init {
  if (self = [super init]) {
    self.device = MTLCreateSystemDefaultDevice();
    self.pixelFormat = MTLPixelFormatBGRA8Unorm;
    _availableTextures = [[NSMutableSet alloc] init];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setDrawableSize:(CGSize)drawableSize {
  @synchronized(self) {
    [_availableTextures removeAllObjects];
    _front = nil;
    _totalTextures = 0;
    _drawableSize = drawableSize;
    [super setDrawableSize:drawableSize];
  }
}

- (void)didEnterBackground:(id)notification {
  @synchronized(self) {
    [_availableTextures removeAllObjects];
    _totalTextures = _front != nil ? 1 : 0;
  }
}

- (CGSize)drawableSize {
  @synchronized(self) {
    return _drawableSize;
  }
}

- (IOSurface*)createIOSurface {
  unsigned pixelFormat;
  unsigned bytesPerElement;
  if (self.pixelFormat == MTLPixelFormatRGBA16Float) {
    pixelFormat = kCVPixelFormatType_64RGBAHalf;
    bytesPerElement = 8;
  } else if (self.pixelFormat == MTLPixelFormatBGRA8Unorm) {
    pixelFormat = kCVPixelFormatType_32BGRA;
    bytesPerElement = 4;
  } else if (self.pixelFormat == MTLPixelFormatBGRA10_XR) {
    pixelFormat = kCVPixelFormatType_40ARGBLEWideGamut;
    bytesPerElement = 8;
  } else {
    NSString* errorMessage =
        [NSString stringWithFormat:@"Unsupported pixel format: %lu", self.pixelFormat];
    [FlutterLogger logError:errorMessage];
    return nil;
  }
  size_t bytesPerRow =
      IOSurfaceAlignProperty(kIOSurfaceBytesPerRow, _drawableSize.width * bytesPerElement);
  size_t totalBytes =
      IOSurfaceAlignProperty(kIOSurfaceAllocSize, _drawableSize.height * bytesPerRow);
  NSDictionary* options = @{
    (id)kIOSurfaceWidth : @(_drawableSize.width),
    (id)kIOSurfaceHeight : @(_drawableSize.height),
    (id)kIOSurfacePixelFormat : @(pixelFormat),
    (id)kIOSurfaceBytesPerElement : @(bytesPerElement),
    (id)kIOSurfaceBytesPerRow : @(bytesPerRow),
    (id)kIOSurfaceAllocSize : @(totalBytes),
  };

  IOSurfaceRef res = IOSurfaceCreate((CFDictionaryRef)options);
  if (res == nil) {
    NSString* errorMessage = [NSString
        stringWithFormat:@"Failed to create IOSurface with options %@", options.debugDescription];
    [FlutterLogger logError:errorMessage];
    return nil;
  }

  if (self.colorspace != nil) {
    CFStringRef name = CGColorSpaceGetName(self.colorspace);
    IOSurfaceSetValue(res, kIOSurfaceColorSpace, name);
  } else {
    IOSurfaceSetValue(res, kIOSurfaceColorSpace, kCGColorSpaceSRGB);
  }
  return (__bridge_transfer IOSurface*)res;
}

- (FlutterTexture*)nextTexture {
  CFTimeInterval start = CACurrentMediaTime();
  while (true) {
    FlutterTexture* texture = [self tryNextTexture];
    if (texture != nil) {
      return texture;
    }
    CFTimeInterval elapsed = CACurrentMediaTime() - start;
    if (elapsed > 1.0) {
      NSLog(@"Waited %f seconds for a drawable, giving up.", elapsed);
      return nil;
    }
  }
}

- (FlutterTexture*)tryNextTexture {
  @synchronized(self) {
    if (_front != nil && _front.waitingForCompletion) {
      return nil;
    }
    if (_totalTextures < 3) {
      ++_totalTextures;
      IOSurface* surface = [self createIOSurface];
      if (surface == nil) {
        return nil;
      }
      MTLTextureDescriptor* textureDescriptor =
          [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:self.pixelFormat
                                                             width:_drawableSize.width
                                                            height:_drawableSize.height
                                                         mipmapped:NO];

      if (self.framebufferOnly) {
        textureDescriptor.usage = MTLTextureUsageRenderTarget;
      } else {
        textureDescriptor.usage =
            MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite;
      }
      id<MTLTexture> texture = [self.device newTextureWithDescriptor:textureDescriptor
                                                           iosurface:(__bridge IOSurfaceRef)surface
                                                               plane:0];
      FlutterTexture* flutterTexture = [[FlutterTexture alloc] initWithTexture:texture
                                                                       surface:surface];
      return flutterTexture;
    } else {
      // Prefer surface that is not in use and has been presented the longest
      // time ago.
      // When isInUse is false, the surface is definitely not used by the compositor.
      // When isInUse is true, the surface may be used by the compositor.
      // When both surfaces are in use, the one presented earlier will be returned.
      // The assumption here is that the compositor is already aware of the
      // newer texture and is unlikely to read from the older one, even though it
      // has not decreased the use count yet (there seems to be certain latency).
      FlutterTexture* res = nil;
      for (FlutterTexture* texture in _availableTextures) {
        if (res == nil) {
          res = texture;
        } else if (res.surface.isInUse && !texture.surface.isInUse) {
          // prefer texture that is not in use.
          res = texture;
        } else if (res.surface.isInUse == texture.surface.isInUse &&
                   texture.presentedTime < res.presentedTime) {
          // prefer texture with older presented time.
          res = texture;
        }
      }
      if (res != nil) {
        [_availableTextures removeObject:res];
      }
      return res;
    }
  }
}

- (id<CAMetalDrawable>)nextFlutterDrawable {
  FlutterTexture* texture = [self nextTexture];
  if (texture == nil) {
    return nil;
  }
  FlutterDrawable* drawable = [[FlutterDrawable alloc] initWithTexture:texture
                                                                 layer:self
                                                            drawableId:_nextDrawableId++];
  return drawable;
}

- (id<CAMetalDrawable>)nextDrawable {
  // Metal renderers receive this instance as CAMetalLayer and call nextDrawable.
  return [self nextFlutterDrawable];
}

- (id<CAMetalDrawable>)acquirePresentationDrawable {
  return [super nextDrawable];
}

- (void)presentTexture:(FlutterTexture*)texture {
  @synchronized(self) {
    if (texture.texture.width != _drawableSize.width ||
        texture.texture.height != _drawableSize.height) {
      return;
    }
    if (_front != nil) {
      [_availableTextures addObject:_front];
    }
    _front = texture;
    texture.presentedTime = CACurrentMediaTime();
  }
}

- (void)returnTexture:(FlutterTexture*)texture {
  if (texture == nil) {
    return;
  }
  @synchronized(self) {
    if (texture.texture.width == _drawableSize.width &&
        texture.texture.height == _drawableSize.height) {
      [_availableTextures addObject:texture];
    }
  }
}

+ (BOOL)enabled {
  static BOOL enabled = YES;
  static BOOL didCheckInfoPlist = NO;
  if (!didCheckInfoPlist) {
    didCheckInfoPlist = YES;
    NSNumber* use_flutter_metal_layer =
        [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FLTUseFlutterMetalLayer"];
    if (use_flutter_metal_layer != nil && ![use_flutter_metal_layer boolValue]) {
      enabled = NO;
    }
  }
  return enabled;
}

@end
