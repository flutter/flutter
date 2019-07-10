// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/test_gl_surface.h"

#include <EGL/egl.h>
#include <GLES2/gl2.h>

#include <sstream>
#include <string>

#include "flutter/fml/logging.h"
#include "third_party/skia/include/gpu/gl/GrGLAssembleInterface.h"

namespace flutter {
namespace testing {

static std::string GetEGLError() {
  std::stringstream stream;

  auto error = ::eglGetError();

  stream << "EGL Result: '";

  switch (error) {
    case EGL_SUCCESS:
      stream << "EGL_SUCCESS";
      break;
    case EGL_NOT_INITIALIZED:
      stream << "EGL_NOT_INITIALIZED";
      break;
    case EGL_BAD_ACCESS:
      stream << "EGL_BAD_ACCESS";
      break;
    case EGL_BAD_ALLOC:
      stream << "EGL_BAD_ALLOC";
      break;
    case EGL_BAD_ATTRIBUTE:
      stream << "EGL_BAD_ATTRIBUTE";
      break;
    case EGL_BAD_CONTEXT:
      stream << "EGL_BAD_CONTEXT";
      break;
    case EGL_BAD_CONFIG:
      stream << "EGL_BAD_CONFIG";
      break;
    case EGL_BAD_CURRENT_SURFACE:
      stream << "EGL_BAD_CURRENT_SURFACE";
      break;
    case EGL_BAD_DISPLAY:
      stream << "EGL_BAD_DISPLAY";
      break;
    case EGL_BAD_SURFACE:
      stream << "EGL_BAD_SURFACE";
      break;
    case EGL_BAD_MATCH:
      stream << "EGL_BAD_MATCH";
      break;
    case EGL_BAD_PARAMETER:
      stream << "EGL_BAD_PARAMETER";
      break;
    case EGL_BAD_NATIVE_PIXMAP:
      stream << "EGL_BAD_NATIVE_PIXMAP";
      break;
    case EGL_BAD_NATIVE_WINDOW:
      stream << "EGL_BAD_NATIVE_WINDOW";
      break;
    case EGL_CONTEXT_LOST:
      stream << "EGL_CONTEXT_LOST";
      break;
    default:
      stream << "Unknown";
  }

  stream << "' (0x" << std::hex << error << std::dec << ").";
  return stream.str();
}

TestGLSurface::TestGLSurface() {
  display_ = ::eglGetDisplay(EGL_DEFAULT_DISPLAY);
  FML_CHECK(display_ != EGL_NO_DISPLAY);

  auto result = ::eglInitialize(display_, NULL, NULL);
  FML_CHECK(result == EGL_TRUE) << GetEGLError();

  EGLConfig config = {0};

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

  result = ::eglChooseConfig(display_, attribute_list, &config, 1, &num_config);
  FML_CHECK(result == EGL_TRUE) << GetEGLError();
  FML_CHECK(num_config == 1) << GetEGLError();

  {
    const EGLint surface_attributes[] = {
        EGL_HEIGHT, 1,  //
        EGL_WIDTH,  1,  //
        EGL_NONE,
    };

    onscreen_surface_ =
        ::eglCreatePbufferSurface(display_,           // display connection
                                  config,             // config
                                  surface_attributes  // surface attributes
        );
    FML_CHECK(onscreen_surface_ != EGL_NO_SURFACE) << GetEGLError();

    offscreen_surface_ =
        ::eglCreatePbufferSurface(display_,           // display connection
                                  config,             // config
                                  surface_attributes  // surface attributes
        );
    FML_CHECK(offscreen_surface_ != EGL_NO_SURFACE) << GetEGLError();
  }

  {
    const EGLint context_attributes[] = {
        EGL_CONTEXT_CLIENT_VERSION,  //
        2,                           //
        EGL_NONE                     //
    };

    onscreen_context_ =
        ::eglCreateContext(display_,           // display connection
                           config,             // config
                           EGL_NO_CONTEXT,     // sharegroup
                           context_attributes  // context attributes
        );
    FML_CHECK(onscreen_context_ != EGL_NO_CONTEXT) << GetEGLError();

    offscreen_context_ =
        ::eglCreateContext(display_,           // display connection
                           config,             // config
                           onscreen_context_,  // sharegroup
                           context_attributes  // context attributes
        );
    FML_CHECK(offscreen_context_ != EGL_NO_CONTEXT) << GetEGLError();
  }
}

TestGLSurface::~TestGLSurface() {
  auto result = ::eglDestroyContext(display_, onscreen_context_);
  FML_CHECK(result == EGL_TRUE) << GetEGLError();

  result = ::eglDestroyContext(display_, offscreen_context_);
  FML_CHECK(result == EGL_TRUE) << GetEGLError();

  result = ::eglDestroySurface(display_, onscreen_surface_);
  FML_CHECK(result == EGL_TRUE) << GetEGLError();

  result = ::eglDestroySurface(display_, offscreen_surface_);
  FML_CHECK(result == EGL_TRUE) << GetEGLError();

  result = ::eglTerminate(display_);
  FML_CHECK(result == EGL_TRUE);
}

bool TestGLSurface::MakeCurrent() {
  auto result = ::eglMakeCurrent(display_, onscreen_surface_, onscreen_surface_,
                                 onscreen_context_);

  if (result == EGL_FALSE) {
    FML_LOG(ERROR) << "Could not make the context current. " << GetEGLError();
  }

  return result == EGL_TRUE;
}

bool TestGLSurface::ClearCurrent() {
  auto result = ::eglMakeCurrent(display_, EGL_NO_SURFACE, EGL_NO_SURFACE,
                                 EGL_NO_CONTEXT);

  if (result == EGL_FALSE) {
    FML_LOG(ERROR) << "Could not clear the current context. " << GetEGLError();
  }

  return result == EGL_TRUE;
}

bool TestGLSurface::Present() {
  auto result = ::eglSwapBuffers(display_, onscreen_surface_);

  if (result == EGL_FALSE) {
    FML_LOG(ERROR) << "Could not swap buffers. " << GetEGLError();
  }

  return result == EGL_TRUE;
}

uint32_t TestGLSurface::GetFramebuffer() const {
  // Return FBO0
  return 0;
}

bool TestGLSurface::MakeResourceCurrent() {
  auto result = ::eglMakeCurrent(display_, offscreen_surface_,
                                 offscreen_surface_, offscreen_context_);

  if (result == EGL_FALSE) {
    FML_LOG(ERROR) << "Could not make the resource context current. "
                   << GetEGLError();
  }

  return result == EGL_TRUE;
}

void* TestGLSurface::GetProcAddress(const char* name) const {
  if (name == nullptr) {
    return nullptr;
  }
  auto symbol = ::eglGetProcAddress(name);
  if (symbol == NULL) {
    FML_LOG(ERROR) << "Could not fetch symbol for name: " << name;
  }
  return reinterpret_cast<void*>(symbol);
}

sk_sp<GrContext> TestGLSurface::CreateContext() {
  if (!MakeCurrent()) {
    return nullptr;
  }

  auto get_string =
      reinterpret_cast<PFNGLGETSTRINGPROC>(GetProcAddress("glGetString"));

  if (!get_string) {
    return nullptr;
  }

  auto c_version = reinterpret_cast<const char*>(get_string(GL_VERSION));

  if (c_version == NULL) {
    return nullptr;
  }

  GrGLGetProc get_proc = [](void* context, const char name[]) -> GrGLFuncPtr {
    return reinterpret_cast<GrGLFuncPtr>(
        reinterpret_cast<TestGLSurface*>(context)->GetProcAddress(name));
  };

  std::string version(c_version);
  auto interface = version.find("OpenGL ES") == std::string::npos
                       ? GrGLMakeAssembledGLInterface(this, get_proc)
                       : GrGLMakeAssembledGLESInterface(this, get_proc);

  if (!interface) {
    return nullptr;
  }

  return GrContext::MakeGL(interface);
}

}  // namespace testing
}  // namespace flutter
