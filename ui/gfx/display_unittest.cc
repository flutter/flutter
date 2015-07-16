// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/display.h"

#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gfx/insets.h"

namespace {

TEST(DisplayTest, WorkArea) {
  gfx::Display display(0, gfx::Rect(0, 0, 100, 100));
  EXPECT_EQ("0,0 100x100", display.bounds().ToString());
  EXPECT_EQ("0,0 100x100", display.work_area().ToString());

  display.set_work_area(gfx::Rect(3, 4, 90, 80));
  EXPECT_EQ("0,0 100x100", display.bounds().ToString());
  EXPECT_EQ("3,4 90x80", display.work_area().ToString());

  display.SetScaleAndBounds(1.0f, gfx::Rect(10, 20, 50, 50));
  EXPECT_EQ("10,20 50x50", display.bounds().ToString());
  EXPECT_EQ("13,24 40x30", display.work_area().ToString());

  display.SetSize(gfx::Size(200, 200));
  EXPECT_EQ("13,24 190x180", display.work_area().ToString());

  display.UpdateWorkAreaFromInsets(gfx::Insets(3, 4, 5, 6));
  EXPECT_EQ("14,23 190x192", display.work_area().ToString());
}

TEST(DisplayTest, Scale) {
  gfx::Display display(0, gfx::Rect(0, 0, 100, 100));
  display.set_work_area(gfx::Rect(10, 10, 80, 80));
  EXPECT_EQ("0,0 100x100", display.bounds().ToString());
  EXPECT_EQ("10,10 80x80", display.work_area().ToString());

  // Scale it back to 2x
  display.SetScaleAndBounds(2.0f, gfx::Rect(0, 0, 140, 140));
  EXPECT_EQ("0,0 70x70", display.bounds().ToString());
  EXPECT_EQ("10,10 50x50", display.work_area().ToString());

  // Scale it back to 1x
  display.SetScaleAndBounds(1.0f, gfx::Rect(0, 0, 100, 100));
  EXPECT_EQ("0,0 100x100", display.bounds().ToString());
  EXPECT_EQ("10,10 80x80", display.work_area().ToString());
}

}
