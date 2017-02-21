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

#include "FontLanguageListCache.h"
#include "ICUTestBase.h"
#include "MinikinInternal.h"

namespace minikin {

typedef ICUTestBase FontLanguageListCacheTest;

TEST_F(FontLanguageListCacheTest, getId) {
    EXPECT_NE(0UL, FontStyle::registerLanguageList("en"));
    EXPECT_NE(0UL, FontStyle::registerLanguageList("jp"));
    EXPECT_NE(0UL, FontStyle::registerLanguageList("en,zh-Hans"));

    ScopedLock _l(gLock);

    EXPECT_EQ(0UL, putLanguageListToCacheLocked(""));

    EXPECT_EQ(putLanguageListToCacheLocked("en"), putLanguageListToCacheLocked("en"));
    EXPECT_NE(putLanguageListToCacheLocked("en"), putLanguageListToCacheLocked("jp"));

    EXPECT_EQ(putLanguageListToCacheLocked("en,zh-Hans"),
            putLanguageListToCacheLocked("en,zh-Hans"));
    EXPECT_NE(putLanguageListToCacheLocked("en,zh-Hans"),
            putLanguageListToCacheLocked("zh-Hans,en"));
    EXPECT_NE(putLanguageListToCacheLocked("en,zh-Hans"),
            putLanguageListToCacheLocked("jp"));
    EXPECT_NE(putLanguageListToCacheLocked("en,zh-Hans"),
            putLanguageListToCacheLocked("en"));
    EXPECT_NE(putLanguageListToCacheLocked("en,zh-Hans"),
            putLanguageListToCacheLocked("en,zh-Hant"));
}

TEST_F(FontLanguageListCacheTest, getById) {
    ScopedLock _l(gLock);

    uint32_t enLangId = putLanguageListToCacheLocked("en");
    uint32_t jpLangId = putLanguageListToCacheLocked("jp");
    FontLanguage english = getFontLanguagesFromCacheLocked(enLangId)[0];
    FontLanguage japanese = getFontLanguagesFromCacheLocked(jpLangId)[0];

    const FontLanguages& defLangs = getFontLanguagesFromCacheLocked(0);
    EXPECT_TRUE(defLangs.empty());

    const FontLanguages& langs = getFontLanguagesFromCacheLocked(
            putLanguageListToCacheLocked("en"));
    ASSERT_EQ(1UL, langs.size());
    EXPECT_EQ(english, langs[0]);

    const FontLanguages& langs2 = getFontLanguagesFromCacheLocked(
            putLanguageListToCacheLocked("en,jp"));
    ASSERT_EQ(2UL, langs2.size());
    EXPECT_EQ(english, langs2[0]);
    EXPECT_EQ(japanese, langs2[1]);
}

}  // namespace minikin
