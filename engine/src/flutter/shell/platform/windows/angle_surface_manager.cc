// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/angle_surface_manager.h"

#include <iostream>

namespace flutter {

AngleSurfaceManager::AngleSurfaceManager()
    : egl_config_(nullptr),
      egl_display_(EGL_NO_DISPLAY),
      egl_context_(EGL_NO_CONTEXT) {
  initialize_succeeded_ = Initialize();
}

AngleSurfaceManager::~AngleSurfaceManager() {
  CleanUp();
}

bool AngleSurfaceManager::Initialize() {
  const EGLint configAttributes[] = {EGL_RED_SIZE,   8, EGL_GREEN_SIZE,   8,
                                     EGL_BLUE_SIZE,  8, EGL_ALPHA_SIZE,   8,
                                     EGL_DEPTH_SIZE, 8, EGL_STENCIL_SIZE, 8,
                                     EGL_NONE};

  const EGLint display_context_attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 2,
                                               EGL_NONE};

  const EGLint default_display_attributes[] = {
      // These are prefered display attributes and request ANGLE's D3D11
      // renderer. eglInitialize will only succeed with these attributes if the
      // hardware supports D3D11 Feature Level 10_0+.
      EGL_PLATFORM_ANGLE_TYPE_ANGLE,
      EGL_PLATFORM_ANGLE_TYPE_D3D11_ANGLE,

      // EGL_PLATFORM_ANGLE_ENABLE_AUTOMATIC_TRIM_ANGLE is an option that will
      // enable ANGLE to automatically call the IDXGIDevice3::Trim method on
      // behalf of the application when it gets suspended.
      EGL_PLATFORM_ANGLE_ENABLE_AUTOMATIC_TRIM_ANGLE,
      EGL_TRUE,
      EGL_NONE,
  };

  const EGLint fl9_3_display_attributes[] = {
      // These are used to request ANGLE's D3D11 renderer, with D3D11 Feature
      // Level 9_3.
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

  const EGLint warp_display_attributes[] = {
      // These attributes request D3D11 WARP (software rendering fallback) as a
      // last resort.
      EGL_PLATFORM_ANGLE_TYPE_ANGLE,
      EGL_PLATFORM_ANGLE_TYPE_D3D11_ANGLE,
      EGL_PLATFORM_ANGLE_ENABLE_AUTOMATIC_TRIM_ANGLE,
      EGL_TRUE,
      EGL_NONE,
  };

  PFNEGLGETPLATFORMDISPLAYEXTPROC eglGetPlatformDisplayEXT =
      reinterpret_cast<PFNEGLGETPLATFORMDISPLAYEXTPROC>(
          eglGetProcAddress("eglGetPlatformDisplayEXT"));
  if (!eglGetPlatformDisplayEXT) {
    std::cerr << "EGL: eglGetPlatformDisplayEXT not available" << std::endl;
    return false;
  }

  // Try to initialize EGL to D3D11 Feature Level 10_0+.
  egl_display_ =
      eglGetPlatformDisplayEXT(EGL_PLATFORM_ANGLE_ANGLE, EGL_DEFAULT_DISPLAY,
                               default_display_attributes);
  if (egl_display_ == EGL_NO_DISPLAY) {
    std::cerr << "EGL: Failed to get a compatible EGLdisplay" << std::endl;
    return false;
  }

  if (eglInitialize(egl_display_, nullptr, nullptr) == EGL_FALSE) {
    // If above failed, try to initialize EGL to D3D11 Feature Level 9_3, if
    // 10_0+ is unavailable.
    egl_display_ =
        eglGetPlatformDisplayEXT(EGL_PLATFORM_ANGLE_ANGLE, EGL_DEFAULT_DISPLAY,
                                 fl9_3_display_attributes);
    if (egl_display_ == EGL_NO_DISPLAY) {
      std::cerr << "EGL: Failed to get a compatible 9.3 EGLdisplay"
                << std::endl;
      return false;
    }

    if (eglInitialize(egl_display_, nullptr, nullptr) == EGL_FALSE) {
      // If all else fails, attempt D3D11 Feature Level 11_0 on WARP as a last
      // resort
      egl_display_ = eglGetPlatformDisplayEXT(EGL_PLATFORM_ANGLE_ANGLE,
                                              EGL_DEFAULT_DISPLAY,
                                              warp_display_attributes);
      if (egl_display_ == EGL_NO_DISPLAY) {
        std::cerr << "EGL: Failed to get a compatible WARP EGLdisplay"
                  << std::endl;
        return false;
      }

      if (eglInitialize(egl_display_, nullptr, nullptr) == EGL_FALSE) {
        std::cerr << "EGL: Failed to initialize EGL" << std::endl;
        return false;
      }
    }
  }

  EGLint numConfigs = 0;
  if ((eglChooseConfig(egl_display_, configAttributes, &egl_config_, 1,
                       &numConfigs) == EGL_FALSE) ||
      (numConfigs == 0)) {
    std::cerr << "EGL: Failed to choose first context" << std::endl;
    return false;
  }

  egl_context_ = eglCreateContext(egl_display_, egl_config_, EGL_NO_CONTEXT,
                                  display_context_attributes);
  if (egl_context_ == EGL_NO_CONTEXT) {
    std::cerr << "EGL: Failed to create EGL context" << std::endl;
    return false;
  }

  egl_resource_context_ = eglCreateContext(
      egl_display_, egl_config_, egl_context_, display_context_attributes);

  if (egl_resource_context_ == EGL_NO_CONTEXT) {
    std::cerr << "EGL: Failed to create EGL resource context" << std::endl;
    return false;
  }

  return true;
}

void AngleSurfaceManager::CleanUp() {
  EGLBoolean result = EGL_FALSE;

  if (egl_display_ != EGL_NO_DISPLAY && egl_context_ != EGL_NO_CONTEXT) {
    result = eglDestroyContext(egl_display_, egl_context_);
    egl_context_ = EGL_NO_CONTEXT;

    if (result == EGL_FALSE) {
      std::cerr << "EGL: Failed to destroy context" << std::endl;
    }
  }

  if (egl_display_ != EGL_NO_DISPLAY &&
      egl_resource_context_ != EGL_NO_CONTEXT) {
    result = eglDestroyContext(egl_display_, egl_resource_context_);
    egl_resource_context_ = EGL_NO_CONTEXT;

    if (result == EGL_FALSE) {
      std::cerr << "EGL: Failed to destroy resource context" << std::endl;
    }
  }

  if (egl_display_ != EGL_NO_DISPLAY) {
    eglTerminate(egl_display_);
    egl_display_ = EGL_NO_DISPLAY;
  }
}

bool AngleSurfaceManager::CreateSurface(WindowsRenderTarget* render_target) {
  if (!render_target || !initialize_succeeded_) {
    return false;
  }

  EGLSurface surface = EGL_NO_SURFACE;

  const EGLint surfaceAttributes[] = {EGL_NONE};

  surface = eglCreateWindowSurface(
      egl_display_, egl_config_,
      static_cast<EGLNativeWindowType>(std::get<HWND>(*render_target)),
      surfaceAttributes);
  if (surface == EGL_NO_SURFACE) {
    std::cerr << "Surface creation failed." << std::endl;
  }

  render_surface_ = surface;
  return true;
}

void AngleSurfaceManager::GetSurfaceDimensions(EGLint* width, EGLint* height) {
  if (render_surface_ == EGL_NO_SURFACE || !initialize_succeeded_) {
    width = 0;
    height = 0;
    return;
  }

  eglQuerySurface(egl_display_, render_surface_, EGL_WIDTH, width);
  eglQuerySurface(egl_display_, render_surface_, EGL_HEIGHT, height);
}

void AngleSurfaceManager::DestroySurface() {
  if (egl_display_ != EGL_NO_DISPLAY && render_surface_ != EGL_NO_SURFACE) {
    eglDestroySurface(egl_display_, render_surface_);
  }
  render_surface_ = EGL_NO_SURFACE;
}

bool AngleSurfaceManager::MakeCurrent() {
  return (eglMakeCurrent(egl_display_, render_surface_, render_surface_,
                         egl_context_) == EGL_TRUE);
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

}  // namespace flutter
