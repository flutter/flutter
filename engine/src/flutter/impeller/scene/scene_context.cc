// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/scene_context.h"

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

  is_valid_ = true;
}

SceneContext::~SceneContext() = default;

bool SceneContext::IsValid() const {
  return is_valid_;
}

std::shared_ptr<Context> SceneContext::GetContext() const {
  return context_;
}

}  // namespace scene
}  // namespace impeller
