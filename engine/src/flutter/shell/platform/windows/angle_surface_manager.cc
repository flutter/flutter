// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/angle_surface_manager.h"

#include <vector>

#include "flutter/fml/logging.h"

// Logs an EGL error to stderr. This automatically calls eglGetError()
// and logs the error code.
static void LogEglError(std::string message) {
  EGLint error = eglGetError();
  FML_LOG(ERROR) << "EGL: " << message;
  FML_LOG(ERROR) << "EGL: eglGetError returned " << error;
}

namespace flutter {

int AngleSurfaceManager::instance_count_ = 0;

std::unique_ptr<AngleSurfaceManager> AngleSurfaceManager::Create(
    bool enable_impeller) {
  std::unique_ptr<AngleSurfaceManager> manager;
  manager.reset(new AngleSurfaceManager(enable_impeller));
  if (!manager->initialize_succeeded_) {
    return nullptr;
  }
  return std::move(manager);
}

AngleSurfaceManager::AngleSurfaceManager(bool enable_impeller)
    : egl_config_(nullptr),
      egl_display_(EGL_NO_DISPLAY),
      egl_context_(EGL_NO_CONTEXT) {
  initialize_succeeded_ = Initialize(enable_impeller);
  ++instance_count_;
}

AngleSurfaceManager::~AngleSurfaceManager() {
  CleanUp();
  --instance_count_;
}

bool AngleSurfaceManager::InitializeEGL(
    PFNEGLGETPLATFORMDISPLAYEXTPROC egl_get_platform_display_EXT,
    const EGLint* config,
    bool should_log) {
  egl_display_ = egl_get_platform_display_EXT(EGL_PLATFORM_ANGLE_ANGLE,
                                              EGL_DEFAULT_DISPLAY, config);

  if (egl_display_ == EGL_NO_DISPLAY) {
    if (should_log) {
      LogEglError("Failed to get a compatible EGLdisplay");
    }
    return false;
  }

  if (eglInitialize(egl_display_, nullptr, nullptr) == EGL_FALSE) {
    if (should_log) {
      LogEglError("Failed to initialize EGL via ANGLE");
    }
    return false;
  }

  return true;
}

bool AngleSurfaceManager::Initialize(bool enable_impeller) {
  const EGLint config_attributes[] = {EGL_RED_SIZE,   8, EGL_GREEN_SIZE,   8,
                                      EGL_BLUE_SIZE,  8, EGL_ALPHA_SIZE,   8,
                                      EGL_DEPTH_SIZE, 8, EGL_STENCIL_SIZE, 8,
                                      EGL_NONE};

  const EGLint impeller_config_attributes[] = {
      EGL_RED_SIZE,       8, EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE,    8,
      EGL_ALPHA_SIZE,     8, EGL_DEPTH_SIZE, 0, EGL_STENCIL_SIZE, 8,
      EGL_SAMPLE_BUFFERS, 1, EGL_SAMPLES,    4, EGL_NONE};
  const EGLint impeller_config_attributes_no_msaa[] = {
      EGL_RED_SIZE,   8, EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE,    8,
      EGL_ALPHA_SIZE, 8, EGL_DEPTH_SIZE, 0, EGL_STENCIL_SIZE, 8,
      EGL_NONE};

  const EGLint display_context_attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 2,
                                               EGL_NONE};

  // These are preferred display attributes and request ANGLE's D3D11
  // renderer. eglInitialize will only succeed with these attributes if the
  // hardware supports D3D11 Feature Level 10_0+.
  const EGLint d3d11_display_attributes[] = {
      EGL_PLATFORM_ANGLE_TYPE_ANGLE,
      EGL_PLATFORM_ANGLE_TYPE_D3D11_ANGLE,

      // EGL_PLATFORM_ANGLE_ENABLE_AUTOMATIC_TRIM_ANGLE is an option that will
      // enable ANGLE to automatically call the IDXGIDevice3::Trim method on
      // behalf of the application when it gets suspended.
      EGL_PLATFORM_ANGLE_ENABLE_AUTOMATIC_TRIM_ANGLE,
      EGL_TRUE,

      // This extension allows angle to render directly on a D3D swapchain
      // in the correct orientation on D3D11.
      EGL_EXPERIMENTAL_PRESENT_PATH_ANGLE,
      EGL_EXPERIMENTAL_PRESENT_PATH_FAST_ANGLE,

      EGL_NONE,
  };

  // These are used to request ANGLE's D3D11 renderer, with D3D11 Feature
  // Level 9_3.
  const EGLint d3d11_fl_9_3_display_attributes[] = {
      EGL_PLATFORM_ANGLE_TYPE_ANGLE,
      EGL_PLATFORM_ANGLE_TYPE_D3D11_ANGLE,
      EGL_PLATFORM_ANGLE_MAX_VERSION_MAJOR_ANGLE,
      9,
      EGL_PLATFORM_ANGLE_MAX_VERSION_MINOR_ANGLE,
      3,
      EGL_PLATFORM_ANGLE_ENABLE_AUTOMATIC_TRIM_ANGLE,
      EGL_TRUE,
      EGL_NONE,
  };

  // These attributes request D3D11 WARP (software rendering fallback) in case
  // hardware-backed D3D11 is unavailable.
  const EGLint d3d11_warp_display_attributes[] = {
      EGL_PLATFORM_ANGLE_TYPE_ANGLE,
      EGL_PLATFORM_ANGLE_TYPE_D3D11_ANGLE,
      EGL_PLATFORM_ANGLE_ENABLE_AUTOMATIC_TRIM_ANGLE,
      EGL_TRUE,
      EGL_NONE,
  };

  std::vector<const EGLint*> display_attributes_configs = {
      d3d11_display_attributes,
      d3d11_fl_9_3_display_attributes,
      d3d11_warp_display_attributes,
  };

  PFNEGLGETPLATFORMDISPLAYEXTPROC egl_get_platform_display_EXT =
      reinterpret_cast<PFNEGLGETPLATFORMDISPLAYEXTPROC>(
          eglGetProcAddress("eglGetPlatformDisplayEXT"));
  if (!egl_get_platform_display_EXT) {
    LogEglError("eglGetPlatformDisplayEXT not available");
    return false;
  }

  // Attempt to initialize ANGLE's renderer in order of: D3D11, D3D11 Feature
  // Level 9_3 and finally D3D11 WARP.
  for (auto config : display_attributes_configs) {
    bool should_log = (config == display_attributes_configs.back());
    if (InitializeEGL(egl_get_platform_display_EXT, config, should_log)) {
      break;
    }
  }

  EGLint numConfigs = 0;
  if (enable_impeller) {
    // First try the MSAA configuration.
    if ((eglChooseConfig(egl_display_, impeller_config_attributes, &egl_config_,
                         1, &numConfigs) == EGL_FALSE) ||
        (numConfigs == 0)) {
      // Next fall back to disabled MSAA.
      if ((eglChooseConfig(egl_display_, impeller_config_attributes_no_msaa,
                           &egl_config_, 1, &numConfigs) == EGL_FALSE) ||
          (numConfigs == 0)) {
        LogEglError("Failed to choose first context");
        return false;
      }
    }
  } else {
    if ((eglChooseConfig(egl_display_, config_attributes, &egl_config_, 1,
                         &numConfigs) == EGL_FALSE) ||
        (numConfigs == 0)) {
      LogEglError("Failed to choose first context");
      return false;
    }
  }

  egl_context_ = eglCreateContext(egl_display_, egl_config_, EGL_NO_CONTEXT,
                                  display_context_attributes);
  if (egl_context_ == EGL_NO_CONTEXT) {
    LogEglError("Failed to create EGL context");
    return false;
  }

  egl_resource_context_ = eglCreateContext(
      egl_display_, egl_config_, egl_context_, display_context_attributes);

  if (egl_resource_context_ == EGL_NO_CONTEXT) {
    LogEglError("Failed to create EGL resource context");
    return false;
  }

  return true;
}

void AngleSurfaceManager::CleanUp() {
  EGLBoolean result = EGL_FALSE;

  // Needs to be reset before destroying the EGLContext.
  resolved_device_.Reset();

  if (egl_display_ != EGL_NO_DISPLAY && egl_context_ != EGL_NO_CONTEXT) {
    result = eglDestroyContext(egl_display_, egl_context_);
    egl_context_ = EGL_NO_CONTEXT;

    if (result == EGL_FALSE) {
      LogEglError("Failed to destroy context");
    }
  }

  if (egl_display_ != EGL_NO_DISPLAY &&
      egl_resource_context_ != EGL_NO_CONTEXT) {
    result = eglDestroyContext(egl_display_, egl_resource_context_);
    egl_resource_context_ = EGL_NO_CONTEXT;

    if (result == EGL_FALSE) {
      LogEglError("Failed to destroy resource context");
    }
  }

  if (egl_display_ != EGL_NO_DISPLAY) {
    // Display is reused between instances so only terminate display
    // if destroying last instance
    if (instance_count_ == 1) {
      eglTerminate(egl_display_);
    }
    egl_display_ = EGL_NO_DISPLAY;
  }
}

bool AngleSurfaceManager::CreateSurface(WindowsRenderTarget* render_target,
                                        EGLint width,
                                        EGLint height,
                                        bool vsync_enabled) {
  if (!render_target || !initialize_succeeded_) {
    return false;
  }

  EGLSurface surface = EGL_NO_SURFACE;

  const EGLint surfaceAttributes[] = {
      EGL_FIXED_SIZE_ANGLE, EGL_TRUE, EGL_WIDTH, width,
      EGL_HEIGHT,           height,   EGL_NONE};

  surface = eglCreateWindowSurface(
      egl_display_, egl_config_,
      static_cast<EGLNativeWindowType>(std::get<HWND>(*render_target)),
      surfaceAttributes);
  if (surface == EGL_NO_SURFACE) {
    LogEglError("Surface creation failed.");
    return false;
  }

  surface_width_ = width;
  surface_height_ = height;
  render_surface_ = surface;

  if (!MakeCurrent()) {
    LogEglError("Unable to make surface current to update the swap interval");
    return false;
  }

  SetVSyncEnabled(vsync_enabled);
  return true;
}

void AngleSurfaceManager::ResizeSurface(WindowsRenderTarget* render_target,
                                        EGLint width,
                                        EGLint height,
                                        bool vsync_enabled) {
  EGLint existing_width, existing_height;
  GetSurfaceDimensions(&existing_width, &existing_height);
  if (width != existing_width || height != existing_height) {
    surface_width_ = width;
    surface_height_ = height;

    ClearContext();
    DestroySurface();
    if (!CreateSurface(render_target, width, height, vsync_enabled)) {
      FML_LOG(ERROR)
          << "AngleSurfaceManager::ResizeSurface failed to create surface";
    }
  }
}

void AngleSurfaceManager::GetSurfaceDimensions(EGLint* width, EGLint* height) {
  if (render_surface_ == EGL_NO_SURFACE || !initialize_succeeded_) {
    *width = 0;
    *height = 0;
    return;
  }

  // Can't use eglQuerySurface here; Because we're not using
  // EGL_FIXED_SIZE_ANGLE flag anymore, Angle may resize the surface before
  // Flutter asks it to, which breaks resize redraw synchronization
  *width = surface_width_;
  *height = surface_height_;
}

void AngleSurfaceManager::DestroySurface() {
  if (egl_display_ != EGL_NO_DISPLAY && render_surface_ != EGL_NO_SURFACE) {
    eglDestroySurface(egl_display_, render_surface_);
  }
  render_surface_ = EGL_NO_SURFACE;
}

bool AngleSurfaceManager::HasContextCurrent() {
  return eglGetCurrentContext() != EGL_NO_CONTEXT;
}

bool AngleSurfaceManager::MakeCurrent() {
  return (eglMakeCurrent(egl_display_, render_surface_, render_surface_,
                         egl_context_) == EGL_TRUE);
}

bool AngleSurfaceManager::ClearCurrent() {
  return (eglMakeCurrent(egl_display_, EGL_NO_SURFACE, EGL_NO_SURFACE,
                         EGL_NO_CONTEXT) == EGL_TRUE);
}

bool AngleSurfaceManager::ClearContext() {
  return (eglMakeCurrent(egl_display_, nullptr, nullptr, egl_context_) ==
          EGL_TRUE);
}

bool AngleSurfaceManager::MakeResourceCurrent() {
  return (eglMakeCurrent(egl_display_, EGL_NO_SURFACE, EGL_NO_SURFACE,
                         egl_resource_context_) == EGL_TRUE);
}

EGLBoolean AngleSurfaceManager::SwapBuffers() {
  return (eglSwapBuffers(egl_display_, render_surface_));
}

EGLSurface AngleSurfaceManager::CreateSurfaceFromHandle(
    EGLenum handle_type,
    EGLClientBuffer handle,
    const EGLint* attributes) const {
  return eglCreatePbufferFromClientBuffer(egl_display_, handle_type, handle,
                                          egl_config_, attributes);
}

void AngleSurfaceManager::SetVSyncEnabled(bool enabled) {
  // OpenGL swap intervals can be used to prevent screen tearing.
  // If enabled, the raster thread blocks until the v-blank.
  // This is unnecessary if DWM composition is enabled.
  // See: https://www.khronos.org/opengl/wiki/Swap_Interval
  // See: https://learn.microsoft.com/windows/win32/dwm/composition-ovw
  if (eglSwapInterval(egl_display_, enabled ? 1 : 0) != EGL_TRUE) {
    LogEglError("Unable to update the swap interval");
    return;
  }
}

bool AngleSurfaceManager::GetDevice(ID3D11Device** device) {
  if (!resolved_device_) {
    PFNEGLQUERYDISPLAYATTRIBEXTPROC egl_query_display_attrib_EXT =
        reinterpret_cast<PFNEGLQUERYDISPLAYATTRIBEXTPROC>(
            eglGetProcAddress("eglQueryDisplayAttribEXT"));

    PFNEGLQUERYDEVICEATTRIBEXTPROC egl_query_device_attrib_EXT =
        reinterpret_cast<PFNEGLQUERYDEVICEATTRIBEXTPROC>(
            eglGetProcAddress("eglQueryDeviceAttribEXT"));

    if (!egl_query_display_attrib_EXT || !egl_query_device_attrib_EXT) {
      return false;
    }

    EGLAttrib egl_device = 0;
    EGLAttrib angle_device = 0;
    if (egl_query_display_attrib_EXT(egl_display_, EGL_DEVICE_EXT,
                                     &egl_device) == EGL_TRUE) {
      if (egl_query_device_attrib_EXT(
              reinterpret_cast<EGLDeviceEXT>(egl_device),
              EGL_D3D11_DEVICE_ANGLE, &angle_device) == EGL_TRUE) {
        resolved_device_ = reinterpret_cast<ID3D11Device*>(angle_device);
      }
    }
  }

  resolved_device_.CopyTo(device);
  return (resolved_device_ != nullptr);
}

}  // namespace flutter
