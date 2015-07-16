// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/basictypes.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gfx/geometry/rect.h"
#include "ui/gfx/skia_util.h"

namespace gfx {

TEST(RectTest, SkiaRectConversions) {
  Rect isrc(10, 20, 30, 40);
  RectF fsrc(10.5f, 20.5f, 30.5f, 40.5f);

  SkIRect skirect = RectToSkIRect(isrc);
  EXPECT_EQ(isrc.ToString(), SkIRectToRect(skirect).ToString());

  SkRect skrect = RectToSkRect(isrc);
  EXPECT_EQ(gfx::RectF(isrc).ToString(), SkRectToRectF(skrect).ToString());

  skrect = RectFToSkRect(fsrc);
  EXPECT_EQ(fsrc.ToString(), SkRectToRectF(skrect).ToString());
}

}  // namespace gfx
