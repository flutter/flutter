// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Helper functions for GL.

#ifndef GPU_COMMAND_BUFFER_TESTS_GL_TEST_UTILS_H_
#define GPU_COMMAND_BUFFER_TESTS_GL_TEST_UTILS_H_

#include <GLES2/gl2.h>
#include "base/basictypes.h"

class GLTestHelper {
 public:
  static const uint8 kCheckClearValue = 123u;

  static bool HasExtension(const char* extension);
  static bool CheckGLError(const char* msg, int line);

  // Compiles a shader.
  // Does not check for errors, always returns shader.
  static GLuint CompileShader(GLenum type, const char* shaderSrc);

  // Compiles a shader and checks for compilation errors.
  // Returns shader, 0 on failure.
  static GLuint LoadShader(GLenum type, const char* shaderSrc);

  // Attaches 2 shaders and links them to a program.
  // Does not check for errors, always returns program.
  static GLuint LinkProgram(GLuint vertex_shader, GLuint fragment_shader);

  // Attaches 2 shaders, links them to a program, and checks for errors.
  // Returns program, 0 on failure.
  static GLuint SetupProgram(GLuint vertex_shader, GLuint fragment_shader);

  // Compiles 2 shaders, attaches and links them to a program
  // Returns program, 0 on failure.
  static GLuint LoadProgram(
      const char* vertex_shader_source,
      const char* fragment_shader_source);

  // Make a unit quad with position only.
  // Returns the created buffer.
  static GLuint SetupUnitQuad(GLint position_location);

  // Make a 6 vertex colors.
  // Returns the created buffer.
  static GLuint SetupColorsForUnitQuad(
      GLint location, const GLfloat color[4], GLenum usage);

  // Checks an area of pixels for a color.
  static bool CheckPixels(
      GLint x, GLint y, GLsizei width, GLsizei height, GLint tolerance,
      const uint8* color);

  // Uses ReadPixels to save an area of the current FBO/Backbuffer.
  static bool SaveBackbufferAsBMP(const char* filename, int width, int height);
};

#endif  // GPU_COMMAND_BUFFER_TESTS_GL_TEST_UTILS_H_
