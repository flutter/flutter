// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/bindings/jni/jni_object.h"

#include "base/strings/string_util.h"
#include "sky/engine/bindings/jni/dart_jni.h"
#include "sky/engine/bindings/jni/jni_array.h"

namespace blink {

IMPLEMENT_WRAPPERTYPEINFO(jni, JniObject);

JniObject::JniObject(JNIEnv* env, jobject object)
    : object_(env, object) {
}

JniObject::~JniObject() {
}

PassRefPtr<JniObject> JniObject::Create(JNIEnv* env, jobject object) {
  if (object == nullptr)
    return nullptr;

  std::string class_name = DartJni::GetObjectClassName(env, object);

  JniObject* result;

  if (class_name == "java.lang.String") {
    result = new JniString(env, static_cast<jstring>(object));
  } else if (base::StartsWith(class_name, "[L", base::CompareCase::SENSITIVE)) {
    result = new JniObjectArray(env, static_cast<jobjectArray>(object));
  } else {
    result = new JniObject(env, object);
  }

  return adoptRef(result);
}

int64_t JniObject::GetIntField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jint result = env->GetIntField(java_object(), fieldId);
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

PassRefPtr<JniObject> JniObject::CallObjectMethod(
    jmethodID methodId,
    const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception) goto fail;

    jobject result = env->CallObjectMethodA(java_object(), methodId,
                                            java_args.jvalues());
    if (CheckJniException(env, &exception)) goto fail;

    return JniObject::Create(env, result);
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return nullptr;
}

bool JniObject::CallBooleanMethod(jmethodID methodId,
                                  const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception) goto fail;

    jboolean result = env->CallBooleanMethodA(java_object(), methodId,
                                              java_args.jvalues());
    if (CheckJniException(env, &exception)) goto fail;

    return result == JNI_TRUE;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return false;
}

int64_t JniObject::CallIntMethod(jmethodID methodId,
                                 const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception) goto fail;

    jint result = env->CallIntMethodA(java_object(), methodId,
                                      java_args.jvalues());
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

IMPLEMENT_WRAPPERTYPEINFO(jni, JniString);

JniString::JniString(JNIEnv* env, jstring object)
    : JniObject(env, object) {}

JniString::~JniString() {
}

jstring JniString::java_string() {
  return static_cast<jstring>(java_object());
}

std::string JniString::GetText() {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jsize length = env->GetStringLength(java_string());
    if (CheckJniException(env, &exception)) goto fail;

    const jchar* chars = env->GetStringChars(java_string(), NULL);
    if (CheckJniException(env, &exception)) goto fail;

    std::string result(reinterpret_cast<const char*>(chars), length);
    env->ReleaseStringChars(java_string(), chars);

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return std::string();
}

} // namespace blink
