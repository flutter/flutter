// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <unordered_map>
#include "display_list/dl_builder.h"
#include "flow/embedded_views.h"
#include "flutter/flow/view_slicer.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {
void AddSliceOfSize(
    std::unordered_map<int64_t, std::unique_ptr<EmbedderViewSlice>>& slices,
    int64_t id,
    DlRect rect) {
  slices[id] = std::make_unique<DisplayListEmbedderViewSlice>(rect);
  DlPaint paint;
  paint.setColor(DlColor::kBlack());
  slices[id]->canvas()->DrawRect(rect, paint);
}
}  // namespace

TEST(ViewSlicerTest, CanSlicerNonOverlappingViews) {
  DisplayListBuilder builder(DlRect::MakeLTRB(0, 0, 100, 100));

  std::vector<int64_t> composition_order = {1};
  std::unordered_map<int64_t, std::unique_ptr<EmbedderViewSlice>> slices;
  AddSliceOfSize(slices, 1, DlRect::MakeLTRB(99, 99, 100, 100));

  std::unordered_map<int64_t, DlRect> view_rects = {
      {1, DlRect::MakeLTRB(50, 50, 60, 60)}};

  auto computed_overlays =
      SliceViews(&builder, composition_order, slices, view_rects);

  EXPECT_TRUE(computed_overlays.empty());
}

TEST(ViewSlicerTest, IgnoresFractionalOverlaps) {
  DisplayListBuilder builder(DlRect::MakeLTRB(0, 0, 100, 100));

  std::vector<int64_t> composition_order = {1};
  std::unordered_map<int64_t, std::unique_ptr<EmbedderViewSlice>> slices;
  AddSliceOfSize(slices, 1, DlRect::MakeLTRB(0, 0, 50.49, 50.49));

  std::unordered_map<int64_t, DlRect> view_rects = {
      {1, DlRect::MakeLTRB(50.5, 50.5, 100, 100)}};

  auto computed_overlays =
      SliceViews(&builder, composition_order, slices, view_rects);

  EXPECT_TRUE(computed_overlays.empty());
}

TEST(ViewSlicerTest, ComputesOverlapWith1PV) {
  DisplayListBuilder builder(DlRect::MakeLTRB(0, 0, 100, 100));

  std::vector<int64_t> composition_order = {1};
  std::unordered_map<int64_t, std::unique_ptr<EmbedderViewSlice>> slices;
  AddSliceOfSize(slices, 1, DlRect::MakeLTRB(0, 0, 50, 50));

  std::unordered_map<int64_t, DlRect> view_rects = {
      {1, DlRect::MakeLTRB(0, 0, 100, 100)}};

  auto computed_overlays =
      SliceViews(&builder, composition_order, slices, view_rects);

  EXPECT_EQ(computed_overlays.size(), 1u);
  auto overlay = computed_overlays.find(1);
  ASSERT_NE(overlay, computed_overlays.end());

  EXPECT_EQ(overlay->second, DlRect::MakeLTRB(0, 0, 50, 50));
}

TEST(ViewSlicerTest, ComputesOverlapWith2PV) {
  DisplayListBuilder builder(DlRect::MakeLTRB(0, 0, 100, 100));

  std::vector<int64_t> composition_order = {1, 2};
  std::unordered_map<int64_t, std::unique_ptr<EmbedderViewSlice>> slices;
  AddSliceOfSize(slices, 1, DlRect::MakeLTRB(0, 0, 50, 50));
  AddSliceOfSize(slices, 2, DlRect::MakeLTRB(50, 50, 100, 100));

  std::unordered_map<int64_t, DlRect> view_rects = {
      {1, DlRect::MakeLTRB(0, 0, 50, 50)},      //
      {2, DlRect::MakeLTRB(50, 50, 100, 100)},  //
  };

  auto computed_overlays =
      SliceViews(&builder, composition_order, slices, view_rects);

  EXPECT_EQ(computed_overlays.size(), 2u);

  auto overlay = computed_overlays.find(1);
  ASSERT_NE(overlay, computed_overlays.end());

  EXPECT_EQ(overlay->second, DlRect::MakeLTRB(0, 0, 50, 50));

  overlay = computed_overlays.find(2);
  ASSERT_NE(overlay, computed_overlays.end());
  EXPECT_EQ(overlay->second, DlRect::MakeLTRB(50, 50, 100, 100));
}

TEST(ViewSlicerTest, OverlappingTwoPVs) {
  DisplayListBuilder builder(DlRect::MakeLTRB(0, 0, 100, 100));

  std::vector<int64_t> composition_order = {1, 2};
  std::unordered_map<int64_t, std::unique_ptr<EmbedderViewSlice>> slices;
  // This embeded view overlaps both platform views:
  //
  //   [  A  [   ]]
  //   [_____[ C ]]
  //   [  B  [   ]]
  //   [          ]
  AddSliceOfSize(slices, 1, DlRect::MakeLTRB(0, 0, 0, 0));
  AddSliceOfSize(slices, 2, DlRect::MakeLTRB(0, 0, 100, 100));

  std::unordered_map<int64_t, DlRect> view_rects = {
      {1, DlRect::MakeLTRB(0, 0, 50, 50)},      //
      {2, DlRect::MakeLTRB(50, 50, 100, 100)},  //
  };

  auto computed_overlays =
      SliceViews(&builder, composition_order, slices, view_rects);

  EXPECT_EQ(computed_overlays.size(), 1u);

  auto overlay = computed_overlays.find(2);
  ASSERT_NE(overlay, computed_overlays.end());

  // We create a single overlay for both overlapping sections.
  EXPECT_EQ(overlay->second, DlRect::MakeLTRB(0, 0, 100, 100));
}

TEST(ViewSlicerTest, ContentUnderAnEarlierOverlayGetsAnOverlay) {
  DisplayListBuilder builder(DlRect::MakeLTRB(0, 0, 100, 100));

  std::vector<int64_t> composition_order = {1, 2, 3};
  std::unordered_map<int64_t, std::unique_ptr<EmbedderViewSlice>> slices;
  // The slice after platform view 2 covers the frame, like a modal barrier,
  // so its overlay spans from platform view 1 to platform view 2. The slice
  // after platform view 3 draws X, which doesn't intersect any platform view
  // but is inside that overlay:
  //
  //   [     1     ]
  //
  //      [  3  ]
  //
  //      [  X  ]
  //
  //   [     2     ]
  AddSliceOfSize(slices, 1, DlRect::MakeLTRB(0, 0, 0, 0));
  AddSliceOfSize(slices, 2, DlRect::MakeLTRB(0, 0, 100, 100));
  AddSliceOfSize(slices, 3, DlRect::MakeLTRB(20, 60, 80, 70));

  std::unordered_map<int64_t, DlRect> view_rects = {
      {1, DlRect::MakeLTRB(0, 0, 100, 10)},    //
      {2, DlRect::MakeLTRB(0, 90, 100, 100)},  //
      {3, DlRect::MakeLTRB(20, 40, 80, 50)},   //
  };

  auto computed_overlays =
      SliceViews(&builder, composition_order, slices, view_rects);

  EXPECT_EQ(computed_overlays.size(), 2u);

  auto overlay = computed_overlays.find(2);
  ASSERT_NE(overlay, computed_overlays.end());
  EXPECT_EQ(overlay->second, DlRect::MakeLTRB(0, 0, 100, 100));

  // X is clipped out of the background canvas, so it needs an overlay above
  // the one of platform view 2.
  overlay = computed_overlays.find(3);
  ASSERT_NE(overlay, computed_overlays.end());
  EXPECT_EQ(overlay->second, DlRect::MakeLTRB(20, 60, 80, 70));
}

TEST(ViewSlicerTest, ContentOutsideEarlierOverlaysGetsNoOverlay) {
  DisplayListBuilder builder(DlRect::MakeLTRB(0, 0, 100, 100));

  std::vector<int64_t> composition_order = {1, 2, 3};
  std::unordered_map<int64_t, std::unique_ptr<EmbedderViewSlice>> slices;
  // As above, but the slice after platform view 2 only covers platform
  // view 1, so X stays in the background canvas.
  AddSliceOfSize(slices, 1, DlRect::MakeLTRB(0, 0, 0, 0));
  AddSliceOfSize(slices, 2, DlRect::MakeLTRB(0, 0, 100, 20));
  AddSliceOfSize(slices, 3, DlRect::MakeLTRB(20, 60, 80, 70));

  std::unordered_map<int64_t, DlRect> view_rects = {
      {1, DlRect::MakeLTRB(0, 0, 100, 10)},    //
      {2, DlRect::MakeLTRB(0, 90, 100, 100)},  //
      {3, DlRect::MakeLTRB(20, 40, 80, 50)},   //
  };

  auto computed_overlays =
      SliceViews(&builder, composition_order, slices, view_rects);

  EXPECT_EQ(computed_overlays.size(), 1u);

  auto overlay = computed_overlays.find(2);
  ASSERT_NE(overlay, computed_overlays.end());
  EXPECT_EQ(overlay->second, DlRect::MakeLTRB(0, 0, 100, 10));

  EXPECT_EQ(computed_overlays.find(3), computed_overlays.end());
}

TEST(ViewSlicerTest, ContentPartlyUnderAnEarlierOverlay) {
  DisplayListBuilder builder(DlRect::MakeLTRB(0, 0, 100, 100));

  std::vector<int64_t> composition_order = {1, 2, 3};
  std::unordered_map<int64_t, std::unique_ptr<EmbedderViewSlice>> slices;
  // The overlay of platform view 2 spans from platform view 1 down to the
  // bottom of platform view 2 at y = 70, and X reaches from inside it to below
  // it. Only the part of X inside it needs an overlay; the rest stays in the
  // background canvas.
  AddSliceOfSize(slices, 1, DlRect::MakeLTRB(0, 0, 0, 0));
  AddSliceOfSize(slices, 2, DlRect::MakeLTRB(0, 0, 100, 70));
  AddSliceOfSize(slices, 3, DlRect::MakeLTRB(20, 60, 80, 80));

  std::unordered_map<int64_t, DlRect> view_rects = {
      {1, DlRect::MakeLTRB(0, 0, 100, 10)},    //
      {2, DlRect::MakeLTRB(90, 65, 100, 70)},  //
      {3, DlRect::MakeLTRB(20, 40, 80, 50)},   //
  };

  auto computed_overlays =
      SliceViews(&builder, composition_order, slices, view_rects);

  EXPECT_EQ(computed_overlays.size(), 2u);

  auto overlay = computed_overlays.find(2);
  ASSERT_NE(overlay, computed_overlays.end());
  EXPECT_EQ(overlay->second, DlRect::MakeLTRB(0, 0, 100, 70));

  overlay = computed_overlays.find(3);
  ASSERT_NE(overlay, computed_overlays.end());
  EXPECT_EQ(overlay->second, DlRect::MakeLTRB(20, 60, 80, 70));
}

}  // namespace testing
}  // namespace flutter
