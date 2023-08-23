// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/compute_command.h"

#include <utility>

#include "impeller/base/validation.h"
#include "impeller/core/formats.h"

namespace impeller {

bool ComputeCommand::BindResource(ShaderStage stage,
                                  const ShaderUniformSlot& slot,
                                  const ShaderMetadata& metadata,
                                  const BufferView& view) {
  if (stage != ShaderStage::kCompute) {
    VALIDATION_LOG << "Use Command for non-compute shader stages.";
    return false;
  }
  if (!view) {
    return false;
  }

  bindings.buffers[slot.ext_res_0] = {.slot = slot, .view = {&metadata, view}};
  return true;
}

bool ComputeCommand::BindResource(
    ShaderStage stage,
    const SampledImageSlot& slot,
    const ShaderMetadata& metadata,
    const std::shared_ptr<const Texture>& texture,
    const std::shared_ptr<const Sampler>& sampler) {
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
  if (!slot.HasSampler() || !slot.HasTexture()) {
    return true;
  }

  bindings.sampled_images[slot.sampler_index] = TextureAndSampler{
      .slot = slot,
      .texture = {&metadata, texture},
      .sampler = {&metadata, sampler},
  };

  return false;
}

}  // namespace impeller
