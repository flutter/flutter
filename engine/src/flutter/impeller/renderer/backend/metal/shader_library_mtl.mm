// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/shader_library_mtl.h"

#include "impeller/renderer/backend/metal/shader_function_mtl.h"

namespace impeller {

ShaderLibraryMTL::ShaderLibraryMTL(id<MTLLibrary> library)
    : library_(library) {}

ShaderLibraryMTL::~ShaderLibraryMTL() = default;

std::shared_ptr<const ShaderFunction> ShaderLibraryMTL::GetFunction(
    const std::string_view& name,
    ShaderStage stage) {
  if (!library_) {
    return nullptr;
  }

  ShaderKey key(name, stage);

  if (auto found = functions_.find(key); found != functions_.end()) {
    return found->second;
  }

  auto function = [library_ newFunctionWithName:@(name.data())];
  if (!function) {
    return nullptr;
  }

  auto func = std::shared_ptr<ShaderFunctionMTL>(new ShaderFunctionMTL(
      library_id_, function, {name.data(), name.size()}, stage));
  functions_[key] = func;
  return func;
}

}  // namespace impeller
