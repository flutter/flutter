/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

// Tests for the Font class.

#include "config.h"

#include "platform/fonts/Character.h"
#include "platform/fonts/Font.h"

#include <gtest/gtest.h>

namespace blink {

static void TestSpecificUCharRange(UChar rangeStart, UChar rangeEnd)
{
    UChar below[1];
    UChar start[1];
    UChar midway[1];
    UChar end[1];
    UChar above[1];

    below[0] = rangeStart - 1;
    start[0] = rangeStart;
    midway[0] = ((int)rangeStart + (int)rangeEnd) / 2;
    end[0] = rangeEnd;
    above[0] = rangeEnd + 1;

    EXPECT_EQ(SimplePath, Character::characterRangeCodePath(below, 1));
    EXPECT_EQ(ComplexPath, Character::characterRangeCodePath(start, 1));
    EXPECT_EQ(ComplexPath, Character::characterRangeCodePath(midway, 1));
    EXPECT_EQ(ComplexPath, Character::characterRangeCodePath(end, 1));
    EXPECT_EQ(SimplePath, Character::characterRangeCodePath(above, 1));
}

TEST(FontTest, TestCharacterRangeCodePath)
{
    static UChar c1[] = { 0x0 };
    EXPECT_EQ(SimplePath, Character::characterRangeCodePath(c1, 1));

    TestSpecificUCharRange(0x2E5, 0x2E9);
    TestSpecificUCharRange(0x300, 0x36F);
    TestSpecificUCharRange(0x0591, 0x05BD);
    TestSpecificUCharRange(0x05BF, 0x05CF);
    TestSpecificUCharRange(0x0600, 0x109F);
    TestSpecificUCharRange(0x1100, 0x11FF);
    TestSpecificUCharRange(0x135D, 0x135F);
    TestSpecificUCharRange(0x1700, 0x18AF);
    TestSpecificUCharRange(0x1900, 0x194F);
    TestSpecificUCharRange(0x1980, 0x19DF);
    TestSpecificUCharRange(0x1A00, 0x1CFF);

    static UChar c2[] = { 0x1DBF };
    EXPECT_EQ(SimplePath, Character::characterRangeCodePath(c2, 1));
    static UChar c3[] = { 0x1DC0 };
    EXPECT_EQ(ComplexPath, Character::characterRangeCodePath(c3, 1));
    static UChar c4[] = { 0x1DD0 };
    EXPECT_EQ(ComplexPath, Character::characterRangeCodePath(c4, 1));
    static UChar c5[] = { 0x1DFF };
    EXPECT_EQ(ComplexPath, Character::characterRangeCodePath(c5, 1));
    static UChar c6[] = { 0x1E00 };
    EXPECT_EQ(SimpleWithGlyphOverflowPath, Character::characterRangeCodePath(c6, 1));
    static UChar c7[] = { 0x2000 };
    EXPECT_EQ(SimpleWithGlyphOverflowPath, Character::characterRangeCodePath(c7, 1));
    static UChar c8[] = { 0x2001 };
    EXPECT_EQ(SimplePath, Character::characterRangeCodePath(c8, 1));

    TestSpecificUCharRange(0x20D0, 0x20FF);
    TestSpecificUCharRange(0x2CEF, 0x2CF1);
    TestSpecificUCharRange(0x302A, 0x302F);

    TestSpecificUCharRange(0xA67C, 0xA67D);
    TestSpecificUCharRange(0xA6F0, 0xA6F1);
    TestSpecificUCharRange(0xA800, 0xABFF);

    TestSpecificUCharRange(0xD7B0, 0xD7FF);
    TestSpecificUCharRange(0xFE00, 0xFE0F);
    TestSpecificUCharRange(0xFE20, 0xFE2F);
}

TEST(FontTest, TestCharacterRangeCodePathSurrogate1)
{
    /* To be surrogate ... */
    /* 1st character must be 0xD800 .. 0xDBFF */
    /* 2nd character must be 0xdc00 .. 0xdfff */

    /* The following 5 should all be Simple because they are not surrogate. */
    static UChar c1[] = { 0xD800, 0xDBFE };
    EXPECT_EQ(SimplePath, Character::characterRangeCodePath(c1, 2));
    static UChar c2[] = { 0xD800, 0xE000 };
    EXPECT_EQ(SimplePath, Character::characterRangeCodePath(c2, 2));
    static UChar c3[] = { 0xDBFF, 0xDBFE };
    EXPECT_EQ(SimplePath, Character::characterRangeCodePath(c3, 2));
    static UChar c4[] = { 0xDBFF, 0xE000 };
    EXPECT_EQ(SimplePath, Character::characterRangeCodePath(c4, 2));
    static UChar c5[] = { 0xDC00, 0xDBFF };
    EXPECT_EQ(SimplePath, Character::characterRangeCodePath(c5, 2));

    /* To be Complex, the Supplementary Character must be in either */
    /* U+1F1E6 through U+1F1FF or U+E0100 through U+E01EF. */
    /* That is, a lead of 0xD83C with trail 0xDDE6 .. 0xDDFF or */
    /* a lead of 0xDB40 with trail 0xDD00 .. 0xDDEF. */
    static UChar c6[] = { 0xD83C, 0xDDE5 };
    EXPECT_EQ(SimplePath, Character::characterRangeCodePath(c6, 2));
    static UChar c7[] = { 0xD83C, 0xDDE6 };
    EXPECT_EQ(ComplexPath, Character::characterRangeCodePath(c7, 2));
    static UChar c8[] = { 0xD83C, 0xDDF0 };
    EXPECT_EQ(ComplexPath, Character::characterRangeCodePath(c8, 2));
    static UChar c9[] = { 0xD83C, 0xDDFF };
    EXPECT_EQ(ComplexPath, Character::characterRangeCodePath(c9, 2));
    static UChar c10[] = { 0xD83C, 0xDE00 };
    EXPECT_EQ(SimplePath, Character::characterRangeCodePath(c10, 2));

    static UChar c11[] = { 0xDB40, 0xDCFF };
    EXPECT_EQ(SimplePath, Character::characterRangeCodePath(c11, 2));
    static UChar c12[] = { 0xDB40, 0xDD00 };
    EXPECT_EQ(ComplexPath, Character::characterRangeCodePath(c12, 2));
    static UChar c13[] = { 0xDB40, 0xDDED };
    EXPECT_EQ(ComplexPath, Character::characterRangeCodePath(c13, 2));
    static UChar c14[] = { 0xDB40, 0xDDEF };
    EXPECT_EQ(ComplexPath, Character::characterRangeCodePath(c14, 2));
    static UChar c15[] = { 0xDB40, 0xDDF0 };
    EXPECT_EQ(SimplePath, Character::characterRangeCodePath(c15, 2));
}

TEST(FontTest, TestCharacterRangeCodePathString)
{
    // Simple-Simple is still simple
    static UChar c1[] = { 0x2FF, 0x2FF };
    EXPECT_EQ(SimplePath, Character::characterRangeCodePath(c1, 2));
    // Complex-Simple is Complex
    static UChar c2[] = { 0x300, 0x2FF };
    EXPECT_EQ(ComplexPath, Character::characterRangeCodePath(c2, 2));
    // Simple-Complex is Complex
    static UChar c3[] = { 0x2FF, 0x330 };
    EXPECT_EQ(ComplexPath, Character::characterRangeCodePath(c3, 2));
    // Complex-Complex is Complex
    static UChar c4[] = { 0x36F, 0x330 };
    EXPECT_EQ(ComplexPath, Character::characterRangeCodePath(c4, 2));
    // SimpleWithGlyphOverflow-Simple is SimpleWithGlyphOverflow
    static UChar c5[] = { 0x1E00, 0x2FF };
    EXPECT_EQ(SimpleWithGlyphOverflowPath, Character::characterRangeCodePath(c5, 2));
    // Simple-SimpleWithGlyphOverflow is SimpleWithGlyphOverflow
    static UChar c6[] = { 0x2FF, 0x2000 };
    EXPECT_EQ(SimpleWithGlyphOverflowPath, Character::characterRangeCodePath(c6, 2));
    // SimpleWithGlyphOverflow-Complex is Complex
    static UChar c7[] = { 0x1E00, 0x330 };
    EXPECT_EQ(ComplexPath, Character::characterRangeCodePath(c7, 2));
    // Complex-SimpleWithGlyphOverflow is Complex
    static UChar c8[] = { 0x330, 0x2000 };
    EXPECT_EQ(ComplexPath, Character::characterRangeCodePath(c8, 2));
    // Surrogate-Complex is Complex
    static UChar c9[] = { 0xD83C, 0xDDE5, 0x330 };
    EXPECT_EQ(ComplexPath, Character::characterRangeCodePath(c9, 3));
    // Complex-Surrogate is Complex
    static UChar c10[] = { 0x330, 0xD83C, 0xDDE5 };
    EXPECT_EQ(ComplexPath, Character::characterRangeCodePath(c10, 3));
}

static void TestSpecificUChar32RangeIdeograph(UChar32 rangeStart, UChar32 rangeEnd)
{
    EXPECT_FALSE(Character::isCJKIdeograph(rangeStart - 1));
    EXPECT_TRUE(Character::isCJKIdeograph(rangeStart));
    EXPECT_TRUE(Character::isCJKIdeograph((UChar32)((uint64_t)rangeStart + (uint64_t)rangeEnd) / 2));
    EXPECT_TRUE(Character::isCJKIdeograph(rangeEnd));
    EXPECT_FALSE(Character::isCJKIdeograph(rangeEnd + 1));
}

TEST(FontTest, TestIsCJKIdeograph)
{
    // The basic CJK Unified Ideographs block.
    TestSpecificUChar32RangeIdeograph(0x4E00, 0x9FFF);
    // CJK Unified Ideographs Extension A.
    TestSpecificUChar32RangeIdeograph(0x3400, 0x4DBF);
    // CJK Unified Ideographs Extension A and Kangxi Radicals.
    TestSpecificUChar32RangeIdeograph(0x2E80, 0x2FDF);
    // CJK Strokes.
    TestSpecificUChar32RangeIdeograph(0x31C0, 0x31EF);
    // CJK Compatibility Ideographs.
    TestSpecificUChar32RangeIdeograph(0xF900, 0xFAFF);
    // CJK Unified Ideographs Extension B.
    TestSpecificUChar32RangeIdeograph(0x20000, 0x2A6DF);
    // CJK Unified Ideographs Extension C.
    // CJK Unified Ideographs Extension D.
    TestSpecificUChar32RangeIdeograph(0x2A700, 0x2B81F);
    // CJK Compatibility Ideographs Supplement.
    TestSpecificUChar32RangeIdeograph(0x2F800, 0x2FA1F);
}

static void TestSpecificUChar32RangeIdeographSymbol(UChar32 rangeStart, UChar32 rangeEnd)
{
    EXPECT_FALSE(Character::isCJKIdeographOrSymbol(rangeStart - 1));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(rangeStart));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol((UChar32)((uint64_t)rangeStart + (uint64_t)rangeEnd) / 2));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(rangeEnd));
    EXPECT_FALSE(Character::isCJKIdeographOrSymbol(rangeEnd + 1));
}

TEST(FontTest, TestIsCJKIdeographOrSymbol)
{
    // CJK Compatibility Ideographs Supplement.
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2C7));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2CA));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2CB));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2D9));

    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2020));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2021));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2030));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x203B));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x203C));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2042));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2047));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2048));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2049));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2051));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x20DD));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x20DE));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2100));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2103));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2105));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2109));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x210A));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2113));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2116));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2121));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x212B));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x213B));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2150));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2151));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2152));

    TestSpecificUChar32RangeIdeographSymbol(0x2156, 0x215A);
    TestSpecificUChar32RangeIdeographSymbol(0x2160, 0x216B);
    TestSpecificUChar32RangeIdeographSymbol(0x2170, 0x217B);

    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x217F));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2189));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2307));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2312));

    EXPECT_FALSE(Character::isCJKIdeographOrSymbol(0x23BD));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x23BE));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x23C4));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x23CC));
    EXPECT_FALSE(Character::isCJKIdeographOrSymbol(0x23CD));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x23CE));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2423));

    TestSpecificUChar32RangeIdeographSymbol(0x2460, 0x2492);
    TestSpecificUChar32RangeIdeographSymbol(0x249C, 0x24FF);

    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x25A0));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x25A1));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x25A2));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x25AA));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x25AB));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x25B1));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x25B2));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x25B3));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x25B6));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x25B7));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x25BC));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x25BD));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x25C0));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x25C1));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x25C6));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x25C7));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x25C9));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x25CB));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x25CC));

    TestSpecificUChar32RangeIdeographSymbol(0x25CE, 0x25D3);
    TestSpecificUChar32RangeIdeographSymbol(0x25E2, 0x25E6);

    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x25EF));

    TestSpecificUChar32RangeIdeographSymbol(0x2600, 0x2603);

    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2605));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2606));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x260E));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2616));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2617));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2640));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2642));

    TestSpecificUChar32RangeIdeographSymbol(0x2660, 0x266F);
    TestSpecificUChar32RangeIdeographSymbol(0x2672, 0x267D);

    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x26A0));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x26BD));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x26BE));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2713));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x271A));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x273F));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2740));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2756));

    TestSpecificUChar32RangeIdeographSymbol(0x2776, 0x277F);

    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x2B1A));

    TestSpecificUChar32RangeIdeographSymbol(0x2FF0, 0x302F);
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x3031));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x312F));
    EXPECT_FALSE(Character::isCJKIdeographOrSymbol(0x3130));

    EXPECT_FALSE(Character::isCJKIdeographOrSymbol(0x318F));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x3190));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x319F));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x31BF));

    EXPECT_FALSE(Character::isCJKIdeographOrSymbol(0x31FF));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x3200));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x3300));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x33FF));

    TestSpecificUChar32RangeIdeographSymbol(0xF860, 0xF862);
    TestSpecificUChar32RangeIdeographSymbol(0xFE30, 0xFE4F);

    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0xFE10));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0xFE11));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0xFE12));
    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0xFE19));

    EXPECT_FALSE(Character::isCJKIdeographOrSymbol(0xFF0D));
    EXPECT_FALSE(Character::isCJKIdeographOrSymbol(0xFF1B));
    EXPECT_FALSE(Character::isCJKIdeographOrSymbol(0xFF1C));
    EXPECT_FALSE(Character::isCJKIdeographOrSymbol(0xFF1E));

    TestSpecificUChar32RangeIdeographSymbol(0xFF00, 0xFFEF);

    EXPECT_TRUE(Character::isCJKIdeographOrSymbol(0x1F100));

    TestSpecificUChar32RangeIdeographSymbol(0x1F110, 0x1F129);
    TestSpecificUChar32RangeIdeographSymbol(0x1F130, 0x1F149);
    TestSpecificUChar32RangeIdeographSymbol(0x1F150, 0x1F169);
    TestSpecificUChar32RangeIdeographSymbol(0x1F170, 0x1F189);
    TestSpecificUChar32RangeIdeographSymbol(0x1F200, 0x1F6FF);
}

} // namespace blink

