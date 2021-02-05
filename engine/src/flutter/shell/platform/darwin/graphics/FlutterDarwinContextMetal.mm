// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/graphics/FlutterDarwinContextMetal.h"

#include "flutter/common/graphics/persistent_cache.h"
#include "flutter/fml/logging.h"
#include "third_party/skia/include/gpu/GrContextOptions.h"

static GrContextOptions CreateMetalGrContextOptions() {
  GrContextOptions options = {};
  if (flutter::PersistentCache::cache_sksl()) {
    options.fShaderCacheStrategy = GrContextOptions::ShaderCacheStrategy::kSkSL;
  }
  flutter::PersistentCache::MarkStrategySet();
  options.fPersistentCache = flutter::PersistentCache::GetCacheForProcess();
  return options;
}

@implementation FlutterDarwinContextMetal

- (instancetype)initWithDefaultMTLDevice {
  id<MTLDevice> device = MTLCreateSystemDefaultDevice();
  return [self initWithMTLDevice:device commandQueue:[device newCommandQueue]];
}

- (instancetype)initWithMTLDevice:(id<MTLDevice>)device
                     commandQueue:(id<MTLCommandQueue>)commandQueue {
  self = [super init];
  if (self != nil) {
    _device = device;

    if (!_device) {
      FML_DLOG(ERROR) << "Could not acquire Metal device.";
      [self release];
      return nil;
    }

    _commandQueue = commandQueue;

    if (!_commandQueue) {
      FML_DLOG(ERROR) << "Could not create Metal command queue.";
      [self release];
      return nil;
    }

    [_commandQueue setLabel:@"Flutter Main Queue"];

    auto contextOptions = CreateMetalGrContextOptions();

    // Skia expect arguments to `MakeMetal` transfer ownership of the reference in for release later
    // when the GrDirectContext is collected.
    _mainContext =
        GrDirectContext::MakeMetal([_device retain], [_commandQueue retain], contextOptions);
    _resourceContext =
        GrDirectContext::MakeMetal([_device retain], [_commandQueue retain], contextOptions);

    if (!_mainContext || !_resourceContext) {
      FML_DLOG(ERROR) << "Could not create Skia Metal contexts.";
      [self release];
      return nil;
    }

    _resourceContext->setResourceCacheLimits(0u, 0u);
  }
  return self;
}

@end
