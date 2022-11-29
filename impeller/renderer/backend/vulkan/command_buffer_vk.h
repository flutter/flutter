// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/vulkan/command_pool_vk.h"
#include "impeller/renderer/backend/vulkan/fenced_command_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/surface_producer_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/command_buffer.h"

namespace impeller {

class CommandBufferVK final : public CommandBuffer {
 public:
  static std::shared_ptr<CommandBufferVK> Create(
      const std::weak_ptr<const Context>& context,
      vk::Device device);

  CommandBufferVK(std::weak_ptr<const Context> context,
                  vk::Device device,
                  std::unique_ptr<CommandPoolVK> command_pool,
                  std::shared_ptr<FencedCommandBufferVK> command_buffer);

  // |CommandBuffer|
  ~CommandBufferVK() override;

 private:
  friend class ContextVK;

  vk::Device device_;
  std::unique_ptr<CommandPoolVK> command_pool_;
  vk::UniqueRenderPass render_pass_;
  std::shared_ptr<FencedCommandBufferVK> fenced_command_buffer_;
  bool is_valid_ = false;

  // |CommandBuffer|
  void SetLabel(const std::string& label) const override;

  // |CommandBuffer|
  bool IsValid() const override;

  // |CommandBuffer|
  bool OnSubmitCommands(CompletionCallback callback) override;

  // |CommandBuffer|
  std::shared_ptr<RenderPass> OnCreateRenderPass(RenderTarget target) override;

  // |CommandBuffer|
  std::shared_ptr<BlitPass> OnCreateBlitPass() const override;

  // |CommandBuffer|
  std::shared_ptr<ComputePass> OnCreateComputePass() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(CommandBufferVK);
};

}  // namespace impeller
