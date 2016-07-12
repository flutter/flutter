// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/android/platform_view_android.h"

#include <EGL/egl.h>

#include <android/input.h>
#include <android/native_window_jni.h>

#include <utility>

#include "base/bind.h"
#include "base/location.h"
#include "jni/FlutterView_jni.h"
#include "sky/engine/core/script/dart_service_isolate.h"
#include "sky/engine/wtf/MakeUnique.h"
#include "sky/shell/shell.h"
#include "sky/shell/shell_view.h"

namespace sky {
namespace shell {

class AndroidNativeWindow {
 public:
  using Handle = ANativeWindow*;

  explicit AndroidNativeWindow(Handle window) : window_(window) {
    if (window_ != nullptr) {
      ANativeWindow_acquire(window_);
    }
  }

  ~AndroidNativeWindow() {
    if (window_ != nullptr) {
      ANativeWindow_release(window_);
      window_ = nullptr;
    }
  }

  bool IsValid() const { return window_ != nullptr; }

  Handle handle() const { return window_; }

 private:
  Handle window_;

  DISALLOW_COPY_AND_ASSIGN(AndroidNativeWindow);
};

class AndroidGLContext {
 public:
  explicit AndroidGLContext(AndroidNativeWindow::Handle window_handle,
                            PlatformView::SurfaceConfig config)
      : window_(window_handle),
        display_(EGL_NO_DISPLAY),
        config_(nullptr),
        surface_(EGL_NO_SURFACE),
        context_(EGL_NO_CONTEXT),
        valid_(false) {
    if (!window_.IsValid()) {
      // We always require a valid window since we are only going to deal
      // with window surfaces.
      return;
    }

    bool success = false;

    // Setup the display connection.

    std::tie(success, display_) = SetupDisplayConnection();

    if (!success) {
      return;
    }

    // Choose a valid configuration.

    std::tie(success, config_) = ChooseWindowConfiguration(display_, config);

    if (!success) {
      return;
    }

    // Create a window surface for the configuration.

    std::tie(success, surface_) =
        CreateWindowSurface(display_, config_, window_.handle());

    if (!success) {
      return;
    }

    // Create a context for the configuration.

    std::tie(success, context_) = CreateContext(display_, config_);

    if (!success) {
      return;
    }

    // All done!
    valid_ = true;
  }

  ~AndroidGLContext() {
    if (!TeardownContext(display_, context_)) {
      LOG(INFO)
          << "Could not tear down the EGL context. Possible resource leak.";
    }

    if (!TeardownSurface(display_, surface_)) {
      LOG(INFO)
          << "Could not tear down the EGL surface. Possible resource leak.";
    }

    if (!TeardownDisplayConnection(display_)) {
      LOG(INFO) << "Could not tear down the EGL display connection. Possible "
                   "resource leak.";
    }
  }

  bool IsValid() const { return valid_; }

  bool ContextMakeCurrent() {
    return eglMakeCurrent(display_, surface_, surface_, context_) == EGL_TRUE;
  }

  bool SwapBuffers() { return eglSwapBuffers(display_, surface_); }

 private:
  AndroidNativeWindow window_;
  EGLDisplay display_;
  EGLConfig config_;
  EGLSurface surface_;
  EGLContext context_;

  bool valid_;

  template <class T>
  using EGLResult = std::pair<bool, T>;

  static EGLResult<EGLDisplay> SetupDisplayConnection() {
    // Get the display.
    EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);

    if (display == EGL_NO_DISPLAY) {
      return {false, EGL_NO_DISPLAY};
    }

    // Initialize the display connection.
    if (eglInitialize(display, nullptr, nullptr) != EGL_TRUE) {
      return {false, EGL_NO_DISPLAY};
    }

    return {true, display};
  }

  static bool TeardownDisplayConnection(EGLDisplay display) {
    if (display != EGL_NO_DISPLAY) {
      return eglTerminate(display) == EGL_TRUE;
    }

    return true;
  }

  static bool TeardownContext(EGLDisplay display, EGLContext context) {
    if (context != EGL_NO_CONTEXT) {
      return eglDestroyContext(display, context) == EGL_TRUE;
    }

    return true;
  }

  static bool TeardownSurface(EGLDisplay display, EGLSurface surface) {
    if (surface != EGL_NO_SURFACE) {
      return eglDestroySurface(display, surface) == EGL_TRUE;
    }

    return true;
  }

  static EGLResult<EGLConfig> ChooseWindowConfiguration(
      EGLDisplay display,
      PlatformView::SurfaceConfig config) {
    EGLint attributes[] = {
        // clang-format off
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
        EGL_SURFACE_TYPE,    EGL_WINDOW_BIT,
        EGL_RED_SIZE,        config.red_bits,
        EGL_GREEN_SIZE,      config.green_bits,
        EGL_BLUE_SIZE,       config.blue_bits,
        EGL_ALPHA_SIZE,      config.alpha_bits,
        EGL_DEPTH_SIZE,      config.depth_bits,
        EGL_STENCIL_SIZE,    config.stencil_bits,
        EGL_NONE,            // termination sentinel
        // clang-format on
    };

    EGLint config_count = 0;
    EGLConfig egl_config = nullptr;

    if (eglChooseConfig(display, attributes, &egl_config, 1, &config_count) !=
        EGL_TRUE) {
      return {false, nullptr};
    }

    bool success = config_count > 0 && egl_config != nullptr;

    return {success, success ? egl_config : nullptr};
  }

  static EGLResult<EGLSurface> CreateWindowSurface(
      EGLDisplay display,
      EGLConfig config,
      AndroidNativeWindow::Handle window_handle) {
    // The configurations are only required when dealing with extensions or VG.
    // We do neither.
    EGLSurface surface = eglCreateWindowSurface(
        display, config, reinterpret_cast<EGLNativeWindowType>(window_handle),
        nullptr);
    return {surface != EGL_NO_SURFACE, surface};
  }

  static EGLResult<EGLSurface> CreateContext(EGLDisplay display,
                                             EGLConfig config) {
    EGLint attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE};

    EGLContext context =
        eglCreateContext(display, config, EGL_NO_CONTEXT, attributes);

    return {context != EGL_NO_CONTEXT, context};
  }

  DISALLOW_COPY_AND_ASSIGN(AndroidGLContext);
};

static jlong Attach(JNIEnv* env, jclass clazz, jint skyEngineHandle) {
  ShellView* shell_view = new ShellView(Shell::Shared());
  auto view = static_cast<PlatformViewAndroid*>(shell_view->view());
  view->SetShellView(std::unique_ptr<ShellView>(shell_view));
  view->ConnectToEngine(mojo::InterfaceRequest<SkyEngine>(
      mojo::ScopedMessagePipeHandle(mojo::MessagePipeHandle(skyEngineHandle))));
  return reinterpret_cast<jlong>(shell_view->view());
}

jint GetObservatoryPort(JNIEnv* env, jclass clazz) {
  return blink::DartServiceIsolate::GetObservatoryPort();
}

// static
bool PlatformViewAndroid::Register(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

// Per platform implementation of PlatformView::Create
PlatformView* PlatformView::Create(const Config& config,
                                   SurfaceConfig surface_config) {
  return new PlatformViewAndroid(config, surface_config);
}

PlatformViewAndroid::PlatformViewAndroid(const Config& config,
                                         SurfaceConfig surface_config)
    : PlatformView(config, surface_config), weak_factory_(this) {}

PlatformViewAndroid::~PlatformViewAndroid() = default;

void PlatformViewAndroid::SetShellView(std::unique_ptr<ShellView> shell_view) {
  DCHECK(!shell_view_);
  shell_view_ = std::move(shell_view);
}

void PlatformViewAndroid::Detach(JNIEnv* env, jobject obj) {
  shell_view_.reset();
  // Note: |this| has been destroyed at this point.
}

void PlatformViewAndroid::SurfaceCreated(JNIEnv* env,
                                         jobject obj,
                                         jobject jsurface) {
  base::android::ScopedJavaLocalRef<jobject> protector(env, jsurface);
  // Note: This ensures that any local references used by
  // ANativeWindow_fromSurface are released immediately. This is needed as a
  // workaround for https://code.google.com/p/android/issues/detail?id=68174
  {
    base::android::ScopedJavaLocalFrame scoped_local_reference_frame(env);
    ANativeWindow* window = ANativeWindow_fromSurface(env, jsurface);
    auto context = WTF::MakeUnique<AndroidGLContext>(window, surface_config_);
    if (context->IsValid()) {
      context_ = std::move(context);
    }
    ANativeWindow_release(window);
  }

  NotifyCreated();
}

void PlatformViewAndroid::SurfaceDestroyed(JNIEnv* env, jobject obj) {
  NotifyDestroyed();
  context_ = nullptr;
}

base::WeakPtr<sky::shell::PlatformView> PlatformViewAndroid::GetWeakViewPtr() {
  return weak_factory_.GetWeakPtr();
}

uint64_t PlatformViewAndroid::DefaultFramebuffer() const {
  // FBO 0 is the default window bound framebuffer on Android.
  return 0;
}

bool PlatformViewAndroid::ContextMakeCurrent() {
  return context_ != nullptr ? context_->ContextMakeCurrent() : false;
}

bool PlatformViewAndroid::SwapBuffers() {
  return context_ != nullptr ? context_->SwapBuffers() : false;
}

}  // namespace shell
}  // namespace sky
