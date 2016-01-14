// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/bindings/jni/jni_array.h"

#include "sky/engine/bindings/jni/dart_jni.h"

namespace blink {

IMPLEMENT_WRAPPERTYPEINFO(jni, JniArray);

JniArray::JniArray(JNIEnv* env, jarray array)
    : JniObject(env, array) {}

JniArray::~JniArray() {
}

jsize JniArray::GetLength() {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jsize result = env->GetArrayLength(java_array<jarray>());
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

template<typename JArrayType>
JArrayType JniArray::java_array() const {
  return static_cast<JArrayType>(java_object());
}

IMPLEMENT_WRAPPERTYPEINFO(jni, JniObjectArray);

JniObjectArray::JniObjectArray(JNIEnv* env, jobjectArray array)
    : JniArray(env, array) {}

JniObjectArray::~JniObjectArray() {
}

PassRefPtr<JniObject> JniObjectArray::GetArrayElement(jsize index) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jobject obj = env->GetObjectArrayElement(java_array<jobjectArray>(),
                                             index);
    if (CheckJniException(env, &exception)) goto fail;

    return JniObject::Create(env, obj);
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return nullptr;
}

void JniObjectArray::SetArrayElement(jsize index, const JniObject* value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetObjectArrayElement(java_array<jobjectArray>(), index,
                               value->java_object());
    if (CheckJniException(env, &exception)) goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return;
}

} // namespace blink
