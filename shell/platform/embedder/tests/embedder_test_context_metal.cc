// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_test_context_metal.h"

#include <memory>

#include "embedder.h"
#include "flutter/fml/logging.h"
#include "flutter/shell/platform/embedder/tests/embedder_test_compositor_metal.h"

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
  metal_surface_ = TestMetalSurface::Create(*metal_context_, surface_size_);
}

size_t EmbedderTestContextMetal::GetSurfacePresentCount() const {
  return present_count_;
}

EmbedderTestContextType EmbedderTestContextMetal::GetContextType() const {
  return EmbedderTestContextType::kMetalContext;
}

void EmbedderTestContextMetal::SetupCompositor() {
  FML_CHECK(!compositor_) << "Already set up a compositor in this context.";
  FML_CHECK(metal_surface_)
      << "Set up the Metal surface before setting up a compositor.";
  compositor_ = std::make_unique<EmbedderTestCompositorMetal>(
      surface_size_, metal_surface_->GetGrContext());
}

TestMetalContext* EmbedderTestContextMetal::GetTestMetalContext() {
  return metal_context_.get();
}

bool EmbedderTestContextMetal::Present(int64_t texture_id) {
  FireRootSurfacePresentCallbackIfPresent(
      [&]() { return metal_surface_->GetRasterSurfaceSnapshot(); });
  present_count_++;
  return metal_context_->Present(texture_id);
}

void EmbedderTestContextMetal::SetExternalTextureCallback(
    TestExternalTextureCallback external_texture_frame_callback) {
  external_texture_frame_callback_ = external_texture_frame_callback;
}

bool EmbedderTestContextMetal::PopulateExternalTexture(
    int64_t texture_id,
    size_t w,
    size_t h,
    FlutterMetalExternalTexture* output) {
  if (external_texture_frame_callback_ != nullptr) {
    return external_texture_frame_callback_(texture_id, w, h, output);
  } else {
    return false;
  }
}

FlutterMetalTexture EmbedderTestContextMetal::GetNextDrawable(
    const FlutterFrameInfo* frame_info) {
  auto texture_info = metal_surface_->GetTextureInfo();

  FlutterMetalTexture texture;
  texture.struct_size = sizeof(FlutterMetalTexture);
  texture.texture_id = texture_info.texture_id;
  texture.texture =
      reinterpret_cast<FlutterMetalTextureHandle>(texture_info.texture);
  return texture;
}

}  // namespace testing
}  // namespace flutter
