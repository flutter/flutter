// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TXT_PLATFORM_H_
#define TXT_PLATFORM_H_

#include <string>
#include "flutter/fml/macros.h"

#include "third_party/skia/include/core/SkFontMgr.h"

namespace txt {

std::string GetDefaultFontFamily();

sk_sp<SkFontMgr> GetDefaultFontManager();

}  // namespace txt

#endif  // TXT_PLATFORM_H_
