// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <optional>

#include "flutter/impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

class PassBindingsCache {
 public:
  void BindPipeline(vk::CommandBuffer command_buffer,
                    vk::PipelineBindPoint pipeline_bind_point,
                    vk::Pipeline pipeline);

  void SetStencilReference(vk::CommandBuffer command_buffer,
                           vk::StencilFaceFlags face_mask,
                           uint32_t reference);

  void SetScissor(vk::CommandBuffer command_buffer,
                  uint32_t first_scissor,
                  uint32_t scissor_count,
                  const vk::Rect2D* scissors);

  void SetViewport(vk::CommandBuffer command_buffer,
                   uint32_t first_viewport,
                   uint32_t viewport_count,
                   const vk::Viewport* viewports);

 private:
  // bindPipeline
  std::optional<vk::Pipeline> graphics_pipeline_;
  std::optional<vk::Pipeline> compute_pipeline_;
  // setStencilReference
  std::optional<vk::StencilFaceFlags> stencil_face_flags_;
  uint32_t stencil_reference_ = 0;
  // setScissor
  std::optional<vk::Rect2D> scissors_;
  // setViewport
  std::optional<vk::Viewport> viewport_;
};

}  // namespace impeller
