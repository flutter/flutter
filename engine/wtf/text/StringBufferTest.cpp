/*
 * Copyright 2014 The Chromium Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file.
 */

#include "config.h"

#include "wtf/text/StringBuffer.h"

#include <gtest/gtest.h>

namespace {


TEST(StringBuffer, Initial)
{
    StringBuffer<LChar> buf1;
    EXPECT_EQ(0u, buf1.length());
    EXPECT_FALSE(buf1.characters());

    StringBuffer<LChar> buf2(0);
    EXPECT_EQ(0u, buf2.length());
    EXPECT_FALSE(buf2.characters());

    StringBuffer<LChar> buf3(1);
    EXPECT_EQ(1u, buf3.length());
    EXPECT_TRUE(buf3.characters());
}

TEST(StringBuffer, shrink)
{
    StringBuffer<LChar> buf(2);
    EXPECT_EQ(2u, buf.length());
    buf[0] = 'a';
    buf[1] = 'b';

    buf.shrink(1);
    EXPECT_EQ(1u, buf.length());
    EXPECT_EQ('a', buf[0]);

    buf.shrink(0);
    EXPECT_EQ(0u, buf.length());
}

} // namespace
