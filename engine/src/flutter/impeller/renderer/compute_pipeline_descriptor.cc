// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/compute_pipeline_descriptor.h"

#include "impeller/core/formats.h"
#include "impeller/renderer/shader_function.h"
#include "impeller/renderer/shader_library.h"
#include "impeller/renderer/vertex_descriptor.h"

namespace impeller {

ComputePipelineDescriptor::ComputePipelineDescriptor() = default;

ComputePipelineDescriptor::~ComputePipelineDescriptor() = default;

// Comparable<ComputePipelineDescriptor>
std::size_t ComputePipelineDescriptor::GetHash() const {
  auto seed = fml::HashCombine();
  fml::HashCombineSeed(seed, label_);
  if (entrypoint_) {
    fml::HashCombineSeed(seed, entrypoint_->GetHash());
  }
  return seed;
}

// Comparable<ComputePipelineDescriptor>
bool ComputePipelineDescriptor::IsEqual(
    const ComputePipelineDescriptor& other) const {
  return label_ == other.label_ &&
         DeepComparePointer(entrypoint_, other.entrypoint_);
}

ComputePipelineDescriptor& ComputePipelineDescriptor::SetLabel(
    std::string label) {
  label_ = std::move(label);
  return *this;
}

ComputePipelineDescriptor& ComputePipelineDescriptor::SetStageEntrypoint(
    std::shared_ptr<const ShaderFunction> function) {
  FML_DCHECK(!function || function->GetStage() == ShaderStage::kCompute);
  if (!function || function->GetStage() != ShaderStage::kCompute) {
    return *this;
  }

  if (function->GetStage() == ShaderStage::kUnknown) {
    return *this;
  }

  entrypoint_ = std::move(function);

  return *this;
}

std::shared_ptr<const ShaderFunction>
ComputePipelineDescriptor::GetStageEntrypoint() const {
  return entrypoint_;
}

const std::string& ComputePipelineDescriptor::GetLabel() const {
  return label_;
}

}  // namespace impeller
