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
#include "inja/inja.hpp"
#include "rapidjson/document.h"
#include "rapidjson/prettywriter.h"
#include "rapidjson/rapidjson.h"
#include "rapidjson/stringbuffer.h"

namespace impeller {
namespace compiler {

using Writer = rapidjson::PrettyWriter<rapidjson::StringBuffer>;

static std::string BaseTypeToString(spirv_cross::SPIRType::BaseType type) {
  using Type = spirv_cross::SPIRType::BaseType;
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
    const spirv_cross::ParsedIR& ir,
    const spirv_cross::CompilerMSL& compiler,
    const spirv_cross::SPIRType& type,
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

static std::string GetMemberNameAtIndex(
    const spirv_cross::ParsedIR& ir,
    const spirv_cross::CompilerMSL& compiler,
    const spirv_cross::SPIRType& type,
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

static bool ReflectType(Writer& writer,
                        const spirv_cross::ParsedIR& ir,
                        const spirv_cross::CompilerMSL& compiler,
                        const spirv_cross::TypeID& type_id) {
  const auto type = compiler.get_type(type_id);

  writer.Key("type");
  writer.StartObject();

  writer.Key("type_name");
  writer.String(BaseTypeToString(type.basetype));

  writer.Key("bit_width");
  writer.Uint64(type.width);

  writer.Key("vec_size");
  writer.Uint64(type.vecsize);

  writer.Key("columns");
  writer.Uint64(type.columns);

  // Member types should only be present if the base type is a struct.
  if (!type.member_types.empty()) {
    writer.Key("member");
    writer.StartArray();
    for (size_t i = 0; i < type.member_types.size(); i++) {
      writer.StartObject();
      {
        writer.Key("type_id");
        writer.Uint64(type.member_types[i]);
        writer.Key("member_name");
        writer.String(GetMemberNameAtIndex(ir, compiler, type, i));
      }
      writer.EndObject();
    }
    writer.EndArray();
  }

  writer.EndObject();
  return true;
}

static bool ReflectBaseResource(Writer& writer,
                                const spirv_cross::ParsedIR& ir,
                                const spirv_cross::CompilerMSL& compiler,
                                const spirv_cross::Resource& res) {
  writer.Key("name");
  writer.String(res.name);

  writer.Key("descriptor_set");
  writer.Uint64(compiler.get_decoration(
      res.id, spv::Decoration::DecorationDescriptorSet));

  writer.Key("binding");
  writer.Uint64(
      compiler.get_decoration(res.id, spv::Decoration::DecorationBinding));

  writer.Key("location");
  writer.Uint64(
      compiler.get_decoration(res.id, spv::Decoration::DecorationLocation));

  if (!ReflectType(writer, ir, compiler, res.type_id)) {
    return false;
  }

  return true;
}

static bool ReflectStageIO(Writer& writer,
                           const spirv_cross::ParsedIR& ir,
                           const spirv_cross::CompilerMSL& compiler,
                           const spirv_cross::Resource& io) {
  writer.StartObject();

  if (!ReflectBaseResource(writer, ir, compiler, io)) {
    return false;
  }

  writer.EndObject();
  return true;
}

static bool ReflectUniformBuffer(Writer& writer,
                                 const spirv_cross::ParsedIR& ir,
                                 const spirv_cross::CompilerMSL& compiler,
                                 const spirv_cross::Resource& buffer) {
  writer.StartObject();

  if (!ReflectBaseResource(writer, ir, compiler, buffer)) {
    return false;
  }

  writer.Key("index");
  writer.Uint64(
      compiler.get_decoration(buffer.id, spv::Decoration::DecorationIndex));

  writer.EndObject();
  return true;
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

static std::shared_ptr<fml::Mapping> ReflectTemplateArguments(
    const Reflector::Options& options,
    const spirv_cross::ParsedIR& ir,
    const spirv_cross::CompilerMSL& compiler) {
  auto buffer = std::make_shared<rapidjson::StringBuffer>();
  Writer writer(*buffer);

  writer.StartObject();  // root

  {
    const auto& entrypoints = compiler.get_entry_points_and_stages();
    if (entrypoints.size() != 1) {
      FML_LOG(ERROR) << "Incorrect number of entrypoints in the shader. Found "
                     << entrypoints.size() << " but expected 1.";
      return nullptr;
    }

    writer.Key("entrypoint");
    writer.String(entrypoints.front().name);

    writer.Key("shader_name");
    writer.String(options.shader_name);

    writer.Key("shader_stage");
    writer.String(ExecutionModelToString(entrypoints.front().execution_model));

    writer.Key("header_file_name");
    writer.String(options.header_file_name);
  }

  const auto all_shader_resources = compiler.get_shader_resources();

  {
    writer.Key("uniform_buffers");
    writer.StartArray();
    for (const auto& uniform_buffer : all_shader_resources.uniform_buffers) {
      if (!ReflectUniformBuffer(writer, ir, compiler, uniform_buffer)) {
        FML_LOG(ERROR) << "Could not reflect uniform buffer.";
        return nullptr;
      }
    }
    writer.EndArray();
  }

  {
    writer.Key("stage_inputs");
    writer.StartArray();
    for (const auto& input : all_shader_resources.stage_inputs) {
      if (!ReflectStageIO(writer, ir, compiler, input)) {
        FML_LOG(ERROR) << "Could not reflect stage input.";
        return nullptr;
      }
    }
    writer.EndArray();
  }

  {
    writer.Key("stage_outputs");
    writer.StartArray();
    for (const auto& output : all_shader_resources.stage_outputs) {
      if (!ReflectStageIO(writer, ir, compiler, output)) {
        FML_LOG(ERROR) << "Could not reflect stage output.";
        return nullptr;
      }
    }
    writer.EndArray();
  }

  {
    auto reflect_types =
        [&](const spirv_cross::SmallVector<spirv_cross::Resource> resources)
        -> bool {
      for (const auto& resource : resources) {
      }
      return true;
    };
    writer.Key("type_definitions");
    writer.StartArray();
    if (!reflect_types(all_shader_resources.uniform_buffers) ||
        !reflect_types(all_shader_resources.stage_inputs) ||
        !reflect_types(all_shader_resources.stage_outputs)) {
      return nullptr;
    }
    writer.EndArray();
  }

  writer.EndObject();  // root

  return std::make_shared<fml::NonOwnedMapping>(
      reinterpret_cast<const uint8_t*>(buffer->GetString()), buffer->GetSize(),
      [buffer](auto, auto) {});
}

static std::shared_ptr<fml::Mapping> InflateTemplate(
    const spirv_cross::CompilerMSL& compiler,
    const std::string_view& tmpl,
    const fml::Mapping* reflection_args) {
  if (!reflection_args) {
    return nullptr;
  }

  inja::Environment env;
  env.set_trim_blocks(true);
  env.set_lstrip_blocks(true);

  env.add_callback("camel_case", 1u, [](inja::Arguments& args) {
    return ConvertToCamelCase(args.at(0u)->get<std::string>());
  });

  env.add_callback("to_shader_stage", 1u, [](inja::Arguments& args) {
    return StringToShaderStage(args.at(0u)->get<std::string>());
  });

  auto template_data = inja::json::parse(
      reinterpret_cast<const char*>(reflection_args->GetMapping()));

  auto inflated_template =
      std::make_shared<std::string>(env.render(tmpl, template_data));

  return std::make_shared<fml::NonOwnedMapping>(
      reinterpret_cast<const uint8_t*>(inflated_template->data()),
      inflated_template->size(), [inflated_template](auto, auto) {});
}

Reflector::Reflector(Options options,
                     const spirv_cross::ParsedIR& ir,
                     const spirv_cross::CompilerMSL& compiler)
    : options_(std::move(options)),
      template_arguments_(ReflectTemplateArguments(options_, ir, compiler)),
      reflection_header_(InflateTemplate(compiler,
                                         kReflectionHeaderTemplate,
                                         template_arguments_.get())),
      reflection_cc_(InflateTemplate(compiler,
                                     kReflectionCCTemplate,
                                     template_arguments_.get())) {
  if (!template_arguments_) {
    return;
  }

  if (!reflection_header_) {
    return;
  }

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
  return template_arguments_;
}

std::shared_ptr<fml::Mapping> Reflector::GetReflectionHeader() const {
  return reflection_header_;
}

std::shared_ptr<fml::Mapping> Reflector::GetReflectionCC() const {
  return reflection_cc_;
}

}  // namespace compiler
}  // namespace impeller
