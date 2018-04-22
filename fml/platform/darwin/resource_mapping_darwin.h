// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_PLATFORM_DARWIN_RESOURCE_MAPPING_DARWIN_H_
#define FLUTTER_FML_PLATFORM_DARWIN_RESOURCE_MAPPING_DARWIN_H_

#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"

namespace fml {

class ResourceMappingDarwin : public Mapping {
 public:
  ResourceMappingDarwin(const std::string& resource);

  ~ResourceMappingDarwin() override;

  size_t GetSize() const override;

  const uint8_t* GetMapping() const override;

 private:
  FileMapping actual_;

  FML_DISALLOW_COPY_AND_ASSIGN(ResourceMappingDarwin);
};

}  // namespace fml

#endif  // FLUTTER_FML_PLATFORM_DARWIN_RESOURCE_MAPPING_DARWIN_H_
