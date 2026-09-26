// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/jvm_invoker.h"

#include <cstring>

#if FML_OS_ANDROID
#include <android/native_window.h>
#include <android/native_window_jni.h>
#endif

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/platform/android/android_mutators_mapper.h"

namespace flutter {
namespace android {

DefaultJvmInvoker::DefaultJvmInvoker(
    fml::RefPtr<fml::TaskRunner> platform_task_runner)
    : attached_(true), platform_task_runner_(std::move(platform_task_runner)) {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::DefaultJvmInvoker");
}

DefaultJvmInvoker::~DefaultJvmInvoker() {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::~DefaultJvmInvoker");
}

bool DefaultJvmInvoker::EnsureAttachedToThread() {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::EnsureAttachedToThread");
  attached_.store(true);
  return true;
}

void DefaultJvmInvoker::DetachFromThread() {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::DetachFromThread");
  attached_.store(false);
}

bool DefaultJvmInvoker::HasPendingException() const {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::HasPendingException");
  return pending_exception_.load();
}

void DefaultJvmInvoker::ClearPendingException() {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::ClearPendingException");
  pending_exception_.store(false);
}

bool DefaultJvmInvoker::HandlePlatformMessage(const std::string& channel,
                                              const uint8_t* message,
                                              size_t message_size,
                                              int32_t response_id,
                                              int64_t message_data) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::HandlePlatformMessage", "channel",
               channel.c_str());
  if (pending_exception_.load()) {
    return false;
  }
  return true;
}

bool DefaultJvmInvoker::HandlePlatformMessageResponse(int32_t response_id,
                                                      const uint8_t* data,
                                                      size_t data_size) {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::HandlePlatformMessageResponse");
  if (pending_exception_.load()) {
    return false;
  }
  return true;
}

bool DefaultJvmInvoker::UpdateSemantics(
    const std::vector<uint8_t>& buffer,
    const std::vector<std::string>& strings,
    const std::vector<std::vector<uint8_t>>& string_attribute_args) {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::UpdateSemantics");
  if (pending_exception_.load()) {
    return false;
  }
  return true;
}

bool DefaultJvmInvoker::UpdateCustomAccessibilityActions(
    const std::vector<uint8_t>& actions_buffer,
    const std::vector<std::string>& action_strings) {
  TRACE_EVENT0("flutter",
               "DefaultJvmInvoker::UpdateCustomAccessibilityActions");
  if (pending_exception_.load()) {
    return false;
  }
  return true;
}

bool DefaultJvmInvoker::SetSemanticsTreeEnabled(bool enabled) {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::SetSemanticsTreeEnabled");
  if (pending_exception_.load()) {
    return false;
  }
  return true;
}

bool DefaultJvmInvoker::SetApplicationLocale(const std::string& locale) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::SetApplicationLocale", "locale",
               locale.c_str());
  if (pending_exception_.load()) {
    return false;
  }
  return true;
}

bool DefaultJvmInvoker::OnFirstFrame() {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::OnFirstFrame");
  if (pending_exception_.load()) {
    return false;
  }
  return true;
}

bool DefaultJvmInvoker::OnPreEngineRestart() {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::OnPreEngineRestart");
  if (pending_exception_.load()) {
    return false;
  }
  return true;
}

bool DefaultJvmInvoker::RequestDartDeferredLibrary(int loading_unit_id) {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::RequestDartDeferredLibrary");
  if (pending_exception_.load()) {
    return false;
  }
  return true;
}

bool DefaultJvmInvoker::DecodeImage(const uint8_t* data,
                                    size_t size,
                                    int64_t generator_handle) {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::DecodeImage");
  if (pending_exception_.load() || !data || size == 0) {
    return false;
  }
  return true;
}

bool DefaultJvmInvoker::PushPlatformViewMutators(
    int64_t view_id,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    const std::vector<uint8_t>& payload) {
  return PushPlatformViewMutators(view_id, x, y, width, height, width, height,
                                  payload);
}

bool DefaultJvmInvoker::PushPlatformViewMutators(
    int64_t view_id,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    int32_t view_width,
    int32_t view_height,
    const std::vector<uint8_t>& payload) {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::PushPlatformViewMutators");
  if (pending_exception_.load()) {
    return false;
  }
  return true;
}

bool DefaultJvmInvoker::InvokeVoidMethod(const std::string& method_name,
                                         const std::string& signature,
                                         const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::InvokeVoidMethod", "method",
               method_name.c_str());
  if (pending_exception_.load()) {
    FML_LOG(WARNING) << "Ignoring InvokeVoidMethod on " << method_name
                     << " due to pending JVM exception.";
    return false;
  }
  return true;
}

bool DefaultJvmInvoker::InvokeBooleanMethod(
    const std::string& method_name,
    const std::string& signature,
    const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::InvokeBooleanMethod", "method",
               method_name.c_str());
  if (pending_exception_.load()) {
    return false;
  }
  return true;
}

int64_t DefaultJvmInvoker::InvokeIntMethod(
    const std::string& method_name,
    const std::string& signature,
    const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::InvokeIntMethod", "method",
               method_name.c_str());
  if (pending_exception_.load()) {
    return -1;
  }
  return 0;
}

double DefaultJvmInvoker::InvokeDoubleMethod(
    const std::string& method_name,
    const std::string& signature,
    const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::InvokeDoubleMethod", "method",
               method_name.c_str());
  if (pending_exception_.load()) {
    return 0.0;
  }
  return 0.0;
}

std::string DefaultJvmInvoker::InvokeStringMethod(
    const std::string& method_name,
    const std::string& signature,
    const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::InvokeStringMethod", "method",
               method_name.c_str());
  if (pending_exception_.load()) {
    return "";
  }
  return "";
}

std::vector<uint8_t> DefaultJvmInvoker::InvokeBytesMethod(
    const std::string& method_name,
    const std::string& signature,
    const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::InvokeBytesMethod", "method",
               method_name.c_str());
  if (pending_exception_.load()) {
    return {};
  }
  return {};
}

bool DefaultJvmInvoker::PostJvmTask(std::function<void()> task) {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::PostJvmTask");
  if (!task) {
    return false;
  }
  if (platform_task_runner_) {
    platform_task_runner_->PostTask(task);
    return true;
  }
  FML_LOG(WARNING) << "PostJvmTask failed: no platform task runner configured.";
  return false;
}

// =============================================================================
// AndroidJvmInvoker Implementation
// =============================================================================

static jmethodID g_handle_platform_message_method = nullptr;
static jmethodID g_handle_platform_message_response_method = nullptr;
static jmethodID g_on_first_frame_method = nullptr;
static jmethodID g_on_engine_restart_method = nullptr;
static jmethodID g_set_application_locale_method = nullptr;
static jmethodID g_update_semantics_method = nullptr;
static jmethodID g_update_custom_accessibility_actions_method = nullptr;
static jmethodID g_set_semantics_tree_enabled_method = nullptr;

static jmethodID g_on_display_platform_view_method = nullptr;
static jmethodID g_on_display_platform_view2_method = nullptr;
static jmethodID g_on_begin_frame_method = nullptr;
static jmethodID g_on_end_frame_method = nullptr;
static jmethodID g_end_frame2_method = nullptr;
static jmethodID g_create_overlay_surface_method = nullptr;
static jmethodID g_create_overlay_surface2_method = nullptr;
static jmethodID g_destroy_overlay_surfaces_method = nullptr;
static jmethodID g_destroy_overlay_surface2_method = nullptr;
static jmethodID g_show_overlay_surface2_method = nullptr;
static jmethodID g_hide_overlay_surface2_method = nullptr;
static jmethodID g_create_transaction_method = nullptr;
static jmethodID g_swap_transactions_method = nullptr;
static jmethodID g_hide_platform_view2_method = nullptr;
static jmethodID g_on_display_overlay_surface_method = nullptr;

static fml::jni::ScopedJavaGlobalRef<jclass>* g_mutators_stack_class = nullptr;
static jmethodID g_mutators_stack_init = nullptr;
static jmethodID g_mutators_stack_push_transform = nullptr;
static jmethodID g_mutators_stack_push_cliprect = nullptr;
static jmethodID g_mutators_stack_push_cliprrect = nullptr;
static jmethodID g_mutators_stack_push_opacity = nullptr;

static fml::jni::ScopedJavaGlobalRef<jclass>* g_overlay_surface_class = nullptr;
static jmethodID g_overlay_surface_get_id_method = nullptr;
static jmethodID g_overlay_surface_get_surface_method = nullptr;

bool AndroidJvmInvoker::RegisterJni(JNIEnv* env, jclass clazz) {
  if (!env || !clazz) {
    return false;
  }
  g_handle_platform_message_method =
      env->GetMethodID(clazz, "handlePlatformMessage",
                       "(Ljava/lang/String;Ljava/nio/ByteBuffer;IJ)V");
  g_handle_platform_message_response_method = env->GetMethodID(
      clazz, "handlePlatformMessageResponse", "(ILjava/nio/ByteBuffer;)V");
  g_on_first_frame_method = env->GetMethodID(clazz, "onFirstFrame", "()V");
  g_on_engine_restart_method =
      env->GetMethodID(clazz, "onPreEngineRestart", "()V");
  g_set_application_locale_method =
      env->GetMethodID(clazz, "setApplicationLocale", "(Ljava/lang/String;)V");
  g_update_semantics_method = env->GetMethodID(
      clazz, "updateSemantics",
      "(Ljava/nio/ByteBuffer;[Ljava/lang/String;[Ljava/nio/ByteBuffer;)V");
  g_update_custom_accessibility_actions_method =
      env->GetMethodID(clazz, "updateCustomAccessibilityActions",
                       "(Ljava/nio/ByteBuffer;[Ljava/lang/String;)V");
  g_set_semantics_tree_enabled_method =
      env->GetMethodID(clazz, "setSemanticsTreeEnabled", "(Z)V");

  g_on_display_platform_view_method =
      env->GetMethodID(clazz, "onDisplayPlatformView",
                       "(IIIIIIILio/flutter/embedding/engine/mutatorsstack/"
                       "FlutterMutatorsStack;)V");
  g_on_display_platform_view2_method =
      env->GetMethodID(clazz, "onDisplayPlatformView2",
                       "(IIIIIIILio/flutter/embedding/engine/mutatorsstack/"
                       "FlutterMutatorsStack;)V");
  g_on_begin_frame_method = env->GetMethodID(clazz, "onBeginFrame", "()V");
  g_on_end_frame_method = env->GetMethodID(clazz, "onEndFrame", "()V");
  g_end_frame2_method = env->GetMethodID(clazz, "endFrame2", "()V");
  g_create_overlay_surface_method =
      env->GetMethodID(clazz, "createOverlaySurface",
                       "()Lio/flutter/embedding/engine/FlutterOverlaySurface;");
  g_create_overlay_surface2_method =
      env->GetMethodID(clazz, "createOverlaySurface2",
                       "()Lio/flutter/embedding/engine/FlutterOverlaySurface;");
  g_destroy_overlay_surfaces_method =
      env->GetMethodID(clazz, "destroyOverlaySurfaces", "()V");
  g_destroy_overlay_surface2_method =
      env->GetMethodID(clazz, "destroyOverlaySurface2", "()V");
  g_show_overlay_surface2_method =
      env->GetMethodID(clazz, "showOverlaySurface2", "()V");
  g_hide_overlay_surface2_method =
      env->GetMethodID(clazz, "hideOverlaySurface2", "()V");
  g_create_transaction_method =
      env->GetMethodID(clazz, "createTransaction",
                       "()Landroid/view/SurfaceControl$Transaction;");
  g_swap_transactions_method =
      env->GetMethodID(clazz, "swapTransactions", "()V");
  g_hide_platform_view2_method =
      env->GetMethodID(clazz, "hidePlatformView2", "(I)V");
  g_on_display_overlay_surface_method =
      env->GetMethodID(clazz, "onDisplayOverlaySurface", "(IIIII)V");

  if (env->ExceptionCheck()) {
    env->ExceptionClear();
  }

  jclass local_stack_class = env->FindClass(
      "io/flutter/embedding/engine/mutatorsstack/FlutterMutatorsStack");
  if (local_stack_class) {
    g_mutators_stack_class =
        new fml::jni::ScopedJavaGlobalRef<jclass>(env, local_stack_class);
    env->DeleteLocalRef(local_stack_class);
    g_mutators_stack_init =
        env->GetMethodID(g_mutators_stack_class->obj(), "<init>", "()V");
    g_mutators_stack_push_transform = env->GetMethodID(
        g_mutators_stack_class->obj(), "pushTransform", "([F)V");
    g_mutators_stack_push_cliprect = env->GetMethodID(
        g_mutators_stack_class->obj(), "pushClipRect", "(FFFF)V");
    g_mutators_stack_push_cliprrect = env->GetMethodID(
        g_mutators_stack_class->obj(), "pushClipRRect", "(FFFF[F)V");
    g_mutators_stack_push_opacity =
        env->GetMethodID(g_mutators_stack_class->obj(), "pushOpacity", "(F)V");
  }
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
  }

  jclass local_surf_class =
      env->FindClass("io/flutter/embedding/engine/FlutterOverlaySurface");
  if (local_surf_class) {
    g_overlay_surface_class =
        new fml::jni::ScopedJavaGlobalRef<jclass>(env, local_surf_class);
    env->DeleteLocalRef(local_surf_class);
    g_overlay_surface_get_id_method =
        env->GetMethodID(g_overlay_surface_class->obj(), "getId", "()I");
    g_overlay_surface_get_surface_method =
        env->GetMethodID(g_overlay_surface_class->obj(), "getSurface",
                         "()Landroid/view/Surface;");
  }
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
  }

  return g_handle_platform_message_method != nullptr &&
         g_handle_platform_message_response_method != nullptr &&
         g_on_first_frame_method != nullptr &&
         g_on_engine_restart_method != nullptr &&
         g_set_application_locale_method != nullptr &&
         g_update_semantics_method != nullptr &&
         g_update_custom_accessibility_actions_method != nullptr &&
         g_set_semantics_tree_enabled_method != nullptr;
}

AndroidJvmInvoker::AndroidJvmInvoker(
    std::shared_ptr<fml::jni::JavaObjectWeakGlobalRef> java_object,
    fml::RefPtr<fml::TaskRunner> platform_task_runner)
    : java_object_(std::move(java_object)),
      platform_task_runner_(std::move(platform_task_runner)) {
  TRACE_EVENT0("flutter", "AndroidJvmInvoker::AndroidJvmInvoker");
}

AndroidJvmInvoker::~AndroidJvmInvoker() {
  TRACE_EVENT0("flutter", "AndroidJvmInvoker::~AndroidJvmInvoker");
#if FML_OS_ANDROID
  std::lock_guard<std::mutex> lock(overlay_windows_mutex_);
  for (auto& [id, window] : overlay_windows_) {
    if (window != nullptr) {
      ANativeWindow_release(window);
    }
  }
  overlay_windows_.clear();
#endif
}

void AndroidJvmInvoker::SetJavaObject(
    std::shared_ptr<fml::jni::JavaObjectWeakGlobalRef> java_object) {
  std::lock_guard<std::mutex> lock(java_object_mutex_);
  java_object_ = std::move(java_object);
}

std::shared_ptr<fml::jni::JavaObjectWeakGlobalRef>
AndroidJvmInvoker::GetJavaObject() const {
  std::lock_guard<std::mutex> lock(java_object_mutex_);
  return java_object_;
}

fml::jni::ScopedJavaLocalRef<jobject> AndroidJvmInvoker::GetJavaObjectLocalRef(
    JNIEnv*& env) const {
  env = nullptr;
  {
    std::lock_guard<std::mutex> lock(java_object_mutex_);
    if (!java_object_) {
      return fml::jni::ScopedJavaLocalRef<jobject>();
    }
  }
  env = fml::jni::AttachCurrentThread();
  if (!env) {
    return fml::jni::ScopedJavaLocalRef<jobject>();
  }
  std::lock_guard<std::mutex> lock(java_object_mutex_);
  if (!java_object_) {
    env = nullptr;
    return fml::jni::ScopedJavaLocalRef<jobject>();
  }
  return java_object_->get(env);
}

bool AndroidJvmInvoker::EnsureAttachedToThread() {
  TRACE_EVENT0("flutter", "AndroidJvmInvoker::EnsureAttachedToThread");
  {
    std::lock_guard<std::mutex> lock(java_object_mutex_);
    if (!java_object_) {
      return false;
    }
  }
  return fml::jni::AttachCurrentThread() != nullptr;
}

void AndroidJvmInvoker::DetachFromThread() {
  TRACE_EVENT0("flutter", "AndroidJvmInvoker::DetachFromThread");
  {
    std::lock_guard<std::mutex> lock(java_object_mutex_);
    if (!java_object_) {
      return;
    }
  }
  fml::jni::DetachFromVM();
}

bool AndroidJvmInvoker::HasPendingException() const {
  TRACE_EVENT0("flutter", "AndroidJvmInvoker::HasPendingException");
  {
    std::lock_guard<std::mutex> lock(java_object_mutex_);
    if (!java_object_) {
      return false;
    }
  }
  JNIEnv* env = fml::jni::AttachCurrentThread();
  return env && env->ExceptionCheck();
}

void AndroidJvmInvoker::ClearPendingException() {
  TRACE_EVENT0("flutter", "AndroidJvmInvoker::ClearPendingException");
  {
    std::lock_guard<std::mutex> lock(java_object_mutex_);
    if (!java_object_) {
      return;
    }
  }
  JNIEnv* env = fml::jni::AttachCurrentThread();
  if (env) {
    env->ExceptionClear();
  }
}

bool AndroidJvmInvoker::HandlePlatformMessage(const std::string& channel,
                                              const uint8_t* message,
                                              size_t message_size,
                                              int32_t response_id,
                                              int64_t message_data) {
  TRACE_EVENT1("flutter", "AndroidJvmInvoker::HandlePlatformMessage", "channel",
               channel.c_str());
  JNIEnv* env = nullptr;
  fml::jni::ScopedJavaLocalRef<jobject> java_object =
      GetJavaObjectLocalRef(env);
  if (!env || java_object.is_null()) {
    return true;
  }
  if (!g_handle_platform_message_method) {
    return false;
  }

  fml::jni::ScopedJavaLocalRef<jstring> java_channel =
      fml::jni::StringToJavaString(env, channel);

  if (message != nullptr) {
    void* buffer_copy = nullptr;
    if (message_data == 0) {
      size_t alloc_size = message_size == 0 ? 1 : message_size;
      buffer_copy = malloc(alloc_size);
      if (!buffer_copy) {
        return false;
      }
      if (message_size > 0) {
        memcpy(buffer_copy, message, message_size);
      }
      message_data = reinterpret_cast<jlong>(buffer_copy);
    } else {
      buffer_copy = reinterpret_cast<void*>(message_data);
    }
    fml::jni::ScopedJavaLocalRef<jobject> direct_buf(
        env, env->NewDirectByteBuffer(buffer_copy, message_size));
    env->CallVoidMethod(java_object.obj(), g_handle_platform_message_method,
                        java_channel.obj(), direct_buf.obj(), response_id,
                        message_data);
  } else {
    env->CallVoidMethod(java_object.obj(), g_handle_platform_message_method,
                        java_channel.obj(), nullptr, response_id,
                        static_cast<jlong>(0));
  }
  return !fml::jni::CheckException(env);
}

bool AndroidJvmInvoker::HandlePlatformMessageResponse(int32_t response_id,
                                                      const uint8_t* data,
                                                      size_t data_size) {
  TRACE_EVENT0("flutter", "AndroidJvmInvoker::HandlePlatformMessageResponse");
  JNIEnv* env = nullptr;
  fml::jni::ScopedJavaLocalRef<jobject> java_object =
      GetJavaObjectLocalRef(env);
  if (!env || java_object.is_null()) {
    return true;
  }
  if (!g_handle_platform_message_response_method) {
    return false;
  }

  fml::jni::ScopedJavaLocalRef<jobject> data_buf;
  if (data != nullptr) {
    static const uint8_t kDummy = 0;
    void* buffer_ptr = data_size > 0 ? const_cast<uint8_t*>(data)
                                     : const_cast<uint8_t*>(&kDummy);
    data_buf.Reset(env, env->NewDirectByteBuffer(buffer_ptr, data_size));
  }
  env->CallVoidMethod(java_object.obj(),
                      g_handle_platform_message_response_method, response_id,
                      data_buf.obj());
  return !fml::jni::CheckException(env);
}

bool AndroidJvmInvoker::UpdateSemantics(
    const std::vector<uint8_t>& buffer,
    const std::vector<std::string>& strings,
    const std::vector<std::vector<uint8_t>>& string_attribute_args) {
  TRACE_EVENT0("flutter", "AndroidJvmInvoker::UpdateSemantics");
  JNIEnv* env = nullptr;
  fml::jni::ScopedJavaLocalRef<jobject> java_object =
      GetJavaObjectLocalRef(env);
  if (!env || java_object.is_null()) {
    return true;
  }
  if (!g_update_semantics_method) {
    return false;
  }

  fml::jni::ScopedJavaLocalRef<jobject> direct_buffer(
      env, env->NewDirectByteBuffer(const_cast<uint8_t*>(buffer.data()),
                                    buffer.size()));
  fml::jni::ScopedJavaLocalRef<jobjectArray> jstrings =
      fml::jni::VectorToStringArray(env, strings);
  fml::jni::ScopedJavaLocalRef<jobjectArray> jstring_attribute_args =
      fml::jni::VectorToBufferArray(env, string_attribute_args);

  env->CallVoidMethod(java_object.obj(), g_update_semantics_method,
                      direct_buffer.obj(), jstrings.obj(),
                      jstring_attribute_args.obj());
  return !fml::jni::CheckException(env);
}

bool AndroidJvmInvoker::UpdateCustomAccessibilityActions(
    const std::vector<uint8_t>& actions_buffer,
    const std::vector<std::string>& action_strings) {
  TRACE_EVENT0("flutter",
               "AndroidJvmInvoker::UpdateCustomAccessibilityActions");
  JNIEnv* env = nullptr;
  fml::jni::ScopedJavaLocalRef<jobject> java_object =
      GetJavaObjectLocalRef(env);
  if (!env || java_object.is_null()) {
    return true;
  }
  if (!g_update_custom_accessibility_actions_method) {
    return false;
  }

  fml::jni::ScopedJavaLocalRef<jobject> direct_actions_buffer(
      env, env->NewDirectByteBuffer(const_cast<uint8_t*>(actions_buffer.data()),
                                    actions_buffer.size()));
  fml::jni::ScopedJavaLocalRef<jobjectArray> jstrings =
      fml::jni::VectorToStringArray(env, action_strings);

  env->CallVoidMethod(java_object.obj(),
                      g_update_custom_accessibility_actions_method,
                      direct_actions_buffer.obj(), jstrings.obj());
  return !fml::jni::CheckException(env);
}

bool AndroidJvmInvoker::SetSemanticsTreeEnabled(bool enabled) {
  TRACE_EVENT0("flutter", "AndroidJvmInvoker::SetSemanticsTreeEnabled");
  JNIEnv* env = nullptr;
  fml::jni::ScopedJavaLocalRef<jobject> java_object =
      GetJavaObjectLocalRef(env);
  if (!env || java_object.is_null()) {
    return true;
  }
  if (!g_set_semantics_tree_enabled_method) {
    return false;
  }

  env->CallVoidMethod(java_object.obj(), g_set_semantics_tree_enabled_method,
                      enabled);
  return !fml::jni::CheckException(env);
}

bool AndroidJvmInvoker::SetApplicationLocale(const std::string& locale) {
  TRACE_EVENT1("flutter", "AndroidJvmInvoker::SetApplicationLocale", "locale",
               locale.c_str());
  JNIEnv* env = nullptr;
  fml::jni::ScopedJavaLocalRef<jobject> java_object =
      GetJavaObjectLocalRef(env);
  if (!env || java_object.is_null()) {
    return true;
  }
  if (!g_set_application_locale_method) {
    return false;
  }
  fml::jni::ScopedJavaLocalRef<jstring> jlocale =
      fml::jni::StringToJavaString(env, locale);
  env->CallVoidMethod(java_object.obj(), g_set_application_locale_method,
                      jlocale.obj());
  return !fml::jni::CheckException(env);
}

bool AndroidJvmInvoker::OnFirstFrame() {
  TRACE_EVENT0("flutter", "AndroidJvmInvoker::OnFirstFrame");
  JNIEnv* env = nullptr;
  fml::jni::ScopedJavaLocalRef<jobject> java_object =
      GetJavaObjectLocalRef(env);
  if (!env || java_object.is_null()) {
    return true;
  }
  if (!g_on_first_frame_method) {
    return false;
  }
  env->CallVoidMethod(java_object.obj(), g_on_first_frame_method);
  return !fml::jni::CheckException(env);
}

bool AndroidJvmInvoker::OnPreEngineRestart() {
  TRACE_EVENT0("flutter", "AndroidJvmInvoker::OnPreEngineRestart");
  JNIEnv* env = nullptr;
  fml::jni::ScopedJavaLocalRef<jobject> java_object =
      GetJavaObjectLocalRef(env);
  if (!env || java_object.is_null()) {
    return true;
  }
  if (!g_on_engine_restart_method) {
    return false;
  }
  env->CallVoidMethod(java_object.obj(), g_on_engine_restart_method);
  return !fml::jni::CheckException(env);
}

bool AndroidJvmInvoker::RequestDartDeferredLibrary(int loading_unit_id) {
  TRACE_EVENT1("flutter", "AndroidJvmInvoker::RequestDartDeferredLibrary",
               "loading_unit_id", std::to_string(loading_unit_id).c_str());
  return true;
}

bool AndroidJvmInvoker::DecodeImage(const uint8_t* data,
                                    size_t size,
                                    int64_t generator_handle) {
  TRACE_EVENT0("flutter", "AndroidJvmInvoker::DecodeImage");
  return true;
}

bool AndroidJvmInvoker::PushPlatformViewMutators(
    int64_t view_id,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    const std::vector<uint8_t>& payload) {
  return PushPlatformViewMutators(view_id, x, y, width, height, width, height,
                                  payload);
}

bool AndroidJvmInvoker::PushPlatformViewMutators(
    int64_t view_id,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    int32_t view_width,
    int32_t view_height,
    const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "AndroidJvmInvoker::PushPlatformViewMutators",
               "view_id", std::to_string(view_id).c_str());
  JNIEnv* env = nullptr;
  fml::jni::ScopedJavaLocalRef<jobject> java_object =
      GetJavaObjectLocalRef(env);
  if (!env || java_object.is_null()) {
    return true;
  }

  jobject j_stack = nullptr;
  if (g_mutators_stack_class && g_mutators_stack_init) {
    j_stack =
        env->NewObject(g_mutators_stack_class->obj(), g_mutators_stack_init);
  }
  if (j_stack == nullptr) {
    jclass local_class = env->FindClass(
        "io/flutter/embedding/engine/mutatorsstack/FlutterMutatorsStack");
    if (local_class) {
      jmethodID init_id = env->GetMethodID(local_class, "<init>", "()V");
      if (init_id) {
        j_stack = env->NewObject(local_class, init_id);
      }
      env->DeleteLocalRef(local_class);
    }
  }

  if (j_stack && !payload.empty()) {
    auto maybe_stack =
        AndroidMutatorsStack::Deserialize(payload.data(), payload.size());
    if (maybe_stack.has_value()) {
      for (const auto& m : maybe_stack->GetMutators()) {
        switch (m.type) {
          case AndroidMutatorType::kTransform: {
            const auto& mat = m.GetMatrix();
            // 3x3 2D affine transformation matrix elements.
            constexpr size_t kMatrixElements = 9;
            fml::jni::ScopedJavaLocalRef<jfloatArray> arr(
                env, env->NewFloatArray(kMatrixElements));
            env->SetFloatArrayRegion(arr.obj(), 0, kMatrixElements, mat.values);
            jmethodID push_transform = g_mutators_stack_push_transform;
            if (!push_transform) {
              jclass stack_cls = env->GetObjectClass(j_stack);
              push_transform =
                  env->GetMethodID(stack_cls, "pushTransform", "([F)V");
              env->DeleteLocalRef(stack_cls);
            }
            if (push_transform) {
              env->CallVoidMethod(j_stack, push_transform, arr.obj());
            }
            break;
          }
          case AndroidMutatorType::kClipRect: {
            const auto& r = m.GetRect();
            jmethodID push_cliprect = g_mutators_stack_push_cliprect;
            if (!push_cliprect) {
              jclass stack_cls = env->GetObjectClass(j_stack);
              push_cliprect =
                  env->GetMethodID(stack_cls, "pushClipRect", "(FFFF)V");
              env->DeleteLocalRef(stack_cls);
            }
            if (push_cliprect) {
              env->CallVoidMethod(
                  j_stack, push_cliprect, static_cast<jfloat>(r.left),
                  static_cast<jfloat>(r.top), static_cast<jfloat>(r.right),
                  static_cast<jfloat>(r.bottom));
            }
            break;
          }
          case AndroidMutatorType::kClipRRect: {
            const auto& rr = m.GetRRect();
            // 4 corner radii pairs (x, y).
            constexpr size_t kRadiiElements = 8;
            fml::jni::ScopedJavaLocalRef<jfloatArray> arr(
                env, env->NewFloatArray(kRadiiElements));
            env->SetFloatArrayRegion(arr.obj(), 0, kRadiiElements, rr.radii);
            jmethodID push_cliprrect = g_mutators_stack_push_cliprrect;
            if (!push_cliprrect) {
              jclass stack_cls = env->GetObjectClass(j_stack);
              push_cliprrect =
                  env->GetMethodID(stack_cls, "pushClipRRect", "(FFFF[F)V");
              env->DeleteLocalRef(stack_cls);
            }
            if (push_cliprrect) {
              env->CallVoidMethod(
                  j_stack, push_cliprrect, static_cast<jfloat>(rr.rect.left),
                  static_cast<jfloat>(rr.rect.top),
                  static_cast<jfloat>(rr.rect.right),
                  static_cast<jfloat>(rr.rect.bottom), arr.obj());
            }
            break;
          }
          case AndroidMutatorType::kOpacity: {
            jmethodID push_opacity = g_mutators_stack_push_opacity;
            if (!push_opacity) {
              jclass stack_cls = env->GetObjectClass(j_stack);
              push_opacity = env->GetMethodID(stack_cls, "pushOpacity", "(F)V");
              env->DeleteLocalRef(stack_cls);
            }
            if (push_opacity) {
              env->CallVoidMethod(j_stack, push_opacity,
                                  static_cast<jfloat>(m.GetOpacity()));
            }
            break;
          }
        }
      }
    }
  }

  jclass jni_class = env->GetObjectClass(java_object.obj());
  bool is_hcpp = false;
  if (jni_class) {
    jfieldID pvc2_field = env->GetFieldID(
        jni_class, "platformViewsController2",
        "Lio/flutter/plugin/platform/PlatformViewsController2;");
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
    }
    jfieldID pvc1_field =
        env->GetFieldID(jni_class, "platformViewsController",
                        "Lio/flutter/plugin/platform/PlatformViewsController;");
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
    }

    jobject pvc2 = pvc2_field
                       ? env->GetObjectField(java_object.obj(), pvc2_field)
                       : nullptr;
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
    }
    jobject pvc1 = pvc1_field
                       ? env->GetObjectField(java_object.obj(), pvc1_field)
                       : nullptr;
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
    }

    if (pvc2 != nullptr) {
      if (pvc1 == nullptr) {
        is_hcpp = true;
      } else if (hcpp_enabled_.load()) {
        bool in_pvc2 = false;
        jclass pvc2_cls = env->GetObjectClass(pvc2);
        if (pvc2_cls) {
          jmethodID get_view = env->GetMethodID(pvc2_cls, "getPlatformViewById",
                                                "(I)Landroid/view/View;");
          if (env->ExceptionCheck()) {
            env->ExceptionClear();
          }
          if (get_view) {
            jobject view = env->CallObjectMethod(pvc2, get_view,
                                                 static_cast<jint>(view_id));
            if (env->ExceptionCheck()) {
              env->ExceptionClear();
            }
            if (view != nullptr) {
              in_pvc2 = true;
              env->DeleteLocalRef(view);
            }
          }
          env->DeleteLocalRef(pvc2_cls);
        }
        bool in_pvc1 = false;
        if (!in_pvc2) {
          jclass pvc1_cls = env->GetObjectClass(pvc1);
          if (pvc1_cls) {
            jmethodID get_view1 = env->GetMethodID(
                pvc1_cls, "getPlatformViewById", "(I)Landroid/view/View;");
            if (env->ExceptionCheck()) {
              env->ExceptionClear();
            }
            if (get_view1) {
              jobject view1 = env->CallObjectMethod(pvc1, get_view1,
                                                    static_cast<jint>(view_id));
              if (env->ExceptionCheck()) {
                env->ExceptionClear();
              }
              if (view1 != nullptr) {
                in_pvc1 = true;
                env->DeleteLocalRef(view1);
              }
            }
            env->DeleteLocalRef(pvc1_cls);
          }
        }
        is_hcpp = in_pvc2 || !in_pvc1;
      }
    }

    if (pvc2) {
      env->DeleteLocalRef(pvc2);
    }
    if (pvc1) {
      env->DeleteLocalRef(pvc1);
    }
  }

  jmethodID target_method = is_hcpp ? g_on_display_platform_view2_method
                                    : g_on_display_platform_view_method;
  if (!target_method && jni_class) {
    const char* name =
        is_hcpp ? "onDisplayPlatformView2" : "onDisplayPlatformView";
    target_method = env->GetMethodID(jni_class, name,
                                     "(IIIIIIILio/flutter/embedding/engine/"
                                     "mutatorsstack/FlutterMutatorsStack;)V");
  }

  if (target_method) {
    env->CallVoidMethod(
        java_object.obj(), target_method, static_cast<jint>(view_id),
        static_cast<jint>(x), static_cast<jint>(y), static_cast<jint>(width),
        static_cast<jint>(height), static_cast<jint>(view_width),
        static_cast<jint>(view_height), j_stack);
  }

  if (j_stack) {
    env->DeleteLocalRef(j_stack);
  }
  if (jni_class) {
    env->DeleteLocalRef(jni_class);
  }

  if (env->ExceptionCheck()) {
    env->ExceptionClear();
    return false;
  }
  return true;
}

bool AndroidJvmInvoker::InvokeVoidMethod(const std::string& method_name,
                                         const std::string& signature,
                                         const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "AndroidJvmInvoker::InvokeVoidMethod", "method",
               method_name.c_str());
  if (method_name == "setHcppEnabled" && signature == "(Z)V") {
    bool b = !payload.empty() && payload[0] != 0;
    hcpp_enabled_.store(b);
    return true;
  }
  JNIEnv* env = nullptr;
  fml::jni::ScopedJavaLocalRef<jobject> java_object =
      GetJavaObjectLocalRef(env);
  if (!env || java_object.is_null()) {
    return true;
  }

  jclass clazz = env->GetObjectClass(java_object.obj());
  if (!clazz) {
    return false;
  }

  if (signature == "()V") {
    jmethodID method = nullptr;
    if (method_name == "onBeginFrame") {
      method = g_on_begin_frame_method;
    } else if (method_name == "onEndFrame") {
      method = g_on_end_frame_method;
    } else if (method_name == "endFrame2") {
      method = g_end_frame2_method;
    } else if (method_name == "destroyOverlaySurfaces") {
      method = g_destroy_overlay_surfaces_method;
    } else if (method_name == "destroyOverlaySurface2") {
      method = g_destroy_overlay_surface2_method;
    } else if (method_name == "showOverlaySurface2") {
      method = g_show_overlay_surface2_method;
    } else if (method_name == "hideOverlaySurface2") {
      method = g_hide_overlay_surface2_method;
    } else if (method_name == "swapTransactions") {
      method = g_swap_transactions_method;
    }
    if (!method) {
      method = env->GetMethodID(clazz, method_name.c_str(), "()V");
    }
    if (method) {
      env->CallVoidMethod(java_object.obj(), method);
    }
#if FML_OS_ANDROID
    if (method_name == "destroyOverlaySurfaces" ||
        method_name == "destroyOverlaySurface2") {
      std::lock_guard<std::mutex> lock(overlay_windows_mutex_);
      for (auto& [id, window] : overlay_windows_) {
        if (window != nullptr) {
          ANativeWindow_release(window);
        }
      }
      overlay_windows_.clear();
    }
#endif
  } else if (signature == "(I)V") {
    int32_t val = 0;
    if (payload.size() >= sizeof(int32_t)) {
      memcpy(&val, payload.data(), sizeof(int32_t));
    }
    jmethodID method = nullptr;
    if (method_name == "hidePlatformView2") {
      method = g_hide_platform_view2_method;
    }
    if (!method) {
      method = env->GetMethodID(clazz, method_name.c_str(), "(I)V");
    }
    if (method) {
      env->CallVoidMethod(java_object.obj(), method, static_cast<jint>(val));
    }
  } else if (signature == "(Z)V") {
    bool b = !payload.empty() && payload[0] != 0;
    jmethodID method = env->GetMethodID(clazz, method_name.c_str(), "(Z)V");
    if (method) {
      env->CallVoidMethod(java_object.obj(), method, static_cast<jboolean>(b));
    }
  } else if (signature == "(IIIII)V") {
    // 5 parameters for onDisplayOverlaySurface: id, x, y, width, height.
    constexpr size_t kOverlayFieldCount = 5;
    if (payload.size() >= sizeof(int32_t) * kOverlayFieldCount) {
      int32_t s_id, x, y, w, h;
      constexpr size_t kOffsetSurfaceId = 0;
      constexpr size_t kOffsetX = sizeof(int32_t) * 1;
      constexpr size_t kOffsetY = sizeof(int32_t) * 2;
      constexpr size_t kOffsetWidth = sizeof(int32_t) * 3;
      constexpr size_t kOffsetHeight = sizeof(int32_t) * 4;
      memcpy(&s_id, payload.data() + kOffsetSurfaceId, sizeof(int32_t));
      memcpy(&x, payload.data() + kOffsetX, sizeof(int32_t));
      memcpy(&y, payload.data() + kOffsetY, sizeof(int32_t));
      memcpy(&w, payload.data() + kOffsetWidth, sizeof(int32_t));
      memcpy(&h, payload.data() + kOffsetHeight, sizeof(int32_t));
      jmethodID method = g_on_display_overlay_surface_method;
      if (!method) {
        method = env->GetMethodID(clazz, method_name.c_str(), "(IIIII)V");
      }
      if (method) {
        env->CallVoidMethod(java_object.obj(), method, s_id, x, y, w, h);
      }
    }
  } else if (signature == "(JJ)V") {
    // 2 parameters for onVsync: frame_nanos, target_time_nanos.
    constexpr size_t kVsyncFieldCount = 2;
    if (payload.size() >= sizeof(int64_t) * kVsyncFieldCount) {
      int64_t f_nanos, t_nanos;
      constexpr size_t kOffsetFrameNanos = 0;
      constexpr size_t kOffsetTargetNanos = sizeof(int64_t) * 1;
      memcpy(&f_nanos, payload.data() + kOffsetFrameNanos, sizeof(int64_t));
      memcpy(&t_nanos, payload.data() + kOffsetTargetNanos, sizeof(int64_t));
      jmethodID method = env->GetMethodID(clazz, method_name.c_str(), "(JJ)V");
      if (method) {
        env->CallVoidMethod(java_object.obj(), method,
                            static_cast<jlong>(f_nanos),
                            static_cast<jlong>(t_nanos));
      }
    }
  } else if (signature == "(J)V") {
    if (payload.size() >= sizeof(int64_t)) {
      int64_t val;
      memcpy(&val, payload.data(), sizeof(int64_t));
      jmethodID method = env->GetMethodID(clazz, method_name.c_str(), "(J)V");
      if (method) {
        env->CallVoidMethod(java_object.obj(), method, static_cast<jlong>(val));
      }
    }
  } else if (signature == "(Ljava/lang/String;)V") {
    std::string str(reinterpret_cast<const char*>(payload.data()),
                    payload.size());
    jstring jstr = env->NewStringUTF(str.c_str());
    jmethodID method =
        env->GetMethodID(clazz, method_name.c_str(), "(Ljava/lang/String;)V");
    if (method) {
      env->CallVoidMethod(java_object.obj(), method, jstr);
    }
    if (jstr) {
      env->DeleteLocalRef(jstr);
    }
  }

  env->DeleteLocalRef(clazz);
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
    return false;
  }
  return true;
}

bool AndroidJvmInvoker::InvokeBooleanMethod(
    const std::string& method_name,
    const std::string& signature,
    const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "AndroidJvmInvoker::InvokeBooleanMethod", "method",
               method_name.c_str());
  JNIEnv* env = nullptr;
  fml::jni::ScopedJavaLocalRef<jobject> java_object =
      GetJavaObjectLocalRef(env);
  if (!env || java_object.is_null()) {
    return true;
  }

  if (method_name == "createPlatformViewTransaction") {
    jclass clazz = env->GetObjectClass(java_object.obj());
    if (!clazz) {
      return false;
    }
    jmethodID method = g_create_transaction_method;
    if (!method) {
      method = env->GetMethodID(clazz, "createTransaction",
                                "()Landroid/view/SurfaceControl$Transaction;");
    }
    env->DeleteLocalRef(clazz);
    if (!method) {
      if (env->ExceptionCheck()) {
        env->ExceptionClear();
      }
      return false;
    }
    jobject tx = env->CallObjectMethod(java_object.obj(), method);
    bool success = (tx != nullptr);
    if (tx) {
      env->DeleteLocalRef(tx);
    }
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
      return false;
    }
    return success;
  }

  if (signature == "()Z") {
    jclass clazz = env->GetObjectClass(java_object.obj());
    if (clazz) {
      jmethodID method = env->GetMethodID(clazz, method_name.c_str(), "()Z");
      bool res = false;
      if (method) {
        res = env->CallBooleanMethod(java_object.obj(), method);
      }
      env->DeleteLocalRef(clazz);
      if (env->ExceptionCheck()) {
        env->ExceptionClear();
        return false;
      }
      return res;
    }
  }

  return true;
}

int64_t AndroidJvmInvoker::InvokeIntMethod(
    const std::string& method_name,
    const std::string& signature,
    const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "AndroidJvmInvoker::InvokeIntMethod", "method",
               method_name.c_str());
  JNIEnv* env = nullptr;
  fml::jni::ScopedJavaLocalRef<jobject> java_object =
      GetJavaObjectLocalRef(env);
  if (!env || java_object.is_null()) {
    return 0;
  }

  if (method_name == "createOverlaySurfaceId" ||
      method_name == "createOverlaySurface2Id") {
    jclass clazz = env->GetObjectClass(java_object.obj());
    if (!clazz) {
      return -1;
    }
    bool is_v2 = (method_name == "createOverlaySurface2Id");
    jmethodID create_method = is_v2 ? g_create_overlay_surface2_method
                                    : g_create_overlay_surface_method;
    if (!create_method) {
      const char* name =
          is_v2 ? "createOverlaySurface2" : "createOverlaySurface";
      create_method = env->GetMethodID(
          clazz, name, "()Lio/flutter/embedding/engine/FlutterOverlaySurface;");
    }
    env->DeleteLocalRef(clazz);
    if (!create_method) {
      if (env->ExceptionCheck()) {
        env->ExceptionClear();
      }
      return -1;
    }

    jobject surface_obj =
        env->CallObjectMethod(java_object.obj(), create_method);
    if (!surface_obj) {
      if (env->ExceptionCheck()) {
        env->ExceptionClear();
      }
      return -1;
    }

    jmethodID get_id_method = g_overlay_surface_get_id_method;
    if (!get_id_method) {
      jclass surf_class = env->GetObjectClass(surface_obj);
      if (surf_class) {
        get_id_method = env->GetMethodID(surf_class, "getId", "()I");
        env->DeleteLocalRef(surf_class);
      }
    }

    int32_t id = -1;
    if (get_id_method) {
      id = env->CallIntMethod(surface_obj, get_id_method);
    }

#if FML_OS_ANDROID
    jmethodID get_surface_method = g_overlay_surface_get_surface_method;
    if (!get_surface_method) {
      jclass surf_class = env->GetObjectClass(surface_obj);
      if (surf_class) {
        get_surface_method = env->GetMethodID(surf_class, "getSurface",
                                              "()Landroid/view/Surface;");
        env->DeleteLocalRef(surf_class);
      }
    }
    if (get_surface_method && id >= 0) {
      jobject surface = env->CallObjectMethod(surface_obj, get_surface_method);
      if (surface) {
        ANativeWindow* window = ANativeWindow_fromSurface(env, surface);
        env->DeleteLocalRef(surface);
        if (window) {
          std::lock_guard<std::mutex> lock(overlay_windows_mutex_);
          auto it = overlay_windows_.find(id);
          if (it != overlay_windows_.end() && it->second != nullptr) {
            ANativeWindow_release(it->second);
          }
          overlay_windows_[id] = window;
        }
      }
    }
#endif

    env->DeleteLocalRef(surface_obj);
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
      return -1;
    }
    return id;
  }

  if (signature == "()I") {
    jclass clazz = env->GetObjectClass(java_object.obj());
    if (clazz) {
      jmethodID method = env->GetMethodID(clazz, method_name.c_str(), "()I");
      int64_t result = 0;
      if (method) {
        result = env->CallIntMethod(java_object.obj(), method);
      }
      env->DeleteLocalRef(clazz);
      if (env->ExceptionCheck()) {
        env->ExceptionClear();
        return 0;
      }
      return result;
    }
  }

  return 0;
}

double AndroidJvmInvoker::InvokeDoubleMethod(
    const std::string& method_name,
    const std::string& signature,
    const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "AndroidJvmInvoker::InvokeDoubleMethod", "method",
               method_name.c_str());
  return 0.0;
}

std::string AndroidJvmInvoker::InvokeStringMethod(
    const std::string& method_name,
    const std::string& signature,
    const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "AndroidJvmInvoker::InvokeStringMethod", "method",
               method_name.c_str());
  return "";
}

std::vector<uint8_t> AndroidJvmInvoker::InvokeBytesMethod(
    const std::string& method_name,
    const std::string& signature,
    const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "AndroidJvmInvoker::InvokeBytesMethod", "method",
               method_name.c_str());
  return {};
}

bool AndroidJvmInvoker::PostJvmTask(std::function<void()> task) {
  TRACE_EVENT0("flutter", "AndroidJvmInvoker::PostJvmTask");
  if (!task) {
    return false;
  }
  if (platform_task_runner_) {
    platform_task_runner_->PostTask(task);
    return true;
  }
  return false;
}

ANativeWindow* AndroidJvmInvoker::GetOverlayWindow(int32_t id) {
  std::lock_guard<std::mutex> lock(overlay_windows_mutex_);
  auto it = overlay_windows_.find(id);
  if (it != overlay_windows_.end()) {
    return it->second;
  }
  return nullptr;
}

}  // namespace android
}  // namespace flutter
