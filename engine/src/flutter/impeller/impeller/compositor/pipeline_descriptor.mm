// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/pipeline_descriptor.h"

#include "flutter/fml/hash_combine.h"
#include "impeller/compositor/shader_library.h"

namespace impeller {

PipelineDescriptor::PipelineDescriptor() = default;

PipelineDescriptor::~PipelineDescriptor() = default;

std::size_t PipelineDescriptor::HashEqual::operator()(
    const PipelineDescriptor& des) const {
  auto seed = fml::HashCombine();
  fml::HashCombineSeed(seed, des.label_);
  for (const auto& entry : des.entrypoints_) {
    fml::HashCombineSeed(seed, entry)
  }
}

bool PipelineDescriptor::HashEqual::operator()(
    const PipelineDescriptor& d1,
    const PipelineDescriptor& d2) const {}

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
