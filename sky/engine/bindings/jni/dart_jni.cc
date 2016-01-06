// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/bindings/jni/dart_jni.h"

#include "base/logging.h"
#include "base/android/jni_android.h"
#include "base/android/jni_string.h"
#include "sky/engine/tonic/dart_args.h"
#include "sky/engine/tonic/dart_binding_macros.h"

namespace blink {

using base::android::ScopedJavaLocalRef;
using base::android::ScopedJavaGlobalRef;

namespace {

// Check if a JNI API has thrown an exception.  If so, rethrow it as a
// Dart exception.
void CheckJniException(JNIEnv* env) {
  if (env->ExceptionCheck() == JNI_FALSE)
    return;

  jthrowable java_throwable = env->ExceptionOccurred();
  env->ExceptionClear();
  std::string info = base::android::GetJavaExceptionInfo(
      env, java_throwable);

  Dart_ThrowException(StdStringToDart(info));
}

} // anonymous namespace

DART_NATIVE_CALLBACK_STATIC(JniClass, fromName);

#define FOR_EACH_BINDING(V) \
  V(JniClass, getFieldId) \
  V(JniClass, getStaticFieldId) \
  V(JniClass, getStaticIntField) \
  V(JniClass, getStaticObjectField) \
  V(JniObject, getIntField)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void DartJni::RegisterNatives(DartLibraryNatives* natives) {
  natives->Register({
    DART_REGISTER_NATIVE_STATIC(JniClass, fromName)
    FOR_EACH_BINDING(DART_REGISTER_NATIVE)
  });
}

ScopedJavaGlobalRef<jobject> DartJni::class_loader_;
jmethodID DartJni::load_class_method_id_;

bool DartJni::InitJni() {
  JNIEnv* env = base::android::AttachCurrentThread();

  class_loader_.Reset(base::android::GetClassLoader(env));

  ScopedJavaLocalRef<jclass> class_loader_clazz(
      env, env->FindClass("java/lang/ClassLoader"));
  CHECK(!base::android::ClearException(env));

  load_class_method_id_ = env->GetMethodID(
      class_loader_clazz.obj(),
      "loadClass",
      "(Ljava/lang/String;)Ljava/lang/Class;");
  CHECK(!base::android::ClearException(env));

  return true;
}

ScopedJavaLocalRef<jclass> DartJni::GetClass(JNIEnv* env, const char* name) {
  jobject clazz = env->CallObjectMethod(
      class_loader_.obj(),
      load_class_method_id_,
      base::android::ConvertUTF8ToJavaString(env, name).obj());

  return ScopedJavaLocalRef<jclass>(env, static_cast<jclass>(clazz));
}

IMPLEMENT_WRAPPERTYPEINFO(JniClass);

JniClass::JniClass(JNIEnv* env, jclass clazz)
    : clazz_(env, clazz) {
}

JniClass::~JniClass() {
}

PassRefPtr<JniClass> JniClass::fromName(const char* name) {
  JNIEnv* env = base::android::AttachCurrentThread();

  ScopedJavaLocalRef<jclass> clazz = DartJni::GetClass(env, name);
  CheckJniException(env);

  return adoptRef(new JniClass(env, clazz.obj()));
}

intptr_t JniClass::getFieldId(const char* name, const char* sig) {
  JNIEnv* env = base::android::AttachCurrentThread();
  jfieldID id = env->GetFieldID(clazz_.obj(), name, sig);
  CheckJniException(env);
  return reinterpret_cast<intptr_t>(id);
}

intptr_t JniClass::getStaticFieldId(const char* name, const char* sig) {
  JNIEnv* env = base::android::AttachCurrentThread();
  jfieldID id = env->GetStaticFieldID(clazz_.obj(), name, sig);
  CheckJniException(env);
  return reinterpret_cast<intptr_t>(id);
}

jint JniClass::getStaticIntField(jfieldID fieldId) {
  JNIEnv* env = base::android::AttachCurrentThread();
  return env->GetStaticIntField(clazz_.obj(), fieldId);
}

PassRefPtr<JniObject> JniClass::getStaticObjectField(jfieldID fieldId) {
  JNIEnv* env = base::android::AttachCurrentThread();
  jobject obj = env->GetStaticObjectField(clazz_.obj(), fieldId);
  return JniObject::create(env, obj);
}

IMPLEMENT_WRAPPERTYPEINFO(JniObject);

JniObject::JniObject(JNIEnv* env, jobject object)
    : object_(env, object) {
}

JniObject::~JniObject() {
}

PassRefPtr<JniObject> JniObject::create(JNIEnv* env, jobject object) {
  return adoptRef(new JniObject(env, object));
}

jint JniObject::getIntField(jfieldID fieldId) {
  JNIEnv* env = base::android::AttachCurrentThread();
  return env->GetIntField(object_.obj(), fieldId);
}

} // namespace blink
