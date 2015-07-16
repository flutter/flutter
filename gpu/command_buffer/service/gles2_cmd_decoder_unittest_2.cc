// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/gles2_cmd_decoder.h"

#include "gpu/command_buffer/common/gles2_cmd_format.h"
#include "gpu/command_buffer/common/gles2_cmd_utils.h"
#include "gpu/command_buffer/service/gles2_cmd_decoder_unittest_base.h"
#include "gpu/command_buffer/service/cmd_buffer_engine.h"
#include "gpu/command_buffer/service/context_group.h"
#include "gpu/command_buffer/service/program_manager.h"
#include "gpu/command_buffer/service/test_helper.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gl/gl_mock.h"

using ::gfx::MockGLInterface;
using ::testing::_;
using ::testing::AnyNumber;
using ::testing::DoAll;
using ::testing::InSequence;
using ::testing::MatcherCast;
using ::testing::Pointee;
using ::testing::Return;
using ::testing::SetArrayArgument;
using ::testing::SetArgumentPointee;
using ::testing::StrEq;

namespace gpu {
namespace gles2 {

class GLES2DecoderTest2 : public GLES2DecoderTestBase {
 public:
  GLES2DecoderTest2() { }

  void TestAcceptedUniform(GLenum uniform_type, uint32 accepts_apis) {
    SetupShaderForUniform(uniform_type);
    bool valid_uniform = false;

    EXPECT_CALL(*gl_, Uniform1i(1, _)).Times(AnyNumber());
    EXPECT_CALL(*gl_, Uniform1iv(1, _, _)).Times(AnyNumber());
    EXPECT_CALL(*gl_, Uniform2iv(1, _, _)).Times(AnyNumber());
    EXPECT_CALL(*gl_, Uniform3iv(1, _, _)).Times(AnyNumber());
    EXPECT_CALL(*gl_, Uniform4iv(1, _, _)).Times(AnyNumber());
    EXPECT_CALL(*gl_, Uniform1f(1, _)).Times(AnyNumber());
    EXPECT_CALL(*gl_, Uniform1fv(1, _, _)).Times(AnyNumber());
    EXPECT_CALL(*gl_, Uniform2fv(1, _, _)).Times(AnyNumber());
    EXPECT_CALL(*gl_, Uniform3fv(1, _, _)).Times(AnyNumber());
    EXPECT_CALL(*gl_, Uniform4fv(1, _, _)).Times(AnyNumber());
    EXPECT_CALL(*gl_, UniformMatrix2fv(1, _, _, _)).Times(AnyNumber());
    EXPECT_CALL(*gl_, UniformMatrix3fv(1, _, _, _)).Times(AnyNumber());
    EXPECT_CALL(*gl_, UniformMatrix4fv(1, _, _, _)).Times(AnyNumber());

    {
      valid_uniform = accepts_apis & Program::kUniform1i;
      cmds::Uniform1i cmd;
      cmd.Init(1, 2);
      EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
      EXPECT_EQ(valid_uniform ? GL_NO_ERROR : GL_INVALID_OPERATION,
                GetGLError());
    }

    {
      valid_uniform = accepts_apis & Program::kUniform1i;
      cmds::Uniform1ivImmediate& cmd =
          *GetImmediateAs<cmds::Uniform1ivImmediate>();
      GLint data[2][1] = {{0}};
      cmd.Init(1, 2, &data[0][0]);
      EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(data)));
      EXPECT_EQ(valid_uniform ? GL_NO_ERROR : GL_INVALID_OPERATION,
                GetGLError());
    }

    {
      valid_uniform = accepts_apis & Program::kUniform2i;
      cmds::Uniform2i cmd;
      cmd.Init(1, 2, 3);
      EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
      EXPECT_EQ(valid_uniform ? GL_NO_ERROR : GL_INVALID_OPERATION,
                GetGLError());
    }

    {
      valid_uniform = accepts_apis & Program::kUniform2i;
      cmds::Uniform2ivImmediate& cmd =
          *GetImmediateAs<cmds::Uniform2ivImmediate>();
      GLint data[2][2] = {{0}};
      cmd.Init(1, 2, &data[0][0]);
      EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(data)));
      EXPECT_EQ(valid_uniform ? GL_NO_ERROR : GL_INVALID_OPERATION,
                GetGLError());
    }

    {
      valid_uniform = accepts_apis & Program::kUniform3i;
      cmds::Uniform3i cmd;
      cmd.Init(1, 2, 3, 4);
      EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
      EXPECT_EQ(valid_uniform ? GL_NO_ERROR : GL_INVALID_OPERATION,
                GetGLError());
    }

    {
      valid_uniform = accepts_apis & Program::kUniform3i;
      cmds::Uniform3ivImmediate& cmd =
          *GetImmediateAs<cmds::Uniform3ivImmediate>();
      GLint data[2][3] = {{0}};
      cmd.Init(1, 2, &data[0][0]);
      EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(data)));
      EXPECT_EQ(valid_uniform ? GL_NO_ERROR : GL_INVALID_OPERATION,
                GetGLError());
    }

    {
      valid_uniform = accepts_apis & Program::kUniform4i;
      cmds::Uniform4i cmd;
      cmd.Init(1, 2, 3, 4, 5);
      EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
      EXPECT_EQ(valid_uniform ? GL_NO_ERROR : GL_INVALID_OPERATION,
                GetGLError());
    }

    {
      valid_uniform = accepts_apis & Program::kUniform4i;
      cmds::Uniform4ivImmediate& cmd =
          *GetImmediateAs<cmds::Uniform4ivImmediate>();
      GLint data[2][4] = {{0}};
      cmd.Init(1, 2, &data[0][0]);
      EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(data)));
      EXPECT_EQ(valid_uniform ? GL_NO_ERROR : GL_INVALID_OPERATION,
                GetGLError());
    }

    ////////////////////

    {
      valid_uniform = accepts_apis & Program::kUniform1f;
      cmds::Uniform1f cmd;
      cmd.Init(1, 2);
      EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
      EXPECT_EQ(valid_uniform ? GL_NO_ERROR : GL_INVALID_OPERATION,
                GetGLError());
    }

    {
      valid_uniform = accepts_apis & Program::kUniform1f;
      cmds::Uniform1fvImmediate& cmd =
          *GetImmediateAs<cmds::Uniform1fvImmediate>();
      GLfloat data[2][1] = {{0.0f}};
      cmd.Init(1, 2, &data[0][0]);
      EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(data)));
      EXPECT_EQ(valid_uniform ? GL_NO_ERROR : GL_INVALID_OPERATION,
                GetGLError());
    }

    {
      valid_uniform = accepts_apis & Program::kUniform2f;
      cmds::Uniform2f cmd;
      cmd.Init(1, 2, 3);
      EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
      EXPECT_EQ(valid_uniform ? GL_NO_ERROR : GL_INVALID_OPERATION,
                GetGLError());
    }

    {
      valid_uniform = accepts_apis & Program::kUniform2f;
      cmds::Uniform2fvImmediate& cmd =
          *GetImmediateAs<cmds::Uniform2fvImmediate>();
      GLfloat data[2][2] = {{0.0f}};
      cmd.Init(1, 2, &data[0][0]);
      EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(data)));
      EXPECT_EQ(valid_uniform ? GL_NO_ERROR : GL_INVALID_OPERATION,
                GetGLError());
    }

    {
      valid_uniform = accepts_apis & Program::kUniform3f;
      cmds::Uniform3f cmd;
      cmd.Init(1, 2, 3, 4);
      EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
      EXPECT_EQ(valid_uniform ? GL_NO_ERROR : GL_INVALID_OPERATION,
                GetGLError());
    }

    {
      valid_uniform = accepts_apis & Program::kUniform3f;
      cmds::Uniform3fvImmediate& cmd =
          *GetImmediateAs<cmds::Uniform3fvImmediate>();
      GLfloat data[2][3] = {{0.0f}};
      cmd.Init(1, 2, &data[0][0]);
      EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(data)));
      EXPECT_EQ(valid_uniform ? GL_NO_ERROR : GL_INVALID_OPERATION,
                GetGLError());
    }

    {
      valid_uniform = accepts_apis & Program::kUniform4f;
      cmds::Uniform4f cmd;
      cmd.Init(1, 2, 3, 4, 5);
      EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
      EXPECT_EQ(valid_uniform ? GL_NO_ERROR : GL_INVALID_OPERATION,
                GetGLError());
    }

    {
      valid_uniform = accepts_apis & Program::kUniform4f;
      cmds::Uniform4fvImmediate& cmd =
          *GetImmediateAs<cmds::Uniform4fvImmediate>();
      GLfloat data[2][4] = {{0.0f}};
      cmd.Init(1, 2, &data[0][0]);
      EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(data)));
      EXPECT_EQ(valid_uniform ? GL_NO_ERROR : GL_INVALID_OPERATION,
                GetGLError());
    }

    {
      valid_uniform = accepts_apis & Program::kUniformMatrix2f;
      cmds::UniformMatrix2fvImmediate& cmd =
          *GetImmediateAs<cmds::UniformMatrix2fvImmediate>();
      GLfloat data[2][2 * 2] = {{0.0f}};

      cmd.Init(1, 2, &data[0][0]);
      EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(data)));
      EXPECT_EQ(valid_uniform ? GL_NO_ERROR : GL_INVALID_OPERATION,
                GetGLError());
    }

    {
      valid_uniform = accepts_apis & Program::kUniformMatrix3f;
      cmds::UniformMatrix3fvImmediate& cmd =
          *GetImmediateAs<cmds::UniformMatrix3fvImmediate>();
      GLfloat data[2][3 * 3] = {{0.0f}};
      cmd.Init(1, 2, &data[0][0]);
      EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(data)));
      EXPECT_EQ(valid_uniform ? GL_NO_ERROR : GL_INVALID_OPERATION,
                GetGLError());
    }

    {
      valid_uniform = accepts_apis & Program::kUniformMatrix4f;
      cmds::UniformMatrix4fvImmediate& cmd =
          *GetImmediateAs<cmds::UniformMatrix4fvImmediate>();
      GLfloat data[2][4 * 4] = {{0.0f}};
      cmd.Init(1, 2, &data[0][0]);
      EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(data)));
      EXPECT_EQ(valid_uniform ? GL_NO_ERROR : GL_INVALID_OPERATION,
                GetGLError());
    }
  }
};

INSTANTIATE_TEST_CASE_P(Service, GLES2DecoderTest2, ::testing::Bool());

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::RenderbufferStorage, 0>(
    bool valid) {
  DoBindRenderbuffer(GL_RENDERBUFFER, client_renderbuffer_id_,
                    kServiceRenderbufferId);
  if (valid) {
    EnsureRenderbufferBound(false);
    EXPECT_CALL(*gl_, GetError())
        .WillOnce(Return(GL_NO_ERROR))
        .RetiresOnSaturation();
    EXPECT_CALL(*gl_,
                RenderbufferStorageEXT(GL_RENDERBUFFER, _, 3, 4))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*gl_, GetError())
        .WillOnce(Return(GL_NO_ERROR))
        .RetiresOnSaturation();
  }
}

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::GenQueriesEXTImmediate, 0>(
    bool valid) {
  if (!valid) {
    // Make the client_query_id_ so that trying to make it again
    // will fail.
    cmds::GenQueriesEXTImmediate& cmd =
        *GetImmediateAs<cmds::GenQueriesEXTImmediate>();
    cmd.Init(1, &client_query_id_);
    EXPECT_EQ(error::kNoError,
              ExecuteImmediateCmd(cmd, sizeof(client_query_id_)));
  }
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::DeleteQueriesEXTImmediate, 0>(
    bool valid) {
  if (valid) {
    // Make the client_query_id_ so that trying to delete it will succeed.
    cmds::GenQueriesEXTImmediate& cmd =
        *GetImmediateAs<cmds::GenQueriesEXTImmediate>();
    cmd.Init(1, &client_query_id_);
    EXPECT_EQ(error::kNoError,
              ExecuteImmediateCmd(cmd, sizeof(client_query_id_)));
  }
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::LinkProgram, 0>(
    bool /* valid */) {
  const GLuint kClientVertexShaderId = 5001;
  const GLuint kServiceVertexShaderId = 6001;
  const GLuint kClientFragmentShaderId = 5002;
  const GLuint kServiceFragmentShaderId = 6002;
  DoCreateShader(
      GL_VERTEX_SHADER, kClientVertexShaderId, kServiceVertexShaderId);
  DoCreateShader(
      GL_FRAGMENT_SHADER, kClientFragmentShaderId, kServiceFragmentShaderId);

  TestHelper::SetShaderStates(
      gl_.get(), GetShader(kClientVertexShaderId), true);
  TestHelper::SetShaderStates(
      gl_.get(), GetShader(kClientFragmentShaderId), true);

  InSequence dummy;
  EXPECT_CALL(*gl_,
              AttachShader(kServiceProgramId, kServiceVertexShaderId))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_,
              AttachShader(kServiceProgramId, kServiceFragmentShaderId))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetProgramiv(kServiceProgramId, GL_LINK_STATUS, _))
      .WillOnce(SetArgumentPointee<2>(1));
  EXPECT_CALL(*gl_,
      GetProgramiv(kServiceProgramId, GL_INFO_LOG_LENGTH, _))
      .WillOnce(SetArgumentPointee<2>(0))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, GetProgramiv(kServiceProgramId, GL_ACTIVE_ATTRIBUTES, _))
      .WillOnce(SetArgumentPointee<2>(0));
  EXPECT_CALL(
      *gl_,
      GetProgramiv(kServiceProgramId, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, _))
      .WillOnce(SetArgumentPointee<2>(0));
  EXPECT_CALL(*gl_, GetProgramiv(kServiceProgramId, GL_ACTIVE_UNIFORMS, _))
      .WillOnce(SetArgumentPointee<2>(0));
  EXPECT_CALL(
      *gl_,
      GetProgramiv(kServiceProgramId, GL_ACTIVE_UNIFORM_MAX_LENGTH, _))
      .WillOnce(SetArgumentPointee<2>(0));

  cmds::AttachShader attach_cmd;
  attach_cmd.Init(client_program_id_, kClientVertexShaderId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(attach_cmd));

  attach_cmd.Init(client_program_id_, kClientFragmentShaderId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(attach_cmd));
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::UseProgram, 0>(
    bool /* valid */) {
  // Needs the same setup as LinkProgram.
  SpecializedSetup<cmds::LinkProgram, 0>(false);

  EXPECT_CALL(*gl_, LinkProgram(kServiceProgramId))
      .Times(1)
      .RetiresOnSaturation();

  cmds::LinkProgram link_cmd;
  link_cmd.Init(client_program_id_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(link_cmd));
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::Uniform1f, 0>(
    bool /* valid */) {
  SetupShaderForUniform(GL_FLOAT);
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::Uniform1fvImmediate, 0>(
    bool /* valid */) {
  SetupShaderForUniform(GL_FLOAT);
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::Uniform1ivImmediate, 0>(
    bool /* valid */) {
  SetupShaderForUniform(GL_INT);
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::Uniform2f, 0>(
    bool /* valid */) {
  SetupShaderForUniform(GL_FLOAT_VEC2);
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::Uniform2i, 0>(
    bool /* valid */) {
  SetupShaderForUniform(GL_INT_VEC2);
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::Uniform2fvImmediate, 0>(
    bool /* valid */) {
  SetupShaderForUniform(GL_FLOAT_VEC2);
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::Uniform2ivImmediate, 0>(
    bool /* valid */) {
  SetupShaderForUniform(GL_INT_VEC2);
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::Uniform3f, 0>(
    bool /* valid */) {
  SetupShaderForUniform(GL_FLOAT_VEC3);
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::Uniform3i, 0>(
    bool /* valid */) {
  SetupShaderForUniform(GL_INT_VEC3);
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::Uniform3fvImmediate, 0>(
    bool /* valid */) {
  SetupShaderForUniform(GL_FLOAT_VEC3);
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::Uniform3ivImmediate, 0>(
    bool /* valid */) {
  SetupShaderForUniform(GL_INT_VEC3);
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::Uniform4f, 0>(
    bool /* valid */) {
  SetupShaderForUniform(GL_FLOAT_VEC4);
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::Uniform4i, 0>(
    bool /* valid */) {
  SetupShaderForUniform(GL_INT_VEC4);
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::Uniform4fvImmediate, 0>(
    bool /* valid */) {
  SetupShaderForUniform(GL_FLOAT_VEC4);
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::Uniform4ivImmediate, 0>(
    bool /* valid */) {
  SetupShaderForUniform(GL_INT_VEC4);
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::UniformMatrix2fvImmediate, 0>(
    bool /* valid */) {
  SetupShaderForUniform(GL_FLOAT_MAT2);
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::UniformMatrix3fvImmediate, 0>(
    bool /* valid */) {
  SetupShaderForUniform(GL_FLOAT_MAT3);
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::UniformMatrix4fvImmediate, 0>(
    bool /* valid */) {
  SetupShaderForUniform(GL_FLOAT_MAT4);
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::TexParameterf, 0>(
    bool /* valid */) {
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::TexParameteri, 0>(
    bool /* valid */) {
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::TexParameterfvImmediate, 0>(
    bool /* valid */) {
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::TexParameterivImmediate, 0>(
    bool /* valid */) {
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::GetVertexAttribiv, 0>(
    bool valid) {
  DoBindBuffer(GL_ARRAY_BUFFER, client_buffer_id_, kServiceBufferId);
  DoVertexAttribPointer(1, 1, GL_FLOAT, 0, 0);
  if (valid) {
    EXPECT_CALL(*gl_, GetError())
        .WillOnce(Return(GL_NO_ERROR))
        .WillOnce(Return(GL_NO_ERROR))
        .RetiresOnSaturation();
  }
};

template <>
void GLES2DecoderTestBase::SpecializedSetup<cmds::GetVertexAttribfv, 0>(
    bool valid) {
  DoBindBuffer(GL_ARRAY_BUFFER, client_buffer_id_, kServiceBufferId);
  DoVertexAttribPointer(1, 1, GL_FLOAT, 0, 0);
  if (valid) {
    EXPECT_CALL(*gl_, GetError())
        .WillOnce(Return(GL_NO_ERROR))
        .WillOnce(Return(GL_NO_ERROR))
        .RetiresOnSaturation();
  }
};


#include "gpu/command_buffer/service/gles2_cmd_decoder_unittest_2_autogen.h"

TEST_P(GLES2DecoderTest2, AcceptsUniform_GL_INT) {
  TestAcceptedUniform(GL_INT, Program::kUniform1i);
}

TEST_P(GLES2DecoderTest2, AcceptsUniform_GL_INT_VEC2) {
  TestAcceptedUniform(GL_INT_VEC2, Program::kUniform2i);
}

TEST_P(GLES2DecoderTest2, AcceptsUniform_GL_INT_VEC3) {
  TestAcceptedUniform(GL_INT_VEC3, Program::kUniform3i);
}

TEST_P(GLES2DecoderTest2, AcceptsUniform_GL_INT_VEC4) {
  TestAcceptedUniform(GL_INT_VEC4, Program::kUniform4i);
}

TEST_P(GLES2DecoderTest2, AcceptsUniform_GL_BOOL) {
  TestAcceptedUniform(GL_BOOL, Program::kUniform1i | Program::kUniform1f);
}

TEST_P(GLES2DecoderTest2, AcceptsUniform_GL_BOOL_VEC2) {
  TestAcceptedUniform(GL_BOOL_VEC2, Program::kUniform2i | Program::kUniform2f);
}

TEST_P(GLES2DecoderTest2, AcceptsUniform_GL_BOOL_VEC3) {
  TestAcceptedUniform(GL_BOOL_VEC3, Program::kUniform3i | Program::kUniform3f);
}

TEST_P(GLES2DecoderTest2, AcceptsUniform_GL_BOOL_VEC4) {
  TestAcceptedUniform(GL_BOOL_VEC4, Program::kUniform4i | Program::kUniform4f);
}

TEST_P(GLES2DecoderTest2, AcceptsUniformTypeFLOAT) {
  TestAcceptedUniform(GL_FLOAT, Program::kUniform1f);
}

TEST_P(GLES2DecoderTest2, AcceptsUniform_GL_FLOAT_VEC2) {
  TestAcceptedUniform(GL_FLOAT_VEC2, Program::kUniform2f);
}

TEST_P(GLES2DecoderTest2, AcceptsUniform_GL_FLOAT_VEC3) {
  TestAcceptedUniform(GL_FLOAT_VEC3, Program::kUniform3f);
}

TEST_P(GLES2DecoderTest2, AcceptsUniform_GL_FLOAT_VEC4) {
  TestAcceptedUniform(GL_FLOAT_VEC4, Program::kUniform4f);
}

TEST_P(GLES2DecoderTest2, AcceptsUniform_GL_FLOAT_MAT2) {
  TestAcceptedUniform(GL_FLOAT_MAT2, Program::kUniformMatrix2f);
}

TEST_P(GLES2DecoderTest2, AcceptsUniform_GL_FLOAT_MAT3) {
  TestAcceptedUniform(GL_FLOAT_MAT3, Program::kUniformMatrix3f);
}

TEST_P(GLES2DecoderTest2, AcceptsUniform_GL_FLOAT_MAT4) {
  TestAcceptedUniform(GL_FLOAT_MAT4, Program::kUniformMatrix4f);
}

}  // namespace gles2
}  // namespace gpu

