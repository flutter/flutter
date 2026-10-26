// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/jvm_invoker.h"

#include <dlfcn.h>
#include <cmath>
#include <cstdlib>
#include <cstring>

#if FML_OS_ANDROID
#include <sys/system_properties.h>
#endif

namespace flutter {

namespace {

jclass g_flutter_jni_class = nullptr;

jmethodID g_handle_platform_message_method = nullptr;
jmethodID g_handle_platform_message_response_method = nullptr;
bool g_response_method_takes_position = false;
jmethodID g_update_semantics_method = nullptr;
jmethodID g_set_custom_accessibility_actions_method = nullptr;
jmethodID g_on_first_frame_method = nullptr;
jmethodID g_on_engine_restart_method = nullptr;
jmethodID g_create_overlay_surface_method = nullptr;
jmethodID g_destroy_overlay_surfaces_method = nullptr;
jmethodID g_on_begin_frame_method = nullptr;
jmethodID g_on_end_frame_method = nullptr;
jmethodID g_compute_platform_resolved_locale_method = nullptr;
jmethodID g_request_dart_deferred_library_method = nullptr;
jmethodID g_on_display_platform_view_method = nullptr;
jmethodID g_get_scaled_font_size_method = nullptr;
jmethodID g_on_display_platform_view2_method = nullptr;
jmethodID g_hide_platform_view2_method = nullptr;
jmethodID g_end_frame2_method = nullptr;
jmethodID g_create_overlay_surface2_method = nullptr;
jmethodID g_destroy_overlay_surface2_method = nullptr;
jmethodID g_show_overlay_surface2_method = nullptr;
jmethodID g_hide_overlay_surface2_method = nullptr;
jmethodID g_set_application_locale_method = nullptr;
jmethodID g_set_semantics_tree_enabled_method = nullptr;

jclass g_mutators_stack_class = nullptr;
jmethodID g_mutators_stack_ctor_method = nullptr;
jmethodID g_mutators_stack_push_transform_method = nullptr;
jmethodID g_mutators_stack_push_clip_rect_method = nullptr;
jmethodID g_mutators_stack_push_clip_rrect_method = nullptr;
jmethodID g_mutators_stack_push_opacity_method = nullptr;

// Number of floats in a 3x3 Android transformation matrix.
constexpr size_t kMutatorMatrixElementCount = 9;
// Number of ints in a clip rectangle (left, top, right, bottom).
constexpr size_t kMutatorRectCoordCount = 4;
// Number of floats in a rounded clip rectangle (4 bounds + 8 corner radii).
constexpr size_t kMutatorRRectFloatCount = 12;
// Number of corner radii floats in a rounded clip rectangle.
constexpr size_t kMutatorRRectRadiiCount = 8;

// Mutator type discriminators matching AndroidMutatorType in
// android_mutators_mapper.h.
constexpr int32_t kMutatorTypeClipRect = 0;
constexpr int32_t kMutatorTypeClipRRect = 1;
constexpr int32_t kMutatorTypeClipPath = 2;
constexpr int32_t kMutatorTypeTransform = 3;
constexpr int32_t kMutatorTypeOpacity = 4;

// Non-null backing byte for 0-length direct ByteBuffers so JNI
// NewDirectByteBuffer never receives nullptr for an empty non-null payload.
uint8_t kEmptyDirectBufferByte = 0;

// Minimum Android API level required for Impeller Vulkan backend (Android 10 /
// API 29).
constexpr int kMinVulkanApiLevel = 29;

// Minimum Vulkan API version required (Vulkan 1.1: major=1, minor=1 -> (1 <<
// 22) | (1 << 12)).
constexpr uint32_t kMinVulkanApiVersion = (1u << 22) | (1u << 12);

// Synthetic handles used when VulkanDeviceOwner runs on host unit tests without
// a mock driver.
constexpr uintptr_t kSyntheticInstanceAddress = 0x1001;
constexpr uintptr_t kSyntheticPhysicalDeviceAddress = 0x1002;
constexpr uintptr_t kSyntheticDeviceAddress = 0x1003;
constexpr uintptr_t kSyntheticQueueAddress = 0x1004;

class DynamicMockHandle : public OSLibrary {
 public:
  explicit DynamicMockHandle(std::shared_ptr<MockOSLibrary> impl)
      : impl_(std::move(impl)) {}
  ~DynamicMockHandle() override = default;

  void* ResolveSymbol(const char* symbol_name) override {
    return impl_->ResolveSymbol(symbol_name);
  }

 private:
  std::shared_ptr<MockOSLibrary> impl_;
};

}  // namespace

bool JvmInvoker::RegisterMethodIds(JNIEnv* env) {
  if (env == nullptr) {
    return false;
  }

  jclass local_class = env->FindClass("io/flutter/embedding/engine/FlutterJNI");
  if (local_class == nullptr) {
    return false;
  }

  g_flutter_jni_class = static_cast<jclass>(env->NewGlobalRef(local_class));
  env->DeleteLocalRef(local_class);

  if (g_flutter_jni_class == nullptr) {
    return false;
  }

  g_handle_platform_message_method =
      env->GetMethodID(g_flutter_jni_class, "handlePlatformMessage",
                       "(Ljava/lang/String;Ljava/nio/ByteBuffer;IJ)V");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
  }

  g_response_method_takes_position = false;
  g_handle_platform_message_response_method =
      env->GetMethodID(g_flutter_jni_class, "handlePlatformMessageResponse",
                       "(ILjava/nio/ByteBuffer;)V");
  if (env->ExceptionCheck() ||
      g_handle_platform_message_response_method == nullptr) {
    env->ExceptionClear();
    g_handle_platform_message_response_method = env->GetMethodID(
        g_flutter_jni_class, "invokePlatformMessageResponseCallback",
        "(ILjava/nio/ByteBuffer;I)V");
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
    } else if (g_handle_platform_message_response_method != nullptr) {
      g_response_method_takes_position = true;
    }
  }

  g_update_semantics_method = env->GetMethodID(
      g_flutter_jni_class, "updateSemantics",
      "(Ljava/nio/ByteBuffer;[Ljava/lang/String;[Ljava/nio/ByteBuffer;)V");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
  }

  g_set_custom_accessibility_actions_method =
      env->GetMethodID(g_flutter_jni_class, "updateCustomAccessibilityActions",
                       "(Ljava/nio/ByteBuffer;[Ljava/lang/String;)V");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
  }

  g_on_first_frame_method =
      env->GetMethodID(g_flutter_jni_class, "onFirstFrame", "()V");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
  }

  g_on_engine_restart_method =
      env->GetMethodID(g_flutter_jni_class, "onPreEngineRestart", "()V");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
  }

  g_create_overlay_surface_method =
      env->GetMethodID(g_flutter_jni_class, "createOverlaySurface",
                       "()Lio/flutter/embedding/engine/FlutterOverlaySurface;");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
  }

  g_destroy_overlay_surfaces_method =
      env->GetMethodID(g_flutter_jni_class, "destroyOverlaySurfaces", "()V");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
  }

  g_on_begin_frame_method =
      env->GetMethodID(g_flutter_jni_class, "onBeginFrame", "()V");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
  }

  g_on_end_frame_method =
      env->GetMethodID(g_flutter_jni_class, "onEndFrame", "()V");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
  }

  g_compute_platform_resolved_locale_method =
      env->GetMethodID(g_flutter_jni_class, "computePlatformResolvedLocale",
                       "([Ljava/lang/String;)[Ljava/lang/String;");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
  }

  g_request_dart_deferred_library_method = env->GetMethodID(
      g_flutter_jni_class, "requestDartDeferredLibrary", "(I)V");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
  }

  g_on_display_platform_view_method =
      env->GetMethodID(g_flutter_jni_class, "onDisplayPlatformView",
                       "(IIIIIIILio/flutter/embedding/engine/mutatorsstack/"
                       "FlutterMutatorsStack;)V");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
  }

  g_get_scaled_font_size_method =
      env->GetMethodID(g_flutter_jni_class, "getScaledFontSize", "(FI)F");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
  }

  g_on_display_platform_view2_method =
      env->GetMethodID(g_flutter_jni_class, "onDisplayPlatformView2",
                       "(IIIIIIILio/flutter/embedding/engine/mutatorsstack/"
                       "FlutterMutatorsStack;)V");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
  }

  g_hide_platform_view2_method =
      env->GetMethodID(g_flutter_jni_class, "hidePlatformView2", "(I)V");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
  }

  g_end_frame2_method =
      env->GetMethodID(g_flutter_jni_class, "endFrame2", "()V");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
  }

  g_create_overlay_surface2_method =
      env->GetMethodID(g_flutter_jni_class, "createOverlaySurface2",
                       "()Lio/flutter/embedding/engine/FlutterOverlaySurface;");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
  }

  g_destroy_overlay_surface2_method =
      env->GetMethodID(g_flutter_jni_class, "destroyOverlaySurface2", "()V");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
  }

  g_show_overlay_surface2_method =
      env->GetMethodID(g_flutter_jni_class, "showOverlaySurface2", "()V");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
  }

  g_hide_overlay_surface2_method =
      env->GetMethodID(g_flutter_jni_class, "hideOverlaySurface2", "()V");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
  }

  jclass local_stack_class = env->FindClass(
      "io/flutter/embedding/engine/mutatorsstack/FlutterMutatorsStack");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
    local_stack_class = nullptr;
  }
  if (local_stack_class != nullptr) {
    if (g_mutators_stack_class != nullptr) {
      env->DeleteGlobalRef(g_mutators_stack_class);
    }
    g_mutators_stack_class =
        static_cast<jclass>(env->NewGlobalRef(local_stack_class));
    env->DeleteLocalRef(local_stack_class);
    if (g_mutators_stack_class != nullptr) {
      g_mutators_stack_ctor_method =
          env->GetMethodID(g_mutators_stack_class, "<init>", "()V");
      if (env->ExceptionCheck()) {
        env->ExceptionClear();
      }
      g_mutators_stack_push_transform_method =
          env->GetMethodID(g_mutators_stack_class, "pushTransform", "([F)V");
      if (env->ExceptionCheck()) {
        env->ExceptionClear();
      }
      g_mutators_stack_push_clip_rect_method =
          env->GetMethodID(g_mutators_stack_class, "pushClipRect", "(IIII)V");
      if (env->ExceptionCheck()) {
        env->ExceptionClear();
      }
      g_mutators_stack_push_clip_rrect_method = env->GetMethodID(
          g_mutators_stack_class, "pushClipRRect", "(IIII[F)V");
      if (env->ExceptionCheck()) {
        env->ExceptionClear();
      }
      g_mutators_stack_push_opacity_method =
          env->GetMethodID(g_mutators_stack_class, "pushOpacity", "(F)V");
      if (env->ExceptionCheck()) {
        env->ExceptionClear();
      }
    }
  }

  return true;
}

JvmInvoker::JvmInvoker(JNIEnv* env, jobject flutter_jni) {
#if FML_OS_ANDROID
  test_env_ = (env != nullptr && env->functions != nullptr &&
               env->functions->GetJavaVM == nullptr)
                  ? env
                  : nullptr;
#else
  test_env_ = env;
#endif
  if (env != nullptr && flutter_jni != nullptr) {
    AttachToJava(env, flutter_jni);
  }
}

JvmInvoker::~JvmInvoker() {
  DetachFromJava();
}

void JvmInvoker::AttachToJava(JNIEnv* env, jobject flutter_jni) {
#if FML_OS_ANDROID
  test_env_ = (env != nullptr && env->functions != nullptr &&
               env->functions->GetJavaVM == nullptr)
                  ? env
                  : nullptr;
#else
  test_env_ = env;
#endif
  if (env != nullptr && flutter_jni != nullptr) {
    java_object_ = fml::jni::JavaObjectWeakGlobalRef(env, flutter_jni);
  }
}

void JvmInvoker::DetachFromJava() {
  java_object_.reset();
  test_env_ = nullptr;
}

bool JvmInvoker::IsAttached() const {
  if (java_object_.is_empty()) {
    return false;
  }
  JNIEnv* env = GetEnv();
  if (env == nullptr) {
    return false;
  }
  auto obj = java_object_.get(env);
  return !obj.is_null();
}

JNIEnv* JvmInvoker::GetEnv() const {
  if (test_env_ != nullptr) {
    return test_env_;
  }
  if (java_object_.is_empty()) {
    return nullptr;
  }
#if FML_OS_ANDROID
  return fml::jni::AttachCurrentThread();
#else
  return nullptr;
#endif
}

fml::jni::ScopedJavaLocalRef<jobject> JvmInvoker::GetFlutterJni(
    JNIEnv* env) const {
  if (env == nullptr) {
    return fml::jni::ScopedJavaLocalRef<jobject>();
  }
  return java_object_.get(env);
}

void JvmInvoker::HandlePlatformMessage(const std::string& channel,
                                       const uint8_t* data,
                                       size_t data_size,
                                       int32_t response_id,
                                       int64_t message_data) {
  JNIEnv* env = GetEnv();
  if (env == nullptr) {
    return;
  }
  auto java_object = java_object_.get(env);
  if (java_object.is_null() || g_handle_platform_message_method == nullptr) {
    return;
  }

  jstring java_channel = env->NewStringUTF(channel.c_str());
  jobject direct_buffer = nullptr;
  void* owned_copy = nullptr;
  if (data != nullptr) {
    void* buffer_address = static_cast<void*>(&kEmptyDirectBufferByte);
    if (data_size > 0) {
      if (test_env_ == nullptr && message_data == 0) {
        owned_copy = std::malloc(data_size);
        if (owned_copy != nullptr) {
          std::memcpy(owned_copy, data, data_size);
          buffer_address = owned_copy;
          message_data = reinterpret_cast<int64_t>(owned_copy);
        } else {
          buffer_address = const_cast<uint8_t*>(data);
        }
      } else {
        buffer_address = const_cast<uint8_t*>(data);
      }
    }
    direct_buffer = env->NewDirectByteBuffer(buffer_address, data_size);
  }

  env->CallVoidMethod(java_object.obj(), g_handle_platform_message_method,
                      java_channel, direct_buffer, response_id, message_data);

  if (direct_buffer != nullptr) {
    env->DeleteLocalRef(direct_buffer);
  }
  if (java_channel != nullptr) {
    env->DeleteLocalRef(java_channel);
  }
  fml::jni::CheckException(env);
}

void JvmInvoker::HandlePlatformMessageResponse(int32_t response_id,
                                               const uint8_t* data,
                                               size_t data_size) {
  JNIEnv* env = GetEnv();
  if (env == nullptr) {
    return;
  }
  auto java_object = java_object_.get(env);
  if (java_object.is_null() ||
      g_handle_platform_message_response_method == nullptr) {
    return;
  }

  jobject direct_buffer = nullptr;
  if (data != nullptr) {
    void* buffer_address = data_size > 0
                               ? const_cast<uint8_t*>(data)
                               : static_cast<void*>(&kEmptyDirectBufferByte);
    direct_buffer = env->NewDirectByteBuffer(buffer_address, data_size);
  }

  if (g_response_method_takes_position) {
    env->CallVoidMethod(java_object.obj(),
                        g_handle_platform_message_response_method, response_id,
                        direct_buffer, static_cast<jint>(data_size));
  } else {
    env->CallVoidMethod(java_object.obj(),
                        g_handle_platform_message_response_method, response_id,
                        direct_buffer);
  }

  if (direct_buffer != nullptr) {
    env->DeleteLocalRef(direct_buffer);
  }
  fml::jni::CheckException(env);
}

void JvmInvoker::UpdateSemantics(JNIEnv* env,
                                 jobject buffer,
                                 jobjectArray strings,
                                 jobjectArray string_Attribute_args) {
  if (env == nullptr) {
    env = GetEnv();
  }
  if (env == nullptr) {
    return;
  }
  auto java_object = java_object_.get(env);
  if (java_object.is_null() || g_update_semantics_method == nullptr) {
    return;
  }
  env->CallVoidMethod(java_object.obj(), g_update_semantics_method, buffer,
                      strings, string_Attribute_args);
  fml::jni::CheckException(env);
}

void JvmInvoker::UpdateSemantics(
    const std::vector<uint8_t>& buffer,
    const std::vector<std::string>& strings,
    const std::vector<std::vector<uint8_t>>& string_attribute_args) {
  JNIEnv* env = GetEnv();
  if (env == nullptr || buffer.empty()) {
    return;
  }
  auto java_object = java_object_.get(env);
  if (java_object.is_null() || g_update_semantics_method == nullptr) {
    return;
  }
  jobject direct_buffer = env->NewDirectByteBuffer(
      const_cast<uint8_t*>(buffer.data()), buffer.size());
  auto java_strings = fml::jni::VectorToStringArray(env, strings);
  jclass bb_class = env->FindClass("java/nio/ByteBuffer");
  jobjectArray java_attr_args = nullptr;
  if (bb_class != nullptr) {
    java_attr_args =
        env->NewObjectArray(string_attribute_args.size(), bb_class, nullptr);
    for (size_t i = 0; i < string_attribute_args.size(); ++i) {
      const auto& arg_bytes = string_attribute_args[i];
      void* addr = arg_bytes.empty()
                       ? static_cast<void*>(&kEmptyDirectBufferByte)
                       : const_cast<uint8_t*>(arg_bytes.data());
      jobject item_bb = env->NewDirectByteBuffer(addr, arg_bytes.size());
      env->SetObjectArrayElement(java_attr_args, i, item_bb);
      if (item_bb != nullptr) {
        env->DeleteLocalRef(item_bb);
      }
    }
    env->DeleteLocalRef(bb_class);
  }
  env->CallVoidMethod(java_object.obj(), g_update_semantics_method,
                      direct_buffer, java_strings.obj(), java_attr_args);
  if (java_attr_args != nullptr) {
    env->DeleteLocalRef(java_attr_args);
  }
  if (direct_buffer != nullptr) {
    env->DeleteLocalRef(direct_buffer);
  }
  fml::jni::CheckException(env);
}

void JvmInvoker::UpdateCustomAccessibilityActions(
    const std::vector<uint8_t>& buffer,
    const std::vector<std::string>& strings) {
  JNIEnv* env = GetEnv();
  if (env == nullptr || buffer.empty()) {
    return;
  }
  auto java_object = java_object_.get(env);
  if (java_object.is_null() ||
      g_set_custom_accessibility_actions_method == nullptr) {
    return;
  }
  jobject direct_buffer = env->NewDirectByteBuffer(
      const_cast<uint8_t*>(buffer.data()), buffer.size());
  auto java_strings = fml::jni::VectorToStringArray(env, strings);
  env->CallVoidMethod(java_object.obj(),
                      g_set_custom_accessibility_actions_method, direct_buffer,
                      java_strings.obj());
  if (direct_buffer != nullptr) {
    env->DeleteLocalRef(direct_buffer);
  }
  fml::jni::CheckException(env);
}

void JvmInvoker::AsyncWaitForVsync(int64_t baton) {
  (void)baton;
}

void JvmInvoker::SetApplicationLocale(const std::string& locale) {
  JNIEnv* env = GetEnv();
  if (env == nullptr || test_env_ != nullptr) {
    return;
  }
  auto java_object = java_object_.get(env);
  if (java_object.is_null()) {
    return;
  }
  if (g_set_application_locale_method == nullptr &&
      g_flutter_jni_class != nullptr) {
    g_set_application_locale_method = env->GetMethodID(
        g_flutter_jni_class, "setApplicationLocale", "(Ljava/lang/String;)V");
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
      g_set_application_locale_method = nullptr;
    }
  }
  if (g_set_application_locale_method == nullptr) {
    return;
  }
  jstring java_locale = env->NewStringUTF(locale.c_str());
  env->CallVoidMethod(java_object.obj(), g_set_application_locale_method,
                      java_locale);
  if (java_locale != nullptr) {
    env->DeleteLocalRef(java_locale);
  }
  fml::jni::CheckException(env);
}

void JvmInvoker::SetSemanticsTreeEnabled(bool enabled) {
  JNIEnv* env = GetEnv();
  if (env == nullptr || test_env_ != nullptr) {
    return;
  }
  auto java_object = java_object_.get(env);
  if (java_object.is_null()) {
    return;
  }
  if (g_set_semantics_tree_enabled_method == nullptr &&
      g_flutter_jni_class != nullptr) {
    g_set_semantics_tree_enabled_method = env->GetMethodID(
        g_flutter_jni_class, "setSemanticsTreeEnabled", "(Z)V");
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
      g_set_semantics_tree_enabled_method = nullptr;
    }
  }
  if (g_set_semantics_tree_enabled_method == nullptr) {
    return;
  }
  env->CallVoidMethod(java_object.obj(), g_set_semantics_tree_enabled_method,
                      static_cast<jboolean>(enabled ? JNI_TRUE : JNI_FALSE));
  fml::jni::CheckException(env);
}

std::unique_ptr<std::vector<std::string>>
JvmInvoker::ComputePlatformResolvedLocale(
    const std::vector<std::string>& supported_locales_data) {
  JNIEnv* env = GetEnv();
  if (env == nullptr) {
    return nullptr;
  }
  auto java_object = java_object_.get(env);
  if (java_object.is_null() ||
      g_compute_platform_resolved_locale_method == nullptr) {
    return nullptr;
  }

  auto java_locales =
      fml::jni::VectorToStringArray(env, supported_locales_data);
  jobjectArray result_array = static_cast<jobjectArray>(env->CallObjectMethod(
      java_object.obj(), g_compute_platform_resolved_locale_method,
      java_locales.obj()));
  if (!fml::jni::CheckException(env) || result_array == nullptr) {
    return nullptr;
  }

  auto out = std::make_unique<std::vector<std::string>>(
      fml::jni::StringArrayToVector(env, result_array));
  env->DeleteLocalRef(result_array);
  return out;
}

void JvmInvoker::OnFirstFrame() {
  JNIEnv* env = GetEnv();
  if (env == nullptr) {
    return;
  }
  auto java_object = java_object_.get(env);
  if (java_object.is_null() || g_on_first_frame_method == nullptr) {
    return;
  }
  env->CallVoidMethod(java_object.obj(), g_on_first_frame_method);
  fml::jni::CheckException(env);
}

void JvmInvoker::OnEngineRestart() {
  JNIEnv* env = GetEnv();
  if (env == nullptr) {
    return;
  }
  auto java_object = java_object_.get(env);
  if (java_object.is_null() || g_on_engine_restart_method == nullptr) {
    return;
  }
  env->CallVoidMethod(java_object.obj(), g_on_engine_restart_method);
  fml::jni::CheckException(env);
}

void JvmInvoker::CreatePlatformView(int32_t view_id,
                                    const std::string& view_type,
                                    double width,
                                    double height,
                                    int32_t direction,
                                    const std::vector<uint8_t>& params) {}

void JvmInvoker::DisposePlatformView(int32_t view_id) {}
void JvmInvoker::OffsetPlatformView(int32_t view_id, double top, double left) {}
void JvmInvoker::ResizePlatformView(int32_t view_id,
                                    double width,
                                    double height) {}

namespace {

jobject BuildJavaMutatorsStack(JNIEnv* env,
                               const std::vector<int32_t>& mutators_types,
                               const std::vector<float>& mutators_matrices,
                               const std::vector<int32_t>& mutators_rects,
                               const std::vector<float>& mutators_rrects,
                               const std::vector<float>& mutators_opacities) {
  if (env == nullptr || env->functions == nullptr ||
      env->functions->NewFloatArray == nullptr ||
      env->functions->SetFloatArrayRegion == nullptr) {
    return nullptr;
  }
  bool owns_local_stack_cls = false;
  jclass stack_cls = g_mutators_stack_class;
  if (stack_cls == nullptr) {
    stack_cls = env->FindClass(
        "io/flutter/embedding/engine/mutatorsstack/FlutterMutatorsStack");
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
      stack_cls = nullptr;
    }
    if (stack_cls == nullptr) {
      return nullptr;
    }
    owns_local_stack_cls = true;
  }

  jmethodID ctor = g_mutators_stack_ctor_method;
  if (ctor == nullptr) {
    ctor = env->GetMethodID(stack_cls, "<init>", "()V");
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
      ctor = nullptr;
    }
  }
  jmethodID push_transform = g_mutators_stack_push_transform_method;
  if (push_transform == nullptr) {
    push_transform = env->GetMethodID(stack_cls, "pushTransform", "([F)V");
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
      push_transform = nullptr;
    }
  }
  jmethodID push_clip_rect = g_mutators_stack_push_clip_rect_method;
  if (push_clip_rect == nullptr) {
    push_clip_rect = env->GetMethodID(stack_cls, "pushClipRect", "(IIII)V");
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
      push_clip_rect = nullptr;
    }
  }
  jmethodID push_clip_rrect = g_mutators_stack_push_clip_rrect_method;
  if (push_clip_rrect == nullptr) {
    push_clip_rrect = env->GetMethodID(stack_cls, "pushClipRRect", "(IIII[F)V");
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
      push_clip_rrect = nullptr;
    }
  }
  jmethodID push_opacity = g_mutators_stack_push_opacity_method;
  if (push_opacity == nullptr) {
    push_opacity = env->GetMethodID(stack_cls, "pushOpacity", "(F)V");
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
      push_opacity = nullptr;
    }
  }
  if (ctor == nullptr) {
    if (owns_local_stack_cls) {
      env->DeleteLocalRef(stack_cls);
    }
    return nullptr;
  }

  jobject stack = env->NewObject(stack_cls, ctor);
  if (env->ExceptionCheck() || stack == nullptr) {
    env->ExceptionClear();
    if (owns_local_stack_cls) {
      env->DeleteLocalRef(stack_cls);
    }
    return nullptr;
  }

  size_t matrix_offset = 0;
  size_t rect_offset = 0;
  size_t rrect_offset = 0;
  size_t opacity_offset = 0;
  for (int32_t t : mutators_types) {
    if (t == kMutatorTypeClipRect || t == kMutatorTypeClipPath) {
      if (push_clip_rect != nullptr &&
          rect_offset + kMutatorRectCoordCount <= mutators_rects.size()) {
        env->CallVoidMethod(
            stack, push_clip_rect, mutators_rects[rect_offset + 0],
            mutators_rects[rect_offset + 1], mutators_rects[rect_offset + 2],
            mutators_rects[rect_offset + 3]);
        rect_offset += kMutatorRectCoordCount;
      } else if (t == kMutatorTypeClipRect && push_transform != nullptr &&
                 matrix_offset + kMutatorMatrixElementCount <=
                     mutators_matrices.size()) {
        jfloatArray arr = env->NewFloatArray(kMutatorMatrixElementCount);
        if (arr != nullptr) {
          env->SetFloatArrayRegion(arr, 0, kMutatorMatrixElementCount,
                                   &mutators_matrices[matrix_offset]);
          env->CallVoidMethod(stack, push_transform, arr);
          env->DeleteLocalRef(arr);
        }
        matrix_offset += kMutatorMatrixElementCount;
      }
    } else if (t == kMutatorTypeClipRRect) {
      if (push_clip_rrect != nullptr &&
          rrect_offset + kMutatorRRectFloatCount <= mutators_rrects.size()) {
        jint left =
            static_cast<jint>(std::round(mutators_rrects[rrect_offset + 0]));
        jint top =
            static_cast<jint>(std::round(mutators_rrects[rrect_offset + 1]));
        jint right =
            static_cast<jint>(std::round(mutators_rrects[rrect_offset + 2]));
        jint bottom =
            static_cast<jint>(std::round(mutators_rrects[rrect_offset + 3]));
        jfloatArray radii = env->NewFloatArray(kMutatorRRectRadiiCount);
        if (radii != nullptr) {
          env->SetFloatArrayRegion(
              radii, 0, kMutatorRRectRadiiCount,
              &mutators_rrects[rrect_offset + kMutatorRectCoordCount]);
          env->CallVoidMethod(stack, push_clip_rrect, left, top, right, bottom,
                              radii);
          env->DeleteLocalRef(radii);
        }
        rrect_offset += kMutatorRRectFloatCount;
      }
    } else if (t == kMutatorTypeTransform) {
      if (push_transform != nullptr &&
          matrix_offset + kMutatorMatrixElementCount <=
              mutators_matrices.size()) {
        jfloatArray arr = env->NewFloatArray(kMutatorMatrixElementCount);
        if (arr != nullptr) {
          env->SetFloatArrayRegion(arr, 0, kMutatorMatrixElementCount,
                                   &mutators_matrices[matrix_offset]);
          env->CallVoidMethod(stack, push_transform, arr);
          env->DeleteLocalRef(arr);
        }
        matrix_offset += kMutatorMatrixElementCount;
      }
    } else if (t == kMutatorTypeOpacity) {
      if (push_opacity != nullptr &&
          opacity_offset < mutators_opacities.size()) {
        env->CallVoidMethod(stack, push_opacity,
                            mutators_opacities[opacity_offset]);
        opacity_offset += 1;
      }
    }
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
    }
  }

  if (owns_local_stack_cls) {
    env->DeleteLocalRef(stack_cls);
  }
  return stack;
}

}  // namespace

void JvmInvoker::OnPlatformViewDisplay(
    int32_t view_id,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    int32_t original_width,
    int32_t original_height,
    int32_t mutators_count,
    const std::vector<int32_t>& mutators_types,
    const std::vector<float>& mutators_matrices,
    const std::vector<int32_t>& mutators_rects,
    const std::vector<float>& mutators_rrects,
    const std::vector<float>& mutators_opacities) {
  (void)mutators_count;
  JNIEnv* env = GetEnv();
  if (env == nullptr) {
    return;
  }
  auto java_object = java_object_.get(env);
  if (java_object.is_null() || g_on_display_platform_view_method == nullptr) {
    return;
  }
  jobject stack = (test_env_ == nullptr)
                      ? BuildJavaMutatorsStack(
                            env, mutators_types, mutators_matrices,
                            mutators_rects, mutators_rrects, mutators_opacities)
                      : nullptr;
  env->CallVoidMethod(java_object.obj(), g_on_display_platform_view_method,
                      view_id, x, y, width, height, original_width,
                      original_height, stack);
  if (stack != nullptr) {
    env->DeleteLocalRef(stack);
  }
  fml::jni::CheckException(env);
}

void JvmInvoker::OnDisplayPlatformView2(
    int32_t view_id,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    int32_t original_width,
    int32_t original_height,
    int32_t mutators_count,
    const std::vector<int32_t>& mutators_types,
    const std::vector<float>& mutators_matrices,
    const std::vector<int32_t>& mutators_rects,
    const std::vector<float>& mutators_rrects,
    const std::vector<float>& mutators_opacities) {
  (void)mutators_count;
  JNIEnv* env = GetEnv();
  if (env == nullptr) {
    return;
  }
  auto java_object = java_object_.get(env);
  if (java_object.is_null() || g_on_display_platform_view2_method == nullptr) {
    return;
  }
  jobject stack = (test_env_ == nullptr)
                      ? BuildJavaMutatorsStack(
                            env, mutators_types, mutators_matrices,
                            mutators_rects, mutators_rrects, mutators_opacities)
                      : nullptr;
  env->CallVoidMethod(java_object.obj(), g_on_display_platform_view2_method,
                      view_id, x, y, width, height, original_width,
                      original_height, stack);
  if (stack != nullptr) {
    env->DeleteLocalRef(stack);
  }
  fml::jni::CheckException(env);
}

void JvmInvoker::HidePlatformView2(int32_t view_id) {
  JNIEnv* env = GetEnv();
  if (env == nullptr) {
    return;
  }
  auto java_object = java_object_.get(env);
  if (java_object.is_null() || g_hide_platform_view2_method == nullptr) {
    return;
  }
  env->CallVoidMethod(java_object.obj(), g_hide_platform_view2_method, view_id);
  fml::jni::CheckException(env);
}

jobject JvmInvoker::CreateOverlaySurface() {
  JNIEnv* env = GetEnv();
  if (env == nullptr) {
    return nullptr;
  }
  auto java_object = java_object_.get(env);
  if (java_object.is_null() || g_create_overlay_surface_method == nullptr) {
    return nullptr;
  }
  jobject res =
      env->CallObjectMethod(java_object.obj(), g_create_overlay_surface_method);
  fml::jni::CheckException(env);
  return res;
}

jobject JvmInvoker::CreateOverlaySurface2() {
  JNIEnv* env = GetEnv();
  if (env == nullptr) {
    return nullptr;
  }
  auto java_object = java_object_.get(env);
  if (java_object.is_null() || g_create_overlay_surface2_method == nullptr) {
    return nullptr;
  }
  jobject res = env->CallObjectMethod(java_object.obj(),
                                      g_create_overlay_surface2_method);
  fml::jni::CheckException(env);
  return res;
}

void JvmInvoker::DestroyOverlaySurfaces() {
  JNIEnv* env = GetEnv();
  if (env == nullptr) {
    return;
  }
  auto java_object = java_object_.get(env);
  if (java_object.is_null() || g_destroy_overlay_surfaces_method == nullptr) {
    return;
  }
  env->CallVoidMethod(java_object.obj(), g_destroy_overlay_surfaces_method);
  fml::jni::CheckException(env);
}

void JvmInvoker::DestroyOverlaySurface2() {
  JNIEnv* env = GetEnv();
  if (env == nullptr) {
    return;
  }
  auto java_object = java_object_.get(env);
  if (java_object.is_null() || g_destroy_overlay_surface2_method == nullptr) {
    return;
  }
  env->CallVoidMethod(java_object.obj(), g_destroy_overlay_surface2_method);
  fml::jni::CheckException(env);
}

void JvmInvoker::ShowOverlaySurface2() {
  JNIEnv* env = GetEnv();
  if (env == nullptr) {
    return;
  }
  auto java_object = java_object_.get(env);
  if (java_object.is_null() || g_show_overlay_surface2_method == nullptr) {
    return;
  }
  env->CallVoidMethod(java_object.obj(), g_show_overlay_surface2_method);
  fml::jni::CheckException(env);
}

void JvmInvoker::HideOverlaySurface2() {
  JNIEnv* env = GetEnv();
  if (env == nullptr) {
    return;
  }
  auto java_object = java_object_.get(env);
  if (java_object.is_null() || g_hide_overlay_surface2_method == nullptr) {
    return;
  }
  env->CallVoidMethod(java_object.obj(), g_hide_overlay_surface2_method);
  fml::jni::CheckException(env);
}

void JvmInvoker::OnBeginFrame() {
  JNIEnv* env = GetEnv();
  if (env == nullptr) {
    return;
  }
  auto java_object = java_object_.get(env);
  if (java_object.is_null() || g_on_begin_frame_method == nullptr) {
    return;
  }
  env->CallVoidMethod(java_object.obj(), g_on_begin_frame_method);
  fml::jni::CheckException(env);
}

void JvmInvoker::OnEndFrame() {
  JNIEnv* env = GetEnv();
  if (env == nullptr) {
    return;
  }
  auto java_object = java_object_.get(env);
  if (java_object.is_null() || g_on_end_frame_method == nullptr) {
    return;
  }
  env->CallVoidMethod(java_object.obj(), g_on_end_frame_method);
  fml::jni::CheckException(env);
}

void JvmInvoker::EndFrame2() {
  JNIEnv* env = GetEnv();
  if (env == nullptr) {
    return;
  }
  auto java_object = java_object_.get(env);
  if (java_object.is_null() || g_end_frame2_method == nullptr) {
    return;
  }
  env->CallVoidMethod(java_object.obj(), g_end_frame2_method);
  fml::jni::CheckException(env);
}

double JvmInvoker::GetScaledFontSize(double unscaled_font_size,
                                     int32_t configuration_id) {
  constexpr double kUnsupportedFontScaleResult = -1.0;
  JNIEnv* env = GetEnv();
  if (env == nullptr) {
    return kUnsupportedFontScaleResult;
  }
  auto java_object = java_object_.get(env);
  if (java_object.is_null() || g_get_scaled_font_size_method == nullptr) {
    return kUnsupportedFontScaleResult;
  }
  jfloat res =
      env->CallFloatMethod(java_object.obj(), g_get_scaled_font_size_method,
                           static_cast<jfloat>(unscaled_font_size),
                           static_cast<jint>(configuration_id));
  if (!fml::jni::CheckException(env)) {
    return kUnsupportedFontScaleResult;
  }
  return static_cast<double>(res);
}

bool JvmInvoker::RequestDartDeferredLibrary(int32_t loading_unit_id) {
  JNIEnv* env = GetEnv();
  if (env == nullptr) {
    return false;
  }
  auto java_object = java_object_.get(env);
  if (java_object.is_null() ||
      g_request_dart_deferred_library_method == nullptr) {
    return false;
  }
  env->CallVoidMethod(java_object.obj(), g_request_dart_deferred_library_method,
                      static_cast<jint>(loading_unit_id));
  return fml::jni::CheckException(env);
}

namespace {

jobject UnwrapJavaReferenceIfNeeded(JNIEnv* env,
                                    jobject obj_or_ref,
                                    bool* out_is_local_ref) {
  if (out_is_local_ref) {
    *out_is_local_ref = false;
  }
  if (!env || !obj_or_ref || !env->functions || !env->functions->FindClass ||
      !env->functions->IsInstanceOf) {
    return obj_or_ref;
  }
  jclass ref_cls = env->FindClass("java/lang/ref/Reference");
  if (!ref_cls) {
    fml::jni::CheckException(env);
    return obj_or_ref;
  }
  jboolean is_ref = env->IsInstanceOf(obj_or_ref, ref_cls);
  if (!is_ref) {
    env->DeleteLocalRef(ref_cls);
    return obj_or_ref;
  }
  jmethodID get_mid = env->GetMethodID(ref_cls, "get", "()Ljava/lang/Object;");
  env->DeleteLocalRef(ref_cls);
  if (!get_mid) {
    fml::jni::CheckException(env);
    return nullptr;
  }
  jobject target = env->CallObjectMethod(obj_or_ref, get_mid);
  if (!fml::jni::CheckException(env) || !target) {
    return nullptr;
  }
  if (out_is_local_ref) {
    *out_is_local_ref = true;
  }
  return target;
}

}  // namespace

bool JvmInvoker::SurfaceTextureShouldUpdate(jobject surface_texture_wrapper) {
  if (test_env_ != nullptr || surface_texture_wrapper == nullptr) {
    return false;
  }
  JNIEnv* env = GetEnv();
  if (!env) {
    return false;
  }
  bool is_local = false;
  jobject target =
      UnwrapJavaReferenceIfNeeded(env, surface_texture_wrapper, &is_local);
  if (!target) {
    return false;
  }
  jclass cls = env->GetObjectClass(target);
  if (!cls) {
    if (is_local) {
      env->DeleteLocalRef(target);
    }
    fml::jni::CheckException(env);
    return false;
  }
  jmethodID mid = env->GetMethodID(cls, "shouldUpdate", "()Z");
  env->DeleteLocalRef(cls);
  if (!mid) {
    if (is_local) {
      env->DeleteLocalRef(target);
    }
    fml::jni::CheckException(env);
    return false;
  }
  jboolean res = env->CallBooleanMethod(target, mid);
  if (is_local) {
    env->DeleteLocalRef(target);
  }
  if (!fml::jni::CheckException(env)) {
    return false;
  }
  return res == JNI_TRUE;
}

void JvmInvoker::SurfaceTextureAttachToGLContext(
    jobject surface_texture_wrapper,
    int32_t texture_id) {
  if (test_env_ != nullptr || surface_texture_wrapper == nullptr) {
    return;
  }
  JNIEnv* env = GetEnv();
  if (!env) {
    return;
  }
  bool is_local = false;
  jobject target =
      UnwrapJavaReferenceIfNeeded(env, surface_texture_wrapper, &is_local);
  if (!target) {
    return;
  }
  jclass cls = env->GetObjectClass(target);
  if (!cls) {
    if (is_local) {
      env->DeleteLocalRef(target);
    }
    fml::jni::CheckException(env);
    return;
  }
  jmethodID mid = env->GetMethodID(cls, "attachToGLContext", "(I)V");
  env->DeleteLocalRef(cls);
  if (!mid) {
    if (is_local) {
      env->DeleteLocalRef(target);
    }
    fml::jni::CheckException(env);
    return;
  }
  env->CallVoidMethod(target, mid, static_cast<jint>(texture_id));
  if (is_local) {
    env->DeleteLocalRef(target);
  }
  fml::jni::CheckException(env);
}

void JvmInvoker::SurfaceTextureUpdateTexImage(jobject surface_texture_wrapper) {
  if (test_env_ != nullptr || surface_texture_wrapper == nullptr) {
    return;
  }
  JNIEnv* env = GetEnv();
  if (!env) {
    return;
  }
  bool is_local = false;
  jobject target =
      UnwrapJavaReferenceIfNeeded(env, surface_texture_wrapper, &is_local);
  if (!target) {
    return;
  }
  jclass cls = env->GetObjectClass(target);
  if (!cls) {
    if (is_local) {
      env->DeleteLocalRef(target);
    }
    fml::jni::CheckException(env);
    return;
  }
  jmethodID mid = env->GetMethodID(cls, "updateTexImage", "()V");
  env->DeleteLocalRef(cls);
  if (!mid) {
    if (is_local) {
      env->DeleteLocalRef(target);
    }
    fml::jni::CheckException(env);
    return;
  }
  env->CallVoidMethod(target, mid);
  if (is_local) {
    env->DeleteLocalRef(target);
  }
  fml::jni::CheckException(env);
}

void JvmInvoker::SurfaceTextureGetTransformMatrix(
    jobject surface_texture_wrapper,
    float transform_matrix[16]) {
  if (test_env_ != nullptr || surface_texture_wrapper == nullptr ||
      transform_matrix == nullptr) {
    return;
  }
  JNIEnv* env = GetEnv();
  if (!env || !env->functions || !env->functions->NewFloatArray) {
    return;
  }
  bool is_local = false;
  jobject target =
      UnwrapJavaReferenceIfNeeded(env, surface_texture_wrapper, &is_local);
  if (!target) {
    return;
  }
  jclass cls = env->GetObjectClass(target);
  if (!cls) {
    if (is_local) {
      env->DeleteLocalRef(target);
    }
    fml::jni::CheckException(env);
    return;
  }
  jmethodID mid = env->GetMethodID(cls, "getTransformMatrix", "([F)V");
  env->DeleteLocalRef(cls);
  if (!mid) {
    if (is_local) {
      env->DeleteLocalRef(target);
    }
    fml::jni::CheckException(env);
    return;
  }
  // 4x4 UV transform matrix element count (16 floats).
  constexpr jsize kTransformMatrixSize = 16;
  jfloatArray j_matrix = env->NewFloatArray(kTransformMatrixSize);
  if (!j_matrix) {
    if (is_local) {
      env->DeleteLocalRef(target);
    }
    fml::jni::CheckException(env);
    return;
  }
  env->CallVoidMethod(target, mid, j_matrix);
  if (is_local) {
    env->DeleteLocalRef(target);
  }
  if (fml::jni::CheckException(env)) {
    env->GetFloatArrayRegion(j_matrix, 0, kTransformMatrixSize,
                             transform_matrix);
  }
  env->DeleteLocalRef(j_matrix);
}

void JvmInvoker::SurfaceTextureDetachFromGLContext(
    jobject surface_texture_wrapper) {
  if (test_env_ != nullptr || surface_texture_wrapper == nullptr) {
    return;
  }
  JNIEnv* env = GetEnv();
  if (!env) {
    return;
  }
  bool is_local = false;
  jobject target =
      UnwrapJavaReferenceIfNeeded(env, surface_texture_wrapper, &is_local);
  if (!target) {
    return;
  }
  jclass cls = env->GetObjectClass(target);
  if (!cls) {
    if (is_local) {
      env->DeleteLocalRef(target);
    }
    fml::jni::CheckException(env);
    return;
  }
  jmethodID mid = env->GetMethodID(cls, "detachFromGLContext", "()V");
  env->DeleteLocalRef(cls);
  if (!mid) {
    if (is_local) {
      env->DeleteLocalRef(target);
    }
    fml::jni::CheckException(env);
    return;
  }
  env->CallVoidMethod(target, mid);
  if (is_local) {
    env->DeleteLocalRef(target);
  }
  fml::jni::CheckException(env);
}

jobject JvmInvoker::ImageTextureEntryAcquireLatestImage(
    jobject image_texture_entry) {
  if (test_env_ != nullptr || image_texture_entry == nullptr) {
    return nullptr;
  }
  JNIEnv* env = GetEnv();
  if (!env) {
    return nullptr;
  }
  bool is_local = false;
  jobject target =
      UnwrapJavaReferenceIfNeeded(env, image_texture_entry, &is_local);
  if (!target) {
    return nullptr;
  }
  jclass cls = env->GetObjectClass(target);
  if (!cls) {
    if (is_local) {
      env->DeleteLocalRef(target);
    }
    fml::jni::CheckException(env);
    return nullptr;
  }
  jmethodID mid =
      env->GetMethodID(cls, "acquireLatestImage", "()Landroid/media/Image;");
  env->DeleteLocalRef(cls);
  if (!mid) {
    if (is_local) {
      env->DeleteLocalRef(target);
    }
    fml::jni::CheckException(env);
    return nullptr;
  }
  jobject img = env->CallObjectMethod(target, mid);
  if (is_local) {
    env->DeleteLocalRef(target);
  }
  if (!fml::jni::CheckException(env)) {
    return nullptr;
  }
  return img;
}

jobject JvmInvoker::ImageGetHardwareBuffer(jobject image) {
  if (test_env_ != nullptr || image == nullptr) {
    return nullptr;
  }
  JNIEnv* env = GetEnv();
  if (!env) {
    return nullptr;
  }
  jclass cls = env->GetObjectClass(image);
  if (!cls) {
    fml::jni::CheckException(env);
    return nullptr;
  }
  jmethodID mid = env->GetMethodID(cls, "getHardwareBuffer",
                                   "()Landroid/hardware/HardwareBuffer;");
  env->DeleteLocalRef(cls);
  if (!mid) {
    fml::jni::CheckException(env);
    return nullptr;
  }
  jobject hb = env->CallObjectMethod(image, mid);
  if (!fml::jni::CheckException(env)) {
    return nullptr;
  }
  return hb;
}

void JvmInvoker::ImageClose(jobject image) {
  if (test_env_ != nullptr || image == nullptr) {
    return;
  }
  JNIEnv* env = GetEnv();
  if (!env) {
    return;
  }
  jclass cls = env->GetObjectClass(image);
  if (!cls) {
    fml::jni::CheckException(env);
    return;
  }
  jmethodID mid = env->GetMethodID(cls, "close", "()V");
  env->DeleteLocalRef(cls);
  if (!mid) {
    fml::jni::CheckException(env);
    return;
  }
  env->CallVoidMethod(image, mid);
  fml::jni::CheckException(env);
}

void JvmInvoker::HardwareBufferClose(jobject hardware_buffer) {
  if (test_env_ != nullptr || hardware_buffer == nullptr) {
    return;
  }
  JNIEnv* env = GetEnv();
  if (!env) {
    return;
  }
  jclass cls = env->GetObjectClass(hardware_buffer);
  if (!cls) {
    fml::jni::CheckException(env);
    return;
  }
  jmethodID mid = env->GetMethodID(cls, "close", "()V");
  env->DeleteLocalRef(cls);
  if (!mid) {
    fml::jni::CheckException(env);
    return;
  }
  env->CallVoidMethod(hardware_buffer, mid);
  fml::jni::CheckException(env);
}

// OSLibrary and OSLibraryLoader implementations.
DefaultOSLibrary::DefaultOSLibrary(void* handle) : handle_(handle) {}

DefaultOSLibrary::~DefaultOSLibrary() {
  if (handle_ != nullptr) {
    dlclose(handle_);
    handle_ = nullptr;
  }
}

void* DefaultOSLibrary::ResolveSymbol(const char* symbol_name) {
  if (handle_ == nullptr || symbol_name == nullptr) {
    return nullptr;
  }
  return dlsym(handle_, symbol_name);
}

std::unique_ptr<OSLibrary> DefaultOSLibraryLoader::Load(
    const std::string& library_name) {
  void* handle = dlopen(library_name.c_str(), RTLD_NOW | RTLD_LOCAL);
  if (handle == nullptr) {
    return nullptr;
  }
  return std::make_unique<DefaultOSLibrary>(handle);
}

void MockOSLibrary::RegisterSymbol(const std::string& symbol_name,
                                   void* address) {
  symbols_[symbol_name] = address;
}

void* MockOSLibrary::ResolveSymbol(const char* symbol_name) {
  if (symbol_name == nullptr) {
    return nullptr;
  }
  auto it = symbols_.find(symbol_name);
  if (it != symbols_.end()) {
    return it->second;
  }
  return nullptr;
}

void MockOSLibraryLoader::RegisterLibrary(
    const std::string& library_name,
    std::shared_ptr<MockOSLibrary> library) {
  libraries_[library_name] = std::move(library);
}

std::unique_ptr<OSLibrary> MockOSLibraryLoader::Load(
    const std::string& library_name) {
  auto it = libraries_.find(library_name);
  if (it != libraries_.end() && it->second != nullptr) {
    return std::make_unique<DynamicMockHandle>(it->second);
  }
  return nullptr;
}

// Vulkan eligibility and device owner implementations.
DeviceProperties ReadDeviceProperties(PropertyReader reader) {
  PropertyReader prop_reader = std::move(reader);
  if (!prop_reader) {
    prop_reader = [](const char* key) -> std::string {
#if FML_OS_ANDROID
      char value[PROP_VALUE_MAX] = {0};
      if (__system_property_get(key, value) > 0) {
        return std::string(value);
      }
#endif
      return "";
    };
  }

  DeviceProperties props;
  std::string sdk_str = prop_reader("ro.build.version.sdk");
  if (!sdk_str.empty()) {
    props.api_level = std::atoi(sdk_str.c_str());
  }
  props.hardware = prop_reader("ro.hardware");
  props.manufacturer = prop_reader("ro.product.manufacturer");
  props.model = prop_reader("ro.product.model");
  return props;
}

VulkanIneligibleReason CheckVulkanEligibility(const DeviceProperties& props) {
  if (!props.impeller_enabled) {
    return VulkanIneligibleReason::kImpellerDisabled;
  }
  if (props.force_opengles) {
    return VulkanIneligibleReason::kForceOpenGLES;
  }
  if (props.api_level < kMinVulkanApiLevel) {
    return VulkanIneligibleReason::kApiLevelTooLow;
  }
  if (props.vulkan_api_version < kMinVulkanApiVersion) {
    return VulkanIneligibleReason::kNoVulkanHardware;
  }
  if (!props.has_external_memory_android_hardware_buffer ||
      !props.has_semaphore_fd) {
    return VulkanIneligibleReason::kExtensionMissing;
  }
  if (props.gpu_renderer.find("Adreno (TM) 5") != std::string::npos ||
      props.gpu_renderer.find("Mali-T") != std::string::npos ||
      props.gpu_renderer.find("PowerVR Rogue") != std::string::npos ||
      props.hardware == "goldfish" || props.hardware == "ranchu") {
    if (props.gpu_driver_version.find("BadDriver") != std::string::npos ||
        props.gpu_renderer.find("Adreno (TM) 5") != std::string::npos ||
        props.gpu_renderer.find("Mali-T") != std::string::npos) {
      return VulkanIneligibleReason::kKnownBadGpuDriver;
    }
  }
  return VulkanIneligibleReason::kEligible;
}

const char* VulkanIneligibleReasonToString(VulkanIneligibleReason reason) {
  switch (reason) {
    case VulkanIneligibleReason::kEligible:
      return "Eligible";
    case VulkanIneligibleReason::kApiLevelTooLow:
      return "API level too low (< 29)";
    case VulkanIneligibleReason::kNoVulkanHardware:
      return "Vulkan 1.1+ hardware not supported";
    case VulkanIneligibleReason::kKnownBadGpuDriver:
      return "Known bad GPU driver on blocklist";
    case VulkanIneligibleReason::kExtensionMissing:
      return "Required Vulkan external memory/semaphore extensions missing";
    case VulkanIneligibleReason::kImpellerDisabled:
      return "Impeller disabled by manifest/flag";
    case VulkanIneligibleReason::kForceOpenGLES:
      return "Forced fallback to OpenGLES";
  }
  return "Unknown";
}

std::unique_ptr<VulkanDeviceOwner> VulkanDeviceOwner::Create(
    const Config& config,
    std::optional<MockDriverCallbacks> mock_callbacks) {
  auto owner = std::unique_ptr<VulkanDeviceOwner>(
      new VulkanDeviceOwner(config, std::move(mock_callbacks)));
  if (!owner->IsValid()) {
    return nullptr;
  }
  return owner;
}

VulkanDeviceOwner::VulkanDeviceOwner(
    const Config& config,
    std::optional<MockDriverCallbacks> mock_callbacks)
    : mock_callbacks_(std::move(mock_callbacks)) {
  is_valid_ = Initialize(config);
}

VulkanDeviceOwner::~VulkanDeviceOwner() {
  if (is_valid_) {
    if (mock_callbacks_.has_value() && mock_callbacks_->destroy_fn) {
      mock_callbacks_->destroy_fn(instance_, device_);
    }
    instance_ = nullptr;
    physical_device_ = nullptr;
    device_ = nullptr;
    queue_ = nullptr;
    is_valid_ = false;
  }
}

bool VulkanDeviceOwner::Initialize(const Config& config) {
  if (mock_callbacks_.has_value() && mock_callbacks_->initialize_fn) {
    return mock_callbacks_->initialize_fn(config, &instance_, &physical_device_,
                                          &device_, &queue_,
                                          &queue_family_index_);
  }
  instance_ = reinterpret_cast<VkInstanceHandle>(kSyntheticInstanceAddress);
  physical_device_ =
      reinterpret_cast<VkPhysicalDeviceHandle>(kSyntheticPhysicalDeviceAddress);
  device_ = reinterpret_cast<VkDeviceHandle>(kSyntheticDeviceAddress);
  queue_ = reinterpret_cast<VkQueueHandle>(kSyntheticQueueAddress);
  queue_family_index_ = 0;
  return true;
}

void* VulkanDeviceOwner::GetInstanceProcAddr(const char* name) const {
  if (!is_valid_ || !name) {
    return nullptr;
  }
  if (mock_callbacks_.has_value() && mock_callbacks_->get_instance_proc_addr) {
    return mock_callbacks_->get_instance_proc_addr(instance_, name);
  }
  return nullptr;
}

void* VulkanDeviceOwner::GetDeviceProcAddr(const char* name) const {
  if (!is_valid_ || !name) {
    return nullptr;
  }
  if (mock_callbacks_.has_value() && mock_callbacks_->get_device_proc_addr) {
    return mock_callbacks_->get_device_proc_addr(device_, name);
  }
  return nullptr;
}

}  // namespace flutter
