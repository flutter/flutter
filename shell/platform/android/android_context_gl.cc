// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_context_gl.h"

#include <EGL/eglext.h>

#include <list>
#include <utility>

// required to get API level
#include <sys/system_properties.h>

#include "flutter/fml/trace_event.h"

namespace flutter {

template <class T>
using EGLResult = std::pair<bool, T>;

static void LogLastEGLError() {
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
      FML_LOG(ERROR) << "EGL Error: " << pairs[i].name << " (" << pairs[i].code
                     << ")";
      return;
    }
  }

  FML_LOG(ERROR) << "Unknown EGL Error";
}

static EGLResult<EGLContext> CreateContext(EGLDisplay display,
                                           EGLConfig config,
                                           EGLContext share = EGL_NO_CONTEXT) {
  EGLint attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE};

  EGLContext context = eglCreateContext(display, config, share, attributes);

  return {context != EGL_NO_CONTEXT, context};
}

static EGLResult<EGLConfig> ChooseEGLConfiguration(EGLDisplay display,
                                                   uint8_t msaa_samples) {
  EGLint sample_buffers = msaa_samples > 1 ? 1 : 0;
  EGLint attributes[] = {
      // clang-format off
      EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
      EGL_SURFACE_TYPE,    EGL_WINDOW_BIT,
      EGL_RED_SIZE,        8,
      EGL_GREEN_SIZE,      8,
      EGL_BLUE_SIZE,       8,
      EGL_ALPHA_SIZE,      8,
      EGL_DEPTH_SIZE,      0,
      EGL_STENCIL_SIZE,    8,
      EGL_SAMPLES,         static_cast<EGLint>(msaa_samples),
      EGL_SAMPLE_BUFFERS,  sample_buffers,
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

static bool TeardownContext(EGLDisplay display, EGLContext context) {
  if (context != EGL_NO_CONTEXT) {
    return eglDestroyContext(display, context) == EGL_TRUE;
  }

  return true;
}

class AndroidEGLSurfaceDamage {
 public:
  void init(EGLDisplay display, EGLContext context) {
    if (GetAPILevel() < 28) {
      // Disable partial repaint for devices older than Android 9. There
      // are old devices that have extensions below available but the
      // implementation causes glitches (i.e. Xperia Z3 with Android 6).
      partial_redraw_supported_ = false;
      return;
    }

    const char* extensions = eglQueryString(display, EGL_EXTENSIONS);

    if (HasExtension(extensions, "EGL_KHR_partial_update")) {
      set_damage_region_ = reinterpret_cast<PFNEGLSETDAMAGEREGIONKHRPROC>(
          eglGetProcAddress("eglSetDamageRegionKHR"));
    }

    if (HasExtension(extensions, "EGL_EXT_swap_buffers_with_damage")) {
      swap_buffers_with_damage_ =
          reinterpret_cast<PFNEGLSWAPBUFFERSWITHDAMAGEEXTPROC>(
              eglGetProcAddress("eglSwapBuffersWithDamageEXT"));
    } else if (HasExtension(extensions, "EGL_KHR_swap_buffers_with_damage")) {
      swap_buffers_with_damage_ =
          reinterpret_cast<PFNEGLSWAPBUFFERSWITHDAMAGEEXTPROC>(
              eglGetProcAddress("eglSwapBuffersWithDamageKHR"));
    }

    partial_redraw_supported_ =
        set_damage_region_ != nullptr && swap_buffers_with_damage_ != nullptr;
  }

  static int GetAPILevel() {
    char sdk_version_string[PROP_VALUE_MAX];
    if (__system_property_get("ro.build.version.sdk", sdk_version_string)) {
      return atoi(sdk_version_string);
    } else {
      return -1;
    }
  }

  void SetDamageRegion(EGLDisplay display,
                       EGLSurface surface,
                       const std::optional<SkIRect>& region) {
    if (set_damage_region_ && region) {
      auto rects = RectToInts(display, surface, *region);
      set_damage_region_(display, surface, rects.data(), 1);
    }
  }

  // Maximum damage history - for triple buffering we need to store damage for
  // last two frames; Some Android devices (Pixel 4) use quad buffering.
  static const int kMaxHistorySize = 10;

  bool SupportsPartialRepaint() const { return partial_redraw_supported_; }

  std::optional<SkIRect> InitialDamage(EGLDisplay display, EGLSurface surface) {
    if (!partial_redraw_supported_) {
      return std::nullopt;
    }

    EGLint age;
    eglQuerySurface(display, surface, EGL_BUFFER_AGE_EXT, &age);

    if (age == 0) {  // full repaint
      return std::nullopt;
    } else {
      // join up to (age - 1) last rects from damage history
      --age;
      auto res = SkIRect::MakeEmpty();
      for (auto i = damage_history_.rbegin();
           i != damage_history_.rend() && age > 0; ++i, --age) {
        res.join(*i);
      }
      return res;
    }
  }

  bool SwapBuffersWithDamage(EGLDisplay display,
                             EGLSurface surface,
                             const std::optional<SkIRect>& damage) {
    if (swap_buffers_with_damage_ && damage) {
      damage_history_.push_back(*damage);
      if (damage_history_.size() > kMaxHistorySize) {
        damage_history_.pop_front();
      }
      auto rects = RectToInts(display, surface, *damage);
      return swap_buffers_with_damage_(display, surface, rects.data(), 1);
    } else {
      return eglSwapBuffers(display, surface);
    }
  }

 private:
  std::array<EGLint, 4> static RectToInts(EGLDisplay display,
                                          EGLSurface surface,
                                          const SkIRect& rect) {
    EGLint height;
    eglQuerySurface(display, surface, EGL_HEIGHT, &height);

    std::array<EGLint, 4> res{rect.left(), height - rect.bottom(), rect.width(),
                              rect.height()};
    return res;
  }

  PFNEGLSETDAMAGEREGIONKHRPROC set_damage_region_ = nullptr;
  PFNEGLSWAPBUFFERSWITHDAMAGEEXTPROC swap_buffers_with_damage_ = nullptr;

  bool partial_redraw_supported_;

  bool HasExtension(const char* extensions, const char* name) {
    const char* r = strstr(extensions, name);
    auto len = strlen(name);
    // check that the extension name is terminated by space or null terminator
    return r != nullptr && (r[len] == ' ' || r[len] == 0);
  }

  std::list<SkIRect> damage_history_;
};

AndroidEGLSurface::AndroidEGLSurface(EGLSurface surface,
                                     EGLDisplay display,
                                     EGLContext context)
    : surface_(surface),
      display_(display),
      context_(context),
      damage_(std::make_unique<AndroidEGLSurfaceDamage>()) {
  damage_->init(display_, context);
}

AndroidEGLSurface::~AndroidEGLSurface() {
  [[maybe_unused]] auto result = eglDestroySurface(display_, surface_);
  FML_DCHECK(result == EGL_TRUE);
}

bool AndroidEGLSurface::IsValid() const {
  return surface_ != EGL_NO_SURFACE;
}

bool AndroidEGLSurface::MakeCurrent() const {
  if (eglMakeCurrent(display_, surface_, surface_, context_) != EGL_TRUE) {
    FML_LOG(ERROR) << "Could not make the context current";
    LogLastEGLError();
    return false;
  }
  return true;
}

void AndroidEGLSurface::SetDamageRegion(
    const std::optional<SkIRect>& buffer_damage) {
  damage_->SetDamageRegion(display_, surface_, buffer_damage);
}

bool AndroidEGLSurface::SwapBuffers(
    const std::optional<SkIRect>& surface_damage) {
  TRACE_EVENT0("flutter", "AndroidContextGL::SwapBuffers");
  return damage_->SwapBuffersWithDamage(display_, surface_, surface_damage);
}

bool AndroidEGLSurface::SupportsPartialRepaint() const {
  return damage_->SupportsPartialRepaint();
}

std::optional<SkIRect> AndroidEGLSurface::InitialDamage() {
  return damage_->InitialDamage(display_, surface_);
}

SkISize AndroidEGLSurface::GetSize() const {
  EGLint width = 0;
  EGLint height = 0;

  if (!eglQuerySurface(display_, surface_, EGL_WIDTH, &width) ||
      !eglQuerySurface(display_, surface_, EGL_HEIGHT, &height)) {
    FML_LOG(ERROR) << "Unable to query EGL surface size";
    LogLastEGLError();
    return SkISize::Make(0, 0);
  }
  return SkISize::Make(width, height);
}

AndroidContextGL::AndroidContextGL(
    AndroidRenderingAPI rendering_api,
    fml::RefPtr<AndroidEnvironmentGL> environment,
    const TaskRunners& task_runners,
    uint8_t msaa_samples)
    : AndroidContext(AndroidRenderingAPI::kOpenGLES),
      environment_(environment),
      config_(nullptr),
      task_runners_(task_runners) {
  if (!environment_->IsValid()) {
    FML_LOG(ERROR) << "Could not create an Android GL environment.";
    return;
  }

  bool success = false;

  // Choose a valid configuration.
  std::tie(success, config_) =
      ChooseEGLConfiguration(environment_->Display(), msaa_samples);
  if (!success) {
    FML_LOG(ERROR) << "Could not choose an EGL configuration.";
    LogLastEGLError();
    return;
  }

  // Create a context for the configuration.
  std::tie(success, context_) =
      CreateContext(environment_->Display(), config_, EGL_NO_CONTEXT);
  if (!success) {
    FML_LOG(ERROR) << "Could not create an EGL context";
    LogLastEGLError();
    return;
  }

  std::tie(success, resource_context_) =
      CreateContext(environment_->Display(), config_, context_);
  if (!success) {
    FML_LOG(ERROR) << "Could not create an EGL resource context";
    LogLastEGLError();
    return;
  }

  // All done!
  valid_ = true;
}

AndroidContextGL::~AndroidContextGL() {
  FML_DCHECK(task_runners_.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());
  sk_sp<GrDirectContext> main_context = GetMainSkiaContext();
  SetMainSkiaContext(nullptr);
  fml::AutoResetWaitableEvent latch;
  // This context needs to be deallocated from the raster thread in order to
  // keep a coherent usage of egl from a single thread.
  fml::TaskRunner::RunNowOrPostTask(task_runners_.GetRasterTaskRunner(), [&] {
    if (main_context) {
      std::unique_ptr<AndroidEGLSurface> pbuffer_surface =
          CreatePbufferSurface();
      if (pbuffer_surface->MakeCurrent()) {
        main_context->releaseResourcesAndAbandonContext();
        main_context.reset();
        ClearCurrent();
      }
    }
    latch.Signal();
  });
  latch.Wait();

  if (!TeardownContext(environment_->Display(), context_)) {
    FML_LOG(ERROR)
        << "Could not tear down the EGL context. Possible resource leak.";
    LogLastEGLError();
  }

  if (!TeardownContext(environment_->Display(), resource_context_)) {
    FML_LOG(ERROR) << "Could not tear down the EGL resource context. Possible "
                      "resource leak.";
    LogLastEGLError();
  }
}

std::unique_ptr<AndroidEGLSurface> AndroidContextGL::CreateOnscreenSurface(
    fml::RefPtr<AndroidNativeWindow> window) const {
  if (window->IsFakeWindow()) {
    return CreatePbufferSurface();
  } else {
    EGLDisplay display = environment_->Display();

    const EGLint attribs[] = {EGL_NONE};

    EGLSurface surface = eglCreateWindowSurface(
        display, config_,
        reinterpret_cast<EGLNativeWindowType>(window->handle()), attribs);
    return std::make_unique<AndroidEGLSurface>(surface, display, context_);
  }
}

std::unique_ptr<AndroidEGLSurface> AndroidContextGL::CreateOffscreenSurface()
    const {
  // We only ever create pbuffer surfaces for background resource loading
  // contexts. We never bind the pbuffer to anything.
  EGLDisplay display = environment_->Display();

  const EGLint attribs[] = {EGL_WIDTH, 1, EGL_HEIGHT, 1, EGL_NONE};

  EGLSurface surface = eglCreatePbufferSurface(display, config_, attribs);
  return std::make_unique<AndroidEGLSurface>(surface, display,
                                             resource_context_);
}

std::unique_ptr<AndroidEGLSurface> AndroidContextGL::CreatePbufferSurface()
    const {
  EGLDisplay display = environment_->Display();

  const EGLint attribs[] = {EGL_WIDTH, 1, EGL_HEIGHT, 1, EGL_NONE};

  EGLSurface surface = eglCreatePbufferSurface(display, config_, attribs);
  return std::make_unique<AndroidEGLSurface>(surface, display, context_);
}

fml::RefPtr<AndroidEnvironmentGL> AndroidContextGL::Environment() const {
  return environment_;
}

bool AndroidContextGL::IsValid() const {
  return valid_;
}

bool AndroidContextGL::ClearCurrent() const {
  if (eglGetCurrentContext() != context_) {
    return true;
  }
  if (eglMakeCurrent(environment_->Display(), EGL_NO_SURFACE, EGL_NO_SURFACE,
                     EGL_NO_CONTEXT) != EGL_TRUE) {
    FML_LOG(ERROR) << "Could not clear the current context";
    LogLastEGLError();
    return false;
  }
  return true;
}

EGLContext AndroidContextGL::CreateNewContext() const {
  bool success;
  EGLContext context;
  std::tie(success, context) =
      CreateContext(environment_->Display(), config_, EGL_NO_CONTEXT);
  return success ? context : EGL_NO_CONTEXT;
}

}  // namespace flutter
