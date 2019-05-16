// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "txt/platform.h"

#ifdef FONTCONFIG_FONT_MANAGER_AVAILABLE
#include "third_party/skia/include/ports/SkFontMgr_fontconfig.h"
#else
#include "third_party/skia/include/ports/SkFontMgr_directory.h"
#endif

namespace txt {

std::string GetDefaultFontFamily() {
  return "Arial";
}

sk_sp<SkFontMgr> GetDefaultFontManager() {
#ifdef FONTCONFIG_FONT_MANAGER_AVAILABLE
  return SkFontMgr_New_FontConfig(nullptr);
#else
  return SkFontMgr_New_Custom_Directory("/usr/share/fonts/");
#endif
}

}  // namespace txt
