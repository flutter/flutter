// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_mutators_mapper.h"
#include "flutter/shell/platform/android/flutter_main.h"

#include <cmath>
#include <limits>

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(AndroidMutatorsMapperTest, TransformMappingAndDPRNormalization) {
  FlutterTransformation transform = {
      .scaleX = 1.5,
      .skewX = 0.2,
      .transX = 10.0,
      .skewY = 0.3,
      .scaleY = 2.5,
      .transY = 20.0,
      .pers0 = 0.0,
      .pers1 = 0.0,
      .pers2 = 1.0,
  };

  // DPR = 1.0
  std::vector<float> matrix1 =
      AndroidMutatorsMapper::TransformToAndroidMatrix(transform, 1.0);
  ASSERT_EQ(matrix1.size(), 9u);
  EXPECT_FLOAT_EQ(matrix1[0], 1.5f);
  EXPECT_FLOAT_EQ(matrix1[1], 0.2f);
  EXPECT_FLOAT_EQ(matrix1[2], 10.0f);
  EXPECT_FLOAT_EQ(matrix1[3], 0.3f);
  EXPECT_FLOAT_EQ(matrix1[4], 2.5f);
  EXPECT_FLOAT_EQ(matrix1[5], 20.0f);
  EXPECT_FLOAT_EQ(matrix1[6], 0.0f);
  EXPECT_FLOAT_EQ(matrix1[7], 0.0f);
  EXPECT_FLOAT_EQ(matrix1[8], 1.0f);

  // DPR = 2.5
  std::vector<float> matrix2 =
      AndroidMutatorsMapper::TransformToAndroidMatrix(transform, 2.5);
  ASSERT_EQ(matrix2.size(), 9u);
  EXPECT_FLOAT_EQ(matrix2[0], 1.5f);
  EXPECT_FLOAT_EQ(matrix2[1], 0.2f);
  EXPECT_FLOAT_EQ(matrix2[2], 25.0f);  // 10.0 * 2.5
  EXPECT_FLOAT_EQ(matrix2[3], 0.3f);
  EXPECT_FLOAT_EQ(matrix2[4], 2.5f);
  EXPECT_FLOAT_EQ(matrix2[5], 50.0f);  // 20.0 * 2.5

  // DPR = NaN and negative -> fallback to 1.0
  std::vector<float> matrix_nan =
      AndroidMutatorsMapper::TransformToAndroidMatrix(
          transform, std::numeric_limits<double>::quiet_NaN());
  EXPECT_FLOAT_EQ(matrix_nan[2], 10.0f);
  EXPECT_FLOAT_EQ(matrix_nan[5], 20.0f);

  std::vector<float> matrix_neg =
      AndroidMutatorsMapper::TransformToAndroidMatrix(transform, -1.0);
  EXPECT_FLOAT_EQ(matrix_neg[2], 10.0f);
  EXPECT_FLOAT_EQ(matrix_neg[5], 20.0f);
}

TEST(AndroidMutatorsMapperTest, RadiiMappingAndDPRNormalization) {
  FlutterSize ul = {2.0, 3.0};
  FlutterSize ur = {4.0, 5.0};
  FlutterSize lr = {6.0, 7.0};
  FlutterSize ll = {8.0, 9.0};

  // DPR = 2.0
  std::vector<float> radiis =
      AndroidMutatorsMapper::RadiiToAndroidArray(ul, ur, lr, ll, 2.0);
  ASSERT_EQ(radiis.size(), 8u);
  EXPECT_FLOAT_EQ(radiis[0], 4.0f);   // 2 * 2
  EXPECT_FLOAT_EQ(radiis[1], 6.0f);   // 3 * 2
  EXPECT_FLOAT_EQ(radiis[2], 8.0f);   // 4 * 2
  EXPECT_FLOAT_EQ(radiis[3], 10.0f);  // 5 * 2
  EXPECT_FLOAT_EQ(radiis[4], 12.0f);  // 6 * 2
  EXPECT_FLOAT_EQ(radiis[5], 14.0f);  // 7 * 2
  EXPECT_FLOAT_EQ(radiis[6], 16.0f);  // 8 * 2
  EXPECT_FLOAT_EQ(radiis[7], 18.0f);  // 9 * 2

  // DPR = NaN -> fallback to 1.0
  std::vector<float> radiis_nan = AndroidMutatorsMapper::RadiiToAndroidArray(
      ul, ur, lr, ll, std::numeric_limits<double>::quiet_NaN());
  EXPECT_FLOAT_EQ(radiis_nan[0], 2.0f);
  EXPECT_FLOAT_EQ(radiis_nan[7], 9.0f);
}

TEST(AndroidMutatorsMapperTest, ParseMutationsCompleteStack) {
  // 1. Transform
  FlutterPlatformViewMutation m_transform = {};
  m_transform.type = kFlutterPlatformViewMutationTypeTransformation;
  m_transform.transformation = {
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

  // 2. ClipRect
  FlutterPlatformViewMutation m_cliprect = {};
  m_cliprect.type = kFlutterPlatformViewMutationTypeClipRect;
  m_cliprect.clip_rect = {10.0, 20.0, 100.0, 200.0};

  // 3. ClipRoundedRect
  FlutterPlatformViewMutation m_cliprrect = {};
  m_cliprrect.type = kFlutterPlatformViewMutationTypeClipRoundedRect;
  m_cliprrect.clip_rounded_rect.rect = {0.0, 0.0, 50.0, 50.0};
  m_cliprrect.clip_rounded_rect.upper_left_corner_radius = {4.0, 4.0};
  m_cliprrect.clip_rounded_rect.upper_right_corner_radius = {4.0, 4.0};
  m_cliprrect.clip_rounded_rect.lower_right_corner_radius = {4.0, 4.0};
  m_cliprrect.clip_rounded_rect.lower_left_corner_radius = {4.0, 4.0};

  // 4. ClipRoundSuperellipse
  FlutterPlatformViewMutation m_cliprse = {};
  m_cliprse.type = kFlutterPlatformViewMutationTypeClipRoundSuperellipse;
  m_cliprse.clip_round_superellipse.rect = {10.0, 10.0, 60.0, 60.0};
  m_cliprse.clip_round_superellipse.upper_left_corner_radius = {8.0, 8.0};
  m_cliprse.clip_round_superellipse.upper_right_corner_radius = {8.0, 8.0};
  m_cliprse.clip_round_superellipse.lower_right_corner_radius = {8.0, 8.0};
  m_cliprse.clip_round_superellipse.lower_left_corner_radius = {8.0, 8.0};

  // 5. ClipPath with Move, Line, Quad, Conic, Cubic, Close
  FlutterPathSegment segments[6] = {
      {kFlutterPathVerbMove, {{10.0, 10.0}, {0, 0}, {0, 0}}, 0.0},
      {kFlutterPathVerbLine, {{50.0, 50.0}, {0, 0}, {0, 0}}, 0.0},
      {kFlutterPathVerbQuad, {{20.0, 20.0}, {60.0, 60.0}, {0, 0}}, 0.0},
      {kFlutterPathVerbConic, {{25.0, 25.0}, {65.0, 65.0}, {0, 0}}, 1.5},
      {kFlutterPathVerbCubic, {{15.0, 15.0}, {35.0, 35.0}, {70.0, 70.0}}, 0.0},
      {kFlutterPathVerbClose, {{0, 0}, {0, 0}, {0, 0}}, 0.0},
  };
  FlutterPlatformViewMutation m_clippath = {};
  m_clippath.type = kFlutterPlatformViewMutationTypeClipPath;
  m_clippath.clip_path.struct_size = sizeof(FlutterPath);
  m_clippath.clip_path.fill_type = kFlutterPathFillTypeEvenOdd;
  m_clippath.clip_path.segments_count = 6;
  m_clippath.clip_path.segments = segments;

  // 6. Opacity
  FlutterPlatformViewMutation m_opacity = {};
  m_opacity.type = kFlutterPlatformViewMutationTypeOpacity;
  m_opacity.opacity = 0.75;

  const FlutterPlatformViewMutation* mutations[] = {
      &m_transform, &m_cliprect, &m_cliprrect,
      &m_cliprse,   &m_clippath, &m_opacity,
  };

  std::vector<AndroidMutatorRecord> records =
      AndroidMutatorsMapper::ParseMutations(6, mutations, 2.0);

  ASSERT_EQ(records.size(), 6u);

  // Transform check
  EXPECT_EQ(records[0].type, kFlutterPlatformViewMutationTypeTransformation);
  EXPECT_FLOAT_EQ(records[0].matrix[2], 10.0f);  // 5.0 * 2.0
  EXPECT_FLOAT_EQ(records[0].matrix[5], 30.0f);  // 15.0 * 2.0

  // ClipRect check
  EXPECT_EQ(records[1].type, kFlutterPlatformViewMutationTypeClipRect);
  EXPECT_FLOAT_EQ(records[1].rect.left, 20.0f);
  EXPECT_FLOAT_EQ(records[1].rect.top, 40.0f);
  EXPECT_FLOAT_EQ(records[1].rect.right, 200.0f);
  EXPECT_FLOAT_EQ(records[1].rect.bottom, 400.0f);

  // ClipRRect check
  EXPECT_EQ(records[2].type, kFlutterPlatformViewMutationTypeClipRoundedRect);
  EXPECT_FLOAT_EQ(records[2].rect.right, 100.0f);
  ASSERT_EQ(records[2].radiis.size(), 8u);
  EXPECT_FLOAT_EQ(records[2].radiis[0], 8.0f);

  // ClipRSE check
  EXPECT_EQ(records[3].type,
            kFlutterPlatformViewMutationTypeClipRoundSuperellipse);
  EXPECT_FLOAT_EQ(records[3].rect.left, 20.0f);
  ASSERT_EQ(records[3].radiis.size(), 8u);
  EXPECT_FLOAT_EQ(records[3].radiis[0], 16.0f);

  // ClipPath check
  EXPECT_EQ(records[4].type, kFlutterPlatformViewMutationTypeClipPath);
  EXPECT_EQ(records[4].path_fill_type, kFlutterPathFillTypeEvenOdd);
  ASSERT_EQ(records[4].path_segments.size(), 6u);
  EXPECT_EQ(records[4].path_segments[0].verb, kFlutterPathVerbMove);
  EXPECT_FLOAT_EQ(records[4].path_segments[0].points[0].x, 20.0f);  // 10 * 2
  EXPECT_FLOAT_EQ(records[4].path_segments[0].points[0].y, 20.0f);

  EXPECT_EQ(records[4].path_segments[1].verb, kFlutterPathVerbLine);
  EXPECT_FLOAT_EQ(records[4].path_segments[1].points[0].x, 50.0f * 2);

  EXPECT_EQ(records[4].path_segments[2].verb, kFlutterPathVerbQuad);
  EXPECT_FLOAT_EQ(records[4].path_segments[2].points[0].x, 20.0f * 2);
  EXPECT_FLOAT_EQ(records[4].path_segments[2].points[1].x, 60.0f * 2);

  EXPECT_EQ(records[4].path_segments[3].verb, kFlutterPathVerbConic);
  EXPECT_FLOAT_EQ(records[4].path_segments[3].points[0].x, 25.0f * 2);
  EXPECT_FLOAT_EQ(records[4].path_segments[3].points[1].x, 65.0f * 2);

  EXPECT_EQ(records[4].path_segments[4].verb, kFlutterPathVerbCubic);
  EXPECT_FLOAT_EQ(records[4].path_segments[4].points[0].x, 15.0f * 2);
  EXPECT_FLOAT_EQ(records[4].path_segments[4].points[1].x, 35.0f * 2);
  EXPECT_FLOAT_EQ(records[4].path_segments[4].points[2].x, 70.0f * 2);

  EXPECT_EQ(records[4].path_segments[5].verb, kFlutterPathVerbClose);

  // Opacity check
  EXPECT_EQ(records[5].type, kFlutterPlatformViewMutationTypeOpacity);
  EXPECT_FLOAT_EQ(records[5].opacity, 0.75f);
}

TEST(AndroidMutatorsMapperTest, OpacityNaNAndClampingSafety) {
  FlutterPlatformViewMutation m_nan = {};
  m_nan.type = kFlutterPlatformViewMutationTypeOpacity;
  m_nan.opacity = std::numeric_limits<double>::quiet_NaN();

  FlutterPlatformViewMutation m_overflow = {};
  m_overflow.type = kFlutterPlatformViewMutationTypeOpacity;
  m_overflow.opacity = 2.5;

  FlutterPlatformViewMutation m_underflow = {};
  m_underflow.type = kFlutterPlatformViewMutationTypeOpacity;
  m_underflow.opacity = -0.5;

  const FlutterPlatformViewMutation* mutations[] = {&m_nan, &m_overflow,
                                                    &m_underflow};
  auto records = AndroidMutatorsMapper::ParseMutations(3, mutations, 1.0);
  ASSERT_EQ(records.size(), 3u);
  EXPECT_FLOAT_EQ(records[0].opacity, 1.0f);
  EXPECT_FLOAT_EQ(records[1].opacity, 1.0f);
  EXPECT_FLOAT_EQ(records[2].opacity, 0.0f);
}

TEST(AndroidMutatorsMapperTest, NullAndEmptyMutationsSafety) {
  auto empty_records = AndroidMutatorsMapper::ParseMutations(0, nullptr, 1.0);
  EXPECT_TRUE(empty_records.empty());

  const FlutterPlatformViewMutation* null_array[] = {nullptr, nullptr};
  auto null_records = AndroidMutatorsMapper::ParseMutations(2, null_array, 1.0);
  EXPECT_TRUE(null_records.empty());
}

TEST(AndroidMutatorsMapperTest, DualFlagMatrixTest) {
  for (bool embedder_api_enabled : {false, true}) {
    FlutterMain::SetEmbedderAPIEnabledForTesting(embedder_api_enabled);
    EXPECT_EQ(FlutterMain::IsEmbedderAPIEnabled(), embedder_api_enabled);

    FlutterPlatformViewMutation mutation = {};
    mutation.type = kFlutterPlatformViewMutationTypeOpacity;
    mutation.opacity = 0.5;
    const FlutterPlatformViewMutation* mutations[] = {&mutation};

    auto records = AndroidMutatorsMapper::ParseMutations(1, mutations, 1.0);
    ASSERT_EQ(records.size(), 1u);
    EXPECT_FLOAT_EQ(records[0].opacity, 0.5f);
  }
  FlutterMain::ResetEmbedderAPIEnabledForTesting();
}

}  // namespace testing
}  // namespace flutter
