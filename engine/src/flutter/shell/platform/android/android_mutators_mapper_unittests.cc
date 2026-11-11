// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_mutators_mapper.h"

#include <cmath>
#include <limits>
#include <thread>
#include <vector>

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

/// Floating-point tolerance for matrix, coordinate, and opacity assertions.
constexpr float kTestFloatTolerance = 1e-4f;

/// Standard Retina/high-DPI device pixel ratio (2x physical pixels per logical
/// pixel) used to verify coordinate scaling.
constexpr double kTestDevicePixelRatio2x = 2.0;

/// Default 1x device pixel ratio (1 physical pixel per logical pixel).
constexpr double kTestDevicePixelRatio1x = 1.0;

/// Sample conic weight (sqrt(2)/2 ≈ 0.70710678 represents a circular arc).
constexpr double kCircularArcConicWeight = 0.70710678;

/// Number of verbs in the full SoA path test (Move, Line, Quad, Conic, Cubic,
/// Close).
constexpr size_t kFullSoAPathVerbCount = 6;

/// Total points consumed by Move(1) + Line(1) + Quad(2) + Conic(2) + Cubic(3) +
/// Close(0) = 9 points.
constexpr size_t kFullSoAPathPointCount = 9;

/// Total conic weights consumed by the single Conic verb in the full SoA path.
constexpr size_t kFullSoAPathConicWeightCount = 1;

struct FakeSurfaceControlTransaction {
  void* surface_control = nullptr;
  float pos_x = 0.0f;
  float pos_y = 0.0f;
  float dsdx = 1.0f;
  float dtdx = 0.0f;
  float dtdy = 0.0f;
  float dsdy = 1.0f;
  float alpha = 1.0f;
  bool crop_set = false;
  int32_t crop_left = 0;
  int32_t crop_top = 0;
  int32_t crop_right = 0;
  int32_t crop_bottom = 0;

  void SetPosition(void* sc, float x, float y) {
    surface_control = sc;
    pos_x = x;
    pos_y = y;
  }

  void SetMatrix(void* sc,
                 float in_dsdx,
                 float in_dtdx,
                 float in_dtdy,
                 float in_dsdy) {
    surface_control = sc;
    dsdx = in_dsdx;
    dtdx = in_dtdx;
    dtdy = in_dtdy;
    dsdy = in_dsdy;
  }

  void SetAlpha(void* sc, float a) {
    surface_control = sc;
    alpha = a;
  }

  void SetCrop(void* sc, int32_t l, int32_t t, int32_t r, int32_t b) {
    surface_control = sc;
    crop_set = true;
    crop_left = l;
    crop_top = t;
    crop_right = r;
    crop_bottom = b;
  }
};

}  // namespace

TEST(AndroidMutatorsMapperTest, MatrixIdentityAndMultiply) {
  const AndroidMatrix3x3 id = AndroidMatrix3x3::Identity();
  EXPECT_TRUE(id.IsIdentity());

  // Scale by 2x horizontally, 3x vertically, translate by (10, 20).
  constexpr double kScaleX = 2.0;
  constexpr double kScaleY = 3.0;
  constexpr double kTransX = 10.0;
  constexpr double kTransY = 20.0;
  FlutterTransformation ft = {
      .scaleX = kScaleX,
      .skewX = 0.0,
      .transX = kTransX,
      .skewY = 0.0,
      .scaleY = kScaleY,
      .transY = kTransY,
      .pers0 = 0.0,
      .pers1 = 0.0,
      .pers2 = 1.0,
  };
  const AndroidMatrix3x3 m = AndroidMatrix3x3::FromFlutterTransformation(ft);
  EXPECT_FALSE(m.IsIdentity());
  EXPECT_EQ(AndroidMatrix3x3::Multiply(id, m), m);
  EXPECT_EQ(AndroidMatrix3x3::Multiply(m, id), m);

  // PreTranslate by (5, 4): new transX = 10 + 2*5 = 20, new transY = 20 + 3*4
  // = 32.
  constexpr float kPreDx = 5.0f;
  constexpr float kPreDy = 4.0f;
  constexpr float kExpectedPreTransX = 20.0f;
  constexpr float kExpectedPreTransY = 32.0f;
  const AndroidMatrix3x3 pre =
      AndroidMatrix3x3::PreTranslate(m, kPreDx, kPreDy);
  EXPECT_NEAR(pre.values[kMatrixTransXIndex], kExpectedPreTransX,
              kTestFloatTolerance);
  EXPECT_NEAR(pre.values[kMatrixTransYIndex], kExpectedPreTransY,
              kTestFloatTolerance);
}

TEST(AndroidMutatorsMapperTest, SoAFlutterPathAllVerbsAndConicWeights) {
  const FlutterPathVerb verbs[kFullSoAPathVerbCount] = {
      kFlutterPathVerbMove,  kFlutterPathVerbLine,  kFlutterPathVerbQuad,
      kFlutterPathVerbConic, kFlutterPathVerbCubic, kFlutterPathVerbClose,
  };
  // 9 points for Move(1) + Line(1) + Quad(2) + Conic(2) + Cubic(3).
  const FlutterPoint points[kFullSoAPathPointCount] = {
      {1.0, 2.0},    // Move
      {10.0, 20.0},  // Line
      {15.0, 25.0},  // Quad control
      {30.0, 40.0},  // Quad end
      {35.0, 45.0},  // Conic control
      {50.0, 60.0},  // Conic end
      {55.0, 65.0},  // Cubic control 1
      {70.0, 80.0},  // Cubic control 2
      {90.0, 100.0}  // Cubic end
  };
  const double conic_weights[kFullSoAPathConicWeightCount] = {
      kCircularArcConicWeight};
  constexpr double kBoundsRight = 90.0;
  constexpr double kBoundsBottom = 100.0;

  FlutterPath flutter_path = {};
  flutter_path.struct_size = sizeof(FlutterPath);
  flutter_path.fill_type = kFlutterPathFillTypeEvenOdd;
  flutter_path.verbs_count = kFullSoAPathVerbCount;
  flutter_path.verbs = verbs;
  flutter_path.points_count = kFullSoAPathPointCount;
  flutter_path.points = points;
  flutter_path.conic_weights_count = kFullSoAPathConicWeightCount;
  flutter_path.conic_weights = conic_weights;
  flutter_path.bounds = FlutterRect{0.0, 0.0, kBoundsRight, kBoundsBottom};

  const AndroidClipPath clip_path = AndroidClipPath::FromFlutterPath(
      flutter_path, static_cast<float>(kTestDevicePixelRatio2x));
  EXPECT_EQ(clip_path.fill_type, AndroidPathFillType::kEvenOdd);
  ASSERT_EQ(clip_path.segments.size(), kFullSoAPathVerbCount);
  ASSERT_EQ(clip_path.verbs.size(), kFullSoAPathVerbCount);
  ASSERT_EQ(clip_path.points.size(), kFullSoAPathPointCount);
  ASSERT_EQ(clip_path.conic_weights.size(), kFullSoAPathConicWeightCount);

  // Bounds should be scaled by 2x DPR: (0, 0, 180, 200).
  constexpr float kExpectedScaledBoundsRight = 180.0f;
  constexpr float kExpectedScaledBoundsBottom = 200.0f;
  EXPECT_NEAR(clip_path.bounds.right, kExpectedScaledBoundsRight,
              kTestFloatTolerance);
  EXPECT_NEAR(clip_path.bounds.bottom, kExpectedScaledBoundsBottom,
              kTestFloatTolerance);

  // Verify Conic segment at index 3 has scaled points and conic weight.
  constexpr size_t kConicSegmentIndex = 3;
  constexpr double kExpectedScaledConicCtrlX = 70.0;
  constexpr double kExpectedScaledConicEndY = 120.0;
  EXPECT_EQ(clip_path.segments[kConicSegmentIndex].verb,
            AndroidPathVerb::kConic);
  EXPECT_NEAR(clip_path.segments[kConicSegmentIndex].points[0].x,
              kExpectedScaledConicCtrlX, kTestFloatTolerance);
  EXPECT_NEAR(clip_path.segments[kConicSegmentIndex].points[1].y,
              kExpectedScaledConicEndY, kTestFloatTolerance);
  EXPECT_NEAR(clip_path.segments[kConicSegmentIndex].conic_weight,
              static_cast<float>(kCircularArcConicWeight), kTestFloatTolerance);
}

TEST(AndroidMutatorsMapperTest, SoAFlutterPathTruncatedBuffersStopSafely) {
  // Conic verb requires 2 points and 1 conic weight; provide 0 conic weights.
  const FlutterPathVerb verbs[] = {kFlutterPathVerbMove, kFlutterPathVerbConic};
  const FlutterPoint points[] = {{0.0, 0.0}, {10.0, 10.0}, {20.0, 20.0}};
  constexpr size_t kVerbCount = 2;
  constexpr size_t kPointCount = 3;

  FlutterPath path_missing_weights = {};
  path_missing_weights.struct_size = sizeof(FlutterPath);
  path_missing_weights.fill_type = kFlutterPathFillTypeNonZero;
  path_missing_weights.verbs_count = kVerbCount;
  path_missing_weights.verbs = verbs;
  path_missing_weights.points_count = kPointCount;
  path_missing_weights.points = points;
  path_missing_weights.conic_weights_count = 0;
  path_missing_weights.conic_weights = nullptr;

  const AndroidClipPath parsed =
      AndroidClipPath::FromFlutterPath(path_missing_weights);
  // Move succeeds (1 segment), Conic stops safely without reading null weights.
  EXPECT_EQ(parsed.segments.size(), 1u);
  EXPECT_EQ(parsed.segments[0].verb, AndroidPathVerb::kMove);
}

TEST(AndroidMutatorsMapperTest, ParseMutationsCompleteStackAndSerialization) {
  constexpr double kOpacityValue = 0.5;
  FlutterPlatformViewMutation m_opacity = {};
  m_opacity.type = kFlutterPlatformViewMutationTypeOpacity;
  m_opacity.opacity = kOpacityValue;

  constexpr double kClipLeft = 10.0;
  constexpr double kClipTop = 20.0;
  constexpr double kClipRight = 110.0;
  constexpr double kClipBottom = 220.0;
  FlutterPlatformViewMutation m_rect = {};
  m_rect.type = kFlutterPlatformViewMutationTypeClipRect;
  m_rect.clip_rect = FlutterRect{kClipLeft, kClipTop, kClipRight, kClipBottom};

  constexpr double kCornerRadius = 8.0;
  FlutterPlatformViewMutation m_rrect = {};
  m_rrect.type = kFlutterPlatformViewMutationTypeClipRoundedRect;
  m_rrect.clip_rounded_rect.rect =
      FlutterRect{kClipLeft, kClipTop, kClipRight, kClipBottom};
  m_rrect.clip_rounded_rect.upper_left_corner_radius = {kCornerRadius,
                                                        kCornerRadius};
  m_rrect.clip_rounded_rect.upper_right_corner_radius = {kCornerRadius,
                                                         kCornerRadius};
  m_rrect.clip_rounded_rect.lower_right_corner_radius = {kCornerRadius,
                                                         kCornerRadius};
  m_rrect.clip_rounded_rect.lower_left_corner_radius = {kCornerRadius,
                                                        kCornerRadius};

  FlutterPlatformViewMutation m_transform = {};
  m_transform.type = kFlutterPlatformViewMutationTypeTransformation;
  m_transform.transformation = FlutterTransformation{
      .scaleX = 1.0,
      .skewX = 0.0,
      .transX = 5.0,
      .skewY = 0.0,
      .scaleY = 1.0,
      .transY = 15.0,
      .pers0 = 0.0,
      .pers1 = 0.0,
      .pers2 = 1.0,
  };

  const FlutterPathVerb path_verbs[] = {
      kFlutterPathVerbMove, kFlutterPathVerbConic, kFlutterPathVerbClose};
  const FlutterPoint path_points[] = {{0.0, 0.0}, {25.0, 0.0}, {25.0, 25.0}};
  const double path_weights[] = {kCircularArcConicWeight};
  constexpr size_t kPathVerbsCount = 3;
  constexpr size_t kPathPointsCount = 3;

  FlutterPlatformViewMutation m_path = {};
  m_path.type = kFlutterPlatformViewMutationTypeClipPath;
  m_path.clip_path.struct_size = sizeof(FlutterPath);
  m_path.clip_path.fill_type = kFlutterPathFillTypeEvenOdd;
  m_path.clip_path.verbs_count = kPathVerbsCount;
  m_path.clip_path.verbs = path_verbs;
  m_path.clip_path.points_count = kPathPointsCount;
  m_path.clip_path.points = path_points;
  m_path.clip_path.conic_weights_count = 1;
  m_path.clip_path.conic_weights = path_weights;
  m_path.clip_path.bounds = FlutterRect{0.0, 0.0, 25.0, 25.0};

  constexpr size_t kMutationsCount = 5;
  const FlutterPlatformViewMutation* mutations[kMutationsCount] = {
      &m_transform, &m_opacity, &m_rect, &m_rrect, &m_path};

  FlutterPlatformView pv = {};
  pv.struct_size = sizeof(FlutterPlatformView);
  pv.identifier = 42;
  pv.mutations_count = kMutationsCount;
  pv.mutations = mutations;

  const AndroidMutatorsStack stack = AndroidMutatorsMapper::MapPlatformView(pv);
  EXPECT_EQ(stack.GetMutatorsCount(), kMutationsCount);
  EXPECT_NEAR(stack.GetFinalOpacity(), static_cast<float>(kOpacityValue),
              kTestFloatTolerance);
  ASSERT_EQ(stack.GetFinalClippingPaths().size(), 1u);

  const std::vector<uint8_t> bytes = stack.Serialize();
  const auto restored =
      AndroidMutatorsStack::Deserialize(bytes.data(), bytes.size());
  ASSERT_TRUE(restored.has_value());
  EXPECT_EQ(*restored, stack);

  const auto records = AndroidMutatorsMapper::ParseMutations(
      kMutationsCount, mutations, kTestDevicePixelRatio2x);
  ASSERT_EQ(records.size(), kMutationsCount);
  // Path bounds right = 25 * 2 = 50.
  constexpr int32_t kExpectedScaledPathBound = 50;
  EXPECT_EQ(records[4].rect_right, kExpectedScaledPathBound);
  ASSERT_EQ(records[4].path_segments.size(), kPathVerbsCount);
  EXPECT_EQ(records[4].path_segments[1].verb, AndroidPathVerb::kConic);
}

TEST(AndroidMutatorsMapperTest,
     ApplySurfaceControlTransactionComputesTransform) {
  FlutterPlatformViewMutation m_transform = {};
  m_transform.type = kFlutterPlatformViewMutationTypeTransformation;
  m_transform.transformation = FlutterTransformation{
      .scaleX = 2.0,
      .skewX = 0.0,
      .transX = 12.0,
      .skewY = 0.0,
      .scaleY = 2.0,
      .transY = 24.0,
      .pers0 = 0.0,
      .pers1 = 0.0,
      .pers2 = 1.0,
  };

  FlutterPlatformViewMutation m_opacity = {};
  m_opacity.type = kFlutterPlatformViewMutationTypeOpacity;
  m_opacity.opacity = 0.75;

  FlutterPlatformViewMutation m_clip = {};
  m_clip.type = kFlutterPlatformViewMutationTypeClipRect;
  m_clip.clip_rect = FlutterRect{0.0, 0.0, 100.0, 80.0};

  constexpr size_t kCount = 3;
  const FlutterPlatformViewMutation* mutations[kCount] = {&m_transform,
                                                          &m_opacity, &m_clip};

  const auto records = AndroidMutatorsMapper::ParseMutations(
      kCount, mutations, kTestDevicePixelRatio1x);

  int dummy_sc = 1;
  FakeSurfaceControlTransaction tx;
  EXPECT_TRUE(AndroidMutatorsMapper::ApplySurfaceControlTransaction(
      records, 1.0f, &dummy_sc, tx));
  EXPECT_EQ(tx.surface_control, &dummy_sc);
  EXPECT_NEAR(tx.pos_x, 12.0f, kTestFloatTolerance);
  EXPECT_NEAR(tx.pos_y, 24.0f, kTestFloatTolerance);
  EXPECT_NEAR(tx.dsdx, 2.0f, kTestFloatTolerance);
  EXPECT_NEAR(tx.dsdy, 2.0f, kTestFloatTolerance);
  EXPECT_NEAR(tx.alpha, 0.75f, kTestFloatTolerance);
  EXPECT_TRUE(tx.crop_set);
  // Inverse of 2x scale maps (100, 80) to (50, 40) in local coordinates.
  EXPECT_EQ(tx.crop_right, 50);
  EXPECT_EQ(tx.crop_bottom, 40);
}

}  // namespace testing
}  // namespace flutter
