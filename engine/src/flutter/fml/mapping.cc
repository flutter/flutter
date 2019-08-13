// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/mapping.h"

#include <sstream>

namespace fml {

// FileMapping

uint8_t* FileMapping::GetMutableMapping() {
  return mutable_mapping_;
}

std::unique_ptr<FileMapping> FileMapping::CreateReadOnly(
    const std::string& path) {
  return CreateReadOnly(OpenFile(path.c_str(), false, FilePermission::kRead),
                        "");
}

std::unique_ptr<FileMapping> FileMapping::CreateReadOnly(
    const fml::UniqueFD& base_fd,
    const std::string& sub_path) {
  if (sub_path.size() != 0) {
    return CreateReadOnly(
        OpenFile(base_fd, sub_path.c_str(), false, FilePermission::kRead), "");
  }

  auto mapping = std::make_unique<FileMapping>(
      base_fd, std::initializer_list<Protection>{Protection::kRead});

  if (!mapping->IsValid()) {
    return nullptr;
  }

  return mapping;
}

std::unique_ptr<FileMapping> FileMapping::CreateReadExecute(
    const std::string& path) {
  return CreateReadExecute(
      OpenFile(path.c_str(), false, FilePermission::kRead));
}

std::unique_ptr<FileMapping> FileMapping::CreateReadExecute(
    const fml::UniqueFD& base_fd,
    const std::string& sub_path) {
  if (sub_path.size() != 0) {
    return CreateReadExecute(
        OpenFile(base_fd, sub_path.c_str(), false, FilePermission::kRead), "");
  }

  auto mapping = std::make_unique<FileMapping>(
      base_fd, std::initializer_list<Protection>{Protection::kRead,
                                                 Protection::kExecute});

  if (!mapping->IsValid()) {
    return nullptr;
  }

  return mapping;
}

// Data Mapping

DataMapping::DataMapping(std::vector<uint8_t> data) : data_(std::move(data)) {}

DataMapping::~DataMapping() = default;

size_t DataMapping::GetSize() const {
  return data_.size();
}

const uint8_t* DataMapping::GetMapping() const {
  return data_.data();
}

// NonOwnedMapping

NonOwnedMapping::NonOwnedMapping(const uint8_t* data,
                                 size_t size,
                                 ReleaseProc release_proc)
    : data_(data), size_(size), release_proc_(release_proc) {}

NonOwnedMapping::~NonOwnedMapping() {
  if (release_proc_) {
    release_proc_(data_, size_);
  }
}

size_t NonOwnedMapping::GetSize() const {
  return size_;
}

const uint8_t* NonOwnedMapping::GetMapping() const {
  return data_;
}

// Symbol Mapping

SymbolMapping::SymbolMapping(fml::RefPtr<fml::NativeLibrary> native_library,
                             const char* symbol_name)
    : native_library_(std::move(native_library)) {
  if (native_library_ && symbol_name != nullptr) {
    mapping_ = native_library_->ResolveSymbol(symbol_name);

    if (mapping_ == nullptr) {
      // Apparently, dart_bootstrap seems to account for the Mac behavior of
      // requiring the underscore prefixed symbol name on non-Mac platforms as
      // well. As a fallback, check the underscore prefixed variant of the
      // symbol name and allow callers to not have handle this on a per platform
      // toolchain quirk basis.

      std::stringstream underscore_symbol_name;
      underscore_symbol_name << "_" << symbol_name;
      mapping_ =
          native_library_->ResolveSymbol(underscore_symbol_name.str().c_str());
    }
  }
}

SymbolMapping::~SymbolMapping() = default;

size_t SymbolMapping::GetSize() const {
  return 0;
}

const uint8_t* SymbolMapping::GetMapping() const {
  return mapping_;
}

}  // namespace fml
