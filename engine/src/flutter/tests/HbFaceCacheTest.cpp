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

#include "HbFaceCache.h"

#include <cutils/log.h>
#include <hb.h>
#include <utils/Mutex.h>

#include "MinikinInternal.h"
#include <minikin/MinikinFont.h>

namespace android {
namespace {

// A mock implementation of MinikinFont. The passed integer value will be
// returned in GetUniqueId().
class MockMinikinFont : public MinikinFont {
public:
    MockMinikinFont(int32_t id) : mId(id) {
    }

    virtual bool GetGlyph(uint32_t codepoint, uint32_t *glyph) const {
        LOG_ALWAYS_FATAL("MockMinikinFont::GetGlyph is not implemented.");
        return false;
    }

    virtual float GetHorizontalAdvance(
            uint32_t glyph_id, const MinikinPaint &paint) const {
        LOG_ALWAYS_FATAL("MockMinikinFont::GetHorizontalAdvance is not implemented.");
        return 0.0f;
    }

    virtual void GetBounds(MinikinRect* bounds, uint32_t glyph_id,
            const MinikinPaint &paint) const {
        LOG_ALWAYS_FATAL("MockMinikinFont::GetBounds is not implemented.");
    }

    virtual bool GetTable(uint32_t tag, uint8_t *buf, size_t *size) {
        LOG_ALWAYS_FATAL("MockMinikinFont::GetTable is not implemented.");
        return false;
    }

    virtual int32_t GetUniqueId() const {
        return mId;
    }

private:
    int32_t mId;
};

class HbFaceCacheTest : public testing::Test {
public:
    virtual void TearDown() {
        AutoMutex _l(gMinikinLock);
        purgeHbFaceCacheLocked();
    }
};

TEST_F(HbFaceCacheTest, getHbFaceLockedTest) {
    AutoMutex _l(gMinikinLock);

    MockMinikinFont fontA(1);
    MockMinikinFont fontB(2);
    MockMinikinFont fontC(2);

    // Never return NULL.
    EXPECT_TRUE(getHbFaceLocked(&fontA));
    EXPECT_TRUE(getHbFaceLocked(&fontB));
    EXPECT_TRUE(getHbFaceLocked(&fontC));

    // Must return same object if same font object is passed.
    EXPECT_EQ(getHbFaceLocked(&fontA), getHbFaceLocked(&fontA));
    EXPECT_EQ(getHbFaceLocked(&fontB), getHbFaceLocked(&fontB));
    EXPECT_EQ(getHbFaceLocked(&fontC), getHbFaceLocked(&fontC));

    // Different object must be returned if the passed minikinFont has different ID.
    EXPECT_NE(getHbFaceLocked(&fontA), getHbFaceLocked(&fontB));
    EXPECT_NE(getHbFaceLocked(&fontA), getHbFaceLocked(&fontC));

    // Same object must be returned if the minikinFont has same Id.
    EXPECT_EQ(getHbFaceLocked(&fontB), getHbFaceLocked(&fontC));
}

TEST_F(HbFaceCacheTest, purgeCacheTest) {
    AutoMutex _l(gMinikinLock);
    MockMinikinFont font(1);

    hb_face_t* face = getHbFaceLocked(&font);
    EXPECT_TRUE(face);

    // Set user data to identify the face object.
    hb_user_data_key_t key;
    void* data = (void*)0xdeadbeef;
    hb_face_set_user_data(face, &key, data, NULL, false);
    EXPECT_EQ(data, hb_face_get_user_data(face, &key));

    purgeHbFaceCacheLocked();

    // By checking user data, confirm that the object after purge is different from previously
    // created one. Do not compare the returned pointer here since memory allocator may assign
    // same region for new object.
    face = getHbFaceLocked(&font);
    EXPECT_EQ(nullptr, hb_face_get_user_data(face, &key));
}

}  // namespace
}  // namespace android
