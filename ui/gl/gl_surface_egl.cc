// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_surface_egl.h"

#if defined(OS_ANDROID)
#include <android/native_window_jni.h>
#endif

#include "base/command_line.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/message_loop/message_loop.h"
#include "base/trace_event/trace_event.h"
#include "build/build_config.h"
#include "ui/gfx/geometry/rect.h"
#include "ui/gl/egl_util.h"
#include "ui/gl/gl_context.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_surface_stub.h"
#include "ui/gl/gl_switches.h"
#include "ui/gl/scoped_make_current.h"
#include "ui/gl/sync_control_vsync_provider.h"

#if defined(USE_X11)
extern "C" {
#include <X11/Xlib.h>
}
#endif

#if defined (USE_OZONE)
#include "ui/ozone/public/surface_factory_ozone.h"
#endif

#if !defined(EGL_FIXED_SIZE_ANGLE)
#define EGL_FIXED_SIZE_ANGLE 0x3201
#endif

#if !defined(EGL_OPENGL_ES3_BIT)
#define EGL_OPENGL_ES3_BIT 0x00000040
#endif

using ui::GetLastEGLErrorString;

namespace gfx {

namespace {

EGLDisplay g_display;
EGLNativeDisplayType g_native_display_type;

// In the Cast environment, we need to destroy the EGLNativeDisplayType and
// EGLDisplay returned by the GPU platform when we switch to an external app
// which will temporarily own all screen and GPU resources.
// Even though Chromium is still in the background.
// As such, it must be reinitialized each time we come back to the foreground.
bool g_initialized = false;
int g_num_surfaces = 0;
bool g_terminate_pending = false;

const char* g_egl_extensions = NULL;
bool g_egl_create_context_robustness_supported = false;
bool g_egl_sync_control_supported = false;
bool g_egl_window_fixed_size_supported = false;
bool g_egl_surfaceless_context_supported = false;

class EGLSyncControlVSyncProvider
    : public gfx::SyncControlVSyncProvider {
 public:
  explicit EGLSyncControlVSyncProvider(EGLSurface surface)
      : SyncControlVSyncProvider(),
        surface_(surface) {
  }

  ~EGLSyncControlVSyncProvider() override {}

 protected:
  bool GetSyncValues(int64* system_time,
                     int64* media_stream_counter,
                     int64* swap_buffer_counter) override {
    uint64 u_system_time, u_media_stream_counter, u_swap_buffer_counter;
    bool result = eglGetSyncValuesCHROMIUM(
        g_display, surface_, &u_system_time,
        &u_media_stream_counter, &u_swap_buffer_counter) == EGL_TRUE;
    if (result) {
      *system_time = static_cast<int64>(u_system_time);
      *media_stream_counter = static_cast<int64>(u_media_stream_counter);
      *swap_buffer_counter = static_cast<int64>(u_swap_buffer_counter);
    }
    return result;
  }

  bool GetMscRate(int32* numerator, int32* denominator) override {
    return false;
  }

 private:
  EGLSurface surface_;

  DISALLOW_COPY_AND_ASSIGN(EGLSyncControlVSyncProvider);
};

void DeinitializeEgl() {
  if (g_initialized) {
    g_initialized = false;
    eglTerminate(g_display);
  }
}

}  // namespace

GLSurfaceEGL::GLSurfaceEGL(
  const gfx::SurfaceConfiguration requested_configuration)
    : GLSurface(requested_configuration) {
  ++g_num_surfaces;
  if (!g_initialized) {
    bool result = GLSurfaceEGL::InitializeOneOff();
    DCHECK(result);
    DCHECK(g_initialized);
  }
}

void* GetEGLConfig(const EGLNativeWindowType window,
                   const gfx::SurfaceConfiguration configuration,
                   bool allow_window_bit) {
  // Choose an EGL configuration.
  // On X this is only used for PBuffer surfaces.
  EGLConfig config = {0};

#if defined(USE_X11)
  XWindowAttributes win_attribs;
  if (!XGetWindowAttributes(GLSurfaceEGL::GetNativeDisplay(),
                            window,
                            &win_attribs)) {
    return nullptr;
  }
#endif

  EGLint renderable_type = EGL_OPENGL_ES2_BIT;
  if (base::CommandLine::ForCurrentProcess()->HasSwitch(
          switches::kEnableUnsafeES3APIs)) {
    renderable_type = EGL_OPENGL_ES3_BIT;
  }
  EGLint config_attribs[] = {
    EGL_BUFFER_SIZE, configuration.alpha_bits +
                     configuration.red_bits +
                     configuration.green_bits +
                     configuration.blue_bits,
    EGL_ALPHA_SIZE, configuration.alpha_bits,
    EGL_BLUE_SIZE, configuration.blue_bits,
    EGL_GREEN_SIZE, configuration.green_bits,
    EGL_RED_SIZE, configuration.red_bits,
    EGL_DEPTH_SIZE, configuration.depth_bits,
    EGL_STENCIL_SIZE, configuration.stencil_bits,
    EGL_RENDERABLE_TYPE, renderable_type,
    EGL_SURFACE_TYPE, (allow_window_bit ?
                        (EGL_WINDOW_BIT | EGL_PBUFFER_BIT) :
                        EGL_PBUFFER_BIT),
    EGL_NONE
  };

#if defined(USE_OZONE)
  config_attribs =
      ui::SurfaceFactoryOzone::GetInstance()->GetEGLSurfaceProperties(
          config_attribs);
#elif defined(USE_X11)
  // Try matching the window depth with an alpha channel,
  // because we're worried the destination alpha width could
  // constrain blending precision.
  const int kBufferSizeOffset = 1;
  const int kAlphaSizeOffset = 3;
  config_attribs[kBufferSizeOffset] = win_attribs.depth;
#endif

  EGLint num_configs;
  if (!eglChooseConfig(g_display,
                       config_attribs,
                       NULL,
                       0,
                       &num_configs)) {
    LOG(ERROR) << "eglChooseConfig failed with error "
               << GetLastEGLErrorString();
    return nullptr;
  }

  if (!eglChooseConfig(g_display,
                       config_attribs,
                       &config,
                       1,
                       &num_configs)) {
    LOG(ERROR) << "eglChooseConfig failed with error "
               << GetLastEGLErrorString();
    return nullptr;
  }

#if defined(USE_X11)
  if (num_configs) {
    EGLint config_depth;
    if (!eglGetConfigAttrib(g_display,
                            config,
                            EGL_BUFFER_SIZE,
                            &config_depth)) {
      LOG(ERROR) << "eglGetConfigAttrib failed with error "
                 << GetLastEGLErrorString();
      return nullptr;
    }

    if (config_depth == win_attribs.depth) {
      return config;
    }
  }

  // Try without an alpha channel.
  config_attribs[kAlphaSizeOffset] = 0;
  if (!eglChooseConfig(g_display,
                       config_attribs,
                       &config,
                       1,
                       &num_configs)) {
    LOG(ERROR) << "eglChooseConfig failed with error "
               << GetLastEGLErrorString();
    return nullptr;
  }
#endif

  if (num_configs == 0) {
    LOG(ERROR) << "No suitable EGL configs found.";
    return nullptr;
  }

  return config;
}

bool GLSurfaceEGL::InitializeOneOff() {
  if (g_initialized)
    return true;

  g_native_display_type = GetPlatformDefaultEGLNativeDisplay();

  g_display = eglGetDisplay(g_native_display_type);

  if (!g_display) {
    LOG(ERROR) << "eglGetDisplay failed with error " << GetLastEGLErrorString();
    return false;
  }

  if (!eglInitialize(g_display, NULL, NULL)) {
    LOG(ERROR) << "eglInitialize failed with error " << GetLastEGLErrorString();
    return false;
  }

  g_egl_extensions = eglQueryString(g_display, EGL_EXTENSIONS);
  g_egl_create_context_robustness_supported =
      HasEGLExtension("EGL_EXT_create_context_robustness");
  g_egl_sync_control_supported =
      HasEGLExtension("EGL_CHROMIUM_sync_control");
  g_egl_window_fixed_size_supported =
      HasEGLExtension("EGL_ANGLE_window_fixed_size");

  // We always succeed beyond this point so set g_initialized here to avoid
  // infinite recursion through CreateGLContext and GetDisplay
  // if g_egl_surfaceless_context_supported.
  g_initialized = true;
  g_terminate_pending = false;

  // TODO(oetuaho@nvidia.com): Surfaceless is disabled on Android as a temporary
  // workaround, since code written for Android WebView takes different paths
  // based on whether GL surface objects have underlying EGL surface handles,
  // conflicting with the use of surfaceless. See https://crbug.com/382349
#if defined(OS_ANDROID)
  DCHECK(!g_egl_surfaceless_context_supported);
#else
  // Check if SurfacelessEGL is supported.
  g_egl_surfaceless_context_supported =
      HasEGLExtension("EGL_KHR_surfaceless_context");
  if (g_egl_surfaceless_context_supported) {
    // EGL_KHR_surfaceless_context is supported but ensure
    // GL_OES_surfaceless_context is also supported. We need a current context
    // to query for supported GL extensions.
    scoped_refptr<GLSurface> surface = new SurfacelessEGL(
      Size(1, 1), SurfaceConfiguration());
    scoped_refptr<GLContext> context = GLContext::CreateGLContext(
      NULL, surface.get(), PreferIntegratedGpu);
    if (!context->MakeCurrent(surface.get()))
      g_egl_surfaceless_context_supported = false;

    // Ensure context supports GL_OES_surfaceless_context.
    if (g_egl_surfaceless_context_supported) {
      g_egl_surfaceless_context_supported = context->HasExtension(
          "GL_OES_surfaceless_context");
      context->ReleaseCurrent(surface.get());
    }
  }
#endif

  return true;
}

EGLDisplay GLSurfaceEGL::GetDisplay() {
  DCHECK(g_initialized);
  return g_display;
}

// static
EGLDisplay GLSurfaceEGL::GetHardwareDisplay() {
  if (!g_initialized) {
    bool result = GLSurfaceEGL::InitializeOneOff();
    DCHECK(result);
  }
  return g_display;
}

// static
EGLNativeDisplayType GLSurfaceEGL::GetNativeDisplay() {
  if (!g_initialized) {
    bool result = GLSurfaceEGL::InitializeOneOff();
    DCHECK(result);
  }
  return g_native_display_type;
}

const char* GLSurfaceEGL::GetEGLExtensions() {
  // No need for InitializeOneOff. Assume that extensions will not change
  // after the first initialization.
  return g_egl_extensions;
}

bool GLSurfaceEGL::HasEGLExtension(const char* name) {
  return ExtensionsContain(GetEGLExtensions(), name);
}

bool GLSurfaceEGL::IsCreateContextRobustnessSupported() {
  return g_egl_create_context_robustness_supported;
}

bool GLSurfaceEGL::IsEGLSurfacelessContextSupported() {
  return g_egl_surfaceless_context_supported;
}

void GLSurfaceEGL::DestroyAndTerminateDisplay() {
  DCHECK(g_initialized);
  DCHECK_EQ(g_num_surfaces, 1);
  Destroy();
  g_terminate_pending = true;
}

GLSurfaceEGL::~GLSurfaceEGL() {
  DCHECK_GT(g_num_surfaces, 0) << "Bad surface count";
  if (--g_num_surfaces == 0 && g_terminate_pending) {
    DeinitializeEgl();
    g_terminate_pending = false;
  }
}

NativeViewGLSurfaceEGL::NativeViewGLSurfaceEGL(
    EGLNativeWindowType window,
    const gfx::SurfaceConfiguration requested_configuration)
    : GLSurfaceEGL(requested_configuration),
      window_(window),
      surface_(NULL),
      supports_post_sub_buffer_(false),
      config_(NULL),
      size_(1, 1),
      swap_interval_(1) {
#if defined(OS_ANDROID)
  if (window)
    ANativeWindow_acquire(window);
#endif
}

bool NativeViewGLSurfaceEGL::Initialize() {
  return Initialize(nullptr);
}

bool NativeViewGLSurfaceEGL::Initialize(
    scoped_ptr<VSyncProvider> sync_provider) {
  DCHECK(!surface_);

  if (!GetDisplay()) {
    LOG(ERROR) << "Trying to create surface with invalid display.";
    return false;
  }

  std::vector<EGLint> egl_window_attributes;

  if (g_egl_window_fixed_size_supported) {
    egl_window_attributes.push_back(EGL_FIXED_SIZE_ANGLE);
    egl_window_attributes.push_back(EGL_TRUE);
    egl_window_attributes.push_back(EGL_WIDTH);
    egl_window_attributes.push_back(size_.width());
    egl_window_attributes.push_back(EGL_HEIGHT);
    egl_window_attributes.push_back(size_.height());
  }

  if (gfx::g_driver_egl.ext.b_EGL_NV_post_sub_buffer) {
    egl_window_attributes.push_back(EGL_POST_SUB_BUFFER_SUPPORTED_NV);
    egl_window_attributes.push_back(EGL_TRUE);
  }

  egl_window_attributes.push_back(EGL_NONE);
  // Create a surface for the native window.
  surface_ = eglCreateWindowSurface(
      GetDisplay(), GetConfig(), window_, &egl_window_attributes[0]);

  if (!surface_) {
    LOG(ERROR) << "eglCreateWindowSurface failed with error "
               << GetLastEGLErrorString();
    Destroy();
    return false;
  }

  if (gfx::g_driver_egl.ext.b_EGL_NV_post_sub_buffer) {
    EGLint surfaceVal;
    EGLBoolean retVal = eglQuerySurface(
        GetDisplay(), surface_, EGL_POST_SUB_BUFFER_SUPPORTED_NV, &surfaceVal);
    supports_post_sub_buffer_ = (surfaceVal && retVal) == EGL_TRUE;
  }

  if (sync_provider)
    vsync_provider_.reset(sync_provider.release());
  else if (g_egl_sync_control_supported)
    vsync_provider_.reset(new EGLSyncControlVSyncProvider(surface_));
  return true;
}

void NativeViewGLSurfaceEGL::Destroy() {
  if (surface_) {
    if (!eglDestroySurface(GetDisplay(), surface_)) {
      LOG(ERROR) << "eglDestroySurface failed with error "
                 << GetLastEGLErrorString();
    }
    surface_ = NULL;
  }
}

EGLConfig NativeViewGLSurfaceEGL::GetConfig() {
  if (!config_) {
    DCHECK(window_);
    config_ = GetEGLConfig(window_, this->get_surface_configuration(), true);
  }
  return config_;
}

bool NativeViewGLSurfaceEGL::IsOffscreen() {
  return false;
}

bool NativeViewGLSurfaceEGL::SwapBuffers() {
  TRACE_EVENT2("gpu", "NativeViewGLSurfaceEGL:RealSwapBuffers",
      "width", GetSize().width(),
      "height", GetSize().height());

  if (!eglSwapBuffers(GetDisplay(), surface_)) {
    DVLOG(1) << "eglSwapBuffers failed with error "
             << GetLastEGLErrorString();
    return false;
  }

  return true;
}

gfx::Size NativeViewGLSurfaceEGL::GetSize() {
  EGLint width;
  EGLint height;
  if (!eglQuerySurface(GetDisplay(), surface_, EGL_WIDTH, &width) ||
      !eglQuerySurface(GetDisplay(), surface_, EGL_HEIGHT, &height)) {
    NOTREACHED() << "eglQuerySurface failed with error "
                 << GetLastEGLErrorString();
    return gfx::Size();
  }

  return gfx::Size(width, height);
}

bool NativeViewGLSurfaceEGL::Resize(const gfx::Size& size) {
  if (size == GetSize())
    return true;

  size_ = size;

  scoped_ptr<ui::ScopedMakeCurrent> scoped_make_current;
  GLContext* current_context = GLContext::GetCurrent();
  bool was_current =
      current_context && current_context->IsCurrent(this);
  if (was_current) {
    scoped_make_current.reset(
        new ui::ScopedMakeCurrent(current_context, this));
    current_context->ReleaseCurrent(this);
  }

  Destroy();

  if (!Initialize()) {
    LOG(ERROR) << "Failed to resize window.";
    return false;
  }

  return true;
}

bool NativeViewGLSurfaceEGL::Recreate() {
  Destroy();
  if (!Initialize()) {
    LOG(ERROR) << "Failed to create surface.";
    return false;
  }
  return true;
}

EGLSurface NativeViewGLSurfaceEGL::GetHandle() {
  return surface_;
}

bool NativeViewGLSurfaceEGL::SupportsPostSubBuffer() {
  return supports_post_sub_buffer_;
}

bool NativeViewGLSurfaceEGL::PostSubBuffer(
    int x, int y, int width, int height) {
  DCHECK(supports_post_sub_buffer_);
  if (!eglPostSubBufferNV(GetDisplay(), surface_, x, y, width, height)) {
    DVLOG(1) << "eglPostSubBufferNV failed with error "
             << GetLastEGLErrorString();
    return false;
  }
  return true;
}

VSyncProvider* NativeViewGLSurfaceEGL::GetVSyncProvider() {
  return vsync_provider_.get();
}

void NativeViewGLSurfaceEGL::OnSetSwapInterval(int interval) {
  swap_interval_ = interval;
}

NativeViewGLSurfaceEGL::~NativeViewGLSurfaceEGL() {
  Destroy();
#if defined(OS_ANDROID)
  if (window_)
    ANativeWindow_release(window_);
#endif
}

PbufferGLSurfaceEGL::PbufferGLSurfaceEGL(
    const gfx::Size& size,
    const gfx::SurfaceConfiguration requested_configuration)
    : GLSurfaceEGL(requested_configuration),
      size_(size),
      surface_(nullptr),
      config_(nullptr) {
  // Some implementations of Pbuffer do not support having a 0 size. For such
  // cases use a (1, 1) surface.
  if (size_.GetArea() == 0)
    size_.SetSize(1, 1);
}

bool PbufferGLSurfaceEGL::Initialize() {
  EGLSurface old_surface = surface_;

  EGLDisplay display = GetDisplay();
  if (!display) {
    LOG(ERROR) << "Trying to create surface with invalid display.";
    return false;
  }

  // Allocate the new pbuffer surface before freeing the old one to ensure
  // they have different addresses. If they have the same address then a
  // future call to MakeCurrent might early out because it appears the current
  // context and surface have not changed.
  const EGLint pbuffer_attribs[] = {
    EGL_WIDTH, size_.width(),
    EGL_HEIGHT, size_.height(),
    EGL_NONE
  };

  EGLSurface new_surface = eglCreatePbufferSurface(display,
                                                   GetConfig(),
                                                   pbuffer_attribs);
  if (!new_surface) {
    LOG(ERROR) << "eglCreatePbufferSurface failed with error "
               << GetLastEGLErrorString();
    return false;
  }

  if (old_surface)
    eglDestroySurface(display, old_surface);

  surface_ = new_surface;
  return true;
}

void PbufferGLSurfaceEGL::Destroy() {
  if (surface_) {
    if (!eglDestroySurface(GetDisplay(), surface_)) {
      LOG(ERROR) << "eglDestroySurface failed with error "
                 << GetLastEGLErrorString();
    }
    surface_ = NULL;
  }
}

EGLConfig PbufferGLSurfaceEGL::GetConfig() {
  if (!config_) {
    config_ = GetEGLConfig((EGLNativeWindowType)nullptr,
                           this->get_surface_configuration(),
                           false);
  }
  return config_;
}

bool PbufferGLSurfaceEGL::IsOffscreen() {
  return true;
}

bool PbufferGLSurfaceEGL::SwapBuffers() {
  NOTREACHED() << "Attempted to call SwapBuffers on a PbufferGLSurfaceEGL.";
  return false;
}

gfx::Size PbufferGLSurfaceEGL::GetSize() {
  return size_;
}

bool PbufferGLSurfaceEGL::Resize(const gfx::Size& size) {
  if (size == size_)
    return true;

  scoped_ptr<ui::ScopedMakeCurrent> scoped_make_current;
  GLContext* current_context = GLContext::GetCurrent();
  bool was_current =
      current_context && current_context->IsCurrent(this);
  if (was_current) {
    scoped_make_current.reset(
        new ui::ScopedMakeCurrent(current_context, this));
  }

  size_ = size;

  if (!Initialize()) {
    LOG(ERROR) << "Failed to resize pbuffer.";
    return false;
  }

  return true;
}

EGLSurface PbufferGLSurfaceEGL::GetHandle() {
  return surface_;
}

void* PbufferGLSurfaceEGL::GetShareHandle() {
#if defined(OS_ANDROID)
  NOTREACHED();
  return NULL;
#else
  if (!gfx::g_driver_egl.ext.b_EGL_ANGLE_query_surface_pointer)
    return NULL;

  if (!gfx::g_driver_egl.ext.b_EGL_ANGLE_surface_d3d_texture_2d_share_handle)
    return NULL;

  void* handle;
  if (!eglQuerySurfacePointerANGLE(g_display,
                                   GetHandle(),
                                   EGL_D3D_TEXTURE_2D_SHARE_HANDLE_ANGLE,
                                   &handle)) {
    return NULL;
  }

  return handle;
#endif
}

PbufferGLSurfaceEGL::~PbufferGLSurfaceEGL() {
  Destroy();
}

SurfacelessEGL::SurfacelessEGL(
  const gfx::Size& size,
  const gfx::SurfaceConfiguration requested_configuration)
    : GLSurfaceEGL(requested_configuration), size_(size) {
}

bool SurfacelessEGL::Initialize() {
  return true;
}

void SurfacelessEGL::Destroy() {
}

EGLConfig SurfacelessEGL::GetConfig() {
  return NULL;
}

bool SurfacelessEGL::IsOffscreen() {
  return true;
}

bool SurfacelessEGL::IsSurfaceless() const {
  return true;
}

bool SurfacelessEGL::SwapBuffers() {
  LOG(ERROR) << "Attempted to call SwapBuffers with SurfacelessEGL.";
  return false;
}

gfx::Size SurfacelessEGL::GetSize() {
  return size_;
}

bool SurfacelessEGL::Resize(const gfx::Size& size) {
  size_ = size;
  return true;
}

EGLSurface SurfacelessEGL::GetHandle() {
  return EGL_NO_SURFACE;
}

void* SurfacelessEGL::GetShareHandle() {
  return NULL;
}

SurfacelessEGL::~SurfacelessEGL() {
}

}  // namespace gfx
