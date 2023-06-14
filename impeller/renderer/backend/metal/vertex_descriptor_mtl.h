// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

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

  bool SetStageInputsAndLayout(
      const std::vector<ShaderStageIOSlot>& inputs,
      const std::vector<ShaderStageBufferLayout>& layouts);

  MTLVertexDescriptor* GetMTLVertexDescriptor() const;

 private:
  MTLVertexDescriptor* descriptor_;

  FML_DISALLOW_COPY_AND_ASSIGN(VertexDescriptorMTL);
};

}  // namespace impeller
