// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include <functional>
#include <map>
#include <memory>
#include <string>
#include <string_view>
#include <type_traits>

#include "flutter/fml/macros.h"
#include "impeller/shader_glue/shader_types.h"

namespace impeller {

class ShaderFunction;
class VertexDescriptor;

class PipelineDescriptor {
 public:
  struct HashEqual {
    std::size_t operator()(const PipelineDescriptor& des) const;
    bool operator()(const PipelineDescriptor& d1,
                    const PipelineDescriptor& d2) const;
  };

  PipelineDescriptor();

  ~PipelineDescriptor();

  PipelineDescriptor& SetLabel(const std::string_view& label);

  PipelineDescriptor& SetSampleCount(size_t samples);

  PipelineDescriptor& AddStageEntrypoint(
      std::shared_ptr<const ShaderFunction> function);

  PipelineDescriptor& SetVertexDescriptor(
      std::shared_ptr<VertexDescriptor> vertex_descriptor);

  MTLRenderPipelineDescriptor* GetMTLRenderPipelineDescriptor() const;

 private:
  std::string label_;
  size_t sample_count_ = 1;
  std::map<ShaderStage, std::shared_ptr<const ShaderFunction>> entrypoints_;
  std::shared_ptr<VertexDescriptor> vertex_descriptor_;

  FML_DISALLOW_COPY_AND_ASSIGN(PipelineDescriptor);
};

}  // namespace impeller
