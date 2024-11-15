// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/test_gl_surface.h"

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <EGL/eglplatform.h>
#include <GLES2/gl2.h>

#include <sstream>
#include <string>

#include "flutter/fml/build_config.h"
#include "flutter/fml/logging.h"
#include "third_party/skia/include/core/SkColorSpace.h"
#include "third_party/skia/include/core/SkColorType.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/gpu/ganesh/GrBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/SkSurfaceGanesh.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLAssembleInterface.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLDirectContext.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLTypes.h"

namespace flutter::testing {

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

static bool HasExtension(const char* extensions, const char* name) {
  const char* r = strstr(extensions, name);
  auto len = strlen(name);
  // check that the extension name is terminated by space or null terminator
  return r != nullptr && (r[len] == ' ' || r[len] == 0);
}

static void CheckSwanglekExtensions() {
  const char* extensions = ::eglQueryString(EGL_NO_DISPLAY, EGL_EXTENSIONS);
  FML_CHECK(HasExtension(extensions, "EGL_EXT_platform_base")) << extensions;
  FML_CHECK(HasExtension(extensions, "EGL_ANGLE_platform_angle_vulkan"))
      << extensions;
  FML_CHECK(HasExtension(extensions,
                         "EGL_ANGLE_platform_angle_device_type_swiftshader"))
      << extensions;
}

static EGLDisplay CreateSwangleDisplay() {
  CheckSwanglekExtensions();

  PFNEGLGETPLATFORMDISPLAYEXTPROC egl_get_platform_display_EXT =
      reinterpret_cast<PFNEGLGETPLATFORMDISPLAYEXTPROC>(
          eglGetProcAddress("eglGetPlatformDisplayEXT"));
  FML_CHECK(egl_get_platform_display_EXT)
      << "eglGetPlatformDisplayEXT not available.";

  const EGLint display_config[] = {
      EGL_PLATFORM_ANGLE_TYPE_ANGLE,
      EGL_PLATFORM_ANGLE_TYPE_VULKAN_ANGLE,
      EGL_PLATFORM_ANGLE_DEVICE_TYPE_ANGLE,
      EGL_PLATFORM_ANGLE_DEVICE_TYPE_SWIFTSHADER_ANGLE,
      EGL_PLATFORM_ANGLE_NATIVE_PLATFORM_TYPE_ANGLE,
      EGL_PLATFORM_VULKAN_DISPLAY_MODE_HEADLESS_ANGLE,
      EGL_NONE,
  };

  return egl_get_platform_display_EXT(
      EGL_PLATFORM_ANGLE_ANGLE,
      reinterpret_cast<EGLNativeDisplayType*>(EGL_DEFAULT_DISPLAY),
      display_config);
}

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

TestGLOnscreenOnlySurface::TestGLOnscreenOnlySurface(
    std::shared_ptr<TestEGLContext> context,
    SkISize size)
    : surface_size_(size), egl_context_(std::move(context)) {
  const EGLint attributes[] = {
      EGL_WIDTH,  size.width(),   //
      EGL_HEIGHT, size.height(),  //
      EGL_NONE,
  };

  onscreen_surface_ =
      ::eglCreatePbufferSurface(egl_context_->display,  // display connection
                                egl_context_->config,   // config
                                attributes              // surface attributes
      );
  FML_CHECK(onscreen_surface_ != EGL_NO_SURFACE) << GetEGLError();
}

TestGLOnscreenOnlySurface::~TestGLOnscreenOnlySurface() {
  skia_context_ = nullptr;

  auto result = ::eglDestroySurface(egl_context_->display, onscreen_surface_);
  FML_CHECK(result == EGL_TRUE) << GetEGLError();
}

const SkISize& TestGLOnscreenOnlySurface::GetSurfaceSize() const {
  return surface_size_;
}

bool TestGLOnscreenOnlySurface::MakeCurrent() {
  auto result =
      ::eglMakeCurrent(egl_context_->display, onscreen_surface_,
                       onscreen_surface_, egl_context_->onscreen_context);

  if (result == EGL_FALSE) {
    FML_LOG(ERROR) << "Could not make the context current. " << GetEGLError();
  }

  return result == EGL_TRUE;
}

bool TestGLOnscreenOnlySurface::ClearCurrent() {
  auto result = ::eglMakeCurrent(egl_context_->display, EGL_NO_SURFACE,
                                 EGL_NO_SURFACE, EGL_NO_CONTEXT);

  if (result == EGL_FALSE) {
    FML_LOG(ERROR) << "Could not clear the current context. " << GetEGLError();
  }

  return result == EGL_TRUE;
}

bool TestGLOnscreenOnlySurface::Present() {
  auto result = ::eglSwapBuffers(egl_context_->display, onscreen_surface_);

  if (result == EGL_FALSE) {
    FML_LOG(ERROR) << "Could not swap buffers. " << GetEGLError();
  }

  return result == EGL_TRUE;
}

uint32_t TestGLOnscreenOnlySurface::GetFramebuffer(uint32_t width,
                                                   uint32_t height) const {
  return GetWindowFBOId();
}

void* TestGLOnscreenOnlySurface::GetProcAddress(const char* name) const {
  if (name == nullptr) {
    return nullptr;
  }
  auto symbol = ::eglGetProcAddress(name);
  if (symbol == NULL) {
    FML_LOG(ERROR) << "Could not fetch symbol for name: " << name;
  }
  return reinterpret_cast<void*>(symbol);
}

sk_sp<GrDirectContext> TestGLOnscreenOnlySurface::GetGrContext() {
  if (skia_context_) {
    return skia_context_;
  }

  return CreateGrContext();
}

sk_sp<GrDirectContext> TestGLOnscreenOnlySurface::CreateGrContext() {
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
        reinterpret_cast<TestGLOnscreenOnlySurface*>(context)->GetProcAddress(
            name));
  };

  std::string version(c_version);
  auto interface = version.find("OpenGL ES") == std::string::npos
                       ? GrGLMakeAssembledGLInterface(this, get_proc)
                       : GrGLMakeAssembledGLESInterface(this, get_proc);

  if (!interface) {
    return nullptr;
  }

  skia_context_ = GrDirectContexts::MakeGL(interface);
  return skia_context_;
}

sk_sp<SkSurface> TestGLOnscreenOnlySurface::GetOnscreenSurface() {
  FML_CHECK(::eglGetCurrentContext() != EGL_NO_CONTEXT);

  GrGLFramebufferInfo framebuffer_info = {};
  const uint32_t width = surface_size_.width();
  const uint32_t height = surface_size_.height();
  framebuffer_info.fFBOID = GetFramebuffer(width, height);
#if FML_OS_MACOSX
  framebuffer_info.fFormat = 0x8058;  // GL_RGBA8
#else
  framebuffer_info.fFormat = 0x93A1;  // GL_BGRA8;
#endif

  auto backend_render_target =
      GrBackendRenderTargets::MakeGL(width,            // width
                                     height,           // height
                                     1,                // sample count
                                     8,                // stencil bits
                                     framebuffer_info  // framebuffer info
      );

  SkSurfaceProps surface_properties(0, kUnknown_SkPixelGeometry);

  auto surface = SkSurfaces::WrapBackendRenderTarget(
      GetGrContext().get(),         // context
      backend_render_target,        // backend render target
      kBottomLeft_GrSurfaceOrigin,  // surface origin
      kN32_SkColorType,             // color type
      SkColorSpace::MakeSRGB(),     // color space
      &surface_properties,          // surface properties
      nullptr,                      // release proc
      nullptr                       // release context
  );

  if (!surface) {
    FML_LOG(ERROR) << "Could not wrap the surface while attempting to "
                      "snapshot the GL surface.";
    return nullptr;
  }

  return surface;
}

sk_sp<SkImage> TestGLOnscreenOnlySurface::GetRasterSurfaceSnapshot() {
  auto surface = GetOnscreenSurface();

  if (!surface) {
    FML_LOG(ERROR) << "Aborting snapshot because of on-screen surface "
                      "acquisition failure.";
    return nullptr;
  }

  auto device_snapshot = surface->makeImageSnapshot();

  if (!device_snapshot) {
    FML_LOG(ERROR) << "Could not create the device snapshot while attempting "
                      "to snapshot the GL surface.";
    return nullptr;
  }

  auto host_snapshot = device_snapshot->makeRasterImage();

  if (!host_snapshot) {
    FML_LOG(ERROR) << "Could not create the host snapshot while attempting to "
                      "snapshot the GL surface.";
    return nullptr;
  }

  return host_snapshot;
}

uint32_t TestGLOnscreenOnlySurface::GetWindowFBOId() const {
  return 0u;
}

TestGLSurface::TestGLSurface(SkISize surface_size)
    : TestGLSurface(std::make_shared<TestEGLContext>(), surface_size) {}

TestGLSurface::TestGLSurface(std::shared_ptr<TestEGLContext> egl_context,
                             SkISize surface_size)
    : TestGLOnscreenOnlySurface(std::move(egl_context), surface_size) {
  {
    const EGLint offscreen_surface_attributes[] = {
        EGL_WIDTH,  1,  //
        EGL_HEIGHT, 1,  //
        EGL_NONE,
    };
    offscreen_surface_ = ::eglCreatePbufferSurface(
        egl_context_->display,        // display connection
        egl_context_->config,         // config
        offscreen_surface_attributes  // surface attributes
    );
    FML_CHECK(offscreen_surface_ != EGL_NO_SURFACE) << GetEGLError();
  }
}

TestGLSurface::~TestGLSurface() {
  auto result = ::eglDestroySurface(egl_context_->display, offscreen_surface_);
  FML_CHECK(result == EGL_TRUE) << GetEGLError();
}

bool TestGLSurface::MakeResourceCurrent() {
  auto result =
      ::eglMakeCurrent(egl_context_->display, offscreen_surface_,
                       offscreen_surface_, egl_context_->offscreen_context);

  if (result == EGL_FALSE) {
    FML_LOG(ERROR) << "Could not make the resource context current. "
                   << GetEGLError();
  }

  return result == EGL_TRUE;
}

}  // namespace flutter::testing
