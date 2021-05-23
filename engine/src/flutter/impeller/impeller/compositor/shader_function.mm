// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/shader_function.h"

namespace impeller {

ShaderFunction::ShaderFunction(id<MTLFunction> function, ShaderStage stage)
    : function_(function), stage_(stage) {}

ShaderFunction::~ShaderFunction() = default;

id<MTLFunction> ShaderFunction::GetMTLFunction() const {
  return function_;
}

ShaderStage ShaderFunction::GetStage() const {
  return stage_;
}

}  // namespace impeller
