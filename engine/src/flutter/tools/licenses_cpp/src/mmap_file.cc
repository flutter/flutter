// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tools/licenses_cpp/src/mmap_file.h"

#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>

#include "third_party/abseil-cpp/absl/strings/str_cat.h"

absl::StatusOr<MMapFile> MMapFile::Make(std::string_view path) {
  int fd = open(path.data(), O_RDONLY);
  if (fd < 0) {
    return absl::UnavailableError("can't open file");
  }

  struct stat st;
  if (fstat(fd, &st) < 0) {
    close(fd);
    return absl::UnavailableError("can't stat file");
  }

  if (st.st_size <= 0) {
    close(fd);
    return absl::InvalidArgumentError("file of zero length");
  }

  const char* data = static_cast<const char*>(
      mmap(nullptr, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0));

  if (data == MAP_FAILED) {
    close(fd);
    return absl::UnavailableError(
        absl::StrCat("can't mmap file (", path, "): ", std::strerror(errno)));
  }

  return MMapFile(fd, data, st.st_size);
}

MMapFile::~MMapFile() {
  if (data_) {
    munmap(const_cast<char*>(data_), size_);
  }
  if (fd_ >= 0) {
    close(fd_);
  }
}

MMapFile::MMapFile(MMapFile&& other) {
  fd_ = other.fd_;
  data_ = other.data_;
  size_ = other.size_;
  other.fd_ = -1;
  other.data_ = nullptr;
  other.size_ = 0;
}

MMapFile::MMapFile(int fd, const char* data, size_t size)
    : fd_(fd), data_(data), size_(size) {}
