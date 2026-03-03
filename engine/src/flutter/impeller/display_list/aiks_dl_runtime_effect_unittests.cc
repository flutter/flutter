// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>

#include "absl/status/statusor.h"

#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/dl_paint.h"
#include "flutter/display_list/effects/dl_color_source.h"
#include "flutter/display_list/effects/dl_image_filter.h"
#include "flutter/display_list/effects/dl_runtime_effect.h"
#include "flutter/impeller/display_list/aiks_unittests.h"
#include "flutter/impeller/display_list/dl_image_impeller.h"
#include "flutter/impeller/display_list/dl_runtime_effect_impeller.h"
#include "imgui.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/vector.h"
#include "third_party/abseil-cpp/absl/status/status_matchers.h"

namespace impeller {
namespace testing {

using namespace flutter;

namespace {
absl::StatusOr<std::shared_ptr<DlColorSource>> MakeRuntimeEffect(
    AiksTest* test,
    std::string_view name,
    const std::shared_ptr<std::vector<uint8_t>>& uniform_data = {},
    const std::vector<std::shared_ptr<DlColorSource>>& samplers = {}) {
  auto runtime_stages_result = test->OpenAssetAsRuntimeStage(name.data());
  if (!runtime_stages_result.ok()) {
    return runtime_stages_result.status();
  }
  std::shared_ptr<RuntimeStage> runtime_stage =
      runtime_stages_result
          .value()[PlaygroundBackendToRuntimeStageBackend(test->GetBackend())];
  if (!runtime_stage) {
    return absl::InternalError("Runtime stage not found for backend.");
  }
  if (!runtime_stage->IsDirty()) {
    return absl::InternalError("Runtime stage is not dirty.");
  }

  auto dl_runtime_effect = DlRuntimeEffectImpeller::Make(runtime_stage);

  return DlColorSource::MakeRuntimeEffect(dl_runtime_effect, samplers,
                                          uniform_data);
}
}  // namespace

// Regression test for https://github.com/flutter/flutter/issues/126701 .
TEST_P(AiksTest, CanRenderClippedRuntimeEffects) {
  struct FragUniforms {
    Vector2 iResolution;
    Scalar iTime;
  } frag_uniforms = {.iResolution = Vector2(400, 400), .iTime = 100.0};
  auto uniform_data = std::make_shared<std::vector<uint8_t>>();
  uniform_data->resize(sizeof(FragUniforms));
  memcpy(uniform_data->data(), &frag_uniforms, sizeof(FragUniforms));

  DlPaint paint;
  auto effect =
      MakeRuntimeEffect(this, "runtime_stage_example.frag.iplr", uniform_data);
  ABSL_ASSERT_OK(effect);
  paint.setColorSource(effect.value());

  DisplayListBuilder builder;
  builder.Save();
  builder.ClipRoundRect(
      DlRoundRect::MakeRectXY(DlRect::MakeXYWH(0, 0, 400, 400), 10.0, 10.0),
      DlClipOp::kIntersect);
  builder.DrawRect(DlRect::MakeXYWH(0, 0, 400, 400), paint);
  builder.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, DrawPaintTransformsBounds) {
  struct FragUniforms {
    Size size;
  } frag_uniforms = {.size = Size::MakeWH(400, 400)};
  auto uniform_data = std::make_shared<std::vector<uint8_t>>();
  uniform_data->resize(sizeof(FragUniforms));
  memcpy(uniform_data->data(), &frag_uniforms, sizeof(FragUniforms));

  DlPaint paint;
  auto effect = MakeRuntimeEffect(this, "gradient.frag.iplr", uniform_data);
  ABSL_ASSERT_OK(effect);
  paint.setColorSource(effect.value());

  DisplayListBuilder builder;
  builder.Save();
  builder.Scale(GetContentScale().x, GetContentScale().y);
  builder.DrawPaint(paint);
  builder.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanRenderRuntimeEffectFilter) {
  auto runtime_stages_result =
      OpenAssetAsRuntimeStage("runtime_stage_filter_example.frag.iplr");
  ABSL_ASSERT_OK(runtime_stages_result);
  std::shared_ptr<RuntimeStage> runtime_stage =
      runtime_stages_result
          .value()[PlaygroundBackendToRuntimeStageBackend(GetBackend())];
  ASSERT_TRUE(runtime_stage);
  ASSERT_TRUE(runtime_stage->IsDirty());

  std::vector<std::shared_ptr<DlColorSource>> sampler_inputs = {
      nullptr,
  };
  auto uniform_data = std::make_shared<std::vector<uint8_t>>();
  uniform_data->resize(sizeof(Vector2));

  DlPaint paint;
  paint.setColor(DlColor::kAqua());
  paint.setImageFilter(DlImageFilter::MakeRuntimeEffect(
      DlRuntimeEffectImpeller::Make(runtime_stage), sampler_inputs,
      uniform_data));

  DisplayListBuilder builder;
  builder.DrawRect(DlRect::MakeXYWH(0, 0, 400, 400), paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, RuntimeEffectWithInvalidSamplerDoesNotCrash) {
  ScopedValidationDisable disable_validation;

  // Create a sampler that is not usable as an input to the runtime effect.
  std::vector<flutter::DlColor> colors = {flutter::DlColor::kBlue(),
                                          flutter::DlColor::kRed()};
  const float stops[2] = {0.0, 1.0};
  auto linear = flutter::DlColorSource::MakeLinear({0.0, 0.0}, {300.0, 300.0},
                                                   2, colors.data(), stops,
                                                   flutter::DlTileMode::kClamp);
  std::vector<std::shared_ptr<DlColorSource>> sampler_inputs = {
      linear,
  };

  auto uniform_data = std::make_shared<std::vector<uint8_t>>();
  uniform_data->resize(sizeof(Vector2));

  DlPaint paint;
  auto effect =
      MakeRuntimeEffect(this, "runtime_stage_filter_example.frag.iplr",
                        uniform_data, sampler_inputs);
  ABSL_ASSERT_OK(effect);
  paint.setColorSource(effect.value());

  DisplayListBuilder builder;
  builder.DrawPaint(paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, ComposePaintRuntimeOuter) {
  DisplayListBuilder builder;
  DlPaint background;
  background.setColor(DlColor(1.0, 0.1, 0.1, 0.1, DlColorSpace::kSRGB));
  builder.DrawPaint(background);

  DlPaint paint;
  paint.setColor(DlColor::kGreen());
  float matrix[] = {
      0, 1, 0, 0, 0,  //
      1, 0, 0, 0, 0,  //
      0, 0, 1, 0, 0,  //
      0, 0, 0, 1, 0   //
  };
  std::shared_ptr<DlImageFilter> color_filter =
      DlImageFilter::MakeColorFilter(DlColorFilter::MakeMatrix(matrix));

  auto runtime_stages_result =
      OpenAssetAsRuntimeStage("runtime_stage_filter_warp.frag.iplr");
  ABSL_ASSERT_OK(runtime_stages_result);
  std::shared_ptr<RuntimeStage> runtime_stage =
      runtime_stages_result
          .value()[PlaygroundBackendToRuntimeStageBackend(GetBackend())];
  ASSERT_TRUE(runtime_stage);
  ASSERT_TRUE(runtime_stage->IsDirty());

  std::vector<std::shared_ptr<DlColorSource>> sampler_inputs = {
      nullptr,
  };
  auto uniform_data = std::make_shared<std::vector<uint8_t>>();
  uniform_data->resize(sizeof(Vector2));

  auto runtime_filter = DlImageFilter::MakeRuntimeEffect(
      DlRuntimeEffectImpeller::Make(runtime_stage), sampler_inputs,
      uniform_data);

  builder.Translate(50, 50);
  builder.Scale(0.7, 0.7);

  paint.setImageFilter(
      DlImageFilter::MakeCompose(runtime_filter, color_filter));
  auto image = DlImageImpeller::Make(CreateTextureForFixture("kalimba.jpg"));
  builder.DrawImage(image, DlPoint(100.0, 100.0),
                    DlImageSampling::kNearestNeighbor, &paint);

  DlPaint green;
  green.setColor(DlColor::kGreen());
  builder.DrawLine({100, 100}, {200, 100}, green);
  builder.DrawLine({100, 100}, {100, 200}, green);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, ComposePaintRuntimeInner) {
  auto runtime_stages_result =
      OpenAssetAsRuntimeStage("runtime_stage_filter_warp.frag.iplr");
  ABSL_ASSERT_OK(runtime_stages_result);
  std::shared_ptr<RuntimeStage> runtime_stage =
      runtime_stages_result
          .value()[PlaygroundBackendToRuntimeStageBackend(GetBackend())];
  ASSERT_TRUE(runtime_stage);
  ASSERT_TRUE(runtime_stage->IsDirty());
  Scalar xoffset = 50;
  Scalar yoffset = 50;
  Scalar xscale = 0.7;
  Scalar yscale = 0.7;
  bool compare = false;

  auto callback = [&]() -> sk_sp<DisplayList> {
    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::SliderFloat("xoffset", &xoffset, -50, 50);
      ImGui::SliderFloat("yoffset", &yoffset, -50, 50);
      ImGui::SliderFloat("xscale", &xscale, 0, 1);
      ImGui::SliderFloat("yscale", &yscale, 0, 1);
      ImGui::Checkbox("compare", &compare);
      ImGui::End();
    }
    DisplayListBuilder builder;
    DlPaint background;
    background.setColor(DlColor(1.0, 0.1, 0.1, 0.1, DlColorSpace::kSRGB));
    builder.DrawPaint(background);

    DlPaint paint;
    paint.setColor(DlColor::kGreen());
    float matrix[] = {
        0, 1, 0, 0, 0,  //
        1, 0, 0, 0, 0,  //
        0, 0, 1, 0, 0,  //
        0, 0, 0, 1, 0   //
    };
    std::shared_ptr<DlImageFilter> color_filter =
        DlImageFilter::MakeColorFilter(DlColorFilter::MakeMatrix(matrix));

    std::vector<std::shared_ptr<DlColorSource>> sampler_inputs = {
        nullptr,
    };
    auto uniform_data = std::make_shared<std::vector<uint8_t>>();
    uniform_data->resize(sizeof(Vector2));

    auto runtime_filter = DlImageFilter::MakeRuntimeEffect(
        DlRuntimeEffectImpeller::Make(runtime_stage), sampler_inputs,
        uniform_data);

    builder.Translate(xoffset, yoffset);
    builder.Scale(xscale, yscale);

    paint.setImageFilter(
        DlImageFilter::MakeCompose(color_filter, runtime_filter));
    auto image = DlImageImpeller::Make(CreateTextureForFixture("kalimba.jpg"));
    builder.DrawImage(image, DlPoint(100.0, 100.0),
                      DlImageSampling::kNearestNeighbor, &paint);

    if (compare) {
      paint.setImageFilter(
          DlImageFilter::MakeCompose(runtime_filter, color_filter));
      builder.DrawImage(image, DlPoint(800.0, 100.0),
                        DlImageSampling::kNearestNeighbor, &paint);

      paint.setImageFilter(runtime_filter);
      builder.DrawImage(image, DlPoint(100.0, 800.0),
                        DlImageSampling::kNearestNeighbor, &paint);
    }

    DlPaint green;
    green.setColor(DlColor::kGreen());
    builder.DrawLine({100, 100}, {200, 100}, green);
    builder.DrawLine({100, 100}, {100, 200}, green);
    if (compare) {
      builder.DrawLine({800, 100}, {900, 100}, green);
      builder.DrawLine({800, 100}, {800, 200}, green);
      builder.DrawLine({100, 800}, {200, 800}, green);
      builder.DrawLine({100, 800}, {100, 900}, green);
    }

    return builder.Build();
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, ComposeBackdropRuntimeOuterBlurInner) {
  auto runtime_stages_result =
      OpenAssetAsRuntimeStage("runtime_stage_filter_circle.frag.iplr");
  ABSL_ASSERT_OK(runtime_stages_result);
  std::shared_ptr<RuntimeStage> runtime_stage =
      runtime_stages_result
          .value()[PlaygroundBackendToRuntimeStageBackend(GetBackend())];
  ASSERT_TRUE(runtime_stage);
  ASSERT_TRUE(runtime_stage->IsDirty());
  Scalar sigma = 20.0;

  auto callback = [&]() -> sk_sp<DisplayList> {
    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::SliderFloat("sigma", &sigma, 0, 20);
      ImGui::End();
    }
    DisplayListBuilder builder;
    DlPaint background;
    background.setColor(DlColor(1.0, 0.1, 0.1, 0.1, DlColorSpace::kSRGB));
    builder.DrawPaint(background);

    auto blur_filter =
        DlImageFilter::MakeBlur(sigma, sigma, DlTileMode::kClamp);

    std::vector<std::shared_ptr<DlColorSource>> sampler_inputs = {
        nullptr,
    };

    struct FragUniforms {
      Vector2 size;
      Vector2 origin;
    } frag_uniforms = {.size = Vector2(1, 1), .origin = Vector2(30.f, 30.f)};
    auto uniform_data = std::make_shared<std::vector<uint8_t>>();
    uniform_data->resize(sizeof(FragUniforms));
    memcpy(uniform_data->data(), &frag_uniforms, sizeof(FragUniforms));

    auto runtime_filter = DlImageFilter::MakeRuntimeEffect(
        DlRuntimeEffectImpeller::Make(runtime_stage), sampler_inputs,
        uniform_data);

    auto backdrop_filter = DlImageFilter::MakeCompose(/*outer=*/runtime_filter,
                                                      /*inner=*/blur_filter);

    DlPaint paint;
    auto image = DlImageImpeller::Make(CreateTextureForFixture("kalimba.jpg"));
    builder.DrawImage(image, DlPoint(100.0, 100.0),
                      DlImageSampling::kNearestNeighbor, &paint);

    DlPaint save_paint;
    save_paint.setBlendMode(DlBlendMode::kSrc);
    builder.SaveLayer(std::nullopt, &save_paint, backdrop_filter.get());
    builder.Restore();

    DlPaint green;
    green.setColor(DlColor::kGreen());
    builder.DrawLine({100, 100}, {200, 100}, green);
    builder.DrawLine({100, 100}, {100, 200}, green);

    return builder.Build();
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, ComposeBackdropRuntimeOuterBlurInnerSmallSigma) {
  auto runtime_stages_result =
      OpenAssetAsRuntimeStage("runtime_stage_filter_circle.frag.iplr");
  ABSL_ASSERT_OK(runtime_stages_result);
  std::shared_ptr<RuntimeStage> runtime_stage =
      runtime_stages_result
          .value()[PlaygroundBackendToRuntimeStageBackend(GetBackend())];
  ASSERT_TRUE(runtime_stage);
  ASSERT_TRUE(runtime_stage->IsDirty());
  Scalar sigma = 5.0;

  auto callback = [&]() -> sk_sp<DisplayList> {
    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::SliderFloat("sigma", &sigma, 0, 20);
      ImGui::End();
    }
    DisplayListBuilder builder;
    DlPaint background;
    background.setColor(DlColor(1.0, 0.1, 0.1, 0.1, DlColorSpace::kSRGB));
    builder.DrawPaint(background);

    auto blur_filter =
        DlImageFilter::MakeBlur(sigma, sigma, DlTileMode::kClamp);

    std::vector<std::shared_ptr<DlColorSource>> sampler_inputs = {
        nullptr,
    };
    struct FragUniforms {
      Vector2 size;
      Vector2 origin;
    } frag_uniforms = {.size = Vector2(1, 1), .origin = Vector2(30.f, 30.f)};
    auto uniform_data = std::make_shared<std::vector<uint8_t>>();
    uniform_data->resize(sizeof(FragUniforms));
    memcpy(uniform_data->data(), &frag_uniforms, sizeof(FragUniforms));

    auto runtime_filter = DlImageFilter::MakeRuntimeEffect(
        DlRuntimeEffectImpeller::Make(runtime_stage), sampler_inputs,
        uniform_data);

    auto backdrop_filter = DlImageFilter::MakeCompose(/*outer=*/runtime_filter,
                                                      /*inner=*/blur_filter);

    DlPaint paint;
    auto image = DlImageImpeller::Make(CreateTextureForFixture("kalimba.jpg"));
    builder.DrawImage(image, DlPoint(100.0, 100.0),
                      DlImageSampling::kNearestNeighbor, &paint);

    DlPaint save_paint;
    save_paint.setBlendMode(DlBlendMode::kSrc);
    builder.SaveLayer(std::nullopt, &save_paint, backdrop_filter.get());
    builder.Restore();

    DlPaint green;
    green.setColor(DlColor::kGreen());
    builder.DrawLine({100, 100}, {200, 100}, green);
    builder.DrawLine({100, 100}, {100, 200}, green);

    return builder.Build();
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, ClippedComposeBackdropRuntimeOuterBlurInnerSmallSigma) {
  auto runtime_stages_result =
      OpenAssetAsRuntimeStage("runtime_stage_filter_circle.frag.iplr");
  ABSL_ASSERT_OK(runtime_stages_result);
  std::shared_ptr<RuntimeStage> runtime_stage =
      runtime_stages_result
          .value()[PlaygroundBackendToRuntimeStageBackend(GetBackend())];
  ASSERT_TRUE(runtime_stage);
  ASSERT_TRUE(runtime_stage->IsDirty());
  Scalar sigma = 5.0;
  Vector2 clip_origin = Vector2(20.f, 20.f);
  Vector2 clip_size = Vector2(300, 300);
  Vector2 circle_origin = Vector2(30.f, 30.f);

  auto callback = [&]() -> sk_sp<DisplayList> {
    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::SliderFloat("sigma", &sigma, 0, 20);
      ImGui::SliderFloat("clip_x", &clip_origin.x, 0, 2048.f);
      ImGui::SliderFloat("clip_y", &clip_origin.y, 0, 1536.f);
      ImGui::SliderFloat("clip_width", &clip_size.x, 0, 2048.f);
      ImGui::SliderFloat("clip_height", &clip_size.y, 0, 1536.f);
      ImGui::SliderFloat("circle_x", &circle_origin.x, 0.f, 2048.f);
      ImGui::SliderFloat("circle_y", &circle_origin.y, 0.f, 1536.f);
      ImGui::End();
    }
    DisplayListBuilder builder;
    DlPaint background;
    background.setColor(DlColor(1.0, 0.1, 0.1, 0.1, DlColorSpace::kSRGB));
    builder.DrawPaint(background);

    auto blur_filter =
        DlImageFilter::MakeBlur(sigma, sigma, DlTileMode::kClamp);

    std::vector<std::shared_ptr<DlColorSource>> sampler_inputs = {
        nullptr,
    };
    struct FragUniforms {
      Vector2 size;
      Vector2 origin;
    } frag_uniforms = {.size = Vector2(1, 1), .origin = circle_origin};
    auto uniform_data = std::make_shared<std::vector<uint8_t>>();
    uniform_data->resize(sizeof(FragUniforms));
    memcpy(uniform_data->data(), &frag_uniforms, sizeof(FragUniforms));

    auto runtime_filter = DlImageFilter::MakeRuntimeEffect(
        DlRuntimeEffectImpeller::Make(runtime_stage), sampler_inputs,
        uniform_data);

    auto backdrop_filter = DlImageFilter::MakeCompose(/*outer=*/runtime_filter,
                                                      /*inner=*/blur_filter);

    builder.ClipRect(DlRect::MakeXYWH(clip_origin.x, clip_origin.y, clip_size.x,
                                      clip_size.y));

    DlPaint paint;
    auto image = DlImageImpeller::Make(CreateTextureForFixture("kalimba.jpg"));
    builder.DrawImage(image, DlPoint(100.0, 100.0),
                      DlImageSampling::kNearestNeighbor, &paint);

    DlPaint save_paint;
    save_paint.setBlendMode(DlBlendMode::kSrc);
    builder.SaveLayer(std::nullopt, &save_paint, backdrop_filter.get());
    builder.Restore();

    DlPaint green;
    green.setColor(DlColor::kGreen());
    builder.DrawLine({100, 100}, {200, 100}, green);
    builder.DrawLine({100, 100}, {100, 200}, green);

    return builder.Build();
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, ClippedBackdropFilterWithShader) {
  struct FragUniforms {
    Vector2 uSize;
  } frag_uniforms = {.uSize = Vector2(400, 400)};
  auto uniform_data = std::make_shared<std::vector<uint8_t>>();
  uniform_data->resize(sizeof(FragUniforms));
  memcpy(uniform_data->data(), &frag_uniforms, sizeof(FragUniforms));

  auto runtime_stages_result =
      OpenAssetAsRuntimeStage("runtime_stage_border.frag.iplr");
  ABSL_ASSERT_OK(runtime_stages_result);
  std::shared_ptr<RuntimeStage> runtime_stage =
      runtime_stages_result
          .value()[PlaygroundBackendToRuntimeStageBackend(GetBackend())];
  ASSERT_TRUE(runtime_stage);
  ASSERT_TRUE(runtime_stage->IsDirty());

  std::vector<std::shared_ptr<DlColorSource>> sampler_inputs = {
      nullptr,
  };

  auto runtime_filter = DlImageFilter::MakeRuntimeEffect(
      DlRuntimeEffectImpeller::Make(runtime_stage), sampler_inputs,
      uniform_data);

  DisplayListBuilder builder;

  // Draw a background so the backdrop filter has something to affect
  DlPaint background_paint;
  background_paint.setColor(DlColor::kWhite());
  builder.DrawPaint(background_paint);

  // Draw some pattern to verify the filter effect
  DlPaint pattern_paint;
  pattern_paint.setColor(DlColor::kRed());
  builder.DrawRect(DlRect::MakeXYWH(0, 0, 200, 200), pattern_paint);
  pattern_paint.setColor(DlColor::kBlue());
  builder.DrawRect(DlRect::MakeXYWH(200, 200, 200, 200), pattern_paint);

  builder.Save();

  // Replicate the clip rect (inset by 66)
  // Assuming a 400x400 screen, inset 66 gives roughly 66, 66, 268, 268
  builder.ClipRect(DlRect::MakeXYWH(66, 66, 268, 268));

  DlPaint save_paint;
  // The Flutter code uses a backdrop filter layer.
  // In DisplayList, this corresponds to SaveLayer with a backdrop filter.
  builder.SaveLayer(std::nullopt, &save_paint, runtime_filter.get());

  // The child was empty in the Flutter example, so we don't draw anything
  // inside the SaveLayer

  builder.Restore();  // Restore SaveLayer
  builder.Restore();  // Restore Save (Clip)

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, RuntimeEffectImageFilterRotated) {
  auto image = DlImageImpeller::Make(CreateTextureForFixture("kalimba.jpg"));
  auto size = image->GetBounds().GetSize();

  struct FragUniforms {
    Size size;
  } frag_uniforms = {.size = Size(size.width, size.height)};
  auto uniform_data = std::make_shared<std::vector<uint8_t>>();
  uniform_data->resize(sizeof(FragUniforms));
  memcpy(uniform_data->data(), &frag_uniforms, sizeof(FragUniforms));

  auto runtime_stages_result = OpenAssetAsRuntimeStage("gradient.frag.iplr");
  ABSL_ASSERT_OK(runtime_stages_result);
  std::shared_ptr<RuntimeStage> runtime_stage =
      runtime_stages_result
          .value()[PlaygroundBackendToRuntimeStageBackend(GetBackend())];
  ASSERT_TRUE(runtime_stage);
  ASSERT_TRUE(runtime_stage->IsDirty());

  std::vector<std::shared_ptr<DlColorSource>> sampler_inputs = {
      nullptr,
  };

  auto runtime_filter = DlImageFilter::MakeRuntimeEffect(
      DlRuntimeEffectImpeller::Make(runtime_stage), sampler_inputs,
      uniform_data);

  Scalar rotation = 45;

  auto callback = [&]() -> sk_sp<DisplayList> {
    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::SliderFloat("rotation", &rotation, 0, 360);
      ImGui::End();
    }
    DisplayListBuilder builder;
    builder.Translate(size.width * 0.5, size.height * 0.5);
    builder.Rotate(rotation);
    builder.Translate(-size.width * 0.5, -size.height * 0.5);

    DlPaint paint;
    paint.setImageFilter(runtime_filter);
    builder.DrawImage(image, DlPoint(0.0, 0.0),
                      DlImageSampling::kNearestNeighbor, &paint);

    return builder.Build();
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, RuntimeEffectVectorArray) {
  constexpr float kDimension = 400.0f;
  struct FragUniforms {
    Vector2 iResolution;
    Vector4 iValues;
  } frag_uniforms = {.iResolution = Vector2(kDimension, kDimension),
                     .iValues = Vector4(0.25, 0.50, 0.75, 1.0)};
  auto uniform_data = std::make_shared<std::vector<uint8_t>>();
  uniform_data->resize(sizeof(FragUniforms));
  memcpy(uniform_data->data(), &frag_uniforms, sizeof(FragUniforms));

  DlPaint paint;
  auto effect = MakeRuntimeEffect(this, "runtime_stage_vector_array.frag.iplr",
                                  uniform_data);
  ABSL_ASSERT_OK(effect);
  paint.setColorSource(effect.value());

  DisplayListBuilder builder;
  builder.DrawRect(DlRect::MakeXYWH(0, 0, kDimension, kDimension), paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

}  // namespace testing
}  // namespace impeller
