// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/shader_library.h"

namespace impeller {

ShaderFunction::ShaderFunction(id<MTLFunction> function, ShaderStage stage)
    : function_(function), stage_(stage) {}

ShaderFunction::~ShaderFunction() = default;

ShaderStage ShaderFunction::GetStage() const {
  return stage_;
}

ShaderLibrary::ShaderLibrary(id<MTLLibrary> library) : library_(library) {}

ShaderLibrary::~ShaderLibrary() = default;

std::shared_ptr<ShaderFunction> ShaderLibrary::GetFunction(
    const std::string& name,
    ShaderStage stage) {
  auto function = [library_ newFunctionWithName:@(name.c_str())];
  if (!function) {
    return nullptr;
  }
  return std::shared_ptr<ShaderFunction>(new ShaderFunction(function, stage));
}

}  // namespace impeller
