/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES,:tabnew INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/geometry/FloatBox.h"

#include "platform/geometry/FloatBoxTestHelpers.h"

#include <gtest/gtest.h>

using namespace blink;

namespace {

TEST(FloatBoxTest, SimpleCreationTest)
{
    FloatBox box(1, 2, 3, 4, 5, 6);
    EXPECT_EQ(1, box.x());
    EXPECT_EQ(2, box.y());
    EXPECT_EQ(3, box.z());
    EXPECT_EQ(4, box.width());
    EXPECT_EQ(5, box.height());
    EXPECT_EQ(6, box.depth());
    EXPECT_EQ(5, box.right());
    EXPECT_EQ(7, box.bottom());
    EXPECT_EQ(9, box.front());
}

TEST(FloatBoxTest, PositionTest)
{
    FloatBox box(0, 0, 0, 4, 4, 4);
    box.move(FloatPoint3D(1, 2, 3));
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(1, 2, 3, 4, 4, 4), box);
    box.setOrigin(FloatPoint3D(-1, -2, -3));
    box.move(FloatPoint3D(-1, -2, -3));
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(-2, -4, -6, 4, 4, 4), box);
}

TEST(FloatBoxTest, CopyTest)
{
    FloatBox box(1, 2, 3, 4, 4, 4);
    FloatBox box2(box);
    EXPECT_EQ(box, box2);
    box.setSize(FloatPoint3D(3, 3, 3));
    EXPECT_NE(box, box2);
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(1, 2, 3, 3, 3, 3), box);
}

TEST(FloatBoxTest, FlattenTest)
{
    FloatBox box(1, 2, 3, 4, 4, 4);
    box.flatten();
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(1, 2, 0, 4, 4, 0), box);
}

TEST(FloatBoxTest, ExpandTests)
{
    FloatBox box;
    box.expandTo(FloatPoint3D(10, -3, 2));
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(0, -3, 0, 10, 3, 2), box);

    box.expandTo(FloatPoint3D(-15, 6, 8));
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(-15, -3, 0, 25, 9, 8), box);

    box = FloatBox();
    box.expandTo(FloatPoint3D(-3, 6, 9), FloatPoint3D(-2, 10, 11));
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(-3, 0, 0, 3, 10, 11), box);

    box = FloatBox();
    box.expandTo(FloatBox(-10, -10, -10, 3, 30, 40));
    box.expandTo(FloatBox(-11, 3, 50, 10, 15, 1));
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(-11, -10, -10, 11, 30, 61), box);
}

TEST(FloatBoxTest, UnionTest)
{
    FloatBox box;
    EXPECT_TRUE(box.isEmpty());
    FloatBox unionedBox(3, 5, 6, 5, 3, 9);
    box.unionBounds(unionedBox);
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, unionedBox, box);

    box.unionBounds(FloatBox());
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, unionedBox, box);

    box.unionBounds(FloatBox(0, 0, 0, 1, 1, 1));
    EXPECT_PRED_FORMAT2(FloatBoxTest::AssertAlmostEqual, FloatBox(0, 0, 0, 8, 8, 15), box);
}

TEST(FloatBoxTest, EmptyBoxTest)
{
    FloatBox box;
    EXPECT_TRUE(box.isEmpty());
    box.expandTo(FloatPoint3D(1, 0, 0));
    EXPECT_TRUE(box.isEmpty());
    box.expandTo(FloatPoint3D(0, 1, 0));
    EXPECT_FALSE(box.isEmpty());
}

}
