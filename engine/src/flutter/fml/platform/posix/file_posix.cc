// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/file.h"

#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>

#include "flutter/fml/eintr_wrapper.h"

namespace fml {

fml::UniqueFD OpenFile(const char* path,
                       OpenPermission permission,
                       bool is_directory) {
  return OpenFile(fml::UniqueFD{AT_FDCWD}, path, permission, is_directory);
}

fml::UniqueFD OpenFile(const fml::UniqueFD& base_directory,
                       const char* path,
                       OpenPermission permission,
                       bool is_directory) {
  if (path == nullptr) {
    return fml::UniqueFD{};
  }

  int flags = 0;
  switch (permission) {
    case OpenPermission::kRead:
      flags = O_RDONLY;
      break;
    case OpenPermission::kWrite:
      flags = O_WRONLY;
      break;
    case OpenPermission::kReadWrite:
      flags = O_RDWR;
      break;
    case OpenPermission::kExecute:
      flags = O_RDONLY;
      break;
  }

  if (is_directory) {
    flags |= O_DIRECTORY;
  }

  return fml::UniqueFD{
      FML_HANDLE_EINTR(::openat(base_directory.get(), path, flags))};
}

fml::UniqueFD Duplicate(fml::UniqueFD::element_type descriptor) {
  return fml::UniqueFD{FML_HANDLE_EINTR(::dup(descriptor))};
}

bool IsDirectory(const fml::UniqueFD& directory) {
  if (!directory.is_valid()) {
    return false;
  }

  struct stat stat_result = {};

  if (::fstat(directory.get(), &stat_result) != 0) {
    return false;
  }

  return S_ISDIR(stat_result.st_mode);
}

}  // namespace fml
