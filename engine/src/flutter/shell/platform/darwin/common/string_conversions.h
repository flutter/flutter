// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_COMMON_STRING_CONVERSIONS_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_COMMON_STRING_CONVERSIONS_H_

#include <Foundation/Foundation.h>

#include <vector>

namespace shell {

std::vector<uint8_t> GetVectorFromNSString(NSString* string);

NSString* GetNSStringFromVector(const std::vector<uint8_t>& buffer);

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_COMMON_STRING_CONVERSIONS_H_
