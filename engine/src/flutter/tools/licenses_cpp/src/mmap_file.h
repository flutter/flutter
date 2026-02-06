// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TOOLS_LICENSES_CPP_SRC_MMAP_FILE_H_
#define FLUTTER_TOOLS_LICENSES_CPP_SRC_MMAP_FILE_H_

#include <string_view>
#include "third_party/abseil-cpp/absl/status/statusor.h"

/// A memory mapped file.
class MMapFile {
 public:
  static absl::StatusOr<MMapFile> Make(std::string_view path);

  ~MMapFile();

  MMapFile(const MMapFile&) = delete;
  MMapFile& operator=(const MMapFile&) = delete;

  MMapFile(MMapFile&& other);

  const char* GetData() const { return data_; }

  size_t GetSize() const { return size_; }

 private:
  MMapFile(int fd, const char* data, size_t size);

  int fd_ = -1;
  const char* data_ = nullptr;
  size_t size_ = 0;
};

#endif  // FLUTTER_TOOLS_LICENSES_CPP_SRC_MMAP_FILE_H_
