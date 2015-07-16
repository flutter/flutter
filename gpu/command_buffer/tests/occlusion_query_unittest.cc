// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>

#include "gpu/command_buffer/tests/gl_manager.h"
#include "gpu/command_buffer/tests/gl_test_utils.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace gpu {

class OcclusionQueryTest : public testing::Test {
 protected:
  void SetUp() override {
    GLManager::Options options;
    options.size = gfx::Size(512, 512);
    gl_.Initialize(options);
  }

  void TearDown() override { gl_.Destroy(); }

  void DrawRect(float x, float z, float scale, float* color);

  GLManager gl_;

  GLint position_loc_;
  GLint matrix_loc_;
  GLint color_loc_;
};

static void SetMatrix(float x, float z, float scale, float* matrix) {
  matrix[0] = scale;
  matrix[1] = 0.0f;
  matrix[2] = 0.0f;
  matrix[3] = 0.0f;

  matrix[4] = 0.0f;
  matrix[5] = scale;
  matrix[6] = 0.0f;
  matrix[7] = 0.0f;

  matrix[8] = 0.0f;
  matrix[9] = 0.0f;
  matrix[10] = scale;
  matrix[11] = 0.0f;

  matrix[12] = x;
  matrix[13] = 0.0f;
  matrix[14] = z;
  matrix[15] = 1.0f;
}

void OcclusionQueryTest::DrawRect(float x, float z, float scale, float* color) {
  GLfloat matrix[16];

  SetMatrix(x, z, scale, matrix);

  // Set up the model matrix
  glUniformMatrix4fv(matrix_loc_, 1, GL_FALSE, matrix);
  glUniform4fv(color_loc_, 1, color);

  glDrawArrays(GL_TRIANGLES, 0, 6);
}

TEST_F(OcclusionQueryTest, Occlusion) {
#if defined(OS_MACOSX)
  EXPECT_TRUE(GLTestHelper::HasExtension("GL_EXT_occlusion_query_boolean"))
      << "GL_EXT_occlusion_query_boolean is required on OSX";
#endif

  if (!GLTestHelper::HasExtension("GL_EXT_occlusion_query_boolean")) {
    return;
  }

  static const char* v_shader_str =
      "uniform mat4 worldMatrix;\n"
      "attribute vec3 g_Position;\n"
      "void main()\n"
      "{\n"
      "   gl_Position = worldMatrix *\n"
      "                 vec4(g_Position.x, g_Position.y, g_Position.z, 1.0);\n"
      "}\n";
  static const char* f_shader_str =
      "precision mediump float;"
      "uniform vec4 color;\n"
      "void main()\n"
      "{\n"
      "  gl_FragColor = color;\n"
      "}\n";

  GLuint program = GLTestHelper::LoadProgram(v_shader_str, f_shader_str);

  position_loc_ = glGetAttribLocation(program, "g_Position");
  matrix_loc_ = glGetUniformLocation(program, "worldMatrix");
  color_loc_ = glGetUniformLocation(program, "color");

  GLTestHelper::SetupUnitQuad(position_loc_);

  GLuint query = 0;
  glGenQueriesEXT(1, &query);

  glEnable(GL_DEPTH_TEST);
  glClearColor(0.0f, 0.1f, 0.2f, 1.0f);

  // Use the program object
  glUseProgram(program);

  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  static float red[] = { 1.0f, 0.0f, 0.0f, 1.0f };
  DrawRect(0, 0.0f, 0.50f, red);

  glBeginQueryEXT(GL_ANY_SAMPLES_PASSED_EXT, query);
  static float blue[] = { 0.0f, 0.0f, 1.0f, 1.0f };
  DrawRect(-0.125f, 0.1f, 0.25f, blue);
  glEndQueryEXT(GL_ANY_SAMPLES_PASSED_EXT);

  glFinish();

  GLuint query_status = 0;
  GLuint result = 0;
  glGetQueryObjectuivEXT(query, GL_QUERY_RESULT_AVAILABLE_EXT, &result);
  EXPECT_TRUE(result);
  glGetQueryObjectuivEXT(query, GL_QUERY_RESULT_EXT, &query_status);
  EXPECT_FALSE(query_status);

  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  DrawRect(1, 0.0f, 0.50f, red);

  glBeginQueryEXT(GL_ANY_SAMPLES_PASSED_EXT, query);
  DrawRect(-0.125f, 0.1f, 0.25f, blue);
  glEndQueryEXT(GL_ANY_SAMPLES_PASSED_EXT);

  glFinish();

  query_status = 0;
  result = 0;
  glGetQueryObjectuivEXT(query, GL_QUERY_RESULT_AVAILABLE_EXT, &result);
  EXPECT_TRUE(result);
  glGetQueryObjectuivEXT(query, GL_QUERY_RESULT_EXT, &query_status);
  EXPECT_TRUE(query_status);
  GLTestHelper::CheckGLError("no errors", __LINE__);
}

}  // namespace gpu


