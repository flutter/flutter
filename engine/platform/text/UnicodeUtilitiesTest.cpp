/*
 * Copyright (c) 2013 Yandex LLC. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Yandex LLC nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/text/UnicodeUtilities.h"

#include "wtf/Vector.h"
#include "wtf/text/WTFString.h"
#include "wtf/unicode/CharacterNames.h"
#include <gtest/gtest.h>
#include <unicode/uchar.h>

using namespace blink;

namespace {

static const UChar32 kMaxLatinCharCount = 256;

static bool isTestFirstAndLastCharsInCategoryFailed = false;
UBool U_CALLCONV testFirstAndLastCharsInCategory(const void *context, UChar32 start, UChar32 limit, UCharCategory type)
{
    if (start >= kMaxLatinCharCount
        && U_MASK(type) & (U_GC_S_MASK | U_GC_P_MASK | U_GC_Z_MASK | U_GC_CF_MASK)
        && (!isSeparator(start) || !isSeparator(limit - 1))) {
        isTestFirstAndLastCharsInCategoryFailed = true;

        // Break enumeration process
        return 0;
    }

    return 1;
}

TEST(WebCoreUnicodeUnit, Separators)
{
    static const bool latinSeparatorTable[kMaxLatinCharCount] = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, // space ! " # $ % & ' ( ) * + , - . /
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, //                         : ; < = > ?
        1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //   @
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, //                         [ \ ] ^ _
        1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //   `
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, //                           { | } ~
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0
    };

    for (UChar32 character = 0; character < kMaxLatinCharCount; ++character) {
        EXPECT_EQ(isSeparator(character), latinSeparatorTable[character]);
    }

    isTestFirstAndLastCharsInCategoryFailed = false;
    u_enumCharTypes(&testFirstAndLastCharsInCategory, 0);
    EXPECT_FALSE(isTestFirstAndLastCharsInCategoryFailed);
}

TEST(WebCoreUnicodeUnit, KanaLetters)
{
    // Non Kana symbols
    for (UChar character = 0; character < 0x3041; ++character)
        EXPECT_FALSE(isKanaLetter(character));

    // Hiragana letters.
    for (UChar character = 0x3041; character <= 0x3096; ++character)
        EXPECT_TRUE(isKanaLetter(character));

    // Katakana letters.
    for (UChar character = 0x30A1; character <= 0x30FA; ++character)
        EXPECT_TRUE(isKanaLetter(character));
}

TEST(WebCoreUnicodeUnit, ContainsKanaLetters)
{
    // Non Kana symbols
    String nonKanaString;
    for (UChar character = 0; character < 0x3041; ++character)
        nonKanaString.append(character);
    EXPECT_FALSE(containsKanaLetters(nonKanaString));

    // Hiragana letters.
    for (UChar character = 0x3041; character <= 0x3096; ++character) {
        String str(nonKanaString);
        str.append(character);
        EXPECT_TRUE(containsKanaLetters(str));
    }

    // Katakana letters.
    for (UChar character = 0x30A1; character <= 0x30FA; ++character) {
        String str(nonKanaString);
        str.append(character);
        EXPECT_TRUE(containsKanaLetters(str));
    }
}

TEST(WebCoreUnicodeUnit, FoldQuoteMarkOrSoftHyphenTest)
{
    const UChar charactersToFold[] = {
        hebrewPunctuationGershayim, leftDoubleQuotationMark, rightDoubleQuotationMark,
        hebrewPunctuationGeresh, leftSingleQuotationMark, rightSingleQuotationMark,
        softHyphen
    };

    String stringToFold(charactersToFold, WTF_ARRAY_LENGTH(charactersToFold));
    Vector<UChar> buffer;
    stringToFold.appendTo(buffer);

    foldQuoteMarksAndSoftHyphens(stringToFold);

    const String foldedString("\"\"\"\'\'\'\0", WTF_ARRAY_LENGTH(charactersToFold));
    EXPECT_EQ(stringToFold, foldedString);

    foldQuoteMarksAndSoftHyphens(buffer.data(), buffer.size());
    EXPECT_EQ(String(buffer), foldedString);
}

TEST(WebCoreUnicodeUnit, OnlyKanaLettersEqualityTest)
{
    const UChar nonKanaString1[] = { 'a', 'b', 'c', 'd' };
    const UChar nonKanaString2[] = { 'e', 'f', 'g' };

    // Check that non-Kana letters will be skipped.
    EXPECT_TRUE(checkOnlyKanaLettersInStrings(
        nonKanaString1, WTF_ARRAY_LENGTH(nonKanaString1),
        nonKanaString2, WTF_ARRAY_LENGTH(nonKanaString2)));

    const UChar kanaString[] = { 'e', 'f', 'g', 0x3041 };
    EXPECT_FALSE(checkOnlyKanaLettersInStrings(
        kanaString, WTF_ARRAY_LENGTH(kanaString),
        nonKanaString2, WTF_ARRAY_LENGTH(nonKanaString2)));

    // Compare with self.
    EXPECT_TRUE(checkOnlyKanaLettersInStrings(
        kanaString, WTF_ARRAY_LENGTH(kanaString),
        kanaString, WTF_ARRAY_LENGTH(kanaString)));

    UChar voicedKanaString1[] = { 0x3042, 0x3099 };
    UChar voicedKanaString2[] = { 0x3042, 0x309A };

    // Comparing strings with different sound marks should fail.
    EXPECT_FALSE(checkOnlyKanaLettersInStrings(
        voicedKanaString1, WTF_ARRAY_LENGTH(voicedKanaString1),
        voicedKanaString2, WTF_ARRAY_LENGTH(voicedKanaString2)));

    // Now strings will be the same.
    voicedKanaString2[1] = 0x3099;
    EXPECT_TRUE(checkOnlyKanaLettersInStrings(
        voicedKanaString1, WTF_ARRAY_LENGTH(voicedKanaString1),
        voicedKanaString2, WTF_ARRAY_LENGTH(voicedKanaString2)));

    voicedKanaString2[0] = 0x3043;
    EXPECT_FALSE(checkOnlyKanaLettersInStrings(
        voicedKanaString1, WTF_ARRAY_LENGTH(voicedKanaString1),
        voicedKanaString2, WTF_ARRAY_LENGTH(voicedKanaString2)));
}

TEST(WebCoreUnicodeUnit, StringsWithKanaLettersTest)
{
    const UChar nonKanaString1[] = { 'a', 'b', 'c' };
    const UChar nonKanaString2[] = { 'a', 'b', 'c' };

    // Check that non-Kana letters will be compared.
    EXPECT_TRUE(checkKanaStringsEqual(
        nonKanaString1, WTF_ARRAY_LENGTH(nonKanaString1),
        nonKanaString2, WTF_ARRAY_LENGTH(nonKanaString2)));

    const UChar kanaString[] = { 'a', 'b', 'c', 0x3041 };
    EXPECT_FALSE(checkKanaStringsEqual(
        kanaString, WTF_ARRAY_LENGTH(kanaString),
        nonKanaString2, WTF_ARRAY_LENGTH(nonKanaString2)));

    // Compare with self.
    EXPECT_TRUE(checkKanaStringsEqual(
        kanaString, WTF_ARRAY_LENGTH(kanaString),
        kanaString, WTF_ARRAY_LENGTH(kanaString)));

    const UChar kanaString2[] = { 'x', 'y', 'z', 0x3041 };
    // Comparing strings with different non-Kana letters should fail.
    EXPECT_FALSE(checkKanaStringsEqual(
        kanaString, WTF_ARRAY_LENGTH(kanaString),
        kanaString2, WTF_ARRAY_LENGTH(kanaString2)));

    const UChar kanaString3[] = { 'a', 'b', 'c', 0x3042, 0x3099, 'm', 'n', 'o' };
    // Check that non-Kana letters after Kana letters will be compared.
    EXPECT_TRUE(checkKanaStringsEqual(
        kanaString3, WTF_ARRAY_LENGTH(kanaString3),
        kanaString3, WTF_ARRAY_LENGTH(kanaString3)));

    const UChar kanaString4[] = { 'a', 'b', 'c', 0x3042, 0x3099, 'm', 'n', 'o', 'p' };
    // And now comparing should fail.
    EXPECT_FALSE(checkKanaStringsEqual(
        kanaString3, WTF_ARRAY_LENGTH(kanaString3),
        kanaString4, WTF_ARRAY_LENGTH(kanaString4)));

    UChar voicedKanaString1[] = { 0x3042, 0x3099 };
    UChar voicedKanaString2[] = { 0x3042, 0x309A };

    // Comparing strings with different sound marks should fail.
    EXPECT_FALSE(checkKanaStringsEqual(
        voicedKanaString1, WTF_ARRAY_LENGTH(voicedKanaString1),
        voicedKanaString2, WTF_ARRAY_LENGTH(voicedKanaString2)));

    // Now strings will be the same.
    voicedKanaString2[1] = 0x3099;
    EXPECT_TRUE(checkKanaStringsEqual(
        voicedKanaString1, WTF_ARRAY_LENGTH(voicedKanaString1),
        voicedKanaString2, WTF_ARRAY_LENGTH(voicedKanaString2)));

    voicedKanaString2[0] = 0x3043;
    EXPECT_FALSE(checkKanaStringsEqual(
        voicedKanaString1, WTF_ARRAY_LENGTH(voicedKanaString1),
        voicedKanaString2, WTF_ARRAY_LENGTH(voicedKanaString2)));
}

} // namespace
