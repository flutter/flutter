// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/pass_bindings_cache_mtl.h"

#include "impeller/renderer/backend/metal/formats_mtl.h"

namespace impeller {

void PassBindingsCacheMTL::SetEncoder(id<MTLRenderCommandEncoder> encoder) {
  encoder_ = encoder;
}

bool PassBindingsCacheMTL::SetRenderPipelineState(
    id<MTLRenderPipelineState> pipeline) {
  if (pipeline == pipeline_) {
    return false;
  }
  pipeline_ = pipeline;
  [encoder_ setRenderPipelineState:pipeline_];
  return true;
}

void PassBindingsCacheMTL::SetDepthStencilState(
    id<MTLDepthStencilState> depth_stencil) {
  if (depth_stencil_ == depth_stencil) {
    return;
  }
  depth_stencil_ = depth_stencil;
  [encoder_ setDepthStencilState:depth_stencil_];
}

bool PassBindingsCacheMTL::SetBuffer(ShaderStage stage,
                                     uint64_t index,
                                     uint64_t offset,
                                     id<MTLBuffer> buffer) {
  if (index == kOptimizedOutBinding) {
    // The shader compiler dead-code-eliminated this resource, so it has no
    // argument-table slot. Skip the bind rather than forward an out-of-range
    // index to Metal, which has no bounds check and would crash.
    return true;
  }
  if (!IsCacheableStage(stage) || index >= kMaxBindingIndex) {
    VALIDATION_LOG << "Cannot bind buffer to an unknown stage or out of range "
                      "binding index.";
    return false;
  }
  auto& slots = buffers_[static_cast<size_t>(stage)];
  if (index >= slots.size()) {
    slots.resize(index + 1);
  }
  BufferOffsetPair& slot = slots[index];
  if (slot.buffer == buffer) {
    // The right buffer is bound. Check if its offset needs to be updated.
    if (slot.offset == offset) {
      // Buffer and its offset is identical. Nothing to do.
      return true;
    }

    // Only the offset needs to be updated.
    slot.offset = offset;

    switch (stage) {
      case ShaderStage::kVertex:
        [encoder_ setVertexBufferOffset:offset atIndex:index];
        return true;
      case ShaderStage::kFragment:
        [encoder_ setFragmentBufferOffset:offset atIndex:index];
        return true;
      default:
        break;
    }
  }
  slot = {buffer, static_cast<size_t>(offset)};
  switch (stage) {
    case ShaderStage::kVertex:
      [encoder_ setVertexBuffer:buffer offset:offset atIndex:index];
      return true;
    case ShaderStage::kFragment:
      [encoder_ setFragmentBuffer:buffer offset:offset atIndex:index];
      return true;
    default:
      break;
  }
  return false;
}

bool PassBindingsCacheMTL::SetTexture(ShaderStage stage,
                                      uint64_t index,
                                      id<MTLTexture> texture) {
  if (index == kOptimizedOutBinding) {
    // See SetBuffer: a dead-code-eliminated sampler has no argument-table slot.
    return true;
  }
  if (!IsCacheableStage(stage) || index >= kMaxBindingIndex) {
    VALIDATION_LOG << "Cannot bind texture to an unknown stage or out of range "
                      "binding index.";
    return false;
  }
  auto& slots = textures_[static_cast<size_t>(stage)];
  if (index >= slots.size()) {
    slots.resize(index + 1);
  }
  if (slots[index] == texture) {
    // Already bound.
    return true;
  }
  slots[index] = texture;
  switch (stage) {
    case ShaderStage::kVertex:
      [encoder_ setVertexTexture:texture atIndex:index];
      return true;
    case ShaderStage::kFragment:
      [encoder_ setFragmentTexture:texture atIndex:index];
      return true;
    default:
      break;
  }
  return false;
}

bool PassBindingsCacheMTL::SetSampler(ShaderStage stage,
                                      uint64_t index,
                                      id<MTLSamplerState> sampler) {
  if (index == kOptimizedOutBinding) {
    // See SetBuffer: a dead-code-eliminated sampler has no argument-table slot.
    return true;
  }
  if (!IsCacheableStage(stage) || index >= kMaxBindingIndex) {
    VALIDATION_LOG << "Cannot bind sampler to an unknown stage or out of range "
                      "binding index.";
    return false;
  }
  auto& slots = samplers_[static_cast<size_t>(stage)];
  if (index >= slots.size()) {
    slots.resize(index + 1);
  }
  if (slots[index] == sampler) {
    // Already bound.
    return true;
  }
  slots[index] = sampler;
  switch (stage) {
    case ShaderStage::kVertex:
      [encoder_ setVertexSamplerState:sampler atIndex:index];
      return true;
    case ShaderStage::kFragment:
      [encoder_ setFragmentSamplerState:sampler atIndex:index];
      return true;
    default:
      break;
  }
  return false;
}

void PassBindingsCacheMTL::SetViewport(const Viewport& viewport) {
  if (viewport_.has_value() && viewport_.value() == viewport) {
    return;
  }
  [encoder_ setViewport:MTLViewport{
                            .originX = viewport.rect.GetX(),
                            .originY = viewport.rect.GetY(),
                            .width = viewport.rect.GetWidth(),
                            .height = viewport.rect.GetHeight(),
                            .znear = viewport.depth_range.z_near,
                            .zfar = viewport.depth_range.z_far,
                        }];
  viewport_ = viewport;
}

void PassBindingsCacheMTL::SetScissor(const IRect32& scissor) {
  if (scissor_.has_value() && scissor_.value() == scissor) {
    return;
  }
  [encoder_
      setScissorRect:MTLScissorRect{
                         .x = static_cast<NSUInteger>(scissor.GetX()),
                         .y = static_cast<NSUInteger>(scissor.GetY()),
                         .width = static_cast<NSUInteger>(scissor.GetWidth()),
                         .height = static_cast<NSUInteger>(scissor.GetHeight()),
                     }];
  scissor_ = scissor;
}

void PassBindingsCacheMTL::SetStencilRef(uint32_t stencil_ref) {
  if (stencil_ref_.has_value() && stencil_ref_.value() == stencil_ref) {
    return;
  }
  [encoder_ setStencilReferenceValue:stencil_ref];
  stencil_ref_ = stencil_ref;
}

void PassBindingsCacheMTL::SetWindingOrder(WindingOrder winding) {
  if (winding_.has_value() && winding_.value() == winding) {
    return;
  }
  [encoder_ setFrontFacingWinding:winding == WindingOrder::kClockwise
                                      ? MTLWindingClockwise
                                      : MTLWindingCounterClockwise];
  winding_ = winding;
}

void PassBindingsCacheMTL::SetCullMode(CullMode cull_mode) {
  if (cull_mode_.has_value() && cull_mode_.value() == cull_mode) {
    return;
  }
  [encoder_ setCullMode:ToMTLCullMode(cull_mode)];
  cull_mode_ = cull_mode;
}

void PassBindingsCacheMTL::SetPolygonMode(PolygonMode polygon_mode) {
  if (polygon_mode_.has_value() && polygon_mode_.value() == polygon_mode) {
    return;
  }
  [encoder_ setTriangleFillMode:ToMTLTriangleFillMode(polygon_mode)];
  polygon_mode_ = polygon_mode;
}

}  // namespace impeller
