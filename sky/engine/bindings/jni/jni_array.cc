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

PassRefPtr<JniObjectArray> JniObjectArray::Create(const JniClass* clazz,
                                                  jsize length) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jobjectArray array = env->NewObjectArray(length, clazz->java_class(),
                                             nullptr);
    if (CheckJniException(env, &exception)) goto fail;

    return adoptRef(new JniObjectArray(env, array));
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return nullptr;
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
                               value ? value->java_object() : nullptr);
    if (CheckJniException(env, &exception)) goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return;
}

IMPLEMENT_WRAPPERTYPEINFO(jni, JniBooleanArray);

JniBooleanArray::JniBooleanArray(JNIEnv* env, jbooleanArray array)
    : JniArray(env, array) {}

JniBooleanArray::~JniBooleanArray() {
}

PassRefPtr<JniBooleanArray> JniBooleanArray::Create(jsize length) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jbooleanArray array = env->NewBooleanArray(length);
    if (CheckJniException(env, &exception)) goto fail;

    return adoptRef(new JniBooleanArray(env, array));
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return nullptr;
}

bool JniBooleanArray::GetArrayElement(jsize index) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jboolean result;
    env->GetBooleanArrayRegion(java_array<jbooleanArray>(), index, 1, &result);
    if (CheckJniException(env, &exception)) goto fail;

    return result == JNI_TRUE;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return false;
}

void JniBooleanArray::SetArrayElement(jsize index, bool value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jboolean jni_value = value ? JNI_TRUE : JNI_FALSE;
    env->SetBooleanArrayRegion(java_array<jbooleanArray>(), index, 1,
                               &jni_value);
    if (CheckJniException(env, &exception)) goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return;
}

IMPLEMENT_WRAPPERTYPEINFO(jni, JniByteArray);

JniByteArray::JniByteArray(JNIEnv* env, jbyteArray array)
    : JniArray(env, array) {}

JniByteArray::~JniByteArray() {
}

PassRefPtr<JniByteArray> JniByteArray::Create(jsize length) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jbyteArray array = env->NewByteArray(length);
    if (CheckJniException(env, &exception)) goto fail;

    return adoptRef(new JniByteArray(env, array));
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return nullptr;
}

int64_t JniByteArray::GetArrayElement(jsize index) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jbyte result;
    env->GetByteArrayRegion(java_array<jbyteArray>(), index, 1, &result);
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return false;
}

void JniByteArray::SetArrayElement(jsize index, int64_t value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jbyte jni_value = static_cast<jbyte>(value);
    env->SetByteArrayRegion(java_array<jbyteArray>(), index, 1,
                            &jni_value);
    if (CheckJniException(env, &exception)) goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return;
}

IMPLEMENT_WRAPPERTYPEINFO(jni, JniCharArray);

JniCharArray::JniCharArray(JNIEnv* env, jcharArray array)
    : JniArray(env, array) {}

JniCharArray::~JniCharArray() {
}

PassRefPtr<JniCharArray> JniCharArray::Create(jsize length) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jcharArray array = env->NewCharArray(length);
    if (CheckJniException(env, &exception)) goto fail;

    return adoptRef(new JniCharArray(env, array));
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return nullptr;
}

int64_t JniCharArray::GetArrayElement(jsize index) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jchar result;
    env->GetCharArrayRegion(java_array<jcharArray>(), index, 1, &result);
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return false;
}

void JniCharArray::SetArrayElement(jsize index, int64_t value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jchar jni_value = static_cast<jchar>(value);
    env->SetCharArrayRegion(java_array<jcharArray>(), index, 1,
                            &jni_value);
    if (CheckJniException(env, &exception)) goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return;
}

IMPLEMENT_WRAPPERTYPEINFO(jni, JniShortArray);

JniShortArray::JniShortArray(JNIEnv* env, jshortArray array)
    : JniArray(env, array) {}

JniShortArray::~JniShortArray() {
}

PassRefPtr<JniShortArray> JniShortArray::Create(jsize length) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jshortArray array = env->NewShortArray(length);
    if (CheckJniException(env, &exception)) goto fail;

    return adoptRef(new JniShortArray(env, array));
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return nullptr;
}

int64_t JniShortArray::GetArrayElement(jsize index) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jshort result;
    env->GetShortArrayRegion(java_array<jshortArray>(), index, 1, &result);
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return false;
}

void JniShortArray::SetArrayElement(jsize index, int64_t value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jshort jni_value = static_cast<jshort>(value);
    env->SetShortArrayRegion(java_array<jshortArray>(), index, 1,
                             &jni_value);
    if (CheckJniException(env, &exception)) goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return;
}

IMPLEMENT_WRAPPERTYPEINFO(jni, JniIntArray);

JniIntArray::JniIntArray(JNIEnv* env, jintArray array)
    : JniArray(env, array) {}

JniIntArray::~JniIntArray() {
}

PassRefPtr<JniIntArray> JniIntArray::Create(jsize length) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jintArray array = env->NewIntArray(length);
    if (CheckJniException(env, &exception)) goto fail;

    return adoptRef(new JniIntArray(env, array));
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return nullptr;
}

int64_t JniIntArray::GetArrayElement(jsize index) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jint result;
    env->GetIntArrayRegion(java_array<jintArray>(), index, 1, &result);
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return false;
}

void JniIntArray::SetArrayElement(jsize index, int64_t value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jint jni_value = static_cast<jint>(value);
    env->SetIntArrayRegion(java_array<jintArray>(), index, 1,
                           &jni_value);
    if (CheckJniException(env, &exception)) goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return;
}

IMPLEMENT_WRAPPERTYPEINFO(jni, JniLongArray);

JniLongArray::JniLongArray(JNIEnv* env, jlongArray array)
    : JniArray(env, array) {}

JniLongArray::~JniLongArray() {
}

PassRefPtr<JniLongArray> JniLongArray::Create(jsize length) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jlongArray array = env->NewLongArray(length);
    if (CheckJniException(env, &exception)) goto fail;

    return adoptRef(new JniLongArray(env, array));
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return nullptr;
}

int64_t JniLongArray::GetArrayElement(jsize index) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jlong result;
    env->GetLongArrayRegion(java_array<jlongArray>(), index, 1, &result);
    if (CheckJniException(env, &exception)) goto fail;

    return static_cast<int64_t>(result);
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return false;
}

void JniLongArray::SetArrayElement(jsize index, int64_t value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jlong jni_value = static_cast<jlong>(value);
    env->SetLongArrayRegion(java_array<jlongArray>(), index, 1,
                            &jni_value);
    if (CheckJniException(env, &exception)) goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return;
}

IMPLEMENT_WRAPPERTYPEINFO(jni, JniFloatArray);

JniFloatArray::JniFloatArray(JNIEnv* env, jfloatArray array)
    : JniArray(env, array) {}

JniFloatArray::~JniFloatArray() {
}

PassRefPtr<JniFloatArray> JniFloatArray::Create(jsize length) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jfloatArray array = env->NewFloatArray(length);
    if (CheckJniException(env, &exception)) goto fail;

    return adoptRef(new JniFloatArray(env, array));
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return nullptr;
}

double JniFloatArray::GetArrayElement(jsize index) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jfloat result;
    env->GetFloatArrayRegion(java_array<jfloatArray>(), index, 1, &result);
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return false;
}

void JniFloatArray::SetArrayElement(jsize index, double value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jfloat jni_value = static_cast<jfloat>(value);
    env->SetFloatArrayRegion(java_array<jfloatArray>(), index, 1,
                             &jni_value);
    if (CheckJniException(env, &exception)) goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return;
}

IMPLEMENT_WRAPPERTYPEINFO(jni, JniDoubleArray);

JniDoubleArray::JniDoubleArray(JNIEnv* env, jdoubleArray array)
    : JniArray(env, array) {}

JniDoubleArray::~JniDoubleArray() {
}

PassRefPtr<JniDoubleArray> JniDoubleArray::Create(jsize length) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jdoubleArray array = env->NewDoubleArray(length);
    if (CheckJniException(env, &exception)) goto fail;

    return adoptRef(new JniDoubleArray(env, array));
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return nullptr;
}

double JniDoubleArray::GetArrayElement(jsize index) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jdouble result;
    env->GetDoubleArrayRegion(java_array<jdoubleArray>(), index, 1, &result);
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return false;
}

void JniDoubleArray::SetArrayElement(jsize index, double value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetDoubleArrayRegion(java_array<jdoubleArray>(), index, 1,
                              &value);
    if (CheckJniException(env, &exception)) goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return;
}

} // namespace blink
