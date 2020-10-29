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

#include <algorithm>
#include <list>
#include <memory>
#include <mutex>
#include <set>
#include <string>
#include <unordered_map>
#include <vector>
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "font_skia.h"
#include "minikin/Layout.h"
#include "txt/platform.h"
#include "txt/text_style.h"

namespace txt {

namespace {

const std::shared_ptr<minikin::FontFamily> g_null_family;

}  // anonymous namespace

FontCollection::FamilyKey::FamilyKey(const std::vector<std::string>& families,
                                     const std::string& loc) {
  locale = loc;

  std::stringstream stream;
  for_each(families.begin(), families.end(),
           [&stream](const std::string& str) { stream << str << ','; });
  font_families = stream.str();
}

bool FontCollection::FamilyKey::operator==(
    const FontCollection::FamilyKey& other) const {
  return font_families == other.font_families && locale == other.locale;
}

size_t FontCollection::FamilyKey::Hasher::operator()(
    const FontCollection::FamilyKey& key) const {
  return std::hash<std::string>()(key.font_families) ^
         std::hash<std::string>()(key.locale);
}

class TxtFallbackFontProvider
    : public minikin::FontCollection::FallbackFontProvider {
 public:
  TxtFallbackFontProvider(std::shared_ptr<FontCollection> font_collection)
      : font_collection_(font_collection) {}

  virtual const std::shared_ptr<minikin::FontFamily>& matchFallbackFont(
      uint32_t ch,
      std::string locale) {
    std::shared_ptr<FontCollection> fc = font_collection_.lock();
    if (fc) {
      return fc->MatchFallbackFont(ch, locale);
    } else {
      return g_null_family;
    }
  }

 private:
  std::weak_ptr<FontCollection> font_collection_;
};

FontCollection::FontCollection() : enable_font_fallback_(true) {}

FontCollection::~FontCollection() {
  minikin::Layout::purgeCaches();

#if FLUTTER_ENABLE_SKSHAPER
  if (skt_collection_) {
    skt_collection_->clearCaches();
  }
#endif
}

size_t FontCollection::GetFontManagersCount() const {
  return GetFontManagerOrder().size();
}

void FontCollection::SetupDefaultFontManager() {
  default_font_manager_ = GetDefaultFontManager();
}

void FontCollection::SetDefaultFontManager(sk_sp<SkFontMgr> font_manager) {
  default_font_manager_ = font_manager;

#if FLUTTER_ENABLE_SKSHAPER
  skt_collection_.reset();
#endif
}

void FontCollection::SetAssetFontManager(sk_sp<SkFontMgr> font_manager) {
  asset_font_manager_ = font_manager;

#if FLUTTER_ENABLE_SKSHAPER
  skt_collection_.reset();
#endif
}

void FontCollection::SetDynamicFontManager(sk_sp<SkFontMgr> font_manager) {
  dynamic_font_manager_ = font_manager;

#if FLUTTER_ENABLE_SKSHAPER
  skt_collection_.reset();
#endif
}

void FontCollection::SetTestFontManager(sk_sp<SkFontMgr> font_manager) {
  test_font_manager_ = font_manager;

#if FLUTTER_ENABLE_SKSHAPER
  skt_collection_.reset();
#endif
}

// Return the available font managers in the order they should be queried.
std::vector<sk_sp<SkFontMgr>> FontCollection::GetFontManagerOrder() const {
  std::vector<sk_sp<SkFontMgr>> order;
  if (dynamic_font_manager_)
    order.push_back(dynamic_font_manager_);
  if (asset_font_manager_)
    order.push_back(asset_font_manager_);
  if (test_font_manager_)
    order.push_back(test_font_manager_);
  if (default_font_manager_)
    order.push_back(default_font_manager_);
  return order;
}

void FontCollection::DisableFontFallback() {
  enable_font_fallback_ = false;

#if FLUTTER_ENABLE_SKSHAPER
  if (skt_collection_) {
    skt_collection_->disableFontFallback();
  }
#endif
}

std::shared_ptr<minikin::FontCollection>
FontCollection::GetMinikinFontCollectionForFamilies(
    const std::vector<std::string>& font_families,
    const std::string& locale) {
  // Look inside the font collections cache first.
  FamilyKey family_key(font_families, locale);
  auto cached = font_collections_cache_.find(family_key);
  if (cached != font_collections_cache_.end()) {
    return cached->second;
  }

  std::vector<std::shared_ptr<minikin::FontFamily>> minikin_families;

  // Search for all user provided font families.
  for (size_t fallback_index = 0; fallback_index < font_families.size();
       fallback_index++) {
    std::shared_ptr<minikin::FontFamily> minikin_family =
        FindFontFamilyInManagers(font_families[fallback_index]);
    if (minikin_family != nullptr) {
      minikin_families.push_back(minikin_family);
    }
  }
  // Search for default font family if no user font families were found.
  if (minikin_families.empty()) {
    const auto default_font_families = GetDefaultFontFamilies();
    for (const auto& family : default_font_families) {
      std::shared_ptr<minikin::FontFamily> minikin_family =
          FindFontFamilyInManagers(family);
      if (minikin_family != nullptr) {
        minikin_families.push_back(minikin_family);
        break;
      }
    }
  }
  // Default font family also not found. We fail to get a FontCollection.
  if (minikin_families.empty()) {
    font_collections_cache_[family_key] = nullptr;
    return nullptr;
  }
  if (enable_font_fallback_) {
    for (const std::string& fallback_family :
         fallback_fonts_for_locale_[locale]) {
      auto it = fallback_fonts_.find(fallback_family);
      if (it != fallback_fonts_.end()) {
        minikin_families.push_back(it->second);
      }
    }
  }
  // Create the minikin font collection.
  auto font_collection =
      std::make_shared<minikin::FontCollection>(std::move(minikin_families));
  if (enable_font_fallback_) {
    font_collection->set_fallback_font_provider(
        std::make_unique<TxtFallbackFontProvider>(shared_from_this()));
  }

  // Cache the font collection for future queries.
  font_collections_cache_[family_key] = font_collection;

  return font_collection;
}

std::shared_ptr<minikin::FontFamily> FontCollection::FindFontFamilyInManagers(
    const std::string& family_name) {
  TRACE_EVENT0("flutter", "FontCollection::FindFontFamilyInManagers");
  // Search for the font family in each font manager.
  for (sk_sp<SkFontMgr>& manager : GetFontManagerOrder()) {
    std::shared_ptr<minikin::FontFamily> minikin_family =
        CreateMinikinFontFamily(manager, family_name);
    if (!minikin_family)
      continue;
    return minikin_family;
  }
  return nullptr;
}

void FontCollection::SortSkTypefaces(
    std::vector<sk_sp<SkTypeface>>& sk_typefaces) {
  std::sort(
      sk_typefaces.begin(), sk_typefaces.end(),
      [](const sk_sp<SkTypeface>& a, const sk_sp<SkTypeface>& b) {
        SkFontStyle a_style = a->fontStyle();
        SkFontStyle b_style = b->fontStyle();

        int a_delta = std::abs(a_style.width() - SkFontStyle::kNormal_Width);
        int b_delta = std::abs(b_style.width() - SkFontStyle::kNormal_Width);

        if (a_delta != b_delta) {
          // If a family name query is so generic it ends up bringing in fonts
          // of multiple widths (e.g. condensed, expanded), opt to be
          // conservative and select the most standard width.
          //
          // If a specific width is desired, it should be be narrowed down via
          // the family name.
          //
          // The font weights are also sorted lightest to heaviest but Flutter
          // APIs have the weight specified to narrow it down later. The width
          // ordering here is more consequential since TextStyle doesn't have
          // letter width APIs.
          return a_delta < b_delta;
        } else if (a_style.width() != b_style.width()) {
          // However, if the 2 fonts are equidistant from the "normal" width,
          // just arbitrarily but consistently return the more condensed font.
          return a_style.width() < b_style.width();
        } else if (a_style.weight() != b_style.weight()) {
          return a_style.weight() < b_style.weight();
        } else {
          return a_style.slant() < b_style.slant();
        }
        // Use a cascade of conditions so results are consistent each time.
      });
}

std::shared_ptr<minikin::FontFamily> FontCollection::CreateMinikinFontFamily(
    const sk_sp<SkFontMgr>& manager,
    const std::string& family_name) {
  TRACE_EVENT1("flutter", "FontCollection::CreateMinikinFontFamily",
               "family_name", family_name.c_str());
  sk_sp<SkFontStyleSet> font_style_set(
      manager->matchFamily(family_name.c_str()));
  if (font_style_set == nullptr || font_style_set->count() == 0) {
    return nullptr;
  }

  std::vector<sk_sp<SkTypeface>> skia_typefaces;
  for (int i = 0; i < font_style_set->count(); ++i) {
    TRACE_EVENT0("flutter", "CreateSkiaTypeface");
    sk_sp<SkTypeface> skia_typeface(
        sk_sp<SkTypeface>(font_style_set->createTypeface(i)));
    if (skia_typeface != nullptr) {
      skia_typefaces.emplace_back(std::move(skia_typeface));
    }
  }

  SortSkTypefaces(skia_typefaces);

  std::vector<minikin::Font> minikin_fonts;
  for (const sk_sp<SkTypeface>& skia_typeface : skia_typefaces) {
    // Create the minikin font from the skia typeface.
    // Divide by 100 because the weights are given as "100", "200", etc.
    minikin_fonts.emplace_back(
        std::make_shared<FontSkia>(skia_typeface),
        minikin::FontStyle{skia_typeface->fontStyle().weight() / 100,
                           skia_typeface->isItalic()});
  }

  return std::make_shared<minikin::FontFamily>(std::move(minikin_fonts));
}

const std::shared_ptr<minikin::FontFamily>& FontCollection::MatchFallbackFont(
    uint32_t ch,
    std::string locale) {
  // Check if the ch's matched font has been cached. We cache the results of
  // this method as repeated matchFamilyStyleCharacter calls can become
  // extremely laggy when typing a large number of complex emojis.
  auto lookup = fallback_match_cache_.find(ch);
  if (lookup != fallback_match_cache_.end()) {
    return *lookup->second;
  }
  const std::shared_ptr<minikin::FontFamily>* match =
      &DoMatchFallbackFont(ch, locale);
  fallback_match_cache_.insert(std::make_pair(ch, match));
  return *match;
}

const std::shared_ptr<minikin::FontFamily>& FontCollection::DoMatchFallbackFont(
    uint32_t ch,
    std::string locale) {
  for (const sk_sp<SkFontMgr>& manager : GetFontManagerOrder()) {
    std::vector<const char*> bcp47;
    if (!locale.empty())
      bcp47.push_back(locale.c_str());
    sk_sp<SkTypeface> typeface(manager->matchFamilyStyleCharacter(
        0, SkFontStyle(), bcp47.data(), bcp47.size(), ch));
    if (!typeface)
      continue;

    SkString sk_family_name;
    typeface->getFamilyName(&sk_family_name);
    std::string family_name(sk_family_name.c_str());

    if (std::find(fallback_fonts_for_locale_[locale].begin(),
                  fallback_fonts_for_locale_[locale].end(),
                  family_name) == fallback_fonts_for_locale_[locale].end())
      fallback_fonts_for_locale_[locale].push_back(family_name);

    return GetFallbackFontFamily(manager, family_name);
  }
  return g_null_family;
}

const std::shared_ptr<minikin::FontFamily>&
FontCollection::GetFallbackFontFamily(const sk_sp<SkFontMgr>& manager,
                                      const std::string& family_name) {
  TRACE_EVENT0("flutter", "FontCollection::GetFallbackFontFamily");
  auto fallback_it = fallback_fonts_.find(family_name);
  if (fallback_it != fallback_fonts_.end()) {
    return fallback_it->second;
  }

  std::shared_ptr<minikin::FontFamily> minikin_family =
      CreateMinikinFontFamily(manager, family_name);
  if (!minikin_family)
    return g_null_family;

  auto insert_it =
      fallback_fonts_.insert(std::make_pair(family_name, minikin_family));

  // Clear the cache to force creation of new font collections that will
  // include this fallback font.
  font_collections_cache_.clear();

  return insert_it.first->second;
}

void FontCollection::ClearFontFamilyCache() {
  font_collections_cache_.clear();

#if FLUTTER_ENABLE_SKSHAPER
  if (skt_collection_) {
    skt_collection_->clearCaches();
  }
#endif
}

#if FLUTTER_ENABLE_SKSHAPER

sk_sp<skia::textlayout::FontCollection>
FontCollection::CreateSktFontCollection() {
  if (!skt_collection_) {
    skt_collection_ = sk_make_sp<skia::textlayout::FontCollection>();

    skt_collection_->setDefaultFontManager(default_font_manager_,
                                           GetDefaultFontFamilies()[0].c_str());
    skt_collection_->setAssetFontManager(asset_font_manager_);
    skt_collection_->setDynamicFontManager(dynamic_font_manager_);
    skt_collection_->setTestFontManager(test_font_manager_);
    if (!enable_font_fallback_) {
      skt_collection_->disableFontFallback();
    }
  }

  return skt_collection_;
}

#endif  // FLUTTER_ENABLE_SKSHAPER

}  // namespace txt
