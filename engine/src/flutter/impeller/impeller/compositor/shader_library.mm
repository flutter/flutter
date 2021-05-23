// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/shader_library.h"

namespace impeller {

ShaderLibrary::ShaderLibrary(id<MTLLibrary> library) : library_(library) {}

ShaderLibrary::~ShaderLibrary() = default;

std::shared_ptr<const ShaderFunction> ShaderLibrary::GetFunction(
    const std::string_view& name,
    ShaderStage stage) {
  ShaderKey key(name, stage);

  if (auto found = functions_.find(key); found != functions_.end()) {
    return found->second;
  }

  auto function = [library_ newFunctionWithName:@(name.data())];
  if (!function) {
    return nullptr;
  }

  auto func =
      std::shared_ptr<ShaderFunction>(new ShaderFunction(function, stage));
  functions_[key] = func;
  return func;
}

}  // namespace impeller
