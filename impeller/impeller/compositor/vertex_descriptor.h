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

class VertexDescriptor final : public Comparable<VertexDescriptor> {
 public:
  VertexDescriptor();

  virtual ~VertexDescriptor();

  bool SetStageInputs(const ShaderStageInput* const stage_inputs[],
                      size_t count);

  MTLVertexDescriptor* GetMTLVertexDescriptor() const;

  //| Comparable<VertexDescriptor>|
  std::size_t GetHash() const override;

  // |Comparable<VertexDescriptor>|
  bool IsEqual(const VertexDescriptor& other) const override;

 private:
  struct StageInput {
    size_t location;
    MTLVertexFormat format;
    size_t stride;

    StageInput(size_t p_location, MTLVertexFormat p_format, size_t p_stride)
        : location(p_location), format(p_format), stride(p_stride) {}

    constexpr bool operator==(const StageInput& other) const {
      return location == other.location && format == other.format;
    }
  };
  std::vector<StageInput> stage_inputs_;

  FML_DISALLOW_COPY_AND_ASSIGN(VertexDescriptor);
};

}  // namespace impeller
