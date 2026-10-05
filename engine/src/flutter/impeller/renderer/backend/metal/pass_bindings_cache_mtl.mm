// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/pass_bindings_cache_mtl.h"

namespace impeller {

void PassBindingsCacheMTL::SetEncoder(id<MTLRenderCommandEncoder> encoder) {
  encoder_ = encoder;
}

void PassBindingsCacheMTL::SetRenderPipelineState(
    id<MTLRenderPipelineState> pipeline) {
  if (pipeline == pipeline_) {
    return;
  }
  pipeline_ = pipeline;
  [encoder_ setRenderPipelineState:pipeline_];
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
  auto& buffers_map = buffers_[stage];
  auto found = buffers_map.find(index);
  if (found != buffers_map.end() && found->second.buffer == buffer) {
    // The right buffer is bound. Check if its offset needs to be updated.
    if (found->second.offset == offset) {
      // Buffer and its offset is identical. Nothing to do.
      return true;
    }

    // Only the offset needs to be updated.
    found->second.offset = offset;

    switch (stage) {
      case ShaderStage::kVertex:
        [encoder_ setVertexBufferOffset:offset atIndex:index];
        return true;
      case ShaderStage::kFragment:
        [encoder_ setFragmentBufferOffset:offset atIndex:index];
        return true;
      default:
        VALIDATION_LOG << "Cannot update buffer offset of an unknown stage.";
        return false;
    }
    return true;
  }
  buffers_map[index] = {buffer, static_cast<size_t>(offset)};
  switch (stage) {
    case ShaderStage::kVertex:
      [encoder_ setVertexBuffer:buffer offset:offset atIndex:index];
      return true;
    case ShaderStage::kFragment:
      [encoder_ setFragmentBuffer:buffer offset:offset atIndex:index];
      return true;
    default:
      VALIDATION_LOG << "Cannot bind buffer to unknown shader stage.";
      return false;
  }
  return false;
}

bool PassBindingsCacheMTL::SetBytes(ShaderStage stage,
                                    uint64_t index,
                                    const void* bytes,
                                    size_t length) {
  if (index == kOptimizedOutBinding) {
    // See SetBuffer: a dead-code-eliminated block has no argument-table slot.
    return true;
  }
  // Metal binds a driver-owned allocation at this index, so a buffer bound
  // here earlier is no longer what the shader reads.
  buffers_[stage][index] = {nullptr, 0u};
  switch (stage) {
    case ShaderStage::kVertex:
      [encoder_ setVertexBytes:bytes length:length atIndex:index];
      return true;
    case ShaderStage::kFragment:
      [encoder_ setFragmentBytes:bytes length:length atIndex:index];
      return true;
    default:
      VALIDATION_LOG << "Cannot set bytes on an unknown shader stage.";
      return false;
  }
}

bool PassBindingsCacheMTL::SetTexture(ShaderStage stage,
                                      uint64_t index,
                                      id<MTLTexture> texture) {
  if (index == kOptimizedOutBinding) {
    // See SetBuffer: a dead-code-eliminated sampler has no argument-table slot.
    return true;
  }
  auto& texture_map = textures_[stage];
  auto found = texture_map.find(index);
  if (found != texture_map.end() && found->second == texture) {
    // Already bound.
    return true;
  }
  texture_map[index] = texture;
  switch (stage) {
    case ShaderStage::kVertex:
      [encoder_ setVertexTexture:texture atIndex:index];
      return true;
    case ShaderStage::kFragment:
      [encoder_ setFragmentTexture:texture atIndex:index];
      return true;
    default:
      VALIDATION_LOG << "Cannot bind buffer to unknown shader stage.";
      return false;
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
  auto& sampler_map = samplers_[stage];
  auto found = sampler_map.find(index);
  if (found != sampler_map.end() && found->second == sampler) {
    // Already bound.
    return true;
  }
  sampler_map[index] = sampler;
  switch (stage) {
    case ShaderStage::kVertex:
      [encoder_ setVertexSamplerState:sampler atIndex:index];
      return true;
    case ShaderStage::kFragment:
      [encoder_ setFragmentSamplerState:sampler atIndex:index];
      return true;
    default:
      VALIDATION_LOG << "Cannot bind buffer to unknown shader stage.";
      return false;
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

}  // namespace impeller
