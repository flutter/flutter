// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/gles2_cmd_decoder.h"

#include "gpu/command_buffer/common/gles2_cmd_format.h"
#include "gpu/command_buffer/common/gles2_cmd_utils.h"
#include "gpu/command_buffer/service/gles2_cmd_decoder_unittest.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gl/gl_mock.h"

using ::gfx::MockGLInterface;
using ::testing::_;

namespace gpu {
namespace gles2 {

class GLES2DecoderTestWithCHROMIUMPathRendering : public GLES2DecoderTest {
 public:
  GLES2DecoderTestWithCHROMIUMPathRendering() {}
  void SetUp() override {
    InitState init;
    init.gl_version = "opengl es 3.1";
    init.has_alpha = true;
    init.has_depth = true;
    init.request_alpha = true;
    init.request_depth = true;
    init.bind_generates_resource = true;
    init.extensions = "GL_NV_path_rendering";
    InitDecoder(init);
  }
};

INSTANTIATE_TEST_CASE_P(Service,
                        GLES2DecoderTestWithCHROMIUMPathRendering,
                        ::testing::Bool());

class GLES2DecoderTestWithBlendEquationAdvanced : public GLES2DecoderTest {
 public:
  GLES2DecoderTestWithBlendEquationAdvanced() {}
  void SetUp() override {
    InitState init;
    init.gl_version = "opengl es 2.0";
    init.has_alpha = true;
    init.has_depth = true;
    init.request_alpha = true;
    init.request_depth = true;
    init.bind_generates_resource = true;
    init.extensions = "GL_KHR_blend_equation_advanced";
    InitDecoder(init);
  }
};

INSTANTIATE_TEST_CASE_P(Service,
                        GLES2DecoderTestWithBlendEquationAdvanced,
                        ::testing::Bool());

#include "gpu/command_buffer/service/gles2_cmd_decoder_unittest_extensions_autogen.h"

}  // namespace gles2
}  // namespace gpu

