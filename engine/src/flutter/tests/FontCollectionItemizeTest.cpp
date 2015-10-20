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

#include "FontTestUtils.h"
#include "MinikinFontForTest.h"
#include "UnicodeUtils.h"

using android::FontCollection;
using android::FontLanguage;
using android::FontStyle;

const char kEmojiFont[] = "/system/fonts/NotoColorEmoji.ttf";
const char kJAFont[] = "/system/fonts/NotoSansJP-Regular.otf";
const char kKOFont[] = "/system/fonts/NotoSansKR-Regular.otf";
const char kLatinBoldFont[] = "/system/fonts/Roboto-Bold.ttf";
const char kLatinBoldItalicFont[] = "/system/fonts/Roboto-BoldItalic.ttf";
const char kLatinFont[] = "/system/fonts/Roboto-Regular.ttf";
const char kLatinItalicFont[] = "/system/fonts/Roboto-Italic.ttf";
const char kZH_HansFont[] = "/system/fonts/NotoSansSC-Regular.otf";
const char kZH_HantFont[] = "/system/fonts/NotoSansTC-Regular.otf";

// Utility function for calling itemize function.
void itemize(FontCollection* collection, const char* str, FontStyle style,
        std::vector<FontCollection::Run>* result) {
    const size_t BUF_SIZE = 256;
    uint16_t buf[BUF_SIZE];
    size_t len;

    result->clear();
    ParseUnicode(buf, BUF_SIZE, str, &len, NULL);
    collection->itemize(buf, len, style, result);
}

// Utility function to obtain font path associated with run.
const std::string& getFontPath(const FontCollection::Run& run) {
    return ((MinikinFontForTest*)run.fakedFont.font)->fontPath();
}

TEST(FontCollectionItemizeTest, itemize_latin) {
    std::unique_ptr<FontCollection> collection = getFontCollection();
    std::vector<FontCollection::Run> runs;

    const FontStyle kRegularStyle = FontStyle();
    const FontStyle kItalicStyle = FontStyle(4, true);
    const FontStyle kBoldStyle = FontStyle(7, false);
    const FontStyle kBoldItalicStyle = FontStyle(7, true);

    itemize(collection.get(), "'a' 'b' 'c' 'd' 'e'", kRegularStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(5, runs[0].end);
    EXPECT_EQ(kLatinFont, getFontPath(runs[0]));
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

    itemize(collection.get(), "'a' 'b' 'c' 'd' 'e'", kItalicStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(5, runs[0].end);
    EXPECT_EQ(kLatinItalicFont, getFontPath(runs[0]));
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

    itemize(collection.get(), "'a' 'b' 'c' 'd' 'e'", kBoldStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(5, runs[0].end);
    EXPECT_EQ(kLatinBoldFont, getFontPath(runs[0]));
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

    itemize(collection.get(), "'a' 'b' 'c' 'd' 'e'", kBoldItalicStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(5, runs[0].end);
    EXPECT_EQ(kLatinBoldItalicFont, getFontPath(runs[0]));
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

    // Continue if the specific characters (e.g. hyphen, comma, etc.) is
    // followed.
    itemize(collection.get(), "'a' ',' '-' 'd' '!'", kRegularStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(5, runs[0].end);
    EXPECT_EQ(kLatinFont, getFontPath(runs[0]));
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

    itemize(collection.get(), "'a' ',' '-' 'd' '!'", kRegularStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(5, runs[0].end);
    EXPECT_EQ(kLatinFont, getFontPath(runs[0]));
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

    // U+0301(COMBINING ACUTE ACCENT) must be in the same run with preceding
    // chars if the font supports it.
    itemize(collection.get(), "'a' U+0301", kRegularStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(2, runs[0].end);
    EXPECT_EQ(kLatinFont, getFontPath(runs[0]));
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());
}

TEST(FontCollectionItemizeTest, itemize_emoji) {
    std::unique_ptr<FontCollection> collection = getFontCollection();
    std::vector<FontCollection::Run> runs;

    itemize(collection.get(), "U+1F469 U+1F467", FontStyle(), &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(4, runs[0].end);
    EXPECT_EQ(kEmojiFont, getFontPath(runs[0]));
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

    // U+20E3(COMBINING ENCLOSING KEYCAP) must be in the same run with preceding
    // character if the font supports.
    itemize(collection.get(), "'0' U+20E3", FontStyle(), &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(2, runs[0].end);
    EXPECT_EQ(kEmojiFont, getFontPath(runs[0]));
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

    // Currently there is no fonts which has a glyph for 'a' + U+20E3, so they
    // are splitted into two.
    itemize(collection.get(), "'a' U+20E3", FontStyle(), &runs);
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

TEST(FontCollectionItemizeTest, itemize_non_latin) {
    std::unique_ptr<FontCollection> collection = getFontCollection();
    std::vector<FontCollection::Run> runs;

    FontStyle kJAStyle = FontStyle(FontLanguage("ja_JP", 5));
    FontStyle kUSStyle = FontStyle(FontLanguage("en_US", 5));
    FontStyle kZH_HansStyle = FontStyle(FontLanguage("zh_Hans", 7));

    // All Japanese Hiragana characters.
    itemize(collection.get(), "U+3042 U+3044 U+3046 U+3048 U+304A", kUSStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(5, runs[0].end);
    EXPECT_EQ(kJAFont, getFontPath(runs[0]));
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

    // All Korean Hangul characters.
    itemize(collection.get(), "U+B300 U+D55C U+BBFC U+AD6D", kUSStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(4, runs[0].end);
    EXPECT_EQ(kKOFont, getFontPath(runs[0]));
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

    // All Han characters ja, zh-Hans font having.
    // Japanese font should be selected if the specified language is Japanese.
    itemize(collection.get(), "U+81ED U+82B1 U+5FCD", kJAStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(3, runs[0].end);
    EXPECT_EQ(kJAFont, getFontPath(runs[0]));
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

    // Simplified Chinese font should be selected if the specified language is Simplified
    // Chinese.
    itemize(collection.get(), "U+81ED U+82B1 U+5FCD", kZH_HansStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(3, runs[0].end);
    EXPECT_EQ(kZH_HansFont, getFontPath(runs[0]));
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

    // Fallbacks to other fonts if there is no glyph in the specified language's
    // font. There is no character U+4F60 in Japanese.
    itemize(collection.get(), "U+81ED U+4F60 U+5FCD", kJAStyle, &runs);
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
    itemize(collection.get(), "U+4444 U+302D", FontStyle(), &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(2, runs[0].end);
    EXPECT_EQ(kZH_HansFont, getFontPath(runs[0]));
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());
}

TEST(FontCollectionItemizeTest, itemize_mixed) {
    std::unique_ptr<FontCollection> collection = getFontCollection();
    std::vector<FontCollection::Run> runs;

    FontStyle kUSStyle = FontStyle(FontLanguage("en_US", 5));

    itemize(collection.get(), "'a' U+4F60 'b' U+4F60 'c'", kUSStyle, &runs);
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

TEST(FontCollectionItemizeTest, itemize_variationSelector) {
    std::unique_ptr<FontCollection> collection = getFontCollection();
    std::vector<FontCollection::Run> runs;

    // A glyph for U+4FAE is provided by both Japanese font and Simplified
    // Chinese font. Also a glyph for U+242EE is provided by both Japanese and
    // Traditional Chinese font.  To avoid effects of device default locale,
    // explicitly specify the locale.
    FontStyle kZH_HansStyle = FontStyle(FontLanguage("zh_Hans", 7));
    FontStyle kZH_HantStyle = FontStyle(FontLanguage("zh_Hant", 7));

    // U+4FAE is available in both zh_Hans and ja font, but U+4FAE,U+FE00 is
    // only available in ja font.
    itemize(collection.get(), "U+4FAE", kZH_HansStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(1, runs[0].end);
    EXPECT_EQ(kZH_HansFont, getFontPath(runs[0]));

    itemize(collection.get(), "U+4FAE U+FE00", kZH_HansStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(2, runs[0].end);
    EXPECT_EQ(kJAFont, getFontPath(runs[0]));

    itemize(collection.get(), "U+4FAE U+4FAE U+FE00", kZH_HansStyle, &runs);
    ASSERT_EQ(2U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(1, runs[0].end);
    EXPECT_EQ(kZH_HansFont, getFontPath(runs[0]));
    EXPECT_EQ(1, runs[1].start);
    EXPECT_EQ(3, runs[1].end);
    EXPECT_EQ(kJAFont, getFontPath(runs[1]));

    itemize(collection.get(), "U+4FAE U+4FAE U+FE00 U+4FAE", kZH_HansStyle, &runs);
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
    itemize(collection.get(), "U+4FAE U+FE00 U+FE00", kZH_HansStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(3, runs[0].end);
    EXPECT_EQ(kJAFont, getFontPath(runs[1]));

    // No font supports U+242EE U+FE0E.
    itemize(collection.get(), "U+4FAE U+FE0E", kZH_HansStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(2, runs[0].end);
    EXPECT_EQ(kZH_HansFont, getFontPath(runs[0]));

    // Surrogate pairs handling.
    // U+242EE is available in ja font and zh_Hant font.
    // U+242EE U+FE00 is available only in ja font.
    itemize(collection.get(), "U+242EE", kZH_HantStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(2, runs[0].end);
    EXPECT_EQ(kZH_HantFont, getFontPath(runs[0]));

    itemize(collection.get(), "U+242EE U+FE00", kZH_HantStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(3, runs[0].end);
    EXPECT_EQ(kJAFont, getFontPath(runs[0]));

    itemize(collection.get(), "U+242EE U+242EE U+FE00", kZH_HantStyle, &runs);
    ASSERT_EQ(2U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(2, runs[0].end);
    EXPECT_EQ(kZH_HantFont, getFontPath(runs[0]));
    EXPECT_EQ(2, runs[1].start);
    EXPECT_EQ(5, runs[1].end);
    EXPECT_EQ(kJAFont, getFontPath(runs[1]));

    itemize(collection.get(), "U+242EE U+242EE U+FE00 U+242EE", kZH_HantStyle, &runs);
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
    itemize(collection.get(), "U+242EE U+FE00 U+FE00", kZH_HansStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(4, runs[0].end);
    EXPECT_EQ(kJAFont, getFontPath(runs[0]));

    // No font supports U+242EE U+FE0E
    itemize(collection.get(), "U+242EE U+FE0E", kZH_HantStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(3, runs[0].end);
    EXPECT_EQ(kZH_HantFont, getFontPath(runs[0]));

    // Isolated variation selector supplement.
    itemize(collection.get(), "U+FE00", FontStyle(), &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(1, runs[0].end);
    EXPECT_EQ(kLatinFont, getFontPath(runs[0]));

    itemize(collection.get(), "U+FE00", kZH_HantStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(1, runs[0].end);
    EXPECT_EQ(kLatinFont, getFontPath(runs[0]));
}

TEST(FontCollectionItemizeTest, itemize_variationSelectorSupplement) {
    std::unique_ptr<FontCollection> collection = getFontCollection();
    std::vector<FontCollection::Run> runs;

    // A glyph for U+845B is provided by both Japanese font and Simplified
    // Chinese font. Also a glyph for U+242EE is provided by both Japanese and
    // Traditional Chinese font.  To avoid effects of device default locale,
    // explicitly specify the locale.
    FontStyle kZH_HansStyle = FontStyle(FontLanguage("zh_Hans", 7));
    FontStyle kZH_HantStyle = FontStyle(FontLanguage("zh_Hant", 7));

    // U+845B is available in both zh_Hans and ja font, but U+845B,U+E0100 is
    // only available in ja font.
    itemize(collection.get(), "U+845B", kZH_HansStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(1, runs[0].end);
    EXPECT_EQ(kZH_HansFont, getFontPath(runs[0]));

    itemize(collection.get(), "U+845B U+E0100", kZH_HansStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(3, runs[0].end);
    EXPECT_EQ(kJAFont, getFontPath(runs[0]));

    itemize(collection.get(), "U+845B U+845B U+E0100", kZH_HansStyle, &runs);
    ASSERT_EQ(2U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(1, runs[0].end);
    EXPECT_EQ(kZH_HansFont, getFontPath(runs[0]));
    EXPECT_EQ(1, runs[1].start);
    EXPECT_EQ(4, runs[1].end);
    EXPECT_EQ(kJAFont, getFontPath(runs[1]));

    itemize(collection.get(), "U+845B U+845B U+E0100 U+845B", kZH_HansStyle, &runs);
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
    itemize(collection.get(), "U+845B U+E0100 U+E0100", kZH_HansStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(5, runs[0].end);
    EXPECT_EQ(kJAFont, getFontPath(runs[0]));

    // No font supports U+845B U+E01E0.
    itemize(collection.get(), "U+845B U+E01E0", kZH_HansStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(3, runs[0].end);
    EXPECT_EQ(kZH_HansFont, getFontPath(runs[0]));

    // Isolated variation selector supplement
    // Surrogate pairs handling.
    // U+242EE is available in ja font and zh_Hant font.
    // U+242EE U+E0100 is available only in ja font.
    itemize(collection.get(), "U+242EE", kZH_HantStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(2, runs[0].end);
    EXPECT_EQ(kZH_HantFont, getFontPath(runs[0]));

    itemize(collection.get(), "U+242EE U+E0101", kZH_HantStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(4, runs[0].end);
    EXPECT_EQ(kJAFont, getFontPath(runs[0]));

    itemize(collection.get(), "U+242EE U+242EE U+E0101", kZH_HantStyle, &runs);
    ASSERT_EQ(2U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(2, runs[0].end);
    EXPECT_EQ(kZH_HantFont, getFontPath(runs[0]));
    EXPECT_EQ(2, runs[1].start);
    EXPECT_EQ(6, runs[1].end);
    EXPECT_EQ(kJAFont, getFontPath(runs[1]));

    itemize(collection.get(), "U+242EE U+242EE U+E0101 U+242EE", kZH_HantStyle, &runs);
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
    itemize(collection.get(), "U+242EE U+E0100 U+E0100", kZH_HantStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(6, runs[0].end);
    EXPECT_EQ(kJAFont, getFontPath(runs[0]));

    // No font supports U+242EE U+E01E0.
    itemize(collection.get(), "U+242EE U+E01E0", kZH_HantStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(4, runs[0].end);
    EXPECT_EQ(kZH_HantFont, getFontPath(runs[0]));

    // Isolated variation selector supplement.
    itemize(collection.get(), "U+E0100", FontStyle(), &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(2, runs[0].end);
    EXPECT_EQ(kLatinFont, getFontPath(runs[0]));

    itemize(collection.get(), "U+E0100", kZH_HantStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(2, runs[0].end);
    EXPECT_EQ(kLatinFont, getFontPath(runs[0]));
}

TEST(FontCollectionItemizeTest, itemize_no_crash) {
    std::unique_ptr<FontCollection> collection = getFontCollection();
    std::vector<FontCollection::Run> runs;

    // Broken Surrogate pairs. Check only not crashing.
    itemize(collection.get(), "'a' U+D83D 'a'", FontStyle(), &runs);
    itemize(collection.get(), "'a' U+DC69 'a'", FontStyle(), &runs);
    itemize(collection.get(), "'a' U+D83D U+D83D 'a'", FontStyle(), &runs);
    itemize(collection.get(), "'a' U+DC69 U+DC69 'a'", FontStyle(), &runs);

    // Isolated variation selector. Check only not crashing.
    itemize(collection.get(), "U+FE00 U+FE00", FontStyle(), &runs);
    itemize(collection.get(), "U+E0100 U+E0100", FontStyle(), &runs);
    itemize(collection.get(), "U+FE00 U+E0100", FontStyle(), &runs);
    itemize(collection.get(), "U+E0100 U+FE00", FontStyle(), &runs);

    // Tone mark only. Check only not crashing.
    itemize(collection.get(), "U+302D", FontStyle(), &runs);
    itemize(collection.get(), "U+302D U+302D", FontStyle(), &runs);

    // Tone mark and variation selector mixed. Check only not crashing.
    itemize(collection.get(), "U+FE00 U+302D U+E0100", FontStyle(), &runs);
}

TEST(FontCollectionItemizeTest, itemize_fakery) {
    std::unique_ptr<FontCollection> collection = getFontCollection();
    std::vector<FontCollection::Run> runs;

    FontStyle kJABoldStyle = FontStyle(FontLanguage("ja_JP", 5), 0, 7, false);
    FontStyle kJAItalicStyle = FontStyle(FontLanguage("ja_JP", 5), 0, 5, true);
    FontStyle kJABoldItalicStyle = FontStyle(FontLanguage("ja_JP", 5), 0, 7, true);

    // Currently there is no italic or bold font for Japanese. FontFakery has
    // the differences between desired and actual font style.

    // All Japanese Hiragana characters.
    itemize(collection.get(), "U+3042 U+3044 U+3046 U+3048 U+304A", kJABoldStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(5, runs[0].end);
    EXPECT_EQ(kJAFont, getFontPath(runs[0]));
    EXPECT_TRUE(runs[0].fakedFont.fakery.isFakeBold());
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeItalic());

    // All Japanese Hiragana characters.
    itemize(collection.get(), "U+3042 U+3044 U+3046 U+3048 U+304A", kJAItalicStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(5, runs[0].end);
    EXPECT_EQ(kJAFont, getFontPath(runs[0]));
    EXPECT_FALSE(runs[0].fakedFont.fakery.isFakeBold());
    EXPECT_TRUE(runs[0].fakedFont.fakery.isFakeItalic());

    // All Japanese Hiragana characters.
    itemize(collection.get(), "U+3042 U+3044 U+3046 U+3048 U+304A", kJABoldItalicStyle, &runs);
    ASSERT_EQ(1U, runs.size());
    EXPECT_EQ(0, runs[0].start);
    EXPECT_EQ(5, runs[0].end);
    EXPECT_EQ(kJAFont, getFontPath(runs[0]));
    EXPECT_TRUE(runs[0].fakedFont.fakery.isFakeBold());
    EXPECT_TRUE(runs[0].fakedFont.fakery.isFakeItalic());
}

