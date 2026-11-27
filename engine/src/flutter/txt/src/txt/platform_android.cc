// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "txt/platform_android.h"

#include <mutex>
#include <utility>

#include "txt/platform.h"

#if defined(SK_FONTMGR_ANDROID_AVAILABLE)
#include "third_party/skia/include/ports/SkFontMgr_android.h"
#include "third_party/skia/include/ports/SkFontScanner_FreeType.h"
#endif

#if defined(SK_FONTMGR_FREETYPE_EMPTY_AVAILABLE)
#include "third_party/skia/include/ports/SkFontMgr_empty.h"
#endif

namespace txt {

namespace {

std::mutex& UpdatedSystemFontsXmlMutex() {
  static std::mutex* mutex = new std::mutex();
  return *mutex;
}

std::string& UpdatedSystemFontsXml() {
  static std::string* path = new std::string();
  return *path;
}

}  // namespace

void SetUpdatedSystemFontsXml(std::string path) {
  std::lock_guard<std::mutex> lock(UpdatedSystemFontsXmlMutex());
  UpdatedSystemFontsXml() = std::move(path);
}

sk_sp<SkFontMgr> MakeAndroidFontManager() {
#if defined(SK_FONTMGR_ANDROID_AVAILABLE)
  std::string updated_fonts_xml;
  {
    std::lock_guard<std::mutex> lock(UpdatedSystemFontsXmlMutex());
    updated_fonts_xml = UpdatedSystemFontsXml();
  }
  if (updated_fonts_xml.empty()) {
    return SkFontMgr_New_Android(nullptr, SkFontScanner_Make_FreeType());
  }
  // Entries in updated_fonts_xml carry absolute /data/fonts paths, so fBasePath
  // is empty, and fFallbackFontsXml stays null for version-21 configs
  SkFontMgr_Android_CustomFonts custom = {
      .fSystemFontUse = SkFontMgr_Android_CustomFonts::kPreferCustom,
      .fBasePath = "",
      .fFontsXml = updated_fonts_xml.c_str(),
      .fFallbackFontsXml = nullptr,
      .fIsolated = false,
  };
  return SkFontMgr_New_Android(&custom, SkFontScanner_Make_FreeType());
#elif defined(SK_FONTMGR_FREETYPE_EMPTY_AVAILABLE)
  return SkFontMgr_New_Custom_Empty();
#else
  return SkFontMgr::RefEmpty();
#endif
}

std::vector<std::string> GetDefaultFontFamilies() {
  return {"sans-serif"};
}

sk_sp<SkFontMgr> GetDefaultFontManager(uint32_t font_initialization_data) {
  static sk_sp<SkFontMgr> mgr = MakeAndroidFontManager();
  return mgr;
}

}  // namespace txt
