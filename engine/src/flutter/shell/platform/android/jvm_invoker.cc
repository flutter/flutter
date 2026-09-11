// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/jvm_invoker.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

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
    platform_task_runner_->PostTask(std::move(task));
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
  return !fml::jni::CheckException(env);
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
  return !fml::jni::CheckException(env);
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
  return !fml::jni::CheckException(env);
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
  return !fml::jni::CheckException(env);
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
  return !fml::jni::CheckException(env);
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
  return !fml::jni::CheckException(env);
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
  return !fml::jni::CheckException(env);
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
  return true;
}

bool AndroidJvmInvoker::InvokeVoidMethod(const std::string& method_name,
                                         const std::string& signature,
                                         const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "AndroidJvmInvoker::InvokeVoidMethod", "method",
               method_name.c_str());
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
    platform_task_runner_->PostTask(std::move(task));
    return true;
  }
  return false;
}

}  // namespace android
}  // namespace flutter
