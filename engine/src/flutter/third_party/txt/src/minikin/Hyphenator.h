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

/**
 * An implementation of Liang's hyphenation algorithm.
 */

#ifndef U_USING_ICU_NAMESPACE
#define U_USING_ICU_NAMESPACE 0
#endif  //  U_USING_ICU_NAMESPACE

#include <memory>
#include <unordered_map>
#include <vector>
#include "unicode/locid.h"

#ifndef MINIKIN_HYPHENATOR_H
#define MINIKIN_HYPHENATOR_H

namespace minikin {

enum class HyphenationType : uint8_t {
  // Note: There are implicit assumptions scattered in the code that DONT_BREAK
  // is 0.

  // Do not break.
  DONT_BREAK = 0,
  // Break the line and insert a normal hyphen.
  BREAK_AND_INSERT_HYPHEN = 1,
  // Break the line and insert an Armenian hyphen (U+058A).
  BREAK_AND_INSERT_ARMENIAN_HYPHEN = 2,
  // Break the line and insert a maqaf (Hebrew hyphen, U+05BE).
  BREAK_AND_INSERT_MAQAF = 3,
  // Break the line and insert a Canadian Syllabics hyphen (U+1400).
  BREAK_AND_INSERT_UCAS_HYPHEN = 4,
  // Break the line, but don't insert a hyphen. Used for cases when there is
  // already a hyphen
  // present or the script does not use a hyphen (e.g. in Malayalam).
  BREAK_AND_DONT_INSERT_HYPHEN = 5,
  // Break and replace the last code unit with hyphen. Used for Catalan "l·l"
  // which hyphenates
  // as "l-/l".
  BREAK_AND_REPLACE_WITH_HYPHEN = 6,
  // Break the line, and repeat the hyphen (which is the last character) at the
  // beginning of the
  // next line. Used in Polish, where "czerwono-niebieska" should hyphenate as
  // "czerwono-/-niebieska".
  BREAK_AND_INSERT_HYPHEN_AT_NEXT_LINE = 7,
  // Break the line, insert a ZWJ and hyphen at the first line, and a ZWJ at the
  // second line.
  // This is used in Arabic script, mostly for writing systems of Central Asia.
  // It's our default
  // behavior when a soft hyphen is used in Arabic script.
  BREAK_AND_INSERT_HYPHEN_AND_ZWJ = 8
};

// The hyphen edit represents an edit to the string when a word is
// hyphenated. The most common hyphen edit is adding a "-" at the end
// of a syllable, but nonstandard hyphenation allows for more choices.
// Note that a HyphenEdit can hold two types of edits at the same time,
// One at the beginning of the string/line and one at the end.
class HyphenEdit {
 public:
  static const uint32_t NO_EDIT = 0x00;

  static const uint32_t INSERT_HYPHEN_AT_END = 0x01;
  static const uint32_t INSERT_ARMENIAN_HYPHEN_AT_END = 0x02;
  static const uint32_t INSERT_MAQAF_AT_END = 0x03;
  static const uint32_t INSERT_UCAS_HYPHEN_AT_END = 0x04;
  static const uint32_t INSERT_ZWJ_AND_HYPHEN_AT_END = 0x05;
  static const uint32_t REPLACE_WITH_HYPHEN_AT_END = 0x06;
  static const uint32_t BREAK_AT_END = 0x07;

  static const uint32_t INSERT_HYPHEN_AT_START = 0x01 << 3;
  static const uint32_t INSERT_ZWJ_AT_START = 0x02 << 3;
  static const uint32_t BREAK_AT_START = 0x03 << 3;

  // Keep in sync with the definitions in the Java code at:
  // frameworks/base/graphics/java/android/graphics/Paint.java
  static const uint32_t MASK_END_OF_LINE = 0x07;
  static const uint32_t MASK_START_OF_LINE = 0x03 << 3;

  inline static bool isReplacement(uint32_t hyph) {
    return hyph == REPLACE_WITH_HYPHEN_AT_END;
  }

  inline static bool isInsertion(uint32_t hyph) {
    return (hyph == INSERT_HYPHEN_AT_END ||
            hyph == INSERT_ARMENIAN_HYPHEN_AT_END ||
            hyph == INSERT_MAQAF_AT_END || hyph == INSERT_UCAS_HYPHEN_AT_END ||
            hyph == INSERT_ZWJ_AND_HYPHEN_AT_END ||
            hyph == INSERT_HYPHEN_AT_START || hyph == INSERT_ZWJ_AT_START);
  }

  const static uint32_t* getHyphenString(uint32_t hyph);
  static uint32_t editForThisLine(HyphenationType type);
  static uint32_t editForNextLine(HyphenationType type);

  HyphenEdit() : hyphen(NO_EDIT) {}
  HyphenEdit(uint32_t hyphenInt)  // NOLINT(google-explicit-constructor)
      : hyphen(hyphenInt) {}
  uint32_t getHyphen() const { return hyphen; }
  bool operator==(const HyphenEdit& other) const {
    return hyphen == other.hyphen;
  }

  uint32_t getEnd() const { return hyphen & MASK_END_OF_LINE; }
  uint32_t getStart() const { return hyphen & MASK_START_OF_LINE; }

 private:
  uint32_t hyphen;
};

// hyb file header; implementation details are in the .cpp file
struct Header;

class Hyphenator {
 public:
  // Compute the hyphenation of a word, storing the hyphenation in result
  // vector. Each entry in the vector is a "hyphenation type" for a potential
  // hyphenation that can be applied at the corresponding code unit offset in
  // the word.
  //
  // Example: word is "hyphen", result is the following, corresponding to
  // "hy-phen": [DONT_BREAK, DONT_BREAK, BREAK_AND_INSERT_HYPHEN, DONT_BREAK,
  // DONT_BREAK, DONT_BREAK]
  void hyphenate(std::vector<HyphenationType>* result,
                 const uint16_t* word,
                 size_t len,
                 const icu::Locale& locale);

  // Returns true if the codepoint is like U+2010 HYPHEN in line breaking and
  // usage: a character immediately after which line breaks are allowed, but
  // words containing it should not be automatically hyphenated.
  static bool isLineBreakingHyphen(uint32_t cp);

  // pattern data is in binary format, as described in doc/hyb_file_format.md.
  // Note: the caller is responsible for ensuring that the lifetime of the
  // pattern data is at least as long as the Hyphenator object.

  // Note: nullptr is valid input, in which case the hyphenator only processes
  // soft hyphens.
  static Hyphenator* loadBinary(const uint8_t* patternData,
                                size_t minPrefix,
                                size_t minSuffix);

 private:
  // apply various hyphenation rules including hard and soft hyphens, ignoring
  // patterns
  void hyphenateWithNoPatterns(HyphenationType* result,
                               const uint16_t* word,
                               size_t len,
                               const icu::Locale& locale);

  // Try looking up word in alphabet table, return DONT_BREAK if any code units
  // fail to map. Otherwise, returns BREAK_AND_INSERT_HYPHEN,
  // BREAK_AND_INSERT_ARMENIAN_HYPHEN, or BREAK_AND_DONT_INSERT_HYPHEN based on
  // the script of the characters seen. Note that this method writes len+2
  // entries into alpha_codes (including start and stop)
  HyphenationType alphabetLookup(uint16_t* alpha_codes,
                                 const uint16_t* word,
                                 size_t len);

  // calculate hyphenation from patterns, assuming alphabet lookup has already
  // been done
  void hyphenateFromCodes(HyphenationType* result,
                          const uint16_t* codes,
                          size_t len,
                          HyphenationType hyphenValue);

  // See also LONGEST_HYPHENATED_WORD in LineBreaker.cpp. Here the constant is
  // used so that temporary buffers can be stack-allocated without waste, which
  // is a slightly different use case. It measures UTF-16 code units.
  static const size_t MAX_HYPHENATED_SIZE = 64;

  const uint8_t* patternData;
  size_t minPrefix, minSuffix;

  // accessors for binary data
  const Header* getHeader() const {
    return reinterpret_cast<const Header*>(patternData);
  }
};

}  // namespace minikin

#endif  // MINIKIN_HYPHENATOR_H
