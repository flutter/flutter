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

namespace android {

TEST(FontLanguageListCacheTest, getId) {
    EXPECT_EQ(0UL, FontLanguageListCache::getId(""));
    EXPECT_NE(0UL, FontStyle::registerLanguageList("en"));
    EXPECT_NE(0UL, FontStyle::registerLanguageList("jp"));
    EXPECT_NE(0UL, FontStyle::registerLanguageList("en,zh-Hans"));

    EXPECT_EQ(FontLanguageListCache::getId("en"), FontLanguageListCache::getId("en"));
    EXPECT_NE(FontLanguageListCache::getId("en"), FontLanguageListCache::getId("jp"));

    EXPECT_EQ(FontLanguageListCache::getId("en,zh-Hans"),
              FontLanguageListCache::getId("en,zh-Hans"));
    EXPECT_NE(FontLanguageListCache::getId("en,zh-Hans"),
              FontLanguageListCache::getId("zh-Hans,en"));
    EXPECT_NE(FontLanguageListCache::getId("en,zh-Hans"),
              FontLanguageListCache::getId("jp"));
    EXPECT_NE(FontLanguageListCache::getId("en,zh-Hans"),
              FontLanguageListCache::getId("en"));
    EXPECT_NE(FontLanguageListCache::getId("en,zh-Hans"),
              FontLanguageListCache::getId("en,zh-Hant"));
}

TEST(FontLanguageListCacheTest, getById) {
    FontLanguage english("en", 2);
    FontLanguage japanese("jp", 2);

    EXPECT_EQ(0UL, FontLanguageListCache::getById(0).size());

    FontLanguages langs = FontLanguageListCache::getById(FontLanguageListCache::getId("en"));
    ASSERT_EQ(1UL, langs.size());
    EXPECT_EQ(english, langs[0]);

    langs = FontLanguageListCache::getById(FontLanguageListCache::getId("en,jp"));
    ASSERT_EQ(2UL, langs.size());
    EXPECT_EQ(english, langs[0]);
    EXPECT_EQ(japanese, langs[1]);
}

}  // android
