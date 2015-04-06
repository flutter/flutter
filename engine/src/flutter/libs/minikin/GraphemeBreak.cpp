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

#include <stdint.h>
#include <unicode/uchar.h>
#include <unicode/utf16.h>

#include <minikin/GraphemeBreak.h>

namespace android {

bool GraphemeBreak::isGraphemeBreak(const uint16_t* buf, size_t start, size_t count,
        size_t offset) {
    // This implementation closely follows Unicode Standard Annex #29 on
    // Unicode Text Segmentation (http://www.unicode.org/reports/tr29/),
    // implementing a tailored version of extended grapheme clusters.
    // The GB rules refer to section 3.1.1, Grapheme Cluster Boundary Rules.

    // Rule GB1, sot /; Rule GB2, / eot
    if (offset <= start || offset >= start + count) {
        return true;
    }
    if (U16_IS_TRAIL(buf[offset])) {
        // Don't break a surrogate pair
        return false;
    }
    uint32_t c1 = 0;
    uint32_t c2 = 0;
    size_t offset_back = offset;
    U16_PREV(buf, start, offset_back, c1);
    U16_NEXT(buf, offset, start + count, c2);
    int32_t p1 = u_getIntPropertyValue(c1, UCHAR_GRAPHEME_CLUSTER_BREAK);
    int32_t p2 = u_getIntPropertyValue(c2, UCHAR_GRAPHEME_CLUSTER_BREAK);
    // Rule GB3, CR x LF
    if (p1 == U_GCB_CR && p2 == U_GCB_LF) {
        return false;
    }
    // Rule GB4, (Control | CR | LF) /
    if (p1 == U_GCB_CONTROL || p1 == U_GCB_CR || p1 == U_GCB_LF) {
        return true;
    }
    // Rule GB5, / (Control | CR | LF)
    if (p2 == U_GCB_CONTROL || p2 == U_GCB_CR || p2 == U_GCB_LF) {
        // exclude zero-width control characters from breaking (tailoring of UAX #29)
        if (c2 == 0x00ad
                || (c2 >= 0x200b && c2 <= 0x200f)
                || (c2 >= 0x2028 && c2 <= 0x202e)
                || (c2 >= 0x2060 && c2 <= 0x206f)) {
            return false;
        }
        return true;
    }
    // Rule GB6, L x ( L | V | LV | LVT )
    if (p1 == U_GCB_L && (p2 == U_GCB_L || p2 == U_GCB_V || p2 == U_GCB_LV || p2 == U_GCB_LVT)) {
        return false;
    }
    // Rule GB7, ( LV | V ) x ( V | T )
    if ((p1 == U_GCB_LV || p1 == U_GCB_V) && (p2 == U_GCB_V || p2 == U_GCB_T)) {
        return false;
    }
    // Rule GB8, ( LVT | T ) x T
    if ((p1 == U_GCB_L || p1 == U_GCB_T) && p2 == U_GCB_T) {
        return false;
    }
    // Rule GB8a, Regional_Indicator x Regional_Indicator
    if (p1 == U_GCB_REGIONAL_INDICATOR && p2 == U_GCB_REGIONAL_INDICATOR) {
        return false;
    }
    // Rule GB9, x Extend; Rule GB9a, x SpacingMark
    if (p2 == U_GCB_EXTEND || p2 == U_GCB_SPACING_MARK) {
        if (c2 == 0xe33) {
            // most other implementations break THAI CHARACTER SARA AM
            // (tailoring of UAX #29)
            return true;
        }
        return false;
    }
    // Cluster indic syllables together (tailoring of UAX #29)
    if (u_getIntPropertyValue(c1, UCHAR_CANONICAL_COMBINING_CLASS) == 9  // virama
            && u_getIntPropertyValue(c2, UCHAR_GENERAL_CATEGORY) == U_OTHER_LETTER) {
        return false;
    }
    // Rule GB10, Any / Any
    return true;
}

size_t GraphemeBreak::getTextRunCursor(const uint16_t* buf, size_t start, size_t count,
        size_t offset, MoveOpt opt) {
    switch (opt) {
    case AFTER:
        if (offset < start + count) {
            offset++;
        }
        // fall through
    case AT_OR_AFTER:
        while (!isGraphemeBreak(buf, start, count, offset)) {
            offset++;
        }
        break;
    case BEFORE:
        if (offset > start) {
            offset--;
        }
        // fall through
    case AT_OR_BEFORE:
        while (!isGraphemeBreak(buf, start, count, offset)) {
            offset--;
        }
        break;
    case AT:
        if (!isGraphemeBreak(buf, start, count, offset)) {
            offset = (size_t)-1;
        }
        break;
    }
    return offset;
}

}  // namespace android
