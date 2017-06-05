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

#include "lib/ftl/logging.h"
#include "lib/txt/src/font_skia.h"
#include "third_party/skia/include/ports/SkFontMgr.h"
#include "third_party/skia/include/ports/SkFontMgr_directory.h"

namespace txt {

FontCollection& FontCollection::GetDefaultFontCollection() {
  static FontCollection* collection = nullptr;
  static std::once_flag once;
  std::call_once(once, []() { collection = new FontCollection(); });
  return *collection;
}

FontCollection::FontCollection() = default;

FontCollection::~FontCollection() = default;

std::shared_ptr<minikin::FontCollection>
FontCollection::GetMinikinFontCollectionForFamily(const std::string& family,
                                                  const std::string& dir) {
  // Get the Skia font manager.
  auto skia_font_manager = dir.length() != 0
                               ? SkFontMgr_New_Custom_Directory(dir.c_str())
                               : SkFontMgr::RefDefault();

  FTL_DCHECK(skia_font_manager != nullptr);

  // Ask Skia to resolve a font style set for a font family name.
  // FIXME(chinmaygarde): The name "Sample Font" is hardcoded because CoreText
  // crashes when passed a null string. This seems to be a bug in Skia as
  // SkFontMgr explicitly says passing in nullptr gives the default font.
  auto font_style_set = skia_font_manager->matchFamily(
      family.length() == 0 ? "Sample Font" : family.c_str());
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
