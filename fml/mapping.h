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

class FileMapping : public Mapping {
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

  size_t GetSize() const override;

  const uint8_t* GetMapping() const override;

  uint8_t* GetMutableMapping();

 private:
  size_t size_ = 0;
  uint8_t* mapping_ = nullptr;
  uint8_t* mutable_mapping_ = nullptr;

#if OS_WIN
  fml::UniqueFD mapping_handle_;
#endif

  FML_DISALLOW_COPY_AND_ASSIGN(FileMapping);
};

class DataMapping : public Mapping {
 public:
  DataMapping(std::vector<uint8_t> data);

  ~DataMapping() override;

  size_t GetSize() const override;

  const uint8_t* GetMapping() const override;

 private:
  std::vector<uint8_t> data_;

  FML_DISALLOW_COPY_AND_ASSIGN(DataMapping);
};

class NonOwnedMapping : public Mapping {
 public:
  NonOwnedMapping(const uint8_t* data, size_t size)
      : data_(data), size_(size) {}

  size_t GetSize() const override { return size_; }

  const uint8_t* GetMapping() const override { return data_; }

 private:
  const uint8_t* const data_;
  const size_t size_;

  FML_DISALLOW_COPY_AND_ASSIGN(NonOwnedMapping);
};

}  // namespace fml

#endif  // FLUTTER_FML_MAPPING_H_
