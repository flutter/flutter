// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_PLATFORM_DARWIN_NSSTRING_UTILS_H_
#define FLUTTER_FML_PLATFORM_DARWIN_NSSTRING_UTILS_H_

#include <string>

#include "lib/ftl/macros.h"

@class NSString;

namespace fml {

NSString* StringToNSString(const std::u16string& string);

std::u16string StringFromNSString(NSString* string);

}  // namespace fml

#endif  // FLUTTER_FML_PLATFORM_DARWIN_NSSTRING_UTILS_H_
