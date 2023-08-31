// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <string>
#include <unordered_set>
#include <utility>
#include <vector>

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/display_list_builder.h"
#include "flutter/display_list/dl_blend_mode.h"
#include "flutter/display_list/dl_paint.h"
#include "flutter/display_list/geometry/dl_rtree.h"
#include "flutter/display_list/skia/dl_sk_dispatcher.h"
#include "flutter/display_list/testing/dl_test_snippets.h"
#include "flutter/display_list/utils/dl_receiver_utils.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/math.h"
#include "flutter/testing/display_list_testing.h"
#include "flutter/testing/testing.h"

#include "third_party/skia/include/core/SkBBHFactory.h"
#include "third_party/skia/include/core/SkColorFilter.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"
#include "third_party/skia/include/core/SkRSXform.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {

DlOpReceiver& DisplayListBuilderTestingAccessor(DisplayListBuilder& builder) {
  return builder.asReceiver();
}

DlPaint DisplayListBuilderTestingAttributes(DisplayListBuilder& builder) {
  return builder.CurrentAttributes();
}

namespace testing {

static std::vector<testing::DisplayListInvocationGroup> allGroups =
    CreateAllGroups();

using ClipOp = DlCanvas::ClipOp;
using PointMode = DlCanvas::PointMode;

template <typename BaseT>
class DisplayListTestBase : public BaseT {
 public:
  DisplayListTestBase() = default;

  static DlOpReceiver& ToReceiver(DisplayListBuilder& builder) {
    return DisplayListBuilderTestingAccessor(builder);
  }

  static sk_sp<DisplayList> Build(DisplayListInvocation& invocation) {
    DisplayListBuilder builder;
    invocation.Invoke(ToReceiver(builder));
    return builder.Build();
  }

  static sk_sp<DisplayList> Build(size_t g_index, size_t v_index) {
    DisplayListBuilder builder;
    DlOpReceiver& receiver =
        DisplayListTestBase<::testing::Test>::ToReceiver(builder);
    unsigned int op_count = 0;
    size_t byte_count = 0;
    for (size_t i = 0; i < allGroups.size(); i++) {
      DisplayListInvocationGroup& group = allGroups[i];
      size_t j = (i == g_index ? v_index : 0);
      if (j >= group.variants.size()) {
        continue;
      }
      DisplayListInvocation& invocation = group.variants[j];
      op_count += invocation.op_count();
      byte_count += invocation.raw_byte_count();
      invocation.invoker(receiver);
    }
    sk_sp<DisplayList> dl = builder.Build();
    std::string name;
    if (g_index >= allGroups.size()) {
      name = "Default";
    } else {
      name = allGroups[g_index].op_name;
      if (v_index >= allGroups[g_index].variants.size()) {
        name += " skipped";
      } else {
        name += " variant " + std::to_string(v_index + 1);
      }
    }
    EXPECT_EQ(dl->op_count(false), op_count) << name;
    EXPECT_EQ(dl->bytes(false), byte_count + sizeof(DisplayList)) << name;
    return dl;
  }

  static void check_defaults(
      DisplayListBuilder& builder,
      const SkRect& cull_rect = DisplayListBuilder::kMaxCullRect) {
    DlPaint builder_paint = DisplayListBuilderTestingAttributes(builder);
    DlPaint defaults;

    EXPECT_EQ(builder_paint.isAntiAlias(), defaults.isAntiAlias());
    EXPECT_EQ(builder_paint.isDither(), defaults.isDither());
    EXPECT_EQ(builder_paint.isInvertColors(), defaults.isInvertColors());
    EXPECT_EQ(builder_paint.getColor(), defaults.getColor());
    EXPECT_EQ(builder_paint.getBlendMode(), defaults.getBlendMode());
    EXPECT_EQ(builder_paint.getDrawStyle(), defaults.getDrawStyle());
    EXPECT_EQ(builder_paint.getStrokeWidth(), defaults.getStrokeWidth());
    EXPECT_EQ(builder_paint.getStrokeMiter(), defaults.getStrokeMiter());
    EXPECT_EQ(builder_paint.getStrokeCap(), defaults.getStrokeCap());
    EXPECT_EQ(builder_paint.getStrokeJoin(), defaults.getStrokeJoin());
    EXPECT_EQ(builder_paint.getColorSource(), defaults.getColorSource());
    EXPECT_EQ(builder_paint.getColorFilter(), defaults.getColorFilter());
    EXPECT_EQ(builder_paint.getImageFilter(), defaults.getImageFilter());
    EXPECT_EQ(builder_paint.getMaskFilter(), defaults.getMaskFilter());
    EXPECT_EQ(builder_paint.getPathEffect(), defaults.getPathEffect());
    EXPECT_EQ(builder_paint, defaults);
    EXPECT_TRUE(builder_paint.isDefault());

    EXPECT_EQ(builder.GetTransform(), SkMatrix());
    EXPECT_EQ(builder.GetTransformFullPerspective(), SkM44());

    EXPECT_EQ(builder.GetLocalClipBounds(), cull_rect);
    EXPECT_EQ(builder.GetDestinationClipBounds(), cull_rect);

    EXPECT_EQ(builder.GetSaveCount(), 1);
  }

  typedef const std::function<void(DlCanvas&)> DlSetup;
  typedef const std::function<void(DlCanvas&, DlPaint&, SkRect& rect)>
      DlRenderer;

  static void verify_inverted_bounds(DlSetup& setup,
                                     DlRenderer& renderer,
                                     DlPaint paint,
                                     SkRect render_rect,
                                     SkRect expected_bounds,
                                     const std::string& desc) {
    DisplayListBuilder builder;
    setup(builder);
    renderer(builder, paint, render_rect);
    auto dl = builder.Build();
    FML_LOG(ERROR) << "dl: " << *dl;
    FML_LOG(ERROR) << "ops: " << dl->op_count();
    FML_LOG(ERROR) << "bytes: " << dl->bytes();
    EXPECT_EQ(dl->op_count(), 1u) << desc;
    EXPECT_EQ(dl->bounds(), expected_bounds) << desc;
  }

  static void check_inverted_bounds(DlRenderer& renderer,
                                    const std::string& desc) {
    SkRect rect = SkRect::MakeLTRB(0.0f, 0.0f, 10.0f, 10.0f);
    SkRect invertedLR = SkRect::MakeLTRB(rect.fRight, rect.fTop,  //
                                         rect.fLeft, rect.fBottom);
    SkRect invertedTB = SkRect::MakeLTRB(rect.fLeft, rect.fBottom,  //
                                         rect.fRight, rect.fTop);
    SkRect invertedLTRB = SkRect::MakeLTRB(rect.fRight, rect.fBottom,  //
                                           rect.fLeft, rect.fTop);
    auto empty_setup = [](DlCanvas&) {};

    ASSERT_TRUE(rect.fLeft < rect.fRight);
    ASSERT_TRUE(rect.fTop < rect.fBottom);
    ASSERT_FALSE(rect.isEmpty());
    ASSERT_TRUE(invertedLR.fLeft > invertedLR.fRight);
    ASSERT_TRUE(invertedLR.isEmpty());
    ASSERT_TRUE(invertedTB.fTop > invertedTB.fBottom);
    ASSERT_TRUE(invertedTB.isEmpty());
    ASSERT_TRUE(invertedLTRB.fLeft > invertedLTRB.fRight);
    ASSERT_TRUE(invertedLTRB.fTop > invertedLTRB.fBottom);
    ASSERT_TRUE(invertedLTRB.isEmpty());

    DlPaint ref_paint = DlPaint();
    SkRect ref_bounds = rect;
    verify_inverted_bounds(empty_setup, renderer, ref_paint, invertedLR,
                           ref_bounds, desc + " LR swapped");
    verify_inverted_bounds(empty_setup, renderer, ref_paint, invertedTB,
                           ref_bounds, desc + " TB swapped");
    verify_inverted_bounds(empty_setup, renderer, ref_paint, invertedLTRB,
                           ref_bounds, desc + " LR&TB swapped");

    // Round joins are used because miter joins greatly pad the bounds,
    // but only on paths. So we use round joins for consistency there.
    // We aren't fully testing all stroke-related bounds computations here,
    // those are more fully tested in the render tests. We are simply
    // checking that they are applied to the ordered bounds.
    DlPaint stroke_paint = DlPaint()                                 //
                               .setDrawStyle(DlDrawStyle::kStroke)   //
                               .setStrokeJoin(DlStrokeJoin::kRound)  //
                               .setStrokeWidth(2.0f);
    SkRect stroke_bounds = rect.makeOutset(1.0f, 1.0f);
    verify_inverted_bounds(empty_setup, renderer, stroke_paint, invertedLR,
                           stroke_bounds, desc + " LR swapped, sw 2");
    verify_inverted_bounds(empty_setup, renderer, stroke_paint, invertedTB,
                           stroke_bounds, desc + " TB swapped, sw 2");
    verify_inverted_bounds(empty_setup, renderer, stroke_paint, invertedLTRB,
                           stroke_bounds, desc + " LR&TB swapped, sw 2");

    DlBlurMaskFilter mask_filter(DlBlurStyle::kNormal, 2.0f);
    DlPaint maskblur_paint = DlPaint()  //
                                 .setMaskFilter(&mask_filter);
    SkRect maskblur_bounds = rect.makeOutset(6.0f, 6.0f);
    verify_inverted_bounds(empty_setup, renderer, maskblur_paint, invertedLR,
                           maskblur_bounds, desc + " LR swapped, mask 2");
    verify_inverted_bounds(empty_setup, renderer, maskblur_paint, invertedTB,
                           maskblur_bounds, desc + " TB swapped, mask 2");
    verify_inverted_bounds(empty_setup, renderer, maskblur_paint, invertedLTRB,
                           maskblur_bounds, desc + " LR&TB swapped, mask 2");

    DlErodeImageFilter erode_filter(2.0f, 2.0f);
    DlPaint erode_paint = DlPaint()  //
                              .setImageFilter(&erode_filter);
    SkRect erode_bounds = rect.makeInset(2.0f, 2.0f);
    verify_inverted_bounds(empty_setup, renderer, erode_paint, invertedLR,
                           erode_bounds, desc + " LR swapped, erode 2");
    verify_inverted_bounds(empty_setup, renderer, erode_paint, invertedTB,
                           erode_bounds, desc + " TB swapped, erode 2");
    verify_inverted_bounds(empty_setup, renderer, erode_paint, invertedLTRB,
                           erode_bounds, desc + " LR&TB swapped, erode 2");
  }

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(DisplayListTestBase);
};
using DisplayListTest = DisplayListTestBase<::testing::Test>;

TEST_F(DisplayListTest, Defaults) {
  DisplayListBuilder builder;
  check_defaults(builder);
}

TEST_F(DisplayListTest, EmptyBuild) {
  DisplayListBuilder builder;
  auto dl = builder.Build();
  EXPECT_EQ(dl->op_count(), 0u);
  EXPECT_EQ(dl->bytes(), sizeof(DisplayList));
}

#ifndef NDEBUG
TEST_F(DisplayListTest, SecondBuildDies) {
  DisplayListBuilder builder;
  auto dl1 = builder.Build();
  EXPECT_DEATH_IF_SUPPORTED(builder.Build(), "recorder_ != nullptr");
}

TEST_F(DisplayListTest, BuilderCannotBeReused) {
  DisplayListBuilder builder(kTestBounds);
  builder.DrawRect(kTestBounds, DlPaint());
  auto dl = builder.Build();
  EXPECT_DEATH_IF_SUPPORTED(builder.DrawRect(kTestBounds, DlPaint()),
                            "receiver_ != nullptr");
}
#endif

TEST_F(DisplayListTest, SaveRestoreRestoresTransform) {
  SkRect cull_rect = SkRect::MakeLTRB(-10.0f, -10.0f, 500.0f, 500.0f);
  DisplayListBuilder builder(cull_rect);

  builder.Save();
  builder.Translate(10.0f, 10.0f);
  builder.Restore();
  check_defaults(builder, cull_rect);

  builder.Save();
  builder.Scale(10.0f, 10.0f);
  builder.Restore();
  check_defaults(builder, cull_rect);

  builder.Save();
  builder.Skew(0.1f, 0.1f);
  builder.Restore();
  check_defaults(builder, cull_rect);

  builder.Save();
  builder.Rotate(45.0f);
  builder.Restore();
  check_defaults(builder, cull_rect);

  builder.Save();
  builder.Transform(SkMatrix::Scale(10.0f, 10.0f));
  builder.Restore();
  check_defaults(builder, cull_rect);

  builder.Save();
  builder.Transform2DAffine(1.0f, 0.0f, 12.0f,  //
                            0.0f, 1.0f, 35.0f);
  builder.Restore();
  check_defaults(builder, cull_rect);

  builder.Save();
  builder.Transform(SkM44(SkMatrix::Scale(10.0f, 10.0f)));
  builder.Restore();
  check_defaults(builder, cull_rect);

  builder.Save();
  builder.TransformFullPerspective(1.0f, 0.0f, 0.0f, 12.0f,  //
                                   0.0f, 1.0f, 0.0f, 35.0f,  //
                                   0.0f, 0.0f, 1.0f, 5.0f,   //
                                   0.0f, 0.0f, 0.0f, 1.0f);
  builder.Restore();
  check_defaults(builder, cull_rect);
}

TEST_F(DisplayListTest, SaveRestoreRestoresClip) {
  SkRect cull_rect = SkRect::MakeLTRB(-10.0f, -10.0f, 500.0f, 500.0f);
  DisplayListBuilder builder(cull_rect);

  builder.Save();
  builder.ClipRect({0.0f, 0.0f, 10.0f, 10.0f});
  builder.Restore();
  check_defaults(builder, cull_rect);

  builder.Save();
  builder.ClipRRect(SkRRect::MakeRectXY({0.0f, 0.0f, 5.0f, 5.0f}, 2.0f, 2.0f));
  builder.Restore();
  check_defaults(builder, cull_rect);

  builder.Save();
  builder.ClipPath(SkPath().addOval({0.0f, 0.0f, 10.0f, 10.0f}));
  builder.Restore();
  check_defaults(builder, cull_rect);
}

TEST_F(DisplayListTest, BuilderBoundsTransformComparedToSkia) {
  const SkRect frame_rect = SkRect::MakeLTRB(10, 10, 100, 100);
  DisplayListBuilder builder(frame_rect);
  SkPictureRecorder recorder;
  SkCanvas* canvas = recorder.beginRecording(frame_rect);
  ASSERT_EQ(builder.GetDestinationClipBounds(),
            SkRect::Make(canvas->getDeviceClipBounds()));
  ASSERT_EQ(builder.GetLocalClipBounds().makeOutset(1, 1),
            canvas->getLocalClipBounds());
  ASSERT_EQ(builder.GetTransform(), canvas->getTotalMatrix());
}

TEST_F(DisplayListTest, BuilderInitialClipBounds) {
  SkRect cull_rect = SkRect::MakeWH(100, 100);
  SkRect clip_bounds = SkRect::MakeWH(100, 100);
  DisplayListBuilder builder(cull_rect);
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds);
}

TEST_F(DisplayListTest, BuilderInitialClipBoundsNaN) {
  SkRect cull_rect = SkRect::MakeWH(SK_ScalarNaN, SK_ScalarNaN);
  SkRect clip_bounds = SkRect::MakeEmpty();
  DisplayListBuilder builder(cull_rect);
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds);
}

TEST_F(DisplayListTest, BuilderClipBoundsAfterClipRect) {
  SkRect cull_rect = SkRect::MakeWH(100, 100);
  SkRect clip_rect = SkRect::MakeLTRB(10, 10, 20, 20);
  SkRect clip_bounds = SkRect::MakeLTRB(10, 10, 20, 20);
  DisplayListBuilder builder(cull_rect);
  builder.ClipRect(clip_rect, ClipOp::kIntersect, false);
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds);
}

TEST_F(DisplayListTest, BuilderClipBoundsAfterClipRRect) {
  SkRect cull_rect = SkRect::MakeWH(100, 100);
  SkRect clip_rect = SkRect::MakeLTRB(10, 10, 20, 20);
  SkRRect clip_rrect = SkRRect::MakeRectXY(clip_rect, 2, 2);
  SkRect clip_bounds = SkRect::MakeLTRB(10, 10, 20, 20);
  DisplayListBuilder builder(cull_rect);
  builder.ClipRRect(clip_rrect, ClipOp::kIntersect, false);
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds);
}

TEST_F(DisplayListTest, BuilderClipBoundsAfterClipPath) {
  SkRect cull_rect = SkRect::MakeWH(100, 100);
  SkPath clip_path = SkPath().addRect(10, 10, 15, 15).addRect(15, 15, 20, 20);
  SkRect clip_bounds = SkRect::MakeLTRB(10, 10, 20, 20);
  DisplayListBuilder builder(cull_rect);
  builder.ClipPath(clip_path, ClipOp::kIntersect, false);
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds);
}

TEST_F(DisplayListTest, BuilderInitialClipBoundsNonZero) {
  SkRect cull_rect = SkRect::MakeLTRB(10, 10, 100, 100);
  SkRect clip_bounds = SkRect::MakeLTRB(10, 10, 100, 100);
  DisplayListBuilder builder(cull_rect);
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds);
}

TEST_F(DisplayListTest, UnclippedSaveLayerContentAccountsForFilter) {
  SkRect cull_rect = SkRect::MakeLTRB(0.0f, 0.0f, 300.0f, 300.0f);
  SkRect clip_rect = SkRect::MakeLTRB(100.0f, 100.0f, 200.0f, 200.0f);
  SkRect draw_rect = SkRect::MakeLTRB(50.0f, 140.0f, 101.0f, 160.0f);
  auto filter = DlBlurImageFilter::Make(10.0f, 10.0f, DlTileMode::kDecal);
  DlPaint layer_paint = DlPaint().setImageFilter(filter);

  ASSERT_TRUE(clip_rect.intersects(draw_rect));
  ASSERT_TRUE(cull_rect.contains(clip_rect));
  ASSERT_TRUE(cull_rect.contains(draw_rect));

  DisplayListBuilder builder;
  builder.Save();
  {
    builder.ClipRect(clip_rect, ClipOp::kIntersect, false);
    builder.SaveLayer(&cull_rect, &layer_paint);
    {  //
      builder.DrawRect(draw_rect, DlPaint());
    }
    builder.Restore();
  }
  builder.Restore();
  auto display_list = builder.Build();

  ASSERT_EQ(display_list->op_count(), 6u);

  SkRect result_rect = draw_rect.makeOutset(30.0f, 30.0f);
  ASSERT_TRUE(result_rect.intersect(clip_rect));
  ASSERT_EQ(result_rect, SkRect::MakeLTRB(100.0f, 110.0f, 131.0f, 190.0f));
  ASSERT_EQ(display_list->bounds(), result_rect);
}

TEST_F(DisplayListTest, ClippedSaveLayerContentAccountsForFilter) {
  SkRect cull_rect = SkRect::MakeLTRB(0.0f, 0.0f, 300.0f, 300.0f);
  SkRect clip_rect = SkRect::MakeLTRB(100.0f, 100.0f, 200.0f, 200.0f);
  SkRect draw_rect = SkRect::MakeLTRB(50.0f, 140.0f, 99.0f, 160.0f);
  auto filter = DlBlurImageFilter::Make(10.0f, 10.0f, DlTileMode::kDecal);
  DlPaint layer_paint = DlPaint().setImageFilter(filter);

  ASSERT_FALSE(clip_rect.intersects(draw_rect));
  ASSERT_TRUE(cull_rect.contains(clip_rect));
  ASSERT_TRUE(cull_rect.contains(draw_rect));

  DisplayListBuilder builder;
  builder.Save();
  {
    builder.ClipRect(clip_rect, ClipOp::kIntersect, false);
    builder.SaveLayer(&cull_rect, &layer_paint);
    {  //
      builder.DrawRect(draw_rect, DlPaint());
    }
    builder.Restore();
  }
  builder.Restore();
  auto display_list = builder.Build();

  ASSERT_EQ(display_list->op_count(), 6u);

  SkRect result_rect = draw_rect.makeOutset(30.0f, 30.0f);
  ASSERT_TRUE(result_rect.intersect(clip_rect));
  ASSERT_EQ(result_rect, SkRect::MakeLTRB(100.0f, 110.0f, 129.0f, 190.0f));
  ASSERT_EQ(display_list->bounds(), result_rect);
}

TEST_F(DisplayListTest, SingleOpSizes) {
  for (auto& group : allGroups) {
    for (size_t i = 0; i < group.variants.size(); i++) {
      auto& invocation = group.variants[i];
      sk_sp<DisplayList> dl = Build(invocation);
      auto desc = group.op_name + "(variant " + std::to_string(i + 1) + ")";
      EXPECT_EQ(dl->op_count(false), invocation.op_count()) << desc;
      EXPECT_EQ(dl->bytes(false), invocation.byte_count()) << desc;
    }
  }
}

TEST_F(DisplayListTest, SingleOpDisplayListsNotEqualEmpty) {
  sk_sp<DisplayList> empty = DisplayListBuilder().Build();
  for (auto& group : allGroups) {
    for (size_t i = 0; i < group.variants.size(); i++) {
      sk_sp<DisplayList> dl = Build(group.variants[i]);
      auto desc =
          group.op_name + "(variant " + std::to_string(i + 1) + " != empty)";
      if (group.variants[i].is_empty()) {
        ASSERT_TRUE(DisplayListsEQ_Verbose(dl, empty));
        ASSERT_TRUE(empty->Equals(*dl)) << desc;
      } else {
        ASSERT_TRUE(DisplayListsNE_Verbose(dl, empty));
        ASSERT_FALSE(empty->Equals(*dl)) << desc;
      }
    }
  }
}

TEST_F(DisplayListTest, SingleOpDisplayListsRecapturedAreEqual) {
  for (auto& group : allGroups) {
    for (size_t i = 0; i < group.variants.size(); i++) {
      sk_sp<DisplayList> dl = Build(group.variants[i]);
      // Verify recapturing the replay of the display list is Equals()
      // when dispatching directly from the DL to another builder
      DisplayListBuilder copy_builder;
      DlOpReceiver& r = ToReceiver(copy_builder);
      dl->Dispatch(r);
      sk_sp<DisplayList> copy = copy_builder.Build();
      auto desc =
          group.op_name + "(variant " + std::to_string(i + 1) + " == copy)";
      ASSERT_EQ(copy->op_count(false), dl->op_count(false)) << desc;
      ASSERT_EQ(copy->bytes(false), dl->bytes(false)) << desc;
      ASSERT_EQ(copy->op_count(true), dl->op_count(true)) << desc;
      ASSERT_EQ(copy->bytes(true), dl->bytes(true)) << desc;
      ASSERT_EQ(copy->bounds(), dl->bounds()) << desc;
      ASSERT_TRUE(copy->Equals(*dl)) << desc;
      ASSERT_TRUE(dl->Equals(*copy)) << desc;
    }
  }
}

TEST_F(DisplayListTest, SingleOpDisplayListsCompareToEachOther) {
  for (auto& group : allGroups) {
    std::vector<sk_sp<DisplayList>> lists_a;
    std::vector<sk_sp<DisplayList>> lists_b;
    for (size_t i = 0; i < group.variants.size(); i++) {
      lists_a.push_back(Build(group.variants[i]));
      lists_b.push_back(Build(group.variants[i]));
    }

    for (size_t i = 0; i < lists_a.size(); i++) {
      sk_sp<DisplayList> listA = lists_a[i];
      for (size_t j = 0; j < lists_b.size(); j++) {
        sk_sp<DisplayList> listB = lists_b[j];
        auto desc = group.op_name + "(variant " + std::to_string(i + 1) +
                    " ==? variant " + std::to_string(j + 1) + ")";
        if (i == j ||
            (group.variants[i].is_empty() && group.variants[j].is_empty())) {
          // They are the same variant, or both variants are NOPs
          ASSERT_EQ(listA->op_count(false), listB->op_count(false)) << desc;
          ASSERT_EQ(listA->bytes(false), listB->bytes(false)) << desc;
          ASSERT_EQ(listA->op_count(true), listB->op_count(true)) << desc;
          ASSERT_EQ(listA->bytes(true), listB->bytes(true)) << desc;
          ASSERT_EQ(listA->bounds(), listB->bounds()) << desc;
          ASSERT_TRUE(listA->Equals(*listB)) << desc;
          ASSERT_TRUE(listB->Equals(*listA)) << desc;
        } else {
          // No assertion on op/byte counts or bounds
          // they may or may not be equal between variants
          ASSERT_FALSE(listA->Equals(*listB)) << desc;
          ASSERT_FALSE(listB->Equals(*listA)) << desc;
        }
      }
    }
  }
}

TEST_F(DisplayListTest, SingleOpDisplayListsAreEqualWithOrWithoutRtree) {
  for (auto& group : allGroups) {
    for (size_t i = 0; i < group.variants.size(); i++) {
      DisplayListBuilder builder1(/*prepare_rtree=*/false);
      DisplayListBuilder builder2(/*prepare_rtree=*/true);
      group.variants[i].invoker(ToReceiver(builder1));
      group.variants[i].invoker(ToReceiver(builder2));
      sk_sp<DisplayList> dl1 = builder1.Build();
      sk_sp<DisplayList> dl2 = builder2.Build();

      auto desc = group.op_name + "(variant " + std::to_string(i + 1) + " )";
      ASSERT_EQ(dl1->op_count(false), dl2->op_count(false)) << desc;
      ASSERT_EQ(dl1->bytes(false), dl2->bytes(false)) << desc;
      ASSERT_EQ(dl1->op_count(true), dl2->op_count(true)) << desc;
      ASSERT_EQ(dl1->bytes(true), dl2->bytes(true)) << desc;
      ASSERT_EQ(dl1->bounds(), dl2->bounds()) << desc;
      ASSERT_TRUE(DisplayListsEQ_Verbose(dl1, dl2)) << desc;
      ASSERT_TRUE(DisplayListsEQ_Verbose(dl2, dl2)) << desc;
      ASSERT_EQ(dl1->rtree().get(), nullptr) << desc;
      ASSERT_NE(dl2->rtree().get(), nullptr) << desc;
    }
  }
}

TEST_F(DisplayListTest, FullRotationsAreNop) {
  DisplayListBuilder builder;
  builder.Rotate(0);
  builder.Rotate(360);
  builder.Rotate(720);
  builder.Rotate(1080);
  builder.Rotate(1440);
  sk_sp<DisplayList> dl = builder.Build();
  ASSERT_EQ(dl->bytes(false), sizeof(DisplayList));
  ASSERT_EQ(dl->bytes(true), sizeof(DisplayList));
  ASSERT_EQ(dl->op_count(false), 0u);
  ASSERT_EQ(dl->op_count(true), 0u);
}

TEST_F(DisplayListTest, DisplayListsWithVaryingOpComparisons) {
  sk_sp<DisplayList> default_dl = Build(allGroups.size(), 0);
  ASSERT_TRUE(default_dl->Equals(*default_dl)) << "Default == itself";
  for (size_t gi = 0; gi < allGroups.size(); gi++) {
    DisplayListInvocationGroup& group = allGroups[gi];
    sk_sp<DisplayList> missing_dl = Build(gi, group.variants.size());
    auto desc = "[Group " + group.op_name + " omitted]";
    ASSERT_TRUE(missing_dl->Equals(*missing_dl)) << desc << " == itself";
    ASSERT_FALSE(missing_dl->Equals(*default_dl)) << desc << " != Default";
    ASSERT_FALSE(default_dl->Equals(*missing_dl)) << "Default != " << desc;
    for (size_t vi = 0; vi < group.variants.size(); vi++) {
      auto desc = "[Group " + group.op_name + " variant " +
                  std::to_string(vi + 1) + "]";
      sk_sp<DisplayList> variant_dl = Build(gi, vi);
      ASSERT_TRUE(variant_dl->Equals(*variant_dl)) << desc << " == itself";
      if (vi == 0) {
        ASSERT_TRUE(variant_dl->Equals(*default_dl)) << desc << " == Default";
        ASSERT_TRUE(default_dl->Equals(*variant_dl)) << "Default == " << desc;
      } else {
        ASSERT_FALSE(variant_dl->Equals(*default_dl)) << desc << " != Default";
        ASSERT_FALSE(default_dl->Equals(*variant_dl)) << "Default != " << desc;
      }
      if (group.variants[vi].is_empty()) {
        ASSERT_TRUE(variant_dl->Equals(*missing_dl)) << desc << " != omitted";
        ASSERT_TRUE(missing_dl->Equals(*variant_dl)) << "omitted != " << desc;
      } else {
        ASSERT_FALSE(variant_dl->Equals(*missing_dl)) << desc << " != omitted";
        ASSERT_FALSE(missing_dl->Equals(*variant_dl)) << "omitted != " << desc;
      }
    }
  }
}

TEST_F(DisplayListTest, DisplayListSaveLayerBoundsWithAlphaFilter) {
  SkRect build_bounds = SkRect::MakeLTRB(-100, -100, 200, 200);
  SkRect save_bounds = SkRect::MakeWH(100, 100);
  SkRect rect = SkRect::MakeLTRB(30, 30, 70, 70);
  // clang-format off
  const float color_matrix[] = {
    0, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  };
  // clang-format on
  DlMatrixColorFilter base_color_filter(color_matrix);
  // clang-format off
  const float alpha_matrix[] = {
    0, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 0, 1,
  };
  // clang-format on
  DlMatrixColorFilter alpha_color_filter(alpha_matrix);
  sk_sp<SkColorFilter> sk_alpha_color_filter =
      SkColorFilters::Matrix(alpha_matrix);

  {
    // No tricky stuff, just verifying drawing a rect produces rect bounds
    DisplayListBuilder builder(build_bounds);
    DlPaint save_paint;
    builder.SaveLayer(&save_bounds, &save_paint);
    builder.DrawRect(rect, DlPaint());
    builder.Restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), rect);
  }

  {
    // Now checking that a normal color filter still produces rect bounds
    DisplayListBuilder builder(build_bounds);
    DlPaint save_paint;
    save_paint.setColorFilter(&base_color_filter);
    builder.SaveLayer(&save_bounds, &save_paint);
    builder.DrawRect(rect, DlPaint());
    builder.Restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), rect);
  }

  {
    // Now checking how SkPictureRecorder deals with a color filter
    // that modifies alpha channels (save layer bounds are meaningless
    // under those circumstances)
    SkPictureRecorder recorder;
    SkRTreeFactory rtree_factory;
    SkCanvas* canvas = recorder.beginRecording(build_bounds, &rtree_factory);
    SkPaint p1;
    p1.setColorFilter(sk_alpha_color_filter);
    canvas->saveLayer(save_bounds, &p1);
    SkPaint p2;
    canvas->drawRect(rect, p2);
    canvas->restore();
    sk_sp<SkPicture> picture = recorder.finishRecordingAsPicture();
    ASSERT_EQ(picture->cullRect(), build_bounds);
  }

  {
    // Now checking that DisplayList has the same behavior that we
    // saw in the SkPictureRecorder example above - returning the
    // cull rect of the DisplayListBuilder when it encounters a
    // save layer that modifies an unbounded region
    DisplayListBuilder builder(build_bounds);
    DlPaint save_paint;
    save_paint.setColorFilter(&alpha_color_filter);
    builder.SaveLayer(&save_bounds, &save_paint);
    builder.DrawRect(rect, DlPaint());
    builder.Restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), build_bounds);
  }

  {
    // Verifying that the save layer bounds are not relevant
    // to the behavior in the previous example
    DisplayListBuilder builder(build_bounds);
    DlPaint save_paint;
    save_paint.setColorFilter(&alpha_color_filter);
    builder.SaveLayer(nullptr, &save_paint);
    builder.DrawRect(rect, DlPaint());
    builder.Restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), build_bounds);
  }

  {
    // Making sure hiding a ColorFilter as an ImageFilter will
    // generate the same behavior as setting it as a ColorFilter
    DisplayListBuilder builder(build_bounds);
    DlPaint save_paint;
    DlColorFilterImageFilter color_filter_image_filter(base_color_filter);
    save_paint.setImageFilter(&color_filter_image_filter);
    builder.SaveLayer(&save_bounds, &save_paint);
    builder.DrawRect(rect, DlPaint());
    builder.Restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), rect);
  }

  {
    // Making sure hiding a problematic ColorFilter as an ImageFilter
    // will generate the same behavior as setting it as a ColorFilter
    DisplayListBuilder builder(build_bounds);
    DlPaint save_paint;
    DlColorFilterImageFilter color_filter_image_filter(alpha_color_filter);
    save_paint.setImageFilter(&color_filter_image_filter);
    builder.SaveLayer(&save_bounds, &save_paint);
    builder.DrawRect(rect, DlPaint());
    builder.Restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), build_bounds);
  }

  {
    // Same as above (ImageFilter hiding ColorFilter) with no save bounds
    DisplayListBuilder builder(build_bounds);
    DlPaint save_paint;
    DlColorFilterImageFilter color_filter_image_filter(alpha_color_filter);
    save_paint.setImageFilter(&color_filter_image_filter);
    builder.SaveLayer(nullptr, &save_paint);
    builder.DrawRect(rect, DlPaint());
    builder.Restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), build_bounds);
  }

  {
    // Testing behavior with an unboundable blend mode
    DisplayListBuilder builder(build_bounds);
    DlPaint save_paint;
    save_paint.setBlendMode(DlBlendMode::kClear);
    builder.SaveLayer(&save_bounds, &save_paint);
    builder.DrawRect(rect, DlPaint());
    builder.Restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), build_bounds);
  }

  {
    // Same as previous with no save bounds
    DisplayListBuilder builder(build_bounds);
    DlPaint save_paint;
    save_paint.setBlendMode(DlBlendMode::kClear);
    builder.SaveLayer(nullptr, &save_paint);
    builder.DrawRect(rect, DlPaint());
    builder.Restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), build_bounds);
  }
}

TEST_F(DisplayListTest, NestedOpCountMetricsSameAsSkPicture) {
  SkPictureRecorder recorder;
  recorder.beginRecording(SkRect::MakeWH(150, 100));
  SkCanvas* canvas = recorder.getRecordingCanvas();
  SkPaint paint;
  for (int y = 10; y <= 60; y += 10) {
    for (int x = 10; x <= 60; x += 10) {
      paint.setColor(((x + y) % 20) == 10 ? SK_ColorRED : SK_ColorBLUE);
      canvas->drawRect(SkRect::MakeXYWH(x, y, 80, 80), paint);
    }
  }
  SkPictureRecorder outer_recorder;
  outer_recorder.beginRecording(SkRect::MakeWH(150, 100));
  canvas = outer_recorder.getRecordingCanvas();
  canvas->drawPicture(recorder.finishRecordingAsPicture());

  auto picture = outer_recorder.finishRecordingAsPicture();
  ASSERT_EQ(picture->approximateOpCount(), 1);
  ASSERT_EQ(picture->approximateOpCount(true), 36);

  DisplayListBuilder builder(SkRect::MakeWH(150, 100));
  for (int y = 10; y <= 60; y += 10) {
    for (int x = 10; x <= 60; x += 10) {
      DlColor color = ((x + y) % 20) == 10 ? DlColor::kRed() : DlColor::kBlue();
      builder.DrawRect(SkRect::MakeXYWH(x, y, 80, 80), DlPaint(color));
    }
  }
  DisplayListBuilder outer_builder(SkRect::MakeWH(150, 100));
  outer_builder.DrawDisplayList(builder.Build());

  auto display_list = outer_builder.Build();
  ASSERT_EQ(display_list->op_count(), 1u);
  ASSERT_EQ(display_list->op_count(true), 36u);

  ASSERT_EQ(picture->approximateOpCount(),
            static_cast<int>(display_list->op_count()));
  ASSERT_EQ(picture->approximateOpCount(true),
            static_cast<int>(display_list->op_count(true)));
}

TEST_F(DisplayListTest, DisplayListFullPerspectiveTransformHandling) {
  // SkM44 constructor takes row-major order
  SkM44 sk_matrix = SkM44(
      // clang-format off
       1,  2,  3,  4,
       5,  6,  7,  8,
       9, 10, 11, 12,
      13, 14, 15, 16
      // clang-format on
  );

  {  // First test ==
    DisplayListBuilder builder;
    // builder.transformFullPerspective takes row-major order
    builder.TransformFullPerspective(
        // clang-format off
         1,  2,  3,  4,
         5,  6,  7,  8,
         9, 10, 11, 12,
        13, 14, 15, 16
        // clang-format on
    );
    sk_sp<DisplayList> display_list = builder.Build();
    sk_sp<SkSurface> surface =
        SkSurfaces::Raster(SkImageInfo::MakeN32Premul(10, 10));
    SkCanvas* canvas = surface->getCanvas();
    // We can't use DlSkCanvas.DrawDisplayList as that method protects
    // the canvas against mutations from the display list being drawn.
    auto dispatcher = DlSkCanvasDispatcher(surface->getCanvas());
    display_list->Dispatch(dispatcher);
    SkM44 dl_matrix = canvas->getLocalToDevice();
    ASSERT_EQ(sk_matrix, dl_matrix);
  }
  {  // Next test !=
    DisplayListBuilder builder;
    // builder.transformFullPerspective takes row-major order
    builder.TransformFullPerspective(
        // clang-format off
         1,  5,  9, 13,
         2,  6,  7, 11,
         3,  7, 11, 15,
         4,  8, 12, 16
        // clang-format on
    );
    sk_sp<DisplayList> display_list = builder.Build();
    sk_sp<SkSurface> surface =
        SkSurfaces::Raster(SkImageInfo::MakeN32Premul(10, 10));
    SkCanvas* canvas = surface->getCanvas();
    // We can't use DlSkCanvas.DrawDisplayList as that method protects
    // the canvas against mutations from the display list being drawn.
    auto dispatcher = DlSkCanvasDispatcher(surface->getCanvas());
    display_list->Dispatch(dispatcher);
    SkM44 dl_matrix = canvas->getLocalToDevice();
    ASSERT_NE(sk_matrix, dl_matrix);
  }
}

TEST_F(DisplayListTest, DisplayListTransformResetHandling) {
  DisplayListBuilder builder;
  builder.Scale(20.0, 20.0);
  builder.TransformReset();
  auto display_list = builder.Build();
  ASSERT_NE(display_list, nullptr);
  sk_sp<SkSurface> surface =
      SkSurfaces::Raster(SkImageInfo::MakeN32Premul(10, 10));
  SkCanvas* canvas = surface->getCanvas();
  // We can't use DlSkCanvas.DrawDisplayList as that method protects
  // the canvas against mutations from the display list being drawn.
  auto dispatcher = DlSkCanvasDispatcher(surface->getCanvas());
  display_list->Dispatch(dispatcher);
  ASSERT_TRUE(canvas->getTotalMatrix().isIdentity());
}

TEST_F(DisplayListTest, SingleOpsMightSupportGroupOpacityBlendMode) {
  auto run_tests = [](const std::string& name,
                      void build(DlCanvas & cv, const DlPaint& paint),
                      bool expect_for_op, bool expect_with_kSrc) {
    {
      // First test is the draw op, by itself
      // (usually supports group opacity)
      DisplayListBuilder builder;
      DlPaint paint;
      build(builder, paint);
      auto display_list = builder.Build();
      EXPECT_EQ(display_list->can_apply_group_opacity(), expect_for_op)
          << "{" << std::endl
          << "  " << name << std::endl
          << "}";
    }
    {
      // Second test is the draw op with kSrc,
      // (usually fails group opacity)
      DisplayListBuilder builder;
      DlPaint paint;
      paint.setBlendMode(DlBlendMode::kSrc);
      build(builder, paint);
      auto display_list = builder.Build();
      EXPECT_EQ(display_list->can_apply_group_opacity(), expect_with_kSrc)
          << "{" << std::endl
          << "  receiver.setBlendMode(kSrc);" << std::endl
          << "  " << name << std::endl
          << "}";
    }
  };

#define RUN_TESTS(body) \
  run_tests(            \
      #body, [](DlCanvas& cv, const DlPaint& paint) { body }, true, false)
#define RUN_TESTS2(body, expect) \
  run_tests(                     \
      #body, [](DlCanvas& cv, const DlPaint& paint) { body }, expect, expect)

  RUN_TESTS(cv.DrawPaint(paint););
  RUN_TESTS(cv.DrawColor(SK_ColorRED, paint.getBlendMode()););
  RUN_TESTS2(cv.DrawColor(SK_ColorRED, DlBlendMode::kSrcOver);, true);
  RUN_TESTS2(cv.DrawColor(SK_ColorRED, DlBlendMode::kSrc);, false);
  RUN_TESTS(cv.DrawLine({0, 0}, {10, 10}, paint););
  RUN_TESTS(cv.DrawRect({0, 0, 10, 10}, paint););
  RUN_TESTS(cv.DrawOval({0, 0, 10, 10}, paint););
  RUN_TESTS(cv.DrawCircle({10, 10}, 5, paint););
  RUN_TESTS(cv.DrawRRect(SkRRect::MakeRectXY({0, 0, 10, 10}, 2, 2), paint););
  RUN_TESTS(cv.DrawDRRect(SkRRect::MakeRectXY({0, 0, 10, 10}, 2, 2),
                          SkRRect::MakeRectXY({2, 2, 8, 8}, 2, 2), paint););
  RUN_TESTS(cv.DrawPath(
      SkPath().addOval({0, 0, 10, 10}).addOval({5, 5, 15, 15}), paint););
  RUN_TESTS(cv.DrawArc({0, 0, 10, 10}, 0, math::kPi, true, paint););
  RUN_TESTS2(
      cv.DrawPoints(PointMode::kPoints, TestPointCount, TestPoints, paint);
      , false);
  RUN_TESTS2(cv.DrawVertices(TestVertices1.get(), DlBlendMode::kSrc, paint);
             , false);
  RUN_TESTS(cv.DrawImage(TestImage1, {0, 0}, kLinearSampling, &paint););
  RUN_TESTS(cv.DrawImageRect(TestImage1, SkRect{10.0f, 10.0f, 20.0f, 20.0f},
                             {0, 0, 10, 10}, kNearestSampling, &paint,
                             DlCanvas::SrcRectConstraint::kFast););
  RUN_TESTS2(cv.DrawImageRect(TestImage1, SkRect{10, 10, 20, 20},
                              {0, 0, 10, 10}, kNearestSampling, nullptr,
                              DlCanvas::SrcRectConstraint::kFast);
             , true);
  RUN_TESTS(cv.DrawImageNine(TestImage2, {20, 20, 30, 30}, {0, 0, 20, 20},
                             DlFilterMode::kLinear, &paint););
  RUN_TESTS2(cv.DrawImageNine(TestImage2, {20, 20, 30, 30}, {0, 0, 20, 20},
                              DlFilterMode::kLinear, nullptr);
             , true);
  static SkRSXform xforms[] = {{1, 0, 0, 0}, {0, 1, 0, 0}};
  static SkRect texs[] = {{10, 10, 20, 20}, {20, 20, 30, 30}};
  RUN_TESTS2(
      cv.DrawAtlas(TestImage1, xforms, texs, nullptr, 2, DlBlendMode::kSrcIn,
                   kNearestSampling, nullptr, &paint);
      , false);
  RUN_TESTS2(
      cv.DrawAtlas(TestImage1, xforms, texs, nullptr, 2, DlBlendMode::kSrcIn,
                   kNearestSampling, nullptr, nullptr);
      , false);
  EXPECT_TRUE(TestDisplayList1->can_apply_group_opacity());
  RUN_TESTS2(cv.DrawDisplayList(TestDisplayList1);, true);
  {
    static DisplayListBuilder builder;
    builder.DrawRect({0, 0, 10, 10}, DlPaint());
    builder.DrawRect({5, 5, 15, 15}, DlPaint());
    static auto display_list = builder.Build();
    RUN_TESTS2(cv.DrawDisplayList(display_list);, false);
  }
  RUN_TESTS2(cv.DrawTextBlob(TestBlob1, 0, 0, paint);, false);
  RUN_TESTS2(cv.DrawShadow(kTestPath1, SK_ColorBLACK, 1.0, false, 1.0);, false);

#undef RUN_TESTS2
#undef RUN_TESTS
}

TEST_F(DisplayListTest, OverlappingOpsDoNotSupportGroupOpacity) {
  DisplayListBuilder builder;
  for (int i = 0; i < 10; i++) {
    builder.DrawRect(SkRect::MakeXYWH(i * 10, 0, 30, 30), DlPaint());
  }
  auto display_list = builder.Build();
  EXPECT_FALSE(display_list->can_apply_group_opacity());
}

TEST_F(DisplayListTest, SaveLayerFalseSupportsGroupOpacityOverlappingChidren) {
  DisplayListBuilder builder;
  builder.SaveLayer(nullptr, nullptr);
  for (int i = 0; i < 10; i++) {
    builder.DrawRect(SkRect::MakeXYWH(i * 10, 0, 30, 30), DlPaint());
  }
  builder.Restore();
  auto display_list = builder.Build();
  EXPECT_TRUE(display_list->can_apply_group_opacity());
}

TEST_F(DisplayListTest, SaveLayerTrueSupportsGroupOpacityOverlappingChidren) {
  DisplayListBuilder builder;
  DlPaint save_paint;
  builder.SaveLayer(nullptr, &save_paint);
  for (int i = 0; i < 10; i++) {
    builder.DrawRect(SkRect::MakeXYWH(i * 10, 0, 30, 30), DlPaint());
  }
  builder.Restore();
  auto display_list = builder.Build();
  EXPECT_TRUE(display_list->can_apply_group_opacity());
}

TEST_F(DisplayListTest, SaveLayerPaintWithSrcBlendDoesNotSupportGroupOpacity) {
  DisplayListBuilder builder;
  DlPaint save_paint;
  save_paint.setBlendMode(DlBlendMode::kSrc);
  builder.SaveLayer(nullptr, &save_paint);
  builder.DrawRect({0, 0, 10, 10}, DlPaint());
  builder.Restore();
  auto display_list = builder.Build();
  EXPECT_FALSE(display_list->can_apply_group_opacity());
}

TEST_F(DisplayListTest, SaveLayerFalseSupportsGroupOpacityWithChildSrcBlend) {
  DisplayListBuilder builder;
  builder.SaveLayer(nullptr, nullptr);
  builder.DrawRect({0, 0, 10, 10}, DlPaint().setBlendMode(DlBlendMode::kSrc));
  builder.Restore();
  auto display_list = builder.Build();
  EXPECT_TRUE(display_list->can_apply_group_opacity());
}

TEST_F(DisplayListTest, SaveLayerPaintSupportsGroupOpacityWithChildSrcBlend) {
  DisplayListBuilder builder;
  DlPaint save_paint;
  builder.SaveLayer(nullptr, &save_paint);
  builder.DrawRect({0, 0, 10, 10}, DlPaint().setBlendMode(DlBlendMode::kSrc));
  builder.Restore();
  auto display_list = builder.Build();
  EXPECT_TRUE(display_list->can_apply_group_opacity());
}

TEST_F(DisplayListTest, SaveLayerBoundsSnapshotsImageFilter) {
  DisplayListBuilder builder;
  DlPaint save_paint;
  builder.SaveLayer(nullptr, &save_paint);
  builder.DrawRect({50, 50, 100, 100}, DlPaint());
  // This image filter should be ignored since it was not set before saveLayer
  ToReceiver(builder).setImageFilter(&kTestBlurImageFilter1);
  builder.Restore();
  SkRect bounds = builder.Build()->bounds();
  EXPECT_EQ(bounds, SkRect::MakeLTRB(50, 50, 100, 100));
}

class SaveLayerOptionsExpector : public virtual DlOpReceiver,
                                 public IgnoreAttributeDispatchHelper,
                                 public IgnoreClipDispatchHelper,
                                 public IgnoreTransformDispatchHelper,
                                 public IgnoreDrawDispatchHelper {
 public:
  explicit SaveLayerOptionsExpector(const SaveLayerOptions& expected) {
    expected_.push_back(expected);
  }

  explicit SaveLayerOptionsExpector(std::vector<SaveLayerOptions> expected)
      : expected_(std::move(expected)) {}

  void saveLayer(const SkRect* bounds,
                 const SaveLayerOptions options,
                 const DlImageFilter* backdrop) override {
    EXPECT_EQ(options, expected_[save_layer_count_]);
    save_layer_count_++;
  }

  int save_layer_count() { return save_layer_count_; }

 private:
  std::vector<SaveLayerOptions> expected_;
  int save_layer_count_ = 0;
};

TEST_F(DisplayListTest, SaveLayerOneSimpleOpInheritsOpacity) {
  SaveLayerOptions expected =
      SaveLayerOptions::kWithAttributes.with_can_distribute_opacity();
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  DlPaint save_paint;
  save_paint.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.SaveLayer(nullptr, &save_paint);
  builder.DrawRect({10, 10, 20, 20}, DlPaint());
  builder.Restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST_F(DisplayListTest, SaveLayerNoAttributesInheritsOpacity) {
  SaveLayerOptions expected =
      SaveLayerOptions::kNoAttributes.with_can_distribute_opacity();
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  builder.SaveLayer(nullptr, nullptr);
  builder.DrawRect({10, 10, 20, 20}, DlPaint());
  builder.Restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST_F(DisplayListTest, SaveLayerTwoOverlappingOpsDoesNotInheritOpacity) {
  SaveLayerOptions expected = SaveLayerOptions::kWithAttributes;
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  DlPaint save_paint;
  save_paint.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.SaveLayer(nullptr, &save_paint);
  builder.DrawRect({10, 10, 20, 20}, DlPaint());
  builder.DrawRect({15, 15, 25, 25}, DlPaint());
  builder.Restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST_F(DisplayListTest, NestedSaveLayersMightInheritOpacity) {
  SaveLayerOptions expected1 =
      SaveLayerOptions::kWithAttributes.with_can_distribute_opacity();
  SaveLayerOptions expected2 = SaveLayerOptions::kWithAttributes;
  SaveLayerOptions expected3 =
      SaveLayerOptions::kWithAttributes.with_can_distribute_opacity();
  SaveLayerOptionsExpector expector({expected1, expected2, expected3});

  DisplayListBuilder builder;
  DlPaint save_paint;
  save_paint.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.SaveLayer(nullptr, &save_paint);
  builder.SaveLayer(nullptr, &save_paint);
  builder.DrawRect({10, 10, 20, 20}, DlPaint());
  builder.SaveLayer(nullptr, &save_paint);
  builder.DrawRect({15, 15, 25, 25}, DlPaint());
  builder.Restore();
  builder.Restore();
  builder.Restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 3);
}

TEST_F(DisplayListTest, NestedSaveLayersCanBothSupportOpacityOptimization) {
  SaveLayerOptions expected1 =
      SaveLayerOptions::kWithAttributes.with_can_distribute_opacity();
  SaveLayerOptions expected2 =
      SaveLayerOptions::kNoAttributes.with_can_distribute_opacity();
  SaveLayerOptionsExpector expector({expected1, expected2});

  DisplayListBuilder builder;
  DlPaint save_paint;
  save_paint.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.SaveLayer(nullptr, &save_paint);
  builder.SaveLayer(nullptr, nullptr);
  builder.DrawRect({10, 10, 20, 20}, DlPaint());
  builder.Restore();
  builder.Restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 2);
}

TEST_F(DisplayListTest, SaveLayerImageFilterDoesNotInheritOpacity) {
  SaveLayerOptions expected = SaveLayerOptions::kWithAttributes;
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  DlPaint save_paint;
  save_paint.setColor(SkColorSetARGB(127, 255, 255, 255));
  save_paint.setImageFilter(&kTestBlurImageFilter1);
  builder.SaveLayer(nullptr, &save_paint);
  builder.DrawRect({10, 10, 20, 20}, DlPaint());
  builder.Restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST_F(DisplayListTest, SaveLayerColorFilterDoesNotInheritOpacity) {
  SaveLayerOptions expected = SaveLayerOptions::kWithAttributes;
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  DlPaint save_paint;
  save_paint.setColor(SkColorSetARGB(127, 255, 255, 255));
  save_paint.setColorFilter(&kTestMatrixColorFilter1);
  builder.SaveLayer(nullptr, &save_paint);
  builder.DrawRect({10, 10, 20, 20}, DlPaint());
  builder.Restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST_F(DisplayListTest, SaveLayerSrcBlendDoesNotInheritOpacity) {
  SaveLayerOptions expected = SaveLayerOptions::kWithAttributes;
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  DlPaint save_paint;
  save_paint.setColor(SkColorSetARGB(127, 255, 255, 255));
  save_paint.setBlendMode(DlBlendMode::kSrc);
  builder.SaveLayer(nullptr, &save_paint);
  builder.DrawRect({10, 10, 20, 20}, DlPaint());
  builder.Restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST_F(DisplayListTest, SaveLayerImageFilterOnChildInheritsOpacity) {
  SaveLayerOptions expected =
      SaveLayerOptions::kWithAttributes.with_can_distribute_opacity();
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  DlPaint save_paint;
  save_paint.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.SaveLayer(nullptr, &save_paint);
  builder.DrawRect({10, 10, 20, 20},
                   DlPaint().setImageFilter(&kTestBlurImageFilter1));
  builder.Restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST_F(DisplayListTest, SaveLayerColorFilterOnChildDoesNotInheritOpacity) {
  SaveLayerOptions expected = SaveLayerOptions::kWithAttributes;
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  DlPaint save_paint;
  save_paint.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.SaveLayer(nullptr, &save_paint);
  builder.DrawRect({10, 10, 20, 20},
                   DlPaint().setColorFilter(&kTestMatrixColorFilter1));
  builder.Restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST_F(DisplayListTest, SaveLayerSrcBlendOnChildDoesNotInheritOpacity) {
  SaveLayerOptions expected = SaveLayerOptions::kWithAttributes;
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  DlPaint save_paint;
  save_paint.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.SaveLayer(nullptr, &save_paint);
  builder.DrawRect({10, 10, 20, 20}, DlPaint().setBlendMode(DlBlendMode::kSrc));
  builder.Restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST_F(DisplayListTest, FlutterSvgIssue661BoundsWereEmpty) {
  // See https://github.com/dnfield/flutter_svg/issues/661

  SkPath path1;
  path1.setFillType(SkPathFillType::kWinding);
  path1.moveTo(25.54f, 37.52f);
  path1.cubicTo(20.91f, 37.52f, 16.54f, 33.39f, 13.62f, 30.58f);
  path1.lineTo(13, 30);
  path1.lineTo(12.45f, 29.42f);
  path1.cubicTo(8.39f, 25.15f, 1.61f, 18, 8.37f, 11.27f);
  path1.cubicTo(10.18f, 9.46f, 12.37f, 9.58f, 14.49f, 11.58f);
  path1.cubicTo(15.67f, 12.71f, 17.05f, 14.69f, 17.07f, 16.58f);
  path1.cubicTo(17.0968f, 17.458f, 16.7603f, 18.3081f, 16.14f, 18.93f);
  path1.cubicTo(15.8168f, 19.239f, 15.4653f, 19.5169f, 15.09f, 19.76f);
  path1.cubicTo(14.27f, 20.33f, 14.21f, 20.44f, 14.27f, 20.62f);
  path1.cubicTo(15.1672f, 22.3493f, 16.3239f, 23.9309f, 17.7f, 25.31f);
  path1.cubicTo(19.0791f, 26.6861f, 20.6607f, 27.8428f, 22.39f, 28.74f);
  path1.cubicTo(22.57f, 28.8f, 22.69f, 28.74f, 23.25f, 27.92f);
  path1.cubicTo(23.5f, 27.566f, 23.778f, 27.231f, 24.08f, 26.92f);
  path1.cubicTo(24.7045f, 26.3048f, 25.5538f, 25.9723f, 26.43f, 26);
  path1.cubicTo(28.29f, 26, 30.27f, 27.4f, 31.43f, 28.58f);
  path1.cubicTo(33.43f, 30.67f, 33.55f, 32.9f, 31.74f, 34.7f);
  path1.cubicTo(30.1477f, 36.4508f, 27.906f, 37.4704f, 25.54f, 37.52f);
  path1.close();
  path1.moveTo(11.17f, 12.23f);
  path1.cubicTo(10.6946f, 12.2571f, 10.2522f, 12.4819f, 9.95f, 12.85f);
  path1.cubicTo(5.12f, 17.67f, 8.95f, 22.5f, 14.05f, 27.85f);
  path1.lineTo(14.62f, 28.45f);
  path1.lineTo(15.16f, 28.96f);
  path1.cubicTo(20.52f, 34.06f, 25.35f, 37.89f, 30.16f, 33.06f);
  path1.cubicTo(30.83f, 32.39f, 31.25f, 31.56f, 29.81f, 30.06f);
  path1.cubicTo(28.9247f, 29.07f, 27.7359f, 28.4018f, 26.43f, 28.16f);
  path1.cubicTo(26.1476f, 28.1284f, 25.8676f, 28.2367f, 25.68f, 28.45f);
  path1.cubicTo(25.4633f, 28.6774f, 25.269f, 28.9252f, 25.1f, 29.19f);
  path1.cubicTo(24.53f, 30.01f, 23.47f, 31.54f, 21.54f, 30.79f);
  path1.lineTo(21.41f, 30.72f);
  path1.cubicTo(19.4601f, 29.7156f, 17.6787f, 28.4133f, 16.13f, 26.86f);
  path1.cubicTo(14.5748f, 25.3106f, 13.2693f, 23.5295f, 12.26f, 21.58f);
  path1.lineTo(12.2f, 21.44f);
  path1.cubicTo(11.45f, 19.51f, 12.97f, 18.44f, 13.8f, 17.88f);
  path1.cubicTo(14.061f, 17.706f, 14.308f, 17.512f, 14.54f, 17.3f);
  path1.cubicTo(14.7379f, 17.1067f, 14.8404f, 16.8359f, 14.82f, 16.56f);
  path1.cubicTo(14.5978f, 15.268f, 13.9585f, 14.0843f, 13, 13.19f);
  path1.cubicTo(12.5398f, 12.642f, 11.8824f, 12.2971f, 11.17f, 12.23f);
  path1.lineTo(11.17f, 12.23f);
  path1.close();
  path1.moveTo(27, 19.34f);
  path1.lineTo(24.74f, 19.34f);
  path1.cubicTo(24.7319f, 18.758f, 24.262f, 18.2881f, 23.68f, 18.28f);
  path1.lineTo(23.68f, 16.05f);
  path1.lineTo(23.7f, 16.05f);
  path1.cubicTo(25.5153f, 16.0582f, 26.9863f, 17.5248f, 27, 19.34f);
  path1.lineTo(27, 19.34f);
  path1.close();
  path1.moveTo(32.3f, 19.34f);
  path1.lineTo(30.07f, 19.34f);
  path1.cubicTo(30.037f, 15.859f, 27.171f, 13.011f, 23.69f, 13);
  path1.lineTo(23.69f, 10.72f);
  path1.cubicTo(28.415f, 10.725f, 32.3f, 14.615f, 32.3f, 19.34f);
  path1.close();

  SkPath path2;
  path2.setFillType(SkPathFillType::kWinding);
  path2.moveTo(37.5f, 19.33f);
  path2.lineTo(35.27f, 19.33f);
  path2.cubicTo(35.265f, 12.979f, 30.041f, 7.755f, 23.69f, 7.75f);
  path2.lineTo(23.69f, 5.52f);
  path2.cubicTo(31.264f, 5.525f, 37.495f, 11.756f, 37.5f, 19.33f);
  path2.close();

  DisplayListBuilder builder;
  DlPaint paint = DlPaint(DlColor::kWhite()).setAntiAlias(true);
  {
    builder.Save();
    builder.ClipRect({0, 0, 100, 100}, ClipOp::kIntersect, true);
    {
      builder.Save();
      builder.Transform2DAffine(2.17391, 0, -2547.83,  //
                                0, 2.04082, -500);
      {
        builder.Save();
        builder.ClipRect({1172, 245, 1218, 294}, ClipOp::kIntersect, true);
        {
          builder.SaveLayer(nullptr, nullptr, nullptr);
          {
            builder.Save();
            builder.Transform2DAffine(1.4375, 0, 1164.09,  //
                                      0, 1.53125, 236.548);
            builder.DrawPath(path1, paint);
            builder.Restore();
          }
          {
            builder.Save();
            builder.Transform2DAffine(1.4375, 0, 1164.09,  //
                                      0, 1.53125, 236.548);
            builder.DrawPath(path2, paint);
            builder.Restore();
          }
          builder.Restore();
        }
        builder.Restore();
      }
      builder.Restore();
    }
    builder.Restore();
  }
  sk_sp<DisplayList> display_list = builder.Build();
  // Prior to the fix, the bounds were empty.
  EXPECT_FALSE(display_list->bounds().isEmpty());
  // These are just inside and outside of the expected bounds, but
  // testing float values can be flaky wrt minor changes in the bounds
  // calculations. If these lines have to be revised too often as the DL
  // implementation is improved and maintained, then we can eliminate
  // this test and just rely on the "rounded out" bounds test that follows.
  SkRect min_bounds = SkRect::MakeLTRB(0, 0.00191, 99.983, 100);
  SkRect max_bounds = SkRect::MakeLTRB(0, 0.00189, 99.985, 100);
  ASSERT_TRUE(max_bounds.contains(min_bounds));
  EXPECT_TRUE(max_bounds.contains(display_list->bounds()));
  EXPECT_TRUE(display_list->bounds().contains(min_bounds));

  // This is the more practical result. The bounds are "almost" 0,0,100x100
  EXPECT_EQ(display_list->bounds().roundOut(), SkIRect::MakeWH(100, 100));
  EXPECT_EQ(display_list->op_count(), 19u);
  EXPECT_EQ(display_list->bytes(), sizeof(DisplayList) + 352u);
}

TEST_F(DisplayListTest, TranslateAffectsCurrentTransform) {
  DisplayListBuilder builder;
  builder.Translate(12.3, 14.5);
  SkMatrix matrix = SkMatrix::Translate(12.3, 14.5);
  SkM44 m44 = SkM44(matrix);
  SkM44 cur_m44 = builder.GetTransformFullPerspective();
  SkMatrix cur_matrix = builder.GetTransform();
  ASSERT_EQ(cur_m44, m44);
  ASSERT_EQ(cur_matrix, matrix);
  builder.Translate(10, 10);
  // CurrentTransform has changed
  ASSERT_NE(builder.GetTransformFullPerspective(), m44);
  ASSERT_NE(builder.GetTransform(), cur_matrix);
  // Previous return values have not
  ASSERT_EQ(cur_m44, m44);
  ASSERT_EQ(cur_matrix, matrix);
}

TEST_F(DisplayListTest, ScaleAffectsCurrentTransform) {
  DisplayListBuilder builder;
  builder.Scale(12.3, 14.5);
  SkMatrix matrix = SkMatrix::Scale(12.3, 14.5);
  SkM44 m44 = SkM44(matrix);
  SkM44 cur_m44 = builder.GetTransformFullPerspective();
  SkMatrix cur_matrix = builder.GetTransform();
  ASSERT_EQ(cur_m44, m44);
  ASSERT_EQ(cur_matrix, matrix);
  builder.Translate(10, 10);
  // CurrentTransform has changed
  ASSERT_NE(builder.GetTransformFullPerspective(), m44);
  ASSERT_NE(builder.GetTransform(), cur_matrix);
  // Previous return values have not
  ASSERT_EQ(cur_m44, m44);
  ASSERT_EQ(cur_matrix, matrix);
}

TEST_F(DisplayListTest, RotateAffectsCurrentTransform) {
  DisplayListBuilder builder;
  builder.Rotate(12.3);
  SkMatrix matrix = SkMatrix::RotateDeg(12.3);
  SkM44 m44 = SkM44(matrix);
  SkM44 cur_m44 = builder.GetTransformFullPerspective();
  SkMatrix cur_matrix = builder.GetTransform();
  ASSERT_EQ(cur_m44, m44);
  ASSERT_EQ(cur_matrix, matrix);
  builder.Translate(10, 10);
  // CurrentTransform has changed
  ASSERT_NE(builder.GetTransformFullPerspective(), m44);
  ASSERT_NE(builder.GetTransform(), cur_matrix);
  // Previous return values have not
  ASSERT_EQ(cur_m44, m44);
  ASSERT_EQ(cur_matrix, matrix);
}

TEST_F(DisplayListTest, SkewAffectsCurrentTransform) {
  DisplayListBuilder builder;
  builder.Skew(12.3, 14.5);
  SkMatrix matrix = SkMatrix::Skew(12.3, 14.5);
  SkM44 m44 = SkM44(matrix);
  SkM44 cur_m44 = builder.GetTransformFullPerspective();
  SkMatrix cur_matrix = builder.GetTransform();
  ASSERT_EQ(cur_m44, m44);
  ASSERT_EQ(cur_matrix, matrix);
  builder.Translate(10, 10);
  // CurrentTransform has changed
  ASSERT_NE(builder.GetTransformFullPerspective(), m44);
  ASSERT_NE(builder.GetTransform(), cur_matrix);
  // Previous return values have not
  ASSERT_EQ(cur_m44, m44);
  ASSERT_EQ(cur_matrix, matrix);
}

TEST_F(DisplayListTest, TransformAffectsCurrentTransform) {
  DisplayListBuilder builder;
  builder.Transform2DAffine(3, 0, 12.3,  //
                            1, 5, 14.5);
  SkMatrix matrix = SkMatrix::MakeAll(3, 0, 12.3,  //
                                      1, 5, 14.5,  //
                                      0, 0, 1);
  SkM44 m44 = SkM44(matrix);
  SkM44 cur_m44 = builder.GetTransformFullPerspective();
  SkMatrix cur_matrix = builder.GetTransform();
  ASSERT_EQ(cur_m44, m44);
  ASSERT_EQ(cur_matrix, matrix);
  builder.Translate(10, 10);
  // CurrentTransform has changed
  ASSERT_NE(builder.GetTransformFullPerspective(), m44);
  ASSERT_NE(builder.GetTransform(), cur_matrix);
  // Previous return values have not
  ASSERT_EQ(cur_m44, m44);
  ASSERT_EQ(cur_matrix, matrix);
}

TEST_F(DisplayListTest, FullTransformAffectsCurrentTransform) {
  DisplayListBuilder builder;
  builder.TransformFullPerspective(3, 0, 4, 12.3,  //
                                   1, 5, 3, 14.5,  //
                                   0, 0, 7, 16.2,  //
                                   0, 0, 0, 1);
  SkMatrix matrix = SkMatrix::MakeAll(3, 0, 12.3,  //
                                      1, 5, 14.5,  //
                                      0, 0, 1);
  SkM44 m44 = SkM44(3, 0, 4, 12.3,  //
                    1, 5, 3, 14.5,  //
                    0, 0, 7, 16.2,  //
                    0, 0, 0, 1);
  SkM44 cur_m44 = builder.GetTransformFullPerspective();
  SkMatrix cur_matrix = builder.GetTransform();
  ASSERT_EQ(cur_m44, m44);
  ASSERT_EQ(cur_matrix, matrix);
  builder.Translate(10, 10);
  // CurrentTransform has changed
  ASSERT_NE(builder.GetTransformFullPerspective(), m44);
  ASSERT_NE(builder.GetTransform(), cur_matrix);
  // Previous return values have not
  ASSERT_EQ(cur_m44, m44);
  ASSERT_EQ(cur_matrix, matrix);
}

TEST_F(DisplayListTest, ClipRectAffectsClipBounds) {
  DisplayListBuilder builder;
  SkRect clip_bounds = SkRect::MakeLTRB(10.2, 11.3, 20.4, 25.7);
  builder.ClipRect(clip_bounds, ClipOp::kIntersect, false);

  // Save initial return values for testing restored values
  SkRect initial_local_bounds = builder.GetLocalClipBounds();
  SkRect initial_destination_bounds = builder.GetDestinationClipBounds();
  ASSERT_EQ(initial_local_bounds, clip_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_bounds);

  builder.Save();
  builder.ClipRect({0, 0, 15, 15}, ClipOp::kIntersect, false);
  // Both clip bounds have changed
  ASSERT_NE(builder.GetLocalClipBounds(), clip_bounds);
  ASSERT_NE(builder.GetDestinationClipBounds(), clip_bounds);
  // Previous return values have not changed
  ASSERT_EQ(initial_local_bounds, clip_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_bounds);
  builder.Restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);

  builder.Save();
  builder.Scale(2, 2);
  SkRect scaled_clip_bounds = SkRect::MakeLTRB(5.1, 5.65, 10.2, 12.85);
  ASSERT_EQ(builder.GetLocalClipBounds(), scaled_clip_bounds);
  // Destination bounds are unaffected by transform
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds);
  builder.Restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);
}

TEST_F(DisplayListTest, ClipRectDoAAAffectsClipBounds) {
  DisplayListBuilder builder;
  SkRect clip_bounds = SkRect::MakeLTRB(10.2, 11.3, 20.4, 25.7);
  SkRect clip_expanded_bounds = SkRect::MakeLTRB(10, 11, 21, 26);
  builder.ClipRect(clip_bounds, ClipOp::kIntersect, true);

  // Save initial return values for testing restored values
  SkRect initial_local_bounds = builder.GetLocalClipBounds();
  SkRect initial_destination_bounds = builder.GetDestinationClipBounds();
  ASSERT_EQ(initial_local_bounds, clip_expanded_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_expanded_bounds);

  builder.Save();
  builder.ClipRect({0, 0, 15, 15}, ClipOp::kIntersect, true);
  // Both clip bounds have changed
  ASSERT_NE(builder.GetLocalClipBounds(), clip_expanded_bounds);
  ASSERT_NE(builder.GetDestinationClipBounds(), clip_expanded_bounds);
  // Previous return values have not changed
  ASSERT_EQ(initial_local_bounds, clip_expanded_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_expanded_bounds);
  builder.Restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);

  builder.Save();
  builder.Scale(2, 2);
  SkRect scaled_expanded_bounds = SkRect::MakeLTRB(5, 5.5, 10.5, 13);
  ASSERT_EQ(builder.GetLocalClipBounds(), scaled_expanded_bounds);
  // Destination bounds are unaffected by transform
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_expanded_bounds);
  builder.Restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);
}

TEST_F(DisplayListTest, ClipRectAffectsClipBoundsWithMatrix) {
  DisplayListBuilder builder;
  SkRect clip_bounds_1 = SkRect::MakeLTRB(0, 0, 10, 10);
  SkRect clip_bounds_2 = SkRect::MakeLTRB(10, 10, 20, 20);
  builder.Save();
  builder.ClipRect(clip_bounds_1, ClipOp::kIntersect, false);
  builder.Translate(10, 0);
  builder.ClipRect(clip_bounds_1, ClipOp::kIntersect, false);
  ASSERT_TRUE(builder.GetDestinationClipBounds().isEmpty());
  builder.Restore();

  builder.Save();
  builder.ClipRect(clip_bounds_1, ClipOp::kIntersect, false);
  builder.Translate(-10, -10);
  builder.ClipRect(clip_bounds_2, ClipOp::kIntersect, false);
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds_1);
  builder.Restore();
}

TEST_F(DisplayListTest, ClipRRectAffectsClipBounds) {
  DisplayListBuilder builder;
  SkRect clip_bounds = SkRect::MakeLTRB(10.2, 11.3, 20.4, 25.7);
  SkRRect clip = SkRRect::MakeRectXY(clip_bounds, 3, 2);
  builder.ClipRRect(clip, ClipOp::kIntersect, false);

  // Save initial return values for testing restored values
  SkRect initial_local_bounds = builder.GetLocalClipBounds();
  SkRect initial_destination_bounds = builder.GetDestinationClipBounds();
  ASSERT_EQ(initial_local_bounds, clip_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_bounds);

  builder.Save();
  builder.ClipRect({0, 0, 15, 15}, ClipOp::kIntersect, false);
  // Both clip bounds have changed
  ASSERT_NE(builder.GetLocalClipBounds(), clip_bounds);
  ASSERT_NE(builder.GetDestinationClipBounds(), clip_bounds);
  // Previous return values have not changed
  ASSERT_EQ(initial_local_bounds, clip_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_bounds);
  builder.Restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);

  builder.Save();
  builder.Scale(2, 2);
  SkRect scaled_clip_bounds = SkRect::MakeLTRB(5.1, 5.65, 10.2, 12.85);
  ASSERT_EQ(builder.GetLocalClipBounds(), scaled_clip_bounds);
  // Destination bounds are unaffected by transform
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds);
  builder.Restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);
}

TEST_F(DisplayListTest, ClipRRectDoAAAffectsClipBounds) {
  DisplayListBuilder builder;
  SkRect clip_bounds = SkRect::MakeLTRB(10.2, 11.3, 20.4, 25.7);
  SkRect clip_expanded_bounds = SkRect::MakeLTRB(10, 11, 21, 26);
  SkRRect clip = SkRRect::MakeRectXY(clip_bounds, 3, 2);
  builder.ClipRRect(clip, ClipOp::kIntersect, true);

  // Save initial return values for testing restored values
  SkRect initial_local_bounds = builder.GetLocalClipBounds();
  SkRect initial_destination_bounds = builder.GetDestinationClipBounds();
  ASSERT_EQ(initial_local_bounds, clip_expanded_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_expanded_bounds);

  builder.Save();
  builder.ClipRect({0, 0, 15, 15}, ClipOp::kIntersect, true);
  // Both clip bounds have changed
  ASSERT_NE(builder.GetLocalClipBounds(), clip_expanded_bounds);
  ASSERT_NE(builder.GetDestinationClipBounds(), clip_expanded_bounds);
  // Previous return values have not changed
  ASSERT_EQ(initial_local_bounds, clip_expanded_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_expanded_bounds);
  builder.Restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);

  builder.Save();
  builder.Scale(2, 2);
  SkRect scaled_expanded_bounds = SkRect::MakeLTRB(5, 5.5, 10.5, 13);
  ASSERT_EQ(builder.GetLocalClipBounds(), scaled_expanded_bounds);
  // Destination bounds are unaffected by transform
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_expanded_bounds);
  builder.Restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);
}

TEST_F(DisplayListTest, ClipRRectAffectsClipBoundsWithMatrix) {
  DisplayListBuilder builder;
  SkRect clip_bounds_1 = SkRect::MakeLTRB(0, 0, 10, 10);
  SkRect clip_bounds_2 = SkRect::MakeLTRB(10, 10, 20, 20);
  SkRRect clip1 = SkRRect::MakeRectXY(clip_bounds_1, 3, 2);
  SkRRect clip2 = SkRRect::MakeRectXY(clip_bounds_2, 3, 2);

  builder.Save();
  builder.ClipRRect(clip1, ClipOp::kIntersect, false);
  builder.Translate(10, 0);
  builder.ClipRRect(clip1, ClipOp::kIntersect, false);
  ASSERT_TRUE(builder.GetDestinationClipBounds().isEmpty());
  builder.Restore();

  builder.Save();
  builder.ClipRRect(clip1, ClipOp::kIntersect, false);
  builder.Translate(-10, -10);
  builder.ClipRRect(clip2, ClipOp::kIntersect, false);
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds_1);
  builder.Restore();
}

TEST_F(DisplayListTest, ClipPathAffectsClipBounds) {
  DisplayListBuilder builder;
  SkPath clip = SkPath().addCircle(10.2, 11.3, 2).addCircle(20.4, 25.7, 2);
  SkRect clip_bounds = SkRect::MakeLTRB(8.2, 9.3, 22.4, 27.7);
  builder.ClipPath(clip, ClipOp::kIntersect, false);

  // Save initial return values for testing restored values
  SkRect initial_local_bounds = builder.GetLocalClipBounds();
  SkRect initial_destination_bounds = builder.GetDestinationClipBounds();
  ASSERT_EQ(initial_local_bounds, clip_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_bounds);

  builder.Save();
  builder.ClipRect({0, 0, 15, 15}, ClipOp::kIntersect, false);
  // Both clip bounds have changed
  ASSERT_NE(builder.GetLocalClipBounds(), clip_bounds);
  ASSERT_NE(builder.GetDestinationClipBounds(), clip_bounds);
  // Previous return values have not changed
  ASSERT_EQ(initial_local_bounds, clip_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_bounds);
  builder.Restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);

  builder.Save();
  builder.Scale(2, 2);
  SkRect scaled_clip_bounds = SkRect::MakeLTRB(4.1, 4.65, 11.2, 13.85);
  ASSERT_EQ(builder.GetLocalClipBounds(), scaled_clip_bounds);
  // Destination bounds are unaffected by transform
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds);
  builder.Restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);
}

TEST_F(DisplayListTest, ClipPathDoAAAffectsClipBounds) {
  DisplayListBuilder builder;
  SkPath clip = SkPath().addCircle(10.2, 11.3, 2).addCircle(20.4, 25.7, 2);
  SkRect clip_expanded_bounds = SkRect::MakeLTRB(8, 9, 23, 28);
  builder.ClipPath(clip, ClipOp::kIntersect, true);

  // Save initial return values for testing restored values
  SkRect initial_local_bounds = builder.GetLocalClipBounds();
  SkRect initial_destination_bounds = builder.GetDestinationClipBounds();
  ASSERT_EQ(initial_local_bounds, clip_expanded_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_expanded_bounds);

  builder.Save();
  builder.ClipRect({0, 0, 15, 15}, ClipOp::kIntersect, true);
  // Both clip bounds have changed
  ASSERT_NE(builder.GetLocalClipBounds(), clip_expanded_bounds);
  ASSERT_NE(builder.GetDestinationClipBounds(), clip_expanded_bounds);
  // Previous return values have not changed
  ASSERT_EQ(initial_local_bounds, clip_expanded_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_expanded_bounds);
  builder.Restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);

  builder.Save();
  builder.Scale(2, 2);
  SkRect scaled_expanded_bounds = SkRect::MakeLTRB(4, 4.5, 11.5, 14);
  ASSERT_EQ(builder.GetLocalClipBounds(), scaled_expanded_bounds);
  // Destination bounds are unaffected by transform
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_expanded_bounds);
  builder.Restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);
}

TEST_F(DisplayListTest, ClipPathAffectsClipBoundsWithMatrix) {
  DisplayListBuilder builder;
  SkRect clip_bounds = SkRect::MakeLTRB(0, 0, 10, 10);
  SkPath clip1 = SkPath().addCircle(2.5, 2.5, 2.5).addCircle(7.5, 7.5, 2.5);
  SkPath clip2 = SkPath().addCircle(12.5, 12.5, 2.5).addCircle(17.5, 17.5, 2.5);

  builder.Save();
  builder.ClipPath(clip1, ClipOp::kIntersect, false);
  builder.Translate(10, 0);
  builder.ClipPath(clip1, ClipOp::kIntersect, false);
  ASSERT_TRUE(builder.GetDestinationClipBounds().isEmpty());
  builder.Restore();

  builder.Save();
  builder.ClipPath(clip1, ClipOp::kIntersect, false);
  builder.Translate(-10, -10);
  builder.ClipPath(clip2, ClipOp::kIntersect, false);
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds);
  builder.Restore();
}

TEST_F(DisplayListTest, DiffClipRectDoesNotAffectClipBounds) {
  DisplayListBuilder builder;
  SkRect diff_clip = SkRect::MakeLTRB(0, 0, 15, 15);
  SkRect clip_bounds = SkRect::MakeLTRB(10.2, 11.3, 20.4, 25.7);
  builder.ClipRect(clip_bounds, ClipOp::kIntersect, false);

  // Save initial return values for testing after kDifference clip
  SkRect initial_local_bounds = builder.GetLocalClipBounds();
  SkRect initial_destination_bounds = builder.GetDestinationClipBounds();
  ASSERT_EQ(initial_local_bounds, clip_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_bounds);

  builder.ClipRect(diff_clip, ClipOp::kDifference, false);
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);
}

TEST_F(DisplayListTest, DiffClipRRectDoesNotAffectClipBounds) {
  DisplayListBuilder builder;
  SkRRect diff_clip = SkRRect::MakeRectXY({0, 0, 15, 15}, 1, 1);
  SkRect clip_bounds = SkRect::MakeLTRB(10.2, 11.3, 20.4, 25.7);
  SkRRect clip = SkRRect::MakeRectXY({10.2, 11.3, 20.4, 25.7}, 3, 2);
  builder.ClipRRect(clip, ClipOp::kIntersect, false);

  // Save initial return values for testing after kDifference clip
  SkRect initial_local_bounds = builder.GetLocalClipBounds();
  SkRect initial_destination_bounds = builder.GetDestinationClipBounds();
  ASSERT_EQ(initial_local_bounds, clip_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_bounds);

  builder.ClipRRect(diff_clip, ClipOp::kDifference, false);
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);
}

TEST_F(DisplayListTest, DiffClipPathDoesNotAffectClipBounds) {
  DisplayListBuilder builder;
  SkPath diff_clip = SkPath().addRect({0, 0, 15, 15});
  SkPath clip = SkPath().addCircle(10.2, 11.3, 2).addCircle(20.4, 25.7, 2);
  SkRect clip_bounds = SkRect::MakeLTRB(8.2, 9.3, 22.4, 27.7);
  builder.ClipPath(clip, ClipOp::kIntersect, false);

  // Save initial return values for testing after kDifference clip
  SkRect initial_local_bounds = builder.GetLocalClipBounds();
  SkRect initial_destination_bounds = builder.GetDestinationClipBounds();
  ASSERT_EQ(initial_local_bounds, clip_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_bounds);

  builder.ClipPath(diff_clip, ClipOp::kDifference, false);
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);
}

TEST_F(DisplayListTest, ClipPathWithInvertFillTypeDoesNotAffectClipBounds) {
  SkRect cull_rect = SkRect::MakeLTRB(0, 0, 100.0, 100.0);
  DisplayListBuilder builder(cull_rect);
  SkPath clip = SkPath().addCircle(10.2, 11.3, 2).addCircle(20.4, 25.7, 2);
  clip.setFillType(SkPathFillType::kInverseWinding);
  builder.ClipPath(clip, ClipOp::kIntersect, false);

  ASSERT_EQ(builder.GetLocalClipBounds(), cull_rect);
  ASSERT_EQ(builder.GetDestinationClipBounds(), cull_rect);
}

TEST_F(DisplayListTest, DiffClipPathWithInvertFillTypeAffectsClipBounds) {
  SkRect cull_rect = SkRect::MakeLTRB(0, 0, 100.0, 100.0);
  DisplayListBuilder builder(cull_rect);
  SkPath clip = SkPath().addCircle(10.2, 11.3, 2).addCircle(20.4, 25.7, 2);
  clip.setFillType(SkPathFillType::kInverseWinding);
  SkRect clip_bounds = SkRect::MakeLTRB(8.2, 9.3, 22.4, 27.7);
  builder.ClipPath(clip, ClipOp::kDifference, false);

  ASSERT_EQ(builder.GetLocalClipBounds(), clip_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds);
}

TEST_F(DisplayListTest, FlatDrawPointsProducesBounds) {
  SkPoint horizontal_points[2] = {{10, 10}, {20, 10}};
  SkPoint vertical_points[2] = {{10, 10}, {10, 20}};
  {
    DisplayListBuilder builder;
    builder.DrawPoints(PointMode::kPolygon, 2, horizontal_points, DlPaint());
    SkRect bounds = builder.Build()->bounds();
    EXPECT_TRUE(bounds.contains(10, 10));
    EXPECT_TRUE(bounds.contains(20, 10));
    EXPECT_GE(bounds.width(), 10);
  }
  {
    DisplayListBuilder builder;
    builder.DrawPoints(PointMode::kPolygon, 2, vertical_points, DlPaint());
    SkRect bounds = builder.Build()->bounds();
    EXPECT_TRUE(bounds.contains(10, 10));
    EXPECT_TRUE(bounds.contains(10, 20));
    EXPECT_GE(bounds.height(), 10);
  }
  {
    DisplayListBuilder builder;
    builder.DrawPoints(PointMode::kPoints, 1, horizontal_points, DlPaint());
    SkRect bounds = builder.Build()->bounds();
    EXPECT_TRUE(bounds.contains(10, 10));
  }
  {
    DisplayListBuilder builder;
    builder.DrawPoints(PointMode::kPolygon, 2, horizontal_points,
                       DlPaint().setStrokeWidth(2));
    SkRect bounds = builder.Build()->bounds();
    EXPECT_TRUE(bounds.contains(10, 10));
    EXPECT_TRUE(bounds.contains(20, 10));
    EXPECT_EQ(bounds, SkRect::MakeLTRB(9, 9, 21, 11));
  }
  {
    DisplayListBuilder builder;
    builder.DrawPoints(PointMode::kPolygon, 2, vertical_points,
                       DlPaint().setStrokeWidth(2));
    SkRect bounds = builder.Build()->bounds();
    EXPECT_TRUE(bounds.contains(10, 10));
    EXPECT_TRUE(bounds.contains(10, 20));
    EXPECT_EQ(bounds, SkRect::MakeLTRB(9, 9, 11, 21));
  }
  {
    DisplayListBuilder builder;
    builder.DrawPoints(PointMode::kPoints, 1, horizontal_points,
                       DlPaint().setStrokeWidth(2));
    SkRect bounds = builder.Build()->bounds();
    EXPECT_TRUE(bounds.contains(10, 10));
    EXPECT_EQ(bounds, SkRect::MakeLTRB(9, 9, 11, 11));
  }
}

static void test_rtree(const std::shared_ptr<const DlRTree>& rtree,
                       const SkRect& query,
                       std::vector<SkRect> expected_rects,
                       const std::vector<int>& expected_indices) {
  std::vector<int> indices;
  rtree->search(query, &indices);
  EXPECT_EQ(indices, expected_indices);
  EXPECT_EQ(indices.size(), expected_indices.size());
  std::list<SkRect> rects = rtree->searchAndConsolidateRects(query);
  // ASSERT_EQ(rects.size(), expected_indices.size());
  auto iterator = rects.cbegin();
  for (int i : expected_indices) {
    EXPECT_TRUE(iterator != rects.cend());
    EXPECT_EQ(*iterator++, expected_rects[i]);
  }
}

TEST_F(DisplayListTest, RTreeOfSimpleScene) {
  DisplayListBuilder builder(/*prepare_rtree=*/true);
  builder.DrawRect({10, 10, 20, 20}, DlPaint());
  builder.DrawRect({50, 50, 60, 60}, DlPaint());
  auto display_list = builder.Build();
  auto rtree = display_list->rtree();
  std::vector<SkRect> rects = {
      {10, 10, 20, 20},
      {50, 50, 60, 60},
  };

  // Missing all drawRect calls
  test_rtree(rtree, {5, 5, 10, 10}, rects, {});
  test_rtree(rtree, {20, 20, 25, 25}, rects, {});
  test_rtree(rtree, {45, 45, 50, 50}, rects, {});
  test_rtree(rtree, {60, 60, 65, 65}, rects, {});

  // Hitting just 1 of the drawRects
  test_rtree(rtree, {5, 5, 11, 11}, rects, {0});
  test_rtree(rtree, {19, 19, 25, 25}, rects, {0});
  test_rtree(rtree, {45, 45, 51, 51}, rects, {1});
  test_rtree(rtree, {59, 59, 65, 65}, rects, {1});

  // Hitting both drawRect calls
  test_rtree(rtree, {19, 19, 51, 51}, rects, {0, 1});
}

TEST_F(DisplayListTest, RTreeOfSaveRestoreScene) {
  DisplayListBuilder builder(/*prepare_rtree=*/true);
  builder.DrawRect({10, 10, 20, 20}, DlPaint());
  builder.Save();
  builder.DrawRect({50, 50, 60, 60}, DlPaint());
  builder.Restore();
  auto display_list = builder.Build();
  auto rtree = display_list->rtree();
  std::vector<SkRect> rects = {
      {10, 10, 20, 20},
      {50, 50, 60, 60},
  };

  // Missing all drawRect calls
  test_rtree(rtree, {5, 5, 10, 10}, rects, {});
  test_rtree(rtree, {20, 20, 25, 25}, rects, {});
  test_rtree(rtree, {45, 45, 50, 50}, rects, {});
  test_rtree(rtree, {60, 60, 65, 65}, rects, {});

  // Hitting just 1 of the drawRects
  test_rtree(rtree, {5, 5, 11, 11}, rects, {0});
  test_rtree(rtree, {19, 19, 25, 25}, rects, {0});
  test_rtree(rtree, {45, 45, 51, 51}, rects, {1});
  test_rtree(rtree, {59, 59, 65, 65}, rects, {1});

  // Hitting both drawRect calls
  test_rtree(rtree, {19, 19, 51, 51}, rects, {0, 1});
}

TEST_F(DisplayListTest, RTreeOfSaveLayerFilterScene) {
  DisplayListBuilder builder(/*prepare_rtree=*/true);
  // blur filter with sigma=1 expands by 3 on all sides
  auto filter = DlBlurImageFilter(1.0, 1.0, DlTileMode::kClamp);
  DlPaint default_paint = DlPaint();
  DlPaint filter_paint = DlPaint().setImageFilter(&filter);
  builder.DrawRect({10, 10, 20, 20}, default_paint);
  builder.SaveLayer(nullptr, &filter_paint);
  // the following rectangle will be expanded to 50,50,60,60
  // by the saveLayer filter during the restore operation
  builder.DrawRect({53, 53, 57, 57}, default_paint);
  builder.Restore();
  auto display_list = builder.Build();
  auto rtree = display_list->rtree();
  std::vector<SkRect> rects = {
      {10, 10, 20, 20},
      {50, 50, 60, 60},
  };

  // Missing all drawRect calls
  test_rtree(rtree, {5, 5, 10, 10}, rects, {});
  test_rtree(rtree, {20, 20, 25, 25}, rects, {});
  test_rtree(rtree, {45, 45, 50, 50}, rects, {});
  test_rtree(rtree, {60, 60, 65, 65}, rects, {});

  // Hitting just 1 of the drawRects
  test_rtree(rtree, {5, 5, 11, 11}, rects, {0});
  test_rtree(rtree, {19, 19, 25, 25}, rects, {0});
  test_rtree(rtree, {45, 45, 51, 51}, rects, {1});
  test_rtree(rtree, {59, 59, 65, 65}, rects, {1});

  // Hitting both drawRect calls
  test_rtree(rtree, {19, 19, 51, 51}, rects, {0, 1});
}

TEST_F(DisplayListTest, NestedDisplayListRTreesAreSparse) {
  DisplayListBuilder nested_dl_builder(/**prepare_rtree=*/true);
  nested_dl_builder.DrawRect({10, 10, 20, 20}, DlPaint());
  nested_dl_builder.DrawRect({50, 50, 60, 60}, DlPaint());
  auto nested_display_list = nested_dl_builder.Build();

  DisplayListBuilder builder(/**prepare_rtree=*/true);
  builder.DrawDisplayList(nested_display_list);
  auto display_list = builder.Build();

  auto rtree = display_list->rtree();
  std::vector<SkRect> rects = {
      {10, 10, 20, 20},
      {50, 50, 60, 60},
  };

  // Hitting both sub-dl drawRect calls
  test_rtree(rtree, {19, 19, 51, 51}, rects, {0, 1});
}

TEST_F(DisplayListTest, RemoveUnnecessarySaveRestorePairs) {
  {
    DisplayListBuilder builder;
    builder.DrawRect({10, 10, 20, 20}, DlPaint());
    builder.Save();  // This save op is unnecessary
    builder.DrawRect({50, 50, 60, 60}, DlPaint());
    builder.Restore();

    DisplayListBuilder builder2;
    builder2.DrawRect({10, 10, 20, 20}, DlPaint());
    builder2.DrawRect({50, 50, 60, 60}, DlPaint());
    ASSERT_TRUE(DisplayListsEQ_Verbose(builder.Build(), builder2.Build()));
  }

  {
    DisplayListBuilder builder;
    builder.DrawRect({10, 10, 20, 20}, DlPaint());
    builder.Save();
    builder.Translate(1.0, 1.0);
    {
      builder.Save();  // unnecessary
      builder.DrawRect({50, 50, 60, 60}, DlPaint());
      builder.Restore();
    }

    builder.Restore();

    DisplayListBuilder builder2;
    builder2.DrawRect({10, 10, 20, 20}, DlPaint());
    builder2.Save();
    builder2.Translate(1.0, 1.0);
    { builder2.DrawRect({50, 50, 60, 60}, DlPaint()); }
    builder2.Restore();
    ASSERT_TRUE(DisplayListsEQ_Verbose(builder.Build(), builder2.Build()));
  }
}

TEST_F(DisplayListTest, CollapseMultipleNestedSaveRestore) {
  DisplayListBuilder builder1;
  builder1.Save();
  builder1.Save();
  builder1.Save();
  builder1.Translate(10, 10);
  builder1.Scale(2, 2);
  builder1.ClipRect({10, 10, 20, 20}, ClipOp::kIntersect, false);
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  builder1.Restore();
  builder1.Restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.Save();
  builder2.Translate(10, 10);
  builder2.Scale(2, 2);
  builder2.ClipRect({10, 10, 20, 20}, ClipOp::kIntersect, false);
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  builder2.Restore();
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST_F(DisplayListTest, CollapseNestedSaveAndSaveLayerRestore) {
  DisplayListBuilder builder1;
  builder1.Save();
  builder1.SaveLayer(nullptr, nullptr);
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Scale(2, 2);
  builder1.Restore();
  builder1.Restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.SaveLayer(nullptr, nullptr);
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  builder2.Scale(2, 2);
  builder2.Restore();
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST_F(DisplayListTest, RemoveUnnecessarySaveRestorePairsInSetPaint) {
  SkRect build_bounds = SkRect::MakeLTRB(-100, -100, 200, 200);
  SkRect rect = SkRect::MakeLTRB(30, 30, 70, 70);
  // clang-format off
  const float alpha_matrix[] = {
      0, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, 0, 1,
  };
  // clang-format on
  DlMatrixColorFilter alpha_color_filter(alpha_matrix);
  // Making sure hiding a problematic ColorFilter as an ImageFilter
  // will generate the same behavior as setting it as a ColorFilter

  DlColorFilterImageFilter color_filter_image_filter(alpha_color_filter);
  {
    DisplayListBuilder builder(build_bounds);
    builder.Save();
    DlPaint paint;
    paint.setImageFilter(&color_filter_image_filter);
    builder.DrawRect(rect, paint);
    builder.Restore();
    sk_sp<DisplayList> display_list1 = builder.Build();

    DisplayListBuilder builder2(build_bounds);
    DlPaint paint2;
    paint2.setImageFilter(&color_filter_image_filter);
    builder2.DrawRect(rect, paint2);
    sk_sp<DisplayList> display_list2 = builder2.Build();
    ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
  }

  {
    DisplayListBuilder builder(build_bounds);
    builder.Save();
    builder.SaveLayer(&build_bounds);
    DlPaint paint;
    paint.setImageFilter(&color_filter_image_filter);
    builder.DrawRect(rect, paint);
    builder.Restore();
    builder.Restore();
    sk_sp<DisplayList> display_list1 = builder.Build();

    DisplayListBuilder builder2(build_bounds);
    builder2.SaveLayer(&build_bounds);
    DlPaint paint2;
    paint2.setImageFilter(&color_filter_image_filter);
    builder2.DrawRect(rect, paint2);
    builder2.Restore();
    sk_sp<DisplayList> display_list2 = builder2.Build();
    ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
  }
}

TEST_F(DisplayListTest, TransformTriggersDeferredSave) {
  DisplayListBuilder builder1;
  builder1.Save();
  builder1.Save();
  builder1.TransformFullPerspective(1, 0, 0, 10,   //
                                    0, 1, 0, 100,  //
                                    0, 0, 1, 0,    //
                                    0, 0, 0, 1);
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  builder1.TransformFullPerspective(1, 0, 0, 10,   //
                                    0, 1, 0, 100,  //
                                    0, 0, 1, 0,    //
                                    0, 0, 0, 1);
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.Save();
  builder2.TransformFullPerspective(1, 0, 0, 10,   //
                                    0, 1, 0, 100,  //
                                    0, 0, 1, 0,    //
                                    0, 0, 0, 1);
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  builder2.Restore();
  builder2.Save();
  builder2.TransformFullPerspective(1, 0, 0, 10,   //
                                    0, 1, 0, 100,  //
                                    0, 0, 1, 0,    //
                                    0, 0, 0, 1);
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  builder2.Restore();
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST_F(DisplayListTest, Transform2DTriggersDeferredSave) {
  DisplayListBuilder builder1;
  builder1.Save();
  builder1.Save();
  builder1.Transform2DAffine(0, 1, 12, 1, 0, 33);
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  builder1.Restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.Save();
  builder2.Transform2DAffine(0, 1, 12, 1, 0, 33);
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  builder2.Restore();
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST_F(DisplayListTest, TransformPerspectiveTriggersDeferredSave) {
  DisplayListBuilder builder1;
  builder1.Save();
  builder1.Save();
  builder1.TransformFullPerspective(0, 1, 0, 12,  //
                                    1, 0, 0, 33,  //
                                    3, 2, 5, 29,  //
                                    0, 0, 0, 12);
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  builder1.Restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.Save();
  builder2.TransformFullPerspective(0, 1, 0, 12,  //
                                    1, 0, 0, 33,  //
                                    3, 2, 5, 29,  //
                                    0, 0, 0, 12);
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  builder2.Restore();
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST_F(DisplayListTest, ResetTransformTriggersDeferredSave) {
  DisplayListBuilder builder1;
  builder1.Save();
  builder1.Save();
  builder1.TransformReset();
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  builder1.Restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.Save();
  builder2.TransformReset();
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  builder2.Restore();
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST_F(DisplayListTest, SkewTriggersDeferredSave) {
  DisplayListBuilder builder1;
  builder1.Save();
  builder1.Save();
  builder1.Skew(10, 10);
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  builder1.Restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.Save();
  builder2.Skew(10, 10);
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  builder2.Restore();
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST_F(DisplayListTest, TranslateTriggersDeferredSave) {
  DisplayListBuilder builder1;
  builder1.Save();
  builder1.Save();
  builder1.Translate(10, 10);
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  builder1.Restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.Save();
  builder2.Translate(10, 10);
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  builder2.Restore();
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST_F(DisplayListTest, ScaleTriggersDeferredSave) {
  DisplayListBuilder builder1;
  builder1.Save();
  builder1.Save();
  builder1.Scale(0.5, 0.5);
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  builder1.Restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.Save();
  builder2.Scale(0.5, 0.5);
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  builder2.Restore();
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST_F(DisplayListTest, ClipRectTriggersDeferredSave) {
  DisplayListBuilder builder1;
  builder1.Save();
  builder1.Save();
  builder1.ClipRect(SkRect::MakeLTRB(0, 0, 100, 100), ClipOp::kIntersect, true);
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  builder1.TransformFullPerspective(1, 0, 0, 0,  //
                                    0, 1, 0, 0,  //
                                    0, 0, 1, 0,  //
                                    0, 0, 0, 1);
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.Save();
  builder2.ClipRect(SkRect::MakeLTRB(0, 0, 100, 100), ClipOp::kIntersect, true);
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  builder2.Restore();
  builder2.TransformFullPerspective(1, 0, 0, 0,  //
                                    0, 1, 0, 0,  //
                                    0, 0, 1, 0,  //
                                    0, 0, 0, 1);
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST_F(DisplayListTest, ClipRRectTriggersDeferredSave) {
  DisplayListBuilder builder1;
  builder1.Save();
  builder1.Save();
  builder1.ClipRRect(kTestRRect, ClipOp::kIntersect, true);

  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  builder1.TransformFullPerspective(1, 0, 0, 0,  //
                                    0, 1, 0, 0,  //
                                    0, 0, 1, 0,  //
                                    0, 0, 0, 1);
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.Save();
  builder2.ClipRRect(kTestRRect, ClipOp::kIntersect, true);

  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  builder2.Restore();
  builder2.TransformFullPerspective(1, 0, 0, 0,  //
                                    0, 1, 0, 0,  //
                                    0, 0, 1, 0,  //
                                    0, 0, 0, 1);
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST_F(DisplayListTest, ClipPathTriggersDeferredSave) {
  DisplayListBuilder builder1;
  builder1.Save();
  builder1.Save();
  builder1.ClipPath(kTestPath1, ClipOp::kIntersect, true);
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  builder1.TransformFullPerspective(1, 0, 0, 0,  //
                                    0, 1, 0, 0,  //
                                    0, 0, 1, 0,  //
                                    0, 0, 0, 1);
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.Save();
  builder2.ClipPath(kTestPath1, ClipOp::kIntersect, true);
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  builder2.Restore();
  builder2.TransformFullPerspective(1, 0, 0, 0,  //
                                    0, 1, 0, 0,  //
                                    0, 0, 1, 0,  //
                                    0, 0, 0, 1);
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST_F(DisplayListTest, NOPTranslateDoesNotTriggerDeferredSave) {
  DisplayListBuilder builder1;
  builder1.Save();
  builder1.Save();
  builder1.Translate(0, 0);
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST_F(DisplayListTest, NOPScaleDoesNotTriggerDeferredSave) {
  DisplayListBuilder builder1;
  builder1.Save();
  builder1.Save();
  builder1.Scale(1.0, 1.0);
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST_F(DisplayListTest, NOPRotationDoesNotTriggerDeferredSave) {
  DisplayListBuilder builder1;
  builder1.Save();
  builder1.Save();
  builder1.Rotate(360);
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST_F(DisplayListTest, NOPSkewDoesNotTriggerDeferredSave) {
  DisplayListBuilder builder1;
  builder1.Save();
  builder1.Save();
  builder1.Skew(0, 0);
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST_F(DisplayListTest, NOPTransformDoesNotTriggerDeferredSave) {
  DisplayListBuilder builder1;
  builder1.Save();
  builder1.Save();
  builder1.TransformFullPerspective(1, 0, 0, 0,  //
                                    0, 1, 0, 0,  //
                                    0, 0, 1, 0,  //
                                    0, 0, 0, 1);
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  builder1.TransformFullPerspective(1, 0, 0, 0,  //
                                    0, 1, 0, 0,  //
                                    0, 0, 1, 0,  //
                                    0, 0, 0, 1);
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST_F(DisplayListTest, NOPTransform2DDoesNotTriggerDeferredSave) {
  DisplayListBuilder builder1;
  builder1.Save();
  builder1.Save();
  builder1.Transform2DAffine(1, 0, 0, 0, 1, 0);
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST_F(DisplayListTest, NOPTransformFullPerspectiveDoesNotTriggerDeferredSave) {
  {
    DisplayListBuilder builder1;
    builder1.Save();
    builder1.Save();
    builder1.TransformFullPerspective(1, 0, 0, 0,  //
                                      0, 1, 0, 0,  //
                                      0, 0, 1, 0,  //
                                      0, 0, 0, 1);
    builder1.DrawRect({0, 0, 100, 100}, DlPaint());
    builder1.Restore();
    builder1.DrawRect({0, 0, 100, 100}, DlPaint());
    builder1.Restore();
    auto display_list1 = builder1.Build();

    DisplayListBuilder builder2;
    builder2.DrawRect({0, 0, 100, 100}, DlPaint());
    builder2.DrawRect({0, 0, 100, 100}, DlPaint());
    auto display_list2 = builder2.Build();

    ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
  }

  {
    DisplayListBuilder builder1;
    builder1.Save();
    builder1.Save();
    builder1.TransformFullPerspective(1, 0, 0, 0,  //
                                      0, 1, 0, 0,  //
                                      0, 0, 1, 0,  //
                                      0, 0, 0, 1);
    builder1.TransformReset();
    builder1.DrawRect({0, 0, 100, 100}, DlPaint());
    builder1.Restore();
    builder1.DrawRect({0, 0, 100, 100}, DlPaint());
    builder1.Restore();
    auto display_list1 = builder1.Build();

    DisplayListBuilder builder2;
    builder2.Save();
    builder2.TransformReset();
    builder2.DrawRect({0, 0, 100, 100}, DlPaint());
    builder2.Restore();
    builder2.DrawRect({0, 0, 100, 100}, DlPaint());

    auto display_list2 = builder2.Build();

    ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
  }
}

TEST_F(DisplayListTest, NOPClipDoesNotTriggerDeferredSave) {
  DisplayListBuilder builder1;
  builder1.Save();
  builder1.Save();
  builder1.ClipRect(SkRect::MakeLTRB(0, SK_ScalarNaN, SK_ScalarNaN, 0),
                    ClipOp::kIntersect, true);
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  builder1.DrawRect({0, 0, 100, 100}, DlPaint());
  builder1.Restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  builder2.DrawRect({0, 0, 100, 100}, DlPaint());
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST_F(DisplayListTest, RTreeOfClippedSaveLayerFilterScene) {
  DisplayListBuilder builder(/*prepare_rtree=*/true);
  // blur filter with sigma=1 expands by 30 on all sides
  auto filter = DlBlurImageFilter(10.0, 10.0, DlTileMode::kClamp);
  DlPaint default_paint = DlPaint();
  DlPaint filter_paint = DlPaint().setImageFilter(&filter);
  builder.DrawRect({10, 10, 20, 20}, default_paint);
  builder.ClipRect({50, 50, 60, 60}, ClipOp::kIntersect, false);
  builder.SaveLayer(nullptr, &filter_paint);
  // the following rectangle will be expanded to 23,23,87,87
  // by the saveLayer filter during the restore operation
  // but it will then be clipped to 50,50,60,60
  builder.DrawRect({53, 53, 57, 57}, default_paint);
  builder.Restore();
  auto display_list = builder.Build();
  auto rtree = display_list->rtree();
  std::vector<SkRect> rects = {
      {10, 10, 20, 20},
      {50, 50, 60, 60},
  };

  // Missing all drawRect calls
  test_rtree(rtree, {5, 5, 10, 10}, rects, {});
  test_rtree(rtree, {20, 20, 25, 25}, rects, {});
  test_rtree(rtree, {45, 45, 50, 50}, rects, {});
  test_rtree(rtree, {60, 60, 65, 65}, rects, {});

  // Hitting just 1 of the drawRects
  test_rtree(rtree, {5, 5, 11, 11}, rects, {0});
  test_rtree(rtree, {19, 19, 25, 25}, rects, {0});
  test_rtree(rtree, {45, 45, 51, 51}, rects, {1});
  test_rtree(rtree, {59, 59, 65, 65}, rects, {1});

  // Hitting both drawRect calls
  test_rtree(rtree, {19, 19, 51, 51}, rects, {0, 1});
}

TEST_F(DisplayListTest, RTreeRenderCulling) {
  DisplayListBuilder main_builder(true);
  main_builder.DrawRect({0, 0, 10, 10}, DlPaint());
  main_builder.DrawRect({20, 0, 30, 10}, DlPaint());
  main_builder.DrawRect({0, 20, 10, 30}, DlPaint());
  main_builder.DrawRect({20, 20, 30, 30}, DlPaint());
  auto main = main_builder.Build();

  auto test = [main](SkIRect cull_rect, const sk_sp<DisplayList>& expected) {
    {  // Test SkIRect culling
      DisplayListBuilder culling_builder;
      main->Dispatch(ToReceiver(culling_builder), cull_rect);

      EXPECT_TRUE(DisplayListsEQ_Verbose(culling_builder.Build(), expected));
    }

    {  // Test SkRect culling
      DisplayListBuilder culling_builder;
      main->Dispatch(ToReceiver(culling_builder), SkRect::Make(cull_rect));

      EXPECT_TRUE(DisplayListsEQ_Verbose(culling_builder.Build(), expected));
    }
  };

  {  // No rects
    SkIRect cull_rect = {11, 11, 19, 19};

    DisplayListBuilder expected_builder;
    auto expected = expected_builder.Build();

    test(cull_rect, expected);
  }

  {  // Rect 1
    SkIRect cull_rect = {9, 9, 19, 19};

    DisplayListBuilder expected_builder;
    expected_builder.DrawRect({0, 0, 10, 10}, DlPaint());
    auto expected = expected_builder.Build();

    test(cull_rect, expected);
  }

  {  // Rect 2
    SkIRect cull_rect = {11, 9, 21, 19};

    DisplayListBuilder expected_builder;
    expected_builder.DrawRect({20, 0, 30, 10}, DlPaint());
    auto expected = expected_builder.Build();

    test(cull_rect, expected);
  }

  {  // Rect 3
    SkIRect cull_rect = {9, 11, 19, 21};

    DisplayListBuilder expected_builder;
    expected_builder.DrawRect({0, 20, 10, 30}, DlPaint());
    auto expected = expected_builder.Build();

    test(cull_rect, expected);
  }

  {  // Rect 4
    SkIRect cull_rect = {11, 11, 21, 21};

    DisplayListBuilder expected_builder;
    expected_builder.DrawRect({20, 20, 30, 30}, DlPaint());
    auto expected = expected_builder.Build();

    test(cull_rect, expected);
  }

  {  // All 4 rects
    SkIRect cull_rect = {9, 9, 21, 21};

    test(cull_rect, main);
  }
}

TEST_F(DisplayListTest, DrawSaveDrawCannotInheritOpacity) {
  DisplayListBuilder builder;
  builder.DrawCircle({10, 10}, 5, DlPaint());
  builder.Save();
  builder.ClipRect({0, 0, 20, 20}, DlCanvas::ClipOp::kIntersect, false);
  builder.DrawRect({5, 5, 15, 15}, DlPaint());
  builder.Restore();
  auto display_list = builder.Build();

  ASSERT_FALSE(display_list->can_apply_group_opacity());
}

TEST_F(DisplayListTest, DrawUnorderedRect) {
  auto renderer = [](DlCanvas& canvas, DlPaint& paint, SkRect& rect) {
    canvas.DrawRect(rect, paint);
  };
  check_inverted_bounds(renderer, "DrawRect");
}

TEST_F(DisplayListTest, DrawUnorderedRoundRect) {
  auto renderer = [](DlCanvas& canvas, DlPaint& paint, SkRect& rect) {
    canvas.DrawRRect(SkRRect::MakeRectXY(rect, 2.0f, 2.0f), paint);
  };
  check_inverted_bounds(renderer, "DrawRoundRect");
}

TEST_F(DisplayListTest, DrawUnorderedOval) {
  auto renderer = [](DlCanvas& canvas, DlPaint& paint, SkRect& rect) {
    canvas.DrawOval(rect, paint);
  };
  check_inverted_bounds(renderer, "DrawOval");
}

TEST_F(DisplayListTest, DrawUnorderedRectangularPath) {
  auto renderer = [](DlCanvas& canvas, DlPaint& paint, SkRect& rect) {
    canvas.DrawPath(SkPath().addRect(rect), paint);
  };
  check_inverted_bounds(renderer, "DrawRectangularPath");
}

TEST_F(DisplayListTest, DrawUnorderedOvalPath) {
  auto renderer = [](DlCanvas& canvas, DlPaint& paint, SkRect& rect) {
    canvas.DrawPath(SkPath().addOval(rect), paint);
  };
  check_inverted_bounds(renderer, "DrawOvalPath");
}

TEST_F(DisplayListTest, DrawUnorderedRoundRectPathCW) {
  auto renderer = [](DlCanvas& canvas, DlPaint& paint, SkRect& rect) {
    SkPath path = SkPath()  //
                      .addRoundRect(rect, 2.0f, 2.0f, SkPathDirection::kCW);
    canvas.DrawPath(path, paint);
  };
  check_inverted_bounds(renderer, "DrawRoundRectPath Clockwise");
}

TEST_F(DisplayListTest, DrawUnorderedRoundRectPathCCW) {
  auto renderer = [](DlCanvas& canvas, DlPaint& paint, SkRect& rect) {
    SkPath path = SkPath()  //
                      .addRoundRect(rect, 2.0f, 2.0f, SkPathDirection::kCCW);
    canvas.DrawPath(path, paint);
  };
  check_inverted_bounds(renderer, "DrawRoundRectPath Counter-Clockwise");
}

TEST_F(DisplayListTest, NopOperationsOmittedFromRecords) {
  auto run_tests = [](const std::string& name,
                      void init(DisplayListBuilder & builder, DlPaint & paint),
                      uint32_t expected_op_count = 0u) {
    auto run_one_test =
        [init](const std::string& name,
               void build(DisplayListBuilder & builder, DlPaint & paint),
               uint32_t expected_op_count = 0u) {
          DisplayListBuilder builder;
          DlPaint paint;
          init(builder, paint);
          build(builder, paint);
          auto list = builder.Build();
          if (list->op_count() != expected_op_count) {
            FML_LOG(ERROR) << *list;
          }
          ASSERT_EQ(list->op_count(), expected_op_count) << name;
          ASSERT_TRUE(list->bounds().isEmpty()) << name;
        };
    run_one_test(
        name + " DrawColor",
        [](DisplayListBuilder& builder, DlPaint& paint) {
          builder.DrawColor(paint.getColor(), paint.getBlendMode());
        },
        expected_op_count);
    run_one_test(
        name + " DrawPaint",
        [](DisplayListBuilder& builder, DlPaint& paint) {
          builder.DrawPaint(paint);
        },
        expected_op_count);
    run_one_test(
        name + " DrawRect",
        [](DisplayListBuilder& builder, DlPaint& paint) {
          builder.DrawRect({10, 10, 20, 20}, paint);
        },
        expected_op_count);
    run_one_test(
        name + " Other Draw Ops",
        [](DisplayListBuilder& builder, DlPaint& paint) {
          builder.DrawLine({10, 10}, {20, 20}, paint);
          builder.DrawOval({10, 10, 20, 20}, paint);
          builder.DrawCircle({50, 50}, 20, paint);
          builder.DrawRRect(SkRRect::MakeRectXY({10, 10, 20, 20}, 5, 5), paint);
          builder.DrawDRRect(SkRRect::MakeRectXY({5, 5, 100, 100}, 5, 5),
                             SkRRect::MakeRectXY({10, 10, 20, 20}, 5, 5),
                             paint);
          builder.DrawPath(kTestPath1, paint);
          builder.DrawArc({10, 10, 20, 20}, 45, 90, true, paint);
          SkPoint pts[] = {{10, 10}, {20, 20}};
          builder.DrawPoints(PointMode::kLines, 2, pts, paint);
          builder.DrawVertices(TestVertices1, DlBlendMode::kSrcOver, paint);
          builder.DrawImage(TestImage1, {10, 10}, DlImageSampling::kLinear,
                            &paint);
          builder.DrawImageRect(TestImage1, SkRect{0.0f, 0.0f, 10.0f, 10.0f},
                                SkRect{10.0f, 10.0f, 25.0f, 25.0f},
                                DlImageSampling::kLinear, &paint);
          builder.DrawImageNine(TestImage1, {10, 10, 20, 20},
                                {10, 10, 100, 100}, DlFilterMode::kLinear,
                                &paint);
          SkRSXform xforms[] = {{1, 0, 10, 10}, {0, 1, 10, 10}};
          SkRect rects[] = {{10, 10, 20, 20}, {10, 20, 30, 20}};
          builder.DrawAtlas(TestImage1, xforms, rects, nullptr, 2,
                            DlBlendMode::kSrcOver, DlImageSampling::kLinear,
                            nullptr, &paint);
          builder.DrawTextBlob(TestBlob1, 10, 10, paint);

          // Dst mode eliminates most rendering ops except for
          // the following two, so we'll prune those manually...
          if (paint.getBlendMode() != DlBlendMode::kDst) {
            builder.DrawDisplayList(TestDisplayList1, paint.getOpacity());
            builder.DrawShadow(kTestPath1, paint.getColor(), 1, true, 1);
          }
        },
        expected_op_count);
    run_one_test(
        name + " SaveLayer",
        [](DisplayListBuilder& builder, DlPaint& paint) {
          builder.SaveLayer(nullptr, &paint, nullptr);
          builder.DrawRect({10, 10, 20, 20}, DlPaint());
          builder.Restore();
        },
        expected_op_count);
    run_one_test(
        name + " inside Save",
        [](DisplayListBuilder& builder, DlPaint& paint) {
          builder.Save();
          builder.DrawRect({10, 10, 20, 20}, paint);
          builder.Restore();
        },
        expected_op_count);
  };
  run_tests("transparent color",  //
            [](DisplayListBuilder& builder, DlPaint& paint) {
              paint.setColor(DlColor::kTransparent());
            });
  run_tests("0 alpha",  //
            [](DisplayListBuilder& builder, DlPaint& paint) {
              // The transparent test above already tested transparent
              // black (all 0s), we set White color here so we can test
              // the case of all 1s with a 0 alpha
              paint.setColor(DlColor::kWhite());
              paint.setAlpha(0);
            });
  run_tests("BlendMode::kDst",  //
            [](DisplayListBuilder& builder, DlPaint& paint) {
              paint.setBlendMode(DlBlendMode::kDst);
            });
  run_tests("Empty rect clip",  //
            [](DisplayListBuilder& builder, DlPaint& paint) {
              builder.ClipRect(SkRect::MakeEmpty(), ClipOp::kIntersect, false);
            });
  run_tests("Empty rrect clip",  //
            [](DisplayListBuilder& builder, DlPaint& paint) {
              builder.ClipRRect(SkRRect::MakeEmpty(), ClipOp::kIntersect,
                                false);
            });
  run_tests("Empty path clip",  //
            [](DisplayListBuilder& builder, DlPaint& paint) {
              builder.ClipPath(SkPath(), ClipOp::kIntersect, false);
            });
  run_tests("Transparent SaveLayer",  //
            [](DisplayListBuilder& builder, DlPaint& paint) {
              DlPaint save_paint;
              save_paint.setColor(DlColor::kTransparent());
              builder.SaveLayer(nullptr, &save_paint);
            });
  run_tests("0 alpha SaveLayer",  //
            [](DisplayListBuilder& builder, DlPaint& paint) {
              DlPaint save_paint;
              // The transparent test above already tested transparent
              // black (all 0s), we set White color here so we can test
              // the case of all 1s with a 0 alpha
              save_paint.setColor(DlColor::kWhite());
              save_paint.setAlpha(0);
              builder.SaveLayer(nullptr, &save_paint);
            });
  run_tests("Dst blended SaveLayer",  //
            [](DisplayListBuilder& builder, DlPaint& paint) {
              DlPaint save_paint;
              save_paint.setBlendMode(DlBlendMode::kDst);
              builder.SaveLayer(nullptr, &save_paint);
            });
  run_tests(
      "Nop inside SaveLayer",
      [](DisplayListBuilder& builder, DlPaint& paint) {
        builder.SaveLayer(nullptr, nullptr);
        paint.setBlendMode(DlBlendMode::kDst);
      },
      2u);
  run_tests("DrawImage inside Culled SaveLayer",  //
            [](DisplayListBuilder& builder, DlPaint& paint) {
              DlPaint save_paint;
              save_paint.setColor(DlColor::kTransparent());
              builder.SaveLayer(nullptr, &save_paint);
              builder.DrawImage(TestImage1, {10, 10}, DlImageSampling::kLinear);
            });
}

}  // namespace testing
}  // namespace flutter
