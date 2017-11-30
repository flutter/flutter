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

#include <unicode/uchar.h>
#include <unicode/uscript.h>
#include <algorithm>
#include <memory>
#include <string>
#include <vector>

// HACK: for reading pattern file
#include <fcntl.h>

#define LOG_TAG "Minikin"

#include "minikin/Hyphenator.h"
#include "utils/WindowsUtils.h"

using std::vector;

namespace minikin {

static const uint16_t CHAR_HYPHEN_MINUS = 0x002D;
static const uint16_t CHAR_SOFT_HYPHEN = 0x00AD;
static const uint16_t CHAR_MIDDLE_DOT = 0x00B7;
static const uint16_t CHAR_HYPHEN = 0x2010;

// The following are structs that correspond to tables inside the hyb file
// format

struct AlphabetTable0 {
  uint32_t version;
  uint32_t min_codepoint;
  uint32_t max_codepoint;
  uint8_t data[1];  // actually flexible array, size is known at runtime
};

struct AlphabetTable1 {
  uint32_t version;
  uint32_t n_entries;
  uint32_t data[1];  // actually flexible array, size is known at runtime

  static uint32_t codepoint(uint32_t entry) { return entry >> 11; }
  static uint32_t value(uint32_t entry) { return entry & 0x7ff; }
};

struct Trie {
  uint32_t version;
  uint32_t char_mask;
  uint32_t link_shift;
  uint32_t link_mask;
  uint32_t pattern_shift;
  uint32_t n_entries;
  uint32_t data[1];  // actually flexible array, size is known at runtime
};

struct Pattern {
  uint32_t version;
  uint32_t n_entries;
  uint32_t pattern_offset;
  uint32_t pattern_size;
  uint32_t data[1];  // actually flexible array, size is known at runtime

  // accessors
  static uint32_t len(uint32_t entry) { return entry >> 26; }
  static uint32_t shift(uint32_t entry) { return (entry >> 20) & 0x3f; }
  const uint8_t* buf(uint32_t entry) const {
    return reinterpret_cast<const uint8_t*>(this) + pattern_offset +
           (entry & 0xfffff);
  }
};

struct Header {
  uint32_t magic;
  uint32_t version;
  uint32_t alphabet_offset;
  uint32_t trie_offset;
  uint32_t pattern_offset;
  uint32_t file_size;

  // accessors
  const uint8_t* bytes() const {
    return reinterpret_cast<const uint8_t*>(this);
  }
  uint32_t alphabetVersion() const {
    return *reinterpret_cast<const uint32_t*>(bytes() + alphabet_offset);
  }
  const AlphabetTable0* alphabetTable0() const {
    return reinterpret_cast<const AlphabetTable0*>(bytes() + alphabet_offset);
  }
  const AlphabetTable1* alphabetTable1() const {
    return reinterpret_cast<const AlphabetTable1*>(bytes() + alphabet_offset);
  }
  const Trie* trieTable() const {
    return reinterpret_cast<const Trie*>(bytes() + trie_offset);
  }
  const Pattern* patternTable() const {
    return reinterpret_cast<const Pattern*>(bytes() + pattern_offset);
  }
};

Hyphenator* Hyphenator::loadBinary(const uint8_t* patternData,
                                   size_t minPrefix,
                                   size_t minSuffix) {
  Hyphenator* result = new Hyphenator;
  result->patternData = patternData;
  result->minPrefix = minPrefix;
  result->minSuffix = minSuffix;
  return result;
}

void Hyphenator::hyphenate(vector<HyphenationType>* result,
                           const uint16_t* word,
                           size_t len,
                           const icu::Locale& locale) {
  result->clear();
  result->resize(len);
  const size_t paddedLen = len + 2;  // start and stop code each count for 1
  if (patternData != nullptr && len >= minPrefix + minSuffix &&
      paddedLen <= MAX_HYPHENATED_SIZE) {
    uint16_t alpha_codes[MAX_HYPHENATED_SIZE];
    const HyphenationType hyphenValue = alphabetLookup(alpha_codes, word, len);
    if (hyphenValue != HyphenationType::DONT_BREAK) {
      hyphenateFromCodes(result->data(), alpha_codes, paddedLen, hyphenValue);
      return;
    }
    // TODO: try NFC normalization
    // TODO: handle non-BMP Unicode (requires remapping of offsets)
  }
  // Note that we will always get here if the word contains a hyphen or a soft
  // hyphen, because the alphabet is not expected to contain a hyphen or a soft
  // hyphen character, so alphabetLookup would return DONT_BREAK.
  hyphenateWithNoPatterns(result->data(), word, len, locale);
}

// This function determines whether a character is like U+2010 HYPHEN in
// line breaking and usage: a character immediately after which line breaks
// are allowed, but words containing it should not be automatically
// hyphenated using patterns. This is a curated set, created by manually
// inspecting all the characters that have the Unicode line breaking
// property of BA or HY and seeing which ones are hyphens.
bool Hyphenator::isLineBreakingHyphen(uint32_t c) {
  return (c == 0x002D ||  // HYPHEN-MINUS
          c == 0x058A ||  // ARMENIAN HYPHEN
          c == 0x05BE ||  // HEBREW PUNCTUATION MAQAF
          c == 0x1400 ||  // CANADIAN SYLLABICS HYPHEN
          c == 0x2010 ||  // HYPHEN
          c == 0x2013 ||  // EN DASH
          c == 0x2027 ||  // HYPHENATION POINT
          c == 0x2E17 ||  // DOUBLE OBLIQUE HYPHEN
          c == 0x2E40);   // DOUBLE HYPHEN
}

const static uint32_t HYPHEN_STR[] = {0x2010, 0};
const static uint32_t ARMENIAN_HYPHEN_STR[] = {0x058A, 0};
const static uint32_t MAQAF_STR[] = {0x05BE, 0};
const static uint32_t UCAS_HYPHEN_STR[] = {0x1400, 0};
const static uint32_t ZWJ_STR[] = {0x200D, 0};
const static uint32_t ZWJ_AND_HYPHEN_STR[] = {0x200D, 0x2010, 0};

const uint32_t* HyphenEdit::getHyphenString(uint32_t hyph) {
  switch (hyph) {
    case INSERT_HYPHEN_AT_END:
    case REPLACE_WITH_HYPHEN_AT_END:
    case INSERT_HYPHEN_AT_START:
      return HYPHEN_STR;
    case INSERT_ARMENIAN_HYPHEN_AT_END:
      return ARMENIAN_HYPHEN_STR;
    case INSERT_MAQAF_AT_END:
      return MAQAF_STR;
    case INSERT_UCAS_HYPHEN_AT_END:
      return UCAS_HYPHEN_STR;
    case INSERT_ZWJ_AND_HYPHEN_AT_END:
      return ZWJ_AND_HYPHEN_STR;
    case INSERT_ZWJ_AT_START:
      return ZWJ_STR;
    default:
      return nullptr;
  }
}

uint32_t HyphenEdit::editForThisLine(HyphenationType type) {
  switch (type) {
    case HyphenationType::DONT_BREAK:
      return NO_EDIT;
    case HyphenationType::BREAK_AND_INSERT_HYPHEN:
      return INSERT_HYPHEN_AT_END;
    case HyphenationType::BREAK_AND_INSERT_ARMENIAN_HYPHEN:
      return INSERT_ARMENIAN_HYPHEN_AT_END;
    case HyphenationType::BREAK_AND_INSERT_MAQAF:
      return INSERT_MAQAF_AT_END;
    case HyphenationType::BREAK_AND_INSERT_UCAS_HYPHEN:
      return INSERT_UCAS_HYPHEN_AT_END;
    case HyphenationType::BREAK_AND_REPLACE_WITH_HYPHEN:
      return REPLACE_WITH_HYPHEN_AT_END;
    case HyphenationType::BREAK_AND_INSERT_HYPHEN_AND_ZWJ:
      return INSERT_ZWJ_AND_HYPHEN_AT_END;
    default:
      return BREAK_AT_END;
  }
}

uint32_t HyphenEdit::editForNextLine(HyphenationType type) {
  switch (type) {
    case HyphenationType::DONT_BREAK:
      return NO_EDIT;
    case HyphenationType::BREAK_AND_INSERT_HYPHEN_AT_NEXT_LINE:
      return INSERT_HYPHEN_AT_START;
    case HyphenationType::BREAK_AND_INSERT_HYPHEN_AND_ZWJ:
      return INSERT_ZWJ_AT_START;
    default:
      return BREAK_AT_START;
  }
}

static UScriptCode getScript(uint32_t codePoint) {
  UErrorCode errorCode = U_ZERO_ERROR;
  const UScriptCode script =
      uscript_getScript(static_cast<UChar32>(codePoint), &errorCode);
  if (U_SUCCESS(errorCode)) {
    return script;
  } else {
    return USCRIPT_INVALID_CODE;
  }
}

static HyphenationType hyphenationTypeBasedOnScript(uint32_t codePoint) {
  // Note: It's not clear what the best hyphen for Hebrew is. While maqaf is the
  // "correct" hyphen for Hebrew, modern practice may have shifted towards
  // Western hyphens. We use normal hyphens for now to be safe.
  // BREAK_AND_INSERT_MAQAF is already implemented, so if we want to switch to
  // maqaf for Hebrew, we can simply add a condition here.
  const UScriptCode script = getScript(codePoint);
  if (script == USCRIPT_KANNADA || script == USCRIPT_MALAYALAM ||
      script == USCRIPT_TAMIL || script == USCRIPT_TELUGU) {
    // Grantha is not included, since we don't support non-BMP hyphenation yet.
    return HyphenationType::BREAK_AND_DONT_INSERT_HYPHEN;
  } else if (script == USCRIPT_ARMENIAN) {
    return HyphenationType::BREAK_AND_INSERT_ARMENIAN_HYPHEN;
  } else if (script == USCRIPT_CANADIAN_ABORIGINAL) {
    return HyphenationType::BREAK_AND_INSERT_UCAS_HYPHEN;
  } else {
    return HyphenationType::BREAK_AND_INSERT_HYPHEN;
  }
}

static inline int32_t getJoiningType(UChar32 codepoint) {
  return u_getIntPropertyValue(codepoint, UCHAR_JOINING_TYPE);
}

// Assumption for caller: location must be >= 2 and word[location] ==
// CHAR_SOFT_HYPHEN. This function decides if the letters before and after the
// hyphen should appear as joining.
static inline HyphenationType getHyphTypeForArabic(const uint16_t* word,
                                                   size_t len,
                                                   size_t location) {
  ssize_t i = location;
  int32_t type = U_JT_NON_JOINING;
  while (static_cast<size_t>(i) < len &&
         (type = getJoiningType(word[i])) == U_JT_TRANSPARENT) {
    i++;
  }
  if (type == U_JT_DUAL_JOINING || type == U_JT_RIGHT_JOINING ||
      type == U_JT_JOIN_CAUSING) {
    // The next character is of the type that may join the last character. See
    // if the last character is also of the right type.
    i = location - 2;  // Skip the soft hyphen
    type = U_JT_NON_JOINING;
    while (i >= 0 && (type = getJoiningType(word[i])) == U_JT_TRANSPARENT) {
      i--;
    }
    if (type == U_JT_DUAL_JOINING || type == U_JT_LEFT_JOINING ||
        type == U_JT_JOIN_CAUSING) {
      return HyphenationType::BREAK_AND_INSERT_HYPHEN_AND_ZWJ;
    }
  }
  return HyphenationType::BREAK_AND_INSERT_HYPHEN;
}

// Use various recommendations of UAX #14 Unicode Line Breaking Algorithm for
// hyphenating words that didn't match patterns, especially words that contain
// hyphens or soft hyphens (See sections 5.3, Use of Hyphen, and 5.4, Use of
// Soft Hyphen).
void Hyphenator::hyphenateWithNoPatterns(HyphenationType* result,
                                         const uint16_t* word,
                                         size_t len,
                                         const icu::Locale& locale) {
  result[0] = HyphenationType::DONT_BREAK;
  for (size_t i = 1; i < len; i++) {
    const uint16_t prevChar = word[i - 1];
    if (i > 1 && isLineBreakingHyphen(prevChar)) {
      // Break after hyphens, but only if they don't start the word.

      if ((prevChar == CHAR_HYPHEN_MINUS || prevChar == CHAR_HYPHEN) &&
          strcmp(locale.getLanguage(), "pl") == 0 &&
          getScript(word[i]) == USCRIPT_LATIN) {
        // In Polish, hyphens get repeated at the next line. To be safe,
        // we will do this only if the next character is Latin.
        result[i] = HyphenationType::BREAK_AND_INSERT_HYPHEN_AT_NEXT_LINE;
      } else {
        result[i] = HyphenationType::BREAK_AND_DONT_INSERT_HYPHEN;
      }
    } else if (i > 1 && prevChar == CHAR_SOFT_HYPHEN) {
      // Break after soft hyphens, but only if they don't start the word (a soft
      // hyphen starting the word doesn't give any useful break opportunities).
      // The type of the break is based on the script of the character we break
      // on.
      if (getScript(word[i]) == USCRIPT_ARABIC) {
        // For Arabic, we need to look and see if the characters around the soft
        // hyphen actually join. If they don't, we'll just insert a normal
        // hyphen.
        result[i] = getHyphTypeForArabic(word, len, i);
      } else {
        result[i] = hyphenationTypeBasedOnScript(word[i]);
      }
    } else if (prevChar == CHAR_MIDDLE_DOT && minPrefix < i &&
               i <= len - minSuffix &&
               ((word[i - 2] == 'l' && word[i] == 'l') ||
                (word[i - 2] == 'L' && word[i] == 'L')) &&
               strcmp(locale.getLanguage(), "ca") == 0) {
      // In Catalan, "l·l" should break as "l-" on the first line
      // and "l" on the next line.
      result[i] = HyphenationType::BREAK_AND_REPLACE_WITH_HYPHEN;
    } else {
      result[i] = HyphenationType::DONT_BREAK;
    }
  }
}

HyphenationType Hyphenator::alphabetLookup(uint16_t* alpha_codes,
                                           const uint16_t* word,
                                           size_t len) {
  const Header* header = getHeader();
  HyphenationType result = HyphenationType::BREAK_AND_INSERT_HYPHEN;
  // TODO: check header magic
  uint32_t alphabetVersion = header->alphabetVersion();
  if (alphabetVersion == 0) {
    const AlphabetTable0* alphabet = header->alphabetTable0();
    uint32_t min_codepoint = alphabet->min_codepoint;
    uint32_t max_codepoint = alphabet->max_codepoint;
    alpha_codes[0] = 0;  // word start
    for (size_t i = 0; i < len; i++) {
      uint16_t c = word[i];
      if (c < min_codepoint || c >= max_codepoint) {
        return HyphenationType::DONT_BREAK;
      }
      uint8_t code = alphabet->data[c - min_codepoint];
      if (code == 0) {
        return HyphenationType::DONT_BREAK;
      }
      if (result == HyphenationType::BREAK_AND_INSERT_HYPHEN) {
        result = hyphenationTypeBasedOnScript(c);
      }
      alpha_codes[i + 1] = code;
    }
    alpha_codes[len + 1] = 0;  // word termination
    return result;
  } else if (alphabetVersion == 1) {
    const AlphabetTable1* alphabet = header->alphabetTable1();
    size_t n_entries = alphabet->n_entries;
    const uint32_t* begin = alphabet->data;
    const uint32_t* end = begin + n_entries;
    alpha_codes[0] = 0;
    for (size_t i = 0; i < len; i++) {
      uint16_t c = word[i];
      auto p = std::lower_bound<const uint32_t*, uint32_t>(begin, end, c << 11);
      if (p == end) {
        return HyphenationType::DONT_BREAK;
      }
      uint32_t entry = *p;
      if (AlphabetTable1::codepoint(entry) != c) {
        return HyphenationType::DONT_BREAK;
      }
      if (result == HyphenationType::BREAK_AND_INSERT_HYPHEN) {
        result = hyphenationTypeBasedOnScript(c);
      }
      alpha_codes[i + 1] = AlphabetTable1::value(entry);
    }
    alpha_codes[len + 1] = 0;
    return result;
  }
  return HyphenationType::DONT_BREAK;
}

/**
 * Internal implementation, after conversion to codes. All case folding and
 *normalization has been done by now, and all characters have been found in the
 *alphabet. Note: len here is the padded length including 0 codes at start and
 *end.
 **/
void Hyphenator::hyphenateFromCodes(HyphenationType* result,
                                    const uint16_t* codes,
                                    size_t len,
                                    HyphenationType hyphenValue) {
  static_assert(sizeof(HyphenationType) == sizeof(uint8_t),
                "HyphnationType must be uint8_t.");
  // Reuse the result array as a buffer for calculating intermediate hyphenation
  // numbers.
  uint8_t* buffer = reinterpret_cast<uint8_t*>(result);

  const Header* header = getHeader();
  const Trie* trie = header->trieTable();
  const Pattern* pattern = header->patternTable();
  uint32_t char_mask = trie->char_mask;
  uint32_t link_shift = trie->link_shift;
  uint32_t link_mask = trie->link_mask;
  uint32_t pattern_shift = trie->pattern_shift;
  size_t maxOffset = len - minSuffix - 1;
  for (size_t i = 0; i < len - 1; i++) {
    uint32_t node = 0;  // index into Trie table
    for (size_t j = i; j < len; j++) {
      uint16_t c = codes[j];
      uint32_t entry = trie->data[node + c];
      if ((entry & char_mask) == c) {
        node = (entry & link_mask) >> link_shift;
      } else {
        break;
      }
      uint32_t pat_ix = trie->data[node] >> pattern_shift;
      // pat_ix contains a 3-tuple of length, shift (number of trailing zeros),
      // and an offset into the buf pool. This is the pattern for the substring
      // (i..j) we just matched, which we combine (via point-wise max) into the
      // buffer vector.
      if (pat_ix != 0) {
        uint32_t pat_entry = pattern->data[pat_ix];
        int pat_len = Pattern::len(pat_entry);
        int pat_shift = Pattern::shift(pat_entry);
        const uint8_t* pat_buf = pattern->buf(pat_entry);
        int offset = j + 1 - (pat_len + pat_shift);
        // offset is the index within buffer that lines up with the start of
        // pat_buf
        int start = std::max((int)minPrefix - offset, 0);
        int end = std::min(pat_len, (int)maxOffset - offset);
        for (int k = start; k < end; k++) {
          buffer[offset + k] = std::max(buffer[offset + k], pat_buf[k]);
        }
      }
    }
  }
  // Since the above calculation does not modify values outside
  // [minPrefix, len - minSuffix], they are left as 0 = DONT_BREAK.
  for (size_t i = minPrefix; i < maxOffset; i++) {
    // Hyphenation opportunities happen when the hyphenation numbers are odd.
    result[i] = (buffer[i] & 1u) ? hyphenValue : HyphenationType::DONT_BREAK;
  }
}

}  // namespace minikin
