// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "display_list/effects/dl_color_source.h"
#include "flutter/display_list/skia/dl_sk_paint_dispatcher.h"

#include "flutter/display_list/utils/dl_receiver_utils.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

class MockDispatchHelper final : public virtual DlOpReceiver,
                                 public DlSkPaintDispatchHelper,
                                 public IgnoreClipDispatchHelper,
                                 public IgnoreTransformDispatchHelper,
                                 public IgnoreDrawDispatchHelper {
 public:
  void save() override { DlSkPaintDispatchHelper::save_opacity(0.5f); }

  void restore() override { DlSkPaintDispatchHelper::restore_opacity(); }
};

static const DlColor kTestColors[2] = {DlColor(0xFF000000),
                                       DlColor(0xFFFFFFFF)};
static const float kTestStops[2] = {0.0f, 1.0f};
static const auto kTestLinearGradient =
    DlColorSource::MakeLinear(SkPoint::Make(0.0f, 0.0f),
                              SkPoint::Make(100.0f, 100.0f),
                              2,
                              kTestColors,
                              kTestStops,
                              DlTileMode::kClamp,
                              nullptr);

// Regression test for https://github.com/flutter/flutter/issues/100176.
TEST(DisplayListUtils, OverRestore) {
  MockDispatchHelper helper;
  helper.save();
  helper.restore();
  // There should be a protection here for over-restore to keep the program from
  // crashing.
  helper.restore();
}

// https://github.com/flutter/flutter/issues/132860.
TEST(DisplayListUtils, SetDitherIgnoredIfColorSourceNotGradient) {
  MockDispatchHelper helper;
  helper.setDither(true);
  EXPECT_FALSE(helper.paint().isDither());
}

// https://github.com/flutter/flutter/issues/132860.
TEST(DisplayListUtils, SetColorSourceClearsDitherIfNotGradient) {
  MockDispatchHelper helper;
  helper.setDither(true);
  helper.setColorSource(nullptr);
  EXPECT_FALSE(helper.paint().isDither());
}

// https://github.com/flutter/flutter/issues/132860.
TEST(DisplayListUtils, SetDitherTrueThenSetColorSourceDithersIfGradient) {
  MockDispatchHelper helper;

  // A naive implementation would ignore the dither flag here since the current
  // color source is not a gradient.
  helper.setDither(true);
  helper.setColorSource(kTestLinearGradient.get());
  EXPECT_TRUE(helper.paint().isDither());
}

// https://github.com/flutter/flutter/issues/132860.
TEST(DisplayListUtils, SetDitherTrueThenRenderNonGradientThenRenderGradient) {
  MockDispatchHelper helper;

  // "Render" a dithered non-gradient.
  helper.setDither(true);
  EXPECT_FALSE(helper.paint().isDither());

  // "Render" a gradient.
  helper.setColorSource(kTestLinearGradient.get());
  EXPECT_TRUE(helper.paint().isDither());
}

// https://github.com/flutter/flutter/issues/132860.
TEST(DisplayListUtils, SetDitherTrueThenGradientTHenNonGradientThenGradient) {
  MockDispatchHelper helper;

  // "Render" a dithered gradient.
  helper.setDither(true);
  helper.setColorSource(kTestLinearGradient.get());
  EXPECT_TRUE(helper.paint().isDither());

  // "Render" a non-gradient.
  helper.setColorSource(nullptr);
  EXPECT_FALSE(helper.paint().isDither());

  // "Render" a gradient again.
  helper.setColorSource(kTestLinearGradient.get());
  EXPECT_TRUE(helper.paint().isDither());
}

}  // namespace testing
}  // namespace flutter
