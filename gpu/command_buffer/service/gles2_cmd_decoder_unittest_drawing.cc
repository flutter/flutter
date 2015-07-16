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
using ::testing::SetArgumentPointee;
using ::testing::SetArgPointee;
using ::testing::StrEq;
using ::testing::StrictMock;

namespace gpu {
namespace gles2 {

using namespace cmds;

class GLES2DecoderGeometryInstancingTest : public GLES2DecoderWithShaderTest {
 public:
  GLES2DecoderGeometryInstancingTest() : GLES2DecoderWithShaderTest() {}

  void SetUp() override {
    InitState init;
    init.extensions = "GL_ANGLE_instanced_arrays";
    init.gl_version = "opengl es 2.0";
    init.has_alpha = true;
    init.has_depth = true;
    init.request_alpha = true;
    init.request_depth = true;
    init.bind_generates_resource = true;
    InitDecoder(init);
    SetupDefaultProgram();
  }
};

INSTANTIATE_TEST_CASE_P(Service,
                        GLES2DecoderGeometryInstancingTest,
                        ::testing::Bool());

void GLES2DecoderManualInitTest::DirtyStateMaskTest(GLuint color_bits,
                                                    bool depth_mask,
                                                    GLuint front_stencil_mask,
                                                    GLuint back_stencil_mask) {
  ColorMask color_mask_cmd;
  color_mask_cmd.Init((color_bits & 0x1000) != 0,
                      (color_bits & 0x0100) != 0,
                      (color_bits & 0x0010) != 0,
                      (color_bits & 0x0001) != 0);
  EXPECT_EQ(error::kNoError, ExecuteCmd(color_mask_cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  DepthMask depth_mask_cmd;
  depth_mask_cmd.Init(depth_mask);
  EXPECT_EQ(error::kNoError, ExecuteCmd(depth_mask_cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  StencilMaskSeparate front_stencil_mask_cmd;
  front_stencil_mask_cmd.Init(GL_FRONT, front_stencil_mask);
  EXPECT_EQ(error::kNoError, ExecuteCmd(front_stencil_mask_cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  StencilMaskSeparate back_stencil_mask_cmd;
  back_stencil_mask_cmd.Init(GL_BACK, back_stencil_mask);
  EXPECT_EQ(error::kNoError, ExecuteCmd(back_stencil_mask_cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  SetupExpectationsForApplyingDirtyState(
      false,               // Framebuffer is RGB
      true,                // Framebuffer has depth
      true,                // Framebuffer has stencil
      color_bits,          // color bits
      depth_mask,          // depth mask
      false,               // depth enabled
      front_stencil_mask,  // front stencil mask
      back_stencil_mask,   // back stencil mask
      false);              // stencil enabled

  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawArrays draw_cmd;
  draw_cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(draw_cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

// Test that with an RGB backbuffer if we set the color mask to 1,1,1,1 it is
// set to 1,1,1,0 at Draw time but is 1,1,1,1 at query time.
TEST_P(GLES2DecoderRGBBackbufferTest, RGBBackbufferColorMask) {
  ColorMask cmd;
  cmd.Init(true, true, true, true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  SetupTexture();
  AddExpectationsForSimulatedAttrib0(kNumVertices, 0);
  SetupExpectationsForApplyingDirtyState(true,    // Framebuffer is RGB
                                         false,   // Framebuffer has depth
                                         false,   // Framebuffer has stencil
                                         0x1110,  // color bits
                                         false,   // depth mask
                                         false,   // depth enabled
                                         0,       // front stencil mask
                                         0,       // back stencil mask
                                         false);  // stencil enabled

  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawArrays draw_cmd;
  draw_cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(draw_cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  typedef GetIntegerv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  EXPECT_CALL(*gl_, GetIntegerv(GL_COLOR_WRITEMASK, result->GetData()))
      .Times(0);
  result->size = 0;
  GetIntegerv cmd2;
  cmd2.Init(GL_COLOR_WRITEMASK, shared_memory_id_, shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(
      decoder_->GetGLES2Util()->GLGetNumValuesReturned(GL_COLOR_WRITEMASK),
      result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_EQ(1, result->GetData()[0]);
  EXPECT_EQ(1, result->GetData()[1]);
  EXPECT_EQ(1, result->GetData()[2]);
  EXPECT_EQ(1, result->GetData()[3]);
}

// Test that with no depth if we set DepthMask true that it's set to false at
// draw time but querying it returns true.
TEST_P(GLES2DecoderRGBBackbufferTest, RGBBackbufferDepthMask) {
  EXPECT_CALL(*gl_, DepthMask(true)).Times(0).RetiresOnSaturation();
  DepthMask cmd;
  cmd.Init(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  SetupTexture();
  AddExpectationsForSimulatedAttrib0(kNumVertices, 0);
  SetupExpectationsForApplyingDirtyState(true,    // Framebuffer is RGB
                                         false,   // Framebuffer has depth
                                         false,   // Framebuffer has stencil
                                         0x1110,  // color bits
                                         false,   // depth mask
                                         false,   // depth enabled
                                         0,       // front stencil mask
                                         0,       // back stencil mask
                                         false);  // stencil enabled

  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawArrays draw_cmd;
  draw_cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(draw_cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  typedef GetIntegerv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  EXPECT_CALL(*gl_, GetIntegerv(GL_DEPTH_WRITEMASK, result->GetData()))
      .Times(0);
  result->size = 0;
  GetIntegerv cmd2;
  cmd2.Init(GL_DEPTH_WRITEMASK, shared_memory_id_, shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(
      decoder_->GetGLES2Util()->GLGetNumValuesReturned(GL_DEPTH_WRITEMASK),
      result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_EQ(1, result->GetData()[0]);
}

// Test that with no stencil if we set the stencil mask it's still set to 0 at
// draw time but gets our value if we query.
TEST_P(GLES2DecoderRGBBackbufferTest, RGBBackbufferStencilMask) {
  const GLint kMask = 123;
  EXPECT_CALL(*gl_, StencilMask(kMask)).Times(0).RetiresOnSaturation();
  StencilMask cmd;
  cmd.Init(kMask);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  SetupTexture();
  AddExpectationsForSimulatedAttrib0(kNumVertices, 0);
  SetupExpectationsForApplyingDirtyState(true,    // Framebuffer is RGB
                                         false,   // Framebuffer has depth
                                         false,   // Framebuffer has stencil
                                         0x1110,  // color bits
                                         false,   // depth mask
                                         false,   // depth enabled
                                         0,       // front stencil mask
                                         0,       // back stencil mask
                                         false);  // stencil enabled

  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawArrays draw_cmd;
  draw_cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(draw_cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  typedef GetIntegerv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  EXPECT_CALL(*gl_, GetIntegerv(GL_STENCIL_WRITEMASK, result->GetData()))
      .Times(0);
  result->size = 0;
  GetIntegerv cmd2;
  cmd2.Init(GL_STENCIL_WRITEMASK, shared_memory_id_, shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(
      decoder_->GetGLES2Util()->GLGetNumValuesReturned(GL_STENCIL_WRITEMASK),
      result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_EQ(kMask, result->GetData()[0]);
}

// Test that if an FBO is bound we get the correct masks.
TEST_P(GLES2DecoderRGBBackbufferTest, RGBBackbufferColorMaskFBO) {
  ColorMask cmd;
  cmd.Init(true, true, true, true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  SetupTexture();
  SetupVertexBuffer();
  DoEnableVertexAttribArray(0);
  DoVertexAttribPointer(0, 2, GL_FLOAT, 0, 0);
  DoEnableVertexAttribArray(1);
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);
  DoEnableVertexAttribArray(2);
  DoVertexAttribPointer(2, 2, GL_FLOAT, 0, 0);
  SetupExpectationsForApplyingDirtyState(true,    // Framebuffer is RGB
                                         false,   // Framebuffer has depth
                                         false,   // Framebuffer has stencil
                                         0x1110,  // color bits
                                         false,   // depth mask
                                         false,   // depth enabled
                                         0,       // front stencil mask
                                         0,       // back stencil mask
                                         false);  // stencil enabled

  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawArrays draw_cmd;
  draw_cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(draw_cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  // Check that no extra calls are made on the next draw.
  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_EQ(error::kNoError, ExecuteCmd(draw_cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  // Setup Frame buffer.
  // needs to be 1x1 or else it's not renderable.
  const GLsizei kWidth = 1;
  const GLsizei kHeight = 1;
  const GLenum kFormat = GL_RGB;
  // Use a different texture for framebuffer to avoid drawing feedback loops.
  EXPECT_CALL(*gl_, GenTextures(_, _))
      .WillOnce(SetArgumentPointee<1>(kNewServiceId))
      .RetiresOnSaturation();
  GenHelper<cmds::GenTexturesImmediate>(kNewClientId);
  DoBindTexture(GL_TEXTURE_2D, kNewClientId, kNewServiceId);
  // Pass some data so the texture will be marked as cleared.
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
                         kNewClientId,
                         kNewServiceId,
                         0,
                         GL_NO_ERROR);
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  EXPECT_CALL(*gl_, CheckFramebufferStatusEXT(GL_FRAMEBUFFER))
      .WillOnce(Return(GL_FRAMEBUFFER_COMPLETE))
      .RetiresOnSaturation();

  // This time state needs to be set.
  SetupExpectationsForApplyingDirtyState(false,   // Framebuffer is RGB
                                         false,   // Framebuffer has depth
                                         false,   // Framebuffer has stencil
                                         0x1110,  // color bits
                                         false,   // depth mask
                                         false,   // depth enabled
                                         0,       // front stencil mask
                                         0,       // back stencil mask
                                         false);  // stencil enabled

  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_EQ(error::kNoError, ExecuteCmd(draw_cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  // Check that no extra calls are made on the next draw.
  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_EQ(error::kNoError, ExecuteCmd(draw_cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  // Unbind
  DoBindFramebuffer(GL_FRAMEBUFFER, 0, 0);

  SetupExpectationsForApplyingDirtyState(true,    // Framebuffer is RGB
                                         false,   // Framebuffer has depth
                                         false,   // Framebuffer has stencil
                                         0x1110,  // color bits
                                         false,   // depth mask
                                         false,   // depth enabled
                                         0,       // front stencil mask
                                         0,       // back stencil mask
                                         false);  // stencil enabled

  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_EQ(error::kNoError, ExecuteCmd(draw_cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderManualInitTest, DepthEnableWithDepth) {
  InitState init;
  init.has_depth = true;
  init.request_depth = true;
  init.bind_generates_resource = true;
  InitDecoder(init);

  Enable cmd;
  cmd.Init(GL_DEPTH_TEST);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  SetupDefaultProgram();
  SetupTexture();
  AddExpectationsForSimulatedAttrib0(kNumVertices, 0);
  SetupExpectationsForApplyingDirtyState(true,    // Framebuffer is RGB
                                         true,    // Framebuffer has depth
                                         false,   // Framebuffer has stencil
                                         0x1110,  // color bits
                                         true,    // depth mask
                                         true,    // depth enabled
                                         0,       // front stencil mask
                                         0,       // back stencil mask
                                         false);  // stencil enabled

  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawArrays draw_cmd;
  draw_cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(draw_cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  typedef GetIntegerv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  EXPECT_CALL(*gl_, GetIntegerv(GL_DEPTH_TEST, _))
      .Times(0)
      .RetiresOnSaturation();
  result->size = 0;
  GetIntegerv cmd2;
  cmd2.Init(GL_DEPTH_TEST, shared_memory_id_, shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(decoder_->GetGLES2Util()->GLGetNumValuesReturned(GL_DEPTH_TEST),
            result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_EQ(1, result->GetData()[0]);
}

TEST_P(GLES2DecoderManualInitTest, DepthEnableWithoutRequestedDepth) {
  InitState init;
  init.has_depth = true;
  init.bind_generates_resource = true;
  InitDecoder(init);

  Enable cmd;
  cmd.Init(GL_DEPTH_TEST);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  SetupDefaultProgram();
  SetupTexture();
  AddExpectationsForSimulatedAttrib0(kNumVertices, 0);
  SetupExpectationsForApplyingDirtyState(true,    // Framebuffer is RGB
                                         false,   // Framebuffer has depth
                                         false,   // Framebuffer has stencil
                                         0x1110,  // color bits
                                         false,   // depth mask
                                         false,   // depth enabled
                                         0,       // front stencil mask
                                         0,       // back stencil mask
                                         false);  // stencil enabled

  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawArrays draw_cmd;
  draw_cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(draw_cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  typedef GetIntegerv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  EXPECT_CALL(*gl_, GetIntegerv(GL_DEPTH_TEST, _))
      .Times(0)
      .RetiresOnSaturation();
  result->size = 0;
  GetIntegerv cmd2;
  cmd2.Init(GL_DEPTH_TEST, shared_memory_id_, shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(decoder_->GetGLES2Util()->GLGetNumValuesReturned(GL_DEPTH_TEST),
            result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_EQ(1, result->GetData()[0]);
}

TEST_P(GLES2DecoderManualInitTest, StencilEnableWithStencil) {
  InitState init;
  init.has_stencil = true;
  init.request_stencil = true;
  init.bind_generates_resource = true;
  InitDecoder(init);

  Enable cmd;
  cmd.Init(GL_STENCIL_TEST);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  SetupDefaultProgram();
  SetupTexture();
  AddExpectationsForSimulatedAttrib0(kNumVertices, 0);
  SetupExpectationsForApplyingDirtyState(
      true,                               // Framebuffer is RGB
      false,                              // Framebuffer has depth
      true,                               // Framebuffer has stencil
      0x1110,                             // color bits
      false,                              // depth mask
      false,                              // depth enabled
      GLES2Decoder::kDefaultStencilMask,  // front stencil mask
      GLES2Decoder::kDefaultStencilMask,  // back stencil mask
      true);                              // stencil enabled

  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawArrays draw_cmd;
  draw_cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(draw_cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  typedef GetIntegerv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  EXPECT_CALL(*gl_, GetIntegerv(GL_STENCIL_TEST, _))
      .Times(0)
      .RetiresOnSaturation();
  result->size = 0;
  GetIntegerv cmd2;
  cmd2.Init(GL_STENCIL_TEST, shared_memory_id_, shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(decoder_->GetGLES2Util()->GLGetNumValuesReturned(GL_STENCIL_TEST),
            result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_EQ(1, result->GetData()[0]);
}

TEST_P(GLES2DecoderManualInitTest, StencilEnableWithoutRequestedStencil) {
  InitState init;
  init.has_stencil = true;
  init.bind_generates_resource = true;
  InitDecoder(init);

  Enable cmd;
  cmd.Init(GL_STENCIL_TEST);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  SetupDefaultProgram();
  SetupTexture();
  AddExpectationsForSimulatedAttrib0(kNumVertices, 0);
  SetupExpectationsForApplyingDirtyState(true,    // Framebuffer is RGB
                                         false,   // Framebuffer has depth
                                         false,   // Framebuffer has stencil
                                         0x1110,  // color bits
                                         false,   // depth mask
                                         false,   // depth enabled
                                         0,       // front stencil mask
                                         0,       // back stencil mask
                                         false);  // stencil enabled

  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawArrays draw_cmd;
  draw_cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(draw_cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  typedef GetIntegerv::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  EXPECT_CALL(*gl_, GetIntegerv(GL_STENCIL_TEST, _))
      .Times(0)
      .RetiresOnSaturation();
  result->size = 0;
  GetIntegerv cmd2;
  cmd2.Init(GL_STENCIL_TEST, shared_memory_id_, shared_memory_offset_);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(decoder_->GetGLES2Util()->GLGetNumValuesReturned(GL_STENCIL_TEST),
            result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_EQ(1, result->GetData()[0]);
}

TEST_P(GLES2DecoderManualInitTest, CachedColorMask) {
  InitState init;
  init.has_alpha = true;
  init.has_depth = true;
  init.has_stencil = true;
  init.request_alpha = true;
  init.request_depth = true;
  init.request_stencil = true;
  init.bind_generates_resource = true;
  InitDecoder(init);

  SetupDefaultProgram();
  SetupAllNeededVertexBuffers();
  SetupTexture();

  // Test all color_bits combinations twice.
  for (int i = 0; i < 32; i++) {
    GLuint color_bits = (i & 1 ? 0x0001 : 0x0000) | (i & 2 ? 0x0010 : 0x0000) |
                        (i & 4 ? 0x0100 : 0x0000) | (i & 8 ? 0x1000 : 0x0000);

    // Toggle depth_test to force ApplyDirtyState each time.
    DirtyStateMaskTest(color_bits, false, 0xffffffff, 0xffffffff);
    DirtyStateMaskTest(color_bits, true, 0xffffffff, 0xffffffff);
    DirtyStateMaskTest(color_bits, false, 0xffffffff, 0xffffffff);
  }
}

TEST_P(GLES2DecoderManualInitTest, CachedDepthMask) {
  InitState init;
  init.has_alpha = true;
  init.has_depth = true;
  init.has_stencil = true;
  init.request_alpha = true;
  init.request_depth = true;
  init.request_stencil = true;
  init.bind_generates_resource = true;
  InitDecoder(init);

  SetupDefaultProgram();
  SetupAllNeededVertexBuffers();
  SetupTexture();

  // Test all depth_mask combinations twice.
  for (int i = 0; i < 4; i++) {
    bool depth_mask = (i & 1) == 1;

    // Toggle color masks to force ApplyDirtyState each time.
    DirtyStateMaskTest(0x1010, depth_mask, 0xffffffff, 0xffffffff);
    DirtyStateMaskTest(0x0101, depth_mask, 0xffffffff, 0xffffffff);
    DirtyStateMaskTest(0x1010, depth_mask, 0xffffffff, 0xffffffff);
  }
}

TEST_P(GLES2DecoderManualInitTest, CachedStencilMask) {
  InitState init;
  init.has_alpha = true;
  init.has_depth = true;
  init.has_stencil = true;
  init.request_alpha = true;
  init.request_depth = true;
  init.request_stencil = true;
  init.bind_generates_resource = true;
  InitDecoder(init);

  SetupDefaultProgram();
  SetupAllNeededVertexBuffers();
  SetupTexture();

  // Test all stencil_mask combinations twice.
  for (int i = 0; i < 4; i++) {
    GLuint stencil_mask = (i & 1) ? 0xf0f0f0f0 : 0x0f0f0f0f;

    // Toggle color masks to force ApplyDirtyState each time.
    DirtyStateMaskTest(0x1010, true, stencil_mask, 0xffffffff);
    DirtyStateMaskTest(0x0101, true, stencil_mask, 0xffffffff);
    DirtyStateMaskTest(0x1010, true, stencil_mask, 0xffffffff);
  }

  for (int i = 0; i < 4; i++) {
    GLuint stencil_mask = (i & 1) ? 0xf0f0f0f0 : 0x0f0f0f0f;

    // Toggle color masks to force ApplyDirtyState each time.
    DirtyStateMaskTest(0x1010, true, 0xffffffff, stencil_mask);
    DirtyStateMaskTest(0x0101, true, 0xffffffff, stencil_mask);
    DirtyStateMaskTest(0x1010, true, 0xffffffff, stencil_mask);
  }
}

TEST_P(GLES2DecoderWithShaderTest, DrawArraysNoAttributesSucceeds) {
  SetupTexture();
  AddExpectationsForSimulatedAttrib0(kNumVertices, 0);
  SetupExpectationsForApplyingDefaultDirtyState();

  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawArrays cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

// Tests when the math overflows (0x40000000 * sizeof GLfloat)
TEST_P(GLES2DecoderWithShaderTest, DrawArraysSimulatedAttrib0OverflowFails) {
  const GLsizei kLargeCount = 0x40000000;
  SetupTexture();
  EXPECT_CALL(*gl_, DrawArrays(_, _, _)).Times(0).RetiresOnSaturation();
  DrawArrays cmd;
  cmd.Init(GL_TRIANGLES, 0, kLargeCount);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_OUT_OF_MEMORY, GetGLError());
  EXPECT_FALSE(GetDecoder()->WasContextLost());
}

// Tests when the math overflows (0x7FFFFFFF + 1 = 0x8000000 verts)
TEST_P(GLES2DecoderWithShaderTest, DrawArraysSimulatedAttrib0PosToNegFails) {
  const GLsizei kLargeCount = 0x7FFFFFFF;
  SetupTexture();
  EXPECT_CALL(*gl_, DrawArrays(_, _, _)).Times(0).RetiresOnSaturation();
  DrawArrays cmd;
  cmd.Init(GL_TRIANGLES, 0, kLargeCount);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_OUT_OF_MEMORY, GetGLError());
  EXPECT_FALSE(GetDecoder()->WasContextLost());
}

// Tests when the driver returns an error
TEST_P(GLES2DecoderWithShaderTest, DrawArraysSimulatedAttrib0OOMFails) {
  const GLsizei kFakeLargeCount = 0x1234;
  SetupTexture();
  AddExpectationsForSimulatedAttrib0WithError(
      kFakeLargeCount, 0, GL_OUT_OF_MEMORY);
  EXPECT_CALL(*gl_, DrawArrays(_, _, _)).Times(0).RetiresOnSaturation();
  DrawArrays cmd;
  cmd.Init(GL_TRIANGLES, 0, kFakeLargeCount);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_OUT_OF_MEMORY, GetGLError());
  EXPECT_FALSE(GetDecoder()->WasContextLost());
}

TEST_P(GLES2DecoderWithShaderTest, DrawArraysBadTextureUsesBlack) {
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  // This is an NPOT texture. As the default filtering requires mips
  // this should trigger replacing with black textures before rendering.
  DoTexImage2D(GL_TEXTURE_2D,
               0,
               GL_RGBA,
               3,
               1,
               0,
               GL_RGBA,
               GL_UNSIGNED_BYTE,
               kSharedMemoryId,
               kSharedMemoryOffset);
  AddExpectationsForSimulatedAttrib0(kNumVertices, 0);
  {
    InSequence sequence;
    EXPECT_CALL(*gl_, ActiveTexture(GL_TEXTURE0))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(
        *gl_, BindTexture(GL_TEXTURE_2D, TestHelper::kServiceBlackTexture2dId))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*gl_, ActiveTexture(GL_TEXTURE0))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*gl_, BindTexture(GL_TEXTURE_2D, kServiceTextureId))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*gl_, ActiveTexture(GL_TEXTURE0))
        .Times(1)
        .RetiresOnSaturation();
  }
  SetupExpectationsForApplyingDefaultDirtyState();
  DrawArrays cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, DrawArraysMissingAttributesFails) {
  DoEnableVertexAttribArray(1);

  EXPECT_CALL(*gl_, DrawArrays(_, _, _)).Times(0);
  DrawArrays cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest,
       DrawArraysMissingAttributesZeroCountSucceeds) {
  DoEnableVertexAttribArray(1);

  EXPECT_CALL(*gl_, DrawArrays(_, _, _)).Times(0);
  DrawArrays cmd;
  cmd.Init(GL_TRIANGLES, 0, 0);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, DrawArraysValidAttributesSucceeds) {
  SetupTexture();
  SetupVertexBuffer();
  DoEnableVertexAttribArray(1);
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);
  AddExpectationsForSimulatedAttrib0(kNumVertices, kServiceBufferId);
  SetupExpectationsForApplyingDefaultDirtyState();

  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawArrays cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

// Same as DrawArraysValidAttributesSucceeds, but with workaround
// |init_vertex_attributes|.
TEST_P(GLES2DecoderManualInitTest, InitVertexAttributes) {
  base::CommandLine command_line(0, NULL);
  command_line.AppendSwitchASCII(
      switches::kGpuDriverBugWorkarounds,
      base::IntToString(gpu::INIT_VERTEX_ATTRIBUTES));
  InitState init;
  init.has_alpha = true;
  init.has_depth = true;
  init.request_alpha = true;
  init.request_depth = true;
  init.bind_generates_resource = true;
  InitDecoderWithCommandLine(init, &command_line);
  SetupDefaultProgram();
  SetupTexture();
  SetupVertexBuffer();
  DoEnableVertexAttribArray(1);
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);
  AddExpectationsForSimulatedAttrib0(kNumVertices, kServiceBufferId);
  SetupExpectationsForApplyingDefaultDirtyState();

  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawArrays cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, DrawArraysDeletedBufferFails) {
  SetupVertexBuffer();
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);
  DeleteVertexBuffer();

  EXPECT_CALL(*gl_, DrawArrays(_, _, _)).Times(0);
  DrawArrays cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, DrawArraysDeletedProgramSucceeds) {
  SetupTexture();
  AddExpectationsForSimulatedAttrib0(kNumVertices, 0);
  SetupExpectationsForApplyingDefaultDirtyState();
  DoDeleteProgram(client_program_id_, kServiceProgramId);

  EXPECT_CALL(*gl_, DrawArrays(_, _, _)).Times(1).RetiresOnSaturation();
  EXPECT_CALL(*gl_, DeleteProgram(kServiceProgramId)).Times(1);
  DrawArrays cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, DrawArraysWithInvalidModeFails) {
  SetupVertexBuffer();
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);

  EXPECT_CALL(*gl_, DrawArrays(_, _, _)).Times(0);
  DrawArrays cmd;
  cmd.Init(GL_QUADS, 0, 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());
  cmd.Init(GL_POLYGON, 0, 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, DrawArraysInvalidCountFails) {
  SetupVertexBuffer();
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);

  // Try start > 0
  EXPECT_CALL(*gl_, DrawArrays(_, _, _)).Times(0);
  DrawArrays cmd;
  cmd.Init(GL_TRIANGLES, 1, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  // Try with count > size
  cmd.Init(GL_TRIANGLES, 0, kNumVertices + 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  // Try with attrib offset > 0
  cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 4);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  // Try with size > 2 (ie, vec3 instead of vec2)
  DoVertexAttribPointer(1, 3, GL_FLOAT, 0, 0);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  // Try with stride > 8 (vec2 + vec2 byte)
  DoVertexAttribPointer(1, 2, GL_FLOAT, sizeof(GLfloat) * 3, 0);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, DrawArraysInstancedANGLEFails) {
  SetupTexture();
  SetupVertexBuffer();
  DoEnableVertexAttribArray(1);
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);

  EXPECT_CALL(*gl_, DrawArraysInstancedANGLE(_, _, _, _))
      .Times(0)
      .RetiresOnSaturation();
  DrawArraysInstancedANGLE cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices, 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, VertexAttribDivisorANGLEFails) {
  SetupTexture();
  SetupVertexBuffer();
  DoEnableVertexAttribArray(1);
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);

  EXPECT_CALL(*gl_, VertexAttribDivisorANGLE(_, _))
      .Times(0)
      .RetiresOnSaturation();

  VertexAttribDivisorANGLE cmd;
  cmd.Init(0, 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawArraysInstancedANGLENoAttributesFails) {
  SetupTexture();

  EXPECT_CALL(*gl_, DrawArraysInstancedANGLE(_, _, _, _))
      .Times(0)
      .RetiresOnSaturation();
  DrawArraysInstancedANGLE cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices, 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawArraysInstancedANGLESimulatedAttrib0) {
  SetupTexture();
  SetupVertexBuffer();
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);

  AddExpectationsForSimulatedAttrib0(kNumVertices, kServiceBufferId);
  SetupExpectationsForApplyingDefaultDirtyState();

  DoVertexAttribDivisorANGLE(0, 1);
  EXPECT_CALL(*gl_, DrawArraysInstancedANGLE(GL_TRIANGLES, 0, kNumVertices, 3))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, VertexAttribDivisorANGLE(0, 0))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, VertexAttribDivisorANGLE(0, 1))
      .Times(1)
      .RetiresOnSaturation();
  DrawArraysInstancedANGLE cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices, 3);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawArraysInstancedANGLEMissingAttributesFails) {
  DoEnableVertexAttribArray(1);

  EXPECT_CALL(*gl_, DrawArraysInstancedANGLE(_, _, _, _)).Times(0);
  DrawArraysInstancedANGLE cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices, 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawArraysInstancedANGLEMissingAttributesZeroCountSucceeds) {
  DoEnableVertexAttribArray(1);

  EXPECT_CALL(*gl_, DrawArraysInstancedANGLE(_, _, _, _)).Times(0);
  DrawArraysInstancedANGLE cmd;
  cmd.Init(GL_TRIANGLES, 0, 0, 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawArraysInstancedANGLEValidAttributesSucceeds) {
  SetupTexture();
  SetupVertexBuffer();
  DoEnableVertexAttribArray(1);
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);
  AddExpectationsForSimulatedAttrib0(kNumVertices, kServiceBufferId);
  SetupExpectationsForApplyingDefaultDirtyState();

  EXPECT_CALL(*gl_, DrawArraysInstancedANGLE(GL_TRIANGLES, 0, kNumVertices, 1))
      .Times(1)
      .RetiresOnSaturation();
  DrawArraysInstancedANGLE cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices, 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawArraysInstancedANGLEWithInvalidModeFails) {
  SetupVertexBuffer();
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);

  EXPECT_CALL(*gl_, DrawArraysInstancedANGLE(_, _, _, _)).Times(0);
  DrawArraysInstancedANGLE cmd;
  cmd.Init(GL_QUADS, 0, 1, 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());
  cmd.Init(GL_POLYGON, 0, 1, 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());
}

TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawArraysInstancedANGLEInvalidPrimcountFails) {
  SetupVertexBuffer();
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);

  EXPECT_CALL(*gl_, DrawArraysInstancedANGLE(_, _, _, _)).Times(0);
  DrawArraysInstancedANGLE cmd;
  cmd.Init(GL_TRIANGLES, 0, 1, -1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
}

// Per-instance data is twice as large, but number of instances is half
TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawArraysInstancedANGLELargeInstanceSucceeds) {
  SetupTexture();
  SetupVertexBuffer();
  SetupExpectationsForApplyingDefaultDirtyState();
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);

  DoEnableVertexAttribArray(0);
  DoVertexAttribPointer(0, 4, GL_FLOAT, 0, 0);
  DoVertexAttribDivisorANGLE(0, 1);
  EXPECT_CALL(
      *gl_,
      DrawArraysInstancedANGLE(GL_TRIANGLES, 0, kNumVertices, kNumVertices / 2))
      .Times(1)
      .RetiresOnSaturation();
  DrawArraysInstancedANGLE cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices, kNumVertices / 2);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

// Regular drawArrays takes the divisor into account
TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawArraysWithDivisorSucceeds) {
  SetupTexture();
  SetupVertexBuffer();
  SetupExpectationsForApplyingDefaultDirtyState();
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);

  DoEnableVertexAttribArray(0);
  // Access the data right at the end of the buffer.
  DoVertexAttribPointer(
      0, 2, GL_FLOAT, 0, (kNumVertices - 1) * 2 * sizeof(GLfloat));
  DoVertexAttribDivisorANGLE(0, 1);
  EXPECT_CALL(
      *gl_,
      DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawArrays cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

// Per-instance data is twice as large, but divisor is twice
TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawArraysInstancedANGLELargeDivisorSucceeds) {
  SetupTexture();
  SetupVertexBuffer();
  SetupExpectationsForApplyingDefaultDirtyState();
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);

  DoEnableVertexAttribArray(0);
  DoVertexAttribPointer(0, 4, GL_FLOAT, 0, 0);
  DoVertexAttribDivisorANGLE(0, 2);
  EXPECT_CALL(
      *gl_,
      DrawArraysInstancedANGLE(GL_TRIANGLES, 0, kNumVertices, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawArraysInstancedANGLE cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderGeometryInstancingTest, DrawArraysInstancedANGLELargeFails) {
  SetupTexture();
  SetupVertexBuffer();
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);

  DoEnableVertexAttribArray(0);
  DoVertexAttribPointer(0, 2, GL_FLOAT, 0, 0);
  DoVertexAttribDivisorANGLE(0, 1);
  EXPECT_CALL(*gl_, DrawArraysInstancedANGLE(_, _, _, _))
      .Times(0)
      .RetiresOnSaturation();
  DrawArraysInstancedANGLE cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices, kNumVertices + 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  EXPECT_CALL(*gl_, DrawArraysInstancedANGLE(_, _, _, _))
      .Times(0)
      .RetiresOnSaturation();
  cmd.Init(GL_TRIANGLES, 0, kNumVertices + 1, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

// Per-index data is twice as large, but number of indices is half
TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawArraysInstancedANGLELargeIndexSucceeds) {
  SetupTexture();
  SetupVertexBuffer();
  SetupExpectationsForApplyingDefaultDirtyState();
  DoVertexAttribPointer(1, 4, GL_FLOAT, 0, 0);

  DoEnableVertexAttribArray(0);
  DoVertexAttribPointer(0, 2, GL_FLOAT, 0, 0);
  DoVertexAttribDivisorANGLE(0, 1);
  EXPECT_CALL(
      *gl_,
      DrawArraysInstancedANGLE(GL_TRIANGLES, 0, kNumVertices / 2, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawArraysInstancedANGLE cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices / 2, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawArraysInstancedANGLENoDivisor0Fails) {
  SetupTexture();
  SetupVertexBuffer();
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);

  DoEnableVertexAttribArray(0);
  DoVertexAttribPointer(0, 2, GL_FLOAT, 0, 0);
  DoVertexAttribDivisorANGLE(0, 1);
  DoVertexAttribDivisorANGLE(1, 1);
  EXPECT_CALL(*gl_, DrawArraysInstancedANGLE(_, _, _, _))
      .Times(0)
      .RetiresOnSaturation();
  DrawArraysInstancedANGLE cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices, 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawArraysNoDivisor0Fails) {
  SetupTexture();
  SetupVertexBuffer();
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);

  DoEnableVertexAttribArray(0);
  DoVertexAttribPointer(0, 2, GL_FLOAT, 0, 0);
  DoVertexAttribDivisorANGLE(0, 1);
  DoVertexAttribDivisorANGLE(1, 1);
  EXPECT_CALL(*gl_, DrawArrays(_, _, _))
      .Times(0)
      .RetiresOnSaturation();
  DrawArrays cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, DrawElementsNoAttributesSucceeds) {
  SetupTexture();
  SetupIndexBuffer();
  AddExpectationsForSimulatedAttrib0(kMaxValidIndex + 1, 0);
  SetupExpectationsForApplyingDefaultDirtyState();
  EXPECT_CALL(*gl_,
              DrawElements(GL_TRIANGLES,
                           kValidIndexRangeCount,
                           GL_UNSIGNED_SHORT,
                           BufferOffset(kValidIndexRangeStart * 2)))
      .Times(1)
      .RetiresOnSaturation();
  DrawElements cmd;
  cmd.Init(GL_TRIANGLES,
           kValidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kValidIndexRangeStart * 2);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, DrawElementsMissingAttributesFails) {
  SetupIndexBuffer();
  DoEnableVertexAttribArray(1);

  EXPECT_CALL(*gl_, DrawElements(_, _, _, _)).Times(0);
  DrawElements cmd;
  cmd.Init(GL_TRIANGLES,
           kValidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kValidIndexRangeStart * 2);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest,
       DrawElementsMissingAttributesZeroCountSucceeds) {
  SetupIndexBuffer();
  DoEnableVertexAttribArray(1);

  EXPECT_CALL(*gl_, DrawElements(_, _, _, _)).Times(0);
  DrawElements cmd;
  cmd.Init(GL_TRIANGLES, 0, GL_UNSIGNED_SHORT, kValidIndexRangeStart * 2);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, DrawElementsExtraAttributesFails) {
  SetupIndexBuffer();
  DoEnableVertexAttribArray(6);

  EXPECT_CALL(*gl_, DrawElements(_, _, _, _)).Times(0);
  DrawElements cmd;
  cmd.Init(GL_TRIANGLES,
           kValidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kValidIndexRangeStart * 2);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, DrawElementsValidAttributesSucceeds) {
  SetupTexture();
  SetupVertexBuffer();
  SetupIndexBuffer();
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);
  AddExpectationsForSimulatedAttrib0(kMaxValidIndex + 1, kServiceBufferId);
  SetupExpectationsForApplyingDefaultDirtyState();

  EXPECT_CALL(*gl_,
              DrawElements(GL_TRIANGLES,
                           kValidIndexRangeCount,
                           GL_UNSIGNED_SHORT,
                           BufferOffset(kValidIndexRangeStart * 2)))
      .Times(1)
      .RetiresOnSaturation();
  DrawElements cmd;
  cmd.Init(GL_TRIANGLES,
           kValidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kValidIndexRangeStart * 2);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, DrawElementsDeletedBufferFails) {
  SetupVertexBuffer();
  SetupIndexBuffer();
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);
  DeleteIndexBuffer();

  EXPECT_CALL(*gl_, DrawElements(_, _, _, _)).Times(0);
  DrawElements cmd;
  cmd.Init(GL_TRIANGLES,
           kValidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kValidIndexRangeStart * 2);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, DrawElementsDeletedProgramSucceeds) {
  SetupTexture();
  SetupIndexBuffer();
  AddExpectationsForSimulatedAttrib0(kMaxValidIndex + 1, 0);
  SetupExpectationsForApplyingDefaultDirtyState();
  DoDeleteProgram(client_program_id_, kServiceProgramId);

  EXPECT_CALL(*gl_, DrawElements(_, _, _, _)).Times(1);
  EXPECT_CALL(*gl_, DeleteProgram(kServiceProgramId)).Times(1);
  DrawElements cmd;
  cmd.Init(GL_TRIANGLES,
           kValidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kValidIndexRangeStart * 2);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, DrawElementsWithInvalidModeFails) {
  SetupVertexBuffer();
  SetupIndexBuffer();
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);

  EXPECT_CALL(*gl_, DrawElements(_, _, _, _)).Times(0);
  DrawElements cmd;
  cmd.Init(GL_QUADS,
           kValidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kValidIndexRangeStart * 2);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());
  cmd.Init(GL_POLYGON,
           kValidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kValidIndexRangeStart);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, DrawElementsInvalidCountFails) {
  SetupVertexBuffer();
  SetupIndexBuffer();
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);

  // Try start > 0
  EXPECT_CALL(*gl_, DrawElements(_, _, _, _)).Times(0);
  DrawElements cmd;
  cmd.Init(GL_TRIANGLES, kNumIndices, GL_UNSIGNED_SHORT, 2);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  // Try with count > size
  cmd.Init(GL_TRIANGLES, kNumIndices + 1, GL_UNSIGNED_SHORT, 0);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, DrawElementsOutOfRangeIndicesFails) {
  SetupVertexBuffer();
  SetupIndexBuffer();
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);

  EXPECT_CALL(*gl_, DrawElements(_, _, _, _)).Times(0);
  DrawElements cmd;
  cmd.Init(GL_TRIANGLES,
           kInvalidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kInvalidIndexRangeStart * 2);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, DrawElementsOddOffsetForUint16Fails) {
  SetupVertexBuffer();
  SetupIndexBuffer();
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);

  EXPECT_CALL(*gl_, DrawElements(_, _, _, _)).Times(0);
  DrawElements cmd;
  cmd.Init(GL_TRIANGLES, kInvalidIndexRangeCount, GL_UNSIGNED_SHORT, 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, DrawElementsInstancedANGLEFails) {
  SetupTexture();
  SetupVertexBuffer();
  SetupIndexBuffer();
  DoEnableVertexAttribArray(1);
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);

  EXPECT_CALL(*gl_, DrawElementsInstancedANGLE(_, _, _, _, _))
      .Times(0)
      .RetiresOnSaturation();
  DrawElementsInstancedANGLE cmd;
  cmd.Init(GL_TRIANGLES,
           kValidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kValidIndexRangeStart * 2,
           1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawElementsInstancedANGLENoAttributesFails) {
  SetupTexture();
  SetupIndexBuffer();

  EXPECT_CALL(*gl_, DrawElementsInstancedANGLE(_, _, _, _, _))
      .Times(0)
      .RetiresOnSaturation();
  DrawElementsInstancedANGLE cmd;
  cmd.Init(GL_TRIANGLES,
           kValidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kValidIndexRangeStart * 2,
           1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawElementsInstancedANGLESimulatedAttrib0) {
  SetupTexture();
  SetupVertexBuffer();
  SetupIndexBuffer();
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);

  AddExpectationsForSimulatedAttrib0(kMaxValidIndex + 1, kServiceBufferId);
  SetupExpectationsForApplyingDefaultDirtyState();

  DoVertexAttribDivisorANGLE(0, 1);
  EXPECT_CALL(
      *gl_,
      DrawElementsInstancedANGLE(GL_TRIANGLES,
                                 kValidIndexRangeCount,
                                 GL_UNSIGNED_SHORT,
                                 BufferOffset(kValidIndexRangeStart * 2),
                                 3))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, VertexAttribDivisorANGLE(0, 0))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, VertexAttribDivisorANGLE(0, 1))
      .Times(1)
      .RetiresOnSaturation();
  DrawElementsInstancedANGLE cmd;
  cmd.Init(GL_TRIANGLES,
           kValidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kValidIndexRangeStart * 2,
           3);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawElementsInstancedANGLEMissingAttributesFails) {
  SetupIndexBuffer();
  DoEnableVertexAttribArray(1);

  EXPECT_CALL(*gl_, DrawElementsInstancedANGLE(_, _, _, _, _)).Times(0);
  DrawElementsInstancedANGLE cmd;
  cmd.Init(GL_TRIANGLES,
           kValidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kValidIndexRangeStart * 2,
           1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawElementsInstancedANGLEMissingAttributesZeroCountSucceeds) {
  SetupIndexBuffer();
  DoEnableVertexAttribArray(1);

  EXPECT_CALL(*gl_, DrawElementsInstancedANGLE(_, _, _, _, _)).Times(0);
  DrawElementsInstancedANGLE cmd;
  cmd.Init(GL_TRIANGLES, 0, GL_UNSIGNED_SHORT, kValidIndexRangeStart * 2, 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawElementsInstancedANGLEValidAttributesSucceeds) {
  SetupIndexBuffer();
  SetupTexture();
  SetupVertexBuffer();
  DoEnableVertexAttribArray(1);
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);
  AddExpectationsForSimulatedAttrib0(kMaxValidIndex + 1, kServiceBufferId);
  SetupExpectationsForApplyingDefaultDirtyState();

  EXPECT_CALL(
      *gl_,
      DrawElementsInstancedANGLE(GL_TRIANGLES,
                                 kValidIndexRangeCount,
                                 GL_UNSIGNED_SHORT,
                                 BufferOffset(kValidIndexRangeStart * 2),
                                 1))
      .Times(1)
      .RetiresOnSaturation();
  DrawElementsInstancedANGLE cmd;
  cmd.Init(GL_TRIANGLES,
           kValidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kValidIndexRangeStart * 2,
           1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawElementsInstancedANGLEWithInvalidModeFails) {
  SetupIndexBuffer();
  SetupVertexBuffer();
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);

  EXPECT_CALL(*gl_, DrawElementsInstancedANGLE(_, _, _, _, _)).Times(0);
  DrawElementsInstancedANGLE cmd;
  cmd.Init(GL_QUADS,
           kValidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kValidIndexRangeStart * 2,
           1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());
  cmd.Init(GL_INVALID_ENUM,
           kValidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kValidIndexRangeStart * 2,
           1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_ENUM, GetGLError());
}

// Per-instance data is twice as large, but number of instances is half
TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawElementsInstancedANGLELargeInstanceSucceeds) {
  SetupTexture();
  SetupIndexBuffer();
  SetupVertexBuffer();
  SetupExpectationsForApplyingDefaultDirtyState();
  // Add offset so we're sure we're accessing data near the end of the buffer.
  DoVertexAttribPointer(
      1,
      2,
      GL_FLOAT,
      0,
      (kNumVertices - kMaxValidIndex - 1) * 2 * sizeof(GLfloat));

  DoEnableVertexAttribArray(0);
  DoVertexAttribPointer(0, 4, GL_FLOAT, 0, 0);
  DoVertexAttribDivisorANGLE(0, 1);
  EXPECT_CALL(
      *gl_,
      DrawElementsInstancedANGLE(GL_TRIANGLES,
                                 kValidIndexRangeCount,
                                 GL_UNSIGNED_SHORT,
                                 BufferOffset(kValidIndexRangeStart * 2),
                                 kNumVertices / 2))
      .Times(1)
      .RetiresOnSaturation();
  DrawElementsInstancedANGLE cmd;
  cmd.Init(GL_TRIANGLES,
           kValidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kValidIndexRangeStart * 2,
           kNumVertices / 2);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

// Regular drawElements takes the divisor into account
TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawElementsWithDivisorSucceeds) {
  SetupTexture();
  SetupIndexBuffer();
  SetupVertexBuffer();
  SetupExpectationsForApplyingDefaultDirtyState();
  // Add offset so we're sure we're accessing data near the end of the buffer.
  DoVertexAttribPointer(
      1,
      2,
      GL_FLOAT,
      0,
      (kNumVertices - kMaxValidIndex - 1) * 2 * sizeof(GLfloat));

  DoEnableVertexAttribArray(0);
  // Access the data right at the end of the buffer.
  DoVertexAttribPointer(
      0, 2, GL_FLOAT, 0, (kNumVertices - 1) * 2 * sizeof(GLfloat));
  DoVertexAttribDivisorANGLE(0, 1);
  EXPECT_CALL(
      *gl_,
      DrawElements(GL_TRIANGLES,
                   kValidIndexRangeCount,
                   GL_UNSIGNED_SHORT,
                   BufferOffset(kValidIndexRangeStart * 2)))
      .Times(1)
      .RetiresOnSaturation();
  DrawElements cmd;
  cmd.Init(GL_TRIANGLES,
           kValidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kValidIndexRangeStart * 2);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

// Per-instance data is twice as large, but divisor is twice
TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawElementsInstancedANGLELargeDivisorSucceeds) {
  SetupTexture();
  SetupIndexBuffer();
  SetupVertexBuffer();
  SetupExpectationsForApplyingDefaultDirtyState();
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);

  DoEnableVertexAttribArray(0);
  DoVertexAttribPointer(0, 4, GL_FLOAT, 0, 0);
  DoVertexAttribDivisorANGLE(0, 2);
  EXPECT_CALL(
      *gl_,
      DrawElementsInstancedANGLE(GL_TRIANGLES,
                                 kValidIndexRangeCount,
                                 GL_UNSIGNED_SHORT,
                                 BufferOffset(kValidIndexRangeStart * 2),
                                 kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawElementsInstancedANGLE cmd;
  cmd.Init(GL_TRIANGLES,
           kValidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kValidIndexRangeStart * 2,
           kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawElementsInstancedANGLELargeFails) {
  SetupTexture();
  SetupIndexBuffer();
  SetupVertexBuffer();
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);

  DoEnableVertexAttribArray(0);
  DoVertexAttribPointer(0, 2, GL_FLOAT, 0, 0);
  DoVertexAttribDivisorANGLE(0, 1);
  EXPECT_CALL(*gl_, DrawElementsInstancedANGLE(_, _, _, _, _))
      .Times(0)
      .RetiresOnSaturation();
  DrawElementsInstancedANGLE cmd;
  cmd.Init(GL_TRIANGLES,
           kValidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kValidIndexRangeStart * 2,
           kNumVertices + 1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  EXPECT_CALL(*gl_, DrawElementsInstancedANGLE(_, _, _, _, _))
      .Times(0)
      .RetiresOnSaturation();
  cmd.Init(GL_TRIANGLES,
           kInvalidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kInvalidIndexRangeStart * 2,
           kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawElementsInstancedANGLEInvalidPrimcountFails) {
  SetupTexture();
  SetupIndexBuffer();
  SetupVertexBuffer();
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);

  DoEnableVertexAttribArray(0);
  DoVertexAttribPointer(0, 2, GL_FLOAT, 0, 0);
  DoVertexAttribDivisorANGLE(0, 1);
  EXPECT_CALL(*gl_, DrawElementsInstancedANGLE(_, _, _, _, _))
      .Times(0)
      .RetiresOnSaturation();
  DrawElementsInstancedANGLE cmd;
  cmd.Init(GL_TRIANGLES,
           kValidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kValidIndexRangeStart * 2,
           -1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

// Per-index data is twice as large, but values of indices are smaller
TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawElementsInstancedANGLELargeIndexSucceeds) {
  SetupTexture();
  SetupIndexBuffer();
  SetupVertexBuffer();
  SetupExpectationsForApplyingDefaultDirtyState();
  DoVertexAttribPointer(1, 4, GL_FLOAT, 0, 0);

  DoEnableVertexAttribArray(0);
  DoVertexAttribPointer(0, 2, GL_FLOAT, 0, 0);
  DoVertexAttribDivisorANGLE(0, 1);
  EXPECT_CALL(
      *gl_,
      DrawElementsInstancedANGLE(GL_TRIANGLES,
                                 kValidIndexRangeCount,
                                 GL_UNSIGNED_SHORT,
                                 BufferOffset(kValidIndexRangeStart * 2),
                                 kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawElementsInstancedANGLE cmd;
  cmd.Init(GL_TRIANGLES,
           kValidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kValidIndexRangeStart * 2,
           kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawElementsInstancedANGLENoDivisor0Fails) {
  SetupTexture();
  SetupIndexBuffer();
  SetupVertexBuffer();
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);

  DoEnableVertexAttribArray(0);
  DoVertexAttribPointer(0, 2, GL_FLOAT, 0, 0);
  DoVertexAttribDivisorANGLE(0, 1);
  DoVertexAttribDivisorANGLE(1, 1);
  EXPECT_CALL(*gl_, DrawElementsInstancedANGLE(_, _, _, _, _))
      .Times(0)
      .RetiresOnSaturation();
  DrawElementsInstancedANGLE cmd;
  cmd.Init(GL_TRIANGLES,
           kValidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kValidIndexRangeStart * 2,
           kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderGeometryInstancingTest,
       DrawElementsNoDivisor0Fails) {
  SetupTexture();
  SetupIndexBuffer();
  SetupVertexBuffer();
  DoVertexAttribPointer(1, 2, GL_FLOAT, 0, 0);

  DoEnableVertexAttribArray(0);
  DoVertexAttribPointer(0, 2, GL_FLOAT, 0, 0);
  DoVertexAttribDivisorANGLE(0, 1);
  DoVertexAttribDivisorANGLE(1, 1);
  EXPECT_CALL(*gl_, DrawElements(_, _, _, _))
      .Times(0)
      .RetiresOnSaturation();
  DrawElements cmd;
  cmd.Init(GL_TRIANGLES,
           kValidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kValidIndexRangeStart * 2);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, DrawArraysClearsAfterTexImage2DNULL) {
  SetupAllNeededVertexBuffers();
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  // Create an uncleared texture with 2 levels.
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA, 2, 2, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);
  DoTexImage2D(
      GL_TEXTURE_2D, 1, GL_RGBA, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);
  // Expect 2 levels will be cleared.
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
  SetupClearTextureExpectations(kServiceTextureId,
                                kServiceTextureId,
                                GL_TEXTURE_2D,
                                GL_TEXTURE_2D,
                                1,
                                GL_RGBA,
                                GL_RGBA,
                                GL_UNSIGNED_BYTE,
                                1,
                                1);
  SetupExpectationsForApplyingDefaultDirtyState();
  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawArrays cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  // But not again
  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, DrawElementsClearsAfterTexImage2DNULL) {
  SetupAllNeededVertexBuffers();
  SetupIndexBuffer();
  DoBindTexture(GL_TEXTURE_2D, client_texture_id_, kServiceTextureId);
  // Create an uncleared texture with 2 levels.
  DoTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA, 2, 2, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);
  DoTexImage2D(
      GL_TEXTURE_2D, 1, GL_RGBA, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0, 0);
  // Expect 2 levels will be cleared.
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
  SetupClearTextureExpectations(kServiceTextureId,
                                kServiceTextureId,
                                GL_TEXTURE_2D,
                                GL_TEXTURE_2D,
                                1,
                                GL_RGBA,
                                GL_RGBA,
                                GL_UNSIGNED_BYTE,
                                1,
                                1);
  SetupExpectationsForApplyingDefaultDirtyState();

  EXPECT_CALL(*gl_,
              DrawElements(GL_TRIANGLES,
                           kValidIndexRangeCount,
                           GL_UNSIGNED_SHORT,
                           BufferOffset(kValidIndexRangeStart * 2)))
      .Times(1)
      .RetiresOnSaturation();
  DrawElements cmd;
  cmd.Init(GL_TRIANGLES,
           kValidIndexRangeCount,
           GL_UNSIGNED_SHORT,
           kValidIndexRangeStart * 2);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  // But not again
  EXPECT_CALL(*gl_,
              DrawElements(GL_TRIANGLES,
                           kValidIndexRangeCount,
                           GL_UNSIGNED_SHORT,
                           BufferOffset(kValidIndexRangeStart * 2)))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, DrawClearsAfterTexImage2DNULLInFBO) {
  const GLuint kFBOClientTextureId = 4100;
  const GLuint kFBOServiceTextureId = 4101;

  SetupAllNeededVertexBuffers();
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

  SetupExpectationsForApplyingDirtyState(false,   // Framebuffer is RGB
                                         false,   // Framebuffer has depth
                                         false,   // Framebuffer has stencil
                                         0x1111,  // color bits
                                         false,   // depth mask
                                         false,   // depth enabled
                                         0,       // front stencil mask
                                         0,       // back stencil mask
                                         false);  // stencil enabled

  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawArrays cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  // But not again.
  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, DrawWitFBOThatCantClearDoesNotDraw) {
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

  EXPECT_CALL(*gl_, CheckFramebufferStatusEXT(GL_FRAMEBUFFER))
      .WillOnce(Return(GL_FRAMEBUFFER_UNSUPPORTED))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, DrawArrays(_, _, _)).Times(0).RetiresOnSaturation();
  DrawArrays cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_FRAMEBUFFER_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, DrawClearsAfterRenderbufferStorageInFBO) {
  SetupTexture();
  DoBindRenderbuffer(
      GL_RENDERBUFFER, client_renderbuffer_id_, kServiceRenderbufferId);
  DoBindFramebuffer(
      GL_FRAMEBUFFER, client_framebuffer_id_, kServiceFramebufferId);
  DoRenderbufferStorage(
      GL_RENDERBUFFER, GL_RGBA4, GL_RGBA, 100, 50, GL_NO_ERROR);
  DoFramebufferRenderbuffer(GL_FRAMEBUFFER,
                            GL_COLOR_ATTACHMENT0,
                            GL_RENDERBUFFER,
                            client_renderbuffer_id_,
                            kServiceRenderbufferId,
                            GL_NO_ERROR);

  SetupExpectationsForFramebufferClearing(GL_FRAMEBUFFER,       // target
                                          GL_COLOR_BUFFER_BIT,  // clear bits
                                          0,
                                          0,
                                          0,
                                          0,       // color
                                          0,       // stencil
                                          1.0f,    // depth
                                          false);  // scissor test

  AddExpectationsForSimulatedAttrib0(kNumVertices, 0);
  SetupExpectationsForApplyingDirtyState(false,   // Framebuffer is RGB
                                         false,   // Framebuffer has depth
                                         false,   // Framebuffer has stencil
                                         0x1111,  // color bits
                                         false,   // depth mask
                                         false,   // depth enabled
                                         0,       // front stencil mask
                                         0,       // back stencil mask
                                         false);  // stencil enabled

  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawArrays cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderManualInitTest, DrawArraysClearsAfterTexImage2DNULLCubemap) {
  InitState init;
  init.gl_version = "opengl es 2.0";
  init.has_alpha = true;
  init.has_depth = true;
  init.request_alpha = true;
  init.request_depth = true;
  InitDecoder(init);

  static const GLenum faces[] = {
      GL_TEXTURE_CUBE_MAP_POSITIVE_X, GL_TEXTURE_CUBE_MAP_NEGATIVE_X,
      GL_TEXTURE_CUBE_MAP_POSITIVE_Y, GL_TEXTURE_CUBE_MAP_NEGATIVE_Y,
      GL_TEXTURE_CUBE_MAP_POSITIVE_Z, GL_TEXTURE_CUBE_MAP_NEGATIVE_Z,
  };
  SetupCubemapProgram();
  DoBindTexture(GL_TEXTURE_CUBE_MAP, client_texture_id_, kServiceTextureId);
  // Fill out all the faces for 2 levels, leave 2 uncleared.
  for (int ii = 0; ii < 6; ++ii) {
    GLenum face = faces[ii];
    int32 shm_id =
        (face == GL_TEXTURE_CUBE_MAP_NEGATIVE_Y) ? 0 : kSharedMemoryId;
    uint32 shm_offset =
        (face == GL_TEXTURE_CUBE_MAP_NEGATIVE_Y) ? 0 : kSharedMemoryOffset;
    DoTexImage2D(face,
                 0,
                 GL_RGBA,
                 2,
                 2,
                 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE,
                 shm_id,
                 shm_offset);
    DoTexImage2D(face,
                 1,
                 GL_RGBA,
                 1,
                 1,
                 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE,
                 shm_id,
                 shm_offset);
  }
  // Expect 2 levels will be cleared.
  SetupClearTextureExpectations(kServiceTextureId,
                                kServiceTextureId,
                                GL_TEXTURE_CUBE_MAP,
                                GL_TEXTURE_CUBE_MAP_NEGATIVE_Y,
                                0,
                                GL_RGBA,
                                GL_RGBA,
                                GL_UNSIGNED_BYTE,
                                2,
                                2);
  SetupClearTextureExpectations(kServiceTextureId,
                                kServiceTextureId,
                                GL_TEXTURE_CUBE_MAP,
                                GL_TEXTURE_CUBE_MAP_NEGATIVE_Y,
                                1,
                                GL_RGBA,
                                GL_RGBA,
                                GL_UNSIGNED_BYTE,
                                1,
                                1);
  AddExpectationsForSimulatedAttrib0(kNumVertices, 0);
  SetupExpectationsForApplyingDefaultDirtyState();
  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawArrays cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
}

TEST_P(GLES2DecoderWithShaderTest,
       DrawClearsAfterRenderbuffersWithMultipleAttachments) {
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

  SetupTexture();
  SetupExpectationsForFramebufferClearing(
      GL_FRAMEBUFFER,                             // target
      GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT,  // clear bits
      0,
      0,
      0,
      0,       // color
      0,       // stencil
      1.0f,    // depth
      false);  // scissor test

  AddExpectationsForSimulatedAttrib0(kNumVertices, 0);
  SetupExpectationsForApplyingDirtyState(false,   // Framebuffer is RGB
                                         true,    // Framebuffer has depth
                                         false,   // Framebuffer has stencil
                                         0x1111,  // color bits
                                         true,    // depth mask
                                         false,   // depth enabled
                                         0,       // front stencil mask
                                         0,       // back stencil mask
                                         false);  // stencil enabled

  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawArrays cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest,
       DrawingWithFBOTwiceChecksForFBOCompleteOnce) {
  const GLuint kFBOClientTextureId = 4100;
  const GLuint kFBOServiceTextureId = 4101;

  SetupAllNeededVertexBuffers();

  // Register a texture id.
  EXPECT_CALL(*gl_, GenTextures(_, _))
      .WillOnce(SetArgumentPointee<1>(kFBOServiceTextureId))
      .RetiresOnSaturation();
  GenHelper<GenTexturesImmediate>(kFBOClientTextureId);

  // Setup "render to" texture that is cleared.
  DoBindTexture(GL_TEXTURE_2D, kFBOClientTextureId, kFBOServiceTextureId);
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

  // Make sure we check for framebuffer complete.
  EXPECT_CALL(*gl_, CheckFramebufferStatusEXT(GL_FRAMEBUFFER))
      .WillOnce(Return(GL_FRAMEBUFFER_COMPLETE))
      .RetiresOnSaturation();

  SetupExpectationsForApplyingDirtyState(false,   // Framebuffer is RGB
                                         false,   // Framebuffer has depth
                                         false,   // Framebuffer has stencil
                                         0x1111,  // color bits
                                         false,   // depth mask
                                         false,   // depth enabled
                                         0,       // front stencil mask
                                         0,       // back stencil mask
                                         false);  // stencil enabled

  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawArrays cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());

  // But not again.
  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

TEST_P(GLES2DecoderManualInitTest, DrawClearsDepthTexture) {
  InitState init;
  init.extensions = "GL_ANGLE_depth_texture";
  init.gl_version = "opengl es 2.0";
  init.has_alpha = true;
  init.has_depth = true;
  init.request_alpha = true;
  init.request_depth = true;
  init.bind_generates_resource = true;
  InitDecoder(init);

  SetupDefaultProgram();
  SetupAllNeededVertexBuffers();
  const GLenum attachment = GL_DEPTH_ATTACHMENT;
  const GLenum target = GL_TEXTURE_2D;
  const GLint level = 0;
  DoBindTexture(target, client_texture_id_, kServiceTextureId);

  // Create a depth texture.
  DoTexImage2D(target,
               level,
               GL_DEPTH_COMPONENT,
               1,
               1,
               0,
               GL_DEPTH_COMPONENT,
               GL_UNSIGNED_INT,
               0,
               0);

  // Enable GL_SCISSOR_TEST to make sure we disable it in the clear,
  // then re-enable it.
  DoEnableDisable(GL_SCISSOR_TEST, true);

  EXPECT_CALL(*gl_, GenFramebuffersEXT(1, _)).Times(1).RetiresOnSaturation();
  EXPECT_CALL(*gl_, BindFramebufferEXT(GL_DRAW_FRAMEBUFFER_EXT, _))
      .Times(1)
      .RetiresOnSaturation();

  EXPECT_CALL(*gl_,
              FramebufferTexture2DEXT(GL_DRAW_FRAMEBUFFER_EXT,
                                      attachment,
                                      target,
                                      kServiceTextureId,
                                      level))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, CheckFramebufferStatusEXT(GL_DRAW_FRAMEBUFFER_EXT))
      .WillOnce(Return(GL_FRAMEBUFFER_COMPLETE))
      .RetiresOnSaturation();

  EXPECT_CALL(*gl_, ClearStencil(0)).Times(1).RetiresOnSaturation();
  SetupExpectationsForStencilMask(GLES2Decoder::kDefaultStencilMask,
                                  GLES2Decoder::kDefaultStencilMask);
  EXPECT_CALL(*gl_, ClearDepth(1.0f)).Times(1).RetiresOnSaturation();
  SetupExpectationsForDepthMask(true);
  SetupExpectationsForEnableDisable(GL_SCISSOR_TEST, false);

  EXPECT_CALL(*gl_, Clear(GL_DEPTH_BUFFER_BIT)).Times(1).RetiresOnSaturation();

  SetupExpectationsForRestoreClearState(0.0f, 0.0f, 0.0f, 0.0f, 0, 1.0f, true);

  EXPECT_CALL(*gl_, DeleteFramebuffersEXT(1, _)).Times(1).RetiresOnSaturation();
  EXPECT_CALL(*gl_, BindFramebufferEXT(GL_DRAW_FRAMEBUFFER_EXT, 0))
      .Times(1)
      .RetiresOnSaturation();

  SetupExpectationsForApplyingDefaultDirtyState();
  EXPECT_CALL(*gl_, DrawArrays(GL_TRIANGLES, 0, kNumVertices))
      .Times(1)
      .RetiresOnSaturation();
  DrawArrays cmd;
  cmd.Init(GL_TRIANGLES, 0, kNumVertices);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}

}  // namespace gles2
}  // namespace gpu
