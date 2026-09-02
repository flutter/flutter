// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/jvm_invoker.h"

#include <cstring>
#include "flutter/fml/logging.h"
#include "flutter/fml/platform/android/jni_util.h"
#include "flutter/fml/trace_event.h"

namespace flutter {
namespace android {

DefaultJvmInvoker::DefaultJvmInvoker() : attached_(true) {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::DefaultJvmInvoker");
}

DefaultJvmInvoker::DefaultJvmInvoker(JNIEnv* env, jobject java_object)
    : attached_(true) {
  TRACE_EVENT0("flutter",
               "DefaultJvmInvoker::DefaultJvmInvoker(with java_object)");
  if (env && java_object) {
    java_object_ = std::make_unique<fml::jni::ScopedJavaGlobalRef<jobject>>(
        env, java_object);
  }
}

DefaultJvmInvoker::~DefaultJvmInvoker() {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::~DefaultJvmInvoker");
}

bool DefaultJvmInvoker::EnsureAttachedToThread() {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::EnsureAttachedToThread");
  attached_ = true;
  return true;
}

void DefaultJvmInvoker::DetachFromThread() {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::DetachFromThread");
  attached_ = false;
}

bool DefaultJvmInvoker::HasPendingException() const {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::HasPendingException");
  return pending_exception_;
}

void DefaultJvmInvoker::ClearPendingException() {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::ClearPendingException");
  pending_exception_ = false;
}

bool DefaultJvmInvoker::InvokeVoidMethod(const std::string& method_name,
                                         const std::string& signature,
                                         const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::InvokeVoidMethod", "method",
               method_name.c_str());
  if (pending_exception_) {
    FML_LOG(WARNING) << "Ignoring InvokeVoidMethod on " << method_name
                     << " due to pending JVM exception.";
    return false;
  }
  if (java_object_ && !java_object_->is_null()) {
    JNIEnv* env = fml::jni::AttachCurrentThread();
    if (env && env->functions && env->functions->GetObjectClass &&
        env->functions->GetMethodID && env->functions->CallVoidMethod) {
      jclass clazz = env->GetObjectClass(java_object_->obj());
      if (clazz) {
        jmethodID mid =
            env->GetMethodID(clazz, method_name.c_str(), signature.c_str());
        if (mid) {
          if (signature == "()V") {
            env->CallVoidMethod(java_object_->obj(), mid);
          } else if (signature == "(Z)V" && !payload.empty()) {
            env->CallVoidMethod(java_object_->obj(), mid,
                                static_cast<jboolean>(payload[0] != 0));
          } else if (signature == "(I)V" && payload.size() >= sizeof(int32_t)) {
            int32_t val = 0;
            std::memcpy(&val, payload.data(), sizeof(int32_t));
            env->CallVoidMethod(java_object_->obj(), mid,
                                static_cast<jint>(val));
          } else if (signature == "(II)V" &&
                     payload.size() >= 2 * sizeof(int32_t)) {
            int32_t val1 = 0;
            int32_t val2 = 0;
            std::memcpy(&val1, payload.data(), sizeof(int32_t));
            std::memcpy(&val2, payload.data() + sizeof(int32_t),
                        sizeof(int32_t));
            env->CallVoidMethod(java_object_->obj(), mid,
                                static_cast<jint>(val1),
                                static_cast<jint>(val2));
          } else if (signature == "(IDD)V" &&
                     payload.size() >= (sizeof(int32_t) + 2 * sizeof(double))) {
            int32_t val_i = 0;
            double val_d1 = 0.0;
            double val_d2 = 0.0;
            std::memcpy(&val_i, payload.data(), sizeof(int32_t));
            std::memcpy(&val_d1, payload.data() + sizeof(int32_t),
                        sizeof(double));
            std::memcpy(&val_d2,
                        payload.data() + sizeof(int32_t) + sizeof(double),
                        sizeof(double));
            env->CallVoidMethod(
                java_object_->obj(), mid, static_cast<jint>(val_i),
                static_cast<jdouble>(val_d1), static_cast<jdouble>(val_d2));
          }
          if (fml::jni::HasException(env)) {
            fml::jni::ClearException(env);
            return false;
          }
          return true;
        }
        if (fml::jni::HasException(env)) {
          fml::jni::ClearException(env);
        }
      }
    }
  }
  return true;
}

bool DefaultJvmInvoker::HandlePlatformMessage(
    const std::string& channel,
    const std::vector<uint8_t>& message,
    int32_t response_id,
    bool has_data) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::HandlePlatformMessage", "channel",
               channel.c_str());
  if (java_object_ && !java_object_->is_null()) {
    JNIEnv* env = fml::jni::AttachCurrentThread();
    if (env && env->functions && env->functions->GetObjectClass &&
        env->functions->GetMethodID && env->functions->CallVoidMethod &&
        env->functions->NewStringUTF) {
      jclass clazz = env->GetObjectClass(java_object_->obj());
      if (clazz) {
        jmethodID mid =
            env->GetMethodID(clazz, "handlePlatformMessage",
                             "(Ljava/lang/String;Ljava/nio/ByteBuffer;IJ)V");
        if (mid) {
          jstring jchannel = env->NewStringUTF(channel.c_str());
          jobject jbuffer = nullptr;
          void* raw_data = nullptr;
          if (has_data && env->functions->NewDirectByteBuffer) {
            size_t alloc_size = message.empty() ? 1 : message.size();
            raw_data = malloc(alloc_size);
            if (raw_data != nullptr) {
              if (!message.empty()) {
                std::memcpy(raw_data, message.data(), message.size());
              }
              jbuffer = env->NewDirectByteBuffer(raw_data, message.size());
            }
          }
          env->CallVoidMethod(java_object_->obj(), mid, jchannel, jbuffer,
                              static_cast<jint>(response_id),
                              reinterpret_cast<jlong>(raw_data));
          if (jchannel && env->functions->DeleteLocalRef) {
            env->DeleteLocalRef(jchannel);
          }
          if (jbuffer && env->functions->DeleteLocalRef) {
            env->DeleteLocalRef(jbuffer);
          }
          if (fml::jni::HasException(env)) {
            fml::jni::ClearException(env);
            return false;
          }
          return true;
        }
        if (fml::jni::HasException(env)) {
          fml::jni::ClearException(env);
        }
      }
    }
  }
  return true;
}

bool DefaultJvmInvoker::HandlePlatformMessageResponse(
    int32_t response_id,
    const std::vector<uint8_t>& data,
    bool has_data) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::HandlePlatformMessageResponse",
               "response_id", std::to_string(response_id).c_str());
  if (java_object_ && !java_object_->is_null()) {
    JNIEnv* env = fml::jni::AttachCurrentThread();
    if (env && env->functions && env->functions->GetObjectClass &&
        env->functions->GetMethodID && env->functions->CallVoidMethod) {
      jclass clazz = env->GetObjectClass(java_object_->obj());
      if (clazz) {
        jmethodID mid = env->GetMethodID(clazz, "handlePlatformMessageResponse",
                                         "(ILjava/nio/ByteBuffer;)V");
        if (mid) {
          jobject jbuffer = nullptr;
          uint8_t dummy = 0;
          if (has_data && env->functions->NewDirectByteBuffer) {
            void* buffer_ptr =
                data.empty() ? &dummy : const_cast<uint8_t*>(data.data());
            jbuffer = env->NewDirectByteBuffer(buffer_ptr, data.size());
          }
          env->CallVoidMethod(java_object_->obj(), mid,
                              static_cast<jint>(response_id), jbuffer);
          if (jbuffer && env->functions->DeleteLocalRef) {
            env->DeleteLocalRef(jbuffer);
          }
          if (fml::jni::HasException(env)) {
            fml::jni::ClearException(env);
            return false;
          }
          return true;
        }
        if (fml::jni::HasException(env)) {
          fml::jni::ClearException(env);
        }
      }
    }
  }
  return true;
}

bool DefaultJvmInvoker::InvokeBooleanMethod(
    const std::string& method_name,
    const std::string& signature,
    const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::InvokeBooleanMethod", "method",
               method_name.c_str());
  if (pending_exception_) {
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
  if (pending_exception_) {
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
  if (pending_exception_) {
    return 0.0;
  }
  return 0.0;
}

double DefaultJvmInvoker::GetScaledFontSize(double unscaled_font_size,
                                            int configuration_id) {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::GetScaledFontSize");
  if (java_object_ && !java_object_->is_null()) {
    JNIEnv* env = fml::jni::AttachCurrentThread();
    if (env && env->functions && env->functions->GetObjectClass &&
        env->functions->GetMethodID && env->functions->CallFloatMethod) {
      jclass clazz = env->GetObjectClass(java_object_->obj());
      if (clazz) {
        jmethodID mid = env->GetMethodID(clazz, "getScaledFontSize", "(FI)F");
        if (mid) {
          jfloat result = env->CallFloatMethod(
              java_object_->obj(), mid, static_cast<jfloat>(unscaled_font_size),
              static_cast<jint>(configuration_id));
          if (fml::jni::HasException(env)) {
            fml::jni::ClearException(env);
            return -1.0;
          }
          return static_cast<double>(result);
        }
        if (fml::jni::HasException(env)) {
          fml::jni::ClearException(env);
        }
      }
    }
  }
  return unscaled_font_size;
}

std::string DefaultJvmInvoker::InvokeStringMethod(
    const std::string& method_name,
    const std::string& signature,
    const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::InvokeStringMethod", "method",
               method_name.c_str());
  if (pending_exception_) {
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
  if (pending_exception_) {
    return {};
  }
  return {};
}

bool DefaultJvmInvoker::PostJvmTask(std::function<void()> task) {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::PostJvmTask");
  if (task) {
    task();
    return true;
  }
  return false;
}

bool DefaultJvmInvoker::UpdateSemantics(
    const std::vector<uint8_t>& buffer,
    const std::vector<std::string>& strings,
    const std::vector<std::vector<uint8_t>>& string_attribute_args) {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::UpdateSemantics");
  if (java_object_ && !java_object_->is_null()) {
    JNIEnv* env = fml::jni::AttachCurrentThread();
    if (env && env->functions && env->functions->GetObjectClass &&
        env->functions->GetMethodID && env->functions->CallVoidMethod &&
        env->functions->NewDirectByteBuffer) {
      jclass clazz = env->GetObjectClass(java_object_->obj());
      if (clazz) {
        jmethodID mid = env->GetMethodID(clazz, "updateSemantics",
                                         "(Ljava/nio/ByteBuffer;[Ljava/lang/"
                                         "String;[Ljava/nio/ByteBuffer;)V");
        if (mid) {
          uint8_t dummy = 0;
          void* buffer_ptr =
              buffer.empty() ? &dummy : const_cast<uint8_t*>(buffer.data());
          fml::jni::ScopedJavaLocalRef<jobject> direct_buffer(
              env, env->NewDirectByteBuffer(buffer_ptr, buffer.size()));
          fml::jni::ScopedJavaLocalRef<jobjectArray> jstrings =
              fml::jni::VectorToStringArray(env, strings);
          fml::jni::ScopedJavaLocalRef<jobjectArray> jstring_attribute_args =
              fml::jni::VectorToBufferArray(env, string_attribute_args);

          env->CallVoidMethod(java_object_->obj(), mid, direct_buffer.obj(),
                              jstrings.obj(), jstring_attribute_args.obj());
          if (fml::jni::HasException(env)) {
            fml::jni::ClearException(env);
            return false;
          }
          return true;
        }
        if (fml::jni::HasException(env)) {
          fml::jni::ClearException(env);
        }
      }
    }
  }
  return true;
}

bool DefaultJvmInvoker::UpdateCustomAccessibilityActions(
    const std::vector<uint8_t>& actions_buffer,
    const std::vector<std::string>& action_strings) {
  TRACE_EVENT0("flutter",
               "DefaultJvmInvoker::UpdateCustomAccessibilityActions");
  if (java_object_ && !java_object_->is_null()) {
    JNIEnv* env = fml::jni::AttachCurrentThread();
    if (env && env->functions && env->functions->GetObjectClass &&
        env->functions->GetMethodID && env->functions->CallVoidMethod &&
        env->functions->NewDirectByteBuffer) {
      jclass clazz = env->GetObjectClass(java_object_->obj());
      if (clazz) {
        jmethodID mid =
            env->GetMethodID(clazz, "updateCustomAccessibilityActions",
                             "(Ljava/nio/ByteBuffer;[Ljava/lang/String;)V");
        if (mid) {
          uint8_t dummy = 0;
          void* buffer_ptr = actions_buffer.empty()
                                 ? &dummy
                                 : const_cast<uint8_t*>(actions_buffer.data());
          fml::jni::ScopedJavaLocalRef<jobject> direct_actions_buffer(
              env, env->NewDirectByteBuffer(buffer_ptr, actions_buffer.size()));
          fml::jni::ScopedJavaLocalRef<jobjectArray> jstrings =
              fml::jni::VectorToStringArray(env, action_strings);

          env->CallVoidMethod(java_object_->obj(), mid,
                              direct_actions_buffer.obj(), jstrings.obj());
          if (fml::jni::HasException(env)) {
            fml::jni::ClearException(env);
            return false;
          }
          return true;
        }
        if (fml::jni::HasException(env)) {
          fml::jni::ClearException(env);
        }
      }
    }
  }
  return true;
}

bool DefaultJvmInvoker::SetSemanticsTreeEnabled(bool enabled) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::SetSemanticsTreeEnabled",
               "enabled", enabled ? "true" : "false");
  if (java_object_ && !java_object_->is_null()) {
    JNIEnv* env = fml::jni::AttachCurrentThread();
    if (env && env->functions && env->functions->GetObjectClass &&
        env->functions->GetMethodID && env->functions->CallVoidMethod) {
      jclass clazz = env->GetObjectClass(java_object_->obj());
      if (clazz) {
        jmethodID mid =
            env->GetMethodID(clazz, "setSemanticsTreeEnabled", "(Z)V");
        if (mid) {
          env->CallVoidMethod(java_object_->obj(), mid,
                              static_cast<jboolean>(enabled));
          if (fml::jni::HasException(env)) {
            fml::jni::ClearException(env);
            return false;
          }
          return true;
        }
        if (fml::jni::HasException(env)) {
          fml::jni::ClearException(env);
        }
      }
    }
  }
  return true;
}

bool DefaultJvmInvoker::SetApplicationLocale(const std::string& locale) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::SetApplicationLocale", "locale",
               locale.c_str());
  if (java_object_ && !java_object_->is_null()) {
    JNIEnv* env = fml::jni::AttachCurrentThread();
    if (env && env->functions && env->functions->GetObjectClass &&
        env->functions->GetMethodID && env->functions->CallVoidMethod &&
        env->functions->NewStringUTF) {
      jclass clazz = env->GetObjectClass(java_object_->obj());
      if (clazz) {
        jmethodID mid = env->GetMethodID(clazz, "setApplicationLocale",
                                         "(Ljava/lang/String;)V");
        if (mid) {
          fml::jni::ScopedJavaLocalRef<jstring> jlocale =
              fml::jni::StringToJavaString(env, locale);
          env->CallVoidMethod(java_object_->obj(), mid, jlocale.obj());
          if (fml::jni::HasException(env)) {
            fml::jni::ClearException(env);
            return false;
          }
          return true;
        }
        if (fml::jni::HasException(env)) {
          fml::jni::ClearException(env);
        }
      }
    }
  }
  return true;
}

bool DefaultJvmInvoker::OnDisplayPlatformView(
    int64_t view_id,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    int32_t view_width,
    int32_t view_height,
    const AndroidMutatorsStack& mutators_stack,
    bool hcpp_enabled) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::OnDisplayPlatformView", "view_id",
               std::to_string(view_id).c_str());
  if (java_object_ && !java_object_->is_null()) {
    JNIEnv* env = fml::jni::AttachCurrentThread();
    if (!env || !env->functions || !env->functions->GetObjectClass ||
        !env->functions->GetMethodID || !env->functions->CallVoidMethod ||
        !env->functions->FindClass || !env->functions->NewObject) {
      return false;
    }

    fml::jni::ScopedJavaLocalFrame local_frame(
        env, 32 + 2 * static_cast<int>(mutators_stack.GetMutatorsCount()));

    jclass clazz = env->GetObjectClass(java_object_->obj());
    if (!clazz) {
      if (fml::jni::HasException(env)) {
        fml::jni::ClearException(env);
      }
      return false;
    }

    const char* method_name =
        hcpp_enabled ? "onDisplayPlatformView2" : "onDisplayPlatformView";
    const char* signature =
        "(IIIIIIILio/flutter/embedding/engine/mutatorsstack/"
        "FlutterMutatorsStack;)V";
    jmethodID mid = env->GetMethodID(clazz, method_name, signature);
    if (!mid) {
      if (fml::jni::HasException(env)) {
        fml::jni::ClearException(env);
      }
      return false;
    }

    jclass stack_class = env->FindClass(
        "io/flutter/embedding/engine/mutatorsstack/FlutterMutatorsStack");
    if (!stack_class) {
      if (fml::jni::HasException(env)) {
        fml::jni::ClearException(env);
      }
      return false;
    }

    jmethodID stack_ctor = env->GetMethodID(stack_class, "<init>", "()V");
    if (!stack_ctor) {
      if (fml::jni::HasException(env)) {
        fml::jni::ClearException(env);
      }
      return false;
    }

    jobject stack_obj = env->NewObject(stack_class, stack_ctor);
    if (!stack_obj) {
      if (fml::jni::HasException(env)) {
        fml::jni::ClearException(env);
      }
      return false;
    }

    jmethodID push_transform_mid =
        env->GetMethodID(stack_class, "pushTransform", "([F)V");
    jmethodID push_clip_rect_mid =
        env->GetMethodID(stack_class, "pushClipRect", "(FFFF)V");
    jmethodID push_clip_rrect_mid =
        env->GetMethodID(stack_class, "pushClipRRect", "(FFFF[F)V");
    jmethodID push_opacity_mid =
        env->GetMethodID(stack_class, "pushOpacity", "(F)V");

    for (const auto& mutator : mutators_stack.GetMutators()) {
      switch (mutator.type) {
        case AndroidMutatorType::kTransform: {
          if (push_transform_mid && env->functions->NewFloatArray &&
              env->functions->SetFloatArrayRegion) {
            jfloatArray matrix_array = env->NewFloatArray(9);
            if (matrix_array) {
              env->SetFloatArrayRegion(matrix_array, 0, 9,
                                       mutator.matrix.values);
              env->CallVoidMethod(stack_obj, push_transform_mid, matrix_array);
              if (env->functions->DeleteLocalRef) {
                env->DeleteLocalRef(matrix_array);
              }
            }
          }
          break;
        }
        case AndroidMutatorType::kClipRect: {
          if (push_clip_rect_mid) {
            env->CallVoidMethod(stack_obj, push_clip_rect_mid,
                                static_cast<jfloat>(mutator.rect.left),
                                static_cast<jfloat>(mutator.rect.top),
                                static_cast<jfloat>(mutator.rect.right),
                                static_cast<jfloat>(mutator.rect.bottom));
          }
          break;
        }
        case AndroidMutatorType::kClipRRect: {
          if (push_clip_rrect_mid && env->functions->NewFloatArray &&
              env->functions->SetFloatArrayRegion) {
            jfloatArray radii_array = env->NewFloatArray(8);
            if (radii_array) {
              env->SetFloatArrayRegion(radii_array, 0, 8, mutator.rrect.radii);
              env->CallVoidMethod(
                  stack_obj, push_clip_rrect_mid,
                  static_cast<jfloat>(mutator.rrect.rect.left),
                  static_cast<jfloat>(mutator.rrect.rect.top),
                  static_cast<jfloat>(mutator.rrect.rect.right),
                  static_cast<jfloat>(mutator.rrect.rect.bottom), radii_array);
              if (env->functions->DeleteLocalRef) {
                env->DeleteLocalRef(radii_array);
              }
            }
          }
          break;
        }
        case AndroidMutatorType::kOpacity: {
          if (push_opacity_mid) {
            env->CallVoidMethod(stack_obj, push_opacity_mid,
                                static_cast<jfloat>(mutator.opacity));
          }
          break;
        }
      }
      if (fml::jni::HasException(env)) {
        fml::jni::ClearException(env);
        return false;
      }
    }

    env->CallVoidMethod(java_object_->obj(), mid, static_cast<jint>(view_id),
                        static_cast<jint>(x), static_cast<jint>(y),
                        static_cast<jint>(width), static_cast<jint>(height),
                        static_cast<jint>(view_width),
                        static_cast<jint>(view_height), stack_obj);

    if (fml::jni::HasException(env)) {
      fml::jni::ClearException(env);
      return false;
    }
    return true;
  }
  return true;
}

std::optional<int32_t> DefaultJvmInvoker::CreateOverlaySurface(
    bool hcpp_enabled) {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::CreateOverlaySurface");
  if (java_object_ && !java_object_->is_null()) {
    JNIEnv* env = fml::jni::AttachCurrentThread();
    if (!env || !env->functions || !env->functions->GetObjectClass ||
        !env->functions->GetMethodID || !env->functions->CallObjectMethod) {
      return std::nullopt;
    }
    fml::jni::ScopedJavaLocalFrame local_frame(env, 16);
    jclass clazz = env->GetObjectClass(java_object_->obj());
    if (!clazz) {
      if (fml::jni::HasException(env)) {
        fml::jni::ClearException(env);
      }
      return std::nullopt;
    }
    const char* method_name =
        hcpp_enabled ? "createOverlaySurface2" : "createOverlaySurface";
    const char* signature =
        "()Lio/flutter/embedding/engine/FlutterOverlaySurface;";
    jmethodID mid = env->GetMethodID(clazz, method_name, signature);
    if (!mid) {
      if (fml::jni::HasException(env)) {
        fml::jni::ClearException(env);
      }
      return std::nullopt;
    }
    jobject overlay_obj = env->CallObjectMethod(java_object_->obj(), mid);
    if (!overlay_obj) {
      if (fml::jni::HasException(env)) {
        fml::jni::ClearException(env);
      }
      return std::nullopt;
    }
    jclass overlay_class = env->GetObjectClass(overlay_obj);
    if (!overlay_class) {
      if (fml::jni::HasException(env)) {
        fml::jni::ClearException(env);
      }
      return std::nullopt;
    }
    jmethodID get_id_mid = env->GetMethodID(overlay_class, "getId", "()I");
    if (!get_id_mid || !env->functions->CallIntMethod) {
      if (fml::jni::HasException(env)) {
        fml::jni::ClearException(env);
      }
      return std::nullopt;
    }
    jint id = env->CallIntMethod(overlay_obj, get_id_mid);
    if (fml::jni::HasException(env)) {
      fml::jni::ClearException(env);
      return std::nullopt;
    }
    return static_cast<int32_t>(id);
  }
  return std::nullopt;
}

bool DefaultJvmInvoker::OnDisplayOverlaySurface(int32_t surface_id,
                                                int32_t x,
                                                int32_t y,
                                                int32_t width,
                                                int32_t height) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::OnDisplayOverlaySurface",
               "surface_id", std::to_string(surface_id).c_str());
  if (java_object_ && !java_object_->is_null()) {
    JNIEnv* env = fml::jni::AttachCurrentThread();
    if (!env || !env->functions || !env->functions->GetObjectClass ||
        !env->functions->GetMethodID || !env->functions->CallVoidMethod) {
      return false;
    }
    fml::jni::ScopedJavaLocalFrame local_frame(env, 16);
    jclass clazz = env->GetObjectClass(java_object_->obj());
    if (!clazz) {
      if (fml::jni::HasException(env)) {
        fml::jni::ClearException(env);
      }
      return false;
    }
    jmethodID mid =
        env->GetMethodID(clazz, "onDisplayOverlaySurface", "(IIIII)V");
    if (!mid) {
      if (fml::jni::HasException(env)) {
        fml::jni::ClearException(env);
      }
      return false;
    }
    env->CallVoidMethod(java_object_->obj(), mid, static_cast<jint>(surface_id),
                        static_cast<jint>(x), static_cast<jint>(y),
                        static_cast<jint>(width), static_cast<jint>(height));
    if (fml::jni::HasException(env)) {
      fml::jni::ClearException(env);
      return false;
    }
    return true;
  }
  return true;
}

bool DefaultJvmInvoker::CreateTransaction() {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::CreateTransaction");
  if (java_object_ && !java_object_->is_null()) {
    JNIEnv* env = fml::jni::AttachCurrentThread();
    if (!env || !env->functions || !env->functions->GetObjectClass ||
        !env->functions->GetMethodID || !env->functions->CallObjectMethod) {
      return false;
    }
    fml::jni::ScopedJavaLocalFrame local_frame(env, 16);
    jclass clazz = env->GetObjectClass(java_object_->obj());
    if (!clazz) {
      if (fml::jni::HasException(env)) {
        fml::jni::ClearException(env);
      }
      return false;
    }
    jmethodID mid =
        env->GetMethodID(clazz, "createTransaction",
                         "()Landroid/view/SurfaceControl$Transaction;");
    if (!mid) {
      if (fml::jni::HasException(env)) {
        fml::jni::ClearException(env);
      }
      return false;
    }
    jobject tx_obj = env->CallObjectMethod(java_object_->obj(), mid);
    if (fml::jni::HasException(env)) {
      fml::jni::ClearException(env);
      return false;
    }
    return tx_obj != nullptr;
  }
  return true;
}

bool DefaultJvmInvoker::ResizePlatformView(int64_t view_id,
                                           double width,
                                           double height) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::ResizePlatformView", "view_id",
               std::to_string(view_id).c_str());
  if (java_object_ && !java_object_->is_null()) {
    JNIEnv* env = fml::jni::AttachCurrentThread();
    if (!env || !env->functions || !env->functions->GetObjectClass ||
        !env->functions->GetMethodID || !env->functions->CallVoidMethod) {
      return false;
    }
    fml::jni::ScopedJavaLocalFrame local_frame(env, 16);
    jclass clazz = env->GetObjectClass(java_object_->obj());
    if (!clazz) {
      if (fml::jni::HasException(env)) {
        fml::jni::ClearException(env);
      }
      return false;
    }
    jmethodID mid = env->GetMethodID(clazz, "resizePlatformView", "(IDD)V");
    if (!mid) {
      if (fml::jni::HasException(env)) {
        fml::jni::ClearException(env);
      }
      return false;
    }
    env->CallVoidMethod(java_object_->obj(), mid, static_cast<jint>(view_id),
                        static_cast<jdouble>(width),
                        static_cast<jdouble>(height));
    if (fml::jni::HasException(env)) {
      fml::jni::ClearException(env);
      return false;
    }
    return true;
  }
  return true;
}

bool DefaultJvmInvoker::OffsetPlatformView(int64_t view_id,
                                           double top,
                                           double left) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::OffsetPlatformView", "view_id",
               std::to_string(view_id).c_str());
  if (java_object_ && !java_object_->is_null()) {
    JNIEnv* env = fml::jni::AttachCurrentThread();
    if (!env || !env->functions || !env->functions->GetObjectClass ||
        !env->functions->GetMethodID || !env->functions->CallVoidMethod) {
      return false;
    }
    fml::jni::ScopedJavaLocalFrame local_frame(env, 16);
    jclass clazz = env->GetObjectClass(java_object_->obj());
    if (!clazz) {
      if (fml::jni::HasException(env)) {
        fml::jni::ClearException(env);
      }
      return false;
    }
    jmethodID mid = env->GetMethodID(clazz, "offsetPlatformView", "(IDD)V");
    if (!mid) {
      if (fml::jni::HasException(env)) {
        fml::jni::ClearException(env);
      }
      return false;
    }
    env->CallVoidMethod(java_object_->obj(), mid, static_cast<jint>(view_id),
                        static_cast<jdouble>(top), static_cast<jdouble>(left));
    if (fml::jni::HasException(env)) {
      fml::jni::ClearException(env);
      return false;
    }
    return true;
  }
  return true;
}

bool DefaultJvmInvoker::SetPlatformViewDirection(int64_t view_id,
                                                 int32_t direction) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::SetPlatformViewDirection",
               "view_id", std::to_string(view_id).c_str());
  if (java_object_ && !java_object_->is_null()) {
    JNIEnv* env = fml::jni::AttachCurrentThread();
    if (!env || !env->functions || !env->functions->GetObjectClass ||
        !env->functions->GetMethodID || !env->functions->CallVoidMethod) {
      return false;
    }
    fml::jni::ScopedJavaLocalFrame local_frame(env, 16);
    jclass clazz = env->GetObjectClass(java_object_->obj());
    if (!clazz) {
      if (fml::jni::HasException(env)) {
        fml::jni::ClearException(env);
      }
      return false;
    }
    jmethodID mid =
        env->GetMethodID(clazz, "setPlatformViewDirection", "(II)V");
    if (!mid) {
      if (fml::jni::HasException(env)) {
        fml::jni::ClearException(env);
      }
      return false;
    }
    env->CallVoidMethod(java_object_->obj(), mid, static_cast<jint>(view_id),
                        static_cast<jint>(direction));
    if (fml::jni::HasException(env)) {
      fml::jni::ClearException(env);
      return false;
    }
    return true;
  }
  return true;
}

}  // namespace android
}  // namespace flutter
