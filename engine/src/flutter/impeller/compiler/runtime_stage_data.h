// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_COMPILER_RUNTIME_STAGE_DATA_H_
#define FLUTTER_IMPELLER_COMPILER_RUNTIME_STAGE_DATA_H_

#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "impeller/compiler/types.h"
#include "impeller/core/runtime_types.h"
#include "runtime_stage_types_flatbuffers.h"
#include "spirv_parser.hpp"

namespace impeller {
namespace compiler {

struct UniformDescription {
  std::string name;
  size_t location = 0u;
  spirv_cross::SPIRType::BaseType type = spirv_cross::SPIRType::BaseType::Float;
  size_t rows = 0u;
  size_t columns = 0u;
  size_t bit_width = 0u;
  std::optional<size_t> array_elements = std::nullopt;
};

struct InputDescription {
  std::string name;
  size_t location;
  size_t set;
  size_t binding;
  spirv_cross::SPIRType::BaseType type =
      spirv_cross::SPIRType::BaseType::Unknown;
  size_t bit_width;
  size_t vec_size;
  size_t columns;
  size_t offset;
};

class RuntimeStageData {
 public:
  struct Shader {
    Shader() = default;

    std::string entrypoint;
    spv::ExecutionModel stage;
    std::vector<UniformDescription> uniforms;
    std::vector<InputDescription> inputs;
    std::shared_ptr<fml::Mapping> shader;

    Shader(const Shader&) = delete;
    Shader& operator=(const Shader&) = delete;
  };

  RuntimeStageData();

  ~RuntimeStageData();

  void AddShader(RuntimeStageBackend backend,
                 const std::shared_ptr<Shader>& data);

  std::unique_ptr<fb::RuntimeStagesT> CreateFlatbuffer() const;

  std::shared_ptr<fml::Mapping> CreateJsonMapping() const;

  std::shared_ptr<fml::Mapping> CreateMapping() const;

 private:
  std::map<RuntimeStageBackend, std::shared_ptr<Shader>> data_;

  RuntimeStageData(const RuntimeStageData&) = delete;

  RuntimeStageData& operator=(const RuntimeStageData&) = delete;
};

}  // namespace compiler
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_COMPILER_RUNTIME_STAGE_DATA_H_
