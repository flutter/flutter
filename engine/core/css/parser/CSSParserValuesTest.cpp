/*
 * Copyright 2013, Google Inc. All rights reserved.
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
#include "core/css/parser/CSSParserValues.h"

#include <gtest/gtest.h>

using namespace blink;

namespace {

TEST(CSSParserValuesTest, InitWithEmpty8BitsString)
{
    String string8bit("a");

    CSSParserString cssParserString;
    cssParserString.init(string8bit, 1, 0);
    ASSERT_EQ(0u, cssParserString.length());
}

TEST(CSSParserValuesTest, InitWithEmpty16BitsString)
{
    String string16bit("a");
    string16bit.ensure16Bit();

    CSSParserString cssParserString;
    cssParserString.init(string16bit, 1, 0);
    ASSERT_EQ(0u, cssParserString.length());
}

TEST(CSSParserValuesTest, EqualIgnoringCase8BitsString)
{
    CSSParserString cssParserString;
    String string8bit("sHaDOw");
    cssParserString.init(string8bit, 0, string8bit.length());

    ASSERT_TRUE(cssParserString.equalIgnoringCase("shadow"));
    ASSERT_TRUE(cssParserString.equalIgnoringCase("ShaDow"));
    ASSERT_FALSE(cssParserString.equalIgnoringCase("shadow-all"));
    ASSERT_FALSE(cssParserString.equalIgnoringCase("sha"));
    ASSERT_FALSE(cssParserString.equalIgnoringCase("abCD"));
}

TEST(CSSParserValuesTest, EqualIgnoringCase16BitsString)
{
    String string16bit("sHaDOw");
    string16bit.ensure16Bit();

    CSSParserString cssParserString;
    cssParserString.init(string16bit, 0, string16bit.length());

    ASSERT_TRUE(cssParserString.equalIgnoringCase("shadow"));
    ASSERT_TRUE(cssParserString.equalIgnoringCase("ShaDow"));
    ASSERT_FALSE(cssParserString.equalIgnoringCase("shadow-all"));
    ASSERT_FALSE(cssParserString.equalIgnoringCase("sha"));
    ASSERT_FALSE(cssParserString.equalIgnoringCase("abCD"));
}

TEST(CSSParserValuesTest, CSSParserValuelistClear)
{
    CSSParserValueList list;
    for (int i = 0; i < 3; ++i) {
        CSSParserValue value;
        value.setFromNumber(3);
        list.addValue(value);
    }
    list.clearAndLeakValues();
    ASSERT_FALSE(list.size());
    ASSERT_FALSE(list.currentIndex());
}

} // namespace
