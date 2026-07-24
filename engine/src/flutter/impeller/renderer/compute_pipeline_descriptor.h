// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_COMPUTE_PIPELINE_DESCRIPTOR_H_
#define FLUTTER_IMPELLER_RENDERER_COMPUTE_PIPELINE_DESCRIPTOR_H_

#include <array>
#include <cstdint>
#include <memory>
#include <string>

#include "impeller/base/comparable.h"
#include "impeller/core/shader_types.h"

namespace impeller {

class ShaderFunction;
template <typename T>
class Pipeline;

class ComputePipelineDescriptor final
    : public Comparable<ComputePipelineDescriptor> {
 public:
  ComputePipelineDescriptor();

  ~ComputePipelineDescriptor();

  ComputePipelineDescriptor& SetLabel(std::string_view label);

  const std::string& GetLabel() const;

  ComputePipelineDescriptor& SetStageEntrypoint(
      std::shared_ptr<const ShaderFunction> function);

  std::shared_ptr<const ShaderFunction> GetStageEntrypoint() const;

  //----------------------------------------------------------------------------
  /// @brief      Set the workgroup (threadgroup) size declared by the shader.
  ///
  ///             A dimension of 0 is sized by a specialization constant and
  ///             resolved by the backend at dispatch (for example, to the
  ///             device maximum).
  ///
  ComputePipelineDescriptor& SetWorkgroupSize(std::array<uint32_t, 3> size);

  std::array<uint32_t, 3> GetWorkgroupSize() const;

  // Comparable<ComputePipelineDescriptor>
  std::size_t GetHash() const override;

  // Comparable<PipelineDescriptor>
  bool IsEqual(const ComputePipelineDescriptor& other) const override;

  template <size_t Size>
  bool RegisterDescriptorSetLayouts(
      const std::array<DescriptorSetLayout, Size>& inputs) {
    return RegisterDescriptorSetLayouts(inputs.data(), inputs.size());
  }

  bool RegisterDescriptorSetLayouts(const DescriptorSetLayout desc_set_layout[],
                                    size_t count);

  const std::vector<DescriptorSetLayout>& GetDescriptorSetLayouts() const;

 private:
  std::string label_;
  std::shared_ptr<const ShaderFunction> entrypoint_;
  std::array<uint32_t, 3> workgroup_size_ = {0u, 0u, 0u};
  std::vector<DescriptorSetLayout> descriptor_set_layouts_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_COMPUTE_PIPELINE_DESCRIPTOR_H_
