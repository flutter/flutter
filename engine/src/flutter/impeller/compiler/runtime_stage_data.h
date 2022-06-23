// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "impeller/compiler/types.h"
#include "spirv_parser.hpp"

namespace impeller {
namespace compiler {

struct UniformDescription {
  std::string name;
  size_t location = 0u;
  spirv_cross::SPIRType::BaseType type = spirv_cross::SPIRType::BaseType::Float;
  size_t rows = 0u;
  size_t columns = 0u;
};

class RuntimeStageData {
 public:
  RuntimeStageData(std::string entrypoint,
                   spv::ExecutionModel stage,
                   TargetPlatform target_platform);

  ~RuntimeStageData();

  void AddUniformDescription(UniformDescription uniform);

  void SetShaderData(std::shared_ptr<fml::Mapping> shader);

  std::shared_ptr<fml::Mapping> CreateMapping() const;

 private:
  const std::string entrypoint_;
  const spv::ExecutionModel stage_;
  const TargetPlatform target_platform_;
  std::vector<UniformDescription> uniforms_;
  std::shared_ptr<fml::Mapping> shader_;

  FML_DISALLOW_COPY_AND_ASSIGN(RuntimeStageData);
};

}  // namespace compiler
}  // namespace impeller
