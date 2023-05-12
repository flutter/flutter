// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/command.h"

#include <utility>

#include "impeller/base/validation.h"
#include "impeller/core/formats.h"
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
  vertex_count = buffer.vertex_count;
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
                           const BufferView& view) {
  return DoBindResource(stage, slot, &metadata, view);
}

bool Command::BindResource(
    ShaderStage stage,
    const ShaderUniformSlot& slot,
    const std::shared_ptr<const ShaderMetadata>& metadata,
    const BufferView& view) {
  return DoBindResource(stage, slot, metadata, view);
}

template <class T>
bool Command::DoBindResource(ShaderStage stage,
                             const ShaderUniformSlot& slot,
                             const T metadata,
                             const BufferView& view) {
  if (!view) {
    return false;
  }

  switch (stage) {
    case ShaderStage::kVertex:
      vertex_bindings.uniforms[slot.ext_res_0] = slot;
      vertex_bindings.buffers[slot.ext_res_0] = BufferResource(metadata, view);
      return true;
    case ShaderStage::kFragment:
      fragment_bindings.uniforms[slot.ext_res_0] = slot;
      fragment_bindings.buffers[slot.ext_res_0] =
          BufferResource(metadata, view);
      return true;
    case ShaderStage::kCompute:
      VALIDATION_LOG << "Use ComputeCommands for compute shader stages.";
    case ShaderStage::kTessellationControl:
    case ShaderStage::kTessellationEvaluation:
    case ShaderStage::kUnknown:
      return false;
  }

  return false;
}

bool Command::BindResource(ShaderStage stage,
                           const SampledImageSlot& slot,
                           const ShaderMetadata& metadata,
                           const std::shared_ptr<const Texture>& texture) {
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
    case ShaderStage::kCompute:
      VALIDATION_LOG << "Use ComputeCommands for compute shader stages.";
    case ShaderStage::kTessellationControl:
    case ShaderStage::kTessellationEvaluation:
    case ShaderStage::kUnknown:
      return false;
  }

  return false;
}

bool Command::BindResource(ShaderStage stage,
                           const SampledImageSlot& slot,
                           const ShaderMetadata& metadata,
                           const std::shared_ptr<const Sampler>& sampler) {
  if (!sampler || !sampler->IsValid()) {
    return false;
  }

  if (!slot.HasSampler()) {
    return true;
  }

  switch (stage) {
    case ShaderStage::kVertex:
      vertex_bindings.samplers[slot.sampler_index] = {&metadata, sampler};
      vertex_bindings.sampled_images[slot.sampler_index] = slot;
      return true;
    case ShaderStage::kFragment:
      fragment_bindings.samplers[slot.sampler_index] = {&metadata, sampler};
      fragment_bindings.sampled_images[slot.sampler_index] = slot;
      return true;
    case ShaderStage::kCompute:
      VALIDATION_LOG << "Use ComputeCommands for compute shader stages.";
    case ShaderStage::kUnknown:
    case ShaderStage::kTessellationControl:
    case ShaderStage::kTessellationEvaluation:
      return false;
  }

  return false;
}

bool Command::BindResource(ShaderStage stage,
                           const SampledImageSlot& slot,
                           const ShaderMetadata& metadata,
                           const std::shared_ptr<const Texture>& texture,
                           const std::shared_ptr<const Sampler>& sampler) {
  return BindResource(stage, slot, metadata, texture) &&
         BindResource(stage, slot, metadata, sampler);
}

}  // namespace impeller
