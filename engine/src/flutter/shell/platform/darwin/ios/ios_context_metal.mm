// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/ios_context_metal.h"

#include "flutter/fml/logging.h"
#include "flutter/shell/common/persistent_cache.h"
#include "flutter/shell/platform/darwin/ios/ios_external_texture_metal.h"
#include "third_party/skia/include/gpu/GrContextOptions.h"

namespace flutter {

static GrContextOptions CreateMetalGrContextOptions() {
  GrContextOptions options = {};
  if (PersistentCache::cache_sksl()) {
    options.fShaderCacheStrategy = GrContextOptions::ShaderCacheStrategy::kSkSL;
  }
  PersistentCache::MarkStrategySet();
  options.fPersistentCache = PersistentCache::GetCacheForProcess();
  return options;
}

IOSContextMetal::IOSContextMetal() {
  device_.reset([MTLCreateSystemDefaultDevice() retain]);
  if (!device_) {
    FML_DLOG(ERROR) << "Could not acquire Metal device.";
    return;
  }

  main_queue_.reset([device_ newCommandQueue]);

  if (!main_queue_) {
    FML_DLOG(ERROR) << "Could not create Metal command queue.";
    return;
  }

  [main_queue_ setLabel:@"Flutter Main Queue"];

  const auto& context_options = CreateMetalGrContextOptions();

  // Skia expect arguments to `MakeMetal` transfer ownership of the reference in for release later
  // when the GrContext is collected.
  main_context_ = GrContext::MakeMetal([device_ retain], [main_queue_ retain], context_options);
  resource_context_ = GrContext::MakeMetal([device_ retain], [main_queue_ retain], context_options);

  if (!main_context_ || !resource_context_) {
    FML_DLOG(ERROR) << "Could not create Skia Metal contexts.";
    return;
  }

  resource_context_->setResourceCacheLimits(0u, 0u);

  CVMetalTextureCacheRef texture_cache_raw = NULL;
  auto cv_return = CVMetalTextureCacheCreate(kCFAllocatorDefault,  // allocator
                                             NULL,           // cache attributes (NULL default)
                                             device_.get(),  // metal device
                                             NULL,           // texture attributes (NULL default)
                                             &texture_cache_raw  // [out] cache
  );
  if (cv_return != kCVReturnSuccess) {
    FML_DLOG(ERROR) << "Could not create Metal texture cache.";
    return;
  }
  texture_cache_.Reset(texture_cache_raw);

  is_valid_ = false;
}

IOSContextMetal::~IOSContextMetal() = default;

fml::scoped_nsprotocol<id<MTLDevice>> IOSContextMetal::GetDevice() const {
  return device_;
}

fml::scoped_nsprotocol<id<MTLCommandQueue>> IOSContextMetal::GetMainCommandQueue() const {
  return main_queue_;
}

fml::scoped_nsprotocol<id<MTLCommandQueue>> IOSContextMetal::GetResourceCommandQueue() const {
  // TODO(52150): Create a dedicated resource queue once multiple queues are supported in Skia.
  return main_queue_;
}

sk_sp<GrContext> IOSContextMetal::GetMainContext() const {
  return main_context_;
}

sk_sp<GrContext> IOSContextMetal::GetResourceContext() const {
  return resource_context_;
}

// |IOSContext|
sk_sp<GrContext> IOSContextMetal::CreateResourceContext() {
  return resource_context_;
}

// |IOSContext|
bool IOSContextMetal::MakeCurrent() {
  // This only makes sense for context that need to be bound to a specific thread.
  return true;
}

// |IOSContext|
bool IOSContextMetal::ResourceMakeCurrent() {
  // This only makes sense for context that need to be bound to a specific thread.
  return true;
}

// |IOSContext|
bool IOSContextMetal::ClearCurrent() {
  // This only makes sense for context that need to be bound to a specific thread.
  return true;
}

// |IOSContext|
std::unique_ptr<Texture> IOSContextMetal::CreateExternalTexture(
    int64_t texture_id,
    fml::scoped_nsobject<NSObject<FlutterTexture>> texture) {
  return std::make_unique<IOSExternalTextureMetal>(texture_id, texture_cache_, std::move(texture));
}

}  // namespace flutter
