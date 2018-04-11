// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/platform/darwin/resource_mapping_darwin.h"

#include <Foundation/Foundation.h>

namespace fml {

ResourceMappingDarwin::ResourceMappingDarwin(const std::string& resource)
    : actual_([[[NSBundle mainBundle] pathForResource:@(resource.c_str()) ofType:nil] UTF8String],
              false) {}

ResourceMappingDarwin::~ResourceMappingDarwin() = default;

size_t ResourceMappingDarwin::GetSize() const {
  return actual_.GetSize();
}

const uint8_t* ResourceMappingDarwin::GetMapping() const {
  return actual_.GetMapping();
}

}  // namespace fml
