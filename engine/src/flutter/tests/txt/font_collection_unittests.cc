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
#include "gtest/gtest.h"
#include "lib/ftl/command_line.h"
#include "lib/ftl/logging.h"
#include "lib/txt/tests/txt/utils.h"

namespace txt {

TEST(FontCollection, HasDefaultRegistrations) {
  std::string defaultFamilyName = txt::FontCollection::GetDefaultFamilyName();

  auto collection =
      txt::FontCollection::GetDefaultFontCollection()
          .GetMinikinFontCollectionForFamily("", txt::GetFontDir());
  ASSERT_EQ(
      defaultFamilyName,
      txt::FontCollection::GetDefaultFontCollection().ProcessFamilyName(""));
  ASSERT_NE(defaultFamilyName,
            txt::FontCollection::GetDefaultFontCollection().ProcessFamilyName(
                "NotARealFont!"));
  ASSERT_EQ("NotARealFont!",
            txt::FontCollection::GetDefaultFontCollection().ProcessFamilyName(
                "NotARealFont!"));
  ASSERT_NE(collection.get(), nullptr);
}

TEST(FontCollection, GetMinikinFontCollections) {
  std::string defaultFamilyName = txt::FontCollection::GetDefaultFamilyName();

  auto collectionDef =
      txt::FontCollection::GetDefaultFontCollection()
          .GetMinikinFontCollectionForFamily("", txt::GetFontDir());
  auto collectionRoboto =
      txt::FontCollection::GetDefaultFontCollection()
          .GetMinikinFontCollectionForFamily("Roboto", txt::GetFontDir());
  auto collectionHomemadeApple = txt::FontCollection::GetDefaultFontCollection()
                                     .GetMinikinFontCollectionForFamily(
                                         "Homemade Apple", txt::GetFontDir());
  for (size_t base = 0; base < 50; base++) {
    for (size_t variation = 0; variation < 50; variation++) {
      ASSERT_EQ(collectionDef->hasVariationSelector(base, variation),
                collectionRoboto->hasVariationSelector(base, variation));
    }
  }

  ASSERT_NE(collectionDef, collectionHomemadeApple);
  ASSERT_NE(collectionHomemadeApple, collectionRoboto);
  ASSERT_NE(collectionDef.get(), nullptr);
}

TEST(FontCollection, GetFamilyNames) {
  std::set<std::string> names =
      txt::FontCollection::GetFamilyNames(txt::GetFontDir());

  ASSERT_EQ(names.size(), 19ull);
}

}  // namespace txt