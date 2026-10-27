// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_platform_views_controller.h"

#if FML_OS_ANDROID
#include <android/api-level.h>
#include <android/native_window.h>
#include <android/native_window_jni.h>
#endif

#include <algorithm>
#include <array>
#include <cmath>
#include <limits>
#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/trace_event.h"

namespace flutter {

namespace {

/// Magic tag (0x46424B53544F5245 = "FBKSTORE") stored on `BackingStoreContext`
/// to verify that `FlutterBackingStore::user_data` was allocated by this
/// `AndroidPlatformViewsController`.
constexpr uint64_t kBackingStoreContextMagic = 0x46424B53544F5245ULL;

/// GL_RGBA8 sized internal format constant (0x8058) for OpenGL framebuffers.
constexpr uint32_t kGlRgba8Format = 0x8058u;

/// Epsilon used when comparing whether the mutator stack's root scale matches
/// the device pixel ratio.
constexpr float kDevicePixelRatioMatchEpsilon = 1e-4f;

/// Number of corners of a rectangle, used when computing the axis-aligned
/// bounds of a transformed platform view rect.
constexpr size_t kRectCornerCount = 4;

/// Minimum valid device pixel ratio; non-positive or non-finite values fall
/// back to 1.0.
constexpr double kDefaultControllerDevicePixelRatio = 1.0;

int32_t DetectRuntimeAndroidApiLevel() {
#if FML_OS_ANDROID
  return android_get_device_api_level();
#else
  return kAndroidApiLevelPathConics;
#endif
}

bool ClearJniExceptionIfAny(JNIEnv* env) {
  if (env != nullptr && env->functions != nullptr &&
      env->functions->ExceptionCheck != nullptr &&
      env->ExceptionCheck() == JNI_TRUE) {
    if (env->functions->ExceptionClear != nullptr) {
      env->ExceptionClear();
    }
    return true;
  }
  return false;
}

bool IsRealJniEnv(JNIEnv* env) {
  return env != nullptr && env->functions != nullptr &&
         env->functions->GetJavaVM != nullptr;
}

template <typename T>
bool InvokeOnDisplayOverlaySurfaceHelper(T* invoker,
                                         int32_t surface_id,
                                         int32_t x,
                                         int32_t y,
                                         int32_t width,
                                         int32_t height) {
  if constexpr (requires {
                  invoker->OnDisplayOverlaySurface(surface_id, x, y, width,
                                                   height);
                }) {
    invoker->OnDisplayOverlaySurface(surface_id, x, y, width, height);
    return true;
  } else {
    JNIEnv* env = invoker->GetEnv();
    if (env == nullptr || env->functions == nullptr ||
        env->functions->GetObjectClass == nullptr ||
        env->functions->GetMethodID == nullptr ||
        env->functions->CallVoidMethod == nullptr) {
      return true;
    }
    auto java_object = invoker->GetFlutterJni(env);
    if (java_object.is_null()) {
      return true;
    }
    jclass clazz = env->GetObjectClass(java_object.obj());
    if (ClearJniExceptionIfAny(env) || clazz == nullptr) {
      return true;
    }
    jmethodID method =
        env->GetMethodID(clazz, "onDisplayOverlaySurface", "(IIIII)V");
    const bool method_had_exception = ClearJniExceptionIfAny(env);
    if (env->functions->DeleteLocalRef != nullptr) {
      env->DeleteLocalRef(clazz);
    }
    if (!method_had_exception && method != nullptr) {
      env->CallVoidMethod(java_object.obj(), method,
                          static_cast<jint>(surface_id), static_cast<jint>(x),
                          static_cast<jint>(y), static_cast<jint>(width),
                          static_cast<jint>(height));
      ClearJniExceptionIfAny(env);
    }
    return true;
  }
}

template <typename T>
void InvokeSealFrameTransactionsHelper(T* invoker) {
  if constexpr (requires { invoker->SealFrameTransactions(); }) {
    invoker->SealFrameTransactions();
  } else {
    JNIEnv* env = invoker->GetEnv();
    if (!IsRealJniEnv(env)) {
      return;
    }
    auto java_object = invoker->GetFlutterJni(env);
    if (java_object.is_null()) {
      return;
    }
    jclass clazz = env->GetObjectClass(java_object.obj());
    if (ClearJniExceptionIfAny(env) || clazz == nullptr) {
      return;
    }
    jmethodID method = env->GetMethodID(clazz, "sealFrameTransactions", "()V");
    const bool method_had_exception = ClearJniExceptionIfAny(env);
    env->DeleteLocalRef(clazz);
    if (!method_had_exception && method != nullptr) {
      env->CallVoidMethod(java_object.obj(), method);
      ClearJniExceptionIfAny(env);
    }
  }
}

template <typename T>
void InvokeSwapTransactionsHelper(T* invoker) {
  if constexpr (requires { invoker->SwapTransactions(); }) {
    invoker->SwapTransactions();
  } else {
    JNIEnv* env = invoker->GetEnv();
    if (!IsRealJniEnv(env)) {
      return;
    }
    auto java_object = invoker->GetFlutterJni(env);
    if (java_object.is_null()) {
      return;
    }
    jclass clazz = env->GetObjectClass(java_object.obj());
    if (ClearJniExceptionIfAny(env) || clazz == nullptr) {
      return;
    }
    jmethodID method = env->GetMethodID(clazz, "swapTransactions", "()V");
    const bool method_had_exception = ClearJniExceptionIfAny(env);
    env->DeleteLocalRef(clazz);
    if (!method_had_exception && method != nullptr) {
      env->CallVoidMethod(java_object.obj(), method);
      ClearJniExceptionIfAny(env);
    }
  }
}

void UnpackMutatorsStackForJvmInvoker(const AndroidMutatorsStack& stack,
                                      std::vector<int32_t>* out_types,
                                      std::vector<float>* out_matrices,
                                      std::vector<int32_t>* out_rects,
                                      std::vector<float>* out_rrects,
                                      std::vector<float>* out_opacities) {
  for (const auto& mutator : stack.GetMutators()) {
    out_types->push_back(static_cast<int32_t>(mutator.type));
    switch (mutator.type) {
      case AndroidMutatorType::kTransform:
        out_matrices->insert(out_matrices->end(), mutator.matrix.values.begin(),
                             mutator.matrix.values.end());
        break;
      case AndroidMutatorType::kClipRect:
        out_rects->push_back(
            static_cast<int32_t>(std::round(mutator.rect.left)));
        out_rects->push_back(
            static_cast<int32_t>(std::round(mutator.rect.top)));
        out_rects->push_back(
            static_cast<int32_t>(std::round(mutator.rect.right)));
        out_rects->push_back(
            static_cast<int32_t>(std::round(mutator.rect.bottom)));
        break;
      case AndroidMutatorType::kClipRRect:
        out_rrects->push_back(mutator.rrect.rect.left);
        out_rrects->push_back(mutator.rrect.rect.top);
        out_rrects->push_back(mutator.rrect.rect.right);
        out_rrects->push_back(mutator.rrect.rect.bottom);
        out_rrects->insert(out_rrects->end(), mutator.rrect.radii.begin(),
                           mutator.rrect.radii.end());
        break;
      case AndroidMutatorType::kClipPath:
        out_rects->push_back(
            static_cast<int32_t>(std::round(mutator.rect.left)));
        out_rects->push_back(
            static_cast<int32_t>(std::round(mutator.rect.top)));
        out_rects->push_back(
            static_cast<int32_t>(std::round(mutator.rect.right)));
        out_rects->push_back(
            static_cast<int32_t>(std::round(mutator.rect.bottom)));
        break;
      case AndroidMutatorType::kOpacity:
        out_opacities->push_back(mutator.opacity);
        break;
    }
  }
}

}  // namespace

// =============================================================================
// DefaultPlatformViewsProvider
// =============================================================================

DefaultPlatformViewsProvider::DefaultPlatformViewsProvider(
    std::shared_ptr<JvmInvoker> jvm_invoker)
    : shared_jvm_invoker_(std::move(jvm_invoker)),
      raw_jvm_invoker_(shared_jvm_invoker_.get()) {}

DefaultPlatformViewsProvider::DefaultPlatformViewsProvider(
    JvmInvoker* raw_jvm_invoker)
    : raw_jvm_invoker_(raw_jvm_invoker) {}

DefaultPlatformViewsProvider::~DefaultPlatformViewsProvider() {
  DefaultPlatformViewsProvider::DestroyOverlaySurfaces();
}

void DefaultPlatformViewsProvider::SetJvmInvoker(
    std::shared_ptr<JvmInvoker> jvm_invoker) {
  std::lock_guard<std::mutex> lock(mutex_);
  shared_jvm_invoker_ = std::move(jvm_invoker);
  raw_jvm_invoker_ = shared_jvm_invoker_.get();
}

void DefaultPlatformViewsProvider::SetJvmInvoker(JvmInvoker* raw_jvm_invoker) {
  std::lock_guard<std::mutex> lock(mutex_);
  shared_jvm_invoker_.reset();
  raw_jvm_invoker_ = raw_jvm_invoker;
}

JvmInvoker* DefaultPlatformViewsProvider::GetInvoker() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return raw_jvm_invoker_;
}

int64_t DefaultPlatformViewsProvider::CreatePlatformView(
    const PlatformViewCreationParams& params,
    PlatformViewCompositionType type) {
  TRACE_EVENT1("flutter", "DefaultPlatformViewsProvider::CreatePlatformView",
               "view_id", std::to_string(params.view_id).c_str());
  JvmInvoker* invoker = GetInvoker();
  if (invoker == nullptr || !invoker->IsAttached()) {
    return -1;
  }
  invoker->CreatePlatformView(static_cast<int32_t>(params.view_id),
                              params.view_type, params.width, params.height,
                              params.direction, params.creation_params);
  if (type == PlatformViewCompositionType::kTextureLayer) {
    return params.texture_id >= 0 ? params.texture_id : params.view_id;
  }
  return 0;
}

bool DefaultPlatformViewsProvider::DisposePlatformView(int64_t view_id) {
  TRACE_EVENT1("flutter", "DefaultPlatformViewsProvider::DisposePlatformView",
               "view_id", std::to_string(view_id).c_str());
  JvmInvoker* invoker = GetInvoker();
  if (invoker == nullptr || !invoker->IsAttached()) {
    return false;
  }
  invoker->DisposePlatformView(static_cast<int32_t>(view_id));
  return true;
}

bool DefaultPlatformViewsProvider::ResizePlatformView(
    const PlatformViewResizeRequest& request,
    double* out_width,
    double* out_height) {
  TRACE_EVENT1("flutter", "DefaultPlatformViewsProvider::ResizePlatformView",
               "view_id", std::to_string(request.view_id).c_str());
  JvmInvoker* invoker = GetInvoker();
  if (invoker == nullptr || !invoker->IsAttached()) {
    return false;
  }
  invoker->ResizePlatformView(static_cast<int32_t>(request.view_id),
                              request.width, request.height);
  if (out_width != nullptr) {
    *out_width = request.width;
  }
  if (out_height != nullptr) {
    *out_height = request.height;
  }
  return true;
}

bool DefaultPlatformViewsProvider::OffsetPlatformView(int64_t view_id,
                                                      double top,
                                                      double left) {
  TRACE_EVENT1("flutter", "DefaultPlatformViewsProvider::OffsetPlatformView",
               "view_id", std::to_string(view_id).c_str());
  JvmInvoker* invoker = GetInvoker();
  if (invoker == nullptr || !invoker->IsAttached()) {
    return false;
  }
  invoker->OffsetPlatformView(static_cast<int32_t>(view_id), top, left);
  return true;
}

bool DefaultPlatformViewsProvider::SetPlatformViewDirection(int64_t view_id,
                                                            int32_t direction) {
  TRACE_EVENT1("flutter",
               "DefaultPlatformViewsProvider::SetPlatformViewDirection",
               "view_id", std::to_string(view_id).c_str());
  (void)direction;
  JvmInvoker* invoker = GetInvoker();
  return invoker != nullptr && invoker->IsAttached();
}

bool DefaultPlatformViewsProvider::ClearPlatformViewFocus(int64_t view_id) {
  TRACE_EVENT1("flutter",
               "DefaultPlatformViewsProvider::ClearPlatformViewFocus",
               "view_id", std::to_string(view_id).c_str());
  JvmInvoker* invoker = GetInvoker();
  return invoker != nullptr && invoker->IsAttached();
}

bool DefaultPlatformViewsProvider::DispatchPlatformViewTouch(
    const PlatformViewTouch& touch) {
  TRACE_EVENT1("flutter",
               "DefaultPlatformViewsProvider::DispatchPlatformViewTouch",
               "view_id", std::to_string(touch.view_id).c_str());
  JvmInvoker* invoker = GetInvoker();
  return invoker != nullptr && invoker->IsAttached();
}

bool DefaultPlatformViewsProvider::OnDisplayPlatformView(
    const PlatformViewGeometry& geometry) {
  TRACE_EVENT1("flutter", "DefaultPlatformViewsProvider::OnDisplayPlatformView",
               "view_id", std::to_string(geometry.view_id).c_str());
  JvmInvoker* invoker = GetInvoker();
  if (invoker == nullptr || !invoker->IsAttached()) {
    return false;
  }

  JNIEnv* env = invoker->GetEnv();
  if (IsRealJniEnv(env)) {
    jobject j_mutators_stack = AndroidMutatorsMapper::CreateJavaMutatorsStack(
        env, geometry.mutators_stack, kDefaultControllerDevicePixelRatio);
    if (j_mutators_stack != nullptr) {
      auto java_object = invoker->GetFlutterJni(env);
      if (!java_object.is_null()) {
        jclass clazz = env->GetObjectClass(java_object.obj());
        if (!ClearJniExceptionIfAny(env) && clazz != nullptr) {
          const char* method_name = IsHcppEnabled() ? "onDisplayPlatformView2"
                                                    : "onDisplayPlatformView";
          jmethodID method = env->GetMethodID(
              clazz, method_name,
              "(IIIIIIILio/flutter/embedding/engine/mutatorsstack/"
              "FlutterMutatorsStack;)V");
          const bool method_had_exception = ClearJniExceptionIfAny(env);
          env->DeleteLocalRef(clazz);
          if (!method_had_exception && method != nullptr) {
            env->CallVoidMethod(
                java_object.obj(), method, static_cast<jint>(geometry.view_id),
                static_cast<jint>(geometry.x), static_cast<jint>(geometry.y),
                static_cast<jint>(geometry.width),
                static_cast<jint>(geometry.height),
                static_cast<jint>(geometry.view_width),
                static_cast<jint>(geometry.view_height), j_mutators_stack);
            ClearJniExceptionIfAny(env);
            env->DeleteLocalRef(j_mutators_stack);
            return true;
          }
        }
      }
      env->DeleteLocalRef(j_mutators_stack);
    }
  }

  std::vector<int32_t> mutators_types;
  std::vector<float> mutators_matrices;
  std::vector<int32_t> mutators_rects;
  std::vector<float> mutators_rrects;
  std::vector<float> mutators_opacities;
  UnpackMutatorsStackForJvmInvoker(geometry.mutators_stack, &mutators_types,
                                   &mutators_matrices, &mutators_rects,
                                   &mutators_rrects, &mutators_opacities);
  const int32_t mutators_count =
      static_cast<int32_t>(geometry.mutators_stack.GetMutatorsCount());

  if (IsHcppEnabled()) {
    invoker->OnDisplayPlatformView2(
        static_cast<int32_t>(geometry.view_id), geometry.x, geometry.y,
        geometry.width, geometry.height, geometry.view_width,
        geometry.view_height, mutators_count, mutators_types, mutators_matrices,
        mutators_rects, mutators_rrects, mutators_opacities);
  } else {
    invoker->OnPlatformViewDisplay(
        static_cast<int32_t>(geometry.view_id), geometry.x, geometry.y,
        geometry.width, geometry.height, geometry.view_width,
        geometry.view_height, mutators_count, mutators_types, mutators_matrices,
        mutators_rects, mutators_rrects, mutators_opacities);
  }
  return true;
}

bool DefaultPlatformViewsProvider::HidePlatformView(int64_t view_id) {
  TRACE_EVENT1("flutter", "DefaultPlatformViewsProvider::HidePlatformView",
               "view_id", std::to_string(view_id).c_str());
  JvmInvoker* invoker = GetInvoker();
  if (invoker == nullptr || !invoker->IsAttached()) {
    return false;
  }
  // In non-HCPP mode PlatformViewsController.onEndFrame() -> finishFrame()
  // already hides views that were not displayed this frame, and
  // PlatformViewsController2 does not own those views.
  if (!IsHcppEnabled()) {
    return true;
  }
  invoker->HidePlatformView2(static_cast<int32_t>(view_id));
  return true;
}

bool DefaultPlatformViewsProvider::SynchronizeToNativeViewHierarchy(bool yes) {
  TRACE_EVENT0(
      "flutter",
      "DefaultPlatformViewsProvider::SynchronizeToNativeViewHierarchy");
  (void)yes;
  JvmInvoker* invoker = GetInvoker();
  return invoker != nullptr && invoker->IsAttached();
}

bool DefaultPlatformViewsProvider::OnBeginFrame() {
  TRACE_EVENT0("flutter", "DefaultPlatformViewsProvider::OnBeginFrame");
  JvmInvoker* invoker = GetInvoker();
  if (invoker == nullptr || !invoker->IsAttached()) {
    return false;
  }
  invoker->OnBeginFrame();
  return true;
}

bool DefaultPlatformViewsProvider::OnEndFrame() {
  TRACE_EVENT0("flutter", "DefaultPlatformViewsProvider::OnEndFrame");
  JvmInvoker* invoker = GetInvoker();
  if (invoker == nullptr || !invoker->IsAttached()) {
    return false;
  }
  if (IsHcppEnabled()) {
    invoker->EndFrame2();
  } else {
    invoker->OnEndFrame();
  }
  return true;
}

std::optional<int32_t> DefaultPlatformViewsProvider::CreateOverlaySurface() {
  TRACE_EVENT0("flutter", "DefaultPlatformViewsProvider::CreateOverlaySurface");
  JvmInvoker* invoker = GetInvoker();
  if (invoker == nullptr || !invoker->IsAttached()) {
    return std::nullopt;
  }

  jobject overlay_surface = IsHcppEnabled() ? invoker->CreateOverlaySurface2()
                                            : invoker->CreateOverlaySurface();
  JNIEnv* env = invoker->GetEnv();
  if (env != nullptr && overlay_surface != nullptr) {
    const bool valid_ref =
        (env->functions == nullptr ||
         env->functions->GetObjectRefType == nullptr ||
         env->GetObjectRefType(overlay_surface) != JNIInvalidRefType);
    if (valid_ref && env->functions != nullptr &&
        env->functions->GetMethodID != nullptr &&
        env->functions->CallIntMethod != nullptr &&
        env->functions->CallObjectMethod != nullptr) {
      jclass overlay_clazz = nullptr;
      if (env->functions->GetObjectClass != nullptr) {
        overlay_clazz = env->GetObjectClass(overlay_surface);
        if (ClearJniExceptionIfAny(env)) {
          overlay_clazz = nullptr;
        }
      }
      if (overlay_clazz == nullptr && env->functions->FindClass != nullptr) {
        overlay_clazz =
            env->FindClass("io/flutter/embedding/engine/FlutterOverlaySurface");
        if (ClearJniExceptionIfAny(env)) {
          overlay_clazz = nullptr;
        }
      }
      if (overlay_clazz != nullptr) {
        jmethodID get_id_method =
            env->GetMethodID(overlay_clazz, "getId", "()I");
        if (ClearJniExceptionIfAny(env)) {
          get_id_method = nullptr;
        }
        jmethodID get_surface_method = env->GetMethodID(
            overlay_clazz, "getSurface", "()Landroid/view/Surface;");
        if (ClearJniExceptionIfAny(env)) {
          get_surface_method = nullptr;
        }
        if (get_id_method != nullptr && get_surface_method != nullptr) {
          const jint id = env->CallIntMethod(overlay_surface, get_id_method);
          const bool id_ok = !ClearJniExceptionIfAny(env);
          jobject java_surface =
              env->CallObjectMethod(overlay_surface, get_surface_method);
          if (ClearJniExceptionIfAny(env)) {
            java_surface = nullptr;
          }
          ANativeWindow* window = nullptr;
#if FML_OS_ANDROID
          if (java_surface != nullptr && IsRealJniEnv(env) &&
              (env->functions->GetObjectRefType == nullptr ||
               env->GetObjectRefType(java_surface) != JNIInvalidRefType)) {
            window = ANativeWindow_fromSurface(env, java_surface);
          }
#endif
          if (java_surface != nullptr &&
              env->functions->DeleteLocalRef != nullptr) {
            env->DeleteLocalRef(java_surface);
          }
          if (env->functions->DeleteLocalRef != nullptr) {
            env->DeleteLocalRef(overlay_clazz);
            env->DeleteLocalRef(overlay_surface);
          }
          if (id_ok) {
            std::lock_guard<std::mutex> lock(mutex_);
#if FML_OS_ANDROID
            auto prev_it = overlay_windows_.find(static_cast<int32_t>(id));
            if (prev_it != overlay_windows_.end() &&
                prev_it->second != nullptr && prev_it->second != window) {
              ANativeWindow_release(prev_it->second);
            }
#endif
            overlay_windows_[static_cast<int32_t>(id)] = window;
            return static_cast<int32_t>(id);
          }
          return std::nullopt;
        }
        if (env->functions->DeleteLocalRef != nullptr) {
          env->DeleteLocalRef(overlay_clazz);
        }
      }
    }
    if (env->functions != nullptr &&
        env->functions->DeleteLocalRef != nullptr) {
      env->DeleteLocalRef(overlay_surface);
    }
  }

  std::lock_guard<std::mutex> lock(mutex_);
  const int32_t surface_id = next_fallback_surface_id_++;
  return surface_id;
}

bool DefaultPlatformViewsProvider::DestroyOverlaySurfaces() {
  TRACE_EVENT0("flutter",
               "DefaultPlatformViewsProvider::DestroyOverlaySurfaces");
  {
    std::lock_guard<std::mutex> lock(mutex_);
#if FML_OS_ANDROID
    for (auto& kv : overlay_windows_) {
      if (kv.second != nullptr) {
        ANativeWindow_release(kv.second);
      }
    }
#endif
    overlay_windows_.clear();
  }
  JvmInvoker* invoker = GetInvoker();
  if (invoker == nullptr || !invoker->IsAttached()) {
    return false;
  }
  if (DefaultPlatformViewsProvider::IsHcppEnabled()) {
    invoker->DestroyOverlaySurface2();
  } else {
    invoker->DestroyOverlaySurfaces();
  }
  return true;
}

bool DefaultPlatformViewsProvider::OnDisplayOverlaySurface(
    const PlatformViewOverlay& overlay) {
  TRACE_EVENT1("flutter",
               "DefaultPlatformViewsProvider::OnDisplayOverlaySurface",
               "surface_id", std::to_string(overlay.surface_id).c_str());
  JvmInvoker* invoker = GetInvoker();
  if (invoker == nullptr || !invoker->IsAttached()) {
    return false;
  }
  return InvokeOnDisplayOverlaySurfaceHelper(invoker, overlay.surface_id,
                                             overlay.x, overlay.y,
                                             overlay.width, overlay.height);
}

bool DefaultPlatformViewsProvider::ShowOverlaySurface(int32_t surface_id) {
  TRACE_EVENT1("flutter", "DefaultPlatformViewsProvider::ShowOverlaySurface",
               "surface_id", std::to_string(surface_id).c_str());
  JvmInvoker* invoker = GetInvoker();
  if (invoker == nullptr || !invoker->IsAttached()) {
    return false;
  }
  invoker->ShowOverlaySurface2();
  return true;
}

bool DefaultPlatformViewsProvider::HideOverlaySurface(int32_t surface_id) {
  TRACE_EVENT1("flutter", "DefaultPlatformViewsProvider::HideOverlaySurface",
               "surface_id", std::to_string(surface_id).c_str());
  JvmInvoker* invoker = GetInvoker();
  if (invoker == nullptr || !invoker->IsAttached()) {
    return false;
  }
  invoker->HideOverlaySurface2();
  return true;
}

ANativeWindow* DefaultPlatformViewsProvider::GetOverlayWindow(
    int32_t surface_id) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = overlay_windows_.find(surface_id);
  if (it != overlay_windows_.end()) {
    return it->second;
  }
  return nullptr;
}

bool DefaultPlatformViewsProvider::CreateTransaction() {
  TRACE_EVENT0("flutter", "DefaultPlatformViewsProvider::CreateTransaction");
  JvmInvoker* invoker = GetInvoker();
  return invoker != nullptr && invoker->IsAttached();
}

bool DefaultPlatformViewsProvider::SealFrameTransactions() {
  TRACE_EVENT0("flutter",
               "DefaultPlatformViewsProvider::SealFrameTransactions");
  JvmInvoker* invoker = GetInvoker();
  if (invoker == nullptr || !invoker->IsAttached()) {
    return false;
  }
  InvokeSealFrameTransactionsHelper(invoker);
  return true;
}

bool DefaultPlatformViewsProvider::SwapTransactions() {
  TRACE_EVENT0("flutter", "DefaultPlatformViewsProvider::SwapTransactions");
  JvmInvoker* invoker = GetInvoker();
  if (invoker == nullptr || !invoker->IsAttached()) {
    return false;
  }
  InvokeSwapTransactionsHelper(invoker);
  return true;
}

bool DefaultPlatformViewsProvider::ApplyTransactions() {
  TRACE_EVENT0("flutter", "DefaultPlatformViewsProvider::ApplyTransactions");
  JvmInvoker* invoker = GetInvoker();
  return invoker != nullptr && invoker->IsAttached();
}

bool DefaultPlatformViewsProvider::SetHcppEnabled(bool enabled) {
  std::lock_guard<std::mutex> lock(mutex_);
  hcpp_enabled_ = enabled;
  return true;
}

bool DefaultPlatformViewsProvider::IsHcppEnabled() {
  std::lock_guard<std::mutex> lock(mutex_);
  return hcpp_enabled_;
}

void* DefaultPlatformViewsProvider::GetSurfaceControl(int32_t surface_id) {
  (void)surface_id;
  return nullptr;
}

// =============================================================================
// InMemoryPlatformViewsProvider
// =============================================================================

InMemoryPlatformViewsProvider::InMemoryPlatformViewsProvider() = default;
InMemoryPlatformViewsProvider::~InMemoryPlatformViewsProvider() = default;

int64_t InMemoryPlatformViewsProvider::CreatePlatformView(
    const PlatformViewCreationParams& params,
    PlatformViewCompositionType type) {
  std::lock_guard<std::mutex> lock(mutex_);
  ViewRecord rec;
  rec.params = params;
  rec.type = type;
  if (type == PlatformViewCompositionType::kTextureLayer) {
    if (rec.params.texture_id < 0) {
      rec.params.texture_id = next_texture_id_++;
    }
    views_[params.view_id] = rec;
    return rec.params.texture_id;
  }
  views_[params.view_id] = rec;
  return 0;
}

bool InMemoryPlatformViewsProvider::DisposePlatformView(int64_t view_id) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = views_.find(view_id);
  if (it == views_.end()) {
    return false;
  }
  views_.erase(it);
  geometries_.erase(view_id);
  return true;
}

bool InMemoryPlatformViewsProvider::ResizePlatformView(
    const PlatformViewResizeRequest& request,
    double* out_width,
    double* out_height) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = views_.find(request.view_id);
  if (it == views_.end()) {
    return false;
  }
  it->second.params.width = request.width;
  it->second.params.height = request.height;
  if (out_width != nullptr) {
    *out_width = request.width;
  }
  if (out_height != nullptr) {
    *out_height = request.height;
  }
  return true;
}

bool InMemoryPlatformViewsProvider::OffsetPlatformView(int64_t view_id,
                                                       double top,
                                                       double left) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = views_.find(view_id);
  if (it == views_.end()) {
    return false;
  }
  it->second.top = top;
  it->second.left = left;
  return true;
}

bool InMemoryPlatformViewsProvider::SetPlatformViewDirection(
    int64_t view_id,
    int32_t direction) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = views_.find(view_id);
  if (it == views_.end()) {
    return false;
  }
  it->second.params.direction = direction;
  return true;
}

bool InMemoryPlatformViewsProvider::ClearPlatformViewFocus(int64_t view_id) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = views_.find(view_id);
  if (it == views_.end()) {
    return false;
  }
  it->second.focused = false;
  return true;
}

bool InMemoryPlatformViewsProvider::DispatchPlatformViewTouch(
    const PlatformViewTouch& touch) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = views_.find(touch.view_id);
  if (it == views_.end()) {
    return false;
  }
  it->second.last_touch = touch;
  return true;
}

bool InMemoryPlatformViewsProvider::OnDisplayPlatformView(
    const PlatformViewGeometry& geometry) {
  std::lock_guard<std::mutex> lock(mutex_);
  geometries_[geometry.view_id] = geometry;
  auto it = views_.find(geometry.view_id);
  if (it != views_.end()) {
    it->second.visible = true;
  }
  ++display_platform_view_count_;
  return true;
}

bool InMemoryPlatformViewsProvider::HidePlatformView(int64_t view_id) {
  std::lock_guard<std::mutex> lock(mutex_);
  hidden_views_.push_back(view_id);
  auto it = views_.find(view_id);
  if (it != views_.end()) {
    it->second.visible = false;
  }
  return true;
}

bool InMemoryPlatformViewsProvider::SynchronizeToNativeViewHierarchy(bool yes) {
  std::lock_guard<std::mutex> lock(mutex_);
  synchronized_ = yes;
  return true;
}

bool InMemoryPlatformViewsProvider::OnBeginFrame() {
  std::lock_guard<std::mutex> lock(mutex_);
  in_frame_ = true;
  ++begin_frame_count_;
  return true;
}

bool InMemoryPlatformViewsProvider::OnEndFrame() {
  std::lock_guard<std::mutex> lock(mutex_);
  in_frame_ = false;
  ++end_frame_count_;
  return true;
}

std::optional<int32_t> InMemoryPlatformViewsProvider::CreateOverlaySurface() {
  std::function<void()> hook;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    hook = on_create_overlay_surface_hook_;
  }
  if (hook) {
    hook();
  }
  std::lock_guard<std::mutex> lock(mutex_);
  int32_t id = next_surface_id_++;
  PlatformViewOverlay ov;
  ov.surface_id = id;
  if (overlay_windows_.find(id) == overlay_windows_.end()) {
    overlay_windows_[id] = reinterpret_cast<ANativeWindow*>(
        static_cast<uintptr_t>(kBaseOverlayFramebufferId + id));
  }
  ov.window = overlay_windows_[id];
  overlays_[id] = ov;
  overlay_visibility_[id] = false;
  ++create_overlay_surface_count_;
  return id;
}

bool InMemoryPlatformViewsProvider::DestroyOverlaySurfaces() {
  std::lock_guard<std::mutex> lock(mutex_);
  overlays_.clear();
  overlay_visibility_.clear();
  overlay_windows_.clear();
  return true;
}

bool InMemoryPlatformViewsProvider::OnDisplayOverlaySurface(
    const PlatformViewOverlay& overlay) {
  std::lock_guard<std::mutex> lock(mutex_);
  overlays_[overlay.surface_id] = overlay;
  overlay_visibility_[overlay.surface_id] = true;
  return true;
}

bool InMemoryPlatformViewsProvider::ShowOverlaySurface(int32_t surface_id) {
  std::lock_guard<std::mutex> lock(mutex_);
  overlay_visibility_[surface_id] = true;
  return true;
}

bool InMemoryPlatformViewsProvider::HideOverlaySurface(int32_t surface_id) {
  std::lock_guard<std::mutex> lock(mutex_);
  overlay_visibility_[surface_id] = false;
  return true;
}

ANativeWindow* InMemoryPlatformViewsProvider::GetOverlayWindow(
    int32_t surface_id) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = overlay_windows_.find(surface_id);
  if (it != overlay_windows_.end()) {
    return it->second;
  }
  return nullptr;
}

bool InMemoryPlatformViewsProvider::CreateTransaction() {
  std::lock_guard<std::mutex> lock(mutex_);
  ++transaction_count_;
  return true;
}

bool InMemoryPlatformViewsProvider::SealFrameTransactions() {
  std::lock_guard<std::mutex> lock(mutex_);
  ++seal_count_;
  return true;
}

bool InMemoryPlatformViewsProvider::SwapTransactions() {
  std::lock_guard<std::mutex> lock(mutex_);
  ++swap_count_;
  return true;
}

bool InMemoryPlatformViewsProvider::ApplyTransactions() {
  std::lock_guard<std::mutex> lock(mutex_);
  ++apply_count_;
  return true;
}

bool InMemoryPlatformViewsProvider::SetHcppEnabled(bool enabled) {
  std::lock_guard<std::mutex> lock(mutex_);
  hcpp_enabled_ = enabled;
  return true;
}

bool InMemoryPlatformViewsProvider::IsHcppEnabled() {
  std::lock_guard<std::mutex> lock(mutex_);
  return hcpp_enabled_;
}

void* InMemoryPlatformViewsProvider::GetSurfaceControl(int32_t surface_id) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = surface_controls_.find(surface_id);
  if (it != surface_controls_.end()) {
    return it->second;
  }
  return nullptr;
}

void InMemoryPlatformViewsProvider::SetOverlayWindowForTesting(
    int32_t surface_id,
    ANativeWindow* window) {
  std::lock_guard<std::mutex> lock(mutex_);
  overlay_windows_[surface_id] = window;
}

void InMemoryPlatformViewsProvider::SetSurfaceControlForTesting(
    int32_t surface_id,
    void* surface_control) {
  std::lock_guard<std::mutex> lock(mutex_);
  surface_controls_[surface_id] = surface_control;
}

void InMemoryPlatformViewsProvider::SetOnCreateOverlaySurfaceHook(
    std::function<void()> hook) {
  std::lock_guard<std::mutex> lock(mutex_);
  on_create_overlay_surface_hook_ = std::move(hook);
}

bool InMemoryPlatformViewsProvider::IsViewCreated(int64_t view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  return views_.find(view_id) != views_.end();
}

std::optional<PlatformViewGeometry>
InMemoryPlatformViewsProvider::GetLastGeometry(int64_t view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = geometries_.find(view_id);
  if (it != geometries_.end()) {
    return it->second;
  }
  return std::nullopt;
}

std::optional<PlatformViewOverlay> InMemoryPlatformViewsProvider::GetOverlay(
    int32_t surface_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = overlays_.find(surface_id);
  if (it != overlays_.end()) {
    return it->second;
  }
  return std::nullopt;
}

bool InMemoryPlatformViewsProvider::IsOverlayVisible(int32_t surface_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = overlay_visibility_.find(surface_id);
  return it != overlay_visibility_.end() ? it->second : false;
}

size_t InMemoryPlatformViewsProvider::GetBeginFrameCount() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return begin_frame_count_;
}

size_t InMemoryPlatformViewsProvider::GetEndFrameCount() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return end_frame_count_;
}

size_t InMemoryPlatformViewsProvider::GetSealFrameTransactionsCount() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return seal_count_;
}

size_t InMemoryPlatformViewsProvider::GetSwapTransactionCount() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return swap_count_;
}

size_t InMemoryPlatformViewsProvider::GetDisplayPlatformViewCount() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return display_platform_view_count_;
}

size_t InMemoryPlatformViewsProvider::GetCreateOverlaySurfaceCount() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return create_overlay_surface_count_;
}

std::vector<int64_t> InMemoryPlatformViewsProvider::GetHiddenPlatformViews()
    const {
  std::lock_guard<std::mutex> lock(mutex_);
  return hidden_views_;
}

// =============================================================================
// AndroidPlatformViewsController
// =============================================================================

AndroidPlatformViewsController::AndroidPlatformViewsController()
    : AndroidPlatformViewsController(
          std::make_shared<DefaultPlatformViewsProvider>(),
          nullptr) {}

AndroidPlatformViewsController::AndroidPlatformViewsController(
    std::shared_ptr<PlatformViewsProvider> provider,
    fml::RefPtr<fml::TaskRunner> platform_task_runner)
    : provider_(provider ? std::move(provider)
                         : std::make_shared<DefaultPlatformViewsProvider>()),
      platform_task_runner_(std::move(platform_task_runner)),
      api_level_(DetectRuntimeAndroidApiLevel()) {
  TRACE_EVENT0(
      "flutter",
      "AndroidPlatformViewsController::AndroidPlatformViewsController");
  ConfigureFlutterCompositor(&compositor_, IsHcppEnabled(), api_level_);
}

AndroidPlatformViewsController::AndroidPlatformViewsController(
    JvmInvoker* jvm_invoker,
    fml::RefPtr<fml::TaskRunner> platform_task_runner)
    : AndroidPlatformViewsController(
          std::make_shared<DefaultPlatformViewsProvider>(jvm_invoker),
          std::move(platform_task_runner)) {
  jvm_invoker_ = jvm_invoker;
}

AndroidPlatformViewsController::AndroidPlatformViewsController(
    const std::shared_ptr<JvmInvoker>& jvm_invoker,
    fml::RefPtr<fml::TaskRunner> platform_task_runner)
    : AndroidPlatformViewsController(
          std::make_shared<DefaultPlatformViewsProvider>(jvm_invoker),
          std::move(platform_task_runner)) {
  jvm_invoker_ = jvm_invoker.get();
}

AndroidPlatformViewsController::~AndroidPlatformViewsController() {
  TRACE_EVENT0(
      "flutter",
      "AndroidPlatformViewsController::~AndroidPlatformViewsController");
  std::lock_guard<std::mutex> lock(mutex_);
  for (const BackingStoreContext* ctx : active_backing_stores_) {
    delete ctx;
  }
  active_backing_stores_.clear();
}

void AndroidPlatformViewsController::SetProvider(
    std::shared_ptr<PlatformViewsProvider> provider) {
  std::lock_guard<std::mutex> lock(mutex_);
  provider_ = std::move(provider);
}

std::shared_ptr<PlatformViewsProvider>
AndroidPlatformViewsController::GetProvider() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return provider_;
}

void AndroidPlatformViewsController::SetPlatformTaskRunner(
    fml::RefPtr<fml::TaskRunner> platform_task_runner) {
  std::lock_guard<std::mutex> lock(mutex_);
  platform_task_runner_ = std::move(platform_task_runner);
}

fml::RefPtr<fml::TaskRunner>
AndroidPlatformViewsController::GetPlatformTaskRunner() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return platform_task_runner_;
}

void AndroidPlatformViewsController::SetRenderDelegate(
    std::shared_ptr<AndroidCompositorRenderDelegate> render_delegate) {
  std::lock_guard<std::mutex> lock(mutex_);
  render_delegate_ = std::move(render_delegate);
  raw_render_delegate_ = render_delegate_.get();
}

void AndroidPlatformViewsController::SetRenderDelegate(
    AndroidCompositorRenderDelegate* raw_render_delegate) {
  std::lock_guard<std::mutex> lock(mutex_);
  render_delegate_.reset();
  raw_render_delegate_ = raw_render_delegate;
}

std::shared_ptr<AndroidCompositorRenderDelegate>
AndroidPlatformViewsController::GetRenderDelegate() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return render_delegate_;
}

AndroidCompositorRenderDelegate*
AndroidPlatformViewsController::GetActiveRenderDelegateLocked() const {
  return raw_render_delegate_ != nullptr ? raw_render_delegate_
                                         : render_delegate_.get();
}

void AndroidPlatformViewsController::SetMergeRasterThreadOnPlatformViews(
    bool merge) {
  bool enable_surface_control = IsHcppEnabled();
  int32_t api_level = kAndroidApiLevelPathConics;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    merge_raster_thread_on_platform_views_ = merge;
    api_level = api_level_;
  }
  ConfigureFlutterCompositor(&compositor_, enable_surface_control, api_level);
}

bool AndroidPlatformViewsController::GetMergeRasterThreadOnPlatformViews()
    const {
  std::lock_guard<std::mutex> lock(mutex_);
  return merge_raster_thread_on_platform_views_;
}

void AndroidPlatformViewsController::SetFramePresentedCallback(
    FramePresentedCallback callback) {
  std::lock_guard<std::mutex> lock(mutex_);
  frame_presented_callback_ = std::move(callback);
}

void AndroidPlatformViewsController::ConfigureForPlatform(
    bool enable_surface_control,
    int32_t api_level) {
  {
    std::lock_guard<std::mutex> lock(mutex_);
    api_level_ = api_level;
    if (provider_) {
      provider_->SetHcppEnabled(enable_surface_control);
    }
  }
  ConfigureFlutterCompositor(&compositor_, enable_surface_control, api_level);
}

void AndroidPlatformViewsController::SetDevicePixelRatio(
    double device_pixel_ratio) {
  std::lock_guard<std::mutex> lock(mutex_);
  if (std::isnan(device_pixel_ratio) || std::isinf(device_pixel_ratio) ||
      device_pixel_ratio <= 0.0) {
    device_pixel_ratio_ = kDefaultControllerDevicePixelRatio;
  } else {
    device_pixel_ratio_ = device_pixel_ratio;
  }
}

double AndroidPlatformViewsController::GetDevicePixelRatio() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return device_pixel_ratio_;
}

void AndroidPlatformViewsController::SetApiLevel(int32_t api_level) {
  std::lock_guard<std::mutex> lock(mutex_);
  api_level_ = api_level;
}

int32_t AndroidPlatformViewsController::GetApiLevel() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return api_level_;
}

// =============================================================================
// FlutterCompositor Configuration & Callbacks
// =============================================================================

void AndroidPlatformViewsController::ConfigureFlutterCompositor(
    FlutterCompositor* compositor_out,
    bool enable_surface_control,
    int32_t api_level) {
  TRACE_EVENT0("flutter",
               "AndroidPlatformViewsController::ConfigureFlutterCompositor");
  if (compositor_out == nullptr) {
    return;
  }
  *compositor_out = {};
  compositor_out->struct_size = sizeof(FlutterCompositor);
  compositor_out->user_data = this;
  compositor_out->create_backing_store_callback =
      &AndroidPlatformViewsController::CreateBackingStoreCallback;
  compositor_out->collect_backing_store_callback =
      &AndroidPlatformViewsController::CollectBackingStoreCallback;
  compositor_out->present_layers_callback = nullptr;
  compositor_out->avoid_backing_store_cache = true;
  compositor_out->present_view_callback =
      &AndroidPlatformViewsController::PresentViewCallback;
  bool merge_raster = true;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    merge_raster = merge_raster_thread_on_platform_views_;
  }
  compositor_out->merge_raster_thread_on_platform_views =
      !enable_surface_control && merge_raster;
  compositor_out->coalesce_overlay_layers = enable_surface_control;
  compositor_out->platform_view_mutation_capabilities =
      (api_level >= kAndroidApiLevelPathConics)
          ? kFlutterPlatformViewMutationCapabilityPathConics
          : kFlutterPlatformViewMutationCapabilityDefault;
}

void AndroidPlatformViewsController::PopulateCompositorConfig(
    FlutterCompositor* compositor_out) {
  const bool enable_surface_control = IsHcppEnabled();
  const int32_t api_level = GetApiLevel();
  ConfigureFlutterCompositor(compositor_out, enable_surface_control, api_level);
}

const FlutterCompositor*
AndroidPlatformViewsController::GetEmbedderCompositor() {
  PopulateCompositorConfig(&compositor_);
  return &compositor_;
}

bool AndroidPlatformViewsController::CreateBackingStoreCallback(
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out,
    void* user_data) {
  if (user_data == nullptr) {
    return false;
  }
  auto* controller = static_cast<AndroidPlatformViewsController*>(user_data);
  return controller->CreateBackingStore(config, backing_store_out);
}

bool AndroidPlatformViewsController::CollectBackingStoreCallback(
    const FlutterBackingStore* renderer,
    void* user_data) {
  if (user_data == nullptr) {
    return false;
  }
  auto* controller = static_cast<AndroidPlatformViewsController*>(user_data);
  return controller->CollectBackingStore(renderer);
}

bool AndroidPlatformViewsController::PresentViewCallback(
    const FlutterPresentViewInfo* info) {
  if (info == nullptr ||
      info->struct_size <
          offsetof(FlutterPresentViewInfo, user_data) + sizeof(void*) ||
      info->user_data == nullptr) {
    return false;
  }
  auto* controller =
      static_cast<AndroidPlatformViewsController*>(info->user_data);
  return controller->PresentView(info);
}

bool AndroidPlatformViewsController::CreateBackingStore(
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
  TRACE_EVENT0("flutter", "AndroidPlatformViewsController::CreateBackingStore");
  if (config == nullptr || backing_store_out == nullptr) {
    return false;
  }
  if (config->struct_size <
      offsetof(FlutterBackingStoreConfig, size) + sizeof(FlutterSize)) {
    return false;
  }

  const double raw_width = config->size.width;
  const double raw_height = config->size.height;
  if (std::isnan(raw_width) || std::isnan(raw_height) ||
      std::isinf(raw_width) || std::isinf(raw_height) || raw_width <= 0.0 ||
      raw_height <= 0.0) {
    return false;
  }

  const size_t width = static_cast<size_t>(std::round(raw_width));
  const size_t height = static_cast<size_t>(std::round(raw_height));
  if (width == 0 || height == 0) {
    return false;
  }

  // Inspect config->is_root_layer when config->struct_size covers it.
  const bool is_root_layer = SAFE_ACCESS(config, is_root_layer, false);
  const FlutterViewId view_id =
      SAFE_ACCESS(config, view_id, kPlatformViewsImplicitViewId);

  *backing_store_out = {};
  backing_store_out->struct_size = sizeof(FlutterBackingStore);

  auto context = std::make_unique<BackingStoreContext>();
  context->magic = kBackingStoreContextMagic;
  context->owner = this;
  context->is_root_layer = is_root_layer;
  context->view_id = view_id;
  context->width = width;
  context->height = height;

  if (is_root_layer) {
    // Root layer: bind and resize the on-screen ANativeWindow* swapchain/FBO.
    ANativeWindow* onscreen_window = nullptr;
    uint32_t onscreen_fbo = kDefaultOnscreenFramebufferId;
    AndroidCompositorRenderDelegate* delegate = nullptr;
    std::shared_ptr<AndroidCompositorRenderDelegate> delegate_keepalive;
    {
      std::lock_guard<std::mutex> lock(mutex_);
      auto& swapchain = onscreen_swapchains_[view_id];
      swapchain.width = width;
      swapchain.height = height;
      ++swapchain.bind_count;
      onscreen_window = swapchain.window;
      onscreen_fbo = swapchain.framebuffer_id;
      delegate_keepalive = render_delegate_;
      delegate = GetActiveRenderDelegateLocked();
    }

    context->native_window = onscreen_window;
    context->framebuffer_id = onscreen_fbo;

    if (delegate != nullptr) {
      if (!delegate->BindAndResizeOnscreenSurface(
              view_id, onscreen_window, width, height, backing_store_out)) {
        return false;
      }
      if (backing_store_out->type == kFlutterBackingStoreTypeOpenGL &&
          backing_store_out->open_gl.type ==
              kFlutterOpenGLTargetTypeFramebuffer) {
        context->framebuffer_id = backing_store_out->open_gl.framebuffer.name;
      }
    } else {
#if FML_OS_ANDROID
      if (onscreen_window != nullptr && jvm_invoker_ != nullptr &&
          jvm_invoker_->IsAttached() && IsRealJniEnv(jvm_invoker_->GetEnv())) {
        ANativeWindow_setBuffersGeometry(
            onscreen_window, static_cast<int32_t>(width),
            static_cast<int32_t>(height), WINDOW_FORMAT_RGBA_8888);
      }
#endif
      backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
      backing_store_out->open_gl.type = kFlutterOpenGLTargetTypeFramebuffer;
      backing_store_out->open_gl.framebuffer.target = kGlRgba8Format;
      backing_store_out->open_gl.framebuffer.name = onscreen_fbo;
      backing_store_out->open_gl.framebuffer.user_data = context.get();
      backing_store_out->open_gl.framebuffer.destruction_callback =
          [](void* /*user_data*/) {};
    }
  } else {
    // Non-root layer: allocate/resize an off-screen overlay surface
    // (SurfacePool / FlutterImageView).
    size_t overlay_index = 0;
    AndroidCompositorRenderDelegate* delegate = nullptr;
    std::shared_ptr<AndroidCompositorRenderDelegate> delegate_keepalive;
    {
      std::lock_guard<std::mutex> lock(mutex_);
      overlay_index = per_view_overlay_cursor_[view_id]++;
      ++per_view_overlay_bind_count_[view_id];
      delegate_keepalive = render_delegate_;
      delegate = GetActiveRenderDelegateLocked();
    }

    // EnsureOverlaySurfaceAllocated releases mutex_ before any platform-thread
    // latch.Wait() when invoked from an unmerged raster thread.
    const std::optional<int32_t> maybe_surface_id =
        EnsureOverlaySurfaceAllocated(overlay_index);
    if (!maybe_surface_id.has_value()) {
      return false;
    }

    const int32_t surface_id = *maybe_surface_id;
    ANativeWindow* overlay_window = GetOverlayWindow(surface_id);
    const uint32_t overlay_fbo =
        kBaseOverlayFramebufferId + static_cast<uint32_t>(surface_id);

    {
      std::lock_guard<std::mutex> lock(mutex_);
      auto& overlay_entry = active_overlay_surfaces_[surface_id];
      overlay_entry.surface_id = surface_id;
      overlay_entry.width = static_cast<int32_t>(width);
      overlay_entry.height = static_cast<int32_t>(height);
      overlay_entry.window = overlay_window;
    }

    context->overlay_index = overlay_index;
    context->overlay_surface_id = surface_id;
    context->native_window = overlay_window;
    context->framebuffer_id = overlay_fbo;

    if (delegate != nullptr) {
      if (!delegate->BindAndResizeOverlaySurface(view_id, surface_id,
                                                 overlay_window, width, height,
                                                 backing_store_out)) {
        return false;
      }
      if (backing_store_out->type == kFlutterBackingStoreTypeOpenGL &&
          backing_store_out->open_gl.type ==
              kFlutterOpenGLTargetTypeFramebuffer) {
        context->framebuffer_id = backing_store_out->open_gl.framebuffer.name;
      }
    } else {
#if FML_OS_ANDROID
      if (overlay_window != nullptr && jvm_invoker_ != nullptr &&
          jvm_invoker_->IsAttached() && IsRealJniEnv(jvm_invoker_->GetEnv())) {
        ANativeWindow_setBuffersGeometry(
            overlay_window, static_cast<int32_t>(width),
            static_cast<int32_t>(height), WINDOW_FORMAT_RGBA_8888);
      }
#endif
      backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
      backing_store_out->open_gl.type = kFlutterOpenGLTargetTypeFramebuffer;
      backing_store_out->open_gl.framebuffer.target = kGlRgba8Format;
      backing_store_out->open_gl.framebuffer.name = overlay_fbo;
      backing_store_out->open_gl.framebuffer.user_data = context.get();
      backing_store_out->open_gl.framebuffer.destruction_callback =
          [](void* /*user_data*/) {};
    }
  }

  BackingStoreContext* raw_context = context.release();
  {
    std::lock_guard<std::mutex> lock(mutex_);
    active_backing_stores_.insert(raw_context);
  }
  backing_store_out->user_data = raw_context;
  backing_store_out->did_update = true;
  return true;
}

bool AndroidPlatformViewsController::CollectBackingStore(
    const FlutterBackingStore* renderer) {
  TRACE_EVENT0("flutter",
               "AndroidPlatformViewsController::CollectBackingStore");
  if (renderer == nullptr) {
    return false;
  }
  const auto* context =
      static_cast<const BackingStoreContext*>(renderer->user_data);
  if (context == nullptr) {
    return true;
  }

  std::lock_guard<std::mutex> lock(mutex_);
  auto it = active_backing_stores_.find(context);
  if (it != active_backing_stores_.end()) {
    active_backing_stores_.erase(it);
    delete context;
  }
  return true;
}

bool AndroidPlatformViewsController::PresentView(
    const FlutterPresentViewInfo* info) {
  TRACE_EVENT0("flutter", "AndroidPlatformViewsController::PresentView");
  if (info == nullptr ||
      info->struct_size <
          offsetof(FlutterPresentViewInfo, user_data) + sizeof(void*)) {
    return false;
  }

  const FlutterViewId view_id =
      SAFE_ACCESS(info, view_id, kPlatformViewsImplicitViewId);
  const size_t layers_count = SAFE_ACCESS(info, layers_count, 0u);
  const FlutterLayer* const* layers = SAFE_ACCESS(info, layers, nullptr);
  if (layers_count > 0 && layers == nullptr) {
    return false;
  }

  double device_pixel_ratio = kDefaultControllerDevicePixelRatio;
  AndroidCompositorRenderDelegate* delegate = nullptr;
  std::shared_ptr<AndroidCompositorRenderDelegate> delegate_keepalive;
  std::unordered_set<const BackingStoreContext*> known_contexts;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    ++present_count_;
    device_pixel_ratio = device_pixel_ratio_;
    delegate_keepalive = render_delegate_;
    delegate = GetActiveRenderDelegateLocked();
    known_contexts = active_backing_stores_;
    per_view_overlay_cursor_[view_id] = 0;
  }

  // Capture per-FlutterViewId frame layers and mutator stacks strictly by value
  // on the stack so concurrent or multi-view presentations never share mutable
  // state.
  ViewFrameSnapshot snapshot;
  snapshot.view_id = view_id;
  size_t fallback_overlay_index = 0;

  for (size_t i = 0; i < layers_count; ++i) {
    const FlutterLayer* layer = layers[i];
    if (layer == nullptr || layer->struct_size < offsetof(FlutterLayer, size) +
                                                     sizeof(FlutterSize)) {
      return false;
    }

    const int32_t layer_x = static_cast<int32_t>(std::round(layer->offset.x));
    const int32_t layer_y = static_cast<int32_t>(std::round(layer->offset.y));
    const int32_t layer_w = static_cast<int32_t>(std::round(layer->size.width));
    const int32_t layer_h =
        static_cast<int32_t>(std::round(layer->size.height));

    if (layer->type == kFlutterLayerContentTypeBackingStore) {
      if (layer->backing_store == nullptr) {
        return false;
      }

      const BackingStoreContext* ctx = nullptr;
      if (layer->backing_store->user_data != nullptr) {
        const auto* candidate = static_cast<const BackingStoreContext*>(
            layer->backing_store->user_data);
        if (known_contexts.find(candidate) != known_contexts.end() &&
            candidate->magic == kBackingStoreContextMagic) {
          ctx = candidate;
        }
      }

      const bool is_root = (ctx != nullptr)
                               ? ctx->is_root_layer
                               : (i == 0 && snapshot.platform_views.empty() &&
                                  !snapshot.root_layer.present);

      if (is_root) {
        snapshot.root_layer.present = true;
        snapshot.root_layer.view_id = view_id;
        snapshot.root_layer.x = layer_x;
        snapshot.root_layer.y = layer_y;
        snapshot.root_layer.width = layer_w;
        snapshot.root_layer.height = layer_h;
        snapshot.root_layer.framebuffer_id =
            (ctx != nullptr) ? ctx->framebuffer_id
                             : kDefaultOnscreenFramebufferId;
        snapshot.root_layer.native_window =
            (ctx != nullptr) ? ctx->native_window : GetOnscreenWindow(view_id);
        snapshot.root_layer.backing_store = layer->backing_store;
      } else {
        CapturedOverlayLayer overlay;
        overlay.overlay_index =
            (ctx != nullptr) ? ctx->overlay_index : fallback_overlay_index++;
        overlay.surface_id = (ctx != nullptr) ? ctx->overlay_surface_id : -1;
        if (overlay.surface_id < 0) {
          auto allocated_id =
              EnsureOverlaySurfaceAllocated(overlay.overlay_index);
          if (allocated_id.has_value()) {
            overlay.surface_id = *allocated_id;
          }
        }
        overlay.x = layer_x;
        overlay.y = layer_y;
        overlay.width = layer_w;
        overlay.height = layer_h;
        overlay.framebuffer_id =
            (ctx != nullptr)
                ? ctx->framebuffer_id
                : (overlay.surface_id >= 0
                       ? kBaseOverlayFramebufferId +
                             static_cast<uint32_t>(overlay.surface_id)
                       : kBaseOverlayFramebufferId);
        overlay.native_window = (ctx != nullptr)
                                    ? ctx->native_window
                                    : GetOverlayWindow(overlay.surface_id);
        overlay.backing_store = layer->backing_store;
        snapshot.overlay_layers.push_back(overlay);
      }
    } else if (layer->type == kFlutterLayerContentTypePlatformView) {
      const FlutterPlatformView* pv = layer->platform_view;
      if (pv == nullptr || pv->struct_size < sizeof(FlutterPlatformView)) {
        return false;
      }

      // Capture mutator stack and records by value for this platform view.
      AndroidMutatorsStack mutators_stack =
          AndroidMutatorsMapper::MapPlatformView(*pv);
      std::vector<AndroidMutatorRecord> mutator_records =
          AndroidMutatorsMapper::ParseMutations(
              pv->mutations_count, pv->mutations, device_pixel_ratio);

      int32_t view_width = layer_w;
      int32_t view_height = layer_h;
      int32_t composed_width = layer_w;
      int32_t composed_height = layer_h;

      const auto& mutators = mutators_stack.GetMutators();
      const float dpr = static_cast<float>(device_pixel_ratio);
      if (!mutators.empty() &&
          mutators.front().type == AndroidMutatorType::kTransform &&
          dpr > 0.0f) {
        const auto& root_matrix = mutators.front().matrix.values;
        if (std::fabs(root_matrix[kMatrixScaleXIndex] - dpr) <
                kDevicePixelRatioMatchEpsilon &&
            std::fabs(root_matrix[kMatrixScaleYIndex] - dpr) <
                kDevicePixelRatioMatchEpsilon &&
            std::fabs(root_matrix[kMatrixSkewXIndex]) <
                kDevicePixelRatioMatchEpsilon &&
            std::fabs(root_matrix[kMatrixSkewYIndex]) <
                kDevicePixelRatioMatchEpsilon) {
          const float logical_w = static_cast<float>(layer->size.width) / dpr;
          const float logical_h = static_cast<float>(layer->size.height) / dpr;
          // Match EmbeddedViewParams::finalBoundingRect(): transform all four
          // corners of the logical view rect and take the axis-aligned
          // bounds, so 90/270 degree rotations swap width and height.
          const auto& final_m = mutators_stack.GetFinalMatrix().values;
          const std::array<std::pair<float, float>, kRectCornerCount> corners =
              {{{0.0f, 0.0f},
                {logical_w, 0.0f},
                {logical_w, logical_h},
                {0.0f, logical_h}}};
          float min_x = std::numeric_limits<float>::max();
          float min_y = std::numeric_limits<float>::max();
          float max_x = std::numeric_limits<float>::lowest();
          float max_y = std::numeric_limits<float>::lowest();
          for (const auto& [cx, cy] : corners) {
            const float tx = final_m[kMatrixScaleXIndex] * cx +
                             final_m[kMatrixSkewXIndex] * cy +
                             final_m[kMatrixTransXIndex];
            const float ty = final_m[kMatrixSkewYIndex] * cx +
                             final_m[kMatrixScaleYIndex] * cy +
                             final_m[kMatrixTransYIndex];
            min_x = std::min(min_x, tx);
            max_x = std::max(max_x, tx);
            min_y = std::min(min_y, ty);
            max_y = std::max(max_y, ty);
          }
          composed_width = static_cast<int32_t>(std::round(max_x)) -
                           static_cast<int32_t>(std::round(min_x));
          composed_height = static_cast<int32_t>(std::round(max_y)) -
                            static_cast<int32_t>(std::round(min_y));
        }
      }

      if (composed_width <= 0) {
        composed_width = view_width;
      }
      if (composed_height <= 0) {
        composed_height = view_height;
      }

      SurfaceControlTransactionTransform sc_transform =
          mutators_stack.GetSurfaceControlTransactionTransform(
              static_cast<float>(layer_x), static_cast<float>(layer_y),
              static_cast<float>(composed_width),
              static_cast<float>(composed_height));

      CapturedPlatformViewLayer captured_pv;
      captured_pv.platform_view_id = pv->identifier;
      captured_pv.x = layer_x;
      captured_pv.y = layer_y;
      captured_pv.width = composed_width;
      captured_pv.height = composed_height;
      captured_pv.view_width = view_width;
      captured_pv.view_height = view_height;
      captured_pv.mutators_stack = std::move(mutators_stack);
      captured_pv.mutator_records = std::move(mutator_records);
      captured_pv.surface_control_transform = sc_transform;
      snapshot.platform_views.push_back(std::move(captured_pv));
    }
  }

  const bool is_surface_control = IsHcppEnabled();
  std::vector<int64_t> views_to_hide;
  bool should_show_overlay = false;
  bool should_hide_overlay = false;
  bool had_previous_views = false;
  fml::RefPtr<fml::TaskRunner> task_runner;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    task_runner = platform_task_runner_;
    auto& previous_views = per_view_visible_platform_views_[view_id];
    had_previous_views = !previous_views.empty();

    std::unordered_set<int64_t> current_views;
    for (const auto& pv : snapshot.platform_views) {
      current_views.insert(pv.platform_view_id);
    }
    for (int64_t prev_id : previous_views) {
      if (current_views.find(prev_id) == current_views.end()) {
        views_to_hide.push_back(prev_id);
      }
    }
    previous_views = std::move(current_views);

    bool& overlay_shown = per_view_overlay_shown_[view_id];
    if (!snapshot.overlay_layers.empty()) {
      should_show_overlay = true;
      overlay_shown = true;
    } else if (overlay_shown) {
      should_hide_overlay = true;
      overlay_shown = false;
    }

    per_view_snapshots_[view_id] = snapshot;
  }

  // Frames with no platform views, overlays, or visibility changes have no
  // Java-side work. Return before posting to the platform thread so an
  // unmerged raster thread never blocks on latch.Wait() for a no-op.
  const bool has_frame_work = !snapshot.platform_views.empty() ||
                              !snapshot.overlay_layers.empty() ||
                              !views_to_hide.empty() || should_show_overlay ||
                              should_hide_overlay || had_previous_views;
  if (!has_frame_work) {
    TRACE_EVENT0("flutter",
                 "AndroidPlatformViewsController::PresentView::NoFrameWork");
    if (snapshot.root_layer.present && delegate) {
      delegate->PresentOnscreenSurface(view_id,
                                       snapshot.root_layer.backing_store);
    }
    return true;
  }

  FramePresentedCallback frame_presented_callback;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    frame_presented_callback = frame_presented_callback_;
  }

  // Every path that posts a platform task calling SwapTransactions() must call
  // SealFrameTransactions() once on the raster thread to keep the per-frame
  // transaction queue paired 1:1.
  if (is_surface_control) {
    SealFrameTransactions();
  }

  const bool cross_thread_presentation =
      task_runner && !task_runner->RunsTasksOnCurrentThread();

  auto execute_presentation =
      [this, view_id, snapshot, delegate,
       views_to_hide = std::move(views_to_hide), is_surface_control,
       should_show_overlay, should_hide_overlay, cross_thread_presentation,
       frame_presented_callback = std::move(frame_presented_callback)]() {
        TRACE_EVENT0("flutter",
                     "AndroidPlatformViewsController::PresentView::Execute");
        ANativeWindow* window_before_display = GetOnscreenWindow(view_id);
        if (!is_surface_control) {
          OnBeginFrame();
        }

        // Dispatch OnDisplayPlatformView to Java without requiring prior C-API
        // platform view registration.
        for (const auto& pv : snapshot.platform_views) {
          PlatformViewGeometry geometry;
          geometry.view_id = pv.platform_view_id;
          geometry.x = pv.x;
          geometry.y = pv.y;
          geometry.width = pv.width;
          geometry.height = pv.height;
          geometry.view_width = pv.view_width;
          geometry.view_height = pv.view_height;
          geometry.mutators_stack = pv.mutators_stack;
          OnDisplayPlatformView(geometry);
        }

        for (int64_t old_view_id : views_to_hide) {
          HidePlatformView(old_view_id);
        }

        const bool window_switched =
            (!is_surface_control && GetOnscreenWindow(view_id) != nullptr &&
             GetOnscreenWindow(view_id) != window_before_display);

        if (delegate) {
          if (snapshot.root_layer.present) {
            if (window_switched) {
              delegate->ClearAndPresentOnscreenSurface(view_id);
            } else {
              delegate->PresentOnscreenSurface(
                  view_id, snapshot.root_layer.backing_store);
            }
          } else if (!is_surface_control && !snapshot.platform_views.empty()) {
            // Hybrid Composition requires FlutterImageView's ImageReader to
            // acquire a frame on every frame with a platform view, even when
            // all Flutter content is in an overlay above the platform view.
            delegate->ClearAndPresentOnscreenSurface(view_id);
          }
        }

        if (is_surface_control) {
          if (delegate) {
            for (const auto& ov : snapshot.overlay_layers) {
              if (ov.surface_id >= 0) {
                delegate->PresentOverlaySurface(view_id, ov.surface_id,
                                                ov.backing_store);
              }
            }
          }
          if (should_show_overlay) {
            ShowOverlaySurface(0);
          } else if (should_hide_overlay) {
            HideOverlaySurface(0);
          }
          SwapTransactions();
          OnEndFrame();
        } else {
          for (const auto& ov : snapshot.overlay_layers) {
            int32_t resolved_id = ov.surface_id;
            if (resolved_id < 0) {
              auto maybe_id = EnsureOverlaySurfaceAllocated(ov.overlay_index);
              if (!maybe_id.has_value()) {
                continue;
              }
              resolved_id = *maybe_id;
            }
            if (delegate && resolved_id >= 0) {
              delegate->PresentOverlaySurface(view_id, resolved_id,
                                              ov.backing_store);
            }
            PlatformViewOverlay overlay;
            overlay.surface_id = resolved_id;
            overlay.x = ov.x;
            overlay.y = ov.y;
            overlay.width = ov.width;
            overlay.height = ov.height;
            overlay.window = ov.native_window;
            OnDisplayOverlaySurface(overlay);
          }
          OnEndFrame();
        }

        // Platform-view-only frames never reach the render delegate's
        // Present*Surface hooks, so report presentation here once Java has
        // received the frame. The owner dedups first-frame notification.
        if (frame_presented_callback && !snapshot.platform_views.empty()) {
          TRACE_EVENT0(
              "flutter",
              "AndroidPlatformViewsController::PresentView::FramePresented");
          frame_presented_callback(view_id);
        }

        if (cross_thread_presentation && delegate) {
          delegate->PrepareForCrossThreadPresentation();
        }
      };

  if (!cross_thread_presentation) {
    execute_presentation();
  } else {
    if (delegate) {
      delegate->PrepareForCrossThreadPresentation();
    }
    fml::AutoResetWaitableEvent latch;
    task_runner->PostTask(
        [execute_presentation = std::move(execute_presentation),
         &latch]() mutable {
          execute_presentation();
          latch.Signal();
        });
    latch.Wait();
  }

  return true;
}

// =============================================================================
// Onscreen Swapchain & Frame State Accessors
// =============================================================================

void AndroidPlatformViewsController::SetOnscreenWindow(FlutterViewId view_id,
                                                       ANativeWindow* window,
                                                       size_t width,
                                                       size_t height) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto& swapchain = onscreen_swapchains_[view_id];
  swapchain.window = window;
  if (width > 0) {
    swapchain.width = width;
  }
  if (height > 0) {
    swapchain.height = height;
  }
}

ANativeWindow* AndroidPlatformViewsController::GetOnscreenWindow(
    FlutterViewId view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = onscreen_swapchains_.find(view_id);
  return it != onscreen_swapchains_.end() ? it->second.window : nullptr;
}

FlutterSize AndroidPlatformViewsController::GetBoundOnscreenSize(
    FlutterViewId view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = onscreen_swapchains_.find(view_id);
  if (it == onscreen_swapchains_.end()) {
    return FlutterSize{0.0, 0.0};
  }
  return FlutterSize{static_cast<double>(it->second.width),
                     static_cast<double>(it->second.height)};
}

uint32_t AndroidPlatformViewsController::GetBoundOnscreenFbo(
    FlutterViewId view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = onscreen_swapchains_.find(view_id);
  return it != onscreen_swapchains_.end() ? it->second.framebuffer_id
                                          : kDefaultOnscreenFramebufferId;
}

size_t AndroidPlatformViewsController::GetOnscreenBindCount(
    FlutterViewId view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = onscreen_swapchains_.find(view_id);
  return it != onscreen_swapchains_.end() ? it->second.bind_count : 0;
}

size_t AndroidPlatformViewsController::GetOverlayBindCount(
    FlutterViewId view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = per_view_overlay_bind_count_.find(view_id);
  return it != per_view_overlay_bind_count_.end() ? it->second : 0;
}

size_t AndroidPlatformViewsController::GetAllocatedStoreCount() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return active_backing_stores_.size();
}

size_t AndroidPlatformViewsController::GetPresentCount() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return present_count_;
}

std::optional<AndroidPlatformViewsController::ViewFrameSnapshot>
AndroidPlatformViewsController::GetLastCommittedFrameSnapshot(
    FlutterViewId view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = per_view_snapshots_.find(view_id);
  if (it != per_view_snapshots_.end()) {
    return it->second;
  }
  return std::nullopt;
}

// =============================================================================
// Overlay Surface Pool & Thread-Safe Allocation
// =============================================================================

std::optional<int32_t>
AndroidPlatformViewsController::CreateOverlaySurfaceInternal(
    const std::shared_ptr<PlatformViewsProvider>& provider,
    const fml::RefPtr<fml::TaskRunner>& task_runner) {
  if (!provider) {
    return std::nullopt;
  }

  // Check RunsTasksOnCurrentThread() so merged platform/raster threads invoke
  // CreateOverlaySurface directly and never deadlock on a latch.
  if (!task_runner || task_runner->RunsTasksOnCurrentThread()) {
    return provider->CreateOverlaySurface();
  }

  // Unmerged thread: caller has already released mutex_ before calling this
  // helper, so waiting on latch will never block the platform thread if it
  // re-enters AndroidPlatformViewsController.
  std::optional<int32_t> allocated_id;
  fml::AutoResetWaitableEvent latch;
  task_runner->PostTask([provider, &allocated_id, &latch]() {
    allocated_id = provider->CreateOverlaySurface();
    latch.Signal();
  });
  latch.Wait();
  return allocated_id;
}

std::optional<int32_t>
AndroidPlatformViewsController::EnsureOverlaySurfaceAllocated(
    size_t overlay_index) {
  TRACE_EVENT1("flutter",
               "AndroidPlatformViewsController::EnsureOverlaySurfaceAllocated",
               "overlay_index", std::to_string(overlay_index).c_str());
  while (true) {
    std::shared_ptr<PlatformViewsProvider> provider;
    fml::RefPtr<fml::TaskRunner> task_runner;
    {
      std::unique_lock<std::mutex> lock(mutex_);
      if (overlay_index < allocated_overlay_surface_ids_.size()) {
        return allocated_overlay_surface_ids_[overlay_index];
      }
      provider = provider_;
      task_runner = platform_task_runner_;
    }

    // mutex_ is NOT held while allocating on the platform thread or waiting on
    // latch.Wait().
    const std::optional<int32_t> maybe_id =
        CreateOverlaySurfaceInternal(provider, task_runner);
    if (!maybe_id.has_value()) {
      return std::nullopt;
    }

    ANativeWindow* window =
        provider ? provider->GetOverlayWindow(*maybe_id) : nullptr;
    {
      std::unique_lock<std::mutex> lock(mutex_);
      if (std::find(allocated_overlay_surface_ids_.begin(),
                    allocated_overlay_surface_ids_.end(),
                    *maybe_id) == allocated_overlay_surface_ids_.end()) {
        allocated_overlay_surface_ids_.push_back(*maybe_id);
      }
      auto& entry = active_overlay_surfaces_[*maybe_id];
      entry.surface_id = *maybe_id;
      if (window != nullptr) {
        entry.window = window;
      }
      if (overlay_index < allocated_overlay_surface_ids_.size()) {
        return allocated_overlay_surface_ids_[overlay_index];
      }
    }
  }
}

std::optional<int32_t>
AndroidPlatformViewsController::RouteCreateOverlaySurface() {
  TRACE_EVENT0("flutter",
               "AndroidPlatformViewsController::RouteCreateOverlaySurface");
  std::shared_ptr<PlatformViewsProvider> provider;
  fml::RefPtr<fml::TaskRunner> task_runner;
  {
    std::unique_lock<std::mutex> lock(mutex_);
    provider = provider_;
    task_runner = platform_task_runner_;
    // Release lock before calling CreateOverlaySurfaceInternal / latch.Wait().
  }

  const std::optional<int32_t> surface_id =
      CreateOverlaySurfaceInternal(provider, task_runner);
  if (!surface_id.has_value()) {
    return std::nullopt;
  }

  ANativeWindow* window =
      provider ? provider->GetOverlayWindow(*surface_id) : nullptr;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    if (std::find(allocated_overlay_surface_ids_.begin(),
                  allocated_overlay_surface_ids_.end(),
                  *surface_id) == allocated_overlay_surface_ids_.end()) {
      allocated_overlay_surface_ids_.push_back(*surface_id);
    }
    PlatformViewOverlay overlay;
    overlay.surface_id = *surface_id;
    overlay.window = window;
    active_overlay_surfaces_[*surface_id] = overlay;
  }
  return surface_id;
}

std::optional<int32_t> AndroidPlatformViewsController::CreateOverlaySurface() {
  return RouteCreateOverlaySurface();
}

bool AndroidPlatformViewsController::DestroyOverlaySurfaces() {
  TRACE_EVENT0("flutter",
               "AndroidPlatformViewsController::DestroyOverlaySurfaces");
  std::shared_ptr<PlatformViewsProvider> provider;
  fml::RefPtr<fml::TaskRunner> task_runner;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    provider = provider_;
    task_runner = platform_task_runner_;
    allocated_overlay_surface_ids_.clear();
    active_overlay_surfaces_.clear();
    per_view_overlay_cursor_.clear();
    per_view_overlay_shown_.clear();
  }
  if (!provider) {
    return false;
  }
  if (!task_runner || task_runner->RunsTasksOnCurrentThread()) {
    return provider->DestroyOverlaySurfaces();
  }
  bool destroyed = false;
  fml::AutoResetWaitableEvent latch;
  task_runner->PostTask([provider, &destroyed, &latch]() {
    destroyed = provider->DestroyOverlaySurfaces();
    latch.Signal();
  });
  latch.Wait();
  return destroyed;
}

bool AndroidPlatformViewsController::OnDisplayOverlaySurface(
    const PlatformViewOverlay& overlay) {
  TRACE_EVENT1("flutter",
               "AndroidPlatformViewsController::OnDisplayOverlaySurface",
               "surface_id", std::to_string(overlay.surface_id).c_str());
  std::shared_ptr<PlatformViewsProvider> provider;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!provider_) {
      return false;
    }
    provider = provider_;
  }
  if (!provider->OnDisplayOverlaySurface(overlay)) {
    return false;
  }
  {
    std::lock_guard<std::mutex> lock(mutex_);
    PlatformViewOverlay updated = overlay;
    auto it = active_overlay_surfaces_.find(overlay.surface_id);
    if (it != active_overlay_surfaces_.end() && updated.window == nullptr) {
      updated.window = it->second.window;
    }
    active_overlay_surfaces_[overlay.surface_id] = updated;
  }
  return true;
}

bool AndroidPlatformViewsController::OnDisplayOverlaySurface(int32_t surface_id,
                                                             int32_t x,
                                                             int32_t y,
                                                             int32_t width,
                                                             int32_t height) {
  PlatformViewOverlay overlay;
  overlay.surface_id = surface_id;
  overlay.x = x;
  overlay.y = y;
  overlay.width = width;
  overlay.height = height;
  return OnDisplayOverlaySurface(overlay);
}

bool AndroidPlatformViewsController::ShowOverlaySurface(int32_t surface_id) {
  TRACE_EVENT1("flutter", "AndroidPlatformViewsController::ShowOverlaySurface",
               "surface_id", std::to_string(surface_id).c_str());
  std::shared_ptr<PlatformViewsProvider> provider;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    provider = provider_;
  }
  return provider ? provider->ShowOverlaySurface(surface_id) : false;
}

bool AndroidPlatformViewsController::HideOverlaySurface(int32_t surface_id) {
  TRACE_EVENT1("flutter", "AndroidPlatformViewsController::HideOverlaySurface",
               "surface_id", std::to_string(surface_id).c_str());
  std::shared_ptr<PlatformViewsProvider> provider;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    provider = provider_;
  }
  return provider ? provider->HideOverlaySurface(surface_id) : false;
}

ANativeWindow* AndroidPlatformViewsController::GetOverlayWindow(
    int32_t surface_id) const {
  std::shared_ptr<PlatformViewsProvider> provider;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = active_overlay_surfaces_.find(surface_id);
    if (it != active_overlay_surfaces_.end() && it->second.window != nullptr) {
      return it->second.window;
    }
    provider = provider_;
  }
  return provider ? provider->GetOverlayWindow(surface_id) : nullptr;
}

void AndroidPlatformViewsController::SetOverlayWindow(int32_t surface_id,
                                                      ANativeWindow* window) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto& entry = active_overlay_surfaces_[surface_id];
  entry.surface_id = surface_id;
  entry.window = window;
}

std::optional<PlatformViewOverlay>
AndroidPlatformViewsController::GetOverlaySurface(int32_t surface_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = active_overlay_surfaces_.find(surface_id);
  if (it != active_overlay_surfaces_.end()) {
    return it->second;
  }
  return std::nullopt;
}

size_t AndroidPlatformViewsController::GetActiveOverlaySurfacesCount() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return active_overlay_surfaces_.size();
}

// =============================================================================
// Platform View Lifecycle & Display (No Prior C-API Registration Required)
// =============================================================================

int64_t AndroidPlatformViewsController::CreatePlatformView(
    const PlatformViewCreationParams& params,
    PlatformViewCompositionType type) {
  TRACE_EVENT1("flutter", "AndroidPlatformViewsController::CreatePlatformView",
               "view_id", std::to_string(params.view_id).c_str());
  std::shared_ptr<PlatformViewsProvider> provider;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    provider = provider_;
  }
  if (!provider) {
    return -1;
  }
  const int64_t result = provider->CreatePlatformView(params, type);
  if (result >= 0) {
    std::lock_guard<std::mutex> lock(mutex_);
    active_composition_types_[params.view_id] = type;
  }
  return result;
}

bool AndroidPlatformViewsController::DisposePlatformView(int64_t view_id) {
  TRACE_EVENT1("flutter", "AndroidPlatformViewsController::DisposePlatformView",
               "view_id", std::to_string(view_id).c_str());
  std::shared_ptr<PlatformViewsProvider> provider;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    provider = provider_;
    active_composition_types_.erase(view_id);
    active_view_geometries_.erase(view_id);
    for (auto& kv : per_view_visible_platform_views_) {
      kv.second.erase(view_id);
    }
  }
  return provider ? provider->DisposePlatformView(view_id) : false;
}

bool AndroidPlatformViewsController::ResizePlatformView(int64_t view_id,
                                                        double width,
                                                        double height,
                                                        double* out_width,
                                                        double* out_height) {
  TRACE_EVENT1("flutter", "AndroidPlatformViewsController::ResizePlatformView",
               "view_id", std::to_string(view_id).c_str());
  std::shared_ptr<PlatformViewsProvider> provider;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    provider = provider_;
  }
  if (!provider) {
    return false;
  }
  PlatformViewResizeRequest req;
  req.view_id = view_id;
  req.width = width;
  req.height = height;
  return provider->ResizePlatformView(req, out_width, out_height);
}

bool AndroidPlatformViewsController::OffsetPlatformView(int64_t view_id,
                                                        double top,
                                                        double left) {
  TRACE_EVENT1("flutter", "AndroidPlatformViewsController::OffsetPlatformView",
               "view_id", std::to_string(view_id).c_str());
  std::shared_ptr<PlatformViewsProvider> provider;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    provider = provider_;
  }
  return provider ? provider->OffsetPlatformView(view_id, top, left) : false;
}

bool AndroidPlatformViewsController::SetDirection(int64_t view_id,
                                                  int32_t direction) {
  TRACE_EVENT1("flutter", "AndroidPlatformViewsController::SetDirection",
               "view_id", std::to_string(view_id).c_str());
  std::shared_ptr<PlatformViewsProvider> provider;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    provider = provider_;
  }
  return provider ? provider->SetPlatformViewDirection(view_id, direction)
                  : false;
}

bool AndroidPlatformViewsController::ClearFocus(int64_t view_id) {
  TRACE_EVENT1("flutter", "AndroidPlatformViewsController::ClearFocus",
               "view_id", std::to_string(view_id).c_str());
  std::shared_ptr<PlatformViewsProvider> provider;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    provider = provider_;
  }
  return provider ? provider->ClearPlatformViewFocus(view_id) : false;
}

bool AndroidPlatformViewsController::DispatchTouchEvent(
    const PlatformViewTouch& touch) {
  TRACE_EVENT1("flutter", "AndroidPlatformViewsController::DispatchTouchEvent",
               "view_id", std::to_string(touch.view_id).c_str());
  std::shared_ptr<PlatformViewsProvider> provider;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    provider = provider_;
  }
  return provider ? provider->DispatchPlatformViewTouch(touch) : false;
}

bool AndroidPlatformViewsController::OnDisplayPlatformView(
    const PlatformViewGeometry& geometry) {
  TRACE_EVENT1("flutter",
               "AndroidPlatformViewsController::OnDisplayPlatformView",
               "view_id", std::to_string(geometry.view_id).c_str());
  std::shared_ptr<PlatformViewsProvider> provider;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!provider_) {
      return false;
    }
    provider = provider_;
    active_view_geometries_[geometry.view_id] = geometry;
  }
  // Dispatch directly to Java/provider without requiring prior C-API
  // CreatePlatformView registration.
  return provider->OnDisplayPlatformView(geometry);
}

bool AndroidPlatformViewsController::OnDisplayPlatformView(
    int64_t view_id,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    int32_t view_width,
    int32_t view_height,
    const AndroidMutatorsStack& mutators_stack) {
  PlatformViewGeometry geometry;
  geometry.view_id = view_id;
  geometry.x = x;
  geometry.y = y;
  geometry.width = width;
  geometry.height = height;
  geometry.view_width = view_width;
  geometry.view_height = view_height;
  geometry.mutators_stack = mutators_stack;
  return OnDisplayPlatformView(geometry);
}

bool AndroidPlatformViewsController::OnDisplayPlatformView(
    const FlutterPlatformView& platform_view,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    int32_t view_width,
    int32_t view_height) {
  TRACE_EVENT1("flutter",
               "AndroidPlatformViewsController::OnDisplayPlatformView(struct)",
               "view_id", std::to_string(platform_view.identifier).c_str());
  if (platform_view.struct_size < sizeof(FlutterPlatformView)) {
    return false;
  }
  AndroidMutatorsStack stack =
      AndroidMutatorsMapper::MapPlatformView(platform_view);
  return OnDisplayPlatformView(platform_view.identifier, x, y, width, height,
                               view_width, view_height, stack);
}

bool AndroidPlatformViewsController::PushPlatformViewMutators(
    int64_t view_id,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    const AndroidMutatorsStack& mutators_stack) {
  return PushPlatformViewMutators(view_id, x, y, width, height, width, height,
                                  mutators_stack);
}

bool AndroidPlatformViewsController::PushPlatformViewMutators(
    int64_t view_id,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    int32_t view_width,
    int32_t view_height,
    const AndroidMutatorsStack& mutators_stack) {
  return OnDisplayPlatformView(view_id, x, y, width, height, view_width,
                               view_height, mutators_stack);
}

bool AndroidPlatformViewsController::PushPlatformViewMutators(
    const FlutterPlatformView& platform_view,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height) {
  return PushPlatformViewMutators(platform_view, x, y, width, height, width,
                                  height);
}

bool AndroidPlatformViewsController::PushPlatformViewMutators(
    const FlutterPlatformView& platform_view,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    int32_t view_width,
    int32_t view_height) {
  return OnDisplayPlatformView(platform_view, x, y, width, height, view_width,
                               view_height);
}

bool AndroidPlatformViewsController::HidePlatformView(int64_t view_id) {
  TRACE_EVENT1("flutter", "AndroidPlatformViewsController::HidePlatformView",
               "view_id", std::to_string(view_id).c_str());
  std::shared_ptr<PlatformViewsProvider> provider;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    provider = provider_;
  }
  return provider ? provider->HidePlatformView(view_id) : false;
}

bool AndroidPlatformViewsController::SynchronizeToNativeViewHierarchy(
    bool yes) {
  TRACE_EVENT0(
      "flutter",
      "AndroidPlatformViewsController::SynchronizeToNativeViewHierarchy");
  std::shared_ptr<PlatformViewsProvider> provider;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    provider = provider_;
  }
  return provider ? provider->SynchronizeToNativeViewHierarchy(yes) : false;
}

bool AndroidPlatformViewsController::OnBeginFrame() {
  TRACE_EVENT0("flutter", "AndroidPlatformViewsController::OnBeginFrame");
  std::shared_ptr<PlatformViewsProvider> provider;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    provider = provider_;
  }
  return provider ? provider->OnBeginFrame() : false;
}

bool AndroidPlatformViewsController::OnEndFrame() {
  TRACE_EVENT0("flutter", "AndroidPlatformViewsController::OnEndFrame");
  std::shared_ptr<PlatformViewsProvider> provider;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    provider = provider_;
  }
  return provider ? provider->OnEndFrame() : false;
}

bool AndroidPlatformViewsController::CreateTransaction() {
  TRACE_EVENT0("flutter", "AndroidPlatformViewsController::CreateTransaction");
  std::shared_ptr<PlatformViewsProvider> provider;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    provider = provider_;
  }
  return provider ? provider->CreateTransaction() : false;
}

bool AndroidPlatformViewsController::SealFrameTransactions() {
  TRACE_EVENT0("flutter",
               "AndroidPlatformViewsController::SealFrameTransactions");
  std::shared_ptr<PlatformViewsProvider> provider;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    provider = provider_;
  }
  return provider ? provider->SealFrameTransactions() : false;
}

bool AndroidPlatformViewsController::SwapTransactions() {
  TRACE_EVENT0("flutter", "AndroidPlatformViewsController::SwapTransactions");
  std::shared_ptr<PlatformViewsProvider> provider;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    provider = provider_;
  }
  return provider ? provider->SwapTransactions() : false;
}

bool AndroidPlatformViewsController::ApplyTransactions() {
  TRACE_EVENT0("flutter", "AndroidPlatformViewsController::ApplyTransactions");
  std::shared_ptr<PlatformViewsProvider> provider;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    provider = provider_;
  }
  return provider ? provider->ApplyTransactions() : false;
}

bool AndroidPlatformViewsController::SetHcppEnabled(bool enabled) {
  TRACE_EVENT1("flutter", "AndroidPlatformViewsController::SetHcppEnabled",
               "enabled", enabled ? "true" : "false");
  std::shared_ptr<PlatformViewsProvider> provider;
  int32_t api_level = kAndroidApiLevelPathConics;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    provider = provider_;
    api_level = api_level_;
  }
  if (!provider || !provider->SetHcppEnabled(enabled)) {
    return false;
  }
  ConfigureFlutterCompositor(&compositor_, enabled, api_level);
  return true;
}

bool AndroidPlatformViewsController::IsHcppEnabled() const {
  std::shared_ptr<PlatformViewsProvider> provider;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    provider = provider_;
  }
  return provider ? provider->IsHcppEnabled() : false;
}

void* AndroidPlatformViewsController::GetSurfaceControl(
    int32_t surface_id) const {
  std::shared_ptr<PlatformViewsProvider> provider;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    provider = provider_;
  }
  return provider ? provider->GetSurfaceControl(surface_id) : nullptr;
}

size_t AndroidPlatformViewsController::GetActiveViewsCount() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return active_composition_types_.size();
}

bool AndroidPlatformViewsController::HasPlatformView(int64_t view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  return active_composition_types_.find(view_id) !=
             active_composition_types_.end() ||
         active_view_geometries_.find(view_id) != active_view_geometries_.end();
}

std::optional<PlatformViewCompositionType>
AndroidPlatformViewsController::GetCompositionType(int64_t view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = active_composition_types_.find(view_id);
  if (it != active_composition_types_.end()) {
    return it->second;
  }
  return std::nullopt;
}

std::optional<PlatformViewGeometry>
AndroidPlatformViewsController::GetPlatformViewGeometry(int64_t view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = active_view_geometries_.find(view_id);
  if (it != active_view_geometries_.end()) {
    return it->second;
  }
  return std::nullopt;
}

}  // namespace flutter
