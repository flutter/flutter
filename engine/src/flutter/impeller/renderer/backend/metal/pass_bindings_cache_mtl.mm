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
                                     __unsafe_unretained id<MTLBuffer> buffer) {
  if (index == kOptimizedOutBinding) {
    // The shader compiler dead-code-eliminated this resource, so it has no
    // argument-table slot. Skip the bind rather than forward an out-of-range
    // index to Metal, which has no bounds check and would crash.
    return true;
  }
  if (stage != ShaderStage::kVertex && stage != ShaderStage::kFragment) {
    VALIDATION_LOG << "Cannot bind buffer to unknown shader stage.";
    return false;
  }
  const bool is_vertex = stage == ShaderStage::kVertex;
  if (index < kMaxBuffers) {
    BufferOffsetPair& bound = buffers_[is_vertex ? 0 : 1][index];
    if (bound.buffer == buffer) {
      // The right buffer is bound. Check if its offset needs to be updated.
      if (bound.offset == offset) {
        // Buffer and its offset is identical. Nothing to do.
        return true;
      }

      // Only the offset needs to be updated.
      bound.offset = offset;
      if (is_vertex) {
        [encoder_ setVertexBufferOffset:offset atIndex:index];
      } else {
        [encoder_ setFragmentBufferOffset:offset atIndex:index];
      }
      return true;
    }
    bound.buffer = buffer;
    bound.offset = static_cast<size_t>(offset);
  }
  if (is_vertex) {
    [encoder_ setVertexBuffer:buffer offset:offset atIndex:index];
  } else {
    [encoder_ setFragmentBuffer:buffer offset:offset atIndex:index];
  }
  return true;
}

bool PassBindingsCacheMTL::SetTexture(
    ShaderStage stage,
    uint64_t index,
    __unsafe_unretained id<MTLTexture> texture) {
  if (index == kOptimizedOutBinding) {
    // See SetBuffer: a dead-code-eliminated sampler has no argument-table slot.
    return true;
  }
  if (stage != ShaderStage::kVertex && stage != ShaderStage::kFragment) {
    VALIDATION_LOG << "Cannot bind buffer to unknown shader stage.";
    return false;
  }
  const bool is_vertex = stage == ShaderStage::kVertex;
  if (index < kMaxTextures) {
    __unsafe_unretained id<MTLTexture>& bound =
        textures_[is_vertex ? 0 : 1][index];
    if (bound == texture) {
      // Already bound.
      return true;
    }
    bound = texture;
  }
  if (is_vertex) {
    [encoder_ setVertexTexture:texture atIndex:index];
  } else {
    [encoder_ setFragmentTexture:texture atIndex:index];
  }
  return true;
}

bool PassBindingsCacheMTL::SetSampler(
    ShaderStage stage,
    uint64_t index,
    __unsafe_unretained id<MTLSamplerState> sampler) {
  if (index == kOptimizedOutBinding) {
    // See SetBuffer: a dead-code-eliminated sampler has no argument-table slot.
    return true;
  }
  if (stage != ShaderStage::kVertex && stage != ShaderStage::kFragment) {
    VALIDATION_LOG << "Cannot bind buffer to unknown shader stage.";
    return false;
  }
  const bool is_vertex = stage == ShaderStage::kVertex;
  if (index < kMaxSamplers) {
    __unsafe_unretained id<MTLSamplerState>& bound =
        samplers_[is_vertex ? 0 : 1][index];
    if (bound == sampler) {
      // Already bound.
      return true;
    }
    bound = sampler;
  }
  if (is_vertex) {
    [encoder_ setVertexSamplerState:sampler atIndex:index];
  } else {
    [encoder_ setFragmentSamplerState:sampler atIndex:index];
  }
  return true;
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
