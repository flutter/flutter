// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/compiler/reflector.h"

#include <atomic>
#include <optional>
#include <sstream>

#include "flutter/fml/closure.h"
#include "flutter/fml/logging.h"
#include "flutter/impeller/compiler/code_gen_template.h"
#include "flutter/impeller/compiler/utilities.h"

namespace impeller {
namespace compiler {

using namespace spirv_cross;

static std::string BaseTypeToString(SPIRType::BaseType type) {
  using Type = SPIRType::BaseType;
  switch (type) {
    case Type::Void:
      return "ShaderType::kVoid";
    case Type::Boolean:
      return "ShaderType::kBoolean";
    case Type::SByte:
      return "ShaderType::kSignedByte";
    case Type::UByte:
      return "ShaderType::kUnsignedByte";
    case Type::Short:
      return "ShaderType::kSignedShort";
    case Type::UShort:
      return "ShaderType::kUnsignedShort";
    case Type::Int:
      return "ShaderType::kSignedInt";
    case Type::UInt:
      return "ShaderType::kUnsignedInt";
    case Type::Int64:
      return "ShaderType::kSignedInt64";
    case Type::UInt64:
      return "ShaderType::kUnsignedInt64";
    case Type::AtomicCounter:
      return "ShaderType::kAtomicCounter";
    case Type::Half:
      return "ShaderType::kHalfFloat";
    case Type::Float:
      return "ShaderType::kFloat";
    case Type::Double:
      return "ShaderType::kDouble";
    case Type::Struct:
      return "ShaderType::kStruct";
    case Type::Image:
      return "ShaderType::kImage";
    case Type::SampledImage:
      return "ShaderType::kSampledImage";
    case Type::Sampler:
      return "ShaderType::kSampler";
    default:
      return "ShaderType::kUnknown";
  }
}

static std::optional<std::string> GetMemberNameAtIndexIfExists(
    const ParsedIR& ir,
    const CompilerMSL& compiler,
    const SPIRType& type,
    size_t index) {
  if (type.type_alias != 0) {
    return GetMemberNameAtIndexIfExists(
        ir, compiler, compiler.get_type(type.type_alias), index);
  }

  if (auto found = ir.meta.find(type.self); found != ir.meta.end()) {
    const auto& members = found->second.members;
    if (index < members.size() && !members[index].alias.empty()) {
      return members[index].alias;
    }
  }
  return std::nullopt;
}

std::string GetMemberNameAtIndex(const ParsedIR& ir,
                                 const CompilerMSL& compiler,
                                 const SPIRType& type,
                                 size_t index) {
  if (auto name = GetMemberNameAtIndexIfExists(ir, compiler, type, index);
      name.has_value()) {
    return name.value();
  }

  static std::atomic_size_t sUnnamedMembersID;
  std::stringstream stream;
  stream << "unnamed_" << sUnnamedMembersID++;
  return stream.str();
}

static std::string ExecutionModelToString(spv::ExecutionModel model) {
  switch (model) {
    case spv::ExecutionModel::ExecutionModelVertex:
      return "vertex";
    case spv::ExecutionModel::ExecutionModelFragment:
      return "fragment";
    default:
      return "unsupported";
  }
}

static std::string StringToShaderStage(std::string str) {
  if (str == "vertex") {
    return "ShaderStage::kVertex";
  }

  if (str == "fragment") {
    return "ShaderStage::kFragment";
  }

  return "ShaderStage::kUnknown";
}

Reflector::Reflector(Options options,
                     std::shared_ptr<const ParsedIR> ir,
                     std::shared_ptr<const CompilerMSL> compiler)
    : options_(std::move(options)),
      ir_(std::move(ir)),
      compiler_(std::move(compiler)) {
  if (!ir_ || !compiler_) {
    return;
  }

  if (auto template_arguments = GenerateTemplateArguments();
      template_arguments.has_value()) {
    template_arguments_ =
        std::make_unique<nlohmann::json>(std::move(template_arguments.value()));
  } else {
    return;
  }

  reflection_header_ = GenerateReflectionHeader();
  if (!reflection_header_) {
    return;
  }

  reflection_cc_ = GenerateReflectionCC();
  if (!reflection_cc_) {
    return;
  }

  is_valid_ = true;
}

Reflector::~Reflector() = default;

bool Reflector::IsValid() const {
  return is_valid_;
}

std::shared_ptr<fml::Mapping> Reflector::GetReflectionJSON() const {
  if (!is_valid_) {
    return nullptr;
  }

  auto json_string =
      std::make_shared<std::string>(template_arguments_->dump(2u));

  return std::make_shared<fml::NonOwnedMapping>(
      reinterpret_cast<const uint8_t*>(json_string->data()),
      json_string->size(), [json_string](auto, auto) {});
}

std::shared_ptr<fml::Mapping> Reflector::GetReflectionHeader() const {
  return reflection_header_;
}

std::shared_ptr<fml::Mapping> Reflector::GetReflectionCC() const {
  return reflection_cc_;
}

std::optional<nlohmann::json> Reflector::GenerateTemplateArguments() const {
  nlohmann::json root;

  {
    const auto& entrypoints = compiler_->get_entry_points_and_stages();
    if (entrypoints.size() != 1) {
      FML_LOG(ERROR) << "Incorrect number of entrypoints in the shader. Found "
                     << entrypoints.size() << " but expected 1.";
      return std::nullopt;
    }

    root["entrypoint"] = entrypoints.front().name;
    root["shader_name"] = options_.shader_name;
    root["shader_stage"] =
        ExecutionModelToString(entrypoints.front().execution_model);
    root["header_file_name"] = options_.header_file_name;
  }

  const auto shader_resources = compiler_->get_shader_resources();

  if (auto uniform_buffers = ReflectResources(shader_resources.uniform_buffers);
      uniform_buffers.has_value()) {
    root["uniform_buffers"] = std::move(uniform_buffers.value());
  } else {
    return std::nullopt;
  }

  if (auto stage_inputs = ReflectResources(shader_resources.stage_inputs);
      stage_inputs.has_value()) {
    root["stage_inputs"] = std::move(stage_inputs.value());
  } else {
    return std::nullopt;
  }

  if (auto stage_outputs = ReflectResources(shader_resources.stage_outputs);
      stage_outputs.has_value()) {
    root["stage_outputs"] = std::move(stage_outputs.value());
  } else {
    return std::nullopt;
  }

  return root;
}

std::shared_ptr<fml::Mapping> Reflector::GenerateReflectionHeader() const {
  return InflateTemplate(kReflectionHeaderTemplate);
}

std::shared_ptr<fml::Mapping> Reflector::GenerateReflectionCC() const {
  return InflateTemplate(kReflectionCCTemplate);
}

std::shared_ptr<fml::Mapping> Reflector::InflateTemplate(
    const std::string_view& tmpl) const {
  inja::Environment env;
  env.set_trim_blocks(true);
  env.set_lstrip_blocks(true);

  env.add_callback("camel_case", 1u, [](inja::Arguments& args) {
    return ConvertToCamelCase(args.at(0u)->get<std::string>());
  });

  env.add_callback("to_shader_stage", 1u, [](inja::Arguments& args) {
    return StringToShaderStage(args.at(0u)->get<std::string>());
  });

  auto inflated_template =
      std::make_shared<std::string>(env.render(tmpl, *template_arguments_));

  return std::make_shared<fml::NonOwnedMapping>(
      reinterpret_cast<const uint8_t*>(inflated_template->data()),
      inflated_template->size(), [inflated_template](auto, auto) {});
}

std::optional<nlohmann::json::object_t> Reflector::ReflectResource(
    const spirv_cross::Resource& resource) const {
  nlohmann::json::object_t result;

  result["name"] = resource.name;
  result["descriptor_set"] = compiler_->get_decoration(
      resource.id, spv::Decoration::DecorationDescriptorSet);
  result["binding"] = compiler_->get_decoration(
      resource.id, spv::Decoration::DecorationBinding);
  result["location"] = compiler_->get_decoration(
      resource.id, spv::Decoration::DecorationLocation);
  result["index"] =
      compiler_->get_decoration(resource.id, spv::Decoration::DecorationIndex);
  auto type = ReflectType(resource.type_id);
  if (!type.has_value()) {
    return std::nullopt;
  }
  result["type"] = std::move(type.value());
  return result;
}

std::optional<nlohmann::json::object_t> Reflector::ReflectType(
    const spirv_cross::TypeID& type_id) const {
  nlohmann::json::object_t result;

  const auto type = compiler_->get_type(type_id);

  result["type_name"] = BaseTypeToString(type.basetype);
  result["bit_width"] = type.width;
  result["vec_size"] = type.vecsize;
  result["columns"] = type.columns;

  return result;
}

std::optional<nlohmann::json::array_t> Reflector::ReflectResources(
    const spirv_cross::SmallVector<spirv_cross::Resource>& resources) const {
  nlohmann::json::array_t result;
  result.reserve(resources.size());
  for (const auto& resource : resources) {
    if (auto reflected = ReflectResource(resource); reflected.has_value()) {
      result.emplace_back(std::move(reflected.value()));
    } else {
      return std::nullopt;
    }
  }
  return result;
}

}  // namespace compiler
}  // namespace impeller
