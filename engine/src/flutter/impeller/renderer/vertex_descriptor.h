// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/base/comparable.h"
#include "impeller/core/shader_types.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief        Describes the format and layout of vertices expected by the
///               pipeline. While it is possible to construct these descriptors
///               manually, it would be tedious to do so. These are usually
///               constructed using shader information reflected using
///               `impellerc`. The usage of this class is indirectly via
///               `PipelineBuilder<VS, FS>`.
///
class VertexDescriptor final : public Comparable<VertexDescriptor> {
 public:
  static constexpr size_t kReservedVertexBufferIndex =
      30u;  // The final slot available. Regular buffer indices go up from 0.

  VertexDescriptor();

  // |Comparable<PipelineVertexDescriptor>|
  virtual ~VertexDescriptor();

  template <size_t Size>
  bool SetStageInputs(
      const std::array<const ShaderStageIOSlot*, Size>& inputs) {
    return SetStageInputs(inputs.data(), inputs.size());
  }

  template <size_t Size>
  bool RegisterDescriptorSetLayouts(
      const std::array<DescriptorSetLayout, Size>& inputs) {
    return RegisterDescriptorSetLayouts(inputs.data(), inputs.size());
  }

  bool SetStageInputs(const ShaderStageIOSlot* const stage_inputs[],
                      size_t count);

  bool RegisterDescriptorSetLayouts(const DescriptorSetLayout desc_set_layout[],
                                    size_t count);

  const std::vector<ShaderStageIOSlot>& GetStageInputs() const;

  const std::vector<DescriptorSetLayout>& GetDescriptorSetLayouts() const;

  // |Comparable<VertexDescriptor>|
  std::size_t GetHash() const override;

  // |Comparable<VertexDescriptor>|
  bool IsEqual(const VertexDescriptor& other) const override;

 private:
  std::vector<ShaderStageIOSlot> inputs_;
  std::vector<DescriptorSetLayout> desc_set_layouts_;

  FML_DISALLOW_COPY_AND_ASSIGN(VertexDescriptor);
};

}  // namespace impeller
