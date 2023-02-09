// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterRenderer.h"

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterExternalTexture.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewController_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewEngineProvider.h"
#include "flutter/shell/platform/embedder/embedder.h"

#pragma mark - Static callbacks that require the engine.

static FlutterMetalTexture OnGetNextDrawableForDefaultView(FlutterEngine* engine,
                                                           const FlutterFrameInfo* frameInfo) {
  // TODO(dkwingsmt): This callback only supports single-view, therefore it only
  // operates on the default view. To support multi-view, we need a new callback
  // that also receives a view ID, or pass the ID via FlutterFrameInfo.
  uint64_t viewId = kFlutterDefaultViewId;
  CGSize size = CGSizeMake(frameInfo->size.width, frameInfo->size.height);
  return [engine.renderer createTextureForView:viewId size:size];
}

static bool OnPresentDrawableOfDefaultView(FlutterEngine* engine,
                                           const FlutterMetalTexture* texture) {
  // TODO(dkwingsmt): This callback only supports single-view, therefore it only
  // operates on the default view. To support multi-view, we need a new callback
  // that also receives a view ID.
  uint64_t viewId = kFlutterDefaultViewId;
  return [engine.renderer present:viewId texture:texture];
}

static bool OnAcquireExternalTexture(FlutterEngine* engine,
                                     int64_t textureIdentifier,
                                     size_t width,
                                     size_t height,
                                     FlutterMetalExternalTexture* metalTexture) {
  return [engine.renderer populateTextureWithIdentifier:textureIdentifier
                                           metalTexture:metalTexture];
}

#pragma mark - FlutterRenderer implementation

@implementation FlutterRenderer {
  FlutterViewEngineProvider* _viewProvider;

  FlutterDarwinContextMetalSkia* _darwinMetalContext;
}

- (instancetype)initWithFlutterEngine:(nonnull FlutterEngine*)flutterEngine {
  self = [super initWithDelegate:self engine:flutterEngine];
  if (self) {
    _viewProvider = [[FlutterViewEngineProvider alloc] initWithEngine:flutterEngine];
    _device = MTLCreateSystemDefaultDevice();
    if (!_device) {
      NSLog(@"Could not acquire Metal device.");
      return nil;
    }

    _commandQueue = [_device newCommandQueue];
    if (!_commandQueue) {
      NSLog(@"Could not create Metal command queue.");
      return nil;
    }

    _darwinMetalContext = [[FlutterDarwinContextMetalSkia alloc] initWithMTLDevice:_device
                                                                      commandQueue:_commandQueue];
  }
  return self;
}

- (FlutterRendererConfig)createRendererConfig {
  FlutterRendererConfig config = {
      .type = FlutterRendererType::kMetal,
      .metal.struct_size = sizeof(FlutterMetalRendererConfig),
      .metal.device = (__bridge FlutterMetalDeviceHandle)_device,
      .metal.present_command_queue = (__bridge FlutterMetalCommandQueueHandle)_commandQueue,
      .metal.get_next_drawable_callback =
          reinterpret_cast<FlutterMetalTextureCallback>(OnGetNextDrawableForDefaultView),
      .metal.present_drawable_callback =
          reinterpret_cast<FlutterMetalPresentCallback>(OnPresentDrawableOfDefaultView),
      .metal.external_texture_frame_callback =
          reinterpret_cast<FlutterMetalTextureFrameCallback>(OnAcquireExternalTexture),
  };
  return config;
}

#pragma mark - Embedder callback implementations.

- (FlutterMetalTexture)createTextureForView:(uint64_t)viewId size:(CGSize)size {
  FlutterView* view = [_viewProvider viewForId:viewId];
  NSAssert(view != nil, @"Can't create texture on a non-existent view 0x%llx.", viewId);
  if (view == nil) {
    // FlutterMetalTexture has texture `null`, therefore is discarded.
    return FlutterMetalTexture{};
  }
  return [view.surfaceManager surfaceForSize:size].asFlutterMetalTexture;
}

- (BOOL)present:(uint64_t)viewId texture:(const FlutterMetalTexture*)texture {
  FlutterView* view = [_viewProvider viewForId:viewId];
  if (view == nil) {
    return NO;
  }
  FlutterSurface* surface = [FlutterSurface fromFlutterMetalTexture:texture];
  if (surface == nil) {
    return NO;
  }
  FlutterSurfacePresentInfo* info = [[FlutterSurfacePresentInfo alloc] init];
  info.surface = surface;
  [view.surfaceManager present:@[ info ] notify:nil];
  return YES;
}

#pragma mark - FlutterTextureRegistrar methods.

- (BOOL)populateTextureWithIdentifier:(int64_t)textureID
                         metalTexture:(FlutterMetalExternalTexture*)textureOut {
  FlutterExternalTexture* texture = [self getTextureWithID:textureID];
  return [texture populateTexture:textureOut];
}

- (FlutterExternalTexture*)onRegisterTexture:(id<FlutterTexture>)texture {
  return [[FlutterExternalTexture alloc] initWithFlutterTexture:texture
                                             darwinMetalContext:_darwinMetalContext];
}

@end
