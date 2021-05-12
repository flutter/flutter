// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <iostream>
#include <memory>

#include "flutter/fml/command_line.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/unique_fd.h"

namespace impeller {
namespace compiler {

struct Switches {
  std::shared_ptr<fml::UniqueFD> working_directory;
  std::string source_file_name;
  std::string metal_file_name;
  std::string spirv_file_name;

  Switches();

  ~Switches();

  Switches(const fml::CommandLine& command_line);

  bool AreValid(std::ostream& explain) const;

  static void PrintHelp(std::ostream& stream);
};

}  // namespace compiler
}  // namespace impeller
