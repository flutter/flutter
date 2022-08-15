// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/render_pass_vk.h"

#include "fml/logging.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"

namespace impeller {

RenderPassVK::RenderPassVK(std::weak_ptr<const Context> context,
                           RenderTarget target,
                           vk::CommandBuffer command_buffer,
                           vk::UniqueRenderPass render_pass)
    : RenderPass(context, target),
      command_buffer_(command_buffer),
      render_pass_(std::move(render_pass)) {
  is_valid_ = true;
}

RenderPassVK::~RenderPassVK() = default;

bool RenderPassVK::IsValid() const {
  return is_valid_;
}

void RenderPassVK::OnSetLabel(std::string label) {
  label_ = std::move(label);
}

bool RenderPassVK::OnEncodeCommands(const Context& context) const {
  if (!IsValid()) {
    return false;
  }
  if (commands_.empty()) {
    return true;
  }
  const auto& render_target = GetRenderTarget();
  if (!render_target.HasColorAttachment(0u)) {
    return false;
  }
  const auto& color0 = render_target.GetColorAttachments().at(0u);
  const auto& depth0 = render_target.GetDepthAttachment();
  const auto& stencil0 = render_target.GetStencilAttachment();

  auto& wrapped_texture = TextureVK::Cast(*color0.texture);

  FML_UNREACHABLE();
}

}  // namespace impeller
