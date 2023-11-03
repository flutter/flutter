// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/shader_function_mtl.h"

namespace impeller {

ShaderFunctionMTL::ShaderFunctionMTL(UniqueID parent_library_id,
                                     id<MTLFunction> function,
                                     std::string name,
                                     ShaderStage stage)
    : ShaderFunction(parent_library_id, std::move(name), stage),
      function_(function) {}

ShaderFunctionMTL::~ShaderFunctionMTL() = default;

id<MTLFunction> ShaderFunctionMTL::GetMTLFunction() const {
  return function_;
}

}  // namespace impeller
