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
#include <minikin/GraphemeBreak.h>
#include "UnicodeUtils.h"

namespace minikin {

bool IsBreak(const char* src) {
  const size_t BUF_SIZE = 256;
  uint16_t buf[BUF_SIZE];
  size_t offset;
  size_t size;
  ParseUnicode(buf, BUF_SIZE, src, &size, &offset);
  return GraphemeBreak::isGraphemeBreak(nullptr, buf, 0, size, offset);
}

bool IsBreakWithAdvances(const float* advances, const char* src) {
  const size_t BUF_SIZE = 256;
  uint16_t buf[BUF_SIZE];
  size_t offset;
  size_t size;
  ParseUnicode(buf, BUF_SIZE, src, &size, &offset);
  return GraphemeBreak::isGraphemeBreak(advances, buf, 0, size, offset);
}

TEST(GraphemeBreak, utf16) {
  EXPECT_FALSE(IsBreak("U+D83C | U+DC31"));  // emoji, U+1F431

  // tests for invalid UTF-16
  EXPECT_TRUE(IsBreak("U+D800 | U+D800"));  // two leading surrogates
  EXPECT_TRUE(IsBreak("U+DC00 | U+DC00"));  // two trailing surrogates
  EXPECT_TRUE(IsBreak("'a' | U+D800"));     // lonely leading surrogate
  EXPECT_TRUE(IsBreak("U+DC00 | 'a'"));     // lonely trailing surrogate
  EXPECT_TRUE(
      IsBreak("U+D800 | 'a'"));  // leading surrogate followed by non-surrogate
  EXPECT_TRUE(
      IsBreak("'a' | U+DC00"));  // non-surrogate followed by trailing surrogate
}

TEST(GraphemeBreak, rules) {
  // Rule GB1, sot ÷; Rule GB2, ÷ eot
  EXPECT_TRUE(IsBreak("| 'a'"));
  EXPECT_TRUE(IsBreak("'a' |"));

  // Rule GB3, CR x LF
  EXPECT_FALSE(IsBreak("U+000D | U+000A"));  // CR x LF

  // Rule GB4, (Control | CR | LF) ÷
  EXPECT_TRUE(IsBreak("'a' | U+2028"));  // Line separator
  EXPECT_TRUE(IsBreak("'a' | U+000D"));  // LF
  EXPECT_TRUE(IsBreak("'a' | U+000A"));  // CR

  // Rule GB5, ÷ (Control | CR | LF)
  EXPECT_TRUE(IsBreak("U+2028 | 'a'"));  // Line separator
  EXPECT_TRUE(IsBreak("U+000D | 'a'"));  // LF
  EXPECT_TRUE(IsBreak("U+000A | 'a'"));  // CR

  // Rule GB6, L x ( L | V | LV | LVT )
  EXPECT_FALSE(IsBreak("U+1100 | U+1100"));  // L x L
  EXPECT_FALSE(IsBreak("U+1100 | U+1161"));  // L x V
  EXPECT_FALSE(IsBreak("U+1100 | U+AC00"));  // L x LV
  EXPECT_FALSE(IsBreak("U+1100 | U+AC01"));  // L x LVT

  // Rule GB7, ( LV | V ) x ( V | T )
  EXPECT_FALSE(IsBreak("U+AC00 | U+1161"));  // LV x V
  EXPECT_FALSE(IsBreak("U+1161 | U+1161"));  // V x V
  EXPECT_FALSE(IsBreak("U+AC00 | U+11A8"));  // LV x T
  EXPECT_FALSE(IsBreak("U+1161 | U+11A8"));  // V x T

  // Rule GB8, ( LVT | T ) x T
  EXPECT_FALSE(IsBreak("U+AC01 | U+11A8"));  // LVT x T
  EXPECT_FALSE(IsBreak("U+11A8 | U+11A8"));  // T x T

  // Other hangul pairs not counted above _are_ breaks (GB10)
  EXPECT_TRUE(IsBreak("U+AC00 | U+1100"));  // LV x L
  EXPECT_TRUE(IsBreak("U+AC01 | U+1100"));  // LVT x L
  EXPECT_TRUE(IsBreak("U+11A8 | U+1100"));  // T x L
  EXPECT_TRUE(IsBreak("U+11A8 | U+AC00"));  // T x LV
  EXPECT_TRUE(IsBreak("U+11A8 | U+AC01"));  // T x LVT

  // Rule GB12 and Rule GB13, Regional_Indicator x Regional_Indicator
  EXPECT_FALSE(IsBreak("U+1F1FA | U+1F1F8"));
  EXPECT_TRUE(IsBreak(
      "U+1F1FA U+1F1F8 | U+1F1FA U+1F1F8"));  // Regional indicator pair (flag)
  EXPECT_FALSE(IsBreak(
      "U+1F1FA | U+1F1F8 U+1F1FA U+1F1F8"));  // Regional indicator pair (flag)
  EXPECT_FALSE(IsBreak(
      "U+1F1FA U+1F1F8 U+1F1FA | U+1F1F8"));  // Regional indicator pair (flag)

  EXPECT_TRUE(
      IsBreak("U+1F1FA U+1F1F8 | U+1F1FA"));  // Regional indicator pair (flag)
  EXPECT_FALSE(
      IsBreak("U+1F1FA | U+1F1F8 U+1F1FA"));  // Regional indicator pair (flag)
  // Same case as the two above, knowing that the first two characters ligate,
  // which is what would typically happen.
  const float firstPairLigated[] = {1.0, 0.0, 0.0, 0.0,
                                    1.0, 0.0};  // Two entries per codepoint
  EXPECT_TRUE(
      IsBreakWithAdvances(firstPairLigated, "U+1F1FA U+1F1F8 | U+1F1FA"));
  EXPECT_FALSE(
      IsBreakWithAdvances(firstPairLigated, "U+1F1FA | U+1F1F8 U+1F1FA"));
  // Repeat the tests, But now the font doesn't have a ligature for the first
  // two characters, while it does have a ligature for the last two. This could
  // happen for fonts that do not support some (potentially encoded later than
  // they were developed) flags.
  const float secondPairLigated[] = {1.0, 0.0, 1.0, 0.0, 0.0, 0.0};
  EXPECT_FALSE(
      IsBreakWithAdvances(secondPairLigated, "U+1F1FA U+1F1F8 | U+1F1FA"));
  EXPECT_TRUE(
      IsBreakWithAdvances(secondPairLigated, "U+1F1FA | U+1F1F8 U+1F1FA"));

  EXPECT_TRUE(IsBreak(
      "'a' U+1F1FA U+1F1F8 | U+1F1FA"));  // Regional indicator pair (flag)
  EXPECT_FALSE(IsBreak(
      "'a' U+1F1FA | U+1F1F8 U+1F1FA"));  // Regional indicator pair (flag)

  EXPECT_TRUE(IsBreak("'a' U+1F1FA U+1F1F8 | U+1F1FA U+1F1F8"));  // Regional
                                                                  // indicator
                                                                  // pair (flag)
  EXPECT_FALSE(IsBreak("'a' U+1F1FA | U+1F1F8 U+1F1FA U+1F1F8"));  // Regional
                                                                   // indicator
                                                                   // pair
                                                                   // (flag)
  EXPECT_FALSE(IsBreak("'a' U+1F1FA U+1F1F8 U+1F1FA | U+1F1F8"));  // Regional
                                                                   // indicator
                                                                   // pair
                                                                   // (flag)

  // Rule GB9, x (Extend | ZWJ)
  EXPECT_FALSE(IsBreak("'a' | U+0301"));  // combining accent
  // TODO(jsimmons): re-enable this test when ICU has been updated in all
  // Flutter platforms.
  // EXPECT_FALSE(IsBreak("'a' | U+200D"));  // ZWJ
  // Rule GB9a, x SpacingMark
  EXPECT_FALSE(IsBreak("U+0915 | U+093E"));  // KA, AA (spacing mark)
  // Rule GB9b, Prepend x
  // see tailoring test for prepend, as current ICU doesn't have any characters
  // in the class

  // Rule GB999, Any ÷ Any
  EXPECT_TRUE(IsBreak("'a' | 'b'"));
  EXPECT_TRUE(IsBreak("'f' | 'i'"));        // probable ligature
  EXPECT_TRUE(IsBreak("U+0644 | U+0627"));  // probable ligature, lam + alef
  EXPECT_TRUE(IsBreak("U+4E00 | U+4E00"));  // CJK ideographs
  EXPECT_TRUE(
      IsBreak("'a' | U+1F1FA U+1F1F8"));  // Regional indicator pair (flag)
  EXPECT_TRUE(
      IsBreak("U+1F1FA U+1F1F8 | 'a'"));  // Regional indicator pair (flag)

  // Extended rule for emoji tag sequence.
  EXPECT_TRUE(IsBreak("'a' | U+1F3F4 'a'"));
  EXPECT_TRUE(IsBreak("'a' U+1F3F4 | 'a'"));

  // Immediate tag_term after tag_base.
  EXPECT_TRUE(IsBreak("'a' | U+1F3F4 U+E007F 'a'"));
  EXPECT_FALSE(IsBreak("U+1F3F4 | U+E007F"));
  EXPECT_TRUE(IsBreak("'a' U+1F3F4 U+E007F | 'a'"));

  // Flag sequence
  // U+1F3F4 U+E0067 U+E0062 U+E0073 U+E0063 U+E0074 U+E007F is emoji tag
  // sequence for the flag of Scotland. U+1F3F4 is WAVING BLACK FLAG. This can
  // be a tag_base character. U+E0067 is TAG LATIN SMALL LETTER G. This can be a
  // part of tag_spec. U+E0062 is TAG LATIN SMALL LETTER B. This can be a part
  // of tag_spec. U+E0073 is TAG LATIN SMALL LETTER S. This can be a part of
  // tag_spec. U+E0063 is TAG LATIN SMALL LETTER C. This can be a part of
  // tag_spec. U+E0074 is TAG LATIN SMALL LETTER T. This can be a part of
  // tag_spec. U+E007F is CANCEL TAG. This is a tag_term character.
  EXPECT_TRUE(
      IsBreak("'a' | U+1F3F4 U+E0067 U+E0062 U+E0073 U+E0063 U+E0074 U+E007F"));
  EXPECT_FALSE(
      IsBreak("U+1F3F4 | U+E0067 U+E0062 U+E0073 U+E0063 U+E0074 U+E007F"));
  EXPECT_FALSE(
      IsBreak("U+1F3F4 U+E0067 | U+E0062 U+E0073 U+E0063 U+E0074 U+E007F"));
  EXPECT_FALSE(
      IsBreak("U+1F3F4 U+E0067 U+E0062 | U+E0073 U+E0063 U+E0074 U+E007F"));
  EXPECT_FALSE(
      IsBreak("U+1F3F4 U+E0067 U+E0062 U+E0073 | U+E0063 U+E0074 U+E007F"));
  EXPECT_FALSE(
      IsBreak("U+1F3F4 U+E0067 U+E0062 U+E0073 U+E0063 | U+E0074 U+E007F"));
  EXPECT_FALSE(
      IsBreak("U+1F3F4 U+E0067 U+E0062 U+E0073 U+E0063 U+E0074 | U+E007F"));
  EXPECT_TRUE(
      IsBreak("U+1F3F4 U+E0067 U+E0062 U+E0073 U+E0063 U+E0074 U+E007F | 'a'"));
}

TEST(GraphemeBreak, DISABLED_tailoring) {
  // control characters that we interpret as "extend"
  EXPECT_FALSE(IsBreak("'a' | U+00AD"));   // soft hyphen
  EXPECT_FALSE(IsBreak("'a' | U+200B"));   // zwsp
  EXPECT_FALSE(IsBreak("'a' | U+200E"));   // lrm
  EXPECT_FALSE(IsBreak("'a' | U+202A"));   // lre
  EXPECT_FALSE(IsBreak("'a' | U+E0041"));  // tag character

  // UTC-approved characters for the Prepend class
  EXPECT_FALSE(
      IsBreak("U+06DD | U+0661"));  // arabic subtending mark + digit one

  EXPECT_TRUE(IsBreak("U+0E01 | U+0E33"));  // Thai sara am

  // virama is not a grapheme break, but "pure killer" is
  EXPECT_FALSE(IsBreak("U+0915 | U+094D U+0915"));  // Devanagari ka+virama+ka
  EXPECT_FALSE(IsBreak("U+0915 U+094D | U+0915"));  // Devanagari ka+virama+ka
  EXPECT_FALSE(
      IsBreak("U+0E01 | U+0E3A U+0E01"));          // thai phinthu = pure killer
  EXPECT_TRUE(IsBreak("U+0E01 U+0E3A | U+0E01"));  // thai phinthu = pure killer

  // Repetition of above tests, but with a given advances array that implies
  // everything became just one cluster.
  const float conjoined[] = {1.0, 0.0, 0.0};
  EXPECT_FALSE(IsBreakWithAdvances(
      conjoined,
      "U+0915 | U+094D U+0915"));  // Devanagari ka+virama+ka
  EXPECT_FALSE(IsBreakWithAdvances(
      conjoined,
      "U+0915 U+094D | U+0915"));  // Devanagari ka+virama+ka
  EXPECT_FALSE(IsBreakWithAdvances(
      conjoined,
      "U+0E01 | U+0E3A U+0E01"));  // thai phinthu = pure killer
  EXPECT_TRUE(IsBreakWithAdvances(
      conjoined,
      "U+0E01 U+0E3A | U+0E01"));  // thai phinthu = pure killer

  // Repetition of above tests, but with a given advances array that the virama
  // did not form a cluster with the following consonant. The difference is that
  // there is now a grapheme break after the virama in ka+virama+ka.
  const float separate[] = {1.0, 0.0, 1.0};
  EXPECT_FALSE(IsBreakWithAdvances(
      separate,
      "U+0915 | U+094D U+0915"));  // Devanagari ka+virama+ka
  EXPECT_TRUE(IsBreakWithAdvances(
      separate,
      "U+0915 U+094D | U+0915"));  // Devanagari ka+virama+ka
  EXPECT_FALSE(IsBreakWithAdvances(
      separate,
      "U+0E01 | U+0E3A U+0E01"));  // thai phinthu = pure killer
  EXPECT_TRUE(IsBreakWithAdvances(
      separate,
      "U+0E01 U+0E3A | U+0E01"));  // thai phinthu = pure killer

  // suppress grapheme breaks in zwj emoji sequences
  EXPECT_FALSE(
      IsBreak("U+1F469 U+200D | U+2764 U+FE0F U+200D U+1F48B U+200D U+1F468"));
  EXPECT_FALSE(
      IsBreak("U+1F469 U+200D U+2764 U+FE0F U+200D | U+1F48B U+200D U+1F468"));
  EXPECT_FALSE(
      IsBreak("U+1F469 U+200D U+2764 U+FE0F U+200D U+1F48B U+200D | U+1F468"));
  EXPECT_FALSE(IsBreak("U+1F468 U+200D | U+1F469 U+200D U+1F466"));
  EXPECT_FALSE(IsBreak("U+1F468 U+200D U+1F469 U+200D | U+1F466"));
  EXPECT_FALSE(
      IsBreak("U+1F469 U+200D | U+1F469 U+200D U+1F467 U+200D U+1F466"));
  EXPECT_FALSE(
      IsBreak("U+1F469 U+200D U+1F469 U+200D | U+1F467 U+200D U+1F466"));
  EXPECT_FALSE(
      IsBreak("U+1F469 U+200D U+1F469 U+200D U+1F467 U+200D | U+1F466"));
  EXPECT_FALSE(IsBreak("U+1F441 U+200D | U+1F5E8"));

  // Do not break before and after zwj with all kind of emoji characters.
  EXPECT_FALSE(IsBreak("U+1F431 | U+200D U+1F464"));
  EXPECT_FALSE(IsBreak("U+1F431 U+200D | U+1F464"));

  // ARABIC LETTER BEH + ZWJ + heart, not a zwj emoji sequence, so we preserve
  // the break
  EXPECT_TRUE(IsBreak("U+0628 U+200D | U+2764"));
}

TEST(GraphemeBreak, DISABLED_emojiModifiers) {
  EXPECT_FALSE(
      IsBreak("U+261D | U+1F3FB"));  // white up pointing index + modifier
  EXPECT_FALSE(IsBreak("U+270C | U+1F3FB"));   // victory hand + modifier
  EXPECT_FALSE(IsBreak("U+1F466 | U+1F3FB"));  // boy + modifier
  EXPECT_FALSE(IsBreak("U+1F466 | U+1F3FC"));  // boy + modifier
  EXPECT_FALSE(IsBreak("U+1F466 | U+1F3FD"));  // boy + modifier
  EXPECT_FALSE(IsBreak("U+1F466 | U+1F3FE"));  // boy + modifier
  EXPECT_FALSE(IsBreak("U+1F466 | U+1F3FF"));  // boy + modifier
  EXPECT_FALSE(IsBreak("U+1F918 | U+1F3FF"));  // sign of the horns + modifier
  EXPECT_FALSE(IsBreak("U+1F933 | U+1F3FF"));  // selfie (Unicode 9) + modifier
  // Repetition of the tests above, with the knowledge that they are ligated.
  const float ligated1_2[] = {1.0, 0.0, 0.0};
  const float ligated2_2[] = {1.0, 0.0, 0.0, 0.0};
  EXPECT_FALSE(IsBreakWithAdvances(ligated1_2, "U+261D | U+1F3FB"));
  EXPECT_FALSE(IsBreakWithAdvances(ligated1_2, "U+270C | U+1F3FB"));
  EXPECT_FALSE(IsBreakWithAdvances(ligated2_2, "U+1F466 | U+1F3FB"));
  EXPECT_FALSE(IsBreakWithAdvances(ligated2_2, "U+1F466 | U+1F3FC"));
  EXPECT_FALSE(IsBreakWithAdvances(ligated2_2, "U+1F466 | U+1F3FD"));
  EXPECT_FALSE(IsBreakWithAdvances(ligated2_2, "U+1F466 | U+1F3FE"));
  EXPECT_FALSE(IsBreakWithAdvances(ligated2_2, "U+1F466 | U+1F3FF"));
  EXPECT_FALSE(IsBreakWithAdvances(ligated2_2, "U+1F918 | U+1F3FF"));
  EXPECT_FALSE(IsBreakWithAdvances(ligated2_2, "U+1F933 | U+1F3FF"));
  // Repetition of the tests above, with the knowledge that they are not
  // ligated.
  const float unligated1_2[] = {1.0, 1.0, 0.0};
  const float unligated2_2[] = {1.0, 0.0, 1.0, 0.0};
  EXPECT_TRUE(IsBreakWithAdvances(unligated1_2, "U+261D | U+1F3FB"));
  EXPECT_TRUE(IsBreakWithAdvances(unligated1_2, "U+270C | U+1F3FB"));
  EXPECT_TRUE(IsBreakWithAdvances(unligated2_2, "U+1F466 | U+1F3FB"));
  EXPECT_TRUE(IsBreakWithAdvances(unligated2_2, "U+1F466 | U+1F3FC"));
  EXPECT_TRUE(IsBreakWithAdvances(unligated2_2, "U+1F466 | U+1F3FD"));
  EXPECT_TRUE(IsBreakWithAdvances(unligated2_2, "U+1F466 | U+1F3FE"));
  EXPECT_TRUE(IsBreakWithAdvances(unligated2_2, "U+1F466 | U+1F3FF"));
  EXPECT_TRUE(IsBreakWithAdvances(unligated2_2, "U+1F918 | U+1F3FF"));
  EXPECT_TRUE(IsBreakWithAdvances(unligated2_2, "U+1F933 | U+1F3FF"));

  // adding extend characters between emoji base and modifier doesn't affect
  // grapheme cluster
  EXPECT_FALSE(IsBreak(
      "U+270C U+FE0E | U+1F3FB"));  // victory hand + text style + modifier
  EXPECT_FALSE(
      IsBreak("U+270C U+FE0F | U+1F3FB"));  // heart + emoji style + modifier
  // Repetition of the two tests above, with the knowledge that they are
  // ligated.
  const float ligated1_1_2[] = {1.0, 0.0, 0.0, 0.0};
  EXPECT_FALSE(IsBreakWithAdvances(ligated1_1_2, "U+270C U+FE0E | U+1F3FB"));
  EXPECT_FALSE(IsBreakWithAdvances(ligated1_1_2, "U+270C U+FE0F | U+1F3FB"));
  // Repetition of the first two tests, with the knowledge that they are not
  // ligated.
  const float unligated1_1_2[] = {1.0, 0.0, 1.0, 0.0};
  EXPECT_TRUE(IsBreakWithAdvances(unligated1_1_2, "U+270C U+FE0E | U+1F3FB"));
  EXPECT_TRUE(IsBreakWithAdvances(unligated1_1_2, "U+270C U+FE0F | U+1F3FB"));

  // heart is not an emoji base
  EXPECT_TRUE(IsBreak("U+2764 | U+1F3FB"));  // heart + modifier
  EXPECT_TRUE(
      IsBreak("U+2764 U+FE0E | U+1F3FB"));  // heart + emoji style + modifier
  EXPECT_TRUE(
      IsBreak("U+2764 U+FE0F | U+1F3FB"));    // heart + emoji style + modifier
  EXPECT_TRUE(IsBreak("U+1F3FB | U+1F3FB"));  // modifier + modifier

  // rat is not an emoji modifer
  EXPECT_TRUE(IsBreak("U+1F466 | U+1F400"));  // boy + rat
}

TEST(GraphemeBreak, DISABLED_genderBalancedEmoji) {
  // U+1F469 is WOMAN, U+200D is ZWJ, U+1F4BC is BRIEFCASE.
  EXPECT_FALSE(IsBreak("U+1F469 | U+200D U+1F4BC"));
  EXPECT_FALSE(IsBreak("U+1F469 U+200D | U+1F4BC"));
  // The above two cases, when the ligature is not supported in the font. We now
  // expect a break between them.
  const float unligated2_1_2[] = {1.0, 0.0, 0.0, 1.0, 0.0};
  EXPECT_FALSE(IsBreakWithAdvances(unligated2_1_2, "U+1F469 | U+200D U+1F4BC"));
  EXPECT_TRUE(IsBreakWithAdvances(unligated2_1_2, "U+1F469 U+200D | U+1F4BC"));

  // U+2695 has now emoji property, so should be part of ZWJ sequence.
  EXPECT_FALSE(IsBreak("U+1F469 | U+200D U+2695"));
  EXPECT_FALSE(IsBreak("U+1F469 U+200D | U+2695"));
  // The above two cases, when the ligature is not supported in the font. We now
  // expect a break between them.
  const float unligated2_1_1[] = {1.0, 0.0, 0.0, 1.0};
  EXPECT_FALSE(IsBreakWithAdvances(unligated2_1_1, "U+1F469 | U+200D U+2695"));
  EXPECT_TRUE(IsBreakWithAdvances(unligated2_1_1, "U+1F469 U+200D | U+2695"));
}

TEST(GraphemeBreak, offsets) {
  uint16_t string[] = {0x0041, 0x06DD, 0x0045, 0x0301, 0x0049, 0x0301};
  EXPECT_TRUE(GraphemeBreak::isGraphemeBreak(nullptr, string, 2, 3, 2));
  EXPECT_FALSE(GraphemeBreak::isGraphemeBreak(nullptr, string, 2, 3, 3));
  EXPECT_TRUE(GraphemeBreak::isGraphemeBreak(nullptr, string, 2, 3, 4));
  EXPECT_TRUE(GraphemeBreak::isGraphemeBreak(nullptr, string, 2, 3, 5));
}

}  // namespace minikin
