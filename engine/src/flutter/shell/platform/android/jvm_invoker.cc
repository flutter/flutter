// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/jvm_invoker.h"

#include <android/native_window_jni.h>

#include "flutter/fml/logging.h"
#include "flutter/fml/platform/android/jni_util.h"
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
static jmethodID g_on_end_frame_method = nullptr;
static jmethodID g_end_frame2_method = nullptr;

static jmethodID g_create_overlay_surface_method = nullptr;
static jmethodID g_create_overlay_surface2_method = nullptr;
static jmethodID g_destroy_overlay_surfaces_method = nullptr;
static jmethodID g_destroy_overlay_surface2_method = nullptr;
static jmethodID g_on_display_overlay_surface_method = nullptr;
static jmethodID g_show_overlay_surface2_method = nullptr;
static jmethodID g_hide_overlay_surface2_method = nullptr;

static fml::jni::ScopedJavaGlobalRef<jclass>* g_overlay_surface_class = nullptr;
static jmethodID g_overlay_surface_get_id_method = nullptr;
static jmethodID g_overlay_surface_get_surface_method = nullptr;

static fml::jni::ScopedJavaGlobalRef<jclass>* g_mutators_stack_class = nullptr;
static jmethodID g_mutators_stack_init_method = nullptr;
static jmethodID g_mutators_stack_push_transform_method = nullptr;
static jmethodID g_mutators_stack_push_cliprect_method = nullptr;
static jmethodID g_mutators_stack_push_cliprrect_method = nullptr;
static jmethodID g_mutators_stack_push_opacity_method = nullptr;

static fml::jni::ScopedJavaGlobalRef<jclass>* g_flutter_jni_class = nullptr;
static jmethodID g_set_vm_service_uri_static_method = nullptr;

bool AndroidJvmInvoker::RegisterJni(JNIEnv* env, jclass clazz) {
  if (!env || !clazz) {
    return false;
  }
  if (!g_flutter_jni_class) {
    g_flutter_jni_class = new fml::jni::ScopedJavaGlobalRef<jclass>();
  }
  g_flutter_jni_class->Reset(env, clazz);
  g_set_vm_service_uri_static_method =
      env->GetStaticMethodID(clazz, "setVMServiceUri", "(Ljava/lang/String;)V");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
    g_set_vm_service_uri_static_method = nullptr;
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
  g_on_end_frame_method = env->GetMethodID(clazz, "onEndFrame", "()V");
  g_end_frame2_method = env->GetMethodID(clazz, "endFrame2", "()V");

  g_create_overlay_surface_method =
      env->GetMethodID(clazz, "createOverlaySurface",
                       "()Lio/flutter/embedding/engine/FlutterOverlaySurface;");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
    g_create_overlay_surface_method = nullptr;
  }
  g_create_overlay_surface2_method =
      env->GetMethodID(clazz, "createOverlaySurface2",
                       "()Lio/flutter/embedding/engine/FlutterOverlaySurface;");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
    g_create_overlay_surface2_method = nullptr;
  }
  g_destroy_overlay_surfaces_method =
      env->GetMethodID(clazz, "destroyOverlaySurfaces", "()V");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
    g_destroy_overlay_surfaces_method = nullptr;
  }
  g_destroy_overlay_surface2_method =
      env->GetMethodID(clazz, "destroyOverlaySurface2", "()V");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
    g_destroy_overlay_surface2_method = nullptr;
  }
  g_on_display_overlay_surface_method =
      env->GetMethodID(clazz, "onDisplayOverlaySurface", "(IIIII)V");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
    g_on_display_overlay_surface_method = nullptr;
  }
  g_show_overlay_surface2_method =
      env->GetMethodID(clazz, "showOverlaySurface2", "()V");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
    g_show_overlay_surface2_method = nullptr;
  }
  g_hide_overlay_surface2_method =
      env->GetMethodID(clazz, "hideOverlaySurface2", "()V");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
    g_hide_overlay_surface2_method = nullptr;
  }

  jclass overlay_surface_local =
      env->FindClass("io/flutter/embedding/engine/FlutterOverlaySurface");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
    overlay_surface_local = nullptr;
  }
  if (overlay_surface_local) {
    if (!g_overlay_surface_class) {
      g_overlay_surface_class = new fml::jni::ScopedJavaGlobalRef<jclass>();
    }
    g_overlay_surface_class->Reset(env, overlay_surface_local);
    env->DeleteLocalRef(overlay_surface_local);

    jclass overlay_cls = g_overlay_surface_class->obj();
    g_overlay_surface_get_id_method =
        env->GetMethodID(overlay_cls, "getId", "()I");
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
      g_overlay_surface_get_id_method = nullptr;
    }
    g_overlay_surface_get_surface_method =
        env->GetMethodID(overlay_cls, "getSurface", "()Landroid/view/Surface;");
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
      g_overlay_surface_get_surface_method = nullptr;
    }
  }

  jclass mutators_stack_local = env->FindClass(
      "io/flutter/embedding/engine/mutatorsstack/FlutterMutatorsStack");
  if (mutators_stack_local) {
    if (!g_mutators_stack_class) {
      g_mutators_stack_class = new fml::jni::ScopedJavaGlobalRef<jclass>();
    }
    g_mutators_stack_class->Reset(env, mutators_stack_local);
    env->DeleteLocalRef(mutators_stack_local);

    jclass stack_class = g_mutators_stack_class->obj();
    g_mutators_stack_init_method =
        env->GetMethodID(stack_class, "<init>", "()V");
    g_mutators_stack_push_transform_method =
        env->GetMethodID(stack_class, "pushTransform", "([F)V");
    g_mutators_stack_push_cliprect_method =
        env->GetMethodID(stack_class, "pushClipRect", "(FFFF)V");
    g_mutators_stack_push_cliprrect_method =
        env->GetMethodID(stack_class, "pushClipRRect", "(FFFF[F)V");
    g_mutators_stack_push_opacity_method =
        env->GetMethodID(stack_class, "pushOpacity", "(F)V");
  }

  return g_handle_platform_message_method != nullptr &&
         g_handle_platform_message_response_method != nullptr &&
         g_on_first_frame_method != nullptr &&
         g_on_engine_restart_method != nullptr &&
         g_set_application_locale_method != nullptr &&
         g_update_semantics_method != nullptr &&
         g_update_custom_accessibility_actions_method != nullptr &&
         g_set_semantics_tree_enabled_method != nullptr &&
         g_on_display_platform_view_method != nullptr &&
         g_on_display_platform_view2_method != nullptr &&
         g_on_end_frame_method != nullptr && g_end_frame2_method != nullptr &&
         g_mutators_stack_class != nullptr &&
         !g_mutators_stack_class->is_null() &&
         g_mutators_stack_init_method != nullptr &&
         g_mutators_stack_push_transform_method != nullptr &&
         g_mutators_stack_push_cliprect_method != nullptr &&
         g_mutators_stack_push_cliprrect_method != nullptr &&
         g_mutators_stack_push_opacity_method != nullptr;
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
}

void AndroidJvmInvoker::SetJavaObject(
    const std::shared_ptr<fml::jni::JavaObjectWeakGlobalRef>& java_object) {
  std::lock_guard<std::mutex> lock(java_object_mutex_);
  java_object_ = java_object;
}

std::shared_ptr<fml::jni::JavaObjectWeakGlobalRef>
AndroidJvmInvoker::GetJavaObject() const {
  std::lock_guard<std::mutex> lock(java_object_mutex_);
  return java_object_;
}

void AndroidJvmInvoker::SetPlatformTaskRunner(
    fml::RefPtr<fml::TaskRunner> platform_task_runner) {
  std::lock_guard<std::mutex> lock(platform_task_runner_mutex_);
  platform_task_runner_ = std::move(platform_task_runner);
}

fml::RefPtr<fml::TaskRunner> AndroidJvmInvoker::GetPlatformTaskRunner() const {
  std::lock_guard<std::mutex> lock(platform_task_runner_mutex_);
  return platform_task_runner_;
}

bool AndroidJvmInvoker::EnsureAttachedToThread() {
  TRACE_EVENT0("flutter", "AndroidJvmInvoker::EnsureAttachedToThread");
  return fml::jni::AttachCurrentThread() != nullptr;
}

void AndroidJvmInvoker::DetachFromThread() {
  TRACE_EVENT0("flutter", "AndroidJvmInvoker::DetachFromThread");
  fml::jni::DetachFromVM();
}

bool AndroidJvmInvoker::HasPendingException() const {
  TRACE_EVENT0("flutter", "AndroidJvmInvoker::HasPendingException");
  JNIEnv* env = fml::jni::AttachCurrentThread();
  return env && env->ExceptionCheck();
}

void AndroidJvmInvoker::ClearPendingException() {
  TRACE_EVENT0("flutter", "AndroidJvmInvoker::ClearPendingException");
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
  JNIEnv* env = fml::jni::AttachCurrentThread();
  if (!env) {
    return false;
  }
  fml::jni::ScopedJavaLocalRef<jobject> java_object;
  {
    std::lock_guard<std::mutex> lock(java_object_mutex_);
    if (java_object_) {
      java_object = java_object_->get(env);
    }
  }
  if (java_object.is_null()) {
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
  return fml::jni::CheckException(env);
}

bool AndroidJvmInvoker::HandlePlatformMessageResponse(int32_t response_id,
                                                      const uint8_t* data,
                                                      size_t data_size) {
  TRACE_EVENT0("flutter", "AndroidJvmInvoker::HandlePlatformMessageResponse");
  JNIEnv* env = fml::jni::AttachCurrentThread();
  if (!env) {
    return false;
  }
  fml::jni::ScopedJavaLocalRef<jobject> java_object;
  {
    std::lock_guard<std::mutex> lock(java_object_mutex_);
    if (java_object_) {
      java_object = java_object_->get(env);
    }
  }
  if (java_object.is_null()) {
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
  return fml::jni::CheckException(env);
}

bool AndroidJvmInvoker::UpdateSemantics(
    const std::vector<uint8_t>& buffer,
    const std::vector<std::string>& strings,
    const std::vector<std::vector<uint8_t>>& string_attribute_args) {
  TRACE_EVENT0("flutter", "AndroidJvmInvoker::UpdateSemantics");
  JNIEnv* env = fml::jni::AttachCurrentThread();
  if (!env) {
    return false;
  }
  fml::jni::ScopedJavaLocalRef<jobject> java_object;
  {
    std::lock_guard<std::mutex> lock(java_object_mutex_);
    if (java_object_) {
      java_object = java_object_->get(env);
    }
  }
  if (java_object.is_null()) {
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
  return fml::jni::CheckException(env);
}

bool AndroidJvmInvoker::UpdateCustomAccessibilityActions(
    const std::vector<uint8_t>& actions_buffer,
    const std::vector<std::string>& action_strings) {
  TRACE_EVENT0("flutter",
               "AndroidJvmInvoker::UpdateCustomAccessibilityActions");
  JNIEnv* env = fml::jni::AttachCurrentThread();
  if (!env) {
    return false;
  }
  fml::jni::ScopedJavaLocalRef<jobject> java_object;
  {
    std::lock_guard<std::mutex> lock(java_object_mutex_);
    if (java_object_) {
      java_object = java_object_->get(env);
    }
  }
  if (java_object.is_null()) {
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
  return fml::jni::CheckException(env);
}

bool AndroidJvmInvoker::SetSemanticsTreeEnabled(bool enabled) {
  TRACE_EVENT0("flutter", "AndroidJvmInvoker::SetSemanticsTreeEnabled");
  JNIEnv* env = fml::jni::AttachCurrentThread();
  if (!env) {
    return false;
  }
  fml::jni::ScopedJavaLocalRef<jobject> java_object;
  {
    std::lock_guard<std::mutex> lock(java_object_mutex_);
    if (java_object_) {
      java_object = java_object_->get(env);
    }
  }
  if (java_object.is_null()) {
    return true;
  }
  if (!g_set_semantics_tree_enabled_method) {
    return false;
  }

  env->CallVoidMethod(java_object.obj(), g_set_semantics_tree_enabled_method,
                      enabled);
  return fml::jni::CheckException(env);
}

bool AndroidJvmInvoker::SetApplicationLocale(const std::string& locale) {
  TRACE_EVENT1("flutter", "AndroidJvmInvoker::SetApplicationLocale", "locale",
               locale.c_str());
  JNIEnv* env = fml::jni::AttachCurrentThread();
  if (!env) {
    return false;
  }
  fml::jni::ScopedJavaLocalRef<jobject> java_object;
  {
    std::lock_guard<std::mutex> lock(java_object_mutex_);
    if (java_object_) {
      java_object = java_object_->get(env);
    }
  }
  if (java_object.is_null()) {
    return true;
  }
  if (!g_set_application_locale_method) {
    return false;
  }
  fml::jni::ScopedJavaLocalRef<jstring> jlocale =
      fml::jni::StringToJavaString(env, locale);
  env->CallVoidMethod(java_object.obj(), g_set_application_locale_method,
                      jlocale.obj());
  return fml::jni::CheckException(env);
}

bool AndroidJvmInvoker::OnFirstFrame() {
  TRACE_EVENT0("flutter", "AndroidJvmInvoker::OnFirstFrame");
  JNIEnv* env = fml::jni::AttachCurrentThread();
  if (!env) {
    return false;
  }
  fml::jni::ScopedJavaLocalRef<jobject> java_object;
  {
    std::lock_guard<std::mutex> lock(java_object_mutex_);
    if (java_object_) {
      java_object = java_object_->get(env);
    }
  }
  if (java_object.is_null()) {
    return true;
  }
  if (!g_on_first_frame_method) {
    return false;
  }
  env->CallVoidMethod(java_object.obj(), g_on_first_frame_method);
  return fml::jni::CheckException(env);
}

bool AndroidJvmInvoker::OnPreEngineRestart() {
  TRACE_EVENT0("flutter", "AndroidJvmInvoker::OnPreEngineRestart");
  JNIEnv* env = fml::jni::AttachCurrentThread();
  if (!env) {
    return false;
  }
  fml::jni::ScopedJavaLocalRef<jobject> java_object;
  {
    std::lock_guard<std::mutex> lock(java_object_mutex_);
    if (java_object_) {
      java_object = java_object_->get(env);
    }
  }
  if (java_object.is_null()) {
    return true;
  }
  if (!g_on_engine_restart_method) {
    return false;
  }
  env->CallVoidMethod(java_object.obj(), g_on_engine_restart_method);
  return fml::jni::CheckException(env);
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

  fml::RefPtr<fml::TaskRunner> platform_runner;
  {
    std::lock_guard<std::mutex> lock(platform_task_runner_mutex_);
    platform_runner = platform_task_runner_;
  }

  if (platform_runner && !platform_runner->RunsTasksOnCurrentThread()) {
    platform_runner->PostTask([weak_this = weak_from_this(), view_id, x, y,
                               width, height, view_width, view_height,
                               payload]() {
      if (auto invoker = weak_this.lock()) {
        invoker->PushPlatformViewMutators(view_id, x, y, width, height,
                                          view_width, view_height, payload);
      }
    });
    return true;
  }

  if (!fml::jni::HasJavaVM()) {
    return true;
  }
  JNIEnv* env = fml::jni::AttachCurrentThread();
  if (!env) {
    FML_LOG(ERROR) << "Could not attach JNIEnv for PushPlatformViewMutators.";
    return false;
  }

  fml::jni::ScopedJavaLocalRef<jobject> java_object;
  {
    std::lock_guard<std::mutex> lock(java_object_mutex_);
    if (java_object_) {
      java_object = java_object_->get(env);
    }
  }
  if (java_object.is_null() || !g_mutators_stack_class ||
      g_mutators_stack_class->is_null() || !g_mutators_stack_init_method) {
    FML_LOG(ERROR) << "Java object or mutators stack class not initialized.";
    return false;
  }

  fml::jni::ScopedJavaLocalRef<jobject> mutators_stack(
      env, env->NewObject(g_mutators_stack_class->obj(),
                          g_mutators_stack_init_method));
  if (mutators_stack.is_null()) {
    FML_LOG(ERROR) << "Failed to instantiate Java FlutterMutatorsStack.";
    return false;
  }

  if (!payload.empty()) {
    auto stack_opt =
        AndroidMutatorsStack::Deserialize(payload.data(), payload.size());
    if (!stack_opt.has_value()) {
      FML_LOG(ERROR) << "Failed to deserialize AndroidMutatorsStack payload.";
      return false;
    }

    // Named constants for JNI float array sizes
    // 3x3 affine transformation matrix represented as 9 floats
    constexpr jsize kMatrixElementCount = 9;
    // 4 corner radii pairs (x, y) represented as 8 floats
    constexpr jsize kRadiiElementCount = 8;

    for (const auto& mutator : stack_opt->GetMutators()) {
      switch (mutator.type) {
        case AndroidMutatorType::kTransform: {
          const auto& mat = mutator.GetMatrix();
          jfloatArray j_mat = env->NewFloatArray(kMatrixElementCount);
          if (!j_mat) {
            FML_LOG(ERROR) << "OOM allocating transform float array.";
            return false;
          }
          env->SetFloatArrayRegion(j_mat, 0, kMatrixElementCount, mat.values);
          env->CallVoidMethod(mutators_stack.obj(),
                              g_mutators_stack_push_transform_method, j_mat);
          env->DeleteLocalRef(j_mat);
          break;
        }
        case AndroidMutatorType::kClipRect: {
          const auto& r = mutator.GetRect();
          env->CallVoidMethod(mutators_stack.obj(),
                              g_mutators_stack_push_cliprect_method, r.left,
                              r.top, r.right, r.bottom);
          break;
        }
        case AndroidMutatorType::kClipRRect: {
          const auto& rr = mutator.GetRRect();
          jfloatArray j_radii = env->NewFloatArray(kRadiiElementCount);
          if (!j_radii) {
            FML_LOG(ERROR) << "OOM allocating radii float array.";
            return false;
          }
          env->SetFloatArrayRegion(j_radii, 0, kRadiiElementCount, rr.radii);
          env->CallVoidMethod(mutators_stack.obj(),
                              g_mutators_stack_push_cliprrect_method,
                              rr.rect.left, rr.rect.top, rr.rect.right,
                              rr.rect.bottom, j_radii);
          env->DeleteLocalRef(j_radii);
          break;
        }
        case AndroidMutatorType::kOpacity: {
          env->CallVoidMethod(mutators_stack.obj(),
                              g_mutators_stack_push_opacity_method,
                              mutator.GetOpacity());
          break;
        }
      }
      if (!fml::jni::CheckException(env)) {
        FML_LOG(ERROR) << "Exception occurred while pushing mutators to stack.";
        return false;
      }
    }
  }

  jmethodID method = is_hcpp_active_.load() ? g_on_display_platform_view2_method
                                            : g_on_display_platform_view_method;
  if (!method) {
    FML_LOG(ERROR) << "Target onDisplayPlatformView method not found (HCPP="
                   << is_hcpp_active_.load() << ").";
    return false;
  }

  env->CallVoidMethod(java_object.obj(), method, static_cast<jint>(view_id),
                      static_cast<jint>(x), static_cast<jint>(y),
                      static_cast<jint>(width), static_cast<jint>(height),
                      static_cast<jint>(view_width),
                      static_cast<jint>(view_height), mutators_stack.obj());
  return fml::jni::CheckException(env);
}

std::unique_ptr<PlatformViewOverlaySurface>
AndroidJvmInvoker::CreateOverlaySurface() {
  TRACE_EVENT0("flutter", "AndroidJvmInvoker::CreateOverlaySurface");
  if (!fml::jni::HasJavaVM()) {
    return nullptr;
  }

  JNIEnv* env = fml::jni::AttachCurrentThread();
  if (!env) {
    FML_LOG(ERROR)
        << "Failed to attach current thread to JVM in CreateOverlaySurface.";
    return nullptr;
  }

  fml::jni::ScopedJavaLocalRef<jobject> java_object;
  {
    std::lock_guard<std::mutex> lock(java_object_mutex_);
    if (java_object_) {
      java_object = java_object_->get(env);
    }
  }
  if (java_object.is_null()) {
    FML_LOG(ERROR) << "Cannot create overlay surface: java_object is null.";
    return nullptr;
  }

  jmethodID method = is_hcpp_active_.load() ? g_create_overlay_surface2_method
                                            : g_create_overlay_surface_method;
  if (!method) {
    jclass cls = env->GetObjectClass(java_object.obj());
    if (cls) {
      const char* name = is_hcpp_active_.load() ? "createOverlaySurface2"
                                                : "createOverlaySurface";
      method = env->GetMethodID(
          cls, name, "()Lio/flutter/embedding/engine/FlutterOverlaySurface;");
      if (env->ExceptionCheck()) {
        env->ExceptionClear();
        method = nullptr;
      }
      env->DeleteLocalRef(cls);
    }
  }

  if (!method) {
    FML_LOG(ERROR)
        << "Failed to find createOverlaySurface method on FlutterJNI.";
    return nullptr;
  }

  jobject overlay_surface_obj =
      env->CallObjectMethod(java_object.obj(), method);
  if (env->ExceptionCheck()) {
    env->ExceptionDescribe();
    env->ExceptionClear();
    FML_LOG(ERROR) << "Exception occurred during createOverlaySurface call.";
    return nullptr;
  }

  if (!overlay_surface_obj) {
    FML_LOG(ERROR)
        << "createOverlaySurface returned null FlutterOverlaySurface.";
    return nullptr;
  }

  // Extract ID.
  jint id = -1;
  jclass overlay_class = env->GetObjectClass(overlay_surface_obj);
  jmethodID get_id_method = g_overlay_surface_get_id_method;
  if (!get_id_method && overlay_class) {
    get_id_method = env->GetMethodID(overlay_class, "getId", "()I");
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
      get_id_method = nullptr;
    }
  }
  if (get_id_method) {
    id = env->CallIntMethod(overlay_surface_obj, get_id_method);
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
      id = -1;
    }
  }

  // Extract Surface.
  jmethodID get_surface_method = g_overlay_surface_get_surface_method;
  if (!get_surface_method && overlay_class) {
    get_surface_method = env->GetMethodID(overlay_class, "getSurface",
                                          "()Landroid/view/Surface;");
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
      get_surface_method = nullptr;
    }
  }

  jobject surface_obj = nullptr;
  if (get_surface_method) {
    surface_obj =
        env->CallObjectMethod(overlay_surface_obj, get_surface_method);
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
      surface_obj = nullptr;
    }
  }

  if (overlay_class) {
    env->DeleteLocalRef(overlay_class);
  }

  if (!surface_obj) {
    env->DeleteLocalRef(overlay_surface_obj);
    FML_LOG(ERROR) << "Failed to extract Surface from FlutterOverlaySurface.";
    return nullptr;
  }

  ANativeWindow* window = ANativeWindow_fromSurface(env, surface_obj);
  env->DeleteLocalRef(surface_obj);
  env->DeleteLocalRef(overlay_surface_obj);

  if (!window) {
    FML_LOG(ERROR) << "ANativeWindow_fromSurface failed for overlay surface id "
                   << id;
    return nullptr;
  }

  return std::make_unique<PlatformViewOverlaySurface>(id, window);
}

void AndroidJvmInvoker::DestroyOverlaySurfaces() {
  TRACE_EVENT0("flutter", "AndroidJvmInvoker::DestroyOverlaySurfaces");
  if (!fml::jni::HasJavaVM()) {
    return;
  }

  JNIEnv* env = fml::jni::AttachCurrentThread();
  if (!env) {
    FML_LOG(ERROR)
        << "Failed to attach current thread to JVM in DestroyOverlaySurfaces.";
    return;
  }

  fml::jni::ScopedJavaLocalRef<jobject> java_object;
  {
    std::lock_guard<std::mutex> lock(java_object_mutex_);
    if (java_object_) {
      java_object = java_object_->get(env);
    }
  }
  if (java_object.is_null()) {
    return;
  }

  jmethodID method = is_hcpp_active_.load() ? g_destroy_overlay_surface2_method
                                            : g_destroy_overlay_surfaces_method;
  if (!method) {
    jclass cls = env->GetObjectClass(java_object.obj());
    if (cls) {
      const char* name = is_hcpp_active_.load() ? "destroyOverlaySurface2"
                                                : "destroyOverlaySurfaces";
      method = env->GetMethodID(cls, name, "()V");
      if (env->ExceptionCheck()) {
        env->ExceptionClear();
        method = nullptr;
      }
      env->DeleteLocalRef(cls);
    }
  }

  if (method) {
    env->CallVoidMethod(java_object.obj(), method);
    if (env->ExceptionCheck()) {
      env->ExceptionDescribe();
      env->ExceptionClear();
      FML_LOG(ERROR)
          << "Exception occurred during destroyOverlaySurfaces call.";
    }
  }
}

bool AndroidJvmInvoker::OnDisplayOverlaySurface(int32_t id,
                                                int32_t x,
                                                int32_t y,
                                                int32_t width,
                                                int32_t height) {
  TRACE_EVENT0("flutter", "AndroidJvmInvoker::OnDisplayOverlaySurface");
  if (!fml::jni::HasJavaVM()) {
    return true;
  }

  JNIEnv* env = fml::jni::AttachCurrentThread();
  if (!env) {
    FML_LOG(ERROR)
        << "Failed to attach current thread to JVM in OnDisplayOverlaySurface.";
    return false;
  }

  fml::jni::ScopedJavaLocalRef<jobject> java_object;
  {
    std::lock_guard<std::mutex> lock(java_object_mutex_);
    if (java_object_) {
      java_object = java_object_->get(env);
    }
  }
  if (java_object.is_null()) {
    return false;
  }

  jmethodID method = g_on_display_overlay_surface_method;
  if (!method) {
    jclass cls = env->GetObjectClass(java_object.obj());
    if (cls) {
      method = env->GetMethodID(cls, "onDisplayOverlaySurface", "(IIIII)V");
      if (env->ExceptionCheck()) {
        env->ExceptionClear();
        method = nullptr;
      }
      env->DeleteLocalRef(cls);
    }
  }

  if (method) {
    env->CallVoidMethod(java_object.obj(), method, static_cast<jint>(id),
                        static_cast<jint>(x), static_cast<jint>(y),
                        static_cast<jint>(width), static_cast<jint>(height));
    return fml::jni::CheckException(env);
  }
  return false;
}

bool AndroidJvmInvoker::InvokeVoidMethod(const std::string& method_name,
                                         const std::string& signature,
                                         const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "AndroidJvmInvoker::InvokeVoidMethod", "method",
               method_name.c_str());

  if (method_name == "setVmServiceUri") {
    if (!fml::jni::HasJavaVM()) {
      // Host unit tests or environments without an active JavaVM.
      return true;
    }

    JNIEnv* env = fml::jni::AttachCurrentThread();
    if (!env) {
      FML_LOG(ERROR) << "Failed to attach current thread to JVM.";
      return false;
    }

    std::string uri(payload.begin(), payload.end());
    jstring j_uri = env->NewStringUTF(uri.c_str());
    if (!j_uri) {
      FML_LOG(ERROR) << "Failed to allocate jstring for VM service URI.";
      return false;
    }

    bool success = false;

    // Check if an instance object is available.
    std::shared_ptr<fml::jni::JavaObjectWeakGlobalRef> java_obj_ref;
    {
      std::lock_guard<std::mutex> lock(java_object_mutex_);
      java_obj_ref = java_object_;
    }

    if (java_obj_ref) {
      auto instance = java_obj_ref->get(env);
      if (instance.obj()) {
        jclass cls = env->GetObjectClass(instance.obj());
        if (cls) {
          // Instance method is named setVmServiceUri (lowercase 'm')
          jmethodID method =
              env->GetMethodID(cls, "setVmServiceUri", "(Ljava/lang/String;)V");
          if (env->ExceptionCheck()) {
            env->ExceptionClear();
            method = nullptr;
          }
          if (method) {
            env->CallVoidMethod(instance.obj(), method, j_uri);
            if (fml::jni::CheckException(env)) {
              success = true;
            }
          }
          env->DeleteLocalRef(cls);
        }
      }
    }

    // Fall back to static method if instance method was not invoked.
    if (!success && g_flutter_jni_class && g_flutter_jni_class->obj() &&
        g_set_vm_service_uri_static_method) {
      env->CallStaticVoidMethod(g_flutter_jni_class->obj(),
                                g_set_vm_service_uri_static_method, j_uri);
      if (fml::jni::CheckException(env)) {
        success = true;
      }
    }

    env->DeleteLocalRef(j_uri);

    if (env->ExceptionCheck()) {
      env->ExceptionDescribe();
      env->ExceptionClear();
      FML_LOG(ERROR) << "Exception occurred while calling setVMServiceUri.";
      return false;
    }

    return success;
  }

  if (method_name == "onEndFrame" || method_name == "endFrame2") {
    if (!fml::jni::HasJavaVM()) {
      return true;
    }

    JNIEnv* env = fml::jni::AttachCurrentThread();
    if (!env) {
      FML_LOG(ERROR) << "Failed to attach current thread to JVM.";
      return false;
    }

    std::shared_ptr<fml::jni::JavaObjectWeakGlobalRef> java_obj_ref;
    {
      std::lock_guard<std::mutex> lock(java_object_mutex_);
      java_obj_ref = java_object_;
    }
    if (!java_obj_ref) {
      return false;
    }

    auto java_object = java_obj_ref->get(env);
    if (java_object.is_null()) {
      return false;
    }

    jmethodID method = (method_name == "endFrame2") ? g_end_frame2_method
                                                    : g_on_end_frame_method;
    if (!method) {
      jclass cls = env->GetObjectClass(java_object.obj());
      if (cls) {
        method = env->GetMethodID(cls, method_name.c_str(), "()V");
        if (env->ExceptionCheck()) {
          env->ExceptionClear();
          method = nullptr;
        }
        env->DeleteLocalRef(cls);
      }
    }
    if (!method) {
      FML_LOG(ERROR) << "Method " << method_name << " not found on FlutterJNI.";
      return false;
    }

    env->CallVoidMethod(java_object.obj(), method);
    return fml::jni::CheckException(env);
  }

  if (method_name == "onDisplayOverlaySurface") {
    // 5 x 32-bit signed integers: surface_id, x, y, width, height (5 * 4 = 20
    // bytes).
    static constexpr size_t kExpectedPayloadBytes = 20;
    if (payload.size() >= kExpectedPayloadBytes) {
      int32_t id = 0;
      int32_t x = 0;
      int32_t y = 0;
      int32_t width = 0;
      int32_t height = 0;
      memcpy(&id, payload.data(), sizeof(int32_t));
      memcpy(&x, payload.data() + sizeof(int32_t), sizeof(int32_t));
      memcpy(&y, payload.data() + sizeof(int32_t) * 2, sizeof(int32_t));
      memcpy(&width, payload.data() + sizeof(int32_t) * 3, sizeof(int32_t));
      memcpy(&height, payload.data() + sizeof(int32_t) * 4, sizeof(int32_t));
      return OnDisplayOverlaySurface(id, x, y, width, height);
    }
    FML_LOG(ERROR) << "Invalid payload size for onDisplayOverlaySurface: "
                   << payload.size();
    return false;
  }

  if (method_name == "destroyOverlaySurfaces" ||
      method_name == "destroyOverlaySurface2") {
    DestroyOverlaySurfaces();
    return true;
  }

  if (method_name == "showOverlaySurface2" ||
      method_name == "hideOverlaySurface2") {
    if (!fml::jni::HasJavaVM()) {
      return true;
    }
    JNIEnv* env = fml::jni::AttachCurrentThread();
    if (!env) {
      FML_LOG(ERROR) << "Failed to attach current thread to JVM.";
      return false;
    }
    std::shared_ptr<fml::jni::JavaObjectWeakGlobalRef> java_obj_ref;
    {
      std::lock_guard<std::mutex> lock(java_object_mutex_);
      java_obj_ref = java_object_;
    }
    if (!java_obj_ref) {
      return false;
    }
    auto java_object = java_obj_ref->get(env);
    if (java_object.is_null()) {
      return false;
    }
    jmethodID method = (method_name == "showOverlaySurface2")
                           ? g_show_overlay_surface2_method
                           : g_hide_overlay_surface2_method;
    if (!method) {
      jclass cls = env->GetObjectClass(java_object.obj());
      if (cls) {
        method = env->GetMethodID(cls, method_name.c_str(), "()V");
        if (env->ExceptionCheck()) {
          env->ExceptionClear();
          method = nullptr;
        }
        env->DeleteLocalRef(cls);
      }
    }
    if (!method) {
      FML_LOG(ERROR) << "Method " << method_name << " not found on FlutterJNI.";
      return false;
    }
    env->CallVoidMethod(java_object.obj(), method);
    return fml::jni::CheckException(env);
  }

  return true;
}

bool AndroidJvmInvoker::InvokeBooleanMethod(
    const std::string& method_name,
    const std::string& signature,
    const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "AndroidJvmInvoker::InvokeBooleanMethod", "method",
               method_name.c_str());
  return true;
}

int64_t AndroidJvmInvoker::InvokeIntMethod(
    const std::string& method_name,
    const std::string& signature,
    const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "AndroidJvmInvoker::InvokeIntMethod", "method",
               method_name.c_str());
  if (method_name == "createOverlaySurfaceId" ||
      method_name == "createOverlaySurface2Id") {
    auto overlay = CreateOverlaySurface();
    if (!overlay) {
      return -1;
    }
    return overlay->id;
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
  fml::RefPtr<fml::TaskRunner> platform_runner;
  {
    std::lock_guard<std::mutex> lock(platform_task_runner_mutex_);
    platform_runner = platform_task_runner_;
  }
  if (platform_runner) {
    platform_runner->PostTask(std::move(task));
    return true;
  }
  return false;
}

}  // namespace android
}  // namespace flutter
