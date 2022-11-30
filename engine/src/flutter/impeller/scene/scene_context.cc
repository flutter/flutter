// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/scene_context.h"
#include "impeller/renderer/formats.h"

namespace impeller {
namespace scene {

void SceneContextOptions::ApplyToPipelineDescriptor(
    PipelineDescriptor& desc) const {
  desc.SetSampleCount(sample_count);
  desc.SetPrimitiveType(primitive_type);
}

template <typename PipelineT>
static std::unique_ptr<PipelineT> CreateDefaultPipeline(
    const Context& context) {
  auto desc = PipelineT::Builder::MakeDefaultPipelineDescriptor(context);
  if (!desc.has_value()) {
    return nullptr;
  }
  // Apply default ContentContextOptions to the descriptor.
  SceneContextOptions{}.ApplyToPipelineDescriptor(*desc);
  return std::make_unique<PipelineT>(context, desc);
}

SceneContext::SceneContext(std::shared_ptr<Context> context)
    : context_(std::move(context)) {
  if (!context_ || !context_->IsValid()) {
    return;
  }

  unlit_pipeline_[{}] = CreateDefaultPipeline<UnlitPipeline>(*context_);

  {
    impeller::TextureDescriptor texture_descriptor;
    texture_descriptor.storage_mode = impeller::StorageMode::kHostVisible;
    texture_descriptor.format = PixelFormat::kDefaultColor;
    texture_descriptor.size = {1, 1};
    texture_descriptor.mip_count = 1u;

    placeholder_texture_ =
        context_->GetResourceAllocator()->CreateTexture(texture_descriptor);
    if (!placeholder_texture_) {
      FML_DLOG(ERROR) << "Could not create placeholder texture.";
      return;
    }

    uint8_t pixel[] = {0xFF, 0xFF, 0xFF, 0xFF};
    if (!placeholder_texture_->SetContents(pixel, 4, 0)) {
      FML_DLOG(ERROR) << "Could not set contents of placeholder texture.";
      return;
    }
  }

  is_valid_ = true;
}

SceneContext::~SceneContext() = default;

bool SceneContext::IsValid() const {
  return is_valid_;
}

std::shared_ptr<Context> SceneContext::GetContext() const {
  return context_;
}

std::shared_ptr<Texture> SceneContext::GetPlaceholderTexture() const {
  return placeholder_texture_;
}

}  // namespace scene
}  // namespace impeller
