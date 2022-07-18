// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/shader_library_vk.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "impeller/blobcat/blob_library.h"
#include "impeller/renderer/backend/vulkan/shader_function_vk.h"

namespace impeller {

static ShaderStage ToShaderStage(Blob::ShaderType type) {
  switch (type) {
    case Blob::ShaderType::kVertex:
      return ShaderStage::kVertex;
    case Blob::ShaderType::kFragment:
      return ShaderStage::kFragment;
  }
  FML_UNREACHABLE();
}

static std::string VKShaderNameToShaderKeyName(const std::string& name,
                                               ShaderStage stage) {
  std::stringstream stream;
  stream << name;
  switch (stage) {
    case ShaderStage::kUnknown:
      stream << "_unknown_";
      break;
    case ShaderStage::kVertex:
      stream << "_vertex_";
      break;
    case ShaderStage::kFragment:
      stream << "_fragment_";
      break;
    case ShaderStage::kTessellationControl:
      stream << "_tessellation_control_";
      break;
    case ShaderStage::kTessellationEvaluation:
      stream << "_tessellation_evaluation_";
      break;
    case ShaderStage::kCompute:
      stream << "_compute_";
      break;
  }
  stream << "main";
  return stream.str();
}

ShaderLibraryVK::ShaderLibraryVK(
    const vk::Device& device,
    const std::vector<std::shared_ptr<fml::Mapping>>& shader_libraries_data) {
  TRACE_EVENT0("impeller", "ShaderLibraryCreate");
  ShaderFunctionMap functions;
  bool success = true;
  auto iterator = [&success, &device, &functions, library_id = library_id_](
                      auto type,           //
                      const auto& name,    //
                      const auto& mapping  //
                      ) -> bool {
    vk::ShaderModuleCreateInfo shader_module_info;

    shader_module_info.setPCode(
        reinterpret_cast<const uint32_t*>(mapping->GetMapping()));
    shader_module_info.setCodeSize(mapping->GetSize());

    auto module = device.createShaderModuleUnique(shader_module_info);

    if (module.result != vk::Result::eSuccess) {
      VALIDATION_LOG << "Could not create shader module: "
                     << vk::to_string(module.result);
      success = false;
      return false;
    }

    const auto stage = ToShaderStage(type);
    const auto key_name = VKShaderNameToShaderKeyName(name, stage);

    functions[ShaderKey{key_name, stage}] = std::shared_ptr<ShaderFunctionVK>(
        new ShaderFunctionVK(library_id,              //
                             key_name,                //
                             stage,                   //
                             std::move(module.value)  //
                             ));

    return true;
  };
  for (const auto& library_data : shader_libraries_data) {
    auto blob_library = BlobLibrary{library_data};
    if (!blob_library.IsValid()) {
      VALIDATION_LOG << "Could not construct shader blob library.";
      return;
    }
    blob_library.IterateAllBlobs(iterator);
  }

  if (!success) {
    return;
  }
  functions_ = std::move(functions);
  is_valid_ = true;
}

ShaderLibraryVK::~ShaderLibraryVK() = default;

bool ShaderLibraryVK::IsValid() const {
  return is_valid_;
}

std::shared_ptr<const ShaderFunction> ShaderLibraryVK::GetFunction(
    std::string_view name,
    ShaderStage stage) {
  const auto key = ShaderKey{{name.data(), name.size()}, stage};
  auto found = functions_.find(key);
  if (found != functions_.end()) {
    return found->second;
  }
  return nullptr;
}

}  // namespace impeller
