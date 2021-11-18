// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <optional>

#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "inja/inja.hpp"
#include "third_party/spirv_cross/spirv_msl.hpp"
#include "third_party/spirv_cross/spirv_parser.hpp"

namespace impeller {
namespace compiler {

struct StructMember {
  std::string type;
  std::string name;
  size_t offset = 0u;
  size_t byte_length = 0u;
};

class Reflector {
 public:
  struct Options {
    std::string shader_name;
    std::string header_file_name;
  };

  Reflector(Options options,
            std::shared_ptr<const spirv_cross::ParsedIR> ir,
            std::shared_ptr<const spirv_cross::CompilerMSL> compiler);

  ~Reflector();

  bool IsValid() const;

  std::shared_ptr<fml::Mapping> GetReflectionJSON() const;

  std::shared_ptr<fml::Mapping> GetReflectionHeader() const;

  std::shared_ptr<fml::Mapping> GetReflectionCC() const;

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
  // TODO(csg): There is no reason this needs to the MSL subtype.
  const std::shared_ptr<const spirv_cross::CompilerMSL> compiler_;
  std::unique_ptr<const nlohmann::json> template_arguments_;
  std::shared_ptr<fml::Mapping> reflection_header_;
  std::shared_ptr<fml::Mapping> reflection_cc_;
  bool is_valid_ = false;

  std::optional<nlohmann::json> GenerateTemplateArguments() const;

  std::shared_ptr<fml::Mapping> GenerateReflectionHeader() const;

  std::shared_ptr<fml::Mapping> GenerateReflectionCC() const;

  std::shared_ptr<fml::Mapping> InflateTemplate(
      const std::string_view& tmpl) const;

  std::optional<nlohmann::json::object_t> ReflectResource(
      const spirv_cross::Resource& resource) const;

  std::optional<nlohmann::json::array_t> ReflectResources(
      const spirv_cross::SmallVector<spirv_cross::Resource>& resources) const;

  std::optional<nlohmann::json::object_t> ReflectType(
      const spirv_cross::TypeID& type_id) const;

  nlohmann::json::object_t EmitStructDefinition(
      std::optional<Reflector::StructDefinition> struc) const;

  std::optional<StructDefinition> ReflectStructDefinition(
      const spirv_cross::TypeID& type_id) const;

  std::vector<BindPrototype> ReflectBindPrototypes(
      const spirv_cross::ShaderResources& resources) const;

  nlohmann::json::array_t EmitBindPrototypes(
      const spirv_cross::ShaderResources& resources) const;

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

  FML_DISALLOW_COPY_AND_ASSIGN(Reflector);
};

}  // namespace compiler
}  // namespace impeller
