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
#include "gpu/command_buffer/service/image_manager.h"
#include "gpu/command_buffer/service/mailbox_manager.h"
#include "gpu/command_buffer/service/mocks.h"
#include "gpu/command_buffer/service/program_manager.h"
#include "gpu/command_buffer/service/test_helper.h"
#include "gpu/config/gpu_switches.h"
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
using ::testing::SetArgPointee;
using ::testing::StrEq;
using ::testing::StrictMock;

namespace gpu {
namespace gles2 {

using namespace cmds;

TEST_P(GLES2DecoderWithShaderTest, GetProgramInfoCHROMIUMValidArgs) {
  const uint32 kBucketId = 123;
  GetProgramInfoCHROMIUM cmd;
  cmd.Init(client_program_id_, kBucketId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  CommonDecoder::Bucket* bucket = decoder_->GetBucket(kBucketId);
  EXPECT_GT(bucket->size(), 0u);
}

TEST_P(GLES2DecoderWithShaderTest, GetProgramInfoCHROMIUMInvalidArgs) {
  const uint32 kBucketId = 123;
  CommonDecoder::Bucket* bucket = decoder_->GetBucket(kBucketId);
  EXPECT_TRUE(bucket == NULL);
  GetProgramInfoCHROMIUM cmd;
  cmd.Init(kInvalidClientId, kBucketId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  bucket = decoder_->GetBucket(kBucketId);
  ASSERT_TRUE(bucket != NULL);
  EXPECT_EQ(sizeof(ProgramInfoHeader), bucket->size());
  ProgramInfoHeader* info =
      bucket->GetDataAs<ProgramInfoHeader*>(0, sizeof(ProgramInfoHeader));
  ASSERT_TRUE(info != 0);
  EXPECT_EQ(0u, info->link_status);
  EXPECT_EQ(0u, info->num_attribs);
  EXPECT_EQ(0u, info->num_uniforms);
}

TEST_P(GLES2DecoderWithShaderTest, GetUniformBlocksCHROMIUMValidArgs) {
  const uint32 kBucketId = 123;
  GetUniformBlocksCHROMIUM cmd;
  cmd.Init(client_program_id_, kBucketId);
  EXPECT_CALL(*gl_, GetProgramiv(kServiceProgramId, GL_LINK_STATUS, _))
      .WillOnce(SetArgPointee<2>(GL_TRUE))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_,
              GetProgramiv(kServiceProgramId, GL_ACTIVE_UNIFORM_BLOCKS, _))
      .WillOnce(SetArgPointee<2>(0))
      .RetiresOnSaturation();
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  CommonDecoder::Bucket* bucket = decoder_->GetBucket(kBucketId);
  EXPECT_EQ(sizeof(UniformBlocksHeader), bucket->size());
  UniformBlocksHeader* header =
      bucket->GetDataAs<UniformBlocksHeader*>(0, sizeof(UniformBlocksHeader));
  EXPECT_TRUE(header != NULL);
  EXPECT_EQ(0u, header->num_uniform_blocks);
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetUniformBlocksCHROMIUMInvalidArgs) {
  const uint32 kBucketId = 123;
  CommonDecoder::Bucket* bucket = decoder_->GetBucket(kBucketId);
  EXPECT_TRUE(bucket == NULL);
  GetUniformBlocksCHROMIUM cmd;
  cmd.Init(kInvalidClientId, kBucketId);
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  bucket = decoder_->GetBucket(kBucketId);
  ASSERT_TRUE(bucket != NULL);
  EXPECT_EQ(sizeof(UniformBlocksHeader), bucket->size());
  UniformBlocksHeader* header =
      bucket->GetDataAs<UniformBlocksHeader*>(0, sizeof(UniformBlocksHeader));
  ASSERT_TRUE(header != NULL);
  EXPECT_EQ(0u, header->num_uniform_blocks);
}

TEST_P(GLES2DecoderWithShaderTest, GetUniformsES3CHROMIUMValidArgs) {
  const uint32 kBucketId = 123;
  GetUniformsES3CHROMIUM cmd;
  cmd.Init(client_program_id_, kBucketId);
  EXPECT_CALL(*gl_, GetProgramiv(kServiceProgramId, GL_LINK_STATUS, _))
      .WillOnce(SetArgPointee<2>(GL_TRUE))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_,
              GetProgramiv(kServiceProgramId, GL_ACTIVE_UNIFORMS, _))
      .WillOnce(SetArgPointee<2>(0))
      .RetiresOnSaturation();
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  CommonDecoder::Bucket* bucket = decoder_->GetBucket(kBucketId);
  EXPECT_EQ(sizeof(UniformsES3Header), bucket->size());
  UniformsES3Header* header =
      bucket->GetDataAs<UniformsES3Header*>(0, sizeof(UniformsES3Header));
  EXPECT_TRUE(header != NULL);
  EXPECT_EQ(0u, header->num_uniforms);
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetUniformsES3CHROMIUMInvalidArgs) {
  const uint32 kBucketId = 123;
  CommonDecoder::Bucket* bucket = decoder_->GetBucket(kBucketId);
  EXPECT_TRUE(bucket == NULL);
  GetUniformsES3CHROMIUM cmd;
  cmd.Init(kInvalidClientId, kBucketId);
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  bucket = decoder_->GetBucket(kBucketId);
  ASSERT_TRUE(bucket != NULL);
  EXPECT_EQ(sizeof(UniformsES3Header), bucket->size());
  UniformsES3Header* header =
      bucket->GetDataAs<UniformsES3Header*>(0, sizeof(UniformsES3Header));
  ASSERT_TRUE(header != NULL);
  EXPECT_EQ(0u, header->num_uniforms);
}

TEST_P(GLES2DecoderWithShaderTest,
       GetTransformFeedbackVaryingsCHROMIUMValidArgs) {
  const uint32 kBucketId = 123;
  GetTransformFeedbackVaryingsCHROMIUM cmd;
  cmd.Init(client_program_id_, kBucketId);
  EXPECT_CALL(*gl_, GetProgramiv(kServiceProgramId, GL_LINK_STATUS, _))
      .WillOnce(SetArgPointee<2>(GL_TRUE))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_,
              GetProgramiv(
                  kServiceProgramId, GL_TRANSFORM_FEEDBACK_VARYINGS, _))
      .WillOnce(SetArgPointee<2>(0))
      .RetiresOnSaturation();
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  CommonDecoder::Bucket* bucket = decoder_->GetBucket(kBucketId);
  EXPECT_EQ(sizeof(TransformFeedbackVaryingsHeader), bucket->size());
  TransformFeedbackVaryingsHeader* header =
      bucket->GetDataAs<TransformFeedbackVaryingsHeader*>(
          0, sizeof(TransformFeedbackVaryingsHeader));
  EXPECT_TRUE(header != NULL);
  EXPECT_EQ(0u, header->num_transform_feedback_varyings);
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest,
       GetTransformFeedbackVaryingsCHROMIUMInvalidArgs) {
  const uint32 kBucketId = 123;
  CommonDecoder::Bucket* bucket = decoder_->GetBucket(kBucketId);
  EXPECT_TRUE(bucket == NULL);
  GetTransformFeedbackVaryingsCHROMIUM cmd;
  cmd.Init(kInvalidClientId, kBucketId);
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  bucket = decoder_->GetBucket(kBucketId);
  ASSERT_TRUE(bucket != NULL);
  EXPECT_EQ(sizeof(TransformFeedbackVaryingsHeader), bucket->size());
  TransformFeedbackVaryingsHeader* header =
      bucket->GetDataAs<TransformFeedbackVaryingsHeader*>(
          0, sizeof(TransformFeedbackVaryingsHeader));
  ASSERT_TRUE(header != NULL);
  EXPECT_EQ(0u, header->num_transform_feedback_varyings);
}

TEST_P(GLES2DecoderWithShaderTest, GetUniformivSucceeds) {
  GetUniformiv::Result* result =
      static_cast<GetUniformiv::Result*>(shared_memory_address_);
  result->size = 0;
  GetUniformiv cmd;
  cmd.Init(client_program_id_,
           kUniform2FakeLocation,
           kSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_CALL(*gl_, GetUniformiv(kServiceProgramId, kUniform2RealLocation, _))
      .Times(1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GLES2Util::GetGLDataTypeSizeForUniforms(kUniform2Type),
            result->size);
}

TEST_P(GLES2DecoderWithShaderTest, GetUniformivArrayElementSucceeds) {
  GetUniformiv::Result* result =
      static_cast<GetUniformiv::Result*>(shared_memory_address_);
  result->size = 0;
  GetUniformiv cmd;
  cmd.Init(client_program_id_,
           kUniform2ElementFakeLocation,
           kSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_CALL(*gl_,
              GetUniformiv(kServiceProgramId, kUniform2ElementRealLocation, _))
      .Times(1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GLES2Util::GetGLDataTypeSizeForUniforms(kUniform2Type),
            result->size);
}

TEST_P(GLES2DecoderWithShaderTest, GetUniformivBadProgramFails) {
  GetUniformiv::Result* result =
      static_cast<GetUniformiv::Result*>(shared_memory_address_);
  result->size = 0;
  GetUniformiv cmd;
  // non-existant program
  cmd.Init(kInvalidClientId,
           kUniform2FakeLocation,
           kSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_CALL(*gl_, GetUniformiv(_, _, _)).Times(0);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0U, result->size);
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
// Valid id that is not a program. The GL spec requires a different error for
// this case.
#if GLES2_TEST_SHADER_VS_PROGRAM_IDS
  result->size = kInitialResult;
  cmd.Init(client_shader_id_,
           kUniform2FakeLocation,
           kSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0U, result->size);
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
#endif  // GLES2_TEST_SHADER_VS_PROGRAM_IDS
  // Unlinked program
  EXPECT_CALL(*gl_, CreateProgram())
      .Times(1)
      .WillOnce(Return(kNewServiceId))
      .RetiresOnSaturation();
  CreateProgram cmd2;
  cmd2.Init(kNewClientId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  result->size = kInitialResult;
  cmd.Init(kNewClientId,
           kUniform2FakeLocation,
           kSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0U, result->size);
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, GetUniformivBadLocationFails) {
  GetUniformiv::Result* result =
      static_cast<GetUniformiv::Result*>(shared_memory_address_);
  result->size = 0;
  GetUniformiv cmd;
  // invalid location
  cmd.Init(client_program_id_,
           kInvalidUniformLocation,
           kSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_CALL(*gl_, GetUniformiv(_, _, _)).Times(0);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0U, result->size);
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, GetUniformivBadSharedMemoryFails) {
  GetUniformiv cmd;
  cmd.Init(client_program_id_,
           kUniform2FakeLocation,
           kInvalidSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_CALL(*gl_, GetUniformiv(_, _, _)).Times(0);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  cmd.Init(client_program_id_,
           kUniform2FakeLocation,
           kSharedMemoryId,
           kInvalidSharedMemoryOffset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
};

TEST_P(GLES2DecoderWithShaderTest, GetUniformfvSucceeds) {
  GetUniformfv::Result* result =
      static_cast<GetUniformfv::Result*>(shared_memory_address_);
  result->size = 0;
  GetUniformfv cmd;
  cmd.Init(client_program_id_,
           kUniform2FakeLocation,
           kSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_CALL(*gl_, GetUniformfv(kServiceProgramId, kUniform2RealLocation, _))
      .Times(1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GLES2Util::GetGLDataTypeSizeForUniforms(kUniform2Type),
            result->size);
}

TEST_P(GLES2DecoderWithShaderTest, GetUniformfvArrayElementSucceeds) {
  GetUniformfv::Result* result =
      static_cast<GetUniformfv::Result*>(shared_memory_address_);
  result->size = 0;
  GetUniformfv cmd;
  cmd.Init(client_program_id_,
           kUniform2ElementFakeLocation,
           kSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_CALL(*gl_,
              GetUniformfv(kServiceProgramId, kUniform2ElementRealLocation, _))
      .Times(1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GLES2Util::GetGLDataTypeSizeForUniforms(kUniform2Type),
            result->size);
}

TEST_P(GLES2DecoderWithShaderTest, GetUniformfvBadProgramFails) {
  GetUniformfv::Result* result =
      static_cast<GetUniformfv::Result*>(shared_memory_address_);
  result->size = 0;
  GetUniformfv cmd;
  // non-existant program
  cmd.Init(kInvalidClientId,
           kUniform2FakeLocation,
           kSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_CALL(*gl_, GetUniformfv(_, _, _)).Times(0);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0U, result->size);
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
// Valid id that is not a program. The GL spec requires a different error for
// this case.
#if GLES2_TEST_SHADER_VS_PROGRAM_IDS
  result->size = kInitialResult;
  cmd.Init(client_shader_id_,
           kUniform2FakeLocation,
           kSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0U, result->size);
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
#endif  // GLES2_TEST_SHADER_VS_PROGRAM_IDS
  // Unlinked program
  EXPECT_CALL(*gl_, CreateProgram())
      .Times(1)
      .WillOnce(Return(kNewServiceId))
      .RetiresOnSaturation();
  CreateProgram cmd2;
  cmd2.Init(kNewClientId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  result->size = kInitialResult;
  cmd.Init(kNewClientId,
           kUniform2FakeLocation,
           kSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0U, result->size);
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, GetUniformfvBadLocationFails) {
  GetUniformfv::Result* result =
      static_cast<GetUniformfv::Result*>(shared_memory_address_);
  result->size = 0;
  GetUniformfv cmd;
  // invalid location
  cmd.Init(client_program_id_,
           kInvalidUniformLocation,
           kSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_CALL(*gl_, GetUniformfv(_, _, _)).Times(0);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0U, result->size);
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, GetUniformfvBadSharedMemoryFails) {
  GetUniformfv cmd;
  cmd.Init(client_program_id_,
           kUniform2FakeLocation,
           kInvalidSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_CALL(*gl_, GetUniformfv(_, _, _)).Times(0);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  cmd.Init(client_program_id_,
           kUniform2FakeLocation,
           kSharedMemoryId,
           kInvalidSharedMemoryOffset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
};

TEST_P(GLES2DecoderWithShaderTest, GetAttachedShadersSucceeds) {
  GetAttachedShaders cmd;
  typedef GetAttachedShaders::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->size = 0;
  EXPECT_CALL(*gl_, GetAttachedShaders(kServiceProgramId, 1, _, _)).WillOnce(
      DoAll(SetArgPointee<2>(1), SetArgPointee<3>(kServiceShaderId)));
  cmd.Init(client_program_id_,
           shared_memory_id_,
           shared_memory_offset_,
           Result::ComputeSize(1));
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(1, result->GetNumResults());
  EXPECT_EQ(client_shader_id_, result->GetData()[0]);
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, GetAttachedShadersResultNotInitFail) {
  GetAttachedShaders cmd;
  typedef GetAttachedShaders::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->size = 1;
  EXPECT_CALL(*gl_, GetAttachedShaders(_, _, _, _)).Times(0);
  cmd.Init(client_program_id_,
           shared_memory_id_,
           shared_memory_offset_,
           Result::ComputeSize(1));
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetAttachedShadersBadProgramFails) {
  GetAttachedShaders cmd;
  typedef GetAttachedShaders::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->size = 0;
  EXPECT_CALL(*gl_, GetAttachedShaders(_, _, _, _)).Times(0);
  cmd.Init(kInvalidClientId,
           shared_memory_id_,
           shared_memory_offset_,
           Result::ComputeSize(1));
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0U, result->size);
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, GetAttachedShadersBadSharedMemoryFails) {
  GetAttachedShaders cmd;
  typedef GetAttachedShaders::Result Result;
  cmd.Init(client_program_id_,
           kInvalidSharedMemoryId,
           shared_memory_offset_,
           Result::ComputeSize(1));
  EXPECT_CALL(*gl_, GetAttachedShaders(_, _, _, _)).Times(0);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  cmd.Init(client_program_id_,
           shared_memory_id_,
           kInvalidSharedMemoryOffset,
           Result::ComputeSize(1));
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetShaderPrecisionFormatSucceeds) {
  ScopedGLImplementationSetter gl_impl(::gfx::kGLImplementationEGLGLES2);
  GetShaderPrecisionFormat cmd;
  typedef GetShaderPrecisionFormat::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->success = 0;
  const GLint range[2] = {62, 62};
  const GLint precision = 16;
  EXPECT_CALL(*gl_, GetShaderPrecisionFormat(_, _, _, _))
      .WillOnce(DoAll(SetArrayArgument<2>(range, range + 2),
                      SetArgPointee<3>(precision)))
      .RetiresOnSaturation();
  cmd.Init(GL_VERTEX_SHADER,
           GL_HIGH_FLOAT,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_NE(0, result->success);
  EXPECT_EQ(range[0], result->min_range);
  EXPECT_EQ(range[1], result->max_range);
  EXPECT_EQ(precision, result->precision);
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, GetShaderPrecisionFormatResultNotInitFails) {
  GetShaderPrecisionFormat cmd;
  typedef GetShaderPrecisionFormat::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->success = 1;
  // NOTE: GL might not be called. There is no Desktop OpenGL equivalent
  cmd.Init(GL_VERTEX_SHADER,
           GL_HIGH_FLOAT,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetShaderPrecisionFormatBadArgsFails) {
  typedef GetShaderPrecisionFormat::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->success = 0;
  GetShaderPrecisionFormat cmd;
  cmd.Init(
      GL_TEXTURE_2D, GL_HIGH_FLOAT, shared_memory_id_, shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());
  result->success = 0;
  cmd.Init(GL_VERTEX_SHADER,
           GL_TEXTURE_2D,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest,
       GetShaderPrecisionFormatBadSharedMemoryFails) {
  GetShaderPrecisionFormat cmd;
  cmd.Init(GL_VERTEX_SHADER,
           GL_HIGH_FLOAT,
           kInvalidSharedMemoryId,
           shared_memory_offset_);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  cmd.Init(GL_VERTEX_SHADER,
           GL_TEXTURE_2D,
           shared_memory_id_,
           kInvalidSharedMemoryOffset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetActiveUniformSucceeds) {
  const GLuint kUniformIndex = 1;
  const uint32 kBucketId = 123;
  GetActiveUniform cmd;
  typedef GetActiveUniform::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->success = 0;
  cmd.Init(client_program_id_,
           kUniformIndex,
           kBucketId,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_NE(0, result->success);
  EXPECT_EQ(kUniform2Size, result->size);
  EXPECT_EQ(kUniform2Type, result->type);
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  CommonDecoder::Bucket* bucket = decoder_->GetBucket(kBucketId);
  ASSERT_TRUE(bucket != NULL);
  EXPECT_EQ(
      0,
      memcmp(
          bucket->GetData(0, bucket->size()), kUniform2Name, bucket->size()));
}

TEST_P(GLES2DecoderWithShaderTest, GetActiveUniformResultNotInitFails) {
  const GLuint kUniformIndex = 1;
  const uint32 kBucketId = 123;
  GetActiveUniform cmd;
  typedef GetActiveUniform::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->success = 1;
  cmd.Init(client_program_id_,
           kUniformIndex,
           kBucketId,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetActiveUniformBadProgramFails) {
  const GLuint kUniformIndex = 1;
  const uint32 kBucketId = 123;
  GetActiveUniform cmd;
  typedef GetActiveUniform::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->success = 0;
  cmd.Init(kInvalidClientId,
           kUniformIndex,
           kBucketId,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0, result->success);
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
#if GLES2_TEST_SHADER_VS_PROGRAM_IDS
  result->success = 0;
  cmd.Init(client_shader_id_,
           kUniformIndex,
           kBucketId,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0, result->success);
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
#endif  // GLES2_TEST_SHADER_VS_PROGRAM_IDS
}

TEST_P(GLES2DecoderWithShaderTest, GetActiveUniformBadIndexFails) {
  const uint32 kBucketId = 123;
  GetActiveUniform cmd;
  typedef GetActiveUniform::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->success = 0;
  cmd.Init(client_program_id_,
           kBadUniformIndex,
           kBucketId,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0, result->success);
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, GetActiveUniformBadSharedMemoryFails) {
  const GLuint kUniformIndex = 1;
  const uint32 kBucketId = 123;
  GetActiveUniform cmd;
  cmd.Init(client_program_id_,
           kUniformIndex,
           kBucketId,
           kInvalidSharedMemoryId,
           shared_memory_offset_);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  cmd.Init(client_program_id_,
           kUniformIndex,
           kBucketId,
           shared_memory_id_,
           kInvalidSharedMemoryOffset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetActiveUniformBlockNameSucceeds) {
  const uint32 kBucketId = 123;
  GetActiveUniformBlockName cmd;
  typedef GetActiveUniformBlockName::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  *result = 0;
  cmd.Init(client_program_id_,
           0,
           kBucketId,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_CALL(*gl_, GetProgramiv(kServiceProgramId, GL_LINK_STATUS, _))
      .WillOnce(SetArgPointee<2>(GL_TRUE))
      .RetiresOnSaturation();
  const char kName[] = "HolyCow";
  const GLsizei kMaxLength = strlen(kName) + 1;
  EXPECT_CALL(*gl_,
              GetProgramiv(kServiceProgramId,
                           GL_ACTIVE_UNIFORM_BLOCK_MAX_NAME_LENGTH, _))
      .WillOnce(SetArgPointee<2>(kMaxLength))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_,
              GetActiveUniformBlockName(kServiceProgramId, 0, _, _, _))
      .WillOnce(DoAll(SetArgPointee<3>(strlen(kName)),
                      SetArrayArgument<4>(kName, kName + strlen(kName) + 1)))
      .RetiresOnSaturation();
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_NE(0, *result);
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  CommonDecoder::Bucket* bucket = decoder_->GetBucket(kBucketId);
  ASSERT_TRUE(bucket != NULL);
  EXPECT_EQ(0,
            memcmp(bucket->GetData(0, bucket->size()), kName, bucket->size()));
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetActiveUniformBlockNameUnlinkedProgram) {
  const uint32 kBucketId = 123;
  GetActiveUniformBlockName cmd;
  typedef GetActiveUniformBlockName::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  *result = 0;
  cmd.Init(client_program_id_,
           0,
           kBucketId,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_CALL(*gl_, GetProgramiv(kServiceProgramId, GL_LINK_STATUS, _))
      .WillOnce(SetArgPointee<2>(GL_FALSE))
      .RetiresOnSaturation();
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0, *result);
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest,
       GetActiveUniformBlockNameResultNotInitFails) {
  const uint32 kBucketId = 123;
  GetActiveUniformBlockName cmd;
  typedef GetActiveUniformBlockName::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  *result = 1;
  cmd.Init(client_program_id_,
           0,
           kBucketId,
           shared_memory_id_,
           shared_memory_offset_);
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetActiveUniformBlockNameBadProgramFails) {
  const uint32 kBucketId = 123;
  GetActiveUniformBlockName cmd;
  typedef GetActiveUniformBlockName::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  *result = 0;
  cmd.Init(kInvalidClientId,
           0,
           kBucketId,
           shared_memory_id_,
           shared_memory_offset_);
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0, *result);
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest,
       GetActiveUniformBlockNameBadSharedMemoryFails) {
  const uint32 kBucketId = 123;
  GetActiveUniformBlockName cmd;
  decoder_->set_unsafe_es3_apis_enabled(true);
  cmd.Init(client_program_id_,
           0,
           kBucketId,
           kInvalidSharedMemoryId,
           shared_memory_offset_);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  cmd.Init(client_program_id_,
           0,
           kBucketId,
           shared_memory_id_,
           kInvalidSharedMemoryOffset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetActiveUniformBlockivSucceeds) {
  GetActiveUniformBlockiv cmd;
  typedef GetActiveUniformBlockiv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  GLenum kPname[] {
    GL_UNIFORM_BLOCK_BINDING,
    GL_UNIFORM_BLOCK_DATA_SIZE,
    GL_UNIFORM_BLOCK_NAME_LENGTH,
    GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS,
    GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES,
    GL_UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER,
    GL_UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER,
  };
  for (size_t ii = 0; ii < arraysize(kPname); ++ii) {
    result->SetNumResults(0);
    cmd.Init(client_program_id_,
             0,
             kPname[ii],
             shared_memory_id_,
             shared_memory_offset_);
    EXPECT_CALL(*gl_, GetError())
        .WillOnce(Return(GL_NO_ERROR))
        .WillOnce(Return(GL_NO_ERROR))
        .RetiresOnSaturation();
    EXPECT_CALL(*gl_, GetProgramiv(kServiceProgramId, GL_LINK_STATUS, _))
        .WillOnce(SetArgPointee<2>(GL_TRUE))
        .RetiresOnSaturation();
    if (kPname[ii] == GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES) {
      EXPECT_CALL(*gl_, GetError())
          .WillOnce(Return(GL_NO_ERROR))
          .RetiresOnSaturation();
      EXPECT_CALL(*gl_,
                  GetActiveUniformBlockiv(kServiceProgramId, 0,
                      GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS, _))
          .WillOnce(SetArgPointee<3>(1))
          .RetiresOnSaturation();
    }
    EXPECT_CALL(*gl_,
                GetActiveUniformBlockiv(
                    kServiceProgramId, 0, kPname[ii], _))
        .WillOnce(SetArgPointee<3>(1976))
        .RetiresOnSaturation();
    decoder_->set_unsafe_es3_apis_enabled(true);
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
    EXPECT_EQ(1, result->GetNumResults());
    EXPECT_EQ(GL_NO_ERROR, GetGLError());
    EXPECT_EQ(1976, result->GetData()[0]);
    decoder_->set_unsafe_es3_apis_enabled(false);
    EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));
  }
}

TEST_P(GLES2DecoderWithShaderTest,
       GetActiveUniformBlockivSucceedsZeroUniforms) {
  GetActiveUniformBlockiv cmd;
  typedef GetActiveUniformBlockiv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->SetNumResults(0);
  cmd.Init(client_program_id_,
           0,
           GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetProgramiv(kServiceProgramId, GL_LINK_STATUS, _))
      .WillOnce(SetArgPointee<2>(GL_TRUE))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_,
              GetActiveUniformBlockiv(
                  kServiceProgramId, 0, GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS, _))
      .WillOnce(SetArgPointee<3>(0))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_,
              GetActiveUniformBlockiv(kServiceProgramId, 0,
                  GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES, _))
      .Times(1)
      .RetiresOnSaturation();
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0, result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, GetActiveUniformBlockivUnlinkedProgram) {
  GetActiveUniformBlockiv cmd;
  typedef GetActiveUniformBlockiv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->SetNumResults(0);
  cmd.Init(client_program_id_,
           0,
           GL_UNIFORM_BLOCK_BINDING,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_CALL(*gl_, GetProgramiv(kServiceProgramId, GL_LINK_STATUS, _))
      .WillOnce(SetArgPointee<2>(GL_FALSE))
      .RetiresOnSaturation();
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0, result->GetNumResults());
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest,
       GetActiveUniformBlockivResultNotInitFails) {
  GetActiveUniformBlockiv cmd;
  typedef GetActiveUniformBlockiv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->SetNumResults(1);  // Should be initialized to 0.
  cmd.Init(client_program_id_,
           0,
           GL_UNIFORM_BLOCK_BINDING,
           shared_memory_id_,
           shared_memory_offset_);
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_CALL(*gl_, GetProgramiv(kServiceProgramId, GL_LINK_STATUS, _))
      .WillOnce(SetArgPointee<2>(GL_TRUE))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetActiveUniformBlockivBadProgramFails) {
  GetActiveUniformBlockiv cmd;
  typedef GetActiveUniformBlockiv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->SetNumResults(0);
  cmd.Init(kInvalidClientId,
           0,
           GL_UNIFORM_BLOCK_BINDING,
           shared_memory_id_,
           shared_memory_offset_);
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0, result->GetNumResults());
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest,
       GetActiveUniformBlockivBadSharedMemoryFails) {
  GetActiveUniformBlockiv cmd;
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_CALL(*gl_, GetProgramiv(kServiceProgramId, GL_LINK_STATUS, _))
      .WillOnce(SetArgPointee<2>(GL_TRUE))
      .WillOnce(SetArgPointee<2>(GL_TRUE))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  cmd.Init(client_program_id_,
           0,
           GL_UNIFORM_BLOCK_BINDING,
           kInvalidSharedMemoryId,
           shared_memory_offset_);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  cmd.Init(client_program_id_,
           0,
           GL_UNIFORM_BLOCK_BINDING,
           shared_memory_id_,
           kInvalidSharedMemoryOffset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetActiveAttribSucceeds) {
  const GLuint kAttribIndex = 1;
  const uint32 kBucketId = 123;
  GetActiveAttrib cmd;
  typedef GetActiveAttrib::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->success = 0;
  cmd.Init(client_program_id_,
           kAttribIndex,
           kBucketId,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_NE(0, result->success);
  EXPECT_EQ(kAttrib2Size, result->size);
  EXPECT_EQ(kAttrib2Type, result->type);
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  CommonDecoder::Bucket* bucket = decoder_->GetBucket(kBucketId);
  ASSERT_TRUE(bucket != NULL);
  EXPECT_EQ(
      0,
      memcmp(bucket->GetData(0, bucket->size()), kAttrib2Name, bucket->size()));
}

TEST_P(GLES2DecoderWithShaderTest, GetActiveAttribResultNotInitFails) {
  const GLuint kAttribIndex = 1;
  const uint32 kBucketId = 123;
  GetActiveAttrib cmd;
  typedef GetActiveAttrib::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->success = 1;
  cmd.Init(client_program_id_,
           kAttribIndex,
           kBucketId,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetActiveAttribBadProgramFails) {
  const GLuint kAttribIndex = 1;
  const uint32 kBucketId = 123;
  GetActiveAttrib cmd;
  typedef GetActiveAttrib::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->success = 0;
  cmd.Init(kInvalidClientId,
           kAttribIndex,
           kBucketId,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0, result->success);
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
#if GLES2_TEST_SHADER_VS_PROGRAM_IDS
  result->success = 0;
  cmd.Init(client_shader_id_,
           kAttribIndex,
           kBucketId,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0, result->success);
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
#endif  // GLES2_TEST_SHADER_VS_PROGRAM_IDS
}

TEST_P(GLES2DecoderWithShaderTest, GetActiveAttribBadIndexFails) {
  const uint32 kBucketId = 123;
  GetActiveAttrib cmd;
  typedef GetActiveAttrib::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->success = 0;
  cmd.Init(client_program_id_,
           kBadAttribIndex,
           kBucketId,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0, result->success);
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, GetActiveAttribBadSharedMemoryFails) {
  const GLuint kAttribIndex = 1;
  const uint32 kBucketId = 123;
  GetActiveAttrib cmd;
  cmd.Init(client_program_id_,
           kAttribIndex,
           kBucketId,
           kInvalidSharedMemoryId,
           shared_memory_offset_);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  cmd.Init(client_program_id_,
           kAttribIndex,
           kBucketId,
           shared_memory_id_,
           kInvalidSharedMemoryOffset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetUniformIndicesSucceeds) {
  const uint32 kBucketId = 123;
  const char kName0[] = "Cow";
  const char kName1[] = "Chicken";
  const char* kNames[] = { kName0, kName1 };
  const size_t kCount = arraysize(kNames);
  const char kValidStrEnd = 0;
  const GLuint kIndices[] = { 1, 2 };
  SetBucketAsCStrings(kBucketId, kCount, kNames, kCount, kValidStrEnd);
  GetUniformIndices::Result* result =
      static_cast<GetUniformIndices::Result*>(shared_memory_address_);
  GetUniformIndices cmd;
  cmd.Init(client_program_id_,
           kBucketId,
           kSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_CALL(*gl_, GetUniformIndices(kServiceProgramId, kCount, _, _))
      .WillOnce(SetArrayArgument<3>(kIndices, kIndices + kCount))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetProgramiv(kServiceProgramId, GL_LINK_STATUS, _))
      .WillOnce(SetArgPointee<2>(GL_TRUE))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  decoder_->set_unsafe_es3_apis_enabled(true);
  result->size = 0;
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(kCount, static_cast<size_t>(result->GetNumResults()));
  for (size_t ii = 0; ii < kCount; ++ii) {
    EXPECT_EQ(kIndices[ii], result->GetData()[ii]);
  }
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetUniformIndicesBadProgramFails) {
  const uint32 kBucketId = 123;
  const char kName0[] = "Cow";
  const char kName1[] = "Chicken";
  const char* kNames[] = { kName0, kName1 };
  const size_t kCount = arraysize(kNames);
  const char kValidStrEnd = 0;
  SetBucketAsCStrings(kBucketId, kCount, kNames, kCount, kValidStrEnd);
  GetUniformIndices::Result* result =
      static_cast<GetUniformIndices::Result*>(shared_memory_address_);
  decoder_->set_unsafe_es3_apis_enabled(true);
  GetUniformIndices cmd;
  // None-existant program
  cmd.Init(kInvalidClientId,
           kBucketId,
           kSharedMemoryId,
           kSharedMemoryOffset);
  result->size = 0;
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0, result->GetNumResults());
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  // Unlinked program.
  EXPECT_CALL(*gl_, GetProgramiv(kServiceProgramId, GL_LINK_STATUS, _))
      .WillOnce(SetArgPointee<2>(GL_FALSE))
      .RetiresOnSaturation();
  cmd.Init(client_program_id_,
           kBucketId,
           kSharedMemoryId,
           kSharedMemoryOffset);
  result->size = 0;
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0, result->GetNumResults());
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, GetUniformIndicesBadParamsFails) {
  const uint32 kBucketId = 123;
  const char kName0[] = "Cow";
  const char kName1[] = "Chicken";
  const char* kNames[] = { kName0, kName1 };
  const size_t kCount = arraysize(kNames);
  const char kValidStrEnd = 0;
  const GLuint kIndices[] = { 1, 2 };
  SetBucketAsCStrings(kBucketId, kCount, kNames, kCount, kValidStrEnd);
  GetUniformIndices::Result* result =
      static_cast<GetUniformIndices::Result*>(shared_memory_address_);
  GetUniformIndices cmd;
  cmd.Init(client_program_id_,
           kBucketId,
           kSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_CALL(*gl_, GetUniformIndices(kServiceProgramId, kCount, _, _))
      .WillOnce(SetArrayArgument<3>(kIndices, kIndices + kCount))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetProgramiv(kServiceProgramId, GL_LINK_STATUS, _))
      .WillOnce(SetArgPointee<2>(GL_TRUE))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_INVALID_VALUE))
      .RetiresOnSaturation();
  decoder_->set_unsafe_es3_apis_enabled(true);
  result->size = 0;
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0, result->GetNumResults());
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, GetUniformIndicesResultNotInitFails) {
  const uint32 kBucketId = 123;
  const char kName0[] = "Cow";
  const char kName1[] = "Chicken";
  const char* kNames[] = { kName0, kName1 };
  const size_t kCount = arraysize(kNames);
  const char kValidStrEnd = 0;
  SetBucketAsCStrings(kBucketId, kCount, kNames, kCount, kValidStrEnd);
  GetUniformIndices::Result* result =
      static_cast<GetUniformIndices::Result*>(shared_memory_address_);
  decoder_->set_unsafe_es3_apis_enabled(true);
  GetUniformIndices cmd;
  result->size = 1976;  // Any value other than 0.
  cmd.Init(kInvalidClientId,
           kBucketId,
           kSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetUniformIndicesBadSharedMemoryFails) {
  const uint32 kBucketId = 123;
  const char kName0[] = "Cow";
  const char kName1[] = "Chicken";
  const char* kNames[] = { kName0, kName1 };
  const size_t kCount = arraysize(kNames);
  const char kValidStrEnd = 0;
  SetBucketAsCStrings(kBucketId, kCount, kNames, kCount, kValidStrEnd);
  GetUniformIndices::Result* result =
      static_cast<GetUniformIndices::Result*>(shared_memory_address_);
  decoder_->set_unsafe_es3_apis_enabled(true);
  GetUniformIndices cmd;
  cmd.Init(client_program_id_,
           kBucketId,
           kInvalidSharedMemoryId,
           kSharedMemoryOffset);
  result->size = 0;
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  cmd.Init(client_program_id_,
           kBucketId,
           kSharedMemoryId,
           kInvalidSharedMemoryOffset);
  result->size = 0;
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetActiveUniformsivSucceeds) {
  const uint32 kBucketId = 123;
  const GLuint kIndices[] = { 1, 2 };
  const GLint kResults[] = { 1976, 321 };
  const size_t kCount = arraysize(kIndices);
  SetBucketData(kBucketId, kIndices, sizeof(GLuint) * kCount);
  GetActiveUniformsiv::Result* result =
      static_cast<GetActiveUniformsiv::Result*>(shared_memory_address_);
  GetActiveUniformsiv cmd;
  cmd.Init(client_program_id_,
           kBucketId,
           GL_UNIFORM_TYPE,
           kSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_CALL(*gl_,
              GetActiveUniformsiv(
                  kServiceProgramId, kCount, _, GL_UNIFORM_TYPE, _))
      .WillOnce(SetArrayArgument<4>(kResults, kResults + kCount))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetProgramiv(kServiceProgramId, GL_LINK_STATUS, _))
      .WillOnce(SetArgPointee<2>(GL_TRUE))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  decoder_->set_unsafe_es3_apis_enabled(true);
  result->size = 0;
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(kCount, static_cast<size_t>(result->GetNumResults()));
  for (size_t ii = 0; ii < kCount; ++ii) {
    EXPECT_EQ(kResults[ii], result->GetData()[ii]);
  }
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetActiveUniformsivBadProgramFails) {
  const uint32 kBucketId = 123;
  const GLuint kIndices[] = { 1, 2 };
  const size_t kCount = arraysize(kIndices);
  SetBucketData(kBucketId, kIndices, sizeof(GLuint) * kCount);
  GetActiveUniformsiv::Result* result =
      static_cast<GetActiveUniformsiv::Result*>(shared_memory_address_);
  decoder_->set_unsafe_es3_apis_enabled(true);
  GetActiveUniformsiv cmd;
  // None-existant program
  cmd.Init(kInvalidClientId,
           kBucketId,
           GL_UNIFORM_TYPE,
           kSharedMemoryId,
           kSharedMemoryOffset);
  result->size = 0;
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0, result->GetNumResults());
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  // Unlinked program.
  cmd.Init(client_program_id_,
           kBucketId,
           GL_UNIFORM_TYPE,
           kSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_CALL(*gl_, GetProgramiv(kServiceProgramId, GL_LINK_STATUS, _))
      .WillOnce(SetArgPointee<2>(GL_FALSE))
      .RetiresOnSaturation();
  result->size = 0;
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0, result->GetNumResults());
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, GetActiveUniformsivBadParamsFails) {
  const uint32 kBucketId = 123;
  const GLuint kIndices[] = { 1, 2 };
  const GLint kResults[] = { 1976, 321 };
  const size_t kCount = arraysize(kIndices);
  SetBucketData(kBucketId, kIndices, sizeof(GLuint) * kCount);
  GetActiveUniformsiv::Result* result =
      static_cast<GetActiveUniformsiv::Result*>(shared_memory_address_);
  GetActiveUniformsiv cmd;
  cmd.Init(client_program_id_,
           kBucketId,
           GL_UNIFORM_TYPE,
           kSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_CALL(*gl_,
              GetActiveUniformsiv(
                  kServiceProgramId, kCount, _, GL_UNIFORM_TYPE, _))
      .WillOnce(SetArrayArgument<4>(kResults, kResults + kCount))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetProgramiv(kServiceProgramId, GL_LINK_STATUS, _))
      .WillOnce(SetArgPointee<2>(GL_TRUE))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_INVALID_VALUE))
      .RetiresOnSaturation();
  decoder_->set_unsafe_es3_apis_enabled(true);
  result->size = 0;
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0, result->GetNumResults());
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, GetActiveUniformsivResultNotInitFails) {
  const uint32 kBucketId = 123;
  const GLuint kIndices[] = { 1, 2 };
  const size_t kCount = arraysize(kIndices);
  SetBucketData(kBucketId, kIndices, sizeof(GLuint) * kCount);
  GetActiveUniformsiv::Result* result =
      static_cast<GetActiveUniformsiv::Result*>(shared_memory_address_);
  GetActiveUniformsiv cmd;
  cmd.Init(client_program_id_,
           kBucketId,
           GL_UNIFORM_TYPE,
           kSharedMemoryId,
           kSharedMemoryOffset);
  decoder_->set_unsafe_es3_apis_enabled(true);
  result->size = 1976;  // Any value other than 0.
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetActiveUniformsivBadSharedMemoryFails) {
  const uint32 kBucketId = 123;
  const GLuint kIndices[] = { 1, 2 };
  const size_t kCount = arraysize(kIndices);
  SetBucketData(kBucketId, kIndices, sizeof(GLuint) * kCount);
  GetActiveUniformsiv::Result* result =
      static_cast<GetActiveUniformsiv::Result*>(shared_memory_address_);
  GetActiveUniformsiv cmd;
  decoder_->set_unsafe_es3_apis_enabled(true);
  result->size = 0;
  cmd.Init(client_program_id_,
           kBucketId,
           GL_UNIFORM_TYPE,
           kInvalidSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  result->size = 0;
  cmd.Init(client_program_id_,
           kBucketId,
           GL_UNIFORM_TYPE,
           kSharedMemoryId,
           kInvalidSharedMemoryOffset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetShaderInfoLogValidArgs) {
  const char* kInfo = "hello";
  const uint32 kBucketId = 123;
  CompileShader compile_cmd;
  GetShaderInfoLog cmd;
  EXPECT_CALL(*gl_, ShaderSource(kServiceShaderId, 1, _, _));
  EXPECT_CALL(*gl_, CompileShader(kServiceShaderId));
  EXPECT_CALL(*gl_, GetShaderiv(kServiceShaderId, GL_COMPILE_STATUS, _))
      .WillOnce(SetArgPointee<2>(GL_FALSE))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetShaderiv(kServiceShaderId, GL_INFO_LOG_LENGTH, _))
      .WillOnce(SetArgPointee<2>(strlen(kInfo) + 1))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetShaderInfoLog(kServiceShaderId, strlen(kInfo) + 1, _, _))
      .WillOnce(DoAll(SetArgPointee<2>(strlen(kInfo)),
                      SetArrayArgument<3>(kInfo, kInfo + strlen(kInfo) + 1)));
  compile_cmd.Init(client_shader_id_);
  cmd.Init(client_shader_id_, kBucketId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(compile_cmd));
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  CommonDecoder::Bucket* bucket = decoder_->GetBucket(kBucketId);
  ASSERT_TRUE(bucket != NULL);
  EXPECT_EQ(strlen(kInfo) + 1, bucket->size());
  EXPECT_EQ(0,
            memcmp(bucket->GetData(0, bucket->size()), kInfo, bucket->size()));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, GetShaderInfoLogInvalidArgs) {
  const uint32 kBucketId = 123;
  GetShaderInfoLog cmd;
  cmd.Init(kInvalidClientId, kBucketId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, GetTransformFeedbackVaryingSucceeds) {
  const GLuint kIndex = 1;
  const uint32 kBucketId = 123;
  const char kName[] = "HolyCow";
  const GLsizei kBufferSize = static_cast<GLsizei>(strlen(kName) + 1);
  const GLsizei kSize = 2;
  const GLenum kType = GL_FLOAT_VEC2;
  GetTransformFeedbackVarying cmd;
  typedef GetTransformFeedbackVarying::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->success = 0;
  EXPECT_CALL(*gl_, GetProgramiv(kServiceProgramId, GL_LINK_STATUS, _))
      .WillOnce(SetArgPointee<2>(GL_TRUE))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetProgramiv(kServiceProgramId,
                                 GL_TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH, _))
      .WillOnce(SetArgPointee<2>(kBufferSize))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_,
              GetTransformFeedbackVarying(
                  kServiceProgramId, kIndex, _, _, _, _, _))
      .WillOnce(DoAll(SetArgPointee<3>(kBufferSize - 1),
                      SetArgPointee<4>(kSize),
                      SetArgPointee<5>(kType),
                      SetArrayArgument<6>(kName, kName + kBufferSize)))
      .RetiresOnSaturation();
  cmd.Init(client_program_id_,
           kIndex,
           kBucketId,
           shared_memory_id_,
           shared_memory_offset_);
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_NE(0, result->success);
  EXPECT_EQ(kSize, static_cast<GLsizei>(result->size));
  EXPECT_EQ(kType, static_cast<GLenum>(result->type));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  CommonDecoder::Bucket* bucket = decoder_->GetBucket(kBucketId);
  ASSERT_TRUE(bucket != NULL);
  EXPECT_EQ(
      0, memcmp(bucket->GetData(0, bucket->size()), kName, bucket->size()));
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetTransformFeedbackVaryingNotInitFails) {
  const GLuint kIndex = 1;
  const uint32 kBucketId = 123;
  GetTransformFeedbackVarying cmd;
  typedef GetTransformFeedbackVarying::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->success = 1;
  cmd.Init(client_program_id_,
           kIndex,
           kBucketId,
           shared_memory_id_,
           shared_memory_offset_);
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetTransformFeedbackVaryingBadProgramFails) {
  const GLuint kIndex = 1;
  const uint32 kBucketId = 123;
  GetTransformFeedbackVarying cmd;
  typedef GetTransformFeedbackVarying::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->success = 0;
  cmd.Init(kInvalidClientId,
           kIndex,
           kBucketId,
           shared_memory_id_,
           shared_memory_offset_);
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0, result->success);
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, GetTransformFeedbackVaryingBadParamsFails) {
  const GLuint kIndex = 1;
  const uint32 kBucketId = 123;
  const GLsizei kBufferSize = 10;
  GetTransformFeedbackVarying cmd;
  typedef GetTransformFeedbackVarying::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->success = 0;
  cmd.Init(client_program_id_,
           kIndex,
           kBucketId,
           shared_memory_id_,
           shared_memory_offset_);
  EXPECT_CALL(*gl_, GetProgramiv(kServiceProgramId, GL_LINK_STATUS, _))
      .WillOnce(SetArgPointee<2>(GL_TRUE))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetProgramiv(kServiceProgramId,
                                 GL_TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH, _))
      .WillOnce(SetArgPointee<2>(kBufferSize))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_INVALID_VALUE))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_,
              GetTransformFeedbackVarying(
                  kServiceProgramId, kIndex, _, _, _, _, _))
      .Times(1)
      .RetiresOnSaturation();
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(0, result->success);
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest,
       GetTransformFeedbackVaryingBadSharedMemoryFails) {
  const GLuint kIndex = 1;
  const uint32 kBucketId = 123;
  GetTransformFeedbackVarying cmd;
  typedef GetTransformFeedbackVarying::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  result->success = 0;
  decoder_->set_unsafe_es3_apis_enabled(true);
  cmd.Init(client_program_id_,
           kIndex,
           kBucketId,
           kInvalidSharedMemoryId,
           shared_memory_offset_);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  cmd.Init(client_program_id_,
           kIndex,
           kBucketId,
           shared_memory_id_,
           kInvalidSharedMemoryOffset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderTest, CompileShaderValidArgs) {
  // Compile shader should not actually call any GL calls yet.
  CompileShader cmd;
  cmd.Init(client_shader_id_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));

  // Getting the shader compilation state should trigger the actual GL calls.
  EXPECT_CALL(*gl_, ShaderSource(kServiceShaderId, 1, _, _));
  EXPECT_CALL(*gl_, CompileShader(kServiceShaderId));
  EXPECT_CALL(*gl_, GetShaderiv(kServiceShaderId, GL_COMPILE_STATUS, _))
      .WillOnce(SetArgPointee<2>(GL_TRUE))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetError())
        .WillOnce(Return(GL_NO_ERROR))
        .WillOnce(Return(GL_NO_ERROR))
        .RetiresOnSaturation();

  GetShaderiv status_cmd;
  status_cmd.Init(client_shader_id_, GL_COMPILE_STATUS,
                  kSharedMemoryId, kSharedMemoryOffset);
  EXPECT_EQ(error::kNoError, ExecuteCmd(status_cmd));
}

TEST_P(GLES2DecoderTest, CompileShaderInvalidArgs) {
  CompileShader cmd;
  cmd.Init(kInvalidClientId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
#if GLES2_TEST_SHADER_VS_PROGRAM_IDS
  cmd.Init(client_program_id_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
#endif  // GLES2_TEST_SHADER_VS_PROGRAM_IDS
}

TEST_P(GLES2DecoderTest, ShaderSourceBucketAndGetShaderSourceValidArgs) {
  const uint32 kInBucketId = 123;
  const uint32 kOutBucketId = 125;
  const char kSource0[] = "hello";
  const char* kSource[] = { kSource0 };
  const char kValidStrEnd = 0;
  SetBucketAsCStrings(kInBucketId, 1, kSource, 1, kValidStrEnd);
  ShaderSourceBucket cmd;
  cmd.Init(client_shader_id_, kInBucketId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  ClearSharedMemory();
  GetShaderSource get_cmd;
  get_cmd.Init(client_shader_id_, kOutBucketId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(get_cmd));
  CommonDecoder::Bucket* bucket = decoder_->GetBucket(kOutBucketId);
  ASSERT_TRUE(bucket != NULL);
  EXPECT_EQ(sizeof(kSource0), bucket->size());
  EXPECT_EQ(0, memcmp(bucket->GetData(0, bucket->size()),
                      kSource0, bucket->size()));
}

#if GLES2_TEST_SHADER_VS_PROGRAM_IDS
TEST_P(GLES2DecoderTest, ShaderSourceBucketWithProgramId) {
  const uint32 kBucketId = 123;
  const char kSource0[] = "hello";
  const char* kSource[] = { kSource0 };
  const char kValidStrEnd = 0;
  SetBucketAsCStrings(kBucketId, 1, kSource, 1, kValidStrEnd);
  ShaderSourceBucket cmd;
  cmd.Init(client_program_id_, kBucketId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}
#endif  // GLES2_TEST_SHADER_VS_PROGRAM_IDS

TEST_P(GLES2DecoderTest, ShaderSourceStripComments) {
  const uint32 kInBucketId = 123;
  const char kSource0[] = "hello/*te\ast*/world//a\ab";
  const char* kSource[] = { kSource0 };
  const char kValidStrEnd = 0;
  SetBucketAsCStrings(kInBucketId, 1, kSource, 1, kValidStrEnd);
  ShaderSourceBucket cmd;
  cmd.Init(client_shader_id_, kInBucketId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, Uniform1iValidArgs) {
  EXPECT_CALL(*gl_, Uniform1i(kUniform1RealLocation, 2));
  Uniform1i cmd;
  cmd.Init(kUniform1FakeLocation, 2);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, Uniform1ivImmediateValidArgs) {
  Uniform1ivImmediate& cmd = *GetImmediateAs<Uniform1ivImmediate>();
  EXPECT_CALL(*gl_,
              Uniform1iv(kUniform1RealLocation,
                         1,
                         reinterpret_cast<GLint*>(ImmediateDataAddress(&cmd))));
  GLint temp[1 * 2] = {
      0,
  };
  cmd.Init(kUniform1FakeLocation, 1, &temp[0]);
  EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(temp)));
}

TEST_P(GLES2DecoderWithShaderTest, Uniform1ivImmediateInvalidValidArgs) {
  EXPECT_CALL(*gl_, Uniform1iv(_, _, _)).Times(0);
  Uniform1ivImmediate& cmd = *GetImmediateAs<Uniform1ivImmediate>();
  GLint temp[1 * 2] = {
      0,
  };
  cmd.Init(kUniform1FakeLocation, 2, &temp[0]);
  EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(temp)));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, Uniform1ivZeroCount) {
  EXPECT_CALL(*gl_, Uniform1iv(_, _, _)).Times(0);
  Uniform1ivImmediate& cmd = *GetImmediateAs<Uniform1ivImmediate>();
  GLint temp = 0;
  cmd.Init(kUniform1FakeLocation, 0, &temp);
  EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(temp)));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, Uniform1iSamplerIsLmited) {
  EXPECT_CALL(*gl_, Uniform1i(_, _)).Times(0);
  Uniform1i cmd;
  cmd.Init(kUniform1FakeLocation, kNumTextureUnits);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, Uniform1ivSamplerIsLimited) {
  EXPECT_CALL(*gl_, Uniform1iv(_, _, _)).Times(0);
  Uniform1ivImmediate& cmd = *GetImmediateAs<Uniform1ivImmediate>();
  GLint temp[] = {kNumTextureUnits};
  cmd.Init(kUniform1FakeLocation, 1, &temp[0]);
  EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(temp)));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
}

TEST_P(GLES2DecoderTest, BindAttribLocationBucket) {
  const uint32 kBucketId = 123;
  const GLint kLocation = 2;
  const char* kName = "testing";
  EXPECT_CALL(*gl_,
              BindAttribLocation(kServiceProgramId, kLocation, StrEq(kName)))
      .Times(1);
  SetBucketAsCString(kBucketId, kName);
  BindAttribLocationBucket cmd;
  cmd.Init(client_program_id_, kLocation, kBucketId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderTest, BindAttribLocationBucketInvalidArgs) {
  const uint32 kBucketId = 123;
  const GLint kLocation = 2;
  const char* kName = "testing";
  EXPECT_CALL(*gl_, BindAttribLocation(_, _, _)).Times(0);
  BindAttribLocationBucket cmd;
  // check bucket does not exist.
  cmd.Init(client_program_id_, kLocation, kBucketId);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  // check bucket is empty.
  SetBucketAsCString(kBucketId, NULL);
  cmd.Init(client_program_id_, kLocation, kBucketId);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  // Check bad program id
  SetBucketAsCString(kBucketId, kName);
  cmd.Init(kInvalidClientId, kLocation, kBucketId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, GetAttribLocation) {
  const uint32 kBucketId = 123;
  const char* kNonExistentName = "foobar";
  typedef GetAttribLocation::Result Result;
  Result* result = GetSharedMemoryAs<Result*>();
  SetBucketAsCString(kBucketId, kAttrib2Name);
  *result = -1;
  GetAttribLocation cmd;
  cmd.Init(client_program_id_, kBucketId, kSharedMemoryId, kSharedMemoryOffset);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(kAttrib2Location, *result);
  SetBucketAsCString(kBucketId, kNonExistentName);
  *result = -1;
  cmd.Init(client_program_id_, kBucketId, kSharedMemoryId, kSharedMemoryOffset);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(-1, *result);
}

TEST_P(GLES2DecoderWithShaderTest, GetAttribLocationInvalidArgs) {
  const uint32 kBucketId = 123;
  typedef GetAttribLocation::Result Result;
  Result* result = GetSharedMemoryAs<Result*>();
  *result = -1;
  GetAttribLocation cmd;
  // Check no bucket
  cmd.Init(client_program_id_, kBucketId, kSharedMemoryId, kSharedMemoryOffset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(-1, *result);
  // Check bad program id.
  SetBucketAsCString(kBucketId, kAttrib2Name);
  cmd.Init(kInvalidClientId, kBucketId, kSharedMemoryId, kSharedMemoryOffset);
  *result = -1;
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(-1, *result);
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  // Check bad memory
  cmd.Init(client_program_id_,
           kBucketId,
           kInvalidSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  cmd.Init(client_program_id_,
           kBucketId,
           kSharedMemoryId,
           kInvalidSharedMemoryOffset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetFragDataLocation) {
  const uint32 kBucketId = 123;
  const GLint kLocation = 10;
  const char* kName = "color";
  typedef GetFragDataLocation::Result Result;
  Result* result = GetSharedMemoryAs<Result*>();
  SetBucketAsCString(kBucketId, kName);
  *result = -1;
  GetFragDataLocation cmd;
  cmd.Init(client_program_id_, kBucketId, kSharedMemoryId, kSharedMemoryOffset);
  EXPECT_CALL(*gl_, GetFragDataLocation(kServiceProgramId, StrEq(kName)))
      .WillOnce(Return(kLocation))
      .RetiresOnSaturation();
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(kLocation, *result);
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetFragDataLocationInvalidArgs) {
  const uint32 kBucketId = 123;
  typedef GetFragDataLocation::Result Result;
  Result* result = GetSharedMemoryAs<Result*>();
  *result = -1;
  GetFragDataLocation cmd;
  decoder_->set_unsafe_es3_apis_enabled(true);
  // Check no bucket
  cmd.Init(client_program_id_, kBucketId, kSharedMemoryId, kSharedMemoryOffset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(-1, *result);
  // Check bad program id.
  const char* kName = "color";
  SetBucketAsCString(kBucketId, kName);
  cmd.Init(kInvalidClientId, kBucketId, kSharedMemoryId, kSharedMemoryOffset);
  *result = -1;
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(-1, *result);
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  // Check bad memory
  cmd.Init(client_program_id_,
           kBucketId,
           kInvalidSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  cmd.Init(client_program_id_,
           kBucketId,
           kSharedMemoryId,
           kInvalidSharedMemoryOffset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetUniformBlockIndex) {
  const uint32 kBucketId = 123;
  const GLuint kIndex = 10;
  const char* kName = "color";
  typedef GetUniformBlockIndex::Result Result;
  Result* result = GetSharedMemoryAs<Result*>();
  SetBucketAsCString(kBucketId, kName);
  *result = GL_INVALID_INDEX;
  GetUniformBlockIndex cmd;
  cmd.Init(client_program_id_, kBucketId, kSharedMemoryId, kSharedMemoryOffset);
  EXPECT_CALL(*gl_, GetUniformBlockIndex(kServiceProgramId, StrEq(kName)))
      .WillOnce(Return(kIndex))
      .RetiresOnSaturation();
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(kIndex, *result);
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetUniformBlockIndexInvalidArgs) {
  const uint32 kBucketId = 123;
  typedef GetUniformBlockIndex::Result Result;
  Result* result = GetSharedMemoryAs<Result*>();
  *result = GL_INVALID_INDEX;
  GetUniformBlockIndex cmd;
  decoder_->set_unsafe_es3_apis_enabled(true);
  // Check no bucket
  cmd.Init(client_program_id_, kBucketId, kSharedMemoryId, kSharedMemoryOffset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_INDEX, *result);
  // Check bad program id.
  const char* kName = "color";
  SetBucketAsCString(kBucketId, kName);
  cmd.Init(kInvalidClientId, kBucketId, kSharedMemoryId, kSharedMemoryOffset);
  *result = GL_INVALID_INDEX;
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_INDEX, *result);
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  // Check bad memory
  cmd.Init(client_program_id_,
           kBucketId,
           kInvalidSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  cmd.Init(client_program_id_,
           kBucketId,
           kSharedMemoryId,
           kInvalidSharedMemoryOffset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, GetUniformLocation) {
  const uint32 kBucketId = 123;
  const char* kNonExistentName = "foobar";
  typedef GetUniformLocation::Result Result;
  Result* result = GetSharedMemoryAs<Result*>();
  SetBucketAsCString(kBucketId, kUniform2Name);
  *result = -1;
  GetUniformLocation cmd;
  cmd.Init(client_program_id_, kBucketId, kSharedMemoryId, kSharedMemoryOffset);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(kUniform2FakeLocation, *result);
  SetBucketAsCString(kBucketId, kNonExistentName);
  *result = -1;
  cmd.Init(client_program_id_, kBucketId, kSharedMemoryId, kSharedMemoryOffset);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(-1, *result);
}

TEST_P(GLES2DecoderWithShaderTest, GetUniformLocationInvalidArgs) {
  const uint32 kBucketId = 123;
  typedef GetUniformLocation::Result Result;
  Result* result = GetSharedMemoryAs<Result*>();
  *result = -1;
  GetUniformLocation cmd;
  // Check no bucket
  cmd.Init(client_program_id_, kBucketId, kSharedMemoryId, kSharedMemoryOffset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(-1, *result);
  // Check bad program id.
  SetBucketAsCString(kBucketId, kUniform2Name);
  cmd.Init(kInvalidClientId, kBucketId, kSharedMemoryId, kSharedMemoryOffset);
  *result = -1;
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(-1, *result);
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  // Check bad memory
  cmd.Init(client_program_id_,
           kBucketId,
           kInvalidSharedMemoryId,
           kSharedMemoryOffset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  cmd.Init(client_program_id_,
           kBucketId,
           kSharedMemoryId,
           kInvalidSharedMemoryOffset);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, UniformBlockBindingValidArgs) {
  EXPECT_CALL(*gl_, UniformBlockBinding(kServiceProgramId, 2, 3));
  SpecializedSetup<cmds::UniformBlockBinding, 0>(true);
  cmds::UniformBlockBinding cmd;
  cmd.Init(client_program_id_, 2, 3);
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest, BindUniformLocationCHROMIUMBucket) {
  const uint32 kBucketId = 123;
  const GLint kLocation = 2;
  const char* kName = "testing";
  const char* kBadName1 = "gl_testing";
  const char* kBadName2 = "testing[1]";

  SetBucketAsCString(kBucketId, kName);
  BindUniformLocationCHROMIUMBucket cmd;
  cmd.Init(client_program_id_,
           kLocation,
           kBucketId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  // check negative location
  SetBucketAsCString(kBucketId, kName);
  cmd.Init(client_program_id_, -1, kBucketId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  // check highest location
  SetBucketAsCString(kBucketId, kName);
  GLint kMaxLocation =
      (kMaxFragmentUniformVectors + kMaxVertexUniformVectors) * 4 - 1;
  cmd.Init(client_program_id_,
           kMaxLocation,
           kBucketId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  // check too high location
  SetBucketAsCString(kBucketId, kName);
  cmd.Init(client_program_id_,
           kMaxLocation + 1,
           kBucketId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  // check bad name "gl_..."
  SetBucketAsCString(kBucketId, kBadName1);
  cmd.Init(client_program_id_,
           kLocation,
           kBucketId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
  // check bad name "name[1]" non zero
  SetBucketAsCString(kBucketId, kBadName2);
  cmd.Init(client_program_id_,
           kLocation,
           kBucketId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
}

TEST_P(GLES2DecoderManualInitTest, ClearUniformsBeforeFirstProgramUse) {
  base::CommandLine command_line(0, NULL);
  command_line.AppendSwitchASCII(
      switches::kGpuDriverBugWorkarounds,
      base::IntToString(gpu::CLEAR_UNIFORMS_BEFORE_FIRST_PROGRAM_USE));
  InitState init;
  init.has_alpha = true;
  init.request_alpha = true;
  init.bind_generates_resource = true;
  InitDecoderWithCommandLine(init, &command_line);
  {
    static AttribInfo attribs[] = {
        {
         kAttrib1Name, kAttrib1Size, kAttrib1Type, kAttrib1Location,
        },
        {
         kAttrib2Name, kAttrib2Size, kAttrib2Type, kAttrib2Location,
        },
        {
         kAttrib3Name, kAttrib3Size, kAttrib3Type, kAttrib3Location,
        },
    };
    static UniformInfo uniforms[] = {
        {kUniform1Name, kUniform1Size, kUniform1Type, kUniform1FakeLocation,
         kUniform1RealLocation, kUniform1DesiredLocation},
        {kUniform2Name, kUniform2Size, kUniform2Type, kUniform2FakeLocation,
         kUniform2RealLocation, kUniform2DesiredLocation},
        {kUniform3Name, kUniform3Size, kUniform3Type, kUniform3FakeLocation,
         kUniform3RealLocation, kUniform3DesiredLocation},
    };
    SetupShader(attribs,
                arraysize(attribs),
                uniforms,
                arraysize(uniforms),
                client_program_id_,
                kServiceProgramId,
                client_vertex_shader_id_,
                kServiceVertexShaderId,
                client_fragment_shader_id_,
                kServiceFragmentShaderId);
    TestHelper::SetupExpectationsForClearingUniforms(
        gl_.get(), uniforms, arraysize(uniforms));
  }

  {
    EXPECT_CALL(*gl_, UseProgram(kServiceProgramId))
        .Times(1)
        .RetiresOnSaturation();
    cmds::UseProgram cmd;
    cmd.Init(client_program_id_);
    EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  }
}

// TODO(gman): DeleteProgram

// TODO(gman): UseProgram

// TODO(gman): DeleteShader

}  // namespace gles2
}  // namespace gpu
