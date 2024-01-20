// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/test/recording_render_pass.h"

#include <utility>

namespace impeller {

RecordingRenderPass::RecordingRenderPass(
    std::shared_ptr<RenderPass> delegate,
    const std::shared_ptr<Context>& context,
    const RenderTarget& render_target)
    : RenderPass(context, render_target), delegate_(std::move(delegate)) {}

// |RenderPass|
void RecordingRenderPass::SetPipeline(
    const std::shared_ptr<Pipeline<PipelineDescriptor>>& pipeline) {
  pending_.pipeline = pipeline;
  delegate_->SetPipeline(pipeline);
}

void RecordingRenderPass::SetCommandLabel(std::string_view label) {
#ifdef IMPELLER_DEBUG
  pending_.label = std::string(label);
#endif  // IMPELLER_DEBUG
  delegate_->SetCommandLabel(label);
}

// |RenderPass|
void RecordingRenderPass::SetStencilReference(uint32_t value) {
  pending_.stencil_reference = value;
  delegate_->SetStencilReference(value);
}

// |RenderPass|
void RecordingRenderPass::SetBaseVertex(uint64_t value) {
  pending_.base_vertex = value;
  delegate_->SetBaseVertex(value);
}

// |RenderPass|
void RecordingRenderPass::SetViewport(Viewport viewport) {
  pending_.viewport = viewport;
  delegate_->SetViewport(viewport);
}

// |RenderPass|
void RecordingRenderPass::SetScissor(IRect scissor) {
  pending_.scissor = scissor;
  delegate_->SetScissor(scissor);
}

// |RenderPass|
void RecordingRenderPass::SetInstanceCount(size_t count) {
  pending_.instance_count = count;
  delegate_->SetInstanceCount(count);
}

// |RenderPass|
bool RecordingRenderPass::SetVertexBuffer(VertexBuffer buffer) {
  pending_.vertex_buffer = buffer;
  return delegate_->SetVertexBuffer(buffer);
}

// |RenderPass|
fml::Status RecordingRenderPass::Draw() {
  commands_.emplace_back(std::move(pending_));
  pending_ = {};
  return delegate_->Draw();
}

// |RenderPass|
void RecordingRenderPass::OnSetLabel(std::string label) {
  return;
}

// |RenderPass|
bool RecordingRenderPass::OnEncodeCommands(const Context& context) const {
  return delegate_->EncodeCommands();
}

// |RenderPass|
bool RecordingRenderPass::BindResource(ShaderStage stage,
                                       DescriptorType type,
                                       const ShaderUniformSlot& slot,
                                       const ShaderMetadata& metadata,
                                       BufferView view) {
  pending_.BindResource(stage, type, slot, metadata, view);
  return delegate_->BindResource(stage, type, slot, metadata, view);
}

// |RenderPass|
bool RecordingRenderPass::BindResource(
    ShaderStage stage,
    DescriptorType type,
    const ShaderUniformSlot& slot,
    const std::shared_ptr<const ShaderMetadata>& metadata,
    BufferView view) {
  pending_.BindResource(stage, type, slot, metadata, view);
  return delegate_->BindResource(stage, type, slot, metadata, view);
}

// |RenderPass|
bool RecordingRenderPass::BindResource(ShaderStage stage,
                                       DescriptorType type,
                                       const SampledImageSlot& slot,
                                       const ShaderMetadata& metadata,
                                       std::shared_ptr<const Texture> texture,
                                       std::shared_ptr<const Sampler> sampler) {
  pending_.BindResource(stage, type, slot, metadata, texture, sampler);
  return delegate_->BindResource(stage, type, slot, metadata, texture, sampler);
}

}  // namespace impeller
