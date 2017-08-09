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

#ifndef LIB_TXT_SRC_FONT_COLLECTION_H_
#define LIB_TXT_SRC_FONT_COLLECTION_H_

#define DEFAULT_FAMILY_NAME "Roboto"
#ifdef ANDROID_FONT_MANAGER_AVAILABLE
#undef DEFAULT_FAMILY_NAME
// On Android, Roboto is called 'sans-serif'
#define DEFAULT_FAMILY_NAME "sans-serif"
#endif

#define DEFAULT_CACHE_CAPACITY 20

#include <list>
#include <memory>
#include <set>
#include <string>
#include <unordered_map>
#include <vector>

#include "lib/ftl/macros.h"
#include "minikin/FontCollection.h"
#include "minikin/FontFamily.h"
#include "third_party/gtest/include/gtest/gtest_prod.h"
#include "third_party/skia/include/core/SkRefCnt.h"
#include "third_party/skia/include/ports/SkFontMgr.h"

namespace txt {

// FontCollection holds a vector of Skia Font Managers and handles font
// fallback. If no additional font directories are provided, then only the
// default font directory will be available.
class FontCollection {
 public:
  enum CacheMethod {
    kNone,
    kLRU,  // Least Recently Used.
    kUnlimited,
  };
  // TODO(garyq): Will be deprecated when full compatibility with Flutter Engine
  // is complete.
  static FontCollection& GetDefaultFontCollection();

  // TODO(garyq): Will be deprecated when full compatibility with Flutter Engine
  // is complete..
  static FontCollection& GetFontCollection(std::string dir = "");

  // TODO(garyq): Will be deprecated when full compatibility with Flutter Engine
  // is complete.
  static FontCollection& GetFontCollection(std::vector<std::string> dirs);

  // Provides a pointer to the minikin FontCollection for the given font family.
  // If the famly is not in any font manager, this will return a nullptr. Once a
  // font is loaded, it is cached and future calls will be very efficient
  // (until/if the font is flushed).
  std::shared_ptr<minikin::FontCollection> GetMinikinFontCollectionForFamily(
      const std::string& family);

  FontCollection(const std::vector<std::string>& dirs,
                 CacheMethod cache_method = CacheMethod::kUnlimited);

  FontCollection(std::string dir,
                 CacheMethod cache_method = CacheMethod::kUnlimited);

  FontCollection(CacheMethod cache_method);

  FontCollection();

  ~FontCollection();

  // Provides a set of all available family names.
  std::set<std::string> GetFamilyNames();

  // Returns true when the supplied font family exists in any of the font
  // managers.
  bool HasFamily(const std::string family) const;

  // Adds a new SkFontMgr to the front of the stack of font managers.
  void AddFontMgr(std::string dir, bool rediscover_family_names = true);

  // Adds the provided SkFontMgr to the front of the stack of font managers.
  void AddFontMgr(sk_sp<SkFontMgr> font_mgr,
                  bool rediscover_family_names = true);

  // Removes all fonts that do not fit in the cache capacity from memory.
  void FlushCache();

  // When in LRU mode, the cache will only hold the <cap> most recently used
  // fonts. This may be used when the application becomes low on memory or a
  // very large number of fonts are used.
  void SetCacheCapacity(const size_t cap);

  // Call this to limit memory usage by cached fonts. SetLowMemoryMode() will
  // enable default LRU policy and flush fonts beyond capacity.
  void SetLowMemoryMode(bool mode = true, size_t cap = DEFAULT_CACHE_CAPACITY);

 private:
  std::vector<sk_sp<SkFontMgr>> skia_font_managers_;
  // Cache the names because GetFamilyNames() can be frequently called.
  std::set<std::string> family_names_;
  CacheMethod cache_method_ = CacheMethod::kUnlimited;
  std::list<std::string> lru_tracker_;
  size_t cache_capacity_ = DEFAULT_CACHE_CAPACITY;

  // Cache minikin font collections to prevent slow disk reads.
  std::unordered_map<std::string, std::shared_ptr<minikin::FontCollection>>
      minikin_font_collection_map_;

  FRIEND_TEST(FontCollection, HasDefaultRegistrations);
  FRIEND_TEST(FontCollection, GetMinikinFontCollections);
  FRIEND_TEST(FontCollection, GetFamilyNames);

  // Postprocess the family name to handle the following properties: fallback
  // when not found and reverting to the default name when no fallback is found.
  const std::string ProcessFamilyName(const std::string& family);

  // Polls all of the SkFontMgrs to obtain a set of all available font family
  // names.
  void DiscoverFamilyNames();

  // Add the family names of mgr to set of available font family names.
  void DiscoverFamilyNames(sk_sp<SkFontMgr> mgr);

  void TrimCache();

  static const std::string GetDefaultFamilyName() {
    return DEFAULT_FAMILY_NAME;
  };
};

}  // namespace txt

#endif  // LIB_TXT_SRC_FONT_COLLECTION_H_
