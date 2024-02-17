// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/render_pass.h"
#include "fml/status.h"

namespace impeller {

RenderPass::RenderPass(std::shared_ptr<const Context> context,
                       const RenderTarget& target)
    : context_(std::move(context)),
      sample_count_(target.GetSampleCount()),
      pixel_format_(target.GetRenderTargetPixelFormat()),
      has_depth_attachment_(target.GetDepthAttachment().has_value()),
      has_stencil_attachment_(target.GetStencilAttachment().has_value()),
      render_target_size_(target.GetRenderTargetSize()),
      render_target_(target),
      orthographic_(Matrix::MakeOrthographic(render_target_size_)) {}

RenderPass::~RenderPass() {}

SampleCount RenderPass::GetSampleCount() const {
  return sample_count_;
}

PixelFormat RenderPass::GetRenderTargetPixelFormat() const {
  return pixel_format_;
}

bool RenderPass::HasDepthAttachment() const {
  return has_depth_attachment_;
}

bool RenderPass::HasStencilAttachment() const {
  return has_stencil_attachment_;
}

const RenderTarget& RenderPass::GetRenderTarget() const {
  return render_target_;
}

ISize RenderPass::GetRenderTargetSize() const {
  return render_target_size_;
}

const Matrix& RenderPass::GetOrthographicTransform() const {
  return orthographic_;
}

void RenderPass::SetLabel(std::string label) {
  if (label.empty()) {
    return;
  }
  OnSetLabel(std::move(label));
}

bool RenderPass::AddCommand(Command&& command) {
  if (!command.IsValid()) {
    VALIDATION_LOG << "Attempted to add an invalid command to the render pass.";
    return false;
  }

  if (command.scissor.has_value()) {
    auto target_rect = IRect::MakeSize(render_target_.GetRenderTargetSize());
    if (!target_rect.Contains(command.scissor.value())) {
      VALIDATION_LOG << "Cannot apply a scissor that lies outside the bounds "
                        "of the render target.";
      return false;
    }
  }

  if (command.vertex_buffer.vertex_count == 0u ||
      command.instance_count == 0u) {
    // Essentially a no-op. Don't record the command but this is not necessary
    // an error either.
    return true;
  }

  commands_.emplace_back(std::move(command));
  return true;
}

bool RenderPass::EncodeCommands() const {
  return OnEncodeCommands(*context_);
}

const std::shared_ptr<const Context>& RenderPass::GetContext() const {
  return context_;
}

void RenderPass::SetPipeline(
    const std::shared_ptr<Pipeline<PipelineDescriptor>>& pipeline) {
  pending_.pipeline = pipeline;
}

void RenderPass::SetCommandLabel(std::string_view label) {
#ifdef IMPELLER_DEBUG
  pending_.label = std::string(label);
#endif  // IMPELLER_DEBUG
}

void RenderPass::SetStencilReference(uint32_t value) {
  pending_.stencil_reference = value;
}

void RenderPass::SetBaseVertex(uint64_t value) {
  pending_.base_vertex = value;
}

void RenderPass::SetViewport(Viewport viewport) {
  pending_.viewport = viewport;
}

void RenderPass::SetScissor(IRect scissor) {
  pending_.scissor = scissor;
}

void RenderPass::SetInstanceCount(size_t count) {
  pending_.instance_count = count;
}

bool RenderPass::SetVertexBuffer(VertexBuffer buffer) {
  return pending_.BindVertices(std::move(buffer));
}

fml::Status RenderPass::Draw() {
  auto result = AddCommand(std::move(pending_));
  pending_ = Command{};
  if (result) {
    return fml::Status();
  }
  return fml::Status(fml::StatusCode::kInvalidArgument,
                     "Failed to encode command");
}

// |ResourceBinder|
bool RenderPass::BindResource(ShaderStage stage,
                              DescriptorType type,
                              const ShaderUniformSlot& slot,
                              const ShaderMetadata& metadata,
                              BufferView view) {
  return pending_.BindResource(stage, type, slot, metadata, view);
}

bool RenderPass::BindResource(
    ShaderStage stage,
    DescriptorType type,
    const ShaderUniformSlot& slot,
    const std::shared_ptr<const ShaderMetadata>& metadata,
    BufferView view) {
  return pending_.BindResource(stage, type, slot, metadata, std::move(view));
}

// |ResourceBinder|
bool RenderPass::BindResource(ShaderStage stage,
                              DescriptorType type,
                              const SampledImageSlot& slot,
                              const ShaderMetadata& metadata,
                              std::shared_ptr<const Texture> texture,
                              const std::unique_ptr<const Sampler>& sampler) {
  return pending_.BindResource(stage, type, slot, metadata, std::move(texture),
                               sampler);
}

}  // namespace impeller
