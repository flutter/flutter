// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_CONTEXT_GL_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_CONTEXT_GL_H_

#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_counted.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/platform/android/android_context.h"
#include "flutter/shell/platform/android/android_environment_gl.h"
#include "flutter/shell/platform/android/android_native_window.h"
#include "third_party/skia/include/core/SkSize.h"

namespace flutter {

//------------------------------------------------------------------------------
/// The Android context is used by `AndroidSurfaceGL` to create and manage
/// EGL surfaces.
///
/// This context binds `EGLContext` to the current rendering thread and to the
/// draw and read `EGLSurface`s.
///
class AndroidContextGL : public AndroidContext {
 public:
  AndroidContextGL(AndroidRenderingAPI rendering_api,
                   fml::RefPtr<AndroidEnvironmentGL> environment);

  ~AndroidContextGL();

  //----------------------------------------------------------------------------
  /// @brief      Allocates an new EGL window surface that is used for on-screen
  ///             pixels.
  ///
  /// @attention  Consumers must tear down the surface by calling
  ///             `AndroidContextGL::TeardownSurface`.
  ///
  /// @return     The window surface.
  ///
  EGLSurface CreateOnscreenSurface(
      fml::RefPtr<AndroidNativeWindow> window) const;

  //----------------------------------------------------------------------------
  /// @brief      Allocates an 1x1 pbuffer surface that is used for making the
  ///             offscreen current for texture uploads.
  ///
  /// @attention  Consumers must tear down the surface by calling
  ///             `AndroidContextGL::TeardownSurface`.
  ///
  /// @return     The pbuffer surface.
  ///
  EGLSurface CreateOffscreenSurface() const;

  //----------------------------------------------------------------------------
  /// @return     The Android environment that contains a reference to the
  /// display.
  ///
  fml::RefPtr<AndroidEnvironmentGL> Environment() const;

  //----------------------------------------------------------------------------
  /// @return     Whether the current context is valid. That is, if the EGL
  /// contexts
  ///             were successfully created.
  ///
  bool IsValid() const;

  //----------------------------------------------------------------------------
  /// @return     Whether the current context was successfully clear.
  ///
  bool ClearCurrent();

  //----------------------------------------------------------------------------
  /// @brief      Binds the EGLContext context to the current rendering thread
  ///             and to the draw and read surface.
  ///
  /// @return     Whether the surface was made current.
  ///
  bool MakeCurrent(EGLSurface& surface);

  //----------------------------------------------------------------------------
  /// @brief      Binds the resource EGLContext context to the current rendering
  ///             thread and to the draw and read surface.
  ///
  /// @return     Whether the surface was made current.
  ///
  bool ResourceMakeCurrent(EGLSurface& surface);

  //----------------------------------------------------------------------------
  /// @brief      This only applies to on-screen surfaces such as those created
  ///             by `AndroidContextGL::CreateOnscreenSurface`.
  ///
  /// @return     Whether the EGL surface color buffer was swapped.
  ///
  bool SwapBuffers(EGLSurface& surface);

  //----------------------------------------------------------------------------
  /// @return     The size of an `EGLSurface`.
  ///
  SkISize GetSize(EGLSurface& surface);

  //----------------------------------------------------------------------------
  /// @brief      Destroys an `EGLSurface`.
  ///
  /// @return     Whether the surface was destroyed.
  ///
  bool TeardownSurface(EGLSurface& surface);

 private:
  fml::RefPtr<AndroidEnvironmentGL> environment_;
  EGLConfig config_;
  EGLContext context_;
  EGLContext resource_context_;
  bool valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidContextGL);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_CONTEXT_GL_H_
