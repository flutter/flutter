// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/basictypes.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gfx/geometry/box_f.h"

namespace gfx {

TEST(BoxTest, Constructors) {
  EXPECT_EQ(BoxF(0.f, 0.f, 0.f, 0.f, 0.f, 0.f).ToString(),
            BoxF().ToString());
  EXPECT_EQ(BoxF(0.f, 0.f, 0.f, -3.f, -5.f, -7.f).ToString(),
            BoxF().ToString());

  EXPECT_EQ(BoxF(0.f, 0.f, 0.f, 3.f, 5.f, 7.f).ToString(),
            BoxF(3.f, 5.f, 7.f).ToString());
  EXPECT_EQ(BoxF(0.f, 0.f, 0.f, 0.f, 0.f, 0.f).ToString(),
            BoxF(-3.f, -5.f, -7.f).ToString());

  EXPECT_EQ(BoxF(2.f, 4.f, 6.f, 3.f, 5.f, 7.f).ToString(),
            BoxF(Point3F(2.f, 4.f, 6.f), 3.f, 5.f, 7.f).ToString());
  EXPECT_EQ(BoxF(2.f, 4.f, 6.f, 0.f, 0.f, 0.f).ToString(),
            BoxF(Point3F(2.f, 4.f, 6.f), -3.f, -5.f, -7.f).ToString());
}

TEST(BoxTest, IsEmpty) {
  EXPECT_TRUE(BoxF(0.f, 0.f, 0.f, 0.f, 0.f, 0.f).IsEmpty());
  EXPECT_TRUE(BoxF(1.f, 2.f, 3.f, 0.f, 0.f, 0.f).IsEmpty());

  EXPECT_TRUE(BoxF(0.f, 0.f, 0.f, 2.f, 0.f, 0.f).IsEmpty());
  EXPECT_TRUE(BoxF(1.f, 2.f, 3.f, 2.f, 0.f, 0.f).IsEmpty());
  EXPECT_TRUE(BoxF(0.f, 0.f, 0.f, 0.f, 2.f, 0.f).IsEmpty());
  EXPECT_TRUE(BoxF(1.f, 2.f, 3.f, 0.f, 2.f, 0.f).IsEmpty());
  EXPECT_TRUE(BoxF(0.f, 0.f, 0.f, 0.f, 0.f, 2.f).IsEmpty());
  EXPECT_TRUE(BoxF(1.f, 2.f, 3.f, 0.f, 0.f, 2.f).IsEmpty());

  EXPECT_FALSE(BoxF(0.f, 0.f, 0.f, 0.f, 2.f, 2.f).IsEmpty());
  EXPECT_FALSE(BoxF(1.f, 2.f, 3.f, 0.f, 2.f, 2.f).IsEmpty());
  EXPECT_FALSE(BoxF(0.f, 0.f, 0.f, 2.f, 0.f, 2.f).IsEmpty());
  EXPECT_FALSE(BoxF(1.f, 2.f, 3.f, 2.f, 0.f, 2.f).IsEmpty());
  EXPECT_FALSE(BoxF(0.f, 0.f, 0.f, 2.f, 2.f, 0.f).IsEmpty());
  EXPECT_FALSE(BoxF(1.f, 2.f, 3.f, 2.f, 2.f, 0.f).IsEmpty());

  EXPECT_FALSE(BoxF(0.f, 0.f, 0.f, 2.f, 2.f, 2.f).IsEmpty());
  EXPECT_FALSE(BoxF(1.f, 2.f, 3.f, 2.f, 2.f, 2.f).IsEmpty());
}

TEST(BoxTest, Union) {
  BoxF empty_box;
  BoxF box1(0.f, 0.f, 0.f, 1.f, 1.f, 1.f);
  BoxF box2(0.f, 0.f, 0.f, 4.f, 6.f, 8.f);
  BoxF box3(3.f, 4.f, 5.f, 6.f, 4.f, 0.f);

  EXPECT_EQ(empty_box.ToString(), UnionBoxes(empty_box, empty_box).ToString());
  EXPECT_EQ(box1.ToString(), UnionBoxes(empty_box, box1).ToString());
  EXPECT_EQ(box1.ToString(), UnionBoxes(box1, empty_box).ToString());
  EXPECT_EQ(box2.ToString(), UnionBoxes(empty_box, box2).ToString());
  EXPECT_EQ(box2.ToString(), UnionBoxes(box2, empty_box).ToString());
  EXPECT_EQ(box3.ToString(), UnionBoxes(empty_box, box3).ToString());
  EXPECT_EQ(box3.ToString(), UnionBoxes(box3, empty_box).ToString());

  // box_1 is contained in box_2
  EXPECT_EQ(box2.ToString(), UnionBoxes(box1, box2).ToString());
  EXPECT_EQ(box2.ToString(), UnionBoxes(box2, box1).ToString());

  // box_1 and box_3 are disjoint
  EXPECT_EQ(BoxF(0.f, 0.f, 0.f, 9.f, 8.f, 5.f).ToString(),
            UnionBoxes(box1, box3).ToString());
  EXPECT_EQ(BoxF(0.f, 0.f, 0.f, 9.f, 8.f, 5.f).ToString(),
            UnionBoxes(box3, box1).ToString());

  // box_2 and box_3 intersect, but neither contains the other
  EXPECT_EQ(BoxF(0.f, 0.f, 0.f, 9.f, 8.f, 8.f).ToString(),
            UnionBoxes(box2, box3).ToString());
  EXPECT_EQ(BoxF(0.f, 0.f, 0.f, 9.f, 8.f, 8.f).ToString(),
            UnionBoxes(box3, box2).ToString());
}

TEST(BoxTest, ExpandTo) {
  BoxF box1;
  BoxF box2(0.f, 0.f, 0.f, 1.f, 1.f, 1.f);
  BoxF box3(1.f, 1.f, 1.f, 0.f, 0.f, 0.f);

  Point3F point1(0.5f, 0.5f, 0.5f);
  Point3F point2(-0.5f, -0.5f, -0.5f);

  BoxF expected1_1(0.f, 0.f, 0.f, 0.5f, 0.5f, 0.5f);
  BoxF expected1_2(-0.5f, -0.5f, -0.5f, 1.f, 1.f, 1.f);

  BoxF expected2_1 = box2;
  BoxF expected2_2(-0.5f, -0.5f, -0.5f, 1.5f, 1.5f, 1.5f);

  BoxF expected3_1(0.5f, 0.5f, 0.5f, 0.5f, 0.5f, 0.5f);
  BoxF expected3_2(-0.5f, -0.5f, -0.5f, 1.5f, 1.5f, 1.5f);

  box1.ExpandTo(point1);
  EXPECT_EQ(expected1_1.ToString(), box1.ToString());
  box1.ExpandTo(point2);
  EXPECT_EQ(expected1_2.ToString(), box1.ToString());

  box2.ExpandTo(point1);
  EXPECT_EQ(expected2_1.ToString(), box2.ToString());
  box2.ExpandTo(point2);
  EXPECT_EQ(expected2_2.ToString(), box2.ToString());

  box3.ExpandTo(point1);
  EXPECT_EQ(expected3_1.ToString(), box3.ToString());
  box3.ExpandTo(point2);
  EXPECT_EQ(expected3_2.ToString(), box3.ToString());
}

TEST(BoxTest, Scale) {
  BoxF box1(2.f, 3.f, 4.f, 5.f, 6.f, 7.f);

  EXPECT_EQ(BoxF().ToString(), ScaleBox(box1, 0.f).ToString());
  EXPECT_EQ(box1.ToString(), ScaleBox(box1, 1.f).ToString());
  EXPECT_EQ(BoxF(4.f, 12.f, 24.f, 10.f, 24.f, 42.f).ToString(),
            ScaleBox(box1, 2.f, 4.f, 6.f).ToString());

  BoxF box2 = box1;
  box2.Scale(0.f);
  EXPECT_EQ(BoxF().ToString(), box2.ToString());

  box2 = box1;
  box2.Scale(1.f);
  EXPECT_EQ(box1.ToString(), box2.ToString());

  box2.Scale(2.f, 4.f, 6.f);
  EXPECT_EQ(BoxF(4.f, 12.f, 24.f, 10.f, 24.f, 42.f).ToString(),
            box2.ToString());
}

TEST(BoxTest, Equals) {
  EXPECT_TRUE(BoxF() == BoxF());
  EXPECT_TRUE(BoxF(2.f, 3.f, 4.f, 6.f, 8.f, 10.f) ==
              BoxF(2.f, 3.f, 4.f, 6.f, 8.f, 10.f));
  EXPECT_FALSE(BoxF() == BoxF(0.f, 0.f, 0.f, 0.f, 0.f, 1.f));
  EXPECT_FALSE(BoxF() == BoxF(0.f, 0.f, 0.f, 0.f, 1.f, 0.f));
  EXPECT_FALSE(BoxF() == BoxF(0.f, 0.f, 0.f, 1.f, 0.f, 0.f));
  EXPECT_FALSE(BoxF() == BoxF(0.f, 0.f, 1.f, 0.f, 0.f, 0.f));
  EXPECT_FALSE(BoxF() == BoxF(0.f, 1.f, 0.f, 0.f, 0.f, 0.f));
  EXPECT_FALSE(BoxF() == BoxF(1.f, 0.f, 0.f, 0.f, 0.f, 0.f));
}

TEST(BoxTest, NotEquals) {
  EXPECT_FALSE(BoxF() != BoxF());
  EXPECT_FALSE(BoxF(2.f, 3.f, 4.f, 6.f, 8.f, 10.f) !=
               BoxF(2.f, 3.f, 4.f, 6.f, 8.f, 10.f));
  EXPECT_TRUE(BoxF() != BoxF(0.f, 0.f, 0.f, 0.f, 0.f, 1.f));
  EXPECT_TRUE(BoxF() != BoxF(0.f, 0.f, 0.f, 0.f, 1.f, 0.f));
  EXPECT_TRUE(BoxF() != BoxF(0.f, 0.f, 0.f, 1.f, 0.f, 0.f));
  EXPECT_TRUE(BoxF() != BoxF(0.f, 0.f, 1.f, 0.f, 0.f, 0.f));
  EXPECT_TRUE(BoxF() != BoxF(0.f, 1.f, 0.f, 0.f, 0.f, 0.f));
  EXPECT_TRUE(BoxF() != BoxF(1.f, 0.f, 0.f, 0.f, 0.f, 0.f));
}


TEST(BoxTest, Offset) {
  BoxF box1(2.f, 3.f, 4.f, 5.f, 6.f, 7.f);

  EXPECT_EQ(box1.ToString(), (box1 + Vector3dF(0.f, 0.f, 0.f)).ToString());
  EXPECT_EQ(BoxF(3.f, 1.f, 0.f, 5.f, 6.f, 7.f).ToString(),
            (box1 + Vector3dF(1.f, -2.f, -4.f)).ToString());

  BoxF box2 = box1;
  box2 += Vector3dF(0.f, 0.f, 0.f);
  EXPECT_EQ(box1.ToString(), box2.ToString());

  box2 += Vector3dF(1.f, -2.f, -4.f);
  EXPECT_EQ(BoxF(3.f, 1.f, 0.f, 5.f, 6.f, 7.f).ToString(),
            box2.ToString());
}

}  // namespace gfx
