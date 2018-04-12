// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/mapping.h"

#include <fcntl.h>

#include <type_traits>

#include "lib/fxl/build_config.h"

#include <io.h>
#include <windows.h>

using PlatformResourceMapping = fml::FileMapping;

namespace fml {

Mapping::Mapping() = default;

Mapping::~Mapping() = default;

bool PlatformHasResourcesBundle() {
  return !std::is_same<PlatformResourceMapping, FileMapping>::value;
}

std::unique_ptr<Mapping> GetResourceMapping(const std::string& resource_name) {
  return std::make_unique<PlatformResourceMapping>(resource_name);
}

FileMapping::FileMapping(const std::string& path)
    : size_(0), mapping_(nullptr) {
  HANDLE file_handle_ =
      CreateFileA(reinterpret_cast<LPCSTR>(path.c_str()), GENERIC_READ,
                  FILE_SHARE_READ, nullptr, OPEN_EXISTING,
                  FILE_ATTRIBUTE_NORMAL | FILE_FLAG_RANDOM_ACCESS, nullptr);

  if (file_handle_ == INVALID_HANDLE_VALUE) {
    return;
  }

  size_ = GetFileSize(file_handle_, nullptr);
  if (size_ == INVALID_FILE_SIZE) {
    size_ = 0;
    return;
  }

  mapping_handle_ = CreateFileMapping(file_handle_, nullptr, PAGE_READONLY, 0,
                                      size_, nullptr);

  CloseHandle(file_handle_);

  if (mapping_handle_ == INVALID_HANDLE_VALUE) {
    return;
  }

  auto mapping = MapViewOfFile(mapping_handle_, FILE_MAP_READ, 0, 0, size_);

  if (mapping == INVALID_HANDLE_VALUE) {
    CloseHandle(mapping_handle_);
    mapping_handle_ = INVALID_HANDLE_VALUE;
    return;
  }

  mapping_ = static_cast<uint8_t*>(mapping);
}

FileMapping::~FileMapping() {
  if (mapping_ != nullptr) {
    UnmapViewOfFile(mapping_);
    CloseHandle(mapping_handle_);
  }
}

size_t FileMapping::GetSize() const {
  return size_;
}

const uint8_t* FileMapping::GetMapping() const {
  return mapping_;
}

}  // namespace fml
