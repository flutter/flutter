// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_MAPPING_H_
#define FLUTTER_FML_MAPPING_H_

#include <string>

#include "lib/fxl/files/unique_fd.h"
#include "lib/fxl/macros.h"

namespace fml {

class Mapping {
 public:
  Mapping();

  virtual ~Mapping();

  virtual size_t GetSize() const = 0;

  virtual const uint8_t* GetMapping() const = 0;

 private:
  FXL_DISALLOW_COPY_AND_ASSIGN(Mapping);
};

bool PlatformHasResourcesBundle();

std::unique_ptr<Mapping> GetResourceMapping(const std::string& resource_name);

class FileMapping : public Mapping {
 public:
  FileMapping(const std::string& path);

  FileMapping(const fxl::UniqueFD& fd);

  ~FileMapping() override;

  size_t GetSize() const override;

  const uint8_t* GetMapping() const override;

 private:
  size_t size_;
  uint8_t* mapping_;

  FXL_DISALLOW_COPY_AND_ASSIGN(FileMapping);
};

}  // namespace fml

#endif  // FLUTTER_FML_MAPPING_H_
