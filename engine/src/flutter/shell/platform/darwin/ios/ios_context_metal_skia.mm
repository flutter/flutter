// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/ios_context_metal_skia.h"

#include "flutter/common/graphics/persistent_cache.h"
#include "flutter/fml/logging.h"
#import "flutter/shell/platform/darwin/graphics/FlutterDarwinContextMetal.h"
#import "flutter/shell/platform/darwin/ios/ios_external_texture_metal.h"
#include "third_party/skia/include/gpu/GrContextOptions.h"

namespace flutter {

IOSContextMetalSkia::IOSContextMetalSkia(MsaaSampleCount msaa_samples) : IOSContext(msaa_samples) {
  darwin_context_metal_ = fml::scoped_nsobject<FlutterDarwinContextMetal>{
      [[FlutterDarwinContextMetal alloc] initWithDefaultMTLDevice]};

  if (!darwin_context_metal_) {
    return;
  }

  main_command_queue_.reset([darwin_context_metal_.get().commandQueue retain]);

  CVMetalTextureCacheRef texture_cache_raw = NULL;
  auto cv_return = CVMetalTextureCacheCreate(kCFAllocatorDefault,  // allocator
                                             NULL,  // cache attributes (NULL default)
                                             darwin_context_metal_.get().device,  // metal device
                                             NULL,  // texture attributes (NULL default)
                                             &texture_cache_raw  // [out] cache
  );
  if (cv_return != kCVReturnSuccess) {
    FML_DLOG(ERROR) << "Could not create Metal texture cache.";
    return;
  }
  texture_cache_.Reset(texture_cache_raw);
}

IOSContextMetalSkia::~IOSContextMetalSkia() = default;

fml::scoped_nsobject<FlutterDarwinContextMetal> IOSContextMetalSkia::GetDarwinContext() const {
  return darwin_context_metal_;
}

IOSRenderingBackend IOSContextMetalSkia::GetBackend() const {
  return IOSRenderingBackend::kSkia;
}

sk_sp<GrDirectContext> IOSContextMetalSkia::GetMainContext() const {
  return darwin_context_metal_.get().mainContext;
}

sk_sp<GrDirectContext> IOSContextMetalSkia::GetResourceContext() const {
  return darwin_context_metal_.get().resourceContext;
}

// |IOSContext|
sk_sp<GrDirectContext> IOSContextMetalSkia::CreateResourceContext() {
  return darwin_context_metal_.get().resourceContext;
}

// |IOSContext|
std::unique_ptr<GLContextResult> IOSContextMetalSkia::MakeCurrent() {
  // This only makes sense for context that need to be bound to a specific thread.
  return std::make_unique<GLContextDefaultResult>(true);
}

// |IOSContext|
std::unique_ptr<Texture> IOSContextMetalSkia::CreateExternalTexture(
    int64_t texture_id,
    fml::scoped_nsobject<NSObject<FlutterTexture>> texture) {
  return std::make_unique<IOSExternalTextureMetal>(
      fml::scoped_nsobject<FlutterDarwinExternalTextureMetal>{
          [[darwin_context_metal_ createExternalTextureWithIdentifier:texture_id
                                                              texture:texture] retain]});
}

}  // namespace flutter
