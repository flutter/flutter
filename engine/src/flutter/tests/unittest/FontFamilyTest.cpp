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

#include <minikin/FontFamily.h>

#include <android/log.h>
#include <gtest/gtest.h>

#include "FontLanguageListCache.h"
#include "ICUTestBase.h"
#include "MinikinFontForTest.h"
#include "MinikinInternal.h"

namespace minikin {

typedef ICUTestBase FontLanguagesTest;
typedef ICUTestBase FontLanguageTest;

static const FontLanguages& createFontLanguages(const std::string& input) {
    android::AutoMutex _l(gMinikinLock);
    uint32_t langId = FontLanguageListCache::getId(input);
    return FontLanguageListCache::getById(langId);
}

static FontLanguage createFontLanguage(const std::string& input) {
    android::AutoMutex _l(gMinikinLock);
    uint32_t langId = FontLanguageListCache::getId(input);
    return FontLanguageListCache::getById(langId)[0];
}

static FontLanguage createFontLanguageWithoutICUSanitization(const std::string& input) {
    return FontLanguage(input.c_str(), input.size());
}

TEST_F(FontLanguageTest, basicTests) {
    FontLanguage defaultLang;
    FontLanguage emptyLang("", 0);
    FontLanguage english = createFontLanguage("en");
    FontLanguage french = createFontLanguage("fr");
    FontLanguage und = createFontLanguage("und");
    FontLanguage undZsye = createFontLanguage("und-Zsye");

    EXPECT_EQ(english, english);
    EXPECT_EQ(french, french);

    EXPECT_TRUE(defaultLang != defaultLang);
    EXPECT_TRUE(emptyLang != emptyLang);
    EXPECT_TRUE(defaultLang != emptyLang);
    EXPECT_TRUE(defaultLang != und);
    EXPECT_TRUE(emptyLang != und);
    EXPECT_TRUE(english != defaultLang);
    EXPECT_TRUE(english != emptyLang);
    EXPECT_TRUE(english != french);
    EXPECT_TRUE(english != undZsye);
    EXPECT_TRUE(und != undZsye);
    EXPECT_TRUE(english != und);

    EXPECT_TRUE(defaultLang.isUnsupported());
    EXPECT_TRUE(emptyLang.isUnsupported());

    EXPECT_FALSE(english.isUnsupported());
    EXPECT_FALSE(french.isUnsupported());
    EXPECT_FALSE(und.isUnsupported());
    EXPECT_FALSE(undZsye.isUnsupported());
}

TEST_F(FontLanguageTest, getStringTest) {
    EXPECT_EQ("en-Latn-US", createFontLanguage("en").getString());
    EXPECT_EQ("en-Latn-US", createFontLanguage("en-Latn").getString());

    // Capitalized language code or lowercased script should be normalized.
    EXPECT_EQ("en-Latn-US", createFontLanguage("EN-LATN").getString());
    EXPECT_EQ("en-Latn-US", createFontLanguage("EN-latn").getString());
    EXPECT_EQ("en-Latn-US", createFontLanguage("en-latn").getString());

    // Invalid script should be kept.
    EXPECT_EQ("en-Xyzt-US", createFontLanguage("en-xyzt").getString());

    EXPECT_EQ("en-Latn-US", createFontLanguage("en-Latn-US").getString());
    EXPECT_EQ("ja-Jpan-JP", createFontLanguage("ja").getString());
    EXPECT_EQ("zh-Hant-TW", createFontLanguage("zh-TW").getString());
    EXPECT_EQ("zh-Hant-HK", createFontLanguage("zh-HK").getString());
    EXPECT_EQ("zh-Hant-MO", createFontLanguage("zh-MO").getString());
    EXPECT_EQ("zh-Hans-CN", createFontLanguage("zh").getString());
    EXPECT_EQ("zh-Hans-CN", createFontLanguage("zh-CN").getString());
    EXPECT_EQ("zh-Hans-SG", createFontLanguage("zh-SG").getString());
    EXPECT_EQ("und", createFontLanguage("und").getString());
    EXPECT_EQ("und", createFontLanguage("UND").getString());
    EXPECT_EQ("und", createFontLanguage("Und").getString());
    EXPECT_EQ("und-Zsye", createFontLanguage("und-Zsye").getString());
    EXPECT_EQ("und-Zsye", createFontLanguage("Und-ZSYE").getString());
    EXPECT_EQ("und-Zsye", createFontLanguage("Und-zsye").getString());

    EXPECT_EQ("de-Latn-DE", createFontLanguage("de-1901").getString());

    EXPECT_EQ("es-Latn-419", createFontLanguage("es-Latn-419").getString());

    // Emoji subtag is dropped from getString().
    EXPECT_EQ("es-Latn-419", createFontLanguage("es-419-u-em-emoji").getString());
    EXPECT_EQ("es-Latn-419", createFontLanguage("es-Latn-419-u-em-emoji").getString());

    // This is not a necessary desired behavior, just known behavior.
    EXPECT_EQ("en-Latn-US", createFontLanguage("und-Abcdefgh").getString());
}

TEST_F(FontLanguageTest, testReconstruction) {
    EXPECT_EQ("en", createFontLanguageWithoutICUSanitization("en").getString());
    EXPECT_EQ("fil", createFontLanguageWithoutICUSanitization("fil").getString());
    EXPECT_EQ("und", createFontLanguageWithoutICUSanitization("und").getString());

    EXPECT_EQ("en-Latn", createFontLanguageWithoutICUSanitization("en-Latn").getString());
    EXPECT_EQ("fil-Taga", createFontLanguageWithoutICUSanitization("fil-Taga").getString());
    EXPECT_EQ("und-Zsye", createFontLanguageWithoutICUSanitization("und-Zsye").getString());

    EXPECT_EQ("en-US", createFontLanguageWithoutICUSanitization("en-US").getString());
    EXPECT_EQ("fil-PH", createFontLanguageWithoutICUSanitization("fil-PH").getString());
    EXPECT_EQ("es-419", createFontLanguageWithoutICUSanitization("es-419").getString());

    EXPECT_EQ("en-Latn-US", createFontLanguageWithoutICUSanitization("en-Latn-US").getString());
    EXPECT_EQ("fil-Taga-PH", createFontLanguageWithoutICUSanitization("fil-Taga-PH").getString());
    EXPECT_EQ("es-Latn-419", createFontLanguageWithoutICUSanitization("es-Latn-419").getString());

    // Possible minimum/maximum values.
    EXPECT_EQ("aa", createFontLanguageWithoutICUSanitization("aa").getString());
    EXPECT_EQ("zz", createFontLanguageWithoutICUSanitization("zz").getString());
    EXPECT_EQ("aa-Aaaa", createFontLanguageWithoutICUSanitization("aa-Aaaa").getString());
    EXPECT_EQ("zz-Zzzz", createFontLanguageWithoutICUSanitization("zz-Zzzz").getString());
    EXPECT_EQ("aaa-Aaaa-AA", createFontLanguageWithoutICUSanitization("aaa-Aaaa-AA").getString());
    EXPECT_EQ("zzz-Zzzz-ZZ", createFontLanguageWithoutICUSanitization("zzz-Zzzz-ZZ").getString());
    EXPECT_EQ("aaa-Aaaa-000", createFontLanguageWithoutICUSanitization("aaa-Aaaa-000").getString());
    EXPECT_EQ("zzz-Zzzz-999", createFontLanguageWithoutICUSanitization("zzz-Zzzz-999").getString());
}

TEST_F(FontLanguageTest, ScriptEqualTest) {
    EXPECT_TRUE(createFontLanguage("en").isEqualScript(createFontLanguage("en")));
    EXPECT_TRUE(createFontLanguage("en-Latn").isEqualScript(createFontLanguage("en")));
    EXPECT_TRUE(createFontLanguage("jp-Latn").isEqualScript(createFontLanguage("en-Latn")));
    EXPECT_TRUE(createFontLanguage("en-Jpan").isEqualScript(createFontLanguage("en-Jpan")));

    EXPECT_FALSE(createFontLanguage("en-Jpan").isEqualScript(createFontLanguage("en-Hira")));
    EXPECT_FALSE(createFontLanguage("en-Jpan").isEqualScript(createFontLanguage("en-Hani")));
}

TEST_F(FontLanguageTest, ScriptMatchTest) {
    const bool SUPPORTED = true;
    const bool NOT_SUPPORTED = false;

    struct TestCase {
        const std::string baseScript;
        const std::string requestedScript;
        bool isSupported;
    } testCases[] = {
        // Same scripts
        { "en-Latn", "Latn", SUPPORTED },
        { "ja-Jpan", "Jpan", SUPPORTED },
        { "ja-Hira", "Hira", SUPPORTED },
        { "ja-Kana", "Kana", SUPPORTED },
        { "ja-Hrkt", "Hrkt", SUPPORTED },
        { "zh-Hans", "Hans", SUPPORTED },
        { "zh-Hant", "Hant", SUPPORTED },
        { "zh-Hani", "Hani", SUPPORTED },
        { "ko-Kore", "Kore", SUPPORTED },
        { "ko-Hang", "Hang", SUPPORTED },
        { "zh-Hanb", "Hanb", SUPPORTED },

        // Japanese supports Hiragana, Katakanara, etc.
        { "ja-Jpan", "Hira", SUPPORTED },
        { "ja-Jpan", "Kana", SUPPORTED },
        { "ja-Jpan", "Hrkt", SUPPORTED },
        { "ja-Hrkt", "Hira", SUPPORTED },
        { "ja-Hrkt", "Kana", SUPPORTED },

        // Chinese supports Han.
        { "zh-Hans", "Hani", SUPPORTED },
        { "zh-Hant", "Hani", SUPPORTED },
        { "zh-Hanb", "Hani", SUPPORTED },

        // Hanb supports Bopomofo.
        { "zh-Hanb", "Bopo", SUPPORTED },

        // Korean supports Hangul.
        { "ko-Kore", "Hang", SUPPORTED },

        // Different scripts
        { "ja-Jpan", "Latn", NOT_SUPPORTED },
        { "en-Latn", "Jpan", NOT_SUPPORTED },
        { "ja-Jpan", "Hant", NOT_SUPPORTED },
        { "zh-Hant", "Jpan", NOT_SUPPORTED },
        { "ja-Jpan", "Hans", NOT_SUPPORTED },
        { "zh-Hans", "Jpan", NOT_SUPPORTED },
        { "ja-Jpan", "Kore", NOT_SUPPORTED },
        { "ko-Kore", "Jpan", NOT_SUPPORTED },
        { "zh-Hans", "Hant", NOT_SUPPORTED },
        { "zh-Hant", "Hans", NOT_SUPPORTED },
        { "zh-Hans", "Kore", NOT_SUPPORTED },
        { "ko-Kore", "Hans", NOT_SUPPORTED },
        { "zh-Hant", "Kore", NOT_SUPPORTED },
        { "ko-Kore", "Hant", NOT_SUPPORTED },

        // Hiragana doesn't support Japanese, etc.
        { "ja-Hira", "Jpan", NOT_SUPPORTED },
        { "ja-Kana", "Jpan", NOT_SUPPORTED },
        { "ja-Hrkt", "Jpan", NOT_SUPPORTED },
        { "ja-Hani", "Jpan", NOT_SUPPORTED },
        { "ja-Hira", "Hrkt", NOT_SUPPORTED },
        { "ja-Kana", "Hrkt", NOT_SUPPORTED },
        { "ja-Hani", "Hrkt", NOT_SUPPORTED },
        { "ja-Hani", "Hira", NOT_SUPPORTED },
        { "ja-Hani", "Kana", NOT_SUPPORTED },

        // Kanji doesn't support Chinese, etc.
        { "zh-Hani", "Hant", NOT_SUPPORTED },
        { "zh-Hani", "Hans", NOT_SUPPORTED },
        { "zh-Hani", "Hanb", NOT_SUPPORTED },

        // Hangul doesn't support Korean, etc.
        { "ko-Hang", "Kore", NOT_SUPPORTED },
        { "ko-Hani", "Kore", NOT_SUPPORTED },
        { "ko-Hani", "Hang", NOT_SUPPORTED },
        { "ko-Hang", "Hani", NOT_SUPPORTED },

        // Han with botomofo doesn't support simplified Chinese, etc.
        { "zh-Hanb", "Hant", NOT_SUPPORTED },
        { "zh-Hanb", "Hans", NOT_SUPPORTED },
        { "zh-Hanb", "Jpan", NOT_SUPPORTED },
        { "zh-Hanb", "Kore", NOT_SUPPORTED },
    };

    for (auto testCase : testCases) {
        hb_script_t script = hb_script_from_iso15924_tag(
                HB_TAG(testCase.requestedScript[0], testCase.requestedScript[1],
                       testCase.requestedScript[2], testCase.requestedScript[3]));
        if (testCase.isSupported) {
            EXPECT_TRUE(
                    createFontLanguage(testCase.baseScript).supportsHbScript(script))
                    << testCase.baseScript << " should support " << testCase.requestedScript;
        } else {
            EXPECT_FALSE(
                    createFontLanguage(testCase.baseScript).supportsHbScript(script))
                    << testCase.baseScript << " shouldn't support " << testCase.requestedScript;
        }
    }
}

TEST_F(FontLanguagesTest, basicTests) {
    FontLanguages emptyLangs;
    EXPECT_EQ(0u, emptyLangs.size());

    FontLanguage english = createFontLanguage("en");
    const FontLanguages& singletonLangs = createFontLanguages("en");
    EXPECT_EQ(1u, singletonLangs.size());
    EXPECT_EQ(english, singletonLangs[0]);

    FontLanguage french = createFontLanguage("fr");
    const FontLanguages& twoLangs = createFontLanguages("en,fr");
    EXPECT_EQ(2u, twoLangs.size());
    EXPECT_EQ(english, twoLangs[0]);
    EXPECT_EQ(french, twoLangs[1]);
}

TEST_F(FontLanguagesTest, unsupportedLanguageTests) {
    const FontLanguages& oneUnsupported = createFontLanguages("abcd-example");
    EXPECT_TRUE(oneUnsupported.empty());

    const FontLanguages& twoUnsupporteds = createFontLanguages("abcd-example,abcd-example");
    EXPECT_TRUE(twoUnsupporteds.empty());

    FontLanguage english = createFontLanguage("en");
    const FontLanguages& firstUnsupported = createFontLanguages("abcd-example,en");
    EXPECT_EQ(1u, firstUnsupported.size());
    EXPECT_EQ(english, firstUnsupported[0]);

    const FontLanguages& lastUnsupported = createFontLanguages("en,abcd-example");
    EXPECT_EQ(1u, lastUnsupported.size());
    EXPECT_EQ(english, lastUnsupported[0]);
}

TEST_F(FontLanguagesTest, repeatedLanguageTests) {
    FontLanguage english = createFontLanguage("en");
    FontLanguage french = createFontLanguage("fr");
    FontLanguage canadianFrench = createFontLanguage("fr-CA");
    FontLanguage englishInLatn = createFontLanguage("en-Latn");
    ASSERT_TRUE(english == englishInLatn);

    const FontLanguages& langs = createFontLanguages("en,en-Latn");
    EXPECT_EQ(1u, langs.size());
    EXPECT_EQ(english, langs[0]);

    const FontLanguages& fr = createFontLanguages("fr,fr-FR,fr-Latn-FR");
    EXPECT_EQ(1u, fr.size());
    EXPECT_EQ(french, fr[0]);

    // ICU appends FR to fr. The third language is dropped which is same as the first language.
    const FontLanguages& fr2 = createFontLanguages("fr,fr-CA,fr-FR");
    EXPECT_EQ(2u, fr2.size());
    EXPECT_EQ(french, fr2[0]);
    EXPECT_EQ(canadianFrench, fr2[1]);

    // The order should be kept.
    const FontLanguages& langs2 = createFontLanguages("en,fr,en-Latn");
    EXPECT_EQ(2u, langs2.size());
    EXPECT_EQ(english, langs2[0]);
    EXPECT_EQ(french, langs2[1]);
}

TEST_F(FontLanguagesTest, identifierTest) {
    EXPECT_EQ(createFontLanguage("en-Latn-US"), createFontLanguage("en-Latn-US"));
    EXPECT_EQ(createFontLanguage("zh-Hans-CN"), createFontLanguage("zh-Hans-CN"));
    EXPECT_EQ(createFontLanguage("en-Zsye-US"), createFontLanguage("en-Zsye-US"));

    EXPECT_NE(createFontLanguage("en-Latn-US"), createFontLanguage("en-Latn-GB"));
    EXPECT_NE(createFontLanguage("en-Latn-US"), createFontLanguage("en-Zsye-US"));
    EXPECT_NE(createFontLanguage("es-Latn-US"), createFontLanguage("en-Latn-US"));
    EXPECT_NE(createFontLanguage("zh-Hant-HK"), createFontLanguage("zh-Hant-TW"));
}

TEST_F(FontLanguagesTest, undEmojiTests) {
    FontLanguage emoji = createFontLanguage("und-Zsye");
    EXPECT_EQ(FontLanguage::EMSTYLE_EMOJI, emoji.getEmojiStyle());

    FontLanguage und = createFontLanguage("und");
    EXPECT_EQ(FontLanguage::EMSTYLE_EMPTY, und.getEmojiStyle());
    EXPECT_FALSE(emoji == und);

    FontLanguage undExample = createFontLanguage("und-example");
    EXPECT_EQ(FontLanguage::EMSTYLE_EMPTY, undExample.getEmojiStyle());
    EXPECT_FALSE(emoji == undExample);
}

TEST_F(FontLanguagesTest, subtagEmojiTest) {
    std::string subtagEmojiStrings[] = {
        // Duplicate subtag case.
        "und-Latn-u-em-emoji-u-em-text",

        // Strings that contain language.
        "und-u-em-emoji",
        "en-u-em-emoji",

        // Strings that contain the script.
        "und-Jpan-u-em-emoji",
        "en-Latn-u-em-emoji",
        "und-Zsym-u-em-emoji",
        "und-Zsye-u-em-emoji",
        "en-Zsym-u-em-emoji",
        "en-Zsye-u-em-emoji",

        // Strings that contain the county.
        "und-US-u-em-emoji",
        "en-US-u-em-emoji",
        "es-419-u-em-emoji",
        "und-Latn-US-u-em-emoji",
        "en-Zsym-US-u-em-emoji",
        "en-Zsye-US-u-em-emoji",
        "es-Zsye-419-u-em-emoji",
    };

    for (auto subtagEmojiString : subtagEmojiStrings) {
        SCOPED_TRACE("Test for \"" + subtagEmojiString + "\"");
        FontLanguage subtagEmoji = createFontLanguage(subtagEmojiString);
        EXPECT_EQ(FontLanguage::EMSTYLE_EMOJI, subtagEmoji.getEmojiStyle());
    }
}

TEST_F(FontLanguagesTest, subtagTextTest) {
    std::string subtagTextStrings[] = {
        // Duplicate subtag case.
        "und-Latn-u-em-text-u-em-emoji",

        // Strings that contain language.
        "und-u-em-text",
        "en-u-em-text",

        // Strings that contain the script.
        "und-Latn-u-em-text",
        "en-Jpan-u-em-text",
        "und-Zsym-u-em-text",
        "und-Zsye-u-em-text",
        "en-Zsym-u-em-text",
        "en-Zsye-u-em-text",

        // Strings that contain the county.
        "und-US-u-em-text",
        "en-US-u-em-text",
        "es-419-u-em-text",
        "und-Latn-US-u-em-text",
        "en-Zsym-US-u-em-text",
        "en-Zsye-US-u-em-text",
        "es-Zsye-419-u-em-text",
    };

    for (auto subtagTextString : subtagTextStrings) {
        SCOPED_TRACE("Test for \"" + subtagTextString + "\"");
        FontLanguage subtagText = createFontLanguage(subtagTextString);
        EXPECT_EQ(FontLanguage::EMSTYLE_TEXT, subtagText.getEmojiStyle());
    }
}

// TODO: add more "und" language cases whose language and script are
//       unexpectedly translated to en-Latn by ICU.
TEST_F(FontLanguagesTest, subtagDefaultTest) {
    std::string subtagDefaultStrings[] = {
        // Duplicate subtag case.
        "en-Latn-u-em-default-u-em-emoji",
        "en-Latn-u-em-default-u-em-text",

        // Strings that contain language.
        "und-u-em-default",
        "en-u-em-default",

        // Strings that contain the script.
        "en-Latn-u-em-default",
        "en-Zsym-u-em-default",
        "en-Zsye-u-em-default",

        // Strings that contain the county.
        "en-US-u-em-default",
        "en-Latn-US-u-em-default",
        "es-Latn-419-u-em-default",
        "en-Zsym-US-u-em-default",
        "en-Zsye-US-u-em-default",
        "es-Zsye-419-u-em-default",
    };

    for (auto subtagDefaultString : subtagDefaultStrings) {
        SCOPED_TRACE("Test for \"" + subtagDefaultString + "\"");
        FontLanguage subtagDefault = createFontLanguage(subtagDefaultString);
        EXPECT_EQ(FontLanguage::EMSTYLE_DEFAULT, subtagDefault.getEmojiStyle());
    }
}

TEST_F(FontLanguagesTest, subtagEmptyTest) {
    std::string subtagEmptyStrings[] = {
        "und",
        "jp",
        "en-US",
        "en-Latn",
        "en-Latn-US",
        "en-Latn-US-u-em",
        "en-Latn-US-u-em-defaultemoji",
    };

    for (auto subtagEmptyString : subtagEmptyStrings) {
        SCOPED_TRACE("Test for \"" + subtagEmptyString + "\"");
        FontLanguage subtagEmpty = createFontLanguage(subtagEmptyString);
        EXPECT_EQ(FontLanguage::EMSTYLE_EMPTY, subtagEmpty.getEmojiStyle());
    }
}

TEST_F(FontLanguagesTest, registerLanguageListTest) {
    EXPECT_EQ(0UL, FontStyle::registerLanguageList(""));
    EXPECT_NE(0UL, FontStyle::registerLanguageList("en"));
    EXPECT_NE(0UL, FontStyle::registerLanguageList("jp"));
    EXPECT_NE(0UL, FontStyle::registerLanguageList("en,zh-Hans"));

    EXPECT_EQ(FontStyle::registerLanguageList("en"), FontStyle::registerLanguageList("en"));
    EXPECT_NE(FontStyle::registerLanguageList("en"), FontStyle::registerLanguageList("jp"));

    EXPECT_EQ(FontStyle::registerLanguageList("en,zh-Hans"),
              FontStyle::registerLanguageList("en,zh-Hans"));
    EXPECT_NE(FontStyle::registerLanguageList("en,zh-Hans"),
              FontStyle::registerLanguageList("zh-Hans,en"));
    EXPECT_NE(FontStyle::registerLanguageList("en,zh-Hans"),
              FontStyle::registerLanguageList("jp"));
    EXPECT_NE(FontStyle::registerLanguageList("en,zh-Hans"),
              FontStyle::registerLanguageList("en"));
    EXPECT_NE(FontStyle::registerLanguageList("en,zh-Hans"),
              FontStyle::registerLanguageList("en,zh-Hant"));
}

// The test font has following glyphs.
// U+82A6
// U+82A6 U+FE00 (VS1)
// U+82A6 U+E0100 (VS17)
// U+82A6 U+E0101 (VS18)
// U+82A6 U+E0102 (VS19)
// U+845B
// U+845B U+FE00 (VS2)
// U+845B U+E0101 (VS18)
// U+845B U+E0102 (VS19)
// U+845B U+E0103 (VS20)
// U+537F
// U+717D U+FE02 (VS3)
// U+717D U+E0102 (VS19)
// U+717D U+E0103 (VS20)
const char kVsTestFont[] = kTestFontDir "VarioationSelectorTest-Regular.ttf";

class FontFamilyTest : public ICUTestBase {
public:
    virtual void SetUp() override {
        ICUTestBase::SetUp();
        if (access(kVsTestFont, R_OK) != 0) {
            FAIL() << "Unable to read " << kVsTestFont << ". "
                   << "Please prepare the test data directory. "
                   << "For more details, please see how_to_run.txt.";
        }
    }
};

// Asserts that the font family has glyphs for and only for specified codepoint
// and variationSelector pairs.
void expectVSGlyphs(FontFamily* family, uint32_t codepoint, const std::set<uint32_t>& vs) {
    for (uint32_t i = 0xFE00; i <= 0xE01EF; ++i) {
        // Move to variation selectors supplements after variation selectors.
        if (i == 0xFF00) {
            i = 0xE0100;
        }
        if (vs.find(i) == vs.end()) {
            EXPECT_FALSE(family->hasGlyph(codepoint, i))
                    << "Glyph for U+" << std::hex << codepoint << " U+" << i;
        } else {
            EXPECT_TRUE(family->hasGlyph(codepoint, i))
                    << "Glyph for U+" << std::hex << codepoint << " U+" << i;
        }

    }
}

TEST_F(FontFamilyTest, hasVariationSelectorTest) {
    std::shared_ptr<MinikinFont> minikinFont(new MinikinFontForTest(kVsTestFont));
    std::shared_ptr<FontFamily> family(
            new FontFamily(std::vector<Font>{ Font(minikinFont, FontStyle()) }));

    android::AutoMutex _l(gMinikinLock);

    const uint32_t kVS1 = 0xFE00;
    const uint32_t kVS2 = 0xFE01;
    const uint32_t kVS3 = 0xFE02;
    const uint32_t kVS17 = 0xE0100;
    const uint32_t kVS18 = 0xE0101;
    const uint32_t kVS19 = 0xE0102;
    const uint32_t kVS20 = 0xE0103;

    const uint32_t kSupportedChar1 = 0x82A6;
    EXPECT_TRUE(family->getCoverage().get(kSupportedChar1));
    expectVSGlyphs(family.get(), kSupportedChar1, std::set<uint32_t>({kVS1, kVS17, kVS18, kVS19}));

    const uint32_t kSupportedChar2 = 0x845B;
    EXPECT_TRUE(family->getCoverage().get(kSupportedChar2));
    expectVSGlyphs(family.get(), kSupportedChar2, std::set<uint32_t>({kVS2, kVS18, kVS19, kVS20}));

    const uint32_t kNoVsSupportedChar = 0x537F;
    EXPECT_TRUE(family->getCoverage().get(kNoVsSupportedChar));
    expectVSGlyphs(family.get(), kNoVsSupportedChar, std::set<uint32_t>());

    const uint32_t kVsOnlySupportedChar = 0x717D;
    EXPECT_FALSE(family->getCoverage().get(kVsOnlySupportedChar));
    expectVSGlyphs(family.get(), kVsOnlySupportedChar, std::set<uint32_t>({kVS3, kVS19, kVS20}));

    const uint32_t kNotSupportedChar = 0x845C;
    EXPECT_FALSE(family->getCoverage().get(kNotSupportedChar));
    expectVSGlyphs(family.get(), kNotSupportedChar, std::set<uint32_t>());
}

TEST_F(FontFamilyTest, hasVSTableTest) {
    struct TestCase {
        const std::string fontPath;
        bool hasVSTable;
    } testCases[] = {
        { kTestFontDir "Ja.ttf", true },
        { kTestFontDir "ZhHant.ttf", true },
        { kTestFontDir "ZhHans.ttf", true },
        { kTestFontDir "Italic.ttf", false },
        { kTestFontDir "Bold.ttf", false },
        { kTestFontDir "BoldItalic.ttf", false },
    };

    for (auto testCase : testCases) {
        SCOPED_TRACE(testCase.hasVSTable ?
                "Font " + testCase.fontPath + " should have a variation sequence table." :
                "Font " + testCase.fontPath + " shouldn't have a variation sequence table.");

        std::shared_ptr<MinikinFont> minikinFont(
                new MinikinFontForTest(testCase.fontPath));
        std::shared_ptr<FontFamily> family(new FontFamily(
                std::vector<Font>{ Font(minikinFont, FontStyle()) }));
        android::AutoMutex _l(gMinikinLock);
        EXPECT_EQ(testCase.hasVSTable, family->hasVSTable());
    }
}

TEST_F(FontFamilyTest, createFamilyWithVariationTest) {
    // This font has 'wdth' and 'wght' axes.
    const char kMultiAxisFont[] = kTestFontDir "/MultiAxis.ttf";
    const char kNoAxisFont[] = kTestFontDir "/Regular.ttf";

    std::shared_ptr<MinikinFont> multiAxisFont(new MinikinFontForTest(kMultiAxisFont));
    std::shared_ptr<FontFamily> multiAxisFamily(
            std::shared_ptr<FontFamily>(new FontFamily(
                    std::vector<Font>({Font(multiAxisFont, FontStyle())}))));

    std::shared_ptr<MinikinFont> noAxisFont(new MinikinFontForTest(kNoAxisFont));
    std::shared_ptr<FontFamily> noAxisFamily(
            std::shared_ptr<FontFamily>(new FontFamily(
                    std::vector<Font>({Font(noAxisFont, FontStyle())}))));

    {
        // Do not ceate new instance if none of variations are specified.
        EXPECT_EQ(nullptr,
                multiAxisFamily->createFamilyWithVariation(std::vector<FontVariation>()));
        EXPECT_EQ(nullptr,
                noAxisFamily->createFamilyWithVariation(std::vector<FontVariation>()));
    }
    {
        // New instance should be used for supported variation.
        std::vector<FontVariation> variations = {{MinikinFont::MakeTag('w', 'd', 't', 'h'), 1.0f}};
        std::shared_ptr<FontFamily> newFamily(
                multiAxisFamily->createFamilyWithVariation(variations));
        EXPECT_NE(nullptr, newFamily.get());
        EXPECT_NE(multiAxisFamily.get(), newFamily.get());
        EXPECT_EQ(nullptr, noAxisFamily->createFamilyWithVariation(variations));
    }
    {
        // New instance should be used for supported variation. (multiple variations case)
        std::vector<FontVariation> variations = {
                { MinikinFont::MakeTag('w', 'd', 't', 'h'), 1.0f },
                { MinikinFont::MakeTag('w', 'g', 'h', 't'), 1.0f }
        };
        std::shared_ptr<FontFamily> newFamily(
                multiAxisFamily->createFamilyWithVariation(variations));
        EXPECT_NE(nullptr, newFamily.get());
        EXPECT_NE(multiAxisFamily.get(), newFamily.get());
        EXPECT_EQ(nullptr, noAxisFamily->createFamilyWithVariation(variations));
    }
    {
        // Do not ceate new instance if none of variations are supported.
        std::vector<FontVariation> variations = {
                { MinikinFont::MakeTag('Z', 'Z', 'Z', 'Z'), 1.0f }
        };
        EXPECT_EQ(nullptr, multiAxisFamily->createFamilyWithVariation(variations));
        EXPECT_EQ(nullptr, noAxisFamily->createFamilyWithVariation(variations));
    }
    {
        // At least one axis is supported, should create new instance.
        std::vector<FontVariation> variations = {
                { MinikinFont::MakeTag('w', 'd', 't', 'h'), 1.0f },
                { MinikinFont::MakeTag('Z', 'Z', 'Z', 'Z'), 1.0f }
        };
        std::shared_ptr<FontFamily> newFamily(
                multiAxisFamily->createFamilyWithVariation(variations));
        EXPECT_NE(nullptr, newFamily.get());
        EXPECT_NE(multiAxisFamily.get(), newFamily.get());
        EXPECT_EQ(nullptr, noAxisFamily->createFamilyWithVariation(variations));
    }
}

}  // namespace minikin
