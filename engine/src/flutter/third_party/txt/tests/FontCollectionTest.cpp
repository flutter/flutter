/*
 * Copyright (C) 2015 The Android Open Source Project
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

#include <gtest/gtest.h>

#include <minikin/FontCollection.h>
#include "FontTestUtils.h"
#include "MinikinFontForTest.h"
#include "minikin/MinikinInternal.h"

namespace minikin {

// The test font has following glyphs.
// U+82A6
// U+82A6 U+FE00 (VS1)
// U+82A6 U+E0100 (VS17)
// U+82A6 U+E0101 (VS18)
// U+82A6 U+E0102 (VS19)
// U+845B
// U+845B U+FE01 (VS2)
// U+845B U+E0101 (VS18)
// U+845B U+E0102 (VS19)
// U+845B U+E0103 (VS20)
// U+537F
// U+717D U+FE02 (VS3)
// U+717D U+E0102 (VS19)
// U+717D U+E0103 (VS20)
const char kVsTestFont[] = kTestFontDir "/VariationSelectorTest-Regular.ttf";

void expectVSGlyphs(const FontCollection* fc,
                    uint32_t codepoint,
                    const std::set<uint32_t>& vsSet) {
  for (uint32_t vs = 0xFE00; vs <= 0xE01EF; ++vs) {
    // Move to variation selectors supplements after variation selectors.
    if (vs == 0xFF00) {
      vs = 0xE0100;
    }
    if (vsSet.find(vs) == vsSet.end()) {
      EXPECT_FALSE(fc->hasVariationSelector(codepoint, vs))
          << "Glyph for U+" << std::hex << codepoint << " U+" << vs;
    } else {
      EXPECT_TRUE(fc->hasVariationSelector(codepoint, vs))
          << "Glyph for U+" << std::hex << codepoint << " U+" << vs;
    }
  }
}

TEST(FontCollectionTest, hasVariationSelectorTest) {
  std::shared_ptr<MinikinFont> font(new MinikinFontForTest(kVsTestFont));
  std::shared_ptr<FontFamily> family(
      new FontFamily(std::vector<Font>({Font(font, FontStyle())})));
  std::vector<std::shared_ptr<FontFamily>> families({family});
  std::shared_ptr<FontCollection> fc(new FontCollection(families));

  EXPECT_FALSE(fc->hasVariationSelector(0x82A6, 0));
  expectVSGlyphs(
      fc.get(), 0x82A6,
      std::set<uint32_t>({0xFE00, 0xFE0E, 0xE0100, 0xE0101, 0xE0102}));

  EXPECT_FALSE(fc->hasVariationSelector(0x845B, 0));
  expectVSGlyphs(
      fc.get(), 0x845B,
      std::set<uint32_t>({0xFE01, 0xFE0E, 0xE0101, 0xE0102, 0xE0103}));

  EXPECT_FALSE(fc->hasVariationSelector(0x537F, 0));
  expectVSGlyphs(fc.get(), 0x537F, std::set<uint32_t>({0xFE0E}));

  EXPECT_FALSE(fc->hasVariationSelector(0x717D, 0));
  expectVSGlyphs(fc.get(), 0x717D,
                 std::set<uint32_t>({0xFE02, 0xE0102, 0xE0103}));
}

const char kEmojiXmlFile[] = kTestFontDir "emoji.xml";

TEST(FontCollectionTest, hasVariationSelectorTest_emoji) {
  std::shared_ptr<FontCollection> collection(
      getFontCollection(kTestFontDir, kEmojiXmlFile));

  // Both text/color font have cmap format 14 subtable entry for VS15/VS16
  // respectively.
  EXPECT_TRUE(collection->hasVariationSelector(0x2623, 0xFE0E));
  EXPECT_TRUE(collection->hasVariationSelector(0x2623, 0xFE0F));

  // The text font has cmap format 14 subtable entry for VS15 but the color font
  // doesn't have for VS16
  EXPECT_TRUE(collection->hasVariationSelector(0x2626, 0xFE0E));
  EXPECT_FALSE(collection->hasVariationSelector(0x2626, 0xFE0F));

  // The color font has cmap format 14 subtable entry for VS16 but the text font
  // doesn't have for VS15.
  EXPECT_TRUE(collection->hasVariationSelector(0x262A, 0xFE0E));
  EXPECT_TRUE(collection->hasVariationSelector(0x262A, 0xFE0F));

  // Neither text/color font have cmap format 14 subtable entry for VS15/VS16.
  EXPECT_TRUE(collection->hasVariationSelector(0x262E, 0xFE0E));
  EXPECT_FALSE(collection->hasVariationSelector(0x262E, 0xFE0F));

  // Text font doesn't support U+1F3FD. Only the color emoji fonts has. So VS15
  // is not supported.
  EXPECT_FALSE(collection->hasVariationSelector(0x1F3FD, 0xFE0E));

  // Text font doesn't have U+262F U+FE0E or even its base code point U+262F.
  EXPECT_FALSE(collection->hasVariationSelector(0x262F, 0xFE0E));

  // None of the fonts support U+2229.
  EXPECT_FALSE(collection->hasVariationSelector(0x2229, 0xFE0E));
  EXPECT_FALSE(collection->hasVariationSelector(0x2229, 0xFE0F));
}

TEST(FontCollectionTest, newEmojiTest) {
  std::shared_ptr<FontCollection> collection(
      getFontCollection(kTestFontDir, kEmojiXmlFile));

  // U+2695, U+2640, U+2642 are not in emoji catrgory in Unicode 9 but they are
  // now in emoji category. Should return true even if U+FE0E was appended.
  // These three emojis are only avalilable in TextEmoji.ttf but U+2695 is
  // excluded here since it is used in other tests.
  EXPECT_TRUE(collection->hasVariationSelector(0x2640, 0xFE0E));
  EXPECT_FALSE(collection->hasVariationSelector(0x2640, 0xFE0F));
  EXPECT_TRUE(collection->hasVariationSelector(0x2642, 0xFE0E));
  EXPECT_FALSE(collection->hasVariationSelector(0x2642, 0xFE0F));
}

TEST(FontCollectionTest, createWithVariations) {
  // This font has 'wdth' and 'wght' axes.
  const char kMultiAxisFont[] = kTestFontDir "/MultiAxis.ttf";
  const char kNoAxisFont[] = kTestFontDir "/Regular.ttf";

  std::shared_ptr<MinikinFont> multiAxisFont(
      new MinikinFontForTest(kMultiAxisFont));
  std::shared_ptr<FontFamily> multiAxisFamily(
      new FontFamily(std::vector<Font>({Font(multiAxisFont, FontStyle())})));
  std::vector<std::shared_ptr<FontFamily>> multiAxisFamilies({multiAxisFamily});
  std::shared_ptr<FontCollection> multiAxisFc(
      new FontCollection(multiAxisFamilies));

  std::shared_ptr<MinikinFont> noAxisFont(new MinikinFontForTest(kNoAxisFont));
  std::shared_ptr<FontFamily> noAxisFamily(
      new FontFamily(std::vector<Font>({Font(noAxisFont, FontStyle())})));
  std::vector<std::shared_ptr<FontFamily>> noAxisFamilies({noAxisFamily});
  std::shared_ptr<FontCollection> noAxisFc(new FontCollection(noAxisFamilies));

  {
    // Do not ceate new instance if none of variations are specified.
    EXPECT_EQ(nullptr, multiAxisFc->createCollectionWithVariation(
                           std::vector<FontVariation>()));
    EXPECT_EQ(nullptr, noAxisFc->createCollectionWithVariation(
                           std::vector<FontVariation>()));
  }
  {
    // New instance should be used for supported variation.
    std::vector<FontVariation> variations = {
        {MinikinFont::MakeTag('w', 'd', 't', 'h'), 1.0f}};
    std::shared_ptr<FontCollection> newFc(
        multiAxisFc->createCollectionWithVariation(variations));
    EXPECT_NE(nullptr, newFc.get());
    EXPECT_NE(multiAxisFc.get(), newFc.get());

    EXPECT_EQ(nullptr, noAxisFc->createCollectionWithVariation(variations));
  }
  {
    // New instance should be used for supported variation (multiple variations
    // case).
    std::vector<FontVariation> variations = {
        {MinikinFont::MakeTag('w', 'd', 't', 'h'), 1.0f},
        {MinikinFont::MakeTag('w', 'g', 'h', 't'), 1.0f}};
    std::shared_ptr<FontCollection> newFc(
        multiAxisFc->createCollectionWithVariation(variations));
    EXPECT_NE(nullptr, newFc.get());
    EXPECT_NE(multiAxisFc.get(), newFc.get());

    EXPECT_EQ(nullptr, noAxisFc->createCollectionWithVariation(variations));
  }
  {
    // Do not ceate new instance if none of variations are supported.
    std::vector<FontVariation> variations = {
        {MinikinFont::MakeTag('Z', 'Z', 'Z', 'Z'), 1.0f}};
    EXPECT_EQ(nullptr, multiAxisFc->createCollectionWithVariation(variations));
    EXPECT_EQ(nullptr, noAxisFc->createCollectionWithVariation(variations));
  }
  {
    // At least one axis is supported, should create new instance.
    std::vector<FontVariation> variations = {
        {MinikinFont::MakeTag('w', 'd', 't', 'h'), 1.0f},
        {MinikinFont::MakeTag('Z', 'Z', 'Z', 'Z'), 1.0f}};
    std::shared_ptr<FontCollection> newFc(
        multiAxisFc->createCollectionWithVariation(variations));
    EXPECT_NE(nullptr, newFc.get());
    EXPECT_NE(multiAxisFc.get(), newFc.get());

    EXPECT_EQ(nullptr, noAxisFc->createCollectionWithVariation(variations));
  }
}

}  // namespace minikin
