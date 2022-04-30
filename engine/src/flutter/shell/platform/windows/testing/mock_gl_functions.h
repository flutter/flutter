// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_GL_FUNCTIONS_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_GL_FUNCTIONS_H_

#include "flutter/shell/platform/windows/external_texture.h"

namespace flutter {
namespace testing {

// A class providing a mocked subset of OpenGL API functions.
class MockGlFunctions {
 public:
  MockGlFunctions() {
    gl_procs_.glGenTextures = &glGenTextures;
    gl_procs_.glDeleteTextures = &glDeleteTextures;
    gl_procs_.glBindTexture = &glBindTexture;
    gl_procs_.glTexParameteri = &glTexParameteri;
    gl_procs_.glTexImage2D = &glTexImage2D;
    gl_procs_.valid = true;
  }

  const GlProcs& gl_procs() { return gl_procs_; }

  static void glGenTextures(GLsizei n, GLuint* textures) {
    // The minimum valid texture ID is 1
    for (auto i = 0; i < n; i++) {
      textures[i] = i + 1;
    }
  }

  static void glDeleteTextures(GLsizei n, const GLuint* textures) {}
  static void glBindTexture(GLenum target, GLuint texture) {}
  static void glTexParameteri(GLenum target, GLenum pname, GLint param) {}
  static void glTexImage2D(GLenum target,
                           GLint level,
                           GLint internalformat,
                           GLsizei width,
                           GLsizei height,
                           GLint border,
                           GLenum format,
                           GLenum type,
                           const void* data) {}

 private:
  GlProcs gl_procs_;
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_GL_FUNCTIONS_H_
