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
  id<MTLDevice> mtlDevice = MTLCreateSystemDefaultDevice();
  return [self initWithMTLDevice:mtlDevice commandQueue:[mtlDevice newCommandQueue]];
}

- (instancetype)initWithMTLDevice:(id<MTLDevice>)mtlDevice
                     commandQueue:(id<MTLCommandQueue>)commandQueue {
  self = [super init];
  if (self != nil) {
    _mtlDevice = mtlDevice;

    if (!_mtlDevice) {
      FML_DLOG(ERROR) << "Could not acquire Metal device.";
      [self release];
      return nil;
    }

    _mtlCommandQueue = commandQueue;

    if (!_mtlCommandQueue) {
      FML_DLOG(ERROR) << "Could not create Metal command queue.";
      [self release];
      return nil;
    }

    [_mtlCommandQueue setLabel:@"Flutter Main Queue"];

    auto contextOptions = CreateMetalGrContextOptions();

    // Skia expect arguments to `MakeMetal` transfer ownership of the reference in for release later
    // when the GrDirectContext is collected.
    _mainContext =
        GrDirectContext::MakeMetal([_mtlDevice retain], [_mtlCommandQueue retain], contextOptions);
    _resourceContext =
        GrDirectContext::MakeMetal([_mtlDevice retain], [_mtlCommandQueue retain], contextOptions);

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
