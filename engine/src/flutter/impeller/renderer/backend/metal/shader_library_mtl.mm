// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/shader_library_mtl.h"

#include "impeller/renderer/backend/metal/shader_function_mtl.h"

namespace impeller {

ShaderLibraryMTL::ShaderLibraryMTL(NSArray<id<MTLLibrary>>* libraries)
    : libraries_(libraries) {
  if (libraries_ == nil || libraries_.count == 0) {
    return;
  }

  is_valid_ = true;
}

ShaderLibraryMTL::~ShaderLibraryMTL() = default;

bool ShaderLibraryMTL::IsValid() const {
  return is_valid_;
}

std::shared_ptr<const ShaderFunction> ShaderLibraryMTL::GetFunction(
    const std::string_view& name,
    ShaderStage stage) {
  if (!IsValid()) {
    return nullptr;
  }

  ShaderKey key(name, stage);

  if (auto found = functions_.find(key); found != functions_.end()) {
    return found->second;
  }

  id<MTLFunction> function = nil;

  for (size_t i = 0, count = [libraries_ count]; i < count; i++) {
    function = [libraries_[i] newFunctionWithName:@(name.data())];
    if (function) {
      break;
    }
  }

  if (function == nil) {
    return nullptr;
  }

  auto func = std::shared_ptr<ShaderFunctionMTL>(new ShaderFunctionMTL(
      library_id_, function, {name.data(), name.size()}, stage));
  functions_[key] = func;
  return func;
}

}  // namespace impeller
