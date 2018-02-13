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

#include "font_collection.h"

#include <list>
#include <memory>
#include <mutex>
#include <set>
#include <string>
#include <unordered_map>
#include <vector>
#include "font_skia.h"
#include "lib/fxl/logging.h"
#include "txt/platform.h"
#include "txt/text_style.h"

namespace txt {

namespace {

// Example characters representing character classes that may require a
// fallback font.
const std::vector<SkUnichar> fallback_characters{
    0x1f600,  // emoji
    0x4e00,   // CJK
    0x5d0,    // Hebrew
    0x627,    // Arabic
};

// Font families that will be used as a last resort if no font manager provides
// a font matching a particular character.
const std::vector<std::string> last_resort_fonts{
    "Arial",
};

}  // anonymous namespace

class TxtFallbackFontProvider
    : public minikin::FontCollection::FallbackFontProvider {
 public:
  TxtFallbackFontProvider(std::shared_ptr<FontCollection> font_collection)
      : font_collection_(font_collection) {}

  virtual const std::shared_ptr<minikin::FontFamily>& matchFallbackFont(
      uint32_t ch) {
    return font_collection_->MatchFallbackFont(ch);
  }

 private:
  std::shared_ptr<FontCollection> font_collection_;
};

FontCollection::FontCollection() : enable_font_fallback_(true) {}

FontCollection::~FontCollection() = default;

size_t FontCollection::GetFontManagersCount() const {
  return skia_font_managers_.size();
}

void FontCollection::PushFront(sk_sp<SkFontMgr> skia_font_manager) {
  if (!skia_font_manager) {
    return;
  }
  UpdateFallbackFonts(skia_font_manager);
  skia_font_managers_.push_front(std::move(skia_font_manager));
}

void FontCollection::PushBack(sk_sp<SkFontMgr> skia_font_manager) {
  if (!skia_font_manager) {
    return;
  }
  UpdateFallbackFonts(skia_font_manager);
  skia_font_managers_.push_back(std::move(skia_font_manager));
}

void FontCollection::DisableFontFallback() {
  enable_font_fallback_ = false;
}

std::shared_ptr<minikin::FontCollection>
FontCollection::GetMinikinFontCollectionForFamily(const std::string& family) {
  // Look inside the font collections cache first.
  auto cached = font_collections_cache_.find(family);
  if (cached != font_collections_cache_.end()) {
    return cached->second;
  }

  for (sk_sp<SkFontMgr> manager : skia_font_managers_) {
    auto font_style_set = manager->matchFamily(family.c_str());
    if (font_style_set == nullptr || font_style_set->count() == 0) {
      continue;
    }

    std::vector<minikin::Font> minikin_fonts;

    // Add fonts to the Minikin font family.
    for (int i = 0, style_count = font_style_set->count(); i < style_count;
         ++i) {
      // Create the skia typeface.
      auto skia_typeface =
          sk_ref_sp<SkTypeface>(font_style_set->createTypeface(i));
      if (skia_typeface == nullptr) {
        continue;
      }

      // Create the minikin font from the skia typeface.
      // Divide by 100 because the weights are given as "100", "200", etc.
      minikin::Font minikin_font(
          std::make_shared<FontSkia>(skia_typeface),
          minikin::FontStyle{skia_typeface->fontStyle().weight() / 100,
                             skia_typeface->isItalic()});

      minikin_fonts.emplace_back(std::move(minikin_font));
    }

    // Create a Minikin font family.
    auto minikin_family =
        std::make_shared<minikin::FontFamily>(std::move(minikin_fonts));

    // Create a vector of font families for the Minikin font collection.
    std::vector<std::shared_ptr<minikin::FontFamily>> minikin_families = {
        minikin_family,
    };
    if (enable_font_fallback_) {
      for (const auto& fallback : fallback_fonts_)
        minikin_families.push_back(fallback.second);
    }

    // Create the minikin font collection.
    auto font_collection =
        std::make_shared<minikin::FontCollection>(std::move(minikin_families));
    if (enable_font_fallback_) {
      font_collection->set_fallback_font_provider(
          std::make_unique<TxtFallbackFontProvider>(shared_from_this()));
    }

    // Cache the font collection for future queries.
    font_collections_cache_[family] = font_collection;

    return font_collection;
  }

  const auto default_font_family = GetDefaultFontFamily();
  if (family != default_font_family) {
    return GetMinikinFontCollectionForFamily(default_font_family);
  }

  // No match found in any of our font managers.
  return nullptr;
}

const std::shared_ptr<minikin::FontFamily>& FontCollection::MatchFallbackFont(
    uint32_t ch) {
  for (const auto& manager : skia_font_managers_) {
    sk_sp<SkTypeface> typeface(
        manager->matchFamilyStyleCharacter(0, SkFontStyle(), nullptr, 0, ch));
    if (!typeface)
      continue;

    return GetFontFamilyForTypeface(typeface);
  }

  return null_family_;
}

const std::shared_ptr<minikin::FontFamily>&
FontCollection::GetFontFamilyForTypeface(const sk_sp<SkTypeface>& typeface) {
  SkFontID typeface_id = typeface->uniqueID();
  auto fallback_it = fallback_fonts_.find(typeface_id);
  if (fallback_it != fallback_fonts_.end()) {
    return fallback_it->second;
  }

  std::vector<minikin::Font> minikin_fonts;
  minikin_fonts.emplace_back(std::make_shared<FontSkia>(typeface),
                             minikin::FontStyle());
  auto insert_it = fallback_fonts_.insert(std::make_pair(
      typeface_id,
      std::make_shared<minikin::FontFamily>(std::move(minikin_fonts))));

  // Clear the cache to force creation of new font collections that will include
  // this fallback font.
  font_collections_cache_.clear();

  return insert_it.first->second;
}

void FontCollection::UpdateFallbackFonts(sk_sp<SkFontMgr> manager) {
  // Prepopulate the fallback font cache with fonts matching some widely
  // used character classes.
  for (SkUnichar fallback_char : fallback_characters) {
    sk_sp<SkTypeface> typeface(manager->matchFamilyStyleCharacter(
        0, SkFontStyle(), nullptr, 0, fallback_char));
    if (typeface) {
      // Create a Minikin font family for this typeface if one does not already
      // exist.
      GetFontFamilyForTypeface(typeface);
    }
  }

  // Add additional font families to be used if nothing else matches.
  for (const std::string& family : last_resort_fonts) {
    sk_sp<SkTypeface> typeface(
        manager->matchFamilyStyle(family.c_str(), SkFontStyle()));
    if (typeface) {
      GetFontFamilyForTypeface(typeface);
    }
  }
}

}  // namespace txt
