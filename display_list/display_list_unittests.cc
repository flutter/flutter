// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <string>
#include <unordered_set>
#include <utility>
#include <vector>

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/display_list_blend_mode.h"
#include "flutter/display_list/display_list_builder.h"
#include "flutter/display_list/display_list_paint.h"
#include "flutter/display_list/display_list_rtree.h"
#include "flutter/display_list/display_list_utils.h"
#include "flutter/display_list/testing/dl_test_snippets.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/math.h"
#include "flutter/testing/display_list_testing.h"
#include "flutter/testing/testing.h"

#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {
namespace testing {

static std::vector<testing::DisplayListInvocationGroup> allGroups =
    CreateAllGroups();

using ClipOp = DlCanvas::ClipOp;
using PointMode = DlCanvas::PointMode;

TEST(DisplayList, BuilderCanBeReused) {
  DisplayListBuilder builder(kTestBounds);
  builder.DrawRect(kTestBounds, DlPaint());
  auto dl = builder.Build();
  builder.DrawRect(kTestBounds, DlPaint());
  auto dl2 = builder.Build();
  ASSERT_TRUE(dl->Equals(dl2));
}

TEST(DisplayList, BuilderBoundsTransformComparedToSkia) {
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

TEST(DisplayList, BuilderInitialClipBounds) {
  SkRect cull_rect = SkRect::MakeWH(100, 100);
  SkRect clip_bounds = SkRect::MakeWH(100, 100);
  DisplayListBuilder builder(cull_rect);
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds);
}

TEST(DisplayList, BuilderInitialClipBoundsNaN) {
  SkRect cull_rect = SkRect::MakeWH(SK_ScalarNaN, SK_ScalarNaN);
  SkRect clip_bounds = SkRect::MakeEmpty();
  DisplayListBuilder builder(cull_rect);
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds);
}

TEST(DisplayList, BuilderClipBoundsAfterClipRect) {
  SkRect cull_rect = SkRect::MakeWH(100, 100);
  SkRect clip_rect = SkRect::MakeLTRB(10, 10, 20, 20);
  SkRect clip_bounds = SkRect::MakeLTRB(10, 10, 20, 20);
  DisplayListBuilder builder(cull_rect);
  builder.clipRect(clip_rect, ClipOp::kIntersect, false);
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds);
}

TEST(DisplayList, BuilderClipBoundsAfterClipRRect) {
  SkRect cull_rect = SkRect::MakeWH(100, 100);
  SkRect clip_rect = SkRect::MakeLTRB(10, 10, 20, 20);
  SkRRect clip_rrect = SkRRect::MakeRectXY(clip_rect, 2, 2);
  SkRect clip_bounds = SkRect::MakeLTRB(10, 10, 20, 20);
  DisplayListBuilder builder(cull_rect);
  builder.clipRRect(clip_rrect, ClipOp::kIntersect, false);
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds);
}

TEST(DisplayList, BuilderClipBoundsAfterClipPath) {
  SkRect cull_rect = SkRect::MakeWH(100, 100);
  SkPath clip_path = SkPath().addRect(10, 10, 15, 15).addRect(15, 15, 20, 20);
  SkRect clip_bounds = SkRect::MakeLTRB(10, 10, 20, 20);
  DisplayListBuilder builder(cull_rect);
  builder.clipPath(clip_path, ClipOp::kIntersect, false);
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds);
}

TEST(DisplayList, BuilderInitialClipBoundsNonZero) {
  SkRect cull_rect = SkRect::MakeLTRB(10, 10, 100, 100);
  SkRect clip_bounds = SkRect::MakeLTRB(10, 10, 100, 100);
  DisplayListBuilder builder(cull_rect);
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds);
}

TEST(DisplayList, SingleOpSizes) {
  for (auto& group : allGroups) {
    for (size_t i = 0; i < group.variants.size(); i++) {
      auto& invocation = group.variants[i];
      sk_sp<DisplayList> dl = invocation.Build();
      auto desc = group.op_name + "(variant " + std::to_string(i + 1) + ")";
      ASSERT_EQ(dl->op_count(false), invocation.op_count()) << desc;
      ASSERT_EQ(dl->bytes(false), invocation.byte_count()) << desc;
    }
  }
}

TEST(DisplayList, SingleOpDisplayListsNotEqualEmpty) {
  sk_sp<DisplayList> empty = DisplayListBuilder().Build();
  for (auto& group : allGroups) {
    for (size_t i = 0; i < group.variants.size(); i++) {
      sk_sp<DisplayList> dl = group.variants[i].Build();
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

TEST(DisplayList, SingleOpDisplayListsRecapturedAreEqual) {
  for (auto& group : allGroups) {
    for (size_t i = 0; i < group.variants.size(); i++) {
      sk_sp<DisplayList> dl = group.variants[i].Build();
      // Verify recapturing the replay of the display list is Equals()
      // when dispatching directly from the DL to another builder
      DisplayListBuilder builder;
      dl->Dispatch(builder.asDispatcher());
      sk_sp<DisplayList> copy = builder.Build();
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

TEST(DisplayList, SingleOpDisplayListsCompareToEachOther) {
  for (auto& group : allGroups) {
    std::vector<sk_sp<DisplayList>> lists_a;
    std::vector<sk_sp<DisplayList>> lists_b;
    for (size_t i = 0; i < group.variants.size(); i++) {
      lists_a.push_back(group.variants[i].Build());
      lists_b.push_back(group.variants[i].Build());
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

TEST(DisplayList, SingleOpDisplayListsAreEqualWhetherOrNotToPrepareRtree) {
  for (auto& group : allGroups) {
    for (size_t i = 0; i < group.variants.size(); i++) {
      DisplayListBuilder builder1(/*prepare_rtree=*/false);
      DisplayListBuilder builder2(/*prepare_rtree=*/true);
      group.variants[i].invoker(builder1);
      group.variants[i].invoker(builder2);
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

TEST(DisplayList, FullRotationsAreNop) {
  DisplayListBuilder builder;
  builder.rotate(0);
  builder.rotate(360);
  builder.rotate(720);
  builder.rotate(1080);
  builder.rotate(1440);
  sk_sp<DisplayList> dl = builder.Build();
  ASSERT_EQ(dl->bytes(false), sizeof(DisplayList));
  ASSERT_EQ(dl->bytes(true), sizeof(DisplayList));
  ASSERT_EQ(dl->op_count(false), 0u);
  ASSERT_EQ(dl->op_count(true), 0u);
}

TEST(DisplayList, AllBlendModeNops) {
  DisplayListBuilder builder;
  builder.setBlendMode(DlBlendMode::kSrcOver);
  builder.setBlender(nullptr);
  sk_sp<DisplayList> dl = builder.Build();
  ASSERT_EQ(dl->bytes(false), sizeof(DisplayList));
  ASSERT_EQ(dl->bytes(true), sizeof(DisplayList));
  ASSERT_EQ(dl->op_count(false), 0u);
  ASSERT_EQ(dl->op_count(true), 0u);
}

static sk_sp<DisplayList> Build(size_t g_index, size_t v_index) {
  DisplayListBuilder builder;
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
    invocation.invoker(builder);
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

TEST(DisplayList, DisplayListsWithVaryingOpComparisons) {
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

TEST(DisplayList, DisplayListSaveLayerBoundsWithAlphaFilter) {
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

  {
    // No tricky stuff, just verifying drawing a rect produces rect bounds
    DisplayListBuilder builder(build_bounds);
    builder.saveLayer(&save_bounds, true);
    builder.drawRect(rect);
    builder.restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), rect);
  }

  {
    // Now checking that a normal color filter still produces rect bounds
    DisplayListBuilder builder(build_bounds);
    builder.setColorFilter(&base_color_filter);
    builder.saveLayer(&save_bounds, true);
    builder.setColorFilter(nullptr);
    builder.drawRect(rect);
    builder.restore();
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
    p1.setColorFilter(alpha_color_filter.skia_object());
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
    builder.setColorFilter(&alpha_color_filter);
    builder.saveLayer(&save_bounds, true);
    builder.setColorFilter(nullptr);
    builder.drawRect(rect);
    builder.restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), build_bounds);
  }

  {
    // Verifying that the save layer bounds are not relevant
    // to the behavior in the previous example
    DisplayListBuilder builder(build_bounds);
    builder.setColorFilter(&alpha_color_filter);
    builder.saveLayer(nullptr, true);
    builder.setColorFilter(nullptr);
    builder.drawRect(rect);
    builder.restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), build_bounds);
  }

  {
    // Making sure hiding a ColorFilter as an ImageFilter will
    // generate the same behavior as setting it as a ColorFilter
    DisplayListBuilder builder(build_bounds);
    DlColorFilterImageFilter color_filter_image_filter(base_color_filter);
    builder.setImageFilter(&color_filter_image_filter);
    builder.saveLayer(&save_bounds, true);
    builder.setImageFilter(nullptr);
    builder.drawRect(rect);
    builder.restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), rect);
  }

  {
    // Making sure hiding a problematic ColorFilter as an ImageFilter
    // will generate the same behavior as setting it as a ColorFilter
    DisplayListBuilder builder(build_bounds);
    DlColorFilterImageFilter color_filter_image_filter(alpha_color_filter);
    builder.setImageFilter(&color_filter_image_filter);
    builder.saveLayer(&save_bounds, true);
    builder.setImageFilter(nullptr);
    builder.drawRect(rect);
    builder.restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), build_bounds);
  }

  {
    // Same as above (ImageFilter hiding ColorFilter) with no save bounds
    DisplayListBuilder builder(build_bounds);
    DlColorFilterImageFilter color_filter_image_filter(alpha_color_filter);
    builder.setImageFilter(&color_filter_image_filter);
    builder.saveLayer(nullptr, true);
    builder.setImageFilter(nullptr);
    builder.drawRect(rect);
    builder.restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), build_bounds);
  }

  {
    // Testing behavior with an unboundable blend mode
    DisplayListBuilder builder(build_bounds);
    builder.setBlendMode(DlBlendMode::kClear);
    builder.saveLayer(&save_bounds, true);
    builder.setBlendMode(DlBlendMode::kSrcOver);
    builder.drawRect(rect);
    builder.restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), build_bounds);
  }

  {
    // Same as previous with no save bounds
    DisplayListBuilder builder(build_bounds);
    builder.setBlendMode(DlBlendMode::kClear);
    builder.saveLayer(nullptr, true);
    builder.setBlendMode(DlBlendMode::kSrcOver);
    builder.drawRect(rect);
    builder.restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), build_bounds);
  }
}

TEST(DisplayList, NestedOpCountMetricsSameAsSkPicture) {
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
      builder.setColor(((x + y) % 20) == 10 ? SK_ColorRED : SK_ColorBLUE);
      builder.drawRect(SkRect::MakeXYWH(x, y, 80, 80));
    }
  }
  DisplayListBuilder outer_builder(SkRect::MakeWH(150, 100));
  outer_builder.drawDisplayList(builder.Build());

  auto display_list = outer_builder.Build();
  ASSERT_EQ(display_list->op_count(), 1u);
  ASSERT_EQ(display_list->op_count(true), 36u);

  ASSERT_EQ(picture->approximateOpCount(),
            static_cast<int>(display_list->op_count()));
  ASSERT_EQ(picture->approximateOpCount(true),
            static_cast<int>(display_list->op_count(true)));
}

class AttributeRefTester {
 public:
  virtual void setRefToPaint(SkPaint& paint) const = 0;
  virtual void setRefToDisplayList(DisplayListBuilder& builder) const = 0;
  virtual bool ref_is_unique() const = 0;

  void testDisplayList() {
    {
      DisplayListBuilder builder;
      setRefToDisplayList(builder);
      builder.drawRect(SkRect::MakeLTRB(50, 50, 100, 100));
      ASSERT_FALSE(ref_is_unique());
    }
    ASSERT_TRUE(ref_is_unique());
  }
  void testPaint() {
    {
      SkPaint paint;
      setRefToPaint(paint);
      ASSERT_FALSE(ref_is_unique());
    }
    ASSERT_TRUE(ref_is_unique());
  }

  void test() {
    testDisplayList();
    testPaint();
  }
};

TEST(DisplayList, DisplayListBlenderRefHandling) {
  class BlenderRefTester : public virtual AttributeRefTester {
   public:
    void setRefToPaint(SkPaint& paint) const override {
      paint.setBlender(blender_);
    }
    void setRefToDisplayList(DisplayListBuilder& builder) const override {
      builder.setBlender(blender_);
    }
    bool ref_is_unique() const override { return blender_->unique(); }

   private:
    sk_sp<SkBlender> blender_ =
        SkBlenders::Arithmetic(0.25, 0.25, 0.25, 0.25, true);
  };

  BlenderRefTester tester;
  tester.test();
  ASSERT_TRUE(tester.ref_is_unique());
}

TEST(DisplayList, DisplayListFullPerspectiveTransformHandling) {
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
    builder.transformFullPerspective(
        // clang-format off
         1,  2,  3,  4,
         5,  6,  7,  8,
         9, 10, 11, 12,
        13, 14, 15, 16
        // clang-format on
    );
    sk_sp<DisplayList> display_list = builder.Build();
    sk_sp<SkSurface> surface = SkSurface::MakeRasterN32Premul(10, 10);
    SkCanvas* canvas = surface->getCanvas();
    display_list->RenderTo(canvas);
    SkM44 dl_matrix = canvas->getLocalToDevice();
    ASSERT_EQ(sk_matrix, dl_matrix);
  }
  {  // Next test !=
    DisplayListBuilder builder;
    // builder.transformFullPerspective takes row-major order
    builder.transformFullPerspective(
        // clang-format off
         1,  5,  9, 13,
         2,  6,  7, 11,
         3,  7, 11, 15,
         4,  8, 12, 16
        // clang-format on
    );
    sk_sp<DisplayList> display_list = builder.Build();
    sk_sp<SkSurface> surface = SkSurface::MakeRasterN32Premul(10, 10);
    SkCanvas* canvas = surface->getCanvas();
    display_list->RenderTo(canvas);
    SkM44 dl_matrix = canvas->getLocalToDevice();
    ASSERT_NE(sk_matrix, dl_matrix);
  }
}

TEST(DisplayList, DisplayListTransformResetHandling) {
  DisplayListBuilder builder;
  builder.scale(20.0, 20.0);
  builder.transformReset();
  auto list = builder.Build();
  ASSERT_NE(list, nullptr);
  sk_sp<SkSurface> surface = SkSurface::MakeRasterN32Premul(10, 10);
  SkCanvas* canvas = surface->getCanvas();
  list->RenderTo(canvas);
  ASSERT_TRUE(canvas->getTotalMatrix().isIdentity());
}

TEST(DisplayList, SingleOpsMightSupportGroupOpacityWithOrWithoutBlendMode) {
  auto run_tests = [](const std::string& name,
                      void build(DisplayListBuilder & builder),
                      bool expect_for_op, bool expect_with_kSrc) {
    {
      // First test is the draw op, by itself
      // (usually supports group opacity)
      DisplayListBuilder builder;
      build(builder);
      auto display_list = builder.Build();
      EXPECT_EQ(display_list->can_apply_group_opacity(), expect_for_op)
          << "{" << std::endl
          << "  " << name << std::endl
          << "}";
    }
    {
      // Second test i the draw op with kSrc,
      // (usually fails group opacity)
      DisplayListBuilder builder;
      builder.setBlendMode(DlBlendMode::kSrc);
      build(builder);
      auto display_list = builder.Build();
      EXPECT_EQ(display_list->can_apply_group_opacity(), expect_with_kSrc)
          << "{" << std::endl
          << "  builder.setBlendMode(kSrc);" << std::endl
          << "  " << name << std::endl
          << "}";
    }
  };

#define RUN_TESTS(body) \
  run_tests(            \
      #body, [](DisplayListBuilder& builder) { body }, true, false)
#define RUN_TESTS2(body, expect) \
  run_tests(                     \
      #body, [](DisplayListBuilder& builder) { body }, expect, expect)

  RUN_TESTS(builder.drawPaint(););
  RUN_TESTS2(builder.drawColor(SK_ColorRED, DlBlendMode::kSrcOver);, true);
  RUN_TESTS2(builder.drawColor(SK_ColorRED, DlBlendMode::kSrc);, false);
  RUN_TESTS(builder.drawLine({0, 0}, {10, 10}););
  RUN_TESTS(builder.drawRect({0, 0, 10, 10}););
  RUN_TESTS(builder.drawOval({0, 0, 10, 10}););
  RUN_TESTS(builder.drawCircle({10, 10}, 5););
  RUN_TESTS(builder.drawRRect(SkRRect::MakeRectXY({0, 0, 10, 10}, 2, 2)););
  RUN_TESTS(builder.drawDRRect(SkRRect::MakeRectXY({0, 0, 10, 10}, 2, 2),
                               SkRRect::MakeRectXY({2, 2, 8, 8}, 2, 2)););
  RUN_TESTS(builder.drawPath(
      SkPath().addOval({0, 0, 10, 10}).addOval({5, 5, 15, 15})););
  RUN_TESTS(builder.drawArc({0, 0, 10, 10}, 0, math::kPi, true););
  RUN_TESTS2(builder.drawPoints(PointMode::kPoints, TestPointCount, TestPoints);
             , false);
  RUN_TESTS2(builder.drawVertices(TestVertices1, DlBlendMode::kSrc);, false);
  RUN_TESTS(builder.drawImage(TestImage1, {0, 0}, kLinearSampling, true););
  RUN_TESTS2(builder.drawImage(TestImage1, {0, 0}, kLinearSampling, false);
             , true);
  RUN_TESTS(builder.drawImageRect(TestImage1, {10, 10, 20, 20}, {0, 0, 10, 10},
                                  kNearestSampling, true););
  RUN_TESTS2(builder.drawImageRect(TestImage1, {10, 10, 20, 20}, {0, 0, 10, 10},
                                   kNearestSampling, false);
             , true);
  RUN_TESTS(builder.drawImageNine(TestImage2, {20, 20, 30, 30}, {0, 0, 20, 20},
                                  DlFilterMode::kLinear, true););
  RUN_TESTS2(builder.drawImageNine(TestImage2, {20, 20, 30, 30}, {0, 0, 20, 20},
                                   DlFilterMode::kLinear, false);
             , true);
  RUN_TESTS(builder.drawImageLattice(
      TestImage1,
      {kTestDivs1, kTestDivs1, nullptr, 3, 3, &kTestLatticeSrcRect, nullptr},
      {10, 10, 40, 40}, DlFilterMode::kNearest, true););
  RUN_TESTS2(builder.drawImageLattice(
      TestImage1,
      {kTestDivs1, kTestDivs1, nullptr, 3, 3, &kTestLatticeSrcRect, nullptr},
      {10, 10, 40, 40}, DlFilterMode::kNearest, false);
             , true);
  static SkRSXform xforms[] = {{1, 0, 0, 0}, {0, 1, 0, 0}};
  static SkRect texs[] = {{10, 10, 20, 20}, {20, 20, 30, 30}};
  RUN_TESTS2(
      builder.drawAtlas(TestImage1, xforms, texs, nullptr, 2,
                        DlBlendMode::kSrcIn, kNearestSampling, nullptr, true);
      , false);
  RUN_TESTS2(
      builder.drawAtlas(TestImage1, xforms, texs, nullptr, 2,
                        DlBlendMode::kSrcIn, kNearestSampling, nullptr, false);
      , false);
  RUN_TESTS(builder.drawPicture(TestPicture1, nullptr, true););
  RUN_TESTS2(builder.drawPicture(TestPicture1, nullptr, false);, true);
  EXPECT_TRUE(TestDisplayList1->can_apply_group_opacity());
  RUN_TESTS2(builder.drawDisplayList(TestDisplayList1);, true);
  {
    static DisplayListBuilder builder;
    builder.drawRect({0, 0, 10, 10});
    builder.drawRect({5, 5, 15, 15});
    static auto display_list = builder.Build();
    RUN_TESTS2(builder.drawDisplayList(display_list);, false);
  }
  RUN_TESTS(builder.drawTextBlob(TestBlob1, 0, 0););
  RUN_TESTS2(builder.drawShadow(kTestPath1, SK_ColorBLACK, 1.0, false, 1.0);
             , false);

#undef RUN_TESTS2
#undef RUN_TESTS
}

TEST(DisplayList, OverlappingOpsDoNotSupportGroupOpacity) {
  DisplayListBuilder builder;
  for (int i = 0; i < 10; i++) {
    builder.drawRect(SkRect::MakeXYWH(i * 10, 0, 30, 30));
  }
  auto display_list = builder.Build();
  EXPECT_FALSE(display_list->can_apply_group_opacity());
}

TEST(DisplayList, SaveLayerFalseSupportsGroupOpacityWithOverlappingChidren) {
  DisplayListBuilder builder;
  builder.saveLayer(nullptr, false);
  for (int i = 0; i < 10; i++) {
    builder.drawRect(SkRect::MakeXYWH(i * 10, 0, 30, 30));
  }
  builder.restore();
  auto display_list = builder.Build();
  EXPECT_TRUE(display_list->can_apply_group_opacity());
}

TEST(DisplayList, SaveLayerTrueSupportsGroupOpacityWithOverlappingChidren) {
  DisplayListBuilder builder;
  builder.saveLayer(nullptr, true);
  for (int i = 0; i < 10; i++) {
    builder.drawRect(SkRect::MakeXYWH(i * 10, 0, 30, 30));
  }
  builder.restore();
  auto display_list = builder.Build();
  EXPECT_TRUE(display_list->can_apply_group_opacity());
}

TEST(DisplayList, SaveLayerFalseWithSrcBlendSupportsGroupOpacity) {
  DisplayListBuilder builder;
  builder.setBlendMode(DlBlendMode::kSrc);
  builder.saveLayer(nullptr, false);
  builder.drawRect({0, 0, 10, 10});
  builder.restore();
  auto display_list = builder.Build();
  EXPECT_TRUE(display_list->can_apply_group_opacity());
}

TEST(DisplayList, SaveLayerTrueWithSrcBlendDoesNotSupportGroupOpacity) {
  DisplayListBuilder builder;
  builder.setBlendMode(DlBlendMode::kSrc);
  builder.saveLayer(nullptr, true);
  builder.drawRect({0, 0, 10, 10});
  builder.restore();
  auto display_list = builder.Build();
  EXPECT_FALSE(display_list->can_apply_group_opacity());
}

TEST(DisplayList, SaveLayerFalseSupportsGroupOpacityWithChildSrcBlend) {
  DisplayListBuilder builder;
  builder.saveLayer(nullptr, false);
  builder.setBlendMode(DlBlendMode::kSrc);
  builder.drawRect({0, 0, 10, 10});
  builder.restore();
  auto display_list = builder.Build();
  EXPECT_TRUE(display_list->can_apply_group_opacity());
}

TEST(DisplayList, SaveLayerTrueSupportsGroupOpacityWithChildSrcBlend) {
  DisplayListBuilder builder;
  builder.saveLayer(nullptr, true);
  builder.setBlendMode(DlBlendMode::kSrc);
  builder.drawRect({0, 0, 10, 10});
  builder.restore();
  auto display_list = builder.Build();
  EXPECT_TRUE(display_list->can_apply_group_opacity());
}

TEST(DisplayList, SaveLayerBoundsSnapshotsImageFilter) {
  DisplayListBuilder builder;
  builder.saveLayer(nullptr, true);
  builder.drawRect({50, 50, 100, 100});
  // This image filter should be ignored since it was not set before saveLayer
  builder.setImageFilter(&kTestBlurImageFilter1);
  builder.restore();
  SkRect bounds = builder.Build()->bounds();
  EXPECT_EQ(bounds, SkRect::MakeLTRB(50, 50, 100, 100));
}

class SaveLayerOptionsExpector : public virtual Dispatcher,
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

TEST(DisplayList, SaveLayerOneSimpleOpSupportsOpacityOptimization) {
  SaveLayerOptions expected =
      SaveLayerOptions::kWithAttributes.with_can_distribute_opacity();
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  builder.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.saveLayer(nullptr, true);
  builder.drawRect({10, 10, 20, 20});
  builder.restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST(DisplayList, SaveLayerNoAttributesSupportsOpacityOptimization) {
  SaveLayerOptions expected =
      SaveLayerOptions::kNoAttributes.with_can_distribute_opacity();
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  builder.saveLayer(nullptr, false);
  builder.drawRect({10, 10, 20, 20});
  builder.restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST(DisplayList, SaveLayerTwoOverlappingOpsPreventsOpacityOptimization) {
  SaveLayerOptions expected = SaveLayerOptions::kWithAttributes;
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  builder.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.saveLayer(nullptr, true);
  builder.drawRect({10, 10, 20, 20});
  builder.drawRect({15, 15, 25, 25});
  builder.restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST(DisplayList, NestedSaveLayersMightSupportOpacityOptimization) {
  SaveLayerOptions expected1 =
      SaveLayerOptions::kWithAttributes.with_can_distribute_opacity();
  SaveLayerOptions expected2 = SaveLayerOptions::kWithAttributes;
  SaveLayerOptions expected3 =
      SaveLayerOptions::kWithAttributes.with_can_distribute_opacity();
  SaveLayerOptionsExpector expector({expected1, expected2, expected3});

  DisplayListBuilder builder;
  builder.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.saveLayer(nullptr, true);
  builder.saveLayer(nullptr, true);
  builder.drawRect({10, 10, 20, 20});
  builder.saveLayer(nullptr, true);
  builder.drawRect({15, 15, 25, 25});
  builder.restore();
  builder.restore();
  builder.restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 3);
}

TEST(DisplayList, NestedSaveLayersCanBothSupportOpacityOptimization) {
  SaveLayerOptions expected1 =
      SaveLayerOptions::kWithAttributes.with_can_distribute_opacity();
  SaveLayerOptions expected2 =
      SaveLayerOptions::kNoAttributes.with_can_distribute_opacity();
  SaveLayerOptionsExpector expector({expected1, expected2});

  DisplayListBuilder builder;
  builder.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.saveLayer(nullptr, true);
  builder.saveLayer(nullptr, false);
  builder.drawRect({10, 10, 20, 20});
  builder.restore();
  builder.restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 2);
}

TEST(DisplayList, SaveLayerImageFilterPreventsOpacityOptimization) {
  SaveLayerOptions expected = SaveLayerOptions::kWithAttributes;
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  builder.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.setImageFilter(&kTestBlurImageFilter1);
  builder.saveLayer(nullptr, true);
  builder.setImageFilter(nullptr);
  builder.drawRect({10, 10, 20, 20});
  builder.restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST(DisplayList, SaveLayerColorFilterPreventsOpacityOptimization) {
  SaveLayerOptions expected = SaveLayerOptions::kWithAttributes;
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  builder.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.setColorFilter(&kTestMatrixColorFilter1);
  builder.saveLayer(nullptr, true);
  builder.setColorFilter(nullptr);
  builder.drawRect({10, 10, 20, 20});
  builder.restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST(DisplayList, SaveLayerSrcBlendPreventsOpacityOptimization) {
  SaveLayerOptions expected = SaveLayerOptions::kWithAttributes;
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  builder.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.setBlendMode(DlBlendMode::kSrc);
  builder.saveLayer(nullptr, true);
  builder.setBlendMode(DlBlendMode::kSrcOver);
  builder.drawRect({10, 10, 20, 20});
  builder.restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST(DisplayList, SaveLayerImageFilterOnChildSupportsOpacityOptimization) {
  SaveLayerOptions expected =
      SaveLayerOptions::kWithAttributes.with_can_distribute_opacity();
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  builder.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.saveLayer(nullptr, true);
  builder.setImageFilter(&kTestBlurImageFilter1);
  builder.drawRect({10, 10, 20, 20});
  builder.restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST(DisplayList, SaveLayerColorFilterOnChildPreventsOpacityOptimization) {
  SaveLayerOptions expected = SaveLayerOptions::kWithAttributes;
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  builder.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.saveLayer(nullptr, true);
  builder.setColorFilter(&kTestMatrixColorFilter1);
  builder.drawRect({10, 10, 20, 20});
  builder.restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST(DisplayList, SaveLayerSrcBlendOnChildPreventsOpacityOptimization) {
  SaveLayerOptions expected = SaveLayerOptions::kWithAttributes;
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  builder.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.saveLayer(nullptr, true);
  builder.setBlendMode(DlBlendMode::kSrc);
  builder.drawRect({10, 10, 20, 20});
  builder.restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST(DisplayList, FlutterSvgIssue661BoundsWereEmpty) {
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
  {
    builder.save();
    builder.clipRect({0, 0, 100, 100}, ClipOp::kIntersect, true);
    {
      builder.save();
      builder.transform2DAffine(2.17391, 0, -2547.83,  //
                                0, 2.04082, -500);
      {
        builder.save();
        builder.clipRect({1172, 245, 1218, 294}, ClipOp::kIntersect, true);
        {
          builder.saveLayer(nullptr, SaveLayerOptions::kWithAttributes,
                            nullptr);
          {
            builder.save();
            builder.transform2DAffine(1.4375, 0, 1164.09,  //
                                      0, 1.53125, 236.548);
            builder.setAntiAlias(1);
            builder.setColor(0xffffffff);
            builder.drawPath(path1);
            builder.restore();
          }
          {
            builder.save();
            builder.transform2DAffine(1.4375, 0, 1164.09,  //
                                      0, 1.53125, 236.548);
            builder.drawPath(path2);
            builder.restore();
          }
          builder.restore();
        }
        builder.restore();
      }
      builder.restore();
    }
    builder.restore();
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

TEST(DisplayList, TranslateAffectsCurrentTransform) {
  DisplayListBuilder builder;
  builder.translate(12.3, 14.5);
  SkMatrix matrix = SkMatrix::Translate(12.3, 14.5);
  SkM44 m44 = SkM44(matrix);
  SkM44 cur_m44 = builder.GetTransformFullPerspective();
  SkMatrix cur_matrix = builder.GetTransform();
  ASSERT_EQ(cur_m44, m44);
  ASSERT_EQ(cur_matrix, matrix);
  builder.translate(10, 10);
  // CurrentTransform has changed
  ASSERT_NE(builder.GetTransformFullPerspective(), m44);
  ASSERT_NE(builder.GetTransform(), cur_matrix);
  // Previous return values have not
  ASSERT_EQ(cur_m44, m44);
  ASSERT_EQ(cur_matrix, matrix);
}

TEST(DisplayList, ScaleAffectsCurrentTransform) {
  DisplayListBuilder builder;
  builder.scale(12.3, 14.5);
  SkMatrix matrix = SkMatrix::Scale(12.3, 14.5);
  SkM44 m44 = SkM44(matrix);
  SkM44 cur_m44 = builder.GetTransformFullPerspective();
  SkMatrix cur_matrix = builder.GetTransform();
  ASSERT_EQ(cur_m44, m44);
  ASSERT_EQ(cur_matrix, matrix);
  builder.translate(10, 10);
  // CurrentTransform has changed
  ASSERT_NE(builder.GetTransformFullPerspective(), m44);
  ASSERT_NE(builder.GetTransform(), cur_matrix);
  // Previous return values have not
  ASSERT_EQ(cur_m44, m44);
  ASSERT_EQ(cur_matrix, matrix);
}

TEST(DisplayList, RotateAffectsCurrentTransform) {
  DisplayListBuilder builder;
  builder.rotate(12.3);
  SkMatrix matrix = SkMatrix::RotateDeg(12.3);
  SkM44 m44 = SkM44(matrix);
  SkM44 cur_m44 = builder.GetTransformFullPerspective();
  SkMatrix cur_matrix = builder.GetTransform();
  ASSERT_EQ(cur_m44, m44);
  ASSERT_EQ(cur_matrix, matrix);
  builder.translate(10, 10);
  // CurrentTransform has changed
  ASSERT_NE(builder.GetTransformFullPerspective(), m44);
  ASSERT_NE(builder.GetTransform(), cur_matrix);
  // Previous return values have not
  ASSERT_EQ(cur_m44, m44);
  ASSERT_EQ(cur_matrix, matrix);
}

TEST(DisplayList, SkewAffectsCurrentTransform) {
  DisplayListBuilder builder;
  builder.skew(12.3, 14.5);
  SkMatrix matrix = SkMatrix::Skew(12.3, 14.5);
  SkM44 m44 = SkM44(matrix);
  SkM44 cur_m44 = builder.GetTransformFullPerspective();
  SkMatrix cur_matrix = builder.GetTransform();
  ASSERT_EQ(cur_m44, m44);
  ASSERT_EQ(cur_matrix, matrix);
  builder.translate(10, 10);
  // CurrentTransform has changed
  ASSERT_NE(builder.GetTransformFullPerspective(), m44);
  ASSERT_NE(builder.GetTransform(), cur_matrix);
  // Previous return values have not
  ASSERT_EQ(cur_m44, m44);
  ASSERT_EQ(cur_matrix, matrix);
}

TEST(DisplayList, TransformAffectsCurrentTransform) {
  DisplayListBuilder builder;
  builder.transform2DAffine(3, 0, 12.3,  //
                            1, 5, 14.5);
  SkMatrix matrix = SkMatrix::MakeAll(3, 0, 12.3,  //
                                      1, 5, 14.5,  //
                                      0, 0, 1);
  SkM44 m44 = SkM44(matrix);
  SkM44 cur_m44 = builder.GetTransformFullPerspective();
  SkMatrix cur_matrix = builder.GetTransform();
  ASSERT_EQ(cur_m44, m44);
  ASSERT_EQ(cur_matrix, matrix);
  builder.translate(10, 10);
  // CurrentTransform has changed
  ASSERT_NE(builder.GetTransformFullPerspective(), m44);
  ASSERT_NE(builder.GetTransform(), cur_matrix);
  // Previous return values have not
  ASSERT_EQ(cur_m44, m44);
  ASSERT_EQ(cur_matrix, matrix);
}

TEST(DisplayList, FullTransformAffectsCurrentTransform) {
  DisplayListBuilder builder;
  builder.transformFullPerspective(3, 0, 4, 12.3,  //
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
  builder.translate(10, 10);
  // CurrentTransform has changed
  ASSERT_NE(builder.GetTransformFullPerspective(), m44);
  ASSERT_NE(builder.GetTransform(), cur_matrix);
  // Previous return values have not
  ASSERT_EQ(cur_m44, m44);
  ASSERT_EQ(cur_matrix, matrix);
}

TEST(DisplayList, ClipRectAffectsClipBounds) {
  DisplayListBuilder builder;
  SkRect clip_bounds = SkRect::MakeLTRB(10.2, 11.3, 20.4, 25.7);
  builder.clipRect(clip_bounds, ClipOp::kIntersect, false);

  // Save initial return values for testing restored values
  SkRect initial_local_bounds = builder.GetLocalClipBounds();
  SkRect initial_destination_bounds = builder.GetDestinationClipBounds();
  ASSERT_EQ(initial_local_bounds, clip_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_bounds);

  builder.save();
  builder.clipRect({0, 0, 15, 15}, ClipOp::kIntersect, false);
  // Both clip bounds have changed
  ASSERT_NE(builder.GetLocalClipBounds(), clip_bounds);
  ASSERT_NE(builder.GetDestinationClipBounds(), clip_bounds);
  // Previous return values have not changed
  ASSERT_EQ(initial_local_bounds, clip_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_bounds);
  builder.restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);

  builder.save();
  builder.scale(2, 2);
  SkRect scaled_clip_bounds = SkRect::MakeLTRB(5.1, 5.65, 10.2, 12.85);
  ASSERT_EQ(builder.GetLocalClipBounds(), scaled_clip_bounds);
  // Destination bounds are unaffected by transform
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds);
  builder.restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);
}

TEST(DisplayList, ClipRectDoAAAffectsClipBounds) {
  DisplayListBuilder builder;
  SkRect clip_bounds = SkRect::MakeLTRB(10.2, 11.3, 20.4, 25.7);
  SkRect clip_expanded_bounds = SkRect::MakeLTRB(10, 11, 21, 26);
  builder.clipRect(clip_bounds, ClipOp::kIntersect, true);

  // Save initial return values for testing restored values
  SkRect initial_local_bounds = builder.GetLocalClipBounds();
  SkRect initial_destination_bounds = builder.GetDestinationClipBounds();
  ASSERT_EQ(initial_local_bounds, clip_expanded_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_expanded_bounds);

  builder.save();
  builder.clipRect({0, 0, 15, 15}, ClipOp::kIntersect, true);
  // Both clip bounds have changed
  ASSERT_NE(builder.GetLocalClipBounds(), clip_expanded_bounds);
  ASSERT_NE(builder.GetDestinationClipBounds(), clip_expanded_bounds);
  // Previous return values have not changed
  ASSERT_EQ(initial_local_bounds, clip_expanded_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_expanded_bounds);
  builder.restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);

  builder.save();
  builder.scale(2, 2);
  SkRect scaled_expanded_bounds = SkRect::MakeLTRB(5, 5.5, 10.5, 13);
  ASSERT_EQ(builder.GetLocalClipBounds(), scaled_expanded_bounds);
  // Destination bounds are unaffected by transform
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_expanded_bounds);
  builder.restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);
}

TEST(DisplayList, ClipRectAffectsClipBoundsWithMatrix) {
  DisplayListBuilder builder;
  SkRect clip_bounds_1 = SkRect::MakeLTRB(0, 0, 10, 10);
  SkRect clip_bounds_2 = SkRect::MakeLTRB(10, 10, 20, 20);
  builder.save();
  builder.clipRect(clip_bounds_1, ClipOp::kIntersect, false);
  builder.translate(10, 0);
  builder.clipRect(clip_bounds_1, ClipOp::kIntersect, false);
  ASSERT_TRUE(builder.GetDestinationClipBounds().isEmpty());
  builder.restore();

  builder.save();
  builder.clipRect(clip_bounds_1, ClipOp::kIntersect, false);
  builder.translate(-10, -10);
  builder.clipRect(clip_bounds_2, ClipOp::kIntersect, false);
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds_1);
  builder.restore();
}

TEST(DisplayList, ClipRRectAffectsClipBounds) {
  DisplayListBuilder builder;
  SkRect clip_bounds = SkRect::MakeLTRB(10.2, 11.3, 20.4, 25.7);
  SkRRect clip = SkRRect::MakeRectXY(clip_bounds, 3, 2);
  builder.clipRRect(clip, ClipOp::kIntersect, false);

  // Save initial return values for testing restored values
  SkRect initial_local_bounds = builder.GetLocalClipBounds();
  SkRect initial_destination_bounds = builder.GetDestinationClipBounds();
  ASSERT_EQ(initial_local_bounds, clip_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_bounds);

  builder.save();
  builder.clipRect({0, 0, 15, 15}, ClipOp::kIntersect, false);
  // Both clip bounds have changed
  ASSERT_NE(builder.GetLocalClipBounds(), clip_bounds);
  ASSERT_NE(builder.GetDestinationClipBounds(), clip_bounds);
  // Previous return values have not changed
  ASSERT_EQ(initial_local_bounds, clip_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_bounds);
  builder.restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);

  builder.save();
  builder.scale(2, 2);
  SkRect scaled_clip_bounds = SkRect::MakeLTRB(5.1, 5.65, 10.2, 12.85);
  ASSERT_EQ(builder.GetLocalClipBounds(), scaled_clip_bounds);
  // Destination bounds are unaffected by transform
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds);
  builder.restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);
}

TEST(DisplayList, ClipRRectDoAAAffectsClipBounds) {
  DisplayListBuilder builder;
  SkRect clip_bounds = SkRect::MakeLTRB(10.2, 11.3, 20.4, 25.7);
  SkRect clip_expanded_bounds = SkRect::MakeLTRB(10, 11, 21, 26);
  SkRRect clip = SkRRect::MakeRectXY(clip_bounds, 3, 2);
  builder.clipRRect(clip, ClipOp::kIntersect, true);

  // Save initial return values for testing restored values
  SkRect initial_local_bounds = builder.GetLocalClipBounds();
  SkRect initial_destination_bounds = builder.GetDestinationClipBounds();
  ASSERT_EQ(initial_local_bounds, clip_expanded_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_expanded_bounds);

  builder.save();
  builder.clipRect({0, 0, 15, 15}, ClipOp::kIntersect, true);
  // Both clip bounds have changed
  ASSERT_NE(builder.GetLocalClipBounds(), clip_expanded_bounds);
  ASSERT_NE(builder.GetDestinationClipBounds(), clip_expanded_bounds);
  // Previous return values have not changed
  ASSERT_EQ(initial_local_bounds, clip_expanded_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_expanded_bounds);
  builder.restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);

  builder.save();
  builder.scale(2, 2);
  SkRect scaled_expanded_bounds = SkRect::MakeLTRB(5, 5.5, 10.5, 13);
  ASSERT_EQ(builder.GetLocalClipBounds(), scaled_expanded_bounds);
  // Destination bounds are unaffected by transform
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_expanded_bounds);
  builder.restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);
}

TEST(DisplayList, ClipRRectAffectsClipBoundsWithMatrix) {
  DisplayListBuilder builder;
  SkRect clip_bounds_1 = SkRect::MakeLTRB(0, 0, 10, 10);
  SkRect clip_bounds_2 = SkRect::MakeLTRB(10, 10, 20, 20);
  SkRRect clip1 = SkRRect::MakeRectXY(clip_bounds_1, 3, 2);
  SkRRect clip2 = SkRRect::MakeRectXY(clip_bounds_2, 3, 2);

  builder.save();
  builder.clipRRect(clip1, ClipOp::kIntersect, false);
  builder.translate(10, 0);
  builder.clipRRect(clip1, ClipOp::kIntersect, false);
  ASSERT_TRUE(builder.GetDestinationClipBounds().isEmpty());
  builder.restore();

  builder.save();
  builder.clipRRect(clip1, ClipOp::kIntersect, false);
  builder.translate(-10, -10);
  builder.clipRRect(clip2, ClipOp::kIntersect, false);
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds_1);
  builder.restore();
}

TEST(DisplayList, ClipPathAffectsClipBounds) {
  DisplayListBuilder builder;
  SkPath clip = SkPath().addCircle(10.2, 11.3, 2).addCircle(20.4, 25.7, 2);
  SkRect clip_bounds = SkRect::MakeLTRB(8.2, 9.3, 22.4, 27.7);
  builder.clipPath(clip, ClipOp::kIntersect, false);

  // Save initial return values for testing restored values
  SkRect initial_local_bounds = builder.GetLocalClipBounds();
  SkRect initial_destination_bounds = builder.GetDestinationClipBounds();
  ASSERT_EQ(initial_local_bounds, clip_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_bounds);

  builder.save();
  builder.clipRect({0, 0, 15, 15}, ClipOp::kIntersect, false);
  // Both clip bounds have changed
  ASSERT_NE(builder.GetLocalClipBounds(), clip_bounds);
  ASSERT_NE(builder.GetDestinationClipBounds(), clip_bounds);
  // Previous return values have not changed
  ASSERT_EQ(initial_local_bounds, clip_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_bounds);
  builder.restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);

  builder.save();
  builder.scale(2, 2);
  SkRect scaled_clip_bounds = SkRect::MakeLTRB(4.1, 4.65, 11.2, 13.85);
  ASSERT_EQ(builder.GetLocalClipBounds(), scaled_clip_bounds);
  // Destination bounds are unaffected by transform
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds);
  builder.restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);
}

TEST(DisplayList, ClipPathDoAAAffectsClipBounds) {
  DisplayListBuilder builder;
  SkPath clip = SkPath().addCircle(10.2, 11.3, 2).addCircle(20.4, 25.7, 2);
  SkRect clip_expanded_bounds = SkRect::MakeLTRB(8, 9, 23, 28);
  builder.clipPath(clip, ClipOp::kIntersect, true);

  // Save initial return values for testing restored values
  SkRect initial_local_bounds = builder.GetLocalClipBounds();
  SkRect initial_destination_bounds = builder.GetDestinationClipBounds();
  ASSERT_EQ(initial_local_bounds, clip_expanded_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_expanded_bounds);

  builder.save();
  builder.clipRect({0, 0, 15, 15}, ClipOp::kIntersect, true);
  // Both clip bounds have changed
  ASSERT_NE(builder.GetLocalClipBounds(), clip_expanded_bounds);
  ASSERT_NE(builder.GetDestinationClipBounds(), clip_expanded_bounds);
  // Previous return values have not changed
  ASSERT_EQ(initial_local_bounds, clip_expanded_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_expanded_bounds);
  builder.restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);

  builder.save();
  builder.scale(2, 2);
  SkRect scaled_expanded_bounds = SkRect::MakeLTRB(4, 4.5, 11.5, 14);
  ASSERT_EQ(builder.GetLocalClipBounds(), scaled_expanded_bounds);
  // Destination bounds are unaffected by transform
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_expanded_bounds);
  builder.restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);
}

TEST(DisplayList, ClipPathAffectsClipBoundsWithMatrix) {
  DisplayListBuilder builder;
  SkRect clip_bounds = SkRect::MakeLTRB(0, 0, 10, 10);
  SkPath clip1 = SkPath().addCircle(2.5, 2.5, 2.5).addCircle(7.5, 7.5, 2.5);
  SkPath clip2 = SkPath().addCircle(12.5, 12.5, 2.5).addCircle(17.5, 17.5, 2.5);

  builder.save();
  builder.clipPath(clip1, ClipOp::kIntersect, false);
  builder.translate(10, 0);
  builder.clipPath(clip1, ClipOp::kIntersect, false);
  ASSERT_TRUE(builder.GetDestinationClipBounds().isEmpty());
  builder.restore();

  builder.save();
  builder.clipPath(clip1, ClipOp::kIntersect, false);
  builder.translate(-10, -10);
  builder.clipPath(clip2, ClipOp::kIntersect, false);
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds);
  builder.restore();
}

TEST(DisplayList, DiffClipRectDoesNotAffectClipBounds) {
  DisplayListBuilder builder;
  SkRect diff_clip = SkRect::MakeLTRB(0, 0, 15, 15);
  SkRect clip_bounds = SkRect::MakeLTRB(10.2, 11.3, 20.4, 25.7);
  builder.clipRect(clip_bounds, ClipOp::kIntersect, false);

  // Save initial return values for testing after kDifference clip
  SkRect initial_local_bounds = builder.GetLocalClipBounds();
  SkRect initial_destination_bounds = builder.GetDestinationClipBounds();
  ASSERT_EQ(initial_local_bounds, clip_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_bounds);

  builder.clipRect(diff_clip, ClipOp::kDifference, false);
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);
}

TEST(DisplayList, DiffClipRRectDoesNotAffectClipBounds) {
  DisplayListBuilder builder;
  SkRRect diff_clip = SkRRect::MakeRectXY({0, 0, 15, 15}, 1, 1);
  SkRect clip_bounds = SkRect::MakeLTRB(10.2, 11.3, 20.4, 25.7);
  SkRRect clip = SkRRect::MakeRectXY({10.2, 11.3, 20.4, 25.7}, 3, 2);
  builder.clipRRect(clip, ClipOp::kIntersect, false);

  // Save initial return values for testing after kDifference clip
  SkRect initial_local_bounds = builder.GetLocalClipBounds();
  SkRect initial_destination_bounds = builder.GetDestinationClipBounds();
  ASSERT_EQ(initial_local_bounds, clip_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_bounds);

  builder.clipRRect(diff_clip, ClipOp::kDifference, false);
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);
}

TEST(DisplayList, DiffClipPathDoesNotAffectClipBounds) {
  DisplayListBuilder builder;
  SkPath diff_clip = SkPath().addRect({0, 0, 15, 15});
  SkPath clip = SkPath().addCircle(10.2, 11.3, 2).addCircle(20.4, 25.7, 2);
  SkRect clip_bounds = SkRect::MakeLTRB(8.2, 9.3, 22.4, 27.7);
  builder.clipPath(clip, ClipOp::kIntersect, false);

  // Save initial return values for testing after kDifference clip
  SkRect initial_local_bounds = builder.GetLocalClipBounds();
  SkRect initial_destination_bounds = builder.GetDestinationClipBounds();
  ASSERT_EQ(initial_local_bounds, clip_bounds);
  ASSERT_EQ(initial_destination_bounds, clip_bounds);

  builder.clipPath(diff_clip, ClipOp::kDifference, false);
  ASSERT_EQ(builder.GetLocalClipBounds(), initial_local_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), initial_destination_bounds);
}

TEST(DisplayList, ClipPathWithInvertFillTypeDoesNotAffectClipBounds) {
  SkRect cull_rect = SkRect::MakeLTRB(0, 0, 100.0, 100.0);
  DisplayListBuilder builder(cull_rect);
  SkPath clip = SkPath().addCircle(10.2, 11.3, 2).addCircle(20.4, 25.7, 2);
  clip.setFillType(SkPathFillType::kInverseWinding);
  builder.clipPath(clip, ClipOp::kIntersect, false);

  ASSERT_EQ(builder.GetLocalClipBounds(), cull_rect);
  ASSERT_EQ(builder.GetDestinationClipBounds(), cull_rect);
}

TEST(DisplayList, DiffClipPathWithInvertFillTypeAffectsClipBounds) {
  SkRect cull_rect = SkRect::MakeLTRB(0, 0, 100.0, 100.0);
  DisplayListBuilder builder(cull_rect);
  SkPath clip = SkPath().addCircle(10.2, 11.3, 2).addCircle(20.4, 25.7, 2);
  clip.setFillType(SkPathFillType::kInverseWinding);
  SkRect clip_bounds = SkRect::MakeLTRB(8.2, 9.3, 22.4, 27.7);
  builder.clipPath(clip, ClipOp::kDifference, false);

  ASSERT_EQ(builder.GetLocalClipBounds(), clip_bounds);
  ASSERT_EQ(builder.GetDestinationClipBounds(), clip_bounds);
}

TEST(DisplayList, FlatDrawPointsProducesBounds) {
  SkPoint horizontal_points[2] = {{10, 10}, {20, 10}};
  SkPoint vertical_points[2] = {{10, 10}, {10, 20}};
  {
    DisplayListBuilder builder;
    builder.drawPoints(PointMode::kPolygon, 2, horizontal_points);
    SkRect bounds = builder.Build()->bounds();
    EXPECT_TRUE(bounds.contains(10, 10));
    EXPECT_TRUE(bounds.contains(20, 10));
    EXPECT_GE(bounds.width(), 10);
  }
  {
    DisplayListBuilder builder;
    builder.drawPoints(PointMode::kPolygon, 2, vertical_points);
    SkRect bounds = builder.Build()->bounds();
    EXPECT_TRUE(bounds.contains(10, 10));
    EXPECT_TRUE(bounds.contains(10, 20));
    EXPECT_GE(bounds.height(), 10);
  }
  {
    DisplayListBuilder builder;
    builder.drawPoints(PointMode::kPoints, 1, horizontal_points);
    SkRect bounds = builder.Build()->bounds();
    EXPECT_TRUE(bounds.contains(10, 10));
  }
  {
    DisplayListBuilder builder;
    builder.setStrokeWidth(2);
    builder.drawPoints(PointMode::kPolygon, 2, horizontal_points);
    SkRect bounds = builder.Build()->bounds();
    EXPECT_TRUE(bounds.contains(10, 10));
    EXPECT_TRUE(bounds.contains(20, 10));
    EXPECT_EQ(bounds, SkRect::MakeLTRB(9, 9, 21, 11));
  }
  {
    DisplayListBuilder builder;
    builder.setStrokeWidth(2);
    builder.drawPoints(PointMode::kPolygon, 2, vertical_points);
    SkRect bounds = builder.Build()->bounds();
    EXPECT_TRUE(bounds.contains(10, 10));
    EXPECT_TRUE(bounds.contains(10, 20));
    EXPECT_EQ(bounds, SkRect::MakeLTRB(9, 9, 11, 21));
  }
  {
    DisplayListBuilder builder;
    builder.setStrokeWidth(2);
    builder.drawPoints(PointMode::kPoints, 1, horizontal_points);
    SkRect bounds = builder.Build()->bounds();
    EXPECT_TRUE(bounds.contains(10, 10));
    EXPECT_EQ(bounds, SkRect::MakeLTRB(9, 9, 11, 11));
  }
}

static void test_rtree(const sk_sp<const DlRTree>& rtree,
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

TEST(DisplayList, RTreeOfSimpleScene) {
  DisplayListBuilder builder(/*prepare_rtree=*/true);
  builder.drawRect({10, 10, 20, 20});
  builder.drawRect({50, 50, 60, 60});
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

TEST(DisplayList, RTreeOfSaveRestoreScene) {
  DisplayListBuilder builder(/*prepare_rtree=*/true);
  builder.drawRect({10, 10, 20, 20});
  builder.save();
  builder.drawRect({50, 50, 60, 60});
  builder.restore();
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

TEST(DisplayList, RTreeOfSaveLayerFilterScene) {
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

TEST(DisplayList, NestedDisplayListRTreesAreSparse) {
  DisplayListBuilder nested_dl_builder(/**prepare_rtree=*/true);
  nested_dl_builder.drawRect({10, 10, 20, 20});
  nested_dl_builder.drawRect({50, 50, 60, 60});
  auto nested_display_list = nested_dl_builder.Build();

  DisplayListBuilder builder(/**prepare_rtree=*/true);
  builder.drawDisplayList(nested_display_list);
  auto display_list = builder.Build();

  auto rtree = display_list->rtree();
  std::vector<SkRect> rects = {
      {10, 10, 20, 20},
      {50, 50, 60, 60},
  };

  // Hitting both sub-dl drawRect calls
  test_rtree(rtree, {19, 19, 51, 51}, rects, {0, 1});
}

TEST(DisplayList, RemoveUnnecessarySaveRestorePairs) {
  {
    DisplayListBuilder builder;
    builder.drawRect({10, 10, 20, 20});
    builder.save();  // This save op is unnecessary
    builder.drawRect({50, 50, 60, 60});
    builder.restore();

    DisplayListBuilder builder2;
    builder2.drawRect({10, 10, 20, 20});
    builder2.drawRect({50, 50, 60, 60});
    ASSERT_TRUE(DisplayListsEQ_Verbose(builder.Build(), builder2.Build()));
  }

  {
    DisplayListBuilder builder;
    builder.drawRect({10, 10, 20, 20});
    builder.save();
    builder.translate(1.0, 1.0);
    {
      builder.save();  // unnecessary
      builder.drawRect({50, 50, 60, 60});
      builder.restore();
    }

    builder.restore();

    DisplayListBuilder builder2;
    builder2.drawRect({10, 10, 20, 20});
    builder2.save();
    builder2.translate(1.0, 1.0);
    { builder2.drawRect({50, 50, 60, 60}); }
    builder2.restore();
    ASSERT_TRUE(DisplayListsEQ_Verbose(builder.Build(), builder2.Build()));
  }
}

TEST(DisplayList, CollapseMultipleNestedSaveRestore) {
  DisplayListBuilder builder1;
  builder1.save();
  builder1.save();
  builder1.save();
  builder1.translate(10, 10);
  builder1.scale(2, 2);
  builder1.clipRect({10, 10, 20, 20}, ClipOp::kIntersect, false);
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  builder1.restore();
  builder1.restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.save();
  builder2.translate(10, 10);
  builder2.scale(2, 2);
  builder2.clipRect({10, 10, 20, 20}, ClipOp::kIntersect, false);
  builder2.drawRect({0, 0, 100, 100});
  builder2.restore();
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST(DisplayList, CollapseNestedSaveAndSaveLayerRestore) {
  DisplayListBuilder builder1;
  builder1.save();
  builder1.saveLayer(nullptr, false);
  builder1.drawRect({0, 0, 100, 100});
  builder1.scale(2, 2);
  builder1.restore();
  builder1.restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.saveLayer(nullptr, false);
  builder2.drawRect({0, 0, 100, 100});
  builder2.scale(2, 2);
  builder2.restore();
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST(DisplayList, RemoveUnnecessarySaveRestorePairsInSetPaint) {
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

TEST(DisplayList, TransformTriggersDeferredSave) {
  DisplayListBuilder builder1;
  builder1.save();
  builder1.save();
  builder1.transform(SkM44::Translate(10, 100));
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  builder1.transform(SkM44::Translate(10, 100));
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.save();
  builder2.transform(SkM44::Translate(10, 100));
  builder2.drawRect({0, 0, 100, 100});
  builder2.restore();
  builder2.save();
  builder2.transform(SkM44::Translate(10, 100));
  builder2.drawRect({0, 0, 100, 100});
  builder2.restore();
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST(DisplayList, Transform2DTriggersDeferredSave) {
  DisplayListBuilder builder1;
  builder1.save();
  builder1.save();
  builder1.transform2DAffine(0, 1, 12, 1, 0, 33);
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  builder1.restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.save();
  builder2.transform2DAffine(0, 1, 12, 1, 0, 33);
  builder2.drawRect({0, 0, 100, 100});
  builder2.restore();
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST(DisplayList, TransformPerspectiveTriggersDeferredSave) {
  DisplayListBuilder builder1;
  builder1.save();
  builder1.save();
  builder1.transformFullPerspective(0, 1, 0, 12, 1, 0, 0, 33, 3, 2, 5, 29, 0, 0,
                                    0, 12);
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  builder1.restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.save();
  builder2.transformFullPerspective(0, 1, 0, 12, 1, 0, 0, 33, 3, 2, 5, 29, 0, 0,
                                    0, 12);
  builder2.drawRect({0, 0, 100, 100});
  builder2.restore();
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST(DisplayList, ResetTransformTriggersDeferredSave) {
  DisplayListBuilder builder1;
  builder1.save();
  builder1.save();
  builder1.transformReset();
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  builder1.restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.save();
  builder2.transformReset();
  builder2.drawRect({0, 0, 100, 100});
  builder2.restore();
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST(DisplayList, SkewTriggersDeferredSave) {
  DisplayListBuilder builder1;
  builder1.save();
  builder1.save();
  builder1.skew(10, 10);
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  builder1.restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.save();
  builder2.skew(10, 10);
  builder2.drawRect({0, 0, 100, 100});
  builder2.restore();
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST(DisplayList, TranslateTriggersDeferredSave) {
  DisplayListBuilder builder1;
  builder1.save();
  builder1.save();
  builder1.translate(10, 10);
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  builder1.restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.save();
  builder2.translate(10, 10);
  builder2.drawRect({0, 0, 100, 100});
  builder2.restore();
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST(DisplayList, ScaleTriggersDeferredSave) {
  DisplayListBuilder builder1;
  builder1.save();
  builder1.save();
  builder1.scale(0.5, 0.5);
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  builder1.restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.save();
  builder2.scale(0.5, 0.5);
  builder2.drawRect({0, 0, 100, 100});
  builder2.restore();
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST(DisplayList, ClipRectTriggersDeferredSave) {
  DisplayListBuilder builder1;
  builder1.save();
  builder1.save();
  builder1.clipRect(SkRect::MakeLTRB(0, 0, 100, 100), ClipOp::kIntersect, true);
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  builder1.transform(SkM44());
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.save();
  builder2.clipRect(SkRect::MakeLTRB(0, 0, 100, 100), ClipOp::kIntersect, true);
  builder2.drawRect({0, 0, 100, 100});
  builder2.restore();
  builder2.transform(SkM44());
  builder2.drawRect({0, 0, 100, 100});
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST(DisplayList, ClipRRectTriggersDeferredSave) {
  DisplayListBuilder builder1;
  builder1.save();
  builder1.save();
  builder1.clipRRect(kTestRRect, ClipOp::kIntersect, true);

  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  builder1.transform(SkM44());
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.save();
  builder2.clipRRect(kTestRRect, ClipOp::kIntersect, true);

  builder2.drawRect({0, 0, 100, 100});
  builder2.restore();
  builder2.transform(SkM44());
  builder2.drawRect({0, 0, 100, 100});
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST(DisplayList, ClipPathTriggersDeferredSave) {
  DisplayListBuilder builder1;
  builder1.save();
  builder1.save();
  builder1.clipPath(kTestPath1, ClipOp::kIntersect, true);
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  builder1.transform(SkM44());
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.save();
  builder2.clipPath(kTestPath1, ClipOp::kIntersect, true);
  builder2.drawRect({0, 0, 100, 100});
  builder2.restore();
  builder2.transform(SkM44());
  builder2.drawRect({0, 0, 100, 100});
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST(DisplayList, NOPTranslateDoesNotTriggerDeferredSave) {
  DisplayListBuilder builder1;
  builder1.save();
  builder1.save();
  builder1.translate(0, 0);
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.drawRect({0, 0, 100, 100});
  builder2.drawRect({0, 0, 100, 100});
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST(DisplayList, NOPScaleDoesNotTriggerDeferredSave) {
  DisplayListBuilder builder1;
  builder1.save();
  builder1.save();
  builder1.scale(1.0, 1.0);
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.drawRect({0, 0, 100, 100});
  builder2.drawRect({0, 0, 100, 100});
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST(DisplayList, NOPRotationDoesNotTriggerDeferredSave) {
  DisplayListBuilder builder1;
  builder1.save();
  builder1.save();
  builder1.rotate(360);
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.drawRect({0, 0, 100, 100});
  builder2.drawRect({0, 0, 100, 100});
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST(DisplayList, NOPSkewDoesNotTriggerDeferredSave) {
  DisplayListBuilder builder1;
  builder1.save();
  builder1.save();
  builder1.skew(0, 0);
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.drawRect({0, 0, 100, 100});
  builder2.drawRect({0, 0, 100, 100});
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST(DisplayList, NOPTransformDoesNotTriggerDeferredSave) {
  DisplayListBuilder builder1;
  builder1.save();
  builder1.save();
  builder1.transform(SkM44());
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  builder1.transform(SkM44());
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.drawRect({0, 0, 100, 100});
  builder2.drawRect({0, 0, 100, 100});
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST(DisplayList, NOPTransform2DDoesNotTriggerDeferredSave) {
  DisplayListBuilder builder1;
  builder1.save();
  builder1.save();
  builder1.transform2DAffine(1, 0, 0, 0, 1, 0);
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.drawRect({0, 0, 100, 100});
  builder2.drawRect({0, 0, 100, 100});
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST(DisplayList, NOPTransformFullPerspectiveDoesNotTriggerDeferredSave) {
  {
    DisplayListBuilder builder1;
    builder1.save();
    builder1.save();
    builder1.transformFullPerspective(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0,
                                      0, 1);
    builder1.drawRect({0, 0, 100, 100});
    builder1.restore();
    builder1.drawRect({0, 0, 100, 100});
    builder1.restore();
    auto display_list1 = builder1.Build();

    DisplayListBuilder builder2;
    builder2.drawRect({0, 0, 100, 100});
    builder2.drawRect({0, 0, 100, 100});
    auto display_list2 = builder2.Build();

    ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
  }

  {
    DisplayListBuilder builder1;
    builder1.save();
    builder1.save();
    builder1.transformFullPerspective(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0,
                                      0, 1);
    builder1.transformReset();
    builder1.drawRect({0, 0, 100, 100});
    builder1.restore();
    builder1.drawRect({0, 0, 100, 100});
    builder1.restore();
    auto display_list1 = builder1.Build();

    DisplayListBuilder builder2;
    builder2.save();
    builder2.transformReset();
    builder2.drawRect({0, 0, 100, 100});
    builder2.restore();
    builder2.drawRect({0, 0, 100, 100});

    auto display_list2 = builder2.Build();

    ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
  }
}

TEST(DisplayList, NOPClipDoesNotTriggerDeferredSave) {
  DisplayListBuilder builder1;
  builder1.save();
  builder1.save();
  builder1.clipRect(SkRect::MakeLTRB(0, SK_ScalarNaN, SK_ScalarNaN, 0),
                    ClipOp::kIntersect, true);
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  builder1.drawRect({0, 0, 100, 100});
  builder1.restore();
  auto display_list1 = builder1.Build();

  DisplayListBuilder builder2;
  builder2.drawRect({0, 0, 100, 100});
  builder2.drawRect({0, 0, 100, 100});
  auto display_list2 = builder2.Build();

  ASSERT_TRUE(DisplayListsEQ_Verbose(display_list1, display_list2));
}

TEST(DisplayList, RTreeOfClippedSaveLayerFilterScene) {
  DisplayListBuilder builder(/*prepare_rtree=*/true);
  // blur filter with sigma=1 expands by 30 on all sides
  auto filter = DlBlurImageFilter(10.0, 10.0, DlTileMode::kClamp);
  DlPaint default_paint = DlPaint();
  DlPaint filter_paint = DlPaint().setImageFilter(&filter);
  builder.DrawRect({10, 10, 20, 20}, default_paint);
  builder.clipRect({50, 50, 60, 60}, ClipOp::kIntersect, false);
  builder.SaveLayer(nullptr, &filter_paint);
  // the following rectangle will be expanded to 23,23,87,87
  // by the saveLayer filter during the restore operation
  // but it will then be clipped to 50,50,60,60
  builder.DrawRect({53, 53, 57, 57}, default_paint);
  builder.restore();
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

TEST(DisplayList, RTreeRenderCulling) {
  DisplayListBuilder main_builder(true);
  main_builder.drawRect({0, 0, 10, 10});
  main_builder.drawRect({20, 0, 30, 10});
  main_builder.drawRect({0, 20, 10, 30});
  main_builder.drawRect({20, 20, 30, 30});
  auto main = main_builder.Build();

  {  // No rects
    SkRect cull_rect = {11, 11, 19, 19};

    DisplayListBuilder expected_builder;
    auto expected = expected_builder.Build();

    DisplayListBuilder culling_builder(cull_rect);
    main->RenderTo(&culling_builder);

    EXPECT_TRUE(DisplayListsEQ_Verbose(culling_builder.Build(), expected));
  }

  {  // Rect 1
    SkRect cull_rect = {9, 9, 19, 19};

    DisplayListBuilder expected_builder;
    expected_builder.drawRect({0, 0, 10, 10});
    auto expected = expected_builder.Build();

    DisplayListBuilder culling_builder(cull_rect);
    main->RenderTo(&culling_builder);

    EXPECT_TRUE(DisplayListsEQ_Verbose(culling_builder.Build(), expected));
  }

  {  // Rect 2
    SkRect cull_rect = {11, 9, 21, 19};

    DisplayListBuilder expected_builder;
    expected_builder.drawRect({20, 0, 30, 10});
    auto expected = expected_builder.Build();

    DisplayListBuilder culling_builder(cull_rect);
    main->RenderTo(&culling_builder);

    EXPECT_TRUE(DisplayListsEQ_Verbose(culling_builder.Build(), expected));
  }

  {  // Rect 3
    SkRect cull_rect = {9, 11, 19, 21};

    DisplayListBuilder expected_builder;
    expected_builder.drawRect({0, 20, 10, 30});
    auto expected = expected_builder.Build();

    DisplayListBuilder culling_builder(cull_rect);
    main->RenderTo(&culling_builder);

    EXPECT_TRUE(DisplayListsEQ_Verbose(culling_builder.Build(), expected));
  }

  {  // Rect 4
    SkRect cull_rect = {11, 11, 21, 21};

    DisplayListBuilder expected_builder;
    expected_builder.drawRect({20, 20, 30, 30});
    auto expected = expected_builder.Build();

    DisplayListBuilder culling_builder(cull_rect);
    main->RenderTo(&culling_builder);

    EXPECT_TRUE(DisplayListsEQ_Verbose(culling_builder.Build(), expected));
  }

  {  // All 4 rects
    SkRect cull_rect = {9, 9, 21, 21};

    DisplayListBuilder culling_builder(cull_rect);
    main->RenderTo(&culling_builder);

    EXPECT_TRUE(DisplayListsEQ_Verbose(culling_builder.Build(), main));
  }
}

}  // namespace testing
}  // namespace flutter
