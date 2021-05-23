// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/pipeline_descriptor.h"

#include "impeller/compositor/shader_library.h"
#include "impeller/compositor/vertex_descriptor.h"

namespace impeller {

PipelineDescriptor::PipelineDescriptor() = default;

PipelineDescriptor::~PipelineDescriptor() = default;

// Comparable<PipelineDescriptor>
std::size_t PipelineDescriptor::GetHash() const {
  auto seed = fml::HashCombine();
  fml::HashCombineSeed(seed, label_);
  fml::HashCombineSeed(seed, sample_count_);
  for (const auto& entry : entrypoints_) {
    fml::HashCombineSeed(seed, entry.first);
    if (auto second = entry.second) {
      fml::HashCombineSeed(seed, second->GetHash());
    }
  }
  if (vertex_descriptor_) {
    fml::HashCombineSeed(seed, vertex_descriptor_->GetHash());
  }
  return seed;
}

// Comparable<PipelineDescriptor>
bool PipelineDescriptor::IsEqual(const PipelineDescriptor& other) const {
  return label_ == other.label_ && sample_count_ == other.sample_count_ &&
         DeepCompareMap(entrypoints_, other.entrypoints_) &&
         DeepComparePointer(vertex_descriptor_, other.vertex_descriptor_);
}

PipelineDescriptor& PipelineDescriptor::SetLabel(
    const std::string_view& label) {
  label_ = {label.data(), label.size()};
  return *this;
}

PipelineDescriptor& PipelineDescriptor::SetSampleCount(size_t samples) {
  sample_count_ = samples;
  return *this;
}

PipelineDescriptor& PipelineDescriptor::AddStageEntrypoint(
    std::shared_ptr<const ShaderFunction> function) {
  if (!function) {
    return *this;
  }

  if (function->GetStage() == ShaderStage::kUnknown) {
    return *this;
  }

  entrypoints_[function->GetStage()] = std::move(function);

  return *this;
}

PipelineDescriptor& PipelineDescriptor::SetVertexDescriptor(
    std::shared_ptr<VertexDescriptor> vertex_descriptor) {
  vertex_descriptor_ = std::move(vertex_descriptor);
  return *this;
}

MTLRenderPipelineDescriptor*
PipelineDescriptor::GetMTLRenderPipelineDescriptor() const {
  auto descriptor = [[MTLRenderPipelineDescriptor alloc] init];
  descriptor.label = @(label_.c_str());
  descriptor.sampleCount = sample_count_;

  for (const auto& entry : entrypoints_) {
    if (entry.first == ShaderStage::kVertex) {
      descriptor.vertexFunction = entry.second->GetMTLFunction();
    }
    if (entry.first == ShaderStage::kFragment) {
      descriptor.fragmentFunction = entry.second->GetMTLFunction();
    }
  }
  return descriptor;
}

}  // namespace impeller
