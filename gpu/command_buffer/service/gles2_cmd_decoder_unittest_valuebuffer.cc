// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/gles2_cmd_decoder.h"

#include "base/command_line.h"
#include "gpu/command_buffer/common/gles2_cmd_format.h"
#include "gpu/command_buffer/common/gles2_cmd_utils.h"
#include "gpu/command_buffer/service/gles2_cmd_decoder_unittest.h"
#include "gpu/command_buffer/service/test_helper.h"
#include "gpu/command_buffer/service/valuebuffer_manager.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_mock.h"
#include "ui/gl/gl_surface_stub.h"

using ::gfx::MockGLInterface;
using ::testing::_;

namespace gpu {
namespace gles2 {

using namespace cmds;

TEST_P(GLES2DecoderWithShaderTest, ValuebufferBasic) {
  const uint32 kBufferId = 123;
  ValueState valuestate;
  valuestate.int_value[0] = 111;
  valuestate.int_value[1] = 222;
  valuebuffer_manager()->CreateValuebuffer(kBufferId);
  pending_valuebuffer_state()->UpdateState(
      GL_MOUSE_POSITION_CHROMIUM, valuestate);
  BindValuebufferCHROMIUM cmd1;
  cmd1.Init(GL_SUBSCRIBED_VALUES_BUFFER_CHROMIUM, kBufferId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd1));
  SubscribeValueCHROMIUM cmd2;
  cmd2.Init(GL_SUBSCRIBED_VALUES_BUFFER_CHROMIUM, GL_MOUSE_POSITION_CHROMIUM);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  PopulateSubscribedValuesCHROMIUM cmd3;
  cmd3.Init(GL_SUBSCRIBED_VALUES_BUFFER_CHROMIUM);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd3));
  EXPECT_CALL(*gl_, Uniform2iv(kUniform2RealLocation, 1, _)).Times(1);
  UniformValuebufferCHROMIUM cmd4;
  cmd4.Init(kUniform2FakeLocation, GL_SUBSCRIBED_VALUES_BUFFER_CHROMIUM,
            GL_MOUSE_POSITION_CHROMIUM);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd4));
}

TEST_P(GLES2DecoderWithShaderTest, SubscribeValuebufferNotBound) {
  const uint32 kBufferId = 123;
  ValueState valuestate;
  valuestate.int_value[0] = 111;
  valuestate.int_value[1] = 222;
  valuebuffer_manager()->CreateValuebuffer(kBufferId);
  pending_valuebuffer_state()->UpdateState(
      GL_MOUSE_POSITION_CHROMIUM, valuestate);
  SubscribeValueCHROMIUM cmd1;
  cmd1.Init(GL_SUBSCRIBED_VALUES_BUFFER_CHROMIUM, GL_MOUSE_POSITION_CHROMIUM);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd1));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, PopulateValuebufferNoSubscription) {
  const uint32 kBufferId = 123;
  ValueState valuestate;
  valuestate.int_value[0] = 111;
  valuestate.int_value[1] = 222;
  valuebuffer_manager()->CreateValuebuffer(kBufferId);
  pending_valuebuffer_state()->UpdateState(
      GL_MOUSE_POSITION_CHROMIUM, valuestate);
  BindValuebufferCHROMIUM cmd1;
  cmd1.Init(GL_SUBSCRIBED_VALUES_BUFFER_CHROMIUM, kBufferId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd1));
  PopulateSubscribedValuesCHROMIUM cmd2;
  cmd2.Init(GL_SUBSCRIBED_VALUES_BUFFER_CHROMIUM);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_EQ(GL_NONE, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, UniformValuebufferNoState) {
  const uint32 kBufferId = 123;
  ValueState valuestate;
  valuestate.int_value[0] = 111;
  valuestate.int_value[1] = 222;
  valuebuffer_manager()->CreateValuebuffer(kBufferId);
  pending_valuebuffer_state()->UpdateState(
      GL_MOUSE_POSITION_CHROMIUM, valuestate);
  BindValuebufferCHROMIUM cmd1;
  cmd1.Init(GL_SUBSCRIBED_VALUES_BUFFER_CHROMIUM, kBufferId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd1));
  SubscribeValueCHROMIUM cmd2;
  cmd2.Init(GL_SUBSCRIBED_VALUES_BUFFER_CHROMIUM, GL_MOUSE_POSITION_CHROMIUM);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  EXPECT_CALL(*gl_, Uniform2iv(kUniform2RealLocation, 1, _)).Times(0);
  UniformValuebufferCHROMIUM cmd3;
  cmd3.Init(kUniform2FakeLocation, GL_SUBSCRIBED_VALUES_BUFFER_CHROMIUM,
            GL_MOUSE_POSITION_CHROMIUM);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd3));
  EXPECT_EQ(GL_NONE, GetGLError());
}

TEST_P(GLES2DecoderWithShaderTest, UniformValuebufferInvalidLocation) {
  const uint32 kBufferId = 123;
  ValueState valuestate;
  valuestate.int_value[0] = 111;
  valuestate.int_value[1] = 222;
  valuebuffer_manager()->CreateValuebuffer(kBufferId);
  pending_valuebuffer_state()->UpdateState(
      GL_MOUSE_POSITION_CHROMIUM, valuestate);
  BindValuebufferCHROMIUM cmd1;
  cmd1.Init(GL_SUBSCRIBED_VALUES_BUFFER_CHROMIUM, kBufferId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd1));
  SubscribeValueCHROMIUM cmd2;
  cmd2.Init(GL_SUBSCRIBED_VALUES_BUFFER_CHROMIUM, GL_MOUSE_POSITION_CHROMIUM);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd2));
  PopulateSubscribedValuesCHROMIUM cmd3;
  cmd3.Init(GL_SUBSCRIBED_VALUES_BUFFER_CHROMIUM);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd3));
  EXPECT_CALL(*gl_, Uniform2iv(kUniform2RealLocation, 1, _)).Times(0);
  UniformValuebufferCHROMIUM cmd4;
  cmd4.Init(kUniform1FakeLocation, GL_SUBSCRIBED_VALUES_BUFFER_CHROMIUM,
            GL_MOUSE_POSITION_CHROMIUM);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd4));
  EXPECT_EQ(GL_INVALID_OPERATION, GetGLError());
}

}  // namespace gles2
}  // namespace gpu
