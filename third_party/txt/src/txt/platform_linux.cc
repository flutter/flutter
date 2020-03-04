// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "txt/platform.h"

#ifdef FLUTTER_USE_FONTCONFIG
#include "third_party/skia/include/ports/SkFontMgr_fontconfig.h"
#else
#include "third_party/skia/include/ports/SkFontMgr_directory.h"
#endif

namespace txt {

std::vector<std::string> GetDefaultFontFamilies() {
  return {"Ubuntu", "Cantarell", "DejaVu Sans", "Liberation Sans", "Arial"};
}

sk_sp<SkFontMgr> GetDefaultFontManager() {
#ifdef FLUTTER_USE_FONTCONFIG
  return SkFontMgr_New_FontConfig(nullptr);
#else
  return SkFontMgr_New_Custom_Directory("/usr/share/fonts/");
#endif
}

}  // namespace txt
