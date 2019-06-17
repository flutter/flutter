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

#include <memory>

#include "FontTestUtils.h"
#include "ICUTestBase.h"
#include "MinikinFontForTest.h"
#include "UnicodeUtils.h"
#include "minikin/FontFamily.h"
#include "minikin/FontLanguage.h"
#include "minikin/FontLanguageListCache.h"
#include "minikin/MinikinInternal.h"

namespace minikin {

const char kItemizeFontXml[] = kTestFontDir "itemize.xml";
const char kEmojiFont[] = kTestFontDir "Emoji.ttf";
const char kJAFont[] = kTestFontDir "Ja.ttf";
const char kKOFont[] = kTestFontDir "Ko.ttf";
const char kLatinBoldFont[] = kTestFontDir "Bold.ttf";
const char kLatinBoldItalicFont[] = kTestFontDir "BoldItalic.ttf";
const char kLatinFont[] = kTestFontDir "Regular.ttf";
const char kLatinItalicFont[] = kTestFontDir "Italic.ttf";
const char kZH_HansFont[] = kTestFontDir "ZhHans.ttf";
const char kZH_HantFont[] = kTestFontDir "ZhHant.ttf";

const char kEmojiXmlFile[] = kTestFontDir "emoji.xml";
const char kNoGlyphFont[] = kTestFontDir "NoGlyphFont.ttf";
const char kColorEmojiFont[] = kTestFontDir "ColorEmojiFont.ttf";
const char kTextEmojiFont[] = kTestFontDir "TextEmojiFont.ttf";
const char kMixedEmojiFont[] = kTestFontDir "ColorTextMixedEmojiFont.ttf";

const char kHasCmapFormat14Font[] = kTestFontDir "NoCmapFormat14.ttf";
const char kNoCmapFormat14Font[] =
    kTestFontDir "VariationSelectorTest-Regular.ttf";

typedef ICUTestBase FontCollectionItemizeTest;

// Utility function for calling itemize function.
void itemize(const std::shared_ptr<FontCollection>& collection,
             const char* str,
             FontStyle style,
             std::vector<FontCollection::Run>* result) {
  const size_t BUF_SIZE = 256;
  uint16_t buf[BUF_SIZE];
  size_t len;

  result->clear();
  ParseUnicode(buf, BUF_SIZE, str, &len, NULL);
  std::scoped_lock _l(gMinikinLock);
  collection->itemize(buf, len, style, result);
}

// Utility function to obtain font path associated with run.
const std::string& getFontPath(const FontCollection::Run& run) {
  EXPECT_NE(nullptr, run.fakedFont.font);
  return ((MinikinFontForTest*)run.fakedFont.font)->fontPath();
}

// Utility function to obtain FontLanguages from string.
const FontLanguages& registerAndGetFontLanguages(
    const std::string& lang_string) {
  std::scoped_lock _l(gMinikinLock);
  return FontLanguageListCache::getById(
      FontLanguageListCache::getId(lang_string));
}

TEST_F(FontCollectionItemizeTest, itemize_latin) {
  std::shared_ptr<FontCollection> collection(
      getFontCollection(kTestFontDir, kItemizeFontXml));
  std::vector<FontCollection::Run> runs;

  const FontStyle kRegularStyle = FontStyle();
  const FontStyle kItalicStyle = FontStyle(4, true);
  const FontStyle kBoldStyle = FontStyle(7, false);
  const FontStyle kBoldItalicStyle = FontStyle(7, true);

  itemize(collection, "'a' 'b' 'c' 'd' 'e'", kRegularStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(5, runs[0].end);
  EXPECT_EQ(kLatinFont, getFontPath(runs[0]));
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

  itemize(collection, "'a' 'b' 'c' 'd' 'e'", kItalicStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(5, runs[0].end);
  EXPECT_EQ(kLatinItalicFont, getFontPath(runs[0]));
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

  itemize(collection, "'a' 'b' 'c' 'd' 'e'", kBoldStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(5, runs[0].end);
  EXPECT_EQ(kLatinBoldFont, getFontPath(runs[0]));
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

  itemize(collection, "'a' 'b' 'c' 'd' 'e'", kBoldItalicStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(5, runs[0].end);
  EXPECT_EQ(kLatinBoldItalicFont, getFontPath(runs[0]));
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

  // Continue if the specific characters (e.g. hyphen, comma, etc.) is
  // followed.
  itemize(collection, "'a' ',' '-' 'd' '!'", kRegularStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(5, runs[0].end);
  EXPECT_EQ(kLatinFont, getFontPath(runs[0]));
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

  itemize(collection, "'a' ',' '-' 'd' '!'", kRegularStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(5, runs[0].end);
  EXPECT_EQ(kLatinFont, getFontPath(runs[0]));
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

  // U+0301(COMBINING ACUTE ACCENT) must be in the same run with preceding
  // chars if the font supports it.
  itemize(collection, "'a' U+0301", kRegularStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kLatinFont, getFontPath(runs[0]));
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());
}

TEST_F(FontCollectionItemizeTest, itemize_emoji) {
  std::shared_ptr<FontCollection> collection(
      getFontCollection(kTestFontDir, kItemizeFontXml));
  std::vector<FontCollection::Run> runs;

  itemize(collection, "U+1F469 U+1F467", FontStyle(), &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(4, runs[0].end);
  EXPECT_EQ(kEmojiFont, getFontPath(runs[0]));
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

  // U+20E3(COMBINING ENCLOSING KEYCAP) must be in the same run with preceding
  // character if the font supports.
  itemize(collection, "'0' U+20E3", FontStyle(), &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kEmojiFont, getFontPath(runs[0]));
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

  itemize(collection, "U+1F470 U+20E3", FontStyle(), &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(3, runs[0].end);
  EXPECT_EQ(kEmojiFont, getFontPath(runs[0]));
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

  itemize(collection, "U+242EE U+1F470 U+20E3", FontStyle(), &runs);
  ASSERT_EQ(2U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kJAFont, getFontPath(runs[0]));
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

  EXPECT_EQ(2, runs[1].start);
  EXPECT_EQ(5, runs[1].end);
  EXPECT_EQ(kEmojiFont, getFontPath(runs[1]));
  EXPECT_FALSE(runs[1].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[1].fakedFont.fakery.isFakeItalic());

  // Currently there is no fonts which has a glyph for 'a' + U+20E3, so they
  // are splitted into two.
  itemize(collection, "'a' U+20E3", FontStyle(), &runs);
  ASSERT_EQ(2U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(1, runs[0].end);
  EXPECT_EQ(kLatinFont, getFontPath(runs[0]));
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

  EXPECT_EQ(1, runs[1].start);
  EXPECT_EQ(2, runs[1].end);
  EXPECT_EQ(kEmojiFont, getFontPath(runs[1]));
  EXPECT_FALSE(runs[1].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[1].fakedFont.fakery.isFakeItalic());
}

TEST_F(FontCollectionItemizeTest, itemize_non_latin) {
  std::shared_ptr<FontCollection> collection(
      getFontCollection(kTestFontDir, kItemizeFontXml));
  std::vector<FontCollection::Run> runs;

  FontStyle kJAStyle = FontStyle(FontStyle::registerLanguageList("ja_JP"));
  FontStyle kUSStyle = FontStyle(FontStyle::registerLanguageList("en_US"));
  FontStyle kZH_HansStyle =
      FontStyle(FontStyle::registerLanguageList("zh_Hans"));

  // All Japanese Hiragana characters.
  itemize(collection, "U+3042 U+3044 U+3046 U+3048 U+304A", kUSStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(5, runs[0].end);
  EXPECT_EQ(kJAFont, getFontPath(runs[0]));
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

  // All Korean Hangul characters.
  itemize(collection, "U+B300 U+D55C U+BBFC U+AD6D", kUSStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(4, runs[0].end);
  EXPECT_EQ(kKOFont, getFontPath(runs[0]));
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

  // All Han characters ja, zh-Hans font having.
  // Japanese font should be selected if the specified language is Japanese.
  itemize(collection, "U+81ED U+82B1 U+5FCD", kJAStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(3, runs[0].end);
  EXPECT_EQ(kJAFont, getFontPath(runs[0]));
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

  // Simplified Chinese font should be selected if the specified language is
  // Simplified Chinese.
  itemize(collection, "U+81ED U+82B1 U+5FCD", kZH_HansStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(3, runs[0].end);
  EXPECT_EQ(kZH_HansFont, getFontPath(runs[0]));
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

  // Fallbacks to other fonts if there is no glyph in the specified language's
  // font. There is no character U+4F60 in Japanese.
  itemize(collection, "U+81ED U+4F60 U+5FCD", kJAStyle, &runs);
  ASSERT_EQ(3U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(1, runs[0].end);
  EXPECT_EQ(kJAFont, getFontPath(runs[0]));
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

  EXPECT_EQ(1, runs[1].start);
  EXPECT_EQ(2, runs[1].end);
  EXPECT_EQ(kZH_HansFont, getFontPath(runs[1]));
  EXPECT_FALSE(runs[1].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[1].fakedFont.fakery.isFakeItalic());

  EXPECT_EQ(2, runs[2].start);
  EXPECT_EQ(3, runs[2].end);
  EXPECT_EQ(kJAFont, getFontPath(runs[2]));
  EXPECT_FALSE(runs[2].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[2].fakedFont.fakery.isFakeItalic());

  // Tone mark.
  itemize(collection, "U+4444 U+302D", FontStyle(), &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kZH_HansFont, getFontPath(runs[0]));
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

  // Both zh-Hant and ja fonts support U+242EE, but zh-Hans doesn't.
  // Here, ja and zh-Hant font should have the same score but ja should be
  // selected since it is listed before zh-Hant.
  itemize(collection, "U+242EE", kZH_HansStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kJAFont, getFontPath(runs[0]));
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());
}

TEST_F(FontCollectionItemizeTest, itemize_mixed) {
  std::shared_ptr<FontCollection> collection(
      getFontCollection(kTestFontDir, kItemizeFontXml));
  std::vector<FontCollection::Run> runs;

  FontStyle kUSStyle = FontStyle(FontStyle::registerLanguageList("en_US"));

  itemize(collection, "'a' U+4F60 'b' U+4F60 'c'", kUSStyle, &runs);
  ASSERT_EQ(5U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(1, runs[0].end);
  EXPECT_EQ(kLatinFont, getFontPath(runs[0]));
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

  EXPECT_EQ(1, runs[1].start);
  EXPECT_EQ(2, runs[1].end);
  EXPECT_EQ(kZH_HansFont, getFontPath(runs[1]));
  EXPECT_FALSE(runs[1].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[1].fakedFont.fakery.isFakeItalic());

  EXPECT_EQ(2, runs[2].start);
  EXPECT_EQ(3, runs[2].end);
  EXPECT_EQ(kLatinFont, getFontPath(runs[2]));
  EXPECT_FALSE(runs[2].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[2].fakedFont.fakery.isFakeItalic());

  EXPECT_EQ(3, runs[3].start);
  EXPECT_EQ(4, runs[3].end);
  EXPECT_EQ(kZH_HansFont, getFontPath(runs[3]));
  EXPECT_FALSE(runs[3].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[3].fakedFont.fakery.isFakeItalic());

  EXPECT_EQ(4, runs[4].start);
  EXPECT_EQ(5, runs[4].end);
  EXPECT_EQ(kLatinFont, getFontPath(runs[4]));
  EXPECT_FALSE(runs[4].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[4].fakedFont.fakery.isFakeItalic());
}

TEST_F(FontCollectionItemizeTest, itemize_variationSelector) {
  std::shared_ptr<FontCollection> collection(
      getFontCollection(kTestFontDir, kItemizeFontXml));
  std::vector<FontCollection::Run> runs;

  // A glyph for U+4FAE is provided by both Japanese font and Simplified
  // Chinese font. Also a glyph for U+242EE is provided by both Japanese and
  // Traditional Chinese font.  To avoid effects of device default locale,
  // explicitly specify the locale.
  FontStyle kZH_HansStyle =
      FontStyle(FontStyle::registerLanguageList("zh_Hans"));
  FontStyle kZH_HantStyle =
      FontStyle(FontStyle::registerLanguageList("zh_Hant"));

  // U+4FAE is available in both zh_Hans and ja font, but U+4FAE,U+FE00 is
  // only available in ja font.
  itemize(collection, "U+4FAE", kZH_HansStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(1, runs[0].end);
  EXPECT_EQ(kZH_HansFont, getFontPath(runs[0]));

  itemize(collection, "U+4FAE U+FE00", kZH_HansStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kJAFont, getFontPath(runs[0]));

  itemize(collection, "U+4FAE U+4FAE U+FE00", kZH_HansStyle, &runs);
  ASSERT_EQ(2U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(1, runs[0].end);
  EXPECT_EQ(kZH_HansFont, getFontPath(runs[0]));
  EXPECT_EQ(1, runs[1].start);
  EXPECT_EQ(3, runs[1].end);
  EXPECT_EQ(kJAFont, getFontPath(runs[1]));

  itemize(collection, "U+4FAE U+4FAE U+FE00 U+4FAE", kZH_HansStyle, &runs);
  ASSERT_EQ(3U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(1, runs[0].end);
  EXPECT_EQ(kZH_HansFont, getFontPath(runs[0]));
  EXPECT_EQ(1, runs[1].start);
  EXPECT_EQ(3, runs[1].end);
  EXPECT_EQ(kJAFont, getFontPath(runs[1]));
  EXPECT_EQ(3, runs[2].start);
  EXPECT_EQ(4, runs[2].end);
  EXPECT_EQ(kZH_HansFont, getFontPath(runs[2]));

  // Validation selector after validation selector.
  itemize(collection, "U+4FAE U+FE00 U+FE00", kZH_HansStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(3, runs[0].end);
  EXPECT_EQ(kJAFont, getFontPath(runs[1]));

  // No font supports U+242EE U+FE0E.
  itemize(collection, "U+4FAE U+FE0E", kZH_HansStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kZH_HansFont, getFontPath(runs[0]));

  // Surrogate pairs handling.
  // U+242EE is available in ja font and zh_Hant font.
  // U+242EE U+FE00 is available only in ja font.
  itemize(collection, "U+242EE", kZH_HantStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kZH_HantFont, getFontPath(runs[0]));

  itemize(collection, "U+242EE U+FE00", kZH_HantStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(3, runs[0].end);
  EXPECT_EQ(kJAFont, getFontPath(runs[0]));

  itemize(collection, "U+242EE U+242EE U+FE00", kZH_HantStyle, &runs);
  ASSERT_EQ(2U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kZH_HantFont, getFontPath(runs[0]));
  EXPECT_EQ(2, runs[1].start);
  EXPECT_EQ(5, runs[1].end);
  EXPECT_EQ(kJAFont, getFontPath(runs[1]));

  itemize(collection, "U+242EE U+242EE U+FE00 U+242EE", kZH_HantStyle, &runs);
  ASSERT_EQ(3U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kZH_HantFont, getFontPath(runs[0]));
  EXPECT_EQ(2, runs[1].start);
  EXPECT_EQ(5, runs[1].end);
  EXPECT_EQ(kJAFont, getFontPath(runs[1]));
  EXPECT_EQ(5, runs[2].start);
  EXPECT_EQ(7, runs[2].end);
  EXPECT_EQ(kZH_HantFont, getFontPath(runs[2]));

  // Validation selector after validation selector.
  itemize(collection, "U+242EE U+FE00 U+FE00", kZH_HansStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(4, runs[0].end);
  EXPECT_EQ(kJAFont, getFontPath(runs[0]));

  // No font supports U+242EE U+FE0E
  itemize(collection, "U+242EE U+FE0E", kZH_HantStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(3, runs[0].end);
  EXPECT_EQ(kZH_HantFont, getFontPath(runs[0]));

  // Isolated variation selector supplement.
  itemize(collection, "U+FE00", FontStyle(), &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(1, runs[0].end);
  EXPECT_TRUE(runs[0].fakedFont.font == nullptr ||
              kLatinFont == getFontPath(runs[0]));

  itemize(collection, "U+FE00", kZH_HantStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(1, runs[0].end);
  EXPECT_TRUE(runs[0].fakedFont.font == nullptr ||
              kLatinFont == getFontPath(runs[0]));

  // First font family (Regular.ttf) supports U+203C but doesn't support U+203C
  // U+FE0F. Emoji.ttf font supports U+203C U+FE0F.  Emoji.ttf should be
  // selected.
  itemize(collection, "U+203C U+FE0F", kZH_HantStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kEmojiFont, getFontPath(runs[0]));

  // First font family (Regular.ttf) supports U+203C U+FE0E.
  itemize(collection, "U+203C U+FE0E", kZH_HantStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kLatinFont, getFontPath(runs[0]));
}

TEST_F(FontCollectionItemizeTest, itemize_variationSelectorSupplement) {
  std::shared_ptr<FontCollection> collection(
      getFontCollection(kTestFontDir, kItemizeFontXml));
  std::vector<FontCollection::Run> runs;

  // A glyph for U+845B is provided by both Japanese font and Simplified
  // Chinese font. Also a glyph for U+242EE is provided by both Japanese and
  // Traditional Chinese font.  To avoid effects of device default locale,
  // explicitly specify the locale.
  FontStyle kZH_HansStyle =
      FontStyle(FontStyle::registerLanguageList("zh_Hans"));
  FontStyle kZH_HantStyle =
      FontStyle(FontStyle::registerLanguageList("zh_Hant"));

  // U+845B is available in both zh_Hans and ja font, but U+845B,U+E0100 is
  // only available in ja font.
  itemize(collection, "U+845B", kZH_HansStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(1, runs[0].end);
  EXPECT_EQ(kZH_HansFont, getFontPath(runs[0]));

  itemize(collection, "U+845B U+E0100", kZH_HansStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(3, runs[0].end);
  EXPECT_EQ(kJAFont, getFontPath(runs[0]));

  itemize(collection, "U+845B U+845B U+E0100", kZH_HansStyle, &runs);
  ASSERT_EQ(2U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(1, runs[0].end);
  EXPECT_EQ(kZH_HansFont, getFontPath(runs[0]));
  EXPECT_EQ(1, runs[1].start);
  EXPECT_EQ(4, runs[1].end);
  EXPECT_EQ(kJAFont, getFontPath(runs[1]));

  itemize(collection, "U+845B U+845B U+E0100 U+845B", kZH_HansStyle, &runs);
  ASSERT_EQ(3U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(1, runs[0].end);
  EXPECT_EQ(kZH_HansFont, getFontPath(runs[0]));
  EXPECT_EQ(1, runs[1].start);
  EXPECT_EQ(4, runs[1].end);
  EXPECT_EQ(kJAFont, getFontPath(runs[1]));
  EXPECT_EQ(4, runs[2].start);
  EXPECT_EQ(5, runs[2].end);
  EXPECT_EQ(kZH_HansFont, getFontPath(runs[2]));

  // Validation selector after validation selector.
  itemize(collection, "U+845B U+E0100 U+E0100", kZH_HansStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(5, runs[0].end);
  EXPECT_EQ(kJAFont, getFontPath(runs[0]));

  // No font supports U+845B U+E01E0.
  itemize(collection, "U+845B U+E01E0", kZH_HansStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(3, runs[0].end);
  EXPECT_EQ(kZH_HansFont, getFontPath(runs[0]));

  // Isolated variation selector supplement
  // Surrogate pairs handling.
  // U+242EE is available in ja font and zh_Hant font.
  // U+242EE U+E0100 is available only in ja font.
  itemize(collection, "U+242EE", kZH_HantStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kZH_HantFont, getFontPath(runs[0]));

  itemize(collection, "U+242EE U+E0101", kZH_HantStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(4, runs[0].end);
  EXPECT_EQ(kJAFont, getFontPath(runs[0]));

  itemize(collection, "U+242EE U+242EE U+E0101", kZH_HantStyle, &runs);
  ASSERT_EQ(2U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kZH_HantFont, getFontPath(runs[0]));
  EXPECT_EQ(2, runs[1].start);
  EXPECT_EQ(6, runs[1].end);
  EXPECT_EQ(kJAFont, getFontPath(runs[1]));

  itemize(collection, "U+242EE U+242EE U+E0101 U+242EE", kZH_HantStyle, &runs);
  ASSERT_EQ(3U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kZH_HantFont, getFontPath(runs[0]));
  EXPECT_EQ(2, runs[1].start);
  EXPECT_EQ(6, runs[1].end);
  EXPECT_EQ(kJAFont, getFontPath(runs[1]));
  EXPECT_EQ(6, runs[2].start);
  EXPECT_EQ(8, runs[2].end);
  EXPECT_EQ(kZH_HantFont, getFontPath(runs[2]));

  // Validation selector after validation selector.
  itemize(collection, "U+242EE U+E0100 U+E0100", kZH_HantStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(6, runs[0].end);
  EXPECT_EQ(kJAFont, getFontPath(runs[0]));

  // No font supports U+242EE U+E01E0.
  itemize(collection, "U+242EE U+E01E0", kZH_HantStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(4, runs[0].end);
  EXPECT_EQ(kZH_HantFont, getFontPath(runs[0]));

  // Isolated variation selector supplement.
  itemize(collection, "U+E0100", FontStyle(), &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_TRUE(runs[0].fakedFont.font == nullptr ||
              kLatinFont == getFontPath(runs[0]));

  itemize(collection, "U+E0100", kZH_HantStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_TRUE(runs[0].fakedFont.font == nullptr ||
              kLatinFont == getFontPath(runs[0]));
}

TEST_F(FontCollectionItemizeTest, itemize_no_crash) {
  std::shared_ptr<FontCollection> collection(
      getFontCollection(kTestFontDir, kItemizeFontXml));
  std::vector<FontCollection::Run> runs;

  // Broken Surrogate pairs. Check only not crashing.
  itemize(collection, "'a' U+D83D 'a'", FontStyle(), &runs);
  itemize(collection, "'a' U+DC69 'a'", FontStyle(), &runs);
  itemize(collection, "'a' U+D83D U+D83D 'a'", FontStyle(), &runs);
  itemize(collection, "'a' U+DC69 U+DC69 'a'", FontStyle(), &runs);

  // Isolated variation selector. Check only not crashing.
  itemize(collection, "U+FE00 U+FE00", FontStyle(), &runs);
  itemize(collection, "U+E0100 U+E0100", FontStyle(), &runs);
  itemize(collection, "U+FE00 U+E0100", FontStyle(), &runs);
  itemize(collection, "U+E0100 U+FE00", FontStyle(), &runs);

  // Tone mark only. Check only not crashing.
  itemize(collection, "U+302D", FontStyle(), &runs);
  itemize(collection, "U+302D U+302D", FontStyle(), &runs);

  // Tone mark and variation selector mixed. Check only not crashing.
  itemize(collection, "U+FE00 U+302D U+E0100", FontStyle(), &runs);
}

TEST_F(FontCollectionItemizeTest, itemize_fakery) {
  std::shared_ptr<FontCollection> collection(
      getFontCollection(kTestFontDir, kItemizeFontXml));
  std::vector<FontCollection::Run> runs;

  FontStyle kJABoldStyle =
      FontStyle(FontStyle::registerLanguageList("ja_JP"), 0, 7, false);
  FontStyle kJAItalicStyle =
      FontStyle(FontStyle::registerLanguageList("ja_JP"), 0, 5, true);
  FontStyle kJABoldItalicStyle =
      FontStyle(FontStyle::registerLanguageList("ja_JP"), 0, 7, true);

  // Currently there is no italic or bold font for Japanese. FontFakery has
  // the differences between desired and actual font style.

  // All Japanese Hiragana characters.
  itemize(collection, "U+3042 U+3044 U+3046 U+3048 U+304A", kJABoldStyle,
          &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(5, runs[0].end);
  EXPECT_EQ(kJAFont, getFontPath(runs[0]));
  EXPECT_TRUE(runs[0].fakedFont.fakery.isFakeBold());
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

  // All Japanese Hiragana characters.
  itemize(collection, "U+3042 U+3044 U+3046 U+3048 U+304A", kJAItalicStyle,
          &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(5, runs[0].end);
  EXPECT_EQ(kJAFont, getFontPath(runs[0]));
  EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
  EXPECT_TRUE(runs[0].fakedFont.fakery.isFakeItalic());

  // All Japanese Hiragana characters.
  itemize(collection, "U+3042 U+3044 U+3046 U+3048 U+304A", kJABoldItalicStyle,
          &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(5, runs[0].end);
  EXPECT_EQ(kJAFont, getFontPath(runs[0]));
  EXPECT_TRUE(runs[0].fakedFont.fakery.isFakeBold());
  EXPECT_TRUE(runs[0].fakedFont.fakery.isFakeItalic());
}

TEST_F(FontCollectionItemizeTest, itemize_vs_sequence_but_no_base_char) {
  // kVSTestFont supports U+717D U+FE02 but doesn't support U+717D.
  // kVSTestFont should be selected for U+717D U+FE02 even if it does not
  // support the base code point.
  const std::string kVSTestFont =
      kTestFontDir "VariationSelectorTest-Regular.ttf";

  std::vector<std::shared_ptr<FontFamily>> families;
  std::shared_ptr<MinikinFont> font(new MinikinFontForTest(kLatinFont));
  std::shared_ptr<FontFamily> family1(new FontFamily(
      VARIANT_DEFAULT, std::vector<Font>{Font(font, FontStyle())}));
  families.push_back(family1);

  std::shared_ptr<MinikinFont> font2(new MinikinFontForTest(kVSTestFont));
  std::shared_ptr<FontFamily> family2(new FontFamily(
      VARIANT_DEFAULT, std::vector<Font>{Font(font2, FontStyle())}));
  families.push_back(family2);

  std::shared_ptr<FontCollection> collection(new FontCollection(families));

  std::vector<FontCollection::Run> runs;

  itemize(collection, "U+717D U+FE02", FontStyle(), &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kVSTestFont, getFontPath(runs[0]));
}

TEST_F(FontCollectionItemizeTest, itemize_LanguageScore) {
  struct TestCase {
    std::string userPreferredLanguages;
    std::vector<std::string> fontLanguages;
    int selectedFontIndex;
  } testCases[] = {
      // Font can specify empty language.
      {"und", {"", ""}, 0},
      {"und", {"", "en-Latn"}, 0},
      {"en-Latn", {"", ""}, 0},
      {"en-Latn", {"", "en-Latn"}, 1},

      // Single user preferred language.
      // Exact match case
      {"en-Latn", {"en-Latn", "ja-Jpan"}, 0},
      {"ja-Jpan", {"en-Latn", "ja-Jpan"}, 1},
      {"en-Latn", {"en-Latn", "nl-Latn", "es-Latn"}, 0},
      {"nl-Latn", {"en-Latn", "nl-Latn", "es-Latn"}, 1},
      {"es-Latn", {"en-Latn", "nl-Latn", "es-Latn"}, 2},
      {"es-Latn", {"en-Latn", "en-Latn", "nl-Latn"}, 0},

      // Exact script match case
      {"en-Latn", {"nl-Latn", "e-Latn"}, 0},
      {"en-Arab", {"nl-Latn", "ar-Arab"}, 1},
      {"en-Latn", {"be-Latn", "ar-Arab", "d-Beng"}, 0},
      {"en-Arab", {"be-Latn", "ar-Arab", "d-Beng"}, 1},
      {"en-Beng", {"be-Latn", "ar-Arab", "d-Beng"}, 2},
      {"en-Beng", {"be-Latn", "ar-Beng", "d-Beng"}, 1},
      {"zh-Hant", {"zh-Hant", "zh-Hans"}, 0},
      {"zh-Hans", {"zh-Hant", "zh-Hans"}, 1},

      // Subscript match case, e.g. Jpan supports Hira.
      {"en-Hira", {"ja-Jpan"}, 0},
      {"zh-Hani", {"zh-Hans", "zh-Hant"}, 0},
      {"zh-Hani", {"zh-Hant", "zh-Hans"}, 0},
      {"en-Hira", {"zh-Hant", "ja-Jpan", "ja-Jpan"}, 1},

      // Language match case
      {"ja-Latn", {"zh-Latn", "ja-Latn"}, 1},
      {"zh-Latn", {"zh-Latn", "ja-Latn"}, 0},
      {"ja-Latn", {"zh-Latn", "ja-Latn"}, 1},
      {"ja-Latn", {"zh-Latn", "ja-Latn", "ja-Latn"}, 1},

      // Mixed case
      // Script/subscript match is strongest.
      {"ja-Jpan", {"en-Latn", "ja-Latn", "en-Jpan"}, 2},
      {"ja-Hira", {"en-Latn", "ja-Latn", "en-Jpan"}, 2},
      {"ja-Hira", {"en-Latn", "ja-Latn", "en-Jpan", "en-Jpan"}, 2},

      // Language match only happens if the script matches.
      {"ja-Hira", {"en-Latn", "ja-Latn"}, 0},
      {"ja-Hira", {"en-Jpan", "ja-Jpan"}, 1},

      // Multiple languages.
      // Even if all fonts have the same score, use the 2nd language for better
      // selection.
      {"en-Latn,ja-Jpan", {"zh-Hant", "zh-Hans", "ja-Jpan"}, 2},
      {"en-Latn,nl-Latn", {"es-Latn", "be-Latn", "nl-Latn"}, 2},
      {"en-Latn,br-Latn,nl-Latn", {"es-Latn", "be-Latn", "nl-Latn"}, 2},
      {"en-Latn,br-Latn,nl-Latn",
       {"es-Latn", "be-Latn", "nl-Latn", "nl-Latn"},
       2},

      // Script score.
      {"en-Latn,ja-Jpan", {"en-Arab", "en-Jpan"}, 1},
      {"en-Latn,ja-Jpan", {"en-Arab", "en-Jpan", "en-Jpan"}, 1},

      // Language match case
      {"en-Latn,ja-Latn", {"bd-Latn", "ja-Latn"}, 1},
      {"en-Latn,ja-Latn", {"bd-Latn", "ja-Latn", "ja-Latn"}, 1},

      // Language match only happens if the script matches.
      {"en-Latn,ar-Arab", {"en-Beng", "ar-Arab"}, 1},

      // Multiple languages in the font settings.
      {"ko-Jamo", {"ja-Jpan", "ko-Kore", "ko-Kore,ko-Jamo"}, 2},
      {"en-Latn", {"ja-Jpan", "en-Latn,ja-Jpan"}, 1},
      {"en-Latn", {"ja-Jpan", "ja-Jpan,en-Latn"}, 1},
      {"en-Latn", {"ja-Jpan,zh-Hant", "en-Latn,ja-Jpan", "en-Latn"}, 1},
      {"en-Latn", {"zh-Hant,ja-Jpan", "ja-Jpan,en-Latn", "en-Latn"}, 1},

      // Kore = Hang + Hani, etc.
      {"ko-Kore", {"ko-Hang", "ko-Jamo,ko-Hani", "ko-Hang,ko-Hani"}, 2},
      {"ja-Hrkt", {"ja-Hira", "ja-Kana", "ja-Hira,ja-Kana"}, 2},
      {"ja-Jpan",
       {"ja-Hira", "ja-Kana", "ja-Hani", "ja-Hira,ja-Kana,ja-Hani"},
       3},
      {"zh-Hanb", {"zh-Hant", "zh-Bopo", "zh-Hant,zh-Bopo"}, 2},
      {"zh-Hanb", {"ja-Hanb", "zh-Hant,zh-Bopo"}, 1},

      // Language match with unified subscript bits.
      {"zh-Hanb",
       {"zh-Hant", "zh-Bopo", "ja-Hant,ja-Bopo", "zh-Hant,zh-Bopo"},
       3},
      {"zh-Hanb",
       {"zh-Hant", "zh-Bopo", "ja-Hant,zh-Bopo", "zh-Hant,zh-Bopo"},
       3},

      // Two elements subtag matching: language and subtag or language or
      // script.
      {"ja-Kana-u-em-emoji", {"zh-Hant", "ja-Kana"}, 1},
      {"ja-Kana-u-em-emoji", {"zh-Hant", "ja-Kana", "ja-Zsye"}, 2},
      {"ja-Zsym-u-em-emoji", {"ja-Kana", "ja-Zsym", "ja-Zsye"}, 2},

      // One element subtag matching: subtag only or script only.
      {"en-Latn-u-em-emoji", {"ja-Latn", "ja-Zsye"}, 1},
      {"en-Zsym-u-em-emoji", {"ja-Zsym", "ja-Zsye"}, 1},
      {"en-Zsye-u-em-text", {"ja-Zsym", "ja-Zsye"}, 0},

      // Multiple languages list with subtags.
      {"en-Latn,ja-Jpan-u-em-text", {"en-Latn", "en-Zsye", "en-Zsym"}, 0},
      {"en-Latn,en-Zsye,ja-Jpan-u-em-text", {"zh", "en-Zsye", "en-Zsym"}, 1},
  };

  for (auto testCase : testCases) {
    std::string fontLanguagesStr = "{";
    for (size_t i = 0; i < testCase.fontLanguages.size(); ++i) {
      if (i != 0) {
        fontLanguagesStr += ", ";
      }
      fontLanguagesStr += "\"" + testCase.fontLanguages[i] + "\"";
    }
    fontLanguagesStr += "}";
    SCOPED_TRACE("Test of user preferred languages: \"" +
                 testCase.userPreferredLanguages +
                 "\" with font languages: " + fontLanguagesStr);

    std::vector<std::shared_ptr<FontFamily>> families;

    // Prepare first font which doesn't supports U+9AA8
    std::shared_ptr<MinikinFont> firstFamilyMinikinFont(
        new MinikinFontForTest(kNoGlyphFont));
    std::shared_ptr<FontFamily> firstFamily(new FontFamily(
        FontStyle::registerLanguageList("und"), 0 /* variant */,
        std::vector<Font>({Font(firstFamilyMinikinFont, FontStyle())})));
    families.push_back(firstFamily);

    // Prepare font families
    // Each font family is associated with a specified language. All font
    // families except for the first font support U+9AA8.
    std::unordered_map<MinikinFont*, int> fontLangIdxMap;

    for (size_t i = 0; i < testCase.fontLanguages.size(); ++i) {
      std::shared_ptr<MinikinFont> minikin_font(
          new MinikinFontForTest(kJAFont));
      std::shared_ptr<FontFamily> family(new FontFamily(
          FontStyle::registerLanguageList(testCase.fontLanguages[i]),
          0 /* variant */,
          std::vector<Font>({Font(minikin_font, FontStyle())})));
      families.push_back(family);
      fontLangIdxMap.insert(std::make_pair(minikin_font.get(), i));
    }
    std::shared_ptr<FontCollection> collection(new FontCollection(families));
    // Do itemize
    const FontStyle style = FontStyle(
        FontStyle::registerLanguageList(testCase.userPreferredLanguages));
    std::vector<FontCollection::Run> runs;
    itemize(collection, "U+9AA8", style, &runs);
    ASSERT_EQ(1U, runs.size());
    ASSERT_NE(nullptr, runs[0].fakedFont.font);

    // First family doesn't support U+9AA8 and others support it, so the first
    // font should not be selected.
    EXPECT_NE(firstFamilyMinikinFont.get(), runs[0].fakedFont.font);

    // Lookup used font family by MinikinFont*.
    const int usedLangIndex = fontLangIdxMap[runs[0].fakedFont.font];
    EXPECT_EQ(testCase.selectedFontIndex, usedLangIndex);
  }
}

TEST_F(FontCollectionItemizeTest, itemize_LanguageAndCoverage) {
  struct TestCase {
    std::string testString;
    std::string requestedLanguages;
    std::string expectedFont;
  } testCases[] = {
      // Following test cases verify that following rules in font fallback
      // chain.
      // - If the first font in the collection supports the given character or
      // variation sequence,
      //   it should be selected.
      // - If the font doesn't support the given character, variation sequence
      // or its base
      //   character, it should not be selected.
      // - If two or more fonts match the requested languages, the font matches
      // with the highest
      //   priority language should be selected.
      // - If two or more fonts get the same score, the font listed earlier in
      // the XML file
      //   (here, kItemizeFontXml) should be selected.

      // Regardless of language, the first font is always selected if it covers
      // the code point.
      {"'a'", "", kLatinFont},
      {"'a'", "en-Latn", kLatinFont},
      {"'a'", "ja-Jpan", kLatinFont},
      {"'a'", "ja-Jpan,en-Latn", kLatinFont},
      {"'a'", "zh-Hans,zh-Hant,en-Latn,ja-Jpan,fr-Latn", kLatinFont},

      // U+81ED is supported by both the ja font and zh-Hans font.
      {"U+81ED", "", kZH_HansFont},  // zh-Hans font is listed before ja font.
      {"U+81ED", "en-Latn",
       kZH_HansFont},  // zh-Hans font is listed before ja font.
      {"U+81ED", "ja-Jpan", kJAFont},
      {"U+81ED", "zh-Hans", kZH_HansFont},

      {"U+81ED", "ja-Jpan,en-Latn", kJAFont},
      {"U+81ED", "en-Latn,ja-Jpan", kJAFont},
      {"U+81ED", "en-Latn,zh-Hans", kZH_HansFont},
      {"U+81ED", "zh-Hans,en-Latn", kZH_HansFont},
      {"U+81ED", "ja-Jpan,zh-Hans", kJAFont},
      {"U+81ED", "zh-Hans,ja-Jpan", kZH_HansFont},

      {"U+81ED", "en-Latn,zh-Hans,ja-Jpan", kZH_HansFont},
      {"U+81ED", "en-Latn,ja-Jpan,zh-Hans", kJAFont},
      {"U+81ED", "en-Latn,zh-Hans,ja-Jpan", kZH_HansFont},
      {"U+81ED", "ja-Jpan,en-Latn,zh-Hans", kJAFont},
      {"U+81ED", "ja-Jpan,zh-Hans,en-Latn", kJAFont},
      {"U+81ED", "zh-Hans,en-Latn,ja-Jpan", kZH_HansFont},
      {"U+81ED", "zh-Hans,ja-Jpan,en-Latn", kZH_HansFont},

      // U+304A is only supported by ja font.
      {"U+304A", "", kJAFont},
      {"U+304A", "ja-Jpan", kJAFont},
      {"U+304A", "zh-Hant", kJAFont},
      {"U+304A", "zh-Hans", kJAFont},

      {"U+304A", "ja-Jpan,zh-Hant", kJAFont},
      {"U+304A", "zh-Hant,ja-Jpan", kJAFont},
      {"U+304A", "zh-Hans,zh-Hant", kJAFont},
      {"U+304A", "zh-Hant,zh-Hans", kJAFont},
      {"U+304A", "zh-Hans,ja-Jpan", kJAFont},
      {"U+304A", "ja-Jpan,zh-Hans", kJAFont},

      {"U+304A", "zh-Hans,ja-Jpan,zh-Hant", kJAFont},
      {"U+304A", "zh-Hans,zh-Hant,ja-Jpan", kJAFont},
      {"U+304A", "ja-Jpan,zh-Hans,zh-Hant", kJAFont},
      {"U+304A", "ja-Jpan,zh-Hant,zh-Hans", kJAFont},
      {"U+304A", "zh-Hant,zh-Hans,ja-Jpan", kJAFont},
      {"U+304A", "zh-Hant,ja-Jpan,zh-Hans", kJAFont},

      // U+242EE is supported by both ja font and zh-Hant fonts but not by
      // zh-Hans font.
      {"U+242EE", "", kJAFont},  // ja font is listed before zh-Hant font.
      {"U+242EE", "ja-Jpan", kJAFont},
      {"U+242EE", "zh-Hans", kJAFont},
      {"U+242EE", "zh-Hant", kZH_HantFont},

      {"U+242EE", "ja-Jpan,zh-Hant", kJAFont},
      {"U+242EE", "zh-Hant,ja-Jpan", kZH_HantFont},
      {"U+242EE", "zh-Hans,zh-Hant", kZH_HantFont},
      {"U+242EE", "zh-Hant,zh-Hans", kZH_HantFont},
      {"U+242EE", "zh-Hans,ja-Jpan", kJAFont},
      {"U+242EE", "ja-Jpan,zh-Hans", kJAFont},

      {"U+242EE", "zh-Hans,ja-Jpan,zh-Hant", kJAFont},
      {"U+242EE", "zh-Hans,zh-Hant,ja-Jpan", kZH_HantFont},
      {"U+242EE", "ja-Jpan,zh-Hans,zh-Hant", kJAFont},
      {"U+242EE", "ja-Jpan,zh-Hant,zh-Hans", kJAFont},
      {"U+242EE", "zh-Hant,zh-Hans,ja-Jpan", kZH_HantFont},
      {"U+242EE", "zh-Hant,ja-Jpan,zh-Hans", kZH_HantFont},

      // U+9AA8 is supported by all ja-Jpan, zh-Hans, zh-Hant fonts.
      {"U+9AA8", "",
       kZH_HansFont},  // zh-Hans font is listed before ja and zh-Hant fonts.
      {"U+9AA8", "ja-Jpan", kJAFont},
      {"U+9AA8", "zh-Hans", kZH_HansFont},
      {"U+9AA8", "zh-Hant", kZH_HantFont},

      {"U+9AA8", "ja-Jpan,zh-Hant", kJAFont},
      {"U+9AA8", "zh-Hant,ja-Jpan", kZH_HantFont},
      {"U+9AA8", "zh-Hans,zh-Hant", kZH_HansFont},
      {"U+9AA8", "zh-Hant,zh-Hans", kZH_HantFont},
      {"U+9AA8", "zh-Hans,ja-Jpan", kZH_HansFont},
      {"U+9AA8", "ja-Jpan,zh-Hans", kJAFont},

      {"U+9AA8", "zh-Hans,ja-Jpan,zh-Hant", kZH_HansFont},
      {"U+9AA8", "zh-Hans,zh-Hant,ja-Jpan", kZH_HansFont},
      {"U+9AA8", "ja-Jpan,zh-Hans,zh-Hant", kJAFont},
      {"U+9AA8", "ja-Jpan,zh-Hant,zh-Hans", kJAFont},
      {"U+9AA8", "zh-Hant,zh-Hans,ja-Jpan", kZH_HantFont},
      {"U+9AA8", "zh-Hant,ja-Jpan,zh-Hans", kZH_HantFont},

      // U+242EE U+FE00 is supported by ja font but not by zh-Hans or zh-Hant
      // fonts.
      {"U+242EE U+FE00", "", kJAFont},
      {"U+242EE U+FE00", "ja-Jpan", kJAFont},
      {"U+242EE U+FE00", "zh-Hant", kJAFont},
      {"U+242EE U+FE00", "zh-Hans", kJAFont},

      {"U+242EE U+FE00", "ja-Jpan,zh-Hant", kJAFont},
      {"U+242EE U+FE00", "zh-Hant,ja-Jpan", kJAFont},
      {"U+242EE U+FE00", "zh-Hans,zh-Hant", kJAFont},
      {"U+242EE U+FE00", "zh-Hant,zh-Hans", kJAFont},
      {"U+242EE U+FE00", "zh-Hans,ja-Jpan", kJAFont},
      {"U+242EE U+FE00", "ja-Jpan,zh-Hans", kJAFont},

      {"U+242EE U+FE00", "zh-Hans,ja-Jpan,zh-Hant", kJAFont},
      {"U+242EE U+FE00", "zh-Hans,zh-Hant,ja-Jpan", kJAFont},
      {"U+242EE U+FE00", "ja-Jpan,zh-Hans,zh-Hant", kJAFont},
      {"U+242EE U+FE00", "ja-Jpan,zh-Hant,zh-Hans", kJAFont},
      {"U+242EE U+FE00", "zh-Hant,zh-Hans,ja-Jpan", kJAFont},
      {"U+242EE U+FE00", "zh-Hant,ja-Jpan,zh-Hans", kJAFont},

      // U+3402 U+E0100 is supported by both zh-Hans and zh-Hant but not by ja
      // font.
      {"U+3402 U+E0100", "",
       kZH_HansFont},  // zh-Hans font is listed before zh-Hant font.
      {"U+3402 U+E0100", "ja-Jpan",
       kZH_HansFont},  // zh-Hans font is listed before zh-Hant font.
      {"U+3402 U+E0100", "zh-Hant", kZH_HantFont},
      {"U+3402 U+E0100", "zh-Hans", kZH_HansFont},

      {"U+3402 U+E0100", "ja-Jpan,zh-Hant", kZH_HantFont},
      {"U+3402 U+E0100", "zh-Hant,ja-Jpan", kZH_HantFont},
      {"U+3402 U+E0100", "zh-Hans,zh-Hant", kZH_HansFont},
      {"U+3402 U+E0100", "zh-Hant,zh-Hans", kZH_HantFont},
      {"U+3402 U+E0100", "zh-Hans,ja-Jpan", kZH_HansFont},
      {"U+3402 U+E0100", "ja-Jpan,zh-Hans", kZH_HansFont},

      {"U+3402 U+E0100", "zh-Hans,ja-Jpan,zh-Hant", kZH_HansFont},
      {"U+3402 U+E0100", "zh-Hans,zh-Hant,ja-Jpan", kZH_HansFont},
      {"U+3402 U+E0100", "ja-Jpan,zh-Hans,zh-Hant", kZH_HansFont},
      {"U+3402 U+E0100", "ja-Jpan,zh-Hant,zh-Hans", kZH_HantFont},
      {"U+3402 U+E0100", "zh-Hant,zh-Hans,ja-Jpan", kZH_HantFont},
      {"U+3402 U+E0100", "zh-Hant,ja-Jpan,zh-Hans", kZH_HantFont},

      // No font supports U+4444 U+FE00 but only zh-Hans supports its base
      // character U+4444.
      {"U+4444 U+FE00", "", kZH_HansFont},
      {"U+4444 U+FE00", "ja-Jpan", kZH_HansFont},
      {"U+4444 U+FE00", "zh-Hant", kZH_HansFont},
      {"U+4444 U+FE00", "zh-Hans", kZH_HansFont},

      {"U+4444 U+FE00", "ja-Jpan,zh-Hant", kZH_HansFont},
      {"U+4444 U+FE00", "zh-Hant,ja-Jpan", kZH_HansFont},
      {"U+4444 U+FE00", "zh-Hans,zh-Hant", kZH_HansFont},
      {"U+4444 U+FE00", "zh-Hant,zh-Hans", kZH_HansFont},
      {"U+4444 U+FE00", "zh-Hans,ja-Jpan", kZH_HansFont},
      {"U+4444 U+FE00", "ja-Jpan,zh-Hans", kZH_HansFont},

      {"U+4444 U+FE00", "zh-Hans,ja-Jpan,zh-Hant", kZH_HansFont},
      {"U+4444 U+FE00", "zh-Hans,zh-Hant,ja-Jpan", kZH_HansFont},
      {"U+4444 U+FE00", "ja-Jpan,zh-Hans,zh-Hant", kZH_HansFont},
      {"U+4444 U+FE00", "ja-Jpan,zh-Hant,zh-Hans", kZH_HansFont},
      {"U+4444 U+FE00", "zh-Hant,zh-Hans,ja-Jpan", kZH_HansFont},
      {"U+4444 U+FE00", "zh-Hant,ja-Jpan,zh-Hans", kZH_HansFont},

      // No font supports U+81ED U+E0100 but ja and zh-Hans support its base
      // character U+81ED.
      // zh-Hans font is listed before ja font.
      {"U+81ED U+E0100", "", kZH_HansFont},
      {"U+81ED U+E0100", "ja-Jpan", kJAFont},
      {"U+81ED U+E0100", "zh-Hant", kZH_HansFont},
      {"U+81ED U+E0100", "zh-Hans", kZH_HansFont},

      {"U+81ED U+E0100", "ja-Jpan,zh-Hant", kJAFont},
      {"U+81ED U+E0100", "zh-Hant,ja-Jpan", kJAFont},
      {"U+81ED U+E0100", "zh-Hans,zh-Hant", kZH_HansFont},
      {"U+81ED U+E0100", "zh-Hant,zh-Hans", kZH_HansFont},
      {"U+81ED U+E0100", "zh-Hans,ja-Jpan", kZH_HansFont},
      {"U+81ED U+E0100", "ja-Jpan,zh-Hans", kJAFont},

      {"U+81ED U+E0100", "zh-Hans,ja-Jpan,zh-Hant", kZH_HansFont},
      {"U+81ED U+E0100", "zh-Hans,zh-Hant,ja-Jpan", kZH_HansFont},
      {"U+81ED U+E0100", "ja-Jpan,zh-Hans,zh-Hant", kJAFont},
      {"U+81ED U+E0100", "ja-Jpan,zh-Hant,zh-Hans", kJAFont},
      {"U+81ED U+E0100", "zh-Hant,zh-Hans,ja-Jpan", kZH_HansFont},
      {"U+81ED U+E0100", "zh-Hant,ja-Jpan,zh-Hans", kJAFont},

      // No font supports U+9AA8 U+E0100 but all zh-Hans zh-hant ja fonts
      // support its base
      // character U+9AA8.
      // zh-Hans font is listed before ja and zh-Hant fonts.
      {"U+9AA8 U+E0100", "", kZH_HansFont},
      {"U+9AA8 U+E0100", "ja-Jpan", kJAFont},
      {"U+9AA8 U+E0100", "zh-Hans", kZH_HansFont},
      {"U+9AA8 U+E0100", "zh-Hant", kZH_HantFont},

      {"U+9AA8 U+E0100", "ja-Jpan,zh-Hant", kJAFont},
      {"U+9AA8 U+E0100", "zh-Hant,ja-Jpan", kZH_HantFont},
      {"U+9AA8 U+E0100", "zh-Hans,zh-Hant", kZH_HansFont},
      {"U+9AA8 U+E0100", "zh-Hant,zh-Hans", kZH_HantFont},
      {"U+9AA8 U+E0100", "zh-Hans,ja-Jpan", kZH_HansFont},
      {"U+9AA8 U+E0100", "ja-Jpan,zh-Hans", kJAFont},

      {"U+9AA8 U+E0100", "zh-Hans,ja-Jpan,zh-Hant", kZH_HansFont},
      {"U+9AA8 U+E0100", "zh-Hans,zh-Hant,ja-Jpan", kZH_HansFont},
      {"U+9AA8 U+E0100", "ja-Jpan,zh-Hans,zh-Hant", kJAFont},
      {"U+9AA8 U+E0100", "ja-Jpan,zh-Hant,zh-Hans", kJAFont},
      {"U+9AA8 U+E0100", "zh-Hant,zh-Hans,ja-Jpan", kZH_HantFont},
      {"U+9AA8 U+E0100", "zh-Hant,ja-Jpan,zh-Hans", kZH_HantFont},

      // All zh-Hans,zh-Hant,ja fonts support U+35A8 U+E0100 and its base
      // character U+35A8.
      // zh-Hans font is listed before ja and zh-Hant fonts.
      {"U+35A8", "", kZH_HansFont},
      {"U+35A8", "ja-Jpan", kJAFont},
      {"U+35A8", "zh-Hans", kZH_HansFont},
      {"U+35A8", "zh-Hant", kZH_HantFont},

      {"U+35A8", "ja-Jpan,zh-Hant", kJAFont},
      {"U+35A8", "zh-Hant,ja-Jpan", kZH_HantFont},
      {"U+35A8", "zh-Hans,zh-Hant", kZH_HansFont},
      {"U+35A8", "zh-Hant,zh-Hans", kZH_HantFont},
      {"U+35A8", "zh-Hans,ja-Jpan", kZH_HansFont},
      {"U+35A8", "ja-Jpan,zh-Hans", kJAFont},

      {"U+35A8", "zh-Hans,ja-Jpan,zh-Hant", kZH_HansFont},
      {"U+35A8", "zh-Hans,zh-Hant,ja-Jpan", kZH_HansFont},
      {"U+35A8", "ja-Jpan,zh-Hans,zh-Hant", kJAFont},
      {"U+35A8", "ja-Jpan,zh-Hant,zh-Hans", kJAFont},
      {"U+35A8", "zh-Hant,zh-Hans,ja-Jpan", kZH_HantFont},
      {"U+35A8", "zh-Hant,ja-Jpan,zh-Hans", kZH_HantFont},

      // All zh-Hans,zh-Hant,ja fonts support U+35B6 U+E0100, but zh-Hant and ja
      // fonts support its
      // base character U+35B6.
      // ja font is listed before zh-Hant font.
      {"U+35B6", "", kJAFont},
      {"U+35B6", "ja-Jpan", kJAFont},
      {"U+35B6", "zh-Hant", kZH_HantFont},
      {"U+35B6", "zh-Hans", kJAFont},

      {"U+35B6", "ja-Jpan,zh-Hant", kJAFont},
      {"U+35B6", "zh-Hant,ja-Jpan", kZH_HantFont},
      {"U+35B6", "zh-Hans,zh-Hant", kZH_HantFont},
      {"U+35B6", "zh-Hant,zh-Hans", kZH_HantFont},
      {"U+35B6", "zh-Hans,ja-Jpan", kJAFont},
      {"U+35B6", "ja-Jpan,zh-Hans", kJAFont},

      {"U+35B6", "zh-Hans,ja-Jpan,zh-Hant", kJAFont},
      {"U+35B6", "zh-Hans,zh-Hant,ja-Jpan", kZH_HantFont},
      {"U+35B6", "ja-Jpan,zh-Hans,zh-Hant", kJAFont},
      {"U+35B6", "ja-Jpan,zh-Hant,zh-Hans", kJAFont},
      {"U+35B6", "zh-Hant,zh-Hans,ja-Jpan", kZH_HantFont},
      {"U+35B6", "zh-Hant,ja-Jpan,zh-Hans", kZH_HantFont},

      // All zh-Hans,zh-Hant,ja fonts support U+35C5 U+E0100, but only ja font
      // supports its base
      // character U+35C5.
      {"U+35C5", "", kJAFont},
      {"U+35C5", "ja-Jpan", kJAFont},
      {"U+35C5", "zh-Hant", kJAFont},
      {"U+35C5", "zh-Hans", kJAFont},

      {"U+35C5", "ja-Jpan,zh-Hant", kJAFont},
      {"U+35C5", "zh-Hant,ja-Jpan", kJAFont},
      {"U+35C5", "zh-Hans,zh-Hant", kJAFont},
      {"U+35C5", "zh-Hant,zh-Hans", kJAFont},
      {"U+35C5", "zh-Hans,ja-Jpan", kJAFont},
      {"U+35C5", "ja-Jpan,zh-Hans", kJAFont},

      {"U+35C5", "zh-Hans,ja-Jpan,zh-Hant", kJAFont},
      {"U+35C5", "zh-Hans,zh-Hant,ja-Jpan", kJAFont},
      {"U+35C5", "ja-Jpan,zh-Hans,zh-Hant", kJAFont},
      {"U+35C5", "ja-Jpan,zh-Hant,zh-Hans", kJAFont},
      {"U+35C5", "zh-Hant,zh-Hans,ja-Jpan", kJAFont},
      {"U+35C5", "zh-Hant,ja-Jpan,zh-Hans", kJAFont},

      // None of ja-Jpan, zh-Hant, zh-Hans font supports U+1F469. Emoji font
      // supports it.
      {"U+1F469", "", kEmojiFont},
      {"U+1F469", "ja-Jpan", kEmojiFont},
      {"U+1F469", "zh-Hant", kEmojiFont},
      {"U+1F469", "zh-Hans", kEmojiFont},

      {"U+1F469", "ja-Jpan,zh-Hant", kEmojiFont},
      {"U+1F469", "zh-Hant,ja-Jpan", kEmojiFont},
      {"U+1F469", "zh-Hans,zh-Hant", kEmojiFont},
      {"U+1F469", "zh-Hant,zh-Hans", kEmojiFont},
      {"U+1F469", "zh-Hans,ja-Jpan", kEmojiFont},
      {"U+1F469", "ja-Jpan,zh-Hans", kEmojiFont},

      {"U+1F469", "zh-Hans,ja-Jpan,zh-Hant", kEmojiFont},
      {"U+1F469", "zh-Hans,zh-Hant,ja-Jpan", kEmojiFont},
      {"U+1F469", "ja-Jpan,zh-Hans,zh-Hant", kEmojiFont},
      {"U+1F469", "ja-Jpan,zh-Hant,zh-Hans", kEmojiFont},
      {"U+1F469", "zh-Hant,zh-Hans,ja-Jpan", kEmojiFont},
      {"U+1F469", "zh-Hant,ja-Jpan,zh-Hans", kEmojiFont},
  };

  std::shared_ptr<FontCollection> collection(
      getFontCollection(kTestFontDir, kItemizeFontXml));

  for (auto testCase : testCases) {
    SCOPED_TRACE("Test for \"" + testCase.testString + "\" with languages " +
                 testCase.requestedLanguages);

    std::vector<FontCollection::Run> runs;
    const FontStyle style =
        FontStyle(FontStyle::registerLanguageList(testCase.requestedLanguages));
    itemize(collection, testCase.testString.c_str(), style, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(testCase.expectedFont, getFontPath(runs[0]));
  }
}

TEST_F(FontCollectionItemizeTest, itemize_emojiSelection_withFE0E) {
  std::shared_ptr<FontCollection> collection(
      getFontCollection(kTestFontDir, kEmojiXmlFile));
  std::vector<FontCollection::Run> runs;

  const FontStyle kDefaultFontStyle;

  // U+00A9 is a text default emoji which is only available in
  // TextEmojiFont.ttf. TextEmojiFont.ttf should be selected.
  itemize(collection, "U+00A9 U+FE0E", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kTextEmojiFont, getFontPath(runs[0]));

  // U+00A9 is a text default emoji which is only available in
  // ColorEmojiFont.ttf. ColorEmojiFont.ttf should be selected.
  itemize(collection, "U+00AE U+FE0E", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  // Text emoji is specified but it is not available. Use color emoji instead.
  EXPECT_EQ(kColorEmojiFont, getFontPath(runs[0]));

  // U+203C is a text default emoji which is available in both TextEmojiFont.ttf
  // and ColorEmojiFont.ttf. TextEmojiFont.ttf should be selected.
  itemize(collection, "U+203C U+FE0E", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kTextEmojiFont, getFontPath(runs[0]));

  // U+2049 is a text default emoji which is not available either
  // TextEmojiFont.ttf or ColorEmojiFont.ttf. No font should be selected.
  itemize(collection, "U+2049 U+FE0E", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kNoGlyphFont, getFontPath(runs[0]));

  // U+231A is a emoji default emoji which is available only in TextEmojifFont.
  // TextEmojiFont.ttf sohuld be selected.
  itemize(collection, "U+231A U+FE0E", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kTextEmojiFont, getFontPath(runs[0]));

  // U+231B is a emoji default emoji which is available only in
  // ColorEmojiFont.ttf. ColorEmojiFont.ttf should be selected.
  itemize(collection, "U+231B U+FE0E", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  // Text emoji is specified but it is not available. Use color emoji instead.
  EXPECT_EQ(kColorEmojiFont, getFontPath(runs[0]));

  // U+23E9 is a emoji default emoji which is available in both
  // TextEmojiFont.ttf and ColorEmojiFont.ttf. TextEmojiFont.ttf should be
  // selected even if U+23E9 is emoji default emoji since U+FE0E is appended.
  itemize(collection, "U+23E9 U+FE0E", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kTextEmojiFont, getFontPath(runs[0]));

  // U+23EA is a emoji default emoji but which is not available in either
  // TextEmojiFont.ttf or ColorEmojiFont.ttf. No font should be selected.
  itemize(collection, "U+23EA U+FE0E", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kNoGlyphFont, getFontPath(runs[0]));

  // U+26FA U+FE0E is specified but ColorTextMixedEmojiFont has a variation
  // sequence U+26F9 U+FE0F in its cmap, so ColorTextMixedEmojiFont should be
  // selected instaed of ColorEmojiFont.
  itemize(collection, "U+26FA U+FE0E", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kMixedEmojiFont, getFontPath(runs[0]));
}

TEST_F(FontCollectionItemizeTest, itemize_emojiSelection_withFE0F) {
  std::shared_ptr<FontCollection> collection(
      getFontCollection(kTestFontDir, kEmojiXmlFile));
  std::vector<FontCollection::Run> runs;

  const FontStyle kDefaultFontStyle;

  // U+00A9 is a text default emoji which is available only in
  // TextEmojiFont.ttf. TextEmojiFont.ttf should be selected.
  itemize(collection, "U+00A9 U+FE0F", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  // Color emoji is specified but it is not available. Use text representation
  // instead.
  EXPECT_EQ(kTextEmojiFont, getFontPath(runs[0]));

  // U+00AE is a text default emoji which is available only in
  // ColorEmojiFont.ttf. ColorEmojiFont.ttf should be selected.
  itemize(collection, "U+00AE U+FE0F", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kColorEmojiFont, getFontPath(runs[0]));

  // U+203C is a text default emoji which is available in both TextEmojiFont.ttf
  // and ColorEmojiFont.ttf. ColorEmojiFont.ttf should be selected even if
  // U+203C is a text default emoji since U+FF0F is appended.
  itemize(collection, "U+203C U+FE0F", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kColorEmojiFont, getFontPath(runs[0]));

  // U+2049 is a text default emoji which is not available in either
  // TextEmojiFont.ttf or ColorEmojiFont.ttf. No font should be selected.
  itemize(collection, "U+2049 U+FE0F", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kNoGlyphFont, getFontPath(runs[0]));

  // U+231A is a emoji default emoji which is available only in
  // TextEmojiFont.ttf. TextEmojiFont.ttf should be selected.
  itemize(collection, "U+231A U+FE0F", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  // Color emoji is specified but it is not available. Use text representation
  // instead.
  EXPECT_EQ(kTextEmojiFont, getFontPath(runs[0]));

  // U+231B is a emoji default emoji which is available only in
  // ColorEmojiFont.ttf. ColorEmojiFont.ttf should be selected.
  itemize(collection, "U+231B U+FE0F", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kColorEmojiFont, getFontPath(runs[0]));

  // U+23E9 is a emoji default emoji which is available in both
  // TextEmojiFont.ttf and ColorEmojiFont.ttf. ColorEmojiFont.ttf should be
  // selected.
  itemize(collection, "U+23E9 U+FE0F", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kColorEmojiFont, getFontPath(runs[0]));

  // U+23EA is a emoji default emoji which is not available in either
  // TextEmojiFont.ttf or ColorEmojiFont.ttf. No font should be selected.
  itemize(collection, "U+23EA U+FE0F", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kNoGlyphFont, getFontPath(runs[0]));

  // U+26F9 U+FE0F is specified but ColorTextMixedEmojiFont has a variation
  // sequence U+26F9 U+FE0F in its cmap, so ColorTextMixedEmojiFont should be
  // selected instaed of ColorEmojiFont.
  itemize(collection, "U+26F9 U+FE0F", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kMixedEmojiFont, getFontPath(runs[0]));
}

TEST_F(FontCollectionItemizeTest, itemize_emojiSelection_with_skinTone) {
  std::shared_ptr<FontCollection> collection(
      getFontCollection(kTestFontDir, kEmojiXmlFile));
  std::vector<FontCollection::Run> runs;

  const FontStyle kDefaultFontStyle;

  // TextEmoji font is selected since it is listed before ColorEmoji font.
  itemize(collection, "U+261D", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(1, runs[0].end);
  EXPECT_EQ(kTextEmojiFont, getFontPath(runs[0]));

  // If skin tone is specified, it should be colored.
  itemize(collection, "U+261D U+1F3FD", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(3, runs[0].end);
  EXPECT_EQ(kColorEmojiFont, getFontPath(runs[0]));

  // Still color font is selected if an emoji variation selector is specified.
  itemize(collection, "U+261D U+FE0F U+1F3FD", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(4, runs[0].end);
  EXPECT_EQ(kColorEmojiFont, getFontPath(runs[0]));

  // Text font should be selected if a text variation selector is specified and
  // skin tone is rendered by itself.
  itemize(collection, "U+261D U+FE0E U+1F3FD", kDefaultFontStyle, &runs);
  ASSERT_EQ(2U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kTextEmojiFont, getFontPath(runs[0]));
  EXPECT_EQ(2, runs[1].start);
  EXPECT_EQ(4, runs[1].end);
  EXPECT_EQ(kColorEmojiFont, getFontPath(runs[1]));
}

TEST_F(FontCollectionItemizeTest, itemize_PrivateUseArea) {
  std::shared_ptr<FontCollection> collection(
      getFontCollection(kTestFontDir, kEmojiXmlFile));
  std::vector<FontCollection::Run> runs;

  const FontStyle kDefaultFontStyle;

  // Should not set nullptr to the result run. (Issue 26808815)
  itemize(collection, "U+FEE10", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(2, runs[0].end);
  EXPECT_EQ(kNoGlyphFont, getFontPath(runs[0]));

  itemize(collection, "U+FEE40 U+FE4C5", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(4, runs[0].end);
  EXPECT_EQ(kNoGlyphFont, getFontPath(runs[0]));
}

TEST_F(FontCollectionItemizeTest, itemize_genderBalancedEmoji) {
  std::shared_ptr<FontCollection> collection(
      getFontCollection(kTestFontDir, kEmojiXmlFile));
  std::vector<FontCollection::Run> runs;

  const FontStyle kDefaultFontStyle;

  itemize(collection, "U+1F469 U+200D U+1F373", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(5, runs[0].end);
  EXPECT_EQ(kColorEmojiFont, getFontPath(runs[0]));

  itemize(collection, "U+1F469 U+200D U+2695 U+FE0F", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(5, runs[0].end);
  EXPECT_EQ(kColorEmojiFont, getFontPath(runs[0]));

  itemize(collection, "U+1F469 U+200D U+2695", kDefaultFontStyle, &runs);
  ASSERT_EQ(1U, runs.size());
  EXPECT_EQ(0, runs[0].start);
  EXPECT_EQ(4, runs[0].end);
  EXPECT_EQ(kColorEmojiFont, getFontPath(runs[0]));
}

// For b/29585939
TEST_F(FontCollectionItemizeTest, itemizeShouldKeepOrderForVS) {
  const FontStyle kDefaultFontStyle;

  std::shared_ptr<MinikinFont> dummyFont(new MinikinFontForTest(kNoGlyphFont));
  std::shared_ptr<MinikinFont> fontA(new MinikinFontForTest(kZH_HansFont));
  std::shared_ptr<MinikinFont> fontB(new MinikinFontForTest(kZH_HansFont));

  std::shared_ptr<FontFamily> dummyFamily(
      new FontFamily(std::vector<Font>({Font(dummyFont, FontStyle())})));
  std::shared_ptr<FontFamily> familyA(
      new FontFamily(std::vector<Font>({Font(fontA, FontStyle())})));
  std::shared_ptr<FontFamily> familyB(
      new FontFamily(std::vector<Font>({Font(fontB, FontStyle())})));

  std::vector<std::shared_ptr<FontFamily>> families = {dummyFamily, familyA,
                                                       familyB};
  std::vector<std::shared_ptr<FontFamily>> reversedFamilies = {
      dummyFamily, familyB, familyA};

  std::shared_ptr<FontCollection> collection(new FontCollection(families));
  std::shared_ptr<FontCollection> reversedCollection(
      new FontCollection(reversedFamilies));

  // Both fontA/fontB support U+35A8 but don't support U+35A8 U+E0100. The first
  // font should be selected.
  std::vector<FontCollection::Run> runs;
  itemize(collection, "U+35A8 U+E0100", kDefaultFontStyle, &runs);
  EXPECT_EQ(fontA.get(), runs[0].fakedFont.font);

  itemize(reversedCollection, "U+35A8 U+E0100", kDefaultFontStyle, &runs);
  EXPECT_EQ(fontB.get(), runs[0].fakedFont.font);
}

// For b/29585939
TEST_F(FontCollectionItemizeTest, itemizeShouldKeepOrderForVS2) {
  const FontStyle kDefaultFontStyle;

  std::shared_ptr<MinikinFont> dummyFont(new MinikinFontForTest(kNoGlyphFont));
  std::shared_ptr<MinikinFont> hasCmapFormat14Font(
      new MinikinFontForTest(kHasCmapFormat14Font));
  std::shared_ptr<MinikinFont> noCmapFormat14Font(
      new MinikinFontForTest(kNoCmapFormat14Font));

  std::shared_ptr<FontFamily> dummyFamily(
      new FontFamily(std::vector<Font>({Font(dummyFont, FontStyle())})));
  std::shared_ptr<FontFamily> hasCmapFormat14Family(new FontFamily(
      std::vector<Font>({Font(hasCmapFormat14Font, FontStyle())})));
  std::shared_ptr<FontFamily> noCmapFormat14Family(new FontFamily(
      std::vector<Font>({Font(noCmapFormat14Font, FontStyle())})));

  std::vector<std::shared_ptr<FontFamily>> families = {
      dummyFamily, hasCmapFormat14Family, noCmapFormat14Family};
  std::vector<std::shared_ptr<FontFamily>> reversedFamilies = {
      dummyFamily, noCmapFormat14Family, hasCmapFormat14Family};

  std::shared_ptr<FontCollection> collection(new FontCollection(families));
  std::shared_ptr<FontCollection> reversedCollection(
      new FontCollection(reversedFamilies));

  // Both hasCmapFormat14Font/noCmapFormat14Font support U+5380 but don't
  // support U+5380 U+E0100. The first font should be selected.
  std::vector<FontCollection::Run> runs;
  itemize(collection, "U+5380 U+E0100", kDefaultFontStyle, &runs);
  EXPECT_EQ(hasCmapFormat14Font.get(), runs[0].fakedFont.font);

  itemize(reversedCollection, "U+5380 U+E0100", kDefaultFontStyle, &runs);
  EXPECT_EQ(noCmapFormat14Font.get(), runs[0].fakedFont.font);
}

}  // namespace minikin
