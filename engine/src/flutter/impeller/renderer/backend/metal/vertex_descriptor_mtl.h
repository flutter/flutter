// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <Metal/Metal.h>

#include <set>

#include "flutter/fml/macros.h"
#include "impeller/base/backend_cast.h"
#include "impeller/renderer/vertex_descriptor.h"

namespace impeller {

class VertexDescriptorMTL {
 public:
  VertexDescriptorMTL();

  ~VertexDescriptorMTL();

  bool SetStageInputs(const std::vector<ShaderStageIOSlot>& inputs);

  MTLVertexDescriptor* GetMTLVertexDescriptor() const;

 private:
  struct StageInput {
    size_t location;
    MTLVertexFormat format;
    size_t length;

    StageInput(size_t p_location, MTLVertexFormat p_format, size_t p_length)
        : location(p_location), format(p_format), length(p_length) {}

    struct Compare {
      constexpr bool operator()(const StageInput& lhs,
                                const StageInput& rhs) const {
        return lhs.location < rhs.location;
      }
    };
  };
  std::set<StageInput, StageInput::Compare> stage_inputs_;

  FML_DISALLOW_COPY_AND_ASSIGN(VertexDescriptorMTL);
};

}  // namespace impeller
