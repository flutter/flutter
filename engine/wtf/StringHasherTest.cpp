/*
 * Copyright (C) 2013 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"

#include "wtf/StringHasher.h"
#include <gtest/gtest.h>

namespace {

static const LChar nullLChars[2] = { 0, 0 };
static const UChar nullUChars[2] = { 0, 0 };

static const unsigned emptyStringHash = 0x4EC889EU;
static const unsigned singleNullCharacterHash = 0x3D3ABF44U;

static const LChar testALChars[6] = { 0x41, 0x95, 0xFF, 0x50, 0x01, 0 };
static const UChar testAUChars[6] = { 0x41, 0x95, 0xFF, 0x50, 0x01, 0 };
static const UChar testBUChars[6] = { 0x41, 0x95, 0xFFFF, 0x1080, 0x01, 0 };

static const unsigned testAHash1 = 0xEA32B004;
static const unsigned testAHash2 = 0x93F0F71E;
static const unsigned testAHash3 = 0xCB609EB1;
static const unsigned testAHash4 = 0x7984A706;
static const unsigned testAHash5 = 0x0427561F;

static const unsigned testBHash1 = 0xEA32B004;
static const unsigned testBHash2 = 0x93F0F71E;
static const unsigned testBHash3 = 0x59EB1B2C;
static const unsigned testBHash4 = 0xA7BCCC0A;
static const unsigned testBHash5 = 0x79201649;

TEST(StringHasherTest, StringHasher)
{
    StringHasher hasher;

    // The initial state of the hasher.
    EXPECT_EQ(emptyStringHash, hasher.hash());
    EXPECT_EQ(emptyStringHash & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
}

TEST(StringHasherTest, StringHasher_addCharacter)
{
    StringHasher hasher;

    // Hashing a single character.
    hasher = StringHasher();
    hasher.addCharacter(0);
    EXPECT_EQ(singleNullCharacterHash, hasher.hash());
    EXPECT_EQ(singleNullCharacterHash & 0xFFFFFF, hasher.hashWithTop8BitsMasked());

    // Hashing five characters, checking the intermediate state after each is added.
    hasher = StringHasher();
    hasher.addCharacter(testAUChars[0]);
    EXPECT_EQ(testAHash1, hasher.hash());
    EXPECT_EQ(testAHash1 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharacter(testAUChars[1]);
    EXPECT_EQ(testAHash2, hasher.hash());
    EXPECT_EQ(testAHash2 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharacter(testAUChars[2]);
    EXPECT_EQ(testAHash3, hasher.hash());
    EXPECT_EQ(testAHash3 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharacter(testAUChars[3]);
    EXPECT_EQ(testAHash4, hasher.hash());
    EXPECT_EQ(testAHash4 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharacter(testAUChars[4]);
    EXPECT_EQ(testAHash5, hasher.hash());
    EXPECT_EQ(testAHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());

    // Hashing a second set of five characters, including non-Latin-1 characters.
    hasher = StringHasher();
    hasher.addCharacter(testBUChars[0]);
    EXPECT_EQ(testBHash1, hasher.hash());
    EXPECT_EQ(testBHash1 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharacter(testBUChars[1]);
    EXPECT_EQ(testBHash2, hasher.hash());
    EXPECT_EQ(testBHash2 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharacter(testBUChars[2]);
    EXPECT_EQ(testBHash3, hasher.hash());
    EXPECT_EQ(testBHash3 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharacter(testBUChars[3]);
    EXPECT_EQ(testBHash4, hasher.hash());
    EXPECT_EQ(testBHash4 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharacter(testBUChars[4]);
    EXPECT_EQ(testBHash5, hasher.hash());
    EXPECT_EQ(testBHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
}

TEST(StringHasherTest, StringHasher_addCharacters)
{
    StringHasher hasher;

    // Hashing zero characters.
    hasher = StringHasher();
    hasher.addCharacters(static_cast<LChar*>(0), 0);
    EXPECT_EQ(emptyStringHash, hasher.hash());
    EXPECT_EQ(emptyStringHash & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharacters(nullLChars, 0);
    EXPECT_EQ(emptyStringHash, hasher.hash());
    EXPECT_EQ(emptyStringHash & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharacters(static_cast<UChar*>(0), 0);
    EXPECT_EQ(emptyStringHash, hasher.hash());
    EXPECT_EQ(emptyStringHash & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharacters(nullUChars, 0);
    EXPECT_EQ(emptyStringHash, hasher.hash());
    EXPECT_EQ(emptyStringHash & 0xFFFFFF, hasher.hashWithTop8BitsMasked());

    // Hashing one character.
    hasher = StringHasher();
    hasher.addCharacters(nullLChars, 1);
    EXPECT_EQ(singleNullCharacterHash, hasher.hash());
    EXPECT_EQ(singleNullCharacterHash & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharacters(nullUChars, 1);
    EXPECT_EQ(singleNullCharacterHash, hasher.hash());
    EXPECT_EQ(singleNullCharacterHash & 0xFFFFFF, hasher.hashWithTop8BitsMasked());

    // Hashing five characters, all at once.
    hasher = StringHasher();
    hasher.addCharacters(testALChars, 5);
    EXPECT_EQ(testAHash5, hasher.hash());
    EXPECT_EQ(testAHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharacters(testAUChars, 5);
    EXPECT_EQ(testAHash5, hasher.hash());
    EXPECT_EQ(testAHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharacters(testBUChars, 5);
    EXPECT_EQ(testBHash5, hasher.hash());
    EXPECT_EQ(testBHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());

    // Hashing five characters, in groups of two, then the last one.
    hasher = StringHasher();
    hasher.addCharacters(testALChars, 2);
    EXPECT_EQ(testAHash2, hasher.hash());
    EXPECT_EQ(testAHash2 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharacters(testALChars + 2, 2);
    EXPECT_EQ(testAHash4, hasher.hash());
    EXPECT_EQ(testAHash4 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharacters(testALChars + 4, 1);
    EXPECT_EQ(testAHash5, hasher.hash());
    EXPECT_EQ(testAHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharacters(testALChars, 2);
    hasher.addCharacters(testALChars + 2, 2);
    hasher.addCharacters(testALChars + 4, 1);
    EXPECT_EQ(testAHash5, hasher.hash());
    EXPECT_EQ(testAHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharacters(testAUChars, 2);
    EXPECT_EQ(testAHash2, hasher.hash());
    EXPECT_EQ(testAHash2 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharacters(testAUChars + 2, 2);
    EXPECT_EQ(testAHash4, hasher.hash());
    EXPECT_EQ(testAHash4 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharacters(testAUChars + 4, 1);
    EXPECT_EQ(testAHash5, hasher.hash());
    EXPECT_EQ(testAHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharacters(testAUChars, 2);
    hasher.addCharacters(testAUChars + 2, 2);
    hasher.addCharacters(testAUChars + 4, 1);
    EXPECT_EQ(testAHash5, hasher.hash());
    EXPECT_EQ(testAHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharacters(testBUChars, 2);
    EXPECT_EQ(testBHash2, hasher.hash());
    EXPECT_EQ(testBHash2 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharacters(testBUChars + 2, 2);
    EXPECT_EQ(testBHash4, hasher.hash());
    EXPECT_EQ(testBHash4 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharacters(testBUChars + 4, 1);
    EXPECT_EQ(testBHash5, hasher.hash());
    EXPECT_EQ(testBHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharacters(testBUChars, 2);
    hasher.addCharacters(testBUChars + 2, 2);
    hasher.addCharacters(testBUChars + 4, 1);
    EXPECT_EQ(testBHash5, hasher.hash());
    EXPECT_EQ(testBHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());

    // Hashing five characters, the first three, then the last two.
    hasher = StringHasher();
    hasher.addCharacters(testALChars, 3);
    EXPECT_EQ(testAHash3, hasher.hash());
    EXPECT_EQ(testAHash3 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharacters(testALChars + 3, 2);
    EXPECT_EQ(testAHash5, hasher.hash());
    EXPECT_EQ(testAHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharacters(testALChars, 3);
    EXPECT_EQ(testAHash3, hasher.hash());
    EXPECT_EQ(testAHash3 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharacters(testALChars + 3, 2);
    EXPECT_EQ(testAHash5, hasher.hash());
    EXPECT_EQ(testAHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharacters(testAUChars, 3);
    EXPECT_EQ(testAHash3, hasher.hash());
    EXPECT_EQ(testAHash3 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharacters(testAUChars + 3, 2);
    EXPECT_EQ(testAHash5, hasher.hash());
    EXPECT_EQ(testAHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharacters(testAUChars, 3);
    EXPECT_EQ(testAHash3, hasher.hash());
    EXPECT_EQ(testAHash3 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharacters(testAUChars + 3, 2);
    EXPECT_EQ(testAHash5, hasher.hash());
    EXPECT_EQ(testAHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharacters(testBUChars, 3);
    EXPECT_EQ(testBHash3, hasher.hash());
    EXPECT_EQ(testBHash3 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharacters(testBUChars + 3, 2);
    EXPECT_EQ(testBHash5, hasher.hash());
    EXPECT_EQ(testBHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharacters(testBUChars, 3);
    hasher.addCharacters(testBUChars + 3, 2);
    EXPECT_EQ(testBHash5, hasher.hash());
    EXPECT_EQ(testBHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
}

TEST(StringHasherTest, StringHasher_addCharactersAssumingAligned)
{
    StringHasher hasher;

    // Hashing zero characters.
    hasher = StringHasher();
    hasher.addCharactersAssumingAligned(static_cast<LChar*>(0), 0);
    EXPECT_EQ(emptyStringHash, hasher.hash());
    EXPECT_EQ(emptyStringHash & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharactersAssumingAligned(nullLChars, 0);
    EXPECT_EQ(emptyStringHash, hasher.hash());
    EXPECT_EQ(emptyStringHash & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharactersAssumingAligned(static_cast<UChar*>(0), 0);
    EXPECT_EQ(emptyStringHash, hasher.hash());
    EXPECT_EQ(emptyStringHash & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharactersAssumingAligned(nullUChars, 0);
    EXPECT_EQ(emptyStringHash, hasher.hash());
    EXPECT_EQ(emptyStringHash & 0xFFFFFF, hasher.hashWithTop8BitsMasked());

    // Hashing one character.
    hasher = StringHasher();
    hasher.addCharactersAssumingAligned(nullLChars, 1);
    EXPECT_EQ(singleNullCharacterHash, hasher.hash());
    EXPECT_EQ(singleNullCharacterHash & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharactersAssumingAligned(nullUChars, 1);
    EXPECT_EQ(singleNullCharacterHash, hasher.hash());
    EXPECT_EQ(singleNullCharacterHash & 0xFFFFFF, hasher.hashWithTop8BitsMasked());

    // Hashing five characters, all at once.
    hasher = StringHasher();
    hasher.addCharactersAssumingAligned(testALChars, 5);
    EXPECT_EQ(testAHash5, hasher.hash());
    EXPECT_EQ(testAHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharactersAssumingAligned(testAUChars, 5);
    EXPECT_EQ(testAHash5, hasher.hash());
    EXPECT_EQ(testAHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharactersAssumingAligned(testBUChars, 5);
    EXPECT_EQ(testBHash5, hasher.hash());
    EXPECT_EQ(testBHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());

    // Hashing five characters, in groups of two, then the last one.
    hasher = StringHasher();
    hasher.addCharactersAssumingAligned(testALChars, 2);
    EXPECT_EQ(testAHash2, hasher.hash());
    EXPECT_EQ(testAHash2 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharactersAssumingAligned(testALChars + 2, 2);
    EXPECT_EQ(testAHash4, hasher.hash());
    EXPECT_EQ(testAHash4 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharactersAssumingAligned(testALChars + 4, 1);
    EXPECT_EQ(testAHash5, hasher.hash());
    EXPECT_EQ(testAHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharactersAssumingAligned(testALChars, 2);
    hasher.addCharactersAssumingAligned(testALChars + 2, 2);
    hasher.addCharactersAssumingAligned(testALChars + 4, 1);
    EXPECT_EQ(testAHash5, hasher.hash());
    EXPECT_EQ(testAHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharactersAssumingAligned(testAUChars, 2);
    EXPECT_EQ(testAHash2, hasher.hash());
    EXPECT_EQ(testAHash2 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharactersAssumingAligned(testAUChars + 2, 2);
    EXPECT_EQ(testAHash4, hasher.hash());
    EXPECT_EQ(testAHash4 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharactersAssumingAligned(testAUChars + 4, 1);
    EXPECT_EQ(testAHash5, hasher.hash());
    EXPECT_EQ(testAHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharactersAssumingAligned(testAUChars, 2);
    hasher.addCharactersAssumingAligned(testAUChars + 2, 2);
    hasher.addCharactersAssumingAligned(testAUChars + 4, 1);
    EXPECT_EQ(testAHash5, hasher.hash());
    EXPECT_EQ(testAHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharactersAssumingAligned(testBUChars, 2);
    EXPECT_EQ(testBHash2, hasher.hash());
    EXPECT_EQ(testBHash2 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharactersAssumingAligned(testBUChars + 2, 2);
    EXPECT_EQ(testBHash4, hasher.hash());
    EXPECT_EQ(testBHash4 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharactersAssumingAligned(testBUChars + 4, 1);
    EXPECT_EQ(testBHash5, hasher.hash());
    EXPECT_EQ(testBHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher = StringHasher();
    hasher.addCharactersAssumingAligned(testBUChars, 2);
    hasher.addCharactersAssumingAligned(testBUChars + 2, 2);
    hasher.addCharactersAssumingAligned(testBUChars + 4, 1);
    EXPECT_EQ(testBHash5, hasher.hash());
    EXPECT_EQ(testBHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());

    // Hashing five characters, first two characters one at a time,
    // then two more, then the last one.
    hasher = StringHasher();
    hasher.addCharacter(testBUChars[0]);
    EXPECT_EQ(testBHash1, hasher.hash());
    EXPECT_EQ(testBHash1 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharacter(testBUChars[1]);
    EXPECT_EQ(testBHash2, hasher.hash());
    EXPECT_EQ(testBHash2 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharactersAssumingAligned(testBUChars[2], testBUChars[3]);
    EXPECT_EQ(testBHash4, hasher.hash());
    EXPECT_EQ(testBHash4 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
    hasher.addCharactersAssumingAligned(testBUChars + 4, 1);
    EXPECT_EQ(testBHash5, hasher.hash());
    EXPECT_EQ(testBHash5 & 0xFFFFFF, hasher.hashWithTop8BitsMasked());
}

TEST(StringHasherTest, StringHasher_computeHash)
{
    EXPECT_EQ(emptyStringHash, StringHasher::computeHash(static_cast<LChar*>(0), 0));
    EXPECT_EQ(emptyStringHash, StringHasher::computeHash(nullLChars, 0));
    EXPECT_EQ(emptyStringHash, StringHasher::computeHash(static_cast<UChar*>(0), 0));
    EXPECT_EQ(emptyStringHash, StringHasher::computeHash(nullUChars, 0));

    EXPECT_EQ(singleNullCharacterHash, StringHasher::computeHash(nullLChars, 1));
    EXPECT_EQ(singleNullCharacterHash, StringHasher::computeHash(nullUChars, 1));

    EXPECT_EQ(testAHash5, StringHasher::computeHash(testALChars, 5));
    EXPECT_EQ(testAHash5, StringHasher::computeHash(testAUChars, 5));
    EXPECT_EQ(testBHash5, StringHasher::computeHash(testBUChars, 5));
}

TEST(StringHasherTest, StringHasher_computeHashAndMaskTop8Bits)
{
    EXPECT_EQ(emptyStringHash & 0xFFFFFF, StringHasher::computeHashAndMaskTop8Bits(static_cast<LChar*>(0), 0));
    EXPECT_EQ(emptyStringHash & 0xFFFFFF, StringHasher::computeHashAndMaskTop8Bits(nullLChars, 0));
    EXPECT_EQ(emptyStringHash & 0xFFFFFF, StringHasher::computeHashAndMaskTop8Bits(static_cast<UChar*>(0), 0));
    EXPECT_EQ(emptyStringHash & 0xFFFFFF, StringHasher::computeHashAndMaskTop8Bits(nullUChars, 0));

    EXPECT_EQ(singleNullCharacterHash & 0xFFFFFF, StringHasher::computeHashAndMaskTop8Bits(nullLChars, 1));
    EXPECT_EQ(singleNullCharacterHash & 0xFFFFFF, StringHasher::computeHashAndMaskTop8Bits(nullUChars, 1));

    EXPECT_EQ(testAHash5 & 0xFFFFFF, StringHasher::computeHashAndMaskTop8Bits(testALChars, 5));
    EXPECT_EQ(testAHash5 & 0xFFFFFF, StringHasher::computeHashAndMaskTop8Bits(testAUChars, 5));
    EXPECT_EQ(testBHash5 & 0xFFFFFF, StringHasher::computeHashAndMaskTop8Bits(testBUChars, 5));
}

TEST(StringHasherTest, StringHasher_hashMemory)
{
    EXPECT_EQ(emptyStringHash & 0xFFFFFF, StringHasher::hashMemory(0, 0));
    EXPECT_EQ(emptyStringHash & 0xFFFFFF, StringHasher::hashMemory(nullUChars, 0));
    EXPECT_EQ(emptyStringHash & 0xFFFFFF, StringHasher::hashMemory<0>(0));
    EXPECT_EQ(emptyStringHash & 0xFFFFFF, StringHasher::hashMemory<0>(nullUChars));

    EXPECT_EQ(singleNullCharacterHash & 0xFFFFFF, StringHasher::hashMemory(nullUChars, 2));
    EXPECT_EQ(singleNullCharacterHash & 0xFFFFFF, StringHasher::hashMemory<2>(nullUChars));

    EXPECT_EQ(testAHash5 & 0xFFFFFF, StringHasher::hashMemory(testAUChars, 10));
    EXPECT_EQ(testAHash5 & 0xFFFFFF, StringHasher::hashMemory<10>(testAUChars));
    EXPECT_EQ(testBHash5 & 0xFFFFFF, StringHasher::hashMemory(testBUChars, 10));
    EXPECT_EQ(testBHash5 & 0xFFFFFF, StringHasher::hashMemory<10>(testBUChars));
}

} // namespace
