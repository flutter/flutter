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

class GLES2DecoderRestoreStateTest : public GLES2DecoderManualInitTest {
 public:
  GLES2DecoderRestoreStateTest() {}

 protected:
  void AddExpectationsForActiveTexture(GLenum unit);
  void AddExpectationsForBindTexture(GLenum target, GLuint id);
  void InitializeContextState(ContextState* state,
                              uint32 non_default_unit,
                              uint32 active_unit);
};

INSTANTIATE_TEST_CASE_P(Service,
                        GLES2DecoderRestoreStateTest,
                        ::testing::Bool());

void GLES2DecoderRestoreStateTest::AddExpectationsForActiveTexture(
    GLenum unit) {
  EXPECT_CALL(*gl_, ActiveTexture(unit)).Times(1).RetiresOnSaturation();
}

void GLES2DecoderRestoreStateTest::AddExpectationsForBindTexture(GLenum target,
                                                                 GLuint id) {
  EXPECT_CALL(*gl_, BindTexture(target, id)).Times(1).RetiresOnSaturation();
}

void GLES2DecoderRestoreStateTest::InitializeContextState(
    ContextState* state,
    uint32 non_default_unit,
    uint32 active_unit) {
  state->texture_units.resize(group().max_texture_units());
  for (uint32 tt = 0; tt < state->texture_units.size(); ++tt) {
    TextureRef* ref_cube_map =
        group().texture_manager()->GetDefaultTextureInfo(GL_TEXTURE_CUBE_MAP);
    state->texture_units[tt].bound_texture_cube_map = ref_cube_map;
    TextureRef* ref_2d =
        (tt == non_default_unit)
            ? group().texture_manager()->GetTexture(client_texture_id_)
            : group().texture_manager()->GetDefaultTextureInfo(GL_TEXTURE_2D);
    state->texture_units[tt].bound_texture_2d = ref_2d;
  }
  state->active_texture_unit = active_unit;
}

TEST_P(GLES2DecoderRestoreStateTest, NullPreviousStateBGR) {
  InitState init;
  init.bind_generates_resource = true;
  InitDecoder(init);
  SetupTexture();

  InSequence sequence;
  // Expect to restore texture bindings for unit GL_TEXTURE0.
  AddExpectationsForActiveTexture(GL_TEXTURE0);
  AddExpectationsForBindTexture(GL_TEXTURE_2D, kServiceTextureId);
  AddExpectationsForBindTexture(GL_TEXTURE_CUBE_MAP,
                                TestHelper::kServiceDefaultTextureCubemapId);

  // Expect to restore texture bindings for remaining units.
  for (uint32 i = 1; i < group().max_texture_units(); ++i) {
    AddExpectationsForActiveTexture(GL_TEXTURE0 + i);
    AddExpectationsForBindTexture(GL_TEXTURE_2D,
                                  TestHelper::kServiceDefaultTexture2dId);
    AddExpectationsForBindTexture(GL_TEXTURE_CUBE_MAP,
                                  TestHelper::kServiceDefaultTextureCubemapId);
  }

  // Expect to restore the active texture unit to GL_TEXTURE0.
  AddExpectationsForActiveTexture(GL_TEXTURE0);

  GetDecoder()->RestoreAllTextureUnitBindings(NULL);
}

TEST_P(GLES2DecoderRestoreStateTest, NullPreviousState) {
  InitState init;
  InitDecoder(init);
  SetupTexture();

  InSequence sequence;
  // Expect to restore texture bindings for unit GL_TEXTURE0.
  AddExpectationsForActiveTexture(GL_TEXTURE0);
  AddExpectationsForBindTexture(GL_TEXTURE_2D, kServiceTextureId);
  AddExpectationsForBindTexture(GL_TEXTURE_CUBE_MAP, 0);

  // Expect to restore texture bindings for remaining units.
  for (uint32 i = 1; i < group().max_texture_units(); ++i) {
    AddExpectationsForActiveTexture(GL_TEXTURE0 + i);
    AddExpectationsForBindTexture(GL_TEXTURE_2D, 0);
    AddExpectationsForBindTexture(GL_TEXTURE_CUBE_MAP, 0);
  }

  // Expect to restore the active texture unit to GL_TEXTURE0.
  AddExpectationsForActiveTexture(GL_TEXTURE0);

  GetDecoder()->RestoreAllTextureUnitBindings(NULL);
}

TEST_P(GLES2DecoderRestoreStateTest, WithPreviousStateBGR) {
  InitState init;
  init.bind_generates_resource = true;
  InitDecoder(init);
  SetupTexture();

  // Construct a previous ContextState with all texture bindings
  // set to default textures.
  ContextState prev_state(NULL, NULL, NULL);
  InitializeContextState(&prev_state, std::numeric_limits<uint32>::max(), 0);

  InSequence sequence;
  // Expect to restore only GL_TEXTURE_2D binding for GL_TEXTURE0 unit,
  // since the rest of the bindings haven't changed between the current
  // state and the |prev_state|.
  AddExpectationsForActiveTexture(GL_TEXTURE0);
  AddExpectationsForBindTexture(GL_TEXTURE_2D, kServiceTextureId);

  // Expect to restore active texture unit to GL_TEXTURE0.
  AddExpectationsForActiveTexture(GL_TEXTURE0);

  GetDecoder()->RestoreAllTextureUnitBindings(&prev_state);
}

TEST_P(GLES2DecoderRestoreStateTest, WithPreviousState) {
  InitState init;
  InitDecoder(init);
  SetupTexture();

  // Construct a previous ContextState with all texture bindings
  // set to default textures.
  ContextState prev_state(NULL, NULL, NULL);
  InitializeContextState(&prev_state, std::numeric_limits<uint32>::max(), 0);

  InSequence sequence;
  // Expect to restore only GL_TEXTURE_2D binding for GL_TEXTURE0 unit,
  // since the rest of the bindings haven't changed between the current
  // state and the |prev_state|.
  AddExpectationsForActiveTexture(GL_TEXTURE0);
  AddExpectationsForBindTexture(GL_TEXTURE_2D, kServiceTextureId);

  // Expect to restore active texture unit to GL_TEXTURE0.
  AddExpectationsForActiveTexture(GL_TEXTURE0);

  GetDecoder()->RestoreAllTextureUnitBindings(&prev_state);
}

TEST_P(GLES2DecoderRestoreStateTest, ActiveUnit1) {
  InitState init;
  InitDecoder(init);

  // Bind a non-default texture to GL_TEXTURE1 unit.
  EXPECT_CALL(*gl_, ActiveTexture(GL_TEXTURE1));
  ActiveTexture cmd;
  cmd.Init(GL_TEXTURE1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  SetupTexture();

  // Construct a previous ContextState with all texture bindings
  // set to default textures.
  ContextState prev_state(NULL, NULL, NULL);
  InitializeContextState(&prev_state, std::numeric_limits<uint32>::max(), 0);

  InSequence sequence;
  // Expect to restore only GL_TEXTURE_2D binding for GL_TEXTURE1 unit,
  // since the rest of the bindings haven't changed between the current
  // state and the |prev_state|.
  AddExpectationsForActiveTexture(GL_TEXTURE1);
  AddExpectationsForBindTexture(GL_TEXTURE_2D, kServiceTextureId);

  // Expect to restore active texture unit to GL_TEXTURE1.
  AddExpectationsForActiveTexture(GL_TEXTURE1);

  GetDecoder()->RestoreAllTextureUnitBindings(&prev_state);
}

TEST_P(GLES2DecoderRestoreStateTest, NonDefaultUnit0BGR) {
  InitState init;
  init.bind_generates_resource = true;
  InitDecoder(init);

  // Bind a non-default texture to GL_TEXTURE1 unit.
  EXPECT_CALL(*gl_, ActiveTexture(GL_TEXTURE1));
  SpecializedSetup<ActiveTexture, 0>(true);
  ActiveTexture cmd;
  cmd.Init(GL_TEXTURE1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  SetupTexture();

  // Construct a previous ContextState with GL_TEXTURE_2D target in
  // GL_TEXTURE0 unit bound to a non-default texture and the rest
  // set to default textures.
  ContextState prev_state(NULL, NULL, NULL);
  InitializeContextState(&prev_state, 0, kServiceTextureId);

  InSequence sequence;
  // Expect to restore GL_TEXTURE_2D binding for GL_TEXTURE0 unit to
  // a default texture.
  AddExpectationsForActiveTexture(GL_TEXTURE0);
  AddExpectationsForBindTexture(GL_TEXTURE_2D,
                                TestHelper::kServiceDefaultTexture2dId);

  // Expect to restore GL_TEXTURE_2D binding for GL_TEXTURE1 unit to
  // non-default.
  AddExpectationsForActiveTexture(GL_TEXTURE1);
  AddExpectationsForBindTexture(GL_TEXTURE_2D, kServiceTextureId);

  // Expect to restore active texture unit to GL_TEXTURE1.
  AddExpectationsForActiveTexture(GL_TEXTURE1);

  GetDecoder()->RestoreAllTextureUnitBindings(&prev_state);
}

TEST_P(GLES2DecoderRestoreStateTest, NonDefaultUnit1BGR) {
  InitState init;
  init.bind_generates_resource = true;
  InitDecoder(init);

  // Bind a non-default texture to GL_TEXTURE0 unit.
  SetupTexture();

  // Construct a previous ContextState with GL_TEXTURE_2D target in
  // GL_TEXTURE1 unit bound to a non-default texture and the rest
  // set to default textures.
  ContextState prev_state(NULL, NULL, NULL);
  InitializeContextState(&prev_state, 1, kServiceTextureId);

  InSequence sequence;
  // Expect to restore GL_TEXTURE_2D binding to the non-default texture
  // for GL_TEXTURE0 unit.
  AddExpectationsForActiveTexture(GL_TEXTURE0);
  AddExpectationsForBindTexture(GL_TEXTURE_2D, kServiceTextureId);

  // Expect to restore GL_TEXTURE_2D binding to the default texture
  // for GL_TEXTURE1 unit.
  AddExpectationsForActiveTexture(GL_TEXTURE1);
  AddExpectationsForBindTexture(GL_TEXTURE_2D,
                                TestHelper::kServiceDefaultTexture2dId);

  // Expect to restore active texture unit to GL_TEXTURE0.
  AddExpectationsForActiveTexture(GL_TEXTURE0);

  GetDecoder()->RestoreAllTextureUnitBindings(&prev_state);
}

TEST_P(GLES2DecoderRestoreStateTest, DefaultUnit0) {
  InitState init;
  InitDecoder(init);

  // Bind a non-default texture to GL_TEXTURE1 unit.
  EXPECT_CALL(*gl_, ActiveTexture(GL_TEXTURE1));
  SpecializedSetup<ActiveTexture, 0>(true);
  ActiveTexture cmd;
  cmd.Init(GL_TEXTURE1);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  SetupTexture();

  // Construct a previous ContextState with GL_TEXTURE_2D target in
  // GL_TEXTURE0 unit bound to a non-default texture and the rest
  // set to default textures.
  ContextState prev_state(NULL, NULL, NULL);
  InitializeContextState(&prev_state, 0, kServiceTextureId);

  InSequence sequence;
  // Expect to restore GL_TEXTURE_2D binding for GL_TEXTURE0 unit to
  // the 0 texture.
  AddExpectationsForActiveTexture(GL_TEXTURE0);
  AddExpectationsForBindTexture(GL_TEXTURE_2D, 0);

  // Expect to restore GL_TEXTURE_2D binding for GL_TEXTURE1 unit to
  // non-default.
  AddExpectationsForActiveTexture(GL_TEXTURE1);
  AddExpectationsForBindTexture(GL_TEXTURE_2D, kServiceTextureId);

  // Expect to restore active texture unit to GL_TEXTURE1.
  AddExpectationsForActiveTexture(GL_TEXTURE1);

  GetDecoder()->RestoreAllTextureUnitBindings(&prev_state);
}

TEST_P(GLES2DecoderRestoreStateTest, DefaultUnit1) {
  InitState init;
  InitDecoder(init);

  // Bind a non-default texture to GL_TEXTURE0 unit.
  SetupTexture();

  // Construct a previous ContextState with GL_TEXTURE_2D target in
  // GL_TEXTURE1 unit bound to a non-default texture and the rest
  // set to default textures.
  ContextState prev_state(NULL, NULL, NULL);
  InitializeContextState(&prev_state, 1, kServiceTextureId);

  InSequence sequence;
  // Expect to restore GL_TEXTURE_2D binding to the non-default texture
  // for GL_TEXTURE0 unit.
  AddExpectationsForActiveTexture(GL_TEXTURE0);
  AddExpectationsForBindTexture(GL_TEXTURE_2D, kServiceTextureId);

  // Expect to restore GL_TEXTURE_2D binding to the 0 texture
  // for GL_TEXTURE1 unit.
  AddExpectationsForActiveTexture(GL_TEXTURE1);
  AddExpectationsForBindTexture(GL_TEXTURE_2D, 0);

  // Expect to restore active texture unit to GL_TEXTURE0.
  AddExpectationsForActiveTexture(GL_TEXTURE0);

  GetDecoder()->RestoreAllTextureUnitBindings(&prev_state);
}

TEST_P(GLES2DecoderManualInitTest, ContextStateCapabilityCaching) {
  struct TestInfo {
    GLenum gl_enum;
    bool default_state;
    bool expect_set;
  };

  // TODO(vmiura): Should autogen this to match build_gles2_cmd_buffer.py.
  TestInfo test[] = {{GL_BLEND, false, true},
                     {GL_CULL_FACE, false, true},
                     {GL_DEPTH_TEST, false, false},
                     {GL_DITHER, true, true},
                     {GL_POLYGON_OFFSET_FILL, false, true},
                     {GL_SAMPLE_ALPHA_TO_COVERAGE, false, true},
                     {GL_SAMPLE_COVERAGE, false, true},
                     {GL_SCISSOR_TEST, false, true},
                     {GL_STENCIL_TEST, false, false},
                     {0, false, false}};

  InitState init;
  InitDecoder(init);

  for (int i = 0; test[i].gl_enum; i++) {
    bool enable_state = test[i].default_state;

    // Test setting default state initially is ignored.
    EnableDisableTest(test[i].gl_enum, enable_state, test[i].expect_set);

    // Test new and cached state changes.
    for (int n = 0; n < 3; n++) {
      enable_state = !enable_state;
      EnableDisableTest(test[i].gl_enum, enable_state, test[i].expect_set);
      EnableDisableTest(test[i].gl_enum, enable_state, test[i].expect_set);
    }
  }
}

// TODO(vmiura): Tests for VAO restore.

// TODO(vmiura): Tests for ContextState::RestoreAttribute().

// TODO(vmiura): Tests for ContextState::RestoreBufferBindings().

// TODO(vmiura): Tests for ContextState::RestoreProgramBindings().

// TODO(vmiura): Tests for ContextState::RestoreRenderbufferBindings().

// TODO(vmiura): Tests for ContextState::RestoreProgramBindings().

// TODO(vmiura): Tests for ContextState::RestoreGlobalState().

}  // namespace gles2
}  // namespace gpu
