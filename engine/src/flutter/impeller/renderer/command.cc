// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/command.h"

#include "impeller/base/validation.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/vertex_descriptor.h"

namespace impeller {

bool Command::BindVertices(const VertexBuffer& buffer) {
  if (buffer.index_type == IndexType::kUnknown) {
    VALIDATION_LOG << "Cannot bind vertex buffer with an unknown index type.";
    return false;
  }

  vertex_bindings.buffers[VertexDescriptor::kReservedVertexBufferIndex] = {
      nullptr, buffer.vertex_buffer};
  index_buffer = buffer.index_buffer;
  index_count = buffer.index_count;
  index_type = buffer.index_type;
  return true;
}

BufferView Command::GetVertexBuffer() const {
  auto found = vertex_bindings.buffers.find(
      VertexDescriptor::kReservedVertexBufferIndex);
  if (found != vertex_bindings.buffers.end()) {
    return found->second.resource;
  }
  return {};
}

bool Command::BindResource(ShaderStage stage,
                           const ShaderUniformSlot& slot,
                           const ShaderMetadata& metadata,
                           BufferView view) {
  if (!view) {
    return false;
  }

  switch (stage) {
    case ShaderStage::kVertex:
      vertex_bindings.buffers[slot.binding] = {&metadata, view};
      return true;
    case ShaderStage::kFragment:
      fragment_bindings.buffers[slot.binding] = {&metadata, view};
      return true;
    case ShaderStage::kTessellationControl:
    case ShaderStage::kTessellationEvaluation:
    case ShaderStage::kCompute:
    case ShaderStage::kUnknown:
      return false;
  }

  return false;
}

bool Command::BindResource(ShaderStage stage,
                           const SampledImageSlot& slot,
                           const ShaderMetadata& metadata,
                           std::shared_ptr<const Texture> texture) {
  if (!texture || !texture->IsValid()) {
    return false;
  }

  if (!slot.HasTexture()) {
    return true;
  }

  switch (stage) {
    case ShaderStage::kVertex:
      vertex_bindings.textures[slot.texture_index] = {&metadata, texture};
      return true;
    case ShaderStage::kFragment:
      fragment_bindings.textures[slot.texture_index] = {&metadata, texture};
      return true;
    case ShaderStage::kTessellationControl:
    case ShaderStage::kTessellationEvaluation:
    case ShaderStage::kCompute:
    case ShaderStage::kUnknown:
      return false;
  }

  return false;
}

bool Command::BindResource(ShaderStage stage,
                           const SampledImageSlot& slot,
                           const ShaderMetadata& metadata,
                           std::shared_ptr<const Sampler> sampler) {
  if (!sampler || !sampler->IsValid()) {
    return false;
  }

  if (!slot.HasSampler()) {
    return true;
  }

  switch (stage) {
    case ShaderStage::kVertex:
      vertex_bindings.samplers[slot.sampler_index] = {&metadata, sampler};
      return true;
    case ShaderStage::kFragment:
      fragment_bindings.samplers[slot.sampler_index] = {&metadata, sampler};
      return true;
    case ShaderStage::kUnknown:
    case ShaderStage::kTessellationControl:
    case ShaderStage::kTessellationEvaluation:
    case ShaderStage::kCompute:
      return false;
  }

  return false;
}

bool Command::BindResource(ShaderStage stage,
                           const SampledImageSlot& slot,
                           const ShaderMetadata& metadata,
                           std::shared_ptr<const Texture> texture,
                           std::shared_ptr<const Sampler> sampler) {
  return BindResource(stage, slot, metadata, texture) &&
         BindResource(stage, slot, metadata, sampler);
}

}  // namespace impeller
