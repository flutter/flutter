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
#include <UnicodeUtils.h>
#include <minikin/GraphemeBreak.h>

using namespace android;

bool IsBreak(const char* src) {
    const size_t BUF_SIZE = 256;
    uint16_t buf[BUF_SIZE];
    size_t offset;
    size_t size;
    ParseUnicode(buf, BUF_SIZE, src, &size, &offset);
    return GraphemeBreak::isGraphemeBreak(buf, 0, size, offset);
}

TEST(GraphemeBreak, utf16) {
    EXPECT_FALSE(IsBreak("U+D83C | U+DC31"));  // emoji, U+1F431

    // tests for invalid UTF-16
    EXPECT_TRUE(IsBreak("U+D800 | U+D800"));  // two leading surrogates
    EXPECT_TRUE(IsBreak("U+DC00 | U+DC00"));  // two trailing surrogates
    EXPECT_TRUE(IsBreak("'a' | U+D800"));  // lonely leading surrogate
    EXPECT_TRUE(IsBreak("U+DC00 | 'a'"));  // lonely trailing surrogate
    EXPECT_TRUE(IsBreak("U+D800 | 'a'"));  // leading surrogate followed by non-surrogate
    EXPECT_TRUE(IsBreak("'a' | U+DC00"));  // non-surrogate followed by trailing surrogate
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

    // Rule GB8a, Regional_Indicator x Regional_Indicator
    EXPECT_FALSE(IsBreak("U+1F1FA | U+1F1F8"));

    // Rule GB9, x Extend
    EXPECT_FALSE(IsBreak("'a' | U+0301"));  // combining accent
    // Rule GB9a, x SpacingMark
    EXPECT_FALSE(IsBreak("U+0915 | U+093E"));  // KA, AA (spacing mark)
    // Rule GB9b, Prepend x
    // see tailoring test for prepend, as current ICU doesn't have any characters in the class

    // Rule GB10, Any ÷ Any
    EXPECT_TRUE(IsBreak("'a' | 'b'"));
    EXPECT_TRUE(IsBreak("'f' | 'i'"));  // probable ligature
    EXPECT_TRUE(IsBreak("U+0644 | U+0627"));  // probable ligature, lam + alef
    EXPECT_TRUE(IsBreak("U+4E00 | U+4E00"));  // CJK ideographs
    EXPECT_TRUE(IsBreak("'a' | U+1F1FA U+1F1F8"));  // Regional indicator pair (flag)
    EXPECT_TRUE(IsBreak("U+1F1FA U+1F1F8 | 'a'"));  // Regional indicator pair (flag)
}

TEST(GraphemeBreak, tailoring) {
    // control characters that we interpret as "extend"
    EXPECT_FALSE(IsBreak("'a' | U+00AD"));  // soft hyphen
    EXPECT_FALSE(IsBreak("'a' | U+200B"));  // zwsp
    EXPECT_FALSE(IsBreak("'a' | U+200E"));  // lrm
    EXPECT_FALSE(IsBreak("'a' | U+202A"));  // lre
    EXPECT_FALSE(IsBreak("'a' | U+E0041"));  // tag character

    // UTC-approved characters for the Prepend class
    EXPECT_FALSE(IsBreak("U+06DD | U+0661"));  // arabic subtending mark + digit one

    EXPECT_TRUE(IsBreak("U+0E01 | U+0E33"));  // Thai sara am

    // virama is not a grapheme break, but "pure killer" is
    EXPECT_FALSE(IsBreak("U+0915 | U+094D U+0915"));  // Devanagari ka+virama+ka
    EXPECT_FALSE(IsBreak("U+0915 U+094D | U+0915"));  // Devanagari ka+virama+ka
    EXPECT_FALSE(IsBreak("U+0E01 | U+0E3A U+0E01"));  // thai phinthu = pure killer
    EXPECT_TRUE(IsBreak("U+0E01 U+0E3A | U+0E01"));  // thai phinthu = pure killer
}

TEST(GraphemeBreak, offsets) {
    uint16_t string[] = { 0x0041, 0x06DD, 0x0045, 0x0301, 0x0049, 0x0301 };
    EXPECT_TRUE(GraphemeBreak::isGraphemeBreak(string, 2, 3, 2));
    EXPECT_FALSE(GraphemeBreak::isGraphemeBreak(string, 2, 3, 3));
    EXPECT_TRUE(GraphemeBreak::isGraphemeBreak(string, 2, 3, 4));
    EXPECT_TRUE(GraphemeBreak::isGraphemeBreak(string, 2, 3, 5));
}
