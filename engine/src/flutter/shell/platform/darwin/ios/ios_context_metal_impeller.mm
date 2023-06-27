// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/ios_context_metal_impeller.h"
#include "flutter/impeller/entity/mtl/entity_shaders.h"
#import "flutter/shell/platform/darwin/ios/ios_external_texture_metal.h"

namespace flutter {

IOSContextMetalImpeller::IOSContextMetalImpeller(
    std::shared_ptr<const fml::SyncSwitch> is_gpu_disabled_sync_switch)
    : IOSContext(MsaaSampleCount::kFour),
      darwin_context_metal_impeller_(fml::scoped_nsobject<FlutterDarwinContextMetalImpeller>{
          [[FlutterDarwinContextMetalImpeller alloc]
              init:std::move(is_gpu_disabled_sync_switch)]}) {}

IOSContextMetalImpeller::~IOSContextMetalImpeller() = default;

fml::scoped_nsobject<FlutterDarwinContextMetalSkia> IOSContextMetalImpeller::GetDarwinContext()
    const {
  return fml::scoped_nsobject<FlutterDarwinContextMetalSkia>{};
}

IOSRenderingBackend IOSContextMetalImpeller::GetBackend() const {
  return IOSRenderingBackend::kImpeller;
}

sk_sp<GrDirectContext> IOSContextMetalImpeller::GetMainContext() const {
  return nullptr;
}

sk_sp<GrDirectContext> IOSContextMetalImpeller::GetResourceContext() const {
  return nullptr;
}

// |IOSContext|
sk_sp<GrDirectContext> IOSContextMetalImpeller::CreateResourceContext() {
  return nullptr;
}

// |IOSContext|
std::shared_ptr<impeller::Context> IOSContextMetalImpeller::GetImpellerContext() const {
  return darwin_context_metal_impeller_.get().context;
}

// |IOSContext|
std::unique_ptr<GLContextResult> IOSContextMetalImpeller::MakeCurrent() {
  // This only makes sense for contexts that need to be bound to a specific thread.
  return std::make_unique<GLContextDefaultResult>(true);
}

// |IOSContext|
std::unique_ptr<Texture> IOSContextMetalImpeller::CreateExternalTexture(
    int64_t texture_id,
    fml::scoped_nsobject<NSObject<FlutterTexture>> texture) {
  return std::make_unique<IOSExternalTextureMetal>(
      fml::scoped_nsobject<FlutterDarwinExternalTextureMetal>{
          [[darwin_context_metal_impeller_ createExternalTextureWithIdentifier:texture_id
                                                                       texture:texture] retain]});
}

}  // namespace flutter
