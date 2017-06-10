/*
 * Copyright 2017 Google, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "lib/txt/src/font_collection.h"

#include <mutex>
#include <set>
#include <string>

#include "lib/ftl/logging.h"
#include "lib/txt/src/font_skia.h"
#include "third_party/skia/include/core/SkString.h"
#include "third_party/skia/include/ports/SkFontMgr.h"
#include "third_party/skia/include/ports/SkFontMgr_directory.h"

namespace txt {

FontCollection& FontCollection::GetDefaultFontCollection() {
  static FontCollection* collection = nullptr;
  static std::once_flag once;
  std::call_once(once, []() { collection = new FontCollection(); });
  return *collection;
}

FontCollection::FontCollection() {
#ifdef DIRECTORY_FONT_MANAGER_AVAILABLE
  skia_font_manager_ = dir.length() != 0
                           ? SkFontMgr_New_Custom_Directory(dir.c_str())
                           : SkFontMgr::RefDefault();
#else
  skia_font_manager_ = SkFontMgr::RefDefault();
#endif
}

FontCollection::~FontCollection() = default;

std::set<std::string> FontCollection::GetFamilyNames(const std::string& dir) {
  std::set<std::string> names;
  SkString str;
  for (int i = 0; i < skia_font_manager_->countFamilies(); i++) {
    skia_font_manager_->getFamilyName(i, &str);
    names.insert(std::string{str.writable_str()});
  }
  return names;
}

const std::string FontCollection::ProcessFamilyName(const std::string& family) {
#ifdef DIRECTORY_FONT_MANAGER_AVAILABLE
  return family.length() == 0 ? DEFAULT_FAMILY_NAME : family;
#else
  if (family.length() == 0) {
    return *GetFamilyNames().begin();
  } else if (GetFamilyNames().count(family) > 0) {  // Ensure family exists.
    return family;
  } else {
    return *GetFamilyNames().begin();  // First family available.
  }
#endif
}

std::shared_ptr<minikin::FontCollection>
FontCollection::GetMinikinFontCollectionForFamily(const std::string& family,
                                                  const std::string& dir) {
  FTL_DCHECK(skia_font_manager_ != nullptr);

  // Ask Skia to resolve a font style set for a font family name.
  // FIXME(chinmaygarde): The name "Coolvetica" is hardcoded because CoreText
  // crashes when passed a null string. This seems to be a bug in Skia as
  // SkFontMgr explicitly says passing in nullptr gives the default font.

  auto font_style_set =
      skia_font_manager_->matchFamily(ProcessFamilyName(family).c_str());
  FTL_DCHECK(font_style_set != nullptr);

  std::vector<minikin::Font> minikin_fonts;

  // Add fonts to the Minikin font family.
  for (int i = 0, style_count = font_style_set->count(); i < style_count; ++i) {
    // Create the skia typeface
    auto skia_typeface =
        sk_ref_sp<SkTypeface>(font_style_set->createTypeface(i));
    if (skia_typeface == nullptr) {
      continue;
    }

    // Create the minikin font from the skia typeface.
    minikin::Font minikin_font(
        std::make_shared<FontSkia>(skia_typeface),
        minikin::FontStyle{skia_typeface->fontStyle().weight(),
                           skia_typeface->isItalic()});

    minikin_fonts.emplace_back(std::move(minikin_font));
  }

  // Create a Minikin font family.
  auto minikin_family =
      std::make_shared<minikin::FontFamily>(std::move(minikin_fonts));

  // Create a vector of font families for the Minkin font collection. For now,
  // we only have one family in our collection.
  std::vector<std::shared_ptr<minikin::FontFamily>> minikin_families = {
      minikin_family,
  };

  // Return the font collection.
  return std::make_shared<minikin::FontCollection>(minikin_families);
}

}  // namespace txt
