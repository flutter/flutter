// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/common/buffer_conversions.h"

namespace flutter {

std::vector<uint8_t> GetVectorFromNSData(NSData* data) {
  const uint8_t* bytes = reinterpret_cast<const uint8_t*>(data.bytes);
  return std::vector<uint8_t>(bytes, bytes + data.length);
}

NSData* GetNSDataFromVector(const std::vector<uint8_t>& buffer) {
  return [NSData dataWithBytes:buffer.data() length:buffer.size()];
}

std::unique_ptr<fml::Mapping> GetMappingFromNSData(NSData* data) {
  return std::make_unique<fml::DataMapping>(GetVectorFromNSData(data));
}

NSData* GetNSDataFromMapping(std::unique_ptr<fml::Mapping> mapping) {
  return [NSData dataWithBytes:mapping->GetMapping() length:mapping->GetSize()];
}

}  // namespace flutter
