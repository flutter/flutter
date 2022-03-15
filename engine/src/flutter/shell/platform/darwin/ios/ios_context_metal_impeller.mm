// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/ios_context_metal_impeller.h"

namespace flutter {

IOSContextMetalImpeller::IOSContextMetalImpeller() = default;

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
