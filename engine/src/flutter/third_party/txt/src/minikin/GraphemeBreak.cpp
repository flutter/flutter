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
#include <algorithm>

#include <minikin/Emoji.h>
#include <minikin/GraphemeBreak.h>
#include "MinikinInternal.h"
#include "utils/WindowsUtils.h"

namespace minikin {

int32_t tailoredGraphemeClusterBreak(uint32_t c) {
  // Characters defined as Control that we want to treat them as Extend.
  // These are curated manually.
  if (c == 0x00AD                      // SHY
      || c == 0x061C                   // ALM
      || c == 0x180E                   // MONGOLIAN VOWEL SEPARATOR
      || c == 0x200B                   // ZWSP
      || c == 0x200E                   // LRM
      || c == 0x200F                   // RLM
      || (0x202A <= c && c <= 0x202E)  // LRE, RLE, PDF, LRO, RLO
      || ((c | 0xF) ==
          0x206F)     // WJ, invisible math operators, LRI, RLI, FSI, PDI,
                      // and the deprecated invisible format controls
      || c == 0xFEFF  // BOM
      || ((c | 0x7F) ==
          0xE007F))  // recently undeprecated tag characters in Plane 14
    return U_GCB_EXTEND;
  // THAI CHARACTER SARA AM is treated as a normal letter by most other
  // implementations: they allow a grapheme break before it.
  else if (c == 0x0E33)
    return U_GCB_OTHER;
  else
    return u_getIntPropertyValue(c, UCHAR_GRAPHEME_CLUSTER_BREAK);
}

// Returns true for all characters whose IndicSyllabicCategory is Pure_Killer.
// From http://www.unicode.org/Public/9.0.0/ucd/IndicSyllabicCategory.txt
bool isPureKiller(uint32_t c) {
  return (c == 0x0E3A || c == 0x0E4E || c == 0x0F84 || c == 0x103A ||
          c == 0x1714 || c == 0x1734 || c == 0x17D1 || c == 0x1BAA ||
          c == 0x1BF2 || c == 0x1BF3 || c == 0xA806 || c == 0xA953 ||
          c == 0xABED || c == 0x11134 || c == 0x112EA || c == 0x1172B);
}

bool GraphemeBreak::isGraphemeBreak(const float* advances,
                                    const uint16_t* buf,
                                    size_t start,
                                    size_t count,
                                    const size_t offset) {
  // This implementation closely follows Unicode Standard Annex #29 on
  // Unicode Text Segmentation (http://www.unicode.org/reports/tr29/),
  // implementing a tailored version of extended grapheme clusters.
  // The GB rules refer to section 3.1.1, Grapheme Cluster Boundary Rules.

  // Rule GB1, sot ÷; Rule GB2, ÷ eot
  if (offset <= start || offset >= start + count) {
    return true;
  }
  if (U16_IS_TRAIL(buf[offset])) {
    // Don't break a surrogate pair, but a lonely trailing surrogate pair is a
    // break
    return !U16_IS_LEAD(buf[offset - 1]);
  }
  uint32_t c1 = 0;
  uint32_t c2 = 0;
  size_t offset_back = offset;
  size_t offset_forward = offset;
  U16_PREV(buf, start, offset_back, c1);
  U16_NEXT(buf, offset_forward, start + count, c2);
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
  if (p1 == U_GCB_L &&
      (p2 == U_GCB_L || p2 == U_GCB_V || p2 == U_GCB_LV || p2 == U_GCB_LVT)) {
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
  // Rule GB9, x (Extend | ZWJ); Rule GB9a, x SpacingMark; Rule GB9b, Prepend x
  if (p2 == U_GCB_EXTEND || p2 == U_GCB_ZWJ || p2 == U_GCB_SPACING_MARK ||
      p1 == U_GCB_PREPEND) {
    return false;
  }

  // This is used to decide font-dependent grapheme clusters. If we don't have
  // the advance information, we become conservative in grapheme breaking and
  // assume that it has no advance.
  const bool c2_has_advance =
      (advances != nullptr && advances[offset - start] != 0.0);

  // All the following rules are font-dependent, in the way that if we know c2
  // has an advance, we definitely know that it cannot form a grapheme with the
  // character(s) before it. So we make the decision in favor a grapheme break
  // early.
  if (c2_has_advance) {
    return true;
  }

  // Note: For Rule GB10 and GB11 below, we do not use the Unicode line breaking
  // properties for determining emoji-ness and carry our own data, because our
  // data could be more fresh than what ICU provides.
  //
  // Tailored version of Rule GB10, (E_Base | EBG) Extend* × E_Modifier.
  // The rule itself says do not break between emoji base and emoji modifiers,
  // skipping all Extend characters. Variation selectors are considered Extend,
  // so they are handled fine.
  //
  // We tailor this by requiring that an actual ligature is formed. If the font
  // doesn't form a ligature, we allow a break before the modifier.
  if (isEmojiModifier(c2)) {
    uint32_t c0 = c1;
    size_t offset_backback = offset_back;
    int32_t p0 = p1;
    if (p0 == U_GCB_EXTEND && offset_backback > start) {
      // skip over emoji variation selector
      U16_PREV(buf, start, offset_backback, c0);
    }
    if (isEmojiBase(c0)) {
      return false;
    }
  }

  // Tailored version of Rule GB11, ZWJ × (Glue_After_Zwj | EBG)
  // We try to make emoji sequences with ZWJ a single grapheme cluster, but only
  // if they actually merge to one cluster. So we are more relaxed than the UAX
  // #29 rules in accepting any emoji character after the ZWJ, but are tighter
  // in that we only treat it as one cluster if a ligature is actually formed
  // and we also require the character before the ZWJ to also be an emoji.
  if (p1 == U_GCB_ZWJ && isEmoji(c2) && offset_back > start) {
    // look at character before ZWJ to see that both can participate in an
    // emoji zwj sequence
    uint32_t c0 = 0;
    size_t offset_backback = offset_back;
    U16_PREV(buf, start, offset_backback, c0);
    if (c0 == 0xFE0F && offset_backback > start) {
      // skip over emoji variation selector
      U16_PREV(buf, start, offset_backback, c0);
    }
    if (isEmoji(c0)) {
      return false;
    }
  }

  // Tailored version of Rule GB12 and Rule GB13 that look at even-odd cases.
  // sot   (RI RI)*  RI x RI
  // [^RI] (RI RI)*  RI x RI
  //
  // If we have font information, we have already broken the cluster if and only
  // if the second character had no advance, which means a ligature was formed.
  // If we don't, we look back like UAX #29 recommends, but only up to 1000 code
  // units.
  if (p1 == U_GCB_REGIONAL_INDICATOR && p2 == U_GCB_REGIONAL_INDICATOR) {
    if (advances != nullptr) {
      // We have advances information. But if we are here, we already know c2
      // has no advance. So we should definitely disallow a break.
      return false;
    } else {
      // Look at up to 1000 code units.
      const size_t lookback_barrier =
          std::max((ssize_t)start, (ssize_t)offset_back - 1000);
      size_t offset_backback = offset_back;
      while (offset_backback > lookback_barrier) {
        uint32_t c0 = 0;
        U16_PREV(buf, lookback_barrier, offset_backback, c0);
        if (tailoredGraphemeClusterBreak(c0) != U_GCB_REGIONAL_INDICATOR) {
          offset_backback += U16_LENGTH(c0);
          break;
        }
      }
      // The number 4 comes from the number of code units in a whole flag.
      return (offset - offset_backback) % 4 == 0;
    }
  }
  // Cluster Indic syllables together (tailoring of UAX #29).
  // Immediately after each virama (that is not just a pure killer) followed by
  // a letter, we disallow grapheme breaks (if we are here, we don't know about
  // advances, or we already know that c2 has no advance).
  if (u_getIntPropertyValue(c1, UCHAR_CANONICAL_COMBINING_CLASS) == 9  // virama
      && !isPureKiller(c1) &&
      u_getIntPropertyValue(c2, UCHAR_GENERAL_CATEGORY) == U_OTHER_LETTER) {
    return false;
  }
  // Rule GB999, Any ÷ Any
  return true;
}

size_t GraphemeBreak::getTextRunCursor(const float* advances,
                                       const uint16_t* buf,
                                       size_t start,
                                       size_t count,
                                       size_t offset,
                                       MoveOpt opt) {
  switch (opt) {
    case AFTER:
      if (offset < start + count) {
        offset++;
      }
      // fall through
    case AT_OR_AFTER:
      while (!isGraphemeBreak(advances, buf, start, count, offset)) {
        offset++;
      }
      break;
    case BEFORE:
      if (offset > start) {
        offset--;
      }
      // fall through
    case AT_OR_BEFORE:
      while (!isGraphemeBreak(advances, buf, start, count, offset)) {
        offset--;
      }
      break;
    case AT:
      if (!isGraphemeBreak(advances, buf, start, count, offset)) {
        offset = (size_t)-1;
      }
      break;
  }
  return offset;
}

}  // namespace minikin
