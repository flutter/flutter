// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_MAPPING_H_
#define FLUTTER_FML_MAPPING_H_

#include <initializer_list>
#include <memory>
#include <string>
#include <vector>

#include "flutter/fml/build_config.h"
#include "flutter/fml/file.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/native_library.h"
#include "flutter/fml/unique_fd.h"

namespace fml {

class Mapping {
 public:
  Mapping();

  virtual ~Mapping();

  virtual size_t GetSize() const = 0;

  virtual const uint8_t* GetMapping() const = 0;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(Mapping);
};

class FileMapping final : public Mapping {
 public:
  enum class Protection {
    kRead,
    kWrite,
    kExecute,
  };

  FileMapping(const fml::UniqueFD& fd,
              std::initializer_list<Protection> protection = {
                  Protection::kRead});

  ~FileMapping() override;

  static std::unique_ptr<FileMapping> CreateReadOnly(const std::string& path);

  static std::unique_ptr<FileMapping> CreateReadOnly(
      const fml::UniqueFD& base_fd,
      const std::string& sub_path = "");

  static std::unique_ptr<FileMapping> CreateReadExecute(
      const std::string& path);

  static std::unique_ptr<FileMapping> CreateReadExecute(
      const fml::UniqueFD& base_fd,
      const std::string& sub_path = "");

  // |Mapping|
  size_t GetSize() const override;

  // |Mapping|
  const uint8_t* GetMapping() const override;

  uint8_t* GetMutableMapping();

  bool IsValid() const;

 private:
  bool valid_ = false;
  size_t size_ = 0;
  uint8_t* mapping_ = nullptr;
  uint8_t* mutable_mapping_ = nullptr;

#if OS_WIN
  fml::UniqueFD mapping_handle_;
#endif

  FML_DISALLOW_COPY_AND_ASSIGN(FileMapping);
};

class DataMapping final : public Mapping {
 public:
  DataMapping(std::vector<uint8_t> data);

  ~DataMapping() override;

  // |Mapping|
  size_t GetSize() const override;

  // |Mapping|
  const uint8_t* GetMapping() const override;

 private:
  std::vector<uint8_t> data_;

  FML_DISALLOW_COPY_AND_ASSIGN(DataMapping);
};

class NonOwnedMapping final : public Mapping {
 public:
  using ReleaseProc = std::function<void(const uint8_t* data, size_t size)>;
  NonOwnedMapping(const uint8_t* data,
                  size_t size,
                  ReleaseProc release_proc = nullptr);

  ~NonOwnedMapping() override;

  // |Mapping|
  size_t GetSize() const override;

  // |Mapping|
  const uint8_t* GetMapping() const override;

 private:
  const uint8_t* const data_;
  const size_t size_;
  const ReleaseProc release_proc_;

  FML_DISALLOW_COPY_AND_ASSIGN(NonOwnedMapping);
};

class SymbolMapping final : public Mapping {
 public:
  SymbolMapping(fml::RefPtr<fml::NativeLibrary> native_library,
                const char* symbol_name);

  ~SymbolMapping() override;

  // |Mapping|
  size_t GetSize() const override;

  // |Mapping|
  const uint8_t* GetMapping() const override;

 private:
  fml::RefPtr<fml::NativeLibrary> native_library_;
  const uint8_t* mapping_ = nullptr;

  FML_DISALLOW_COPY_AND_ASSIGN(SymbolMapping);
};

}  // namespace fml

#endif  // FLUTTER_FML_MAPPING_H_
