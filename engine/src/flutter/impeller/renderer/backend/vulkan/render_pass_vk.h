// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/render_target.h"

namespace impeller {

class RenderPassVK final : public RenderPass {
 public:
  RenderPassVK(std::weak_ptr<const Context> context,
               RenderTarget target,
               vk::CommandBuffer command_buffer,
               vk::UniqueRenderPass render_pass);

  // |RenderPass|
  ~RenderPassVK() override;

 private:
  friend class CommandBufferVK;

  vk::CommandBuffer command_buffer_;
  vk::UniqueRenderPass render_pass_;
  std::string label_ = "";
  bool is_valid_ = false;

  // |RenderPass|
  bool IsValid() const override;

  // |RenderPass|
  void OnSetLabel(std::string label) override;

  // |RenderPass|
  bool OnEncodeCommands(const Context& context) const override;

  FML_DISALLOW_COPY_AND_ASSIGN(RenderPassVK);
};

}  // namespace impeller
