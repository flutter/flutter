// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/jni/jni_object.h"

#include "base/strings/string_util.h"
#include "flutter/lib/jni/dart_jni.h"
#include "flutter/lib/jni/jni_array.h"
#include "flutter/lib/jni/jni_class.h"
#include "flutter/lib/jni/jni_string.h"

namespace blink {

IMPLEMENT_WRAPPERTYPEINFO(jni, JniObject);

JniObject::JniObject(JNIEnv* env, jobject object) : object_(env, object) {}

JniObject::~JniObject() {}

ftl::RefPtr<JniObject> JniObject::Create(JNIEnv* env, jobject object) {
  if (object == nullptr)
    return nullptr;

  std::string class_name = DartJni::GetObjectClassName(env, object);

  ftl::RefPtr<JniObject> result;

  if (class_name == "java.lang.String") {
    result = ftl::MakeRefCounted<JniString>(env, static_cast<jstring>(object));
  } else if (class_name == "java.lang.Class") {
    result = ftl::MakeRefCounted<JniClass>(env, static_cast<jclass>(object));
  } else if (base::StartsWith(class_name, "[L", base::CompareCase::SENSITIVE)) {
    result = ftl::MakeRefCounted<JniObjectArray>(
        env, static_cast<jobjectArray>(object));
  } else if (class_name == "[Z") {
    result = ftl::MakeRefCounted<JniBooleanArray>(
        env, static_cast<jbooleanArray>(object));
  } else if (class_name == "[B") {
    result =
        ftl::MakeRefCounted<JniByteArray>(env, static_cast<jbyteArray>(object));
  } else if (class_name == "[C") {
    result =
        ftl::MakeRefCounted<JniCharArray>(env, static_cast<jcharArray>(object));
  } else if (class_name == "[S") {
    result = ftl::MakeRefCounted<JniShortArray>(
        env, static_cast<jshortArray>(object));
  } else if (class_name == "[I") {
    result =
        ftl::MakeRefCounted<JniIntArray>(env, static_cast<jintArray>(object));
  } else if (class_name == "[J") {
    result =
        ftl::MakeRefCounted<JniLongArray>(env, static_cast<jlongArray>(object));
  } else if (class_name == "[F") {
    result = ftl::MakeRefCounted<JniFloatArray>(
        env, static_cast<jfloatArray>(object));
  } else if (class_name == "[D") {
    result = ftl::MakeRefCounted<JniDoubleArray>(
        env, static_cast<jdoubleArray>(object));
  } else {
    result = ftl::MakeRefCounted<JniObject>(env, object);
  }

  return result;
}

ftl::RefPtr<JniClass> JniObject::GetObjectClass() {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jclass clazz = env->GetObjectClass(java_object());
    if (CheckJniException(env, &exception))
      goto fail;

    return ftl::MakeRefCounted<JniClass>(env, clazz);
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return nullptr;
}

ftl::RefPtr<JniObject> JniObject::GetObjectField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jobject obj = env->GetObjectField(java_object(), fieldId);
    if (CheckJniException(env, &exception))
      goto fail;

    return JniObject::Create(env, obj);
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return nullptr;
}

bool JniObject::GetBooleanField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jboolean result = env->GetBooleanField(java_object(), fieldId);
    if (CheckJniException(env, &exception))
      goto fail;

    return result == JNI_TRUE;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return false;
}

int64_t JniObject::GetByteField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jbyte result = env->GetByteField(java_object(), fieldId);
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

int64_t JniObject::GetCharField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jchar result = env->GetCharField(java_object(), fieldId);
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

int64_t JniObject::GetShortField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jshort result = env->GetShortField(java_object(), fieldId);
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

int64_t JniObject::GetIntField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jint result = env->GetIntField(java_object(), fieldId);
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

int64_t JniObject::GetLongField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jlong result = env->GetLongField(java_object(), fieldId);
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

double JniObject::GetFloatField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jfloat result = env->GetFloatField(java_object(), fieldId);
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

double JniObject::GetDoubleField(jfieldID fieldId) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jfloat result = env->GetDoubleField(java_object(), fieldId);
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

void JniObject::SetObjectField(jfieldID fieldId, const JniObject* value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetObjectField(java_object(), fieldId,
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

void JniObject::SetBooleanField(jfieldID fieldId, bool value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetBooleanField(java_object(), fieldId, value ? JNI_TRUE : JNI_FALSE);
    if (CheckJniException(env, &exception))
      goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return;
}

void JniObject::SetByteField(jfieldID fieldId, int64_t value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetByteField(java_object(), fieldId, value);
    if (CheckJniException(env, &exception))
      goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return;
}

void JniObject::SetCharField(jfieldID fieldId, int64_t value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetCharField(java_object(), fieldId, value);
    if (CheckJniException(env, &exception))
      goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return;
}

void JniObject::SetShortField(jfieldID fieldId, int64_t value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetShortField(java_object(), fieldId, value);
    if (CheckJniException(env, &exception))
      goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return;
}

void JniObject::SetIntField(jfieldID fieldId, int64_t value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetIntField(java_object(), fieldId, value);
    if (CheckJniException(env, &exception))
      goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return;
}

void JniObject::SetLongField(jfieldID fieldId, int64_t value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetLongField(java_object(), fieldId, value);
    if (CheckJniException(env, &exception))
      goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return;
}

void JniObject::SetFloatField(jfieldID fieldId, double value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetFloatField(java_object(), fieldId, value);
    if (CheckJniException(env, &exception))
      goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return;
}

void JniObject::SetDoubleField(jfieldID fieldId, double value) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    env->SetDoubleField(java_object(), fieldId, value);
    if (CheckJniException(env, &exception))
      goto fail;

    return;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return;
}

ftl::RefPtr<JniObject> JniObject::CallObjectMethod(
    jmethodID methodId,
    const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception)
      goto fail;

    jobject obj =
        env->CallObjectMethodA(java_object(), methodId, java_args.jvalues());
    if (CheckJniException(env, &exception))
      goto fail;

    return JniObject::Create(env, obj);
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return nullptr;
}

bool JniObject::CallBooleanMethod(jmethodID methodId,
                                  const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception)
      goto fail;

    jboolean result =
        env->CallBooleanMethodA(java_object(), methodId, java_args.jvalues());
    if (CheckJniException(env, &exception))
      goto fail;

    return result == JNI_TRUE;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return false;
}

int64_t JniObject::CallByteMethod(jmethodID methodId,
                                  const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception)
      goto fail;

    jbyte result =
        env->CallByteMethodA(java_object(), methodId, java_args.jvalues());
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

int64_t JniObject::CallCharMethod(jmethodID methodId,
                                  const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception)
      goto fail;

    jchar result =
        env->CallCharMethodA(java_object(), methodId, java_args.jvalues());
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

int64_t JniObject::CallShortMethod(jmethodID methodId,
                                   const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception)
      goto fail;

    jshort result =
        env->CallShortMethodA(java_object(), methodId, java_args.jvalues());
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

int64_t JniObject::CallIntMethod(jmethodID methodId,
                                 const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception)
      goto fail;

    jint result =
        env->CallIntMethodA(java_object(), methodId, java_args.jvalues());
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

int64_t JniObject::CallLongMethod(jmethodID methodId,
                                  const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception)
      goto fail;

    jlong result =
        env->CallLongMethodA(java_object(), methodId, java_args.jvalues());
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

double JniObject::CallFloatMethod(jmethodID methodId,
                                  const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception)
      goto fail;

    jfloat result =
        env->CallFloatMethodA(java_object(), methodId, java_args.jvalues());
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

double JniObject::CallDoubleMethod(jmethodID methodId,
                                   const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception)
      goto fail;

    jdouble result =
        env->CallDoubleMethodA(java_object(), methodId, java_args.jvalues());
    if (CheckJniException(env, &exception))
      goto fail;

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return 0;
}

void JniObject::CallVoidMethod(jmethodID methodId,
                               const std::vector<Dart_Handle>& args) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    JniMethodArgs java_args;
    java_args.Convert(env, args, &exception);
    if (exception)
      goto fail;

    env->CallVoidMethodA(java_object(), methodId, java_args.jvalues());
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
