/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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
 *     * Neither the name of Google Inc. nor the names of its
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

#include "wtf/text/TextCodecUTF8.h"

#include "wtf/OwnPtr.h"
#include "wtf/text/TextCodec.h"
#include "wtf/text/TextEncoding.h"
#include "wtf/text/TextEncodingRegistry.h"
#include "wtf/text/WTFString.h"
#include <gtest/gtest.h>

namespace WTF {

namespace {

TEST(TextCodecUTF8, DecodeAscii)
{
    TextEncoding encoding("UTF-8");
    OwnPtr<TextCodec> codec(newTextCodec(encoding));

    const char testCase[] = "HelloWorld";
    size_t testCaseSize = sizeof(testCase) - 1;

    bool sawError = false;
    const String& result = codec->decode(testCase, testCaseSize, DataEOF, false, sawError);
    EXPECT_FALSE(sawError);
    ASSERT_EQ(testCaseSize, result.length());
    for (size_t i = 0; i < testCaseSize; ++i) {
        EXPECT_EQ(testCase[i], result[i]);
    }
}

TEST(TextCodecUTF8, DecodeChineseCharacters)
{
    TextEncoding encoding("UTF-8");
    OwnPtr<TextCodec> codec(newTextCodec(encoding));

    // "Kanji" in Chinese characters.
    const char testCase[] = "\xe6\xbc\xa2\xe5\xad\x97";
    size_t testCaseSize = sizeof(testCase) - 1;

    bool sawError = false;
    const String& result = codec->decode(testCase, testCaseSize, DataEOF, false, sawError);
    EXPECT_FALSE(sawError);
    ASSERT_EQ(2u, result.length());
    EXPECT_EQ(0x6f22U, result[0]);
    EXPECT_EQ(0x5b57U, result[1]);
}

TEST(TextCodecUTF8, Decode0xFF)
{
    TextEncoding encoding("UTF-8");
    OwnPtr<TextCodec> codec(newTextCodec(encoding));

    bool sawError = false;
    const String& result = codec->decode("\xff", 1, DataEOF, false, sawError);
    EXPECT_TRUE(sawError);
    ASSERT_EQ(1u, result.length());
    EXPECT_EQ(0xFFFDU, result[0]);
}

} // namespace

} // namespace WTF
