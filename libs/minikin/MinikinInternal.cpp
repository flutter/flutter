/*
 * Copyright (C) 2014 The Android Open Source Project
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

// Definitions internal to Minikin
#define LOG_TAG "Minikin"

#include "MinikinInternal.h"
#include "HbFontCache.h"
#include "generated/UnicodeData.h"

#include <log/log.h>

namespace minikin {

android::Mutex gMinikinLock;

void assertMinikinLocked() {
#ifdef ENABLE_RACE_DETECTION
    LOG_ALWAYS_FATAL_IF(gMinikinLock.tryLock() == 0);
#endif
}

bool isEmoji(uint32_t c) {
    // U+2695 U+2640 U+2642 are not in emoji category in Unicode 9 but they are now emoji category.
    // TODO: remove once emoji database is updated.
    if (c == 0x2695 || c == 0x2640 || c == 0x2642) {
        return true;
    }
    const size_t length = sizeof(generated::EMOJI_LIST) / sizeof(generated::EMOJI_LIST[0]);
    return std::binary_search(generated::EMOJI_LIST, generated::EMOJI_LIST + length, c);
}

// Based on Modifiers from http://www.unicode.org/L2/L2016/16011-data-file.txt
bool isEmojiModifier(uint32_t c) {
    return (0x1F3FB <= c && c <= 0x1F3FF);
}

// Based on Emoji_Modifier_Base from
// http://www.unicode.org/Public/emoji/3.0/emoji-data.txt
bool isEmojiBase(uint32_t c) {
    if (0x261D <= c && c <= 0x270D) {
        return (c == 0x261D || c == 0x26F9 || (0x270A <= c && c <= 0x270D));
    } else if (0x1F385 <= c && c <= 0x1F93E) {
        return (c == 0x1F385
                || (0x1F3C3 <= c && c <= 0x1F3C4)
                || (0x1F3CA <= c && c <= 0x1F3CB)
                || (0x1F442 <= c && c <= 0x1F443)
                || (0x1F446 <= c && c <= 0x1F450)
                || (0x1F466 <= c && c <= 0x1F469)
                || c == 0x1F46E
                || (0x1F470 <= c && c <= 0x1F478)
                || c == 0x1F47C
                || (0x1F481 <= c && c <= 0x1F483)
                || (0x1F485 <= c && c <= 0x1F487)
                || c == 0x1F4AA
                || c == 0x1F575
                || c == 0x1F57A
                || c == 0x1F590
                || (0x1F595 <= c && c <= 0x1F596)
                || (0x1F645 <= c && c <= 0x1F647)
                || (0x1F64B <= c && c <= 0x1F64F)
                || c == 0x1F6A3
                || (0x1F6B4 <= c && c <= 0x1F6B6)
                || c == 0x1F6C0
                || (0x1F918 <= c && c <= 0x1F91E)
                || c == 0x1F926
                || c == 0x1F930
                || (0x1F933 <= c && c <= 0x1F939)
                || (0x1F93B <= c && c <= 0x1F93E));
    } else {
        return false;
    }
}

hb_blob_t* getFontTable(const MinikinFont* minikinFont, uint32_t tag) {
    assertMinikinLocked();
    hb_font_t* font = getHbFontLocked(minikinFont);
    hb_face_t* face = hb_font_get_face(font);
    hb_blob_t* blob = hb_face_reference_table(face, tag);
    hb_font_destroy(font);
    return blob;
}

}  // namespace minikin
