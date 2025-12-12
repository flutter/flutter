// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <optional>

#include "flutter/testing/testing.h"
#include "impeller/entity/contents/runtime_effect_contents.h"
#include "impeller/geometry/geometry_asserts.h"

#include "impeller/renderer/testing/mocks.h"

namespace impeller {
namespace testing {

TEST(RuntimeEffectContentsTest, CalculateFrameInfo) {
  std::vector<RuntimeEffectContents::TextureInput> inputs;
  auto& input = inputs.emplace_back();
  auto mock_texture = std::make_shared<MockTexture>(TextureDescriptor{
      .size = ISize(100, 100),
  });
  EXPECT_CALL(*mock_texture, GetSize())
      .WillRepeatedly(::testing::Return(ISize(100, 100)));
  input.texture = mock_texture;
  // Identity transform
  input.transform = Matrix();

  auto frame_info =
      RuntimeEffectContents::CalculateFrameInfo(inputs, Matrix(), std::nullopt);

  // input.transform (identity) invert is identity.
  // normalize is scale(1/100, 1/100, 1).
  // result = normalize * identity

  Matrix expected = Matrix::MakeScale(Vector3(0.01, 0.01, 1.0));
  EXPECT_MATRIX_NEAR(frame_info.text_transform_0, expected);
}

TEST(RuntimeEffectContentsTest, CalculateFrameInfoWithScale) {
  std::vector<RuntimeEffectContents::TextureInput> inputs;
  auto& input = inputs.emplace_back();
  auto mock_texture = std::make_shared<MockTexture>(TextureDescriptor{
      .size = ISize(100, 100),
  });
  EXPECT_CALL(*mock_texture, GetSize())
      .WillRepeatedly(::testing::Return(ISize(100, 100)));
  input.texture = mock_texture;
  // Screen space is scaled by 2.0 relative to texture?
  // input.transform maps Local -> Screen.

  input.transform = Matrix::MakeScale(Vector2(2.0, 2.0));

  auto frame_info =
      RuntimeEffectContents::CalculateFrameInfo(inputs, Matrix(), std::nullopt);

  // Invert(Scale(2)) = Scale(0.5).
  // Normalize = Scale(0.01).
  // Result = Scale(0.01) * Scale(0.5) = Scale(0.005).

  Matrix expected = Matrix::MakeScale(Vector3(0.005, 0.005, 1.0));
  EXPECT_MATRIX_NEAR(frame_info.text_transform_0, expected);
}

TEST(RuntimeEffectContentsTest, CalculateFrameInfoWithHalo) {
  std::vector<RuntimeEffectContents::TextureInput> inputs;

  // Input 0: Background/Source (Should be centered too)
  {
    auto& input = inputs.emplace_back();
    auto mock_texture = std::make_shared<MockTexture>(TextureDescriptor{
        .size = ISize(100, 100),
    });
    EXPECT_CALL(*mock_texture, GetSize())
        .WillRepeatedly(::testing::Return(ISize(100, 100)));
    input.texture = mock_texture;
    input.transform = Matrix();
  }

  // Input 1: Destination/Halo (Should be centered)
  {
    auto& input = inputs.emplace_back();
    auto mock_texture = std::make_shared<MockTexture>(TextureDescriptor{
        .size = ISize(100, 100),
    });
    EXPECT_CALL(*mock_texture, GetSize())
        .WillRepeatedly(::testing::Return(ISize(100, 100)));
    input.texture = mock_texture;
    input.transform = Matrix();
  }

  // Coverage is 120x120 (100 + 20 padding).
  Rect coverage = Rect::MakeXYWH(0, 0, 120, 120);

  auto frame_info =
      RuntimeEffectContents::CalculateFrameInfo(inputs, Matrix(), coverage);

  // Common expected matrix for 100x100 texture in 120x120 coverage (center
  // offset 10)
  Matrix expected = Matrix::MakeScale(Vector3(0.01, 0.01, 1.0)) *
                    Matrix::MakeTranslation(Vector3(-10.0, -10.0, 0.0));

  // Check Input 0
  EXPECT_MATRIX_NEAR(frame_info.text_transform_0, expected);

  // Check Input 1
  EXPECT_MATRIX_NEAR(frame_info.text_transform_1, expected);
}

}  // namespace testing
}  // namespace impeller
