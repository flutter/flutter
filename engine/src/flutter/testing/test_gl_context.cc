// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/test_gl_context.h"

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <EGL/eglplatform.h>

#include <cstring>

#include "flutter/fml/logging.h"
#include "flutter/testing/test_gl_utils.h"
#include "flutter/testing/test_swangle_utils.h"

namespace flutter::testing {

TestEGLContext::TestEGLContext() {
  display = CreateSwangleDisplay();
  FML_CHECK(display != EGL_NO_DISPLAY);

  auto result = ::eglInitialize(display, nullptr, nullptr);
  FML_CHECK(result == EGL_TRUE) << GetEGLError();

  config = {0};

  EGLint num_config = 0;
  const EGLint attribute_list[] = {EGL_RED_SIZE,
                                   8,
                                   EGL_GREEN_SIZE,
                                   8,
                                   EGL_BLUE_SIZE,
                                   8,
                                   EGL_ALPHA_SIZE,
                                   8,
                                   EGL_SURFACE_TYPE,
                                   EGL_PBUFFER_BIT,
                                   EGL_CONFORMANT,
                                   EGL_OPENGL_ES2_BIT,
                                   EGL_RENDERABLE_TYPE,
                                   EGL_OPENGL_ES2_BIT,
                                   EGL_NONE};

  result = ::eglChooseConfig(display, attribute_list, &config, 1, &num_config);
  FML_CHECK(result == EGL_TRUE) << GetEGLError();
  FML_CHECK(num_config == 1) << GetEGLError();

  {
    const EGLint context_attributes[] = {
        EGL_CONTEXT_CLIENT_VERSION,  //
        2,                           //
        EGL_NONE                     //
    };

    onscreen_context =
        ::eglCreateContext(display,            // display connection
                           config,             // config
                           EGL_NO_CONTEXT,     // sharegroup
                           context_attributes  // context attributes
        );
    FML_CHECK(onscreen_context != EGL_NO_CONTEXT) << GetEGLError();

    offscreen_context =
        ::eglCreateContext(display,            // display connection
                           config,             // config
                           onscreen_context,   // sharegroup
                           context_attributes  // context attributes
        );
    FML_CHECK(offscreen_context != EGL_NO_CONTEXT) << GetEGLError();
  }
}

TestEGLContext::~TestEGLContext() {
  auto result = ::eglDestroyContext(display, onscreen_context);
  FML_CHECK(result == EGL_TRUE) << GetEGLError();

  result = ::eglDestroyContext(display, offscreen_context);
  FML_CHECK(result == EGL_TRUE) << GetEGLError();

  result = ::eglTerminate(display);
  FML_CHECK(result == EGL_TRUE);
}

}  // namespace flutter::testing
