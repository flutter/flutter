// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/compiler/reflector.h"

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
      return "Void";
    case Type::Boolean:
      return "Boolean";
    case Type::SByte:
      return "SByte";
    case Type::UByte:
      return "UByte";
    case Type::Short:
      return "Short";
    case Type::UShort:
      return "UShort";
    case Type::Int:
      return "Int";
    case Type::UInt:
      return "UInt";
    case Type::Int64:
      return "Int64";
    case Type::UInt64:
      return "UInt64";
    case Type::AtomicCounter:
      return "AtomicCounter";
    case Type::Half:
      return "Half";
    case Type::Float:
      return "Float";
    case Type::Double:
      return "Double";
    case Type::Struct:
      return "Struct";
    case Type::Image:
      return "Image";
    case Type::SampledImage:
      return "SampledImage";
    case Type::Sampler:
      return "Sampler";
    case Type::AccelerationStructure:
      return "AccelerationStructure";
    case Type::RayQuery:
      return "RayQuery";
    default:
      return "unknown";
  }
}

static bool ReflectType(Writer& writer,
                        const spirv_cross::CompilerMSL& compiler,
                        const spirv_cross::SPIRType& type) {
  writer.Key("type");
  writer.StartObject();

  writer.Key("type_name");
  writer.String(BaseTypeToString(type.basetype));

  writer.Key("member_types");
  writer.StartArray();
  for (const auto& member : type.member_types) {
    if (!ReflectType(writer, compiler, compiler.get_type(member))) {
      return false;
    }
  }
  writer.EndArray();

  writer.EndObject();
  return true;
}

static bool ReflectBaseResource(Writer& writer,
                                const spirv_cross::CompilerMSL& compiler,
                                const spirv_cross::Resource& res) {
  writer.Key("name");
  writer.String(compiler.get_name(res.id));

  writer.Key("descriptor_set");
  writer.Uint64(compiler.get_decoration(
      res.id, spv::Decoration::DecorationDescriptorSet));

  writer.Key("binding");
  writer.Uint64(
      compiler.get_decoration(res.id, spv::Decoration::DecorationBinding));

  writer.Key("location");
  writer.Uint64(
      compiler.get_decoration(res.id, spv::Decoration::DecorationLocation));

  if (!ReflectType(writer, compiler, compiler.get_type(res.type_id))) {
    return false;
  }

  return true;
}

static bool ReflectStageInput(Writer& writer,
                              const spirv_cross::CompilerMSL& compiler,
                              const spirv_cross::Resource& input) {
  writer.StartObject();

  if (!ReflectBaseResource(writer, compiler, input)) {
    return false;
  }

  writer.EndObject();
  return true;
}

static bool ReflectUniformBuffer(Writer& writer,
                                 const spirv_cross::CompilerMSL& compiler,
                                 const spirv_cross::Resource& buffer) {
  writer.StartObject();

  if (!ReflectBaseResource(writer, compiler, buffer)) {
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
      return "ShaderStage::kVertex";
    case spv::ExecutionModel::ExecutionModelFragment:
      return "ShaderStage::kFragment";
    default:
      return "ShaderStage::kUnsupported";
  }
}

static std::shared_ptr<fml::Mapping> ReflectTemplateArguments(
    const Reflector::Options& options,
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

  {
    writer.Key("uniform_buffers");
    writer.StartArray();
    for (const auto& uniform_buffer :
         compiler.get_shader_resources().uniform_buffers) {
      if (!ReflectUniformBuffer(writer, compiler, uniform_buffer)) {
        FML_LOG(ERROR) << "Could not reflect uniform buffer.";
        return nullptr;
      }
    }
    writer.EndArray();
  }

  {
    writer.Key("stage_inputs");
    writer.StartArray();
    for (const auto& input : compiler.get_shader_resources().stage_inputs) {
      if (!ReflectStageInput(writer, compiler, input)) {
        FML_LOG(ERROR) << "Could not reflect uniform buffer.";
        return nullptr;
      }
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

  auto template_data = inja::json::parse(
      reinterpret_cast<const char*>(reflection_args->GetMapping()));

  auto inflated_template =
      std::make_shared<std::string>(env.render(tmpl, template_data));

  return std::make_shared<fml::NonOwnedMapping>(
      reinterpret_cast<const uint8_t*>(inflated_template->data()),
      inflated_template->size(), [inflated_template](auto, auto) {});
}

Reflector::Reflector(Options options, const spirv_cross::CompilerMSL& compiler)
    : options_(std::move(options)),
      template_arguments_(ReflectTemplateArguments(options_, compiler)),
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
