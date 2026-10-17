// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <memory>

#include "flutter/display_list/effects/dl_color_filter.h"
#include "flutter/display_list/effects/image_filters/dl_blur_image_filter.h"
#include "flutter/display_list/effects/image_filters/dl_color_filter_image_filter.h"
#include "flutter/display_list/effects/image_filters/dl_compose_image_filter.h"
#include "flutter/flow/embedded_views.h"
#include "flutter/fml/message_loop.h"
#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder_2.h"
#include "flutter/shell/platform/android/jni/jni_mock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

constexpr double kDpr = 2.0;
const DlISize kFrameSize = DlISize(1000, 2000);

TaskRunners GetTaskRunnersForFixture() {
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  auto& loop = fml::MessageLoop::GetCurrent();
  return {
      "test",
      loop.GetTaskRunner(),  // platform
      loop.GetTaskRunner(),  // raster
      loop.GetTaskRunner(),  // ui
      loop.GetTaskRunner()   // io
  };
}

std::unique_ptr<AndroidExternalViewEmbedder2> MakeEmbedder() {
  static AndroidContext android_context(AndroidRenderingAPI::kSoftware);
  auto embedder = std::make_unique<AndroidExternalViewEmbedder2>(
      android_context, std::make_shared<JNIMock>(), nullptr,
      GetTaskRunnersForFixture());
  embedder->PrepareFlutterView(kFrameSize, kDpr);
  // Host builds default to "unsupported"; most tests exercise the supported
  // path.
  embedder->SetNativeBackdropBlurSupportedForTesting(true);
  return embedder;
}

// Prerolls a platform view covering `rect_points` (logical pixels) and
// records it as visited, as the platform view layer would during preroll.
void AddPlatformView(AndroidExternalViewEmbedder2& embedder,
                     int64_t view_id,
                     const DlRect& rect_points) {
  DlMatrix matrix =
      DlMatrix::MakeScale({kDpr, kDpr, 1}) *
      DlMatrix::MakeTranslation({rect_points.GetX(), rect_points.GetY(), 0});
  embedder.PrerollCompositeEmbeddedView(
      view_id, std::make_unique<EmbeddedViewParams>(
                   matrix, rect_points.GetSize(), MutatorsStack()));
  embedder.PushVisitedPlatformView(view_id);
}

std::shared_ptr<DlImageFilter> Blur(DlScalar sigma) {
  return DlBlurImageFilter::Make(sigma, sigma, DlTileMode::kClamp);
}

std::shared_ptr<DlImageFilter> Saturation() {
  const float matrix[20] = {
      0.5f, 0.5f, 0.0f, 0, 0,  //
      0.5f, 0.5f, 0.0f, 0, 0,  //
      0.0f, 0.5f, 0.5f, 0, 0,  //
      0.0f, 0.0f, 0.0f, 1, 0,
  };
  return DlColorFilterImageFilter::Make(DlColorFilter::MakeMatrix(matrix));
}

// Device-pixel rect of a filter, as the backdrop filter layer reports it.
DlRect DeviceRect(const DlRect& rect_points) {
  return rect_points.Scale(kDpr);
}

}  // namespace

TEST(AndroidExternalViewEmbedder2BackdropBlur,
     LeavesFiltersToFlutterWithoutNativeBlur) {
  auto embedder = MakeEmbedder();
  embedder->SetNativeBackdropBlurSupportedForTesting(false);
  AddPlatformView(*embedder, 1, DlRect::MakeLTRB(0, 0, 100, 100));

  embedder->PushFilterToVisitedPlatformViews(
      Blur(5), DeviceRect(DlRect::MakeLTRB(50, 50, 150, 150)));

  // Nothing is sent to the platform and, importantly, the filter region is not
  // pulled out of the background layer, so Flutter still blurs its own content.
  EXPECT_TRUE(embedder->GetBackdropBlursForTesting().empty());
  EXPECT_TRUE(embedder->GetBackdropOverlayRectsForTesting().empty());
}

TEST(AndroidExternalViewEmbedder2BackdropBlur, IgnoresFiltersWithoutViews) {
  auto embedder = MakeEmbedder();

  embedder->PushFilterToVisitedPlatformViews(
      Blur(5), DeviceRect(DlRect::MakeLTRB(0, 0, 100, 100)));

  EXPECT_TRUE(embedder->GetBackdropBlursForTesting().empty());
  EXPECT_TRUE(embedder->GetBackdropOverlayRectsForTesting().empty());
}

TEST(AndroidExternalViewEmbedder2BackdropBlur,
     IgnoresFiltersThatDoNotCoverAPlatformView) {
  auto embedder = MakeEmbedder();
  AddPlatformView(*embedder, 1, DlRect::MakeLTRB(0, 0, 100, 100));

  embedder->PushFilterToVisitedPlatformViews(
      Blur(5), DeviceRect(DlRect::MakeLTRB(200, 200, 300, 300)));

  EXPECT_TRUE(embedder->GetBackdropBlursForTesting().empty());
  EXPECT_TRUE(embedder->GetBackdropOverlayRectsForTesting().empty());
}

TEST(AndroidExternalViewEmbedder2BackdropBlur, CollectsBlurInDevicePixels) {
  auto embedder = MakeEmbedder();
  AddPlatformView(*embedder, 1, DlRect::MakeLTRB(0, 0, 100, 100));

  const DlRect filter = DeviceRect(DlRect::MakeLTRB(50, 50, 150, 150));
  embedder->PushFilterToVisitedPlatformViews(Blur(5), filter);

  const auto& blurs = embedder->GetBackdropBlursForTesting();
  ASSERT_EQ(blurs.size(), 6u);
  EXPECT_EQ(blurs[0], filter.GetLeft());
  EXPECT_EQ(blurs[1], filter.GetTop());
  EXPECT_EQ(blurs[2], filter.GetRight());
  EXPECT_EQ(blurs[3], filter.GetBottom());
  EXPECT_FLOAT_EQ(blurs[4], 5 * kDpr);  // sigma
  EXPECT_FLOAT_EQ(blurs[5], 0);         // corner radius

  // The filter region (and so the filter's children) is forced into the
  // overlay of the view the filter sits above.
  const auto& overlay_rects = embedder->GetBackdropOverlayRectsForTesting();
  ASSERT_EQ(overlay_rects.size(), 1u);
  EXPECT_EQ(overlay_rects.at(1), filter);
}

TEST(AndroidExternalViewEmbedder2BackdropBlur, ClipsBlurToTheFrame) {
  auto embedder = MakeEmbedder();
  AddPlatformView(*embedder, 1, DlRect::MakeLTRB(0, 0, 100, 100));

  embedder->PushFilterToVisitedPlatformViews(
      Blur(5), DlRect::MakeLTRB(-100, -100, 100, 100));

  const auto& blurs = embedder->GetBackdropBlursForTesting();
  ASSERT_EQ(blurs.size(), 6u);
  EXPECT_EQ(blurs[0], 0);
  EXPECT_EQ(blurs[1], 0);
  EXPECT_EQ(blurs[2], 100);
  EXPECT_EQ(blurs[3], 100);
}

TEST(AndroidExternalViewEmbedder2BackdropBlur,
     UsesTheCornerRadiusOfTheEnclosingClip) {
  auto embedder = MakeEmbedder();
  AddPlatformView(*embedder, 1, DlRect::MakeLTRB(0, 0, 100, 100));

  // ClipRRect(child: BackdropFilter): the clip is pushed, then the filter.
  const DlRect clip_points = DlRect::MakeLTRB(50, 50, 150, 150);
  embedder->PushClipRRectToVisitedPlatformViews(
      DlRoundRect::MakeRectXY(clip_points, 12, 12));
  embedder->PushFilterToVisitedPlatformViews(Blur(5), DeviceRect(clip_points));

  const auto& blurs = embedder->GetBackdropBlursForTesting();
  ASSERT_EQ(blurs.size(), 6u);
  EXPECT_FLOAT_EQ(blurs[5], 12 * kDpr);
}

TEST(AndroidExternalViewEmbedder2BackdropBlur,
     IgnoresTheCornerRadiusWhenAnExtraTransformSeparatesClipAndFilter) {
  auto embedder = MakeEmbedder();
  AddPlatformView(*embedder, 1, DlRect::MakeLTRB(0, 0, 100, 100));

  // The clip is reported in its local space; the filter rect in device space
  // is scaled by the dpr and an extra 1.5x transform. The radius cannot be
  // mapped reliably, so the corners are left square.
  const DlRect clip_local = DlRect::MakeLTRB(0, 0, 100, 100);
  embedder->PushClipRRectToVisitedPlatformViews(
      DlRoundRect::MakeRectXY(clip_local, 10, 10));
  embedder->PushFilterToVisitedPlatformViews(Blur(5),
                                             clip_local.Scale(kDpr * 1.5));

  const auto& blurs = embedder->GetBackdropBlursForTesting();
  ASSERT_EQ(blurs.size(), 6u);
  EXPECT_FLOAT_EQ(blurs[5], 0);
}

TEST(AndroidExternalViewEmbedder2BackdropBlur,
     IgnoresAClipThatDoesNotBoundTheFilter) {
  auto embedder = MakeEmbedder();
  AddPlatformView(*embedder, 1, DlRect::MakeLTRB(0, 0, 100, 100));

  embedder->PushClipRRectToVisitedPlatformViews(
      DlRoundRect::MakeRectXY(DlRect::MakeLTRB(0, 0, 30, 30), 12, 12));
  embedder->PushFilterToVisitedPlatformViews(
      Blur(5), DeviceRect(DlRect::MakeLTRB(50, 50, 150, 150)));

  const auto& blurs = embedder->GetBackdropBlursForTesting();
  ASSERT_EQ(blurs.size(), 6u);
  EXPECT_FLOAT_EQ(blurs[5], 0);
}

TEST(AndroidExternalViewEmbedder2BackdropBlur,
     AClipAroundAPlatformViewDoesNotLeakIntoALaterFilter) {
  auto embedder = MakeEmbedder();

  // ClipRRect(child: PlatformView) followed by a sibling BackdropFilter of
  // the same size: the clip belongs to the platform view, not the filter.
  const DlRect rect = DlRect::MakeLTRB(0, 0, 100, 100);
  embedder->PushClipRRectToVisitedPlatformViews(
      DlRoundRect::MakeRectXY(rect, 12, 12));
  AddPlatformView(*embedder, 1, rect);
  embedder->PushFilterToVisitedPlatformViews(Blur(5), DeviceRect(rect));

  const auto& blurs = embedder->GetBackdropBlursForTesting();
  ASSERT_EQ(blurs.size(), 6u);
  EXPECT_FLOAT_EQ(blurs[5], 0);
}

TEST(AndroidExternalViewEmbedder2BackdropBlur, AClipIsConsumedByOneFilter) {
  auto embedder = MakeEmbedder();
  AddPlatformView(*embedder, 1, DlRect::MakeLTRB(0, 0, 100, 100));

  const DlRect rect = DlRect::MakeLTRB(0, 0, 100, 100);
  embedder->PushClipRRectToVisitedPlatformViews(
      DlRoundRect::MakeRectXY(rect, 12, 12));
  embedder->PushFilterToVisitedPlatformViews(Blur(5), DeviceRect(rect));
  embedder->PushFilterToVisitedPlatformViews(Blur(5), DeviceRect(rect));

  const auto& blurs = embedder->GetBackdropBlursForTesting();
  ASSERT_EQ(blurs.size(), 12u);
  EXPECT_FLOAT_EQ(blurs[5], 12 * kDpr);
  EXPECT_FLOAT_EQ(blurs[11], 0);
}

TEST(AndroidExternalViewEmbedder2BackdropBlur,
     ExtractsTheBlurFromAComposedCupertinoFilter) {
  auto embedder = MakeEmbedder();
  AddPlatformView(*embedder, 1, DlRect::MakeLTRB(0, 0, 100, 100));
  const DlRect filter = DeviceRect(DlRect::MakeLTRB(0, 0, 100, 100));

  // CupertinoPopupSurface: compose(saturation, blur) and compose(blur,
  // saturation) must both yield the blur.
  embedder->PushFilterToVisitedPlatformViews(
      DlComposeImageFilter::Make(Saturation(), Blur(7)), filter);
  embedder->PushFilterToVisitedPlatformViews(
      DlComposeImageFilter::Make(Blur(9), Saturation()), filter);

  const auto& blurs = embedder->GetBackdropBlursForTesting();
  ASSERT_EQ(blurs.size(), 12u);
  EXPECT_FLOAT_EQ(blurs[4], 7 * kDpr);
  EXPECT_FLOAT_EQ(blurs[10], 9 * kDpr);
}

TEST(AndroidExternalViewEmbedder2BackdropBlur, DropsNonBlurFilters) {
  auto embedder = MakeEmbedder();
  AddPlatformView(*embedder, 1, DlRect::MakeLTRB(0, 0, 100, 100));

  embedder->PushFilterToVisitedPlatformViews(
      Saturation(), DeviceRect(DlRect::MakeLTRB(0, 0, 100, 100)));

  EXPECT_TRUE(embedder->GetBackdropBlursForTesting().empty());
  EXPECT_TRUE(embedder->GetBackdropOverlayRectsForTesting().empty());
}

TEST(AndroidExternalViewEmbedder2BackdropBlur,
     UnionsOverlayRectsOfSeveralFiltersAboveOneView) {
  auto embedder = MakeEmbedder();
  AddPlatformView(*embedder, 1, DlRect::MakeLTRB(0, 0, 100, 100));

  embedder->PushFilterToVisitedPlatformViews(
      Blur(5), DeviceRect(DlRect::MakeLTRB(0, 0, 50, 50)));
  embedder->PushFilterToVisitedPlatformViews(
      Blur(5), DeviceRect(DlRect::MakeLTRB(60, 60, 90, 90)));

  EXPECT_EQ(embedder->GetBackdropBlursForTesting().size(), 12u);
  const auto& overlay_rects = embedder->GetBackdropOverlayRectsForTesting();
  ASSERT_EQ(overlay_rects.size(), 1u);
  EXPECT_EQ(overlay_rects.at(1), DeviceRect(DlRect::MakeLTRB(0, 0, 90, 90)));
}

TEST(AndroidExternalViewEmbedder2BackdropBlur,
     AttributesTheOverlayToTheMostRecentPlatformView) {
  auto embedder = MakeEmbedder();
  AddPlatformView(*embedder, 1, DlRect::MakeLTRB(0, 0, 100, 100));
  AddPlatformView(*embedder, 2, DlRect::MakeLTRB(0, 200, 100, 300));

  // Covers only view 1, but is painted after view 2, so its children land in
  // view 2's overlay (the topmost one).
  embedder->PushFilterToVisitedPlatformViews(
      Blur(5), DeviceRect(DlRect::MakeLTRB(0, 0, 50, 50)));

  const auto& overlay_rects = embedder->GetBackdropOverlayRectsForTesting();
  ASSERT_EQ(overlay_rects.size(), 1u);
  EXPECT_TRUE(overlay_rects.count(2));
}

TEST(AndroidExternalViewEmbedder2BackdropBlur, StateIsResetPerFrame) {
  auto embedder = MakeEmbedder();
  AddPlatformView(*embedder, 1, DlRect::MakeLTRB(0, 0, 100, 100));
  embedder->PushClipRRectToVisitedPlatformViews(
      DlRoundRect::MakeRectXY(DlRect::MakeLTRB(0, 0, 100, 100), 12, 12));
  embedder->PushFilterToVisitedPlatformViews(
      Blur(5), DeviceRect(DlRect::MakeLTRB(0, 0, 100, 100)));
  ASSERT_FALSE(embedder->GetBackdropBlursForTesting().empty());

  embedder->PrepareFlutterView(kFrameSize, kDpr);

  EXPECT_TRUE(embedder->GetBackdropBlursForTesting().empty());
  EXPECT_TRUE(embedder->GetBackdropOverlayRectsForTesting().empty());
}

}  // namespace testing
}  // namespace flutter
