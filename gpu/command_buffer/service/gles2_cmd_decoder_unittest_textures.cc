// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/gles2_cmd_decoder.h"

#include "base/command_line.h"
#include "base/strings/string_number_conversions.h"
#include "gpu/command_buffer/common/gles2_cmd_format.h"
#include "gpu/command_buffer/common/gles2_cmd_utils.h"
#include "gpu/command_buffer/common/id_allocator.h"
#include "gpu/command_buffer/service/async_pixel_transfer_delegate_mock.h"
#include "gpu/command_buffer/service/async_pixel_transfer_manager.h"
#include "gpu/command_buffer/service/async_pixel_transfer_manager_mock.h"
#include "gpu/command_buffer/service/cmd_buffer_engine.h"
#include "gpu/command_buffer/service/context_group.h"
#include "gpu/command_buffer/service/context_state.h"
#include "gpu/command_buffer/service/gl_surface_mock.h"
#include "gpu/command_buffer/service/gles2_cmd_decoder_unittest.h"
#include "gpu/command_buffer/service/image_manager.h"
#include "gpu/command_buffer/service/mailbox_manager.h"
#include "gpu/command_buffer/service/mocks.h"
#include "gpu/command_buffer/service/program_manager.h"
#include "gpu/command_buffer/service/test_helper.h"
#include "gpu/config/gpu_switches.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gl/gl_image_stub.h"
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

TEST_P(GLES2DecoderTest, GenerateMipmapWrongFormatsFails) {
  EXPECT_CALL(*gl_, GenerateMipmapEXT(_)).Times(0);
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA, 16, 17, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);
  GenerateMipmap cmd;
  cmd.Init(GL_TEXTURE_2D);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderTest, GenerateMipmapHandlesOutOfMemory) {
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  TextureManager* manager = group().texture_manager();
  TextureRef* texture_ref = manager->GetTexture(client_texture_id_);
  ASSERT_TRUE(texture_ref != NULL);
  Texture* texture = texture_ref->texture();
  GLint width = 0;
  GLint height = 0;
  EXPECT_FALSE(texture->GetLevelSize(GL_TEXTURE_2D, 2, &width, &height));
  DoTexImage2D(GL_TEXTURE_2D,
               0,
               GL_RGBA,
               16,
               16,
               0,
               GL_RGBA,
               GL_UNSIGNED_BYTE,
               kSharedMemoryId,
               kSharedMemoryOffset);
  EXPECT_CALL(*gl_, GenerateMipmapEXT(GL_TEXTURE_2D)).Times(1);
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_OUT_OF_MEMORY))
      .RetiresOnSaturation();
  GenerateMipmap cmd;
  cmd.Init(GL_TEXTURE_2D);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_OUT_OF_MEMORY, GetGLError());
  EXPECT_FALSE(texture->GetLevelSize(GL_TEXTURE_2D, 2, &width, &height));
}

TEST_P(GLES2DecoderTest, GenerateMipmapClearsUnclearedTexture) {
  EXPECT_CALL(*gl_, GenerateMipmapEXT(_)).Times(0);
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA, 2, 2, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);
  SetupClearTextureExpectations(kServiceTextureId,
                                kServiceTextureId,
                                GL_TEXTURE_2D,
                                GL_TEXTURE_2D,
                                0,
                                GL_RGBA,
                                GL_RGBA,
                                GL_UNSIGNED_BYTE,
                                2,
                                2);
  EXPECT_CALL(*gl_, GenerateMipmapEXT(GL_TEXTURE_2D));
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  GenerateMipmap cmd;
  cmd.Init(GL_TEXTURE_2D);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

// Same as GenerateMipmapClearsUnclearedTexture, but with workaround
// |set_texture_filters_before_generating_mipmap|.
TEST_P(GLES2DecoderManualInitTest, SetTextureFiltersBeforeGenerateMipmap) {
  base::CommandLine command_line(0, NULL);
  command_line.AppendSwitchASCII(
      switches::kGpuDriverBugWorkarounds,
      base::IntToString(gpu::SET_TEXTURE_FILTER_BEFORE_GENERATING_MIPMAP));
  InitState init;
  init.bind_generates_resource = true;
  InitDecoderWithCommandLine(init, &command_line);

  EXPECT_CALL(*gl_, GenerateMipmapEXT(_)).Times(0);
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA, 2, 2, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);
  SetupClearTextureExpectations(kServiceTextureId,
                                kServiceTextureId,
                                GL_TEXTURE_2D,
                                GL_TEXTURE_2D,
                                0,
                                GL_RGBA,
                                GL_RGBA,
                                GL_UNSIGNED_BYTE,
                                2,
                                2);
  EXPECT_CALL(
      *gl_,
      TexParameteri(
          GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GenerateMipmapEXT(GL_TEXTURE_2D));
  EXPECT_CALL(
      *gl_,
      TexParameteri(
          GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_LINEAR))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  GenerateMipmap cmd;
  cmd.Init(GL_TEXTURE_2D);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderTest, ActiveTextureValidArgs) {
  EXPECT_CALL(*gl_, ActiveTexture(GL_TEXTURE1));
  SpecializedSetup<ActiveTexture, 0>(true);
  ActiveTexture cmd;
  cmd.Init(GL_TEXTURE1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderTest, ActiveTextureInvalidArgs) {
  EXPECT_CALL(*gl_, ActiveTexture(_)).Times(0);
  SpecializedSetup<ActiveTexture, 0>(false);
  ActiveTexture cmd;
  cmd.Init(GL_TEXTURE0 - 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());
  cmd.Init(kNumTextureUnits);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());
}

TEST_P(GLES2DecoderTest, TexSubImage2DValidArgs) {
  const int kWidth = 16;
  const int kHeight = 8;
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  DoTexImage2D(GL_TEXTURE_2D,
               1,
               GL_RGBA,
               kWidth,
               kHeight,
               0,
               GL_RGBA,
               GL_UNSIGNED_BYTE,
               kSharedMemoryId,
               kSharedMemoryOffset);
  EXPECT_CALL(*gl_,
              TexSubImage2D(GL_TEXTURE_2D,
                            1,
                            1,
                            0,
                            kWidth - 1,
                            kHeight,
                            GL_RGBA,
                            GL_UNSIGNED_BYTE,
                            shared_memory_address_))
      .Times(1)
      .RetiresOnSaturation();
  TexSubImage2D cmd;
  cmd.Init(GL_TEXTURE_2D,
           1,
           1,
           0,
           kWidth - 1,
           kHeight,
           GL_RGBA,
           GL_UNSIGNED_BYTE,
           kSharedMemoryId,
           kSharedMemoryOffset,
           GL_FALSE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderTest, TexSubImage2DBadArgs) {
  const int kWidth = 16;
  const int kHeight = 8;
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  DoTexImage2D(GL_TEXTURE_2D,
               1,
               GL_RGBA,
               kWidth,
               kHeight,
               0,
               GL_RGBA,
               GL_UNSIGNED_BYTE,
               0,
               0);
  TexSubImage2D cmd;
  cmd.Init(GL_TEXTURE0,
           1,
           0,
           0,
           kWidth,
           kHeight,
           GL_RGBA,
           GL_UNSIGNED_BYTE,
           kSharedMemoryId,
           kSharedMemoryOffset,
           GL_FALSE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());
  cmd.Init(GL_TEXTURE_2D,
           1,
           0,
           0,
           kWidth,
           kHeight,
           GL_TRUE,
           GL_UNSIGNED_BYTE,
           kSharedMemoryId,
           kSharedMemoryOffset,
           GL_FALSE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());
  cmd.Init(GL_TEXTURE_2D,
           1,
           0,
           0,
           kWidth,
           kHeight,
           GL_RGBA,
           GL_UNSIGNED_INT,
           kSharedMemoryId,
           kSharedMemoryOffset,
           GL_FALSE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());
  cmd.Init(GL_TEXTURE_2D,
           1,
           -1,
           0,
           kWidth,
           kHeight,
           GL_RGBA,
           GL_UNSIGNED_BYTE,
           kSharedMemoryId,
           kSharedMemoryOffset,
           GL_FALSE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  cmd.Init(GL_TEXTURE_2D,
           1,
           1,
           0,
           kWidth,
           kHeight,
           GL_RGBA,
           GL_UNSIGNED_BYTE,
           kSharedMemoryId,
           kSharedMemoryOffset,
           GL_FALSE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  cmd.Init(GL_TEXTURE_2D,
           1,
           0,
           -1,
           kWidth,
           kHeight,
           GL_RGBA,
           GL_UNSIGNED_BYTE,
           kSharedMemoryId,
           kSharedMemoryOffset,
           GL_FALSE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  cmd.Init(GL_TEXTURE_2D,
           1,
           0,
           1,
           kWidth,
           kHeight,
           GL_RGBA,
           GL_UNSIGNED_BYTE,
           kSharedMemoryId,
           kSharedMemoryOffset,
           GL_FALSE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  cmd.Init(GL_TEXTURE_2D,
           1,
           0,
           0,
           kWidth + 1,
           kHeight,
           GL_RGBA,
           GL_UNSIGNED_BYTE,
           kSharedMemoryId,
           kSharedMemoryOffset,
           GL_FALSE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  cmd.Init(GL_TEXTURE_2D,
           1,
           0,
           0,
           kWidth,
           kHeight + 1,
           GL_RGBA,
           GL_UNSIGNED_BYTE,
           kSharedMemoryId,
           kSharedMemoryOffset,
           GL_FALSE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  cmd.Init(GL_TEXTURE_2D,
           1,
           0,
           0,
           kWidth,
           kHeight,
           GL_RGB,
           GL_UNSIGNED_BYTE,
           kSharedMemoryId,
           kSharedMemoryOffset,
           GL_FALSE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
  cmd.Init(GL_TEXTURE_2D,
           1,
           0,
           0,
           kWidth,
           kHeight,
           GL_RGBA,
           GL_UNSIGNED_SHORT_4_4_4_4,
           kSharedMemoryId,
           kSharedMemoryOffset,
           GL_FALSE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
  cmd.Init(GL_TEXTURE_2D,
           1,
           0,
           0,
           kWidth,
           kHeight,
           GL_RGBA,
           GL_UNSIGNED_BYTE,
           kInvalidSharedMemoryId,
           kSharedMemoryOffset,
           GL_FALSE);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  cmd.Init(GL_TEXTURE_2D,
           1,
           0,
           0,
           kWidth,
           kHeight,
           GL_RGBA,
           GL_UNSIGNED_BYTE,
           kSharedMemoryId,
           kInvalidSharedMemoryOffset,
           GL_FALSE);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderTest, CopyTexSubImage2DValidArgs) {
  const int kWidth = 16;
  const int kHeight = 8;
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  DoTexImage2D(GL_TEXTURE_2D,
               1,
               GL_RGBA,
               kWidth,
               kHeight,
               0,
               GL_RGBA,
               GL_UNSIGNED_BYTE,
               kSharedMemoryId,
               kSharedMemoryOffset);
  EXPECT_CALL(*gl_,
              CopyTexSubImage2D(GL_TEXTURE_2D, 1, 0, 0, 0, 0, kWidth, kHeight))
      .Times(1)
      .RetiresOnSaturation();
  CopyTexSubImage2D cmd;
  cmd.Init(GL_TEXTURE_2D, 1, 0, 0, 0, 0, kWidth, kHeight);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderTest, CopyTexSubImage2DBadArgs) {
  const int kWidth = 16;
  const int kHeight = 8;
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  DoTexImage2D(GL_TEXTURE_2D,
               1,
               GL_RGBA,
               kWidth,
               kHeight,
               0,
               GL_RGBA,
               GL_UNSIGNED_BYTE,
               0,
               0);
  CopyTexSubImage2D cmd;
  cmd.Init(GL_TEXTURE0, 1, 0, 0, 0, 0, kWidth, kHeight);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());
  cmd.Init(GL_TEXTURE_2D, 1, -1, 0, 0, 0, kWidth, kHeight);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  cmd.Init(GL_TEXTURE_2D, 1, 1, 0, 0, 0, kWidth, kHeight);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  cmd.Init(GL_TEXTURE_2D, 1, 0, -1, 0, 0, kWidth, kHeight);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  cmd.Init(GL_TEXTURE_2D, 1, 0, 1, 0, 0, kWidth, kHeight);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  cmd.Init(GL_TEXTURE_2D, 1, 0, 0, 0, 0, kWidth + 1, kHeight);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  cmd.Init(GL_TEXTURE_2D, 1, 0, 0, 0, 0, kWidth, kHeight + 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
}

TEST_P(GLES2DecoderTest, TexImage2DRedefinitionSucceeds) {
  const int kWidth = 16;
  const int kHeight = 8;
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  EXPECT_CALL(*gl_, GetError()).WillRepeatedly(Return(GL_NO_ERROR));
  for (int ii = 0; ii < 2; ++ii) {
    TexImage2D cmd;
    if (ii == 0) {
      EXPECT_CALL(*gl_,
                  TexImage2D(GL_TEXTURE_2D,
                             0,
                             GL_RGBA,
                             kWidth,
                             kHeight,
                             0,
                             GL_RGBA,
                             GL_UNSIGNED_BYTE,
                             _))
          .Times(1)
          .RetiresOnSaturation();
      cmd.Init(GL_TEXTURE_2D,
               0,
               GL_RGBA,
               kWidth,
               kHeight,
               GL_RGBA,
               GL_UNSIGNED_BYTE,
               kSharedMemoryId,
               kSharedMemoryOffset);
    } else {
      SetupClearTextureExpectations(kServiceTextureId,
                                    kServiceTextureId,
                                    GL_TEXTURE_2D,
                                    GL_TEXTURE_2D,
                                    0,
                                    GL_RGBA,
                                    GL_RGBA,
                                    GL_UNSIGNED_BYTE,
                                    kWidth,
                                    kHeight);
      cmd.Init(GL_TEXTURE_2D,
               0,
               GL_RGBA,
               kWidth,
               kHeight,
               GL_RGBA,
               GL_UNSIGNED_BYTE,
               0,
               0);
    }
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
    EXPECT_CALL(*gl_,
                TexSubImage2D(GL_TEXTURE_2D,
                              0,
                              0,
                              0,
                              kWidth,
                              kHeight - 1,
                              GL_RGBA,
                              GL_UNSIGNED_BYTE,
                              shared_memory_address_))
        .Times(1)
        .RetiresOnSaturation();
    // Consider this TexSubImage2D command part of the previous TexImage2D
    // (last GL_TRUE argument). It will be skipped if there are bugs in the
    // redefinition case.
    TexSubImage2D cmd2;
    cmd2.Init(GL_TEXTURE_2D,
              0,
              0,
              0,
              kWidth,
              kHeight - 1,
              GL_RGBA,
              GL_UNSIGNED_BYTE,
              kSharedMemoryId,
              kSharedMemoryOffset,
              GL_TRUE);
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  }
}

TEST_P(GLES2DecoderTest, TexImage2DGLError) {
  GLenum target = GL_TEXTURE_2D;
  GLint level = 0;
  GLenum internal_format = GL_RGBA;
  GLsizei width = 2;
  GLsizei height = 4;
  GLint border = 0;
  GLenum format = GL_RGBA;
  GLenum type = GL_UNSIGNED_BYTE;
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  TextureManager* manager = group().texture_manager();
  TextureRef* texture_ref = manager->GetTexture(client_texture_id_);
  ASSERT_TRUE(texture_ref != NULL);
  Texture* texture = texture_ref->texture();
  EXPECT_FALSE(texture->GetLevelSize(GL_TEXTURE_2D, level, &width, &height));
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_OUT_OF_MEMORY))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_,
              TexImage2D(target,
                         level,
                         internal_format,
                         width,
                         height,
                         border,
                         format,
                         type,
                         _))
      .Times(1)
      .RetiresOnSaturation();
  TexImage2D cmd;
  cmd.Init(target,
           level,
           internal_format,
           width,
           height,
           format,
           type,
           kSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_OUT_OF_MEMORY, GetGLError());
  EXPECT_FALSE(texture->GetLevelSize(GL_TEXTURE_2D, level, &width, &height));
}

TEST_P(GLES2DecoderTest, CopyTexImage2DGLError) {
  GLenum target = GL_TEXTURE_2D;
  GLint level = 0;
  GLenum internal_format = GL_RGBA;
  GLsizei width = 2;
  GLsizei height = 4;
  GLint border = 0;
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  TextureManager* manager = group().texture_manager();
  TextureRef* texture_ref = manager->GetTexture(client_texture_id_);
  ASSERT_TRUE(texture_ref != NULL);
  Texture* texture = texture_ref->texture();
  EXPECT_FALSE(texture->GetLevelSize(GL_TEXTURE_2D, level, &width, &height));
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_OUT_OF_MEMORY))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_,
              CopyTexImage2D(
                  target, level, internal_format, 0, 0, width, height, border))
      .Times(1)
      .RetiresOnSaturation();
  CopyTexImage2D cmd;
  cmd.Init(target, level, internal_format, 0, 0, width, height);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_OUT_OF_MEMORY, GetGLError());
  EXPECT_FALSE(texture->GetLevelSize(GL_TEXTURE_2D, level, &width, &height));
}

TEST_P(GLES2DecoderManualInitTest, CompressedTexImage2DBucketBadBucket) {
  InitState init;
  init.extensions = "GL_EXT_texture_compression_s3tc";
  init.bind_generates_resource = true;
  InitDecoder(init);

  const uint32 kBadBucketId = 123;
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  CompressedTexImage2DBucket cmd;
  cmd.Init(GL_TEXTURE_2D,
           0,
           GL_COMPRESSED_RGBA_S3TC_DXT5_EXT,
           4,
           4,
           kBadBucketId);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  CompressedTexSubImage2DBucket cmd2;
  cmd2.Init(GL_TEXTURE_2D,
            0,
            0,
            0,
            4,
            4,
            GL_COMPRESSED_RGBA_S3TC_DXT5_EXT,
            kBadBucketId);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

namespace {

struct S3TCTestData {
  GLenum format;
  size_t block_size;
};

}  // anonymous namespace.

TEST_P(GLES2DecoderManualInitTest, CompressedTexImage2DS3TC) {
  InitState init;
  init.extensions = "GL_EXT_texture_compression_s3tc";
  init.bind_generates_resource = true;
  InitDecoder(init);
  const uint32 kBucketId = 123;
  CommonDecoder::Bucket* bucket = decoder_->CreateBucket(kBucketId);
  ASSERT_TRUE(bucket != NULL);

  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);

  static const S3TCTestData test_data[] = {
      {
       GL_COMPRESSED_RGB_S3TC_DXT1_EXT, 8,
      },
      {
       GL_COMPRESSED_RGBA_S3TC_DXT1_EXT, 8,
      },
      {
       GL_COMPRESSED_RGBA_S3TC_DXT3_EXT, 16,
      },
      {
       GL_COMPRESSED_RGBA_S3TC_DXT5_EXT, 16,
      },
  };

  for (size_t ii = 0; ii < arraysize(test_data); ++ii) {
    const S3TCTestData& test = test_data[ii];
    CompressedTexImage2DBucket cmd;
    // test small width.
    DoCompressedTexImage2D(
        GL_TEXTURE_2D, 0, test.format, 2, 4, 0, test.block_size, kBucketId);
    EXPECT_EQ(GL_NO_ERROR, GetGLError());

    // test bad width.
    cmd.Init(GL_TEXTURE_2D, 0, test.format, 5, 4, kBucketId);
    bucket->SetSize(test.block_size * 2);
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
    EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());

    // test small height.
    DoCompressedTexImage2D(
        GL_TEXTURE_2D, 0, test.format, 4, 2, 0, test.block_size, kBucketId);
    EXPECT_EQ(GL_NO_ERROR, GetGLError());

    // test too bad height.
    cmd.Init(GL_TEXTURE_2D, 0, test.format, 4, 5, kBucketId);
    bucket->SetSize(test.block_size * 2);
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
    EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());

    // test small for level 0.
    DoCompressedTexImage2D(
        GL_TEXTURE_2D, 0, test.format, 1, 1, 0, test.block_size, kBucketId);
    EXPECT_EQ(GL_NO_ERROR, GetGLError());

    // test small for level 0.
    DoCompressedTexImage2D(
        GL_TEXTURE_2D, 0, test.format, 2, 2, 0, test.block_size, kBucketId);
    EXPECT_EQ(GL_NO_ERROR, GetGLError());

    // test size too large.
    cmd.Init(GL_TEXTURE_2D, 0, test.format, 4, 4, kBucketId);
    bucket->SetSize(test.block_size * 2);
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
    EXPECT_EQ(GL_INVALID_VALUE, GetGLError());

    // test size too small.
    cmd.Init(GL_TEXTURE_2D, 0, test.format, 4, 4, kBucketId);
    bucket->SetSize(test.block_size / 2);
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
    EXPECT_EQ(GL_INVALID_VALUE, GetGLError());

    // test with 3 mips.
    DoCompressedTexImage2D(
        GL_TEXTURE_2D, 0, test.format, 4, 4, 0, test.block_size, kBucketId);
    DoCompressedTexImage2D(
        GL_TEXTURE_2D, 1, test.format, 2, 2, 0, test.block_size, kBucketId);
    DoCompressedTexImage2D(
        GL_TEXTURE_2D, 2, test.format, 1, 1, 0, test.block_size, kBucketId);
    EXPECT_EQ(GL_NO_ERROR, GetGLError());

    // Test a 16x16
    DoCompressedTexImage2D(GL_TEXTURE_2D,
                           0,
                           test.format,
                           16,
                           16,
                           0,
                           test.block_size * 4 * 4,
                           kBucketId);
    EXPECT_EQ(GL_NO_ERROR, GetGLError());

    CompressedTexSubImage2DBucket sub_cmd;
    bucket->SetSize(test.block_size);
    // Test sub image bad xoffset
    sub_cmd.Init(GL_TEXTURE_2D, 0, 1, 0, 4, 4, test.format, kBucketId);
    EXPECT_EQ(error::kNoError, ExecuteCmd(sub_cmd));
    EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());

    // Test sub image bad yoffset
    sub_cmd.Init(GL_TEXTURE_2D, 0, 0, 2, 4, 4, test.format, kBucketId);
    EXPECT_EQ(error::kNoError, ExecuteCmd(sub_cmd));
    EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());

    // Test sub image bad width
    bucket->SetSize(test.block_size * 2);
    sub_cmd.Init(GL_TEXTURE_2D, 0, 0, 0, 5, 4, test.format, kBucketId);
    EXPECT_EQ(error::kNoError, ExecuteCmd(sub_cmd));
    EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());

    // Test sub image bad height
    sub_cmd.Init(GL_TEXTURE_2D, 0, 0, 0, 4, 5, test.format, kBucketId);
    EXPECT_EQ(error::kNoError, ExecuteCmd(sub_cmd));
    EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());

    // Test sub image bad size
    bucket->SetSize(test.block_size + 1);
    sub_cmd.Init(GL_TEXTURE_2D, 0, 0, 0, 4, 4, test.format, kBucketId);
    EXPECT_EQ(error::kNoError, ExecuteCmd(sub_cmd));
    EXPECT_EQ(GL_INVALID_VALUE, GetGLError());

    for (GLint yoffset = 0; yoffset <= 8; yoffset += 4) {
      for (GLint xoffset = 0; xoffset <= 8; xoffset += 4) {
        for (GLsizei height = 4; height <= 8; height += 4) {
          for (GLsizei width = 4; width <= 8; width += 4) {
            GLsizei size = test.block_size * (width / 4) * (height / 4);
            bucket->SetSize(size);
            EXPECT_CALL(*gl_,
                        CompressedTexSubImage2D(GL_TEXTURE_2D,
                                                0,
                                                xoffset,
                                                yoffset,
                                                width,
                                                height,
                                                test.format,
                                                size,
                                                _))
                .Times(1)
                .RetiresOnSaturation();
            sub_cmd.Init(GL_TEXTURE_2D,
                         0,
                         xoffset,
                         yoffset,
                         width,
                         height,
                         test.format,
                         kBucketId);
            EXPECT_EQ(error::kNoError, ExecuteCmd(sub_cmd));
            EXPECT_EQ(GL_NO_ERROR, GetGLError());
          }
        }
      }
    }
  }
}

TEST_P(GLES2DecoderManualInitTest, CompressedTexImage2DETC1) {
  InitState init;
  init.extensions = "GL_OES_compressed_ETC1_RGB8_texture";
  init.gl_version = "opengl es 2.0";
  init.bind_generates_resource = true;
  InitDecoder(init);
  const uint32 kBucketId = 123;
  CommonDecoder::Bucket* bucket = decoder_->CreateBucket(kBucketId);
  ASSERT_TRUE(bucket != NULL);

  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);

  const GLenum kFormat = GL_ETC1_RGB8_OES;
  const size_t kBlockSize = 8;

  CompressedTexImage2DBucket cmd;
  // test small width.
  DoCompressedTexImage2D(GL_TEXTURE_2D, 0, kFormat, 4, 8, 0, 16, kBucketId);
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  // test small height.
  DoCompressedTexImage2D(GL_TEXTURE_2D, 0, kFormat, 8, 4, 0, 16, kBucketId);
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  // test size too large.
  cmd.Init(GL_TEXTURE_2D, 0, kFormat, 4, 4, kBucketId);
  bucket->SetSize(kBlockSize * 2);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());

  // test size too small.
  cmd.Init(GL_TEXTURE_2D, 0, kFormat, 4, 4, kBucketId);
  bucket->SetSize(kBlockSize / 2);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());

  // Test a 16x16
  DoCompressedTexImage2D(
      GL_TEXTURE_2D, 0, kFormat, 16, 16, 0, kBlockSize * 16, kBucketId);
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  // Test CompressedTexSubImage not allowed
  CompressedTexSubImage2DBucket sub_cmd;
  bucket->SetSize(kBlockSize);
  sub_cmd.Init(GL_TEXTURE_2D, 0, 0, 0, 4, 4, kFormat, kBucketId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(sub_cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());

  // Test TexSubImage not allowed for ETC1 compressed texture
  TextureRef* texture_ref = GetTexture(client_texture_id_);
  ASSERT_TRUE(texture_ref != NULL);
  Texture* texture = texture_ref->texture();
  GLenum type, internal_format;
  EXPECT_TRUE(texture->GetLevelType(GL_TEXTURE_2D, 0, &type, &internal_format));
  EXPECT_EQ(kFormat, internal_format);
  TexSubImage2D texsub_cmd;
  texsub_cmd.Init(GL_TEXTURE_2D,
                  0,
                  0,
                  0,
                  4,
                  4,
                  GL_RGBA,
                  GL_UNSIGNED_BYTE,
                  kSharedMemoryId,
                  kSharedMemoryOffset,
                  GL_FALSE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(texsub_cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());

  // Test CopyTexSubImage not allowed for ETC1 compressed texture
  CopyTexSubImage2D copy_cmd;
  copy_cmd.Init(GL_TEXTURE_2D, 0, 0, 0, 0, 0, 4, 4);
  EXPECT_EQ(error::kNoError, ExecuteCmd(copy_cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderManualInitTest, EGLImageExternalBindTexture) {
  InitState init;
  init.extensions = "GL_OES_EGL_image_external";
  init.gl_version = "opengl es 2.0";
  init.bind_generates_resource = true;
  InitDecoder(init);
  EXPECT_CALL(*gl_, BindTexture(GL_TEXTURE_EXTERNAL_OES, kNewServiceId));
  EXPECT_CALL(*gl_, GenTextures(1, _))
      .WillOnce(SetArgumentPointee<1>(kNewServiceId));
  BindTexture cmd;
  cmd.Init(GL_TEXTURE_EXTERNAL_OES, kNewClientId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  TextureRef* texture_ref = GetTexture(kNewClientId);
  EXPECT_TRUE(texture_ref != NULL);
  EXPECT_TRUE(texture_ref->texture()->target() == GL_TEXTURE_EXTERNAL_OES);
}

TEST_P(GLES2DecoderManualInitTest, EGLImageExternalGetBinding) {
  InitState init;
  init.extensions = "GL_OES_EGL_image_external";
  init.gl_version = "opengl es 2.0";
  init.bind_generates_resource = true;
  InitDecoder(init);
  DoBindTexture(GL_TEXTURE_EXTERNAL_OES, client_texture_id_, kServiceTextureId);

  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  typedef GetIntegerv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  EXPECT_CALL(*gl_,
              GetIntegerv(GL_TEXTURE_BINDING_EXTERNAL_OES, result->GetData()))
      .Times(0);
  result->size = 0;
  GetIntegerv cmd;
  cmd.Init(GL_TEXTURE_BINDING_EXTERNAL_OES,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(decoder_->GetGLES2Util()->GLGetNumValuesReturned(
                GL_TEXTURE_BINDING_EXTERNAL_OES),
            result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_EQ(client_texture_id_, (uint32)result->GetData()[0]);
}

TEST_P(GLES2DecoderManualInitTest, EGLImageExternalTextureDefaults) {
  InitState init;
  init.extensions = "GL_OES_EGL_image_external";
  init.gl_version = "opengl es 2.0";
  init.bind_generates_resource = true;
  InitDecoder(init);
  DoBindTexture(GL_TEXTURE_EXTERNAL_OES, client_texture_id_, kServiceTextureId);

  TextureRef* texture_ref = GetTexture(client_texture_id_);
  EXPECT_TRUE(texture_ref != NULL);
  Texture* texture = texture_ref->texture();
  EXPECT_TRUE(texture->target() == GL_TEXTURE_EXTERNAL_OES);
  EXPECT_TRUE(texture->min_filter() == GL_LINEAR);
  EXPECT_TRUE(texture->wrap_s() == GL_CLAMP_TO_EDGE);
  EXPECT_TRUE(texture->wrap_t() == GL_CLAMP_TO_EDGE);
}

TEST_P(GLES2DecoderManualInitTest, EGLImageExternalTextureParam) {
  InitState init;
  init.extensions = "GL_OES_EGL_image_external";
  init.gl_version = "opengl es 2.0";
  init.bind_generates_resource = true;
  InitDecoder(init);
  DoBindTexture(GL_TEXTURE_EXTERNAL_OES, client_texture_id_, kServiceTextureId);

  EXPECT_CALL(*gl_,
              TexParameteri(
                  GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MIN_FILTER, GL_NEAREST));
  EXPECT_CALL(
      *gl_,
      TexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MIN_FILTER, GL_LINEAR));
  EXPECT_CALL(
      *gl_,
      TexParameteri(
          GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE));
  EXPECT_CALL(
      *gl_,
      TexParameteri(
          GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE));
  TexParameteri cmd;
  cmd.Init(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  cmd.Init(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  cmd.Init(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  cmd.Init(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  TextureRef* texture_ref = GetTexture(client_texture_id_);
  EXPECT_TRUE(texture_ref != NULL);
  Texture* texture = texture_ref->texture();
  EXPECT_TRUE(texture->target() == GL_TEXTURE_EXTERNAL_OES);
  EXPECT_TRUE(texture->min_filter() == GL_LINEAR);
  EXPECT_TRUE(texture->wrap_s() == GL_CLAMP_TO_EDGE);
  EXPECT_TRUE(texture->wrap_t() == GL_CLAMP_TO_EDGE);
}

TEST_P(GLES2DecoderManualInitTest, EGLImageExternalTextureParamInvalid) {
  InitState init;
  init.extensions = "GL_OES_EGL_image_external";
  init.gl_version = "opengl es 2.0";
  init.bind_generates_resource = true;
  InitDecoder(init);
  DoBindTexture(GL_TEXTURE_EXTERNAL_OES, client_texture_id_, kServiceTextureId);

  TexParameteri cmd;
  cmd.Init(GL_TEXTURE_EXTERNAL_OES,
           GL_TEXTURE_MIN_FILTER,
           GL_NEAREST_MIPMAP_NEAREST);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());

  cmd.Init(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_S, GL_REPEAT);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());

  cmd.Init(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_T, GL_REPEAT);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());

  TextureRef* texture_ref = GetTexture(client_texture_id_);
  EXPECT_TRUE(texture_ref != NULL);
  Texture* texture = texture_ref->texture();
  EXPECT_TRUE(texture->target() == GL_TEXTURE_EXTERNAL_OES);
  EXPECT_TRUE(texture->min_filter() == GL_LINEAR);
  EXPECT_TRUE(texture->wrap_s() == GL_CLAMP_TO_EDGE);
  EXPECT_TRUE(texture->wrap_t() == GL_CLAMP_TO_EDGE);
}

TEST_P(GLES2DecoderManualInitTest, EGLImageExternalTexImage2DError) {
  InitState init;
  init.extensions = "GL_OES_EGL_image_external";
  init.gl_version = "opengl es 2.0";
  init.bind_generates_resource = true;
  InitDecoder(init);

  GLenum target = GL_TEXTURE_EXTERNAL_OES;
  GLint level = 0;
  GLenum internal_format = GL_RGBA;
  GLsizei width = 2;
  GLsizei height = 4;
  GLenum format = GL_RGBA;
  GLenum type = GL_UNSIGNED_BYTE;
  DoBindTexture(GL_TEXTURE_EXTERNAL_OES, client_texture_id_, kServiceTextureId);
  ASSERT_TRUE(GetTexture(client_texture_id_) != NULL);
  TexImage2D cmd;
  cmd.Init(target,
           level,
           internal_format,
           width,
           height,
           format,
           type,
           kSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));

  // TexImage2D is not allowed with GL_TEXTURE_EXTERNAL_OES targets.
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());
}

TEST_P(GLES2DecoderManualInitTest, DefaultTextureZero) {
  InitState init;
  InitDecoder(init);

  BindTexture cmd1;
  cmd1.Init(GL_TEXTURE_2D, 0);
  EXPECT_CALL(*gl_, BindTexture(GL_TEXTURE_2D, 0));
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd1));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  BindTexture cmd2;
  cmd2.Init(GL_TEXTURE_CUBE_MAP, 0);
  EXPECT_CALL(*gl_, BindTexture(GL_TEXTURE_CUBE_MAP, 0));
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderManualInitTest, DefaultTextureBGR) {
  InitState init;
  init.bind_generates_resource = true;
  InitDecoder(init);

  BindTexture cmd1;
  cmd1.Init(GL_TEXTURE_2D, 0);
  EXPECT_CALL(
      *gl_, BindTexture(GL_TEXTURE_2D, TestHelper::kServiceDefaultTexture2dId));
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd1));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  BindTexture cmd2;
  cmd2.Init(GL_TEXTURE_CUBE_MAP, 0);
  EXPECT_CALL(*gl_,
              BindTexture(GL_TEXTURE_CUBE_MAP,
                          TestHelper::kServiceDefaultTextureCubemapId));
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

// Test that default texture 0 is immutable.
TEST_P(GLES2DecoderManualInitTest, NoDefaultTexParameterf) {
  InitState init;
  InitDecoder(init);

  {
    BindTexture cmd1;
    cmd1.Init(GL_TEXTURE_2D, 0);
    EXPECT_CALL(*gl_, BindTexture(GL_TEXTURE_2D, 0));
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd1));
    EXPECT_EQ(GL_NO_ERROR, GetGLError());

    TexParameterf cmd2;
    cmd2.Init(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
    EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  }

  {
    BindTexture cmd1;
    cmd1.Init(GL_TEXTURE_CUBE_MAP, 0);
    EXPECT_CALL(*gl_, BindTexture(GL_TEXTURE_CUBE_MAP, 0));
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd1));
    EXPECT_EQ(GL_NO_ERROR, GetGLError());

    TexParameterf cmd2;
    cmd2.Init(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
    EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  }
}

TEST_P(GLES2DecoderManualInitTest, NoDefaultTexParameteri) {
  InitState init;
  InitDecoder(init);

  {
    BindTexture cmd1;
    cmd1.Init(GL_TEXTURE_2D, 0);
    EXPECT_CALL(*gl_, BindTexture(GL_TEXTURE_2D, 0));
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd1));
    EXPECT_EQ(GL_NO_ERROR, GetGLError());

    TexParameteri cmd2;
    cmd2.Init(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
    EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  }

  {
    BindTexture cmd1;
    cmd1.Init(GL_TEXTURE_CUBE_MAP, 0);
    EXPECT_CALL(*gl_, BindTexture(GL_TEXTURE_CUBE_MAP, 0));
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd1));
    EXPECT_EQ(GL_NO_ERROR, GetGLError());

    TexParameteri cmd2;
    cmd2.Init(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
    EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  }
}

TEST_P(GLES2DecoderManualInitTest, NoDefaultTexParameterfv) {
  InitState init;
  InitDecoder(init);

  {
    BindTexture cmd1;
    cmd1.Init(GL_TEXTURE_2D, 0);
    EXPECT_CALL(*gl_, BindTexture(GL_TEXTURE_2D, 0));
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd1));
    EXPECT_EQ(GL_NO_ERROR, GetGLError());

    GLfloat data = GL_NEAREST;
    TexParameterfvImmediate& cmd2 =
      *GetImmediateAs<TexParameterfvImmediate>();
    cmd2.Init(GL_TEXTURE_2D,
              GL_TEXTURE_MAG_FILTER,
              &data);
    EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd2, sizeof(data)));
    EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  }

  {
    BindTexture cmd1;
    cmd1.Init(GL_TEXTURE_CUBE_MAP, 0);
    EXPECT_CALL(*gl_, BindTexture(GL_TEXTURE_CUBE_MAP, 0));
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd1));
    EXPECT_EQ(GL_NO_ERROR, GetGLError());

    GLfloat data = GL_NEAREST;
    TexParameterfvImmediate& cmd2 =
      *GetImmediateAs<TexParameterfvImmediate>();
    cmd2.Init(GL_TEXTURE_CUBE_MAP,
              GL_TEXTURE_MAG_FILTER,
              &data);
    EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd2, sizeof(data)));
    EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  }
}

TEST_P(GLES2DecoderManualInitTest, NoDefaultTexParameteriv) {
  InitState init;
  InitDecoder(init);

  {
    BindTexture cmd1;
    cmd1.Init(GL_TEXTURE_2D, 0);
    EXPECT_CALL(*gl_, BindTexture(GL_TEXTURE_2D, 0));
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd1));
    EXPECT_EQ(GL_NO_ERROR, GetGLError());

    GLfloat data = GL_NEAREST;
    TexParameterfvImmediate& cmd2 =
      *GetImmediateAs<TexParameterfvImmediate>();
    cmd2.Init(GL_TEXTURE_2D,
              GL_TEXTURE_MAG_FILTER,
              &data);
    EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd2, sizeof(data)));
    EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  }

  {
    BindTexture cmd1;
    cmd1.Init(GL_TEXTURE_CUBE_MAP, 0);
    EXPECT_CALL(*gl_, BindTexture(GL_TEXTURE_CUBE_MAP, 0));
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd1));
    EXPECT_EQ(GL_NO_ERROR, GetGLError());

    GLfloat data = GL_NEAREST;
    TexParameterfvImmediate& cmd2 =
      *GetImmediateAs<TexParameterfvImmediate>();
    cmd2.Init(GL_TEXTURE_CUBE_MAP,
              GL_TEXTURE_MAG_FILTER,
              &data);
    EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd2, sizeof(data)));
    EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  }
}

TEST_P(GLES2DecoderManualInitTest, NoDefaultTexImage2D) {
  InitState init;
  InitDecoder(init);

  BindTexture cmd1;
  cmd1.Init(GL_TEXTURE_2D, 0);
  EXPECT_CALL(*gl_, BindTexture(GL_TEXTURE_2D, 0));
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd1));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  TexImage2D cmd2;
  cmd2.Init(GL_TEXTURE_2D,
            0,
            GL_RGBA,
            2,
            2,
            GL_RGBA,
            GL_UNSIGNED_BYTE,
            kSharedMemoryId,
            kSharedMemoryOffset);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderManualInitTest, NoDefaultTexSubImage2D) {
  InitState init;
  InitDecoder(init);

  BindTexture cmd1;
  cmd1.Init(GL_TEXTURE_2D, 0);
  EXPECT_CALL(*gl_, BindTexture(GL_TEXTURE_2D, 0));
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd1));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  TexSubImage2D cmd2;
  cmd2.Init(GL_TEXTURE_2D,
            0,
            1,
            1,
            1,
            1,
            GL_RGBA,
            GL_UNSIGNED_BYTE,
            kSharedMemoryId,
            kSharedMemoryOffset,
            GL_FALSE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderManualInitTest, ARBTextureRectangleBindTexture) {
  InitState init;
  init.extensions = "GL_ARB_texture_rectangle";
  init.bind_generates_resource = true;
  InitDecoder(init);
  EXPECT_CALL(*gl_, BindTexture(GL_TEXTURE_RECTANGLE_ARB, kNewServiceId));
  EXPECT_CALL(*gl_, GenTextures(1, _))
      .WillOnce(SetArgumentPointee<1>(kNewServiceId));
  BindTexture cmd;
  cmd.Init(GL_TEXTURE_RECTANGLE_ARB, kNewClientId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  Texture* texture = GetTexture(kNewClientId)->texture();
  EXPECT_TRUE(texture != NULL);
  EXPECT_TRUE(texture->target() == GL_TEXTURE_RECTANGLE_ARB);
}

TEST_P(GLES2DecoderManualInitTest, ARBTextureRectangleGetBinding) {
  InitState init;
  init.extensions = "GL_ARB_texture_rectangle";
  init.bind_generates_resource = true;
  InitDecoder(init);
  DoBindTexture(
      GL_TEXTURE_RECTANGLE_ARB, client_texture_id_, kServiceTextureId);

  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  typedef GetIntegerv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  EXPECT_CALL(*gl_,
              GetIntegerv(GL_TEXTURE_BINDING_RECTANGLE_ARB, result->GetData()))
      .Times(0);
  result->size = 0;
  GetIntegerv cmd;
  cmd.Init(GL_TEXTURE_BINDING_RECTANGLE_ARB,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(decoder_->GetGLES2Util()->GLGetNumValuesReturned(
                GL_TEXTURE_BINDING_RECTANGLE_ARB),
            result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_EQ(client_texture_id_, (uint32)result->GetData()[0]);
}

TEST_P(GLES2DecoderManualInitTest, ARBTextureRectangleTextureDefaults) {
  InitState init;
  init.extensions = "GL_ARB_texture_rectangle";
  init.bind_generates_resource = true;
  InitDecoder(init);
  DoBindTexture(
      GL_TEXTURE_RECTANGLE_ARB, client_texture_id_, kServiceTextureId);

  Texture* texture = GetTexture(client_texture_id_)->texture();
  EXPECT_TRUE(texture != NULL);
  EXPECT_TRUE(texture->target() == GL_TEXTURE_RECTANGLE_ARB);
  EXPECT_TRUE(texture->min_filter() == GL_LINEAR);
  EXPECT_TRUE(texture->wrap_s() == GL_CLAMP_TO_EDGE);
  EXPECT_TRUE(texture->wrap_t() == GL_CLAMP_TO_EDGE);
}

TEST_P(GLES2DecoderManualInitTest, ARBTextureRectangleTextureParam) {
  InitState init;
  init.extensions = "GL_ARB_texture_rectangle";
  init.bind_generates_resource = true;
  InitDecoder(init);

  DoBindTexture(
      GL_TEXTURE_RECTANGLE_ARB, client_texture_id_, kServiceTextureId);

  EXPECT_CALL(*gl_,
              TexParameteri(
                  GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_NEAREST));
  EXPECT_CALL(*gl_,
              TexParameteri(
                  GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR));
  EXPECT_CALL(
      *gl_,
      TexParameteri(
          GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE));
  EXPECT_CALL(
      *gl_,
      TexParameteri(
          GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE));
  TexParameteri cmd;
  cmd.Init(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  cmd.Init(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  cmd.Init(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  cmd.Init(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  Texture* texture = GetTexture(client_texture_id_)->texture();
  EXPECT_TRUE(texture != NULL);
  EXPECT_TRUE(texture->target() == GL_TEXTURE_RECTANGLE_ARB);
  EXPECT_TRUE(texture->min_filter() == GL_LINEAR);
  EXPECT_TRUE(texture->wrap_s() == GL_CLAMP_TO_EDGE);
  EXPECT_TRUE(texture->wrap_t() == GL_CLAMP_TO_EDGE);
}

TEST_P(GLES2DecoderManualInitTest, ARBTextureRectangleTextureParamInvalid) {
  InitState init;
  init.extensions = "GL_ARB_texture_rectangle";
  init.bind_generates_resource = true;
  InitDecoder(init);

  DoBindTexture(
      GL_TEXTURE_RECTANGLE_ARB, client_texture_id_, kServiceTextureId);

  TexParameteri cmd;
  cmd.Init(GL_TEXTURE_RECTANGLE_ARB,
           GL_TEXTURE_MIN_FILTER,
           GL_NEAREST_MIPMAP_NEAREST);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());

  cmd.Init(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_REPEAT);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());

  cmd.Init(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_REPEAT);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());

  Texture* texture = GetTexture(client_texture_id_)->texture();
  EXPECT_TRUE(texture != NULL);
  EXPECT_TRUE(texture->target() == GL_TEXTURE_RECTANGLE_ARB);
  EXPECT_TRUE(texture->min_filter() == GL_LINEAR);
  EXPECT_TRUE(texture->wrap_s() == GL_CLAMP_TO_EDGE);
  EXPECT_TRUE(texture->wrap_t() == GL_CLAMP_TO_EDGE);
}

TEST_P(GLES2DecoderManualInitTest, ARBTextureRectangleTexImage2DError) {
  InitState init;
  init.extensions = "GL_ARB_texture_rectangle";
  init.bind_generates_resource = true;
  InitDecoder(init);

  GLenum target = GL_TEXTURE_RECTANGLE_ARB;
  GLint level = 0;
  GLenum internal_format = GL_RGBA;
  GLsizei width = 2;
  GLsizei height = 4;
  GLenum format = GL_RGBA;
  GLenum type = GL_UNSIGNED_BYTE;
  DoBindTexture(
      GL_TEXTURE_RECTANGLE_ARB, client_texture_id_, kServiceTextureId);
  ASSERT_TRUE(GetTexture(client_texture_id_) != NULL);
  TexImage2D cmd;
  cmd.Init(target,
           level,
           internal_format,
           width,
           height,
           format,
           type,
           kSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));

  // TexImage2D is not allowed with GL_TEXTURE_RECTANGLE_ARB targets.
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());
}

TEST_P(GLES2DecoderManualInitTest, TexSubImage2DClearsAfterTexImage2DNULL) {
  InitState init;
  init.gl_version = "opengl es 2.0";
  init.has_alpha = true;
  init.has_depth = true;
  init.request_alpha = true;
  init.request_depth = true;
  InitDecoder(init);

  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA, 2, 2, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);
  SetupClearTextureExpectations(kServiceTextureId,
                                kServiceTextureId,
                                GL_TEXTURE_2D,
                                GL_TEXTURE_2D,
                                0,
                                GL_RGBA,
                                GL_RGBA,
                                GL_UNSIGNED_BYTE,
                                2,
                                2);
  EXPECT_CALL(*gl_,
              TexSubImage2D(GL_TEXTURE_2D,
                            0,
                            1,
                            1,
                            1,
                            1,
                            GL_RGBA,
                            GL_UNSIGNED_BYTE,
                            shared_memory_address_))
      .Times(1)
      .RetiresOnSaturation();
  TexSubImage2D cmd;
  cmd.Init(GL_TEXTURE_2D,
           0,
           1,
           1,
           1,
           1,
           GL_RGBA,
           GL_UNSIGNED_BYTE,
           kSharedMemoryId,
           kSharedMemoryOffset,
           GL_FALSE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  // Test if we call it again it does not clear.
  EXPECT_CALL(*gl_,
              TexSubImage2D(GL_TEXTURE_2D,
                            0,
                            1,
                            1,
                            1,
                            1,
                            GL_RGBA,
                            GL_UNSIGNED_BYTE,
                            shared_memory_address_))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderTest, TexSubImage2DDoesNotClearAfterTexImage2DNULLThenData) {
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA, 2, 2, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);
  DoTexImage2D(GL_TEXTURE_2D,
               0,
               GL_RGBA,
               2,
               2,
               0,
               GL_RGBA,
               GL_UNSIGNED_BYTE,
               kSharedMemoryId,
               kSharedMemoryOffset);
  EXPECT_CALL(*gl_,
              TexSubImage2D(GL_TEXTURE_2D,
                            0,
                            1,
                            1,
                            1,
                            1,
                            GL_RGBA,
                            GL_UNSIGNED_BYTE,
                            shared_memory_address_))
      .Times(1)
      .RetiresOnSaturation();
  TexSubImage2D cmd;
  cmd.Init(GL_TEXTURE_2D,
           0,
           1,
           1,
           1,
           1,
           GL_RGBA,
           GL_UNSIGNED_BYTE,
           kSharedMemoryId,
           kSharedMemoryOffset,
           GL_FALSE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  // Test if we call it again it does not clear.
  EXPECT_CALL(*gl_,
              TexSubImage2D(GL_TEXTURE_2D,
                            0,
                            1,
                            1,
                            1,
                            1,
                            GL_RGBA,
                            GL_UNSIGNED_BYTE,
                            shared_memory_address_))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(
    GLES2DecoderManualInitTest,
    TexSubImage2DDoesNotClearAfterTexImage2DNULLThenDataWithTexImage2DIsFaster) {
  base::CommandLine command_line(0, NULL);
  command_line.AppendSwitchASCII(
      switches::kGpuDriverBugWorkarounds,
      base::IntToString(gpu::TEXSUBIMAGE2D_FASTER_THAN_TEXIMAGE2D));
  InitState init;
  init.bind_generates_resource = true;
  InitDecoderWithCommandLine(init, &command_line);
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA, 2, 2, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);

  {
    // Uses texSubimage internally because the above workaround is active and
    // the update is for the full size of the texture.
    EXPECT_CALL(*gl_,
                TexSubImage2D(
                    GL_TEXTURE_2D, 0, 0, 0, 2, 2, GL_RGBA, GL_UNSIGNED_BYTE, _))
        .Times(1)
        .RetiresOnSaturation();
    cmds::TexImage2D cmd;
    cmd.Init(GL_TEXTURE_2D,
             0,
             GL_RGBA,
             2,
             2,
             GL_RGBA,
             GL_UNSIGNED_BYTE,
             kSharedMemoryId,
             kSharedMemoryOffset);
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  }

  EXPECT_CALL(*gl_,
              TexSubImage2D(GL_TEXTURE_2D,
                            0,
                            1,
                            1,
                            1,
                            1,
                            GL_RGBA,
                            GL_UNSIGNED_BYTE,
                            shared_memory_address_))
      .Times(1)
      .RetiresOnSaturation();
  TexSubImage2D cmd;
  cmd.Init(GL_TEXTURE_2D,
           0,
           1,
           1,
           1,
           1,
           GL_RGBA,
           GL_UNSIGNED_BYTE,
           kSharedMemoryId,
           kSharedMemoryOffset,
           GL_FALSE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  // Test if we call it again it does not clear.
  EXPECT_CALL(*gl_,
              TexSubImage2D(GL_TEXTURE_2D,
                            0,
                            1,
                            1,
                            1,
                            1,
                            GL_RGBA,
                            GL_UNSIGNED_BYTE,
                            shared_memory_address_))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderTest, TexSubImage2DClearsAfterTexImage2DWithDataThenNULL) {
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  // Put in data (so it should be marked as cleared)
  DoTexImage2D(GL_TEXTURE_2D,
               0,
               GL_RGBA,
               2,
               2,
               0,
               GL_RGBA,
               GL_UNSIGNED_BYTE,
               kSharedMemoryId,
               kSharedMemoryOffset);
  // Put in no data.
  TexImage2D tex_cmd;
  tex_cmd.Init(
      GL_TEXTURE_2D, 0, GL_RGBA, 2, 2, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);
  // It won't actually call TexImage2D, just mark it as uncleared.
  EXPECT_EQ(error::kNoError, ExecuteCmd(tex_cmd));
  // Next call to TexSubImage2d should clear.
  SetupClearTextureExpectations(kServiceTextureId,
                                kServiceTextureId,
                                GL_TEXTURE_2D,
                                GL_TEXTURE_2D,
                                0,
                                GL_RGBA,
                                GL_RGBA,
                                GL_UNSIGNED_BYTE,
                                2,
                                2);
  EXPECT_CALL(*gl_,
              TexSubImage2D(GL_TEXTURE_2D,
                            0,
                            1,
                            1,
                            1,
                            1,
                            GL_RGBA,
                            GL_UNSIGNED_BYTE,
                            shared_memory_address_))
      .Times(1)
      .RetiresOnSaturation();
  TexSubImage2D cmd;
  cmd.Init(GL_TEXTURE_2D,
           0,
           1,
           1,
           1,
           1,
           GL_RGBA,
           GL_UNSIGNED_BYTE,
           kSharedMemoryId,
           kSharedMemoryOffset,
           GL_FALSE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderTest, CopyTexImage2DMarksTextureAsCleared) {
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);

  TextureManager* manager = group().texture_manager();
  TextureRef* texture_ref = manager->GetTexture(client_texture_id_);
  ASSERT_TRUE(texture_ref != NULL);
  Texture* texture = texture_ref->texture();

  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, CopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 0, 0, 1, 1, 0))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  CopyTexImage2D cmd;
  cmd.Init(GL_TEXTURE_2D, 0, GL_RGBA, 0, 0, 1, 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));

  EXPECT_TRUE(texture->SafeToRenderFrom());
}

TEST_P(GLES2DecoderTest, CopyTexSubImage2DClearsUnclearedTexture) {
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA, 2, 2, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);

  SetupClearTextureExpectations(kServiceTextureId,
                                kServiceTextureId,
                                GL_TEXTURE_2D,
                                GL_TEXTURE_2D,
                                0,
                                GL_RGBA,
                                GL_RGBA,
                                GL_UNSIGNED_BYTE,
                                2,
                                2);
  EXPECT_CALL(*gl_, CopyTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 0, 0, 1, 1))
      .Times(1)
      .RetiresOnSaturation();
  CopyTexSubImage2D cmd;
  cmd.Init(GL_TEXTURE_2D, 0, 0, 0, 0, 0, 1, 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));

  TextureManager* manager = group().texture_manager();
  TextureRef* texture_ref = manager->GetTexture(client_texture_id_);
  ASSERT_TRUE(texture_ref != NULL);
  Texture* texture = texture_ref->texture();
  EXPECT_TRUE(texture->SafeToRenderFrom());
}

TEST_P(GLES2DecoderTest, CopyTexSubImage2DClearsUnclearedBackBufferSizedTexture) {
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  DoTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, kBackBufferWidth, kBackBufferHeight,
               0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);

  EXPECT_CALL(*gl_, CopyTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 0, 0,
                                      kBackBufferWidth, kBackBufferHeight))
      .Times(1)
      .RetiresOnSaturation();
  CopyTexSubImage2D cmd;
  cmd.Init(GL_TEXTURE_2D, 0, 0, 0, 0, 0, kBackBufferWidth, kBackBufferHeight);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));

  TextureManager* manager = group().texture_manager();
  TextureRef* texture_ref = manager->GetTexture(client_texture_id_);
  ASSERT_TRUE(texture_ref != NULL);
  Texture* texture = texture_ref->texture();
  EXPECT_TRUE(texture->SafeToRenderFrom());
}

TEST_P(GLES2DecoderManualInitTest, CompressedImage2DMarksTextureAsCleared) {
  InitState init;
  init.extensions = "GL_EXT_texture_compression_s3tc";
  init.bind_generates_resource = true;
  InitDecoder(init);

  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(
      *gl_,
      CompressedTexImage2D(
          GL_TEXTURE_2D, 0, GL_COMPRESSED_RGB_S3TC_DXT1_EXT, 4, 4, 0, 8, _))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  CompressedTexImage2D cmd;
  cmd.Init(GL_TEXTURE_2D,
           0,
           GL_COMPRESSED_RGB_S3TC_DXT1_EXT,
           4,
           4,
           8,
           kSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  TextureManager* manager = group().texture_manager();
  TextureRef* texture_ref = manager->GetTexture(client_texture_id_);
  EXPECT_TRUE(texture_ref->texture()->SafeToRenderFrom());
}

TEST_P(GLES2DecoderTest, TextureUsageAngleExtNotEnabledByDefault) {
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);

  TexParameteri cmd;
  cmd.Init(
      GL_TEXTURE_2D, GL_TEXTURE_USAGE_ANGLE, GL_FRAMEBUFFER_ATTACHMENT_ANGLE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());
}

TEST_P(GLES2DecoderTest, ProduceAndConsumeTextureCHROMIUM) {
  Mailbox mailbox = Mailbox::Generate();

  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA, 3, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);
  DoTexImage2D(
      GL_TEXTURE_2D, 1, GL_RGBA, 2, 4, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);
  TextureRef* texture_ref =
      group().texture_manager()->GetTexture(client_texture_id_);
  ASSERT_TRUE(texture_ref != NULL);
  Texture* texture = texture_ref->texture();
  EXPECT_EQ(kServiceTextureId, texture->service_id());

  ProduceTextureCHROMIUMImmediate& produce_cmd =
      *GetImmediateAs<ProduceTextureCHROMIUMImmediate>();
  produce_cmd.Init(GL_TEXTURE_2D, mailbox.name);
  EXPECT_EQ(error::kNoError,
            ExecuteImmediateCmd(produce_cmd, sizeof(mailbox.name)));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  // Texture didn't change.
  GLsizei width;
  GLsizei height;
  GLenum type;
  GLenum internal_format;

  EXPECT_TRUE(texture->GetLevelSize(GL_TEXTURE_2D, 0, &width, &height));
  EXPECT_EQ(3, width);
  EXPECT_EQ(1, height);
  EXPECT_TRUE(texture->GetLevelType(GL_TEXTURE_2D, 0, &type, &internal_format));
  EXPECT_EQ(static_cast<GLenum>(GL_RGBA), internal_format);
  EXPECT_EQ(static_cast<GLenum>(GL_UNSIGNED_BYTE), type);

  EXPECT_TRUE(texture->GetLevelSize(GL_TEXTURE_2D, 1, &width, &height));
  EXPECT_EQ(2, width);
  EXPECT_EQ(4, height);
  EXPECT_TRUE(texture->GetLevelType(GL_TEXTURE_2D, 1, &type, &internal_format));
  EXPECT_EQ(static_cast<GLenum>(GL_RGBA), internal_format);
  EXPECT_EQ(static_cast<GLenum>(GL_UNSIGNED_BYTE), type);

  // Service ID has not changed.
  EXPECT_EQ(kServiceTextureId, texture->service_id());

  // Create new texture for consume.
  EXPECT_CALL(*gl_, GenTextures(_, _))
      .WillOnce(SetArgumentPointee<1>(kNewServiceId))
      .RetiresOnSaturation();
  DoBindTexture(GL_TEXTURE_2D, kNewClientId, kNewServiceId);

  // Assigns and binds original service size texture ID.
  EXPECT_CALL(*gl_, DeleteTextures(1, _)).Times(1).RetiresOnSaturation();
  EXPECT_CALL(*gl_, BindTexture(GL_TEXTURE_2D, kServiceTextureId))
      .Times(1)
      .RetiresOnSaturation();

  ConsumeTextureCHROMIUMImmediate& consume_cmd =
      *GetImmediateAs<ConsumeTextureCHROMIUMImmediate>();
  consume_cmd.Init(GL_TEXTURE_2D, mailbox.name);
  EXPECT_EQ(error::kNoError,
            ExecuteImmediateCmd(consume_cmd, sizeof(mailbox.name)));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  // Texture is redefined.
  EXPECT_TRUE(texture->GetLevelSize(GL_TEXTURE_2D, 0, &width, &height));
  EXPECT_EQ(3, width);
  EXPECT_EQ(1, height);
  EXPECT_TRUE(texture->GetLevelType(GL_TEXTURE_2D, 0, &type, &internal_format));
  EXPECT_EQ(static_cast<GLenum>(GL_RGBA), internal_format);
  EXPECT_EQ(static_cast<GLenum>(GL_UNSIGNED_BYTE), type);

  EXPECT_TRUE(texture->GetLevelSize(GL_TEXTURE_2D, 1, &width, &height));
  EXPECT_EQ(2, width);
  EXPECT_EQ(4, height);
  EXPECT_TRUE(texture->GetLevelType(GL_TEXTURE_2D, 1, &type, &internal_format));
  EXPECT_EQ(static_cast<GLenum>(GL_RGBA), internal_format);
  EXPECT_EQ(static_cast<GLenum>(GL_UNSIGNED_BYTE), type);

  // Service ID is restored.
  EXPECT_EQ(kServiceTextureId, texture->service_id());
}

TEST_P(GLES2DecoderTest, ProduceAndConsumeDirectTextureCHROMIUM) {
  Mailbox mailbox = Mailbox::Generate();

  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA, 3, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);
  DoTexImage2D(
      GL_TEXTURE_2D, 1, GL_RGBA, 2, 4, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);
  TextureRef* texture_ref =
      group().texture_manager()->GetTexture(client_texture_id_);
  ASSERT_TRUE(texture_ref != NULL);
  Texture* texture = texture_ref->texture();
  EXPECT_EQ(kServiceTextureId, texture->service_id());

  ProduceTextureDirectCHROMIUMImmediate& produce_cmd =
      *GetImmediateAs<ProduceTextureDirectCHROMIUMImmediate>();
  produce_cmd.Init(client_texture_id_, GL_TEXTURE_2D, mailbox.name);
  EXPECT_EQ(error::kNoError,
            ExecuteImmediateCmd(produce_cmd, sizeof(mailbox.name)));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  // Texture didn't change.
  GLsizei width;
  GLsizei height;
  GLenum type;
  GLenum internal_format;

  EXPECT_TRUE(texture->GetLevelSize(GL_TEXTURE_2D, 0, &width, &height));
  EXPECT_EQ(3, width);
  EXPECT_EQ(1, height);
  EXPECT_TRUE(texture->GetLevelType(GL_TEXTURE_2D, 0, &type, &internal_format));
  EXPECT_EQ(static_cast<GLenum>(GL_RGBA), internal_format);
  EXPECT_EQ(static_cast<GLenum>(GL_UNSIGNED_BYTE), type);

  EXPECT_TRUE(texture->GetLevelSize(GL_TEXTURE_2D, 1, &width, &height));
  EXPECT_EQ(2, width);
  EXPECT_EQ(4, height);
  EXPECT_TRUE(texture->GetLevelType(GL_TEXTURE_2D, 1, &type, &internal_format));
  EXPECT_EQ(static_cast<GLenum>(GL_RGBA), internal_format);
  EXPECT_EQ(static_cast<GLenum>(GL_UNSIGNED_BYTE), type);

  // Service ID has not changed.
  EXPECT_EQ(kServiceTextureId, texture->service_id());

  // Consume the texture into a new client ID.
  GLuint new_texture_id = kNewClientId;
  CreateAndConsumeTextureCHROMIUMImmediate& consume_cmd =
      *GetImmediateAs<CreateAndConsumeTextureCHROMIUMImmediate>();
  consume_cmd.Init(GL_TEXTURE_2D, new_texture_id, mailbox.name);
  EXPECT_EQ(error::kNoError,
            ExecuteImmediateCmd(consume_cmd, sizeof(mailbox.name)));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  // Make sure the new client ID is associated with the produced service ID.
  texture_ref = group().texture_manager()->GetTexture(new_texture_id);
  ASSERT_TRUE(texture_ref != NULL);
  texture = texture_ref->texture();
  EXPECT_EQ(kServiceTextureId, texture->service_id());

  DoBindTexture(GL_TEXTURE_2D, kNewClientId, kServiceTextureId);

  // Texture is redefined.
  EXPECT_TRUE(texture->GetLevelSize(GL_TEXTURE_2D, 0, &width, &height));
  EXPECT_EQ(3, width);
  EXPECT_EQ(1, height);
  EXPECT_TRUE(texture->GetLevelType(GL_TEXTURE_2D, 0, &type, &internal_format));
  EXPECT_EQ(static_cast<GLenum>(GL_RGBA), internal_format);
  EXPECT_EQ(static_cast<GLenum>(GL_UNSIGNED_BYTE), type);

  EXPECT_TRUE(texture->GetLevelSize(GL_TEXTURE_2D, 1, &width, &height));
  EXPECT_EQ(2, width);
  EXPECT_EQ(4, height);
  EXPECT_TRUE(texture->GetLevelType(GL_TEXTURE_2D, 1, &type, &internal_format));
  EXPECT_EQ(static_cast<GLenum>(GL_RGBA), internal_format);
  EXPECT_EQ(static_cast<GLenum>(GL_UNSIGNED_BYTE), type);
}

TEST_P(GLES2DecoderTest, ProduceTextureCHROMIUMInvalidTarget) {
  Mailbox mailbox = Mailbox::Generate();

  DoBindTexture(GL_TEXTURE_CUBE_MAP, client_texture_id_, kServiceTextureId);
  DoTexImage2D(
      GL_TEXTURE_CUBE_MAP_POSITIVE_X, 0, GL_RGBA, 3, 1, 0, GL_RGBA,
      GL_UNSIGNED_BYTE, 0, 0);
  TextureRef* texture_ref =
      group().texture_manager()->GetTexture(client_texture_id_);
  ASSERT_TRUE(texture_ref != NULL);
  Texture* texture = texture_ref->texture();
  EXPECT_EQ(kServiceTextureId, texture->service_id());

  ProduceTextureDirectCHROMIUMImmediate& produce_cmd =
      *GetImmediateAs<ProduceTextureDirectCHROMIUMImmediate>();
  produce_cmd.Init(client_texture_id_, GL_TEXTURE_2D, mailbox.name);
  EXPECT_EQ(error::kNoError,
            ExecuteImmediateCmd(produce_cmd, sizeof(mailbox.name)));

  // ProduceTexture should fail it the texture and produce targets don't match.
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderTest, CreateAndConsumeTextureCHROMIUMInvalidMailbox) {
  // Attempt to consume the mailbox when no texture has been produced with it.
  Mailbox mailbox = Mailbox::Generate();
  GLuint new_texture_id = kNewClientId;

  EXPECT_CALL(*gl_, GenTextures(1, _))
        .WillOnce(SetArgumentPointee<1>(kNewServiceId))
        .RetiresOnSaturation();
  EXPECT_CALL(*gl_, BindTexture(GL_TEXTURE_2D, _))
        .Times(2)
        .RetiresOnSaturation();
  EXPECT_CALL(*gl_, ActiveTexture(GL_TEXTURE0))
      .Times(1)
      .RetiresOnSaturation();

  CreateAndConsumeTextureCHROMIUMImmediate& consume_cmd =
      *GetImmediateAs<CreateAndConsumeTextureCHROMIUMImmediate>();
  consume_cmd.Init(GL_TEXTURE_2D, new_texture_id, mailbox.name);
  EXPECT_EQ(error::kNoError,
            ExecuteImmediateCmd(consume_cmd, sizeof(mailbox.name)));

  // CreateAndConsumeTexture should fail if the mailbox isn't associated with a
  // texture.
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());

  // Make sure the new client_id is associated with a texture ref even though
  // CreateAndConsumeTexture failed.
  TextureRef* texture_ref =
      group().texture_manager()->GetTexture(new_texture_id);
  ASSERT_TRUE(texture_ref != NULL);
  Texture* texture = texture_ref->texture();
  // New texture should have the correct target type.
  EXPECT_TRUE(texture->target() == GL_TEXTURE_2D);
  // New texture should have a valid service_id.
  EXPECT_EQ(kNewServiceId, texture->service_id());
}

TEST_P(GLES2DecoderTest, CreateAndConsumeTextureCHROMIUMInvalidTarget) {
  Mailbox mailbox = Mailbox::Generate();

  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  TextureRef* texture_ref =
      group().texture_manager()->GetTexture(client_texture_id_);
  ASSERT_TRUE(texture_ref != NULL);

  ProduceTextureDirectCHROMIUMImmediate& produce_cmd =
      *GetImmediateAs<ProduceTextureDirectCHROMIUMImmediate>();
  produce_cmd.Init(client_texture_id_, GL_TEXTURE_2D, mailbox.name);
  EXPECT_EQ(error::kNoError,
            ExecuteImmediateCmd(produce_cmd, sizeof(mailbox.name)));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  EXPECT_CALL(*gl_, GenTextures(1, _))
        .WillOnce(SetArgumentPointee<1>(kNewServiceId))
        .RetiresOnSaturation();
  EXPECT_CALL(*gl_, BindTexture(GL_TEXTURE_CUBE_MAP, _))
        .Times(2)
        .RetiresOnSaturation();
  EXPECT_CALL(*gl_, ActiveTexture(GL_TEXTURE0))
        .Times(1)
        .RetiresOnSaturation();

  // Attempt to consume the mailbox with a different target.
  GLuint new_texture_id = kNewClientId;
  CreateAndConsumeTextureCHROMIUMImmediate& consume_cmd =
      *GetImmediateAs<CreateAndConsumeTextureCHROMIUMImmediate>();
  consume_cmd.Init(GL_TEXTURE_CUBE_MAP, new_texture_id, mailbox.name);
  EXPECT_EQ(error::kNoError,
            ExecuteImmediateCmd(consume_cmd, sizeof(mailbox.name)));

  // CreateAndConsumeTexture should fail if the produced texture had a different
  // target.
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());

  // Make sure the new client_id is associated with a texture ref even though
  // CreateAndConsumeTexture failed.
  texture_ref = group().texture_manager()->GetTexture(new_texture_id);
  ASSERT_TRUE(texture_ref != NULL);
  Texture* texture = texture_ref->texture();
  // New texture should have the correct target type.
  EXPECT_TRUE(texture->target() == GL_TEXTURE_CUBE_MAP);
  // New texture should have a valid service_id.
  EXPECT_EQ(kNewServiceId, texture->service_id());

  // Make sure the client_id did not become associated with the produced texture
  // service_id.
  EXPECT_NE(kServiceTextureId, texture->service_id());
}

TEST_P(GLES2DecoderManualInitTest, DepthTextureBadArgs) {
  InitState init;
  init.extensions = "GL_ANGLE_depth_texture";
  init.gl_version = "opengl es 2.0";
  init.has_depth = true;
  init.has_stencil = true;
  init.request_depth = true;
  init.request_stencil = true;
  init.bind_generates_resource = true;
  InitDecoder(init);

  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  // Check trying to upload data fails.
  TexImage2D tex_cmd;
  tex_cmd.Init(GL_TEXTURE_2D,
               0,
               GL_DEPTH_COMPONENT,
               1,
               1,
               GL_DEPTH_COMPONENT,
               GL_UNSIGNED_INT,
               kSharedMemoryId,
               kSharedMemoryOffset);
  EXPECT_EQ(error::kNoError, ExecuteCmd(tex_cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
  // Try level > 0.
  tex_cmd.Init(GL_TEXTURE_2D,
               1,
               GL_DEPTH_COMPONENT,
               1,
               1,
               GL_DEPTH_COMPONENT,
               GL_UNSIGNED_INT,
               0,
               0);
  EXPECT_EQ(error::kNoError, ExecuteCmd(tex_cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
  // Make a 1 pixel depth texture.
  DoTexImage2D(GL_TEXTURE_2D,
               0,
               GL_DEPTH_COMPONENT,
               1,
               1,
               0,
               GL_DEPTH_COMPONENT,
               GL_UNSIGNED_INT,
               0,
               0);
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  // Check that trying to update it fails.
  TexSubImage2D tex_sub_cmd;
  tex_sub_cmd.Init(GL_TEXTURE_2D,
                   0,
                   0,
                   0,
                   1,
                   1,
                   GL_DEPTH_COMPONENT,
                   GL_UNSIGNED_INT,
                   kSharedMemoryId,
                   kSharedMemoryOffset,
                   GL_FALSE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(tex_sub_cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());

  // Check that trying to CopyTexImage2D fails
  CopyTexImage2D copy_tex_cmd;
  copy_tex_cmd.Init(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT, 0, 0, 1, 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(copy_tex_cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());

  // Check that trying to CopyTexSubImage2D fails
  CopyTexSubImage2D copy_sub_cmd;
  copy_sub_cmd.Init(GL_TEXTURE_2D, 0, 0, 0, 0, 0, 1, 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(copy_sub_cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderManualInitTest, GenerateMipmapDepthTexture) {
  InitState init;
  init.extensions = "GL_ANGLE_depth_texture";
  init.gl_version = "opengl es 2.0";
  init.has_depth = true;
  init.has_stencil = true;
  init.request_depth = true;
  init.request_stencil = true;
  init.bind_generates_resource = true;
  InitDecoder(init);
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  DoTexImage2D(GL_TEXTURE_2D,
               0,
               GL_DEPTH_COMPONENT,
               2,
               2,
               0,
               GL_DEPTH_COMPONENT,
               GL_UNSIGNED_INT,
               0,
               0);
  GenerateMipmap cmd;
  cmd.Init(GL_TEXTURE_2D);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderTest, BindTexImage2DCHROMIUM) {
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA, 3, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);
  TextureRef* texture_ref =
      group().texture_manager()->GetTexture(client_texture_id_);
  ASSERT_TRUE(texture_ref != NULL);
  Texture* texture = texture_ref->texture();
  EXPECT_EQ(kServiceTextureId, texture->service_id());

  scoped_refptr<gfx::GLImage> image(new gfx::GLImageStub);
  GetImageManager()->AddImage(image.get(), 1);
  EXPECT_FALSE(GetImageManager()->LookupImage(1) == NULL);

  GLsizei width;
  GLsizei height;
  GLenum type;
  GLenum internal_format;

  EXPECT_TRUE(texture->GetLevelSize(GL_TEXTURE_2D, 0, &width, &height));
  EXPECT_EQ(3, width);
  EXPECT_EQ(1, height);
  EXPECT_TRUE(texture->GetLevelType(GL_TEXTURE_2D, 0, &type, &internal_format));
  EXPECT_EQ(static_cast<GLenum>(GL_RGBA), internal_format);
  EXPECT_EQ(static_cast<GLenum>(GL_UNSIGNED_BYTE), type);
  EXPECT_TRUE(texture->GetLevelImage(GL_TEXTURE_2D, 0) == NULL);

  // Bind image to texture.
  // ScopedGLErrorSuppressor calls GetError on its constructor and destructor.
  DoBindTexImage2DCHROMIUM(GL_TEXTURE_2D, 1);
  EXPECT_TRUE(texture->GetLevelSize(GL_TEXTURE_2D, 0, &width, &height));
  // Image should now be set.
  EXPECT_FALSE(texture->GetLevelImage(GL_TEXTURE_2D, 0) == NULL);

  // Define new texture image.
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA, 3, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);
  EXPECT_TRUE(texture->GetLevelSize(GL_TEXTURE_2D, 0, &width, &height));
  // Image should no longer be set.
  EXPECT_TRUE(texture->GetLevelImage(GL_TEXTURE_2D, 0) == NULL);
}

TEST_P(GLES2DecoderTest, BindTexImage2DCHROMIUMCubeMapNotAllowed) {
  scoped_refptr<gfx::GLImage> image(new gfx::GLImageStub);
  GetImageManager()->AddImage(image.get(), 1);
  DoBindTexture(GL_TEXTURE_CUBE_MAP, client_texture_id_, kServiceTextureId);

  BindTexImage2DCHROMIUM bind_tex_image_2d_cmd;
  bind_tex_image_2d_cmd.Init(GL_TEXTURE_CUBE_MAP, 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(bind_tex_image_2d_cmd));
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());
}

TEST_P(GLES2DecoderTest, OrphanGLImageWithTexImage2D) {
  scoped_refptr<gfx::GLImage> image(new gfx::GLImageStub);
  GetImageManager()->AddImage(image.get(), 1);
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);

  DoBindTexImage2DCHROMIUM(GL_TEXTURE_2D, 1);

  TextureRef* texture_ref =
      group().texture_manager()->GetTexture(client_texture_id_);
  ASSERT_TRUE(texture_ref != NULL);
  Texture* texture = texture_ref->texture();

  EXPECT_TRUE(texture->GetLevelImage(GL_TEXTURE_2D, 0) == image.get());
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA, 3, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);
  EXPECT_TRUE(texture->GetLevelImage(GL_TEXTURE_2D, 0) == NULL);
}

TEST_P(GLES2DecoderTest, GLImageAttachedAfterSubTexImage2D) {
  // Specifically tests that TexSubImage2D is not optimized to TexImage2D
  // in the presence of image attachments.
  ASSERT_FALSE(
      feature_info()->workarounds().texsubimage2d_faster_than_teximage2d);

  scoped_refptr<gfx::GLImage> image(new gfx::GLImageStub);
  GetImageManager()->AddImage(image.get(), 1);
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);

  GLenum target = GL_TEXTURE_2D;
  GLint level = 0;
  GLint xoffset = 0;
  GLint yoffset = 0;
  GLsizei width = 1;
  GLsizei height = 1;
  GLint border = 0;
  GLenum format = GL_RGBA;
  GLenum type = GL_UNSIGNED_BYTE;
  uint32_t pixels_shm_id = kSharedMemoryId;
  uint32_t pixels_shm_offset = kSharedMemoryOffset;
  GLboolean internal = 0;

  // Define texture first.
  DoTexImage2D(target, level, format, width, height, border, format, type,
               pixels_shm_id, pixels_shm_offset);

  // Bind texture to GLImage.
  DoBindTexImage2DCHROMIUM(GL_TEXTURE_2D, 1);

  // Check binding.
  TextureRef* texture_ref =
      group().texture_manager()->GetTexture(client_texture_id_);
  ASSERT_TRUE(texture_ref != NULL);
  Texture* texture = texture_ref->texture();
  EXPECT_TRUE(texture->GetLevelImage(GL_TEXTURE_2D, 0) == image.get());

  // TexSubImage2D should not unbind GLImage.
  EXPECT_CALL(*gl_, TexSubImage2D(target, level, xoffset, yoffset, width,
                                  height, format, type, _))
      .Times(1)
      .RetiresOnSaturation();
  cmds::TexSubImage2D tex_sub_image_2d_cmd;
  tex_sub_image_2d_cmd.Init(target, level, xoffset, yoffset, width, height,
                            format, type, pixels_shm_id, pixels_shm_offset,
                            internal);
  EXPECT_EQ(error::kNoError, ExecuteCmd(tex_sub_image_2d_cmd));
  EXPECT_TRUE(texture->GetLevelImage(GL_TEXTURE_2D, 0) == image.get());
}

TEST_P(GLES2DecoderTest, GLImageAttachedAfterClearLevel) {
  scoped_refptr<gfx::GLImage> image(new gfx::GLImageStub);
  GetImageManager()->AddImage(image.get(), 1);
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);

  GLenum target = GL_TEXTURE_2D;
  GLint level = 0;
  GLint xoffset = 0;
  GLint yoffset = 0;
  GLsizei width = 1;
  GLsizei height = 1;
  GLint border = 0;
  GLenum format = GL_RGBA;
  GLenum type = GL_UNSIGNED_BYTE;
  uint32_t pixels_shm_id = kSharedMemoryId;
  uint32_t pixels_shm_offset = kSharedMemoryOffset;

  // Define texture first.
  DoTexImage2D(target, level, format, width, height, border, format, type,
               pixels_shm_id, pixels_shm_offset);

  // Bind texture to GLImage.
  DoBindTexImage2DCHROMIUM(GL_TEXTURE_2D, 1);

  // Check binding.
  TextureRef* texture_ref =
      group().texture_manager()->GetTexture(client_texture_id_);
  ASSERT_TRUE(texture_ref != NULL);
  Texture* texture = texture_ref->texture();
  EXPECT_TRUE(texture->GetLevelImage(GL_TEXTURE_2D, 0) == image.get());

  // ClearLevel should use glTexSubImage2D to avoid unbinding GLImage.
  EXPECT_CALL(*gl_, BindTexture(GL_TEXTURE_2D, kServiceTextureId))
      .Times(2)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, TexSubImage2D(target, level, xoffset, yoffset, width,
                                  height, format, type, _))
      .Times(1)
      .RetiresOnSaturation();
  GetDecoder()->ClearLevel(texture, target, level, format, format, type, width,
                           height, false);
  EXPECT_TRUE(texture->GetLevelImage(GL_TEXTURE_2D, 0) == image.get());
}

TEST_P(GLES2DecoderTest, ReleaseTexImage2DCHROMIUM) {
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA, 3, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);
  TextureRef* texture_ref =
      group().texture_manager()->GetTexture(client_texture_id_);
  ASSERT_TRUE(texture_ref != NULL);
  Texture* texture = texture_ref->texture();
  EXPECT_EQ(kServiceTextureId, texture->service_id());

  scoped_refptr<gfx::GLImage> image(new gfx::GLImageStub);
  GetImageManager()->AddImage(image.get(), 1);
  EXPECT_FALSE(GetImageManager()->LookupImage(1) == NULL);

  GLsizei width;
  GLsizei height;
  GLenum type;
  GLenum internal_format;

  EXPECT_TRUE(texture->GetLevelSize(GL_TEXTURE_2D, 0, &width, &height));
  EXPECT_EQ(3, width);
  EXPECT_EQ(1, height);
  EXPECT_TRUE(texture->GetLevelType(GL_TEXTURE_2D, 0, &type, &internal_format));
  EXPECT_EQ(static_cast<GLenum>(GL_RGBA), internal_format);
  EXPECT_EQ(static_cast<GLenum>(GL_UNSIGNED_BYTE), type);
  EXPECT_TRUE(texture->GetLevelImage(GL_TEXTURE_2D, 0) == NULL);

  // Bind image to texture.
  // ScopedGLErrorSuppressor calls GetError on its constructor and destructor.
  DoBindTexImage2DCHROMIUM(GL_TEXTURE_2D, 1);
  EXPECT_TRUE(texture->GetLevelSize(GL_TEXTURE_2D, 0, &width, &height));
  // Image should now be set.
  EXPECT_FALSE(texture->GetLevelImage(GL_TEXTURE_2D, 0) == NULL);

  // Release image from texture.
  // ScopedGLErrorSuppressor calls GetError on its constructor and destructor.
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  ReleaseTexImage2DCHROMIUM release_tex_image_2d_cmd;
  release_tex_image_2d_cmd.Init(GL_TEXTURE_2D, 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(release_tex_image_2d_cmd));
  EXPECT_TRUE(texture->GetLevelSize(GL_TEXTURE_2D, 0, &width, &height));
  // Image should no longer be set.
  EXPECT_TRUE(texture->GetLevelImage(GL_TEXTURE_2D, 0) == NULL);
}

class MockGLImage : public gfx::GLImage {
 public:
  MockGLImage() {}

  // Overridden from gfx::GLImage:
  MOCK_METHOD0(GetSize, gfx::Size());
  MOCK_METHOD1(Destroy, void(bool));
  MOCK_METHOD1(BindTexImage, bool(unsigned));
  MOCK_METHOD1(ReleaseTexImage, void(unsigned));
  MOCK_METHOD1(CopyTexImage, bool(unsigned));
  MOCK_METHOD0(WillUseTexImage, void());
  MOCK_METHOD0(DidUseTexImage, void());
  MOCK_METHOD0(WillModifyTexImage, void());
  MOCK_METHOD0(DidModifyTexImage, void());
  MOCK_METHOD5(ScheduleOverlayPlane, bool(gfx::AcceleratedWidget,
                                          int,
                                          gfx::OverlayTransform,
                                          const gfx::Rect&,
                                          const gfx::RectF&));

 protected:
  virtual ~MockGLImage() {}
};

TEST_P(GLES2DecoderWithShaderTest, UseTexImage) {
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  DoTexImage2D(GL_TEXTURE_2D,
               0,
               GL_RGBA,
               1,
               1,
               0,
               GL_RGBA,
               GL_UNSIGNED_BYTE,
               kSharedMemoryId,
               kSharedMemoryOffset);

  TextureRef* texture_ref =
      group().texture_manager()->GetTexture(client_texture_id_);
  ASSERT_TRUE(texture_ref != NULL);
  Texture* texture = texture_ref->texture();
  EXPECT_EQ(kServiceTextureId, texture->service_id());

  const int32 kImageId = 1;
  scoped_refptr<MockGLImage> image(new MockGLImage);
  GetImageManager()->AddImage(image.get(), kImageId);

  // Bind image to texture.
  EXPECT_CALL(*image.get(), BindTexImage(GL_TEXTURE_2D))
      .Times(1)
      .WillOnce(Return(true))
      .RetiresOnSaturation();
  EXPECT_CALL(*image.get(), GetSize())
      .Times(1)
      .WillOnce(Return(gfx::Size(1, 1)))
      .RetiresOnSaturation();
  // ScopedGLErrorSuppressor calls GetError on its constructor and destructor.
  DoBindTexImage2DCHROMIUM(GL_TEXTURE_2D, kImageId);

  AddExpectationsForSimulatedAttrib0(kNumVertices, 0);
  SetupExpectationsForApplyingDefaultDirtyState();

  // ScopedGLErrorSuppressor calls GetError on its constructor and destructor.
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, ActiveTexture(GL_TEXTURE0)).Times(3).RetiresOnSaturation();
  EXPECT_CALL(*image.get(), WillUseTexImage()).Times(1).RetiresOnSaturation();
  EXPECT_CALL(*image.get(), DidUseTexImage()).Times(1).RetiresOnSaturation();
  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawArrays cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  DoBindFramebuffer(
      GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
  // ScopedGLErrorSuppressor calls GetError on its constructor and destructor.
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, ActiveTexture(GL_TEXTURE0)).Times(1).RetiresOnSaturation();
  EXPECT_CALL(*gl_, BindTexture(GL_TEXTURE_2D, kServiceTextureId))
      .Times(2)
      .RetiresOnSaturation();
  // Image will be 'in use' as long as bound to a framebuffer.
  EXPECT_CALL(*image.get(), WillUseTexImage()).Times(1).RetiresOnSaturation();
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
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  FramebufferTexture2D fbtex_cmd;
  fbtex_cmd.Init(GL_FRAMEBUFFER,
                 GL_COLOR_ATTACHMENT0,
                 GL_TEXTURE_2D,
                 client_texture_id_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(fbtex_cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  // ScopedGLErrorSuppressor calls GetError on its constructor and destructor.
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_,
              FramebufferRenderbufferEXT(GL_FRAMEBUFFER,
                                         GL_COLOR_ATTACHMENT0,
                                         GL_RENDERBUFFER,
                                         kServiceRenderbufferId))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, ActiveTexture(GL_TEXTURE0)).Times(1).RetiresOnSaturation();
  EXPECT_CALL(*gl_, BindTexture(GL_TEXTURE_2D, kServiceTextureId))
      .Times(2)
      .RetiresOnSaturation();
  // Image should no longer be 'in use' after being unbound from framebuffer.
  EXPECT_CALL(*image.get(), DidUseTexImage()).Times(1).RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  FramebufferRenderbuffer fbrb_cmd;
  fbrb_cmd.Init(GL_FRAMEBUFFER,
                GL_COLOR_ATTACHMENT0,
                GL_RENDERBUFFER,
                client_renderbuffer_id_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(fbrb_cmd));
}

TEST_P(GLES2DecoderManualInitTest, DrawWithGLImageExternal) {
  InitState init;
  init.extensions = "GL_OES_EGL_image_external";
  init.gl_version = "opengl es 2.0";
  init.has_alpha = true;
  init.has_depth = true;
  init.request_alpha = true;
  init.request_depth = true;
  init.bind_generates_resource = true;
  InitDecoder(init);

  TextureRef* texture_ref = GetTexture(client_texture_id_);
  scoped_refptr<MockGLImage> image(new MockGLImage);
  group().texture_manager()->SetTarget(texture_ref, GL_TEXTURE_EXTERNAL_OES);
  group().texture_manager()->SetLevelInfo(texture_ref,
                                          GL_TEXTURE_EXTERNAL_OES,
                                          0,
                                          GL_RGBA,
                                          0,
                                          0,
                                          1,
                                          0,
                                          GL_RGBA,
                                          GL_UNSIGNED_BYTE,
                                          true);
  group().texture_manager()->SetLevelImage(
      texture_ref, GL_TEXTURE_EXTERNAL_OES, 0, image.get());

  DoBindTexture(GL_TEXTURE_EXTERNAL_OES, client_texture_id_, kServiceTextureId);
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  SetupSamplerExternalProgram();
  SetupIndexBuffer();
  AddExpectationsForSimulatedAttrib0(kMaxValidIndex + 1, 0);
  SetupExpectationsForApplyingDefaultDirtyState();
  EXPECT_TRUE(group().texture_manager()->CanRender(texture_ref));

  InSequence s;
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, ActiveTexture(GL_TEXTURE0)).Times(1).RetiresOnSaturation();
  EXPECT_CALL(*image.get(), WillUseTexImage()).Times(1).RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, DrawElements(_, _, _, _)).Times(1);
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, ActiveTexture(GL_TEXTURE0)).Times(1).RetiresOnSaturation();
  EXPECT_CALL(*image.get(), DidUseTexImage()).Times(1).RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, ActiveTexture(GL_TEXTURE0)).Times(1).RetiresOnSaturation();
  DrawElements cmd;
  cmd.Init(GL_TRIANGLES,
           kValidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kValidIndexRangeStart * 2);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderManualInitTest, TexImage2DFloatOnGLES2) {
  InitState init;
  init.extensions = "GL_OES_texture_float";
  init.gl_version = "opengl es 2.0";
  InitDecoder(init);
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  DoTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 16, 17, 0, GL_RGBA, GL_FLOAT, 0, 0);
  DoTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 16, 17, 0, GL_RGB, GL_FLOAT, 0, 0);
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_LUMINANCE, 16, 17, 0, GL_LUMINANCE, GL_FLOAT, 0, 0);
  DoTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, 16, 17, 0, GL_ALPHA, GL_FLOAT, 0, 0);
  DoTexImage2D(GL_TEXTURE_2D,
               0,
               GL_LUMINANCE_ALPHA,
               16,
               17,
               0,
               GL_LUMINANCE_ALPHA,
               GL_FLOAT,
               0,
               0);
}

TEST_P(GLES2DecoderManualInitTest, TexImage2DFloatOnGLES3) {
  InitState init;
  init.extensions = "GL_OES_texture_float GL_EXT_color_buffer_float";
  init.gl_version = "opengl es 3.0";
  InitDecoder(init);
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  DoTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 16, 17, 0, GL_RGBA, GL_FLOAT, 0, 0);
  DoTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 16, 17, 0, GL_RGB, GL_FLOAT, 0, 0);
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA32F, 16, 17, 0, GL_RGBA, GL_FLOAT, 0, 0);
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_LUMINANCE, 16, 17, 0, GL_LUMINANCE, GL_FLOAT, 0, 0);
  DoTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, 16, 17, 0, GL_ALPHA, GL_FLOAT, 0, 0);
  DoTexImage2D(GL_TEXTURE_2D,
               0,
               GL_LUMINANCE_ALPHA,
               16,
               17,
               0,
               GL_LUMINANCE_ALPHA,
               GL_FLOAT,
               0,
               0);
}

TEST_P(GLES2DecoderManualInitTest, TexSubImage2DFloatOnGLES3) {
  InitState init;
  init.extensions = "GL_OES_texture_float GL_EXT_color_buffer_float";
  init.gl_version = "opengl es 3.0";
  InitDecoder(init);
  const int kWidth = 8;
  const int kHeight = 4;
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  DoTexImage2D(GL_TEXTURE_2D,
               0,
               GL_RGBA32F,
               kWidth,
               kHeight,
               0,
               GL_RGBA,
               GL_FLOAT,
               0,
               0);
  EXPECT_CALL(*gl_,
              TexImage2D(GL_TEXTURE_2D,
                         0,
                         GL_RGBA32F,
                         kWidth,
                         kHeight,
                         0,
                         GL_RGBA,
                         GL_FLOAT,
                         shared_memory_address_))
      .Times(1)
      .RetiresOnSaturation();
  TexSubImage2D cmd;
  cmd.Init(GL_TEXTURE_2D,
           0,
           0,
           0,
           kWidth,
           kHeight,
           GL_RGBA,
           GL_FLOAT,
           kSharedMemoryId,
           kSharedMemoryOffset,
           GL_FALSE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderManualInitTest, TexSubImage2DFloatDoesClearOnGLES3) {
  InitState init;
  init.extensions = "GL_OES_texture_float GL_EXT_color_buffer_float";
  init.gl_version = "opengl es 3.0";
  InitDecoder(init);
  const int kWidth = 8;
  const int kHeight = 4;
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  DoTexImage2D(GL_TEXTURE_2D,
               0,
               GL_RGBA32F,
               kWidth,
               kHeight,
               0,
               GL_RGBA,
               GL_FLOAT,
               0,
               0);
  SetupClearTextureExpectations(kServiceTextureId,
                                kServiceTextureId,
                                GL_TEXTURE_2D,
                                GL_TEXTURE_2D,
                                0,
                                GL_RGBA32F,
                                GL_RGBA,
                                GL_FLOAT,
                                kWidth,
                                kHeight);
  EXPECT_CALL(*gl_,
              TexSubImage2D(GL_TEXTURE_2D,
                            0,
                            1,
                            0,
                            kWidth - 1,
                            kHeight,
                            GL_RGBA,
                            GL_FLOAT,
                            shared_memory_address_))
      .Times(1)
      .RetiresOnSaturation();
  TexSubImage2D cmd;
  cmd.Init(GL_TEXTURE_2D,
           0,
           1,
           0,
           kWidth - 1,
           kHeight,
           GL_RGBA,
           GL_FLOAT,
           kSharedMemoryId,
           kSharedMemoryOffset,
           GL_FALSE);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderManualInitTest, TexImage2DFloatConvertsFormatDesktop) {
  InitState init;
  init.extensions = "GL_ARB_texture_float";
  InitDecoder(init);
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA32F, 16, 17, 0, GL_RGBA, GL_FLOAT, 0, 0);
  DoTexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F, 16, 17, 0, GL_RGB, GL_FLOAT, 0, 0);
  DoTexImage2DConvertInternalFormat(GL_TEXTURE_2D,
                                    0,
                                    GL_RGBA,
                                    16,
                                    17,
                                    0,
                                    GL_RGBA,
                                    GL_FLOAT,
                                    0,
                                    0,
                                    GL_RGBA32F_ARB);
  DoTexImage2DConvertInternalFormat(GL_TEXTURE_2D,
                                    0,
                                    GL_RGB,
                                    16,
                                    17,
                                    0,
                                    GL_RGB,
                                    GL_FLOAT,
                                    0,
                                    0,
                                    GL_RGB32F_ARB);
  DoTexImage2DConvertInternalFormat(GL_TEXTURE_2D,
                                    0,
                                    GL_LUMINANCE,
                                    16,
                                    17,
                                    0,
                                    GL_LUMINANCE,
                                    GL_FLOAT,
                                    0,
                                    0,
                                    GL_LUMINANCE32F_ARB);
  DoTexImage2DConvertInternalFormat(GL_TEXTURE_2D,
                                    0,
                                    GL_ALPHA,
                                    16,
                                    17,
                                    0,
                                    GL_ALPHA,
                                    GL_FLOAT,
                                    0,
                                    0,
                                    GL_ALPHA32F_ARB);
  DoTexImage2DConvertInternalFormat(GL_TEXTURE_2D,
                                    0,
                                    GL_LUMINANCE_ALPHA,
                                    16,
                                    17,
                                    0,
                                    GL_LUMINANCE_ALPHA,
                                    GL_FLOAT,
                                    0,
                                    0,
                                    GL_LUMINANCE_ALPHA32F_ARB);
}

class GLES2DecoderCompressedFormatsTest : public GLES2DecoderManualInitTest {
 public:
  GLES2DecoderCompressedFormatsTest() {}

  static bool ValueInArray(GLint value, GLint* array, GLint count) {
    for (GLint ii = 0; ii < count; ++ii) {
      if (array[ii] == value) {
        return true;
      }
    }
    return false;
  }

  void CheckFormats(const char* extension, const GLenum* formats, int count) {
    InitState init;
    init.extensions = extension;
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
    result->size = 0;
    EXPECT_CALL(*gl_, GetIntegerv(_, _)).Times(0).RetiresOnSaturation();
    cmd.Init(GL_NUM_COMPRESSED_TEXTURE_FORMATS,
             shared_memory_id_,
             shared_memory_offset_);
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
    EXPECT_EQ(1, result->GetNumResults());
    GLint num_formats = result->GetData()[0];
    EXPECT_EQ(count, num_formats);
    EXPECT_EQ(GL_NO_ERROR, GetGLError());

    result->size = 0;
    cmd.Init(GL_COMPRESSED_TEXTURE_FORMATS,
             shared_memory_id_,
             shared_memory_offset_);
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
    EXPECT_EQ(num_formats, result->GetNumResults());

    for (int i = 0; i < count; ++i) {
      EXPECT_TRUE(
          ValueInArray(formats[i], result->GetData(), result->GetNumResults()));
    }

    EXPECT_EQ(GL_NO_ERROR, GetGLError());
  }
};

INSTANTIATE_TEST_CASE_P(Service,
                        GLES2DecoderCompressedFormatsTest,
                        ::testing::Bool());

TEST_P(GLES2DecoderCompressedFormatsTest, GetCompressedTextureFormatsS3TC) {
  const GLenum formats[] = {
      GL_COMPRESSED_RGB_S3TC_DXT1_EXT, GL_COMPRESSED_RGBA_S3TC_DXT1_EXT,
      GL_COMPRESSED_RGBA_S3TC_DXT3_EXT, GL_COMPRESSED_RGBA_S3TC_DXT5_EXT};
  CheckFormats("GL_EXT_texture_compression_s3tc", formats, 4);
}

TEST_P(GLES2DecoderCompressedFormatsTest, GetCompressedTextureFormatsATC) {
  const GLenum formats[] = {GL_ATC_RGB_AMD, GL_ATC_RGBA_EXPLICIT_ALPHA_AMD,
                            GL_ATC_RGBA_INTERPOLATED_ALPHA_AMD};
  CheckFormats("GL_AMD_compressed_ATC_texture", formats, 3);
}

TEST_P(GLES2DecoderCompressedFormatsTest, GetCompressedTextureFormatsPVRTC) {
  const GLenum formats[] = {
      GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG, GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG,
      GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG, GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG};
  CheckFormats("GL_IMG_texture_compression_pvrtc", formats, 4);
}

TEST_P(GLES2DecoderCompressedFormatsTest, GetCompressedTextureFormatsETC1) {
  const GLenum formats[] = {GL_ETC1_RGB8_OES};
  CheckFormats("GL_OES_compressed_ETC1_RGB8_texture", formats, 1);
}

TEST_P(GLES2DecoderManualInitTest, GetNoCompressedTextureFormats) {
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
  result->size = 0;
  EXPECT_CALL(*gl_, GetIntegerv(_, _)).Times(0).RetiresOnSaturation();
  cmd.Init(GL_NUM_COMPRESSED_TEXTURE_FORMATS,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(1, result->GetNumResults());
  GLint num_formats = result->GetData()[0];
  EXPECT_EQ(0, num_formats);
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  result->size = 0;
  cmd.Init(
      GL_COMPRESSED_TEXTURE_FORMATS, shared_memory_id_, shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(num_formats, result->GetNumResults());

  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

// TODO(gman): Complete this test.
// TEST_P(GLES2DecoderTest, CompressedTexImage2DGLError) {
// }

// TODO(gman): CompressedTexImage2D

// TODO(gman): CompressedTexImage2DImmediate

// TODO(gman): CompressedTexSubImage2DImmediate

// TODO(gman): TexImage2D

// TODO(gman): TexImage2DImmediate

// TODO(gman): TexSubImage2DImmediate

}  // namespace gles2
}  // namespace gpu
