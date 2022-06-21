// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// FLUTTER_NOLINT: https://github.com/flutter/flutter/issues/105732

#include "impeller/compiler/reflector.h"

#include <atomic>
#include <optional>
#include <set>
#include <sstream>

#include "flutter/fml/closure.h"
#include "flutter/fml/logging.h"
#include "impeller/base/strings.h"
#include "impeller/base/validation.h"
#include "impeller/compiler/code_gen_template.h"
#include "impeller/compiler/utilities.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/scalar.h"

namespace impeller {
namespace compiler {

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

static std::string ExecutionModelToString(spv::ExecutionModel model) {
  switch (model) {
    case spv::ExecutionModel::ExecutionModelVertex:
      return "vertex";
    case spv::ExecutionModel::ExecutionModelFragment:
      return "fragment";
    case spv::ExecutionModel::ExecutionModelTessellationControl:
      return "tessellation_control";
    case spv::ExecutionModel::ExecutionModelTessellationEvaluation:
      return "tessellation_evaluation";
    case spv::ExecutionModel::ExecutionModelGLCompute:
      return "compute";
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

  if (str == "tessellation_control") {
    return "ShaderStage::kTessellationControl";
  }

  if (str == "tessellation_evaluation") {
    return "ShaderStage::kTessellationEvaluation";
  }

  if (str == "compute") {
    return "ShaderStage::kCompute";
  }

  return "ShaderStage::kUnknown";
}

Reflector::Reflector(Options options,
                     std::shared_ptr<const spirv_cross::ParsedIR> ir,
                     std::shared_ptr<fml::Mapping> shader_data,
                     CompilerBackend compiler)
    : options_(std::move(options)),
      ir_(std::move(ir)),
      shader_data_(std::move(shader_data)),
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

  runtime_stage_data_ = GenerateRuntimeStageData();
  if (!runtime_stage_data_) {
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

std::shared_ptr<RuntimeStageData> Reflector::GetRuntimeStageData() const {
  return runtime_stage_data_;
}

std::optional<nlohmann::json> Reflector::GenerateTemplateArguments() const {
  nlohmann::json root;

  const auto& entrypoints = compiler_->get_entry_points_and_stages();
  if (entrypoints.size() != 1) {
    VALIDATION_LOG << "Incorrect number of entrypoints in the shader. Found "
                   << entrypoints.size() << " but expected 1.";
    return std::nullopt;
  }

  {
    root["entrypoint"] = options_.entry_point_name;
    root["shader_name"] = options_.shader_name;
    root["shader_stage"] =
        ExecutionModelToString(entrypoints.front().execution_model);
    root["header_file_name"] = options_.header_file_name;
  }

  const auto shader_resources = compiler_->get_shader_resources();

  // Uniform and storage buffers.
  {
    auto& buffers = root["buffers"] = nlohmann::json::array_t{};
    if (auto uniform_buffers_json =
            ReflectResources(shader_resources.uniform_buffers);
        uniform_buffers_json.has_value()) {
      for (const auto& uniform_buffer : uniform_buffers_json.value()) {
        buffers.emplace_back(std::move(uniform_buffer));
      }
    } else {
      return std::nullopt;
    }
    if (auto storage_buffers_json =
            ReflectResources(shader_resources.storage_buffers);
        storage_buffers_json.has_value()) {
      for (const auto& uniform_buffer : storage_buffers_json.value()) {
        buffers.emplace_back(std::move(uniform_buffer));
      }
    } else {
      return std::nullopt;
    }
  }

  {
    auto& stage_inputs = root["stage_inputs"] = nlohmann::json::array_t{};
    if (auto stage_inputs_json =
            ReflectResources(shader_resources.stage_inputs);
        stage_inputs_json.has_value()) {
      stage_inputs = std::move(stage_inputs_json.value());
    } else {
      return std::nullopt;
    }
  }

  {
    auto combined_sampled_images =
        ReflectResources(shader_resources.sampled_images);
    auto images = ReflectResources(shader_resources.separate_images);
    auto samplers = ReflectResources(shader_resources.separate_samplers);
    if (!combined_sampled_images.has_value() || !images.has_value() ||
        !samplers.has_value()) {
      return std::nullopt;
    }
    auto& sampled_images = root["sampled_images"] = nlohmann::json::array_t{};
    for (auto value : combined_sampled_images.value()) {
      sampled_images.emplace_back(std::move(value));
    }
    for (auto value : images.value()) {
      sampled_images.emplace_back(std::move(value));
    }
    for (auto value : samplers.value()) {
      sampled_images.emplace_back(std::move(value));
    }
  }

  if (auto stage_outputs = ReflectResources(shader_resources.stage_outputs);
      stage_outputs.has_value()) {
    root["stage_outputs"] = std::move(stage_outputs.value());
  } else {
    return std::nullopt;
  }

  {
    auto& struct_definitions = root["struct_definitions"] =
        nlohmann::json::array_t{};
    if (entrypoints.front().execution_model ==
            spv::ExecutionModel::ExecutionModelVertex &&
        !shader_resources.stage_inputs.empty()) {
      if (auto struc =
              ReflectPerVertexStructDefinition(shader_resources.stage_inputs);
          struc.has_value()) {
        struct_definitions.emplace_back(EmitStructDefinition(struc.value()));
      } else {
        // If there are stage inputs, it is an error to not generate a per
        // vertex data struct for a vertex like shader stage.
        return std::nullopt;
      }
    }

    std::set<spirv_cross::ID> known_structs;
    ir_->for_each_typed_id<spirv_cross::SPIRType>(
        [&](uint32_t, const spirv_cross::SPIRType& type) {
          if (known_structs.find(type.self) != known_structs.end()) {
            // Iterating over types this way leads to duplicates which may cause
            // duplicate struct definitions.
            return;
          }
          known_structs.insert(type.self);
          if (auto struc = ReflectStructDefinition(type.self);
              struc.has_value()) {
            struct_definitions.emplace_back(
                EmitStructDefinition(struc.value()));
          }
        });
  }

  root["bind_prototypes"] = EmitBindPrototypes(shader_resources);

  return root;
}

std::shared_ptr<fml::Mapping> Reflector::GenerateReflectionHeader() const {
  return InflateTemplate(kReflectionHeaderTemplate);
}

std::shared_ptr<fml::Mapping> Reflector::GenerateReflectionCC() const {
  return InflateTemplate(kReflectionCCTemplate);
}

std::shared_ptr<RuntimeStageData> Reflector::GenerateRuntimeStageData() const {
  const auto& entrypoints = compiler_->get_entry_points_and_stages();
  if (entrypoints.size() != 1u) {
    VALIDATION_LOG << "Single entrypoint not found.";
    return nullptr;
  }
  auto data = std::make_shared<RuntimeStageData>(
      options_.entry_point_name,            //
      entrypoints.front().execution_model,  //
      options_.target_platform              //
  );
  data->SetShaderData(shader_data_);
  ir_->for_each_typed_id<spirv_cross::SPIRVariable>(
      [&](uint32_t, const spirv_cross::SPIRVariable& var) {
        if (var.storage != spv::StorageClassUniformConstant) {
          return;
        }
        const auto spir_type = compiler_->get_type(var.basetype);
        UniformDescription uniform_description;
        uniform_description.name = compiler_->get_name(var.self);
        uniform_description.location = compiler_->get_decoration(
            var.self, spv::Decoration::DecorationLocation);
        uniform_description.type = spir_type.basetype;
        uniform_description.rows = spir_type.vecsize;
        uniform_description.columns = spir_type.columns;
        data->AddUniformDescription(std::move(uniform_description));
      });
  return data;
}

static std::string ToString(CompilerBackend::Type type) {
  switch (type) {
    case CompilerBackend::Type::kMSL:
      return "Metal Shading Language";
    case CompilerBackend::Type::kGLSL:
      return "OpenGL Shading Language";
  }
  FML_UNREACHABLE();
}

std::shared_ptr<fml::Mapping> Reflector::InflateTemplate(
    std::string_view tmpl) const {
  inja::Environment env;
  env.set_trim_blocks(true);
  env.set_lstrip_blocks(true);

  env.add_callback("camel_case", 1u, [](inja::Arguments& args) {
    return ConvertToCamelCase(args.at(0u)->get<std::string>());
  });

  env.add_callback("to_shader_stage", 1u, [](inja::Arguments& args) {
    return StringToShaderStage(args.at(0u)->get<std::string>());
  });

  env.add_callback("get_generator_name", 0u,
                   [type = compiler_.GetType()](inja::Arguments& args) {
                     return ToString(type);
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
  result["ext_res_0"] = compiler_.GetExtendedMSLResourceBinding(
      CompilerBackend::ExtendedResourceIndex::kPrimary, resource.id);
  result["ext_res_1"] = compiler_.GetExtendedMSLResourceBinding(
      CompilerBackend::ExtendedResourceIndex::kSecondary, resource.id);
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
  auto& members = result["members"] = nlohmann::json::array_t{};
  if (type.basetype == spirv_cross::SPIRType::BaseType::Struct) {
    for (const auto& struct_member : ReadStructMembers(type_id)) {
      auto member = nlohmann::json::object_t{};
      member["name"] = struct_member.name;
      member["type"] = struct_member.type;
      member["base_type"] = struct_member.base_type;
      member["offset"] = struct_member.offset;
      member["size"] = struct_member.byte_length;
      members.emplace_back(std::move(member));
    }
  }

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

static std::string TypeNameWithPaddingOfSize(size_t size) {
  std::stringstream stream;
  stream << "Padding<" << size << ">";
  return stream.str();
}

struct KnownType {
  std::string name;
  size_t byte_size = 0;
};

static std::optional<KnownType> ReadKnownScalarType(
    spirv_cross::SPIRType::BaseType type) {
  switch (type) {
    case spirv_cross::SPIRType::BaseType::Boolean:
      return KnownType{
          .name = "bool",
          .byte_size = sizeof(bool),
      };
    case spirv_cross::SPIRType::BaseType::Float:
      return KnownType{
          .name = "Scalar",
          .byte_size = sizeof(Scalar),
      };
    case spirv_cross::SPIRType::BaseType::UInt:
      return KnownType{
          .name = "uint32_t",
          .byte_size = sizeof(uint32_t),
      };
    case spirv_cross::SPIRType::BaseType::Int:
      return KnownType{
          .name = "int32_t",
          .byte_size = sizeof(int32_t),
      };
    default:
      break;
  }
  return std::nullopt;
}

//------------------------------------------------------------------------------
/// @brief      Get the reflected struct size. In the vast majority of the
///             cases, this is the same as the declared struct size as given by
///             the compiler. But, additional padding may need to be introduced
///             after the end of the struct to keep in line with the alignment
///             requirement of the individual struct members. This method
///             figures out the actual size of the reflected struct that can be
///             referenced in native code.
///
/// @param[in]  members  The members
///
/// @return     The reflected structure size.
///
static size_t GetReflectedStructSize(const std::vector<StructMember>& members) {
  auto struct_size = 0u;
  for (const auto& member : members) {
    struct_size += member.byte_length;
  }
  return struct_size;
}

std::vector<StructMember> Reflector::ReadStructMembers(
    const spirv_cross::TypeID& type_id) const {
  const auto& struct_type = compiler_->get_type(type_id);
  FML_CHECK(struct_type.basetype == spirv_cross::SPIRType::BaseType::Struct);

  std::vector<StructMember> result;

  size_t current_byte_offset = 0;
  size_t max_member_alignment = 0;

  for (size_t i = 0; i < struct_type.member_types.size(); i++) {
    const auto& member = compiler_->get_type(struct_type.member_types[i]);
    const auto struct_member_offset =
        compiler_->type_struct_member_offset(struct_type, i);

    if (struct_member_offset > current_byte_offset) {
      const auto alignment_pad = struct_member_offset - current_byte_offset;
      result.emplace_back(StructMember{
          TypeNameWithPaddingOfSize(alignment_pad),                 // type
          BaseTypeToString(spirv_cross::SPIRType::BaseType::Void),  // basetype
          SPrintF("_PADDING_%s_",
                  GetMemberNameAtIndex(struct_type, i).c_str()),  // name
          current_byte_offset,                                    // offset
          alignment_pad                                           // byte_length
      });
      current_byte_offset += alignment_pad;
    }

    max_member_alignment =
        std::max<size_t>(max_member_alignment,
                         (member.width / 8) * member.columns * member.vecsize);

    FML_CHECK(current_byte_offset == struct_member_offset);

    // Tightly packed 4x4 Matrix is special cased as we know how to work with
    // those.
    if (member.basetype == spirv_cross::SPIRType::BaseType::Float &&  //
        member.width == sizeof(Scalar) * 8 &&                         //
        member.columns == 4 &&                                        //
        member.vecsize == 4                                           //
    ) {
      result.emplace_back(StructMember{
          "Matrix",                              // type
          BaseTypeToString(member.basetype),     // basetype
          GetMemberNameAtIndex(struct_type, i),  // name
          struct_member_offset,                  // offset
          sizeof(Matrix)                         // byte_length
      });
      current_byte_offset += sizeof(Matrix);
      continue;
    }

    // Tightly packed Point (vec2).
    if (member.basetype == spirv_cross::SPIRType::BaseType::Float &&  //
        member.width == sizeof(float) * 8 &&                          //
        member.columns == 1 &&                                        //
        member.vecsize == 2                                           //
    ) {
      result.emplace_back(StructMember{
          "Point",                               // type
          BaseTypeToString(member.basetype),     // basetype
          GetMemberNameAtIndex(struct_type, i),  // name
          struct_member_offset,                  // offset
          sizeof(Point)                          // byte_length
      });
      current_byte_offset += sizeof(Point);
      continue;
    }

    // Tightly packed Vector3.
    if (member.basetype == spirv_cross::SPIRType::BaseType::Float &&  //
        member.width == sizeof(float) * 8 &&                          //
        member.columns == 1 &&                                        //
        member.vecsize == 3                                           //
    ) {
      result.emplace_back(StructMember{
          "Vector3",                             // type
          BaseTypeToString(member.basetype),     // basetype
          GetMemberNameAtIndex(struct_type, i),  // name
          struct_member_offset,                  // offset
          sizeof(Vector3)                        // byte_length
      });
      current_byte_offset += sizeof(Vector3);
      continue;
    }

    // Tightly packed Vector4.
    if (member.basetype == spirv_cross::SPIRType::BaseType::Float &&  //
        member.width == sizeof(float) * 8 &&                          //
        member.columns == 1 &&                                        //
        member.vecsize == 4                                           //
    ) {
      result.emplace_back(StructMember{
          "Vector4",                             // type
          BaseTypeToString(member.basetype),     // basetype
          GetMemberNameAtIndex(struct_type, i),  // name
          struct_member_offset,                  // offset
          sizeof(Vector4)                        // byte_length
      });
      current_byte_offset += sizeof(Vector4);
      continue;
    }

    // Other isolated scalars (like bool, int, float/Scalar, etc..).
    {
      auto maybe_known_type = ReadKnownScalarType(member.basetype);
      if (maybe_known_type.has_value() &&  //
          member.columns == 1 &&           //
          member.vecsize == 1              //
      ) {
        // Add the type directly.
        result.emplace_back(StructMember{
            maybe_known_type.value().name,         // type
            BaseTypeToString(member.basetype),     // basetype
            GetMemberNameAtIndex(struct_type, i),  // name
            struct_member_offset,                  // offset
            maybe_known_type.value().byte_size     // byte_length
        });
        current_byte_offset += maybe_known_type.value().byte_size;
        continue;
      }
    }

    // Catch all for unknown types. Just add the necessary padding to the struct
    // and move on.
    {
      const size_t byte_length =
          (member.width * member.columns * member.vecsize) / 8u;
      result.emplace_back(StructMember{
          TypeNameWithPaddingOfSize(byte_length),  // type
          BaseTypeToString(member.basetype),       // basetype
          GetMemberNameAtIndex(struct_type, i),    // name
          struct_member_offset,                    // offset
          byte_length                              // byte_length
      });
      current_byte_offset += byte_length;
      continue;
    }
  }

  if (max_member_alignment > 0u) {
    const auto struct_length = current_byte_offset;
    {
      const auto excess = struct_length % max_member_alignment;
      if (excess != 0) {
        const auto padding = max_member_alignment - excess;
        result.emplace_back(StructMember{
            TypeNameWithPaddingOfSize(padding),  // type
            BaseTypeToString(
                spirv_cross::SPIRType::BaseType::Void),  // basetype
            "_PADDING_",                                 // name
            current_byte_offset,                         // offset
            padding                                      // byte_length
        });
      }
    }
  }

  return result;
}

std::optional<Reflector::StructDefinition> Reflector::ReflectStructDefinition(
    const spirv_cross::TypeID& type_id) const {
  const auto& type = compiler_->get_type(type_id);
  if (type.basetype != spirv_cross::SPIRType::BaseType::Struct) {
    return std::nullopt;
  }

  const auto struct_name = compiler_->get_name(type_id);
  if (struct_name.find("_RESERVED_IDENTIFIER_") != std::string::npos) {
    return std::nullopt;
  }

  auto struct_members = ReadStructMembers(type_id);
  auto reflected_struct_size = GetReflectedStructSize(struct_members);

  StructDefinition struc;
  struc.name = struct_name;
  struc.byte_length = reflected_struct_size;
  struc.members = std::move(struct_members);
  return struc;
}

nlohmann::json::object_t Reflector::EmitStructDefinition(
    std::optional<Reflector::StructDefinition> struc) const {
  nlohmann::json::object_t result;
  result["name"] = struc->name;
  result["byte_length"] = struc->byte_length;
  auto& members = result["members"] = nlohmann::json::array_t{};
  for (const auto& struc_member : struc->members) {
    auto& member = members.emplace_back(nlohmann::json::object_t{});
    member["name"] = struc_member.name;
    member["type"] = struc_member.type;
    member["base_type"] = struc_member.base_type;
    member["offset"] = struc_member.offset;
    member["byte_length"] = struc_member.byte_length;
  }
  return result;
}

struct VertexType {
  std::string type_name;
  std::string base_type_name;
  std::string variable_name;
  size_t byte_length = 0u;
};

static VertexType VertexTypeFromInputResource(
    const spirv_cross::Compiler& compiler,
    const spirv_cross::Resource* resource) {
  VertexType result;
  result.variable_name = resource->name;
  const auto type = compiler.get_type(resource->type_id);
  result.base_type_name = BaseTypeToString(type.basetype);
  const auto total_size = type.columns * type.vecsize * type.width / 8u;
  result.byte_length = total_size;

  if (type.basetype == spirv_cross::SPIRType::BaseType::Float &&
      type.columns == 1u && type.vecsize == 2u &&
      type.width == sizeof(float) * 8u) {
    result.type_name = "Point";
  } else if (type.basetype == spirv_cross::SPIRType::BaseType::Float &&
             type.columns == 1u && type.vecsize == 4u &&
             type.width == sizeof(float) * 8u) {
    result.type_name = "Vector4";
  } else if (type.basetype == spirv_cross::SPIRType::BaseType::Float &&
             type.columns == 1u && type.vecsize == 3u &&
             type.width == sizeof(float) * 8u) {
    result.type_name = "Vector3";
  } else if (type.basetype == spirv_cross::SPIRType::BaseType::Float &&
             type.columns == 1u && type.vecsize == 1u &&
             type.width == sizeof(float) * 8u) {
    result.type_name = "Scalar";
  } else if (type.basetype == spirv_cross::SPIRType::BaseType::Int &&
             type.columns == 1u && type.vecsize == 1u &&
             type.width == sizeof(int32_t) * 8u) {
    result.type_name = "int32_t";
  } else {
    // Catch all unknown padding.
    result.type_name = TypeNameWithPaddingOfSize(total_size);
  }

  return result;
}

std::optional<Reflector::StructDefinition>
Reflector::ReflectPerVertexStructDefinition(
    const spirv_cross::SmallVector<spirv_cross::Resource>& stage_inputs) const {
  // Avoid emitting a zero sized structure. The code gen templates assume a
  // non-zero size.
  if (stage_inputs.empty()) {
    return std::nullopt;
  }

  // Validate locations are contiguous and there are no duplicates.
  std::set<uint32_t> locations;
  for (const auto& input : stage_inputs) {
    auto location = compiler_->get_decoration(
        input.id, spv::Decoration::DecorationLocation);
    if (locations.count(location) != 0) {
      // Duplicate location. Bail.
      return std::nullopt;
    }
    locations.insert(location);
  }

  for (size_t i = 0; i < locations.size(); i++) {
    if (locations.count(i) != 1) {
      // Locations are not contiguous. This usually happens when a single stage
      // input takes multiple input slots. No reflection information can be
      // generated for such cases anyway. So bail! It is up to the shader author
      // to make sure one stage input maps to a single input slot.
      return std::nullopt;
    }
  }

  auto input_for_location =
      [&](uint32_t queried_location) -> const spirv_cross::Resource* {
    for (const auto& input : stage_inputs) {
      auto location = compiler_->get_decoration(
          input.id, spv::Decoration::DecorationLocation);
      if (location == queried_location) {
        return &input;
      }
    }
    // This really cannot happen with all the validation above.
    FML_UNREACHABLE();
    return nullptr;
  };

  StructDefinition struc;
  struc.name = "PerVertexData";
  struc.byte_length = 0u;
  for (size_t i = 0; i < locations.size(); i++) {
    auto resource = input_for_location(i);
    if (resource == nullptr) {
      return std::nullopt;
    }
    const auto vertex_type =
        VertexTypeFromInputResource(*compiler_.GetCompiler(), resource);

    auto member = StructMember{
        vertex_type.type_name,       // type
        vertex_type.base_type_name,  // base type
        vertex_type.variable_name,   // name
        struc.byte_length,           // offset
        vertex_type.byte_length      // byte_length
    };
    struc.byte_length += vertex_type.byte_length;
    struc.members.emplace_back(std::move(member));
  }
  return struc;
}

std::optional<std::string> Reflector::GetMemberNameAtIndexIfExists(
    const spirv_cross::SPIRType& parent_type,
    size_t index) const {
  if (parent_type.type_alias != 0) {
    return GetMemberNameAtIndexIfExists(
        compiler_->get_type(parent_type.type_alias), index);
  }

  if (auto found = ir_->meta.find(parent_type.self); found != ir_->meta.end()) {
    const auto& members = found->second.members;
    if (index < members.size() && !members[index].alias.empty()) {
      return members[index].alias;
    }
  }
  return std::nullopt;
}

std::string Reflector::GetMemberNameAtIndex(
    const spirv_cross::SPIRType& parent_type,
    size_t index,
    std::string suffix) const {
  if (auto name = GetMemberNameAtIndexIfExists(parent_type, index);
      name.has_value()) {
    return name.value();
  }
  static std::atomic_size_t sUnnamedMembersID;
  std::stringstream stream;
  stream << "unnamed_" << sUnnamedMembersID++ << suffix;
  return stream.str();
}

std::vector<Reflector::BindPrototype> Reflector::ReflectBindPrototypes(
    const spirv_cross::ShaderResources& resources) const {
  std::vector<BindPrototype> prototypes;
  for (const auto& uniform_buffer : resources.uniform_buffers) {
    auto& proto = prototypes.emplace_back(BindPrototype{});
    proto.return_type = "bool";
    proto.name = ConvertToCamelCase(uniform_buffer.name);
    {
      std::stringstream stream;
      stream << "Bind uniform buffer for resource named " << uniform_buffer.name
             << ".";
      proto.docstring = stream.str();
    }
    proto.args.push_back(BindPrototypeArgument{
        .type_name = "Command&",
        .argument_name = "command",
    });
    proto.args.push_back(BindPrototypeArgument{
        .type_name = "BufferView",
        .argument_name = "view",
    });
  }
  for (const auto& storage_buffer : resources.storage_buffers) {
    auto& proto = prototypes.emplace_back(BindPrototype{});
    proto.return_type = "bool";
    proto.name = ConvertToCamelCase(storage_buffer.name);
    {
      std::stringstream stream;
      stream << "Bind storage buffer for resource named " << storage_buffer.name
             << ".";
      proto.docstring = stream.str();
    }
    proto.args.push_back(BindPrototypeArgument{
        .type_name = "Command&",
        .argument_name = "command",
    });
    proto.args.push_back(BindPrototypeArgument{
        .type_name = "BufferView",
        .argument_name = "view",
    });
  }
  for (const auto& sampled_image : resources.sampled_images) {
    auto& proto = prototypes.emplace_back(BindPrototype{});
    proto.return_type = "bool";
    proto.name = ConvertToCamelCase(sampled_image.name);
    {
      std::stringstream stream;
      stream << "Bind combined image sampler for resource named "
             << sampled_image.name << ".";
      proto.docstring = stream.str();
    }
    proto.args.push_back(BindPrototypeArgument{
        .type_name = "Command&",
        .argument_name = "command",
    });
    proto.args.push_back(BindPrototypeArgument{
        .type_name = "std::shared_ptr<const Texture>",
        .argument_name = "texture",
    });
    proto.args.push_back(BindPrototypeArgument{
        .type_name = "std::shared_ptr<const Sampler>",
        .argument_name = "sampler",
    });
  }
  for (const auto& separate_image : resources.separate_images) {
    auto& proto = prototypes.emplace_back(BindPrototype{});
    proto.return_type = "bool";
    proto.name = ConvertToCamelCase(separate_image.name);
    {
      std::stringstream stream;
      stream << "Bind separate image for resource named " << separate_image.name
             << ".";
      proto.docstring = stream.str();
    }
    proto.args.push_back(BindPrototypeArgument{
        .type_name = "Command&",
        .argument_name = "command",
    });
    proto.args.push_back(BindPrototypeArgument{
        .type_name = "std::shared_ptr<const Texture>",
        .argument_name = "texture",
    });
  }
  for (const auto& separate_sampler : resources.separate_samplers) {
    auto& proto = prototypes.emplace_back(BindPrototype{});
    proto.return_type = "bool";
    proto.name = ConvertToCamelCase(separate_sampler.name);
    {
      std::stringstream stream;
      stream << "Bind separate sampler for resource named "
             << separate_sampler.name << ".";
      proto.docstring = stream.str();
    }
    proto.args.push_back(BindPrototypeArgument{
        .type_name = "Command&",
        .argument_name = "command",
    });
    proto.args.push_back(BindPrototypeArgument{
        .type_name = "std::shared_ptr<const Sampler>",
        .argument_name = "sampler",
    });
  }
  return prototypes;
}

nlohmann::json::array_t Reflector::EmitBindPrototypes(
    const spirv_cross::ShaderResources& resources) const {
  const auto prototypes = ReflectBindPrototypes(resources);
  nlohmann::json::array_t result;
  for (const auto& res : prototypes) {
    auto& item = result.emplace_back(nlohmann::json::object_t{});
    item["return_type"] = res.return_type;
    item["name"] = res.name;
    item["docstring"] = res.docstring;
    auto& args = item["args"] = nlohmann::json::array_t{};
    for (const auto& arg : res.args) {
      auto& json_arg = args.emplace_back(nlohmann::json::object_t{});
      json_arg["type_name"] = arg.type_name;
      json_arg["argument_name"] = arg.argument_name;
    }
  }
  return result;
}

}  // namespace compiler
}  // namespace impeller
