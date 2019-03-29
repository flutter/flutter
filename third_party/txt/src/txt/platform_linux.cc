// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "txt/platform.h"

#include "third_party/skia/include/ports/SkFontMgr_directory.h"

namespace txt {

std::string GetDefaultFontFamily() {
  return "Arial";
}

sk_sp<SkFontMgr> GetDefaultFontManager() {
  return SkFontMgr_New_Custom_Directory("/usr/share/fonts/");
}

}  // namespace txt
