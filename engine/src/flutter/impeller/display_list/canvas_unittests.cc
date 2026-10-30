// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <chrono>
#include <thread>
#include <unordered_map>
#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/dl_color.h"
#include "flutter/display_list/dl_paint.h"
#include "flutter/display_list/dl_tile_mode.h"
#include "flutter/display_list/effects/dl_image_filter.h"
#include "flutter/display_list/geometry/dl_geometry_types.h"
#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/testing/testing.h"
#include "gtest/gtest.h"
#include "impeller/core/device_buffer.h"
#include "impeller/core/device_buffer_descriptor.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/display_list/aiks_context.h"
#include "impeller/display_list/aiks_unittests.h"
#include "impeller/display_list/canvas.h"
#include "impeller/display_list/dl_dispatcher.h"
#include "impeller/display_list/dl_image_impeller.h"
#include "impeller/display_list/dl_runtime_effect_impeller.h"
#include "impeller/display_list/dl_vertices_geometry.h"
#include "impeller/geometry/geometry_asserts.h"
#include "impeller/playground/playground.h"
#include "impeller/playground/widgets.h"
#include "impeller/renderer/blit_pass.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/command_queue.h"
#include "impeller/renderer/render_target.h"
#include "third_party/abseil-cpp/absl/status/status_matchers.h"

namespace impeller {
namespace testing {

std::unique_ptr<Canvas> CreateTestCanvas(
    ContentContext& context,
    std::optional<Rect> cull_rect = std::nullopt,
    bool requires_readback = false) {
  TextureDescriptor onscreen_desc;
  onscreen_desc.size = {100, 100};
  onscreen_desc.format =
      context.GetDeviceCapabilities().GetDefaultColorFormat();
  onscreen_desc.usage = TextureUsage::kRenderTarget;
  onscreen_desc.storage_mode = StorageMode::kDevicePrivate;
  onscreen_desc.sample_count = SampleCount::kCount1;
  std::shared_ptr<Texture> onscreen =
      context.GetContext()->GetResourceAllocator()->CreateTexture(
          onscreen_desc);

  ColorAttachment color0;
  color0.load_action = LoadAction::kClear;
  if (context.GetContext()->GetCapabilities()->SupportsOffscreenMSAA()) {
    TextureDescriptor onscreen_msaa_desc = onscreen_desc;
    onscreen_msaa_desc.sample_count = SampleCount::kCount4;
    onscreen_msaa_desc.storage_mode = StorageMode::kDeviceTransient;
    onscreen_msaa_desc.type = TextureType::kTexture2DMultisample;

    std::shared_ptr<Texture> onscreen_msaa =
        context.GetContext()->GetResourceAllocator()->CreateTexture(
            onscreen_msaa_desc);
    color0.resolve_texture = onscreen;
    color0.texture = onscreen_msaa;
    color0.store_action = StoreAction::kMultisampleResolve;
  } else {
    color0.texture = onscreen;
  }

  RenderTarget render_target;
  render_target.SetColorAttachment(color0, 0);

  if (cull_rect.has_value()) {
    return std::make_unique<Canvas>(
        context, render_target, /*is_onscreen=*/false,
        /*requires_readback=*/requires_readback, cull_rect.value());
  }
  return std::make_unique<Canvas>(context, render_target, /*is_onscreen=*/false,
                                  /*requires_readback=*/requires_readback);
}

TEST_P(AiksTest, TransformMultipliesCorrectly) {
  ContentContext& context = GetContentContext();
  auto canvas = CreateTestCanvas(context);

  ASSERT_MATRIX_NEAR(canvas->GetCurrentTransform(), Matrix());

  // clang-format off
  canvas->Translate(Vector3(100, 200));
  ASSERT_MATRIX_NEAR(
    canvas->GetCurrentTransform(),
    Matrix(  1,   0,   0,   0,
             0,   1,   0,   0,
             0,   0,   1,   0,
           100, 200,   0,   1));

  canvas->Rotate(Radians(kPiOver2));
  ASSERT_MATRIX_NEAR(
    canvas->GetCurrentTransform(),
    Matrix(  0,   1,   0,   0,
            -1,   0,   0,   0,
             0,   0,   1,   0,
           100, 200,   0,   1));

  canvas->Scale(Vector3(2, 3));
  ASSERT_MATRIX_NEAR(
    canvas->GetCurrentTransform(),
    Matrix(  0,   2,   0,   0,
            -3,   0,   0,   0,
             0,   0,   0,   0,
           100, 200,   0,   1));

  canvas->Translate(Vector3(100, 200));
  ASSERT_MATRIX_NEAR(
    canvas->GetCurrentTransform(),
    Matrix(   0,   2,   0,   0,
             -3,   0,   0,   0,
              0,   0,   0,   0,
           -500, 400,   0,   1));
  // clang-format on
}

TEST_P(AiksTest, CanvasCanPushPopCTM) {
  ContentContext& context = GetContentContext();
  auto canvas = CreateTestCanvas(context);

  ASSERT_EQ(canvas->GetSaveCount(), 1u);
  ASSERT_EQ(canvas->Restore(), false);

  canvas->Translate(Size{100, 100});
  canvas->Save(10);
  ASSERT_EQ(canvas->GetSaveCount(), 2u);
  ASSERT_MATRIX_NEAR(canvas->GetCurrentTransform(),
                     Matrix::MakeTranslation({100.0, 100.0, 0.0}));
  ASSERT_TRUE(canvas->Restore());
  ASSERT_EQ(canvas->GetSaveCount(), 1u);
  ASSERT_MATRIX_NEAR(canvas->GetCurrentTransform(),
                     Matrix::MakeTranslation({100.0, 100.0, 0.0}));
}

TEST_P(AiksTest, CanvasCTMCanBeUpdated) {
  ContentContext& context = GetContentContext();
  auto canvas = CreateTestCanvas(context);

  Matrix identity;
  ASSERT_MATRIX_NEAR(canvas->GetCurrentTransform(), identity);
  canvas->Translate(Size{100, 100});
  ASSERT_MATRIX_NEAR(canvas->GetCurrentTransform(),
                     Matrix::MakeTranslation({100.0, 100.0, 0.0}));
}

TEST_P(AiksTest, BackdropCountDownNormal) {
  ContentContext& context = GetContentContext();
  if (!context.GetDeviceCapabilities().SupportsFramebufferFetch()) {
    GTEST_SKIP() << "Test requires device with framebuffer fetch";
  }
  auto canvas = CreateTestCanvas(context, Rect::MakeLTRB(0, 0, 100, 100),
                                 /*requires_readback=*/true);
  // 3 backdrop filters
  canvas->SetBackdropData({}, 3);

  auto blur =
      flutter::DlImageFilter::MakeBlur(4, 4, flutter::DlTileMode::kClamp);
  flutter::DlRect rect = flutter::DlRect::MakeLTRB(0, 0, 50, 50);

  EXPECT_TRUE(canvas->RequiresReadback());
  canvas->DrawRect(rect, {.color = Color::Azure()});
  canvas->SaveLayer({}, rect, blur.get(),
                    ContentBoundsPromise::kContainsContents,
                    /*total_content_depth=*/1);
  canvas->Restore();
  EXPECT_TRUE(canvas->RequiresReadback());

  canvas->SaveLayer({}, rect, blur.get(),
                    ContentBoundsPromise::kContainsContents,
                    /*total_content_depth=*/1);
  canvas->Restore();
  EXPECT_TRUE(canvas->RequiresReadback());

  canvas->SaveLayer({}, rect, blur.get(),
                    ContentBoundsPromise::kContainsContents,
                    /*total_content_depth=*/1);
  canvas->Restore();
  EXPECT_FALSE(canvas->RequiresReadback());
}

TEST_P(AiksTest, BackdropCountDownBackdropId) {
  ContentContext& context = GetContentContext();
  if (!context.GetDeviceCapabilities().SupportsFramebufferFetch()) {
    GTEST_SKIP() << "Test requires device with framebuffer fetch";
  }
  auto canvas = CreateTestCanvas(context, Rect::MakeLTRB(0, 0, 100, 100),
                                 /*requires_readback=*/true);
  // 3 backdrop filters all with same id.
  std::unordered_map<int64_t, BackdropData> data;
  data[1] = BackdropData{.backdrop_count = 3};
  canvas->SetBackdropData(data, 3);

  auto blur =
      flutter::DlImageFilter::MakeBlur(4, 4, flutter::DlTileMode::kClamp);

  EXPECT_TRUE(canvas->RequiresReadback());
  canvas->DrawRect(flutter::DlRect::MakeLTRB(0, 0, 50, 50),
                   {.color = Color::Azure()});
  canvas->SaveLayer({}, std::nullopt, blur.get(),
                    ContentBoundsPromise::kContainsContents,
                    /*total_content_depth=*/1, /*can_distribute_opacity=*/false,
                    /*backdrop_id=*/1);
  canvas->Restore();
  EXPECT_FALSE(canvas->RequiresReadback());

  canvas->SaveLayer({}, std::nullopt, blur.get(),
                    ContentBoundsPromise::kContainsContents,
                    /*total_content_depth=*/1, /*can_distribute_opacity=*/false,
                    /*backdrop_id=*/1);
  canvas->Restore();
  EXPECT_FALSE(canvas->RequiresReadback());

  canvas->SaveLayer({}, std::nullopt, blur.get(),
                    ContentBoundsPromise::kContainsContents,
                    /*total_content_depth=*/1, /*can_distribute_opacity=*/false,
                    /*backdrop_id=*/1);
  canvas->Restore();
  EXPECT_FALSE(canvas->RequiresReadback());
}

TEST_P(AiksTest, BackdropCountDownBackdropIdMixed) {
  ContentContext& context = GetContentContext();
  if (!context.GetDeviceCapabilities().SupportsFramebufferFetch()) {
    GTEST_SKIP() << "Test requires device with framebuffer fetch";
  }
  auto canvas = CreateTestCanvas(context, Rect::MakeLTRB(0, 0, 100, 100),
                                 /*requires_readback=*/true);
  // 3 backdrop filters, 2 with same id.
  std::unordered_map<int64_t, BackdropData> data;
  data[1] = BackdropData{.backdrop_count = 2};
  canvas->SetBackdropData(data, 3);

  auto blur =
      flutter::DlImageFilter::MakeBlur(4, 4, flutter::DlTileMode::kClamp);

  EXPECT_TRUE(canvas->RequiresReadback());
  canvas->DrawRect(flutter::DlRect::MakeLTRB(0, 0, 50, 50),
                   {.color = Color::Azure()});
  canvas->SaveLayer({}, std::nullopt, blur.get(),
                    ContentBoundsPromise::kContainsContents, 1, false);
  canvas->Restore();
  EXPECT_TRUE(canvas->RequiresReadback());

  canvas->SaveLayer({}, std::nullopt, blur.get(),
                    ContentBoundsPromise::kContainsContents, 1, false, 1);
  canvas->Restore();
  EXPECT_FALSE(canvas->RequiresReadback());

  canvas->SaveLayer({}, std::nullopt, blur.get(),
                    ContentBoundsPromise::kContainsContents, 1, false, 1);
  canvas->Restore();
  EXPECT_FALSE(canvas->RequiresReadback());
}

TEST_P(AiksTest, BackdropGroupIdUsesCoverageUnionForSnapshot) {
  ContentContext& context = GetContentContext();
  auto canvas = CreateTestCanvas(context, Rect::MakeLTRB(0, 0, 1000, 1000),
                                 /*requires_readback=*/true);
  std::unordered_map<int64_t, BackdropData> data;
  data[1] = BackdropData{
      .backdrop_count = 2,
      .all_filters_equal = true,
      .coverage_union = Rect::MakeLTRB(100, 100, 200, 200),
  };
  canvas->SetBackdropData(data, 2);

  auto blur =
      flutter::DlImageFilter::MakeBlur(4, 4, flutter::DlTileMode::kClamp);

  canvas->DrawRect(flutter::DlRect::MakeLTRB(0, 0, 1000, 1000),
                   {.color = Color::Azure()});
  canvas->SaveLayer({}, std::nullopt, blur.get(),
                    ContentBoundsPromise::kContainsContents,
                    /*total_content_depth=*/1, /*can_distribute_opacity=*/false,
                    /*backdrop_id=*/1);
  canvas->Restore();

  canvas->SaveLayer({}, std::nullopt, blur.get(),
                    ContentBoundsPromise::kContainsContents,
                    /*total_content_depth=*/1, /*can_distribute_opacity=*/false,
                    /*backdrop_id=*/1);
  canvas->Restore();

  const auto& backdrop_map = canvas->GetBackdropData();
  auto it = backdrop_map.find(1);
  ASSERT_TRUE(it != backdrop_map.end());
  EXPECT_TRUE(it->second.shared_filter_snapshot.has_value());
  if (it->second.shared_filter_snapshot.has_value()) {
    ISize snapshot_size = it->second.shared_filter_snapshot->texture->GetSize();
    EXPECT_LE(snapshot_size.width, 250u);
    EXPECT_LE(snapshot_size.height, 250u);
  }
}

TEST_P(AiksTest, BackdropGroupSharedSnapshotReservesContentDepth) {
  ContentContext& context = GetContentContext();
  auto canvas = CreateTestCanvas(context, Rect::MakeLTRB(0, 0, 1000, 1000),
                                 /*requires_readback=*/true);
  std::unordered_map<int64_t, BackdropData> data;
  data[1] = BackdropData{
      .backdrop_count = 2,
      .all_filters_equal = true,
      .coverage_union = Rect::MakeLTRB(100, 100, 300, 200),
  };
  canvas->SetBackdropData(data, 2);

  auto blur =
      flutter::DlImageFilter::MakeBlur(4, 4, flutter::DlTileMode::kClamp);

  canvas->DrawRect(flutter::DlRect::MakeLTRB(0, 0, 1000, 1000),
                   {.color = Color::Azure()});
  for (int i = 0; i < 2; i++) {
    canvas->SaveLayer({}, std::nullopt, blur.get(),
                      ContentBoundsPromise::kContainsContents,
                      /*total_content_depth=*/1,
                      /*can_distribute_opacity=*/false,
                      /*backdrop_id=*/1);
    canvas->DrawRect(flutter::DlRect::MakeXYWH(100 + i * 100, 100, 100, 100),
                     {.color = Color::Red()});
    canvas->Restore();
  }

  const auto& backdrop_map = canvas->GetBackdropData();
  auto it = backdrop_map.find(1);
  ASSERT_TRUE(it != backdrop_map.end());
  EXPECT_TRUE(it->second.shared_filter_snapshot.has_value());
}

// We only know the total number of backdrop filters, not the number of backdrop
// filters in the root pass. If we reach a count of 0 while in a nested
// saveLayer, we should not restore to the onscreen.
TEST_P(AiksTest, BackdropCountDownWithNestedSaveLayers) {
  ContentContext& context = GetContentContext();
  if (!context.GetDeviceCapabilities().SupportsFramebufferFetch()) {
    GTEST_SKIP() << "Test requires device with framebuffer fetch";
  }
  auto canvas = CreateTestCanvas(context, Rect::MakeLTRB(0, 0, 100, 100),
                                 /*requires_readback=*/true);

  canvas->SetBackdropData({}, 2);

  auto blur =
      flutter::DlImageFilter::MakeBlur(4, 4, flutter::DlTileMode::kClamp);

  EXPECT_TRUE(canvas->RequiresReadback());
  canvas->DrawRect(flutter::DlRect::MakeLTRB(0, 0, 50, 50),
                   {.color = Color::Azure()});
  canvas->SaveLayer({}, std::nullopt, blur.get(),
                    ContentBoundsPromise::kContainsContents,
                    /*total_content_depth=*/3);

  // This filter is nested in the first saveLayer. We cannot restore to onscreen
  // here.
  canvas->SaveLayer({}, std::nullopt, blur.get(),
                    ContentBoundsPromise::kContainsContents,
                    /*total_content_depth=*/1);
  canvas->Restore();
  EXPECT_TRUE(canvas->RequiresReadback());

  canvas->Restore();
  EXPECT_TRUE(canvas->RequiresReadback());
}

TEST_P(AiksTest, DrawVerticesLinearGradientWithEmptySize) {
  RenderCallback callback = [&](RenderTarget& render_target) {
    ContentContext& context = GetContentContext();
    Canvas canvas(context, render_target, true, false);

    std::vector<flutter::DlPoint> vertex_coordinates = {
        flutter::DlPoint(0, 0),
        flutter::DlPoint(600, 0),
        flutter::DlPoint(0, 600),
    };
    std::vector<flutter::DlPoint> texture_coordinates = {
        flutter::DlPoint(0, 0),
        flutter::DlPoint(500, 0),
        flutter::DlPoint(0, 500),
    };
    std::vector<uint16_t> indices = {0, 1, 2};
    flutter::DlVertices::Builder vertices_builder(
        flutter::DlVertexMode::kTriangleStrip, vertex_coordinates.size(),
        flutter::DlVertices::Builder::kHasTextureCoordinates, indices.size());
    vertices_builder.store_vertices(vertex_coordinates.data());
    vertices_builder.store_indices(indices.data());
    vertices_builder.store_texture_coordinates(texture_coordinates.data());
    auto vertices = vertices_builder.build();

    // The start and end points of the gradient form an empty rectangle.
    std::vector<flutter::DlColor> colors = {flutter::DlColor::kBlue(),
                                            flutter::DlColor::kRed()};
    std::vector<Scalar> stops = {0.0, 1.0};
    auto gradient = flutter::DlColorSource::MakeLinear(
        {0, 0}, {0, 600}, 2, colors.data(), stops.data(),
        flutter::DlTileMode::kClamp);

    Paint paint;
    paint.color_source = gradient.get();
    canvas.DrawVertices(std::make_shared<DlVerticesGeometry>(vertices, context),
                        BlendMode::kSrcOver, paint);

    canvas.EndReplay();
    return true;
  };

  ASSERT_TRUE(Playground::OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, DrawVerticesWithEmptyTextureCoordinates) {
  auto runtime_stages_result =
      OpenAssetAsRuntimeStage("runtime_stage_simple.frag.iplr");
  ABSL_ASSERT_OK(runtime_stages_result);
  std::shared_ptr<RuntimeStage> runtime_stage =
      runtime_stages_result.value()[GetRuntimeStageBackend()];
  ASSERT_TRUE(runtime_stage);

  auto runtime_effect = flutter::DlRuntimeEffectImpeller::Make(runtime_stage);
  auto uniform_data = std::make_shared<std::vector<uint8_t>>();
  auto color_source = flutter::DlColorSource::MakeRuntimeEffect(
      runtime_effect, {}, uniform_data);

  RenderCallback callback = [&](RenderTarget& render_target) {
    ContentContext& context = GetContentContext();
    Canvas canvas(context, render_target, true, false);

    std::vector<flutter::DlPoint> vertex_coordinates = {
        flutter::DlPoint(100, 100),
        flutter::DlPoint(300, 100),
        flutter::DlPoint(100, 300),
    };
    // The bounding box of the texture coordinates is empty.
    std::vector<flutter::DlPoint> texture_coordinates = {
        flutter::DlPoint(0, 0),
        flutter::DlPoint(0, 100),
        flutter::DlPoint(0, 0),
    };
    std::vector<uint16_t> indices = {0, 1, 2};
    flutter::DlVertices::Builder vertices_builder(
        flutter::DlVertexMode::kTriangleStrip, vertex_coordinates.size(),
        flutter::DlVertices::Builder::kHasTextureCoordinates, indices.size());
    vertices_builder.store_vertices(vertex_coordinates.data());
    vertices_builder.store_indices(indices.data());
    vertices_builder.store_texture_coordinates(texture_coordinates.data());
    auto vertices = vertices_builder.build();

    Paint paint;
    paint.color_source = color_source.get();
    canvas.DrawVertices(std::make_shared<DlVerticesGeometry>(vertices, context),
                        BlendMode::kSrcOver, paint);

    canvas.EndReplay();
    return true;
  };

  ASSERT_TRUE(Playground::OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, SupportsBlitToOnscreen) {
  ContentContext& context = GetContentContext();
  auto canvas = CreateTestCanvas(context, Rect::MakeLTRB(0, 0, 100, 100),
                                 /*requires_readback=*/true);

  if (GetBackend() != PlaygroundBackend::kMetal &&
      GetBackend() != PlaygroundBackend::kMetalSDF) {
    EXPECT_FALSE(canvas->SupportsBlitToOnscreen());
  } else {
    EXPECT_TRUE(canvas->SupportsBlitToOnscreen());
  }
}

TEST_P(AiksTest, RoundSuperellipseShadowComparison) {
  // Config
  Size default_size(600, 400);
  Point left_center(400, 700);
  Point right_center(1300, 700);
  Color color = Color::Red();

  // Convert `color` to a `color_source`. This forces
  // `canvas.DrawRoundSuperellipse` to use the regular shadow algorithm
  // (blurring) instead of the fast shadow algorithm.
  std::shared_ptr<flutter::DlColorSource> color_source;
  {
    flutter::DlColor dl_color = flutter::DlColor(color.ToARGB());
    std::vector<flutter::DlColor> colors = {dl_color, dl_color};
    std::vector<Scalar> stops = {0.0, 1.0};
    color_source = flutter::DlColorSource::MakeLinear(
        {0, 0}, {1000, 1000}, 2, colors.data(), stops.data(),
        flutter::DlTileMode::kClamp);
  }

  RenderCallback callback = [&](RenderTarget& render_target) {
    ContentContext& context = GetContentContext();
    Canvas canvas(context, render_target, true, false);
    // Somehow there's a scaling factor between PlaygroundPoint and Canvas.
    Matrix ctm = Matrix::MakeScale(Vector2(1, 1) * 0.5);
    Matrix i_ctm = ctm.Invert();

    static Scalar sigma = 0.05;
    static Scalar radius = 200;

    // Define the ImGui
    if (IsPlaygroundEnabled()) {
      ImGui::Begin("Shadow", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
      ImGui::SliderFloat("Sigma", &sigma, 0, 100);
      ImGui::SliderFloat("Radius", &radius, 0, 1000);
      ImGui::End();
    }

    static PlaygroundPoint right_reference_var(
        ctm * (right_center + default_size / 2), 30, Color::White());
    Point right_reference = i_ctm * DrawPlaygroundPoint(right_reference_var);
    Point half_size = (right_reference - right_center).Abs();
    Rect left_bounds = Rect::MakeEllipseBounds(left_center, half_size);
    Rect right_bounds = Rect::MakeEllipseBounds(right_center, half_size);

    Paint paint{
        .color = color,
        .mask_blur_descriptor =
            Paint::MaskBlurDescriptor{
                .sigma = Sigma(sigma),
            },
    };

    // Left: Draw with canvas
    canvas.DrawRoundSuperellipse(
        RoundSuperellipse::MakeRectRadius(left_bounds, radius), paint);

    // Right: Direct draw
    paint.color_source = color_source.get();
    canvas.DrawRoundSuperellipse(
        RoundSuperellipse::MakeRectRadius(right_bounds, radius), paint);

    canvas.EndReplay();
    return true;
  };

  ASSERT_TRUE(Playground::OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, ImageTextureCacheBehavesCorrectly) {
  ContentContext& context = GetContentContext();

  TextureDescriptor desc;
  desc.size = {100, 100};
  desc.format = context.GetDeviceCapabilities().GetDefaultColorFormat();
  desc.usage = TextureUsage::kRenderTarget;
  auto texture =
      context.GetContext()->GetResourceAllocator()->CreateTexture(desc);

  auto dl_image = impeller::DlImageImpeller::Make(texture);

  context.SetTextureCachingEnabled(true);
  auto cached_tex1 = dl_image->GetCachedTexture(context);
  ASSERT_EQ(cached_tex1, texture);

  auto cached_tex2 = context.GetCachedTexture(dl_image.get());
  ASSERT_EQ(cached_tex2, texture);

  context.RemoveCachedTexture(dl_image.get());
  auto cached_tex3 = context.GetCachedTexture(dl_image.get());
  ASSERT_EQ(cached_tex3, nullptr);

  auto cached_tex4 = dl_image->GetCachedTexture(context);
  ASSERT_EQ(cached_tex4, texture);

  context.ClearCachedTextures();
  auto cached_tex5 = context.GetCachedTexture(dl_image.get());
  ASSERT_EQ(cached_tex5, nullptr);

  context.SetTextureCachingEnabled(false);
}

/// Verifies blend mode compatibility with SDF rendering.
///
/// The compatibility condition is:
/// `mix(blend(src, dst), dst, 1 - sdf_alpha) == blend(src * sdf_alpha, dst)`
TEST_P(AiksTest, BlendModeCompatibilityWithSDFRendering) {
  std::vector<Color> colors = {
      Color::BlackTransparent(),
      Color::Black(),
      Color::White(),
      Color::LimeGreen(),
      Color::CornflowerBlue(),
      Color::LimeGreen().WithAlpha(0.8),
      Color::CornflowerBlue().WithAlpha(0.7),
  };

  for (int i = 0; i <= static_cast<int>(BlendMode::kLastMode); i++) {
    BlendMode blend_mode = static_cast<BlendMode>(i);
    bool blend_mode_is_compatible = true;

    for (const auto& src : colors) {
      for (const auto& dst : colors) {
        for (Scalar sdf_alpha = 0.0; sdf_alpha < 1.01; sdf_alpha += 0.2) {
          // `mix(blend(src, dst), dst, 1 - sdf_alpha)`:
          // 1. Blend src onto dst.
          Color blended = dst.Blend(src, blend_mode);
          // 2. Mix with dst using sdf_alpha. Mix by lerping using
          // pre-multiplied colors.
          Color blended_then_sdf_alpha_applied =
              Color::Lerp(blended.Premultiply(), dst.Premultiply(),
                          1.0 - sdf_alpha)
                  .Unpremultiply();

          // `blend(src * sdf_alpha, dst)`:
          // 1. Apply sdf_alpha to src's alpha.
          Color sdf_alpha_applied = src.WithAlpha(src.alpha * sdf_alpha);
          // 2. Blend onto dst.
          Color sdf_alpha_applied_then_blended =
              dst.Blend(sdf_alpha_applied, blend_mode);

          // Compare results.
          if (blended_then_sdf_alpha_applied !=
              sdf_alpha_applied_then_blended) {
            blend_mode_is_compatible = false;
          }
        }
      }
    }

    Paint paint = {.blend_mode = blend_mode};
    EXPECT_EQ(blend_mode_is_compatible,
              Canvas::IsCompatibleWithSDFRendering(paint))
        << "Failure for BlendMode: " << BlendModeToString(blend_mode);
  }
}

TEST(CanvasTest, NonAntialiasedPaintIncompatibleWithSDFRendering) {
  Paint paint;
  paint.anti_alias = false;
  EXPECT_FALSE(Canvas::IsCompatibleWithSDFRendering(paint));
}

TEST(CanvasTest, AntialiasedPaintCompatibleWithSDFRendering) {
  Paint paint;
  EXPECT_TRUE(Canvas::IsCompatibleWithSDFRendering(paint));
}

namespace {

/// Copies `texture` into a host-visible `DeviceBuffer` via a blit pass and
/// blocks until GPU execution completes so tests can inspect raw pixel bytes
/// via `DeviceBuffer::OnGetContents()`.
std::shared_ptr<DeviceBuffer> ReadbackTextureBytes(
    const std::shared_ptr<Context>& context,
    const std::shared_ptr<Texture>& texture) {
  if (!context || !texture) {
    return nullptr;
  }
  DeviceBufferDescriptor buf_desc;
  buf_desc.size = texture->GetTextureDescriptor().GetByteSizeOfBaseMipLevel();
  buf_desc.readback = true;
  buf_desc.storage_mode = StorageMode::kHostVisible;
  std::shared_ptr<DeviceBuffer> readback_buf =
      context->GetResourceAllocator()->CreateBuffer(buf_desc);
  if (!readback_buf) {
    return nullptr;
  }

  std::shared_ptr<CommandBuffer> cmd = context->CreateCommandBuffer();
  std::shared_ptr<BlitPass> blit = cmd->CreateBlitPass();
  if (!blit->AddCopy(texture, readback_buf) || !blit->EncodeCommands()) {
    return nullptr;
  }
  auto latch = std::make_shared<fml::CountDownLatch>(1u);
  if (!context->GetCommandQueue()
           ->Submit({cmd},
                    [latch](CommandBuffer::Status) { latch->CountDown(); })
           .ok()) {
    return nullptr;
  }
  latch->Wait();
  readback_buf->Invalidate();
  return readback_buf;
}

}  // namespace

// Exercises the root-pass FlipBackdrop path (should_use_onscreen == true on
// framebuffer-fetch backends).
TEST_P(AiksTest, ClippedBackdropFilterInRootPassPreservesRoundedCorners) {
  AiksContext aiks_context(GetContext(), nullptr);
  ASSERT_TRUE(aiks_context.IsValid());

  flutter::DisplayListBuilder builder;
  builder.DrawPaint(flutter::DlPaint(flutter::DlColor::kBlack()));

  flutter::DlRect card = flutter::DlRect::MakeXYWH(40, 40, 120, 120);
  builder.ClipRoundSuperellipse(
      flutter::DlRoundSuperellipse::MakeRectXY(card, 32.0f, 32.0f));

  // Dispatch a containing ClipRect via a child DisplayList so
  // DisplayListBuilder does not elide it at recording time. RecordClip omits a
  // replay entity for the containing rect, so restoring the child scope must
  // keep the ancestor rounded clip on the replay stack.
  flutter::DisplayListBuilder child_builder;
  child_builder.ClipRect(flutter::DlRect::MakeXYWH(0, 0, 200, 200));
  child_builder.DrawRect(
      card, flutter::DlPaint(flutter::DlColor::kGreen().withAlpha(128)));
  builder.DrawDisplayList(child_builder.Build());

  auto blur = flutter::DlImageFilter::MakeBlur(10.0f, 10.0f,
                                               flutter::DlTileMode::kClamp);
  builder.SaveLayer(card, nullptr, blur.get());
  builder.DrawRect(card, flutter::DlPaint(flutter::DlColor::kWhite()));
  builder.Restore();

  std::shared_ptr<Texture> texture =
      DisplayListToTexture(builder.Build(), ISize{200, 200}, aiks_context);
  ASSERT_TRUE(texture);

  std::shared_ptr<DeviceBuffer> readback_buf =
      ReadbackTextureBytes(GetContext(), texture);
  ASSERT_TRUE(readback_buf);
  const uint8_t* bytes = readback_buf->OnGetContents();
  ASSERT_NE(bytes, nullptr);

  // `card` spans [40, 160] x [40, 160]. Top-left (42, 42) and top-right
  // (157, 42) lie inside `card` but outside the 32px corner arc, so they must
  // stay opaque black (0, 0, 0, 255) rather than bleeding white if the rounded
  // clip fails to replay after FlipBackdrop.
  for (size_t x : {42u, 157u}) {
    const size_t corner_offset = (42 * 200 + x) * 4;
    EXPECT_EQ(bytes[corner_offset + 0], 0u) << "x=" << x;
    EXPECT_EQ(bytes[corner_offset + 1], 0u) << "x=" << x;
    EXPECT_EQ(bytes[corner_offset + 2], 0u) << "x=" << x;
    EXPECT_EQ(bytes[corner_offset + 3], 255u) << "x=" << x;
  }

  // Sanity-check that the card interior at (100, 70) rendered white.
  const size_t interior_offset = (70 * 200 + 100) * 4;
  EXPECT_GT(bytes[interior_offset + 0], 240u);
  EXPECT_GT(bytes[interior_offset + 1], 240u);
  EXPECT_GT(bytes[interior_offset + 2], 240u);
  EXPECT_EQ(bytes[interior_offset + 3], 255u);
}

// Exercises the offscreen-subpass FlipBackdrop path (render_passes_.size() ==
// 2 inside an opacity SaveLayer anchored at (0, 0) via DrawPaint, so
// should_use_onscreen == false).
TEST_P(AiksTest, ClippedBackdropFilterInSubpassPreservesRoundedCorners) {
  AiksContext aiks_context(GetContext(), nullptr);
  ASSERT_TRUE(aiks_context.IsValid());

  flutter::DisplayListBuilder builder;
  flutter::DlPaint black_paint(flutter::DlColor::kBlack());
  builder.DrawPaint(black_paint);

  flutter::DlPaint opacity_paint;
  opacity_paint.setOpacity(0.98f);
  builder.SaveLayer(flutter::DlRect::MakeXYWH(0, 0, 200, 200), &opacity_paint);
  builder.DrawPaint(black_paint);

  flutter::DlRect card = flutter::DlRect::MakeXYWH(40, 40, 120, 120);
  builder.ClipRoundSuperellipse(
      flutter::DlRoundSuperellipse::MakeRectXY(card, 32.0f, 32.0f));

  // Dispatch a containing ClipRect via a child DisplayList so
  // DisplayListBuilder does not elide it at recording time. RecordClip omits a
  // replay entity for the containing rect, so restoring the child scope must
  // keep the ancestor rounded clip on the replay stack.
  flutter::DisplayListBuilder child_builder;
  child_builder.ClipRect(flutter::DlRect::MakeXYWH(0, 0, 200, 200));
  child_builder.DrawRect(
      card, flutter::DlPaint(flutter::DlColor::kGreen().withAlpha(128)));
  builder.DrawDisplayList(child_builder.Build());

  auto blur = flutter::DlImageFilter::MakeBlur(10.0f, 10.0f,
                                               flutter::DlTileMode::kClamp);
  builder.SaveLayer(card, nullptr, blur.get());
  builder.DrawRect(card, flutter::DlPaint(flutter::DlColor::kWhite()));
  builder.Restore();
  builder.Restore();

  std::shared_ptr<Texture> texture =
      DisplayListToTexture(builder.Build(), ISize{200, 200}, aiks_context);
  ASSERT_TRUE(texture);

  std::shared_ptr<DeviceBuffer> readback_buf =
      ReadbackTextureBytes(GetContext(), texture);
  ASSERT_TRUE(readback_buf);
  const uint8_t* bytes = readback_buf->OnGetContents();
  ASSERT_NE(bytes, nullptr);

  // `card` spans [40, 160] x [40, 160]. Top-left (42, 42) and top-right
  // (157, 42) lie inside `card` but outside the 32px corner arc, so they must
  // stay opaque black (0, 0, 0, 255) rather than bleeding white if the rounded
  // clip fails to replay after FlipBackdrop.
  for (size_t x : {42u, 157u}) {
    const size_t corner_offset = (42 * 200 + x) * 4;
    EXPECT_EQ(bytes[corner_offset + 0], 0u) << "x=" << x;
    EXPECT_EQ(bytes[corner_offset + 1], 0u) << "x=" << x;
    EXPECT_EQ(bytes[corner_offset + 2], 0u) << "x=" << x;
    EXPECT_EQ(bytes[corner_offset + 3], 255u) << "x=" << x;
  }

  // Sanity-check that the card interior at (100, 70) rendered white.
  const size_t interior_offset = (70 * 200 + 100) * 4;
  EXPECT_GT(bytes[interior_offset + 0], 240u);
  EXPECT_GT(bytes[interior_offset + 1], 240u);
  EXPECT_GT(bytes[interior_offset + 2], 240u);
  EXPECT_EQ(bytes[interior_offset + 3], 255u);
}

TEST_P(AiksTest, ClippedBackdropFilterPreservesAlpha) {
  AiksContext aiks_context(GetContext(), nullptr);
  ASSERT_TRUE(aiks_context.IsValid());

  // Keep 4x MSAA D32FS8 (~900 KB at 160x180) under VMA's 2 MB dedicated
  // allocation threshold, and hold a ~1.44 MB texture so VMA sizes and retains
  // a single 4 MB device-local block across snapshots.
  TextureDescriptor seed_desc;
  seed_desc.storage_mode = StorageMode::kDevicePrivate;
  seed_desc.format = PixelFormat::kR8G8B8A8UNormInt;
  seed_desc.size = {600, 600};
  seed_desc.usage = TextureUsage::kRenderTarget | TextureUsage::kShaderRead;
  std::shared_ptr<Texture> seed_tex =
      GetContext()->GetResourceAllocator()->CreateTexture(seed_desc);
  ASSERT_TRUE(seed_tex);

  const ISize kTargetSize = {160, 180};

  // 1. Prime VMA's block with non-zero 4x MSAA clip depth values across
  // (0, 0, 150, 180). Difference clips always write depth rather than using
  // hardware scissor.
  {
    flutter::DisplayListBuilder prime_builder;
    prime_builder.ClipRect(flutter::DlRect::MakeXYWH(0, 0, 150, 180),
                           flutter::DlClipOp::kDifference);
    for (int i = 0; i < 4; i++) {
      prime_builder.DrawRect(flutter::DlRect::MakeXYWH(152, 0, 4, 4),
                             flutter::DlPaint(flutter::DlColor::kWhite()));
    }
    std::shared_ptr<Texture> prime_tex =
        DisplayListToTexture(prime_builder.Build(), kTargetSize, aiks_context);
    ASSERT_TRUE(prime_tex);
    ASSERT_TRUE(ReadbackTextureBytes(GetContext(), prime_tex));
  }
  // Allow ResourceManagerVK's background reaper thread to return the priming
  // suballocations to VMA before the next snapshot (if the reaper lags under
  // heavy load, VMA allocates fresh zeroed memory and the test safely passes).
  if (GetBackend() == PlaygroundBackend::kVulkan) {
    std::this_thread::sleep_for(std::chrono::milliseconds(20));
  }

  // 2. Render a single root-clipped BackdropFilter over a transparent
  // background. On framebuffer-fetch backends, should_use_onscreen == true
  // flips directly onto render_target_ via InlinePassContext, clearing the
  // recycled MSAA depth attachment rather than falling back to BlitToOnscreen
  // with LoadAction::kDontCare depth.
  flutter::DisplayListBuilder sheet_builder;
  flutter::DlRect sheet = flutter::DlRect::MakeXYWH(20, 10, 120, 70);
  sheet_builder.ClipRoundSuperellipse(
      flutter::DlRoundSuperellipse::MakeRectXY(sheet, 12.0f, 12.0f));
  auto blur = flutter::DlImageFilter::MakeBlur(10.0f, 10.0f,
                                               flutter::DlTileMode::kClamp);
  sheet_builder.SaveLayer(sheet, nullptr, blur.get());
  sheet_builder.DrawRect(
      sheet, flutter::DlPaint(flutter::DlColor::kWhite().withAlpha(200)));
  sheet_builder.Restore();

  std::shared_ptr<Texture> sheet_tex =
      DisplayListToTexture(sheet_builder.Build(), kTargetSize, aiks_context);
  ASSERT_TRUE(sheet_tex);

  std::shared_ptr<DeviceBuffer> readback_buf =
      ReadbackTextureBytes(GetContext(), sheet_tex);
  ASSERT_TRUE(readback_buf);
  const uint8_t* bytes = readback_buf->OnGetContents();
  ASSERT_NE(bytes, nullptr);

  // Over a transparent (0, 0, 0, 0) backdrop, `kWhite().withAlpha(200)`
  // produces premultiplied (200, 200, 200, 200) at interior pixel (80, 45).
  // Check channel 0 (R in RGBA, B in Metal's BGRA) and alpha (offset + 3) to
  // verify stale MSAA depth subsamples did not reject or attenuate samples.
  const size_t offset = (45 * 160 + 80) * 4;
  EXPECT_NEAR(bytes[offset + 0], 200, 2);
  EXPECT_NEAR(bytes[offset + 3], 200, 2);
}

}  // namespace testing
}  // namespace impeller
