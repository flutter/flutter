// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/common/string_conversions.h"

namespace shell {

std::vector<uint8_t> GetVectorFromNSString(NSString* string) {
  if (!string.length)
    return std::vector<uint8_t>();
  const char* chars = string.UTF8String;
  const uint8_t* bytes = reinterpret_cast<const uint8_t*>(chars);
  return std::vector<uint8_t>(bytes, bytes + strlen(chars));
}

NSString* GetNSStringFromVector(const std::vector<uint8_t>& buffer) {
  NSString* string = [[NSString alloc] initWithBytes:buffer.data()
                                              length:buffer.size()
                                            encoding:NSUTF8StringEncoding];
  [string autorelease];
  return string;
}

}  // namespace shell
