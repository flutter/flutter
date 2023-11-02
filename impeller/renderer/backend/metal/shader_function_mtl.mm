// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/shader_function_mtl.h"

namespace impeller {

ShaderFunctionMTL::ShaderFunctionMTL(UniqueID parent_library_id,
                                     id<MTLFunction> function,
                                     id<MTLLibrary> library,
                                     std::string name,
                                     ShaderStage stage)
    : ShaderFunction(parent_library_id, std::move(name), stage),
      function_(function),
      library_(library) {}

ShaderFunctionMTL::~ShaderFunctionMTL() = default;

id<MTLFunction> ShaderFunctionMTL::GetMTLFunctionSpecialized(
    const std::vector<int>& constants) const {
  MTLFunctionConstantValues* constantValues =
      [[MTLFunctionConstantValues alloc] init];
  size_t index = 0;
  for (const auto value : constants) {
    int copied_value = value;
    [constantValues setConstantValue:&copied_value
                                type:MTLDataTypeInt
                             atIndex:index];
    index++;
  }
  NSError* error = nil;
  auto result = [library_ newFunctionWithName:@(GetName().data())
                               constantValues:constantValues
                                        error:&error];
  if (error != nil) {
    return nil;
  }
  return result;
}

id<MTLFunction> ShaderFunctionMTL::GetMTLFunction() const {
  return function_;
}

}  // namespace impeller
