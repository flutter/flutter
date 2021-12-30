// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <iostream>
#include <memory>

#include "flutter/fml/command_line.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/unique_fd.h"
#include "flutter/impeller/compiler/compiler.h"
#include "flutter/impeller/compiler/include_dir.h"

namespace impeller {
namespace compiler {

struct Switches {
  Compiler::TargetPlatform target_platform = Compiler::TargetPlatform::kUnknown;
  std::shared_ptr<fml::UniqueFD> working_directory;
  std::vector<IncludeDir> include_directories;
  std::string source_file_name;
  std::string metal_file_name;
  std::string spirv_file_name;
  std::string reflection_json_name;
  std::string reflection_header_name;
  std::string reflection_cc_name;
  std::string depfile_path;

  Switches();

  ~Switches();

  Switches(const fml::CommandLine& command_line);

  bool AreValid(std::ostream& explain) const;

  static void PrintHelp(std::ostream& stream);
};

}  // namespace compiler
}  // namespace impeller
