// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/shader_library_vk.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "impeller/blobcat/blob_library.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/shader_function_vk.h"

namespace impeller {

static ShaderStage ToShaderStage(BlobShaderType type) {
  switch (type) {
    case BlobShaderType::kVertex:
      return ShaderStage::kVertex;
    case BlobShaderType::kFragment:
      return ShaderStage::kFragment;
    case BlobShaderType::kCompute:
      return ShaderStage::kCompute;
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
    std::weak_ptr<DeviceHolder> device_holder,
    const std::vector<std::shared_ptr<fml::Mapping>>& shader_libraries_data)
    : device_holder_(std::move(device_holder)) {
  TRACE_EVENT0("impeller", "CreateShaderLibrary");
  bool success = true;
  auto iterator = [&](auto type,         //
                      const auto& name,  //
                      const auto& code   //
                      ) -> bool {
    if (!RegisterFunction(name, ToShaderStage(type), code)) {
      success = false;
      return false;
    }
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
    VALIDATION_LOG << "Could not create shader modules for all shader blobs.";
    return;
  }
  is_valid_ = true;
}

ShaderLibraryVK::~ShaderLibraryVK() = default;

bool ShaderLibraryVK::IsValid() const {
  return is_valid_;
}

// |ShaderLibrary|
std::shared_ptr<const ShaderFunction> ShaderLibraryVK::GetFunction(
    std::string_view name,
    ShaderStage stage) {
  ReaderLock lock(functions_mutex_);

  const auto key = ShaderKey{{name.data(), name.size()}, stage};
  auto found = functions_.find(key);
  if (found != functions_.end()) {
    return found->second;
  }
  return nullptr;
}

// |ShaderLibrary|
void ShaderLibraryVK::RegisterFunction(std::string name,
                                       ShaderStage stage,
                                       std::shared_ptr<fml::Mapping> code,
                                       RegistrationCallback callback) {
  const auto result = RegisterFunction(name, stage, code);
  if (callback) {
    callback(result);
  }
}

static bool IsMappingSPIRV(const fml::Mapping& mapping) {
  // https://registry.khronos.org/SPIR-V/specs/1.0/SPIRV.html#Magic
  const uint32_t kSPIRVMagic = 0x07230203;
  if (mapping.GetSize() < sizeof(kSPIRVMagic)) {
    return false;
  }
  uint32_t magic = 0u;
  ::memcpy(&magic, mapping.GetMapping(), sizeof(magic));
  return magic == kSPIRVMagic;
}

bool ShaderLibraryVK::RegisterFunction(
    const std::string& name,
    ShaderStage stage,
    const std::shared_ptr<fml::Mapping>& code) {
  if (!code) {
    return false;
  }

  if (!IsMappingSPIRV(*code)) {
    VALIDATION_LOG << "Shader is not valid SPIRV.";
    return false;
  }

  vk::ShaderModuleCreateInfo shader_module_info;

  shader_module_info.setPCode(
      reinterpret_cast<const uint32_t*>(code->GetMapping()));
  shader_module_info.setCodeSize(code->GetSize());

  auto device_holder = device_holder_.lock();
  if (!device_holder) {
    return false;
  }
  FML_DCHECK(device_holder->GetDevice());
  auto module =
      device_holder->GetDevice().createShaderModuleUnique(shader_module_info);

  if (module.result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not create shader module: "
                   << vk::to_string(module.result);
    return false;
  }

  const auto key_name = VKShaderNameToShaderKeyName(name, stage);

  vk::UniqueShaderModule shader_module = std::move(module.value);
  ContextVK::SetDebugName(device_holder->GetDevice(), *shader_module,
                          "Shader " + name);

  WriterLock lock(functions_mutex_);
  functions_[ShaderKey{key_name, stage}] = std::shared_ptr<ShaderFunctionVK>(
      new ShaderFunctionVK(device_holder_,
                           library_id_,              //
                           key_name,                 //
                           stage,                    //
                           std::move(shader_module)  //
                           ));

  return true;
}

// |ShaderLibrary|
void ShaderLibraryVK::UnregisterFunction(std::string name, ShaderStage stage) {
  WriterLock lock(functions_mutex_);

  const auto key = ShaderKey{name, stage};

  auto found = functions_.find(key);
  if (found != functions_.end()) {
    VALIDATION_LOG << "Library function named " << name
                   << " was not found, so it couldn't be unregistered.";
    return;
  }

  functions_.erase(found);

  return;
}

}  // namespace impeller
