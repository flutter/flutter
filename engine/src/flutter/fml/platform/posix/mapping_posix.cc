// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/mapping.h"

#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

#include <type_traits>

#include "flutter/fml/build_config.h"
#include "flutter/fml/eintr_wrapper.h"
#include "flutter/fml/unique_fd.h"

namespace fml {

Mapping::Mapping() = default;

Mapping::~Mapping() = default;

FileMapping::FileMapping(const std::string& path, bool executable)
    : FileMapping(
          fml::UniqueFD{FML_HANDLE_EINTR(::open(path.c_str(), O_RDONLY))},
          executable) {}

FileMapping::FileMapping(const fml::UniqueFD& handle, bool executable)
    : size_(0), mapping_(nullptr) {
  if (!handle.is_valid()) {
    return;
  }

  struct stat stat_buffer = {};

  if (::fstat(handle.get(), &stat_buffer) != 0) {
    return;
  }

  if (stat_buffer.st_size <= 0) {
    return;
  }

  int flags = PROT_READ;
  if (executable) {
    flags |= PROT_EXEC;
  }

  auto mapping =
      ::mmap(nullptr, stat_buffer.st_size, flags, MAP_PRIVATE, handle.get(), 0);

  if (mapping == MAP_FAILED) {
    return;
  }

  mapping_ = static_cast<uint8_t*>(mapping);
  size_ = stat_buffer.st_size;
}

FileMapping::~FileMapping() {
  if (mapping_ != nullptr) {
    ::munmap(mapping_, size_);
  }
}

size_t FileMapping::GetSize() const {
  return size_;
}

const uint8_t* FileMapping::GetMapping() const {
  return mapping_;
}

}  // namespace fml
