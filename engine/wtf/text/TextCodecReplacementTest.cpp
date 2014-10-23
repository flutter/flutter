// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"

#include "wtf/text/TextCodecReplacement.h"

#include "wtf/OwnPtr.h"
#include "wtf/text/CString.h"
#include "wtf/text/TextCodec.h"
#include "wtf/text/TextEncoding.h"
#include "wtf/text/TextEncodingRegistry.h"
#include "wtf/text/WTFString.h"
#include <gtest/gtest.h>

namespace WTF {

namespace {

// Just one example, others are listed in the codec implementation.
const char* replacementAlias = "iso-2022-kr";

TEST(TextCodecReplacement, Aliases)
{
    // "replacement" is not a valid alias for itself
    EXPECT_FALSE(TextEncoding("replacement").isValid());
    EXPECT_FALSE(TextEncoding("rEpLaCeMeNt").isValid());

    EXPECT_TRUE(TextEncoding(replacementAlias).isValid());
    EXPECT_STREQ("replacement", TextEncoding(replacementAlias).name());
}

TEST(TextCodecReplacement, DecodesToFFFD)
{
    TextEncoding encoding(replacementAlias);
    OwnPtr<TextCodec> codec(newTextCodec(encoding));

    bool sawError = false;
    const char testCase[] = "hello world";
    size_t testCaseSize = sizeof(testCase) - 1;

    const String result = codec->decode(testCase, testCaseSize, DataEOF, false, sawError);
    EXPECT_TRUE(sawError);
    ASSERT_EQ(1u, result.length());
    EXPECT_EQ(0xFFFDU, result[0]);
}

TEST(TextCodecReplacement, EncodesToUTF8)
{
    TextEncoding encoding(replacementAlias);
    OwnPtr<TextCodec> codec(newTextCodec(encoding));

    // "Kanji" in Chinese characters.
    const UChar testCase[] = { 0x6F22, 0x5B57 };
    size_t testCaseSize = WTF_ARRAY_LENGTH(testCase);
    CString result = codec->encode(testCase, testCaseSize, QuestionMarksForUnencodables);

    EXPECT_STREQ("\xE6\xBC\xA2\xE5\xAD\x97", result.data());
}

} // namespace

} // namespace WTF
