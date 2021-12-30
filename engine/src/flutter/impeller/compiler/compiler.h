// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <initializer_list>
#include <sstream>
#include <string>

#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "flutter/impeller/compiler/include_dir.h"
#include "flutter/impeller/compiler/reflector.h"
#include "shaderc/shaderc.hpp"
#include "third_party/spirv_cross/spirv_msl.hpp"
#include "third_party/spirv_cross/spirv_parser.hpp"

namespace impeller {
namespace compiler {

class Compiler {
 public:
  enum class SourceType {
    kUnknown,
    kVertexShader,
    kFragmentShader,
  };

  enum class TargetPlatform {
    kUnknown,
    kMacOS,
    kIPhoneOS,
  };

  static SourceType SourceTypeFromFileName(const std::string& file_name);

  static std::string EntryPointFromSourceName(const std::string& file_name,
                                              SourceType type);

  struct SourceOptions {
    SourceType type = SourceType::kUnknown;
    TargetPlatform target_platform = TargetPlatform::kUnknown;
    std::shared_ptr<fml::UniqueFD> working_directory;
    std::vector<IncludeDir> include_dirs;
    std::string file_name = "main.glsl";
    std::string entry_point_name = "main";

    SourceOptions() = default;

    SourceOptions(const std::string& file_name)
        : type(SourceTypeFromFileName(file_name)), file_name(file_name) {}
  };

  Compiler(const fml::Mapping& source_mapping,
           SourceOptions options,
           Reflector::Options reflector_options);

  ~Compiler();

  bool IsValid() const;

  std::unique_ptr<fml::Mapping> GetSPIRVAssembly() const;

  std::unique_ptr<fml::Mapping> GetMSLShaderSource() const;

  std::string GetErrorMessages() const;

  const std::vector<std::string>& GetIncludedFileNames() const;

  std::unique_ptr<fml::Mapping> CreateDepfileContents(
      std::initializer_list<std::string> targets) const;

  const Reflector* GetReflector() const;

 private:
  SourceOptions options_;
  std::shared_ptr<shaderc::SpvCompilationResult> spv_result_;
  std::shared_ptr<std::string> msl_string_;
  std::stringstream error_stream_;
  std::unique_ptr<Reflector> reflector_;
  std::vector<std::string> included_file_names_;
  bool is_valid_ = false;

  std::string GetSourcePrefix() const;

  std::string GetDependencyNames(std::string separator) const;

  FML_DISALLOW_COPY_AND_ASSIGN(Compiler);
};

}  // namespace compiler
}  // namespace impeller
