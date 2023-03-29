// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/scene_context.h"
#include "impeller/core/formats.h"
#include "impeller/scene/material.h"
#include "impeller/scene/shaders/skinned.vert.h"
#include "impeller/scene/shaders/unlit.frag.h"
#include "impeller/scene/shaders/unskinned.vert.h"

namespace impeller {
namespace scene {

void SceneContextOptions::ApplyToPipelineDescriptor(
    PipelineDescriptor& desc) const {
  DepthAttachmentDescriptor depth;
  depth.depth_compare = CompareFunction::kLess;
  depth.depth_write_enabled = true;
  desc.SetDepthStencilAttachmentDescriptor(depth);
  desc.SetDepthPixelFormat(PixelFormat::kD32FloatS8UInt);

  StencilAttachmentDescriptor stencil;
  stencil.stencil_compare = CompareFunction::kAlways;
  stencil.depth_stencil_pass = StencilOperation::kKeep;
  desc.SetStencilAttachmentDescriptors(stencil);
  desc.SetStencilPixelFormat(PixelFormat::kD32FloatS8UInt);

  desc.SetSampleCount(sample_count);
  desc.SetPrimitiveType(primitive_type);

  desc.SetWindingOrder(WindingOrder::kCounterClockwise);
  desc.SetCullMode(CullMode::kBackFace);
}

SceneContext::SceneContext(std::shared_ptr<Context> context)
    : context_(std::move(context)) {
  if (!context_ || !context_->IsValid()) {
    return;
  }

  pipelines_[{PipelineKey{GeometryType::kUnskinned, MaterialType::kUnlit}}] =
      MakePipelineVariants<UnskinnedVertexShader, UnlitFragmentShader>(
          *context_);
  pipelines_[{PipelineKey{GeometryType::kSkinned, MaterialType::kUnlit}}] =
      MakePipelineVariants<SkinnedVertexShader, UnlitFragmentShader>(*context_);

  {
    impeller::TextureDescriptor texture_descriptor;
    texture_descriptor.storage_mode = impeller::StorageMode::kHostVisible;
    texture_descriptor.format = PixelFormat::kR8G8B8A8UNormInt;
    texture_descriptor.size = {1, 1};
    texture_descriptor.mip_count = 1u;

    placeholder_texture_ =
        context_->GetResourceAllocator()->CreateTexture(texture_descriptor);
    placeholder_texture_->SetLabel("Placeholder Texture");
    if (!placeholder_texture_) {
      FML_LOG(ERROR) << "Could not create placeholder texture.";
      return;
    }

    uint8_t pixel[] = {0xFF, 0xFF, 0xFF, 0xFF};
    if (!placeholder_texture_->SetContents(pixel, 4)) {
      FML_LOG(ERROR) << "Could not set contents of placeholder texture.";
      return;
    }
  }

  is_valid_ = true;
}

SceneContext::~SceneContext() = default;

std::shared_ptr<Pipeline<PipelineDescriptor>> SceneContext::GetPipeline(
    PipelineKey key,
    SceneContextOptions opts) const {
  if (!IsValid()) {
    return nullptr;
  }
  if (auto found = pipelines_.find(key); found != pipelines_.end()) {
    return found->second->GetPipeline(opts);
  }
  return nullptr;
}

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
