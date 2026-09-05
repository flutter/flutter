// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cmath>
#include <future>
#include <vector>

#include "flutter/shell/platform/android/android_mutators_mapper.h"
#include "gtest/gtest.h"

namespace flutter {
namespace android {
namespace testing {

TEST(AndroidMutatorTest, Matrix3x3IdentityAndFactory) {
  AndroidMatrix3x3 identity = AndroidMatrix3x3::Identity();
  EXPECT_TRUE(identity.IsIdentity());

  float out_x = 0.0f;
  float out_y = 0.0f;
  EXPECT_TRUE(identity.TransformPoint(10.0f, 20.0f, &out_x, &out_y));
  EXPECT_FLOAT_EQ(out_x, 10.0f);
  EXPECT_FLOAT_EQ(out_y, 20.0f);

  AndroidMatrix3x3 translate = AndroidMatrix3x3::MakeTranslation(50.0f, 100.0f);
  EXPECT_FALSE(translate.IsIdentity());
  EXPECT_TRUE(translate.TransformPoint(10.0f, 20.0f, &out_x, &out_y));
  EXPECT_FLOAT_EQ(out_x, 60.0f);
  EXPECT_FLOAT_EQ(out_y, 120.0f);

  AndroidMatrix3x3 scale = AndroidMatrix3x3::MakeScale(2.0f, 3.0f);
  EXPECT_TRUE(scale.TransformPoint(10.0f, 20.0f, &out_x, &out_y));
  EXPECT_FLOAT_EQ(out_x, 20.0f);
  EXPECT_FLOAT_EQ(out_y, 60.0f);
}

TEST(AndroidMutatorTest, Matrix3x3ConcatenationAndMultiplication) {
  AndroidMatrix3x3 m1 = AndroidMatrix3x3::MakeTranslation(10.0f, 20.0f);
  AndroidMatrix3x3 m2 = AndroidMatrix3x3::MakeScale(2.0f, 2.0f);

  // m1 * m2: Scale first, then Translate
  // (x * 2) + 10, (y * 2) + 20
  AndroidMatrix3x3 combined = m1.Multiply(m2);

  float out_x = 0.0f;
  float out_y = 0.0f;
  EXPECT_TRUE(combined.TransformPoint(5.0f, 5.0f, &out_x, &out_y));
  EXPECT_FLOAT_EQ(out_x, 20.0f);  // 5 * 2 + 10 = 20
  EXPECT_FLOAT_EQ(out_y, 30.0f);  // 5 * 2 + 20 = 30

  // PreConcat: this = this * other
  AndroidMatrix3x3 pre_concat = m1;
  pre_concat.PreConcat(m2);
  EXPECT_EQ(pre_concat, combined);

  // PostConcat: this = other * this
  AndroidMatrix3x3 post_concat = m2;
  post_concat.PostConcat(m1);
  EXPECT_EQ(post_concat, combined);
}

TEST(AndroidMutatorTest, Matrix3x3FromFlutterTransformation) {
  FlutterTransformation ft = {
      .scaleX = 2.0,
      .skewX = 0.5,
      .transX = 15.0,
      .skewY = 0.25,
      .scaleY = 3.0,
      .transY = 25.0,
      .pers0 = 0.0,
      .pers1 = 0.0,
      .pers2 = 1.0,
  };

  AndroidMatrix3x3 mat = AndroidMatrix3x3::FromFlutterTransformation(ft);
  EXPECT_FLOAT_EQ(mat.values[0], 2.0f);
  EXPECT_FLOAT_EQ(mat.values[1], 0.5f);
  EXPECT_FLOAT_EQ(mat.values[2], 15.0f);
  EXPECT_FLOAT_EQ(mat.values[3], 0.25f);
  EXPECT_FLOAT_EQ(mat.values[4], 3.0f);
  EXPECT_FLOAT_EQ(mat.values[5], 25.0f);
  EXPECT_FLOAT_EQ(mat.values[6], 0.0f);
  EXPECT_FLOAT_EQ(mat.values[7], 0.0f);
  EXPECT_FLOAT_EQ(mat.values[8], 1.0f);

  float out_x = 0.0f;
  float out_y = 0.0f;
  EXPECT_TRUE(mat.TransformPoint(10.0f, 10.0f, &out_x, &out_y));
  EXPECT_FLOAT_EQ(out_x, 2.0f * 10.0f + 0.5f * 10.0f + 15.0f);   // 40.0
  EXPECT_FLOAT_EQ(out_y, 0.25f * 10.0f + 3.0f * 10.0f + 25.0f);  // 57.5
}

TEST(AndroidMutatorTest, AndroidRectConversion) {
  FlutterRect fr = {
      .left = 10.5,
      .top = 20.5,
      .right = 110.5,
      .bottom = 220.5,
  };

  AndroidRect ar = AndroidRect::FromFlutterRect(fr);
  EXPECT_FLOAT_EQ(ar.left, 10.5f);
  EXPECT_FLOAT_EQ(ar.top, 20.5f);
  EXPECT_FLOAT_EQ(ar.right, 110.5f);
  EXPECT_FLOAT_EQ(ar.bottom, 220.5f);
  EXPECT_FLOAT_EQ(ar.width(), 100.0f);
  EXPECT_FLOAT_EQ(ar.height(), 200.0f);
  EXPECT_FALSE(ar.IsEmpty());

  AndroidRect empty_rect = {100.0f, 100.0f, 50.0f, 50.0f};
  EXPECT_TRUE(empty_rect.IsEmpty());
}

TEST(AndroidMutatorTest, AndroidRoundedRectConversion) {
  FlutterRoundedRect frr = {
      .rect = {.left = 0.0, .top = 0.0, .right = 100.0, .bottom = 50.0},
      .upper_left_corner_radius = {.width = 5.0, .height = 6.0},
      .upper_right_corner_radius = {.width = 7.0, .height = 8.0},
      .lower_right_corner_radius = {.width = 9.0, .height = 10.0},
      .lower_left_corner_radius = {.width = 11.0, .height = 12.0},
  };

  AndroidRoundedRect arr = AndroidRoundedRect::FromFlutterRoundedRect(frr);
  EXPECT_FLOAT_EQ(arr.rect.left, 0.0f);
  EXPECT_FLOAT_EQ(arr.rect.right, 100.0f);
  EXPECT_FLOAT_EQ(arr.radii[0], 5.0f);
  EXPECT_FLOAT_EQ(arr.radii[1], 6.0f);
  EXPECT_FLOAT_EQ(arr.radii[2], 7.0f);
  EXPECT_FLOAT_EQ(arr.radii[3], 8.0f);
  EXPECT_FLOAT_EQ(arr.radii[4], 9.0f);
  EXPECT_FLOAT_EQ(arr.radii[5], 10.0f);
  EXPECT_FLOAT_EQ(arr.radii[6], 11.0f);
  EXPECT_FLOAT_EQ(arr.radii[7], 12.0f);
}

TEST(AndroidMutatorTest, AndroidMutatorsStackOperations) {
  AndroidMutatorsStack stack;
  EXPECT_EQ(stack.GetMutatorsCount(), 0u);
  EXPECT_FLOAT_EQ(stack.GetFinalOpacity(), 1.0f);
  EXPECT_TRUE(stack.GetFinalMatrix().IsIdentity());

  // 1. Push Transform
  FlutterTransformation ft = {
      .scaleX = 2.0,
      .skewX = 0.0,
      .transX = 100.0,
      .skewY = 0.0,
      .scaleY = 2.0,
      .transY = 200.0,
      .pers0 = 0.0,
      .pers1 = 0.0,
      .pers2 = 1.0,
  };
  stack.PushTransform(ft);
  EXPECT_EQ(stack.GetMutatorsCount(), 1u);
  EXPECT_EQ(stack.GetMutators()[0].type, AndroidMutatorType::kTransform);

  // 2. Push Opacity
  stack.PushOpacity(0.5f);
  EXPECT_EQ(stack.GetMutatorsCount(), 2u);
  EXPECT_FLOAT_EQ(stack.GetFinalOpacity(), 0.5f);

  stack.PushOpacity(0.5f);
  EXPECT_FLOAT_EQ(stack.GetFinalOpacity(), 0.25f);

  // 3. Push ClipRect
  FlutterRect rect = {.left = 10.0, .top = 20.0, .right = 90.0, .bottom = 80.0};
  stack.PushClipRect(rect);
  EXPECT_EQ(stack.GetMutatorsCount(), 4u);
  EXPECT_EQ(stack.GetFinalClipRects().size(), 1u);
  EXPECT_FLOAT_EQ(stack.GetFinalClipRects()[0].left, 10.0f);

  // 4. Push ClipRRect
  FlutterRoundedRect rrect = {
      .rect = rect,
      .upper_left_corner_radius = {.width = 4.0, .height = 4.0},
      .upper_right_corner_radius = {.width = 4.0, .height = 4.0},
      .lower_right_corner_radius = {.width = 4.0, .height = 4.0},
      .lower_left_corner_radius = {.width = 4.0, .height = 4.0},
  };
  stack.PushClipRRect(rrect);
  EXPECT_EQ(stack.GetMutatorsCount(), 5u);
  EXPECT_EQ(stack.GetFinalClipRRects().size(), 1u);

  // 5. Test Clear
  stack.Clear();
  EXPECT_EQ(stack.GetMutatorsCount(), 0u);
  EXPECT_FLOAT_EQ(stack.GetFinalOpacity(), 1.0f);
  EXPECT_TRUE(stack.GetFinalMatrix().IsIdentity());
  EXPECT_TRUE(stack.GetFinalClipRects().empty());
  EXPECT_TRUE(stack.GetFinalClipRRects().empty());
}

TEST(AndroidMutatorTest, PlatformViewMatrixParityWithFlutterMutatorView) {
  // Test parity with FlutterMutatorView.java:
  // getPlatformViewMatrix():
  // 1. finalMatrix
  // 2. finalMatrix.preScale(1 / screenDensity, 1 / screenDensity)
  // 3. finalMatrix.postTranslate(-left, -top)
  AndroidMutatorsStack stack;

  FlutterTransformation ft = {
      .scaleX = 4.0,
      .skewX = 0.0,
      .transX = 400.0,
      .skewY = 0.0,
      .scaleY = 4.0,
      .transY = 600.0,
      .pers0 = 0.0,
      .pers1 = 0.0,
      .pers2 = 1.0,
  };
  stack.PushTransform(ft);

  float screen_density = 2.0f;
  float left = 50.0f;
  float top = 100.0f;

  AndroidMatrix3x3 pv_matrix =
      stack.GetPlatformViewMatrix(screen_density, left, top);

  // Expected computation:
  // Scale down by screen_density:
  // Scale(0.5, 0.5) * Transform:
  // matrix = [4, 0, 400; 0, 4, 600; 0, 0, 1] * [0.5, 0, 0; 0, 0.5, 0; 0, 0, 1]
  // = [2, 0, 400; 0, 2, 600; 0, 0, 1]
  // Then post-translate by (-50, -100):
  // = [2, 0, 350; 0, 2, 500; 0, 0, 1]
  EXPECT_FLOAT_EQ(pv_matrix.values[0], 2.0f);
  EXPECT_FLOAT_EQ(pv_matrix.values[4], 2.0f);
  EXPECT_FLOAT_EQ(pv_matrix.values[2], 350.0f);
  EXPECT_FLOAT_EQ(pv_matrix.values[5], 500.0f);

  float tx = 0.0f;
  float ty = 0.0f;
  EXPECT_TRUE(pv_matrix.TransformPoint(10.0f, 10.0f, &tx, &ty));
  EXPECT_FLOAT_EQ(tx, 10.0f * 2.0f + 350.0f);  // 370.0
  EXPECT_FLOAT_EQ(ty, 10.0f * 2.0f + 500.0f);  // 520.0
}

TEST(AndroidMutatorTest, AndroidMutatorsMapperMapPlatformView) {
  FlutterPlatformViewMutation m1 = {
      .type = kFlutterPlatformViewMutationTypeTransformation,
      .transformation =
          {
              .scaleX = 1.5,
              .skewX = 0.0,
              .transX = 30.0,
              .skewY = 0.0,
              .scaleY = 1.5,
              .transY = 40.0,
              .pers0 = 0.0,
              .pers1 = 0.0,
              .pers2 = 1.0,
          },
  };

  FlutterPlatformViewMutation m2 = {
      .type = kFlutterPlatformViewMutationTypeOpacity,
      .opacity = 0.8,
  };

  FlutterPlatformViewMutation m3 = {
      .type = kFlutterPlatformViewMutationTypeClipRect,
      .clip_rect = {.left = 0.0, .top = 0.0, .right = 200.0, .bottom = 200.0},
  };

  const FlutterPlatformViewMutation* mutations[] = {&m1, &m2, &m3};

  FlutterPlatformView pv = {
      .struct_size = sizeof(FlutterPlatformView),
      .identifier = 42,
      .mutations_count = 3,
      .mutations = mutations,
  };

  AndroidMutatorsStack stack = AndroidMutatorsMapper::MapPlatformView(pv);
  EXPECT_EQ(stack.GetMutatorsCount(), 3u);
  EXPECT_FLOAT_EQ(stack.GetFinalOpacity(), 0.8f);
  EXPECT_EQ(stack.GetFinalClipRects().size(), 1u);
  EXPECT_FLOAT_EQ(stack.GetFinalMatrix().values[0], 1.5f);
  EXPECT_FLOAT_EQ(stack.GetFinalMatrix().values[2], 30.0f);

  // Invalid struct size should return empty stack safely
  FlutterPlatformView invalid_pv = pv;
  invalid_pv.struct_size = sizeof(FlutterPlatformView) - 1;
  EXPECT_EQ(
      AndroidMutatorsMapper::MapPlatformView(invalid_pv).GetMutatorsCount(),
      0u);
}

TEST(AndroidMutatorTest, SerializationAndDeserializationRoundtrip) {
  AndroidMutatorsStack original;

  FlutterTransformation ft = {
      .scaleX = 2.0,
      .skewX = 0.1,
      .transX = 10.0,
      .skewY = 0.2,
      .scaleY = 3.0,
      .transY = 20.0,
      .pers0 = 0.0,
      .pers1 = 0.0,
      .pers2 = 1.0,
  };
  original.PushTransform(ft);
  original.PushOpacity(0.75f);

  FlutterRect rect = {
      .left = 5.0, .top = 10.0, .right = 105.0, .bottom = 210.0};
  original.PushClipRect(rect);

  FlutterRoundedRect rrect = {
      .rect = rect,
      .upper_left_corner_radius = {.width = 2.0, .height = 2.0},
      .upper_right_corner_radius = {.width = 3.0, .height = 3.0},
      .lower_right_corner_radius = {.width = 4.0, .height = 4.0},
      .lower_left_corner_radius = {.width = 5.0, .height = 5.0},
  };
  original.PushClipRRect(rrect);

  std::vector<uint8_t> bytes = original.Serialize();
  ASSERT_FALSE(bytes.empty());

  auto deserialized =
      AndroidMutatorsStack::Deserialize(bytes.data(), bytes.size());
  ASSERT_TRUE(deserialized.has_value());
  if (deserialized.has_value()) {
    EXPECT_EQ(*deserialized, original);
  }

  // Corrupted bytes return nullopt
  EXPECT_FALSE(AndroidMutatorsStack::Deserialize(nullptr, 0).has_value());
  std::vector<uint8_t> corrupted = bytes;
  corrupted[0] = 0xFF;  // break magic
  EXPECT_FALSE(
      AndroidMutatorsStack::Deserialize(corrupted.data(), corrupted.size())
          .has_value());

  // Trailing extraneous padding bytes should be rejected strictly
  std::vector<uint8_t> padded = bytes;
  padded.push_back(0x00);
  EXPECT_FALSE(AndroidMutatorsStack::Deserialize(padded.data(), padded.size())
                   .has_value());
}

TEST(AndroidMutatorTest, MultithreadedConcurrentMapping) {
  constexpr size_t kThreadCount = 8;
  constexpr size_t kIterations = 100;
  std::vector<std::future<bool>> futures;
  futures.reserve(kThreadCount);

  for (size_t t = 0; t < kThreadCount; ++t) {
    futures.push_back(std::async(std::launch::async, [t]() {
      for (size_t iter = 0; iter < kIterations; ++iter) {
        FlutterPlatformViewMutation m1 = {
            .type = kFlutterPlatformViewMutationTypeTransformation,
            .transformation =
                {
                    .scaleX = static_cast<double>(t + 1),
                    .skewX = 0.0,
                    .transX = static_cast<double>(iter),
                    .skewY = 0.0,
                    .scaleY = static_cast<double>(t + 1),
                    .transY = static_cast<double>(iter * 2),
                    .pers0 = 0.0,
                    .pers1 = 0.0,
                    .pers2 = 1.0,
                },
        };
        FlutterPlatformViewMutation m2 = {
            .type = kFlutterPlatformViewMutationTypeOpacity,
            .opacity = 0.9,
        };
        const FlutterPlatformViewMutation* mutations[] = {&m1, &m2};
        FlutterPlatformView pv = {
            .struct_size = sizeof(FlutterPlatformView),
            .identifier =
                static_cast<FlutterPlatformViewIdentifier>(t * 1000 + iter),
            .mutations_count = 2,
            .mutations = mutations,
        };
        AndroidMutatorsStack stack = AndroidMutatorsMapper::MapPlatformView(pv);
        if (stack.GetMutatorsCount() != 2) {
          return false;
        }
        std::vector<uint8_t> bytes = stack.Serialize();
        auto copy =
            AndroidMutatorsStack::Deserialize(bytes.data(), bytes.size());
        if (!copy.has_value() || *copy != stack) {
          return false;
        }
      }
      return true;
    }));
  }

  for (auto& f : futures) {
    EXPECT_TRUE(f.get());
  }
}

}  // namespace testing
}  // namespace android
}  // namespace flutter
