// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/common/buffer_conversions.h"

namespace flutter {

fml::MallocMapping CopyNSDataToMapping(NSData* data) {
  const uint8_t* bytes = static_cast<const uint8_t*>(data.bytes);
  return fml::MallocMapping::Copy(bytes, data.length);
}

NSData* CopyMappingToNSData(fml::MallocMapping buffer) {
  return [NSData dataWithBytes:const_cast<uint8_t*>(buffer.GetMapping()) length:buffer.GetSize()];
}

std::unique_ptr<fml::Mapping> CopyNSDataToMappingPtr(NSData* data) {
  auto mapping = CopyNSDataToMapping(data);
  return std::make_unique<fml::MallocMapping>(std::move(mapping));
}

NSData* CopyMappingPtrToNSData(std::unique_ptr<fml::Mapping> mapping) {
  return [NSData dataWithBytes:mapping->GetMapping() length:mapping->GetSize()];
}

}  // namespace flutter
