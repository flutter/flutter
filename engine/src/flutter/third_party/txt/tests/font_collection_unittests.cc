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

#include "flutter/fml/logging.h"
#include "gtest/gtest.h"
#include "third_party/skia/include/utils/SkCustomTypeface.h"
#include "txt/font_collection.h"
#include "txt_test_utils.h"

namespace txt {

// We don't really need a fixture but a class in a namespace is needed for
// the FRIEND_TEST macro.
class FontCollectionTest : public ::testing::Test {};

namespace {
// This function does some boilerplate to fill a builder with enough real
// font-like data. Otherwise, detach won't actually build an SkTypeface.
void PopulateUserTypefaceBoilerplate(SkCustomTypefaceBuilder* builder) {
  constexpr float upem = 200;

  {
    SkFontMetrics metrics;
    metrics.fFlags = 0;
    metrics.fTop = -200;
    metrics.fAscent = -150;
    metrics.fDescent = 50;
    metrics.fBottom = -75;
    metrics.fLeading = 10;
    metrics.fAvgCharWidth = 150;
    metrics.fMaxCharWidth = 300;
    metrics.fXMin = -20;
    metrics.fXMax = 290;
    metrics.fXHeight = -100;
    metrics.fCapHeight = 0;
    metrics.fUnderlineThickness = 5;
    metrics.fUnderlinePosition = 2;
    metrics.fStrikeoutThickness = 5;
    metrics.fStrikeoutPosition = -50;
    builder->setMetrics(metrics, 1.0f / upem);
  }

  const SkMatrix scale = SkMatrix::Scale(1.0f / upem, 1.0f / upem);
  for (SkGlyphID index = 0; index <= 67; ++index) {
    SkScalar width;
    width = 100;
    SkPath path;
    path.addCircle(50, -50, 75);

    builder->setGlyph(index, width / upem, path.makeTransform(scale));
  }
}
}  // namespace

TEST(FontCollectionTest, CheckSkTypefacesSorting) {
  // We have to make a real SkTypeface here. Not all the structs from the
  // SkTypeface headers are fully declared to be able to gmock.
  // SkCustomTypefaceBuilder is the simplest way to get a simple SkTypeface.
  SkCustomTypefaceBuilder typefaceBuilder1;
  typefaceBuilder1.setFontStyle(SkFontStyle(SkFontStyle::kThin_Weight,
                                            SkFontStyle::kExpanded_Width,
                                            SkFontStyle::kItalic_Slant));
  // For the purpose of this test, we need to fill this to make the SkTypeface
  // build but it doesn't matter. We only care about the SkFontStyle.
  PopulateUserTypefaceBoilerplate(&typefaceBuilder1);
  sk_sp<SkTypeface> typeface1{typefaceBuilder1.detach()};

  SkCustomTypefaceBuilder typefaceBuilder2;
  typefaceBuilder2.setFontStyle(SkFontStyle(SkFontStyle::kLight_Weight,
                                            SkFontStyle::kNormal_Width,
                                            SkFontStyle::kUpright_Slant));
  PopulateUserTypefaceBoilerplate(&typefaceBuilder2);
  sk_sp<SkTypeface> typeface2{typefaceBuilder2.detach()};

  SkCustomTypefaceBuilder typefaceBuilder3;
  typefaceBuilder3.setFontStyle(SkFontStyle(SkFontStyle::kNormal_Weight,
                                            SkFontStyle::kNormal_Width,
                                            SkFontStyle::kUpright_Slant));
  PopulateUserTypefaceBoilerplate(&typefaceBuilder3);
  sk_sp<SkTypeface> typeface3{typefaceBuilder3.detach()};

  SkCustomTypefaceBuilder typefaceBuilder4;
  typefaceBuilder4.setFontStyle(SkFontStyle(SkFontStyle::kThin_Weight,
                                            SkFontStyle::kCondensed_Width,
                                            SkFontStyle::kUpright_Slant));
  PopulateUserTypefaceBoilerplate(&typefaceBuilder4);
  sk_sp<SkTypeface> typeface4{typefaceBuilder4.detach()};

  std::vector<sk_sp<SkTypeface>> candidateTypefaces = {typeface1, typeface2,
                                                       typeface3, typeface4};

  // This sorts the vector in-place.
  txt::FontCollection::SortSkTypefaces(candidateTypefaces);

  // The second one is first because it's both the most normal width font
  // with the lightest weight.
  ASSERT_EQ(candidateTypefaces[0].get(), typeface2.get());
  // Then the most normal width font with normal weight.
  ASSERT_EQ(candidateTypefaces[1].get(), typeface3.get());
  // Then a less normal (condensed) width font.
  ASSERT_EQ(candidateTypefaces[2].get(), typeface4.get());
  // All things equal, 4 came before 1 because we arbitrarily chose to make the
  // narrower font come first.
  ASSERT_EQ(candidateTypefaces[3].get(), typeface1.get());

  // Double check.
  ASSERT_EQ(candidateTypefaces[0]->fontStyle().weight(),
            SkFontStyle::kLight_Weight);
  ASSERT_EQ(candidateTypefaces[0]->fontStyle().width(),
            SkFontStyle::kNormal_Width);

  ASSERT_EQ(candidateTypefaces[1]->fontStyle().weight(),
            SkFontStyle::kNormal_Weight);
  ASSERT_EQ(candidateTypefaces[1]->fontStyle().width(),
            SkFontStyle::kNormal_Width);

  ASSERT_EQ(candidateTypefaces[2]->fontStyle().weight(),
            SkFontStyle::kThin_Weight);
  ASSERT_EQ(candidateTypefaces[2]->fontStyle().width(),
            SkFontStyle::kCondensed_Width);

  ASSERT_EQ(candidateTypefaces[3]->fontStyle().weight(),
            SkFontStyle::kThin_Weight);
  ASSERT_EQ(candidateTypefaces[3]->fontStyle().width(),
            SkFontStyle::kExpanded_Width);
}

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
