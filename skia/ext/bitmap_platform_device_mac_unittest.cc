// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "skia/ext/bitmap_platform_device_mac.h"

#include "base/memory/scoped_ptr.h"
#include "skia/ext/skia_utils_mac.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkRegion.h"
#include "third_party/skia/include/core/SkClipStack.h"

namespace skia {

const int kWidth = 400;
const int kHeight = 300;

class BitmapPlatformDeviceMacTest : public testing::Test {
 public:
  BitmapPlatformDeviceMacTest() {
    bitmap_.reset(BitmapPlatformDevice::Create(
        NULL, kWidth, kHeight, /*is_opaque=*/true));
  }

  scoped_ptr<BitmapPlatformDevice> bitmap_;
};

TEST_F(BitmapPlatformDeviceMacTest, ClipRectTransformWithTranslate) {
  SkMatrix transform;
  transform.setTranslate(50, 140);

  SkClipStack ignore;
  SkRegion clip_region;
  SkIRect rect;
  rect.set(0, 0, kWidth, kHeight);
  clip_region.setRect(rect);
  bitmap_->setMatrixClip(transform, clip_region, ignore);

  CGContextRef context = bitmap_->GetBitmapContext();
  SkRect clip_rect = gfx::CGRectToSkRect(CGContextGetClipBoundingBox(context));
  transform.mapRect(&clip_rect);
  EXPECT_EQ(0, clip_rect.fLeft);
  EXPECT_EQ(0, clip_rect.fTop);
  EXPECT_EQ(kWidth, clip_rect.width());
  EXPECT_EQ(kHeight, clip_rect.height());
}

TEST_F(BitmapPlatformDeviceMacTest, ClipRectTransformWithScale) {
  SkMatrix transform;
  transform.setScale(0.5, 0.5);

  SkClipStack unused;
  SkRegion clip_region;
  SkIRect rect;
  rect.set(0, 0, kWidth, kHeight);
  clip_region.setRect(rect);
  bitmap_->setMatrixClip(transform, clip_region, unused);

  CGContextRef context = bitmap_->GetBitmapContext();
  SkRect clip_rect = gfx::CGRectToSkRect(CGContextGetClipBoundingBox(context));
  transform.mapRect(&clip_rect);
  EXPECT_EQ(0, clip_rect.fLeft);
  EXPECT_EQ(0, clip_rect.fTop);
  EXPECT_EQ(kWidth, clip_rect.width());
  EXPECT_EQ(kHeight, clip_rect.height());
}

}  // namespace skia
