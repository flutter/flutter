// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <string>

#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "impeller/renderer/shader_function.h"
#include "impeller/renderer/shader_types.h"

namespace impeller {

enum RuntimeUniformType {
  kBoolean,
  kSignedByte,
  kUnsignedByte,
  kSignedShort,
  kUnsignedShort,
  kSignedInt,
  kUnsignedInt,
  kSignedInt64,
  kUnsignedInt64,
  kHalfFloat,
  kFloat,
  kDouble,
  kSampledImage,
};

struct RuntimeUniformDimensions {
  size_t rows = 0;
  size_t cols = 0;
};

struct RuntimeUniformDescription {
  std::string name;
  size_t location = 0u;
  RuntimeUniformType type = kFloat;
  RuntimeUniformDimensions dimensions;
};

class RuntimeStage {
 public:
  RuntimeStage(std::shared_ptr<fml::Mapping> payload);

  ~RuntimeStage();

  bool IsValid() const;

  ShaderStage GetShaderStage() const;

  const std::vector<RuntimeUniformDescription>& GetUniforms() const;

  const std::string& GetEntrypoint() const;

  const RuntimeUniformDescription* GetUniform(const std::string& name) const;

  const std::shared_ptr<fml::Mapping>& GetCodeMapping() const;

 private:
  ShaderStage stage_ = ShaderStage::kUnknown;
  std::shared_ptr<fml::Mapping> payload_;
  std::string entrypoint_;
  std::shared_ptr<fml::Mapping> code_mapping_;
  std::vector<RuntimeUniformDescription> uniforms_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(RuntimeStage);
};

}  // namespace impeller
