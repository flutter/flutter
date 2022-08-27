// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/inline_pass_context.h"

#include "impeller/base/validation.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/formats.h"

namespace impeller {

InlinePassContext::InlinePassContext(std::shared_ptr<Context> context,
                                     RenderTarget render_target,
                                     uint32_t pass_texture_reads)
    : context_(context),
      render_target_(render_target),
      total_pass_reads_(pass_texture_reads) {}

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
  return render_target_.GetRenderTargetTexture();
}

bool InlinePassContext::EndPass() {
  if (!IsActive()) {
    return true;
  }

  if (!pass_->EncodeCommands()) {
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
  if (IsActive()) {
    return pass_;
  }

  /// Create a new render pass if one isn't active. This path will run the first
  /// time this method is called, but it'll also run if the pass has been
  /// previously ended via `EndPass`.

  command_buffer_ = context_->CreateCommandBuffer();
  if (!command_buffer_) {
    VALIDATION_LOG << "Could not create command buffer.";
    return nullptr;
  }

  if (render_target_.GetColorAttachments().empty()) {
    VALIDATION_LOG << "Color attachment unexpectedly missing from the "
                      "EntityPass render target.";
    return nullptr;
  }
  auto color0 = render_target_.GetColorAttachments().find(0)->second;

  auto stencil = render_target_.GetStencilAttachment();
  if (!stencil.has_value()) {
    VALIDATION_LOG << "Stencil attachment unexpectedly missing from the "
                      "EntityPass render target.";
    return nullptr;
  }

  command_buffer_->SetLabel(
      "EntityPass Command Buffer: Depth=" + std::to_string(pass_depth) +
      " Count=" + std::to_string(pass_count_));

  // Only clear the color and stencil if this is the very first pass of the
  // layer.
  color0.load_action = pass_count_ > 0 ? LoadAction::kLoad : LoadAction::kClear;
  stencil->load_action = color0.load_action;

  // If we're on the last pass of the layer, there's no need to store the
  // multisample texture or stencil because nothing needs to read it.
  if (color0.resolve_texture) {
    color0.store_action = pass_count_ == total_pass_reads_
                              ? StoreAction::kMultisampleResolve
                              : StoreAction::kStoreAndMultisampleResolve;
  } else {
    color0.store_action = StoreAction::kStore;
  }
  stencil->store_action = pass_count_ == total_pass_reads_
                              ? StoreAction::kDontCare
                              : StoreAction::kStore;

  render_target_.SetColorAttachment(color0, 0);
  render_target_.SetStencilAttachment(stencil.value());

  pass_ = command_buffer_->CreateRenderPass(render_target_);
  if (!pass_) {
    VALIDATION_LOG << "Could not create render pass.";
    return nullptr;
  }

  pass_->SetLabel(
      "EntityPass Render Pass: Depth=" + std::to_string(pass_depth) +
      " Count=" + std::to_string(pass_count_));

  ++pass_count_;

  return pass_;
}

}  // namespace impeller
