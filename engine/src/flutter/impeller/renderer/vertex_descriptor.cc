// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/vertex_descriptor.h"

namespace impeller {

PipelineVertexDescriptor::PipelineVertexDescriptor() = default;

PipelineVertexDescriptor::~PipelineVertexDescriptor() = default;

bool PipelineVertexDescriptor::SetStageInputs(
    const ShaderStageIOSlot* const stage_inputs[],
    size_t count) {
  inputs_.reserve(inputs_.size() + count);
  for (size_t i = 0; i < count; i++) {
    inputs_.emplace_back(*stage_inputs[i]);
  }
  return true;
}

// |Comparable<VertexDescriptor>|
size_t PipelineVertexDescriptor::GetHash() const {
  auto seed = fml::HashCombine();
  for (const auto& input : inputs_) {
    fml::HashCombineSeed(seed, input.GetHash());
  }
  return seed;
}

// |Comparable<VertexDescriptor>|
bool PipelineVertexDescriptor::IsEqual(
    const PipelineVertexDescriptor& other) const {
  return inputs_ == other.inputs_;
}

const std::vector<ShaderStageIOSlot>& PipelineVertexDescriptor::GetStageInputs()
    const {
  return inputs_;
}

}  // namespace impeller
