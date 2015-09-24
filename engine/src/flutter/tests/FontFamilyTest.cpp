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

#include <minikin/FontFamily.h>
#include "MinikinFontForTest.h"
#include "MinikinInternal.h"

namespace android {

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
const char kVsTestFont[] = "/data/minikin/test/data/VarioationSelectorTest-Regular.ttf";

class FontFamilyTest : public testing::Test {
public:
    virtual void SetUp() override {
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
            EXPECT_FALSE(family->hasVariationSelector(codepoint, i))
                    << "Glyph for U+" << std::hex << codepoint << " U+" << i;
        } else {
            EXPECT_TRUE(family->hasVariationSelector(codepoint, i))
                    << "Glyph for U+" << std::hex << codepoint << " U+" << i;
        }

    }
}

TEST_F(FontFamilyTest, hasVariationSelectorTest) {
    MinikinFontForTest minikinFont(kVsTestFont);
    FontFamily family;
    family.addFont(&minikinFont);

    AutoMutex _l(gMinikinLock);

    const uint32_t kVS1 = 0xFE00;
    const uint32_t kVS2 = 0xFE01;
    const uint32_t kVS3 = 0xFE02;
    const uint32_t kVS17 = 0xE0100;
    const uint32_t kVS18 = 0xE0101;
    const uint32_t kVS19 = 0xE0102;
    const uint32_t kVS20 = 0xE0103;

    const uint32_t kSupportedChar1 = 0x82A6;
    EXPECT_TRUE(family.getCoverage()->get(kSupportedChar1));
    expectVSGlyphs(&family, kSupportedChar1, std::set<uint32_t>({kVS1, kVS17, kVS18, kVS19}));

    const uint32_t kSupportedChar2 = 0x845B;
    EXPECT_TRUE(family.getCoverage()->get(kSupportedChar2));
    expectVSGlyphs(&family, kSupportedChar2, std::set<uint32_t>({kVS2, kVS18, kVS19, kVS20}));

    const uint32_t kNoVsSupportedChar = 0x537F;
    EXPECT_TRUE(family.getCoverage()->get(kNoVsSupportedChar));
    expectVSGlyphs(&family, kNoVsSupportedChar, std::set<uint32_t>());

    const uint32_t kVsOnlySupportedChar = 0x717D;
    EXPECT_FALSE(family.getCoverage()->get(kVsOnlySupportedChar));
    expectVSGlyphs(&family, kVsOnlySupportedChar, std::set<uint32_t>({kVS3, kVS19, kVS20}));

    const uint32_t kNotSupportedChar = 0x845C;
    EXPECT_FALSE(family.getCoverage()->get(kNotSupportedChar));
    expectVSGlyphs(&family, kNotSupportedChar, std::set<uint32_t>());
}

TEST_F(FontFamilyTest, hasVariationSelectorWorksAfterpurgeHbFontCache) {
    MinikinFontForTest minikinFont(kVsTestFont);
    FontFamily family;
    family.addFont(&minikinFont);

    const uint32_t kVS1 = 0xFE00;
    const uint32_t kSupportedChar1 = 0x82A6;

    AutoMutex _l(gMinikinLock);
    EXPECT_TRUE(family.hasVariationSelector(kSupportedChar1, kVS1));

    family.purgeHbFontCache();
    EXPECT_TRUE(family.hasVariationSelector(kSupportedChar1, kVS1));
}
}  // namespace android
