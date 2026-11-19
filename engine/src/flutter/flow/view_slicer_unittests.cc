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

TEST(ViewSlicerTest, ExtraOverlayRectsForceContentIntoOverlay) {
  DisplayListBuilder builder(DlRect::MakeLTRB(0, 0, 100, 100));

  std::vector<int64_t> composition_order = {1};
  std::unordered_map<int64_t, std::unique_ptr<EmbedderViewSlice>> slices;
  // The slice content does not overlap the platform view at all, so without
  // an extra overlay rect no overlay would be needed.
  AddSliceOfSize(slices, 1, DlRect::MakeLTRB(60, 60, 100, 100));

  std::unordered_map<int64_t, DlRect> view_rects = {
      {1, DlRect::MakeLTRB(0, 0, 50, 50)}};

  // A backdrop filter's children must composite above the native blur, so
  // the embedder forces the filter region into the overlay.
  std::unordered_map<int64_t, DlRect> extra_overlay_rects = {
      {1, DlRect::MakeLTRB(60, 60, 80, 80)}};

  auto computed_overlays = SliceViews(&builder, composition_order, slices,
                                      view_rects, extra_overlay_rects);

  EXPECT_EQ(computed_overlays.size(), 1u);
  auto overlay = computed_overlays.find(1);
  ASSERT_NE(overlay, computed_overlays.end());
  EXPECT_EQ(overlay->second, DlRect::MakeLTRB(60, 60, 80, 80));
}

TEST(ViewSlicerTest, ExtraOverlayRectsUnionWithPlatformViewOverlap) {
  DisplayListBuilder builder(DlRect::MakeLTRB(0, 0, 100, 100));

  std::vector<int64_t> composition_order = {1};
  std::unordered_map<int64_t, std::unique_ptr<EmbedderViewSlice>> slices;
  AddSliceOfSize(slices, 1, DlRect::MakeLTRB(0, 0, 100, 100));

  std::unordered_map<int64_t, DlRect> view_rects = {
      {1, DlRect::MakeLTRB(0, 0, 50, 50)}};
  std::unordered_map<int64_t, DlRect> extra_overlay_rects = {
      {1, DlRect::MakeLTRB(40, 40, 90, 90)}};

  auto computed_overlays = SliceViews(&builder, composition_order, slices,
                                      view_rects, extra_overlay_rects);

  auto overlay = computed_overlays.find(1);
  ASSERT_NE(overlay, computed_overlays.end());
  EXPECT_EQ(overlay->second, DlRect::MakeLTRB(0, 0, 90, 90));
}

}  // namespace testing
}  // namespace flutter
