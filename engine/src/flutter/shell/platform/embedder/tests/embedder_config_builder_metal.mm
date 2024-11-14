// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_config_builder.h"

#include "flutter/shell/platform/embedder/tests/embedder_test_context_metal.h"

namespace flutter::testing {

void EmbedderConfigBuilder::InitializeMetalRendererConfig() {
  if (context_.GetContextType() != EmbedderTestContextType::kMetalContext) {
    return;
  }

  metal_renderer_config_.struct_size = sizeof(metal_renderer_config_);
  EmbedderTestContextMetal& metal_context = reinterpret_cast<EmbedderTestContextMetal&>(context_);

  metal_renderer_config_.device = metal_context.GetTestMetalContext()->GetMetalDevice();
  metal_renderer_config_.present_command_queue =
      metal_context.GetTestMetalContext()->GetMetalCommandQueue();
  metal_renderer_config_.get_next_drawable_callback = [](void* user_data,
                                                         const FlutterFrameInfo* frame_info) {
    return reinterpret_cast<EmbedderTestContextMetal*>(user_data)->GetNextDrawable(frame_info);
  };
  metal_renderer_config_.present_drawable_callback =
      [](void* user_data, const FlutterMetalTexture* texture) -> bool {
    EmbedderTestContextMetal* metal_context =
        reinterpret_cast<EmbedderTestContextMetal*>(user_data);
    return metal_context->Present(texture->texture_id);
  };
  metal_renderer_config_.external_texture_frame_callback =
      [](void* user_data, int64_t texture_id, size_t width, size_t height,
         FlutterMetalExternalTexture* texture_out) -> bool {
    EmbedderTestContextMetal* metal_context =
        reinterpret_cast<EmbedderTestContextMetal*>(user_data);
    return metal_context->PopulateExternalTexture(texture_id, width, height, texture_out);
  };
}

void EmbedderConfigBuilder::SetMetalRendererConfig(SkISize surface_size) {
  renderer_config_.type = FlutterRendererType::kMetal;
  renderer_config_.metal = metal_renderer_config_;
  context_.SetupSurface(surface_size);
}

}  // namespace flutter::testing
