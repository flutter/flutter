// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <GLES2/gl2extchromium.h>

#include "base/basictypes.h"
#include "gpu/command_buffer/tests/gl_manager.h"
#include "gpu/command_buffer/tests/gl_test_utils.h"
#include "testing/gtest/include/gtest/gtest.h"

#define SHADER(src) #src

namespace gpu {

static const uint16 kRedMask = 0xF800;
static const uint16 kGreenMask = 0x07E0;
static const uint16 kBlueMask = 0x001F;

// Color palette in 565 format.
static const uint16 kPalette[] = {
  kGreenMask | kBlueMask,   // Cyan.
  kBlueMask  | kRedMask,    // Magenta.
  kRedMask   | kGreenMask,  // Yellow.
  0x0000,                   // Black.
  kRedMask,                 // Red.
  kGreenMask,               // Green.
  kBlueMask,                // Blue.
  0xFFFF,                   // White.
};
static const unsigned kBlockSize = 4;
static const unsigned kPaletteSize = sizeof(kPalette) / sizeof(kPalette[0]);
static const unsigned kTextureWidth = kBlockSize * kPaletteSize;
static const unsigned kTextureHeight = kBlockSize;

static const char* extension(GLenum format) {
  switch(format) {
    case GL_COMPRESSED_RGB_S3TC_DXT1_EXT:
    case GL_COMPRESSED_RGBA_S3TC_DXT1_EXT:
      return "GL_EXT_texture_compression_dxt1";
    case GL_COMPRESSED_RGBA_S3TC_DXT3_EXT:
      return "GL_CHROMIUM_texture_compression_dxt3";
    case GL_COMPRESSED_RGBA_S3TC_DXT5_EXT:
      return "GL_CHROMIUM_texture_compression_dxt5";
    default:
      NOTREACHED();
  }
  return NULL;
}

// Index that chooses the given colors (color_0 and color_1),
// not the interpolated colors (color_2 and color_3).
static const uint16 kColor0 = 0x0000;
static const uint16 kColor1 = 0x5555;

static GLuint LoadCompressedTexture(const void* data,
                                    GLsizeiptr size,
                                    GLenum format,
                                    GLsizei width,
                                    GLsizei height) {
  GLuint texture;
  glGenTextures(1, &texture);
  glBindTexture(GL_TEXTURE_2D, texture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glCompressedTexImage2D(
      GL_TEXTURE_2D, 0, format, width, height, 0, size, data);
  return texture;
}

GLuint LoadTextureDXT1(bool alpha) {
  const unsigned kStride = 4;
  uint16 data[kStride * kPaletteSize];
  for (unsigned i = 0; i < kPaletteSize; ++i) {
    // Each iteration defines a 4x4 block of texture.
    unsigned j = kStride * i;
    data[j++] = kPalette[i];  // color_0.
    data[j++] = kPalette[i];  // color_1.
    data[j++] = kColor0;  // color index.
    data[j++] = kColor1;  // color index.
  }
  GLenum format = alpha ?
      GL_COMPRESSED_RGBA_S3TC_DXT1_EXT : GL_COMPRESSED_RGB_S3TC_DXT1_EXT;
  return LoadCompressedTexture(
      data, sizeof(data), format, kTextureWidth, kTextureHeight);
}

GLuint LoadTextureDXT3() {
  const unsigned kStride = 8;
  const uint16 kOpaque = 0xFFFF;
  uint16 data[kStride * kPaletteSize];
  for (unsigned i = 0; i < kPaletteSize; ++i) {
    // Each iteration defines a 4x4 block of texture.
    unsigned j = kStride * i;
    data[j++] = kOpaque;  // alpha row 0.
    data[j++] = kOpaque;  // alpha row 1.
    data[j++] = kOpaque;  // alpha row 2.
    data[j++] = kOpaque;  // alpha row 3.
    data[j++] = kPalette[i];  // color_0.
    data[j++] = kPalette[i];  // color_1.
    data[j++] = kColor0;  // color index.
    data[j++] = kColor1;  // color index.
  }
  return LoadCompressedTexture(data,
                               sizeof(data),
                               GL_COMPRESSED_RGBA_S3TC_DXT3_EXT,
                               kTextureWidth,
                               kTextureHeight);
}

GLuint LoadTextureDXT5() {
  const unsigned kStride = 8;
  const uint16 kClear = 0x0000;
  const uint16 kAlpha7 = 0xFFFF;  // Opaque alpha index.
  uint16 data[kStride * kPaletteSize];
  for (unsigned i = 0; i < kPaletteSize; ++i) {
    // Each iteration defines a 4x4 block of texture.
    unsigned j = kStride * i;
    data[j++] = kClear;  // alpha_0 | alpha_1.
    data[j++] = kAlpha7;  // alpha index.
    data[j++] = kAlpha7;  // alpha index.
    data[j++] = kAlpha7;  // alpha index.
    data[j++] = kPalette[i];  // color_0.
    data[j++] = kPalette[i];  // color_1.
    data[j++] = kColor0;  // color index.
    data[j++] = kColor1;  // color index.
  }
  return LoadCompressedTexture(data,
                               sizeof(data),
                               GL_COMPRESSED_RGBA_S3TC_DXT5_EXT,
                               kTextureWidth,
                               kTextureHeight);
}

static void ToRGB888(uint16 rgb565, uint8 rgb888[]) {
  uint8 r5 = (rgb565 & kRedMask)   >> 11;
  uint8 g6 = (rgb565 & kGreenMask) >> 5;
  uint8 b5 = (rgb565 & kBlueMask);
  // Replicate upper bits to lower empty bits.
  rgb888[0] = (r5 << 3) | (r5 >> 2);
  rgb888[1] = (g6 << 2) | (g6 >> 4);
  rgb888[2] = (b5 << 3) | (b5 >> 2);
}

class CompressedTextureTest : public ::testing::TestWithParam<GLenum> {
 protected:
  void SetUp() override {
    GLManager::Options options;
    options.size = gfx::Size(kTextureWidth, kTextureHeight);
    gl_.Initialize(options);
  }

  void TearDown() override { gl_.Destroy(); }

  GLuint LoadProgram() {
    const char* v_shader_src = SHADER(
        attribute vec2 a_position;
        varying vec2 v_texcoord;
        void main() {
          gl_Position = vec4(a_position, 0.0, 1.0);
          v_texcoord = (a_position + 1.0) * 0.5;
        }
    );
    const char* f_shader_src = SHADER(
        precision mediump float;
        uniform sampler2D u_texture;
        varying vec2 v_texcoord;
        void main() {
          gl_FragColor = texture2D(u_texture, v_texcoord);
        }
    );
    return GLTestHelper::LoadProgram(v_shader_src, f_shader_src);
  }

  GLuint LoadTexture(GLenum format) {
    switch (format) {
      case GL_COMPRESSED_RGB_S3TC_DXT1_EXT: return LoadTextureDXT1(false);
      case GL_COMPRESSED_RGBA_S3TC_DXT1_EXT: return LoadTextureDXT1(true);
      case GL_COMPRESSED_RGBA_S3TC_DXT3_EXT: return LoadTextureDXT3();
      case GL_COMPRESSED_RGBA_S3TC_DXT5_EXT: return LoadTextureDXT5();
      default: NOTREACHED();
    }
    return 0;
  }

 private:
  GLManager gl_;
};

// The test draws a texture in the given format and verifies that the drawn
// pixels are of the same color as the texture.
// The texture consists of 4x4 blocks of texels (same as DXT), one for each
// color defined in kPalette.
TEST_P(CompressedTextureTest, Draw) {
  GLenum format = GetParam();

  // This test is only valid if compressed texture extension is supported.
  const char* ext = extension(format);
  if (!GLTestHelper::HasExtension(ext))
    return;

  // Load shader program.
  GLuint program = LoadProgram();
  ASSERT_NE(program, 0u);
  GLint position_loc = glGetAttribLocation(program, "a_position");
  GLint texture_loc = glGetUniformLocation(program, "u_texture");
  ASSERT_NE(position_loc, -1);
  ASSERT_NE(texture_loc, -1);
  glUseProgram(program);

  // Load geometry.
  GLuint vbo = GLTestHelper::SetupUnitQuad(position_loc);
  ASSERT_NE(vbo, 0u);

  // Load texture.
  GLuint texture = LoadTexture(format);
  ASSERT_NE(texture, 0u);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, texture);
  glUniform1i(texture_loc, 0);

  // Draw.
  glDrawArrays(GL_TRIANGLES, 0, 6);
  glFlush();

  // Verify results.
  int origin[] = {0, 0};
  uint8 expected_rgba[] = {0, 0, 0, 255};
  for (unsigned i = 0; i < kPaletteSize; ++i) {
    origin[0] = kBlockSize * i;
    ToRGB888(kPalette[i], expected_rgba);
    EXPECT_TRUE(GLTestHelper::CheckPixels(origin[0], origin[1],
                                          kBlockSize, kBlockSize,
                                          0, expected_rgba));
  }
  GLTestHelper::CheckGLError("CompressedTextureTest.Draw", __LINE__);
}

static const GLenum kFormats[] = {
  GL_COMPRESSED_RGB_S3TC_DXT1_EXT,
  GL_COMPRESSED_RGBA_S3TC_DXT1_EXT,
  GL_COMPRESSED_RGBA_S3TC_DXT3_EXT,
  GL_COMPRESSED_RGBA_S3TC_DXT5_EXT
};
INSTANTIATE_TEST_CASE_P(Format,
                        CompressedTextureTest,
                        ::testing::ValuesIn(kFormats));

}  // namespace gpu
