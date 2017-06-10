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

#include <memory>
#include <set>
#include <string>
#include <vector>

#include "lib/ftl/macros.h"
#include "minikin/FontCollection.h"
#include "minikin/FontFamily.h"
#include "third_party/gtest/include/gtest/gtest_prod.h"
#include "third_party/skia/include/core/SkRefCnt.h"
#include "third_party/skia/include/ports/SkFontMgr.h"

namespace txt {

class FontCollection {
 public:
  static FontCollection& GetDefaultFontCollection();

  std::shared_ptr<minikin::FontCollection> GetMinikinFontCollectionForFamily(
      const std::string& family,
      const std::string& dir = "");

  // Provides a set of all available family names.
  std::set<std::string> GetFamilyNames(const std::string& dir = "");

 private:
  sk_sp<SkFontMgr> skia_font_manager_;

  FRIEND_TEST(FontCollection, HasDefaultRegistrations);
  FRIEND_TEST(FontCollection, GetMinikinFontCollections);
  FRIEND_TEST(FontCollection, GetFamilyNames);

  const std::string ProcessFamilyName(const std::string& family);

  static const std::string GetDefaultFamilyName() {
    return DEFAULT_FAMILY_NAME;
  };

  FontCollection();

  ~FontCollection();

  // TODO(chinmaygarde): Caches go here.
  FTL_DISALLOW_COPY_AND_ASSIGN(FontCollection);
};

}  // namespace txt

#endif  // LIB_TXT_SRC_FONT_COLLECTION_H_
