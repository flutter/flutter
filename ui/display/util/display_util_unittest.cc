// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/display/util/display_util.h"

#include "testing/gtest/include/gtest/gtest.h"

namespace ui {

TEST(DisplayUtilTest, TestBlackListedDisplay) {
  EXPECT_TRUE(IsDisplaySizeBlackListed(gfx::Size(10, 10)));
  EXPECT_TRUE(IsDisplaySizeBlackListed(gfx::Size(40, 30)));
  EXPECT_TRUE(IsDisplaySizeBlackListed(gfx::Size(50, 40)));
  EXPECT_TRUE(IsDisplaySizeBlackListed(gfx::Size(160, 90)));
  EXPECT_TRUE(IsDisplaySizeBlackListed(gfx::Size(160, 100)));

  EXPECT_FALSE(IsDisplaySizeBlackListed(gfx::Size(50, 60)));
  EXPECT_FALSE(IsDisplaySizeBlackListed(gfx::Size(100, 70)));
  EXPECT_FALSE(IsDisplaySizeBlackListed(gfx::Size(272, 181)));
}

TEST(DisplayUtilTest, GetScaleFactor) {
  // Normal chromebook spec. DPI ~= 130
  EXPECT_EQ(1.0f, GetScaleFactor(
      gfx::Size(256, 144), gfx::Size(1366, 768)));

  // HiDPI like Pixel. DPI ~= 240
  EXPECT_EQ(2.0f, GetScaleFactor(
      gfx::Size(272, 181), gfx::Size(2560, 1700)));

  // A large external display but normal pixel density. DPI ~= 100
  EXPECT_EQ(1.0f, GetScaleFactor(
      gfx::Size(641, 400), gfx::Size(2560, 1600)));

  // A large external display with high pixel density. DPI ~= 157
  EXPECT_EQ(2.0f, GetScaleFactor(
      gfx::Size(621, 341), gfx::Size(3840, 2160)));

  // 4K resolution but the display is physically even larger. DPI ~= 114
  EXPECT_EQ(1.0f, GetScaleFactor(
      gfx::Size(854, 481), gfx::Size(3840, 2160)));

  // 21.5 inch, 1080p. DPI ~= 102
  EXPECT_EQ(1.0f, GetScaleFactor(
      gfx::Size(476, 267), gfx::Size(1920, 1080)));

  // Corner case; slightly higher density but smaller screens. DPI ~= 165
  EXPECT_EQ(1.0f, GetScaleFactor(
      gfx::Size(293, 165), gfx::Size(1920, 1080)));
}

}  // namespace ui
