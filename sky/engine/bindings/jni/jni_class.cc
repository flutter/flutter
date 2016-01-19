// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/bindings/jni/jni_class.h"

#include "sky/engine/bindings/jni/dart_jni.h"
#include "sky/engine/bindings/jni/jni_object.h"

namespace blink {

using base::android::ScopedJavaLocalRef;

IMPLEMENT_WRAPPERTYPEINFO(jni, JniClass);

JniClass::JniClass(JNIEnv* env, jclass clazz)
    : clazz_(env, clazz) {
}

JniClass::~JniClass() {
}

PassRefPtr<JniClass> JniClass::FromName(const char* name) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    ScopedJavaLocalRef<jclass> clazz = DartJni::GetClass(env, name);
    if (CheckJniException(env, &exception)) goto fail;

    return adoptRef(new JniClass(env, clazz.obj()));
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return nullptr;
}

PassRefPtr<JniClass> JniClass::FromClassObject(const JniObject* classObject) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jobject class_object = classObject->java_object();
    if (!env->IsInstanceOf(class_object, DartJni::class_clazz())) {
      exception = ToDart("invalid JNI class object");
      goto fail;
    }

    return adoptRef(new JniClass(env, static_cast<jclass>(class_object)));
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return nullptr;
}

intptr_t JniClass::GetFieldId(const char* name, const char* sig) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jfieldID id = env->GetFieldID(clazz_.obj(), name, sig);
    if (CheckJniException(env, &exception)) goto fail;

    return reinterpret_cast<intptr_t>(id);
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

intptr_t JniClass::GetStaticFieldId(const char* name, const char* sig) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jfieldID id = env->GetStaticFieldID(clazz_.obj(), name, sig);
    if (CheckJniException(env, &exception)) goto fail;

    return reinterpret_cast<intptr_t>(id);
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

intptr_t JniClass::GetMethodId(const char* name, const char* sig) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jmethodID id = env->GetMethodID(clazz_.obj(), name, sig);
    if (CheckJniException(env, &exception)) goto fail;

    return reinterpret_cast<intptr_t>(id);
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

intptr_t JniClass::GetStaticMethodId(const char* name, const char* sig) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jmethodID id = env->GetStaticMethodID(clazz_.obj(), name, sig);
    if (CheckJniException(env, &exception)) goto fail;

    return reinterpret_cast<intptr_t>(id);
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

PassRefPtr<JniObject> JniClass::NewObject(
    jmethodID methodId, const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception) goto fail;

    jobject obj = env->NewObjectA(clazz_.obj(), methodId, java_args.jvalues());
    if (CheckJniException(env, &exception)) goto fail;

    return JniObject::Create(env, obj);
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return nullptr;
}

PassRefPtr<JniObject> JniClass::GetStaticObjectField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jobject obj = env->GetStaticObjectField(clazz_.obj(), fieldId);
    if (CheckJniException(env, &exception)) goto fail;

    return JniObject::Create(env, obj);
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return nullptr;
}

bool JniClass::GetStaticBooleanField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jboolean result = env->GetStaticBooleanField(clazz_.obj(), fieldId);
    if (CheckJniException(env, &exception)) goto fail;

    return result == JNI_TRUE;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return false;
}

int64_t JniClass::GetStaticByteField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jbyte result = env->GetStaticByteField(clazz_.obj(), fieldId);
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

int64_t JniClass::GetStaticCharField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jchar result = env->GetStaticCharField(clazz_.obj(), fieldId);
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

int64_t JniClass::GetStaticShortField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jshort result = env->GetStaticShortField(clazz_.obj(), fieldId);
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

int64_t JniClass::GetStaticIntField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jint result = env->GetStaticIntField(clazz_.obj(), fieldId);
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

int64_t JniClass::GetStaticLongField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jlong result = env->GetStaticLongField(clazz_.obj(), fieldId);
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

double JniClass::GetStaticFloatField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jfloat result = env->GetStaticFloatField(clazz_.obj(), fieldId);
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

double JniClass::GetStaticDoubleField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jfloat result = env->GetStaticDoubleField(clazz_.obj(), fieldId);
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

void JniClass::SetStaticObjectField(jfieldID fieldId, const JniObject* value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetStaticObjectField(clazz_.obj(), fieldId, value->java_object());
    if (CheckJniException(env, &exception)) goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return;
}

void JniClass::SetStaticBooleanField(jfieldID fieldId, bool value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetStaticBooleanField(clazz_.obj(), fieldId,
                               value ? JNI_TRUE : JNI_FALSE);
    if (CheckJniException(env, &exception)) goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return;
}

void JniClass::SetStaticByteField(jfieldID fieldId, int64_t value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetStaticByteField(clazz_.obj(), fieldId, value);
    if (CheckJniException(env, &exception)) goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return;
}

void JniClass::SetStaticCharField(jfieldID fieldId, int64_t value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetStaticCharField(clazz_.obj(), fieldId, value);
    if (CheckJniException(env, &exception)) goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return;
}

void JniClass::SetStaticShortField(jfieldID fieldId, int64_t value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetStaticShortField(clazz_.obj(), fieldId, value);
    if (CheckJniException(env, &exception)) goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return;
}

void JniClass::SetStaticIntField(jfieldID fieldId, int64_t value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetStaticIntField(clazz_.obj(), fieldId, value);
    if (CheckJniException(env, &exception)) goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return;
}

void JniClass::SetStaticLongField(jfieldID fieldId, int64_t value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetStaticLongField(clazz_.obj(), fieldId, value);
    if (CheckJniException(env, &exception)) goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return;
}

void JniClass::SetStaticFloatField(jfieldID fieldId, double value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetStaticFloatField(clazz_.obj(), fieldId, value);
    if (CheckJniException(env, &exception)) goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return;
}

void JniClass::SetStaticDoubleField(jfieldID fieldId, double value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetStaticDoubleField(clazz_.obj(), fieldId, value);
    if (CheckJniException(env, &exception)) goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return;
}

PassRefPtr<JniObject> JniClass::CallStaticObjectMethod(
    jmethodID methodId, const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception) goto fail;

    jobject obj = env->CallStaticObjectMethodA(clazz_.obj(), methodId,
                                               java_args.jvalues());
    if (CheckJniException(env, &exception)) goto fail;

    return JniObject::Create(env, obj);
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return nullptr;
}

bool JniClass::CallStaticBooleanMethod(jmethodID methodId,
                                       const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception) goto fail;

    jboolean result = env->CallStaticBooleanMethodA(clazz_.obj(), methodId,
                                                    java_args.jvalues());
    if (CheckJniException(env, &exception)) goto fail;

    return result == JNI_TRUE;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return false;
}

int64_t JniClass::CallStaticByteMethod(jmethodID methodId,
                                       const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception) goto fail;

    jbyte result = env->CallStaticByteMethodA(clazz_.obj(), methodId,
                                              java_args.jvalues());
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

int64_t JniClass::CallStaticCharMethod(jmethodID methodId,
                                       const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception) goto fail;

    jchar result = env->CallStaticCharMethodA(clazz_.obj(), methodId,
                                              java_args.jvalues());
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

int64_t JniClass::CallStaticShortMethod(jmethodID methodId,
                                        const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception) goto fail;

    jshort result = env->CallStaticShortMethodA(clazz_.obj(), methodId,
                                                java_args.jvalues());
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

int64_t JniClass::CallStaticIntMethod(jmethodID methodId,
                                      const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception) goto fail;

    jint result = env->CallStaticIntMethodA(clazz_.obj(), methodId,
                                            java_args.jvalues());
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

int64_t JniClass::CallStaticLongMethod(jmethodID methodId,
                                       const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception) goto fail;

    jlong result = env->CallStaticLongMethodA(clazz_.obj(), methodId,
                                              java_args.jvalues());
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

double JniClass::CallStaticFloatMethod(jmethodID methodId,
                                       const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception) goto fail;

    jfloat result = env->CallStaticFloatMethodA(clazz_.obj(), methodId,
                                                java_args.jvalues());
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

double JniClass::CallStaticDoubleMethod(jmethodID methodId,
                                        const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception) goto fail;

    jdouble result = env->CallStaticDoubleMethodA(clazz_.obj(), methodId,
                                                  java_args.jvalues());
    if (CheckJniException(env, &exception)) goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return 0;
}

void JniClass::CallStaticVoidMethod(jmethodID methodId,
                                    const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception) goto fail;

    env->CallStaticVoidMethodA(clazz_.obj(), methodId, java_args.jvalues());
    if (CheckJniException(env, &exception)) goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  ASSERT_NOT_REACHED();
  return;
}

} // namespace blink
