// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/shell/platform/android/platform_view_android.h"

#include <android/input.h>
#include <android/native_window_jni.h>
#include <EGL/egl.h>
#include <sys/resource.h>
#include <sys/time.h>
#include <sys/types.h>

#include <utility>

#include "base/android/jni_android.h"
#include "base/bind.h"
#include "base/location.h"
#include "base/trace_event/trace_event.h"
#include "flutter/common/threads.h"
#include "flutter/runtime/dart_service_isolate.h"
#include "flutter/sky/shell/shell.h"
#include "jni/FlutterView_jni.h"

namespace sky {
namespace shell {

namespace {

template <class T>
using EGLResult = std::pair<bool, T>;

EGLDisplay g_display = EGL_NO_DISPLAY;
EGLContext g_resource_context = EGL_NO_CONTEXT;
EGLSurface g_resource_surface = EGL_NO_SURFACE;

void LogLastEGLError() {
  struct EGLNameErrorPair {
    const char* name;
    EGLint code;
  };

#define _EGL_ERROR_DESC(a) \
  { #a, a }

  const EGLNameErrorPair pairs[] = {
      _EGL_ERROR_DESC(EGL_SUCCESS),
      _EGL_ERROR_DESC(EGL_NOT_INITIALIZED),
      _EGL_ERROR_DESC(EGL_BAD_ACCESS),
      _EGL_ERROR_DESC(EGL_BAD_ALLOC),
      _EGL_ERROR_DESC(EGL_BAD_ATTRIBUTE),
      _EGL_ERROR_DESC(EGL_BAD_CONTEXT),
      _EGL_ERROR_DESC(EGL_BAD_CONFIG),
      _EGL_ERROR_DESC(EGL_BAD_CURRENT_SURFACE),
      _EGL_ERROR_DESC(EGL_BAD_DISPLAY),
      _EGL_ERROR_DESC(EGL_BAD_SURFACE),
      _EGL_ERROR_DESC(EGL_BAD_MATCH),
      _EGL_ERROR_DESC(EGL_BAD_PARAMETER),
      _EGL_ERROR_DESC(EGL_BAD_NATIVE_PIXMAP),
      _EGL_ERROR_DESC(EGL_BAD_NATIVE_WINDOW),
      _EGL_ERROR_DESC(EGL_CONTEXT_LOST),
  };

#undef _EGL_ERROR_DESC

  const auto count = sizeof(pairs) / sizeof(EGLNameErrorPair);

  EGLint last_error = eglGetError();

  for (size_t i = 0; i < count; i++) {
    if (last_error == pairs[i].code) {
      DLOG(INFO) << "EGL Error: " << pairs[i].name << " (" << pairs[i].code
                 << ")";
      return;
    }
  }

  DLOG(WARNING) << "Unknown EGL Error";
}

EGLResult<EGLSurface> CreatePBufferSurface(EGLDisplay display,
                                           EGLConfig config) {
  // We only ever create pbuffer surfaces for background resource loading
  // contexts. We never bind the pbuffer to anything.
  const EGLint attribs[] = {EGL_WIDTH, 1, EGL_HEIGHT, 1, EGL_NONE};
  EGLSurface surface = eglCreatePbufferSurface(display, config, attribs);
  return {surface != EGL_NO_SURFACE, surface};
}

EGLResult<EGLSurface> CreateContext(EGLDisplay display,
                                    EGLConfig config,
                                    EGLContext share = EGL_NO_CONTEXT) {
  EGLint attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE};

  EGLContext context = eglCreateContext(display, config, share, attributes);

  return {context != EGL_NO_CONTEXT, context};
}

EGLResult<EGLConfig> ChooseEGLConfiguration(
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

void InitGlobal() {
  // Get the display.
  g_display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
  if (g_display == EGL_NO_DISPLAY)
    return;

  // Initialize the display connection.
  if (eglInitialize(g_display, nullptr, nullptr) != EGL_TRUE)
    return;

  bool success;

  // Choose a config for resource loading.
  PlatformView::SurfaceConfig resource_config;
  resource_config.stencil_bits = 0;

  EGLConfig resource_egl_config;
  std::tie(success, resource_egl_config) =
      ChooseEGLConfiguration(g_display, resource_config);
  if (!success) {
    DLOG(INFO) << "Could not choose a resource configuration.";
    LogLastEGLError();
    return;
  }

  // Create a pbuffer surface for the configuration for resource loading.
  std::tie(success, g_resource_surface) =
      CreatePBufferSurface(g_display, resource_egl_config);
  if (!success) {
    DLOG(INFO) << "Could not create the pbuffer surface for resource loading.";
    LogLastEGLError();
    return;
  }

  // Create a resource context for the configuration.
  std::tie(success, g_resource_context) =
      CreateContext(g_display, resource_egl_config);

  if (!success) {
    DLOG(INFO) << "Could not create the resource context.";
    LogLastEGLError();
    return;
  }
}

}  // namespace

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

  FTL_DISALLOW_COPY_AND_ASSIGN(AndroidNativeWindow);
};

class AndroidGLContext {
 public:
  explicit AndroidGLContext(AndroidNativeWindow::Handle window_handle,
                            PlatformView::SurfaceConfig config)
      : window_(window_handle),
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

    // Choose a valid configuration.

    std::tie(success, config_) = ChooseEGLConfiguration(g_display, config);

    if (!success) {
      DLOG(INFO) << "Could not choose a window configuration.";
      LogLastEGLError();
      return;
    }

    // Create a window surface for the configuration.

    std::tie(success, surface_) =
        CreateWindowSurface(g_display, config_, window_.handle());

    if (!success) {
      DLOG(INFO) << "Could not create the window surface.";
      LogLastEGLError();
      return;
    }

    // Create a context for the configuration.

    std::tie(success, context_) =
        CreateContext(g_display, config_, g_resource_context);

    if (!success) {
      DLOG(INFO) << "Could not create the main rendering context";
      LogLastEGLError();
      return;
    }

    // All done!
    valid_ = true;
  }

  ~AndroidGLContext() {
    if (!TeardownContext(g_display, context_)) {
      LOG(INFO)
          << "Could not tear down the EGL context. Possible resource leak.";
      LogLastEGLError();
    }

    if (!TeardownSurface(g_display, surface_)) {
      LOG(INFO)
          << "Could not tear down the EGL surface. Possible resource leak.";
      LogLastEGLError();
    }
  }

  bool IsValid() const { return valid_; }

  bool ContextMakeCurrent() {
    if (eglMakeCurrent(g_display, surface_, surface_, context_) != EGL_TRUE) {
      LOG(INFO) << "Could not make the context current";
      LogLastEGLError();
      return false;
    }
    return true;
  }

  bool SwapBuffers() { return eglSwapBuffers(g_display, surface_); }

  SkISize GetSize() {
    EGLint width = 0;
    EGLint height = 0;
    if (!eglQuerySurface(g_display, surface_, EGL_WIDTH, &width) ||
        !eglQuerySurface(g_display, surface_, EGL_HEIGHT, &height)) {
      LOG(ERROR) << "Unable to query EGL surface size";
      LogLastEGLError();
      return SkISize::Make(0, 0);
    }
    return SkISize::Make(width, height);
  }

  void Resize(const SkISize& size) {
    eglMakeCurrent(g_display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);

    TeardownSurface(g_display, surface_);

    bool success;
    std::tie(success, surface_) =
        CreateWindowSurface(g_display, config_, window_.handle());
    if (!success) {
      LOG(ERROR) << "Unable to create EGL window surface";
    }
  }

 private:
  AndroidNativeWindow window_;
  EGLConfig config_;
  EGLSurface surface_;
  EGLContext context_;

  bool valid_;

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

  FTL_DISALLOW_COPY_AND_ASSIGN(AndroidGLContext);
};

static jlong Attach(JNIEnv* env,
                    jclass clazz,
                    jint skyEngineHandle,
                    jobject flutterView) {
  PlatformViewAndroid* view = new PlatformViewAndroid();
  view->ConnectToEngine(mojo::InterfaceRequest<SkyEngine>(
      mojo::ScopedMessagePipeHandle(mojo::MessagePipeHandle(skyEngineHandle))));

  // Create a weak reference to the flutterView Java object so that we can make
  // calls into it later.
  view->set_flutter_view(JavaObjectWeakGlobalRef(env, flutterView));
  return reinterpret_cast<jlong>(view);
}

jint GetObservatoryPort(JNIEnv* env, jclass clazz) {
  return blink::DartServiceIsolate::GetObservatoryPort();
}

// static
bool PlatformViewAndroid::Register(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

PlatformViewAndroid::PlatformViewAndroid() : weak_factory_(this) {
  // If this is the first PlatformView, then intiialize EGL and set up
  // the resource context.
  if (g_display == EGL_NO_DISPLAY)
    InitGlobal();
}

PlatformViewAndroid::~PlatformViewAndroid() = default;

void PlatformViewAndroid::Detach(JNIEnv* env, jobject obj) {
  delete this;
}

void PlatformViewAndroid::SurfaceCreated(JNIEnv* env,
                                         jobject obj,
                                         jobject jsurface) {
  // Note: This ensures that any local references used by
  // ANativeWindow_fromSurface are released immediately. This is needed as a
  // workaround for https://code.google.com/p/android/issues/detail?id=68174
  {
    base::android::ScopedJavaLocalFrame scoped_local_reference_frame(env);
    ANativeWindow* window = ANativeWindow_fromSurface(env, jsurface);
    std::unique_ptr<AndroidGLContext> context(
        new AndroidGLContext(window, surface_config_));
    if (context->IsValid()) {
      context_ = std::move(context);
    }
    ANativeWindow_release(window);
  }

  NotifyCreated();

  SetupResourceContextOnIOThread();

  UpdateThreadPriorities();
}

void PlatformViewAndroid::UpdateThreadPriorities() {
  blink::Threads::Gpu()->PostTask(
      []() { ::setpriority(PRIO_PROCESS, gettid(), -2); });

  blink::Threads::UI()->PostTask(
      []() { ::setpriority(PRIO_PROCESS, gettid(), -1); });
}

void PlatformViewAndroid::SurfaceDestroyed(JNIEnv* env, jobject obj) {
  NotifyDestroyed();
  context_ = nullptr;
}

ftl::WeakPtr<sky::shell::PlatformView> PlatformViewAndroid::GetWeakViewPtr() {
  return weak_factory_.GetWeakPtr();
}

uint64_t PlatformViewAndroid::DefaultFramebuffer() const {
  // FBO 0 is the default window bound framebuffer on Android.
  return 0;
}

bool PlatformViewAndroid::ContextMakeCurrent() {
  return context_ != nullptr ? context_->ContextMakeCurrent() : false;
}

bool PlatformViewAndroid::ResourceContextMakeCurrent() {
  if (eglMakeCurrent(g_display, g_resource_surface, g_resource_surface,
                     g_resource_context) != EGL_TRUE) {
    LOG(INFO) << "Could not make the resource context current";
    LogLastEGLError();
    return false;
  }
  return true;
}

bool PlatformViewAndroid::SwapBuffers() {
  TRACE_EVENT0("flutter", "PlatformViewAndroid::SwapBuffers");
  return context_ != nullptr ? context_->SwapBuffers() : false;
}

SkISize PlatformViewAndroid::GetSize() {
  return context_->GetSize();
}

void PlatformViewAndroid::Resize(const SkISize& size) {
  context_->Resize(size);
}

void PlatformViewAndroid::RunFromSource(const std::string& main,
                                        const std::string& packages,
                                        const std::string& assets_directory) {
  FTL_CHECK(base::android::IsVMInitialized());
  JNIEnv* env = base::android::AttachCurrentThread();
  FTL_CHECK(env);

  {
    base::android::ScopedJavaLocalRef<jobject> local_flutter_view =
        flutter_view_.get(env);
    if (local_flutter_view.is_null()) {
      // Collected.
      return;
    }

    // Grab the class of the flutter view.
    jclass flutter_view_class = env->GetObjectClass(local_flutter_view.obj());
    FTL_CHECK(flutter_view_class);

    // Grab the runFromSource method id.
    jmethodID run_from_source_method_id = env->GetMethodID(
        flutter_view_class, "runFromSource",
        "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V");
    FTL_CHECK(run_from_source_method_id);

    // Invoke runFromSource on the Android UI thread.
    jstring java_main = env->NewStringUTF(main.c_str());
    FTL_CHECK(java_main);
    jstring java_packages = env->NewStringUTF(packages.c_str());
    FTL_CHECK(java_packages);
    jstring java_assets_directory = env->NewStringUTF(assets_directory.c_str());
    FTL_CHECK(java_assets_directory);
    env->CallVoidMethod(local_flutter_view.obj(), run_from_source_method_id,
                        java_main, java_packages, java_assets_directory);
  }

  // Detaching from the VM deletes any stray local references.
  base::android::DetachFromVM();
}

}  // namespace shell
}  // namespace sky
