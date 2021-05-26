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

#include "flutter/fml/hash_combine.h"
#include "flutter/fml/macros.h"
#include "impeller/compositor/comparable.h"
#include "impeller/compositor/formats.h"
#include "impeller/shader_glue/shader_types.h"

namespace impeller {

class ShaderFunction;
class VertexDescriptor;

class PipelineDescriptor : public Comparable<PipelineDescriptor> {
 public:
  PipelineDescriptor();

  ~PipelineDescriptor();

  PipelineDescriptor& SetLabel(const std::string_view& label);

  PipelineDescriptor& SetSampleCount(size_t samples);

  PipelineDescriptor& AddStageEntrypoint(
      std::shared_ptr<const ShaderFunction> function);

  PipelineDescriptor& SetVertexDescriptor(
      std::shared_ptr<VertexDescriptor> vertex_descriptor);

  PipelineDescriptor& SetColorAttachmentDescriptor(
      size_t index,
      ColorAttachmentDescriptor desc);

  MTLRenderPipelineDescriptor* GetMTLRenderPipelineDescriptor() const;

  // Comparable<PipelineDescriptor>
  std::size_t GetHash() const override;

  // Comparable<PipelineDescriptor>
  bool IsEqual(const PipelineDescriptor& other) const override;

 private:
  std::string label_;
  size_t sample_count_ = 1;
  std::map<ShaderStage, std::shared_ptr<const ShaderFunction>> entrypoints_;
  std::map<size_t, ColorAttachmentDescriptor> color_attachment_descriptors_;
  std::shared_ptr<VertexDescriptor> vertex_descriptor_;
};

}  // namespace impeller
