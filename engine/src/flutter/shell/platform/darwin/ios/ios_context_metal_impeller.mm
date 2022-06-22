// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/ios_context_metal_impeller.h"

#include "flutter/impeller/entity/mtl/entity_shaders.h"
#include "flutter/impeller/renderer/backend/metal/context_mtl.h"

namespace flutter {

static std::shared_ptr<impeller::Context> CreateImpellerContext() {
  std::vector<std::shared_ptr<fml::Mapping>> shader_mappings = {
      std::make_shared<fml::NonOwnedMapping>(impeller_entity_shaders_data,
                                             impeller_entity_shaders_length),
  };
  auto context = impeller::ContextMTL::Create(shader_mappings, "Impeller Library");
  if (!context) {
    FML_LOG(ERROR) << "Could not create Metal Impeller Context.";
    return nullptr;
  }
  FML_LOG(ERROR) << "Using the Impeller rendering backend.";
  return context;
}

IOSContextMetalImpeller::IOSContextMetalImpeller()
    : IOSContext(MsaaSampleCount::kFour), context_(CreateImpellerContext()) {}

IOSContextMetalImpeller::~IOSContextMetalImpeller() = default;

fml::scoped_nsobject<FlutterDarwinContextMetal> IOSContextMetalImpeller::GetDarwinContext() const {
  return fml::scoped_nsobject<FlutterDarwinContextMetal>{};
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
  return context_;
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
  return nullptr;
}

}  // namespace flutter
