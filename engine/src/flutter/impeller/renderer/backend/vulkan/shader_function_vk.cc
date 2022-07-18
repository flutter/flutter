// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/shader_function_vk.h"

namespace impeller {

ShaderFunctionVK::ShaderFunctionVK(UniqueID parent_library_id,
                                   std::string name,
                                   ShaderStage stage,
                                   vk::UniqueShaderModule module)
    : ShaderFunction(parent_library_id, std::move(name), stage),
      module_(std::move(module)) {}

ShaderFunctionVK::~ShaderFunctionVK() = default;

const vk::ShaderModule& ShaderFunctionVK::GetModule() const {
  return module_.get();
}

}  // namespace impeller
