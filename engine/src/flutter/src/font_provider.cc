/*
 * Copyright 2017 Google Inc.
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

#include "lib/txt/src/font_provider.h"

#include <mutex>

#include "lib/ftl/logging.h"
#include "lib/txt/src/font_skia.h"
#include "third_party/skia/include/ports/SkFontMgr.h"

namespace txt {
namespace {

bool IsItalic(SkFontStyle::Slant slant) {
  return slant != SkFontStyle::Slant::kUpright_Slant;
}

}  // namespace

FontProvider& FontProvider::GetDefault() {
  static FontProvider* provider = nullptr;
  static std::once_flag once;
  std::call_once(once, []() { provider = new FontProvider(); });
  return *provider;
}

FontProvider::FontProvider() = default;

FontProvider::~FontProvider() = default;

std::shared_ptr<minikin::FontCollection>
FontProvider::GetFontCollectionForFamily(const std::string& family) {
  // Get the Skia font manager.
  auto font_manager = SkFontMgr::RefDefault();
  FTL_DCHECK(font_manager != nullptr);

  // Ask Skia to resolve a font style set for a font family name.
  // FIXME(chinmaygarde): The name "Hevetica" is hardcoded because CoreText
  // crashes when passed a null string. This seems to be a bug in Skia as
  // SkFontMgr explicitly says passing in nullptr gives the default font.
  auto font_style_set = font_manager->matchFamily(
      family.length() == 0 ? "Helvetica" : family.c_str());
  FTL_DCHECK(font_style_set != nullptr);

  std::vector<minikin::Font> fonts;

  // Add fonts to the Minikin font family.
  for (int i = 0, style_count = font_style_set->count(); i < style_count; ++i) {
    auto skia_typeface =
        sk_ref_sp<SkTypeface>(font_style_set->createTypeface(i));
    auto typeface = std::make_shared<FontSkia>(std::move(skia_typeface));

    SkFontStyle font_style;
    font_style_set->getStyle(i, &font_style, nullptr);
    minikin::FontStyle style(font_style.weight(), IsItalic(font_style.slant()));

    fonts.push_back(minikin::Font(std::move(typeface), style));
  }

  auto minikin_family = std::make_shared<minikin::FontFamily>(std::move(fonts));
  return std::make_shared<minikin::FontCollection>(std::move(minikin_family));
}

}  // namespace txt
