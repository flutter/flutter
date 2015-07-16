// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/common/gles2_cmd_utils.h"

#include <limits>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <GLES2/gl2extchromium.h>
#include <GLES3/gl3.h>

#include "testing/gtest/include/gtest/gtest.h"

namespace gpu {
namespace gles2 {

class GLES2UtilTest : public testing:: Test {
 protected:
  GLES2Util util_;
};

TEST_F(GLES2UtilTest, SafeMultiplyUint32) {
  uint32_t result = 0;
  EXPECT_TRUE(SafeMultiplyUint32(2u, 3u, &result));
  EXPECT_EQ(6u, result);
  EXPECT_FALSE(SafeMultiplyUint32(0x80000000u, 2u, &result));
  EXPECT_EQ(0u, result);
  EXPECT_TRUE(SafeMultiplyUint32(0x2u, 0x7FFFFFFFu, &result));
  EXPECT_EQ(0xFFFFFFFEu, result);
  EXPECT_FALSE(SafeMultiplyUint32(2u, 0x80000000u, &result));
  EXPECT_EQ(0u, result);
}

TEST_F(GLES2UtilTest, SafeAddUint32) {
  uint32_t result = 0;
  EXPECT_TRUE(SafeAddUint32(2u, 3u, &result));
  EXPECT_EQ(5u, result);
  EXPECT_FALSE(SafeAddUint32(0x80000000u, 0x80000000u, &result));
  EXPECT_EQ(0u, result);
  EXPECT_TRUE(SafeAddUint32(0xFFFFFFFEu, 0x1u, &result));
  EXPECT_EQ(0xFFFFFFFFu, result);
  EXPECT_FALSE(SafeAddUint32(0xFFFFFFFEu, 0x2u, &result));
  EXPECT_EQ(0u, result);
  EXPECT_TRUE(SafeAddUint32(0x1u, 0xFFFFFFFEu, &result));
  EXPECT_EQ(0xFFFFFFFFu, result);
  EXPECT_FALSE(SafeAddUint32(0x2u, 0xFFFFFFFEu, &result));
  EXPECT_EQ(0u, result);
}

TEST_F(GLES2UtilTest, SafeAddInt32) {
  int32_t result = 0;
  const int32_t kMax = std::numeric_limits<int32_t>::max();
  const int32_t kMin = std::numeric_limits<int32_t>::min();
  EXPECT_TRUE(SafeAddInt32(2, 3, &result));
  EXPECT_EQ(5, result);
  EXPECT_FALSE(SafeAddInt32(kMax, 1, &result));
  EXPECT_EQ(0, result);
  EXPECT_TRUE(SafeAddInt32(kMin + 1, -1, &result));
  EXPECT_EQ(kMin, result);
  EXPECT_FALSE(SafeAddInt32(kMin, -1, &result));
  EXPECT_EQ(0, result);
  EXPECT_TRUE(SafeAddInt32(kMax - 1, 1, &result));
  EXPECT_EQ(kMax, result);
  EXPECT_FALSE(SafeAddInt32(1, kMax, &result));
  EXPECT_EQ(0, result);
  EXPECT_TRUE(SafeAddInt32(-1, kMin + 1, &result));
  EXPECT_EQ(kMin, result);
  EXPECT_FALSE(SafeAddInt32(-1, kMin, &result));
  EXPECT_EQ(0, result);
  EXPECT_TRUE(SafeAddInt32(1, kMax - 1, &result));
  EXPECT_EQ(kMax, result);
}

TEST_F(GLES2UtilTest, GLGetNumValuesReturned) {
  EXPECT_EQ(0, util_.GLGetNumValuesReturned(GL_COMPRESSED_TEXTURE_FORMATS));
  EXPECT_EQ(0, util_.GLGetNumValuesReturned(GL_SHADER_BINARY_FORMATS));

  EXPECT_EQ(0, util_.num_compressed_texture_formats());
  EXPECT_EQ(0, util_.num_shader_binary_formats());

  util_.set_num_compressed_texture_formats(1);
  util_.set_num_shader_binary_formats(2);

  EXPECT_EQ(1, util_.GLGetNumValuesReturned(GL_COMPRESSED_TEXTURE_FORMATS));
  EXPECT_EQ(2, util_.GLGetNumValuesReturned(GL_SHADER_BINARY_FORMATS));

  EXPECT_EQ(1, util_.num_compressed_texture_formats());
  EXPECT_EQ(2, util_.num_shader_binary_formats());
}

TEST_F(GLES2UtilTest, ComputeImageDataSizesFormats) {
  const uint32_t kWidth = 16;
  const uint32_t kHeight = 12;
  uint32_t size;
  uint32_t unpadded_row_size;
  uint32_t padded_row_size;
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_RGB, GL_UNSIGNED_BYTE, 1,
      &size, &unpadded_row_size, &padded_row_size));
  EXPECT_EQ(kWidth * kHeight * 3, size);
  EXPECT_EQ(kWidth * 3, padded_row_size);
  EXPECT_EQ(padded_row_size, unpadded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_RGBA, GL_UNSIGNED_BYTE, 1, &size,
      &unpadded_row_size, &padded_row_size));
  EXPECT_EQ(kWidth * kHeight * 4, size);
  EXPECT_EQ(kWidth * 4, padded_row_size);
  EXPECT_EQ(padded_row_size, unpadded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_LUMINANCE, GL_UNSIGNED_BYTE, 1, &size,
      &unpadded_row_size, &padded_row_size));
  EXPECT_EQ(kWidth * kHeight * 1, size);
  EXPECT_EQ(kWidth * 1, padded_row_size);
  EXPECT_EQ(padded_row_size, unpadded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &size,
      &unpadded_row_size, &padded_row_size));
  EXPECT_EQ(kWidth * kHeight * 2, size);
  EXPECT_EQ(kWidth * 2, padded_row_size);
  EXPECT_EQ(padded_row_size, unpadded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_BGRA_EXT, GL_UNSIGNED_BYTE, 1, &size,
      &unpadded_row_size, &padded_row_size));
  EXPECT_EQ(kWidth * kHeight * 4, size);
  EXPECT_EQ(kWidth * 4, padded_row_size);
  EXPECT_EQ(padded_row_size, unpadded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_ALPHA, GL_UNSIGNED_BYTE, 1, &size,
      &unpadded_row_size, &padded_row_size));
  EXPECT_EQ(kWidth * kHeight * 1, size);
  EXPECT_EQ(kWidth * 1, padded_row_size);
  EXPECT_EQ(padded_row_size, unpadded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_DEPTH_COMPONENT, GL_UNSIGNED_SHORT, 1, &size,
      &unpadded_row_size, &padded_row_size));
  EXPECT_EQ(kWidth * kHeight * 2, size);
  EXPECT_EQ(kWidth * 2, padded_row_size);
  EXPECT_EQ(padded_row_size, unpadded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_DEPTH_STENCIL_OES, GL_UNSIGNED_INT_24_8_OES, 1,
      &size, &unpadded_row_size, &padded_row_size));
  EXPECT_EQ(kWidth * kHeight * 4, size);
  EXPECT_EQ(kWidth * 4, padded_row_size);
  EXPECT_EQ(padded_row_size, unpadded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_RGB_INTEGER, GL_UNSIGNED_BYTE, 1,
      &size, &unpadded_row_size, &padded_row_size));
  EXPECT_EQ(kWidth * kHeight * 3, size);
  EXPECT_EQ(kWidth * 3, padded_row_size);
  EXPECT_EQ(padded_row_size, unpadded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_RG, GL_UNSIGNED_BYTE, 1,
      &size, &unpadded_row_size, &padded_row_size));
  EXPECT_EQ(kWidth * kHeight * 2, size);
  EXPECT_EQ(kWidth * 2, padded_row_size);
  EXPECT_EQ(padded_row_size, unpadded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_RG_INTEGER, GL_UNSIGNED_BYTE, 1,
      &size, &unpadded_row_size, &padded_row_size));
  EXPECT_EQ(kWidth * kHeight * 2, size);
  EXPECT_EQ(kWidth * 2, padded_row_size);
  EXPECT_EQ(padded_row_size, unpadded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_RED, GL_UNSIGNED_BYTE, 1,
      &size, &unpadded_row_size, &padded_row_size));
  EXPECT_EQ(kWidth * kHeight * 1, size);
  EXPECT_EQ(kWidth * 1, padded_row_size);
  EXPECT_EQ(padded_row_size, unpadded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_RED_INTEGER, GL_UNSIGNED_BYTE, 1,
      &size, &unpadded_row_size, &padded_row_size));
  EXPECT_EQ(kWidth * kHeight * 1, size);
  EXPECT_EQ(kWidth * 1, padded_row_size);
  EXPECT_EQ(padded_row_size, unpadded_row_size);
}

TEST_F(GLES2UtilTest, ComputeImageDataSizeTypes) {
  const uint32_t kWidth = 16;
  const uint32_t kHeight = 12;
  uint32_t size;
  uint32_t unpadded_row_size;
  uint32_t padded_row_size;
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_RGBA, GL_UNSIGNED_BYTE, 1, &size,
      &unpadded_row_size, &padded_row_size));
  EXPECT_EQ(kWidth * kHeight * 4, size);
  EXPECT_EQ(kWidth * 4, padded_row_size);
  EXPECT_EQ(padded_row_size, unpadded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_RGBA, GL_UNSIGNED_SHORT_4_4_4_4, 1, &size,
      &unpadded_row_size, &padded_row_size));
  EXPECT_EQ(kWidth * kHeight * 2, size);
  EXPECT_EQ(kWidth * 2, padded_row_size);
  EXPECT_EQ(padded_row_size, unpadded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_RGBA, GL_UNSIGNED_SHORT_5_5_5_1, 1, &size,
      &unpadded_row_size, &padded_row_size));
  EXPECT_EQ(kWidth * kHeight * 2, size);
  EXPECT_EQ(kWidth * 2, padded_row_size);
  EXPECT_EQ(padded_row_size, unpadded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, 1, &size,
      &unpadded_row_size, &padded_row_size));
  EXPECT_EQ(kWidth * kHeight * 2, size);
  EXPECT_EQ(kWidth * 2, padded_row_size);
  EXPECT_EQ(padded_row_size, unpadded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_DEPTH_COMPONENT, GL_UNSIGNED_INT, 1, &size,
      &unpadded_row_size, &padded_row_size));
  EXPECT_EQ(kWidth * kHeight * 4, size);
  EXPECT_EQ(kWidth * 4, padded_row_size);
  EXPECT_EQ(padded_row_size, unpadded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_RGBA, GL_UNSIGNED_INT_2_10_10_10_REV, 1, &size,
      &unpadded_row_size, &padded_row_size));
  EXPECT_EQ(kWidth * kHeight * 4, size);
  EXPECT_EQ(kWidth * 4, padded_row_size);
  EXPECT_EQ(padded_row_size, unpadded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_RGB, GL_UNSIGNED_INT_10F_11F_11F_REV, 1, &size,
      &unpadded_row_size, &padded_row_size));
  EXPECT_EQ(kWidth * kHeight * 4, size);
  EXPECT_EQ(kWidth * 4, padded_row_size);
  EXPECT_EQ(padded_row_size, unpadded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_RGBA, GL_UNSIGNED_INT_5_9_9_9_REV, 1, &size,
      &unpadded_row_size, &padded_row_size));
  EXPECT_EQ(kWidth * kHeight * 4, size);
  EXPECT_EQ(kWidth * 4, padded_row_size);
  EXPECT_EQ(padded_row_size, unpadded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_DEPTH_STENCIL, GL_FLOAT_32_UNSIGNED_INT_24_8_REV,
      1, &size, &unpadded_row_size, &padded_row_size));
  EXPECT_EQ(kWidth * kHeight * 8, size);
  EXPECT_EQ(kWidth * 8, padded_row_size);
  EXPECT_EQ(padded_row_size, unpadded_row_size);
}

TEST_F(GLES2UtilTest, ComputeImageDataSizesUnpackAlignment) {
  const uint32_t kWidth = 19;
  const uint32_t kHeight = 12;
  uint32_t size;
  uint32_t unpadded_row_size;
  uint32_t padded_row_size;
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_RGB, GL_UNSIGNED_BYTE, 1, &size,
      &unpadded_row_size, &padded_row_size));
  EXPECT_EQ(kWidth * kHeight * 3, size);
  EXPECT_EQ(kWidth * 3, unpadded_row_size);
  EXPECT_EQ(kWidth * 3, padded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_RGB, GL_UNSIGNED_BYTE, 2, &size,
      &unpadded_row_size, &padded_row_size));
  EXPECT_EQ((kWidth * 3 + 1) * (kHeight - 1) +
            kWidth * 3, size);
  EXPECT_EQ(kWidth * 3, unpadded_row_size);
  EXPECT_EQ(kWidth * 3 + 1, padded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_RGB, GL_UNSIGNED_BYTE, 4, &size,
      &unpadded_row_size, &padded_row_size));
  EXPECT_EQ((kWidth * 3 + 3) * (kHeight - 1) +
            kWidth * 3, size);
  EXPECT_EQ(kWidth * 3, unpadded_row_size);
  EXPECT_EQ(kWidth * 3 + 3, padded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, 1, GL_RGB, GL_UNSIGNED_BYTE, 8, &size,
      &unpadded_row_size, &padded_row_size));
  EXPECT_EQ((kWidth * 3 + 7) * (kHeight - 1) +
            kWidth * 3, size);
  EXPECT_EQ(kWidth * 3, unpadded_row_size);
  EXPECT_EQ(kWidth * 3 + 7, padded_row_size);
}

TEST_F(GLES2UtilTest, ComputeImageDataSizeDepth) {
  const uint32_t kWidth = 19;
  const uint32_t kHeight = 12;
  const uint32_t kDepth = 3;
  uint32_t size;
  uint32_t unpadded_row_size;
  uint32_t padded_row_size;
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, kDepth, GL_RGB, GL_UNSIGNED_BYTE, 1, &size,
      &unpadded_row_size, &padded_row_size));
  EXPECT_EQ(kWidth * kHeight * kDepth * 3, size);
  EXPECT_EQ(kWidth * 3, padded_row_size);
  EXPECT_EQ(padded_row_size, unpadded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, kDepth, GL_RGB, GL_UNSIGNED_BYTE, 2, &size,
      &unpadded_row_size, &padded_row_size));
  EXPECT_EQ((kWidth * 3 + 1) * (kHeight * kDepth - 1) +
            kWidth * 3, size);
  EXPECT_EQ(kWidth * 3, unpadded_row_size);
  EXPECT_EQ(kWidth * 3 + 1, padded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, kDepth, GL_RGB, GL_UNSIGNED_BYTE, 4, &size,
      &unpadded_row_size, &padded_row_size));
  EXPECT_EQ((kWidth * 3 + 3) * (kHeight * kDepth - 1) +
            kWidth * 3, size);
  EXPECT_EQ(kWidth * 3, unpadded_row_size);
  EXPECT_EQ(kWidth * 3 + 3, padded_row_size);
  EXPECT_TRUE(GLES2Util::ComputeImageDataSizes(
      kWidth, kHeight, kDepth, GL_RGB, GL_UNSIGNED_BYTE, 8, &size,
      &unpadded_row_size, &padded_row_size));
  EXPECT_EQ((kWidth * 3 + 7) * (kHeight * kDepth - 1) +
            kWidth * 3, size);
  EXPECT_EQ(kWidth * 3, unpadded_row_size);
  EXPECT_EQ(kWidth * 3 + 7, padded_row_size);
}

TEST_F(GLES2UtilTest, RenderbufferBytesPerPixel) {
   EXPECT_EQ(1u, GLES2Util::RenderbufferBytesPerPixel(GL_STENCIL_INDEX8));
   EXPECT_EQ(2u, GLES2Util::RenderbufferBytesPerPixel(GL_RGBA4));
   EXPECT_EQ(2u, GLES2Util::RenderbufferBytesPerPixel(GL_RGB565));
   EXPECT_EQ(2u, GLES2Util::RenderbufferBytesPerPixel(GL_RGB5_A1));
   EXPECT_EQ(2u, GLES2Util::RenderbufferBytesPerPixel(GL_DEPTH_COMPONENT16));
   EXPECT_EQ(4u, GLES2Util::RenderbufferBytesPerPixel(GL_RGB));
   EXPECT_EQ(4u, GLES2Util::RenderbufferBytesPerPixel(GL_RGBA));
   EXPECT_EQ(
       4u, GLES2Util::RenderbufferBytesPerPixel(GL_DEPTH24_STENCIL8_OES));
   EXPECT_EQ(4u, GLES2Util::RenderbufferBytesPerPixel(GL_RGB8_OES));
   EXPECT_EQ(4u, GLES2Util::RenderbufferBytesPerPixel(GL_RGBA8_OES));
   EXPECT_EQ(
       4u, GLES2Util::RenderbufferBytesPerPixel(GL_DEPTH_COMPONENT24_OES));
   EXPECT_EQ(0u, GLES2Util::RenderbufferBytesPerPixel(-1));
}

TEST_F(GLES2UtilTest, GetChannelsForCompressedFormat) {
  EXPECT_EQ(0u, GLES2Util::GetChannelsForFormat(GL_ETC1_RGB8_OES));
  EXPECT_EQ(0u, GLES2Util::GetChannelsForFormat(
      GL_COMPRESSED_RGB_S3TC_DXT1_EXT));
  EXPECT_EQ(0u, GLES2Util::GetChannelsForFormat(
      GL_COMPRESSED_RGBA_S3TC_DXT1_EXT));
  EXPECT_EQ(0u, GLES2Util::GetChannelsForFormat(
      GL_COMPRESSED_RGBA_S3TC_DXT3_EXT));
  EXPECT_EQ(0u, GLES2Util::GetChannelsForFormat(
      GL_COMPRESSED_RGBA_S3TC_DXT5_EXT));
  EXPECT_EQ(0u, GLES2Util::GetChannelsForFormat(GL_ATC_RGB_AMD));
  EXPECT_EQ(0u, GLES2Util::GetChannelsForFormat(
      GL_ATC_RGBA_EXPLICIT_ALPHA_AMD));
  EXPECT_EQ(0u, GLES2Util::GetChannelsForFormat(
      GL_ATC_RGBA_INTERPOLATED_ALPHA_AMD));
  EXPECT_EQ(0u, GLES2Util::GetChannelsForFormat(
      GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG));
  EXPECT_EQ(0u, GLES2Util::GetChannelsForFormat(
      GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG));
  EXPECT_EQ(0u, GLES2Util::GetChannelsForFormat(
      GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG));
  EXPECT_EQ(0u, GLES2Util::GetChannelsForFormat(
      GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG));
}

namespace {

void CheckParseUniformName(
    const char* name,
    bool expected_success,
    size_t expected_array_pos,
    int expected_index,
    bool expected_getting_array) {
  int index = 1234;
  size_t array_pos = 1244;
  bool getting_array = false;
  bool success = GLES2Util::ParseUniformName(
      name, &array_pos, &index, &getting_array);
  EXPECT_EQ(expected_success, success);
  if (success) {
    EXPECT_EQ(expected_array_pos, array_pos);
    EXPECT_EQ(expected_index, index);
    EXPECT_EQ(expected_getting_array, getting_array);
  }
}

}  // anonymous namespace

TEST_F(GLES2UtilTest, ParseUniformName) {
  CheckParseUniformName("u_name", true, std::string::npos, 0, false);
  CheckParseUniformName("u_name[]", false, std::string::npos, 0, false);
  CheckParseUniformName("u_name]", false, std::string::npos, 0, false);
  CheckParseUniformName("u_name[0a]", false, std::string::npos, 0, false);
  CheckParseUniformName("u_name[a0]", false, std::string::npos, 0, false);
  CheckParseUniformName("u_name[0a0]", false, std::string::npos, 0, false);
  CheckParseUniformName("u_name[0]", true, 6u, 0, true);
  CheckParseUniformName("u_name[2]", true, 6u, 2, true);
  CheckParseUniformName("u_name[02]", true, 6u, 2, true);
  CheckParseUniformName("u_name[20]", true, 6u, 20, true);
  CheckParseUniformName("u_name[020]", true, 6u, 20, true);
  CheckParseUniformName("u_name[0][0]", true, 9u, 0, true);
  CheckParseUniformName("u_name[3][2]", true, 9u, 2, true);
  CheckParseUniformName("u_name[03][02]", true, 10u, 2, true);
  CheckParseUniformName("u_name[30][20]", true, 10u, 20, true);
  CheckParseUniformName("u_name[030][020]", true, 11u, 20, true);
  CheckParseUniformName("", false, std::string::npos, 0, false);
}

}  // namespace gles2
}  // namespace gpu
