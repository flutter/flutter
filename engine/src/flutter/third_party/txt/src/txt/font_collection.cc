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

#include "font_collection.h"

#include <list>
#include <memory>
#include <mutex>
#include <set>
#include <string>
#include <unordered_map>
#include <vector>

#include "font_skia.h"
#include "lib/ftl/logging.h"
#include "third_party/skia/include/core/SkString.h"
#include "third_party/skia/include/ports/SkFontMgr.h"
#include "third_party/skia/include/ports/SkFontMgr_android.h"
#include "third_party/skia/include/ports/SkFontMgr_directory.h"

namespace txt {
// TODO(garyq): Will be deprecated when full compatibility with Flutter Engine
// is complete.
FontCollection& FontCollection::GetFontCollection(std::string dir) {
  std::vector<std::string> dirs = {dir};
  return GetFontCollection(std::move(dirs));
}

// TODO(garyq): Will be deprecated when full compatibility with Flutter Engine
// is complete.
FontCollection& FontCollection::GetFontCollection(
    std::vector<std::string> dirs) {
  static FontCollection* collection = nullptr;
  static std::once_flag once;
  std::call_once(once, [dirs]() { collection = new FontCollection(dirs); });
  return *collection;
}

// TODO(garyq): Will be deprecated when full compatibility with Flutter Engine
// is complete.
FontCollection& FontCollection::GetDefaultFontCollection() {
  return GetFontCollection("");
}

FontCollection::FontCollection() {
  FontCollection("");
}

FontCollection::FontCollection(CacheMethod cache_method) {
  FontCollection("", cache_method);
}

FontCollection::FontCollection(std::string dir, CacheMethod cache_method) {
  std::vector<std::string> dirs = {dir};
  FontCollection(std::move(dirs), cache_method);
}

FontCollection::FontCollection(const std::vector<std::string>& dirs,
                               CacheMethod cache_method) {
  for (std::string dir : dirs) {
    if (dir.length() != 0) {
      AddFontMgr(dir, false);
    }
  }
  skia_font_managers_.push_back(SkFontMgr::RefDefault());

  DiscoverFamilyNames();

  cache_method_ = cache_method;
}

FontCollection::~FontCollection() = default;

void FontCollection::AddFontMgr(std::string dir, bool rediscover_family_names) {
#ifdef DIRECTORY_FONT_MANAGER_AVAILABLE
  // On Linux systems:
  skia_font_managers_.push_back(SkFontMgr_New_Custom_Directory(dir.c_str()));
#endif
#ifdef ANDROID_FONT_MANAGER_AVAILABLE
  // On Android:
  SkFontMgr_Android_CustomFonts android_custom_font_data;
  // Ensure the dir string is '/' terminated.
  if (dir.back() != '/')
    dir += '/';
  android_custom_font_data.fBasePath = dir.data();
  android_custom_font_data.fSystemFontUse =
      SkFontMgr_Android_CustomFonts::SystemFontUse::kOnlyCustom;
  skia_font_managers_.push_back(
      SkFontMgr_New_Android(&android_custom_font_data));
#endif

  if (rediscover_family_names)
    DiscoverFamilyNames(skia_font_managers_.back());
}

void FontCollection::AddFontMgr(sk_sp<SkFontMgr> font_mgr,
                                bool rediscover_family_names) {
  skia_font_managers_.push_back(font_mgr);
  if (rediscover_family_names)
    DiscoverFamilyNames(font_mgr);
}

void FontCollection::DiscoverFamilyNames() {
  for (sk_sp<SkFontMgr> mgr : skia_font_managers_) {
    DiscoverFamilyNames(mgr);
  }
}

void FontCollection::DiscoverFamilyNames(sk_sp<SkFontMgr> mgr) {
  SkString str;
  for (int i = 0; i < mgr->countFamilies(); i++) {
    mgr->getFamilyName(i, &str);
    family_names_.insert(std::string{str.writable_str()});
  }
}

std::set<std::string> FontCollection::GetFamilyNames() {
  return family_names_;
}

bool FontCollection::HasFamily(const std::string family) const {
  return family_names_.count(family) == 1;
}

void FontCollection::FlushCache() {
  minikin_font_collection_map_.clear();
  lru_tracker_.clear();
}

void FontCollection::SetCacheCapacity(const size_t cap) {
  cache_capacity_ = cap;
}

void FontCollection::SetLowMemoryMode(bool mode, size_t cap) {
  cache_capacity_ = cap;
  if (mode) {
    cache_method_ = CacheMethod::kLRU;
    TrimCache();
  } else {
    cache_method_ = CacheMethod::kUnlimited;
  }
}

void FontCollection::TrimCache() {
  while (minikin_font_collection_map_.size() > cache_capacity_) {
    std::string family_to_evict = lru_tracker_.back();
    lru_tracker_.pop_back();
    minikin_font_collection_map_.erase(family_to_evict);
  }
}

const std::string FontCollection::ProcessFamilyName(const std::string& family) {
#ifdef DIRECTORY_FONT_MANAGER_AVAILABLE
  return family.length() == 0 ? DEFAULT_FAMILY_NAME : family;
#else
  if (family.length() > 0 &&
      GetFamilyNames().count(family) > 0) {  // Ensure family exists.
    return family;
  } else {
    if (GetFamilyNames().count(DEFAULT_FAMILY_NAME) > 0) {
      return DEFAULT_FAMILY_NAME;
    }
    return *GetFamilyNames().begin();  // First family available.
  }
#endif
}

std::shared_ptr<minikin::FontCollection>
FontCollection::GetMinikinFontCollectionForFamily(const std::string& family) {
  FTL_DCHECK(skia_font_managers_.size() > 0);
  std::string processed_family_name = ProcessFamilyName(family);
  // Only obtain new font family if the font has changed between runs.
  if (cache_method_ == CacheMethod::kNone ||
      minikin_font_collection_map_.count(processed_family_name) == 0) {
    // Ask Skia to resolve a font style set for a font family name.
    // FIXME(chinmaygarde): CoreText crashes when passed a null string. This
    // seems to be a bug in Skia as SkFontMgr explicitly says passing in
    // nullptr gives the default font.
    for (sk_sp<SkFontMgr> mgr : skia_font_managers_) {
      FTL_DCHECK(mgr != nullptr);
      auto font_style_set = mgr->matchFamily(processed_family_name.c_str());
      if (font_style_set != nullptr) {
        std::vector<minikin::Font> minikin_fonts;

        // Add fonts to the Minikin font family.
        for (int i = 0, style_count = font_style_set->count(); i < style_count;
             ++i) {
          // Create the skia typeface
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

        // Create a vector of font families for the Minkin font collection. For
        // now, we only have one family in our collection.
        std::vector<std::shared_ptr<minikin::FontFamily>> minikin_families = {
            minikin_family,
        };

        // Assign the font collection.
        minikin_font_collection_map_[processed_family_name] =
            std::make_shared<minikin::FontCollection>(minikin_families);
        return minikin_font_collection_map_[processed_family_name];
      }
    }
    // Uh oh! Font family not found in any of the font managers!
    minikin_font_collection_map_[processed_family_name] = nullptr;
  }

  // Maintain LRU and evict old fonts no longer used.

  lru_tracker_.remove(processed_family_name);
  lru_tracker_.push_front(processed_family_name);
  if (cache_method_ == CacheMethod::kLRU) {
    TrimCache();
  }

  return minikin_font_collection_map_[processed_family_name];
}

}  // namespace txt
