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

#include "LayoutUtils.h"

namespace minikin {

const uint16_t CHAR_NBSP = 0x00A0;

/*
 * Determine whether the code unit is a word space for the purposes of
 * justification.
 */
bool isWordSpace(uint16_t code_unit) {
  return code_unit == ' ' || code_unit == CHAR_NBSP;
}

/**
 * For the purpose of layout, a word break is a boundary with no
 * kerning or complex script processing. This is necessarily a
 * heuristic, but should be accurate most of the time.
 */
static bool isWordBreakAfter(uint16_t c) {
  if (isWordSpace(c) || (c >= 0x2000 && c <= 0x200a) || c == 0x3000) {
    // spaces
    return true;
  }
  // Note: kana is not included, as sophisticated fonts may kern kana
  return false;
}

static bool isWordBreakBefore(uint16_t c) {
  // CJK ideographs (and yijing hexagram symbols)
  return isWordBreakAfter(c) || (c >= 0x3400 && c <= 0x9fff);
}

/**
 * Return offset of previous word break. It is either < offset or == 0.
 */
size_t getPrevWordBreakForCache(const uint16_t* chars,
                                size_t offset,
                                size_t len) {
  if (offset == 0)
    return 0;
  if (offset > len)
    offset = len;
  if (isWordBreakBefore(chars[offset - 1])) {
    return offset - 1;
  }
  for (size_t i = offset - 1; i > 0; i--) {
    if (isWordBreakBefore(chars[i]) || isWordBreakAfter(chars[i - 1])) {
      return i;
    }
  }
  return 0;
}

/**
 * Return offset of next word break. It is either > offset or == len.
 */
size_t getNextWordBreakForCache(const uint16_t* chars,
                                size_t offset,
                                size_t len) {
  if (offset >= len)
    return len;
  if (isWordBreakAfter(chars[offset])) {
    return offset + 1;
  }
  for (size_t i = offset + 1; i < len; i++) {
    // No need to check isWordBreakAfter(chars[i - 1]) since it is checked
    // in previous iteration.  Note that isWordBreakBefore returns true
    // whenever isWordBreakAfter returns true.
    if (isWordBreakBefore(chars[i])) {
      return i;
    }
  }
  return len;
}

}  // namespace minikin
