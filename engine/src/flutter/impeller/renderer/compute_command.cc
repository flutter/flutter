// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/compute_command.h"

#include <utility>

#include "impeller/base/validation.h"
#include "impeller/core/formats.h"
#include "impeller/core/shader_types.h"

namespace impeller {

bool ComputeCommand::BindResource(ShaderStage stage,
                                  DescriptorType type,
                                  const ShaderUniformSlot& slot,
                                  const ShaderMetadata& metadata,
                                  BufferView view) {
  if (stage != ShaderStage::kCompute) {
    VALIDATION_LOG << "Use Command for non-compute shader stages.";
    return false;
  }
  if (!view) {
    return false;
  }

  bindings.buffers.emplace_back(
      BufferAndUniformSlot{.slot = slot, .view = {&metadata, std::move(view)}});
  return true;
}

bool ComputeCommand::BindResource(ShaderStage stage,
                                  DescriptorType type,
                                  const SampledImageSlot& slot,
                                  const ShaderMetadata& metadata,
                                  std::shared_ptr<const Texture> texture,
                                  std::shared_ptr<const Sampler> sampler) {
  if (stage != ShaderStage::kCompute) {
    VALIDATION_LOG << "Use Command for non-compute shader stages.";
    return false;
  }
  if (!sampler || !sampler->IsValid()) {
    return false;
  }
  if (!texture || !texture->IsValid()) {
    return false;
  }

  bindings.sampled_images.emplace_back(TextureAndSampler{
      .slot = slot,
      .texture = {&metadata, std::move(texture)},
      .sampler = std::move(sampler),
  });

  return false;
}

}  // namespace impeller
