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

static RuntimeShaderStage ToShaderStage(fb::Stage stage) {
  switch (stage) {
    case fb::Stage::kVertex:
      return RuntimeShaderStage::kVertex;
    case fb::Stage::kFragment:
      return RuntimeShaderStage::kFragment;
    case fb::Stage::kCompute:
      return RuntimeShaderStage::kCompute;
    case fb::Stage::kTessellationControl:
      return RuntimeShaderStage::kTessellationControl;
    case fb::Stage::kTessellationEvaluation:
      return RuntimeShaderStage::kTessellationEvaluation;
  }
  FML_UNREACHABLE();
}

RuntimeStage::RuntimeStage(std::shared_ptr<fml::Mapping> payload)
    : payload_(std::move(payload)) {
  if (payload_ == nullptr || !payload_->GetMapping()) {
    return;
  }
  if (!fb::RuntimeStageBufferHasIdentifier(payload_->GetMapping())) {
    return;
  }
  auto runtime_stage = fb::GetRuntimeStage(payload_->GetMapping());
  if (!runtime_stage) {
    return;
  }

  stage_ = ToShaderStage(runtime_stage->stage());
  entrypoint_ = runtime_stage->entrypoint()->str();

  auto* uniforms = runtime_stage->uniforms();
  if (uniforms) {
    for (auto i = uniforms->begin(), end = uniforms->end(); i != end; i++) {
      RuntimeUniformDescription desc;
      desc.name = i->name()->str();
      desc.location = i->location();
      desc.type = ToType(i->type());
      desc.dimensions = RuntimeUniformDimensions{
          static_cast<size_t>(i->rows()), static_cast<size_t>(i->columns())};
      desc.bit_width = i->bit_width();
      desc.array_elements = i->array_elements();
      uniforms_.emplace_back(std::move(desc));
    }
  }

  code_mapping_ = std::make_shared<fml::NonOwnedMapping>(
      runtime_stage->shader()->data(),     //
      runtime_stage->shader()->size(),     //
      [payload = payload_](auto, auto) {}  //
  );

  sksl_mapping_ = std::make_shared<fml::NonOwnedMapping>(
      runtime_stage->sksl()->data(),       //
      runtime_stage->sksl()->size(),       //
      [payload = payload_](auto, auto) {}  //
  );

  is_valid_ = true;
}

RuntimeStage::~RuntimeStage() = default;
RuntimeStage::RuntimeStage(RuntimeStage&&) = default;
RuntimeStage& RuntimeStage::operator=(RuntimeStage&&) = default;

bool RuntimeStage::IsValid() const {
  return is_valid_;
}

const std::shared_ptr<fml::Mapping>& RuntimeStage::GetCodeMapping() const {
  return code_mapping_;
}

const std::shared_ptr<fml::Mapping>& RuntimeStage::GetSkSLMapping() const {
  return sksl_mapping_;
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

RuntimeShaderStage RuntimeStage::GetShaderStage() const {
  return stage_;
}

bool RuntimeStage::IsDirty() const {
  return is_dirty_;
}

void RuntimeStage::SetClean() {
  is_dirty_ = false;
}

}  // namespace impeller
