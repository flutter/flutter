// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <vector>
#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/vulkan/surface_producer_vk.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/command.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/render_target.h"
#include "vulkan/vulkan_structs.hpp"

namespace impeller {

class RenderPassVK final : public RenderPass {
 public:
  RenderPassVK(std::weak_ptr<const Context> context,
               vk::Device device,
               RenderTarget target,
               vk::UniqueCommandBuffer command_buffer,
               vk::UniqueRenderPass render_pass,
               SurfaceProducerVK* surface_producer);

  // |RenderPass|
  ~RenderPassVK() override;

 private:
  friend class CommandBufferVK;

  vk::Device device_;
  vk::UniqueCommandBuffer command_buffer_;
  vk::UniqueRenderPass render_pass_;
  SurfaceProducerVK* surface_producer_;

  std::string label_ = "";
  bool is_valid_ = false;

  // |RenderPass|
  bool IsValid() const override;

  // |RenderPass|
  void OnSetLabel(std::string label) override;

  // |RenderPass|
  bool OnEncodeCommands(const Context& context) const override;

  bool EncodeCommand(const Context& context, const Command& command) const;

  bool AllocateAndBindDescriptorSets(
      const Context& context,
      const Command& command,
      PipelineCreateInfoVK* pipeline_create_info) const;

  bool EndCommandBuffer(uint32_t frame_num);

  bool UpdateDescriptorSets(const char* label,
                            const Bindings& bindings,
                            Allocator& allocator,
                            vk::DescriptorSet desc_set) const;

  void SetViewportAndScissor(const Command& command) const;

  vk::Framebuffer CreateFrameBuffer(
      const WrappedTextureInfoVK& wrapped_texture_info) const;

  FML_DISALLOW_COPY_AND_ASSIGN(RenderPassVK);
};

}  // namespace impeller
