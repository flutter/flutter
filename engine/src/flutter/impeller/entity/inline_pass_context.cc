// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/inline_pass_context.h"

#include "impeller/renderer/command_buffer.h"

namespace impeller {

InlinePassContext::InlinePassContext(std::shared_ptr<Context> context,
                                     RenderTarget render_target)
    : context_(context), render_target_(render_target) {}

InlinePassContext::~InlinePassContext() {
  EndPass();
}

bool InlinePassContext::IsValid() const {
  return !render_target_.GetColorAttachments().empty();
}

bool InlinePassContext::IsActive() const {
  return pass_ != nullptr;
}

std::shared_ptr<Texture> InlinePassContext::GetTexture() {
  if (!IsValid()) {
    return nullptr;
  }
  auto color0 = render_target_.GetColorAttachments().find(0)->second;
  return color0.resolve_texture ? color0.resolve_texture : color0.texture;
}

bool InlinePassContext::EndPass() {
  if (!IsActive()) {
    return true;
  }

  if (!pass_->EncodeCommands(context_->GetTransientsAllocator())) {
    return false;
  }

  if (!command_buffer_->SubmitCommands()) {
    return false;
  }

  pass_ = nullptr;
  command_buffer_ = nullptr;

  return true;
}

const RenderTarget& InlinePassContext::GetRenderTarget() const {
  return render_target_;
}

std::shared_ptr<RenderPass> InlinePassContext::GetRenderPass(
    uint32_t pass_depth) {
  // Create a new render pass if one isn't active.
  if (!IsActive()) {
    command_buffer_ = context_->CreateRenderCommandBuffer();
    if (!command_buffer_) {
      return nullptr;
    }

    command_buffer_->SetLabel(
        "EntityPass Command Buffer: Depth=" + std::to_string(pass_depth) +
        " Count=" + std::to_string(pass_count_));

    // Never clear the texture for subsequent passes.
    if (pass_count_ > 0) {
      if (!render_target_.GetColorAttachments().empty()) {
        auto color0 = render_target_.GetColorAttachments().find(0)->second;
        color0.load_action = LoadAction::kLoad;
        render_target_.SetColorAttachment(color0, 0);
      }

      if (auto stencil = render_target_.GetStencilAttachment();
          stencil.has_value()) {
        stencil->load_action = LoadAction::kLoad;
        render_target_.SetStencilAttachment(stencil.value());
      }
    }

    pass_ = command_buffer_->CreateRenderPass(render_target_);
    if (!pass_) {
      return nullptr;
    }

    pass_->SetLabel(
        "EntityPass Render Pass: Depth=" + std::to_string(pass_depth) +
        " Count=" + std::to_string(pass_count_));

    ++pass_count_;
  }

  return pass_;
}

}  // namespace impeller
