// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is auto-generated from
// gpu/command_buffer/build_gles2_cmd_buffer.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

// It is included by gles2_cmd_decoder_unittest_extensions.cc
#ifndef GPU_COMMAND_BUFFER_SERVICE_GLES2_CMD_DECODER_UNITTEST_EXTENSIONS_AUTOGEN_H_
#define GPU_COMMAND_BUFFER_SERVICE_GLES2_CMD_DECODER_UNITTEST_EXTENSIONS_AUTOGEN_H_

// TODO(gman): BlitFramebufferCHROMIUM
// TODO(gman): RenderbufferStorageMultisampleCHROMIUM
// TODO(gman): RenderbufferStorageMultisampleEXT
// TODO(gman): FramebufferTexture2DMultisampleEXT
// TODO(gman): DiscardFramebufferEXTImmediate

TEST_P(GLES2DecoderTestWithCHROMIUMPathRendering,
       MatrixLoadfCHROMIUMImmediateValidArgs) {
  cmds::MatrixLoadfCHROMIUMImmediate& cmd =
      *GetImmediateAs<cmds::MatrixLoadfCHROMIUMImmediate>();
  SpecializedSetup<cmds::MatrixLoadfCHROMIUMImmediate, 0>(true);
  GLfloat temp[16] = {
      0,
  };
  cmd.Init(GL_PATH_PROJECTION_CHROMIUM, &temp[0]);
  EXPECT_CALL(
      *gl_,
      MatrixLoadfEXT(GL_PATH_PROJECTION_CHROMIUM,
                     reinterpret_cast<GLfloat*>(ImmediateDataAddress(&cmd))));
  EXPECT_EQ(error::kNoError, ExecuteImmediateCmd(cmd, sizeof(temp)));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderTestWithCHROMIUMPathRendering,
       MatrixLoadIdentityCHROMIUMValidArgs) {
  EXPECT_CALL(*gl_, MatrixLoadIdentityEXT(GL_PATH_PROJECTION_CHROMIUM));
  SpecializedSetup<cmds::MatrixLoadIdentityCHROMIUM, 0>(true);
  cmds::MatrixLoadIdentityCHROMIUM cmd;
  cmd.Init(GL_PATH_PROJECTION_CHROMIUM);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderTestWithBlendEquationAdvanced, BlendBarrierKHRValidArgs) {
  EXPECT_CALL(*gl_, BlendBarrierKHR());
  SpecializedSetup<cmds::BlendBarrierKHR, 0>(true);
  cmds::BlendBarrierKHR cmd;
  cmd.Init();
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}
#endif  // GPU_COMMAND_BUFFER_SERVICE_GLES2_CMD_DECODER_UNITTEST_EXTENSIONS_AUTOGEN_H_
