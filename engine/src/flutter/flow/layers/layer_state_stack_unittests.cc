// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include "flutter/display_list/effects/dl_color_filter.h"
#include "flutter/display_list/effects/dl_image_filter.h"
#include "flutter/flow/layers/layer.h"
#include "flutter/flow/layers/layer_state_stack.h"
#include "flutter/testing/display_list_testing.h"
#include "flutter/testing/mock_canvas.h"

namespace flutter {
namespace testing {

#ifndef NDEBUG
TEST(LayerStateStack, AccessorsDieWithoutDelegate) {
  LayerStateStack state_stack;

  EXPECT_DEATH_IF_SUPPORTED(state_stack.device_cull_rect(),
                            "LayerStateStack state queried without a delegate");
  EXPECT_DEATH_IF_SUPPORTED(state_stack.local_cull_rect(),
                            "LayerStateStack state queried without a delegate");
  EXPECT_DEATH_IF_SUPPORTED(state_stack.transform_3x3(),
                            "LayerStateStack state queried without a delegate");
  EXPECT_DEATH_IF_SUPPORTED(state_stack.transform_4x4(),
                            "LayerStateStack state queried without a delegate");
  EXPECT_DEATH_IF_SUPPORTED(state_stack.content_culled({}),
                            "LayerStateStack state queried without a delegate");
  {
    // state_stack.set_preroll_delegate(kGiantRect, SkMatrix::I());
    auto mutator = state_stack.save();
    mutator.applyOpacity({}, 0.5);
    state_stack.clear_delegate();
    auto restore = state_stack.applyState({}, 0);
  }
}
#endif

TEST(LayerStateStack, Defaults) {
  LayerStateStack state_stack;

  ASSERT_EQ(state_stack.canvas_delegate(), nullptr);
  ASSERT_EQ(state_stack.checkerboard_func(), nullptr);
  ASSERT_EQ(state_stack.outstanding_opacity(), SK_Scalar1);
  ASSERT_EQ(state_stack.outstanding_color_filter(), nullptr);
  ASSERT_EQ(state_stack.outstanding_image_filter(), nullptr);
  ASSERT_EQ(state_stack.outstanding_bounds(), SkRect());

  state_stack.set_preroll_delegate(kGiantRect, SkMatrix::I());
  ASSERT_EQ(state_stack.device_cull_rect(), kGiantRect);
  ASSERT_EQ(state_stack.local_cull_rect(), kGiantRect);
  ASSERT_EQ(state_stack.transform_3x3(), SkMatrix::I());
  ASSERT_EQ(state_stack.transform_4x4(), SkM44());

  DlPaint dl_paint;
  state_stack.fill(dl_paint);
  ASSERT_EQ(dl_paint, DlPaint());
}

TEST(LayerStateStack, SingularDelegate) {
  LayerStateStack state_stack;
  ASSERT_EQ(state_stack.canvas_delegate(), nullptr);

  // Two kinds of DlCanvas implementation
  DisplayListBuilder builder;
  MockCanvas canvas;

  // no delegate -> builder delegate
  state_stack.set_delegate(&builder);
  ASSERT_EQ(state_stack.canvas_delegate(), &builder);

  // builder delegate -> DlCanvas delegate
  state_stack.set_delegate(&canvas);
  ASSERT_EQ(state_stack.canvas_delegate(), &canvas);

  // DlCanvas delegate -> builder delegate
  state_stack.set_delegate(&builder);
  ASSERT_EQ(state_stack.canvas_delegate(), &builder);

  // builder delegate -> no delegate
  state_stack.clear_delegate();
  ASSERT_EQ(state_stack.canvas_delegate(), nullptr);

  // DlCanvas delegate -> no delegate
  state_stack.set_delegate(&canvas);
  state_stack.clear_delegate();
  ASSERT_EQ(state_stack.canvas_delegate(), nullptr);
}

TEST(LayerStateStack, OldDelegateIsRolledBack) {
  LayerStateStack state_stack;
  DisplayListBuilder builder;
  MockCanvas canvas;

  ASSERT_TRUE(builder.GetTransform().isIdentity());
  ASSERT_TRUE(canvas.GetTransform().isIdentity());

  state_stack.set_delegate(&builder);

  ASSERT_TRUE(builder.GetTransform().isIdentity());
  ASSERT_TRUE(canvas.GetTransform().isIdentity());

  auto mutator = state_stack.save();
  mutator.translate({10, 10});

  ASSERT_EQ(builder.GetTransform(), SkMatrix::Translate(10, 10));
  ASSERT_TRUE(canvas.GetTransform().isIdentity());

  state_stack.set_delegate(&canvas);

  ASSERT_TRUE(builder.GetTransform().isIdentity());
  ASSERT_EQ(canvas.GetTransform(), SkMatrix::Translate(10, 10));

  state_stack.set_preroll_delegate(SkRect::MakeWH(100, 100));

  ASSERT_TRUE(builder.GetTransform().isIdentity());
  ASSERT_TRUE(canvas.GetTransform().isIdentity());

  state_stack.set_delegate(&builder);
  state_stack.clear_delegate();

  ASSERT_TRUE(builder.GetTransform().isIdentity());
  ASSERT_TRUE(canvas.GetTransform().isIdentity());

  state_stack.set_delegate(&canvas);
  state_stack.clear_delegate();

  ASSERT_TRUE(builder.GetTransform().isIdentity());
  ASSERT_TRUE(canvas.GetTransform().isIdentity());
}

TEST(LayerStateStack, Opacity) {
  SkRect rect = {10, 10, 20, 20};

  LayerStateStack state_stack;
  state_stack.set_preroll_delegate(SkRect::MakeLTRB(0, 0, 50, 50));
  {
    auto mutator = state_stack.save();
    mutator.applyOpacity(rect, 0.5f);

    ASSERT_EQ(state_stack.outstanding_opacity(), 0.5f);
    ASSERT_EQ(state_stack.outstanding_bounds(), rect);

    // Check nested opacities multiply with each other
    {
      auto mutator2 = state_stack.save();
      mutator.applyOpacity(rect, 0.5f);

      ASSERT_EQ(state_stack.outstanding_opacity(), 0.25f);
      ASSERT_EQ(state_stack.outstanding_bounds(), rect);

      // Verify output with applyState that does not accept opacity
      {
        DisplayListBuilder builder;
        state_stack.set_delegate(&builder);
        {
          auto restore = state_stack.applyState(rect, 0);
          ASSERT_EQ(state_stack.outstanding_opacity(), SK_Scalar1);
          ASSERT_EQ(state_stack.outstanding_bounds(), SkRect());

          DlPaint paint;
          state_stack.fill(paint);
          builder.DrawRect(rect, paint);
        }
        state_stack.clear_delegate();

        DisplayListBuilder expected;
        DlPaint save_paint =
            DlPaint().setOpacity(state_stack.outstanding_opacity());
        expected.SaveLayer(&rect, &save_paint);
        expected.DrawRect(rect, DlPaint());
        expected.Restore();
        ASSERT_TRUE(DisplayListsEQ_Verbose(builder.Build(), expected.Build()));
      }

      // Verify output with applyState that accepts opacity
      {
        DisplayListBuilder builder;
        state_stack.set_delegate(&builder);
        {
          auto restore = state_stack.applyState(
              rect, LayerStateStack::kCallerCanApplyOpacity);
          ASSERT_EQ(state_stack.outstanding_opacity(), 0.25f);
          ASSERT_EQ(state_stack.outstanding_bounds(), rect);

          DlPaint paint;
          state_stack.fill(paint);
          builder.DrawRect(rect, paint);
        }
        state_stack.clear_delegate();

        DisplayListBuilder expected;
        expected.DrawRect(rect, DlPaint().setOpacity(0.25f));
        ASSERT_TRUE(DisplayListsEQ_Verbose(builder.Build(), expected.Build()));
      }
    }

    ASSERT_EQ(state_stack.outstanding_opacity(), 0.5f);
    ASSERT_EQ(state_stack.outstanding_bounds(), rect);
  }

  ASSERT_EQ(state_stack.outstanding_opacity(), SK_Scalar1);
  ASSERT_EQ(state_stack.outstanding_bounds(), SkRect());
}

TEST(LayerStateStack, ColorFilter) {
  SkRect rect = {10, 10, 20, 20};
  std::shared_ptr<DlBlendColorFilter> outer_filter =
      std::make_shared<DlBlendColorFilter>(DlColor::kYellow(),
                                           DlBlendMode::kColorBurn);
  std::shared_ptr<DlBlendColorFilter> inner_filter =
      std::make_shared<DlBlendColorFilter>(DlColor::kRed(),
                                           DlBlendMode::kColorBurn);

  LayerStateStack state_stack;
  state_stack.set_preroll_delegate(SkRect::MakeLTRB(0, 0, 50, 50));
  {
    auto mutator = state_stack.save();
    mutator.applyColorFilter(rect, outer_filter);

    ASSERT_EQ(state_stack.outstanding_color_filter(), outer_filter);

    // Check nested color filters result in nested saveLayers
    {
      auto mutator2 = state_stack.save();
      mutator.applyColorFilter(rect, inner_filter);

      ASSERT_EQ(state_stack.outstanding_color_filter(), inner_filter);

      // Verify output with applyState that does not accept color filters
      {
        DisplayListBuilder builder;
        state_stack.set_delegate(&builder);
        {
          auto restore = state_stack.applyState(rect, 0);
          ASSERT_EQ(state_stack.outstanding_color_filter(), nullptr);

          DlPaint paint;
          state_stack.fill(paint);
          builder.DrawRect(rect, paint);
        }
        state_stack.clear_delegate();

        DisplayListBuilder expected;
        DlPaint outer_save_paint = DlPaint().setColorFilter(outer_filter);
        DlPaint inner_save_paint = DlPaint().setColorFilter(inner_filter);
        expected.SaveLayer(&rect, &outer_save_paint);
        expected.SaveLayer(&rect, &inner_save_paint);
        expected.DrawRect(rect, DlPaint());
        expected.Restore();
        expected.Restore();
        ASSERT_TRUE(DisplayListsEQ_Verbose(builder.Build(), expected.Build()));
      }

      // Verify output with applyState that accepts color filters
      {
        SkRect rect = {10, 10, 20, 20};
        DisplayListBuilder builder;
        state_stack.set_delegate(&builder);
        {
          auto restore = state_stack.applyState(
              rect, LayerStateStack::kCallerCanApplyColorFilter);
          ASSERT_EQ(state_stack.outstanding_color_filter(), inner_filter);

          DlPaint paint;
          state_stack.fill(paint);
          builder.DrawRect(rect, paint);
        }
        state_stack.clear_delegate();

        DisplayListBuilder expected;
        DlPaint save_paint = DlPaint().setColorFilter(outer_filter);
        DlPaint draw_paint = DlPaint().setColorFilter(inner_filter);
        expected.SaveLayer(&rect, &save_paint);
        expected.DrawRect(rect, draw_paint);
        ASSERT_TRUE(DisplayListsEQ_Verbose(builder.Build(), expected.Build()));
      }
    }

    ASSERT_EQ(state_stack.outstanding_color_filter(), outer_filter);
  }

  ASSERT_EQ(state_stack.outstanding_color_filter(), nullptr);
}

TEST(LayerStateStack, ImageFilter) {
  SkRect rect = {10, 10, 20, 20};
  std::shared_ptr<DlBlurImageFilter> outer_filter =
      std::make_shared<DlBlurImageFilter>(2.0f, 2.0f, DlTileMode::kClamp);
  std::shared_ptr<DlBlurImageFilter> inner_filter =
      std::make_shared<DlBlurImageFilter>(3.0f, 3.0f, DlTileMode::kClamp);
  SkRect inner_src_rect = rect;
  SkRect outer_src_rect;
  ASSERT_EQ(inner_filter->map_local_bounds(rect, outer_src_rect),
            &outer_src_rect);

  LayerStateStack state_stack;
  state_stack.set_preroll_delegate(SkRect::MakeLTRB(0, 0, 50, 50));
  {
    auto mutator = state_stack.save();
    mutator.applyImageFilter(outer_src_rect, outer_filter);

    ASSERT_EQ(state_stack.outstanding_image_filter(), outer_filter);

    // Check nested color filters result in nested saveLayers
    {
      auto mutator2 = state_stack.save();
      mutator.applyImageFilter(rect, inner_filter);

      ASSERT_EQ(state_stack.outstanding_image_filter(), inner_filter);

      // Verify output with applyState that does not accept color filters
      {
        DisplayListBuilder builder;
        state_stack.set_delegate(&builder);
        {
          auto restore = state_stack.applyState(rect, 0);
          ASSERT_EQ(state_stack.outstanding_image_filter(), nullptr);

          DlPaint paint;
          state_stack.fill(paint);
          builder.DrawRect(rect, paint);
        }
        state_stack.clear_delegate();

        DisplayListBuilder expected;
        DlPaint outer_save_paint = DlPaint().setImageFilter(outer_filter);
        DlPaint inner_save_paint = DlPaint().setImageFilter(inner_filter);
        expected.SaveLayer(&outer_src_rect, &outer_save_paint);
        expected.SaveLayer(&inner_src_rect, &inner_save_paint);
        expected.DrawRect(rect, DlPaint());
        expected.Restore();
        expected.Restore();
        ASSERT_TRUE(DisplayListsEQ_Verbose(builder.Build(), expected.Build()));
      }

      // Verify output with applyState that accepts color filters
      {
        SkRect rect = {10, 10, 20, 20};
        DisplayListBuilder builder;
        state_stack.set_delegate(&builder);
        {
          auto restore = state_stack.applyState(
              rect, LayerStateStack::kCallerCanApplyImageFilter);
          ASSERT_EQ(state_stack.outstanding_image_filter(), inner_filter);

          DlPaint paint;
          state_stack.fill(paint);
          builder.DrawRect(rect, paint);
        }
        state_stack.clear_delegate();

        DisplayListBuilder expected;
        DlPaint save_paint = DlPaint().setImageFilter(outer_filter);
        DlPaint draw_paint = DlPaint().setImageFilter(inner_filter);
        expected.SaveLayer(&outer_src_rect, &save_paint);
        expected.DrawRect(rect, draw_paint);
        ASSERT_TRUE(DisplayListsEQ_Verbose(builder.Build(), expected.Build()));
      }
    }

    ASSERT_EQ(state_stack.outstanding_image_filter(), outer_filter);
  }

  ASSERT_EQ(state_stack.outstanding_image_filter(), nullptr);
}

TEST(LayerStateStack, OpacityAndColorFilterInteraction) {
  SkRect rect = {10, 10, 20, 20};
  std::shared_ptr<DlBlendColorFilter> color_filter =
      std::make_shared<DlBlendColorFilter>(DlColor::kYellow(),
                                           DlBlendMode::kColorBurn);

  DisplayListBuilder builder;
  LayerStateStack state_stack;
  state_stack.set_delegate(&builder);
  ASSERT_EQ(builder.GetSaveCount(), 1);

  {
    auto mutator1 = state_stack.save();
    ASSERT_EQ(builder.GetSaveCount(), 1);
    mutator1.applyOpacity(rect, 0.5f);
    ASSERT_EQ(builder.GetSaveCount(), 1);

    {
      auto mutator2 = state_stack.save();
      ASSERT_EQ(builder.GetSaveCount(), 1);
      mutator2.applyColorFilter(rect, color_filter);

      // The opacity will have been resolved by a saveLayer
      ASSERT_EQ(builder.GetSaveCount(), 2);
      ASSERT_EQ(state_stack.outstanding_color_filter(), color_filter);
      ASSERT_EQ(state_stack.outstanding_opacity(), SK_Scalar1);
    }
    ASSERT_EQ(builder.GetSaveCount(), 1);
    ASSERT_EQ(state_stack.outstanding_color_filter(), nullptr);
    ASSERT_EQ(state_stack.outstanding_opacity(), 0.5f);
  }
  ASSERT_EQ(builder.GetSaveCount(), 1);
  ASSERT_EQ(state_stack.outstanding_color_filter(), nullptr);
  ASSERT_EQ(state_stack.outstanding_opacity(), SK_Scalar1);

  {
    auto mutator1 = state_stack.save();
    ASSERT_EQ(builder.GetSaveCount(), 1);
    mutator1.applyColorFilter(rect, color_filter);
    ASSERT_EQ(builder.GetSaveCount(), 1);

    {
      auto mutator2 = state_stack.save();
      ASSERT_EQ(builder.GetSaveCount(), 1);
      mutator2.applyOpacity(rect, 0.5f);

      // color filter applied to opacity can be applied together
      ASSERT_EQ(builder.GetSaveCount(), 1);
      ASSERT_EQ(state_stack.outstanding_color_filter(), color_filter);
      ASSERT_EQ(state_stack.outstanding_opacity(), 0.5f);
    }
    ASSERT_EQ(builder.GetSaveCount(), 1);
    ASSERT_EQ(state_stack.outstanding_color_filter(), color_filter);
    ASSERT_EQ(state_stack.outstanding_opacity(), SK_Scalar1);
  }
  ASSERT_EQ(builder.GetSaveCount(), 1);
  ASSERT_EQ(state_stack.outstanding_color_filter(), nullptr);
  ASSERT_EQ(state_stack.outstanding_opacity(), SK_Scalar1);
}

TEST(LayerStateStack, OpacityAndImageFilterInteraction) {
  SkRect rect = {10, 10, 20, 20};
  std::shared_ptr<DlBlurImageFilter> image_filter =
      std::make_shared<DlBlurImageFilter>(2.0f, 2.0f, DlTileMode::kClamp);

  DisplayListBuilder builder;
  LayerStateStack state_stack;
  state_stack.set_delegate(&builder);
  ASSERT_EQ(builder.GetSaveCount(), 1);

  {
    auto mutator1 = state_stack.save();
    ASSERT_EQ(builder.GetSaveCount(), 1);
    mutator1.applyOpacity(rect, 0.5f);
    ASSERT_EQ(builder.GetSaveCount(), 1);

    {
      auto mutator2 = state_stack.save();
      ASSERT_EQ(builder.GetSaveCount(), 1);
      mutator2.applyImageFilter(rect, image_filter);

      // opacity applied to image filter can be applied together
      ASSERT_EQ(builder.GetSaveCount(), 1);
      ASSERT_EQ(state_stack.outstanding_image_filter(), image_filter);
      ASSERT_EQ(state_stack.outstanding_opacity(), 0.5f);
    }
    ASSERT_EQ(builder.GetSaveCount(), 1);
    ASSERT_EQ(state_stack.outstanding_image_filter(), nullptr);
    ASSERT_EQ(state_stack.outstanding_opacity(), 0.5f);
  }
  ASSERT_EQ(builder.GetSaveCount(), 1);
  ASSERT_EQ(state_stack.outstanding_image_filter(), nullptr);
  ASSERT_EQ(state_stack.outstanding_opacity(), SK_Scalar1);

  {
    auto mutator1 = state_stack.save();
    ASSERT_EQ(builder.GetSaveCount(), 1);
    mutator1.applyImageFilter(rect, image_filter);
    ASSERT_EQ(builder.GetSaveCount(), 1);

    {
      auto mutator2 = state_stack.save();
      ASSERT_EQ(builder.GetSaveCount(), 1);
      mutator2.applyOpacity(rect, 0.5f);

      // The image filter will have been resolved by a saveLayer
      ASSERT_EQ(builder.GetSaveCount(), 2);
      ASSERT_EQ(state_stack.outstanding_image_filter(), nullptr);
      ASSERT_EQ(state_stack.outstanding_opacity(), 0.5f);
    }
    ASSERT_EQ(builder.GetSaveCount(), 1);
    ASSERT_EQ(state_stack.outstanding_image_filter(), image_filter);
    ASSERT_EQ(state_stack.outstanding_opacity(), SK_Scalar1);
  }
  ASSERT_EQ(builder.GetSaveCount(), 1);
  ASSERT_EQ(state_stack.outstanding_image_filter(), nullptr);
  ASSERT_EQ(state_stack.outstanding_opacity(), SK_Scalar1);
}

TEST(LayerStateStack, ColorFilterAndImageFilterInteraction) {
  SkRect rect = {10, 10, 20, 20};
  std::shared_ptr<DlBlendColorFilter> color_filter =
      std::make_shared<DlBlendColorFilter>(DlColor::kYellow(),
                                           DlBlendMode::kColorBurn);
  std::shared_ptr<DlBlurImageFilter> image_filter =
      std::make_shared<DlBlurImageFilter>(2.0f, 2.0f, DlTileMode::kClamp);

  DisplayListBuilder builder;
  LayerStateStack state_stack;
  state_stack.set_delegate(&builder);
  ASSERT_EQ(builder.GetSaveCount(), 1);

  {
    auto mutator1 = state_stack.save();
    ASSERT_EQ(builder.GetSaveCount(), 1);
    mutator1.applyColorFilter(rect, color_filter);
    ASSERT_EQ(builder.GetSaveCount(), 1);

    {
      auto mutator2 = state_stack.save();
      ASSERT_EQ(builder.GetSaveCount(), 1);
      mutator2.applyImageFilter(rect, image_filter);

      // color filter applied to image filter can be applied together
      ASSERT_EQ(builder.GetSaveCount(), 1);
      ASSERT_EQ(state_stack.outstanding_image_filter(), image_filter);
      ASSERT_EQ(state_stack.outstanding_color_filter(), color_filter);
    }
    ASSERT_EQ(builder.GetSaveCount(), 1);
    ASSERT_EQ(state_stack.outstanding_image_filter(), nullptr);
    ASSERT_EQ(state_stack.outstanding_color_filter(), color_filter);
  }
  ASSERT_EQ(builder.GetSaveCount(), 1);
  ASSERT_EQ(state_stack.outstanding_image_filter(), nullptr);
  ASSERT_EQ(state_stack.outstanding_color_filter(), nullptr);

  {
    auto mutator1 = state_stack.save();
    ASSERT_EQ(builder.GetSaveCount(), 1);
    mutator1.applyImageFilter(rect, image_filter);
    ASSERT_EQ(builder.GetSaveCount(), 1);

    {
      auto mutator2 = state_stack.save();
      ASSERT_EQ(builder.GetSaveCount(), 1);
      mutator2.applyColorFilter(rect, color_filter);

      // The image filter will have been resolved by a saveLayer
      ASSERT_EQ(builder.GetSaveCount(), 2);
      ASSERT_EQ(state_stack.outstanding_image_filter(), nullptr);
      ASSERT_EQ(state_stack.outstanding_color_filter(), color_filter);
    }
    ASSERT_EQ(builder.GetSaveCount(), 1);
    ASSERT_EQ(state_stack.outstanding_image_filter(), image_filter);
    ASSERT_EQ(state_stack.outstanding_color_filter(), nullptr);
  }
  ASSERT_EQ(builder.GetSaveCount(), 1);
  ASSERT_EQ(state_stack.outstanding_image_filter(), nullptr);
  ASSERT_EQ(state_stack.outstanding_color_filter(), nullptr);
}

}  // namespace testing
}  // namespace flutter
