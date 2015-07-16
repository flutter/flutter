// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file implements mock GL Interface for unit testing. The interface
// corresponds to the set of functionally distinct GL functions defined in
// generate_bindings.py, which may originate from either desktop GL or GLES.

#ifndef UI_GL_GL_MOCK_H_
#define UI_GL_GL_MOCK_H_

#include "testing/gmock/include/gmock/gmock.h"
#include "ui/gl/gl_bindings.h"

namespace gfx {

class MockGLInterface {
 public:
  MockGLInterface();
  virtual ~MockGLInterface();

  // Set the functions called from the mock GL implementation for the purposes
  // of testing.
  static void SetGLInterface(MockGLInterface* gl_interface);

  // Find an entry point to the mock GL implementation.
  static void* GL_BINDING_CALL GetGLProcAddress(const char* name);

  // Include the auto-generated parts of this class. We split this because
  // it means we can easily edit the non-auto generated parts right here in
  // this file instead of having to edit some template or the code generator.

  // Member functions
  #include "gl_mock_autogen_gl.h"

 private:
  static MockGLInterface* interface_;

  // Static mock functions that invoke the member functions of interface_.
  #include "gl_bindings_autogen_mock.h"
};

}  // namespace gfx

#endif  // UI_GL_GL_MOCK_H_
