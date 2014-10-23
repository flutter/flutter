// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/rendering/style/OutlineValue.h"

#include <gtest/gtest.h>

using namespace blink;

namespace {

TEST(OutlineValueTest, VisuallyEqualStyle)
{
    OutlineValue outline1;
    OutlineValue outline2;

    // Outlines visually equal if their styles are all BNONE.
    EXPECT_TRUE(outline1.visuallyEqual(outline2));
    outline2.setOffset(10);
    EXPECT_TRUE(outline1.visuallyEqual(outline2));

    outline2.setStyle(DOTTED);
    outline1.setOffset(10);
    EXPECT_FALSE(outline1.visuallyEqual(outline2));
}

TEST(OutlineValueTest, VisuallyEqualOffset)
{
    OutlineValue outline1;
    OutlineValue outline2;

    outline1.setStyle(DOTTED);
    outline2.setStyle(DOTTED);
    EXPECT_TRUE(outline1.visuallyEqual(outline2));

    outline1.setOffset(10);
    EXPECT_FALSE(outline1.visuallyEqual(outline2));

    outline2.setOffset(10);
    EXPECT_TRUE(outline1.visuallyEqual(outline2));
}

TEST(OutlineValueTest, VisuallyEqualIsAuto)
{
    OutlineValue outline1;
    OutlineValue outline2;

    outline1.setStyle(DOTTED);
    outline2.setStyle(DOTTED);
    EXPECT_TRUE(outline1.visuallyEqual(outline2));

    outline1.setIsAuto(AUTO_ON);
    EXPECT_FALSE(outline1.visuallyEqual(outline2));

    outline2.setIsAuto(AUTO_ON);
    EXPECT_TRUE(outline1.visuallyEqual(outline2));
}

}
