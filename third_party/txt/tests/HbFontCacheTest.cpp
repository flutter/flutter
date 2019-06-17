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

#include "minikin/HbFontCache.h"

#include <gtest/gtest.h>
#include <log/log.h>

#include <memory>
#include <mutex>

#include <hb.h>

#include <minikin/MinikinFont.h>
#include "MinikinFontForTest.h"
#include "minikin/MinikinInternal.h"

namespace minikin {

class HbFontCacheTest : public testing::Test {
 public:
  virtual void TearDown() {
    std::scoped_lock _l(gMinikinLock);
    purgeHbFontCacheLocked();
  }
};

TEST_F(HbFontCacheTest, getHbFontLockedTest) {
  std::shared_ptr<MinikinFontForTest> fontA(
      new MinikinFontForTest(kTestFontDir "Regular.ttf"));

  std::shared_ptr<MinikinFontForTest> fontB(
      new MinikinFontForTest(kTestFontDir "Bold.ttf"));

  std::shared_ptr<MinikinFontForTest> fontC(
      new MinikinFontForTest(kTestFontDir "BoldItalic.ttf"));

  std::scoped_lock _l(gMinikinLock);
  // Never return NULL.
  EXPECT_NE(nullptr, getHbFontLocked(fontA.get()));
  EXPECT_NE(nullptr, getHbFontLocked(fontB.get()));
  EXPECT_NE(nullptr, getHbFontLocked(fontC.get()));

  EXPECT_NE(nullptr, getHbFontLocked(nullptr));

  // Must return same object if same font object is passed.
  EXPECT_EQ(getHbFontLocked(fontA.get()), getHbFontLocked(fontA.get()));
  EXPECT_EQ(getHbFontLocked(fontB.get()), getHbFontLocked(fontB.get()));
  EXPECT_EQ(getHbFontLocked(fontC.get()), getHbFontLocked(fontC.get()));

  // Different object must be returned if the passed minikinFont has different
  // ID.
  EXPECT_NE(getHbFontLocked(fontA.get()), getHbFontLocked(fontB.get()));
  EXPECT_NE(getHbFontLocked(fontA.get()), getHbFontLocked(fontC.get()));
}

TEST_F(HbFontCacheTest, purgeCacheTest) {
  std::shared_ptr<MinikinFontForTest> minikinFont(
      new MinikinFontForTest(kTestFontDir "Regular.ttf"));

  std::scoped_lock _l(gMinikinLock);
  hb_font_t* font = getHbFontLocked(minikinFont.get());
  ASSERT_NE(nullptr, font);

  // Set user data to identify the font object.
  hb_user_data_key_t key;
  void* data = (void*)0xdeadbeef;
  hb_font_set_user_data(font, &key, data, NULL, false);
  ASSERT_EQ(data, hb_font_get_user_data(font, &key));

  purgeHbFontCacheLocked();

  // By checking user data, confirm that the object after purge is different
  // from previously created one. Do not compare the returned pointer here since
  // memory allocator may assign same region for new object.
  font = getHbFontLocked(minikinFont.get());
  EXPECT_EQ(nullptr, hb_font_get_user_data(font, &key));
}

}  // namespace minikin
