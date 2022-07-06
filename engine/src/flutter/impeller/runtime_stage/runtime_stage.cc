// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/runtime_stage/runtime_stage.h"

#include <array>

#include "impeller/base/validation.h"
#include "impeller/runtime_stage/runtime_stage_flatbuffers.h"

namespace impeller {

static RuntimeUniformType ToType(fb::UniformDataType type) {
  switch (type) {
    case fb::UniformDataType::kBoolean:
      return RuntimeUniformType::kBoolean;
    case fb::UniformDataType::kSignedByte:
      return RuntimeUniformType::kSignedByte;
    case fb::UniformDataType::kUnsignedByte:
      return RuntimeUniformType::kUnsignedByte;
    case fb::UniformDataType::kSignedShort:
      return RuntimeUniformType::kSignedShort;
    case fb::UniformDataType::kUnsignedShort:
      return RuntimeUniformType::kUnsignedShort;
    case fb::UniformDataType::kSignedInt:
      return RuntimeUniformType::kSignedInt;
    case fb::UniformDataType::kUnsignedInt:
      return RuntimeUniformType::kUnsignedInt;
    case fb::UniformDataType::kSignedInt64:
      return RuntimeUniformType::kSignedInt64;
    case fb::UniformDataType::kUnsignedInt64:
      return RuntimeUniformType::kUnsignedInt64;
    case fb::UniformDataType::kHalfFloat:
      return RuntimeUniformType::kHalfFloat;
    case fb::UniformDataType::kFloat:
      return RuntimeUniformType::kFloat;
    case fb::UniformDataType::kDouble:
      return RuntimeUniformType::kDouble;
    case fb::UniformDataType::kSampledImage:
      return RuntimeUniformType::kSampledImage;
  }
  FML_UNREACHABLE();
}

static ShaderStage ToShaderStage(fb::Stage stage) {
  switch (stage) {
    case fb::Stage::kVertex:
      return ShaderStage::kVertex;
    case fb::Stage::kFragment:
      return ShaderStage::kFragment;
    case fb::Stage::kCompute:
      return ShaderStage::kCompute;
    case fb::Stage::kTessellationControl:
      return ShaderStage::kTessellationControl;
    case fb::Stage::kTessellationEvaluation:
      return ShaderStage::kTessellationEvaluation;
  }
  FML_UNREACHABLE();
}

RuntimeStage::RuntimeStage(std::shared_ptr<fml::Mapping> payload)
    : payload_(std::move(payload)) {
  if (payload_ == nullptr || !payload_->GetMapping()) {
    return;
  }
  if (!fb::RuntimeStageBufferHasIdentifier(payload_->GetMapping())) {
    VALIDATION_LOG
        << "Impeller Runtime stage has invalid magic. Perhaps the stage "
           "information is for the incorrect backend or the data is corrupted?";
    return;
  }
  auto runtime_stage = fb::GetRuntimeStage(payload_->GetMapping());
  if (!runtime_stage) {
    return;
  }

  stage_ = ToShaderStage(runtime_stage->stage());
  entrypoint_ = runtime_stage->entrypoint()->str();

  for (auto i = runtime_stage->uniforms()->begin(),
            end = runtime_stage->uniforms()->end();
       i != end; i++) {
    RuntimeUniformDescription desc;
    desc.name = i->name()->str();
    desc.location = i->location();
    desc.type = ToType(i->type());
    desc.dimensions = RuntimeUniformDimensions{i->rows(), i->columns()};
    uniforms_.emplace_back(std::move(desc));
  }

  code_mapping_ = std::make_shared<fml::NonOwnedMapping>(
      runtime_stage->shader()->data(),     //
      runtime_stage->shader()->size(),     //
      [payload = payload_](auto, auto) {}  //
  );

  is_valid_ = true;
}

RuntimeStage::~RuntimeStage() = default;

bool RuntimeStage::IsValid() const {
  return is_valid_;
}

const std::shared_ptr<fml::Mapping>& RuntimeStage::GetCodeMapping() const {
  return code_mapping_;
}

const std::vector<RuntimeUniformDescription>& RuntimeStage::GetUniforms()
    const {
  return uniforms_;
}

const RuntimeUniformDescription* RuntimeStage::GetUniform(
    const std::string& name) const {
  for (const auto& uniform : uniforms_) {
    if (uniform.name == name) {
      return &uniform;
    }
  }
  return nullptr;
}

const std::string& RuntimeStage::GetEntrypoint() const {
  return entrypoint_;
}

ShaderStage RuntimeStage::GetShaderStage() const {
  return stage_;
}

}  // namespace impeller
