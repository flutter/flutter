// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compiler/runtime_stage_data.h"

#include <array>
#include <optional>

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

static std::optional<fb::TargetPlatform> ToTargetPlatform(
    TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform::kUnknown:
    case TargetPlatform::kMetalDesktop:
    case TargetPlatform::kMetalIOS:
    case TargetPlatform::kFlutterSPIRV:
    case TargetPlatform::kOpenGLES:
    case TargetPlatform::kOpenGLDesktop:
      return std::nullopt;
    case TargetPlatform::kRuntimeStageMetal:
      return fb::TargetPlatform::kMetal;
    case TargetPlatform::kRuntimeStageGLES:
      return fb::TargetPlatform::kOpenGLES;
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
