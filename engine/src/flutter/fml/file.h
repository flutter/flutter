// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_FILE_H_
#define FLUTTER_FML_FILE_H_

#include "flutter/fml/macros.h"
#include "flutter/fml/unique_fd.h"

namespace fml {

enum class OpenPermission {
  kRead = 1,
  kWrite = 1 << 1,
  kReadWrite = kRead | kWrite,
  kExecute,
};

fml::UniqueFD OpenFile(const char* path,
                       OpenPermission permission,
                       bool is_directory = false);

fml::UniqueFD OpenFile(const fml::UniqueFD& base_directory,
                       const char* path,
                       OpenPermission permission,
                       bool is_directory = false);

fml::UniqueFD Duplicate(fml::UniqueFD::element_type descriptor);

bool IsDirectory(const fml::UniqueFD& directory);

}  // namespace fml

#endif  // FLUTTER_FML_FILE_H_
