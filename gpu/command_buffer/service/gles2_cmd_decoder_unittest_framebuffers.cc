// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/gles2_cmd_decoder.h"

#include "base/command_line.h"
#include "base/strings/string_number_conversions.h"
#include "gpu/command_buffer/common/gles2_cmd_format.h"
#include "gpu/command_buffer/common/gles2_cmd_utils.h"
#include "gpu/command_buffer/service/async_pixel_transfer_delegate_mock.h"
#include "gpu/command_buffer/service/async_pixel_transfer_manager.h"
#include "gpu/command_buffer/service/async_pixel_transfer_manager_mock.h"
#include "gpu/command_buffer/service/cmd_buffer_engine.h"
#include "gpu/command_buffer/service/context_group.h"
#include "gpu/command_buffer/service/context_state.h"
#include "gpu/command_buffer/service/gl_surface_mock.h"
#include "gpu/command_buffer/service/gles2_cmd_decoder_unittest.h"

#include "gpu/command_buffer/service/gpu_switches.h"
#include "gpu/command_buffer/service/image_manager.h"
#include "gpu/command_buffer/service/mailbox_manager.h"
#include "gpu/command_buffer/service/mocks.h"
#include "gpu/command_buffer/service/program_manager.h"
#include "gpu/command_buffer/service/test_helper.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_mock.h"
#include "ui/gl/gl_surface_stub.h"

#if !defined(GL_DEPTH24_STENCIL8)
#define GL_DEPTH24_STENCIL8 0x88F0
#endif

using ::gfx::MockGLInterface;
using ::testing::_;
using ::testing::DoAll;
using ::testing::InSequence;
using ::testing::Invoke;
using ::testing::MatcherCast;
using ::testing::Mock;
using ::testing::Pointee;
using ::testing::Return;
using ::testing::SaveArg;
using ::testing::SetArrayArgument;
using ::testing::SetArgumentPointee;
using ::testing::SetArgPointee;
using ::testing::StrEq;
using ::testing::StrictMock;

namespace gpu {
namespace gles2 {

using namespace cmds;

class GLES2DecoderTestWithExtensionsOnGLES2 : public GLES2DecoderTest {
 public:
  GLES2DecoderTestWithExtensionsOnGLES2() {}

  void SetUp() override {}
  void Init(const char* extensions) {
    InitState init;
    init.extensions = extensions;
    init.gl_version = "opengl es 2.0";
    init.has_alpha = true;
    init.has_depth = true;
    init.request_alpha = true;
    init.request_depth = true;
    InitDecoder(init);
  }
};

TEST_P(GLES2DecoderTest, CheckFramebufferStatusWithNoBoundTarget) {
  EXPECT_CALL(*gl_, CheckFramebufferStatusEXT(_)).Times(0);
  CheckFramebufferStatus::Result* result =
      static_cast<CheckFramebufferStatus::Result*>(shared_memory_address_);
  *result = 0;
  CheckFramebufferStatus cmd;
  cmd.Init(GL_FRAMEBUFFER, shared_memory_id_, shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(static_cast<GLenum>(GL_FRAMEBUFFER_COMPLETE), *result);
}

TEST_P(GLES2DecoderWithShaderTest, BindAndDeleteFramebuffer) {
  SetupTexture();
  AddExpectationsForSimulatedAttrib0(kNumVertices, 0);
  SetupExpectationsForApplyingDefaultDirtyState();
  DoBindFramebuffer(
      GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
  DoDeleteFramebuffer(client_framebuffer_id_,
                      kServiceFramebufferId,
                      true,
                      GL_FRAMEBUFFER,
                      0,
                      true,
                      GL_FRAMEBUFFER,
                      0);
  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawArrays cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderTest, FramebufferRenderbufferWithNoBoundTarget) {
  EXPECT_CALL(*gl_, FramebufferRenderbufferEXT(_, _, _, _)).Times(0);
  FramebufferRenderbuffer cmd;
  cmd.Init(GL_FRAMEBUFFER,
           GL_COLOR_ATTACHMENT0,
           GL_RENDERBUFFER,
           client_renderbuffer_id_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderTest, FramebufferTexture2DWithNoBoundTarget) {
  EXPECT_CALL(*gl_, FramebufferTexture2DEXT(_, _, _, _, _)).Times(0);
  FramebufferTexture2D cmd;
  cmd.Init(GL_FRAMEBUFFER,
           GL_COLOR_ATTACHMENT0,
           GL_TEXTURE_2D,
           client_texture_id_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderTest, GetFramebufferAttachmentParameterivWithNoBoundTarget) {
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetFramebufferAttachmentParameterivEXT(_, _, _, _))
      .Times(0);
  GetFramebufferAttachmentParameteriv cmd;
  cmd.Init(GL_FRAMEBUFFER,
           GL_COLOR_ATTACHMENT0,
           GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderTest, GetFramebufferAttachmentParameterivWithRenderbuffer) {
  DoBindFramebuffer(
      GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_,
              FramebufferRenderbufferEXT(GL_FRAMEBUFFER,
                                         GL_COLOR_ATTACHMENT0,
                                         GL_RENDERBUFFER,
                                         kServiceRenderbufferId))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  GetFramebufferAttachmentParameteriv::Result* result =
      static_cast<GetFramebufferAttachmentParameteriv::Result*>(
          shared_memory_address_);
  result->size = 0;
  const GLint* result_value = result->GetData();
  FramebufferRenderbuffer fbrb_cmd;
  GetFramebufferAttachmentParameteriv cmd;
  fbrb_cmd.Init(GL_FRAMEBUFFER,
                GL_COLOR_ATTACHMENT0,
                GL_RENDERBUFFER,
                client_renderbuffer_id_);
  cmd.Init(GL_FRAMEBUFFER,
           GL_COLOR_ATTACHMENT0,
           GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(fbrb_cmd));
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_EQ(static_cast<GLuint>(*result_value), client_renderbuffer_id_);
}

TEST_P(GLES2DecoderTest, GetFramebufferAttachmentParameterivWithTexture) {
  DoBindFramebuffer(
      GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_,
              FramebufferTexture2DEXT(GL_FRAMEBUFFER,
                                      GL_COLOR_ATTACHMENT0,
                                      GL_TEXTURE_2D,
                                      kServiceTextureId,
                                      0))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  GetFramebufferAttachmentParameteriv::Result* result =
      static_cast<GetFramebufferAttachmentParameteriv::Result*>(
          shared_memory_address_);
  result->SetNumResults(0);
  const GLint* result_value = result->GetData();
  FramebufferTexture2D fbtex_cmd;
  GetFramebufferAttachmentParameteriv cmd;
  fbtex_cmd.Init(GL_FRAMEBUFFER,
                 GL_COLOR_ATTACHMENT0,
                 GL_TEXTURE_2D,
                 client_texture_id_);
  cmd.Init(GL_FRAMEBUFFER,
           GL_COLOR_ATTACHMENT0,
           GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(fbtex_cmd));
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_EQ(static_cast<GLuint>(*result_value), client_texture_id_);
}

TEST_P(GLES2DecoderWithShaderTest,
       GetRenderbufferParameterivRebindRenderbuffer) {
  SetupTexture();
  DoBindRenderbuffer(
      GL_RENDERBUFFER, client_renderbuffer_id_, kServiceRenderbufferId);
  DoRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA4, GL_RGBA, 1, 1, GL_NO_ERROR);

  GetRenderbufferParameteriv cmd;
  cmd.Init(GL_RENDERBUFFER,
           GL_RENDERBUFFER_RED_SIZE,
           shared_memory_id_,
           shared_memory_offset_);

  RestoreRenderbufferBindings();
  EnsureRenderbufferBound(true);

  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_,
              GetRenderbufferParameterivEXT(
                  GL_RENDERBUFFER, GL_RENDERBUFFER_RED_SIZE, _));
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderTest, GetRenderbufferParameterivWithNoBoundTarget) {
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetRenderbufferParameterivEXT(_, _, _)).Times(0);
  GetRenderbufferParameteriv cmd;
  cmd.Init(GL_RENDERBUFFER,
           GL_RENDERBUFFER_WIDTH,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, RenderbufferStorageRebindRenderbuffer) {
  SetupTexture();
  DoBindRenderbuffer(
      GL_RENDERBUFFER, client_renderbuffer_id_, kServiceRenderbufferId);
  RestoreRenderbufferBindings();
  EnsureRenderbufferBound(true);
  DoRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA4, GL_RGBA, 1, 1, GL_NO_ERROR);
}

TEST_P(GLES2DecoderTest, RenderbufferStorageWithNoBoundTarget) {
  EXPECT_CALL(*gl_, RenderbufferStorageEXT(_, _, _, _)).Times(0);
  RenderbufferStorage cmd;
  cmd.Init(GL_RENDERBUFFER, GL_RGBA4, 3, 4);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

namespace {

// A class to emulate glReadPixels
class ReadPixelsEmulator {
 public:
  // pack_alignment is the alignment you want ReadPixels to use
  // when copying. The actual data passed in pixels should be contiguous.
  ReadPixelsEmulator(GLsizei width,
                     GLsizei height,
                     GLint bytes_per_pixel,
                     const void* src_pixels,
                     const void* expected_pixels,
                     GLint pack_alignment)
      : width_(width),
        height_(height),
        pack_alignment_(pack_alignment),
        bytes_per_pixel_(bytes_per_pixel),
        src_pixels_(reinterpret_cast<const int8*>(src_pixels)),
        expected_pixels_(reinterpret_cast<const int8*>(expected_pixels)) {}

  void ReadPixels(GLint x,
                  GLint y,
                  GLsizei width,
                  GLsizei height,
                  GLenum format,
                  GLenum type,
                  void* pixels) const {
    DCHECK_GE(x, 0);
    DCHECK_GE(y, 0);
    DCHECK_LE(x + width, width_);
    DCHECK_LE(y + height, height_);
    for (GLint yy = 0; yy < height; ++yy) {
      const int8* src = GetPixelAddress(src_pixels_, x, y + yy);
      const void* dst = ComputePackAlignmentAddress(0, yy, width, pixels);
      memcpy(const_cast<void*>(dst), src, width * bytes_per_pixel_);
    }
  }

  bool CompareRowSegment(GLint x,
                         GLint y,
                         GLsizei width,
                         const void* data) const {
    DCHECK(x + width <= width_ || width == 0);
    return memcmp(data,
                  GetPixelAddress(expected_pixels_, x, y),
                  width * bytes_per_pixel_) == 0;
  }

  // Helper to compute address of pixel in pack aligned data.
  const void* ComputePackAlignmentAddress(GLint x,
                                          GLint y,
                                          GLsizei width,
                                          const void* address) const {
    GLint unpadded_row_size = ComputeImageDataSize(width, 1);
    GLint two_rows_size = ComputeImageDataSize(width, 2);
    GLsizei padded_row_size = two_rows_size - unpadded_row_size;
    GLint offset = y * padded_row_size + x * bytes_per_pixel_;
    return static_cast<const int8*>(address) + offset;
  }

  GLint ComputeImageDataSize(GLint width, GLint height) const {
    GLint row_size = width * bytes_per_pixel_;
    if (height > 1) {
      GLint temp = row_size + pack_alignment_ - 1;
      GLint padded_row_size = (temp / pack_alignment_) * pack_alignment_;
      GLint size_of_all_but_last_row = (height - 1) * padded_row_size;
      return size_of_all_but_last_row + row_size;
    } else {
      return height * row_size;
    }
  }

 private:
  const int8* GetPixelAddress(const int8* base, GLint x, GLint y) const {
    return base + (width_ * y + x) * bytes_per_pixel_;
  }

  GLsizei width_;
  GLsizei height_;
  GLint pack_alignment_;
  GLint bytes_per_pixel_;
  const int8* src_pixels_;
  const int8* expected_pixels_;
};

}  // anonymous namespace

void GLES2DecoderTest::CheckReadPixelsOutOfRange(GLint in_read_x,
                                                 GLint in_read_y,
                                                 GLsizei in_read_width,
                                                 GLsizei in_read_height,
                                                 bool init) {
  const GLsizei kWidth = 5;
  const GLsizei kHeight = 3;
  const GLint kBytesPerPixel = 3;
  const GLint kPackAlignment = 4;
  const GLenum kFormat = GL_RGB;
  static const int8 kSrcPixels[kWidth * kHeight * kBytesPerPixel] = {
      12, 13, 14, 18, 19, 18, 19, 12, 13, 14, 18, 19, 18, 19, 13,
      29, 28, 23, 22, 21, 22, 21, 29, 28, 23, 22, 21, 22, 21, 28,
      31, 34, 39, 37, 32, 37, 32, 31, 34, 39, 37, 32, 37, 32, 34,
  };

  ClearSharedMemory();

  // We need to setup an FBO so we can know the max size that ReadPixels will
  // access
  if (init) {
    DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
    DoTexImage2D(GL_TEXTURE_2D,
                 0,
                 kFormat,
                 kWidth,
                 kHeight,
                 0,
                 kFormat,
                 GL_UNSIGNED_BYTE,
                 kSharedMemoryId,
                 kSharedMemoryOffset);
    DoBindFramebuffer(
        GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
    DoFramebufferTexture2D(GL_FRAMEBUFFER,
                           GL_COLOR_ATTACHMENT0,
                           GL_TEXTURE_2D,
                           client_texture_id_,
                           kServiceTextureId,
                           0,
                           GL_NO_ERROR);
    EXPECT_CALL(*gl_, CheckFramebufferStatusEXT(GL_FRAMEBUFFER))
        .WillOnce(Return(GL_FRAMEBUFFER_COMPLETE))
        .RetiresOnSaturation();
  }

  ReadPixelsEmulator emu(
      kWidth, kHeight, kBytesPerPixel, kSrcPixels, kSrcPixels, kPackAlignment);
  typedef ReadPixels::Result Result;
  Result* result = GetSharedMemoryAs<Result*>();
  uint32 result_shm_id = kSharedMemoryId;
  uint32 result_shm_offset = kSharedMemoryOffset;
  uint32 pixels_shm_id = kSharedMemoryId;
  uint32 pixels_shm_offset = kSharedMemoryOffset + sizeof(*result);
  void* dest = &result[1];
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  // ReadPixels will be called for valid size only even though the command
  // is requesting a larger size.
  GLint read_x = std::max(0, in_read_x);
  GLint read_y = std::max(0, in_read_y);
  GLint read_end_x = std::max(0, std::min(kWidth, in_read_x + in_read_width));
  GLint read_end_y = std::max(0, std::min(kHeight, in_read_y + in_read_height));
  GLint read_width = read_end_x - read_x;
  GLint read_height = read_end_y - read_y;
  if (read_width > 0 && read_height > 0) {
    for (GLint yy = read_y; yy < read_end_y; ++yy) {
      EXPECT_CALL(
          *gl_,
          ReadPixels(read_x, yy, read_width, 1, kFormat, GL_UNSIGNED_BYTE, _))
          .WillOnce(Invoke(&emu, &ReadPixelsEmulator::ReadPixels))
          .RetiresOnSaturation();
    }
  }
  ReadPixels cmd;
  cmd.Init(in_read_x,
           in_read_y,
           in_read_width,
           in_read_height,
           kFormat,
           GL_UNSIGNED_BYTE,
           pixels_shm_id,
           pixels_shm_offset,
           result_shm_id,
           result_shm_offset,
           false);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));

  GLint unpadded_row_size = emu.ComputeImageDataSize(in_read_width, 1);
  scoped_ptr<int8[]> zero(new int8[unpadded_row_size]);
  scoped_ptr<int8[]> pack(new int8[kPackAlignment]);
  memset(zero.get(), 0, unpadded_row_size);
  memset(pack.get(), kInitialMemoryValue, kPackAlignment);
  for (GLint yy = 0; yy < in_read_height; ++yy) {
    const int8* row = static_cast<const int8*>(
        emu.ComputePackAlignmentAddress(0, yy, in_read_width, dest));
    GLint y = in_read_y + yy;
    if (y < 0 || y >= kHeight) {
      EXPECT_EQ(0, memcmp(zero.get(), row, unpadded_row_size));
    } else {
      // check off left.
      GLint num_left_pixels = std::max(-in_read_x, 0);
      GLint num_left_bytes = num_left_pixels * kBytesPerPixel;
      EXPECT_EQ(0, memcmp(zero.get(), row, num_left_bytes));

      // check off right.
      GLint num_right_pixels = std::max(in_read_x + in_read_width - kWidth, 0);
      GLint num_right_bytes = num_right_pixels * kBytesPerPixel;
      EXPECT_EQ(0,
                memcmp(zero.get(),
                       row + unpadded_row_size - num_right_bytes,
                       num_right_bytes));

      // check middle.
      GLint x = std::max(in_read_x, 0);
      GLint num_middle_pixels =
          std::max(in_read_width - num_left_pixels - num_right_pixels, 0);
      EXPECT_TRUE(
          emu.CompareRowSegment(x, y, num_middle_pixels, row + num_left_bytes));
    }

    // check padding
    if (yy != in_read_height - 1) {
      GLint num_padding_bytes =
          (kPackAlignment - 1) - (unpadded_row_size % kPackAlignment);
      EXPECT_EQ(0,
                memcmp(pack.get(), row + unpadded_row_size, num_padding_bytes));
    }
  }
}

TEST_P(GLES2DecoderTest, ReadPixels) {
  const GLsizei kWidth = 5;
  const GLsizei kHeight = 3;
  const GLint kBytesPerPixel = 3;
  const GLint kPackAlignment = 4;
  static const int8 kSrcPixels[kWidth * kHeight * kBytesPerPixel] = {
      12, 13, 14, 18, 19, 18, 19, 12, 13, 14, 18, 19, 18, 19, 13,
      29, 28, 23, 22, 21, 22, 21, 29, 28, 23, 22, 21, 22, 21, 28,
      31, 34, 39, 37, 32, 37, 32, 31, 34, 39, 37, 32, 37, 32, 34,
  };

  surface_->SetSize(gfx::Size(INT_MAX, INT_MAX));

  ReadPixelsEmulator emu(
      kWidth, kHeight, kBytesPerPixel, kSrcPixels, kSrcPixels, kPackAlignment);
  typedef ReadPixels::Result Result;
  Result* result = GetSharedMemoryAs<Result*>();
  uint32 result_shm_id = kSharedMemoryId;
  uint32 result_shm_offset = kSharedMemoryOffset;
  uint32 pixels_shm_id = kSharedMemoryId;
  uint32 pixels_shm_offset = kSharedMemoryOffset + sizeof(*result);
  void* dest = &result[1];
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_,
              ReadPixels(0, 0, kWidth, kHeight, GL_RGB, GL_UNSIGNED_BYTE, _))
      .WillOnce(Invoke(&emu, &ReadPixelsEmulator::ReadPixels));
  ReadPixels cmd;
  cmd.Init(0,
           0,
           kWidth,
           kHeight,
           GL_RGB,
           GL_UNSIGNED_BYTE,
           pixels_shm_id,
           pixels_shm_offset,
           result_shm_id,
           result_shm_offset,
           false);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  for (GLint yy = 0; yy < kHeight; ++yy) {
    EXPECT_TRUE(emu.CompareRowSegment(
        0, yy, kWidth, emu.ComputePackAlignmentAddress(0, yy, kWidth, dest)));
  }
}

TEST_P(GLES2DecoderRGBBackbufferTest, ReadPixelsNoAlphaBackbuffer) {
  const GLsizei kWidth = 3;
  const GLsizei kHeight = 3;
  const GLint kBytesPerPixel = 4;
  const GLint kPackAlignment = 4;
  static const uint8 kExpectedPixels[kWidth * kHeight * kBytesPerPixel] = {
      12, 13, 14, 255, 19, 18, 19, 255, 13, 14, 18, 255,
      29, 28, 23, 255, 21, 22, 21, 255, 28, 23, 22, 255,
      31, 34, 39, 255, 32, 37, 32, 255, 34, 39, 37, 255,
  };
  static const uint8 kSrcPixels[kWidth * kHeight * kBytesPerPixel] = {
      12, 13, 14, 18, 19, 18, 19, 12, 13, 14, 18, 19, 29, 28, 23, 22, 21, 22,
      21, 29, 28, 23, 22, 21, 31, 34, 39, 37, 32, 37, 32, 31, 34, 39, 37, 32,
  };

  surface_->SetSize(gfx::Size(INT_MAX, INT_MAX));

  ReadPixelsEmulator emu(kWidth,
                         kHeight,
                         kBytesPerPixel,
                         kSrcPixels,
                         kExpectedPixels,
                         kPackAlignment);
  typedef ReadPixels::Result Result;
  Result* result = GetSharedMemoryAs<Result*>();
  uint32 result_shm_id = kSharedMemoryId;
  uint32 result_shm_offset = kSharedMemoryOffset;
  uint32 pixels_shm_id = kSharedMemoryId;
  uint32 pixels_shm_offset = kSharedMemoryOffset + sizeof(*result);
  void* dest = &result[1];
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_,
              ReadPixels(0, 0, kWidth, kHeight, GL_RGBA, GL_UNSIGNED_BYTE, _))
      .WillOnce(Invoke(&emu, &ReadPixelsEmulator::ReadPixels));
  ReadPixels cmd;
  cmd.Init(0,
           0,
           kWidth,
           kHeight,
           GL_RGBA,
           GL_UNSIGNED_BYTE,
           pixels_shm_id,
           pixels_shm_offset,
           result_shm_id,
           result_shm_offset,
           false);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  for (GLint yy = 0; yy < kHeight; ++yy) {
    EXPECT_TRUE(emu.CompareRowSegment(
        0, yy, kWidth, emu.ComputePackAlignmentAddress(0, yy, kWidth, dest)));
  }
}

TEST_P(GLES2DecoderTest, ReadPixelsOutOfRange) {
  static GLint tests[][4] = {
      {
       -2, -1, 9, 5,
      },  // out of range on all sides
      {
       2, 1, 9, 5,
      },  // out of range on right, bottom
      {
       -7, -4, 9, 5,
      },  // out of range on left, top
      {
       0, -5, 9, 5,
      },  // completely off top
      {
       0, 3, 9, 5,
      },  // completely off bottom
      {
       -9, 0, 9, 5,
      },  // completely off left
      {
       5, 0, 9, 5,
      },  // completely off right
  };

  for (size_t tt = 0; tt < arraysize(tests); ++tt) {
    CheckReadPixelsOutOfRange(
        tests[tt][0], tests[tt][1], tests[tt][2], tests[tt][3], tt == 0);
  }
}

TEST_P(GLES2DecoderTest, ReadPixelsInvalidArgs) {
  typedef ReadPixels::Result Result;
  uint32 result_shm_id = kSharedMemoryId;
  uint32 result_shm_offset = kSharedMemoryOffset;
  uint32 pixels_shm_id = kSharedMemoryId;
  uint32 pixels_shm_offset = kSharedMemoryOffset + sizeof(Result);
  EXPECT_CALL(*gl_, ReadPixels(_, _, _, _, _, _, _)).Times(0);
  ReadPixels cmd;
  cmd.Init(0,
           0,
           -1,
           1,
           GL_RGB,
           GL_UNSIGNED_BYTE,
           pixels_shm_id,
           pixels_shm_offset,
           result_shm_id,
           result_shm_offset,
           false);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  cmd.Init(0,
           0,
           1,
           -1,
           GL_RGB,
           GL_UNSIGNED_BYTE,
           pixels_shm_id,
           pixels_shm_offset,
           result_shm_id,
           result_shm_offset,
           false);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  cmd.Init(0,
           0,
           1,
           1,
           GL_RGB,
           GL_INT,
           pixels_shm_id,
           pixels_shm_offset,
           result_shm_id,
           result_shm_offset,
           false);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());
  cmd.Init(0,
           0,
           1,
           1,
           GL_RGB,
           GL_UNSIGNED_BYTE,
           kInvalidSharedMemoryId,
           pixels_shm_offset,
           result_shm_id,
           result_shm_offset,
           false);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  cmd.Init(0,
           0,
           1,
           1,
           GL_RGB,
           GL_UNSIGNED_BYTE,
           pixels_shm_id,
           kInvalidSharedMemoryOffset,
           result_shm_id,
           result_shm_offset,
           false);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  cmd.Init(0,
           0,
           1,
           1,
           GL_RGB,
           GL_UNSIGNED_BYTE,
           pixels_shm_id,
           pixels_shm_offset,
           kInvalidSharedMemoryId,
           result_shm_offset,
           false);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  cmd.Init(0,
           0,
           1,
           1,
           GL_RGB,
           GL_UNSIGNED_BYTE,
           pixels_shm_id,
           pixels_shm_offset,
           result_shm_id,
           kInvalidSharedMemoryOffset,
           false);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderManualInitTest, ReadPixelsAsyncError) {
  InitState init;
  init.extensions = "GL_ARB_sync";
  init.gl_version = "opengl es 3.0";
  init.has_alpha = true;
  init.request_alpha = true;
  init.bind_generates_resource = true;
  InitDecoder(init);

  typedef ReadPixels::Result Result;

  const GLsizei kWidth = 4;
  const GLsizei kHeight = 4;
  uint32 result_shm_id = kSharedMemoryId;
  uint32 result_shm_offset = kSharedMemoryOffset;
  uint32 pixels_shm_id = kSharedMemoryId;
  uint32 pixels_shm_offset = kSharedMemoryOffset + sizeof(Result);

  EXPECT_CALL(*gl_, GetError())
      // first error check must pass to get to the test
      .WillOnce(Return(GL_NO_ERROR))
      // second check is after BufferData, simulate fail here
      .WillOnce(Return(GL_INVALID_OPERATION))
      // third error check is fall-through call to sync ReadPixels
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();

  EXPECT_CALL(*gl_,
              ReadPixels(0, 0, kWidth, kHeight, GL_RGB, GL_UNSIGNED_BYTE, _))
      .Times(1);
  EXPECT_CALL(*gl_, GenBuffersARB(1, _)).Times(1);
  EXPECT_CALL(*gl_, DeleteBuffersARB(1, _)).Times(1);
  EXPECT_CALL(*gl_, BindBuffer(GL_PIXEL_PACK_BUFFER_ARB, _)).Times(2);
  EXPECT_CALL(*gl_,
              BufferData(GL_PIXEL_PACK_BUFFER_ARB, _, NULL, GL_STREAM_READ))
      .Times(1);

  ReadPixels cmd;
  cmd.Init(0,
           0,
           kWidth,
           kHeight,
           GL_RGB,
           GL_UNSIGNED_BYTE,
           pixels_shm_id,
           pixels_shm_offset,
           result_shm_id,
           result_shm_offset,
           true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
}

// Check that if a renderbuffer is attached and GL returns
// GL_FRAMEBUFFER_COMPLETE that the buffer is cleared and state is restored.
TEST_P(GLES2DecoderTest, FramebufferRenderbufferClearColor) {
  DoBindFramebuffer(
      GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
  ClearColor color_cmd;
  ColorMask color_mask_cmd;
  Enable enable_cmd;
  FramebufferRenderbuffer cmd;
  color_cmd.Init(0.1f, 0.2f, 0.3f, 0.4f);
  color_mask_cmd.Init(0, 1, 0, 1);
  enable_cmd.Init(GL_SCISSOR_TEST);
  cmd.Init(GL_FRAMEBUFFER,
           GL_COLOR_ATTACHMENT0,
           GL_RENDERBUFFER,
           client_renderbuffer_id_);
  InSequence sequence;
  EXPECT_CALL(*gl_, ClearColor(0.1f, 0.2f, 0.3f, 0.4f))
      .Times(1)
      .RetiresOnSaturation();
  SetupExpectationsForEnableDisable(GL_SCISSOR_TEST, true);
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_,
              FramebufferRenderbufferEXT(GL_FRAMEBUFFER,
                                         GL_COLOR_ATTACHMENT0,
                                         GL_RENDERBUFFER,
                                         kServiceRenderbufferId))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_EQ(error::kNoError, ExecuteCmd(color_cmd));
  EXPECT_EQ(error::kNoError, ExecuteCmd(color_mask_cmd));
  EXPECT_EQ(error::kNoError, ExecuteCmd(enable_cmd));
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderTest, FramebufferRenderbufferClearDepth) {
  DoBindFramebuffer(
      GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
  ClearDepthf depth_cmd;
  DepthMask depth_mask_cmd;
  FramebufferRenderbuffer cmd;
  depth_cmd.Init(0.5f);
  depth_mask_cmd.Init(false);
  cmd.Init(GL_FRAMEBUFFER,
           GL_DEPTH_ATTACHMENT,
           GL_RENDERBUFFER,
           client_renderbuffer_id_);
  InSequence sequence;
  EXPECT_CALL(*gl_, ClearDepth(0.5f)).Times(1).RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_,
              FramebufferRenderbufferEXT(GL_FRAMEBUFFER,
                                         GL_DEPTH_ATTACHMENT,
                                         GL_RENDERBUFFER,
                                         kServiceRenderbufferId))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_EQ(error::kNoError, ExecuteCmd(depth_cmd));
  EXPECT_EQ(error::kNoError, ExecuteCmd(depth_mask_cmd));
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderTest, FramebufferRenderbufferClearStencil) {
  DoBindFramebuffer(
      GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
  ClearStencil stencil_cmd;
  StencilMaskSeparate stencil_mask_separate_cmd;
  FramebufferRenderbuffer cmd;
  stencil_cmd.Init(123);
  stencil_mask_separate_cmd.Init(GL_BACK, 0x1234u);
  cmd.Init(GL_FRAMEBUFFER,
           GL_STENCIL_ATTACHMENT,
           GL_RENDERBUFFER,
           client_renderbuffer_id_);
  InSequence sequence;
  EXPECT_CALL(*gl_, ClearStencil(123)).Times(1).RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_,
              FramebufferRenderbufferEXT(GL_FRAMEBUFFER,
                                         GL_STENCIL_ATTACHMENT,
                                         GL_RENDERBUFFER,
                                         kServiceRenderbufferId))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_EQ(error::kNoError, ExecuteCmd(stencil_cmd));
  EXPECT_EQ(error::kNoError, ExecuteCmd(stencil_mask_separate_cmd));
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
}

#if 0  // Turn this test on once we allow GL_DEPTH_STENCIL_ATTACHMENT
TEST_P(GLES2DecoderTest, FramebufferRenderbufferClearDepthStencil) {
  DoBindFramebuffer(GL_FRAMEBUFFER, client_framebuffer_id_,
                    kServiceFramebufferId);
  ClearDepthf depth_cmd;
  ClearStencil stencil_cmd;
  FramebufferRenderbuffer cmd;
  depth_cmd.Init(0.5f);
  stencil_cmd.Init(123);
  cmd.Init(
      GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER,
      client_renderbuffer_id_);
  InSequence sequence;
  EXPECT_CALL(*gl_, ClearDepth(0.5f))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, ClearStencil(123))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, FramebufferRenderbufferEXT(
      GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER,
      kServiceRenderbufferId))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_EQ(error::kNoError, ExecuteCmd(depth_cmd));
  EXPECT_EQ(error::kNoError, ExecuteCmd(stencil_cmd));
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
}
#endif

TEST_P(GLES2DecoderManualInitTest, ActualAlphaMatchesRequestedAlpha) {
  InitState init;
  init.has_alpha = true;
  init.request_alpha = true;
  init.bind_generates_resource = true;
  InitDecoder(init);

  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  typedef GetIntegerv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  EXPECT_CALL(*gl_, GetIntegerv(GL_ALPHA_BITS, _))
      .WillOnce(SetArgumentPointee<1>(8))
      .RetiresOnSaturation();
  result->size = 0;
  GetIntegerv cmd2;
  cmd2.Init(GL_ALPHA_BITS, shared_memory_id_, shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(decoder_->GetGLES2Util()->GLGetNumValuesReturned(GL_ALPHA_BITS),
            result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_EQ(8, result->GetData()[0]);
}

TEST_P(GLES2DecoderManualInitTest, ActualAlphaDoesNotMatchRequestedAlpha) {
  InitState init;
  init.has_alpha = true;
  init.bind_generates_resource = true;
  InitDecoder(init);

  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  typedef GetIntegerv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  EXPECT_CALL(*gl_, GetIntegerv(GL_ALPHA_BITS, _))
      .WillOnce(SetArgumentPointee<1>(8))
      .RetiresOnSaturation();
  result->size = 0;
  GetIntegerv cmd2;
  cmd2.Init(GL_ALPHA_BITS, shared_memory_id_, shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(decoder_->GetGLES2Util()->GLGetNumValuesReturned(GL_ALPHA_BITS),
            result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_EQ(0, result->GetData()[0]);
}

TEST_P(GLES2DecoderManualInitTest, ActualDepthMatchesRequestedDepth) {
  InitState init;
  init.has_depth = true;
  init.request_depth = true;
  init.bind_generates_resource = true;
  InitDecoder(init);

  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  typedef GetIntegerv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  EXPECT_CALL(*gl_, GetIntegerv(GL_DEPTH_BITS, _))
      .WillOnce(SetArgumentPointee<1>(24))
      .RetiresOnSaturation();
  result->size = 0;
  GetIntegerv cmd2;
  cmd2.Init(GL_DEPTH_BITS, shared_memory_id_, shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(decoder_->GetGLES2Util()->GLGetNumValuesReturned(GL_DEPTH_BITS),
            result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_EQ(24, result->GetData()[0]);
}

TEST_P(GLES2DecoderManualInitTest, ActualDepthDoesNotMatchRequestedDepth) {
  InitState init;
  init.has_depth = true;
  init.bind_generates_resource = true;
  InitDecoder(init);

  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  typedef GetIntegerv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  EXPECT_CALL(*gl_, GetIntegerv(GL_DEPTH_BITS, _))
      .WillOnce(SetArgumentPointee<1>(24))
      .RetiresOnSaturation();
  result->size = 0;
  GetIntegerv cmd2;
  cmd2.Init(GL_DEPTH_BITS, shared_memory_id_, shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(decoder_->GetGLES2Util()->GLGetNumValuesReturned(GL_DEPTH_BITS),
            result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_EQ(0, result->GetData()[0]);
}

TEST_P(GLES2DecoderManualInitTest, ActualStencilMatchesRequestedStencil) {
  InitState init;
  init.has_stencil = true;
  init.request_stencil = true;
  init.bind_generates_resource = true;
  InitDecoder(init);

  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  typedef GetIntegerv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  EXPECT_CALL(*gl_, GetIntegerv(GL_STENCIL_BITS, _))
      .WillOnce(SetArgumentPointee<1>(8))
      .RetiresOnSaturation();
  result->size = 0;
  GetIntegerv cmd2;
  cmd2.Init(GL_STENCIL_BITS, shared_memory_id_, shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(decoder_->GetGLES2Util()->GLGetNumValuesReturned(GL_STENCIL_BITS),
            result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_EQ(8, result->GetData()[0]);
}

TEST_P(GLES2DecoderManualInitTest, ActualStencilDoesNotMatchRequestedStencil) {
  InitState init;
  init.has_stencil = true;
  init.bind_generates_resource = true;
  InitDecoder(init);

  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  typedef GetIntegerv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  EXPECT_CALL(*gl_, GetIntegerv(GL_STENCIL_BITS, _))
      .WillOnce(SetArgumentPointee<1>(8))
      .RetiresOnSaturation();
  result->size = 0;
  GetIntegerv cmd2;
  cmd2.Init(GL_STENCIL_BITS, shared_memory_id_, shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(decoder_->GetGLES2Util()->GLGetNumValuesReturned(GL_STENCIL_BITS),
            result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_EQ(0, result->GetData()[0]);
}

TEST_P(GLES2DecoderManualInitTest, PackedDepthStencilReportsCorrectValues) {
  InitState init;
  init.extensions = "GL_OES_packed_depth_stencil";
  init.gl_version = "opengl es 2.0";
  init.has_depth = true;
  init.has_stencil = true;
  init.request_depth = true;
  init.request_stencil = true;
  init.bind_generates_resource = true;
  InitDecoder(init);

  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  typedef GetIntegerv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->size = 0;
  GetIntegerv cmd2;
  cmd2.Init(GL_STENCIL_BITS, shared_memory_id_, shared_memory_offset_);
  EXPECT_CALL(*gl_, GetIntegerv(GL_STENCIL_BITS, _))
      .WillOnce(SetArgumentPointee<1>(8))
      .RetiresOnSaturation();
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(decoder_->GetGLES2Util()->GLGetNumValuesReturned(GL_STENCIL_BITS),
            result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_EQ(8, result->GetData()[0]);
  result->size = 0;
  cmd2.Init(GL_DEPTH_BITS, shared_memory_id_, shared_memory_offset_);
  EXPECT_CALL(*gl_, GetIntegerv(GL_DEPTH_BITS, _))
      .WillOnce(SetArgumentPointee<1>(24))
      .RetiresOnSaturation();
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(decoder_->GetGLES2Util()->GLGetNumValuesReturned(GL_DEPTH_BITS),
            result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_EQ(24, result->GetData()[0]);
}

TEST_P(GLES2DecoderManualInitTest, PackedDepthStencilNoRequestedStencil) {
  InitState init;
  init.extensions = "GL_OES_packed_depth_stencil";
  init.gl_version = "opengl es 2.0";
  init.has_depth = true;
  init.has_stencil = true;
  init.request_depth = true;
  init.bind_generates_resource = true;
  InitDecoder(init);

  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  typedef GetIntegerv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->size = 0;
  GetIntegerv cmd2;
  cmd2.Init(GL_STENCIL_BITS, shared_memory_id_, shared_memory_offset_);
  EXPECT_CALL(*gl_, GetIntegerv(GL_STENCIL_BITS, _))
      .WillOnce(SetArgumentPointee<1>(8))
      .RetiresOnSaturation();
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(decoder_->GetGLES2Util()->GLGetNumValuesReturned(GL_STENCIL_BITS),
            result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_EQ(0, result->GetData()[0]);
  result->size = 0;
  cmd2.Init(GL_DEPTH_BITS, shared_memory_id_, shared_memory_offset_);
  EXPECT_CALL(*gl_, GetIntegerv(GL_DEPTH_BITS, _))
      .WillOnce(SetArgumentPointee<1>(24))
      .RetiresOnSaturation();
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(decoder_->GetGLES2Util()->GLGetNumValuesReturned(GL_DEPTH_BITS),
            result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_EQ(24, result->GetData()[0]);
}

TEST_P(GLES2DecoderManualInitTest, PackedDepthStencilRenderbufferDepth) {
  InitState init;
  init.extensions = "GL_OES_packed_depth_stencil";
  init.gl_version = "opengl es 2.0";
  init.bind_generates_resource = true;
  InitDecoder(init);
  DoBindRenderbuffer(
      GL_RENDERBUFFER, client_renderbuffer_id_, kServiceRenderbufferId);
  DoBindFramebuffer(
      GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);

  EnsureRenderbufferBound(false);
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))  // for RenderbufferStoage
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))  // for FramebufferRenderbuffer
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))  // for GetIntegerv
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))  // for GetIntegerv
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();

  EXPECT_CALL(
      *gl_,
      RenderbufferStorageEXT(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, 100, 50))
      .Times(1)
      .RetiresOnSaturation();
  RenderbufferStorage cmd;
  cmd.Init(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, 100, 50);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_CALL(*gl_,
              FramebufferRenderbufferEXT(GL_FRAMEBUFFER,
                                         GL_DEPTH_ATTACHMENT,
                                         GL_RENDERBUFFER,
                                         kServiceRenderbufferId))
      .Times(1)
      .RetiresOnSaturation();
  FramebufferRenderbuffer fbrb_cmd;
  fbrb_cmd.Init(GL_FRAMEBUFFER,
                GL_DEPTH_ATTACHMENT,
                GL_RENDERBUFFER,
                client_renderbuffer_id_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(fbrb_cmd));

  typedef GetIntegerv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->size = 0;
  GetIntegerv cmd2;
  cmd2.Init(GL_STENCIL_BITS, shared_memory_id_, shared_memory_offset_);
  EXPECT_CALL(*gl_, GetIntegerv(GL_STENCIL_BITS, _))
      .WillOnce(SetArgumentPointee<1>(8))
      .RetiresOnSaturation();
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(decoder_->GetGLES2Util()->GLGetNumValuesReturned(GL_STENCIL_BITS),
            result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_EQ(0, result->GetData()[0]);
  result->size = 0;
  cmd2.Init(GL_DEPTH_BITS, shared_memory_id_, shared_memory_offset_);
  EXPECT_CALL(*gl_, GetIntegerv(GL_DEPTH_BITS, _))
      .WillOnce(SetArgumentPointee<1>(24))
      .RetiresOnSaturation();
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(decoder_->GetGLES2Util()->GLGetNumValuesReturned(GL_DEPTH_BITS),
            result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_EQ(24, result->GetData()[0]);
}

TEST_P(GLES2DecoderManualInitTest, PackedDepthStencilRenderbufferStencil) {
  InitState init;
  init.extensions = "GL_OES_packed_depth_stencil";
  init.gl_version = "opengl es 2.0";
  init.bind_generates_resource = true;
  InitDecoder(init);
  DoBindRenderbuffer(
      GL_RENDERBUFFER, client_renderbuffer_id_, kServiceRenderbufferId);
  DoBindFramebuffer(
      GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);

  EnsureRenderbufferBound(false);
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))  // for RenderbufferStoage
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))  // for FramebufferRenderbuffer
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))  // for GetIntegerv
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))  // for GetIntegerv
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();

  EXPECT_CALL(
      *gl_,
      RenderbufferStorageEXT(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, 100, 50))
      .Times(1)
      .RetiresOnSaturation();
  RenderbufferStorage cmd;
  cmd.Init(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, 100, 50);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_CALL(*gl_,
              FramebufferRenderbufferEXT(GL_FRAMEBUFFER,
                                         GL_STENCIL_ATTACHMENT,
                                         GL_RENDERBUFFER,
                                         kServiceRenderbufferId))
      .Times(1)
      .RetiresOnSaturation();
  FramebufferRenderbuffer fbrb_cmd;
  fbrb_cmd.Init(GL_FRAMEBUFFER,
                GL_STENCIL_ATTACHMENT,
                GL_RENDERBUFFER,
                client_renderbuffer_id_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(fbrb_cmd));

  typedef GetIntegerv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->size = 0;
  GetIntegerv cmd2;
  cmd2.Init(GL_STENCIL_BITS, shared_memory_id_, shared_memory_offset_);
  EXPECT_CALL(*gl_, GetIntegerv(GL_STENCIL_BITS, _))
      .WillOnce(SetArgumentPointee<1>(8))
      .RetiresOnSaturation();
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(decoder_->GetGLES2Util()->GLGetNumValuesReturned(GL_STENCIL_BITS),
            result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_EQ(8, result->GetData()[0]);
  result->size = 0;
  cmd2.Init(GL_DEPTH_BITS, shared_memory_id_, shared_memory_offset_);
  EXPECT_CALL(*gl_, GetIntegerv(GL_DEPTH_BITS, _))
      .WillOnce(SetArgumentPointee<1>(24))
      .RetiresOnSaturation();
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(decoder_->GetGLES2Util()->GLGetNumValuesReturned(GL_DEPTH_BITS),
            result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_EQ(0, result->GetData()[0]);
}

TEST_P(GLES2DecoderTest, FramebufferRenderbufferGLError) {
  DoBindFramebuffer(
      GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_OUT_OF_MEMORY))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_,
              FramebufferRenderbufferEXT(GL_FRAMEBUFFER,
                                         GL_COLOR_ATTACHMENT0,
                                         GL_RENDERBUFFER,
                                         kServiceRenderbufferId))
      .Times(1)
      .RetiresOnSaturation();
  FramebufferRenderbuffer cmd;
  cmd.Init(GL_FRAMEBUFFER,
           GL_COLOR_ATTACHMENT0,
           GL_RENDERBUFFER,
           client_renderbuffer_id_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_OUT_OF_MEMORY, GetGLError());
}

TEST_P(GLES2DecoderTest, FramebufferTexture2DGLError) {
  const GLsizei kWidth = 5;
  const GLsizei kHeight = 3;
  const GLenum kFormat = GL_RGB;
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  DoTexImage2D(GL_TEXTURE_2D,
               0,
               kFormat,
               kWidth,
               kHeight,
               0,
               kFormat,
               GL_UNSIGNED_BYTE,
               0,
               0);
  DoBindFramebuffer(
      GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_OUT_OF_MEMORY))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_,
              FramebufferTexture2DEXT(GL_FRAMEBUFFER,
                                      GL_COLOR_ATTACHMENT0,
                                      GL_TEXTURE_2D,
                                      kServiceTextureId,
                                      0))
      .Times(1)
      .RetiresOnSaturation();
  FramebufferTexture2D fbtex_cmd;
  fbtex_cmd.Init(GL_FRAMEBUFFER,
                 GL_COLOR_ATTACHMENT0,
                 GL_TEXTURE_2D,
                 client_texture_id_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(fbtex_cmd));
  EXPECT_EQ(GL_OUT_OF_MEMORY, GetGLError());
}

TEST_P(GLES2DecoderTest, RenderbufferStorageGLError) {
  DoBindRenderbuffer(
      GL_RENDERBUFFER, client_renderbuffer_id_, kServiceRenderbufferId);
  EnsureRenderbufferBound(false);
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_OUT_OF_MEMORY))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, RenderbufferStorageEXT(GL_RENDERBUFFER, GL_RGBA, 100, 50))
      .Times(1)
      .RetiresOnSaturation();
  RenderbufferStorage cmd;
  cmd.Init(GL_RENDERBUFFER, GL_RGBA4, 100, 50);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_OUT_OF_MEMORY, GetGLError());
}

TEST_P(GLES2DecoderTest, RenderbufferStorageBadArgs) {
  DoBindRenderbuffer(
      GL_RENDERBUFFER, client_renderbuffer_id_, kServiceRenderbufferId);
  EXPECT_CALL(*gl_, RenderbufferStorageEXT(_, _, _, _))
      .Times(0)
      .RetiresOnSaturation();
  RenderbufferStorage cmd;
  cmd.Init(GL_RENDERBUFFER, GL_RGBA4, TestHelper::kMaxRenderbufferSize + 1, 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  cmd.Init(GL_RENDERBUFFER, GL_RGBA4, 1, TestHelper::kMaxRenderbufferSize + 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
}

TEST_P(GLES2DecoderManualInitTest,
       RenderbufferStorageMultisampleCHROMIUMGLError) {
  InitState init;
  init.extensions = "GL_EXT_framebuffer_multisample";
  init.bind_generates_resource = true;
  InitDecoder(init);
  DoBindRenderbuffer(
      GL_RENDERBUFFER, client_renderbuffer_id_, kServiceRenderbufferId);
  EnsureRenderbufferBound(false);
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_OUT_OF_MEMORY))
      .RetiresOnSaturation();
  EXPECT_CALL(
      *gl_,
      RenderbufferStorageMultisampleEXT(GL_RENDERBUFFER, 1, GL_RGBA, 100, 50))
      .Times(1)
      .RetiresOnSaturation();
  RenderbufferStorageMultisampleCHROMIUM cmd;
  cmd.Init(GL_RENDERBUFFER, 1, GL_RGBA4, 100, 50);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_OUT_OF_MEMORY, GetGLError());
}

TEST_P(GLES2DecoderManualInitTest,
       RenderbufferStorageMultisampleCHROMIUMBadArgs) {
  InitState init;
  init.extensions = "GL_EXT_framebuffer_multisample";
  init.bind_generates_resource = true;
  InitDecoder(init);
  DoBindRenderbuffer(
      GL_RENDERBUFFER, client_renderbuffer_id_, kServiceRenderbufferId);
  EXPECT_CALL(*gl_, RenderbufferStorageMultisampleEXT(_, _, _, _, _))
      .Times(0)
      .RetiresOnSaturation();
  RenderbufferStorageMultisampleCHROMIUM cmd;
  cmd.Init(GL_RENDERBUFFER,
           TestHelper::kMaxSamples + 1,
           GL_RGBA4,
           TestHelper::kMaxRenderbufferSize,
           1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  cmd.Init(GL_RENDERBUFFER,
           TestHelper::kMaxSamples,
           GL_RGBA4,
           TestHelper::kMaxRenderbufferSize + 1,
           1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  cmd.Init(GL_RENDERBUFFER,
           TestHelper::kMaxSamples,
           GL_RGBA4,
           1,
           TestHelper::kMaxRenderbufferSize + 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
}

TEST_P(GLES2DecoderManualInitTest, RenderbufferStorageMultisampleCHROMIUM) {
  InitState init;
  init.extensions = "GL_EXT_framebuffer_multisample";
  InitDecoder(init);
  DoBindRenderbuffer(
      GL_RENDERBUFFER, client_renderbuffer_id_, kServiceRenderbufferId);
  InSequence sequence;
  EnsureRenderbufferBound(false);
  DoRenderbufferStorageMultisampleCHROMIUM(GL_RENDERBUFFER,
                                           TestHelper::kMaxSamples,
                                           GL_RGBA4,
                                           GL_RGBA,
                                           TestHelper::kMaxRenderbufferSize,
                                           1);
}

TEST_P(GLES2DecoderManualInitTest,
       RenderbufferStorageMultisampleCHROMIUMRebindRenderbuffer) {
  InitState init;
  init.extensions = "GL_EXT_framebuffer_multisample";
  InitDecoder(init);
  DoBindRenderbuffer(
      GL_RENDERBUFFER, client_renderbuffer_id_, kServiceRenderbufferId);
  RestoreRenderbufferBindings();
  InSequence sequence;
  EnsureRenderbufferBound(true);
  DoRenderbufferStorageMultisampleCHROMIUM(GL_RENDERBUFFER,
                                           TestHelper::kMaxSamples,
                                           GL_RGBA4,
                                           GL_RGBA,
                                           TestHelper::kMaxRenderbufferSize,
                                           1);
}

TEST_P(GLES2DecoderManualInitTest,
       RenderbufferStorageMultisampleEXTNotSupported) {
  InitState init;
  init.extensions = "GL_EXT_framebuffer_multisample";
  init.bind_generates_resource = true;
  InitDecoder(init);
  DoBindRenderbuffer(
      GL_RENDERBUFFER, client_renderbuffer_id_, kServiceRenderbufferId);
  InSequence sequence;
  // GL_EXT_framebuffer_multisample uses RenderbufferStorageMultisampleCHROMIUM.
  RenderbufferStorageMultisampleEXT cmd;
  cmd.Init(GL_RENDERBUFFER,
           TestHelper::kMaxSamples,
           GL_RGBA4,
           TestHelper::kMaxRenderbufferSize,
           1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

class GLES2DecoderMultisampledRenderToTextureTest
    : public GLES2DecoderTestWithExtensionsOnGLES2 {
 public:
  void TestNotCompatibleWithRenderbufferStorageMultisampleCHROMIUM() {
    DoBindRenderbuffer(
        GL_RENDERBUFFER, client_renderbuffer_id_, kServiceRenderbufferId);
    RenderbufferStorageMultisampleCHROMIUM cmd;
    cmd.Init(GL_RENDERBUFFER,
             TestHelper::kMaxSamples,
             GL_RGBA4,
             TestHelper::kMaxRenderbufferSize,
             1);
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
    EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
  }

  void TestRenderbufferStorageMultisampleEXT(const char* extension,
                                             bool rb_rebind) {
    DoBindRenderbuffer(
        GL_RENDERBUFFER, client_renderbuffer_id_, kServiceRenderbufferId);
    InSequence sequence;
    if (rb_rebind) {
      RestoreRenderbufferBindings();
      EnsureRenderbufferBound(true);
    } else {
      EnsureRenderbufferBound(false);
    }

    EXPECT_CALL(*gl_, GetError())
        .WillOnce(Return(GL_NO_ERROR))
        .RetiresOnSaturation();
    if (strstr(extension, "GL_IMG_multisampled_render_to_texture")) {
      EXPECT_CALL(
          *gl_,
          RenderbufferStorageMultisampleIMG(GL_RENDERBUFFER,
                                            TestHelper::kMaxSamples,
                                            GL_RGBA,
                                            TestHelper::kMaxRenderbufferSize,
                                            1))
          .Times(1)
          .RetiresOnSaturation();
    } else {
      EXPECT_CALL(
          *gl_,
          RenderbufferStorageMultisampleEXT(GL_RENDERBUFFER,
                                            TestHelper::kMaxSamples,
                                            GL_RGBA,
                                            TestHelper::kMaxRenderbufferSize,
                                            1))
          .Times(1)
          .RetiresOnSaturation();
    }
    EXPECT_CALL(*gl_, GetError())
        .WillOnce(Return(GL_NO_ERROR))
        .RetiresOnSaturation();
    RenderbufferStorageMultisampleEXT cmd;
    cmd.Init(GL_RENDERBUFFER,
             TestHelper::kMaxSamples,
             GL_RGBA4,
             TestHelper::kMaxRenderbufferSize,
             1);
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
    EXPECT_EQ(GL_NO_ERROR, GetGLError());
  }
};

INSTANTIATE_TEST_CASE_P(Service,
                        GLES2DecoderMultisampledRenderToTextureTest,
                        ::testing::Bool());

TEST_P(GLES2DecoderMultisampledRenderToTextureTest,
       NotCompatibleWithRenderbufferStorageMultisampleCHROMIUM_EXT) {
  Init("GL_EXT_multisampled_render_to_texture");
  TestNotCompatibleWithRenderbufferStorageMultisampleCHROMIUM();
}

TEST_P(GLES2DecoderMultisampledRenderToTextureTest,
       NotCompatibleWithRenderbufferStorageMultisampleCHROMIUM_IMG) {
  Init("GL_IMG_multisampled_render_to_texture");
  TestNotCompatibleWithRenderbufferStorageMultisampleCHROMIUM();
}

TEST_P(GLES2DecoderMultisampledRenderToTextureTest,
       RenderbufferStorageMultisampleEXT_EXT) {
  Init("GL_EXT_multisampled_render_to_texture");
  TestRenderbufferStorageMultisampleEXT("GL_EXT_multisampled_render_to_texture",
                                        false);
}

TEST_P(GLES2DecoderMultisampledRenderToTextureTest,
       RenderbufferStorageMultisampleEXT_IMG) {
  Init("GL_IMG_multisampled_render_to_texture");
  TestRenderbufferStorageMultisampleEXT("GL_IMG_multisampled_render_to_texture",
                                        false);
}

TEST_P(GLES2DecoderMultisampledRenderToTextureTest,
       RenderbufferStorageMultisampleEXT_EXT_RebindRenderbuffer) {
  Init("GL_EXT_multisampled_render_to_texture");
  TestRenderbufferStorageMultisampleEXT("GL_EXT_multisampled_render_to_texture",
                                        true);
}

TEST_P(GLES2DecoderMultisampledRenderToTextureTest,
       RenderbufferStorageMultisampleEXT_IMG_RebindRenderbuffer) {
  Init("GL_IMG_multisampled_render_to_texture");
  TestRenderbufferStorageMultisampleEXT("GL_IMG_multisampled_render_to_texture",
                                        true);
}

TEST_P(GLES2DecoderTest, ReadPixelsGLError) {
  GLenum kFormat = GL_RGBA;
  GLint x = 0;
  GLint y = 0;
  GLsizei width = 2;
  GLsizei height = 4;
  typedef ReadPixels::Result Result;
  uint32 result_shm_id = kSharedMemoryId;
  uint32 result_shm_offset = kSharedMemoryOffset;
  uint32 pixels_shm_id = kSharedMemoryId;
  uint32 pixels_shm_offset = kSharedMemoryOffset + sizeof(Result);
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_OUT_OF_MEMORY))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_,
              ReadPixels(x, y, width, height, kFormat, GL_UNSIGNED_BYTE, _))
      .Times(1)
      .RetiresOnSaturation();
  ReadPixels cmd;
  cmd.Init(x,
           y,
           width,
           height,
           kFormat,
           GL_UNSIGNED_BYTE,
           pixels_shm_id,
           pixels_shm_offset,
           result_shm_id,
           result_shm_offset,
           false);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_OUT_OF_MEMORY, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, UnClearedAttachmentsGetClearedOnClear) {
  const GLuint kFBOClientTextureId = 4100;
  const GLuint kFBOServiceTextureId = 4101;

  // Register a texture id.
  EXPECT_CALL(*gl_, GenTextures(_, _))
      .WillOnce(SetArgumentPointee<1>(kFBOServiceTextureId))
      .RetiresOnSaturation();
  GenHelper<GenTexturesImmediate>(kFBOClientTextureId);

  // Setup "render to" texture.
  DoBindTexture(GL_TEXTURE_2D, kFBOClientTextureId, kFBOServiceTextureId);
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);
  DoBindFramebuffer(
      GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
  DoFramebufferTexture2D(GL_FRAMEBUFFER,
                         GL_COLOR_ATTACHMENT0,
                         GL_TEXTURE_2D,
                         kFBOClientTextureId,
                         kFBOServiceTextureId,
                         0,
                         GL_NO_ERROR);

  // Setup "render from" texture.
  SetupTexture();

  SetupExpectationsForFramebufferClearing(GL_FRAMEBUFFER,       // target
                                          GL_COLOR_BUFFER_BIT,  // clear bits
                                          0,
                                          0,
                                          0,
                                          0,       // color
                                          0,       // stencil
                                          1.0f,    // depth
                                          false);  // scissor test
  SetupExpectationsForApplyingDirtyState(false,    // Framebuffer is RGB
                                         false,    // Framebuffer has depth
                                         false,    // Framebuffer has stencil
                                         0x1111,   // color bits
                                         false,    // depth mask
                                         false,    // depth enabled
                                         0,        // front stencil mask
                                         0,        // back stencil mask
                                         false);   // stencil enabled

  EXPECT_CALL(*gl_, Clear(GL_COLOR_BUFFER_BIT)).Times(1).RetiresOnSaturation();

  Clear cmd;
  cmd.Init(GL_COLOR_BUFFER_BIT);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, UnClearedAttachmentsGetClearedOnReadPixels) {
  const GLuint kFBOClientTextureId = 4100;
  const GLuint kFBOServiceTextureId = 4101;

  // Register a texture id.
  EXPECT_CALL(*gl_, GenTextures(_, _))
      .WillOnce(SetArgumentPointee<1>(kFBOServiceTextureId))
      .RetiresOnSaturation();
  GenHelper<GenTexturesImmediate>(kFBOClientTextureId);

  // Setup "render to" texture.
  DoBindTexture(GL_TEXTURE_2D, kFBOClientTextureId, kFBOServiceTextureId);
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);
  DoBindFramebuffer(
      GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
  DoFramebufferTexture2D(GL_FRAMEBUFFER,
                         GL_COLOR_ATTACHMENT0,
                         GL_TEXTURE_2D,
                         kFBOClientTextureId,
                         kFBOServiceTextureId,
                         0,
                         GL_NO_ERROR);

  // Setup "render from" texture.
  SetupTexture();

  SetupExpectationsForFramebufferClearing(GL_FRAMEBUFFER,       // target
                                          GL_COLOR_BUFFER_BIT,  // clear bits
                                          0,
                                          0,
                                          0,
                                          0,       // color
                                          0,       // stencil
                                          1.0f,    // depth
                                          false);  // scissor test

  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, ReadPixels(0, 0, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, _))
      .Times(1)
      .RetiresOnSaturation();
  typedef ReadPixels::Result Result;
  uint32 result_shm_id = kSharedMemoryId;
  uint32 result_shm_offset = kSharedMemoryOffset;
  uint32 pixels_shm_id = kSharedMemoryId;
  uint32 pixels_shm_offset = kSharedMemoryOffset + sizeof(Result);
  ReadPixels cmd;
  cmd.Init(0,
           0,
           1,
           1,
           GL_RGBA,
           GL_UNSIGNED_BYTE,
           pixels_shm_id,
           pixels_shm_offset,
           result_shm_id,
           result_shm_offset,
           false);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderManualInitTest,
       UnClearedAttachmentsGetClearedOnReadPixelsAndDrawBufferGetsRestored) {
  InitState init;
  init.extensions = "GL_EXT_framebuffer_multisample";
  init.bind_generates_resource = true;
  InitDecoder(init);
  const GLuint kFBOClientTextureId = 4100;
  const GLuint kFBOServiceTextureId = 4101;

  // Register a texture id.
  EXPECT_CALL(*gl_, GenTextures(_, _))
      .WillOnce(SetArgumentPointee<1>(kFBOServiceTextureId))
      .RetiresOnSaturation();
  GenHelper<GenTexturesImmediate>(kFBOClientTextureId);

  // Setup "render from" texture.
  DoBindTexture(GL_TEXTURE_2D, kFBOClientTextureId, kFBOServiceTextureId);
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);
  DoBindFramebuffer(
      GL_READ_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
  DoFramebufferTexture2D(GL_READ_FRAMEBUFFER,
                         GL_COLOR_ATTACHMENT0,
                         GL_TEXTURE_2D,
                         kFBOClientTextureId,
                         kFBOServiceTextureId,
                         0,
                         GL_NO_ERROR);

  // Enable GL_SCISSOR_TEST to make sure we disable it in the clear,
  // then re-enable after.
  DoEnableDisable(GL_SCISSOR_TEST, true);

  SetupExpectationsForFramebufferClearingMulti(
      kServiceFramebufferId,  // read framebuffer service id
      0,                      // backbuffer service id
      GL_READ_FRAMEBUFFER,    // target
      GL_COLOR_BUFFER_BIT,    // clear bits
      0,
      0,
      0,
      0,      // color
      0,      // stencil
      1.0f,   // depth
      true);  // scissor test

  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, ReadPixels(0, 0, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, _))
      .Times(1)
      .RetiresOnSaturation();
  typedef ReadPixels::Result Result;
  uint32 result_shm_id = kSharedMemoryId;
  uint32 result_shm_offset = kSharedMemoryOffset;
  uint32 pixels_shm_id = kSharedMemoryId;
  uint32 pixels_shm_offset = kSharedMemoryOffset + sizeof(Result);
  ReadPixels cmd;
  cmd.Init(0,
           0,
           1,
           1,
           GL_RGBA,
           GL_UNSIGNED_BYTE,
           pixels_shm_id,
           pixels_shm_offset,
           result_shm_id,
           result_shm_offset,
           false);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, CopyTexImageWithInCompleteFBOFails) {
  GLenum target = GL_TEXTURE_2D;
  GLint level = 0;
  GLenum internal_format = GL_RGBA;
  GLsizei width = 2;
  GLsizei height = 4;
  SetupTexture();
  DoBindRenderbuffer(
      GL_RENDERBUFFER, client_renderbuffer_id_, kServiceRenderbufferId);
  DoBindFramebuffer(
      GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
  DoRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA4, GL_RGBA, 0, 0, GL_NO_ERROR);
  DoFramebufferRenderbuffer(GL_FRAMEBUFFER,
                            GL_COLOR_ATTACHMENT0,
                            GL_RENDERBUFFER,
                            client_renderbuffer_id_,
                            kServiceRenderbufferId,
                            GL_NO_ERROR);

  EXPECT_CALL(*gl_, CopyTexImage2D(_, _, _, _, _, _, _, _))
      .Times(0)
      .RetiresOnSaturation();
  CopyTexImage2D cmd;
  cmd.Init(target, level, internal_format, 0, 0, width, height);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_FRAMEBUFFER_OPERATION, GetGLError());
}

void GLES2DecoderWithShaderTest::CheckRenderbufferChangesMarkFBOAsNotComplete(
    bool bound_fbo) {
  FramebufferManager* framebuffer_manager = group().framebuffer_manager();
  SetupTexture();
  DoBindRenderbuffer(
      GL_RENDERBUFFER, client_renderbuffer_id_, kServiceRenderbufferId);
  DoBindFramebuffer(
      GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
  DoRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA4, GL_RGBA, 1, 1, GL_NO_ERROR);
  DoFramebufferRenderbuffer(GL_FRAMEBUFFER,
                            GL_COLOR_ATTACHMENT0,
                            GL_RENDERBUFFER,
                            client_renderbuffer_id_,
                            kServiceRenderbufferId,
                            GL_NO_ERROR);

  if (!bound_fbo) {
    DoBindFramebuffer(GL_FRAMEBUFFER, 0, 0);
  }

  Framebuffer* framebuffer =
      framebuffer_manager->GetFramebuffer(client_framebuffer_id_);
  ASSERT_TRUE(framebuffer != NULL);
  framebuffer_manager->MarkAsComplete(framebuffer);
  EXPECT_TRUE(framebuffer_manager->IsComplete(framebuffer));

  // Test that renderbufferStorage marks fbo as not complete.
  DoRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA4, GL_RGBA, 1, 1, GL_NO_ERROR);
  EXPECT_FALSE(framebuffer_manager->IsComplete(framebuffer));
  framebuffer_manager->MarkAsComplete(framebuffer);
  EXPECT_TRUE(framebuffer_manager->IsComplete(framebuffer));

  // Test deleting renderbuffer marks fbo as not complete.
  DoDeleteRenderbuffer(client_renderbuffer_id_, kServiceRenderbufferId);
  if (bound_fbo) {
    EXPECT_FALSE(framebuffer_manager->IsComplete(framebuffer));
  } else {
    EXPECT_TRUE(framebuffer_manager->IsComplete(framebuffer));
  }
  // Cleanup
  DoDeleteFramebuffer(client_framebuffer_id_,
                      kServiceFramebufferId,
                      bound_fbo,
                      GL_FRAMEBUFFER,
                      0,
                      bound_fbo,
                      GL_FRAMEBUFFER,
                      0);
}

TEST_P(GLES2DecoderWithShaderTest,
       RenderbufferChangesMarkFBOAsNotCompleteBoundFBO) {
  CheckRenderbufferChangesMarkFBOAsNotComplete(true);
}

TEST_P(GLES2DecoderWithShaderTest,
       RenderbufferChangesMarkFBOAsNotCompleteUnboundFBO) {
  CheckRenderbufferChangesMarkFBOAsNotComplete(false);
}

void GLES2DecoderWithShaderTest::CheckTextureChangesMarkFBOAsNotComplete(
    bool bound_fbo) {
  FramebufferManager* framebuffer_manager = group().framebuffer_manager();
  const GLuint kFBOClientTextureId = 4100;
  const GLuint kFBOServiceTextureId = 4101;

  // Register a texture id.
  EXPECT_CALL(*gl_, GenTextures(_, _))
      .WillOnce(SetArgumentPointee<1>(kFBOServiceTextureId))
      .RetiresOnSaturation();
  GenHelper<GenTexturesImmediate>(kFBOClientTextureId);

  SetupTexture();

  // Setup "render to" texture.
  DoBindTexture(GL_TEXTURE_2D, kFBOClientTextureId, kFBOServiceTextureId);
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);
  DoBindFramebuffer(
      GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
  DoFramebufferTexture2D(GL_FRAMEBUFFER,
                         GL_COLOR_ATTACHMENT0,
                         GL_TEXTURE_2D,
                         kFBOClientTextureId,
                         kFBOServiceTextureId,
                         0,
                         GL_NO_ERROR);

  DoBindRenderbuffer(
      GL_RENDERBUFFER, client_renderbuffer_id_, kServiceRenderbufferId);
  DoBindFramebuffer(
      GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
  DoRenderbufferStorage(GL_RENDERBUFFER,
                        GL_DEPTH_COMPONENT16,
                        GL_DEPTH_COMPONENT,
                        1,
                        1,
                        GL_NO_ERROR);
  DoFramebufferRenderbuffer(GL_FRAMEBUFFER,
                            GL_DEPTH_ATTACHMENT,
                            GL_RENDERBUFFER,
                            client_renderbuffer_id_,
                            kServiceRenderbufferId,
                            GL_NO_ERROR);

  if (!bound_fbo) {
    DoBindFramebuffer(GL_FRAMEBUFFER, 0, 0);
  }

  Framebuffer* framebuffer =
      framebuffer_manager->GetFramebuffer(client_framebuffer_id_);
  ASSERT_TRUE(framebuffer != NULL);
  framebuffer_manager->MarkAsComplete(framebuffer);
  EXPECT_TRUE(framebuffer_manager->IsComplete(framebuffer));

  // Test TexImage2D marks fbo as not complete.
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGB, 1, 1, 0, GL_RGB, GL_UNSIGNED_BYTE, 0, 0);
  EXPECT_FALSE(framebuffer_manager->IsComplete(framebuffer));
  framebuffer_manager->MarkAsComplete(framebuffer);
  EXPECT_TRUE(framebuffer_manager->IsComplete(framebuffer));

  // Test CopyImage2D marks fbo as not complete.
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, CopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 0, 0, 1, 1, 0))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  CopyTexImage2D cmd;
  cmd.Init(GL_TEXTURE_2D, 0, GL_RGB, 0, 0, 1, 1);
  // Unbind fbo and bind again after CopyTexImage2D tp avoid feedback loops.
  if (bound_fbo) {
    DoBindFramebuffer(GL_FRAMEBUFFER, 0, 0);
  }
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  if (bound_fbo) {
    DoBindFramebuffer(
        GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
  }
  EXPECT_FALSE(framebuffer_manager->IsComplete(framebuffer));

  // Test deleting texture marks fbo as not complete.
  framebuffer_manager->MarkAsComplete(framebuffer);
  EXPECT_TRUE(framebuffer_manager->IsComplete(framebuffer));
  DoDeleteTexture(kFBOClientTextureId, kFBOServiceTextureId);

  if (bound_fbo) {
    EXPECT_FALSE(framebuffer_manager->IsComplete(framebuffer));
  } else {
    EXPECT_TRUE(framebuffer_manager->IsComplete(framebuffer));
  }
  // Cleanup
  DoDeleteFramebuffer(client_framebuffer_id_,
                      kServiceFramebufferId,
                      bound_fbo,
                      GL_FRAMEBUFFER,
                      0,
                      bound_fbo,
                      GL_FRAMEBUFFER,
                      0);
}

TEST_P(GLES2DecoderWithShaderTest, TextureChangesMarkFBOAsNotCompleteBoundFBO) {
  CheckTextureChangesMarkFBOAsNotComplete(true);
}

TEST_P(GLES2DecoderWithShaderTest,
       TextureChangesMarkFBOAsNotCompleteUnboundFBO) {
  CheckTextureChangesMarkFBOAsNotComplete(false);
}

TEST_P(GLES2DecoderTest, CanChangeSurface) {
  scoped_refptr<GLSurfaceMock> other_surface(new GLSurfaceMock);
  EXPECT_CALL(*other_surface.get(), GetBackingFrameBufferObject())
      .WillOnce(Return(7));
  EXPECT_CALL(*gl_, BindFramebufferEXT(GL_FRAMEBUFFER_EXT, 7));

  decoder_->SetSurface(other_surface);
}

TEST_P(GLES2DecoderTest, DrawBuffersEXTImmediateSuccceeds) {
  const GLsizei count = 1;
  const GLenum bufs[] = {GL_COLOR_ATTACHMENT0};
  DrawBuffersEXTImmediate& cmd = *GetImmediateAs<DrawBuffersEXTImmediate>();
  cmd.Init(count, bufs);

  DoBindFramebuffer(
      GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
  EXPECT_CALL(*gl_, DrawBuffersARB(count, _)).Times(1).RetiresOnSaturation();
  EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(bufs)));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderTest, DrawBuffersEXTImmediateFails) {
  const GLsizei count = 1;
  const GLenum bufs[] = {GL_COLOR_ATTACHMENT1_EXT};
  DrawBuffersEXTImmediate& cmd = *GetImmediateAs<DrawBuffersEXTImmediate>();
  cmd.Init(count, bufs);

  DoBindFramebuffer(
      GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
  EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(bufs)));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderTest, DrawBuffersEXTImmediateBackbuffer) {
  const GLsizei count = 1;
  const GLenum bufs[] = {GL_BACK};
  DrawBuffersEXTImmediate& cmd = *GetImmediateAs<DrawBuffersEXTImmediate>();
  cmd.Init(count, bufs);

  DoBindFramebuffer(
      GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
  EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(bufs)));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());

  DoBindFramebuffer(GL_FRAMEBUFFER, 0, 0);  // unbind

  EXPECT_CALL(*gl_, DrawBuffersARB(count, _)).Times(1).RetiresOnSaturation();

  EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(bufs)));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderManualInitTest, InvalidateFramebufferBinding) {
  InitState init;
  init.gl_version = "opengl es 3.0";
  InitDecoder(init);

  // EXPECT_EQ can't be used to compare function pointers
  EXPECT_TRUE(
      gfx::MockGLInterface::GetGLProcAddress("glInvalidateFramebuffer") !=
      gfx::g_driver_gl.fn.glDiscardFramebufferEXTFn);
  EXPECT_TRUE(
      gfx::MockGLInterface::GetGLProcAddress("glInvalidateFramebuffer") !=
      gfx::MockGLInterface::GetGLProcAddress("glDiscardFramebufferEXT"));
}

TEST_P(GLES2DecoderManualInitTest, DiscardFramebufferEXT) {
  InitState init;
  init.extensions = "GL_EXT_discard_framebuffer";
  init.gl_version = "opengl es 2.0";
  InitDecoder(init);

  // EXPECT_EQ can't be used to compare function pointers
  EXPECT_TRUE(
      gfx::MockGLInterface::GetGLProcAddress("glDiscardFramebufferEXT") ==
      gfx::g_driver_gl.fn.glDiscardFramebufferEXTFn);

  const GLenum target = GL_FRAMEBUFFER;
  const GLsizei count = 1;
  const GLenum attachments[] = {GL_COLOR_ATTACHMENT0};

  SetupTexture();
  DoBindFramebuffer(
      GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
  DoFramebufferTexture2D(GL_FRAMEBUFFER,
                         GL_COLOR_ATTACHMENT0,
                         GL_TEXTURE_2D,
                         client_texture_id_,
                         kServiceTextureId,
                         0,
                         GL_NO_ERROR);
  FramebufferManager* framebuffer_manager = group().framebuffer_manager();
  Framebuffer* framebuffer =
      framebuffer_manager->GetFramebuffer(client_framebuffer_id_);
  EXPECT_TRUE(framebuffer->IsCleared());

  EXPECT_CALL(*gl_, DiscardFramebufferEXT(target, count, _))
      .Times(1)
      .RetiresOnSaturation();
  DiscardFramebufferEXTImmediate& cmd =
      *GetImmediateAs<DiscardFramebufferEXTImmediate>();
  cmd.Init(target, count, attachments);

  EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(attachments)));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_FALSE(framebuffer->IsCleared());
}

TEST_P(GLES2DecoderTest, DiscardFramebufferEXTUnsupported) {
  const GLenum target = GL_FRAMEBUFFER;
  const GLsizei count = 1;
  const GLenum attachments[] = {GL_COLOR_EXT};
  DiscardFramebufferEXTImmediate& cmd =
      *GetImmediateAs<DiscardFramebufferEXTImmediate>();
  cmd.Init(target, count, attachments);

  // Should not result into a call into GL.
  EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(attachments)));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderManualInitTest,
       DiscardedAttachmentsEXTMarksFramebufferIncomplete) {
  InitState init;
  init.extensions = "GL_EXT_discard_framebuffer";
  init.gl_version = "opengl es 2.0";
  init.has_alpha = true;
  init.bind_generates_resource = true;
  InitDecoder(init);

  const GLuint kFBOClientTextureId = 4100;
  const GLuint kFBOServiceTextureId = 4101;

  // Register a texture id.
  EXPECT_CALL(*gl_, GenTextures(_, _))
      .WillOnce(SetArgumentPointee<1>(kFBOServiceTextureId))
      .RetiresOnSaturation();
  GenHelper<GenTexturesImmediate>(kFBOClientTextureId);

  // Setup "render to" texture.
  DoBindTexture(GL_TEXTURE_2D, kFBOClientTextureId, kFBOServiceTextureId);
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);
  DoBindFramebuffer(
      GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
  DoFramebufferTexture2D(GL_FRAMEBUFFER,
                         GL_COLOR_ATTACHMENT0,
                         GL_TEXTURE_2D,
                         kFBOClientTextureId,
                         kFBOServiceTextureId,
                         0,
                         GL_NO_ERROR);

  // Setup "render from" texture.
  SetupTexture();

  SetupExpectationsForFramebufferClearing(GL_FRAMEBUFFER,       // target
                                          GL_COLOR_BUFFER_BIT,  // clear bits
                                          0,
                                          0,
                                          0,
                                          0,       // color
                                          0,       // stencil
                                          1.0f,    // depth
                                          false);  // scissor test
  SetupExpectationsForApplyingDirtyState(false,    // Framebuffer is RGB
                                         false,    // Framebuffer has depth
                                         false,    // Framebuffer has stencil
                                         0x1111,   // color bits
                                         false,    // depth mask
                                         false,    // depth enabled
                                         0,        // front stencil mask
                                         0,        // back stencil mask
                                         false);   // stencil enabled

  EXPECT_CALL(*gl_, Clear(GL_COLOR_BUFFER_BIT)).Times(1).RetiresOnSaturation();

  Clear clear_cmd;
  clear_cmd.Init(GL_COLOR_BUFFER_BIT);
  EXPECT_EQ(error::kNoError, ExecuteCmd(clear_cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  // Check that framebuffer is cleared and complete.
  FramebufferManager* framebuffer_manager = group().framebuffer_manager();
  Framebuffer* framebuffer =
      framebuffer_manager->GetFramebuffer(client_framebuffer_id_);
  EXPECT_TRUE(framebuffer->IsCleared());
  EXPECT_TRUE(framebuffer_manager->IsComplete(framebuffer));

  // Check that Discard GL_COLOR_ATTACHMENT0, sets the attachment as uncleared
  // and the framebuffer as incomplete.
  EXPECT_TRUE(
      gfx::MockGLInterface::GetGLProcAddress("glDiscardFramebufferEXT") ==
      gfx::g_driver_gl.fn.glDiscardFramebufferEXTFn);

  const GLenum target = GL_FRAMEBUFFER;
  const GLsizei count = 1;
  const GLenum attachments[] = {GL_COLOR_ATTACHMENT0};

  DiscardFramebufferEXTImmediate& discard_cmd =
      *GetImmediateAs<DiscardFramebufferEXTImmediate>();
  discard_cmd.Init(target, count, attachments);

  EXPECT_CALL(*gl_, DiscardFramebufferEXT(target, count, _))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_EQ(error::kNoError,
            ExecuteImmediateCmd(discard_cmd, sizeof(attachments)));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_FALSE(framebuffer->IsCleared());
  EXPECT_FALSE(framebuffer_manager->IsComplete(framebuffer));
}

TEST_P(GLES2DecoderManualInitTest, ReadFormatExtension) {
  InitState init;
  init.extensions = "GL_OES_read_format";
  init.bind_generates_resource = true;
  InitDecoder(init);

  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError()).Times(6).RetiresOnSaturation();

  typedef GetIntegerv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  GetIntegerv cmd;
  const GLuint kFBOClientTextureId = 4100;
  const GLuint kFBOServiceTextureId = 4101;

  // Register a texture id.
  EXPECT_CALL(*gl_, GenTextures(_, _))
      .WillOnce(SetArgumentPointee<1>(kFBOServiceTextureId))
      .RetiresOnSaturation();
  GenHelper<GenTexturesImmediate>(kFBOClientTextureId);

  // Setup "render to" texture.
  DoBindTexture(GL_TEXTURE_2D, kFBOClientTextureId, kFBOServiceTextureId);
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);
  DoBindFramebuffer(
      GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
  DoFramebufferTexture2D(GL_FRAMEBUFFER,
                         GL_COLOR_ATTACHMENT0,
                         GL_TEXTURE_2D,
                         kFBOClientTextureId,
                         kFBOServiceTextureId,
                         0,
                         GL_NO_ERROR);

  result->size = 0;
  EXPECT_CALL(*gl_, GetIntegerv(_, _)).Times(1).RetiresOnSaturation();
  cmd.Init(GL_IMPLEMENTATION_COLOR_READ_FORMAT,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(1, result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  result->size = 0;
  EXPECT_CALL(*gl_, GetIntegerv(_, _)).Times(1).RetiresOnSaturation();
  cmd.Init(GL_IMPLEMENTATION_COLOR_READ_TYPE,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(1, result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderManualInitTest, NoReadFormatExtension) {
  InitState init;
  init.bind_generates_resource = true;
  InitDecoder(init);

  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();

  typedef GetIntegerv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  GetIntegerv cmd;
  const GLuint kFBOClientTextureId = 4100;
  const GLuint kFBOServiceTextureId = 4101;

  // Register a texture id.
  EXPECT_CALL(*gl_, GenTextures(_, _))
      .WillOnce(SetArgumentPointee<1>(kFBOServiceTextureId))
      .RetiresOnSaturation();
  GenHelper<GenTexturesImmediate>(kFBOClientTextureId);

  // Setup "render to" texture.
  DoBindTexture(GL_TEXTURE_2D, kFBOClientTextureId, kFBOServiceTextureId);
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);
  DoBindFramebuffer(
      GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
  DoFramebufferTexture2D(GL_FRAMEBUFFER,
                         GL_COLOR_ATTACHMENT0,
                         GL_TEXTURE_2D,
                         kFBOClientTextureId,
                         kFBOServiceTextureId,
                         0,
                         GL_NO_ERROR);

  result->size = 0;
  EXPECT_CALL(*gl_, GetIntegerv(_, _)).Times(0).RetiresOnSaturation();
  cmd.Init(GL_IMPLEMENTATION_COLOR_READ_FORMAT,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(1, result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  result->size = 0;
  EXPECT_CALL(*gl_, GetIntegerv(_, _)).Times(0).RetiresOnSaturation();
  cmd.Init(GL_IMPLEMENTATION_COLOR_READ_TYPE,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(1, result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

// TODO(gman): PixelStorei

// TODO(gman): SwapBuffers

}  // namespace gles2
}  // namespace gpu
