// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/pass_bindings_cache.h"

namespace impeller {
void PassBindingsCache::BindPipeline(vk::CommandBuffer command_buffer,
                                     vk::PipelineBindPoint pipeline_bind_point,
                                     vk::Pipeline pipeline) {
  switch (pipeline_bind_point) {
    case vk::PipelineBindPoint::eGraphics:
      if (graphics_pipeline_.has_value() &&
          graphics_pipeline_.value() == pipeline) {
        return;
      }
      graphics_pipeline_ = pipeline;
      break;
    case vk::PipelineBindPoint::eCompute:
      if (compute_pipeline_.has_value() &&
          compute_pipeline_.value() == pipeline) {
        return;
      }
      compute_pipeline_ = pipeline;
      break;
    default:
      break;
  }
  command_buffer.bindPipeline(pipeline_bind_point, pipeline);
}

void PassBindingsCache::SetStencilReference(vk::CommandBuffer command_buffer,
                                            vk::StencilFaceFlags face_mask,
                                            uint32_t reference) {
  if (stencil_face_flags_.has_value() &&
      face_mask == stencil_face_flags_.value() &&
      reference == stencil_reference_) {
    return;
  }
  stencil_face_flags_ = face_mask;
  stencil_reference_ = reference;
  command_buffer.setStencilReference(face_mask, reference);
}

void PassBindingsCache::SetScissor(vk::CommandBuffer command_buffer,
                                   uint32_t first_scissor,
                                   uint32_t scissor_count,
                                   const vk::Rect2D* scissors) {
  if (first_scissor == 0 && scissor_count == 1) {
    if (scissors_.has_value() && scissors_.value() == scissors[0]) {
      return;
    }
    scissors_ = scissors[0];
  }
  command_buffer.setScissor(first_scissor, scissor_count, scissors);
}

void PassBindingsCache::SetViewport(vk::CommandBuffer command_buffer,
                                    uint32_t first_viewport,
                                    uint32_t viewport_count,
                                    const vk::Viewport* viewports) {
  if (first_viewport == 0 && viewport_count == 1) {
    // Note that this is doing equality checks on floating point numbers.
    if (viewport_.has_value() && viewport_.value() == viewports[0]) {
      return;
    }
    viewport_ = viewports[0];
  }
  command_buffer.setViewport(first_viewport, viewport_count, viewports);
}

}  // namespace impeller
