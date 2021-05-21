// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/pipeline_builder.h"

namespace impeller {

PipelineBuilder::PipelineBuilder() = default;

PipelineBuilder::~PipelineBuilder() = default;

PipelineBuilder& PipelineBuilder::SetLabel(const std::string_view& label) {
  label_ = {label.data(), label.size()};
  return *this;
}

PipelineBuilder& PipelineBuilder::SetSampleCount(size_t samples) {
  sample_count_ = samples;
  return *this;
}

PipelineBuilder& PipelineBuilder::AddStageEntrypoint(
    std::shared_ptr<ShaderFunction> function) {
  if (!function) {
    return *this;
  }

  if (function->GetStage() == ShaderStage::kUnknown) {
    return *this;
  }

  entrypoints_[function->GetStage()] = std::move(function);

  return *this;
}

PipelineBuilder& PipelineBuilder::SetVertexDescriptor(
    std::shared_ptr<VertexDescriptor> vertex_descriptor) {
  vertex_descriptor_ = std::move(vertex_descriptor);
  return *this;
}

}  // namespace impeller
