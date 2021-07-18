// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/compositor/comparable.h"
#include "impeller/shader_glue/shader_types.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief        Describes the format and layout of vertices expected by the
///               pipeline. While it is possible to construct these descriptors
///               manually, it would be tedious to do so. These are usually
///               constructed using shader information reflected using
///               `impellerc`. The usage of this class is indirectly via
///               `PipelineBuilder<VS, FS>`.
///
class PipelineVertexDescriptor final
    : public Comparable<PipelineVertexDescriptor> {
 public:
  static constexpr size_t kReservedVertexBufferIndex =
      30u;  // The final slot available. Regular buffer indices go up from 0.

  PipelineVertexDescriptor();

  virtual ~PipelineVertexDescriptor();

  template <size_t Size>
  bool SetStageInputs(
      const std::array<const ShaderStageIOSlot*, Size>& inputs) {
    return SetStageInputs(inputs.data(), inputs.size());
  }

  bool SetStageInputs(const ShaderStageIOSlot* const stage_inputs[],
                      size_t count);

  //| Comparable<VertexDescriptor>|
  std::size_t GetHash() const override;

  // |Comparable<VertexDescriptor>|
  bool IsEqual(const PipelineVertexDescriptor& other) const override;

  MTLVertexDescriptor* GetMTLVertexDescriptor() const;

 private:
  struct StageInput {
    size_t location;
    MTLVertexFormat format;
    size_t length;

    StageInput(size_t p_location, MTLVertexFormat p_format, size_t p_length)
        : location(p_location), format(p_format), length(p_length) {}

    constexpr bool operator==(const StageInput& other) const {
      return location == other.location && format == other.format &&
             length == other.length;
    }
  };
  std::vector<StageInput> stage_inputs_;

  FML_DISALLOW_COPY_AND_ASSIGN(PipelineVertexDescriptor);
};

}  // namespace impeller
