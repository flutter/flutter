// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_test_context_metal.h"

#include <memory>

#include "flutter/fml/logging.h"

namespace flutter {
namespace testing {

EmbedderTestContextMetal::EmbedderTestContextMetal(std::string assets_path)
    : EmbedderTestContext(assets_path) {
  metal_context_ = std::make_unique<TestMetalContext>();
}

EmbedderTestContextMetal::~EmbedderTestContextMetal() {}

void EmbedderTestContextMetal::SetupSurface(SkISize surface_size) {
  FML_CHECK(surface_size_.isEmpty());
  surface_size_ = surface_size;
}

size_t EmbedderTestContextMetal::GetSurfacePresentCount() const {
  return present_count_;
}

EmbedderTestContextType EmbedderTestContextMetal::GetContextType() const {
  return EmbedderTestContextType::kMetalContext;
}

void EmbedderTestContextMetal::SetupCompositor() {
  FML_CHECK(false) << "Compositor rendering not supported in metal.";
}

TestMetalContext* EmbedderTestContextMetal::GetTestMetalContext() {
  return metal_context_.get();
}

bool EmbedderTestContextMetal::Present(int64_t texture_id) {
  FireRootSurfacePresentCallbackIfPresent([&]() {
    auto metal_surface_ =
        TestMetalSurface::Create(*metal_context_, texture_id, surface_size_);
    return metal_surface_->GetRasterSurfaceSnapshot();
  });
  present_count_++;
  return metal_context_->Present(texture_id);
}

}  // namespace testing
}  // namespace flutter
