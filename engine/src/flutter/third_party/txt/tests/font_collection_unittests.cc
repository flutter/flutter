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

#include "flutter/fml/command_line.h"
#include "flutter/fml/logging.h"
#include "gtest/gtest.h"
#include "txt/font_collection.h"
#include "txt_test_utils.h"

namespace txt {

#if 0

TEST(FontCollection, HasDefaultRegistrations) {
  std::string defaultFamilyName = txt::FontCollection::GetDefaultFamilyName();

  auto collection = txt::FontCollection::GetFontCollection(txt::GetFontDir())
                        .GetMinikinFontCollectionForFamily("");
  ASSERT_EQ(defaultFamilyName,
            txt::FontCollection::GetFontCollection(txt::GetFontDir())
                .ProcessFamilyName(""));
  ASSERT_NE(defaultFamilyName,
            txt::FontCollection::GetFontCollection(txt::GetFontDir())
                .ProcessFamilyName("NotARealFont!"));
  ASSERT_EQ("NotARealFont!",
            txt::FontCollection::GetFontCollection(txt::GetFontDir())
                .ProcessFamilyName("NotARealFont!"));
  ASSERT_NE(collection.get(), nullptr);
}

TEST(FontCollection, GetMinikinFontCollections) {
  std::string defaultFamilyName = txt::FontCollection::GetDefaultFamilyName();

  auto collectionDef = txt::FontCollection::GetFontCollection(txt::GetFontDir())
                           .GetMinikinFontCollectionForFamily("");
  auto collectionRoboto =
      txt::FontCollection::GetFontCollection(txt::GetFontDir())
          .GetMinikinFontCollectionForFamily("Roboto");
  auto collectionHomemadeApple =
      txt::FontCollection::GetFontCollection(txt::GetFontDir())
          .GetMinikinFontCollectionForFamily("Homemade Apple");
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
      txt::FontCollection::GetFontCollection(txt::GetFontDir())
          .GetFamilyNames();

  ASSERT_TRUE(names.size() >= 19ull);

  ASSERT_EQ(names.count("Roboto"), 1ull);
  ASSERT_EQ(names.count("Homemade Apple"), 1ull);

  ASSERT_EQ(names.count("KoreanFont Test"), 1ull);
  ASSERT_EQ(names.count("JapaneseFont Test"), 1ull);
  ASSERT_EQ(names.count("EmojiFont Test"), 1ull);
  ASSERT_EQ(names.count("ItalicFont Test"), 1ull);
  ASSERT_EQ(names.count("VariationSelector Test"), 1ull);
  ASSERT_EQ(names.count("ColorEmojiFont Test"), 1ull);
  ASSERT_EQ(names.count("TraditionalChinese Test"), 1ull);
  ASSERT_EQ(names.count("Sample Font"), 1ull);
  ASSERT_EQ(names.count("MultiAxisFont Test"), 1ull);
  ASSERT_EQ(names.count("TextEmojiFont Test"), 1ull);
  ASSERT_EQ(names.count("No Cmap Format 14 Subtable Test"), 1ull);
  ASSERT_EQ(names.count("ColorTextMixedEmojiFont Test"), 1ull);
  ASSERT_EQ(names.count("BoldFont Test"), 1ull);
  ASSERT_EQ(names.count("EmptyFont Test"), 1ull);
  ASSERT_EQ(names.count("SimplifiedChinese Test"), 1ull);
  ASSERT_EQ(names.count("BoldItalicFont Test"), 1ull);
  ASSERT_EQ(names.count("RegularFont Test"), 1ull);

  ASSERT_EQ(names.count("Not a real font!"), 0ull);
  ASSERT_EQ(names.count(""), 0ull);
  ASSERT_EQ(names.count("Another Fake Font"), 0ull);
}

#endif  // 0

}  // namespace txt
