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

#include <minikin/Emoji.h>

namespace minikin {

bool isNewEmoji(uint32_t c) {
    // Emoji characters new in Unicode emoji 5.0.
    // From http://www.unicode.org/Public/emoji/5.0/emoji-data.txt
    // TODO: Remove once emoji-data.text 5.0 is in ICU or update to 6.0.
    if (c < 0x1F6F7 || c > 0x1F9E6) {
        // Optimization for characters outside the new emoji range.
        return false;
    }
    return (0x1F6F7 <= c && c <= 0x1F6F8)
            || c == 0x1F91F
            || (0x1F928 <= c && c <= 0x1F92F)
            || (0x1F931 <= c && c <= 0x1F932)
            || c == 0x1F94C
            || (0x1F95F <= c && c <= 0x1F96B)
            || (0x1F992 <= c && c <= 0x1F997)
            || (0x1F9D0 <= c && c <= 0x1F9E6);
}

bool isEmoji(uint32_t c) {
#if WIP_NEEDS_ICU_UPDATE
    return false;
#else // WIP_NEEDS_ICU_UPDATE
    return isNewEmoji(c) || u_hasBinaryProperty(c, UCHAR_EMOJI);
#endif // WIP_NEEDS_ICU_UPDATE
}

bool isEmojiModifier(uint32_t c) {
#if WIP_NEEDS_ICU_UPDATE
    return false;
#else // WIP_NEEDS_ICU_UPDATE
    // Emoji modifier are not expected to change, so there's a small change we need to customize
    // this.
    return u_hasBinaryProperty(c, UCHAR_EMOJI_MODIFIER);
#endif // WIP_NEEDS_ICU_UPDATE
}

bool isEmojiBase(uint32_t c) {
#if WIP_NEEDS_ICU_UPDATE
    return false;
#else // WIP_NEEDS_ICU_UPDATE
    // These two characters were removed from Emoji_Modifier_Base in Emoji 4.0, but we need to keep
    // them as emoji modifier bases since there are fonts and user-generated text out there that
    // treats these as potential emoji bases.
    if (c == 0x1F91D || c == 0x1F93C) {
        return true;
    }
    // Emoji Modifier Base characters new in Unicode emoji 5.0.
    // From http://www.unicode.org/Public/emoji/5.0/emoji-data.txt
    // TODO: Remove once emoji-data.text 5.0 is in ICU or update to 6.0.
    if (c == 0x1F91F
            || (0x1F931 <= c && c <= 0x1F932)
            || (0x1F9D1 <= c && c <= 0x1F9DD)) {
        return true;
    }
    return u_hasBinaryProperty(c, UCHAR_EMOJI_MODIFIER_BASE);
#endif // WIP_NEEDS_ICU_UPDATE
}

UCharDirection emojiBidiOverride(const void* /* context */, UChar32 c) {
    if (isNewEmoji(c)) {
        // All new emoji characters in Unicode 10.0 are of the bidi class ON.
        return U_OTHER_NEUTRAL;
    } else {
        return u_charDirection(c);
    }
}

}  // namespace minikin

