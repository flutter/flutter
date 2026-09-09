// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/core/shader_types.h"

namespace impeller {
namespace testing {
namespace {

// Builds a vertex input slot with the fields that drive the format derivation.
ShaderStageIOSlot MakeSlot(ShaderType type,
                           size_t bit_width,
                           size_t vec_size,
                           size_t columns = 1u) {
  return ShaderStageIOSlot{
      "test",  // name
      0u,      // location
      0u,      // set
      0u,      // binding
      type,    // type
      bit_width, vec_size, columns,
      0u,     // offset
      false,  // relaxed_precision
  };
}

}  // namespace

TEST(ShaderTypesTest, VertexAttributeFormatFloat32) {
  EXPECT_EQ(MakeSlot(ShaderType::kFloat, 32u, 1u).GetVertexAttributeFormat(),
            VertexAttributeFormat::kFloat32);
  EXPECT_EQ(MakeSlot(ShaderType::kFloat, 32u, 2u).GetVertexAttributeFormat(),
            VertexAttributeFormat::kFloat32x2);
  EXPECT_EQ(MakeSlot(ShaderType::kFloat, 32u, 3u).GetVertexAttributeFormat(),
            VertexAttributeFormat::kFloat32x3);
  EXPECT_EQ(MakeSlot(ShaderType::kFloat, 32u, 4u).GetVertexAttributeFormat(),
            VertexAttributeFormat::kFloat32x4);
}

TEST(ShaderTypesTest, VertexAttributeFormatHalfFloat) {
  EXPECT_EQ(
      MakeSlot(ShaderType::kHalfFloat, 16u, 1u).GetVertexAttributeFormat(),
      VertexAttributeFormat::kFloat16);
  EXPECT_EQ(
      MakeSlot(ShaderType::kHalfFloat, 16u, 4u).GetVertexAttributeFormat(),
      VertexAttributeFormat::kFloat16x4);
}

TEST(ShaderTypesTest, VertexAttributeFormatIntegers) {
  EXPECT_EQ(
      MakeSlot(ShaderType::kSignedByte, 8u, 1u).GetVertexAttributeFormat(),
      VertexAttributeFormat::kSInt8);
  EXPECT_EQ(
      MakeSlot(ShaderType::kUnsignedByte, 8u, 4u).GetVertexAttributeFormat(),
      VertexAttributeFormat::kUInt8x4);
  EXPECT_EQ(
      MakeSlot(ShaderType::kSignedShort, 16u, 2u).GetVertexAttributeFormat(),
      VertexAttributeFormat::kSInt16x2);
  EXPECT_EQ(
      MakeSlot(ShaderType::kUnsignedShort, 16u, 3u).GetVertexAttributeFormat(),
      VertexAttributeFormat::kUInt16x3);
  EXPECT_EQ(
      MakeSlot(ShaderType::kSignedInt, 32u, 1u).GetVertexAttributeFormat(),
      VertexAttributeFormat::kSInt32);
  EXPECT_EQ(
      MakeSlot(ShaderType::kUnsignedInt, 32u, 4u).GetVertexAttributeFormat(),
      VertexAttributeFormat::kUInt32x4);
}

TEST(ShaderTypesTest, VertexAttributeFormatRejectsMatrices) {
  // Columns greater than one is a matrix input, which is unsupported.
  EXPECT_EQ(MakeSlot(ShaderType::kFloat, 32u, 4u, /*columns=*/4u)
                .GetVertexAttributeFormat(),
            VertexAttributeFormat::kInvalid);
}

TEST(ShaderTypesTest, VertexAttributeFormatRejectsBadComponentCount) {
  EXPECT_EQ(MakeSlot(ShaderType::kFloat, 32u, 0u).GetVertexAttributeFormat(),
            VertexAttributeFormat::kInvalid);
  EXPECT_EQ(MakeSlot(ShaderType::kFloat, 32u, 5u).GetVertexAttributeFormat(),
            VertexAttributeFormat::kInvalid);
}

TEST(ShaderTypesTest, VertexAttributeFormatRejectsBadBitWidth) {
  EXPECT_EQ(MakeSlot(ShaderType::kFloat, 16u, 1u).GetVertexAttributeFormat(),
            VertexAttributeFormat::kInvalid);
  EXPECT_EQ(
      MakeSlot(ShaderType::kSignedInt, 16u, 1u).GetVertexAttributeFormat(),
      VertexAttributeFormat::kInvalid);
}

TEST(ShaderTypesTest, VertexAttributeFormatRejectsUnsupportedScalarKinds) {
  EXPECT_EQ(MakeSlot(ShaderType::kBoolean, 8u, 1u).GetVertexAttributeFormat(),
            VertexAttributeFormat::kInvalid);
  EXPECT_EQ(MakeSlot(ShaderType::kDouble, 64u, 1u).GetVertexAttributeFormat(),
            VertexAttributeFormat::kInvalid);
  EXPECT_EQ(
      MakeSlot(ShaderType::kSignedInt64, 64u, 1u).GetVertexAttributeFormat(),
      VertexAttributeFormat::kInvalid);
}

}  // namespace testing
}  // namespace impeller
