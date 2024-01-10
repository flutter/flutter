// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/render_pass.h"

namespace impeller {

RenderPass::RenderPass(std::weak_ptr<const Context> context,
                       const RenderTarget& target)
    : context_(std::move(context)),
      sample_count_(target.GetSampleCount()),
      pixel_format_(target.GetRenderTargetPixelFormat()),
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
  auto context = context_.lock();
  // The context could have been collected in the meantime.
  if (!context) {
    return false;
  }
  return OnEncodeCommands(*context);
}

const std::weak_ptr<const Context>& RenderPass::GetContext() const {
  return context_;
}

}  // namespace impeller
