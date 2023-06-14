// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <optional>

#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "impeller/compiler/compiler_backend.h"
#include "impeller/compiler/runtime_stage_data.h"
#include "inja/inja.hpp"
#include "spirv_msl.hpp"
#include "spirv_parser.hpp"

namespace impeller {
namespace compiler {

struct StructMember {
  std::string type;
  std::string base_type;
  std::string name;
  size_t offset = 0u;
  size_t size = 0u;
  size_t byte_length = 0u;
  std::optional<size_t> array_elements = std::nullopt;
  size_t element_padding = 0u;

  StructMember(std::string p_type,
               std::string p_base_type,
               std::string p_name,
               size_t p_offset,
               size_t p_size,
               size_t p_byte_length,
               std::optional<size_t> p_array_elements,
               size_t p_element_padding)
      : type(std::move(p_type)),
        base_type(std::move(p_base_type)),
        name(std::move(p_name)),
        offset(p_offset),
        size(p_size),
        byte_length(p_byte_length),
        array_elements(p_array_elements),
        element_padding(p_element_padding) {}
};

class Reflector {
 public:
  struct Options {
    TargetPlatform target_platform = TargetPlatform::kUnknown;
    std::string entry_point_name;
    std::string shader_name;
    std::string header_file_name;
  };

  Reflector(Options options,
            std::shared_ptr<const spirv_cross::ParsedIR> ir,
            std::shared_ptr<fml::Mapping> shader_data,
            CompilerBackend compiler);

  ~Reflector();

  bool IsValid() const;

  std::shared_ptr<fml::Mapping> GetReflectionJSON() const;

  std::shared_ptr<fml::Mapping> GetReflectionHeader() const;

  std::shared_ptr<fml::Mapping> GetReflectionCC() const;

  std::shared_ptr<RuntimeStageData> GetRuntimeStageData() const;

 private:
  struct StructDefinition {
    std::string name;
    size_t byte_length = 0u;
    std::vector<StructMember> members;
  };

  struct BindPrototypeArgument {
    std::string type_name;
    std::string argument_name;
  };

  struct BindPrototype {
    std::string name;
    std::string return_type;
    std::string docstring;
    std::vector<BindPrototypeArgument> args;
  };

  const Options options_;
  const std::shared_ptr<const spirv_cross::ParsedIR> ir_;
  const std::shared_ptr<fml::Mapping> shader_data_;
  const std::shared_ptr<fml::Mapping> sksl_data_;
  const CompilerBackend compiler_;
  std::unique_ptr<const nlohmann::json> template_arguments_;
  std::shared_ptr<fml::Mapping> reflection_header_;
  std::shared_ptr<fml::Mapping> reflection_cc_;
  std::shared_ptr<RuntimeStageData> runtime_stage_data_;
  bool is_valid_ = false;

  std::optional<nlohmann::json> GenerateTemplateArguments() const;

  std::shared_ptr<fml::Mapping> GenerateReflectionHeader() const;

  std::shared_ptr<fml::Mapping> GenerateReflectionCC() const;

  std::shared_ptr<RuntimeStageData> GenerateRuntimeStageData() const;

  std::shared_ptr<fml::Mapping> InflateTemplate(std::string_view tmpl) const;

  std::optional<nlohmann::json::object_t> ReflectResource(
      const spirv_cross::Resource& resource,
      std::optional<size_t> offset) const;

  std::optional<nlohmann::json::array_t> ReflectResources(
      const spirv_cross::SmallVector<spirv_cross::Resource>& resources,
      bool compute_offsets = false) const;

  std::vector<size_t> ComputeOffsets(
      const spirv_cross::SmallVector<spirv_cross::Resource>& resources) const;

  std::optional<nlohmann::json::object_t> ReflectType(
      const spirv_cross::TypeID& type_id) const;

  nlohmann::json::object_t EmitStructDefinition(
      std::optional<Reflector::StructDefinition> struc) const;

  std::optional<StructDefinition> ReflectStructDefinition(
      const spirv_cross::TypeID& type_id) const;

  std::vector<BindPrototype> ReflectBindPrototypes(
      const spirv_cross::ShaderResources& resources,
      spv::ExecutionModel execution_model) const;

  nlohmann::json::array_t EmitBindPrototypes(
      const spirv_cross::ShaderResources& resources,
      spv::ExecutionModel execution_model) const;

  std::optional<StructDefinition> ReflectPerVertexStructDefinition(
      const spirv_cross::SmallVector<spirv_cross::Resource>& stage_inputs)
      const;

  std::optional<std::string> GetMemberNameAtIndexIfExists(
      const spirv_cross::SPIRType& parent_type,
      size_t index) const;

  std::string GetMemberNameAtIndex(const spirv_cross::SPIRType& parent_type,
                                   size_t index,
                                   std::string suffix = "") const;

  std::vector<StructMember> ReadStructMembers(
      const spirv_cross::TypeID& type_id) const;

  std::optional<uint32_t> GetArrayElements(
      const spirv_cross::SPIRType& type) const;

  template <uint32_t Size>
  uint32_t GetArrayStride(const spirv_cross::SPIRType& struct_type,
                          const spirv_cross::SPIRType& member_type,
                          uint32_t index) const {
    auto element_count = GetArrayElements(member_type).value_or(1);
    if (element_count <= 1) {
      return Size;
    }
    return compiler_->type_struct_member_array_stride(struct_type, index);
  };

  FML_DISALLOW_COPY_AND_ASSIGN(Reflector);
};

}  // namespace compiler
}  // namespace impeller
