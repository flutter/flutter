// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/file.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/unique_fd.h"

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

ScopedTemporaryDirectory::ScopedTemporaryDirectory() {
  path_ = CreateTemporaryDirectory();
  if (path_ != "") {
    dir_fd_ = OpenDirectory(path_.c_str(), false, FilePermission::kRead);
  }
}

ScopedTemporaryDirectory::~ScopedTemporaryDirectory() {
  // Windows has to close UniqueFD first before UnlinkDirectory
  dir_fd_.reset();
  if (path_ != "") {
    if (!UnlinkDirectory(path_.c_str())) {
      FML_LOG(ERROR) << "Could not remove directory: " << path_;
    }
  }
}

bool VisitFilesRecursively(const fml::UniqueFD& directory,
                           const FileVisitor& visitor) {
  FileVisitor recursive_visitor = [&recursive_visitor, &visitor](
                                      const UniqueFD& directory,
                                      const std::string& filename) {
    if (!visitor(directory, filename)) {
      return false;
    }
    if (IsDirectory(directory, filename.c_str())) {
      UniqueFD sub_dir = OpenDirectoryReadOnly(directory, filename.c_str());
      if (!sub_dir.is_valid()) {
        FML_LOG(ERROR) << "Can't open sub-directory: " << filename;
        return true;
      }
      return VisitFiles(sub_dir, recursive_visitor);
    }
    return true;
  };
  return VisitFiles(directory, recursive_visitor);
}

fml::UniqueFD OpenFileReadOnly(const fml::UniqueFD& base_directory,
                               const char* path) {
  return OpenFile(base_directory, path, false, FilePermission::kRead);
}

fml::UniqueFD OpenDirectoryReadOnly(const fml::UniqueFD& base_directory,
                                    const char* path) {
  return OpenDirectory(base_directory, path, false, FilePermission::kRead);
}

}  // namespace fml
