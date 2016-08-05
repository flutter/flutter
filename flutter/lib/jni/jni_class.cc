// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/jni/jni_class.h"

#include "flutter/lib/jni/dart_jni.h"

namespace blink {

using tonic::ToDart;
using base::android::ScopedJavaLocalRef;

IMPLEMENT_WRAPPERTYPEINFO(jni, JniClass);

JniClass::JniClass(JNIEnv* env, jclass clazz) : JniObject(env, clazz) {}

JniClass::~JniClass() {}

ftl::RefPtr<JniClass> JniClass::FromName(const char* name) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    if (!name)
      return nullptr;

    ScopedJavaLocalRef<jclass> clazz = DartJni::GetClass(env, name);
    if (CheckJniException(env, &exception))
      goto fail;

    return ftl::MakeRefCounted<JniClass>(env, clazz.obj());
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return nullptr;
}

ftl::RefPtr<JniClass> JniClass::FromClassObject(const JniObject* clazz) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    if (!clazz)
      return nullptr;

    jobject class_object = clazz->java_object();
    if (!env->IsInstanceOf(class_object, DartJni::class_clazz())) {
      exception = ToDart("invalid JNI class object");
      goto fail;
    }

    return ftl::MakeRefCounted<JniClass>(env,
                                         static_cast<jclass>(class_object));
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return nullptr;
}

intptr_t JniClass::GetFieldId(const char* name, const char* sig) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jfieldID id = env->GetFieldID(java_class(), name, sig);
    if (CheckJniException(env, &exception))
      goto fail;

    return reinterpret_cast<intptr_t>(id);
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

intptr_t JniClass::GetStaticFieldId(const char* name, const char* sig) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jfieldID id = env->GetStaticFieldID(java_class(), name, sig);
    if (CheckJniException(env, &exception))
      goto fail;

    return reinterpret_cast<intptr_t>(id);
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

intptr_t JniClass::GetMethodId(const char* name, const char* sig) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jmethodID id = env->GetMethodID(java_class(), name, sig);
    if (CheckJniException(env, &exception))
      goto fail;

    return reinterpret_cast<intptr_t>(id);
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

intptr_t JniClass::GetStaticMethodId(const char* name, const char* sig) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jmethodID id = env->GetStaticMethodID(java_class(), name, sig);
    if (CheckJniException(env, &exception))
      goto fail;

    return reinterpret_cast<intptr_t>(id);
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

ftl::RefPtr<JniObject> JniClass::NewObject(
    jmethodID methodId,
    const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception)
      goto fail;

    jobject obj = env->NewObjectA(java_class(), methodId, java_args.jvalues());
    if (CheckJniException(env, &exception))
      goto fail;

    return JniObject::Create(env, obj);
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return nullptr;
}

bool JniClass::IsAssignable(const JniClass* clazz) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jboolean result = env->IsAssignableFrom(java_class(), clazz->java_class());
    if (CheckJniException(env, &exception))
      goto fail;

    return result == JNI_TRUE;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return false;
}

ftl::RefPtr<JniObject> JniClass::GetStaticObjectField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jobject obj = env->GetStaticObjectField(java_class(), fieldId);
    if (CheckJniException(env, &exception))
      goto fail;

    return JniObject::Create(env, obj);
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return nullptr;
}

bool JniClass::GetStaticBooleanField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jboolean result = env->GetStaticBooleanField(java_class(), fieldId);
    if (CheckJniException(env, &exception))
      goto fail;

    return result == JNI_TRUE;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return false;
}

int64_t JniClass::GetStaticByteField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jbyte result = env->GetStaticByteField(java_class(), fieldId);
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

int64_t JniClass::GetStaticCharField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jchar result = env->GetStaticCharField(java_class(), fieldId);
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

int64_t JniClass::GetStaticShortField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jshort result = env->GetStaticShortField(java_class(), fieldId);
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

int64_t JniClass::GetStaticIntField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jint result = env->GetStaticIntField(java_class(), fieldId);
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

int64_t JniClass::GetStaticLongField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jlong result = env->GetStaticLongField(java_class(), fieldId);
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

double JniClass::GetStaticFloatField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jfloat result = env->GetStaticFloatField(java_class(), fieldId);
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

double JniClass::GetStaticDoubleField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jfloat result = env->GetStaticDoubleField(java_class(), fieldId);
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

void JniClass::SetStaticObjectField(jfieldID fieldId, const JniObject* value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetStaticObjectField(java_class(), fieldId,
                              value ? value->java_object() : nullptr);
    if (CheckJniException(env, &exception))
      goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return;
}

void JniClass::SetStaticBooleanField(jfieldID fieldId, bool value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetStaticBooleanField(java_class(), fieldId,
                               value ? JNI_TRUE : JNI_FALSE);
    if (CheckJniException(env, &exception))
      goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return;
}

void JniClass::SetStaticByteField(jfieldID fieldId, int64_t value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetStaticByteField(java_class(), fieldId, value);
    if (CheckJniException(env, &exception))
      goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return;
}

void JniClass::SetStaticCharField(jfieldID fieldId, int64_t value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetStaticCharField(java_class(), fieldId, value);
    if (CheckJniException(env, &exception))
      goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return;
}

void JniClass::SetStaticShortField(jfieldID fieldId, int64_t value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetStaticShortField(java_class(), fieldId, value);
    if (CheckJniException(env, &exception))
      goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return;
}

void JniClass::SetStaticIntField(jfieldID fieldId, int64_t value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetStaticIntField(java_class(), fieldId, value);
    if (CheckJniException(env, &exception))
      goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return;
}

void JniClass::SetStaticLongField(jfieldID fieldId, int64_t value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetStaticLongField(java_class(), fieldId, value);
    if (CheckJniException(env, &exception))
      goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return;
}

void JniClass::SetStaticFloatField(jfieldID fieldId, double value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetStaticFloatField(java_class(), fieldId, value);
    if (CheckJniException(env, &exception))
      goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return;
}

void JniClass::SetStaticDoubleField(jfieldID fieldId, double value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetStaticDoubleField(java_class(), fieldId, value);
    if (CheckJniException(env, &exception))
      goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return;
}

ftl::RefPtr<JniObject> JniClass::CallStaticObjectMethod(
    jmethodID methodId,
    const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception)
      goto fail;

    jobject obj = env->CallStaticObjectMethodA(java_class(), methodId,
                                               java_args.jvalues());
    if (CheckJniException(env, &exception))
      goto fail;

    return JniObject::Create(env, obj);
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return nullptr;
}

bool JniClass::CallStaticBooleanMethod(jmethodID methodId,
                                       const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception)
      goto fail;

    jboolean result = env->CallStaticBooleanMethodA(java_class(), methodId,
                                                    java_args.jvalues());
    if (CheckJniException(env, &exception))
      goto fail;

    return result == JNI_TRUE;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return false;
}

int64_t JniClass::CallStaticByteMethod(jmethodID methodId,
                                       const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception)
      goto fail;

    jbyte result =
        env->CallStaticByteMethodA(java_class(), methodId, java_args.jvalues());
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

int64_t JniClass::CallStaticCharMethod(jmethodID methodId,
                                       const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception)
      goto fail;

    jchar result =
        env->CallStaticCharMethodA(java_class(), methodId, java_args.jvalues());
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

int64_t JniClass::CallStaticShortMethod(jmethodID methodId,
                                        const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception)
      goto fail;

    jshort result = env->CallStaticShortMethodA(java_class(), methodId,
                                                java_args.jvalues());
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

int64_t JniClass::CallStaticIntMethod(jmethodID methodId,
                                      const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception)
      goto fail;

    jint result =
        env->CallStaticIntMethodA(java_class(), methodId, java_args.jvalues());
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

int64_t JniClass::CallStaticLongMethod(jmethodID methodId,
                                       const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception)
      goto fail;

    jlong result =
        env->CallStaticLongMethodA(java_class(), methodId, java_args.jvalues());
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

double JniClass::CallStaticFloatMethod(jmethodID methodId,
                                       const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception)
      goto fail;

    jfloat result = env->CallStaticFloatMethodA(java_class(), methodId,
                                                java_args.jvalues());
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

double JniClass::CallStaticDoubleMethod(jmethodID methodId,
                                        const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception)
      goto fail;

    jdouble result = env->CallStaticDoubleMethodA(java_class(), methodId,
                                                  java_args.jvalues());
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

void JniClass::CallStaticVoidMethod(jmethodID methodId,
                                    const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception)
      goto fail;

    env->CallStaticVoidMethodA(java_class(), methodId, java_args.jvalues());
    if (CheckJniException(env, &exception))
      goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return;
}

}  // namespace blink
