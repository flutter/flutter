// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_SCENE_IMPORTER_SWITCHES_H_
#define FLUTTER_IMPELLER_SCENE_IMPORTER_SWITCHES_H_

#include <iostream>
#include <memory>

#include "flutter/fml/command_line.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/unique_fd.h"
#include "impeller/scene/importer/types.h"

namespace impeller {
namespace scene {
namespace importer {

struct Switches {
  std::shared_ptr<fml::UniqueFD> working_directory;
  std::string source_file_name;
  SourceType input_type;
  std::string output_file_name;

  Switches();

  ~Switches();

  explicit Switches(const fml::CommandLine& command_line);

  bool AreValid(std::ostream& explain) const;

  static void PrintHelp(std::ostream& stream);
};

}  // namespace importer
}  // namespace scene
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_SCENE_IMPORTER_SWITCHES_H_
