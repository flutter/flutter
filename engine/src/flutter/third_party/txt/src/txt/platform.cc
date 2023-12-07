// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "txt/platform.h"

namespace txt {

std::vector<std::string> GetDefaultFontFamilies() {
  return {"Arial"};
}

sk_sp<SkFontMgr> GetDefaultFontManager(uint32_t font_initialization_data) {
  return SkFontMgr::RefDefault();
}

}  // namespace txt
