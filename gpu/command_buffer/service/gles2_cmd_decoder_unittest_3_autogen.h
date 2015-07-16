// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is auto-generated from
// gpu/command_buffer/build_gles2_cmd_buffer.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

// It is included by gles2_cmd_decoder_unittest_3.cc
#ifndef GPU_COMMAND_BUFFER_SERVICE_GLES2_CMD_DECODER_UNITTEST_3_AUTOGEN_H_
#define GPU_COMMAND_BUFFER_SERVICE_GLES2_CMD_DECODER_UNITTEST_3_AUTOGEN_H_

TEST_P(GLES2DecoderTest3, ValidateProgramValidArgs) {
  EXPECT_CALL(*gl_, ValidateProgram(kServiceProgramId));
  SpecializedSetup<cmds::ValidateProgram, 0>(true);
  cmds::ValidateProgram cmd;
  cmd.Init(client_program_id_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderTest3, VertexAttrib1fValidArgs) {
  EXPECT_CALL(*gl_, VertexAttrib1f(1, 2));
  SpecializedSetup<cmds::VertexAttrib1f, 0>(true);
  cmds::VertexAttrib1f cmd;
  cmd.Init(1, 2);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderTest3, VertexAttrib1fvImmediateValidArgs) {
  cmds::VertexAttrib1fvImmediate& cmd =
      *GetImmediateAs<cmds::VertexAttrib1fvImmediate>();
  SpecializedSetup<cmds::VertexAttrib1fvImmediate, 0>(true);
  GLfloat temp[1] = {
      0,
  };
  cmd.Init(1, &temp[0]);
  EXPECT_CALL(*gl_, VertexAttrib1fv(1, reinterpret_cast<GLfloat*>(
                                           ImmediateDataAddress(&cmd))));
  EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(temp)));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderTest3, VertexAttrib2fValidArgs) {
  EXPECT_CALL(*gl_, VertexAttrib2f(1, 2, 3));
  SpecializedSetup<cmds::VertexAttrib2f, 0>(true);
  cmds::VertexAttrib2f cmd;
  cmd.Init(1, 2, 3);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderTest3, VertexAttrib2fvImmediateValidArgs) {
  cmds::VertexAttrib2fvImmediate& cmd =
      *GetImmediateAs<cmds::VertexAttrib2fvImmediate>();
  SpecializedSetup<cmds::VertexAttrib2fvImmediate, 0>(true);
  GLfloat temp[2] = {
      0,
  };
  cmd.Init(1, &temp[0]);
  EXPECT_CALL(*gl_, VertexAttrib2fv(1, reinterpret_cast<GLfloat*>(
                                           ImmediateDataAddress(&cmd))));
  EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(temp)));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderTest3, VertexAttrib3fValidArgs) {
  EXPECT_CALL(*gl_, VertexAttrib3f(1, 2, 3, 4));
  SpecializedSetup<cmds::VertexAttrib3f, 0>(true);
  cmds::VertexAttrib3f cmd;
  cmd.Init(1, 2, 3, 4);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderTest3, VertexAttrib3fvImmediateValidArgs) {
  cmds::VertexAttrib3fvImmediate& cmd =
      *GetImmediateAs<cmds::VertexAttrib3fvImmediate>();
  SpecializedSetup<cmds::VertexAttrib3fvImmediate, 0>(true);
  GLfloat temp[3] = {
      0,
  };
  cmd.Init(1, &temp[0]);
  EXPECT_CALL(*gl_, VertexAttrib3fv(1, reinterpret_cast<GLfloat*>(
                                           ImmediateDataAddress(&cmd))));
  EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(temp)));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderTest3, VertexAttrib4fValidArgs) {
  EXPECT_CALL(*gl_, VertexAttrib4f(1, 2, 3, 4, 5));
  SpecializedSetup<cmds::VertexAttrib4f, 0>(true);
  cmds::VertexAttrib4f cmd;
  cmd.Init(1, 2, 3, 4, 5);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderTest3, VertexAttrib4fvImmediateValidArgs) {
  cmds::VertexAttrib4fvImmediate& cmd =
      *GetImmediateAs<cmds::VertexAttrib4fvImmediate>();
  SpecializedSetup<cmds::VertexAttrib4fvImmediate, 0>(true);
  GLfloat temp[4] = {
      0,
  };
  cmd.Init(1, &temp[0]);
  EXPECT_CALL(*gl_, VertexAttrib4fv(1, reinterpret_cast<GLfloat*>(
                                           ImmediateDataAddress(&cmd))));
  EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(temp)));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderTest3, VertexAttribI4iValidArgs) {
  EXPECT_CALL(*gl_, VertexAttribI4i(1, 2, 3, 4, 5));
  SpecializedSetup<cmds::VertexAttribI4i, 0>(true);
  cmds::VertexAttribI4i cmd;
  cmd.Init(1, 2, 3, 4, 5);
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderTest3, VertexAttribI4ivImmediateValidArgs) {
  cmds::VertexAttribI4ivImmediate& cmd =
      *GetImmediateAs<cmds::VertexAttribI4ivImmediate>();
  SpecializedSetup<cmds::VertexAttribI4ivImmediate, 0>(true);
  GLint temp[4] = {
      0,
  };
  cmd.Init(1, &temp[0]);
  EXPECT_CALL(*gl_, VertexAttribI4iv(1, reinterpret_cast<GLint*>(
                                            ImmediateDataAddress(&cmd))));
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(temp)));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand, ExecuteImmediateCmd(cmd, sizeof(temp)));
}

TEST_P(GLES2DecoderTest3, VertexAttribI4uiValidArgs) {
  EXPECT_CALL(*gl_, VertexAttribI4ui(1, 2, 3, 4, 5));
  SpecializedSetup<cmds::VertexAttribI4ui, 0>(true);
  cmds::VertexAttribI4ui cmd;
  cmd.Init(1, 2, 3, 4, 5);
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderTest3, VertexAttribI4uivImmediateValidArgs) {
  cmds::VertexAttribI4uivImmediate& cmd =
      *GetImmediateAs<cmds::VertexAttribI4uivImmediate>();
  SpecializedSetup<cmds::VertexAttribI4uivImmediate, 0>(true);
  GLuint temp[4] = {
      0,
  };
  cmd.Init(1, &temp[0]);
  EXPECT_CALL(*gl_, VertexAttribI4uiv(1, reinterpret_cast<GLuint*>(
                                             ImmediateDataAddress(&cmd))));
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(temp)));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand, ExecuteImmediateCmd(cmd, sizeof(temp)));
}
// TODO(gman): VertexAttribIPointer

// TODO(gman): VertexAttribPointer

TEST_P(GLES2DecoderTest3, ViewportValidArgs) {
  EXPECT_CALL(*gl_, Viewport(1, 2, 3, 4));
  SpecializedSetup<cmds::Viewport, 0>(true);
  cmds::Viewport cmd;
  cmd.Init(1, 2, 3, 4);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderTest3, ViewportInvalidArgs2_0) {
  EXPECT_CALL(*gl_, Viewport(_, _, _, _)).Times(0);
  SpecializedSetup<cmds::Viewport, 0>(false);
  cmds::Viewport cmd;
  cmd.Init(1, 2, -1, 4);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
}

TEST_P(GLES2DecoderTest3, ViewportInvalidArgs3_0) {
  EXPECT_CALL(*gl_, Viewport(_, _, _, _)).Times(0);
  SpecializedSetup<cmds::Viewport, 0>(false);
  cmds::Viewport cmd;
  cmd.Init(1, 2, 3, -1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
}
// TODO(gman): WaitSync

// TODO(gman): TexStorage2DEXT
// TODO(gman): GenQueriesEXTImmediate
// TODO(gman): DeleteQueriesEXTImmediate
// TODO(gman): BeginQueryEXT

TEST_P(GLES2DecoderTest3, BeginTransformFeedbackValidArgs) {
  EXPECT_CALL(*gl_, BeginTransformFeedback(GL_POINTS));
  SpecializedSetup<cmds::BeginTransformFeedback, 0>(true);
  cmds::BeginTransformFeedback cmd;
  cmd.Init(GL_POINTS);
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));
}
// TODO(gman): EndQueryEXT

TEST_P(GLES2DecoderTest3, EndTransformFeedbackValidArgs) {
  EXPECT_CALL(*gl_, EndTransformFeedback());
  SpecializedSetup<cmds::EndTransformFeedback, 0>(true);
  cmds::EndTransformFeedback cmd;
  cmd.Init();
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));
}
// TODO(gman): InsertEventMarkerEXT

// TODO(gman): PushGroupMarkerEXT

TEST_P(GLES2DecoderTest3, PopGroupMarkerEXTValidArgs) {
  SpecializedSetup<cmds::PopGroupMarkerEXT, 0>(true);
  cmds::PopGroupMarkerEXT cmd;
  cmd.Init();
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}
// TODO(gman): GenVertexArraysOESImmediate
// TODO(gman): DeleteVertexArraysOESImmediate
// TODO(gman): IsVertexArrayOES
// TODO(gman): BindVertexArrayOES
// TODO(gman): SwapBuffers
// TODO(gman): GetMaxValueInBufferCHROMIUM
// TODO(gman): EnableFeatureCHROMIUM

// TODO(gman): MapBufferRange

// TODO(gman): UnmapBuffer

// TODO(gman): ResizeCHROMIUM
// TODO(gman): GetRequestableExtensionsCHROMIUM

// TODO(gman): RequestExtensionCHROMIUM

// TODO(gman): GetProgramInfoCHROMIUM

// TODO(gman): GetUniformBlocksCHROMIUM

// TODO(gman): GetTransformFeedbackVaryingsCHROMIUM

// TODO(gman): GetUniformsES3CHROMIUM

// TODO(gman): GetTranslatedShaderSourceANGLE
// TODO(gman): PostSubBufferCHROMIUM
// TODO(gman): TexImageIOSurface2DCHROMIUM
// TODO(gman): CopyTextureCHROMIUM
// TODO(gman): CopySubTextureCHROMIUM
// TODO(gman): DrawArraysInstancedANGLE
// TODO(gman): DrawElementsInstancedANGLE
// TODO(gman): VertexAttribDivisorANGLE
// TODO(gman): GenMailboxCHROMIUM

// TODO(gman): ProduceTextureCHROMIUMImmediate
// TODO(gman): ProduceTextureDirectCHROMIUMImmediate
// TODO(gman): ConsumeTextureCHROMIUMImmediate
// TODO(gman): CreateAndConsumeTextureCHROMIUMImmediate
// TODO(gman): BindUniformLocationCHROMIUMBucket
// TODO(gman): GenValuebuffersCHROMIUMImmediate
// TODO(gman): DeleteValuebuffersCHROMIUMImmediate

TEST_P(GLES2DecoderTest3, IsValuebufferCHROMIUMValidArgs) {
  SpecializedSetup<cmds::IsValuebufferCHROMIUM, 0>(true);
  cmds::IsValuebufferCHROMIUM cmd;
  cmd.Init(client_valuebuffer_id_, shared_memory_id_, shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderTest3, IsValuebufferCHROMIUMInvalidArgsBadSharedMemoryId) {
  SpecializedSetup<cmds::IsValuebufferCHROMIUM, 0>(false);
  cmds::IsValuebufferCHROMIUM cmd;
  cmd.Init(client_valuebuffer_id_, kInvalidSharedMemoryId,
           shared_memory_offset_);
  EXPECT_EQ(error::kOutOfBounds, ExecuteCmd(cmd));
  cmd.Init(client_valuebuffer_id_, shared_memory_id_,
           kInvalidSharedMemoryOffset);
  EXPECT_EQ(error::kOutOfBounds, ExecuteCmd(cmd));
}
// TODO(gman): BindValuebufferCHROMIUM
// TODO(gman): SubscribeValueCHROMIUM
// TODO(gman): PopulateSubscribedValuesCHROMIUM
// TODO(gman): UniformValuebufferCHROMIUM
// TODO(gman): BindTexImage2DCHROMIUM
// TODO(gman): ReleaseTexImage2DCHROMIUM
// TODO(gman): TraceBeginCHROMIUM

// TODO(gman): TraceEndCHROMIUM
// TODO(gman): AsyncTexSubImage2DCHROMIUM

// TODO(gman): AsyncTexImage2DCHROMIUM

// TODO(gman): WaitAsyncTexImage2DCHROMIUM

// TODO(gman): WaitAllAsyncTexImage2DCHROMIUM

// TODO(gman): LoseContextCHROMIUM
// TODO(gman): InsertSyncPointCHROMIUM

// TODO(gman): WaitSyncPointCHROMIUM

// TODO(gman): DrawBuffersEXTImmediate
// TODO(gman): DiscardBackbufferCHROMIUM

// TODO(gman): ScheduleOverlayPlaneCHROMIUM
// TODO(gman): SwapInterval
#endif  // GPU_COMMAND_BUFFER_SERVICE_GLES2_CMD_DECODER_UNITTEST_3_AUTOGEN_H_
