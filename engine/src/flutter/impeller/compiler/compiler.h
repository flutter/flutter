// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <string>

#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "shaderc/shaderc.hpp"

namespace impeller {
namespace compiler {

class Compiler {
 public:
  enum class SourceType {
    kVertexShader,
    kFragmentShader,
  };

  static SourceType SourceTypeFromFileName(const std::string& file_name);

  struct SourceOptions {
    SourceType type = SourceType::kVertexShader;
    std::string file_name = "main.glsl";
    std::string entry_point_name = "main";
  };

  Compiler(const fml::Mapping& source_mapping, SourceOptions options);

  ~Compiler();

  bool IsValid() const;

 private:
  shaderc::SpvCompilationResult result_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(Compiler);
};

}  // namespace compiler
}  // namespace impeller
