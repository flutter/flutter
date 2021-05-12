// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/compiler/reflector.h"

#include <sstream>

#include "flutter/fml/logging.h"

namespace impeller {
namespace compiler {

std::string SpvReflectInterfaceVariableToString(
    const SpvReflectInterfaceVariable& var) {
  std::stringstream stream;
  stream << "--- Interface Variable" << std::endl;
  stream << "spirv_id=" << var.spirv_id << std::endl;
  if (var.name) {
    stream << "name=" << var.name << std::endl;
  }
  stream << "location=" << var.location << std::endl;
  stream << "storage_class=" << var.storage_class << std::endl;
  if (var.semantic) {
    stream << "semantic=" << var.semantic << std::endl;
  }
  stream << "decoration_flags=" << var.decoration_flags << std::endl;
  stream << "built_in=" << var.built_in << std::endl;
  // stream << "numeric=" << var.numeric << std::endl;
  //  stream << "array=" << var.array << std::endl;
  stream << "member_count=" << var.member_count << std::endl;
  // stream << "members=" << var.members << std::endl;
  stream << "format=" << var.format << std::endl;
  stream << "type_description=" << var.type_description << std::endl;
  return stream.str();
}

std::string SpvReflectDescriptorBindingToString(
    const SpvReflectDescriptorBinding& des) {
  std::stringstream stream;
  stream << "--- Descriptor Set Binding" << std::endl;
  stream << "spirv_id=" << des.spirv_id << std::endl;
  if (des.name) {
    stream << "name=" << des.name << std::endl;
  }
  stream << "binding=" << des.binding << std::endl;
  stream << "input_attachment_index=" << des.input_attachment_index
         << std::endl;
  stream << "set=" << des.set << std::endl;
  stream << "descriptor_type=" << des.descriptor_type << std::endl;
  stream << "resource_type=" << des.resource_type << std::endl;
  // stream << "image=" << des.image << std::endl;
  // stream << "block=" << des.block << std::endl;
  // stream << "array=" << des.array << std::endl;
  stream << "count=" << des.count << std::endl;
  stream << "accessed=" << des.accessed << std::endl;
  stream << "uav_counter_id=" << des.uav_counter_id << std::endl;
  stream << "uav_counter_binding=" << des.uav_counter_binding << std::endl;
  stream << "type_description=" << des.type_description << std::endl;
  return stream.str();
}

Reflector::Reflector(const fml::Mapping& spirv_binary) {
  if (spirv_binary.GetMapping() == nullptr) {
    return;
  }

  spv_reflect::ShaderModule module(spirv_binary.GetSize(),
                                   spirv_binary.GetMapping());

  if (module.GetResult() != SpvReflectResult::SPV_REFLECT_RESULT_SUCCESS) {
    return;
  }

  FML_LOG(ERROR) << "~~~~~~~~~~~~~ Interface Variables ~~~~~~~~~~~~~";

  {
    uint32_t count = 0;
    if (module.EnumerateInterfaceVariables(&count, nullptr) !=
        SpvReflectResult::SPV_REFLECT_RESULT_SUCCESS) {
      return;
    }

    std::vector<SpvReflectInterfaceVariable*> input_variables;
    input_variables.resize(count);
    if (module.EnumerateInterfaceVariables(&count, input_variables.data()) !=
        SpvReflectResult::SPV_REFLECT_RESULT_SUCCESS) {
      return;
    }

    for (const auto& input_variable : input_variables) {
      FML_LOG(ERROR) << SpvReflectInterfaceVariableToString(*input_variable);
    }
  }

  FML_LOG(ERROR) << "~~~~~~~~~~~~~ Descriptor Bindings ~~~~~~~~~~~~~";

  {
    uint32_t count = 0;
    if (module.EnumerateDescriptorBindings(&count, nullptr) !=
        SpvReflectResult::SPV_REFLECT_RESULT_SUCCESS) {
      return;
    }

    std::vector<SpvReflectDescriptorBinding*> input_variables;
    input_variables.resize(count);
    if (module.EnumerateDescriptorBindings(&count, input_variables.data()) !=
        SpvReflectResult::SPV_REFLECT_RESULT_SUCCESS) {
      return;
    }

    for (const auto& input_variable : input_variables) {
      FML_LOG(ERROR) << SpvReflectDescriptorBindingToString(*input_variable);
    }
  }

  is_valid_ = true;
}

Reflector::~Reflector() = default;

bool Reflector::IsValid() const {
  return is_valid_;
}

}  // namespace compiler
}  // namespace impeller
