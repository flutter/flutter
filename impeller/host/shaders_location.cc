// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "shaders_location.h"

#include "flutter/fml/file.h"
#include "flutter/fml/paths.h"

namespace impeller {

std::optional<std::string> ImpellerShadersLocation(std::string library_name) {
  auto executable_directory = fml::paths::GetExecutableDirectoryPath();

  if (!executable_directory.first) {
    FML_LOG(ERROR) << "Shaders directory could not be found.";
    return std::nullopt;
  }

  auto path = fml::paths::JoinPaths(
      {executable_directory.second, "shaders", library_name});

  if (!fml::IsFile(path)) {
    FML_LOG(ERROR) << "The shader library does not exist: " << path;
    return std::nullopt;
  }

  return path;
}

}  // namespace impeller
