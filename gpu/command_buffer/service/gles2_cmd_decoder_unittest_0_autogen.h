// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is auto-generated from
// gpu/command_buffer/build_gles2_cmd_buffer.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

// It is included by gles2_cmd_decoder_unittest_base.cc
#ifndef GPU_COMMAND_BUFFER_SERVICE_GLES2_CMD_DECODER_UNITTEST_0_AUTOGEN_H_
#define GPU_COMMAND_BUFFER_SERVICE_GLES2_CMD_DECODER_UNITTEST_0_AUTOGEN_H_

void GLES2DecoderTestBase::SetupInitCapabilitiesExpectations(bool es3_capable) {
  ExpectEnableDisable(GL_BLEND, false);
  ExpectEnableDisable(GL_CULL_FACE, false);
  ExpectEnableDisable(GL_DEPTH_TEST, false);
  ExpectEnableDisable(GL_DITHER, true);
  ExpectEnableDisable(GL_POLYGON_OFFSET_FILL, false);
  ExpectEnableDisable(GL_SAMPLE_ALPHA_TO_COVERAGE, false);
  ExpectEnableDisable(GL_SAMPLE_COVERAGE, false);
  ExpectEnableDisable(GL_SCISSOR_TEST, false);
  ExpectEnableDisable(GL_STENCIL_TEST, false);
  if (es3_capable) {
    ExpectEnableDisable(GL_RASTERIZER_DISCARD, false);
    ExpectEnableDisable(GL_PRIMITIVE_RESTART_FIXED_INDEX, false);
  }
}

void GLES2DecoderTestBase::SetupInitStateExpectations() {
  EXPECT_CALL(*gl_, BlendColor(0.0f, 0.0f, 0.0f, 0.0f))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, BlendEquationSeparate(GL_FUNC_ADD, GL_FUNC_ADD))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, BlendFuncSeparate(GL_ONE, GL_ZERO, GL_ONE, GL_ZERO))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, ClearColor(0.0f, 0.0f, 0.0f, 0.0f))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, ClearDepth(1.0f)).Times(1).RetiresOnSaturation();
  EXPECT_CALL(*gl_, ClearStencil(0)).Times(1).RetiresOnSaturation();
  EXPECT_CALL(*gl_, ColorMask(true, true, true, true))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, CullFace(GL_BACK)).Times(1).RetiresOnSaturation();
  EXPECT_CALL(*gl_, DepthFunc(GL_LESS)).Times(1).RetiresOnSaturation();
  EXPECT_CALL(*gl_, DepthMask(true)).Times(1).RetiresOnSaturation();
  EXPECT_CALL(*gl_, DepthRange(0.0f, 1.0f)).Times(1).RetiresOnSaturation();
  EXPECT_CALL(*gl_, FrontFace(GL_CCW)).Times(1).RetiresOnSaturation();
  EXPECT_CALL(*gl_, Hint(GL_GENERATE_MIPMAP_HINT, GL_DONT_CARE))
      .Times(1)
      .RetiresOnSaturation();
  if (group_->feature_info()->feature_flags().oes_standard_derivatives) {
    EXPECT_CALL(*gl_,
                Hint(GL_FRAGMENT_SHADER_DERIVATIVE_HINT_OES, GL_DONT_CARE))
        .Times(1)
        .RetiresOnSaturation();
  }
  EXPECT_CALL(*gl_, LineWidth(1.0f)).Times(1).RetiresOnSaturation();
  if (group_->feature_info()->feature_flags().chromium_path_rendering) {
    EXPECT_CALL(*gl_, MatrixLoadfEXT(GL_PATH_MODELVIEW_CHROMIUM, _))
        .Times(1)
        .RetiresOnSaturation();
  }
  if (group_->feature_info()->feature_flags().chromium_path_rendering) {
    EXPECT_CALL(*gl_, MatrixLoadfEXT(GL_PATH_PROJECTION_CHROMIUM, _))
        .Times(1)
        .RetiresOnSaturation();
  }
  EXPECT_CALL(*gl_, PixelStorei(GL_PACK_ALIGNMENT, 4))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, PixelStorei(GL_UNPACK_ALIGNMENT, 4))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, PolygonOffset(0.0f, 0.0f)).Times(1).RetiresOnSaturation();
  EXPECT_CALL(*gl_, SampleCoverage(1.0f, false)).Times(1).RetiresOnSaturation();
  EXPECT_CALL(*gl_,
              Scissor(kViewportX, kViewportY, kViewportWidth, kViewportHeight))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, StencilFuncSeparate(GL_FRONT, GL_ALWAYS, 0, 0xFFFFFFFFU))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, StencilFuncSeparate(GL_BACK, GL_ALWAYS, 0, 0xFFFFFFFFU))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, StencilMaskSeparate(GL_FRONT, 0xFFFFFFFFU))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, StencilMaskSeparate(GL_BACK, 0xFFFFFFFFU))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, StencilOpSeparate(GL_FRONT, GL_KEEP, GL_KEEP, GL_KEEP))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_, StencilOpSeparate(GL_BACK, GL_KEEP, GL_KEEP, GL_KEEP))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*gl_,
              Viewport(kViewportX, kViewportY, kViewportWidth, kViewportHeight))
      .Times(1)
      .RetiresOnSaturation();
}
#endif  // GPU_COMMAND_BUFFER_SERVICE_GLES2_CMD_DECODER_UNITTEST_0_AUTOGEN_H_
