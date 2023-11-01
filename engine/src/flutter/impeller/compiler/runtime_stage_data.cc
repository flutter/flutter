// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compiler/runtime_stage_data.h"

#include <array>
#include <cstdint>
#include <optional>

#include "inja/inja.hpp"

#include "impeller/base/validation.h"
#include "impeller/runtime_stage/runtime_stage_flatbuffers.h"

namespace impeller {
namespace compiler {

RuntimeStageData::RuntimeStageData(std::string entrypoint,
                                   spv::ExecutionModel stage,
                                   TargetPlatform target_platform)
    : entrypoint_(std::move(entrypoint)),
      stage_(stage),
      target_platform_(target_platform) {}

RuntimeStageData::~RuntimeStageData() = default;

void RuntimeStageData::AddUniformDescription(UniformDescription uniform) {
  uniforms_.emplace_back(std::move(uniform));
}

void RuntimeStageData::SetShaderData(std::shared_ptr<fml::Mapping> shader) {
  shader_ = std::move(shader);
}

void RuntimeStageData::SetSkSLData(std::shared_ptr<fml::Mapping> sksl) {
  sksl_ = std::move(sksl);
}

static std::optional<fb::Stage> ToStage(spv::ExecutionModel stage) {
  switch (stage) {
    case spv::ExecutionModel::ExecutionModelVertex:
      return fb::Stage::kVertex;
    case spv::ExecutionModel::ExecutionModelFragment:
      return fb::Stage::kFragment;
    case spv::ExecutionModel::ExecutionModelGLCompute:
      return fb::Stage::kCompute;
    case spv::ExecutionModel::ExecutionModelTessellationControl:
      return fb::Stage::kTessellationControl;
    case spv::ExecutionModel::ExecutionModelTessellationEvaluation:
      return fb::Stage::kTessellationEvaluation;
    default:
      return std::nullopt;
  }
  FML_UNREACHABLE();
}

static std::optional<uint32_t> ToJsonStage(spv::ExecutionModel stage) {
  switch (stage) {
    case spv::ExecutionModel::ExecutionModelVertex:
      return 0;  // fb::Stage::kVertex;
    case spv::ExecutionModel::ExecutionModelFragment:
      return 1;  // fb::Stage::kFragment;
    case spv::ExecutionModel::ExecutionModelGLCompute:
      return 2;  // fb::Stage::kCompute;
    case spv::ExecutionModel::ExecutionModelTessellationControl:
      return 3;  // fb::Stage::kTessellationControl;
    case spv::ExecutionModel::ExecutionModelTessellationEvaluation:
      return 4;  // fb::Stage::kTessellationEvaluation;
    default:
      return std::nullopt;
  }
  FML_UNREACHABLE();
}

static std::optional<fb::TargetPlatform> ToTargetPlatform(
    TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform::kUnknown:
    case TargetPlatform::kMetalDesktop:
    case TargetPlatform::kMetalIOS:
    case TargetPlatform::kOpenGLES:
    case TargetPlatform::kOpenGLDesktop:
    case TargetPlatform::kVulkan:
      return std::nullopt;
    case TargetPlatform::kSkSL:
      return fb::TargetPlatform::kSkSL;
    case TargetPlatform::kRuntimeStageMetal:
      return fb::TargetPlatform::kMetal;
    case TargetPlatform::kRuntimeStageGLES:
      return fb::TargetPlatform::kOpenGLES;
    case TargetPlatform::kRuntimeStageVulkan:
      return fb::TargetPlatform::kVulkan;
  }
  FML_UNREACHABLE();
}

static std::optional<uint32_t> ToJsonTargetPlatform(TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform::kUnknown:
    case TargetPlatform::kMetalDesktop:
    case TargetPlatform::kMetalIOS:
    case TargetPlatform::kOpenGLES:
    case TargetPlatform::kOpenGLDesktop:
    case TargetPlatform::kVulkan:
      return std::nullopt;
    case TargetPlatform::kSkSL:
      return static_cast<uint32_t>(fb::TargetPlatform::kSkSL);
    case TargetPlatform::kRuntimeStageMetal:
      return static_cast<uint32_t>(fb::TargetPlatform::kMetal);
    case TargetPlatform::kRuntimeStageGLES:
      return static_cast<uint32_t>(fb::TargetPlatform::kOpenGLES);
    case TargetPlatform::kRuntimeStageVulkan:
      return static_cast<uint32_t>(fb::TargetPlatform::kVulkan);
  }
  FML_UNREACHABLE();
}

static std::optional<fb::UniformDataType> ToType(
    spirv_cross::SPIRType::BaseType type) {
  switch (type) {
    case spirv_cross::SPIRType::Boolean:
      return fb::UniformDataType::kBoolean;
    case spirv_cross::SPIRType::SByte:
      return fb::UniformDataType::kSignedByte;
    case spirv_cross::SPIRType::UByte:
      return fb::UniformDataType::kUnsignedByte;
    case spirv_cross::SPIRType::Short:
      return fb::UniformDataType::kSignedShort;
    case spirv_cross::SPIRType::UShort:
      return fb::UniformDataType::kUnsignedShort;
    case spirv_cross::SPIRType::Int:
      return fb::UniformDataType::kSignedInt;
    case spirv_cross::SPIRType::UInt:
      return fb::UniformDataType::kUnsignedInt;
    case spirv_cross::SPIRType::Int64:
      return fb::UniformDataType::kSignedInt64;
    case spirv_cross::SPIRType::UInt64:
      return fb::UniformDataType::kUnsignedInt64;
    case spirv_cross::SPIRType::Half:
      return fb::UniformDataType::kHalfFloat;
    case spirv_cross::SPIRType::Float:
      return fb::UniformDataType::kFloat;
    case spirv_cross::SPIRType::Double:
      return fb::UniformDataType::kDouble;
    case spirv_cross::SPIRType::SampledImage:
      return fb::UniformDataType::kSampledImage;
    case spirv_cross::SPIRType::AccelerationStructure:
    case spirv_cross::SPIRType::AtomicCounter:
    case spirv_cross::SPIRType::Char:
    case spirv_cross::SPIRType::ControlPointArray:
    case spirv_cross::SPIRType::Image:
    case spirv_cross::SPIRType::Interpolant:
    case spirv_cross::SPIRType::RayQuery:
    case spirv_cross::SPIRType::Sampler:
    case spirv_cross::SPIRType::Struct:
    case spirv_cross::SPIRType::Unknown:
    case spirv_cross::SPIRType::Void:
      return std::nullopt;
  }
  FML_UNREACHABLE();
}

static std::optional<uint32_t> ToJsonType(
    spirv_cross::SPIRType::BaseType type) {
  switch (type) {
    case spirv_cross::SPIRType::Boolean:
      return 0;  // fb::UniformDataType::kBoolean;
    case spirv_cross::SPIRType::SByte:
      return 1;  // fb::UniformDataType::kSignedByte;
    case spirv_cross::SPIRType::UByte:
      return 2;  // fb::UniformDataType::kUnsignedByte;
    case spirv_cross::SPIRType::Short:
      return 3;  // fb::UniformDataType::kSignedShort;
    case spirv_cross::SPIRType::UShort:
      return 4;  // fb::UniformDataType::kUnsignedShort;
    case spirv_cross::SPIRType::Int:
      return 5;  // fb::UniformDataType::kSignedInt;
    case spirv_cross::SPIRType::UInt:
      return 6;  // fb::UniformDataType::kUnsignedInt;
    case spirv_cross::SPIRType::Int64:
      return 7;  // fb::UniformDataType::kSignedInt64;
    case spirv_cross::SPIRType::UInt64:
      return 8;  // fb::UniformDataType::kUnsignedInt64;
    case spirv_cross::SPIRType::Half:
      return 9;  // b::UniformDataType::kHalfFloat;
    case spirv_cross::SPIRType::Float:
      return 10;  // fb::UniformDataType::kFloat;
    case spirv_cross::SPIRType::Double:
      return 11;  // fb::UniformDataType::kDouble;
    case spirv_cross::SPIRType::SampledImage:
      return 12;  // fb::UniformDataType::kSampledImage;
    case spirv_cross::SPIRType::AccelerationStructure:
    case spirv_cross::SPIRType::AtomicCounter:
    case spirv_cross::SPIRType::Char:
    case spirv_cross::SPIRType::ControlPointArray:
    case spirv_cross::SPIRType::Image:
    case spirv_cross::SPIRType::Interpolant:
    case spirv_cross::SPIRType::RayQuery:
    case spirv_cross::SPIRType::Sampler:
    case spirv_cross::SPIRType::Struct:
    case spirv_cross::SPIRType::Unknown:
    case spirv_cross::SPIRType::Void:
      return std::nullopt;
  }
  FML_UNREACHABLE();
}

static const char* kStageKey = "stage";
static const char* kTargetPlatformKey = "target_platform";
static const char* kEntrypointKey = "entrypoint";
static const char* kUniformsKey = "uniforms";
static const char* kShaderKey = "sksl";
static const char* kUniformNameKey = "name";
static const char* kUniformLocationKey = "location";
static const char* kUniformTypeKey = "type";
static const char* kUniformRowsKey = "rows";
static const char* kUniformColumnsKey = "columns";
static const char* kUniformBitWidthKey = "bit_width";
static const char* kUniformArrayElementsKey = "array_elements";

std::shared_ptr<fml::Mapping> RuntimeStageData::CreateJsonMapping() const {
  // Runtime Stage Data JSON format
  //   {
  //      "stage": 0,
  //      "target_platform": "",
  //      "entrypoint": "",
  //      "shader": "",
  //      "sksl": "",
  //      "uniforms": [
  //        {
  //           "name": "..",
  //           "location": 0,
  //           "type": 0,
  //           "rows": 0,
  //           "columns": 0,
  //           "bit_width": 0,
  //           "array_elements": 0,
  //        }
  //      ]
  //   },
  nlohmann::json root;

  const auto stage = ToJsonStage(stage_);
  if (!stage.has_value()) {
    VALIDATION_LOG << "Invalid runtime stage.";
    return nullptr;
  }
  root[kStageKey] = stage.value();

  const auto target_platform = ToJsonTargetPlatform(target_platform_);
  if (!target_platform.has_value()) {
    VALIDATION_LOG << "Invalid target platform for runtime stage.";
    return nullptr;
  }
  root[kTargetPlatformKey] = target_platform.value();

  if (shader_->GetSize() > 0u) {
    std::string shader(reinterpret_cast<const char*>(shader_->GetMapping()),
                       shader_->GetSize());
    root[kShaderKey] = shader.c_str();
  }

  auto& uniforms = root[kUniformsKey] = nlohmann::json::array_t{};
  for (const auto& uniform : uniforms_) {
    nlohmann::json uniform_object;
    uniform_object[kUniformNameKey] = uniform.name.c_str();
    uniform_object[kUniformLocationKey] = uniform.location;
    uniform_object[kUniformRowsKey] = uniform.rows;
    uniform_object[kUniformColumnsKey] = uniform.columns;

    auto uniform_type = ToJsonType(uniform.type);
    if (!uniform_type.has_value()) {
      VALIDATION_LOG << "Invalid uniform type for runtime stage.";
      return nullptr;
    }

    uniform_object[kUniformTypeKey] = uniform_type.value();
    uniform_object[kUniformBitWidthKey] = uniform.bit_width;

    if (uniform.array_elements.has_value()) {
      uniform_object[kUniformArrayElementsKey] = uniform.array_elements.value();
    } else {
      uniform_object[kUniformArrayElementsKey] = 0;
    }
    uniforms.push_back(uniform_object);
  }

  auto json_string = std::make_shared<std::string>(root.dump(2u));

  return std::make_shared<fml::NonOwnedMapping>(
      reinterpret_cast<const uint8_t*>(json_string->data()),
      json_string->size(), [json_string](auto, auto) {});
}

std::shared_ptr<fml::Mapping> RuntimeStageData::CreateMapping() const {
  // The high level object API is used here for writing to the buffer. This is
  // just a convenience.
  fb::RuntimeStageT runtime_stage;
  runtime_stage.entrypoint = entrypoint_;
  const auto stage = ToStage(stage_);
  if (!stage.has_value()) {
    VALIDATION_LOG << "Invalid runtime stage.";
    return nullptr;
  }
  runtime_stage.stage = stage.value();
  const auto target_platform = ToTargetPlatform(target_platform_);
  if (!target_platform.has_value()) {
    VALIDATION_LOG << "Invalid target platform for runtime stage.";
    return nullptr;
  }
  runtime_stage.target_platform = target_platform.value();
  if (!shader_) {
    VALIDATION_LOG << "No shader specified for runtime stage.";
    return nullptr;
  }
  if (shader_->GetSize() > 0u) {
    runtime_stage.shader = {shader_->GetMapping(),
                            shader_->GetMapping() + shader_->GetSize()};
  }
  // It is not an error for the SkSL to be ommitted.
  if (sksl_->GetSize() > 0u) {
    runtime_stage.sksl = {sksl_->GetMapping(),
                          sksl_->GetMapping() + sksl_->GetSize()};
  }
  for (const auto& uniform : uniforms_) {
    auto desc = std::make_unique<fb::UniformDescriptionT>();

    desc->name = uniform.name;
    if (desc->name.empty()) {
      VALIDATION_LOG << "Uniform name cannot be empty.";
      return nullptr;
    }
    desc->location = uniform.location;
    desc->rows = uniform.rows;
    desc->columns = uniform.columns;
    auto uniform_type = ToType(uniform.type);
    if (!uniform_type.has_value()) {
      VALIDATION_LOG << "Invalid uniform type for runtime stage.";
      return nullptr;
    }
    desc->type = uniform_type.value();
    desc->bit_width = uniform.bit_width;
    if (uniform.array_elements.has_value()) {
      desc->array_elements = uniform.array_elements.value();
    }

    runtime_stage.uniforms.emplace_back(std::move(desc));
  }
  auto builder = std::make_shared<flatbuffers::FlatBufferBuilder>();
  builder->Finish(fb::RuntimeStage::Pack(*builder.get(), &runtime_stage),
                  fb::RuntimeStageIdentifier());
  return std::make_shared<fml::NonOwnedMapping>(builder->GetBufferPointer(),
                                                builder->GetSize(),
                                                [builder](auto, auto) {});
}

}  // namespace compiler
}  // namespace impeller
