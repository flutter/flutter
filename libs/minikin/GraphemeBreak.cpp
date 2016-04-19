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
#include <algorithm>
#include <unicode/uchar.h>
#include <unicode/utf16.h>

#include <minikin/GraphemeBreak.h>
#include "MinikinInternal.h"

namespace android {

int32_t tailoredGraphemeClusterBreak(uint32_t c) {
    // Characters defined as Control that we want to treat them as Extend.
    // These are curated manually.
    if (c == 0x00AD                         // SHY
            || c == 0x061C                  // ALM
            || c == 0x180E                  // MONGOLIAN VOWEL SEPARATOR
            || c == 0x200B                  // ZWSP
            || c == 0x200E                  // LRM
            || c == 0x200F                  // RLM
            || (0x202A <= c && c <= 0x202E) // LRE, RLE, PDF, LRO, RLO
            || ((c | 0xF) == 0x206F)        // WJ, invisible math operators, LRI, RLI, FSI, PDI,
                                            // and the deprecated invisible format controls
            || c == 0xFEFF                  // BOM
            || ((c | 0x7F) == 0xE007F))     // recently undeprecated tag characters in Plane 14
        return U_GCB_EXTEND;
    // UTC-approved characters for the Prepend class, per
    // http://www.unicode.org/L2/L2015/15183r-graph-cluster-brk.txt
    // These should be removed when our copy of ICU gets updated to Unicode 9.0 (~2016 or 2017).
    else if ((0x0600 <= c && c <= 0x0605) // Arabic subtending marks
            || c == 0x06DD                // ARABIC SUBTENDING MARK
            || c == 0x070F                // SYRIAC ABBREVIATION MARK
            || c == 0x0D4E                // MALAYALAM LETTER DOT REPH
            || c == 0x110BD               // KAITHI NUMBER SIGN
            || c == 0x111C2               // SHARADA SIGN JIHVAMULIYA
            || c == 0x111C3)              // SHARADA SIGN UPADHMANIYA
        return U_GCB_PREPEND;
    // THAI CHARACTER SARA AM is treated as a normal letter by most other implementations: they
    // allow a grapheme break before it.
    else if (c == 0x0E33)
        return U_GCB_OTHER;
    else
        return u_getIntPropertyValue(c, UCHAR_GRAPHEME_CLUSTER_BREAK);
}

// Returns true for all characters whose IndicSyllabicCategory is Pure_Killer.
// From http://www.unicode.org/Public/8.0.0/ucd/IndicSyllabicCategory.txt
bool isPureKiller(uint32_t c) {
    return (c == 0x0E3A || c == 0x0E4E || c == 0x0F84 || c == 0x103A || c == 0x1714 || c == 0x1734
            || c == 0x17D1 || c == 0x1BAA || c == 0x1BF2 || c == 0x1BF3 || c == 0xA806
            || c == 0xA953 || c == 0xABED || c == 0x11134 || c == 0x112EA || c == 0x1172B);
}

bool GraphemeBreak::isGraphemeBreak(const uint16_t* buf, size_t start, size_t count,
        size_t offset) {
    // This implementation closely follows Unicode Standard Annex #29 on
    // Unicode Text Segmentation (http://www.unicode.org/reports/tr29/),
    // implementing a tailored version of extended grapheme clusters.
    // The GB rules refer to section 3.1.1, Grapheme Cluster Boundary Rules.

    // Rule GB1, sot ÷; Rule GB2, ÷ eot
    if (offset <= start || offset >= start + count) {
        return true;
    }
    if (U16_IS_TRAIL(buf[offset])) {
        // Don't break a surrogate pair, but a lonely trailing surrogate pair is a break
        return !U16_IS_LEAD(buf[offset - 1]);
    }
    uint32_t c1 = 0;
    uint32_t c2 = 0;
    size_t offset_back = offset;
    U16_PREV(buf, start, offset_back, c1);
    U16_NEXT(buf, offset, start + count, c2);
    int32_t p1 = tailoredGraphemeClusterBreak(c1);
    int32_t p2 = tailoredGraphemeClusterBreak(c2);
    // Rule GB3, CR x LF
    if (p1 == U_GCB_CR && p2 == U_GCB_LF) {
        return false;
    }
    // Rule GB4, (Control | CR | LF) ÷
    if (p1 == U_GCB_CONTROL || p1 == U_GCB_CR || p1 == U_GCB_LF) {
        return true;
    }
    // Rule GB5, ÷ (Control | CR | LF)
    if (p2 == U_GCB_CONTROL || p2 == U_GCB_CR || p2 == U_GCB_LF) {
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
    if ((p1 == U_GCB_LVT || p1 == U_GCB_T) && p2 == U_GCB_T) {
        return false;
    }
    // Rule GB8a that looks at even-off cases.
    //
    // sot   (RI RI)*  RI x RI
    // [^RI] (RI RI)*  RI x RI
    //                 RI ÷ RI
    if (p1 == U_GCB_REGIONAL_INDICATOR && p2 == U_GCB_REGIONAL_INDICATOR) {
        // Look at up to 1000 code units.
        start = std::max((ssize_t)start, (ssize_t)offset_back - 1000);
        while (offset_back > start) {
            U16_PREV(buf, start, offset_back, c1);
            if (tailoredGraphemeClusterBreak(c1) != U_GCB_REGIONAL_INDICATOR) {
                offset_back += U16_LENGTH(c1);
                break;
            }
        }

        // Note that the offset has moved forwared 2 code units by U16_NEXT.
        // The number 4 comes from the number of code units in a whole flag.
        return (offset - 2 - offset_back) % 4 == 0;
    }
    // Rule GB9, x Extend; Rule GB9a, x SpacingMark; Rule GB9b, Prepend x
    if (p2 == U_GCB_EXTEND || p2 == U_GCB_SPACING_MARK || p1 == U_GCB_PREPEND) {
        return false;
    }
    // Cluster indic syllables together (tailoring of UAX #29)
    // Known limitation: this is overly conservative, and assumes that the virama may form a
    // conjunct with the following letter, which doesn't always happen.
    //
    // There is no easy solution to do this correctly. Even querying the font does not help (with
    // the current font technoloies), since the font may be creating the conjunct using multiple
    // glyphs, while the user may be perceiving that sequence of glyphs as one conjunct or one
    // letter.
    if (u_getIntPropertyValue(c1, UCHAR_CANONICAL_COMBINING_CLASS) == 9  // virama
            && !isPureKiller(c1)
            && u_getIntPropertyValue(c2, UCHAR_GENERAL_CATEGORY) == U_OTHER_LETTER) {
        return false;
    }
    // Tailoring: make emoji sequences with ZWJ a single grapheme cluster
    if (c1 == 0x200D && isEmoji(c2) && offset_back > start) {
        // look at character before ZWJ to see that both can participate in an emoji zwj sequence
        uint32_t c0 = 0;
        U16_PREV(buf, start, offset_back, c0);
        if (c0 == 0xFE0F && offset_back > start) {
            // skip over emoji variation selector
            U16_PREV(buf, start, offset_back, c0);
        }
        if (isEmoji(c0)) {
            return false;
        }
    }
    // Proposed Rule GB9c from http://www.unicode.org/L2/L2016/16011r3-break-prop-emoji.pdf
    // E_Base x E_Modifier
    if (isEmojiModifier(c2)) {
        if (c1 == 0xFE0F && offset_back > start) {
            // skip over emoji variation selector
            U16_PREV(buf, start, offset_back, c1);
        }
        if (isEmojiBase(c1)) {
            return false;
        }
    }
    // Rule GB10, Any ÷ Any
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
