/*
 * Copyright (C) 2016 The Android Open Source Project
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

#include "HbFontCache.h"

#include <cutils/log.h>
#include <hb.h>
#include <utils/Mutex.h>

#include "MinikinInternal.h"
#include "MinikinFontForTest.h"
#include <minikin/MinikinFont.h>

namespace android {
namespace {

class HbFontCacheTest : public testing::Test {
public:
    virtual void TearDown() {
        AutoMutex _l(gMinikinLock);
        purgeHbFontCacheLocked();
    }
};

TEST_F(HbFontCacheTest, getHbFontLockedTest) {
    AutoMutex _l(gMinikinLock);

    MinikinFontForTest fontA(kTestFontDir "Regular.ttf");
    MinikinFontForTest fontB(kTestFontDir "Bold.ttf");
    MinikinFontForTest fontC(kTestFontDir "BoldItalic.ttf");

    // Never return NULL.
    EXPECT_NE(nullptr, getHbFontLocked(&fontA));
    EXPECT_NE(nullptr, getHbFontLocked(&fontB));
    EXPECT_NE(nullptr, getHbFontLocked(&fontC));

    EXPECT_NE(nullptr, getHbFontLocked(nullptr));

    // Must return same object if same font object is passed.
    EXPECT_EQ(getHbFontLocked(&fontA), getHbFontLocked(&fontA));
    EXPECT_EQ(getHbFontLocked(&fontB), getHbFontLocked(&fontB));
    EXPECT_EQ(getHbFontLocked(&fontC), getHbFontLocked(&fontC));

    // Different object must be returned if the passed minikinFont has different ID.
    EXPECT_NE(getHbFontLocked(&fontA), getHbFontLocked(&fontB));
    EXPECT_NE(getHbFontLocked(&fontA), getHbFontLocked(&fontC));
}

TEST_F(HbFontCacheTest, purgeCacheTest) {
    AutoMutex _l(gMinikinLock);
    MinikinFontForTest minikinFont(kTestFontDir "Regular.ttf");

    hb_font_t* font = getHbFontLocked(&minikinFont);
    ASSERT_NE(nullptr, font);

    // Set user data to identify the font object.
    hb_user_data_key_t key;
    void* data = (void*)0xdeadbeef;
    hb_font_set_user_data(font, &key, data, NULL, false);
    ASSERT_EQ(data, hb_font_get_user_data(font, &key));

    purgeHbFontCacheLocked();

    // By checking user data, confirm that the object after purge is different from previously
    // created one. Do not compare the returned pointer here since memory allocator may assign
    // same region for new object.
    font = getHbFontLocked(&minikinFont);
    EXPECT_EQ(nullptr, hb_font_get_user_data(font, &key));
}

}  // namespace
}  // namespace android
