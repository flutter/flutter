// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <string>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/fml/unique_fd.h"
#include "impeller/compiler/include_dir.h"
#include "impeller/compiler/types.h"

namespace impeller {
namespace compiler {

struct SourceOptions {
  SourceType type = SourceType::kUnknown;
  TargetPlatform target_platform = TargetPlatform::kUnknown;
  std::shared_ptr<fml::UniqueFD> working_directory;
  std::vector<IncludeDir> include_dirs;
  std::string file_name = "main.glsl";
  std::string entry_point_name = "main";
  std::vector<std::string> defines;

  SourceOptions();

  ~SourceOptions();

  explicit SourceOptions(const std::string& file_name,
                         SourceType source_type = SourceType::kUnknown);
};

}  // namespace compiler
}  // namespace impeller
