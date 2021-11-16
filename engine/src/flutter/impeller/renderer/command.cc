// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/command.h"

#include "impeller/renderer/vertex_descriptor.h"

namespace impeller {

bool Command::BindVertices(const VertexBuffer& buffer) {
  vertex_bindings.buffers[VertexDescriptor::kReservedVertexBufferIndex] =
      buffer.vertex_buffer;
  index_buffer = buffer.index_buffer;
  index_count = buffer.index_count;
  return true;
}

bool Command::BindResource(ShaderStage stage, size_t binding, BufferView view) {
  if (!view) {
    return false;
  }

  switch (stage) {
    case ShaderStage::kVertex:
      vertex_bindings.buffers[binding] = view;
      return true;
    case ShaderStage::kFragment:
      fragment_bindings.buffers[binding] = view;
      return true;
    case ShaderStage::kUnknown:
      return false;
  }

  return false;
}

bool Command::BindResource(ShaderStage stage,
                           const SampledImageSlot& slot,
                           std::shared_ptr<const Texture> texture) {
  if (!texture || !texture->IsValid()) {
    return false;
  }

  if (!slot.HasTexture()) {
    return true;
  }

  switch (stage) {
    case ShaderStage::kVertex:
      vertex_bindings.textures[slot.texture_index] = texture;
      return true;
    case ShaderStage::kFragment:
      fragment_bindings.textures[slot.texture_index] = texture;
      return true;
    case ShaderStage::kUnknown:
      return false;
  }

  return false;
}

bool Command::BindResource(ShaderStage stage,
                           const SampledImageSlot& slot,
                           std::shared_ptr<const Sampler> sampler) {
  if (!sampler || !sampler->IsValid()) {
    return false;
  }

  if (!slot.HasSampler()) {
    return true;
  }

  switch (stage) {
    case ShaderStage::kVertex:
      vertex_bindings.samplers[slot.sampler_index] = sampler;
      return true;
    case ShaderStage::kFragment:
      fragment_bindings.samplers[slot.sampler_index] = sampler;
      return true;
    case ShaderStage::kUnknown:
      return false;
  }

  return false;
}

bool Command::BindResource(ShaderStage stage,
                           const SampledImageSlot& slot,
                           std::shared_ptr<const Texture> texture,
                           std::shared_ptr<const Sampler> sampler) {
  return BindResource(stage, slot, texture) &&
         BindResource(stage, slot, sampler);
}

}  // namespace impeller
