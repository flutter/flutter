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

#include "HbFontCache.h"

#include <cutils/log.h>
#include <hb.h>
#include <hb-ot.h>
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

class HbFontCache : private OnEntryRemoved<int32_t, hb_font_t*> {
public:
    HbFontCache() : mCache(kMaxEntries) {
        mCache.setOnEntryRemovedListener(this);
    }

    // callback for OnEntryRemoved
    void operator()(int32_t& /* key */, hb_font_t*& value) {
        hb_font_destroy(value);
    }

    hb_font_t* get(int32_t fontId) {
        return mCache.get(fontId);
    }

    void put(int32_t fontId, hb_font_t* font) {
        mCache.put(fontId, font);
    }

    void clear() {
        mCache.clear();
    }

    void remove(int32_t fontId) {
        mCache.remove(fontId);
    }

private:
    static const size_t kMaxEntries = 100;

    LruCache<int32_t, hb_font_t*> mCache;
};

HbFontCache* getFontCacheLocked() {
    assertMinikinLocked();
    static HbFontCache* cache = nullptr;
    if (cache == nullptr) {
        cache = new HbFontCache();
    }
    return cache;
}

void purgeHbFontCacheLocked() {
    assertMinikinLocked();
    getFontCacheLocked()->clear();
}

void purgeHbFont(const MinikinFont* minikinFont) {
    AutoMutex _l(gMinikinLock);
    const int32_t fontId = minikinFont->GetUniqueId();
    getFontCacheLocked()->remove(fontId);
}

hb_font_t* getHbFontLocked(MinikinFont* minikinFont) {
    assertMinikinLocked();
    static hb_font_t* nullFaceFont = nullptr;
    if (minikinFont == nullptr) {
        if (nullFaceFont == nullptr) {
            nullFaceFont = hb_font_create(nullptr);
        }
        return nullFaceFont;
    }

    HbFontCache* fontCache = getFontCacheLocked();
    const int32_t fontId = minikinFont->GetUniqueId();
    hb_font_t* font = fontCache->get(fontId);
    if (font != nullptr) {
        return font;
    }

    hb_face_t* face = hb_face_create_for_tables(referenceTable, minikinFont, nullptr);
    hb_font_t* parent_font = hb_font_create(face);
    hb_ot_font_set_funcs(parent_font);

    unsigned int upem = hb_face_get_upem(face);
    hb_font_set_scale(parent_font, upem, upem);

    font = hb_font_create_sub_font(parent_font);
    hb_font_destroy(parent_font);
    hb_face_destroy(face);
    fontCache->put(fontId, font);
    return font;
}

}  // namespace android
