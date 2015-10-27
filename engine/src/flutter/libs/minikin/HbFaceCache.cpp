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

#define LOG_TAG "Minikin"

#include "HbFaceCache.h"

#include <cutils/log.h>
#include <hb.h>
#include <utils/LruCache.h>

#include <minikin/MinikinFont.h>
#include "MinikinInternal.h"

namespace android {

static hb_blob_t* referenceTable(hb_face_t* /* face */, hb_tag_t tag, void* userData) {
    MinikinFont* font = reinterpret_cast<MinikinFont*>(userData);
    size_t length = 0;
    bool ok = font->GetTable(tag, NULL, &length);
    if (!ok) {
        return 0;
    }
    char* buffer = reinterpret_cast<char*>(malloc(length));
    if (!buffer) {
        return 0;
    }
    ok = font->GetTable(tag, reinterpret_cast<uint8_t*>(buffer), &length);
#ifdef VERBOSE_DEBUG
    ALOGD("referenceTable %c%c%c%c length=%zd %d",
        (tag >>24)&0xff, (tag>>16)&0xff, (tag>>8)&0xff, tag&0xff, length, ok);
#endif
    if (!ok) {
        free(buffer);
        return 0;
    }
    return hb_blob_create(const_cast<char*>(buffer), length,
            HB_MEMORY_MODE_WRITABLE, buffer, free);
}

class HbFaceCache : private OnEntryRemoved<int32_t, hb_face_t*> {
public:
    HbFaceCache() : mCache(kMaxEntries) {
        mCache.setOnEntryRemovedListener(this);
    }

    // callback for OnEntryRemoved
    void operator()(int32_t& /* key */, hb_face_t*& value) {
        hb_face_destroy(value);
    }

    hb_face_t* get(int32_t fontId) {
        return mCache.get(fontId);
    }

    void put(int32_t fontId, hb_face_t* face) {
        mCache.put(fontId, face);
    }

    void clear() {
        mCache.clear();
    }

private:
    static const size_t kMaxEntries = 100;

    LruCache<int32_t, hb_face_t*> mCache;
};

HbFaceCache* getFaceCacheLocked() {
    assertMinikinLocked();
    static HbFaceCache* cache = nullptr;
    if (cache == nullptr) {
        cache = new HbFaceCache();
    }
    return cache;
}

void purgeHbFaceCacheLocked() {
    assertMinikinLocked();
    getFaceCacheLocked()->clear();
}

hb_face_t* getHbFaceLocked(MinikinFont* minikinFont) {
    assertMinikinLocked();
    if (minikinFont == nullptr) {
        return nullptr;
    }

    HbFaceCache* faceCache = getFaceCacheLocked();
    const int32_t fontId = minikinFont->GetUniqueId();
    hb_face_t* face = faceCache->get(fontId);
    if (face != nullptr) {
        return face;
    }

    face = hb_face_create_for_tables(referenceTable, minikinFont, nullptr);
    faceCache->put(fontId, face);
    return face;
}

}  // namespace android
