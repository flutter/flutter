// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <type_traits>
#include <unordered_map>

#include "flutter/fml/macros.h"
#include "impeller/compositor/pipeline_descriptor.h"
#include "impeller/compositor/shader_library.h"
#include "impeller/compositor/vertex_descriptor.h"

namespace impeller {

class PipelineBuilder {
 public:
  PipelineBuilder();

  ~PipelineBuilder();

  PipelineBuilder& SetLabel(const std::string_view& label);

  PipelineBuilder& SetSampleCount(size_t samples);

  PipelineBuilder& AddStageEntrypoint(std::shared_ptr<ShaderFunction> function);

  PipelineBuilder& SetVertexDescriptor(
      std::shared_ptr<VertexDescriptor> vertex_descriptor);

 private:
  std::string label_;
  size_t sample_count_ = 1;
  std::unordered_map<ShaderStage, std::shared_ptr<ShaderFunction>> entrypoints_;
  std::shared_ptr<VertexDescriptor> vertex_descriptor_;

  FML_DISALLOW_COPY_AND_ASSIGN(PipelineBuilder);
};

}  // namespace impeller
