// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/inline_pass_context.h"

#include <utility>

#include "impeller/base/validation.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/texture_descriptor.h"

namespace impeller {

InlinePassContext::InlinePassContext(
    std::shared_ptr<Context> context,
    const RenderTarget& render_target,
    uint32_t pass_texture_reads,
    std::optional<RenderPassResult> collapsed_parent_pass)
    : context_(std::move(context)),
      render_target_(render_target),
      total_pass_reads_(pass_texture_reads),
      is_collapsed_(collapsed_parent_pass.has_value()) {
  if (collapsed_parent_pass.has_value()) {
    pass_ = collapsed_parent_pass.value().pass;
  }
}

InlinePassContext::~InlinePassContext() {
  if (!is_collapsed_) {
    EndPass();
  }
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

InlinePassContext::RenderPassResult InlinePassContext::GetRenderPass(
    uint32_t pass_depth) {
  if (IsActive()) {
    return {.pass = pass_};
  }

  /// Create a new render pass if one isn't active. This path will run the first
  /// time this method is called, but it'll also run if the pass has been
  /// previously ended via `EndPass`.

  command_buffer_ = context_->CreateCommandBuffer();
  if (!command_buffer_) {
    VALIDATION_LOG << "Could not create command buffer.";
    return {};
  }

  if (render_target_.GetColorAttachments().empty()) {
    VALIDATION_LOG << "Color attachment unexpectedly missing from the "
                      "EntityPass render target.";
    return {};
  }
  auto color0 = render_target_.GetColorAttachments().find(0)->second;

  command_buffer_->SetLabel(
      "EntityPass Command Buffer: Depth=" + std::to_string(pass_depth) +
      " Count=" + std::to_string(pass_count_));

  RenderPassResult result;

  if (pass_count_ > 0 && color0.resolve_texture) {
    result.backdrop_texture = color0.resolve_texture;
  }

  if (color0.resolve_texture) {
    color0.load_action =
        pass_count_ > 0 ? LoadAction::kDontCare : LoadAction::kClear;
    color0.store_action = StoreAction::kMultisampleResolve;
  } else {
    color0.load_action = LoadAction::kClear;
    color0.store_action = StoreAction::kStore;
  }

  auto stencil = render_target_.GetStencilAttachment();
  if (!stencil.has_value()) {
    VALIDATION_LOG << "Stencil attachment unexpectedly missing from the "
                      "EntityPass render target.";
    return {};
  }

  // Only clear the stencil if this is the very first pass of the
  // layer.
  stencil->load_action =
      pass_count_ > 0 ? LoadAction::kLoad : LoadAction::kClear;
  // If we're on the last pass of the layer, there's no need to store the
  // stencil because nothing needs to read it.
  stencil->store_action = pass_count_ == total_pass_reads_
                              ? StoreAction::kDontCare
                              : StoreAction::kStore;
  render_target_.SetStencilAttachment(stencil.value());

  render_target_.SetColorAttachment(color0, 0);

  pass_ = command_buffer_->CreateRenderPass(render_target_);
  if (!pass_) {
    VALIDATION_LOG << "Could not create render pass.";
    return {};
  }

  pass_->SetLabel(
      "EntityPass Render Pass: Depth=" + std::to_string(pass_depth) +
      " Count=" + std::to_string(pass_count_));

  ++pass_count_;

  result.pass = pass_;
  return result;
}

uint32_t InlinePassContext::GetPassCount() const {
  return pass_count_;
}

}  // namespace impeller
