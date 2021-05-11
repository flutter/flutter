// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <sstream>
#include <string>

#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "shaderc/shaderc.hpp"
#include "third_party/spirv_cross/spirv_msl.hpp"

namespace impeller {
namespace compiler {

class Compiler {
 public:
  enum class SourceType {
    kUnknown,
    kVertexShader,
    kFragmentShader,
  };

  static SourceType SourceTypeFromFileName(const std::string& file_name);

  struct SourceOptions {
    SourceType type = SourceType::kUnknown;
    std::shared_ptr<fml::UniqueFD> working_directory;
    std::string file_name = "main.glsl";
    std::string entry_point_name = "main";

    SourceOptions() = default;

    SourceOptions(const std::string& file_name)
        : type(SourceTypeFromFileName(file_name)), file_name(file_name) {}
  };

  Compiler(const fml::Mapping& source_mapping, SourceOptions options);

  ~Compiler();

  bool IsValid() const;

  std::unique_ptr<fml::Mapping> GetSPIRVAssembly() const;

  std::unique_ptr<fml::Mapping> GetMSLShaderSource() const;

  std::string GetErrorMessages() const;

 private:
  SourceOptions options_;
  std::shared_ptr<shaderc::SpvCompilationResult> spv_result_;
  std::shared_ptr<std::string> msl_string_;
  std::stringstream error_stream_;
  bool is_valid_ = false;

  std::string GetSourcePrefix() const;

  FML_DISALLOW_COPY_AND_ASSIGN(Compiler);
};

}  // namespace compiler
}  // namespace impeller
