// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/compute_pipeline_descriptor.h"

#include "impeller/base/validation.h"
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
  fml::HashCombineSeed(seed, workgroup_size_[0], workgroup_size_[1],
                       workgroup_size_[2]);
  return seed;
}

// Comparable<ComputePipelineDescriptor>
bool ComputePipelineDescriptor::IsEqual(
    const ComputePipelineDescriptor& other) const {
  return label_ == other.label_ &&
         DeepComparePointer(entrypoint_, other.entrypoint_) &&
         workgroup_size_ == other.workgroup_size_;
}

ComputePipelineDescriptor& ComputePipelineDescriptor::SetLabel(
    std::string_view label) {
  label_ = label;
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

ComputePipelineDescriptor& ComputePipelineDescriptor::SetWorkgroupSize(
    std::array<uint32_t, 3> size) {
  workgroup_size_ = size;
  return *this;
}

std::array<uint32_t, 3> ComputePipelineDescriptor::GetWorkgroupSize() const {
  return workgroup_size_;
}

bool ComputePipelineDescriptor::ValidateWorkgroupSize(
    std::array<uint32_t, 3> max_size,
    uint64_t max_invocations) const {
  const auto& size = workgroup_size_;
  if (size[0] == 0u || size[1] == 0u || size[2] == 0u) {
    VALIDATION_LOG << "Compute pipeline " << label_
                   << " has a workgroup size of 0 in some dimension. A compute "
                      "shader must declare a literal local_size; sizing it "
                      "with a specialization constant is not supported.";
    return false;
  }
  if (size[0] > max_size[0] || size[1] > max_size[1] || size[2] > max_size[2]) {
    VALIDATION_LOG << "Compute pipeline " << label_
                   << " has a workgroup size of " << size[0] << "x" << size[1]
                   << "x" << size[2] << ", which exceeds the device maximum of "
                   << max_size[0] << "x" << max_size[1] << "x" << max_size[2]
                   << ".";
    return false;
  }
  const uint64_t invocations =
      static_cast<uint64_t>(size[0]) * size[1] * size[2];
  if (invocations > max_invocations) {
    VALIDATION_LOG << "Compute pipeline " << label_
                   << " has a workgroup size of " << size[0] << "x" << size[1]
                   << "x" << size[2] << " (" << invocations
                   << " invocations), which exceeds the maximum of "
                   << max_invocations << " invocations per workgroup.";
    return false;
  }
  return true;
}

const std::string& ComputePipelineDescriptor::GetLabel() const {
  return label_;
}

bool ComputePipelineDescriptor::RegisterDescriptorSetLayouts(
    const DescriptorSetLayout desc_set_layout[],
    size_t count) {
  descriptor_set_layouts_.reserve(descriptor_set_layouts_.size() + count);
  for (size_t i = 0; i < count; i++) {
    descriptor_set_layouts_.emplace_back(desc_set_layout[i]);
  }
  return true;
}

const std::vector<DescriptorSetLayout>&
ComputePipelineDescriptor::GetDescriptorSetLayouts() const {
  return descriptor_set_layouts_;
}

}  // namespace impeller
