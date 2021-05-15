// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "shaders_location.h"

#include "flutter/fml/file.h"
#include "flutter/fml/paths.h"

namespace impeller {

std::string ImpellerShadersDirectory() {
  auto path_result = fml::paths::GetExecutableDirectoryPath();
  if (!path_result.first) {
    return {};
  }
  return fml::paths::JoinPaths({path_result.second, "shaders"});
}

std::optional<std::string> ImpellerShadersLocation(std::string library_name) {
  auto path = fml::paths::JoinPaths({ImpellerShadersDirectory(), library_name});

  if (!fml::IsFile(path)) {
    FML_LOG(ERROR) << "The shader library does not exist: " << path;
    return std::nullopt;
  }

  return path;
}

}  // namespace impeller
