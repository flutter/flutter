// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_MAPPING_H_
#define FLUTTER_FML_MAPPING_H_

#include <memory>
#include <string>
#include <vector>

#include "flutter/fml//unique_fd.h"
#include "flutter/fml/build_config.h"
#include "flutter/fml/macros.h"

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

bool PlatformHasResourcesBundle();

std::unique_ptr<Mapping> GetResourceMapping(const std::string& resource_name);

class FileMapping : public Mapping {
 public:
  FileMapping(const std::string& path, bool executable = false);

  FileMapping(const fml::UniqueFD& fd, bool executable = false);

  ~FileMapping() override;

  size_t GetSize() const override;

  const uint8_t* GetMapping() const override;

 private:
  size_t size_ = 0;
  uint8_t* mapping_ = nullptr;

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

}  // namespace fml

#endif  // FLUTTER_FML_MAPPING_H_
