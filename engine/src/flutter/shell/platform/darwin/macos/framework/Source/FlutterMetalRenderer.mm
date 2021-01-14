
// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterMetalRenderer.h"

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterView.h"
#include "flutter/shell/platform/embedder/embedder.h"

#pragma mark - Static callbacks that require the engine.

static FlutterMetalTexture OnGetNextDrawable(FlutterEngine* engine,
                                             const FlutterFrameInfo* frameInfo) {
  CGSize size = CGSizeMake(frameInfo->size.width, frameInfo->size.height);
  FlutterMetalRenderer* metalRenderer = reinterpret_cast<FlutterMetalRenderer*>(engine.renderer);
  return [metalRenderer createTextureForSize:size];
}

static bool OnPresentDrawable(FlutterEngine* engine, const FlutterMetalTexture* texture) {
  FlutterMetalRenderer* metalRenderer = reinterpret_cast<FlutterMetalRenderer*>(engine.renderer);
  return [metalRenderer present:texture->texture_id];
}

#pragma mark - FlutterMetalRenderer implementation

@implementation FlutterMetalRenderer {
  FlutterEngine* _engine;

  FlutterView* _flutterView;
}

- (instancetype)initWithFlutterEngine:(nonnull FlutterEngine*)flutterEngine {
  self = [super init];
  if (self) {
    _engine = flutterEngine;

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
  }
  return self;
}

- (void)setFlutterView:(FlutterView*)view {
  _flutterView = view;
}

- (FlutterRendererConfig)createRendererConfig {
  FlutterRendererConfig config = {
      .type = FlutterRendererType::kMetal,
      .metal.struct_size = sizeof(FlutterMetalRendererConfig),
      .metal.device = (__bridge FlutterMetalDeviceHandle)_device,
      .metal.present_command_queue = (__bridge FlutterMetalCommandQueueHandle)_commandQueue,
      .metal.get_next_drawable_callback =
          reinterpret_cast<FlutterMetalTextureCallback>(OnGetNextDrawable),
      .metal.present_drawable_callback =
          reinterpret_cast<FlutterMetalPresentCallback>(OnPresentDrawable),
  };
  return config;
}

#pragma mark - Embedder callback implementations.

- (FlutterMetalTexture)createTextureForSize:(CGSize)size {
  FlutterMetalRenderBackingStore* backingStore =
      (FlutterMetalRenderBackingStore*)[_flutterView backingStoreForSize:size];
  id<MTLTexture> texture = backingStore.texture;
  FlutterMetalTexture embedderTexture;
  embedderTexture.struct_size = sizeof(FlutterMetalTexture);
  embedderTexture.texture = (__bridge void*)texture;
  embedderTexture.texture_id = reinterpret_cast<int64_t>(texture);
  return embedderTexture;
}

- (BOOL)present:(int64_t)textureID {
  if (!_flutterView) {
    return NO;
  }
  [_flutterView present];
  return YES;
}

#pragma mark - FlutterTextureRegistrar methods.

- (int64_t)registerTexture:(id<FlutterTexture>)texture {
  NSAssert(NO, @"External textures aren't yet supported when using Metal on macOS."
                " See: https://github.com/flutter/flutter/issues/73826");
  return 0;
}

- (void)textureFrameAvailable:(int64_t)textureID {
  NSAssert(NO, @"External textures aren't yet supported when using Metal on macOS."
                " See: https://github.com/flutter/flutter/issues/73826");
}

- (void)unregisterTexture:(int64_t)textureID {
  NSAssert(NO, @"External textures aren't yet supported when using Metal on macOS."
                " See: https://github.com/flutter/flutter/issues/73826");
}

@end
