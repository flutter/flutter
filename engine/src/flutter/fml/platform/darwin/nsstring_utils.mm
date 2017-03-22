// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/platform/darwin/nsstring_utils.h"

#include <Foundation/Foundation.h>

namespace fml {

NSString* StringToNSString(const std::u16string& string) {
  return [[[NSString alloc] initWithBytes:string.data()
                                   length:string.length()
                                 encoding:NSUTF16StringEncoding] autorelease];
}

std::u16string StringFromNSString(NSString* string) {
  if (string.length == 0) {
    return {};
  }
  NSData* data = [string dataUsingEncoding:NSUTF16StringEncoding];
  return {reinterpret_cast<const char16_t*>(data.bytes), data.length};
}

}  // namespace fml
