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

#include <gtest/gtest.h>
#include "UnicodeUtils.h"

#include "minikin/LayoutUtils.h"

namespace minikin {

void ExpectNextWordBreakForCache(size_t offset_in, const char* query_str) {
  const size_t BUF_SIZE = 256U;
  uint16_t buf[BUF_SIZE];
  size_t expected_breakpoint = 0U;
  size_t size = 0U;

  ParseUnicode(buf, BUF_SIZE, query_str, &size, &expected_breakpoint);
  EXPECT_EQ(expected_breakpoint, getNextWordBreakForCache(buf, offset_in, size))
      << "Expected position is [" << query_str << "] from offset " << offset_in;
}

void ExpectPrevWordBreakForCache(size_t offset_in, const char* query_str) {
  const size_t BUF_SIZE = 256U;
  uint16_t buf[BUF_SIZE];
  size_t expected_breakpoint = 0U;
  size_t size = 0U;

  ParseUnicode(buf, BUF_SIZE, query_str, &size, &expected_breakpoint);
  EXPECT_EQ(expected_breakpoint, getPrevWordBreakForCache(buf, offset_in, size))
      << "Expected position is [" << query_str << "] from offset " << offset_in;
}

TEST(WordBreakTest, goNextWordBreakTest) {
  ExpectNextWordBreakForCache(0, "|");

  // Continue for spaces.
  ExpectNextWordBreakForCache(0, "'a' 'b' 'c' 'd' |");
  ExpectNextWordBreakForCache(1, "'a' 'b' 'c' 'd' |");
  ExpectNextWordBreakForCache(2, "'a' 'b' 'c' 'd' |");
  ExpectNextWordBreakForCache(3, "'a' 'b' 'c' 'd' |");
  ExpectNextWordBreakForCache(4, "'a' 'b' 'c' 'd' |");
  ExpectNextWordBreakForCache(1000, "'a' 'b' 'c' 'd' |");

  // Space makes word break.
  ExpectNextWordBreakForCache(0, "'a' 'b' | U+0020 'c' 'd'");
  ExpectNextWordBreakForCache(1, "'a' 'b' | U+0020 'c' 'd'");
  ExpectNextWordBreakForCache(2, "'a' 'b' U+0020 | 'c' 'd'");
  ExpectNextWordBreakForCache(3, "'a' 'b' U+0020 'c' 'd' |");
  ExpectNextWordBreakForCache(4, "'a' 'b' U+0020 'c' 'd' |");
  ExpectNextWordBreakForCache(5, "'a' 'b' U+0020 'c' 'd' |");
  ExpectNextWordBreakForCache(1000, "'a' 'b' U+0020 'c' 'd' |");

  ExpectNextWordBreakForCache(0, "'a' 'b' | U+2000 'c' 'd'");
  ExpectNextWordBreakForCache(1, "'a' 'b' | U+2000 'c' 'd'");
  ExpectNextWordBreakForCache(2, "'a' 'b' U+2000 | 'c' 'd'");
  ExpectNextWordBreakForCache(3, "'a' 'b' U+2000 'c' 'd' |");
  ExpectNextWordBreakForCache(4, "'a' 'b' U+2000 'c' 'd' |");
  ExpectNextWordBreakForCache(5, "'a' 'b' U+2000 'c' 'd' |");
  ExpectNextWordBreakForCache(1000, "'a' 'b' U+2000 'c' 'd' |");

  ExpectNextWordBreakForCache(0, "'a' 'b' | U+2000 U+2000 'c' 'd'");
  ExpectNextWordBreakForCache(1, "'a' 'b' | U+2000 U+2000 'c' 'd'");
  ExpectNextWordBreakForCache(2, "'a' 'b' U+2000 | U+2000 'c' 'd'");
  ExpectNextWordBreakForCache(3, "'a' 'b' U+2000 U+2000 | 'c' 'd'");
  ExpectNextWordBreakForCache(4, "'a' 'b' U+2000 U+2000 'c' 'd' |");
  ExpectNextWordBreakForCache(5, "'a' 'b' U+2000 U+2000 'c' 'd' |");
  ExpectNextWordBreakForCache(6, "'a' 'b' U+2000 U+2000 'c' 'd' |");
  ExpectNextWordBreakForCache(1000, "'a' 'b' U+2000 U+2000 'c' 'd' |");

  // CJK ideographs makes word break.
  ExpectNextWordBreakForCache(0, "U+4E00 | U+4E00   U+4E00   U+4E00   U+4E00");
  ExpectNextWordBreakForCache(1, "U+4E00   U+4E00 | U+4E00   U+4E00   U+4E00");
  ExpectNextWordBreakForCache(2, "U+4E00   U+4E00   U+4E00 | U+4E00   U+4E00");
  ExpectNextWordBreakForCache(3, "U+4E00   U+4E00   U+4E00   U+4E00 | U+4E00");
  ExpectNextWordBreakForCache(4,
                              "U+4E00   U+4E00   U+4E00   U+4E00   U+4E00 |");
  ExpectNextWordBreakForCache(5,
                              "U+4E00   U+4E00   U+4E00   U+4E00   U+4E00 |");
  ExpectNextWordBreakForCache(1000,
                              "U+4E00   U+4E00   U+4E00   U+4E00   U+4E00 |");

  ExpectNextWordBreakForCache(0, "U+4E00 | U+4E8C   U+4E09   U+56DB   U+4E94");
  ExpectNextWordBreakForCache(1, "U+4E00   U+4E8C | U+4E09   U+56DB   U+4E94");
  ExpectNextWordBreakForCache(2, "U+4E00   U+4E8C   U+4E09 | U+56DB   U+4E94");
  ExpectNextWordBreakForCache(3, "U+4E00   U+4E8C   U+4E09   U+56DB | U+4E94");
  ExpectNextWordBreakForCache(4,
                              "U+4E00   U+4E8C   U+4E09   U+56DB   U+4E94 |");
  ExpectNextWordBreakForCache(5,
                              "U+4E00   U+4E8C   U+4E09   U+56DB   U+4E94 |");
  ExpectNextWordBreakForCache(1000,
                              "U+4E00   U+4E8C   U+4E09   U+56DB   U+4E94 |");

  ExpectNextWordBreakForCache(0, "U+4E00 'a' 'b' | U+2000 'c' U+4E00");
  ExpectNextWordBreakForCache(1, "U+4E00 'a' 'b' | U+2000 'c' U+4E00");
  ExpectNextWordBreakForCache(2, "U+4E00 'a' 'b' | U+2000 'c' U+4E00");
  ExpectNextWordBreakForCache(3, "U+4E00 'a' 'b' U+2000 | 'c' U+4E00");
  ExpectNextWordBreakForCache(4, "U+4E00 'a' 'b' U+2000 'c' | U+4E00");
  ExpectNextWordBreakForCache(5, "U+4E00 'a' 'b' U+2000 'c' U+4E00 |");
  ExpectNextWordBreakForCache(1000, "U+4E00 'a' 'b' U+2000 'c' U+4E00 |");

  // Continue if trailing characters is Unicode combining characters.
  ExpectNextWordBreakForCache(0, "U+4E00 U+0332 | U+4E00");
  ExpectNextWordBreakForCache(1, "U+4E00 U+0332 | U+4E00");
  ExpectNextWordBreakForCache(2, "U+4E00 U+0332 U+4E00 |");
  ExpectNextWordBreakForCache(3, "U+4E00 U+0332 U+4E00 |");
  ExpectNextWordBreakForCache(1000, "U+4E00 U+0332 U+4E00 |");

  // Surrogate pairs.
  ExpectNextWordBreakForCache(0, "U+1F60D U+1F618 |");
  ExpectNextWordBreakForCache(1, "U+1F60D U+1F618 |");
  ExpectNextWordBreakForCache(2, "U+1F60D U+1F618 |");
  ExpectNextWordBreakForCache(3, "U+1F60D U+1F618 |");
  ExpectNextWordBreakForCache(4, "U+1F60D U+1F618 |");
  ExpectNextWordBreakForCache(1000, "U+1F60D U+1F618 |");

  // Broken surrogate pairs.
  // U+D84D is leading surrogate but there is no trailing surrogate for it.
  ExpectNextWordBreakForCache(0, "U+D84D U+1F618 |");
  ExpectNextWordBreakForCache(1, "U+D84D U+1F618 |");
  ExpectNextWordBreakForCache(2, "U+D84D U+1F618 |");
  ExpectNextWordBreakForCache(3, "U+D84D U+1F618 |");
  ExpectNextWordBreakForCache(1000, "U+D84D U+1F618 |");

  ExpectNextWordBreakForCache(0, "U+1F618 U+D84D |");
  ExpectNextWordBreakForCache(1, "U+1F618 U+D84D |");
  ExpectNextWordBreakForCache(2, "U+1F618 U+D84D |");
  ExpectNextWordBreakForCache(3, "U+1F618 U+D84D |");
  ExpectNextWordBreakForCache(1000, "U+1F618 U+D84D |");

  // U+DE0D is trailing surrogate but there is no leading surrogate for it.
  ExpectNextWordBreakForCache(0, "U+DE0D U+1F618 |");
  ExpectNextWordBreakForCache(1, "U+DE0D U+1F618 |");
  ExpectNextWordBreakForCache(2, "U+DE0D U+1F618 |");
  ExpectNextWordBreakForCache(3, "U+DE0D U+1F618 |");
  ExpectNextWordBreakForCache(1000, "U+DE0D U+1F618 |");

  ExpectNextWordBreakForCache(0, "U+1F618 U+DE0D |");
  ExpectNextWordBreakForCache(1, "U+1F618 U+DE0D |");
  ExpectNextWordBreakForCache(2, "U+1F618 U+DE0D |");
  ExpectNextWordBreakForCache(3, "U+1F618 U+DE0D |");
  ExpectNextWordBreakForCache(1000, "U+1F618 U+DE0D |");

  // Regional indicator pair. U+1F1FA U+1F1F8 is US national flag.
  ExpectNextWordBreakForCache(0, "U+1F1FA U+1F1F8 |");
  ExpectNextWordBreakForCache(1, "U+1F1FA U+1F1F8 |");
  ExpectNextWordBreakForCache(2, "U+1F1FA U+1F1F8 |");
  ExpectNextWordBreakForCache(1000, "U+1F1FA U+1F1F8 |");

  // Tone marks.
  // CJK ideographic char + Tone mark + CJK ideographic char
  ExpectNextWordBreakForCache(0, "U+4444 U+302D | U+4444");
  ExpectNextWordBreakForCache(1, "U+4444 U+302D | U+4444");
  ExpectNextWordBreakForCache(2, "U+4444 U+302D U+4444 |");
  ExpectNextWordBreakForCache(3, "U+4444 U+302D U+4444 |");
  ExpectNextWordBreakForCache(1000, "U+4444 U+302D U+4444 |");

  // Variation Selectors.
  // CJK Ideographic char + Variation Selector(VS1) + CJK Ideographic char
  ExpectNextWordBreakForCache(0, "U+845B U+FE00 | U+845B");
  ExpectNextWordBreakForCache(1, "U+845B U+FE00 | U+845B");
  ExpectNextWordBreakForCache(2, "U+845B U+FE00 U+845B |");
  ExpectNextWordBreakForCache(3, "U+845B U+FE00 U+845B |");
  ExpectNextWordBreakForCache(1000, "U+845B U+FE00 U+845B |");

  // CJK Ideographic char + Variation Selector(VS17) + CJK Ideographic char
  ExpectNextWordBreakForCache(0, "U+845B U+E0100 | U+845B");
  ExpectNextWordBreakForCache(1, "U+845B U+E0100 | U+845B");
  ExpectNextWordBreakForCache(2, "U+845B U+E0100 | U+845B");
  ExpectNextWordBreakForCache(3, "U+845B U+E0100 U+845B |");
  ExpectNextWordBreakForCache(4, "U+845B U+E0100 U+845B |");
  ExpectNextWordBreakForCache(5, "U+845B U+E0100 U+845B |");
  ExpectNextWordBreakForCache(1000, "U+845B U+E0100 U+845B |");

  // CJK ideographic char + Tone mark + Variation Character(VS1)
  ExpectNextWordBreakForCache(0, "U+4444 U+302D U+FE00 | U+4444");
  ExpectNextWordBreakForCache(1, "U+4444 U+302D U+FE00 | U+4444");
  ExpectNextWordBreakForCache(2, "U+4444 U+302D U+FE00 | U+4444");
  ExpectNextWordBreakForCache(3, "U+4444 U+302D U+FE00 U+4444 |");
  ExpectNextWordBreakForCache(4, "U+4444 U+302D U+FE00 U+4444 |");
  ExpectNextWordBreakForCache(1000, "U+4444 U+302D U+FE00 U+4444 |");

  // CJK ideographic char + Tone mark + Variation Character(VS17)
  ExpectNextWordBreakForCache(0, "U+4444 U+302D U+E0100 | U+4444");
  ExpectNextWordBreakForCache(1, "U+4444 U+302D U+E0100 | U+4444");
  ExpectNextWordBreakForCache(2, "U+4444 U+302D U+E0100 | U+4444");
  ExpectNextWordBreakForCache(3, "U+4444 U+302D U+E0100 | U+4444");
  ExpectNextWordBreakForCache(4, "U+4444 U+302D U+E0100 U+4444 |");
  ExpectNextWordBreakForCache(5, "U+4444 U+302D U+E0100 U+4444 |");
  ExpectNextWordBreakForCache(1000, "U+4444 U+302D U+E0100 U+4444 |");

  // CJK ideographic char + Variation Character(VS1) + Tone mark
  ExpectNextWordBreakForCache(0, "U+4444 U+FE00 U+302D | U+4444");
  ExpectNextWordBreakForCache(1, "U+4444 U+FE00 U+302D | U+4444");
  ExpectNextWordBreakForCache(2, "U+4444 U+FE00 U+302D | U+4444");
  ExpectNextWordBreakForCache(3, "U+4444 U+FE00 U+302D U+4444 |");
  ExpectNextWordBreakForCache(4, "U+4444 U+FE00 U+302D U+4444 |");
  ExpectNextWordBreakForCache(1000, "U+4444 U+FE00 U+302D U+4444 |");

  // CJK ideographic char + Variation Character(VS17) + Tone mark
  ExpectNextWordBreakForCache(0, "U+4444 U+E0100 U+302D | U+4444");
  ExpectNextWordBreakForCache(1, "U+4444 U+E0100 U+302D | U+4444");
  ExpectNextWordBreakForCache(2, "U+4444 U+E0100 U+302D | U+4444");
  ExpectNextWordBreakForCache(3, "U+4444 U+E0100 U+302D | U+4444");
  ExpectNextWordBreakForCache(4, "U+4444 U+E0100 U+302D U+4444 |");
  ExpectNextWordBreakForCache(5, "U+4444 U+E0100 U+302D U+4444 |");
  ExpectNextWordBreakForCache(1000, "U+4444 U+E0100 U+302D U+4444 |");

  // Following test cases are unusual usage of variation selectors and tone
  // marks for caching up the further behavior changes, e.g. index of bounds
  // or crashes. Please feel free to update the test expectations if the
  // behavior change makes sense to you.

  // Isolated Tone marks and Variation Selectors
  ExpectNextWordBreakForCache(0, "U+FE00 |");
  ExpectNextWordBreakForCache(1, "U+FE00 |");
  ExpectNextWordBreakForCache(1000, "U+FE00 |");
  ExpectNextWordBreakForCache(0, "U+E0100 |");
  ExpectNextWordBreakForCache(1000, "U+E0100 |");
  ExpectNextWordBreakForCache(0, "U+302D |");
  ExpectNextWordBreakForCache(1000, "U+302D |");

  // CJK Ideographic char + Variation Selector(VS1) + Variation Selector(VS1)
  ExpectNextWordBreakForCache(0, "U+845B U+FE00 U+FE00 | U+845B");
  ExpectNextWordBreakForCache(1, "U+845B U+FE00 U+FE00 | U+845B");
  ExpectNextWordBreakForCache(2, "U+845B U+FE00 U+FE00 | U+845B");
  ExpectNextWordBreakForCache(3, "U+845B U+FE00 U+FE00 U+845B |");
  ExpectNextWordBreakForCache(4, "U+845B U+FE00 U+FE00 U+845B |");
  ExpectNextWordBreakForCache(1000, "U+845B U+FE00 U+FE00 U+845B |");

  // CJK Ideographic char + Variation Selector(VS17) + Variation Selector(VS17)
  ExpectNextWordBreakForCache(0, "U+845B U+E0100 U+E0100 | U+845B");
  ExpectNextWordBreakForCache(1, "U+845B U+E0100 U+E0100 | U+845B");
  ExpectNextWordBreakForCache(2, "U+845B U+E0100 U+E0100 | U+845B");
  ExpectNextWordBreakForCache(3, "U+845B U+E0100 U+E0100 | U+845B");
  ExpectNextWordBreakForCache(4, "U+845B U+E0100 U+E0100 | U+845B");
  ExpectNextWordBreakForCache(5, "U+845B U+E0100 U+E0100 U+845B |");
  ExpectNextWordBreakForCache(6, "U+845B U+E0100 U+E0100 U+845B |");
  ExpectNextWordBreakForCache(1000, "U+845B U+E0100 U+E0100 U+845B |");

  // CJK Ideographic char + Variation Selector(VS1) + Variation Selector(VS17)
  ExpectNextWordBreakForCache(0, "U+845B U+FE00 U+E0100 | U+845B");
  ExpectNextWordBreakForCache(1, "U+845B U+FE00 U+E0100 | U+845B");
  ExpectNextWordBreakForCache(2, "U+845B U+FE00 U+E0100 | U+845B");
  ExpectNextWordBreakForCache(3, "U+845B U+FE00 U+E0100 | U+845B");
  ExpectNextWordBreakForCache(4, "U+845B U+FE00 U+E0100 U+845B |");
  ExpectNextWordBreakForCache(5, "U+845B U+FE00 U+E0100 U+845B |");
  ExpectNextWordBreakForCache(1000, "U+845B U+FE00 U+E0100 U+845B |");

  // CJK Ideographic char + Variation Selector(VS17) + Variation Selector(VS1)
  ExpectNextWordBreakForCache(0, "U+845B U+E0100 U+FE00 | U+845B");
  ExpectNextWordBreakForCache(1, "U+845B U+E0100 U+FE00 | U+845B");
  ExpectNextWordBreakForCache(2, "U+845B U+E0100 U+FE00 | U+845B");
  ExpectNextWordBreakForCache(3, "U+845B U+E0100 U+FE00 | U+845B");
  ExpectNextWordBreakForCache(4, "U+845B U+E0100 U+FE00 U+845B |");
  ExpectNextWordBreakForCache(5, "U+845B U+E0100 U+FE00 U+845B |");
  ExpectNextWordBreakForCache(1000, "U+845B U+E0100 U+FE00 U+845B |");

  // Tone mark. + Tone mark
  ExpectNextWordBreakForCache(0, "U+4444 U+302D U+302D | U+4444");
  ExpectNextWordBreakForCache(1, "U+4444 U+302D U+302D | U+4444");
  ExpectNextWordBreakForCache(2, "U+4444 U+302D U+302D | U+4444");
  ExpectNextWordBreakForCache(3, "U+4444 U+302D U+302D U+4444 |");
  ExpectNextWordBreakForCache(4, "U+4444 U+302D U+302D U+4444 |");
  ExpectNextWordBreakForCache(1000, "U+4444 U+302D U+302D U+4444 |");
}

TEST(WordBreakTest, goPrevWordBreakTest) {
  ExpectPrevWordBreakForCache(0, "|");

  // Continue for spaces.
  ExpectPrevWordBreakForCache(0, "| 'a' 'b' 'c' 'd'");
  ExpectPrevWordBreakForCache(1, "| 'a' 'b' 'c' 'd'");
  ExpectPrevWordBreakForCache(2, "| 'a' 'b' 'c' 'd'");
  ExpectPrevWordBreakForCache(3, "| 'a' 'b' 'c' 'd'");
  ExpectPrevWordBreakForCache(4, "| 'a' 'b' 'c' 'd'");
  ExpectPrevWordBreakForCache(1000, "| 'a' 'b' 'c' 'd'");

  // Space makes word break.
  ExpectPrevWordBreakForCache(0, "| 'a' 'b' U+0020 'c' 'd'");
  ExpectPrevWordBreakForCache(1, "| 'a' 'b' U+0020 'c' 'd'");
  ExpectPrevWordBreakForCache(2, "| 'a' 'b' U+0020 'c' 'd'");
  ExpectPrevWordBreakForCache(3, "'a' 'b' | U+0020 'c' 'd'");
  ExpectPrevWordBreakForCache(4, "'a' 'b' U+0020 | 'c' 'd'");
  ExpectPrevWordBreakForCache(5, "'a' 'b' U+0020 | 'c' 'd'");
  ExpectPrevWordBreakForCache(1000, "'a' 'b' U+0020 | 'c' 'd'");

  ExpectPrevWordBreakForCache(0, "| 'a' 'b' U+2000 'c' 'd'");
  ExpectPrevWordBreakForCache(1, "| 'a' 'b' U+2000 'c' 'd'");
  ExpectPrevWordBreakForCache(2, "| 'a' 'b' U+2000 'c' 'd'");
  ExpectPrevWordBreakForCache(3, "'a' 'b' | U+2000 'c' 'd'");
  ExpectPrevWordBreakForCache(4, "'a' 'b' U+2000 | 'c' 'd'");
  ExpectPrevWordBreakForCache(5, "'a' 'b' U+2000 | 'c' 'd'");
  ExpectPrevWordBreakForCache(1000, "'a' 'b' U+2000 | 'c' 'd'");

  ExpectPrevWordBreakForCache(0, "| 'a' 'b' U+2000 U+2000 'c' 'd'");
  ExpectPrevWordBreakForCache(1, "| 'a' 'b' U+2000 U+2000 'c' 'd'");
  ExpectPrevWordBreakForCache(2, "| 'a' 'b' U+2000 U+2000 'c' 'd'");
  ExpectPrevWordBreakForCache(3, "'a' 'b' | U+2000 U+2000 'c' 'd'");
  ExpectPrevWordBreakForCache(4, "'a' 'b' U+2000 | U+2000 'c' 'd'");
  ExpectPrevWordBreakForCache(5, "'a' 'b' U+2000 U+2000 | 'c' 'd'");
  ExpectPrevWordBreakForCache(6, "'a' 'b' U+2000 U+2000 | 'c' 'd'");
  ExpectPrevWordBreakForCache(1000, "'a' 'b' U+2000 U+2000 | 'c' 'd'");

  // CJK ideographs makes word break.
  ExpectPrevWordBreakForCache(0, "| U+4E00 U+4E00 U+4E00 U+4E00 U+4E00");
  ExpectPrevWordBreakForCache(1, "| U+4E00 U+4E00 U+4E00 U+4E00 U+4E00");
  ExpectPrevWordBreakForCache(2, "U+4E00 | U+4E00 U+4E00 U+4E00 U+4E00");
  ExpectPrevWordBreakForCache(3, "U+4E00 U+4E00 | U+4E00 U+4E00 U+4E00");
  ExpectPrevWordBreakForCache(4, "U+4E00 U+4E00 U+4E00 | U+4E00 U+4E00");
  ExpectPrevWordBreakForCache(5, "U+4E00 U+4E00 U+4E00 U+4E00 | U+4E00");
  ExpectPrevWordBreakForCache(1000, "U+4E00 U+4E00 U+4E00 U+4E00 | U+4E00");

  ExpectPrevWordBreakForCache(0, "| U+4E00 U+4E8C U+4E09 U+56DB U+4E94");
  ExpectPrevWordBreakForCache(1, "| U+4E00 U+4E8C U+4E09 U+56DB U+4E94");
  ExpectPrevWordBreakForCache(2, "U+4E00 | U+4E8C U+4E09 U+56DB U+4E94");
  ExpectPrevWordBreakForCache(3, "U+4E00 U+4E8C | U+4E09 U+56DB U+4E94");
  ExpectPrevWordBreakForCache(4, "U+4E00 U+4E8C U+4E09 | U+56DB U+4E94");
  ExpectPrevWordBreakForCache(5, "U+4E00 U+4E8C U+4E09 U+56DB | U+4E94");
  ExpectPrevWordBreakForCache(1000, "U+4E00 U+4E8C U+4E09 U+56DB | U+4E94");

  // Mixed case.
  ExpectPrevWordBreakForCache(0, "| U+4E00 'a' 'b' U+2000 'c' U+4E00");
  ExpectPrevWordBreakForCache(1, "| U+4E00 'a' 'b' U+2000 'c' U+4E00");
  ExpectPrevWordBreakForCache(2, "| U+4E00 'a' 'b' U+2000 'c' U+4E00");
  ExpectPrevWordBreakForCache(3, "| U+4E00 'a' 'b' U+2000 'c' U+4E00");
  ExpectPrevWordBreakForCache(4, "U+4E00 'a' 'b' | U+2000 'c' U+4E00");
  ExpectPrevWordBreakForCache(5, "U+4E00 'a' 'b' U+2000 | 'c' U+4E00");
  ExpectPrevWordBreakForCache(6, "U+4E00 'a' 'b' U+2000 'c' | U+4E00");
  ExpectPrevWordBreakForCache(1000, "U+4E00 'a' 'b' U+2000 'c' | U+4E00");

  // Continue if trailing characters is Unicode combining characters.
  ExpectPrevWordBreakForCache(0, "| U+4E00 U+0332 U+4E00");
  ExpectPrevWordBreakForCache(1, "| U+4E00 U+0332 U+4E00");
  ExpectPrevWordBreakForCache(2, "| U+4E00 U+0332 U+4E00");
  ExpectPrevWordBreakForCache(3, "U+4E00 U+0332 | U+4E00");
  ExpectPrevWordBreakForCache(1000, "U+4E00 U+0332 | U+4E00");

  // Surrogate pairs.
  ExpectPrevWordBreakForCache(0, "| U+1F60D U+1F618");
  ExpectPrevWordBreakForCache(1, "| U+1F60D U+1F618");
  ExpectPrevWordBreakForCache(2, "| U+1F60D U+1F618");
  ExpectPrevWordBreakForCache(3, "| U+1F60D U+1F618");
  ExpectPrevWordBreakForCache(4, "| U+1F60D U+1F618");
  ExpectPrevWordBreakForCache(1000, "| U+1F60D U+1F618");

  // Broken surrogate pairs.
  // U+D84D is leading surrogate but there is no trailing surrogate for it.
  ExpectPrevWordBreakForCache(0, "| U+D84D U+1F618");
  ExpectPrevWordBreakForCache(1, "| U+D84D U+1F618");
  ExpectPrevWordBreakForCache(2, "| U+D84D U+1F618");
  ExpectPrevWordBreakForCache(3, "| U+D84D U+1F618");
  ExpectPrevWordBreakForCache(1000, "| U+D84D U+1F618");

  ExpectPrevWordBreakForCache(0, "| U+1F618 U+D84D");
  ExpectPrevWordBreakForCache(1, "| U+1F618 U+D84D");
  ExpectPrevWordBreakForCache(2, "| U+1F618 U+D84D");
  ExpectPrevWordBreakForCache(3, "| U+1F618 U+D84D");
  ExpectPrevWordBreakForCache(1000, "| U+1F618 U+D84D");

  // U+DE0D is trailing surrogate but there is no leading surrogate for it.
  ExpectPrevWordBreakForCache(0, "| U+DE0D U+1F618");
  ExpectPrevWordBreakForCache(1, "| U+DE0D U+1F618");
  ExpectPrevWordBreakForCache(2, "| U+DE0D U+1F618");
  ExpectPrevWordBreakForCache(3, "| U+DE0D U+1F618");
  ExpectPrevWordBreakForCache(1000, "| U+DE0D U+1F618");

  ExpectPrevWordBreakForCache(0, "| U+1F618 U+DE0D");
  ExpectPrevWordBreakForCache(1, "| U+1F618 U+DE0D");
  ExpectPrevWordBreakForCache(2, "| U+1F618 U+DE0D");
  ExpectPrevWordBreakForCache(3, "| U+1F618 U+DE0D");
  ExpectPrevWordBreakForCache(1000, "| U+1F618 U+DE0D");

  // Regional indicator pair. U+1F1FA U+1F1F8 is US national flag.
  ExpectPrevWordBreakForCache(0, "| U+1F1FA U+1F1F8");
  ExpectPrevWordBreakForCache(1, "| U+1F1FA U+1F1F8");
  ExpectPrevWordBreakForCache(2, "| U+1F1FA U+1F1F8");
  ExpectPrevWordBreakForCache(1000, "| U+1F1FA U+1F1F8");

  // Tone marks.
  // CJK ideographic char + Tone mark + CJK ideographic char
  ExpectPrevWordBreakForCache(0, "| U+4444 U+302D U+4444");
  ExpectPrevWordBreakForCache(1, "| U+4444 U+302D U+4444");
  ExpectPrevWordBreakForCache(2, "| U+4444 U+302D U+4444");
  ExpectPrevWordBreakForCache(3, "U+4444 U+302D | U+4444");
  ExpectPrevWordBreakForCache(1000, "U+4444 U+302D | U+4444");

  // Variation Selectors.
  // CJK Ideographic char + Variation Selector(VS1) + CJK Ideographic char
  ExpectPrevWordBreakForCache(0, "| U+845B U+FE00 U+845B");
  ExpectPrevWordBreakForCache(1, "| U+845B U+FE00 U+845B");
  ExpectPrevWordBreakForCache(2, "| U+845B U+FE00 U+845B");
  ExpectPrevWordBreakForCache(3, "U+845B U+FE00 | U+845B");
  ExpectPrevWordBreakForCache(1000, "U+845B U+FE00 | U+845B");

  // CJK Ideographic char + Variation Selector(VS17) + CJK Ideographic char
  ExpectPrevWordBreakForCache(0, "| U+845B U+E0100 U+845B");
  ExpectPrevWordBreakForCache(1, "| U+845B U+E0100 U+845B");
  ExpectPrevWordBreakForCache(2, "| U+845B U+E0100 U+845B");
  ExpectPrevWordBreakForCache(3, "| U+845B U+E0100 U+845B");
  ExpectPrevWordBreakForCache(4, "U+845B U+E0100 | U+845B");
  ExpectPrevWordBreakForCache(5, "U+845B U+E0100 | U+845B");
  ExpectPrevWordBreakForCache(1000, "U+845B U+E0100 | U+845B");

  // CJK ideographic char + Tone mark + Variation Character(VS1)
  ExpectPrevWordBreakForCache(0, "| U+4444 U+302D U+FE00 U+4444");
  ExpectPrevWordBreakForCache(1, "| U+4444 U+302D U+FE00 U+4444");
  ExpectPrevWordBreakForCache(2, "| U+4444 U+302D U+FE00 U+4444");
  ExpectPrevWordBreakForCache(3, "| U+4444 U+302D U+FE00 U+4444");
  ExpectPrevWordBreakForCache(4, "U+4444 U+302D U+FE00 | U+4444");
  ExpectPrevWordBreakForCache(1000, "U+4444 U+302D U+FE00 | U+4444");

  // CJK ideographic char + Tone mark + Variation Character(VS17)
  ExpectPrevWordBreakForCache(0, "| U+4444 U+302D U+E0100 U+4444");
  ExpectPrevWordBreakForCache(1, "| U+4444 U+302D U+E0100 U+4444");
  ExpectPrevWordBreakForCache(2, "| U+4444 U+302D U+E0100 U+4444");
  ExpectPrevWordBreakForCache(3, "| U+4444 U+302D U+E0100 U+4444");
  ExpectPrevWordBreakForCache(4, "| U+4444 U+302D U+E0100 U+4444");
  ExpectPrevWordBreakForCache(5, "U+4444 U+302D U+E0100 | U+4444");
  ExpectPrevWordBreakForCache(1000, "U+4444 U+302D U+E0100 | U+4444");

  // CJK ideographic char + Variation Character(VS1) + Tone mark
  ExpectPrevWordBreakForCache(0, "| U+4444 U+FE00 U+302D U+4444");
  ExpectPrevWordBreakForCache(1, "| U+4444 U+FE00 U+302D U+4444");
  ExpectPrevWordBreakForCache(2, "| U+4444 U+FE00 U+302D U+4444");
  ExpectPrevWordBreakForCache(3, "| U+4444 U+FE00 U+302D U+4444");
  ExpectPrevWordBreakForCache(4, "U+4444 U+FE00 U+302D | U+4444");
  ExpectPrevWordBreakForCache(1000, "U+4444 U+FE00 U+302D | U+4444");

  // CJK ideographic char + Variation Character(VS17) + Tone mark
  ExpectPrevWordBreakForCache(0, "| U+4444 U+E0100 U+302D U+4444");
  ExpectPrevWordBreakForCache(1, "| U+4444 U+E0100 U+302D U+4444");
  ExpectPrevWordBreakForCache(2, "| U+4444 U+E0100 U+302D U+4444");
  ExpectPrevWordBreakForCache(3, "| U+4444 U+E0100 U+302D U+4444");
  ExpectPrevWordBreakForCache(4, "| U+4444 U+E0100 U+302D U+4444");
  ExpectPrevWordBreakForCache(5, "U+4444 U+E0100 U+302D | U+4444");
  ExpectPrevWordBreakForCache(1000, "U+4444 U+E0100 U+302D | U+4444");

  // Following test cases are unusual usage of variation selectors and tone
  // marks for caching up the further behavior changes, e.g. index of bounds
  // or crashes. Please feel free to update the test expectations if the
  // behavior change makes sense to you.

  // Isolated Tone marks and Variation Selectors
  ExpectPrevWordBreakForCache(0, "| U+FE00");
  ExpectPrevWordBreakForCache(1, "| U+FE00");
  ExpectPrevWordBreakForCache(1000, "| U+FE00");
  ExpectPrevWordBreakForCache(0, "| U+E0100");
  ExpectPrevWordBreakForCache(1000, "| U+E0100");
  ExpectPrevWordBreakForCache(0, "| U+302D");
  ExpectPrevWordBreakForCache(1000, "| U+302D");

  // CJK Ideographic char + Variation Selector(VS1) + Variation Selector(VS1)
  ExpectPrevWordBreakForCache(0, "| U+845B U+FE00 U+FE00 U+845B");
  ExpectPrevWordBreakForCache(1, "| U+845B U+FE00 U+FE00 U+845B");
  ExpectPrevWordBreakForCache(2, "| U+845B U+FE00 U+FE00 U+845B");
  ExpectPrevWordBreakForCache(3, "| U+845B U+FE00 U+FE00 U+845B");
  ExpectPrevWordBreakForCache(4, "U+845B U+FE00 U+FE00 | U+845B");
  ExpectPrevWordBreakForCache(1000, "U+845B U+FE00 U+FE00 | U+845B");

  // CJK Ideographic char + Variation Selector(VS17) + Variation Selector(VS17)
  ExpectPrevWordBreakForCache(0, "| U+845B U+E0100 U+E0100 U+845B");
  ExpectPrevWordBreakForCache(1, "| U+845B U+E0100 U+E0100 U+845B");
  ExpectPrevWordBreakForCache(2, "| U+845B U+E0100 U+E0100 U+845B");
  ExpectPrevWordBreakForCache(3, "| U+845B U+E0100 U+E0100 U+845B");
  ExpectPrevWordBreakForCache(4, "| U+845B U+E0100 U+E0100 U+845B");
  ExpectPrevWordBreakForCache(5, "| U+845B U+E0100 U+E0100 U+845B");
  ExpectPrevWordBreakForCache(6, "U+845B U+E0100 U+E0100 | U+845B");
  ExpectPrevWordBreakForCache(1000, "U+845B U+E0100 U+E0100 | U+845B");

  // CJK Ideographic char + Variation Selector(VS1) + Variation Selector(VS17)
  ExpectPrevWordBreakForCache(0, "| U+845B U+FE00 U+E0100 U+845B");
  ExpectPrevWordBreakForCache(1, "| U+845B U+FE00 U+E0100 U+845B");
  ExpectPrevWordBreakForCache(2, "| U+845B U+FE00 U+E0100 U+845B");
  ExpectPrevWordBreakForCache(3, "| U+845B U+FE00 U+E0100 U+845B");
  ExpectPrevWordBreakForCache(4, "| U+845B U+FE00 U+E0100 U+845B");
  ExpectPrevWordBreakForCache(5, "U+845B U+FE00 U+E0100 | U+845B");
  ExpectPrevWordBreakForCache(1000, "U+845B U+FE00 U+E0100 | U+845B");

  // CJK Ideographic char + Variation Selector(VS17) + Variation Selector(VS1)
  ExpectPrevWordBreakForCache(0, "| U+845B U+E0100 U+FE00 U+845B");
  ExpectPrevWordBreakForCache(1, "| U+845B U+E0100 U+FE00 U+845B");
  ExpectPrevWordBreakForCache(2, "| U+845B U+E0100 U+FE00 U+845B");
  ExpectPrevWordBreakForCache(3, "| U+845B U+E0100 U+FE00 U+845B");
  ExpectPrevWordBreakForCache(4, "| U+845B U+E0100 U+FE00 U+845B");
  ExpectPrevWordBreakForCache(5, "U+845B U+E0100 U+FE00 | U+845B");
  ExpectPrevWordBreakForCache(1000, "U+845B U+E0100 U+FE00 | U+845B");

  // Tone mark. + Tone mark
  ExpectPrevWordBreakForCache(0, "| U+4444 U+302D U+302D U+4444");
  ExpectPrevWordBreakForCache(1, "| U+4444 U+302D U+302D U+4444");
  ExpectPrevWordBreakForCache(2, "| U+4444 U+302D U+302D U+4444");
  ExpectPrevWordBreakForCache(3, "| U+4444 U+302D U+302D U+4444");
  ExpectPrevWordBreakForCache(4, "U+4444 U+302D U+302D | U+4444");
  ExpectPrevWordBreakForCache(1000, "U+4444 U+302D U+302D | U+4444");
}

}  // namespace minikin
