// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/file.h"

#include "flutter/fml/logging.h"

namespace fml {

static fml::UniqueFD CreateDirectory(const fml::UniqueFD& base_directory,
                                     const std::vector<std::string>& components,
                                     FilePermission permission,
                                     size_t index) {
  FML_DCHECK(index <= components.size());

  const char* file_path = components[index].c_str();

  auto directory = OpenDirectory(base_directory, file_path, true, permission);

  if (!directory.is_valid()) {
    return {};
  }

  if (index == components.size() - 1) {
    return directory;
  }

  return CreateDirectory(directory, components, permission, index + 1);
}

fml::UniqueFD CreateDirectory(const fml::UniqueFD& base_directory,
                              const std::vector<std::string>& components,
                              FilePermission permission) {
  if (!IsDirectory(base_directory)) {
    return {};
  }

  if (components.size() == 0) {
    return {};
  }

  return CreateDirectory(base_directory, components, permission, 0);
}

}  // namespace fml
